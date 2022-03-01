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
    /// Waits for the specified time.
    func wait(for timeInterval: TimeInterval) {
        let waitForTimeIntervalExpectation = expectation(
            description: "Wait for '\(timeInterval)' second(s)."
        )
        
        let waitTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { timer in
            waitForTimeIntervalExpectation.fulfill()
            timer.invalidate()
        }
        
        wait(for: [waitForTimeIntervalExpectation], timeout: timeInterval + 5.0)
        waitTimer.invalidate()
    }
}
