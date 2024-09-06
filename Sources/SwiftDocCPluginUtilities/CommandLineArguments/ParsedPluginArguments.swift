// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation

/// A container of parsed values for the command line arguments that apply to the plugin itself.
struct ParsedPluginArguments {
    var enableCombinedDocumentation: Bool
    var disableLMDBIndex: Bool
    var verbose: Bool
    var help: Bool
    
    /// Creates a new plugin arguments container by extracting the known plugin values from a command line argument list.
    init(extractingFrom arguments: inout CommandLineArguments) {
        enableCombinedDocumentation = arguments.extractFlag(.enableCombinedDocumentation) ?? false
        disableLMDBIndex = arguments.extractFlag(.disableLMDBIndex)     ?? false
        verbose          = arguments.extractFlag(.verbose)              ?? false
        help             = arguments.extractFlag(named: Self.help).last ?? false
    }
    
    /// A common command line tool flag to print the help text instead of running the command.
    static let help = CommandLineArgument.Names(
        preferred: "--help", alternatives: ["-h"]
    )
}

/// A container of parsed values for the command line arguments that apply to symbol graph extraction.
struct ParsedSymbolGraphArguments {
    // The default values for these are only known within the plugin itself.
    var minimumAccessLevel: String?
    var skipSynthesizedSymbols: Bool?
    var includeExtendedTypes: Bool?
    
    /// Creates a new symbol graph arguments container by extracting the known plugin values from a command line argument list.
    init(extractingFrom arguments: inout CommandLineArguments) {
        minimumAccessLevel     = arguments.extractOption(.minimumAccessLevel)
        skipSynthesizedSymbols = arguments.extractFlag(.skipSynthesizedSymbols)
        includeExtendedTypes   = arguments.extractFlag(.extendedTypes)
    }
}

private extension CommandLineArguments {
    mutating func extractFlag(_ flag: DocumentedFlag) -> Bool? {
        extractFlag(named: flag.names, inverseNames: flag.inverseNames).last
    }
    
    mutating func extractOption(_ flag: DocumentedFlag) -> String? {
        extract(.init(flag.names)).last
    }
}
