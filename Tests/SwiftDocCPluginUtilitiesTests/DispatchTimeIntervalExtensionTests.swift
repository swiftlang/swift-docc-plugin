// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
import SwiftDocCPluginUtilities
import XCTest

final class DispatchTimeIntervalExtensionTests: XCTestCase {
    func testDescriptionInSeconds() {
        XCTAssertEqual(DispatchTimeInterval.nanoseconds(1000).descriptionInSeconds, "0.00s")
        XCTAssertEqual(DispatchTimeInterval.nanoseconds(10000000).descriptionInSeconds, "0.01s")
        XCTAssertEqual(DispatchTimeInterval.nanoseconds(6000000000).descriptionInSeconds, "6.00s")
        
        XCTAssertEqual(DispatchTimeInterval.microseconds(1000).descriptionInSeconds, "0.00s")
        XCTAssertEqual(DispatchTimeInterval.microseconds(10000).descriptionInSeconds, "0.01s")
        XCTAssertEqual(DispatchTimeInterval.microseconds(8000000).descriptionInSeconds, "8.00s")
        XCTAssertEqual(DispatchTimeInterval.microseconds(185009000).descriptionInSeconds, "185.01s")
        
        XCTAssertEqual(DispatchTimeInterval.milliseconds(200).descriptionInSeconds, "0.20s")
        XCTAssertEqual(DispatchTimeInterval.milliseconds(1000).descriptionInSeconds, "1.00s")
        XCTAssertEqual(DispatchTimeInterval.milliseconds(80040).descriptionInSeconds, "80.04s")
        
        XCTAssertEqual(DispatchTimeInterval.seconds(5).descriptionInSeconds, "5.00s")
        XCTAssertEqual(DispatchTimeInterval.seconds(305).descriptionInSeconds, "305.00s")
        
        XCTAssertEqual(DispatchTimeInterval.never.descriptionInSeconds, "n/a")
    }
}
