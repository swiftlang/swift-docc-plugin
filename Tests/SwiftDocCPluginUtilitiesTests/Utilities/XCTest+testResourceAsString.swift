// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
import XCTest

extension XCTestCase {
    func testResourceAsString(named resourceName: String) throws -> String {
        let resourceURL = try XCTUnwrap(
            Bundle.module.url(
                forResource: resourceName,
                withExtension: "txt",
                subdirectory: "Test Fixtures"
            )
        )
        
        return try String(contentsOf: resourceURL, encoding: .utf8)
    }
}
