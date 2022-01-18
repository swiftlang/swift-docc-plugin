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
    /// Invokes the swift package CLI with the given arguments.
    func swiftPackage(
        _ arguments: String,
        workingDirectory directoryURL: URL? = nil
    ) throws -> SwiftInvocationResult {
        let process = Process()
        process.executableURL = currentShellURL
        process.environment = [
            "SWIFTPM_ENABLE_COMMAND_PLUGINS" : "1",
        ]
        process.arguments = [
            "-c", "swift package \(arguments)",
        ]
        process.currentDirectoryURL = directoryURL
        
        let standardOutput = Pipe()
        let standardError = Pipe()
        
        process.standardOutput = standardOutput
        process.standardError = standardError
        
        try process.run()
        process.waitUntilExit()
        
        return SwiftInvocationResult(
            standardOutput: try standardOutput.asString() ?? "",
            standardError: try standardError.asString() ?? "",
            exitStatus: Int(process.terminationStatus)
        )
    }
}

struct SwiftInvocationResult {
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
}
