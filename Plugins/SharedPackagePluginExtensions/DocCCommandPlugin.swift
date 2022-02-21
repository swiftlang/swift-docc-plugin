// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import PackagePlugin

protocol DocCCommandPlugin: CommandPlugin {
    func performDocCCommand(context: PluginContext, arguments: [String]) throws
}

extension DocCCommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) throws {
        do {
            // We're wrapping this in a do/catch block instead of throwing directly
            // from this function because SwiftPM doesn't currently print the localized
            // error description of a thrown error.
            //
            // Using the Diagnostics API directly provides a better UX for the user.
            try performDocCCommand(context: context, arguments: arguments)
        } catch {
            Diagnostics.error(error.localizedDescription)
        }
    }
    
    // This is what was originally required by the `CommandPlugin` protocol and is left
    // for backwards compatibility with existing clients using an older version of the
    // Swift toolchain.
    //
    // As of the official release of Swift 5.6, this method is no longer necessary.
    func performCommand(context: PluginContext, targets: [Target], arguments: [String]) throws {
        try performCommand(context: context, arguments: arguments)
    }
}
