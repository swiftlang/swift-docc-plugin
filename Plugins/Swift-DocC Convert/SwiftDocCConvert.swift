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
        
        let verbose = argumentExtractor.extractFlag(named: "verbose") > 0
        
        // Parse the given command-line arguments
        let parsedArguments = ParsedArguments(argumentExtractor.remainingArguments)
        
        // If the `--help` or `-h` flag was passed, print the plugin's help information
        // and exit.
        guard !parsedArguments.help else {
            let helpInformation = try HelpInformation.forAction(
                .convert,
                doccExecutableURL: doccExecutableURL
            )
            
            print(helpInformation)
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
            let doccArchiveOutputPath = target.doccArchiveOutputPath(in: context)
            
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
                outputPath: doccArchiveOutputPath
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
                
                let describedOutputPath = doccArguments.outputPath ?? "unknown location"
                print("Generated DocC archive at '\(describedOutputPath)'")
            } else {
                Diagnostics.error("'docc convert' invocation failed with a nonzero exit code: '\(process.terminationStatus)'")
            }
            
            return URL(fileURLWithPath: doccArchiveOutputPath)
        }
        
        // Create a build graph for all the documentation build tasks.
        let buildGraph = DocumentationBuildGraph(targets: swiftSourceModuleTargets)
        // Create a serial queue to perform each documentation build task
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        // Operations can't raise errors. Instead we catch the error from 'performBuildTask(_:)'
        // and cancel the remaining tasks.
        let resultLock = NSLock()
        var caughtError: Error?
        var documentationArchives: [URL] = []
        
        let operations = buildGraph.makeOperations { [performBuildTask] task in
            do {
                if let archive = try performBuildTask(task) {
                    resultLock.withLock {
                        documentationArchives.append(archive)
                    }
                }
            } catch {
                resultLock.withLock {
                    caughtError = error
                    queue.cancelAllOperations()
                }
            }
        }
        // If any of the build tasks raised an error. Rethrow that error.
        if let caughtError {
            throw caughtError
        }
        
        // Run all the documentation build tasks in reverse dependency order (dependencies before dependents).
        queue.addOperations(operations, waitUntilFinished: true)
            
        if documentationArchives.count > 1 {
            print("""
            Generated \(documentationArchives.count) DocC archives in '\(context.pluginWorkDirectory.string)':
              \(documentationArchives.map(\.lastPathComponent).sorted().joined(separator: "\n  "))
            """)
        }
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
