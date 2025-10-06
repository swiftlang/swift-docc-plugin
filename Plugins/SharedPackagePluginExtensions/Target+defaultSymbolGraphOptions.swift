// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022-2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import PackagePlugin

extension SourceModuleTarget {
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

#if compiler(<6.3)
        let skipInheritedDocs = false
#endif
        
#if swift(>=5.9)
        let emitExtensionBlockSymbolDefault = true
#else
        let emitExtensionBlockSymbolDefault = false
#endif
        
        return PackageManager.SymbolGraphOptions(
            minimumAccessLevel: targetMinimumAccessLevel,
            includeInheritedDocs: !skipInheritedDocs,
            includeSynthesized: true,
            includeSPI: false,
            emitExtensionBlocks: emitExtensionBlockSymbolDefault
        )
    }
}

#if compiler(<6.3)
private extension PackageManager.SymbolGraphOptions {
    /// A compatibility layer for lower Swift versions which don't toggle include/skip inherited docs.
    init(minimumAccessLevel: PackagePlugin.PackageManager.SymbolGraphOptions.AccessLevel = .public,
         includeInheritedDocs: Bool = true,
         includeSynthesized: Bool = false,
         includeSPI: Bool = false,
         emitExtensionBlocks: Bool) {
        self.init(minimumAccessLevel: minimumAccessLevel, includeSynthesized: includeSynthesized, includeSPI: includeSPI, emitExtensionBlocks: emitExtensionBlocks)
    }
}
#endif


#if swift(<5.8)
private extension PackageManager.SymbolGraphOptions {
    /// A compatibility layer for lower Swift versions which discards unknown parameters.
    init(minimumAccessLevel: PackagePlugin.PackageManager.SymbolGraphOptions.AccessLevel = .public,
         includeSynthesized: Bool = false,
         includeSPI: Bool = false,
         emitExtensionBlocks: Bool) {
        self.init(minimumAccessLevel: minimumAccessLevel, includeSynthesized: includeSynthesized, includeSPI: includeSPI)
    }
}
#endif
