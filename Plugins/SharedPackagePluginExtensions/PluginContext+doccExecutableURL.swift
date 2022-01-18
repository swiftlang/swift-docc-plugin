// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
import PackagePlugin

extension PluginContext {
    /// Returns the executable url that should be used for any invocations of the
    /// `docc` command-line tool in this plugin context.
    ///
    /// If the user has set the `DOCC_EXEC` environment variable this will return the URL
    /// at the given path. Otherwise, this attempts to find the `docc` executable
    /// in the current toolchain.
    var doccExecutable: URL {
        get throws {
            if let doccExecPath = ProcessInfo.processInfo.environment["DOCC_EXEC"] {
                return URL(fileURLWithPath: doccExecPath)
            } else {
                let doccTool = try tool(named: "docc")
                return URL(fileURLWithPath: doccTool.path.string)
            }
        }
    }
}
