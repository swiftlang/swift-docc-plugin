// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

extension PluginFlag {
    /// Create a combined DocC archive containing documentation for all built targets.
    ///
    /// - Note: This flag requires that the `docc` executable supports ``Feature/linkDependencies``.
    static let enableCombinedDocumentationSupport = PluginFlag(
        parsedValues: [
            "--\(enableCombinedDocumentationSupportFlagName)"
        ],
        abstract: "Create a combined DocC archive with all generated documentation",
        description: """
            Experimental feature that allows targets to link to pages in their dependencies and that \
            creates an additional "combined" DocC archive containing all the generated documentation.
            """,
        argumentTransformation: { $0 }
    )
    
    static let enableCombinedDocumentationSupportFlagName = "enable-experimental-combined-documentation"
}

