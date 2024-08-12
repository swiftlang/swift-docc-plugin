// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022-2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
import XCTest

extension XCTestCase {
    enum DocCArchiveSubdirectory: String {
        case dataSubdirectory = "data"
        case indexSubdirectory = "index"
    }
    
    func filesIn(_ url: URL) throws -> [URL] {
        let enumerator = try XCTUnwrap(
            FileManager.default.enumerator(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: .producesRelativePathURLs
            )
        )
        
#if os(Linux)
        // The implementation in Linux CI doesn't produce relative URLs despite the `producesRelativePathURLs` option.
        // Pre-compute how many components the base URL has
        let urlPrefixComponentCount = url.standardizedFileURL.pathComponents.count
#endif
        
        return try enumerator.compactMap {
            guard let url = $0 as? URL else {
                return nil
            }
            
            let isDirectory = try XCTUnwrap(
                url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory
            )
            guard !isDirectory else {
                return nil
            }
            
#if os(Linux)
            // The implementation in Linux CI doesn't produce relative URLs despite the `producesRelativePathURLs` option.
            // Use the pre-computed number of base URL components to manually create a relative URL.
            // Since this is only a test helper, a simplified implantation like this is sufficient. 
            return URL(
                fileURLWithPath: url.standardizedFileURL.pathComponents.dropFirst(urlPrefixComponentCount).joined(separator: "/"),
                relativeTo: url
            )
#else
            return url
#endif
        }
    }
    
    func filesIn(_ subdirectory: DocCArchiveSubdirectory, of doccArchive: URL) throws -> [URL] {
        try filesIn(doccArchive.appendingPathComponent(subdirectory.rawValue))
    }
    
    func relativeFilePathsIn(_ subdirectory: DocCArchiveSubdirectory, of doccArchive: URL) throws -> [String] {
        try filesIn(subdirectory, of: doccArchive)
            .map(\.relativePath)
            .sorted()
    }
    
    func relativeFilePathsIn(_ url: URL) throws -> [String] {
        try filesIn(url)
            .map(\.relativePath)
            .sorted()
    }
}
