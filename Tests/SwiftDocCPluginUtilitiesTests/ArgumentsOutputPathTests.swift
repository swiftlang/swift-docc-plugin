// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
import SwiftDocCPluginUtilities
import XCTest

final class ArgumentsOutputPathTests: XCTestCase {
    func testArgumentsThatContainOutputPath() {
        XCTAssertEqual(
            Arguments(["--output-path", "/test-path"]).outputPath,
            "/test-path"
        )
        
        XCTAssertEqual(
            Arguments(["--output-dir", "/test-path"]).outputPath,
            "/test-path"
        )
        
        XCTAssertEqual(
            Arguments(["other-arg", "--output-path", "/test-path", "--other-flag"]).outputPath,
            "/test-path"
        )
        
        XCTAssertEqual(
            Arguments(["other-arg", "--output-dir", "/test-path", "--other-flag"]).outputPath,
            "/test-path"
        )
    }
    
    func testArgumentsThatDoNotContainOutputPath() {
        XCTAssertNil(
            Arguments(["--other-option", "/test-path"]).outputPath
        )
        
        XCTAssertNil(
            Arguments(["other-arg", "--other-option", "/test-path", "--other-flag"]).outputPath
        )
    }
    
    func testArgumentsThatContainTrailingOutputPathFlag() {
        XCTAssertNil(
            Arguments(["--output-path"]).outputPath
        )
        
        XCTAssertNil(
            Arguments(["--output-dir"]).outputPath
        )
        
        XCTAssertNil(
            Arguments(["other-arg", "--output-option", "/test-path", "--output-path"]).outputPath
        )
        
        XCTAssertNil(
            Arguments(["other-arg", "--output-option", "/test-path", "--output-dir"]).outputPath
        )
    }
}
