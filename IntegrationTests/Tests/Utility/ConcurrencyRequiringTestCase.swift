// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
import XCTest

/// A test case that requires the host toolchain to support Swift concurrency in order
/// to pass.
///
/// All SwiftPM command plugins depend on Swift concurrency so we don't expect to be able
/// to run any integration test that actually invokes the Swift-DocC Plugin without
/// the Swift concurrency libraries.
class ConcurrencyRequiringTestCase: XCTestCase {
    override func setUpWithError() throws {
        try XCTSkipUnless(
            supportsSwiftConcurrency(),
            "The current SDK and/or OS do not support Swift concurrency."
        )
    }
    
    private static var _supportsSwiftConcurrency: Bool?
    
    // Adapted from https://github.com/apple/swift-package-manager/blob/dd7e9cc6/Sources/SPMTestSupport/Toolchain.swift#L55
    private func supportsSwiftConcurrency() throws -> Bool {
#if os(macOS)
        if #available(macOS 12.0, *) {
            // On macOS 12 and later, concurrency is assumed to work.
            return true
        } else {
            if let _supportsSwiftConcurrency = Self._supportsSwiftConcurrency {
                return _supportsSwiftConcurrency
            }
            
            let temporaryDirectory = try temporaryDirectory()
            
            // On macOS 11 and earlier, we don't know if concurrency actually works because not all
            // SDKs and toolchains have the right bits.  We could examine the SDK and the various
            // libraries, but the most accurate test is to just try to compile and run a snippet of
            // code that requires async/await support.  It doesn't have to actually do anything,
            // it's enough that all the libraries can be found (but because the library reference
            // is weak we do need the linkage reference to `_swift_task_create` and the like).
            do {
                let inputPath = temporaryDirectory.appendingPathComponent("foo.swift")
                
                try """
                public func foo() async {}
                
                Task { await foo() }
                """.write(to: inputPath, atomically: true, encoding: .utf8)
                
                let outputPath = temporaryDirectory.appendingPathComponent("foo")
                let process = Process()
                process.executableURL = try swiftExecutableURL
                    .deletingLastPathComponent()
                    .appendingPathComponent("swiftc")
                
                process.arguments = [inputPath.path, "-o", outputPath.path]
                
                try process.run()
                process.waitUntilExit()
                guard process.terminationStatus == EXIT_SUCCESS else {
                    Self._supportsSwiftConcurrency = false
                    return false
                }
            } catch {
                // On any failure we assume false.
                Self._supportsSwiftConcurrency = false
                return false
            }
            // If we get this far we could compile and run a trivial executable that uses
            // libConcurrency, so we can say that this toolchain supports concurrency on this host.
            Self._supportsSwiftConcurrency = true
            return true
        }
#else
        // On other platforms, concurrency is assumed to work since with new enough versions
        // of the toolchain.
        return true
#endif
    }
}

