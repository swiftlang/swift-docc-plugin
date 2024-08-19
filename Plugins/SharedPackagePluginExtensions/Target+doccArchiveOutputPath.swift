// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022-2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import PackagePlugin
import Foundation

extension Target {
    func doccArchiveOutputPath(in context: PluginContext) -> String {
        context.pluginWorkDirectory.appending(archiveName).string
    }
    
    func dependencyDocCArchiveOutputPath(in context: PluginContext) -> String {
        context.pluginWorkDirectory.appending("dependencies").appending(archiveName).string
    }
    
    private var archiveName: String {
        "\(name).doccarchive"
    }
}
