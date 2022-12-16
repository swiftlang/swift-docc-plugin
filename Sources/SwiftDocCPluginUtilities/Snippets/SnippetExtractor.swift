// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation

/// Manages snippet symbol graph extraction.
public class SnippetExtractor {
    /// Uniquely identifies a Swift Package Manager package.
    public typealias PackageIdentifier = String
    
    enum SymbolGraphExtractionResult {
        case packageDoesNotProduceSnippets
        case packageContainsSnippets(symbolGraphFile: URL)
    }
    
    private let snippetTool: URL
    private let workingDirectory: URL
    
    private var snippetSymbolGraphExtractionResults = [PackageIdentifier : SymbolGraphExtractionResult]()
    
    /// Create a new snippet extractor with the given tool
    /// and working directory.
    public init(snippetTool: URL, workingDirectory: URL) {
        self.snippetTool = snippetTool
        self.workingDirectory = workingDirectory
    }
    
    private func snippetsDirectory(in packageDirectory: URL) -> URL? {
        let snippetsDirectory = packageDirectory.appendingPathComponent("Snippets")
        guard _fileExists(snippetsDirectory.path) else {
            return nil
        }
        
        return snippetsDirectory
    }
    
    private func snippetsOutputDirectory(
        in pluginWorkingDirectory: URL,
        packageIdentifier: PackageIdentifier,
        packageDisplayName: String
    ) -> URL {
        return pluginWorkingDirectory
            .appendingPathComponent(".build", isDirectory: true)
            .appendingPathComponent("symbol-graphs", isDirectory: true)
            .appendingPathComponent("snippet-symbol-graphs", isDirectory: true)
            .appendingPathComponent("\(packageDisplayName)-\(packageIdentifier)", isDirectory: true)
    }
    
    /// Runs the given process and waits for it to exit.
    ///
    /// Provided for testing.
    var _runProcess: (Process) throws -> () = { process in
        try process.run()
        process.waitUntilExit()
    }
    
    /// Returns true if the given file exists on disk.
    ///
    /// Provided for testing.
    var _fileExists: (_ path: String) -> Bool = { path in
        return FileManager.default.fileExists(atPath: path)
    }

    /// Returns all of the `.swift` files under a directory recursively.
    ///
    /// Provided for testing.
    var _findSnippetFilesInDirectory: (_ directory: URL) -> [String] = { directory -> [String] in
        guard let snippetEnumerator = FileManager.default.enumerator(at: directory,
                                                                     includingPropertiesForKeys: nil,
                                                                     options: [.skipsHiddenFiles]) else {
            return []

        }
        var snippetInputFiles = [String]()
        for case let potentialSnippetURL as URL in snippetEnumerator {
            guard potentialSnippetURL.pathExtension.lowercased() == "swift" else {
                continue
            }
            snippetInputFiles.append(potentialSnippetURL.path)
        }

        return snippetInputFiles
    }
    
    /// Generate snippets for the given package.
    ///
    /// The snippet extractor has an internal cache so it's safe to call this
    /// function multiple times with the same package identifier.
    ///
    /// - Parameters:
    ///   - packageIdentifier: A unique identifier for the packge.
    ///   - packageDisplayName: A display name for the package.
    ///   - packageDirectory: The root directory for this package.
    ///
    ///     The snippet extractor will look for a `Snippets` subdirectory
    ///     within this directory.
    ///
    /// - Returns: A URL for the output file of the generated snippets symbol graph JSON file.
    public func generateSnippets(
        for packageIdentifier: PackageIdentifier,
        packageDisplayName: String,
        packageDirectory: URL
    ) throws -> URL? {
        switch snippetSymbolGraphExtractionResults[packageIdentifier] {
        case .packageContainsSnippets(symbolGraphFile: let symbolGraphFile):
            return symbolGraphFile
        case .packageDoesNotProduceSnippets:
            return nil
        case .none:
            // No existing build result for this package identifier
            break
        }
        
        guard let snippetsDirectory = snippetsDirectory(in: packageDirectory) else {
            snippetSymbolGraphExtractionResults[packageIdentifier] = .packageDoesNotProduceSnippets
            return nil
        }

        let snippetInputFiles = _findSnippetFilesInDirectory(snippetsDirectory)

        guard !snippetInputFiles.isEmpty else {
            snippetSymbolGraphExtractionResults[packageIdentifier] = .packageDoesNotProduceSnippets
            return nil
        }
        
        let outputDirectory = snippetsOutputDirectory(
            in: workingDirectory,
            packageIdentifier: packageIdentifier,
            packageDisplayName: packageDisplayName
        )

        let outputFile = outputDirectory.appendingPathComponent("\(packageDisplayName)-snippets.symbols.json")
        
        let process = Process()
        process.executableURL = snippetTool
        process.arguments = [
            "--output", outputFile.path,
            "--module-name", packageDisplayName,
        ] + snippetInputFiles

        try _runProcess(process)
        
        if _fileExists(outputFile.path) {
            snippetSymbolGraphExtractionResults[packageIdentifier] = .packageContainsSnippets(symbolGraphFile: outputFile)
            return outputFile
        } else {
            snippetSymbolGraphExtractionResults[packageIdentifier] = .packageDoesNotProduceSnippets
            return nil
        }
    }
}
