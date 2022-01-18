// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

/// A command-line option that specifies a default value so that it can
/// be automatically inserted when required.
struct RequiredCommandLineOption {
    /// The command-line option that is required.
    let option: CommandLineOption
    
    /// The default value that should be used for this command-line option when
    /// dynamically inserting it into a set of arguments.
    let defaultValue: String
    
    init(_ option: CommandLineOption, defaultValue: String) {
        self.option = option
        self.defaultValue = defaultValue
    }
    
    /// Inserts the default name and value for this command-line option into the given
    /// set of arguments, if the given arguments do not already contain this option.
    func insertIntoArgumentsIfMissing(_ arguments: Arguments) -> Arguments {
        guard option.possibleNames.isDisjoint(with: arguments) else {
            return arguments
        }
        
        return arguments + [option.defaultName, defaultValue]
    }
}
