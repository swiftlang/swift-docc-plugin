// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
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
        let snippetGroups = try loadSnippetsAndSnippetGroups(from: URL(fileURLWithPath: snippetsDir))

        let totalSnippetCount = snippetGroups.reduce(0) { $0 + $1.snippets.count }

        guard !snippetGroups.isEmpty,
              snippetGroups.allSatisfy({ !$0.snippets.isEmpty }) else {
                  return
              }

        let symbolGraphFilename = URL(fileURLWithPath: outputDir).appendingPathComponent("\(moduleName)-snippets.symbols.json")

        try emitSymbolGraph(forSnippetGroups: snippetGroups, to: symbolGraphFilename, moduleName: moduleName)
    }

    func emitSymbolGraph(forSnippetGroups snippetGroups: [SnippetGroup], to emitFilename: URL, moduleName: String) throws {
        var groups = [SymbolGraph.Symbol]()
        var snippets = [SymbolGraph.Symbol]()
        var relationships = [SymbolGraph.Relationship]()

        for group in snippetGroups {
            let groupSymbol = SymbolGraph.Symbol(group, packageName: moduleName)
            let snippetSymbols = group.snippets.map {
                SymbolGraph.Symbol($0, packageName: moduleName, groupName: group.name)
            }

            groups.append(groupSymbol)
            snippets.append(contentsOf: snippetSymbols)

            let snippetGroupRelationships = snippetSymbols.map { snippetSymbol in
                SymbolGraph.Relationship(source: snippetSymbol.identifier.precise, target: groupSymbol.identifier.precise, kind: .memberOf, targetFallback: nil)
            }
            relationships.append(contentsOf: snippetGroupRelationships)
        }

        let metadata = SymbolGraph.Metadata(formatVersion: .init(major: 0, minor: 1, patch: 0), generator: "swift-docc-plugin/snippet-build")
        let module = SymbolGraph.Module(name: moduleName, platform: .init(architecture: nil, vendor: nil, operatingSystem: nil, environment: nil))
        let symbolGraph = SymbolGraph(metadata: metadata, module: module, symbols: groups + snippets, relationships: relationships)
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

    func loadSnippetsAndSnippetGroups(from snippetsDirectory: URL) throws -> [SnippetGroup] {
        guard snippetsDirectory.isDirectory else {
            return []
        }

        let topLevelSnippets = try files(in: snippetsDirectory, withExtension: "swift")
            .map { try Snippet(parsing: $0) }

        let topLevelSnippetGroup = SnippetGroup(name: "Snippets",
                                                baseDirectory: snippetsDirectory,
                                                snippets: topLevelSnippets,
                                                explanation: "")

        let subdirectoryGroups = try subdirectories(in: snippetsDirectory)
            .map { subdirectory -> SnippetGroup in
                let snippets = try files(in: subdirectory, withExtension: "swift")
                    .map { try Snippet(parsing: $0) }

                let explanationFile = subdirectory.appendingPathComponent("Explanation.md")

                let snippetGroupExplanation: String
                if explanationFile.isFile {
                    snippetGroupExplanation = try String(contentsOf: explanationFile)
                } else {
                    snippetGroupExplanation = ""
                }

                return SnippetGroup(name: subdirectory.lastPathComponent,
                                    baseDirectory: subdirectory,
                                    snippets: snippets,
                                    explanation: snippetGroupExplanation)
            }

        let snippetGroups = [topLevelSnippetGroup] + subdirectoryGroups.sorted {
            $0.name < $1.name
        }

        return snippetGroups.filter { !$0.snippets.isEmpty }
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
