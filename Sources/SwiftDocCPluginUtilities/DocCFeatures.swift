// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation

/// The features that a `docc` executable lists in its corresponding "features.json" file.
///
/// In a Swift toolchain, the `docc` executable is located at `usr/bin/docc` and the
/// corresponding features file is located at `usr/share/docc/features.json`.
///
/// The "features.json" file is a list of named features. For example:
///
/// ```json
/// {
///   "features": [
///     {
///       "name": "diagnostics-file"
///     },
///     {
///       "name": "dependency"
///     },
///     {
///       "name": "overloads"
///     }
///   ]
/// }
/// ```
struct DocCFeatures: Decodable {
    /// A single named feature that's supported for a given `docc` executable.
    struct Feature: Decodable, Hashable {
        var name: String
    }
    private var features: Set<Feature>
    
    /// Decodes the DocC features that correspond to a given `docc` executable in a Swift toolchain.
    init(doccExecutable: URL) throws {
        let data = try Data(contentsOf: Self._featuresURL(forDoccExecutable: doccExecutable))
        self = try JSONDecoder().decode(DocCFeatures.self, from: data)
    }
    
    /// Creates an empty list of supported DocC features.
    init() {
        features = []
    }
    
    /// Returns the "features.json" file for a given `docc` executable in a Swift toolchain.
    static func _featuresURL(forDoccExecutable doccExecutable: URL) -> URL {
        doccExecutable
            .deletingLastPathComponent() // docc
            .deletingLastPathComponent() // bin
            .appendingPathComponent("share/docc/features.json")
    }
}

extension DocCFeatures: Collection {
    typealias Index = Set<Feature>.Index
    typealias Element = Set<Feature>.Element
    
    var startIndex: Index { features.startIndex }
    var endIndex: Index { features.endIndex }
    
    subscript(index: Index) -> Iterator.Element {
        get { features[index] }
    }
    
    func index(after i: Index) -> Index {
        return features.index(after: i)
    }
}

// MARK: Known features

extension DocCFeatures.Feature {
    /// DocC supports writing diagnostic information to a JSON file, specified by `--diagnostics-output-path`.
    static let diagnosticsFileOutput = DocCFeatures.Feature(name: "diagnostics-file")
    
    /// DocC supports linking between documentation builds and merging archives into a combined archive.
    static let linkDependencies = DocCFeatures.Feature(name: "dependency")
    
    /// DocC supports grouping overloaded symbols.
    static let overloads = DocCFeatures.Feature(name: "overloads")
}
