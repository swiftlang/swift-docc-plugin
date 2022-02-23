// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import XCTest

final class SingleExecutableTargetTests: XCTestCase {
    func testGenerateDocumentation() throws {
        let result = try swiftPackage(
            "generate-documentation",
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "SingleExecutableTarget")
        )
        
        result.assertExitStatusEquals(0)
        XCTAssertEqual(result.referencedDocCArchives.count, 1)
        
        let doccArchiveURL = try XCTUnwrap(result.referencedDocCArchives.first)
        
        let dataDirectoryContents = try filesIn(.dataSubdirectory, of: doccArchiveURL)
        
        XCTAssertEqual(
            Set(dataDirectoryContents.map(\.lastTwoPathComponents)),
            [
                "documentation/executable.json",
                "executable/foo.json",
                "foo/foo().json",
                "foo/main().json",
                "foo/init().json",
            ]
        )
    }
}
