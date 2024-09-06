// swift-tools-version: 5.7
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
import PackageDescription

let package = Package(
    name: "TargetsWithDependencies",
    targets: [
        // Outer
        // ├─ InnerFirst
        // ╰─ InnerSecond
        //    ╰─ NestedInner
        .target(name: "Outer", dependencies: [
            "InnerFirst",
            "InnerSecond",
        ]),
        .target(name: "InnerFirst"),
        .target(name: "InnerSecond", dependencies: [
            "NestedInner"
        ]),
        .target(name: "NestedInner"),
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
