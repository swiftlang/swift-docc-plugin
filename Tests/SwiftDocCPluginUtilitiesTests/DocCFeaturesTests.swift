// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
@testable import SwiftDocCPluginUtilities
import XCTest

final class DocCFeaturesTests: XCTestCase {
    func testKnownFeatures() throws {
        let json = Data("""
        {
          "features": [
            {
              "name": "diagnostics-file"
            },
            {
              "name": "dependency"
            },
            {
              "name": "overloads"
            }
          ]
        }
        """.utf8)
        let features = try JSONDecoder().decode(DocCFeatures.self, from: json)
        
        XCTAssertEqual(features.count, 3)
        
        XCTAssert(features.contains(.diagnosticsFileOutput))
        XCTAssert(features.contains(.overloads))
        XCTAssert(features.contains(.linkDependencies))
        
        XCTAssertFalse(features.contains(.init(name: "some-unknown-feature")))
    }
    
    func testUnknownFeatures() throws {
        let json = Data("""
        {
          "features": [
            {
              "name": "some-unknown-feature"
            }
          ]
        }
        """.utf8)
        let features = try JSONDecoder().decode(DocCFeatures.self, from: json)
        
        XCTAssertEqual(features.count, 1)
        
        XCTAssert(features.contains(.init(name: "some-unknown-feature")))
        
        XCTAssertFalse(features.contains(.diagnosticsFileOutput))
        XCTAssertFalse(features.contains(.overloads))
        XCTAssertFalse(features.contains(.linkDependencies))
    }
    
    func testFeaturesURL() {
        XCTAssertEqual(
            DocCFeatures._featuresURL(forDoccExecutable: URL(fileURLWithPath: "/path/to/toolchain/usr/bin/docc")),
            URL(fileURLWithPath: "/path/to/toolchain/usr/share/docc/features.json")
        )
    }
}
