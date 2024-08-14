// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022-2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation

/// Provides help information for the Swift-DocC plugins.
public enum HelpInformation {
    /// A closure that when called with a plugin action and URL, returns the help information for the given
    /// action.
    ///
    /// This is defined as a static variable to allow for mocking in tests.
    static var _doccHelp: (PluginAction, URL) throws -> (String?) = { pluginAction, doccExecutableURL in
        try Process.runAndCaptureOutput(
            doccExecutableURL,
            arguments: [
                pluginAction.rawValue,
                "--help"
            ]
        )
    }
    
    /// Returns the help text for the given plugin action.
    ///
    /// Uses the provided docc executable URL to invoke `docc` and
    /// merge its help information with the plugin action's. This ensures that the help information
    /// for possible options that can be passed to `docc` is always up-to-date.
    ///
    /// - Parameters:
    ///   - pluginAction: The plugin action that will be described.
    ///   - doccExecutableURL: The docc executable URL that should be used to gather
    ///     possible command-line options.
    public static func forAction(_ pluginAction: PluginAction, doccExecutableURL: URL) throws -> String {
        var helpText: String
        switch pluginAction {
        case .convert:
            helpText = convertPluginHelpOverview
        case .preview:
            helpText = previewPluginHelpOverview
        }
        
        var supportedPluginFlags = [
            DocumentedFlag.disableIndex,
            DocumentedFlag.verbose,
        ]
        
        let doccFeatures = (try? DocCFeatures(doccExecutable: doccExecutableURL)) ?? .init()
        if doccFeatures.contains(.linkDependencies) {
            supportedPluginFlags.insert(DocumentedFlag.enableCombinedDocumentationSupport, at: 1)
        }
        
        for flag in supportedPluginFlags {
            helpText += flag.helpDescription
        }
        
        helpText += "\nSYMBOL GRAPH OPTIONS:\n"
        var supportedSymbolGraphFlags = [
            DocumentedFlag.skipSynthesizedSymbols,
            DocumentedFlag.minimumAccessLevel,
        ]
#if swift(>=5.8)
        supportedSymbolGraphFlags.insert(DocumentedFlag.extendedTypes, at: 1)
#else
        // stops 'not mutated' warning for Swift 5.7 and lower
        supportedPluginFlags += []
#endif
        
        for flag in supportedSymbolGraphFlags {
            helpText += flag.helpDescription
        }
        
        if let doccHelp = try _doccHelp(pluginAction, doccExecutableURL) {
            let doccHelpOptions = doccHelp.components(separatedBy: "\n\n")
                .drop(while: { !$0.hasPrefix("USAGE: ")})
                .dropFirst()
            
            helpText = helpText.trimmingCharacters(in: .newlines) + doccHelpOptions.map { 
                // Join the DocC Options again and prefix each options group with DOCC to separate them from the plugin options
                "\n\n" + ($0.first?.isLetter == true ? "DOCC " : "") + $0
            }.joined()
        }
        
        return helpText.trimmingCharacters(in: .newlines) + "\n"
    }

    private static var convertPluginHelpOverview = """
        OVERVIEW: Creates a Swift-DocC documentation archive from a Swift Package.

        USAGE: swift package [<package-manager-option>] generate-documentation [<plugin-options>] [<docc-options>]
        
        PACKAGE MANAGER OPTIONS:
          --allow-writing-to-package-directory
                                  Allow the plugin to write to the package directory.
          --allow-writing-to-directory <directory-path>
                                  Allow the plugin to write to an additional directory.

        PLUGIN OPTIONS:
          --target <target>       Generate documentation for the specified target.
          --product <product>     Generate documentation for the specified product.
        
        """

    private static var previewPluginHelpOverview = """
        OVERVIEW: Creates and previews a Swift-DocC documentation archive from a Swift Package.

        USAGE: swift package --disable-sandbox [<package-manager-option>] preview-documentation [<plugin-options>] [<docc-options>]
        
        NOTE: This plugin is only able to preview a single target at a time. If your
              package contains more than one documentable target, you must specify which
              target should be previewed with the --target or --product option.
        
        PACKAGE MANAGER OPTIONS:
          --disable-sandbox       Disable using the sandbox when executing subprocesses.
                This flag is **required** when previewing documentation because Swift-DocC
                preview requires local network access to run a local web server.
          --allow-writing-to-package-directory
                                  Allow the plugin to write to the package directory.
          --allow-writing-to-directory <directory-path>
                                  Allow the plugin to write to an additional directory.
        
        PLUGIN OPTIONS:
          --target <target>       Preview documentation for the specified target.
          --product <product>     Preview documentation for the specified product.
        
        """
}

private extension DocumentedFlag {
    var helpDescription: String {
        var flagListText = names.listForHelpDescription
        if let inverseNames {
            flagListText += " / \(inverseNames.listForHelpDescription)"
        }
        
        var description = if flagListText.count < 23 {
            // The flag is short enough to fit the abstract on the same line
            """
              \(flagListText.padding(toLength: 23, withPad: " ", startingAt: 0)) \(abstract)
            
            """
        } else {
            // The flag is too long to fit the abstract on the same line
            """
              \(flagListText)
                                      \(abstract)
            
            """
        }
        if let discussion {
            description += """
                    \(discussion)
            
            """
        }
        
        return description
    }
}

private extension CommandLineArgument.Names {
    var listForHelpDescription: String {
        ([preferred] + all.subtracting([preferred]).sorted()).joined(separator: ", ")
    }
}

private extension Process {
    /// Creates and runs a task with the given url and arguments, and returns the process output.
    ///
    /// This helper is only intended for short running calls with known bound output.
    /// Long running tasks or tasks with possibly unbounded output should read data
    /// incrementally via the `readabilityHandler` instead.
    static func runAndCaptureOutput(_ url: URL, arguments: [String]) throws -> String? {
        let process = Process()
        process.executableURL = url
        process.arguments = arguments
        
        let outputPipe = Pipe()
        
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        
        try process.run()
        process.waitUntilExit()
        
        return try outputPipe.fileHandleForReading.readToEnd().flatMap {
            String(data: $0, encoding: .utf8)
        }
    }
}

