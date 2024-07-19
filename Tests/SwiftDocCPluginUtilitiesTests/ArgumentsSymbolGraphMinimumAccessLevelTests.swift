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

final class ArgumentsSymbolGraphMinimumAccessLevelTests: XCTestCase {
    func testArgumentsThatContainAccessLevel() {
        XCTAssertEqual(
            Arguments(["--experimental-symbol-graph-minimum-access-level", "internal"]).symbolGraphMinimumAccessLevel,
            "internal"
        )
        
        XCTAssertEqual(
            Arguments(["other-arg", "--experimental-symbol-graph-minimum-access-level", "internal", "--other-flag"]).symbolGraphMinimumAccessLevel,
            "internal"
        )
    }
    
    func testArgumentsThatDoNotContainAccessLevel() {
        XCTAssertNil(
            Arguments(["--other-option", "/test-path"]).symbolGraphMinimumAccessLevel
        )
        
        XCTAssertNil(
            Arguments(["other-arg", "--other-option", "/test-path", "--other-flag"]).symbolGraphMinimumAccessLevel
        )
    }
    
    func testArgumentsThatContainTrailingAccessLevelFlag() {
        XCTAssertNil(
            Arguments(["--experimental-symbol-graph-minimum-access-level"]).symbolGraphMinimumAccessLevel
        )
        
        
        XCTAssertNil(
            Arguments(["other-arg", "--experimental-symbol-graph-minimum-access-level"]).symbolGraphMinimumAccessLevel
        )
    }
}
