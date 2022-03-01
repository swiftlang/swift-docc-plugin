// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import XCTest

final class DocCArchiveIndexGenerationTests: XCTestCase {
    func testGenerateDocumentationWithIndexingEnabled() throws {
        let result = try swiftPackage(
            "generate-documentation",
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "SingleLibraryTarget")
        )
        
        result.assertExitStatusEquals(0)
        let doccArchiveURL = try XCTUnwrap(result.referencedDocCArchives.first)
        
        let indexDirectoryContents = try filesIn(.indexSubdirectory, of: doccArchiveURL)
        XCTAssertFalse(indexDirectoryContents.isEmpty)
    }
}
