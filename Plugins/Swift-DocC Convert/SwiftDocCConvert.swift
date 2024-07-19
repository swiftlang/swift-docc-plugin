// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
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
        
        let sourceModuleTargets: [any SourceModuleTarget]
        if specifiedTargets.isEmpty {
            sourceModuleTargets = context.package.allDocumentableTargets
        } else {
            sourceModuleTargets = specifiedTargets
        }
        
        guard !sourceModuleTargets.isEmpty else {
            throw ArgumentParsingError.packageDoesNotContainSourceModuleTargets
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
        
        
        // Iterate over the Swift source module targets we were given.
        for (index, target) in sourceModuleTargets.enumerated() {
            if index != 0 {
                // Emit a line break if this is not the first target being built.
                print()
            }
            
            print("Generating documentation for '\(target.name)'...")
            
            let symbolGraphs = try packageManager.doccSymbolGraphs(
                for: target,
                context: context,
                verbose: verbose,
                snippetExtractor: snippetExtractor,
                customSymbolGraphOptions: parsedArguments.symbolGraphArguments
            )
            
            if try FileManager.default.contentsOfDirectory(atPath: symbolGraphs.targetSymbolGraphsDirectory.path).isEmpty {
                // This target did not produce any symbol graphs. Let's check if it has a
                // DocC catalog.
                
                guard target.doccCatalogPath != nil else {
                    let message = """
                        '\(target.name)' does not contain any documentable symbols or a \
                        DocC catalog and will not produce documentation
                        """
                    
                    if sourceModuleTargets.count > 1 {
                        // We're building multiple targets, just throw a warning for this
                        // one target that does not produce documentation.
                        Diagnostics.warning(message)
                        continue
                    } else {
                        // This is the only target being built so throw an error
                        Diagnostics.error(message)
                        return
                    }
                }
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
                Diagnostics.error("""
                    'docc convert' invocation failed with a nonzero exit code: '\(process.terminationStatus)'
                    """
                )
            }
        }
        
        if sourceModuleTargets.count > 1 {
            print("\nMultiple DocC archives generated at '\(context.pluginWorkDirectory.string)'")
        }
    }
}
