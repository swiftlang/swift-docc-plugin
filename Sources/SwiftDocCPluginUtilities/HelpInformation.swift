// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
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
        
        let supportedPluginFlags = [
            PluginFlag.disableIndex,
        ]
        
        helpText += """
            
            PLUGIN OPTIONS:
            
            """
        
        for flag in supportedPluginFlags {
            helpText += """
                  \(flag.parsedValues.sorted().joined(separator: ", "))
                                          \(flag.abstract)
                        \(flag.description)
                
                """
        }
        
        let doccHelp = try _doccHelp(pluginAction, doccExecutableURL)
        
        if let doccOptions = doccHelp?.components(separatedBy: "OPTIONS:\n").last {
            helpText += """

                DOCC OPTIONS:
                \(doccOptions)
                """
        }
        
        return helpText
    }

    private static var convertPluginHelpOverview = """
        OVERVIEW: Creates a Swift-DocC documentation archive from a Swift Package.

        USAGE: swift package [--target <target>] generate-documentation [<plugin-options> <docc-options>]

        """

    private static var previewPluginHelpOverview = """
        OVERVIEW: Creates and previews a Swift-DocC documentation archive from a Swift Package.

        USAGE: swift package [--target <target>] preview-documentation [<plugin-options> <docc-options>]

        NOTE: This plugin is only able to preview a single target at a time. If your
              package contains more than one documentable target, you must specify which
              target should be previewed with the -target option.
        
        """
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

