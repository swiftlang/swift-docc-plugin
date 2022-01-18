// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

/// A named command-line option.
struct CommandLineOption: Hashable {
    /// The set of possible names that can be used to represent this option on the command-line.
    ///
    /// For example, this might be both `"--output-path"` and `"-o"`.
    let possibleNames: Set<String>
    
    /// The default name that should be used for this command-line option when
    /// dynamically inserting it into a set of arguments.
    let defaultName: String
    
    init(possibleNames: Set<String>, defaultName: String) {
        self.possibleNames = possibleNames
        self.defaultName = defaultName
    }
    
    init(defaultName: String) {
        self.possibleNames = [defaultName]
        self.defaultName = defaultName
    }
}

extension CommandLineOption {
    /// Specifies a display name that `docc` will use for any created DocC archives
    /// if one isn't otherwise specified in the target's DocC catalog.
    static let fallbackDisplayName = CommandLineOption(
        defaultName: "--fallback-display-name"
    )
    
    /// Specifies a bundle identifier that `docc` will use for any created DocC archives
    /// if one isn't otherwise specified in the target's DocC catalog.
    static let fallbackBundleIdentifier = CommandLineOption(
        defaultName: "--fallback-bundle-identifier"
    )
    
    /// Specifies an additional directory of symbol graphs that `docc` will
    /// consider when creating a DocC archive, in addition to those included in the
    /// target's DocC catalog.
    static let additionalSymbolGraphDirectory = CommandLineOption(
        defaultName: "--additional-symbol-graph-dir"
    )
    
    /// Specifies the directory where `docc` will emit the built DocC archive.
    static let outputPath = CommandLineOption(
        possibleNames: ["--output-path", "--output-dir"],
        defaultName: "--output-path"
    )
    
    /// Specifies a default kind that `docc` will use for any modules in the
    /// created DocC archive if one isn't otherwise specified in the target's DocC catalog.
    static let fallbackDefaultModuleKind = CommandLineOption(
        defaultName: "--fallback-default-module-kind"
    )
}
