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
        
        let sourceModuleTargets: [SourceModuleTarget]
        if specifiedTargets.isEmpty {
            sourceModuleTargets = context.package.allDocumentableTargets
        } else {
            sourceModuleTargets = specifiedTargets
        }
        
        guard !sourceModuleTargets.isEmpty else {
            throw ArgumentParsingError.packageDoesNotContainSourceModuleTargets
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
        
        let doccFeatures = try? DocCFeatures(doccExecutable: doccExecutableURL)
        if isCombinedDocumentationEnabled, doccFeatures?.contains(.linkDependencies) == false {
            // The developer uses the combined documentation plugin flag with a DocC version that doesn't support combined documentation.
            Diagnostics.error("""
            Unsupported use of '\(DocumentedFlag.enableCombinedDocumentation.names.preferred)'. \
            DocC version at '\(doccExecutableURL.path)' doesn't support combined documentation.
            """)
            return
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
        
        let intermediateArchivesDirectory = URL(fileURLWithPath: context.pluginWorkDirectory.appending("intermediates").string)
        try? FileManager.default.createDirectory(at: intermediateArchivesDirectory, withIntermediateDirectories: true)
        
        // An inner function that defines the work to build documentation for a given target.
        func performBuildTask(_ task: DocumentationBuildGraph<SourceModuleDocumentationBuildGraphTarget>.Task) throws -> URL? {
            let target = task.target
            print("Extracting symbol information for '\(target.name)'...")
            let symbolGraphGenerationStartTime = DispatchTime.now()
            
            let symbolGraphs = try packageManager.doccSymbolGraphs(
                for: target.sourceTarget,
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
                
                if sourceModuleTargets.count > 1 {
                    // We're building multiple targets, just emit a warning for this
                    // one target that does not produce documentation.
                    Diagnostics.warning(message)
                } else {
                    // This is the only target being built so emit an error
                    Diagnostics.error(message)
                }
                return nil
            }
            
            print("Finished extracting symbol information for '\(target.name)'. (\(symbolGraphGenerationStartTime.distance(to: .now()).descriptionInSeconds))")
            
            // Use an an intermediate output location for each target to avoid targets writing to the same location.
            // When all targets have finished building successfully, the command will move the archives into the final output location.
            func archiveOutputDir(for target: Target) -> String {
                intermediateArchivesDirectory.appendingPathComponent("\(target.name).doccarchive", isDirectory: true).path
            }
            
            let archiveOutputPath = archiveOutputDir(for: target.sourceTarget)
            let dependencyArchivePaths: [String] = isCombinedDocumentationEnabled ? task.dependencies.map { archiveOutputDir(for: $0.target.sourceTarget) } : []
            
            if verbose {
                print("documentation archive output path: '\(archiveOutputPath)'")
            }
            
            // Use the parsed arguments gathered earlier to generate the necessary
            // arguments to pass to `docc`. ParsedArguments will merge the flags provided
            // by the user with default fallback values for required flags that were not
            // provided.
            let doccArguments = parsedArguments.doccArguments(
                action: .convert,
                targetKind: target.sourceTarget.kind == .executable ? .executable : .library,
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
            
            print("Building documentation for '\(target.name)'...")
            let conversionStartTime = DispatchTime.now()
            
            // Run `docc convert` with the generated arguments and wait until the process completes
            let process = try Process.run(doccExecutableURL, arguments: doccArguments)
            process.waitUntilExit()
            
            // Check whether the `docc convert` invocation was successful.
            if process.terminationReason == .exit && process.terminationStatus == 0 {
                print("Finished building documentation for '\(target.name)' (\(conversionStartTime.distance(to: .now()).descriptionInSeconds))")
            } else {
                Diagnostics.error("'docc convert' invocation failed with a nonzero exit code: '\(process.terminationStatus)'")
            }
            
            return URL(fileURLWithPath: archiveOutputPath)
        }
        
        let buildGraphRunner = DocumentationBuildGraphRunner(buildGraph: .init(targets: sourceModuleTargets.map( {SourceModuleDocumentationBuildGraphTarget(sourceTarget: $0)})))
        let intermediateDocumentationArchives = try buildGraphRunner.perform(performBuildTask)
            .compactMap { $0 }
        
        guard let firstIntermediateArchive = intermediateDocumentationArchives.first else {
            print("Didn't generate any documentation archives.")
            return
        }
        
        guard isCombinedDocumentationEnabled else {
            // Move the intermediate archives into their final output location(s).
            let defaultPluginOutputDirectory = URL(fileURLWithPath: context.pluginWorkDirectory.string)
            if intermediateDocumentationArchives.count > 1 {
                // If the developer built more than one target, move each target into a _subdirectory_ of the output directory.
                let outputDirectory = parsedArguments.outputDirectory ?? defaultPluginOutputDirectory
                try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: false)
                
                let archiveLocations = intermediateDocumentationArchives
                    .map { outputDirectory.appendingPathComponent($0.lastPathComponent, isDirectory: true) }
                
                for (from, to) in zip(intermediateDocumentationArchives, archiveLocations) {
                    try? FileManager.default.removeItem(at: to)
                    try FileManager.default.moveItem(at: from, to: to)
                }
                
                print("""
                Generated \(archiveLocations.count) documentation archives:
                  \(archiveLocations.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }).map(\.standardizedFileURL.path).joined(separator: "\n  "))
                """)
            } else {
                let archiveLocation: URL
                if let specifiedOutputLocation = parsedArguments.outputDirectory {
                    // If the developer only built one target and specified an output directory, move the only archive's content into that directory.
                    archiveLocation = specifiedOutputLocation
                } else {
                    // Otherwise, make a new subdirectory for the archive inside the plugin's default output directory
                    archiveLocation = defaultPluginOutputDirectory.appendingPathComponent(firstIntermediateArchive.lastPathComponent, isDirectory: true)
                }
                
                try? FileManager.default.removeItem(at: archiveLocation)
                try FileManager.default.moveItem(at: firstIntermediateArchive, to: archiveLocation)
                print("""
                Generated documentation archive at:
                  \(archiveLocation.standardizedFileURL.path)
                """)
            }
            return
        }
        
        // Merge the intermediate archives into a combined archive
        
        let combinedArchiveOutput: URL
        if let specifiedOutputLocation = parsedArguments.outputDirectory {
            combinedArchiveOutput = specifiedOutputLocation
        } else {
            let combinedArchiveName = "\(context.package.displayName.replacingWhitespaceAndPunctuation(with: "-")).doccarchive"
            combinedArchiveOutput = URL(fileURLWithPath: context.pluginWorkDirectory.appending(combinedArchiveName).string)
        }
        
        var mergeCommandArguments = ["merge"]
        mergeCommandArguments.append(contentsOf: intermediateDocumentationArchives.map(\.standardizedFileURL.path))
        mergeCommandArguments.append(contentsOf: [DocCArguments.outputPath.names.preferred, combinedArchiveOutput.path])
        
        if let doccFeatures, doccFeatures.contains(.synthesizedLandingPageName) {
            mergeCommandArguments.append(contentsOf: [DocCArguments.synthesizedLandingPageName.names.preferred, context.package.displayName])
            mergeCommandArguments.append(contentsOf: [DocCArguments.synthesizedLandingPageKind.names.preferred, "Package"])
        }
        
        // Remove the combined archive if it already exists
        try? FileManager.default.removeItem(at: combinedArchiveOutput)
        
        // Create a new combined archive
        let process = try Process.run(doccExecutableURL, arguments: mergeCommandArguments)
        process.waitUntilExit()
        
        print("""
        Generated combined documentation archive at:
          \(combinedArchiveOutput.standardizedFileURL.path)
        """)
    }
}

// We add the conformance here so that 'DocumentationBuildGraphTarget' doesn't need to know about 'SourceModuleTarget' or import 'PackagePlugin'.
struct SourceModuleDocumentationBuildGraphTarget: DocumentationBuildGraphTarget {
    var sourceTarget: SourceModuleTarget

    var dependencyIDs: [String] {
        // List all the target dependencies in a flat list.
        sourceTarget.dependencies.flatMap {
            switch $0 {
            case .target(let target):   return [target.id]
            case .product(let product): return product.targets.map { $0.id }
            @unknown default:           return []
            }
        }
    }

    var id: String {
        sourceTarget.id
    }

    var name: String {
        sourceTarget.name
    }

    var doccCatalogPath: String? {
        sourceTarget.doccCatalogPath
    }
}

private extension String {
    func replacingWhitespaceAndPunctuation(with separator: String) -> String {
        let charactersToStrip = CharacterSet.whitespaces.union(.punctuationCharacters)
        return components(separatedBy: charactersToStrip).filter({ !$0.isEmpty }).joined(separator: separator)
    }
}
