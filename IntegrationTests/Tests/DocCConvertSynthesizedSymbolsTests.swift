// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022-2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import XCTest

final class DocCConvertSynthesizedSymbolsTests: ConcurrencyRequiringTestCase {
    func testGenerateDocumentationWithSkipSynthesizedSymbolsEnabled() throws {
        let result = try swiftPackage(
            "generate-documentation", "--experimental-skip-synthesized-symbols",
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "PackageWithConformanceSymbols")
        )
        
        result.assertExitStatusEquals(0)
        let archiveURL = try XCTUnwrap(result.onlyOutputArchive)
        
        XCTAssertEqual(try relativeFilePathsIn(.dataSubdirectory, of: archiveURL), [
            "documentation/packagewithconformancesymbols.json",
            "documentation/packagewithconformancesymbols/foo.json",
        ])
    }
    
    func testGenerateDocumentationWithSynthesizedSymbols() throws {
        let result = try swiftPackage(
            "generate-documentation",
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "PackageWithConformanceSymbols")
        )
        
        result.assertExitStatusEquals(0)
        let archiveURL = try XCTUnwrap(result.onlyOutputArchive)
        
        XCTAssertEqual(try relativeFilePathsIn(.dataSubdirectory, of: archiveURL), [
            "documentation/packagewithconformancesymbols.json",
            "documentation/packagewithconformancesymbols/foo.json",
            "documentation/packagewithconformancesymbols/foo/!=(_:_:).json",
            "documentation/packagewithconformancesymbols/foo/equatable-implementations.json",
        ])
    }
}
