// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
import XCTest

extension XCTestCase {
    func swiftPackageProcess(
        _ arguments: [CustomStringConvertible],
        workingDirectory directoryURL: URL? = nil
    ) throws -> Process {
        let process = Process()
        process.executableURL = try swiftExecutableURL
        process.environment = ProcessInfo.processInfo.environment
        
        process.arguments = ["package"] + arguments.map(\.description)
        process.currentDirectoryURL = directoryURL
        return process
    }
    
    /// Invokes the swift package CLI with the given arguments.
    func swiftPackage(
        _ arguments: CustomStringConvertible...,
        workingDirectory directoryURL: URL
    ) throws -> SwiftInvocationResult {
        let process = try swiftPackageProcess(arguments, workingDirectory: directoryURL)
        
        let standardOutputPipe = Pipe()
        let standardErrorPipe = Pipe()
        
        process.standardOutput = standardOutputPipe
        process.standardError = standardErrorPipe

        let processQueue = DispatchQueue(label: "process")
        var standardOutputData = Data()
        var standardErrorData = Data()

        standardOutputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            processQueue.async {
                standardOutputData.append(data)
            }
        }

        standardErrorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            processQueue.async {
                standardErrorData.append(data)
            }
        }

        try process.run()
        process.waitUntilExit()

        standardOutputPipe.fileHandleForReading.readabilityHandler = nil
        standardErrorPipe.fileHandleForReading.readabilityHandler = nil

        processQueue.async {
            standardOutputPipe.fileHandleForReading.closeFile()
            standardErrorPipe.fileHandleForReading.closeFile()
        }

        return try processQueue.sync {
            let standardOutputString = String(data: standardOutputData, encoding: .utf8)
            let standardErrorString = String(data: standardErrorData, encoding: .utf8)

            return SwiftInvocationResult(
                workingDirectory: directoryURL,
                swiftExecutable: try swiftExecutableURL,
                arguments: arguments.map(\.description),
                standardOutput: standardOutputString ?? "",
                standardError: standardErrorString ?? "",
                exitStatus: Int(process.terminationStatus)
            )
        }
    }
    
    private var swiftExecutableURL: URL {
        get throws {
            let whichProcess = Process.shell("which swift")
            
            let standardOutputPipe = Pipe()
            whichProcess.standardOutput = standardOutputPipe
            
            try whichProcess.run()
            whichProcess.waitUntilExit()
            
            let swiftExecutablePath = try XCTUnwrap(
                standardOutputPipe.asString()
            ).trimmingCharacters(in: .newlines)
            
            // Explicitly refer to 'swift' here since 'which swift' returns ../usr/bin/swift-frontend
            // instead of /usr/bin/swift on SwiftCI.
            return URL(fileURLWithPath: swiftExecutablePath)
                .resolvingSymlinksInPath()
                .deletingLastPathComponent()
                .appendingPathComponent("swift")
        }
    }
}

struct SwiftInvocationResult {
    let workingDirectory: URL
    let swiftExecutable: URL
    let arguments: [String]
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

    var pluginOutputsDirectory: URL {
        let pluginWorkingSubdirectory: String
        if arguments.contains("preview-documentation") {
            pluginWorkingSubdirectory = "Swift-DocC Preview"
        } else {
            pluginWorkingSubdirectory = "Swift-DocC"
        }

        return workingDirectory
            .appendingPathComponent(".build", isDirectory: true)
            .appendingPathComponent("plugins", isDirectory: true)
            .appendingPathComponent(pluginWorkingSubdirectory, isDirectory: true)
            .appendingPathComponent("outputs", isDirectory: true)
    }

    var symbolGraphsDirectory: URL {
        return pluginOutputsDirectory
            .appendingPathComponent(".build", isDirectory: true)
            .appendingPathComponent("symbol-graphs", isDirectory: true)
    }

    private func gatherShellEnvironmentInfo() throws -> String {
        let gatherEnvironmentProcess = Process.shell(
            """
            echo -n "pwd: " && pwd && \
            echo "which swift: \(swiftExecutable.path)" && \
            \(swiftExecutable.path) --version && \
            \(swiftExecutable.path) package --version
            """,
            workingDirectory: workingDirectory
        )
        
        let gatherEnvironmentPipe = Pipe()
        gatherEnvironmentProcess.standardOutput = gatherEnvironmentPipe
        gatherEnvironmentProcess.standardError = gatherEnvironmentPipe
        
        try gatherEnvironmentProcess.run()
        gatherEnvironmentProcess.waitUntilExit()
        return try gatherEnvironmentPipe.asString() ?? "unknown"
    }
    
    func assertExitStatusEquals(
        _ expectedExitStatus: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let environmentInfo = (
            try? gatherShellEnvironmentInfo()
        ) ?? "failed to gather environment information"
        
        XCTAssertEqual(
            exitStatus, expectedExitStatus,
            """
            Expected exit status of '\(expectedExitStatus)' and found '\(exitStatus)'.
            Shell environment information:
            \(environmentInfo)
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

extension Pipe {
    func asString() throws -> String? {
        return try fileHandleForReading.readToEnd().flatMap {
            String(data: $0, encoding: .utf8)
        }
    }
}

extension Process {
    private static let currentShellURL: URL = {
        return URL(fileURLWithPath: ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/sh")
    }()

    fileprivate static func shell(_ arguments: String, workingDirectory directoryURL: URL? = nil) -> Process {
        let process = Process()
        process.executableURL = currentShellURL
        process.environment = ProcessInfo.processInfo.environment
        process.arguments = [
            "-c", arguments,
        ]
        process.currentDirectoryURL = directoryURL
        
        return process
    }
}
