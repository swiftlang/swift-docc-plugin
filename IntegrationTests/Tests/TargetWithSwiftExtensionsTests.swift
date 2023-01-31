// This source file is part of the Swift.org open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
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
    
    func testGenerateDocumentationWithoutEnablementFlag() throws {
        let result = try swiftPackage(
            "generate-documentation",
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "LibraryTargetWithExtensionSymbols")
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
                
                "library/customfooconvertible.json",
                "customfooconvertible/asfoo.json",
            ]
        )
    }
    
    func testGenerateDocumentationWithEnablementFlag() throws {
        let result = try swiftPackage(
            "generate-documentation",
            "--include-extended-types",
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "LibraryTargetWithExtensionSymbols")
        )
        
        result.assertExitStatusEquals(0)
        XCTAssertEqual(result.referencedDocCArchives.count, 1)
        
        let doccArchiveURL = try XCTUnwrap(result.referencedDocCArchives.first)
        
        let dataDirectoryContents = try filesIn(.dataSubdirectory, of: doccArchiveURL)
        
        XCTAssertEqual(
            Set(dataDirectoryContents.map(\.lastTwoPathComponents)),
            [
                "documentation/library.json",
                "library/swift.json",
                
                "swift/int.json",
                "int/isarray.json",
                "int/asfoo.json",
                "int/customfooconvertible-implementations.json",
                
                "swift/array.json",
                "array/isarray.json",
                
                "library/foo.json",
                "foo/foo().json",
                
                "library/customfooconvertible.json",
                "customfooconvertible/asfoo.json",
            ]
        )
    }
}
