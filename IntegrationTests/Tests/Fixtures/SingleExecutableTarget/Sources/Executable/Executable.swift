// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

/// This is foo's documentation.
///
/// Foo is an internal struct and should be included in documentation.
@main struct Foo {
    func foo() {}
    
    static func main() {}
    
    init() {}
}

/// This is bar's documentation.
///
/// Bar is a private struct and should not be included in documentation.
private struct Bar {
    private func bar() {}
    
    private init() {}
}
