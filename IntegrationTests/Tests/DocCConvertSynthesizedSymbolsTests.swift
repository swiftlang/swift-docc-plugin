// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
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
        let doccArchiveURL = try XCTUnwrap(result.referencedDocCArchives.first)
        let dataDirectoryContents = try filesIn(.dataSubdirectory, of: doccArchiveURL)
        XCTAssertEqual(
            Set(dataDirectoryContents.map(\.lastTwoPathComponents)),
            [
                "documentation/packagewithconformancesymbols.json",
                "packagewithconformancesymbols/foo.json"
            ]
        )
    }
    
    func testGenerateDocumentationWithSynthesizedSymbols() throws {
        let result = try swiftPackage(
            "generate-documentation",
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "PackageWithConformanceSymbols")
        )
        
        result.assertExitStatusEquals(0)
        let doccArchiveURL = try XCTUnwrap(result.referencedDocCArchives.first)
        let dataDirectoryContents = try filesIn(.dataSubdirectory, of: doccArchiveURL)
        XCTAssertEqual(
            Set(dataDirectoryContents.map(\.lastTwoPathComponents)),
            [
                "documentation/packagewithconformancesymbols.json",
                "packagewithconformancesymbols/foo.json",
                "foo/equatable-implementations.json",
                "foo/!=(_:_:).json"
            ]
        )
    }
}
