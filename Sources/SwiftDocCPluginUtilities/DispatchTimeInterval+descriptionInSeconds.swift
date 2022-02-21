// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation

// These extensions are slightly modified version of the ones originally declared in the
// Swift Package Manager here:
// https://github.com/apple/swift-package-manager/blob/beac985/Sources/Basics/DispatchTimeInterval+Extensions.swift
extension DispatchTimeInterval {
    /// A description of the current time interval suitable for presentation, in seconds.
    ///
    /// Emits a value to a precision of 2 decimal points. For example, this might be `"42.08s"`, or
    /// `"0.00s"`, or `"3.04s"`.
    public var descriptionInSeconds: String {
        switch self {
        case .seconds(let value):
            return "\(value).00s"
        case .milliseconds(let value):
            return String(format: "%.2f", Double(value)/Double(1000)) + "s"
        case .microseconds(let value):
            return String(format: "%.2f", Double(value)/Double(1_000_000)) + "s"
        case .nanoseconds(let value):
            return String(format: "%.2f", Double(value)/Double(1_000_000_000)) + "s"
        case .never:
            return "n/a"
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        @unknown default:
            return "n/a"
        #endif
        }
    }
}

// `distance(to:)` is currently only available on macOS. This should be removed
// when it's available on all platforms.
#if os(Linux) || os(Windows) || os(Android) || os(OpenBSD)
extension DispatchTime {
    public func distance(to: DispatchTime) -> DispatchTimeInterval {
        let duration = to.uptimeNanoseconds - self.uptimeNanoseconds
        return .nanoseconds(duration >= Int.max ? Int.max : Int(duration))
    }
}
#endif
