// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

/// Parsed command-line arguments.
public struct ParsedArguments {
    /// The underlying set of raw string arguments for this set of parsed arguments.
    public let arguments: Arguments
    
    /// A Boolean value that is true if the parsed arguments indicate that a help message
    /// should be printed.
    ///
    /// This is determined by looking for the `--help` and `-h` flags.
    public var help: Bool {
        return arguments.contains("--help") || arguments.contains("-h")
    }
    
    /// Returns the arguments that should be passed to `docc` to invoke the given plugin action.
    ///
    /// Merges the arguments provided upon initialization of the parsed arguments that are relevant
    /// to `docc` with default fallback values for required options that were not provided.
    ///
    /// For example, if ParsedArguments is initialized like so:
    ///
    /// ```swift
    /// let parsedArguments = ParsedArguments(
    ///     [
    ///         "--fallback-display-name", "custom-display-name",
    ///         "--transform-for-static-hosting",
    ///     ]
    /// )
    /// ```
    ///
    /// You can expect the `doccArguments` function to behave like this:
    ///
    /// ```swift
    /// let doccArguments = parsedArguments.doccArguments(
    ///     action: .convert,
    ///     targetKind: .library,
    ///     doccCatalogPath: "/my/catalog.docc",
    ///     targetName: "MyTarget",
    ///     symbolGraphDirectoryPath: "/my/symbol-graph",
    ///     outputPath: "/my/output-path"
    /// )
    ///
    /// print(doccArguments)
    ///
    /// /*
    ///    [
    ///        "convert",
    ///        "/my/catalog.docc",
    ///        "--fallback-display-name", "custom-display-name",
    ///        "--transform-for-static-hosting",
    ///        "--fallback-bundle-identifier", "MyTarget",
    ///        "--additional-symbol-graph-dir", "/my/symbol-graph",
    ///        "--output-path", "/my/output-path"
    ///    ]
    /// */
    /// ```
    ///
    /// The returned `doccArguments` can now be passed to a `docc` executable to
    /// produce documentation for the described target with the given custom options.
    ///
    /// - Parameters:
    ///   - action: The `docc` plugin action that will be invoked.
    ///
    ///   - targetKind: The kind of target being built.
    ///
    ///     For example, this could be a library or an executable.
    ///
    ///   - doccCatalogPath: The docc catalog that should be passed to `docc`, if any.
    ///
    ///   - targetName: The name of the target being described.
    ///
    ///     Used as a fallback value for the required bundle identifier and display name options.
    ///
    ///   - symbolGraphDirectoryPath: Path to the directory containing symbol graph files that
    ///     should be passed to `docc`.
    ///
    ///   - outputPath: The location where `docc` should emit the resulting DocC archive.
    public func doccArguments(
        action: PluginAction,
        targetKind: DocumentationTargetKind,
        doccCatalogPath: String?,
        targetName: String,
        symbolGraphDirectoryPath: String,
        outputPath: String
    ) -> Arguments {
        var doccArguments = arguments.filter(for: .docc)
        
        // Iterate through the flags required for the `docc` invocation
        // and append any that are not already present.
        for requiredFlag in Self.requiredFlags {
            guard !doccArguments.contains(requiredFlag) else {
                continue
            }
            
            doccArguments.append(requiredFlag)
        }
        
        // Build up an array of required command line options by iterating through
        // the options that are required by `docc` and setting their default
        // value based on the given context for this invocation.
        let requiredOptions = Self.requiredOptions.compactMap { option -> RequiredCommandLineOption? in
            let optionValue: String
            switch option {
            case .fallbackDisplayName:
                optionValue = targetName
            case .fallbackBundleIdentifier:
                optionValue = targetName
            case .additionalSymbolGraphDirectory:
                optionValue = symbolGraphDirectoryPath
            case .outputPath:
                optionValue = outputPath
            default:
                // This will throw an assertion when running in tests but allow us to fail
                // gracefully when running in production.
                assertionFailure("Unexpected required option: '\(option)'.")
                return nil
            }
            
            return RequiredCommandLineOption(option, defaultValue: optionValue)
        }
        
        // Now that we've formed an array of required command line options, along with
        // their default values, insert them into the existing set of arguments if
        // they haven't already been specified.
        for requiredOption in requiredOptions {
            doccArguments = requiredOption.insertIntoArgumentsIfMissing(doccArguments)
        }
        
        // Add any required options that are specific to the kind of target being built
        doccArguments = targetKind.addRequiredOptions(to: doccArguments)
        
        // Apply any argument transformations. This allows for custom
        // flags that are specific to the plugin and not built-in to `docc`.
        for argumentsTransformer in Self.argumentsTransformers {
            doccArguments = argumentsTransformer.transform(doccArguments)
        }
        
        // If we were given a catalog path, prepend it to the set of arguments.
        if let doccCatalogPath = doccCatalogPath {
            doccArguments = [doccCatalogPath] + doccArguments
        }
        
        return [action.rawValue] + doccArguments
    }
    
    /// Creates a new set of parsed arguments with the given arguments.
    public init(_ arguments: [String]) {
        self.arguments = arguments
        
        let symbolGraphArguments = arguments.filter(for: .dumpSymbolGraph)
        
        self.symbolGraphArguments = ParsedArguments.ArgumentConsumer.dumpSymbolGraph.flags.compactMap {
            $0.value(for: symbolGraphArguments)
        }
    }
    
    // Build array with plugin flags that modify the symbol graph generation,
    // filtering from the available custom symbol graph options those
    // that correspond to the received flags
    var symbolGraphArguments: [PluginFlag]
    
    /// The command-line options required by the `docc` tool.
    private static let requiredOptions: [CommandLineOption] = [
        .fallbackDisplayName,
        .fallbackBundleIdentifier,
        .additionalSymbolGraphDirectory,
        .outputPath,
    ]
    
    /// The command-line flags required by the `docc` tool.
    private static let requiredFlags = [
        "--emit-lmdb-index",
    ]
    
    private static let argumentsTransformers: [ArgumentsTransforming] = [
        PluginFlag.disableIndex,
        PluginFlag.extendedTypes,
        PluginFlag.skipSynthesizedSymbols
    ]
}

private extension ParsedArguments {
    enum ArgumentConsumer: CaseIterable {
        /// The `docc` command
        case docc
        /// The `swift package dump-symbol-graph` command
        case dumpSymbolGraph
        
        /// Returns the flags applicable to an `ArgumentConsumer`.
        ///
        /// If `flags.isEmpty` is `true`, this `ArgumentConsumer` is assumed to
        /// consume all flags not consumed by any of the other `ArgumentConsumer`s.
        var flags: [PluginFlag] {
            switch self {
            case .dumpSymbolGraph:
                return [
                    PluginFlag.extendedTypes,
                    PluginFlag.skipSynthesizedSymbols
                ]
            case .docc:
                return []
            }
        }
    }
}

private extension Arguments {
    /// Returns the subset of arguments which are applicable to the given `consumer`.
    func filter(for consumer: ParsedArguments.ArgumentConsumer) -> Arguments {
        if !consumer.flags.isEmpty {
            // If the consumer can provide a complete list of valid flags,
            // we only include elements that are included in one of these flags'
            // `parsedValues`, i.e. if one of these flags can be applied to the
            // element.
            let flagsToInclude = consumer.flags
            return self.filter { argument in
                flagsToInclude.contains(where: { flag in
                    flag.parsedValues.contains(argument)
                })
            }
        } else {
            // If the consumer cannot provide a complete list of valid flags, (which
            // should only happen for the `.docc` case) we return all elements
            // that are not applicable to any of the other `ArgumentConsumer`s.
            let flagsToExclude = ParsedArguments.ArgumentConsumer.allCases.flatMap(\.flags)
            return self.filter { argument in
                !flagsToExclude.contains(where: { flag in
                    flag.parsedValues.contains(argument)
                })
            }
        }
    }
}
