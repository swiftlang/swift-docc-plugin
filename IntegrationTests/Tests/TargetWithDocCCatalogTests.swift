// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022-2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import XCTest

final class TargetWithDocCCatalogTests: ConcurrencyRequiringTestCase {
    func testGenerateDocumentation() throws {
        let result = try swiftPackage(
            "generate-documentation",
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "TargetWithDocCCatalog")
        )
        
        result.assertExitStatusEquals(0)
        let outputArchives = result.referencedDocCArchives
        XCTAssertEqual(outputArchives.count, 1)
        let archiveURL = try XCTUnwrap(outputArchives.first)
        
        XCTAssertEqual(try relativeFilePathsIn(.dataSubdirectory, of: archiveURL), [
            "documentation/librarywithdocccatalog.json",
            "documentation/librarywithdocccatalog/article-one.json",
            "documentation/librarywithdocccatalog/article-two.json",
            "documentation/librarywithdocccatalog/foo.json",
            "documentation/librarywithdocccatalog/foo/foo().json",
        ])
    }
}
