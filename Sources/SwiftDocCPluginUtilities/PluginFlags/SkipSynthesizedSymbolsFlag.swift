// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

extension PluginFlag {
    /// Exclude synthesized symbols from the generated documentation.
    ///
    /// `--experimental-skip-synthesized-symbols` produces a DocC archive without compiler synthesized symbols.
    static let skipSynthesizedSymbols = PluginFlag(
        parsedValues: [
            "--experimental-skip-synthesized-symbols"
        ],
        abstract: "Exclude synthesized symbols from the generated documentation",
        description: """
            Experimental feature that produces a DocC archive without compiler synthesized symbols.
            """,
        argumentTransformation: { $0 }
    )

}
