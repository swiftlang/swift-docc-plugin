// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import XCTest

final class TargetWithDocCCatalogTests: XCTestCase {
    func testGenerateDocumentation() throws {
        let result = try swiftPackage(
            "generate-documentation",
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "TargetWithDocCCatalog")
        )
        
        result.assertExitStatusEquals(0)
        XCTAssertEqual(result.referencedDocCArchives.count, 1)
        
        let doccArchiveURL = try XCTUnwrap(result.referencedDocCArchives.first)
        
        let dataDirectoryContents = try filesIn(.dataSubdirectory, of: doccArchiveURL)
        
        XCTAssertEqual(
            Set(dataDirectoryContents.map(\.lastTwoPathComponents)),
            [
                "documentation/librarywithdocccatalog.json",
                "librarywithdocccatalog/article-one.json",
                "librarywithdocccatalog/article-two.json",
                "librarywithdocccatalog/foo.json",
                "foo/foo().json",
            ]
        )
    }
}
