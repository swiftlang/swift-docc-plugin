// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

extension PluginFlag {
    /// Disables indexing for the produced DocC archive.
    ///
    /// Removes the `--index` flag from a given set of arguments if the `--disable-index` flag
    /// is found.
    static let disableIndex = PluginFlag(
        parsedValues: [
            "--disable-indexing",
            "--no-indexing",
        ],
        abstract: "Disable indexing for the produced DocC archive.",
        description: """
            Produces a DocC archive that is best-suited for hosting online but incompatible with Xcode.
            """,
        argumentTransformation: { arguments in
            // Filter out any --index flags from the parsed arguments.
            return arguments.filter { argument in
                argument != "--index"
            }
        }
    )
}
