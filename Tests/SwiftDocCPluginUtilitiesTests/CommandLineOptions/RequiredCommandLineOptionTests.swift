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

final class RequiredCommandLineOptionTests: XCTestCase {
    func testInsertIntoArgumentsIfMissing() {
        let requiredOption = RequiredCommandLineOption(
            CommandLineOption(
                possibleNames: ["--output-path", "--output-directory", "-o"],
                defaultName: "--output-path"
            ),
            defaultValue: "/my/path"
        )
        
        XCTAssertEqual(
            requiredOption.insertIntoArgumentsIfMissing(
                []
            ),
            ["--output-path", "/my/path"]
        )
        
        XCTAssertEqual(
            requiredOption.insertIntoArgumentsIfMissing(
                ["--other-flag", "value"]
            ),
            ["--other-flag", "value", "--output-path", "/my/path"]
        )
        
        XCTAssertEqual(
            requiredOption.insertIntoArgumentsIfMissing(
                ["--output-path", "/custom/path"]
            ),
            ["--output-path", "/custom/path"]
        )
        
        XCTAssertEqual(
            requiredOption.insertIntoArgumentsIfMissing(
                ["-o", "/custom/path"]
            ),
            ["-o", "/custom/path"]
        )
        
        XCTAssertEqual(
            requiredOption.insertIntoArgumentsIfMissing(
                ["--output-directory", "/custom/path"]
            ),
            ["--output-directory", "/custom/path"]
        )
    }
}
