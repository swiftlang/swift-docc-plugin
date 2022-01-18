// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

/// Transforms a set of arguments.
protocol ArgumentsTransforming {
    /// Apply the transformation to the given arguments.
    func transform(_ arguments: Arguments) -> Arguments
}
