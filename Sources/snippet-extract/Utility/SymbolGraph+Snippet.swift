// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022-2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
import Snippets
import struct SymbolKit.SymbolGraph

extension SymbolGraph.Symbol {
    /// Create a symbol for a given snippet.
    ///
    /// - Parameters:
    ///   - snippet: The snippet to create a symbol for.
    ///   - moduleName: The name to use for the package name in the snippet symbol's precise identifier.
    public init(_ snippet: Snippets.Snippet, moduleName: String) throws {
        let basename = snippet.sourceFile.deletingPathExtension().lastPathComponent
        let identifier = SymbolGraph.Symbol.Identifier(precise: "$snippet__\(moduleName).\(basename)", interfaceLanguage: "swift")
        let names = SymbolGraph.Symbol.Names.init(title: basename, navigator: nil, subHeading: nil, prose: nil)
        
        var pathComponents = Array(snippet.sourceFile.absoluteURL.deletingPathExtension().pathComponents[...])

        guard let snippetsPathComponentIndex = pathComponents.firstIndex(where: {
            $0 == "Snippets"
        }) else {
            throw SnippetExtractCommand.ArgumentError.snippetNotContainedInSnippetsDirectory(snippet.sourceFile)
        }

        // In theory, there may be differently named snippet root directories in the future.
        // Replace that path component with the standardized `Snippets`.
        pathComponents.replaceSubrange(pathComponents.startIndex...snippetsPathComponentIndex,
                                       with: CollectionOfOne("Snippets"))
        
        let docComment = SymbolGraph.LineList(snippet.explanation
                                    .split(separator: "\n", maxSplits: Int.max, omittingEmptySubsequences: false)
                                    .map { line in
            SymbolGraph.LineList.Line(text: String(line), range: nil)
        })
        let accessLevel = SymbolGraph.Symbol.AccessControl(rawValue: "public")

        let kind = SymbolGraph.Symbol.Kind(parsedIdentifier: .snippet, displayName: "Snippet")
        
        self.init(identifier: identifier,
                  names: names,
                  pathComponents: pathComponents,
                  docComment: docComment,
                  accessLevel: accessLevel,
                  kind: kind,
                  mixins: [
                      SymbolGraph.Symbol.Snippet.mixinKey: SymbolGraph.Symbol.Snippet(language: "swift", lines: snippet.presentationLines, slices: snippet.slices)
                  ],
                  isVirtual: true)
    }
}
