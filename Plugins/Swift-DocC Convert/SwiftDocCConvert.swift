// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022-2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
import PackagePlugin

/// Creates a Swift-DocC documentation archive from a Swift Package.
@main struct SwiftDocCConvert: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) throws {
        // We'll be creating commands that invoke `docc`, so start by locating it.
        let doccExecutableURL = try context.doccExecutable
        
        var argumentExtractor = ArgumentExtractor(arguments)
        let specifiedTargets = try argumentExtractor.extractSpecifiedTargets(in: context.package)
        
        let swiftSourceModuleTargets: [SwiftSourceModuleTarget]
        if specifiedTargets.isEmpty {
            swiftSourceModuleTargets = context.package.allDocumentableTargets
        } else {
            swiftSourceModuleTargets = specifiedTargets
        }
        
        guard !swiftSourceModuleTargets.isEmpty else {
            throw ArgumentParsingError.packageDoesNotContainSwiftSourceModuleTargets
        }
        
        // Parse the given command-line arguments
        let parsedArguments = ParsedArguments(argumentExtractor.remainingArguments)
        
        // If the `--help` or `-h` flag was passed, print the plugin's help information and exit.
        guard !parsedArguments.pluginArguments.help else {
            let helpInfo = try HelpInformation.forAction(.convert, doccExecutableURL: doccExecutableURL)
            print(helpInfo)
            return
        }
        
        let verbose = parsedArguments.pluginArguments.verbose
        let isCombinedDocumentationEnabled = parsedArguments.pluginArguments.enableCombinedDocumentation
        
        let doccFeatures: DocCFeatures?
        // Only read and decode the features file if something is going to check those flags.
        if isCombinedDocumentationEnabled {
            doccFeatures = try? DocCFeatures(doccExecutable: doccExecutableURL)
            guard doccFeatures?.contains(.linkDependencies) == true else {
                // The developer uses the combined documentation plugin flag with a DocC version that doesn't support combined documentation.
                Diagnostics.error("""
                Unsupported use of '\(DocumentedFlag.enableCombinedDocumentation.names.preferred)'. \
                DocC version at '\(doccExecutableURL.path)' doesn't support combined documentation.
                """)
                return
            }
        } else {
            doccFeatures = nil
        }
        
#if swift(>=5.7)
        let snippetExtractTool = try context.tool(named: "snippet-extract")
        let snippetExtractor = SnippetExtractor(
            snippetTool: URL(fileURLWithPath: snippetExtractTool.path.string, isDirectory: false),
            workingDirectory: URL(fileURLWithPath: context.pluginWorkDirectory.string, isDirectory: true)
        )
#else
        let snippetExtractor: SnippetExtractor? = nil
#endif
        
        // An inner function that defines the work to build documentation for a given target.
        func performBuildTask(_ task: DocumentationBuildGraph<SwiftSourceModuleTarget>.Task) throws -> URL? {
            let target = task.target
            print("Generating documentation for '\(target.name)'...")
            
            let symbolGraphs = try packageManager.doccSymbolGraphs(
                for: target,
                context: context,
                verbose: verbose,
                snippetExtractor: snippetExtractor,
                customSymbolGraphOptions: parsedArguments.symbolGraphArguments
            )
            
            if target.doccCatalogPath == nil,
               try FileManager.default.contentsOfDirectory(atPath: symbolGraphs.targetSymbolGraphsDirectory.path).isEmpty
            {
                // This target did not produce any symbol graphs and has no DocC catalog.
                let message = """
                    '\(target.name)' does not contain any documentable symbols or a \
                    DocC catalog and will not produce documentation
                    """
                
                if swiftSourceModuleTargets.count > 1 {
                    // We're building multiple targets, just emit a warning for this
                    // one target that does not produce documentation.
                    Diagnostics.warning(message)
                } else {
                    // This is the only target being built so emit an error
                    Diagnostics.error(message)
                }
                return nil
            }
            
            // Construct the output path for the generated DocC archive
            let archiveOutputPath: String
            let dependencyArchivePaths: [String]
            if isCombinedDocumentationEnabled {
                // When building combined documentation for many targets, the individual target's documentation isn't the final product.
                // Because of this, we 
                archiveOutputPath  = target.dependencyDocCArchiveOutputPath(in: context)
                dependencyArchivePaths = task.dependencies.map { $0.target.dependencyDocCArchiveOutputPath(in: context) }
                try? FileManager.default.createDirectory(at: URL(fileURLWithPath: archiveOutputPath).deletingLastPathComponent(), withIntermediateDirectories: true)
            } else {
                // Preserve the old
                archiveOutputPath = parsedArguments.outputDirectory?.path ?? target.doccArchiveOutputPath(in: context)
                dependencyArchivePaths = []
            }
            
            if verbose {
                print("docc archive output path: '\(doccArchiveOutputPath)'")
            }
            
            // Use the parsed arguments gathered earlier to generate the necessary
            // arguments to pass to `docc`. ParsedArguments will merge the flags provided
            // by the user with default fallback values for required flags that were not
            // provided.
            let doccArguments = parsedArguments.doccArguments(
                action: .convert,
                targetKind: target.kind == .executable ? .executable : .library,
                doccCatalogPath: target.doccCatalogPath,
                targetName: target.name,
                symbolGraphDirectoryPath: symbolGraphs.unifiedSymbolGraphsDirectory.path,
                outputPath: archiveOutputPath,
                dependencyArchivePaths: dependencyArchivePaths
            )
            
            if verbose {
                let arguments = doccArguments.joined(separator: " ")
                print("docc invocation: '\(doccExecutableURL.path) \(arguments)'")
            }
            
            print("Converting documentation...")
            let conversionStartTime = DispatchTime.now()
            
            // Run `docc convert` with the generated arguments and wait until the process completes
            let process = try Process.run(doccExecutableURL, arguments: doccArguments)
            process.waitUntilExit()
            
            let conversionDuration = conversionStartTime.distance(to: .now())
            
            // Check whether the `docc convert` invocation was successful.
            if process.terminationReason == .exit && process.terminationStatus == 0 {
                print("Conversion complete! (\(conversionDuration.descriptionInSeconds))")
            } else {
                Diagnostics.error("'docc convert' invocation failed with a nonzero exit code: '\(process.terminationStatus)'")
            }
            
            return URL(fileURLWithPath: archiveOutputPath)
        }
        
        let buildGraphRunner = DocumentationBuildGraphRunner(buildGraph: .init(targets: swiftSourceModuleTargets))
        let documentationArchives = try buildGraphRunner.perform(performBuildTask)
            .compactMap { $0 }
            .sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
        
        guard let firstArchive = documentationArchives.first else {
            print("Didn't generate any documentation archives.")
            return
        }
        
        guard isCombinedDocumentationEnabled else {
            if documentationArchives.count > 1 {
                print("""
                Generated \(documentationArchives.count) documentation archives:
                  \(documentationArchives.map(\.path).joined(separator: "\n  "))
                """)
            } else {
                print("""
                Generated documentation archive at:
                  \(firstArchive.path)
                """)
            }
            return
        }
        
        // Merge the archives into a combined archive
        let combinedArchiveOutput: URL
        if let specifiedOutputLocation = parsedArguments.outputDirectory {
            combinedArchiveOutput = specifiedOutputLocation
        } else {
            let combinedArchiveName = "\(context.package.displayName.replacingWhitespaceAndPunctuation(with: "-")).doccarchive"
            combinedArchiveOutput = URL(fileURLWithPath: context.pluginWorkDirectory.appending(combinedArchiveName).string)
        }
        
        var mergeCommandArguments = ["merge"]
        mergeCommandArguments.append(contentsOf: documentationArchives.map(\.standardizedFileURL.path))
        mergeCommandArguments.append(contentsOf: [DocCArguments.outputPath.preferred, combinedArchiveOutput.path])
        
        // Remove the combined archive if it already exists
        try? FileManager.default.removeItem(at: combinedArchiveOutput)
        
        // Create a new combined archive
        let process = try Process.run(doccExecutableURL, arguments: mergeCommandArguments)
        process.waitUntilExit()
        
        print("""
        Generated combined documentation archive at:
          \(combinedArchiveOutput.path)
        """)
    }
}

// We add the conformance here so that 'DocumentationBuildGraphTarget' doesn't need to know about 'SwiftSourceModuleTarget' or import 'PackagePlugin'.
extension SwiftSourceModuleTarget: DocumentationBuildGraphTarget {
    var dependencyIDs: [String] {
        // List all the target dependencies in a flat list.
        dependencies.flatMap {
            switch $0 {
            case .target(let target):   return [target.id]
            case .product(let product): return product.targets.map { $0.id }
            @unknown default:           return []
            }
        }
    }
}

private extension String {
    func replacingWhitespaceAndPunctuation(with separator: String) -> String {
        let charactersToStrip = CharacterSet.whitespaces.union(.punctuationCharacters)
        return components(separatedBy: charactersToStrip).filter({ !$0.isEmpty }).joined(separator: separator)
    }
}
