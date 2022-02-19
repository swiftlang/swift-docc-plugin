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
    /// A Boolean value that is true if the test case is running in Swift CI.
    var runningInSwiftCI: Bool {
        return ProcessInfo.processInfo.environment["SWIFTCI"] != nil
    }
}
