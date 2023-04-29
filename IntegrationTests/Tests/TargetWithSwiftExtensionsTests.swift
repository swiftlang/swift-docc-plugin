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
    
    func testGenerateDocumentationWithoutExtendedTypesFlag() throws {
        let result = try swiftPackage(
            "generate-documentation",
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "LibraryTargetWithExtensionSymbols")
        )
        
        let dataDirectoryContents = try unwrapDataDirectoryContents(of: result)
        
        #if swift(>=5.9)
        try assertDirectoryContentsWithExtendedTypes(dataDirectoryContents)
        #else
        try assertDirectoryContentsWithoutExtendedTypes(dataDirectoryContents)
        #endif
    }
    
    func testGenerateDocumentationWithDisablementFlag() throws {
        let result = try swiftPackage(
            "generate-documentation",
            "--exclude-extended-types",
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "LibraryTargetWithExtensionSymbols")
        )
        
        let dataDirectoryContents = try unwrapDataDirectoryContents(of: result)
        
        try assertDirectoryContentsWithoutExtendedTypes(dataDirectoryContents)
    }
    
    func testGenerateDocumentationWithEnablementFlag() throws {
        let result = try swiftPackage(
            "generate-documentation",
            "--include-extended-types",
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "LibraryTargetWithExtensionSymbols")
        )
        
        let dataDirectoryContents = try unwrapDataDirectoryContents(of: result)
        
        try assertDirectoryContentsWithExtendedTypes(dataDirectoryContents)
    }
    
    func assertDirectoryContentsWithExtendedTypes(_ contents: [URL],
                                                  _ message: @autoclosure () -> String = "",
                                                  file: StaticString = #filePath,
                                                  line: UInt = #line) throws {
        XCTAssertEqual(
            Set(contents.map(\.lastTwoPathComponents)),
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
            ],
            message(),
            file: file,
            line: line
        )
    }
    
    func assertDirectoryContentsWithoutExtendedTypes(_ contents: [URL],
                                                     _ message: @autoclosure () -> String = "",
                                                     file: StaticString = #filePath,
                                                     line: UInt = #line) throws {
        XCTAssertEqual(
            Set(contents.map(\.lastTwoPathComponents)),
            [
                "documentation/library.json",
                
                "library/foo.json",
                "foo/foo().json",
                
                "library/customfooconvertible.json",
                "customfooconvertible/asfoo.json",
            ],
            message(),
            file: file,
            line: line
        )
    }
    
    func unwrapDataDirectoryContents(of result: SwiftInvocationResult,
                                     _ message: @autoclosure () -> String = "",
                                     file: StaticString = #filePath,
                                     line: UInt = #line) throws -> [URL] {
        result.assertExitStatusEquals(0)
        XCTAssertEqual(result.referencedDocCArchives.count, 1, message(), file: file, line: line)
        
        let doccArchiveURL = try XCTUnwrap(result.referencedDocCArchives.first, message(), file: file, line: line)
        
        return try filesIn(.dataSubdirectory, of: doccArchiveURL)
    }
}
