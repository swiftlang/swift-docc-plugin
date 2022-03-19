// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Snippets
import struct SymbolKit.SymbolGraph

extension SymbolGraph.Symbol {
    /// Create a ``SymbolGraph.Symbol`` from a ``SnippetGroup``.
    ///
    /// - parameter packageName: The name to use for the package name in the snippet group symbol's precise identifier.
    init(_ snippetGroup: Snippets.SnippetGroup, packageName: String) {
        let identifier = SymbolGraph.Symbol.Identifier(precise: "$snippet__\(packageName).\(snippetGroup.name)", interfaceLanguage: "swift")
        let names = SymbolGraph.Symbol.Names.init(title: snippetGroup.name, navigator: nil, subHeading: nil, prose: nil)
        let pathComponents = [snippetGroup.name]
        let docComment = SymbolGraph.LineList(snippetGroup.explanation
                                    .split(separator: "\n", maxSplits: Int.max, omittingEmptySubsequences: false)
                                    .map { line in
            SymbolGraph.LineList.Line(text: String(line), range: nil)
        })
        let accessLevel = SymbolGraph.Symbol.AccessControl(rawValue: "public")
        let kind = SymbolGraph.Symbol.Kind(parsedIdentifier: .snippetGroup, displayName: "Snippet Group")
        self.init(identifier: identifier, names: names, pathComponents: pathComponents, docComment: docComment, accessLevel: accessLevel, kind: kind, mixins: [:])
    }

    /// Create a ``SymbolGraph.Symbol`` from a ``Snippet``.
    ///
    /// - parameter packageName: The name to use for the package name in the snippet symbol's precise identifier.
    init(_ snippet: Snippets.Snippet, packageName: String, groupName: String) {
        let identifier = SymbolGraph.Symbol.Identifier(precise: "$snippet__\(packageName).\(groupName).\(snippet.identifier)", interfaceLanguage: "swift")
        let names = SymbolGraph.Symbol.Names.init(title: snippet.identifier, navigator: nil, subHeading: nil, prose: nil)
        let pathComponents = [packageName, groupName, snippet.identifier]
        let docComment = SymbolGraph.LineList(snippet.explanation
                                    .split(separator: "\n", maxSplits: Int.max, omittingEmptySubsequences: false)
                                    .map { line in
            SymbolGraph.LineList.Line(text: String(line), range: nil)
        })
        let accessLevel = SymbolGraph.Symbol.AccessControl(rawValue: "public")

        let kind = SymbolGraph.Symbol.Kind(parsedIdentifier: .snippet, displayName: "Snippet")
        self.init(identifier: identifier, names: names, pathComponents: pathComponents, docComment: docComment, accessLevel: accessLevel, kind: kind, mixins: [
            SymbolGraph.Symbol.Snippet.mixinKey: SymbolGraph.Symbol.Snippet(chunks: [SymbolGraph.Symbol.Snippet.Chunk(name: nil, language: "swift", code: snippet.presentationCode)])
        ])
    }
}
