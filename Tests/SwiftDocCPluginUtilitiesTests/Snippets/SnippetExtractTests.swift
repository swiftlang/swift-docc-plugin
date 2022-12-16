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
@testable import snippet_extract

final class SnippetExtractTests: XCTestCase {
    lazy var workingDirectory = URL(
        fileURLWithPath: "/test-working-directory",
        isDirectory: true
    )
    
    lazy var snippetExtractor = SnippetExtractor(
        snippetTool: URL(fileURLWithPath: "/snippet-tool", isDirectory: false),
        workingDirectory: workingDirectory
    )
    
    func testSnippetGeneration() throws {
        let expectedFilePaths: Set<String> = [
            "/my/package/Snippets",
            "/test-working-directory/.build/symbol-graphs/snippet-symbol-graphs/MyPackage-package-id/MyPackage-snippets.symbols.json",
        ]
        let existingFilePaths: Set<String> = [
            "/my/package/Snippets",
            "/test-working-directory/.build/symbol-graphs/snippet-symbol-graphs/MyPackage-package-id/MyPackage-snippets.symbols.json",
        ]
        snippetExtractor._fileExists = { path in
            XCTAssertTrue(
                expectedFilePaths.contains(path),
                "Unexpected file path: '\(path)'"
            )
            
            return existingFilePaths.contains(path)
        }

        snippetExtractor._findSnippetFilesInDirectory = { _  in
            [
                "/my/package/Snippets/A.swift",
                "/my/package/Snippets/B.swift",
                "/my/package/Snippets/C.swift",
            ]
        }
        
        var snippetExtractorRunProcessCount = 0
        snippetExtractor._runProcess = { process in
            if snippetExtractorRunProcessCount == 0 {
                XCTAssertEqual(
                    process.arguments,
                    [
                        "--output", "/test-working-directory/.build/symbol-graphs/snippet-symbol-graphs/MyPackage-package-id/MyPackage-snippets.symbols.json",
                        "--module-name", "MyPackage",
                        "/my/package/Snippets/A.swift",
                        "/my/package/Snippets/B.swift",
                        "/my/package/Snippets/C.swift",
                    ]
                )
            } else {
                XCTFail("Snippet extract process ran unexpectedly.")
            }
            
            snippetExtractorRunProcessCount += 1
        }
        
        // Assert that generating snippets for the same package multiple times
        // only invokes the snippet-extract process once
        for _ in 1...10 {
            let snippetFile = try snippetExtractor.generateSnippets(
                for: "package-id",
                packageDisplayName: "MyPackage",
                packageDirectory: URL(fileURLWithPath: "/my/package")
            )
            
            XCTAssertEqual(snippetExtractorRunProcessCount, 1)
            XCTAssertEqual(
                snippetFile?.path,
                "/test-working-directory/.build/symbol-graphs/snippet-symbol-graphs/MyPackage-package-id/MyPackage-snippets.symbols.json"
            )
        }
    }
    
    func testSnippetGenerationForNonSnippetPackage() throws {
        let expectedFilePaths: Set<String> = [
            "/my/package/Snippets",
        ]
        
        snippetExtractor._fileExists = { path in
            XCTAssertTrue(
                expectedFilePaths.contains(path),
                "Unexpected file path: '\(path)'"
            )
            
            // Return false when the snippet extract checks for the existence
            // of a snippets directory
            return false
        }

        snippetExtractor._findSnippetFilesInDirectory = { _ in [] }
        
        snippetExtractor._runProcess = { process in
            XCTFail("Snippet extract process ran for package that does not contain snippets.")
        }
        
        let snippetDirectory = try snippetExtractor.generateSnippets(
            for: "package-id",
            packageDisplayName: "MyPackage",
            packageDirectory: URL(fileURLWithPath: "/my/package")
        )
        
        XCTAssertNil(snippetDirectory)
    }
    
    func testSnippetGenerationForMultiplePackages() throws {
        let expectedFilePaths: Set<String> = [
            "/my/package/Snippets",
            "/test-working-directory/.build/symbol-graphs/snippet-symbol-graphs/MyPackage-package-id/MyPackage-snippets.symbols.json",
            "/my/other/package/Snippets",
            "/test-working-directory/.build/symbol-graphs/snippet-symbol-graphs/MyOtherPackage-other-package-id/MyOtherPackage-snippets.symbols.json",
        ]
        let existingFilePaths: Set<String> = [
            "/my/package/Snippets",
            "/test-working-directory/.build/symbol-graphs/snippet-symbol-graphs/MyPackage-package-id/MyPackage-snippets.symbols.json",
            "/my/other/package/Snippets",
            "/test-working-directory/.build/symbol-graphs/snippet-symbol-graphs/MyOtherPackage-other-package-id/MyOtherPackage-snippets.symbols.json",
        ]
        snippetExtractor._fileExists = { path in
            XCTAssertTrue(
                expectedFilePaths.contains(path),
                "Unexpected file path: '\(path)'"
            )
            
            return existingFilePaths.contains(path)
        }

        snippetExtractor._findSnippetFilesInDirectory = { _  in
            [
                "/my/package/Snippets/A.swift",
                "/my/package/Snippets/B.swift",
                "/my/package/Snippets/C.swift",
            ]
        }
        
        var snippetExtractorRunProcessCount = 0
        snippetExtractor._runProcess = { process in
            if snippetExtractorRunProcessCount == 0 {
                XCTAssertEqual(
                    process.arguments,
                    [
                        "--output", "/test-working-directory/.build/symbol-graphs/snippet-symbol-graphs/MyPackage-package-id/MyPackage-snippets.symbols.json",
                        "--module-name", "MyPackage",
                        "/my/package/Snippets/A.swift",
                        "/my/package/Snippets/B.swift",
                        "/my/package/Snippets/C.swift",
                    ]
                )
            } else if snippetExtractorRunProcessCount == 1 {
                XCTAssertEqual(
                    process.arguments,
                    [
                        "--output", "/test-working-directory/.build/symbol-graphs/snippet-symbol-graphs/MyOtherPackage-other-package-id/MyOtherPackage-snippets.symbols.json",
                        "--module-name", "MyOtherPackage",
                        "/my/package/Snippets/A.swift",
                        "/my/package/Snippets/B.swift",
                        "/my/package/Snippets/C.swift",
                    ]
                )
            } else {
                XCTFail("Snippet extract process ran unexpectedly.")
            }
            snippetExtractorRunProcessCount += 1
        }
        
        for _ in 1...10 {
            let snippetSymbolGraphFile = try snippetExtractor.generateSnippets(
                for: "package-id",
                packageDisplayName: "MyPackage",
                packageDirectory: URL(fileURLWithPath: "/my/package")
            )
            
            XCTAssertEqual(snippetExtractorRunProcessCount, 1)
            XCTAssertEqual(
                snippetSymbolGraphFile?.path,
                "/test-working-directory/.build/symbol-graphs/snippet-symbol-graphs/MyPackage-package-id/MyPackage-snippets.symbols.json"
            )
        }
        
        for _ in 1...10 {
            let snippetSymbolGraphFile = try snippetExtractor.generateSnippets(
                for: "other-package-id",
                packageDisplayName: "MyOtherPackage",
                packageDirectory: URL(fileURLWithPath: "/my/other/package")
            )
            
            XCTAssertEqual(snippetExtractorRunProcessCount, 2)
            XCTAssertEqual(
                snippetSymbolGraphFile?.path,
                "/test-working-directory/.build/symbol-graphs/snippet-symbol-graphs/MyOtherPackage-other-package-id/MyOtherPackage-snippets.symbols.json"
            )
        }
    }

    /// If there are no snippets present in the Snippets directory, the snippet-extract tool should not run.
    func testSnippetGenerationForPackageWithSnippetsDirectoryButNoSnippets() throws {
        let expectedFilePaths: Set<String> = [
            "/test-working-directory/.build/symbol-graphs/snippet-symbol-graphs/MyPackage-package-id",
            "/my/package/Snippets",
        ]
        let existingFilePaths: Set<String> = [
            "/my/package/Snippets",
            // Don't include the .build directory here to simulate the situation
            // where we have a `Snippets` directory but running the snippet-extract tool
            // on them doesn't produce snippets.
        ]
        snippetExtractor._fileExists = { path in
            XCTAssertTrue(
                expectedFilePaths.contains(path),
                "Unexpected file path: '\(path)'"
            )
            
            return existingFilePaths.contains(path)
        }

        snippetExtractor._findSnippetFilesInDirectory = { _ in [] }
        
        var snippetExtractorRunProcessCount = 0
        snippetExtractor._runProcess = { process in
            if snippetExtractorRunProcessCount == 0 {
                XCTAssertEqual(
                    process.arguments,
                    [
                        "output", "/test-working-directory/.build/symbol-graphs/snippet-symbol-graphs/MyPackage-package-id/MyPackage-snippets.symbols.json",
                        "--module-name", "MyPackage",
                    ]
                )
            } else {
                XCTFail("Snippet extract process ran unexpectedly.")
            }
            
            snippetExtractorRunProcessCount += 1
        }

        let snippetDirectory = try snippetExtractor.generateSnippets(
            for: "package-id",
            packageDisplayName: "MyPackage",
            packageDirectory: URL(fileURLWithPath: "/my/package")
        )

        XCTAssertEqual(snippetExtractorRunProcessCount, 0)
        XCTAssertNil(snippetDirectory)
    }

    func testSnippetExtractArguments() throws {
        // Valid
        XCTAssertNoThrow(try SnippetExtractCommand(arguments: [
            "--output", "/tmp/somewhere/Something-snippets.symbols.json",
            "--module-name", "Something",
            "Snippets/A.swift"
        ]))

        let command = try SnippetExtractCommand(arguments: [
            "--output", "/tmp/somewhere/Something-snippets.symbols.json",
            "--module-name", "Something",
            "Snippets/A.swift"
        ])
        XCTAssertEqual(command.moduleName, "Something")
        XCTAssertEqual(command.outputFile, "/tmp/somewhere/Something-snippets.symbols.json")
        XCTAssertEqual(command.snippetFiles, ["Snippets/A.swift"])
        
        // Missing Output Dir
        XCTAssertThrowsError(try SnippetExtractCommand(arguments: [
            "--module-name", "Something",
            "Snippets/A.swift",
        ]), "Expected missing option --output error", { (error: Error) in
            let argumentError = error as? SnippetExtractCommand.ArgumentError
            XCTAssertNotNil(argumentError)
            guard case let .missingOption(option) = argumentError,
                  case .outputFile = option else {
                XCTFail("Expected missingOption(.outputDirectory) error")
                return
            }
        })

        // Missing Module Name
        XCTAssertThrowsError(try SnippetExtractCommand(arguments: [
            "--output", "/tmp/somewhere/Something-snippets.symbols.json",
            "Snippets/A.swift",
        ]), "Expected missing option --module-name error", { (error: Error) in
            let argumentError = error as? SnippetExtractCommand.ArgumentError
            XCTAssertNotNil(argumentError)
            guard case let .missingOption(option) = argumentError,
                  case .moduleName = option else {
                XCTFail("Expected missingOption(.moduleName) error")
                return
            }
        })

        // Missing Inputs
        XCTAssertNoThrow(try SnippetExtractCommand(arguments: [
            "--output", "/tmp/somewhere/Something-snippets.symbols.json",
            "--module-name", "Something",
        ]))
    }
}
