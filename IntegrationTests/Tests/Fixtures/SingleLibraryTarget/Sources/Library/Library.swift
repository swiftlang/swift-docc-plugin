// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

/// This is foo's documentation.
///
/// Foo is a public struct and should be included in documentation.
public struct Foo {
    public func foo() {}
}

/// This is bar's documentation.
///
/// Bar is an internal struct and should not be included in documentation.
struct Bar {
    func bar() {}
}
