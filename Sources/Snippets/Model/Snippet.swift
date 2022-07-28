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
public struct Snippet {
    /// The ``URL`` of the source file for this snippet.
    public var sourceFile: URL

    /// A short abstract explaining what the snippet does.
    public var explanation: String
    
    /// The ``presentationLines`` joined with a newline `"\n"` separator.
    public var presentationCode: String {
        return presentationLines.joined(separator: "\n")
    }

    /// The code to display as the snippet.
    public var presentationLines: [String]
    
    /// Named line ranges in the snippet.
    public var slices: [String: Range<Int>]

    init(parsing source: String, sourceFile: URL) {
        let extractor = SnippetParser(source: source)
        self.explanation = extractor.explanationLines.joined(separator: "\n")
        self.presentationLines = extractor.presentationLines.map(String.init)
        self.slices = extractor.slices
        self.sourceFile = sourceFile
    }

    /// Create a Swift snippet by parsing a file.
    ///
    /// - parameter sourceURL: The URL of the file to parse.
    /// - parameter syntax: The name of the syntax of the source file if known.
    public init(parsing sourceFile: URL) throws {
        let source = try String(contentsOf: sourceFile)
        self.init(parsing: source, sourceFile: sourceFile)
    }
    
    subscript(sliceIdentifier: String) -> String? {
        guard let slice = slices[sliceIdentifier] else {
            return nil
        }
        return presentationLines[slice].joined(separator: "\n")
    }
}
