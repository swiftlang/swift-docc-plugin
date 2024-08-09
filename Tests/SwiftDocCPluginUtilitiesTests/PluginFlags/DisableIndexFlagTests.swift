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

final class DisableIndexFlagTests: XCTestCase {
    func testRemovesIndexFlagWhenPresent() {
        XCTAssertEqual(
            PluginFlag.disableIndex.transform(
                ["--disable-indexing", "--emit-lmdb-index", "--other-flag"]
            ),
            ["--other-flag"]
        )
        
        XCTAssertEqual(
            PluginFlag.disableIndex.transform(
                ["--no-indexing", "--emit-lmdb-index", "--other-flag"]
            ),
            ["--other-flag"]
        )
        
        XCTAssertEqual(
            PluginFlag.disableIndex.transform(
                ["--no-indexing", "--disable-indexing", "--emit-lmdb-index", "--other-flag"]
            ),
            ["--other-flag"]
        )
    }
    
    func testDoesNotRemoveIndexFlagWhenNotPresent() {
        XCTAssertEqual(
            PluginFlag.disableIndex.transform(
                ["--emit-lmdb-index", "--other-flag"]
            ),
            ["--emit-lmdb-index", "--other-flag"]
        )
    }
    
    func testNoIndexFlag() {
        XCTAssertEqual(
            PluginFlag.disableIndex.transform(
                ["--disable-indexing", "--other-flag"]
            ),
            ["--other-flag"]
        )
        
        XCTAssertEqual(
            PluginFlag.disableIndex.transform(
                ["--no-indexing", "--other-flag"]
            ),
            ["--other-flag"]
        )
        
        XCTAssertEqual(
            PluginFlag.disableIndex.transform(
                ["--no-indexing", "--disable-indexing", "--other-flag"]
            ),
            ["--other-flag"]
        )
    }
}
