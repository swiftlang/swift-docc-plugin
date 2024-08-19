// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022-2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
@testable import SwiftDocCPluginUtilities
import XCTest

final class ParsedArgumentsTests: XCTestCase {
    func testHelp() {
        XCTAssertTrue(ParsedArguments(["--help"]).pluginArguments.help)
        
        XCTAssertTrue(ParsedArguments(["-h"]).pluginArguments.help)
        
        XCTAssertTrue(ParsedArguments(["--other-flag", "--help"]).pluginArguments.help)
        
        XCTAssertTrue(ParsedArguments(["--other-flag", "-h"]).pluginArguments.help)
        
        XCTAssertTrue(ParsedArguments(["--other-flag", "-h", "--help", "argument"]).pluginArguments.help)
        
        XCTAssertFalse(ParsedArguments(["--other-flag"]).pluginArguments.help)
        
        XCTAssertFalse(ParsedArguments(["--other-flag", "argument"]).pluginArguments.help)
        
        XCTAssertFalse(ParsedArguments(["--hel"]).pluginArguments.help)
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
        XCTAssertEqual(argumentsWithOutputPath.outputDirectory?.path, "/my/custom/output-path")
        
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
                "--emit-lmdb-index",
                "--fallback-display-name", "MyTarget",
                "--fallback-bundle-identifier", "MyTarget",
                "--additional-symbol-graph-dir", "/my/symbol-graph",
                "--output-path", "/my/output-path",
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
        
        let argumentsWithFallbackInfoAndOutputPath = ParsedArguments(
            [
                "--fallback-display-name", "custom-display-name",
                "--fallback-bundle-identifier", "custom-bundle-identifier",
                "--additional-symbol-graph-dir", "/my/custom/symbol-graph",
                "--output-path", "/my/custom/output-path",
            ]
        )
        XCTAssertEqual(argumentsWithFallbackInfoAndOutputPath.outputDirectory?.path, "/my/custom/output-path")
        
        XCTAssertEqual(
            argumentsWithFallbackInfoAndOutputPath.doccArguments(
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
                "--emit-lmdb-index",
                "--output-path", "/my/output-path",
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
        
        let disableIndexingWithCustomOutputArguments = ParsedArguments([
            "--disable-indexing",
            "--output-path", "/custom/output-path"
        ])
        XCTAssertEqual(disableIndexingWithCustomOutputArguments.outputDirectory?.path, "/custom/output-path")
        
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
                "--fallback-display-name", "MyTarget",
                "--fallback-bundle-identifier", "MyTarget",
                "--additional-symbol-graph-dir", "/my/symbol-graph",
                "--output-path", "/my/output-path",
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
        
        let argumentsWithOutputPath = ParsedArguments(
            [
                "--transform-for-static-hosting",
                "--port", "1802",
                "--analyze",
                "--fallback-display-name", "custom-display-name",
                "--output-path", "/my/custom/output-path",
            ]
        )
        XCTAssertEqual(argumentsWithOutputPath.outputDirectory?.path, "/my/custom/output-path")
        
        XCTAssertEqual(
            argumentsWithOutputPath.doccArguments(
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
                "--emit-lmdb-index",
                "--fallback-bundle-identifier", "MyTarget",
                "--additional-symbol-graph-dir", "/my/symbol-graph",
                "--output-path", "/my/output-path",
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
    
    func testSymbolGraphArguments() {
        do {
            let arguments = ParsedArguments(["--include-extended-types", "--experimental-skip-synthesized-symbols", "--symbol-graph-minimum-access-level", "internal"])
            
            XCTAssertEqual(arguments.symbolGraphArguments.includeExtendedTypes, true)
            XCTAssertEqual(arguments.symbolGraphArguments.skipSynthesizedSymbols, true)
            XCTAssertEqual(arguments.symbolGraphArguments.minimumAccessLevel, "internal")
        }
        
        do {
            let arguments = ParsedArguments(["--exclude-extended-types", "--experimental-skip-synthesized-symbols"])
            
            XCTAssertEqual(arguments.symbolGraphArguments.includeExtendedTypes, false)
            XCTAssertEqual(arguments.symbolGraphArguments.skipSynthesizedSymbols, true)
            XCTAssertNil(arguments.symbolGraphArguments.minimumAccessLevel)
        }
        
        do {
            let arguments = ParsedArguments(["--include-extended-types", "--experimental-skip-synthesized-symbols", "--exclude-extended-types"])
            
            XCTAssertEqual(arguments.symbolGraphArguments.includeExtendedTypes, false)
            XCTAssertEqual(arguments.symbolGraphArguments.skipSynthesizedSymbols, true)
            XCTAssertNil(arguments.symbolGraphArguments.minimumAccessLevel)
        }
        do {
            let arguments = ParsedArguments(["--exclude-extended-types", "--include-extended-types"])
            
            XCTAssertEqual(arguments.symbolGraphArguments.includeExtendedTypes, true)
            XCTAssertNil(arguments.symbolGraphArguments.skipSynthesizedSymbols)
            XCTAssertNil(arguments.symbolGraphArguments.minimumAccessLevel)
        }
    }
    
    func testDefaultSymbolGraphArguments() {
        let arguments = ParsedArguments(["--fallback-default-module-kind", "Executable"])
        
        XCTAssertNil(arguments.symbolGraphArguments.includeExtendedTypes)
        XCTAssertNil(arguments.symbolGraphArguments.skipSynthesizedSymbols)
        XCTAssertNil(arguments.symbolGraphArguments.minimumAccessLevel)
    }
}
