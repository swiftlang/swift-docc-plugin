// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
import PackagePlugin

extension SourceModuleTarget {
    /// The path to this target's DocC catalog, if any.
    var doccCatalogPath: String? {
        return sourceFiles.first { sourceFile in
            sourceFile.path.extension?.lowercased() == "docc"
        }?.path.string
    }
}
