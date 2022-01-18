// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation

extension FileManager {
    func copyDirectoryWithoutHiddenFiles(
        at sourceURL: URL,
        to destURL: URL,
        additionalFilter: (URL) -> Bool = { _ in true }
    ) throws {
        try? FileManager.default.removeItem(at: destURL)
        
        try FileManager.default.createDirectory(
            at: destURL,
            withIntermediateDirectories: false
        )
        
        let pluginPackageContents = try FileManager.default.contentsOfDirectory(
            at: sourceURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        )
        .filter(additionalFilter)
        
        for url in pluginPackageContents {
            try FileManager.default.copyItem(
                at: url,
                to: destURL.appendingPathComponent(url.lastPathComponent)
            )
        }
    }
}
