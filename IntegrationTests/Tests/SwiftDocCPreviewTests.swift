// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
import XCTest

final class SwiftDocCPreview: XCTestCase {
    func testRunPreviewServerOnSamePortRepeatedly() throws {
        // Because only a single server can bind to a given port at a time,
        // this test ensures that the preview server running in the `docc`
        // process exits when the an interrupt is sent to the `SwiftPM` process.
        //
        // If it doesn't, subsequent runs of the preview server on the same port will
        // fail because `docc` is still bound to it.
        
        // First ask the system for an available port. If we use an already bound port,
        // this test will fail for unrelated reasons.
        let port = try getAvailablePort()
        
        for index in 1...3 {
            let outputDirectory = try temporaryDirectory().appendingPathComponent("output")
            
            let process = try swiftPackageProcess(
                [
                    "--disable-sandbox",
                    "--allow-writing-to-directory", outputDirectory.path,
                    "preview-documentation",
                    "--port", port,
                    "--output-path", outputDirectory.path
                ],
                workingDirectory: try setupTemporaryDirectoryForFixture(named: "SingleExecutableTarget")
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
            
            guard previewServerHasStarted else {
                XCTFail(
                    """
                    Preview server never started on iteration '\(index)'.
                    
                    Process output:
                    \(try outputPipe.asString() ?? "nil")
                    """
                )
                return
            }
            
            // Wait an additional half second
            wait(for: 0.5)
            
            guard process.isRunning else {
                XCTFail(
                    """
                    Preview server failed to start on iteration '\(index)'.
                    
                    Process output:
                    \(try outputPipe.asString() ?? "nil")
                    """
                )
                return
            }
            
            // Wait 1.5 seconds
            wait(for: 1.5)
            
            // Assert that long-running preview server process is still running after 2 seconds
            guard process.isRunning else {
                XCTFail(
                    """
                    Preview server failed early on iteration '\(index)'.
                    
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
}
