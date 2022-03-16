// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation

/// Manages snippet symbol graph building.
public class SnippetBuilder {
    /// Uniquely identifies a Swift Package Manager package.
    public typealias PackageIdentifier = String
    
    enum SymbolGraphBuildResult {
        case packageDoesNotProduceSnippets
        case packageContainsSnippets(symbolGraphDirectory: URL)
    }
    
    private let snippetTool: URL
    private let workingDirectory: URL
    
    private var snippetSymbolGraphBuildResults = [PackageIdentifier : SymbolGraphBuildResult]()
    
    public init(snippetTool: URL, workingDirectory: URL) {
        self.snippetTool = snippetTool
        self.workingDirectory = workingDirectory
    }
    
    private func snippetsDirectory(in packageDirectory: URL) -> URL? {
        let snippetsDirectory = packageDirectory.appendingPathComponent("Snippets")
        if FileManager.default.fileExists(atPath: snippetsDirectory.path) {
            return snippetsDirectory
        }
        
        // SwiftPM's plugin infrastructure is currently incompatble with Snippet support
        // so allow for an underscored Snippets directory to workaround this. (rdar://89773759)
        let underscoredSnippetsDirectory = packageDirectory.appendingPathComponent("_Snippets")
        if FileManager.default.fileExists(atPath: underscoredSnippetsDirectory.path) {
            return underscoredSnippetsDirectory
        }
        
        return nil
    }
    
    private func snippetsOutputDirectory(
        in pluginWorkingDirectory: URL,
        packageIdentifier: PackageIdentifier,
        packageDisplayName: String
    ) -> URL {
        return pluginWorkingDirectory
            .appendingPathComponent(".build", isDirectory: true)
            .appendingPathComponent("snippet-symbol-graphs", isDirectory: true)
            .appendingPathComponent("\(packageDisplayName)-\(packageIdentifier)", isDirectory: true)
    }
    
    /// Runs the given process and waits for it to exit.
    ///
    /// Provided for testing.
    var runProcess: (Process) throws -> () = { process in
        try process.run()
        process.waitUntilExit()
    }
    
    public func generateSnippets(
        for packageIdentifier: PackageIdentifier,
        packageDisplayName: String,
        packageDirectory: URL
    ) throws -> URL? {
        switch snippetSymbolGraphBuildResults[packageIdentifier] {
        case .packageContainsSnippets(symbolGraphDirectory: let symbolGraphDirectory):
            return symbolGraphDirectory
        case .packageDoesNotProduceSnippets:
            return nil
        case .none:
            // No existing build result for this package identifier
            break
        }
        
        guard let snippetsDirectory = snippetsDirectory(in: packageDirectory) else {
            snippetSymbolGraphBuildResults[packageIdentifier] = .packageDoesNotProduceSnippets
            return nil
        }
        
        let outputDirectory = snippetsOutputDirectory(
            in: workingDirectory,
            packageIdentifier: packageIdentifier,
            packageDisplayName: packageDisplayName
        )
        
        let process = Process()
        process.executableURL = snippetTool
        process.arguments = [
            snippetsDirectory.path,
            outputDirectory.path,
            packageDisplayName,
        ]
        
        try runProcess(process)
        
        if FileManager.default.fileExists(atPath: outputDirectory.path) {
            snippetSymbolGraphBuildResults[packageIdentifier] = .packageContainsSnippets(symbolGraphDirectory: outputDirectory)
            return outputDirectory
        } else {
            snippetSymbolGraphBuildResults[packageIdentifier] = .packageDoesNotProduceSnippets
            return nil
        }
    }
}
