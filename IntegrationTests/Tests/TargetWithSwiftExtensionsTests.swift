// This source file is part of the Swift.org open source project
//
// Copyright (c) 2023-2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
import XCTest

final class TargetWithSwiftExtensionsTests: ConcurrencyRequiringTestCase {
#if swift(>=5.8)
    let supportsIncludingSwiftExtendedTypes = true
#else
    let supportsIncludingSwiftExtendedTypes = false
#endif
    
    override func setUpWithError() throws {
        try XCTSkipUnless(
            supportsIncludingSwiftExtendedTypes,
            "The current toolchain does not support symbol graph generation for extended types."
        )
        
        try super.setUpWithError()
    }
    
    func testGenerateDocumentationWithoutExtendedTypesFlag() throws {
        let result = try swiftPackage(
            "generate-documentation",
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "LibraryTargetWithExtensionSymbols")
        )
        
        result.assertExitStatusEquals(0)
        let outputArchives = result.referencedDocCArchives
        XCTAssertEqual(outputArchives.count, 1)
        let archiveURL = try XCTUnwrap(outputArchives.first)
        
        let dataDirectoryContents = try relativeFilePathsIn(.dataSubdirectory, of: archiveURL)
        
        #if swift(>=5.9)
        XCTAssertEqual(dataDirectoryContents, expectedDataContentWithExtendedTypes)
        #else
        XCTAssertEqual(dataDirectoryContents, expectedDataContentWithoutExtendedTypes)
        #endif
    }
    
    func testGenerateDocumentationWithDisablementFlag() throws {
        let result = try swiftPackage(
            "generate-documentation", "--exclude-extended-types",
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "LibraryTargetWithExtensionSymbols")
        )
        
        result.assertExitStatusEquals(0)
        let outputArchives = result.referencedDocCArchives
        XCTAssertEqual(outputArchives.count, 1)
        let archiveURL = try XCTUnwrap(outputArchives.first)
        
        XCTAssertEqual(try relativeFilePathsIn(.dataSubdirectory, of: archiveURL), expectedDataContentWithoutExtendedTypes)
    }
    
    func testGenerateDocumentationWithEnablementFlag() throws {
        let result = try swiftPackage(
            "generate-documentation", "--include-extended-types",
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "LibraryTargetWithExtensionSymbols")
        )
        
        result.assertExitStatusEquals(0)
        let outputArchives = result.referencedDocCArchives
        XCTAssertEqual(outputArchives.count, 1)
        let archiveURL = try XCTUnwrap(outputArchives.first)
        
        XCTAssertEqual(try relativeFilePathsIn(.dataSubdirectory, of: archiveURL), expectedDataContentWithExtendedTypes)
    }
}

private let expectedDataContentWithoutExtendedTypes = [
    "documentation/library.json",
    "documentation/library/customfooconvertible.json",
    "documentation/library/customfooconvertible/asfoo.json",
    "documentation/library/foo.json",
    "documentation/library/foo/foo().json",
]

private let expectedDataContentWithExtendedTypes =
    expectedDataContentWithoutExtendedTypes + expectedDataExtendedTypesContent

private let expectedDataExtendedTypesContent = [
    "documentation/library/swift.json",
    "documentation/library/swift/array.json",
    "documentation/library/swift/array/isarray.json",
    "documentation/library/swift/int.json",
    "documentation/library/swift/int/asfoo.json",
    "documentation/library/swift/int/customfooconvertible-implementations.json",
    "documentation/library/swift/int/isarray.json",
]
