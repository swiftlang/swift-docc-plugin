// swift-tools-version: 5.6
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
import PackageDescription

let package = Package(
    name: "SingleExecutableTarget",
    targets: [
        .executableTarget(name: "Executable"),
    ]
)

// We only expect 'swift-docc-plugin' to be a sibling when this package
// is running as part of a test.
//
// This allows the package to compile outside of tests for easier
// test development.
if FileManager.default.fileExists(atPath: "../swift-docc-plugin") {
    package.dependencies += [
        .package(path: "../swift-docc-plugin"),
    ]
}
