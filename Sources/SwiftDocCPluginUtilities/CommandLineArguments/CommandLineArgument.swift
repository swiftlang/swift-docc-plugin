// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

/// A named command line argument; either a flag or an option with a value.
public struct CommandLineArgument {
    /// The names of this command line argument.
    public var names: Names
    /// The kind of command line argument.
    public var kind: Kind
    
    /// A collection of names for a command line argument.
    public struct Names: Hashable {
        /// The preferred name for this command line argument.
        public var preferred: String
        /// All possible names for this command line argument.
        public var all: Set<String>
        
        /// Creates a new command line argument collection of names.
        ///
        /// - Parameters:
        ///   - preferred: The preferred name for this command line argument.
        ///   - alternatives: A collection of alternative names for this command line argument.
        public init(preferred: String, alternatives: Set<String> = []) {
            self.all = alternatives.union([preferred])
            self.preferred = preferred
        }
    }
    
    /// A kind of command line argument.
    public enum Kind {
        /// A flag argument without an associated value.
        ///
        /// For example: `"--some-flag"`.
        case flag
        /// An option argument with an associated value.
        ///
        /// For example: `"--some-option", "value"` or `"--some-option=value"`.
        case option(value: String)
    }
    
    /// Creates a new command line flag with the given names.
    /// - Parameters:
    ///   - names: The names for the new command line flag.
    public static func flag(_ names: Names) -> Self {
        .init(names: names, kind: .flag)
    }
    
    /// Creates a new command option with the given names and associated value.
    /// - Parameters:
    ///   - names: The names for the new command line option.
    ///   - value: The value that's associated with this command line option.
    public static func option(_ names: Names, value: String) -> Self {
        .init(names: names, kind: .option(value: value))
    }
}
