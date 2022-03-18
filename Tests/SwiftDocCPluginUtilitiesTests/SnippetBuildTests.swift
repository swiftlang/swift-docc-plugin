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
        XCTAssertNil(snippet.groupName)
        XCTAssertEqual("test", snippet.identifier)
    }

    func testParseFull() {
        let expectedExplanation = "This is a snippet"

        let source = """
        //! \(expectedExplanation)

        func shown() {
            print("Hello, world!")
        }

        // MARK: Hide
        hidden()

        // MARK: Show
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
        XCTAssertNil(snippet.groupName)
        XCTAssertEqual("test", snippet.identifier)
    }

    func testParseRedundantMarkers() {
        let source = """
        //! This is a snippet
        // MARK: Show
        func shown() {
            print("Hello, world!")
        }

        // MARK: Hide
        hidden()

        // MARK: Hide
        // MARK: Show
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
            // MARK: Hide
            struct MyStruct {
                // MARK: Show
                func foo()
            // MARK: Hide
            }
            """
            let snippet = Snippet(parsing: source, sourceFile: fakeSourceFilename)
            XCTAssertEqual("func foo()", snippet.presentationCode)
        }
        
        do {
            let source = """
            // MARK: Hide
            struct Outer {
                // MARK: Show
                struct Inner {
                    func foo()
                }
            // MARK: Hide
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
    func testParseMarkShow() {
        XCTAssertEqual(.shown, "// mark: show".parsedVisibilityMark)
        XCTAssertEqual(.shown, "// Mark: Show".parsedVisibilityMark)
        XCTAssertEqual(.shown, "// MARK: Show".parsedVisibilityMark)
        XCTAssertEqual(.shown, "//      MARK: Show".parsedVisibilityMark)
        XCTAssertEqual(.shown, "//      MARK: Show    ".parsedVisibilityMark)
        XCTAssertNil("MARK: Show".parsedVisibilityMark)
    }

    func testParseMarkHide() {
        XCTAssertEqual(.hidden, "// mark: hide".parsedVisibilityMark)
        XCTAssertEqual(.hidden, "// Mark: Hide".parsedVisibilityMark)
        XCTAssertEqual(.hidden, "// MARK: Hide".parsedVisibilityMark)
        XCTAssertEqual(.hidden, "//      MARK: Hide".parsedVisibilityMark)
        XCTAssertEqual(.hidden, "//      MARK: Hide   ".parsedVisibilityMark)
        XCTAssertNil("MARK: Hide".parsedVisibilityMark)
    }
}
