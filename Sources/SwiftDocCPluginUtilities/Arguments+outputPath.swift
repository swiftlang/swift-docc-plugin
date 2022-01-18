// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation

extension Arguments {
    /// The output path, if any, described by this set of command-line arguments.
    public var outputPath: String? {
        guard let outputPathOptionIndex = firstIndex(
            where: { argument in
                return CommandLineOption.outputPath.possibleNames.contains(argument)
            }
        ) else {
            return nil
        }
        let outputPathIndex = index(after: outputPathOptionIndex)
        guard indices.contains(outputPathIndex) else {
            return nil
        }
        
        // Expand any tilde in the path so that we can return a reasonable path for presentation
        let expandedPath = NSString(string: self[outputPathIndex]).expandingTildeInPath
        return URL(fileURLWithPath: expandedPath).path
    }
}
