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
        enableCombinedDocumentation = arguments.extractFlag(named: Self.enableCombinedDocumentation).last ?? false
        disableLMDBIndex = arguments.extractFlag(named: Self.disableLMDBIndex).last ?? false
        verbose          = arguments.extractFlag(named: Self.verbose).last          ?? false
        help             = arguments.extractFlag(named: Self.help).last             ?? false
    }
    
    /// A plugin feature flag to enable building combined documentation for multiple targets.
    static let enableCombinedDocumentation = CommandLineArgument.Names(
        preferred: "--enable-experimental-combined-documentation"
    )
    
    /// A plugin feature flag to skip adding the `--emit-lmdb-index` flag, that the plugin adds by default.
    static let disableLMDBIndex = CommandLineArgument.Names(
        preferred: "--disable-indexing", alternatives: ["--no-indexing"]
    )
    
    /// A plugin feature flag to enable verbose logging.
    static let verbose = CommandLineArgument.Names(
        preferred: "--verbose"
    )
    
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
        minimumAccessLevel     = arguments.extractOption(named: Self.minimumAccessLevel).last
        skipSynthesizedSymbols = arguments.extractFlag(named: Self.skipSynthesizedSymbols).last
        includeExtendedTypes   = arguments.extractFlag(named: Self.includeExtendedTypes, inverseNames: Self.excludeExtendedTypes).last
    }
    
    /// The minimum access level that the symbol graph extractor will emit symbols for.
    static let minimumAccessLevel = CommandLineArgument.Names(
        preferred: "--symbol-graph-minimum-access-level"
    )
    
    /// The feature flag to omit synthesized symbols when extracting symbol information.
    static let skipSynthesizedSymbols = CommandLineArgument.Names(
        preferred: "--experimental-skip-synthesized-symbols"
    )
    
    /// A pair of positive and negative feature flags to either include or exclude extended types when extracting symbol information.
    static let includeExtendedTypes = CommandLineArgument.Names(
        preferred: "--include-extended-types"
    )
    static let excludeExtendedTypes = CommandLineArgument.Names(
        preferred: "--exclude-extended-types"
    )
}
