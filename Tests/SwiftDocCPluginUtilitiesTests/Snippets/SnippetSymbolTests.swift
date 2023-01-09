// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors


@testable import Snippets
import struct SymbolKit.SymbolGraph
@testable import snippet_extract
import XCTest

class SnippetSymbolTests: XCTestCase {
    func testThrowsErrorWhenCreatingFloatingSwiftSnippet() throws {
        let source = """
        // A snippet.
        foo() {}
        """
        let snippet = Snippets.Snippet(parsing: source,
                                       sourceFile: URL(fileURLWithPath: "/tmp/to/floating/File.swift"))
        XCTAssertThrowsError(try SymbolGraph.Symbol(snippet, moduleName: "MyModule"),
                             "Expected snippetNotContainedInSnippetsDirectory error",
                             { (error: Error) in
            guard let argumentError = error as? SnippetExtractCommand.ArgumentError,
                  case .snippetNotContainedInSnippetsDirectory = argumentError else {
                XCTFail("Expected snippetNotContainedInSnippetsDirectory error")
                return
            }
        })
    }

    func testPathComponentsForSnippetSymbol() throws {
        let source = """
        // A snippet.
        foo() {}
        """
        let snippet = Snippets.Snippet(parsing: source,
                                       sourceFile: URL(fileURLWithPath: "/path/to/my-package/Snippets/ASnippet.swift"))
        let symbol = try SymbolGraph.Symbol(snippet, moduleName: "my-package")
        XCTAssertEqual(["Snippets", "ASnippet"], symbol.pathComponents)
    }
}
