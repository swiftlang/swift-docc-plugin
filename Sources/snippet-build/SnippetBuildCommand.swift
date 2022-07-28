// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
import Snippets
import SymbolKit

@main
struct SnippetBuildCommand {
    var snippetsDir: String
    var outputDir: String
    var moduleName: String

    static func printUsage() {
        let usage = """
            USAGE: snippet-build <snippet directory> <output directory> <module name>

            ARGUMENTS:
                <snippet directory> - The directory containing Swift snippets
                <output directory> - The diretory in which to place Symbol Graph JSON file(s) representing the snippets
                <module name> - The module name to use for the Symbol Graph (typically should be the package name)
            """
        print(usage)
    }

    func run() throws {
        let snippets = try loadSnippets(from: URL(fileURLWithPath: snippetsDir))
        guard snippets.count > 0 else { return }
        let symbolGraphFilename = URL(fileURLWithPath: outputDir)
            .appendingPathComponent("\(moduleName)-snippets.symbols.json")
        try emitSymbolGraph(for: snippets, to: symbolGraphFilename, moduleName: moduleName)
    }

    func emitSymbolGraph(for snippets: [Snippet], to emitFilename: URL, moduleName: String) throws {
        let snippetSymbols = snippets.map { SymbolGraph.Symbol($0, moduleName: moduleName, inDirectory: URL(fileURLWithPath: snippetsDir).absoluteURL) }
        let metadata = SymbolGraph.Metadata(formatVersion: .init(major: 0, minor: 1, patch: 0), generator: "swift-docc-plugin/snippet-build")
        let module = SymbolGraph.Module(name: moduleName, platform: .init(architecture: nil, vendor: nil, operatingSystem: nil, environment: nil), isVirtual: true)
        let symbolGraph = SymbolGraph(metadata: metadata, module: module, symbols: snippetSymbols, relationships: [])
        try FileManager.default.createDirectory(atPath: emitFilename.deletingLastPathComponent().path, withIntermediateDirectories: true, attributes: nil)
        let encoder = JSONEncoder()
        let data = try encoder.encode(symbolGraph)
        try data.write(to: emitFilename)
    }

    func files(in directory: URL, withExtension fileExtension: String? = nil) throws -> [URL] {
        guard directory.isDirectory else {
            return []
        }

        let files = try FileManager.default.contentsOfDirectory(atPath: directory.path)
            .map { directory.appendingPathComponent($0) }
            .filter { $0.isFile }

        guard let fileExtension = fileExtension else {
            return files
        }

        return files.filter { $0.pathExtension == fileExtension }
    }

    func subdirectories(in directory: URL) throws -> [URL] {
        guard directory.isDirectory else {
            return []
        }
        return try FileManager.default.contentsOfDirectory(atPath: directory.path)
            .map { directory.appendingPathComponent($0) }
            .filter { $0.isDirectory }
    }

    func loadSnippets(from snippetsDirectory: URL) throws -> [Snippet] {
        guard snippetsDirectory.isDirectory else {
            return []
        }

        let snippetFiles = try files(in: snippetsDirectory, withExtension: "swift") +
            subdirectories(in: snippetsDirectory)
                .flatMap { subdirectory -> [URL] in
                    try files(in: subdirectory, withExtension: "swift")
                }

        return try snippetFiles.map { try Snippet(parsing: $0) }
    }

    static func main() throws {
        if CommandLine.arguments.count < 4 {
            printUsage()
            exit(0)
        }
        let snippetBuild = SnippetBuildCommand(snippetsDir: CommandLine.arguments[1],
                                               outputDir: CommandLine.arguments[2],
                                               moduleName: CommandLine.arguments[3])
        try snippetBuild.run()
    }
}
