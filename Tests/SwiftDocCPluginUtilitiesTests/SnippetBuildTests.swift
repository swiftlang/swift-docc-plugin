// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
@testable import Snippets
import XCTest

class SnippetBuildTests: XCTestCase {
    let fakeSourceFilename = URL(fileURLWithPath: "/tmp/test.swift")
    func testParseEmpty() {
        let source = ""
        let snippet = Snippet(parsing: source, sourceFile: fakeSourceFilename)

        XCTAssertEqual(fakeSourceFilename, snippet.sourceFile)
        XCTAssertTrue(snippet.explanation.isEmpty)
        XCTAssertTrue(snippet.presentationCode.isEmpty)
        XCTAssertEqual("test", snippet.identifier)
    }

    func testParseFull() {
        let expectedExplanation = "This is a snippet"

        let source = """
        //! \(expectedExplanation)

        func shown() {
            print("Hello, world!")
        }

        // snippet.hide
        hidden()

        // snippet.show
        shown()
        """

        let snippet = Snippet(parsing: source, sourceFile: fakeSourceFilename)

        let expectedCode = """
        func shown() {
            print("Hello, world!")
        }

        shown()
        """

        XCTAssertEqual(fakeSourceFilename, snippet.sourceFile)
        XCTAssertEqual(expectedExplanation, snippet.explanation)
        XCTAssertEqual(expectedCode, snippet.presentationCode)
        XCTAssertEqual("test", snippet.identifier)
    }

    func testParseRedundantMarkers() {
        let source = """
        //! This is a snippet
        // snippet.show
        func shown() {
            print("Hello, world!")
        }

        // snippet.hide
        hidden()

        // snippet.hide
        // snippet.show
        shown()
        """

        let expectedCode = """
        func shown() {
            print("Hello, world!")
        }

        shown()
        """

        let snippet = Snippet(parsing: source, sourceFile: fakeSourceFilename)

        XCTAssertEqual(expectedCode, snippet.presentationCode)
    }

    func testParseRemoveLeadingAndTrailingNewlines() {
        let source = """

        //!
        //! This is a snippet.
        //!


        func foo()



        """
        let snippet = Snippet(parsing: source, sourceFile: fakeSourceFilename)
        XCTAssertEqual("This is a snippet.", snippet.explanation)
        XCTAssertEqual("func foo()", snippet.presentationCode)
    }

    func testParseRemoveExtraIndentation() {
        do {
            let source = """
            // snippet.hide
            struct MyStruct {
                // snippet.show
                func foo()
            // snippet.hide
            }
            """
            let snippet = Snippet(parsing: source, sourceFile: fakeSourceFilename)
            XCTAssertEqual("func foo()", snippet.presentationCode)
        }
        
        do {
            let source = """
            // snippet.hide
            struct Outer {
                // snippet.show
                struct Inner {
                    func foo()
                }
            // snippet.hide
            }
            """

            let snippet = Snippet(parsing: source, sourceFile: fakeSourceFilename)

            XCTAssertEqual("""
            struct Inner {
                func foo()
            }
            """, snippet.presentationCode)
        }
    }
}

class VisibilityMarkTests: XCTestCase {
    func testParseHideShow() {
        XCTAssertEqual(.shown, "// snippet.show".parsedVisibilityMark)
        XCTAssertEqual(.shown, "// Snippet.Show".parsedVisibilityMark)
        XCTAssertEqual(.shown, "// SNIPPET.SHOW".parsedVisibilityMark)
        XCTAssertEqual(.shown, "//      snippet.show".parsedVisibilityMark)
        XCTAssertEqual(.shown, "//      snippet.show      ".parsedVisibilityMark)

        XCTAssertEqual(.hidden, "// snippet.hide".parsedVisibilityMark)
        XCTAssertEqual(.hidden, "// Snippet.Hide".parsedVisibilityMark)
        XCTAssertEqual(.hidden, "// SNIPPET.HIDE".parsedVisibilityMark)
        XCTAssertEqual(.hidden, "//      snippet.hide".parsedVisibilityMark)
        XCTAssertEqual(.hidden, "//      snippet.hide   ".parsedVisibilityMark)

        // Markers need to be a comment.
        XCTAssertNil("snippet.show".parsedVisibilityMark)
        XCTAssertNil("snippet.hide".parsedVisibilityMark)
    }
}
