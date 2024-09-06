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
    
    // Only create arguments from flags or options (with a value)
    
    init(_ flag: Flag) {
        names = flag.names
        kind = .flag
    }
    
    init(_ option: Option, value: String) {
        names = option.names
        kind = .option(value: value)
    }
}

extension CommandLineArgument {
    /// A flag argument without an associated value.
    ///
    /// For example: `"--some-flag"`.
    public struct Flag {
        public var names: Names
        
        /// Creates a new command line flag
        ///
        /// - Parameters:
        ///   - preferred: The preferred name for this flag.
        ///   - alternatives: A collection of alternative names for this flag.
        public init(preferred: String, alternatives: Set<String> = []) {
            // This is duplicating the `Names` parameters to offer a nicer initializer for the common case.
            names = .init(preferred: preferred, alternatives: alternatives)
        }
    }
    
    /// An option argument that will eventually associated with a value.
    ///
    /// For example: `"--some-option", "value"` or `"--some-option=value"`.
    public struct Option {
        public var names: Names
        
        /// Creates a new command line option.
        ///
        /// - Parameters:
        ///   - preferred: The preferred name for this option.
        ///   - alternatives: A collection of alternative names for this option.
        public init(preferred: String, alternatives: Set<String> = []) {
            // This is duplicating the `Names` parameters to offer a nicer initializer for the common case.
            self.init(
                Names(preferred: preferred, alternatives: alternatives)
            )
        }
        
        init(_ names: Names) {
            self.names = names
        }
    }
}
