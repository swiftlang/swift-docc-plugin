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
    static let fakeSnippetsDir = URL(fileURLWithPath: "/tmp/MyPackage/Snippets")
    static let fakeSourceFilename = fakeSnippetsDir.appendingPathComponent("Something").appendingPathComponent("Test.swift")
    func testParseEmpty() {
        let source = ""
        let snippet = Snippet(parsing: source, sourceFile: SnippetBuildTests.fakeSourceFilename)

        XCTAssertEqual(SnippetBuildTests.fakeSourceFilename, snippet.sourceFile)
        XCTAssertTrue(snippet.explanation.isEmpty)
        XCTAssertTrue(snippet.presentationLines.isEmpty)
    }

    func testParseFull() {
        let expectedExplanation = "This is a snippet"

        let source = """
        // \(expectedExplanation)

        func shown() {
            print("Hello, world!")
        }

        // snippet.hide
        hidden()

        // snippet.show
        shown()
        """

        let snippet = Snippet(parsing: source, sourceFile: SnippetBuildTests.fakeSourceFilename)

        let expectedCode = """
        func shown() {
            print("Hello, world!")
        }

        shown()
        """

        XCTAssertEqual(SnippetBuildTests.fakeSourceFilename, snippet.sourceFile)
        XCTAssertEqual(expectedExplanation, snippet.explanation)
        XCTAssertEqual(expectedCode, snippet.presentationCode)
    }

    /// Using a hide marker inside a hidden region has no effect except that the redundant hide markers are still not included.
    func testParseRedundantMarkers() {
        let source = """
        // This is a snippet
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

        let snippet = Snippet(parsing: source, sourceFile: SnippetBuildTests.fakeSourceFilename)

        XCTAssertEqual(expectedCode, snippet.presentationCode)
    }

    /// Empty or whitespace-only leading and trailing lines are removed from both the explanation and presentation code.
    func testParseRemoveLeadingAndTrailingNewlines() {
        let source = """

        //
        // This is a snippet.
        //


        func foo()



        """
        let snippet = Snippet(parsing: source, sourceFile: SnippetBuildTests.fakeSourceFilename)
        XCTAssertEqual("This is a snippet.", snippet.explanation)
        XCTAssertEqual("func foo()", snippet.presentationCode)
    }

    /// The parser removes some equal amount of indentation from the final presentation code lines
    /// enough to ensure that at least one line has no indentation. This ensures that the code isn't needlessly indented.
    func testParseRemoveMinimumIndentation() {
        do {
            let source = """
            // snippet.hide
            struct MyStruct {
                // snippet.show
                func foo()
            // snippet.hide
            }
            """
            let snippet = Snippet(parsing: source, sourceFile: SnippetBuildTests.fakeSourceFilename)
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

            let snippet = Snippet(parsing: source, sourceFile: SnippetBuildTests.fakeSourceFilename)

            XCTAssertEqual("""
            struct Inner {
                func foo()
            }
            """, snippet.presentationCode)
        }
    }

    /// Although snippet markers use the same comment `"//"` prefix as the explanation, the parser should
    /// stop collecting explanation heading lines when encountering a snippet marker.
    func testExplanationInterruptedByVisibilityMark() {
        let source = """
        // This is
        // the explanation.
        // snippet.hide
        import Foo
        // snippet.show
        // Just a regular comment.
        Foo.foo()
        """
        let snippet = Snippet(parsing: source, sourceFile: SnippetBuildTests.fakeSourceFilename)
        XCTAssertEqual("This is\nthe explanation.", snippet.explanation)
        XCTAssertEqual("""
        // Just a regular comment.
        Foo.foo()
        """, snippet.presentationCode)
    }

    /// Only trimming initial indentation measured from the first line: this is
    /// behavior common to Swift documentation comments.
    /// Indentation measuring point in the `source` below:
    ///    *
    func testExplanationRemoveMinimumIndentation() {
        let source = """
        //    An explanation\u{0020}\u{0020}
        //    with high indentation
        //        is trimmed
        //       just enough
        // but not too much.
        foo()
        """

        // \u{0020}\u{0020} here is a hard line break in Markdown: included here to ensure it's preserved.

        // "but not too much" shouldn't be trimmed just because the measurement point was beyond it:
        // this is behavior common to Swift documentation comments.
        let expectedExplanation = """
        An explanation\u{0020}\u{0020}
        with high indentation
            is trimmed
           just enough
        but not too much.
        """

        let snippet = Snippet(parsing: source, sourceFile: SnippetBuildTests.fakeSourceFilename)
        XCTAssertEqual(expectedExplanation, snippet.explanation)
    }

    /// A blank line will terminate the explanation heading.
    func testExplanationInterruptedByNonCommentLine() {
        let sources = [
            """
            // This is
            // the explanation
            thisIsNot()
            """,

            """
            // This is
            // the explanation

            // this is not
            thisIsNot()
            """,
        ]
        for source in sources {
            let snippet = Snippet(parsing: source, sourceFile: SnippetBuildTests.fakeSourceFilename)
            XCTAssertEqual("This is\nthe explanation", snippet.explanation)
        }
    }
    
    // MARK: Slice Tests
    
    func testSliceBasic() {
        let expectedExplanation = "This is the explanation"
        let source = """
        // \(expectedExplanation)
        
        // snippet.foo
        func foo()
        // snippet.end
        """
        
        let snippet = Snippet(parsing: source, sourceFile: SnippetBuildTests.fakeSourceFilename)
        XCTAssertEqual(expectedExplanation, snippet.explanation)
        XCTAssertEqual(1, snippet.slices.count)
        XCTAssertEqual(snippet["foo"], "func foo()")
        XCTAssertEqual("func foo()", snippet.presentationCode)
    }
    
    func testSliceMultiple() {
        let source = """
        // snippet.foo
        func foo() {}
        // snippet.end
        
        other()
        
        // snippet.bar
        func bar() {}
        // snippet.end
        
        other()
        """
        
        let expectedPresentationCode = """
        func foo() {}
        
        other()
        
        func bar() {}
        
        other()
        """
        
        let expectedSlices = [
            "foo": "func foo() {}",
            "bar": "func bar() {}",
        ]
        
        let snippet = Snippet(parsing: source, sourceFile: SnippetBuildTests.fakeSourceFilename)
        XCTAssertEqual(expectedPresentationCode, snippet.presentationCode)
        for (identifier, code) in expectedSlices {
            XCTAssertEqual(snippet[identifier], code)
        }
    }
    
    /// Starting a new slice ends the previous slice before starting another. Slices do not overlap.
    func testSliceEndsPreviousSlice() {
        let source = """
        // snippet.foo
        func foo() {}
        
        // snippet.bar
        func bar() {}
        """
        
        let expectedPresentationCode = """
        func foo() {}
        
        func bar() {}
        """
        
        let expectedSlices = [
            "foo": "func foo() {}",
            "bar": "func bar() {}",
        ]

        let snippet = Snippet(parsing: source, sourceFile: SnippetBuildTests.fakeSourceFilename)
        XCTAssertEqual(expectedPresentationCode, snippet.presentationCode)
        for (identifier, code) in expectedSlices {
            XCTAssertEqual(snippet[identifier], code)
        }
    }
    
    /// The start and end lines of slices are always non-empty.
    func testSliceOmitsLeadingAndTrailingBlankLines() {
        let source = """
        // This is the explanation.
        
        // snippet.foo
        
        func foo() {}
        
        // snippet.end
        foo()
        """
        
        let expectedPresentationCode = """
        func foo() {}
        
        foo()
        """
        
        let snippet = Snippet(parsing: source, sourceFile: SnippetBuildTests.fakeSourceFilename)
        XCTAssertEqual(expectedPresentationCode, snippet.presentationCode)
        
        XCTAssertEqual(snippet["foo"], "func foo() {}")
    }
    
    /// Slices inside hidden regions are not kept.
    func testSliceInHiddenRegion() {
        let source = """
        // This is the explanation.
        
        // snippet.hide
        
        // snippet.foo
        func foo() {}
        // snippet.end
        
        // snippet.show
        foo()
        """
        
        let expectedPresentationCode = "foo()"
        let snippet = Snippet(parsing: source, sourceFile: SnippetBuildTests.fakeSourceFilename)
        XCTAssertEqual(expectedPresentationCode, snippet.presentationCode)
        XCTAssertTrue(snippet.slices.isEmpty)
    }
    
    /// Slices started inside hidden regions are not kept, even if they end outside them.
    func testSliceStartsInsideHiddenRegionButEndsOutsideIt() {
        let source = """
        // This is the explanation.
        
        // snippet.hide
        
        // snippet.foo
        func foo() {}
        // snippet.show
        foo()
        // snippet.end
        """
        
        let expectedPresentationCode = "foo()"
        let snippet = Snippet(parsing: source, sourceFile: SnippetBuildTests.fakeSourceFilename)
        XCTAssertEqual(expectedPresentationCode, snippet.presentationCode)
        XCTAssertTrue(snippet.slices.isEmpty)
    }
    
    /// Slices can hide regions within them.
    func testSliceContainsHiddenRegion() {
        let source = """
        // This is the explanation.
        
        // snippet.foo
        func foo() {
            let x = 1
            // snippet.hide
            debugPrint(x)
            // snippet.show
        }
        // snippet.end
        foo()
        """
        
        let expectedPresentationCode = """
        func foo() {
            let x = 1
        }
        foo()
        """
        
        let snippet = Snippet(parsing: source, sourceFile: SnippetBuildTests.fakeSourceFilename)
        XCTAssertEqual(expectedPresentationCode, snippet.presentationCode)
        XCTAssertEqual(1, snippet.slices.count)
        XCTAssertEqual(snippet["foo"], """
        func foo() {
            let x = 1
        }
        """)
    }
    
    /// If a snippet.end marker is encountered in a hidden region,
    /// still end the slice with whatever non-hidden content it collected before the hidden region started.
    func testSliceEndInsideHiddenRegion() {
        let source = """
        // This is the explanation.
        
        // snippet.foo
        func foo() {
            let x = 1
            // snippet.hide
            debugPrint(x)
        }
        // snippet.end
        // snippet.show
        foo()
        """
        
        let expectedPresentationCode = """
        func foo() {
            let x = 1
        foo()
        """
        
        let snippet = Snippet(parsing: source, sourceFile: SnippetBuildTests.fakeSourceFilename)
        XCTAssertEqual(expectedPresentationCode, snippet.presentationCode)
        XCTAssertEqual(1, snippet.slices.count)
        XCTAssertEqual(snippet["foo"], """
        func foo() {
            let x = 1
        """)
    }
    
    /// Empty slices are not kept.
    func testSliceEmpty() {
        do {
            let source = """
            // This is the explanation.
            
            // snippet.foo
            // snippet.end
            
            func foo() {}
            """
            
            let expectedPresentationCode = """
            func foo() {}
            """
            
            let snippet = Snippet(parsing: source, sourceFile: SnippetBuildTests.fakeSourceFilename)
            XCTAssertEqual(expectedPresentationCode, snippet.presentationCode)
            XCTAssertTrue(snippet.slices.isEmpty)
        }
        
        do {
            let source = """
            // This is the explanation.
            
            // snippet.foo
            // snippet.hide
            func foo() {}
            // snippet.show
            // snippet.end
            func bar() {}
            """
            
            let expectedPresentationCode = """
            func bar() {}
            """
            
            let snippet = Snippet(parsing: source, sourceFile: SnippetBuildTests.fakeSourceFilename)
            XCTAssertEqual(expectedPresentationCode, snippet.presentationCode)
            XCTAssertTrue(snippet.slices.isEmpty)
        }
    }
}

class SnippetParseMarkerTests: XCTestCase {
    func testParseHideShow() {
        XCTAssertEqual(.visibilityChange(isVisible: true), SnippetParser.tryParseSnippetMarker(from: "// snippet.show"))
        XCTAssertEqual(.visibilityChange(isVisible: true), SnippetParser.tryParseSnippetMarker(from: "// Snippet.Show"))
        XCTAssertEqual(.visibilityChange(isVisible: true), SnippetParser.tryParseSnippetMarker(from: "// SNIPPET.SHOW"))
        XCTAssertEqual(.visibilityChange(isVisible: true), SnippetParser.tryParseSnippetMarker(from: "//      snippet.show"))
        XCTAssertEqual(.visibilityChange(isVisible: true), SnippetParser.tryParseSnippetMarker(from: "//      snippet.show      "))

        XCTAssertEqual(.visibilityChange(isVisible: false), SnippetParser.tryParseSnippetMarker(from: "// snippet.hide"))
        XCTAssertEqual(.visibilityChange(isVisible: false), SnippetParser.tryParseSnippetMarker(from: "// Snippet.Hide"))
        XCTAssertEqual(.visibilityChange(isVisible: false), SnippetParser.tryParseSnippetMarker(from: "// SNIPPET.HIDE"))
        XCTAssertEqual(.visibilityChange(isVisible: false), SnippetParser.tryParseSnippetMarker(from: "//      snippet.hide"))
        XCTAssertEqual(.visibilityChange(isVisible: false), SnippetParser.tryParseSnippetMarker(from: "//      snippet.hide   "))

        // Markers need to be a comment.
        XCTAssertNil(SnippetParser.tryParseSnippetMarker(from: "snippet.show"))
        XCTAssertNil(SnippetParser.tryParseSnippetMarker(from: "snippet.hide"))
    }
    
    func testParseSliceStartAndEnd() {
        XCTAssertEqual(.startSlice(identifier: "foo"), SnippetParser.tryParseSnippetMarker(from: "// snippet.foo"))
        XCTAssertEqual(.startSlice(identifier: "foo"), SnippetParser.tryParseSnippetMarker(from: "//   snippet.foo"))
        XCTAssertEqual(.startSlice(identifier: "foo"), SnippetParser.tryParseSnippetMarker(from: "//   snippet.foo    "))
        
        XCTAssertEqual(.endSlice, SnippetParser.tryParseSnippetMarker(from: "// snippet.end"))
        XCTAssertEqual(.endSlice, SnippetParser.tryParseSnippetMarker(from: "// snippet.END"))
        XCTAssertEqual(.endSlice, SnippetParser.tryParseSnippetMarker(from: "//   snippet.end"))
        XCTAssertEqual(.endSlice, SnippetParser.tryParseSnippetMarker(from: "//    snippet.end  "))
    }
}
