// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
@testable import SwiftDocCPluginUtilities
import XCTest

final class PluginFlagTests: XCTestCase {
    func testConsumesParsedValues() {
        let examplePluginFlag = PluginFlag(
            parsedValues: ["--example", "--other-example"],
            abstract: "",
            description: "",
            argumentTransformation: { $0 }
        )
        
        let arguments = Arguments(
            [
                "one",
                "two",
                "--example",
                "three",
                "--other-example",
                "four",
                "five",
            ]
        )
        
        XCTAssertEqual(
            examplePluginFlag.transform(arguments),
            [
                "one",
                "two",
                "three",
                "four",
                "five",
            ]
        )
    }
    
    func testCallsArgumentTransformationClosure() {
        let examplePluginFlag = PluginFlag(
            parsedValues: ["--example", "--other-example"],
            abstract: "",
            description: "",
            argumentTransformation: { arguments in
                return arguments.filter { argument in
                    argument != "one" && argument != "five"
                }
            }
        )
        
        let arguments = Arguments(
            [
                "one",
                "two",
                "--example",
                "three",
                "--other-example",
                "four",
                "five",
            ]
        )
        
        XCTAssertEqual(
            examplePluginFlag.transform(arguments),
            [
                "two",
                "three",
                "four",
            ]
        )
    }
}
