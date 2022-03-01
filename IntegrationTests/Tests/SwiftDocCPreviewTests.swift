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
    func testRunPreviewServerOnSamePortRepeatedly() async throws {
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
            let process = try swiftPackageProcess(
                ["--disable-sandbox", "preview-documentation", "--port", port],
                workingDirectory: try setupTemporaryDirectoryForFixture(named: "SingleExecutableTarget")
            )
            
            let outputPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = outputPipe
            
            try process.run()
            
            var processOutput = ""
            var previewServerHasStarted: Bool {
                processOutput += outputPipe.availableOutput ?? ""
                
                // We expect `docc` to emit a message like this when starting
                // the preview server:
                //
                //     ========================================
                //     Starting Local Preview Server
                //           Address: http://localhost:8000/documentation/executable
                //     ========================================
                return processOutput.contains("Starting Local Preview Server")
            }
            
            var count = 0
            while !previewServerHasStarted && count < 60 {
                // Sleep 0.25 seconds before re-checking process output to
                // see if `docc` has finished compiling docs and has started the preview server.
                try await Task.sleep(nanoseconds: 250000000)
                
                // We'll wait a maximum of 15 seconds. (This generally takes about 0.5 seconds locally)
                count += 1
            }
            
            // Wait an additional half second
            try await Task.sleep(nanoseconds: 500000000)
            
            guard process.isRunning else {
                XCTFail(
                    """
                    Preview server failed to start on iteration '\(index)'.
                    
                    Process output: \(processOutput)
                    """
                )
                return
            }
            
            // Sleep 1.5 seconds
            try await Task.sleep(nanoseconds: 1500000000)
            
            // Assert that long-running preview server process is still running after 2 seconds
            XCTAssertTrue(process.isRunning, "Preview server failed early on iteration '\(index)'.")
            
            // Send an interrupt to the SwiftPM parent process
            process.interrupt()
        }
    }
}
