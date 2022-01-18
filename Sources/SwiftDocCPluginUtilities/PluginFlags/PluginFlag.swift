// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

/// A command-line flag for the docc plugin.
///
/// Plugin flags are distinct from options that are for the docc command-line tool itself.
struct PluginFlag: ArgumentsTransforming {
    /// The string values that will be parsed when detecting this flag.
    ///
    /// For example, this might be `["--disable-index"]`.
    let parsedValues: Set<String>
    
    /// A short, user-facing description of this flag.
    let abstract: String
    
    /// An expanded, user-facing description of this flag.
    let description: String
    
    let argumentTransformation: (Arguments) -> Arguments
    
    /// Transforms the given set of arguments if they include any of this flag's
    /// parsed values.
    ///
    /// For example, if the flag's ``parsedValues`` are `["--disable-index"]`,
    /// and the given parsed arguments contain `["--disable-index", "--index"]`,
    /// then the transformation would both consume the `"--disable-index"` flag
    /// and remove the `"--index"` flag since indexing should be disabled.
    func transform(_ arguments: Arguments) -> Arguments {
        guard !parsedValues.isDisjoint(with: arguments) else {
            // The given parsed arguments do not contain any of this flags
            // parsed values so just return.
            return arguments
        }
        
        // Consume the current flag
        let arguments = arguments.filter { argument in
            !parsedValues.contains(argument)
        }
        
        // Apply the flag to the set of arguments
        return argumentTransformation(arguments)
    }
    
    /// Create a new command-line flag.
    ///
    /// - Parameters:
    ///   - parsedValues: The string values that should be parsed to detect this flag.
    ///   - abstract: The user-facing description of this flag.
    ///   - description: An expanded, user-facing description of this flag.
    ///   - argumentTransformation: A closure that can be applied to a given
    ///     set of parsed arguments if the arguments include any of the this flag's parsed values.
    init(
        parsedValues: Set<String>,
        abstract: String,
        description: String,
        argumentTransformation: @escaping (Arguments) -> Arguments
    ) {
        self.parsedValues = parsedValues
        self.abstract = abstract
        self.description = description
        self.argumentTransformation = argumentTransformation
    }
}
