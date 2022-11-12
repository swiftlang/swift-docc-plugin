// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import PackagePlugin

extension PackageManager.SymbolGraphOptions {
    /// Overrides individual values in the `SymbolGraphOptions`
    /// according to the given `arguments`.
    mutating func override(with arguments: Arguments) {
        for argument in arguments {
            switch argument {
            case "--emit-extension-block-symbols":
#if swift(>=5.8)
                self.emitExtensionBlocks = true
#else
                print("warning: detected '--emit-extension-block-symbols' option, which is incompatible with your swift version (required: 5.8)")
#endif
            default:
                print("warning: detected unknown dump-symbol-graph option '\(argument)'")
            }
        }
    }
}
