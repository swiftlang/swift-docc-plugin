// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022-2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import XCTest

final class SnippetDocumentationGenerationTests: ConcurrencyRequiringTestCase {
    func testGenerateDocumentationForPackageWithSnippets() throws {
        let packageName = "PackageWithSnippets"
        let result = try swiftPackage(
            "generate-documentation",
            "--target", "Library",
            workingDirectory: try setupTemporaryDirectoryForFixture(named: packageName)
        )

        result.assertExitStatusEquals(0)
        let archiveURL = try XCTUnwrap(result.onlyOutputArchive)
        
        XCTAssertEqual(try relativeFilePathsIn(.dataSubdirectory, of: archiveURL), [
            "documentation/library.json",
            "documentation/library/beststruct.json",
            "documentation/library/beststruct/best().json",
            "documentation/library/beststruct/init().json",
        ])
        
        let symbolGraphSubDirectories = try FileManager.default.contentsOfDirectory(
            at: result.symbolGraphsDirectory,
            includingPropertiesForKeys: nil,
            options: .producesRelativePathURLs
        )
        XCTAssertEqual(symbolGraphSubDirectories.map(\.relativePath).sorted(), [
            "snippet-symbol-graphs",
            "unified-symbol-graphs",
        ])
        
        let unifiedSymbolGraphDirectory = try XCTUnwrap(symbolGraphSubDirectories.last)
        let symbolGraphFileNames = try filesIn(unifiedSymbolGraphDirectory).map(\.lastPathComponent)
        XCTAssert(symbolGraphFileNames.contains([
            "\(packageName)-snippets.symbols.json"
        ]))
    }

    func testPreviewDocumentationWithSnippets() throws {
        let outputDirectory = try temporaryDirectory().appendingPathComponent("output")

        let port = try getAvailablePort()

        let process = try swiftPackageProcess(
            [
                "--disable-sandbox",
                "--allow-writing-to-directory", outputDirectory.path,
                "preview-documentation",
                "--target", "Library",
                "--port", port,
                "--output-path", outputDirectory.path,
            ],
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "PackageWithSnippets")
        )

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        try process.run()

        var previewServerHasStarted: Bool {
            // We expect docc to emit a `data` directory at the root of the
            // given output path when it's finished compilation.
            //
            // At this point we can expect that the preview server will start imminently.
            return FileManager.default.fileExists(
                atPath: outputDirectory.appendingPathComponent("data", isDirectory: true).path
            )
        }

        let previewServerHasStartedExpectation = expectation(description: "Preview server started.")

        let checkPreviewServerTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { timer in
            if previewServerHasStarted {
                previewServerHasStartedExpectation.fulfill()
                timer.invalidate()
            }
        }

        wait(for: [previewServerHasStartedExpectation], timeout: 15)
        checkPreviewServerTimer.invalidate()

        guard process.isRunning else {
            XCTFail(
                """
                Preview server failed to start.

                Process output:
                \(try outputPipe.asString() ?? "nil")
                """
            )
            return
        }

        // Send an interrupt to the SwiftPM parent process
        process.interrupt()
    }
}
