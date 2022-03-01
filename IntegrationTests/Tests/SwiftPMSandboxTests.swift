// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import XCTest

final class SwiftPMSandboxTests: XCTestCase {
    func testEnableAdditionalSandboxedDirectories() throws {
        let outputDirectory = try temporaryDirectory()
        
        let result = try swiftPackage(
            "--allow-writing-to-directory", outputDirectory.path,
            "generate-documentation",
            "--output-path", outputDirectory.path,
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "SingleLibraryTarget")
        )
        
        result.assertExitStatusEquals(0)
    }
}
