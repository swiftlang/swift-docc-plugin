// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
@testable import SwiftDocCPluginUtilities
import XCTest

final class ParsedArgumentsTests: XCTestCase {
    func testHelp() {
        XCTAssertTrue(
            ParsedArguments(["--help"]).help
        )
        
        XCTAssertTrue(
            ParsedArguments(["-h"]).help
        )
        
        XCTAssertTrue(
            ParsedArguments(["--other-flag", "--help"]).help
        )
        
        XCTAssertTrue(
            ParsedArguments(["--other-flag", "-h"]).help
        )
        
        XCTAssertTrue(
            ParsedArguments(["--other-flag", "-h", "--help", "argument"]).help
        )
        
        XCTAssertFalse(
            ParsedArguments(["--other-flag"]).help
        )
        
        XCTAssertFalse(
            ParsedArguments(["--other-flag", "argument"]).help
        )
        
        XCTAssertFalse(
            ParsedArguments(["--hel"]).help
        )
    }
    
    func testDocCArgumentsForNoArguments() {
        let arguments = ParsedArguments([])
        
        XCTAssertEqual(
            arguments.doccArguments(
                action: .convert,
                targetKind: .library,
                doccCatalogPath: nil,
                targetName: "MyTarget",
                symbolGraphDirectoryPath: "/my/symbol-graph",
                outputPath: "/my/output-path"
            ),
            [
                "convert",
                "--emit-lmdb-index",
                "--fallback-display-name", "MyTarget",
                "--fallback-bundle-identifier", "MyTarget",
                "--additional-symbol-graph-dir", "/my/symbol-graph",
                "--output-path", "/my/output-path"
            ]
        )
        
        XCTAssertEqual(
            arguments.doccArguments(
                action: .preview,
                targetKind: .library,
                doccCatalogPath: nil,
                targetName: "MyTarget",
                symbolGraphDirectoryPath: "/my/symbol-graph",
                outputPath: "/my/output-path"
            ),
            [
                "preview",
                "--emit-lmdb-index",
                "--fallback-display-name", "MyTarget",
                "--fallback-bundle-identifier", "MyTarget",
                "--additional-symbol-graph-dir", "/my/symbol-graph",
                "--output-path", "/my/output-path"
            ]
        )
        
        XCTAssertEqual(
            arguments.doccArguments(
                action: .convert,
                targetKind: .library,
                doccCatalogPath: "/my/catalog.docc",
                targetName: "MyTarget",
                symbolGraphDirectoryPath: "/my/symbol-graph",
                outputPath: "/my/output-path"
            ),
            [
                "convert",
                "/my/catalog.docc",
                "--emit-lmdb-index",
                "--fallback-display-name", "MyTarget",
                "--fallback-bundle-identifier", "MyTarget",
                "--additional-symbol-graph-dir", "/my/symbol-graph",
                "--output-path", "/my/output-path"
            ]
        )
    }
    
    func testDocCArgumentsForOneArgument() {
        let argumentsWithDisplayName = ParsedArguments(
            ["--fallback-display-name", "custom-display-name"]
        )
        
        XCTAssertEqual(
            argumentsWithDisplayName.doccArguments(
                action: .convert,
                targetKind: .library,
                doccCatalogPath: nil,
                targetName: "MyTarget",
                symbolGraphDirectoryPath: "/my/symbol-graph",
                outputPath: "/my/output-path"
            ),
            [
                "convert",
                "--fallback-display-name", "custom-display-name",
                "--emit-lmdb-index",
                "--fallback-bundle-identifier", "MyTarget",
                "--additional-symbol-graph-dir", "/my/symbol-graph",
                "--output-path", "/my/output-path"
            ]
        )
        
        let argumentsWithBundleIdentifier = ParsedArguments(
            ["--fallback-bundle-identifier", "custom-bundle-identifier"]
        )
        
        XCTAssertEqual(
            argumentsWithBundleIdentifier.doccArguments(
                action: .convert,
                targetKind: .library,
                doccCatalogPath: nil,
                targetName: "MyTarget",
                symbolGraphDirectoryPath: "/my/symbol-graph",
                outputPath: "/my/output-path"
            ),
            [
                "convert",
                "--fallback-bundle-identifier", "custom-bundle-identifier",
                "--emit-lmdb-index",
                "--fallback-display-name", "MyTarget",
                "--additional-symbol-graph-dir", "/my/symbol-graph",
                "--output-path", "/my/output-path"
            ]
        )
        
        let argumentsWithSymbolGraphDir = ParsedArguments(
            ["--additional-symbol-graph-dir", "/my/custom/symbol-graph"]
        )
        
        XCTAssertEqual(
            argumentsWithSymbolGraphDir.doccArguments(
                action: .convert,
                targetKind: .library,
                doccCatalogPath: nil,
                targetName: "MyTarget",
                symbolGraphDirectoryPath: "/my/symbol-graph",
                outputPath: "/my/output-path"
            ),
            [
                "convert",
                "--additional-symbol-graph-dir", "/my/custom/symbol-graph",
                "--emit-lmdb-index",
                "--fallback-display-name", "MyTarget",
                "--fallback-bundle-identifier", "MyTarget",
                "--output-path", "/my/output-path",
            ]
        )
        
        let argumentsWithOutputPath = ParsedArguments(
            ["--output-path", "/my/custom/output-path"]
        )
        
        XCTAssertEqual(
            argumentsWithOutputPath.doccArguments(
                action: .convert,
                targetKind: .library,
                doccCatalogPath: nil,
                targetName: "MyTarget",
                symbolGraphDirectoryPath: "/my/symbol-graph",
                outputPath: "/my/output-path"
            ),
            [
                "convert",
                "--output-path", "/my/custom/output-path",
                "--emit-lmdb-index",
                "--fallback-display-name", "MyTarget",
                "--fallback-bundle-identifier", "MyTarget",
                "--additional-symbol-graph-dir", "/my/symbol-graph",
            ]
        )
    }
    
    func testDocCArgumentsForSomeArguments() {
        let argumentsWithDisplayNameAndBundleIdentifier = ParsedArguments(
            [
                "--fallback-display-name", "custom-display-name",
                "--fallback-bundle-identifier", "custom-bundle-identifier",
            ]
        )
        
        XCTAssertEqual(
            argumentsWithDisplayNameAndBundleIdentifier.doccArguments(
                action: .convert,
                targetKind: .library,
                doccCatalogPath: nil,
                targetName: "MyTarget",
                symbolGraphDirectoryPath: "/my/symbol-graph",
                outputPath: "/my/output-path"
            ),
            [
                "convert",
                "--fallback-display-name", "custom-display-name",
                "--fallback-bundle-identifier", "custom-bundle-identifier",
                "--emit-lmdb-index",
                "--additional-symbol-graph-dir", "/my/symbol-graph",
                "--output-path", "/my/output-path",
            ]
        )
        
        let argumentsWithAllRequiredOptions = ParsedArguments(
            [
                "--fallback-display-name", "custom-display-name",
                "--fallback-bundle-identifier", "custom-bundle-identifier",
                "--additional-symbol-graph-dir", "/my/custom/symbol-graph",
                "--output-path", "/my/custom/output-path",
            ]
        )
        
        XCTAssertEqual(
            argumentsWithAllRequiredOptions.doccArguments(
                action: .convert,
                targetKind: .library,
                doccCatalogPath: nil,
                targetName: "MyTarget",
                symbolGraphDirectoryPath: "/my/symbol-graph",
                outputPath: "/my/output-path"
            ),
            [
                "convert",
                "--fallback-display-name", "custom-display-name",
                "--fallback-bundle-identifier", "custom-bundle-identifier",
                "--additional-symbol-graph-dir", "/my/custom/symbol-graph",
                "--output-path", "/my/custom/output-path",
                "--emit-lmdb-index",
            ]
        )
    }
    
    func testDisableIndexing() {
        let disableIndexingArguments = ParsedArguments(
            ["--disable-indexing"]
        )
        
        XCTAssertEqual(
            disableIndexingArguments.doccArguments(
                action: .convert,
                targetKind: .library,
                doccCatalogPath: "/my/catalog.docc",
                targetName: "MyTarget",
                symbolGraphDirectoryPath: "/my/symbol-graph",
                outputPath: "/my/output-path"
            ),
            [
                "convert",
                "/my/catalog.docc",
                "--fallback-display-name", "MyTarget",
                "--fallback-bundle-identifier", "MyTarget",
                "--additional-symbol-graph-dir", "/my/symbol-graph",
                "--output-path", "/my/output-path"
            ]
        )
        
        let noIndexingArguments = ParsedArguments(
            ["--no-indexing"]
        )
        
        XCTAssertEqual(
            noIndexingArguments.doccArguments(
                action: .convert,
                targetKind: .library,
                doccCatalogPath: "/my/catalog.docc",
                targetName: "MyTarget",
                symbolGraphDirectoryPath: "/my/symbol-graph",
                outputPath: "/my/output-path"
            ),
            [
                "convert",
                "/my/catalog.docc",
                "--fallback-display-name", "MyTarget",
                "--fallback-bundle-identifier", "MyTarget",
                "--additional-symbol-graph-dir", "/my/symbol-graph",
                "--output-path", "/my/output-path"
            ]
        )
        
        let disableIndexingWithCustomOutputArguments = ParsedArguments(
            [
                "--disable-indexing",
                "--output-path", "/custom/output-path"
            ]
        )
        
        XCTAssertEqual(
            disableIndexingWithCustomOutputArguments.doccArguments(
                action: .convert,
                targetKind: .library,
                doccCatalogPath: "/my/catalog.docc",
                targetName: "MyTarget",
                symbolGraphDirectoryPath: "/my/symbol-graph",
                outputPath: "/my/output-path"
            ),
            [
                "convert",
                "/my/catalog.docc",
                "--output-path", "/custom/output-path",
                "--fallback-display-name", "MyTarget",
                "--fallback-bundle-identifier", "MyTarget",
                "--additional-symbol-graph-dir", "/my/symbol-graph",
            ]
        )
    }
    
    func testDocCArgumentsWithAdditionalOptions() {
        let argumentsWithTransformForStaticHosting = ParsedArguments(
            ["--transform-for-static-hosting"]
        )
        
        XCTAssertEqual(
            argumentsWithTransformForStaticHosting.doccArguments(
                action: .convert,
                targetKind: .library,
                doccCatalogPath: "/my/catalog.docc",
                targetName: "MyTarget",
                symbolGraphDirectoryPath: "/my/symbol-graph",
                outputPath: "/my/output-path"
            ),
            [
                "convert",
                "/my/catalog.docc",
                "--transform-for-static-hosting",
                "--emit-lmdb-index",
                "--fallback-display-name", "MyTarget",
                "--fallback-bundle-identifier", "MyTarget",
                "--additional-symbol-graph-dir", "/my/symbol-graph",
                "--output-path", "/my/output-path"
            ]
        )
        
        let argumentsWithMixOfRequiredAndOptional = ParsedArguments(
            [
                "--transform-for-static-hosting",
                "--port", "1802",
                "--analyze",
                "--fallback-display-name", "custom-display-name",
                "--output-path", "/my/custom/output-path",
            ]
        )
        
        XCTAssertEqual(
            argumentsWithMixOfRequiredAndOptional.doccArguments(
                action: .preview,
                targetKind: .library,
                doccCatalogPath: "/my/catalog.docc",
                targetName: "MyTarget",
                symbolGraphDirectoryPath: "/my/symbol-graph",
                outputPath: "/my/output-path"
            ),
            [
                "preview",
                "/my/catalog.docc",
                "--transform-for-static-hosting",
                "--port", "1802",
                "--analyze",
                "--fallback-display-name", "custom-display-name",
                "--output-path", "/my/custom/output-path",
                "--emit-lmdb-index",
                "--fallback-bundle-identifier", "MyTarget",
                "--additional-symbol-graph-dir", "/my/symbol-graph",
            ]
        )
    }
    
    func testDocCArgumentsForExecutableTarget() {
        let emptyArguments = ParsedArguments(
            []
        )
        
        XCTAssertEqual(
            emptyArguments.doccArguments(
                action: .convert,
                targetKind: .executable,
                doccCatalogPath: "/my/catalog.docc",
                targetName: "MyTarget",
                symbolGraphDirectoryPath: "/my/symbol-graph",
                outputPath: "/my/output-path"
            ),
            [
                "convert",
                "/my/catalog.docc",
                "--emit-lmdb-index",
                "--fallback-display-name", "MyTarget",
                "--fallback-bundle-identifier", "MyTarget",
                "--additional-symbol-graph-dir", "/my/symbol-graph",
                "--output-path", "/my/output-path",
                "--fallback-default-module-kind", "Command-line Tool",
            ]
        )
        
        let fallbackDefaultModuleKindSpecified = ParsedArguments(
            ["--fallback-default-module-kind", "Executable"]
        )
        
        XCTAssertEqual(
            fallbackDefaultModuleKindSpecified.doccArguments(
                action: .convert,
                targetKind: .executable,
                doccCatalogPath: "/my/catalog.docc",
                targetName: "MyTarget",
                symbolGraphDirectoryPath: "/my/symbol-graph",
                outputPath: "/my/output-path"
            ),
            [
                "convert",
                "/my/catalog.docc",
                "--fallback-default-module-kind", "Executable",
                "--emit-lmdb-index",
                "--fallback-display-name", "MyTarget",
                "--fallback-bundle-identifier", "MyTarget",
                "--additional-symbol-graph-dir", "/my/symbol-graph",
                "--output-path", "/my/output-path",
            ]
        )
    }
    
    func testDocCArgumentsWithDumpSymbolGraphArguments() {
        let dumpSymbolGraphArguments = ParsedArguments(["--include-extended-types", "--experimental-skip-synthesized-symbols"])
        
        let doccArguments = dumpSymbolGraphArguments.doccArguments(
            action: .convert,
            targetKind: .executable,
            doccCatalogPath: "/my/catalog.docc",
            targetName: "MyTarget",
            symbolGraphDirectoryPath: "/my/symbol-graph",
            outputPath: "/my/output-path"
        )
        
        XCTAssertFalse(doccArguments.contains("--include-extended-types"))
        XCTAssertFalse(doccArguments.contains("--experimental-skip-synthesized-symbols"))
    }
    
    func testDumpSymbolGraphArguments() {
        var dumpSymbolGraphArguments: ParsedArguments
        
        dumpSymbolGraphArguments = ParsedArguments(["--include-extended-types", "--experimental-skip-synthesized-symbols"])
        XCTAssertEqual(dumpSymbolGraphArguments.symbolGraphArguments, [.extendedTypes.positive, .skipSynthesizedSymbols])
        
        dumpSymbolGraphArguments = ParsedArguments(["--exclude-extended-types", "--experimental-skip-synthesized-symbols"])
        XCTAssertEqual(dumpSymbolGraphArguments.symbolGraphArguments, [.extendedTypes.negative, .skipSynthesizedSymbols])
        
        dumpSymbolGraphArguments = ParsedArguments(["--include-extended-types", "--experimental-skip-synthesized-symbols", "--exclude-extended-types"])
        XCTAssertEqual(dumpSymbolGraphArguments.symbolGraphArguments, [.extendedTypes.negative, .skipSynthesizedSymbols])
        
        dumpSymbolGraphArguments = ParsedArguments(["--exclude-extended-types", "--include-extended-types"])
        XCTAssertEqual(dumpSymbolGraphArguments.symbolGraphArguments, [.extendedTypes.positive])
    }
    
    func testDumpSymbolGraphArgumentsWithDocCArguments() {
        let dumpSymbolGraphArguments = ParsedArguments(["--fallback-default-module-kind", "Executable"])
        
        
        XCTAssertEqual(dumpSymbolGraphArguments.symbolGraphArguments, [])
    }
}
