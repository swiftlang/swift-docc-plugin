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
        // FIXME: Need a supported way for SwiftPM to provide DocC catalogs to plugins.
        // This doesn't work because a `.docc` catalog is not considered a source file.
        //
        //     return sourceFiles.first { sourceFile in
        //         sourceFile.path.extension == "docc"
        //     }?.path.string
        //
        // This is a temporary workaround that just looks for the first `.docc` catalog
        // in the target's primary directory.
        
        return FileManager.default.enumerator(
            at: URL(fileURLWithPath: directory.string),
            includingPropertiesForKeys: [.isDirectoryKey]
        )?
        .lazy
        .compactMap { any in
            return any as? URL
        }
        .first { url in
            let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            return isDirectory && url.pathExtension == "docc"
        }?.path
    }
}
