// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation

/// A collection of command-line arguments
public struct CommandLineArguments {
    /// Creates a new collection of command-line arguments from a list of strings
    public init(_ arguments: [String]) {
        guard let literalSeparator = arguments.firstIndex(of: "--") else {
            remainingOptionsOrFlags = arguments[...]
            literalValues           = []
            return
        }
        
        remainingOptionsOrFlags = arguments[..<literalSeparator]
        literalValues           = arguments[literalSeparator...]
    }
    
    /// All remaining (not-yet extracted) arguments, including any literals after the first `--` separator (if there is one).
    public var remainingArguments: [String] {
        .init(remainingOptionsOrFlags + literalValues)
    }
    
    /// All remaining (not-yet extracted) options or flags, up to the the first `--` separator (if there is one).
    private var remainingOptionsOrFlags: Array<String>.SubSequence
    
    /// All literals after the first `--` separator (if there is one).
    private var literalValues: Array<String>.SubSequence
    
    // MARK: Extract
    
    /// Extracts the values for the given command line option.
    ///
    /// Upon return, the arguments list no longer contains any elements that match any spelling of this command line option or its values.
    ///
    /// - Parameter option: The command line option to extract values for.
    /// - Returns: The extracted values for this command line option, in the order that they appear in the arguments list.
    public mutating func extract(_ option: CommandLineArgument.Option) -> [String] {
        var values = [String]()
        let names = option.names
        
        for (index, argument) in remainingOptionsOrFlags.indexed().reversed() {
            guard let suffix = names.suffixAfterMatchingNamesWith(argument: argument) else {
                continue
            }
            defer { remainingOptionsOrFlags.remove(at: index) }
            
            // "--option-name=value"
            if suffix.first == "=" {
                
                values.append(String(suffix.dropFirst(/* the equal sign */)))
            }
            
            // "--option-name", "value"
            else {
                let indexAfter = remainingOptionsOrFlags.index(after: index)
                if indexAfter < remainingOptionsOrFlags.endIndex {
                    values.append(remainingOptionsOrFlags[indexAfter])
                    
                    remainingOptionsOrFlags.remove(at: indexAfter)
                }
            }
        }

        return values.reversed() // The values are gathered in reverse order
    }
    
    /// Extracts the values for the command line flag.
    ///
    /// Upon return, the arguments list no longer contains any elements that match any spelling of this command line flag.
    ///
    /// - Parameter flag: The command line flag to extract values for.
    /// - Returns: The extracted values for this command line flag.
    public mutating func extract(_ flag: CommandLineArgument.Flag) -> [Bool] {
        let positiveNames = flag.names
        let negativeNames = flag.inverseNames
        let allNamesToCheck = positiveNames.all.union(negativeNames?.all ?? [])
        
        var values = [Bool]()
        for (index, argument) in remainingOptionsOrFlags.indexed().reversed() where allNamesToCheck.contains(argument) {
            remainingOptionsOrFlags.remove(at: index)
            
            values.append(negativeNames == nil || positiveNames.all.contains(argument))
        }
        
        return values.reversed() // The values are gathered in reverse order
    }
    
    // MARK: Insert
    
    /// Inserts a command line option into the arguments list unless it already exists.
    /// - Parameters:
    ///   - option: The command line option to insert.
    ///   - value: The value for this option.
    /// - Returns:  `true` if the argument was already present in the arguments list; otherwise, `false`.
    @discardableResult
    public mutating func insertIfMissing(_ option: CommandLineArgument.Option, value: String) -> Bool {
        remainingOptionsOrFlags.appendIfMissing(.init(option, value: value))
    }
    
    /// Inserts a command line flag into the arguments list unless it already exists.
    /// - Parameter flag: The command line flag to insert.
    /// - Returns:  `true` if the argument was already present in the arguments list; otherwise, `false`.
    @discardableResult
    public mutating func insertIfMissing(_ flag: CommandLineArgument.Flag) -> Bool {
        remainingOptionsOrFlags.appendIfMissing(.init(flag))
    }
    
    /// Adds a raw string argument to the start of the arguments list
    mutating func prepend(rawArgument: String)   {
        remainingOptionsOrFlags.insert(rawArgument, at: 0)
    }
    
    /// Inserts a command line option with a new value into the arguments list, overriding any existing values.
    /// - Parameters:
    ///   - option: The command line option to insert.
    ///   - newValue: The new value for this option.
    /// - Returns: `true` if the argument was already present in the arguments list; otherwise, `false`.
    @discardableResult
    public mutating func overrideOrInsert(_ option: CommandLineArgument.Option, newValue: String) -> Bool {
        let didRemoveArguments = !extract(option).isEmpty
        remainingOptionsOrFlags.append(.init(option, value: newValue))
        return didRemoveArguments
    }
}

// MARK: Helpers

private extension ArraySlice<String> {
    /// Appends the command line argument unless it already exists in the slice.
    /// - Parameter argument: The command line argument (flag or option) to append.
    /// - Returns:  `true` if the argument was already present in the slice; otherwise, `false`.
    @discardableResult
    mutating func appendIfMissing(_ argument: CommandLineArgument) -> Bool {
        guard !contains(argument) else {
            return true
        }
        append(argument)
        return false
    }
    
    /// Appends the given command line argument.
    /// - Parameter argument: The command line argument (flag or option) to append.
    mutating func append(_ argument: CommandLineArgument) {
        switch argument.kind {
        case .flag:
            append(argument.names.preferred)
        case .option(let value, _):
            append(contentsOf: [argument.names.preferred, value])
        }
    }
    
    /// Checks if the slice contains the given argument (flag or option).
    func contains(_ argument: CommandLineArgument) -> Bool {
        let names = argument.names
        guard case .option(let value, .arrayOfValues) = argument.kind else {
            // When matching flags or single-value options, it's sufficient to check if the slice contains any of the names.
            //
            // The slice is considered to contain the single-value option, no matter what the existing value is.
            // This is used to avoid repeating an single-value option with a different value.
            return contains(where: {
                names.suffixAfterMatchingNamesWith(argument: $0) != nil
            })
        }
        
        // When matching options that support arrays of values, it's necessary to check the existing option's value.
        //
        // The slice is only considered to contain the array-of-values option, if the new value is found.
        // This is used to allow array-of-values options to insert multiple different values into the arguments.
        for (argumentIndex, argument) in indexed() {
            guard let suffix = names.suffixAfterMatchingNamesWith(argument: argument) else {
                continue
            }
            
            // "--option-name", "value"
            if suffix.first != "=" {
                let indexAfter = index(after: argumentIndex)
                if indexAfter < endIndex, self[indexAfter] == value {
                    return true
                }
            }
            
            // "--option-name=value"
            else if suffix.dropFirst(/* the equal sign */) == value {
                return true
            }
        }
        // Non of the existing options match the new value.
        return false
    }
}

private extension CommandLineArgument.Names {
    /// Returns the suffix after matching one of the names with the argument, or `nil` of the argument doesn't match any of the names.
    func suffixAfterMatchingNamesWith(argument: String) -> Substring? {
        for name in all where argument.hasPrefix(name) {
            return argument.dropFirst(name.count)
        }
        return nil
    }
}

private extension Collection {
    /// Returns a sequence of pairs `(i, x)`, where `i` represents an index and `x` represents an element of the collection.
    func indexed() -> Zip2Sequence<Indices, Self> {
        zip(indices, self)
    }
}
