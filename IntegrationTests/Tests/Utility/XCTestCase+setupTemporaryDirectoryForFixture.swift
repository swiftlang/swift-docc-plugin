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
    /// Identifies the location of the parent Swift-DocC plugin package.
    ///
    /// This integration test suite is nested inside of the primary Swift-DocC plugin package.
    static let swiftDocCPluginPackage = URL(
        fileURLWithPath: #file,
        isDirectory: false
    )
    // Utility:
    .deletingLastPathComponent()
    // Tests:
    .deletingLastPathComponent()
    // IntegrationTests:
    .deletingLastPathComponent()
    // swift-docc-plugin
    .deletingLastPathComponent()
    
    /// Copies the given test fixture to a temporary directory and returns the URL for
    /// its temporary testing location.
    func setupTemporaryDirectoryForFixture(named testFixtureName: String) throws -> URL {
        let temporaryDirectoryURL = try temporaryDirectory()
        
        // Get the url for the requested test package
        let testFixtureURL = try XCTUnwrap(
            Bundle.module.url(
                forResource: testFixtureName,
                withExtension: nil
            )
        )
        
        // We'll copy the test package to a new location in the new temporary directory
        let testFixtureTemporaryURL = temporaryDirectoryURL.appendingPathComponent(
            testFixtureURL.lastPathComponent
        )
        
        try FileManager.default.copyDirectoryWithoutHiddenFiles(
            at: testFixtureURL,
            to: testFixtureTemporaryURL
        )
        
        // Copy the Swift-DocC plugin to the same temporary testing directory so that its
        // a sibling of the test package.
        try FileManager.default.copyDirectoryWithoutHiddenFiles(
            at: Self.swiftDocCPluginPackage,
            to: temporaryDirectoryURL.appendingPathComponent("swift-docc-plugin"),
            additionalFilter: { url in
                // Skip this integration test sub-package
                url.lastPathComponent != "IntegrationTests"
            }
        )
        
        return testFixtureTemporaryURL
    }
    
    func temporaryDirectory() throws -> URL {
        let resourceURL = try XCTUnwrap(Bundle.module.resourceURL)
        
        // Create a temporary testing directory in the bundle's resource directory
        let temporaryDirectoryURL = resourceURL.appendingPathComponent(
            "TemporaryTestingDirectory-\(ProcessInfo.processInfo.globallyUniqueString)"
        )
        try FileManager.default.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: false)
        
        // Add a teardown block to remove the entire testing directory after the test runs
        addTeardownBlock {
            do {
                try FileManager.default.removeItem(at: temporaryDirectoryURL)
            } catch {
                XCTFail("""
                    Failed to remove temporary testing directory at '\(temporaryDirectoryURL.path)': \
                    '\(error.localizedDescription)'.
                    """
                )
            }
        }
        
        return temporaryDirectoryURL
    }
}
