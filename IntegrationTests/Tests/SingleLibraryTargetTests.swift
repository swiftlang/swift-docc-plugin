// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import XCTest

final class SingleLibraryTargetTests: XCTestCase {
    func testGenerateDocumentation() throws {
        let result = try swiftPackage(
            "generate-documentation",
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "SingleLibraryTarget")
        )
        
        result.assertExitStatusEquals(0)
        XCTAssertEqual(result.referencedDocCArchives.count, 1)
        
        let doccArchiveURL = try XCTUnwrap(result.referencedDocCArchives.first)
        
        let dataDirectoryContents = try filesIn(.dataSubdirectory, of: doccArchiveURL)
        
        XCTAssertEqual(
            Set(dataDirectoryContents.map(\.lastTwoPathComponents)),
            [
                "documentation/library.json",
                "library/foo.json",
                "foo/foo().json",
            ]
        )
    }
    
    func testDocumentationGenerationDoesNotEmitErrors() throws {
        let result = try swiftPackage(
            "generate-documentation",
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "SingleLibraryTarget")
        )
        
        result.assertExitStatusEquals(0)
        
        /*
         
         Skipping the remaining assertion because SwiftPM has recently started emitting regular
         build status logging to standard error instead of standard output.
         
         Tracked with rdar://89598464.
        
         XCTAssertTrue(
            result.standardError.isEmpty,
            "Standard error should be empty. Contains: '\(result.standardError)'."
         )
        */
    }
    
    func testGenerateDocumentationWithCustomOutput() throws {
        let customOutputDirectory = try temporaryDirectory().appendingPathComponent(
            "CustomOutput.doccarchive"
        )
        
        let result = try swiftPackage(
            "--allow-writing-to-directory", customOutputDirectory.path,
            "generate-documentation", "--output-path", customOutputDirectory.path,
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "SingleLibraryTarget")
        )
        
        result.assertExitStatusEquals(0)
        XCTAssertEqual(result.referencedDocCArchives.count, 1)
        let referencedDoccArchiveURL = try XCTUnwrap(result.referencedDocCArchives.first)
        
        XCTAssertEqual(referencedDoccArchiveURL.path, customOutputDirectory.path)
        
        let dataDirectoryContents = try filesIn(.dataSubdirectory, of: referencedDoccArchiveURL)
        XCTAssertEqual(dataDirectoryContents.count, 3)
    }
}
