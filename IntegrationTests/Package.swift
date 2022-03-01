// swift-tools-version: 5.5
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import PackageDescription

let package = Package(
    name: "IntegrationTests",
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
    ],
    targets: [
        .testTarget(
            name: "IntegrationTests",
            dependencies: [
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
            ],
            path: "Tests",
            resources: [
                .copy("Fixtures/SingleLibraryTarget"),
                .copy("Fixtures/SingleTestTarget"),
                .copy("Fixtures/SingleExecutableTarget"),
                .copy("Fixtures/MixedTargets"),
                .copy("Fixtures/TargetWithDocCCatalog"),
            ]
        ),
    ]
)
