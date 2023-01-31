// This source file is part of the Swift.org open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
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

/// This is the documentation for ``Swift/Array``.
///
/// This is the extension to ``Array`` with the longest documentation
/// comment, thus it is used for doucmenting the extended type in this
/// target.
extension Array {
    /// This is the documentation for the ``isArray`` property
    /// we added to ``Swift/Array``.
    ///
    /// This is a public extension to an external type and should be included
    /// in the documentation.
    public var isArray: Bool { true }
}

/// This is the documentation for ``Swift/Int``.
///
/// This is the extension to ``Int`` with the longest documentation
/// comment, thus it is used for doucmenting the extended type in this
/// target.
extension Int {
    /// This is the documentation for the ``isArray`` property
    /// we added to ``Swift/Int``.
    ///
    /// This is a public extension to an external type and should be included
    /// in the documentation.
    public var isArray: Bool { false }
}


/// This is the documentation for ``CustomFooConvertible``.
///
/// This is a public protocol and should be included in the documentation.
public protocol CustomFooConvertible {
    /// This is the documentation for ``CustomFooConvertible/asFoo``.
    ///
    /// This is a public protocol requirement and should be included in the documentation.
    var asFoo: Foo { get }
}

/// This is not used as the documentation comment for ``Swift/Int``
/// as it is shorter than the comment on the other extension to `Int`.
extension Int: CustomFooConvertible {
    /// This is the documentation for ``Swift/Int/asFoo``.
    ///
    /// This is a public protocol requirement implementation and should be included in the documentation.
    public var asFoo: Foo { Foo() }
}
