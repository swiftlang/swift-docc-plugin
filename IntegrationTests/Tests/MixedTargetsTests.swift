// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022-2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import XCTest

final class MixedTargetsTests: ConcurrencyRequiringTestCase {
    func testGenerateDocumentationForSpecificTarget() throws {
        let result = try swiftPackage(
            "generate-documentation", "--target", "Executable",
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "MixedTargets")
        )
        
        result.assertExitStatusEquals(0)
        let archiveURL = try XCTUnwrap(result.onlyOutputArchive)
        
        XCTAssertEqual(try relativeFilePathsIn(.dataSubdirectory, of: archiveURL), expectedExecutableDataFiles)
    }
    
    func testGenerateDocumentationForMultipleSpecificTargets() throws {
        let result = try swiftPackage(
            "generate-documentation", "--target", "Executable", "--target", "Library",
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "MixedTargets")
        )
        
        result.assertExitStatusEquals(0)
        let outputArchives = result.referencedDocCArchives
        XCTAssertEqual(result.referencedDocCArchives.count, 2)
        
        let executableArchiveURL = try XCTUnwrap(
            outputArchives.first(where: { $0.lastPathComponent == "Executable.doccarchive" })
        )
        XCTAssertEqual(try relativeFilePathsIn(.dataSubdirectory, of: executableArchiveURL), expectedExecutableDataFiles)
       
        let libraryArchiveURL = try XCTUnwrap(
            outputArchives.first(where: { $0.lastPathComponent == "Library.doccarchive" })
        )
        XCTAssertEqual(try relativeFilePathsIn(.dataSubdirectory, of: libraryArchiveURL), expectedLibraryDataFiles)
    }
}

private let expectedExecutableDataFiles = [
    "documentation/executable.json",
    "documentation/executable/foo.json",
    "documentation/executable/foo/foo().json",
    "documentation/executable/foo/init().json",
    "documentation/executable/foo/main().json",
]

private let expectedLibraryDataFiles = [
    "documentation/library.json",
    "documentation/library/foo.json",
    "documentation/library/foo/foo().json",
]
