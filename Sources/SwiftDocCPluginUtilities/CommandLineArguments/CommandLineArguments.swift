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
    // This is very similar to `PackagePlugin.ArgumentExtractor`.
    // However, because only the plugin itself can import `PackagePlugin` we're unable to test it or our extensions to it.
    // For this reason, new code should use this small implementation instead. 
    
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
    private var remainingOptionsOrFlags: [String].SubSequence
    
    /// All literals after the first `--` separator (if there is one).
    private var literalValues: [String].SubSequence
    
    // MARK: Extract
    
    /// Extracts the values for the command line option with the given names.
    ///
    /// Upon return, the arguments list no longer contains any elements that match any spelling of this command line option or its values.
    ///
    /// - Parameter names: The names of a command line option.
    /// - Returns: The extracted values for this command line option, in the order that they appear in the arguments list.
    public mutating func extractOption(named names: CommandLineArgument.Names) -> [String] {
        var values = [String]()
        
        for (index, argument) in remainingOptionsOrFlags.indexed().reversed() {
            guard let suffix = names.suffixAfterMatchingNamesWith(argument: argument) else {
                continue
            }
            defer { remainingOptionsOrFlags.remove(at: index) }
            
            // "--option-name", "value"
            if suffix.isEmpty {
                let indexAfter = remainingOptionsOrFlags.index(after: index)
                if indexAfter < remainingOptionsOrFlags.endIndex {
                    values.append(remainingOptionsOrFlags[indexAfter])
                    
                    remainingOptionsOrFlags.remove(at: indexAfter)
                }
            }
            
            // "--option-name=value"
            else if suffix.first == "=" {
                values.append(String(suffix.dropFirst(/* the equal sign */)))
            }
        }

        return values.reversed() // The values are gathered in reverse order
    }
    
    /// Extracts the values for the command line flag with the given names.
    ///
    /// Upon return, the arguments list no longer contains any elements that match any spelling of this command line flag.
    ///
    /// - Parameters:
    ///   - positiveNames: The positive names for a command line flag.
    ///   - negativeNames: The negative names for this command line flag, if any.
    /// - Returns: The extracted values for this command line flag.
    public mutating func extractFlag(named positiveNames: CommandLineArgument.Names, inverseNames negativeNames: CommandLineArgument.Names? = nil) -> [Bool] {
        var values = [Bool]()
        let allNamesToCheck = positiveNames.all.union(negativeNames?.all ?? [])
        
        for (index, argument) in remainingOptionsOrFlags.indexed().reversed() where allNamesToCheck.contains(argument) {
            remainingOptionsOrFlags.remove(at: index)
            
            values.append(negativeNames == nil || positiveNames.all.contains(argument))
        }
        
        return values.reversed() // The values are gathered in reverse order
    }
    
    // MARK: Insert
    
    /// Inserts a command line argument into the arguments list unless it already exists.
    /// - Parameter argument: The command line argument (flag or option) to insert.
    /// - Returns:  `true` if the argument was already present in the arguments list; otherwise, `false`.
    @discardableResult
    public mutating func insertIfMissing(_ argument: CommandLineArgument) -> Bool  {
        remainingOptionsOrFlags.appendIfMissing(argument)
    }
    
    /// Adds a raw string argument to the start of the arguments list
    mutating func prepend(rawArgument: String)   {
        remainingOptionsOrFlags.insert(rawArgument, at: 0)
    }
    
    /// Inserts a command line argument into the arguments list, overriding any existing values.
    /// - Parameters:
    ///  - argument: The command line argument (flag or option) to insert.
    ///  - newValue: The new value for this command line argument.
    /// - Returns: `true` if the argument was already present in the arguments list; otherwise, `false`.
    @discardableResult
    public mutating func overrideOrInsertOption(named names: CommandLineArgument.Names, newValue: String) -> Bool {
        let didRemoveArguments = !extractOption(named: names).isEmpty
        remainingOptionsOrFlags.append(.option(names, value: newValue))
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
        guard !contains(argument.names) else {
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
        case .option(let value):
            append(contentsOf: [argument.names.preferred, value])
        }
    }
    
    /// Checks if the slice contains any of the given names.
    func contains(_ names: CommandLineArgument.Names) -> Bool {
        contains(where: {
            names.suffixAfterMatchingNamesWith(argument: $0) != nil
        })
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
