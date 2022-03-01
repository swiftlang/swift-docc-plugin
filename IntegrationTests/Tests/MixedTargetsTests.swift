// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import XCTest

final class MixedTargetsTests: XCTestCase {
    func testGenerateDocumentationForSpecificTarget() throws {
        let result = try swiftPackage(
            "generate-documentation", "--target", "Executable",
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "MixedTargets")
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
    
    func testGenerateDocumentationForMultipleSpecificTargets() throws {
        let result = try swiftPackage(
            "generate-documentation", "--target", "Executable", "--target", "Library",
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "MixedTargets")
        )
        
        result.assertExitStatusEquals(0)
        XCTAssertEqual(result.referencedDocCArchives.count, 2)
        
        let executableDoccArchiveURL = try XCTUnwrap(
            result.referencedDocCArchives.first { archive in
                archive.lastPathComponent.contains("Executable")
            }
        )
        
        let libraryDoccArchiveURL = try XCTUnwrap(
            result.referencedDocCArchives.first { archive in
                archive.lastPathComponent.contains("Library")
            }
        )
        
        let executableDataDirectoryContents = try filesIn(.dataSubdirectory, of: executableDoccArchiveURL)
        
        XCTAssertEqual(
            Set(executableDataDirectoryContents.map(\.lastTwoPathComponents)),
            [
                "documentation/executable.json",
                "executable/foo.json",
                "foo/foo().json",
                "foo/main().json",
                "foo/init().json",
            ]
        )
        
        let libraryDataDirectoryContents = try filesIn(.dataSubdirectory, of: libraryDoccArchiveURL)
        
        XCTAssertEqual(
            Set(libraryDataDirectoryContents.map(\.lastTwoPathComponents)),
            [
                "documentation/library.json",
                "library/foo.json",
                "foo/foo().json",
            ]
        )
    }
}
