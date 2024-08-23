// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation

/// A wrapper around NSLock.
///
/// This type exist to offer an alternative to `NSLock.withLock` on Linux before Swift 6.0.
struct Lock {
    private let innerLock = NSLock()
    
    func withLock<Result>(_ body: () throws -> Result) rethrows -> Result {
        // Use `lock()` and `unlock()` because Linux doesn't support `NSLock.withLock` before Swift 6.0
        innerLock.lock()
        defer { innerLock.unlock() }
        
        return try body()
    }
}
