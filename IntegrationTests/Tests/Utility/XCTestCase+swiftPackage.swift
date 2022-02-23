// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
import XCTest

private let currentShellURL: URL = {
    return URL(fileURLWithPath: ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/sh")
}()

extension XCTestCase {
    func swiftPackageProcess(
        _ arguments: String,
        workingDirectory directoryURL: URL? = nil
    ) throws -> Process {
        let process = Process()
        process.executableURL = currentShellURL
        process.environment = [
            "SWIFTPM_ENABLE_COMMAND_PLUGINS" : "1",
        ]
        process.arguments = [
            "-c", "swift package \(arguments)",
        ]
        process.currentDirectoryURL = directoryURL
        
        return process
    }
    
    /// Invokes the swift package CLI with the given arguments.
    func swiftPackage(
        _ arguments: String,
        workingDirectory directoryURL: URL? = nil
    ) throws -> SwiftInvocationResult {
        let process = try swiftPackageProcess(arguments, workingDirectory: directoryURL)
        
        let standardOutput = Pipe()
        let standardError = Pipe()
        
        process.standardOutput = standardOutput
        process.standardError = standardError
        
        try process.run()
        process.waitUntilExit()
        
        return SwiftInvocationResult(
            arguments: arguments,
            standardOutput: try standardOutput.asString() ?? "",
            standardError: try standardError.asString() ?? "",
            exitStatus: Int(process.terminationStatus)
        )
    }
}

struct SwiftInvocationResult {
    let arguments: String
    let standardOutput: String
    let standardError: String
    let exitStatus: Int
    
    var referencedDocCArchives: [URL] {
        return standardOutput
            .components(separatedBy: .whitespacesAndNewlines)
            .map { component in
                return component.trimmingCharacters(in: CharacterSet(charactersIn: "'."))
            }
            .filter { component in
                return component.hasSuffix(".doccarchive")
            }
            .compactMap(URL.init(fileURLWithPath:))
    }
    
    func assertExitStatusEquals(
        _ expectedExitStatus: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            exitStatus, expectedExitStatus,
            """
            Expected exit status of '\(expectedExitStatus)' and found '\(exitStatus)'.
            Swift package arguments:
            \(arguments)
            
            Standard error:
            \(standardError)
            
            Standard output:
            \(standardOutput)
            """,
            file: file, line: line
        )
    }
}

enum ProcessError: Error {
    case nonZeroExitStatus
}

extension Pipe {
    func asString() throws -> String? {
        return try fileHandleForReading.readToEnd().flatMap {
            String(data: $0, encoding: .utf8)
        }
    }
    
    var availableOutput: String? {
        return String(data: fileHandleForReading.availableData, encoding: .utf8)
    }
}
