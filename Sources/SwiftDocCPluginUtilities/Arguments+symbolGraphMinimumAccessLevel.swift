// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation

extension Arguments {
    /// The symbol graph minimum access level, if any, described by this set of command-line arguments.
    public var symbolGraphMinimumAccessLevel: String? {
        guard let accessLevelOptionIndex = firstIndex(
            where: { argument in
                return CommandLineOption.symbolGraphMinimumAccessLevel.possibleNames.contains(argument)
            }
        ) else {
            return nil
        }
        let accessLevelIndex = index(after: accessLevelOptionIndex)
        guard indices.contains(accessLevelIndex) else {
            return nil
        }
        return self[accessLevelIndex]
    }
}
