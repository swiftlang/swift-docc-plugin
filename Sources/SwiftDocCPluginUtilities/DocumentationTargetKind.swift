// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022-2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

/// A Swift-DocC documentation target kind.
enum DocumentationTargetKind: String {
    /// A Swift Package Manager library target.
    case library
    
    /// A Swift Package Manager executable target.
    case executable
}
