// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

/// A documented command-line flag for the plugin.
///
/// This may include some flags that the plugin forwards to the symbol graph extract tool or to DocC.
struct DocumentedFlag {
    /// The positive names for this flag
    var names: CommandLineArgument.Names
    /// The possible negative names for this flag, if any.
    var inverseNames: CommandLineArgument.Names?
    
    /// A short user-facing description of this flag.
    var abstract: String
    
    /// An expanded user-facing description of this flag.
    var discussion: String?
}

// MARK: Plugin flags

extension DocumentedFlag {
    /// A plugin feature flag to enable building combined documentation for multiple targets.
    ///
    /// - Note: This flag requires that the `docc` executable supports ``Feature/linkDependencies``.
    static let enableCombinedDocumentationSupport = Self(
        names: ParsedPluginArguments.enableCombinedDocumentation,
        abstract: "Create a combined DocC archive with all generated documentation.",
        discussion: """
            Experimental feature that allows targets to link to pages in their dependencies and that \
            creates an additional "combined" DocC archive containing all the generated documentation.
            """
    )
    
    /// A plugin feature flag to skip adding the `--emit-lmdb-index` flag, that the plugin adds by default.
    static let disableIndex = Self(
        names: ParsedPluginArguments.disableLMDBIndex,
        abstract: "Disable indexing for the produced DocC archive.",
        discussion: """
            Produces a DocC archive that is best-suited for hosting online but incompatible with Xcode.
            """
    )
    
    /// A plugin feature flag to enable verbose logging.
    static let verbose = Self(
        names: ParsedPluginArguments.verbose,
        abstract: "Increase verbosity to include informational output.",
        discussion: nil
    )
    
    // We don't need to document the `--help` flag
}

// MARK: Symbol graph flags

extension DocumentedFlag {
    /// Include or exclude extended types in documentation archives.
    ///
    /// Enables/disables the extension block symbol format when calling the dump symbol graph API.
    ///
    /// - Note: This flag is only available starting from Swift 5.8. It should be hidden from the `--help` command for lower toolchain versions.
    /// However, we do not hide the flag entirely, because this enables us to give a more precise warning when accidentally used with Swift 5.7 or lower.
    static let extendedTypes = Self(
        names: ParsedSymbolGraphArguments.includeExtendedTypes,
        inverseNames: ParsedSymbolGraphArguments.excludeExtendedTypes,
        abstract: "Control whether extended types from other modules are shown in the produced DocC archive. (default: \(Self.defaultExtendedTypesValue))",
        discussion: "Allows documenting symbols that a target adds to its dependencies."
    )
    
    /// Exclude synthesized symbols from the generated documentation.
    ///
    /// `--experimental-skip-synthesized-symbols` produces a DocC archive without compiler-synthesized symbols.
    static let skipSynthesizedSymbols = Self(
        names: ParsedSymbolGraphArguments.skipSynthesizedSymbols,
        abstract: "Exclude synthesized symbols from the generated documentation.",
        discussion: """
            Experimental feature that produces a DocC archive without compiler synthesized symbols.
            """
    )
    
    /// The minimum access level that the symbol graph extractor will emit symbols for
    static let minimumAccessLevel = Self(
        names: ParsedSymbolGraphArguments.minimumAccessLevel,
        abstract: "Include symbols with this access level or more. (default: public)",
        discussion: """
            Supported access level values are: `open`, `public`, `internal`, `private`, `fileprivate`
            """
    )
    
#if swift(>=5.9)
    private static let defaultExtendedTypesValue = ParsedSymbolGraphArguments.includeExtendedTypes.preferred
#else
    private static let defaultExtendedTypesValue = ParsedSymbolGraphArguments.excludeExtendedTypes.preferred
#endif
}
