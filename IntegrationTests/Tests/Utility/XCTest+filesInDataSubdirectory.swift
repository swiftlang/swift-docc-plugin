// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
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
    
    func filesIn(_ subdirectory: DocCArchiveSubdirectory, of doccArchive: URL) throws -> [URL] {
        let enumerator = try XCTUnwrap(
            FileManager.default.enumerator(
                at: doccArchive.appendingPathComponent(subdirectory.rawValue),
                includingPropertiesForKeys: [.isDirectoryKey]
            )
        )
        
        return try enumerator.compactMap { any in
            guard let fileURL = any as? URL else {
                return nil
            }
            
            let resourceValues = try XCTUnwrap(fileURL.resourceValues(forKeys: [.isDirectoryKey]))
            if try XCTUnwrap(resourceValues.isDirectory) {
                return nil
            } else {
                return fileURL
            }
        }
    }
}
