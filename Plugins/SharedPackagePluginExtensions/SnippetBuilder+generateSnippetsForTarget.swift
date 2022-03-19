// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
import PackagePlugin

extension SnippetBuilder {
    func generateSnippets(
        for target: SwiftSourceModuleTarget,
        context: PluginContext
    ) throws -> URL? {
        guard let package = context.package.package(for: target) else {
            return nil
        }
        
        return try generateSnippets(
            for: package.id,
            packageDisplayName: package.displayName,
            packageDirectory: URL(fileURLWithPath: package.directory.string, isDirectory: true)
        )
    }
}
