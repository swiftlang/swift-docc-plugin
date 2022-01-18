// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

/// A Swift-DocC documentation target kind.
public enum DocumentationTargetKind: String {
    /// A Swift Package Manager library target.
    case library
    
    /// A Swift Package Manager executable target.
    case executable
    
    var requiredOptions: [RequiredCommandLineOption] {
        switch self {
        case .library:
            return []
        case .executable:
            return [
                RequiredCommandLineOption(
                    .fallbackDefaultModuleKind,
                    defaultValue: "Command-line Tool"
                )
            ]
        }
    }
    
    /// Adds the options required for the target kind into the given set of arguments if
    /// they are not already specified.
    ///
    /// For example, ``executable`` target kinds require a fallback default module kind
    /// to be specified. So, if the given arguments do not already contain
    /// "`--fallback-default-module-kind`", that option will be added along with its default value.
    func addRequiredOptions(to arguments: Arguments) -> Arguments {
        var arguments = arguments
        for requiredOption in requiredOptions {
            arguments = requiredOption.insertIntoArgumentsIfMissing(arguments)
        }
        
        return arguments
    }
}
