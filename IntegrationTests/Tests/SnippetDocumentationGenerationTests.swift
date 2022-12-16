// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import XCTest

final class SnippetDocumentationGenerationTests: ConcurrencyRequiringTestCase {
    func testGenerateDocumentationForPackageWithSnippets() throws {
        let result = try swiftPackage(
            "generate-documentation",
            "--target", "Library",
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "PackageWithSnippets")
        )

        result.assertExitStatusEquals(0)
        XCTAssertEqual(result.referencedDocCArchives.count, 1)

        let doccArchiveURL = try XCTUnwrap(result.referencedDocCArchives.first)

        let dataDirectoryContents = try filesIn(.dataSubdirectory, of: doccArchiveURL)

        XCTAssertEqual(
            Set(dataDirectoryContents.map(\.lastTwoPathComponents)),
            [
                "documentation/library.json",
                "library/beststruct.json",
                "beststruct/init().json",
                "beststruct/best().json",
            ]
        )

        let subDirectoriesOfSymbolGraphDirectory = try FileManager.default.contentsOfDirectory(
            at: result.symbolGraphsDirectory,
            includingPropertiesForKeys: nil
        )

        XCTAssertEqual(
            Set(subDirectoriesOfSymbolGraphDirectory.map(\.lastTwoPathComponents)),
            [
                "symbol-graphs/snippet-symbol-graphs",
                "symbol-graphs/unified-symbol-graphs",
            ]
        )
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
