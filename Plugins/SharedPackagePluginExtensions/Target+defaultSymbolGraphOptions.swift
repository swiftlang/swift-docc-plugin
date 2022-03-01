// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import PackagePlugin

extension SwiftSourceModuleTarget {
    /// Returns the default options that should be used for generating a symbol graph for the
    /// current target in the given package.
    func defaultSymbolGraphOptions(in package: Package) -> PackageManager.SymbolGraphOptions {
        let targetMinimumAccessLevel: PackageManager.SymbolGraphOptions.AccessLevel
        
        if kind == .executable {
            // The target represents an executable so we'll use an 'internal' minimum
            // access level.
            targetMinimumAccessLevel = .internal
        } else {
            // Since the target isn't an executable, we assume it's a library and use
            // the 'public' minimum access level.
            targetMinimumAccessLevel = .public
        }
        
        return PackageManager.SymbolGraphOptions(
            minimumAccessLevel: targetMinimumAccessLevel,
            includeSynthesized: true,
            includeSPI: false
        )
    }
}
