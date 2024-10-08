// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022-2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import XCTest

final class SingleLibraryTargetTests: ConcurrencyRequiringTestCase {
    func testGenerateDocumentation() throws {
        let result = try swiftPackage(
            "generate-documentation",
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "SingleLibraryTarget")
        )
        
        result.assertExitStatusEquals(0)
        let archiveURL = try XCTUnwrap(result.onlyOutputArchive)
        
        XCTAssertEqual(try relativeFilePathsIn(.dataSubdirectory, of: archiveURL), [
            "documentation/library.json",
            "documentation/library/foo.json",
            "documentation/library/foo/foo().json",
        ])
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
        let archiveURL = try XCTUnwrap(result.onlyOutputArchive)
        
        XCTAssertEqual(try relativeFilePathsIn(.dataSubdirectory, of: archiveURL), [
            "documentation/library.json",
            "documentation/library/foo.json",
            "documentation/library/foo/foo().json",
        ])
    }
}
