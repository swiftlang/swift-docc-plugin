// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import XCTest

final class SingleTestTargetTests: XCTestCase {
    func testDoesNotGenerateDocumentation() throws {
        let result = try swiftPackage(
            "generate-documentation",
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "SingleTestTarget")
        )
        
        result.assertExitStatusEquals(1)
        XCTAssertTrue(result.referencedDocCArchives.isEmpty)
    }
}
