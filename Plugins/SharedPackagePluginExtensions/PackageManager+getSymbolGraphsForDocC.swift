// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
import PackagePlugin

extension PackageManager {
    struct DocCSymbolGraphResult {
        let unifiedSymbolGraphsDirectory: URL
        let targetSymbolGraphsDirectory: URL
        let snippetSymbolGraphsDirectory: URL?
        
        init(
            unifiedSymbolGraphsDirectory: URL,
            targetSymbolGraphsDirectory: URL,
            snippetSymbolGraphsDirectory: URL?
        ) {
            self.unifiedSymbolGraphsDirectory = unifiedSymbolGraphsDirectory
            self.targetSymbolGraphsDirectory = targetSymbolGraphsDirectory
            self.snippetSymbolGraphsDirectory = snippetSymbolGraphsDirectory
        }
        
        init(targetSymbolGraphsDirectory: URL) {
            self.unifiedSymbolGraphsDirectory = targetSymbolGraphsDirectory
            self.targetSymbolGraphsDirectory = targetSymbolGraphsDirectory
            self.snippetSymbolGraphsDirectory = nil
        }
    }
    
    /// Returns the relevant symbols graphs for Swift-DocC documentation generation for
    /// the given target.
    func doccSymbolGraphs(
        for target: SwiftSourceModuleTarget,
        context: PluginContext,
        verbose: Bool,
        snippetBuilder: SnippetBuilder?
    ) throws -> DocCSymbolGraphResult {
        // First generate the primary symbol graphs containing information about the
        // symbols defined in the target itself.
        
        let symbolGraphOptions = target.defaultSymbolGraphOptions(in: context.package)
        
        if verbose {
            print("symbol graph options: '\(symbolGraphOptions)'")
        }
        
        let targetSymbolGraphs = try getSymbolGraph(for: target, options: symbolGraphOptions)
        let targetSymbolGraphsDirectory = URL(
            fileURLWithPath: targetSymbolGraphs.directoryPath.string,
            isDirectory: true
        )
        
        if verbose {
            print("target symbol graph directory path: '\(targetSymbolGraphsDirectory.path)'")
        }
        
        // Then, check to see if we were provided a snippet builder. If so,
        // we should attempt to generate symbol graphs for any snippets included in the
        // target's containing package.
        guard let snippetBuilder = snippetBuilder else {
            return DocCSymbolGraphResult(targetSymbolGraphsDirectory: targetSymbolGraphsDirectory)
        }
        
        if verbose {
            print("snippet builder provided, attempting to generate snippet symbol graph")
        }
        
        guard let snippetSymbolGraphsDirectory = try snippetBuilder.generateSnippets(
            for: target,
            context: context
        ) else {
            if verbose {
                print("no snippet symbol graphs generated")
            }
            
            return DocCSymbolGraphResult(targetSymbolGraphsDirectory: targetSymbolGraphsDirectory)
        }
        
        if verbose {
            print("snippet symbol graph directory path: '\(snippetSymbolGraphsDirectory.path)'")
        }
        
        // Since we successfully produced symbol graphs for snippets contained in the
        // target's containing package, we need to move all generated symbol graphs into
        // a single, unified, symbol graph directory.
        //
        // This is necessary because the `docc` CLI only supports accepting a single directory
        // of symbol graphs.
        
        let unifiedSymbolGraphsDirectory = URL(
            fileURLWithPath: context.pluginWorkDirectory.string,
            isDirectory: true
        )
        .appendingPathComponent(".build", isDirectory: true)
        .appendingPathComponent("symbol-graphs", isDirectory: true)
        .appendingPathComponent("unified-symbol-graphs", isDirectory: true)
        .appendingPathComponent("\(target.name)-\(target.id)", isDirectory: true)
        
        if verbose {
            print("unified symbol graphs directory path: '\(unifiedSymbolGraphsDirectory.path)'")
        }
        
        // If there's an existing directory containing unified symbol graphs for this target,
        // just remove it. Ignore the error that could occur if the directory doesn't exist.
        try? FileManager.default.removeItem(atPath: unifiedSymbolGraphsDirectory.path)
        
        try FileManager.default.createDirectory(
            atPath: unifiedSymbolGraphsDirectory.path,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        let targetSymbolGraphsUnifiedDirectory = unifiedSymbolGraphsDirectory.appendingPathComponent(
            "target-symbol-graphs", isDirectory: true
        )
        
        // Copy the symbol graphs for the target into the unified directory
        try FileManager.default.copyItem(
            atPath: targetSymbolGraphsDirectory.path,
            toPath: targetSymbolGraphsUnifiedDirectory.path
        )
        
        let snippetSymbolGraphsUnifiedDirectory = unifiedSymbolGraphsDirectory.appendingPathComponent(
            "snippet-symbol-graphs", isDirectory: true
        )
        
        // Copy the snippet symbol graphs into the unified directory
        try FileManager.default.copyItem(
            atPath: snippetSymbolGraphsDirectory.path,
            toPath: snippetSymbolGraphsUnifiedDirectory.path
        )
        
        return DocCSymbolGraphResult(
            unifiedSymbolGraphsDirectory: unifiedSymbolGraphsDirectory,
            targetSymbolGraphsDirectory: targetSymbolGraphsUnifiedDirectory,
            snippetSymbolGraphsDirectory: snippetSymbolGraphsUnifiedDirectory
        )
    }
}
