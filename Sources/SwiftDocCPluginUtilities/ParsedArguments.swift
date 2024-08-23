// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022-2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation

/// Parsed command-line arguments.
struct ParsedArguments {
    private var arguments: CommandLineArguments
    
    /// Creates a new collection of parsed arguments from the given raw arguments.
    init(_ rawArguments: [String]) {
        var arguments = CommandLineArguments(rawArguments)
        
        outputDirectory = arguments.extractOption(named: DocCArguments.outputPath).last.map {
            URL(fileURLWithPath: $0, isDirectory: true).standardizedFileURL
        }
        
        pluginArguments      = .init(extractingFrom: &arguments)
        symbolGraphArguments = .init(extractingFrom: &arguments)
        
        assert(arguments.extractOption(named: DocCArguments.outputPath).isEmpty,
               "There shouldn't be any output path argument left in the remaining DocC arguments.")
        self.arguments = arguments
    }
    
    /// The parsed plugin arguments.
    var pluginArguments: ParsedPluginArguments
    
    /// The parsed symbol graph arguments.
    var symbolGraphArguments: ParsedSymbolGraphArguments
    
    /// The location where the plugin should write the output documentation archive(s).
    var outputDirectory: URL?
    
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
    ///   - action: The `docc` action to construct arguments for.
    ///   - targetKind: The kind of target (`library` or `executable`) being built.
    ///   - doccCatalogPath: The path to the documentation catalog for this target, if any.
    ///   - targetName: The name of the target being being built.
    ///   - symbolGraphDirectoryPath: A path to a directory containing symbol graph files for this target.
    ///   - outputPath: The location where `docc` should write the resulting documentation archive.
    ///   - dependencyArchivePaths: A list of paths for this target's dependencies' already-built documentation archives.
    func doccArguments(
        action: PluginAction,
        targetKind: DocumentationTargetKind,
        doccCatalogPath: String?,
        targetName: String,
        symbolGraphDirectoryPath: String,
        outputPath: String,
        dependencyArchivePaths: [String] = []
    ) -> [String] {
        var arguments = self.arguments
        
        if !pluginArguments.disableLMDBIndex {
            arguments.insertIfMissing(.flag(DocCArguments.emitLMDBIndex))
        }
        
        arguments.insertIfMissing(.option(DocCArguments.fallbackDisplayName, value: targetName))
        arguments.insertIfMissing(.option(DocCArguments.fallbackBundleIdentifier, value: targetName))
        
        arguments.insertIfMissing(.option(DocCArguments.additionalSymbolGraphDirectory, value: symbolGraphDirectoryPath))
        arguments.insertIfMissing(.option(DocCArguments.outputPath, value: outputPath))
        
        if pluginArguments.enableCombinedDocumentation {
            arguments.insertIfMissing(.flag(DocCArguments.enableExternalLinkSupport))
            
            for dependencyArchivePath in dependencyArchivePaths {
                arguments.insertIfMissing(.option(DocCArguments.externalLinkDependency, value: dependencyArchivePath))
            }
        }
        
        switch targetKind {
        case .library:
            break
        case .executable:
            arguments.insertIfMissing(.option(DocCArguments.fallbackDefaultModuleKind, value: "Command-line Tool"))
        }
        
        // If we were given a catalog path, prepend it to the set of arguments.
        if let doccCatalogPath {
            arguments.prepend(rawArgument: doccCatalogPath)
        }
        
        return [action.rawValue] + arguments.remainingArguments
    }
}

enum DocCArguments {
    /// A fallback value for the bundle display name, if the documentation catalog doesn't specify one or if the build has no symbol information.
    ///
    /// The plugin defines this name so that it can pass a default value for older versions of `docc` which require this.
    static let fallbackDisplayName = CommandLineArgument.Names(
        preferred: "--fallback-display-name"
    )
    
    /// A fallback value for the bundle identifier, if the documentation catalog doesn't specify one or if the build has no symbol information.
    ///
    /// The plugin defines this name so that it can pass a default value for older versions of `docc` which require this.
    static let fallbackBundleIdentifier = CommandLineArgument.Names(
        preferred: "--fallback-bundle-identifier"
    )
    
    /// A fallback value for the "module kind" display name, if the documentation catalog doesn't specify one.
    ///
    /// The plugin defines this name so that it can pass a default value when building documentation for executable targets.
    static let fallbackDefaultModuleKind = CommandLineArgument.Names(
        preferred: "--fallback-default-module-kind"
    )
    
    /// A directory of symbol graph files that DocC will use as input when building documentation.
    ///
    /// The plugin defines this name so that it can pass a default value.
    static let additionalSymbolGraphDirectory = CommandLineArgument.Names(
        preferred: "--additional-symbol-graph-dir"
    )
    
    /// Configures DocC to include a LMDB representation of the navigator index in the output.
    ///
    /// The plugin defines this name so that it can pass this flag by default.
    static let emitLMDBIndex = CommandLineArgument.Names(
        preferred: "--emit-lmdb-index"
    )
    
    /// The directory where DocC will write the built documentation archive.
    ///
    /// The plugin defines this name so that it can intercept it and support building documentation for multiple targets within one package build command.
    static let outputPath = CommandLineArgument.Names(
        preferred: "--output-path",
        alternatives: ["--output-dir", "-o"]
    )
    
    /// A DocC feature flag to enable support for linking to documentation dependencies.
    ///
    /// The plugin defines this name so that it can specify documentation dependencies based on target dependencies when building combined documentation for multiple targets.
    static let enableExternalLinkSupport = CommandLineArgument.Names(
        preferred: "--enable-experimental-external-link-support"
    )
    
    /// A DocC flag that specifies a dependency DocC archive that the current build can link to.
    ///
    /// The plugin defines this name so that it can specify documentation dependencies based on target dependencies when building combined documentation for multiple targets.
    static let externalLinkDependency = CommandLineArgument.Names(
        preferred: "--dependency"
    )
    
    /// A DocC flag for the "merge" command that specifies a custom display name for the synthesized landing page.
    ///
    /// The plugin defines this name so that it can specify the package name as the display name of the default landing page when building combined documentation for multiple targets.
    static let synthesizedLandingPageName = CommandLineArgument.Names(
        preferred: "--synthesized-landing-page-name"
    )
    
    /// A DocC flag for the "merge" command that specifies a custom kind for the synthesized landing page.
    ///
    /// The plugin defines this name so that it can specify "Package" as the kind of the default landing page when building combined documentation for multiple targets.
    static let synthesizedLandingPageKind = CommandLineArgument.Names(
        preferred: "--synthesized-landing-page-kind"
    )
}
