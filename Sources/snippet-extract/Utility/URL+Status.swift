// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022-2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation

extension URL {
    var isFile: Bool {
        let attrs = try? FileManager.default.attributesOfItem(atPath: self.path)
        return attrs?[.type] as? FileAttributeType == .typeRegular
    }

    var isDirectory: Bool {
        var isADirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: self.path, isDirectory: &isADirectory)
            && isADirectory.boolValue
    }
}
