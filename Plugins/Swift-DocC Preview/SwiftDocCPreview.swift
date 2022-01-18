// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
import PackagePlugin

/// Creates and previews a Swift-DocC documentation archive from a Swift Package.
@main struct SwiftDocCPreview: CommandPlugin {
    func performCommand(
        context: PluginContext,
        targets: [Target],
        arguments: [String]
    ) throws {
        // We'll be creating commands that invoke `docc`, so start by locating it.
        let doccExecutableURL = try context.doccExecutable
        
        // Parse the given command-line arguments
        let parsedArguments = ParsedArguments(arguments)
        
        // If the `--help` or `-h` flag was passed, print the plugin's help information
        // and exit.
        guard !parsedArguments.help else {
            let helpInfo = try HelpInformation.forAction(.preview, doccExecutableURL: doccExecutableURL)
            print(helpInfo)
            return
        }
        
        // Swift-DocC only supports Swift source modules; filter
        // out any incompatible targets.
        let possibleTargets = targets.compactMap(\.asSwiftSourceModuleTarget)
        
        // Confirm that at least one compatible target was provided.
        guard let target = possibleTargets.first else {
            Diagnostics.error("""
                None of the provided targets produce Swift-DocC documentation.
                
                Swift-DocC can produce documentation for Swift library and executable targets.
                """
            )
            
            return
        }
        
        // Swift-DocC is only able to preview a single target at a time.
        guard possibleTargets.count == 1 else {
            Diagnostics.error("""
                Multiple targets found that can produce Swift-DocC documentation.
                
                Swift-DocC is only able to preview a single target at a time. If your
                package contains more than one documentable target, you must specify which
                target should be previewed with the -target option.
                
                Compatible targets: \(possibleTargets.map(\.name)).
                """
            )
            
            return
        }
        
        // Ask SwiftPM to generate or update symbol graph files for the target.
        let symbolGraphInfo = try packageManager.getSymbolGraph(
            for: target,
            options: target.defaultSymbolGraphOptions(in: context.package)
        )
        
        // Use the parsed arguments gathered earlier to generate the necessary
        // arguments to pass to `docc`. ParsedArguments will merge the flags provided
        // by the user with default fallback values for required flags that were not
        // provided.
        let doccArguments = parsedArguments.doccArguments(
            action: .preview,
            targetKind: target.representsExecutable(in: context.package) ? .executable : .library,
            doccCatalogPath: target.doccCatalogPath,
            targetName: target.name,
            symbolGraphDirectoryPath: symbolGraphInfo.directoryPath.string,
            outputPath: target.doccArchiveOutputPath(in: context)
        )
        
        // Run `docc preview` with the generated arguments and wait until the process completes
        let process = try Process.run(doccExecutableURL, arguments: doccArguments)
        process.waitUntilExit()
        
        // Check whether the `docc preview` invocation was successful.
        guard process.terminationReason == .exit && process.terminationStatus == 0 else {
            Diagnostics.error("""
                'docc preview' invocation failed with a nonzero exit code: '\(process.terminationStatus)'.
                """
            )
            return
        }
    }
}
