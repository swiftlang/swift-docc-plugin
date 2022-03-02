// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation

/// A Swift code snippet.
///
/// A *snippet* is a short, focused code example that can be shown with little to no context or prose.
struct Snippet {
    /// The ``URL`` of the source file for this snippet.
    var sourceFile: URL

    /// A short abstract explaining what the snippet does.
    var explanation: String

    /// The code to display as the snippet.
    var presentationCode: String

    /// The name of the owning group, if snippet is in a ``SnippetGroup``.
    var groupName: String? = nil

    /// The identifier of the snippet.
    var identifier: String {
        return sourceFile.deletingPathExtension().lastPathComponent
    }

    /// Create a Swift snippet by parsing a file.
    ///
    /// - parameter sourceURL: The URL of the file to parse.
    /// - parameter syntax: The name of the syntax of the source file if known.
    init(parsing sourceFile: URL) throws {
        let source = try String(contentsOf: sourceFile)
        let extractor = PlainTextSnippetExtractor(source: source)
        self.explanation = extractor.explanation
        self.presentationCode = extractor.presentationCode
        self.sourceFile = sourceFile
    }
}
