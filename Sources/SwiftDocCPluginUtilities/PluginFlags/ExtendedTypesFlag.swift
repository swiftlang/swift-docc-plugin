// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

extension PluginFlag {
    /// Include extended types in documentation archives.
    ///
    /// Enables the extension block symbol format when calling the
    /// dump symbol graph API.
    ///
    /// - Note: This flag is only available starting from Swift 5.8. It should
    /// be hidden from the `--help` command for lower toolchain versions.
    /// However, we do not hide the flag entirely, because this enables us to give
    /// a more precise warning when accidentally used with Swift 5.7 or lower.
    static let extendedTypes = PluginFlag(
        parsedValues: [
            "--include-extended-types",
        ],
        abstract: "Include extended types from other modules in the produced DocC archive.",
        description: """
            Allows documenting symbols that a target adds to its dependencies.
            """,
        argumentTransformation: { $0 }
    )
}
