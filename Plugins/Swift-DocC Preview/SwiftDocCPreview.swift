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
    func performCommand(context: PluginContext, arguments: [String]) throws {
        // We'll be creating commands that invoke `docc`, so start by locating it.
        let doccExecutableURL = try context.doccExecutable
        
        var argumentExtractor = ArgumentExtractor(arguments)
        let specifiedTargets = try argumentExtractor.extractSpecifiedTargets(in: context.package)
        
        let possibleTargets: [SwiftSourceModuleTarget]
        if specifiedTargets.isEmpty {
            possibleTargets = context.package.topLevelDocumentableTargets
        } else {
            possibleTargets = specifiedTargets
        }
        
        let verbose = argumentExtractor.extractFlag(named: "verbose") > 0
        
        // Parse the given command-line arguments
        let parsedArguments = ParsedArguments(argumentExtractor.remainingArguments)
        
        // If the `--help` or `-h` flag was passed, print the plugin's help information
        // and exit.
        guard !parsedArguments.help else {
            let helpInfo = try HelpInformation.forAction(.preview, doccExecutableURL: doccExecutableURL)
            print(helpInfo)
            return
        }
        
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
                target should be previewed with the --target option.
                
                Compatible targets: \(context.package.compatibleTargets).
                """
            )
            
            return
        }
        
        let symbolGraphOptions = target.defaultSymbolGraphOptions(in: context.package)
        
        if verbose {
            print("symbol graph options: '\(symbolGraphOptions)'")
        }
        
        // Ask SwiftPM to generate or update symbol graph files for the target.
        let symbolGraphDirectoryPath = try packageManager.getSymbolGraph(
            for: target,
            options: symbolGraphOptions
        ).directoryPath.string
        
        if verbose {
            print("symbol graph directory path: '\(symbolGraphDirectoryPath)'")
        }
        
        if try FileManager.default.contentsOfDirectory(atPath: symbolGraphDirectoryPath).isEmpty {
            // This target did not produce any symbol graphs. Let's check if it has a
            // DocC catalog.
            
            guard target.doccCatalogPath != nil else {
                let message = """
                    '\(target.name)' does not contain any documentable symbols or a \
                    DocC catalog and will not produce documentation
                    """
                
                Diagnostics.error(message)
                return
            }
        }
        
        // Use the parsed arguments gathered earlier to generate the necessary
        // arguments to pass to `docc`. ParsedArguments will merge the flags provided
        // by the user with default fallback values for required flags that were not
        // provided.
        let doccArguments = parsedArguments.doccArguments(
            action: .preview,
            targetKind: target.kind == .executable ? .executable : .library,
            doccCatalogPath: target.doccCatalogPath,
            targetName: target.name,
            symbolGraphDirectoryPath: symbolGraphDirectoryPath,
            outputPath: target.doccArchiveOutputPath(in: context)
        )
        
        if verbose {
            let arguments = doccArguments.joined(separator: " ")
            print("docc invocation: '\(doccExecutableURL.path) \(arguments)'")
        }
        
        // Configure the `docc preview` process with the generated arguments
        let previewProcess = Process()
        previewProcess.executableURL = doccExecutableURL
        previewProcess.arguments = doccArguments
        
        
        func stopPreviewProcess() {
            #if os(macOS) && os(iOS) && os(tvOS) && os(watchOS)
            previewProcess.interrupt()
            #else
            // On non-Darwin systems, `docc` doesn't properly exit with just an interrupt signal
            // so send a SIGKILL instead.
            kill(previewProcess.processIdentifier, SIGKILL)
            #endif
        }
        
        // Monitor for a termination signal and pass any along to the child `docc` preview
        // process.
        //
        // Since Foundation's process does *not* create new processes with the same group ID
        // as the parent process, we don't expect this to happen automatically.
        signal(SIGTERM, SIG_IGN)
        let terminateSignalSource = DispatchSource.makeSignalSource(signal: SIGTERM)
        terminateSignalSource.setEventHandler {
            terminateSignalSource.cancel()
            stopPreviewProcess()
        }
        terminateSignalSource.resume()

        // Monitor for an interrupt signal and pass any along to the child `docc` preview
        // process
        signal(SIGINT, SIG_IGN)
        let interruptSignalSource = DispatchSource.makeSignalSource(signal: SIGINT)
        interruptSignalSource.setEventHandler {
            interruptSignalSource.cancel()
            stopPreviewProcess()
        }
        interruptSignalSource.resume()
        
        // Run the docc preview process and wait until it exits.
        try previewProcess.run()
        previewProcess.waitUntilExit()
        
        // Check whether the `docc preview` invocation was successful.
        guard previewProcess.terminationReason == .exit && previewProcess.terminationStatus == 0 else {
            Diagnostics.error("""
                'docc preview' invocation failed with a nonzero exit code: '\(previewProcess.terminationStatus)'.
                
                Note: The Swift-DocC Preview plugin requires passing the '--disable-sandbox' flag
                to the Swift Package Manager because it requires local network access to
                run a local web server. See 'swift package plugin preview-documentation --help' for details.
                """
            )
            
            return
        }
    }
}
