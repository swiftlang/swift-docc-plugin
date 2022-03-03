// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import ArgumentParser
import Foundation
import SymbolKit
import TSCBasic

struct SnippetBuildCommand: ParsableCommand {
    @Option(help: "The directory containing Swift snippets")
    var snippetsDir: String

    @Option(help: "The directory to write Symbol Graph JSON files")
    var outputDir: String

    @Option(help: "The module name to use for the Symbol Graph")
    var moduleName: String

    func run() throws {
        print("Looking for snippets in \(snippetsDir.debugDescription)")
        let snippetGroups = try loadSnippetsAndSnippetGroups(from: AbsolutePath(snippetsDir))

        let totalSnippetCount = snippetGroups.reduce(0) { $0 + $1.snippets.count }
        print("Found \(snippetGroups.count) snippet groups, \(totalSnippetCount) snippets in total.")

        guard !snippetGroups.isEmpty,
              snippetGroups.allSatisfy({ !$0.snippets.isEmpty }) else {
                  return
              }

        let symbolGraphFilename = AbsolutePath(outputDir).appending(component: "\(moduleName)-snippets.symbols.json")

        print("Writing snippet symbol graph to \(symbolGraphFilename.pathString.debugDescription)")
        try emitSymbolGraph(forSnippetGroups: snippetGroups, to: symbolGraphFilename, moduleName: moduleName)
    }

    public func emitSymbolGraph(forSnippetGroups snippetGroups: [SnippetGroup], to emitFilename: AbsolutePath, moduleName: String) throws {
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
        try FileManager.default.createDirectory(atPath: emitPath.pathString, withIntermediateDirectories: true, attributes: nil)
        let encoder = JSONEncoder()
        let data = try encoder.encode(symbolGraph)
        try data.write(to: emitFilename.asURL)
    }

    func files(in directory: AbsolutePath, withExtension fileExtension: String? = nil) throws -> [AbsolutePath] {
        guard localFileSystem.isDirectory(directory) else {
            return []
        }

        let files = try localFileSystem.getDirectoryContents(directory)
            .map { directory.appending(RelativePath($0)) }
            .filter { localFileSystem.isFile($0) }

        guard let fileExtension = fileExtension else {
            return files
        }

        return files.filter { $0.extension == fileExtension }
    }

    func subdirectories(in directory: AbsolutePath) throws -> [AbsolutePath] {
        guard localFileSystem.isDirectory(directory) else {
            return []
        }
        return try localFileSystem.getDirectoryContents(directory)
            .map { directory.appending(RelativePath($0)) }
            .filter { localFileSystem.isDirectory($0) }
    }

    func loadSnippetsAndSnippetGroups(from snippetsDirectory: AbsolutePath) throws -> [SnippetGroup] {
        guard localFileSystem.isDirectory(snippetsDirectory) else {
            return []
        }

        let topLevelSnippets = try files(in: snippetsDirectory, withExtension: "swift")
            .map { try Snippet(parsing: $0.asURL) }

        let topLevelSnippetGroup = SnippetGroup(name: "Snippets",
                                                baseDirectory: snippetsDirectory.asURL,
                                                snippets: topLevelSnippets,
                                                explanation: "")

        let subdirectoryGroups = try subdirectories(in: snippetsDirectory)
            .map { subdirectory -> SnippetGroup in
                let snippets = try files(in: subdirectory, withExtension: "swift")
                    .map { try Snippet(parsing: $0.asURL) }

                let explanationFile = subdirectory.appending(component: "Explanation.md")

                let snippetGroupExplanation: String
                if localFileSystem.isFile(explanationFile) {
                    snippetGroupExplanation = try String(contentsOf: explanationFile.asURL)
                } else {
                    snippetGroupExplanation = ""
                }

                return SnippetGroup(name: subdirectory.basename,
                                    baseDirectory: subdirectory.asURL,
                                    snippets: snippets,
                                    explanation: snippetGroupExplanation)
            }

        let snippetGroups = [topLevelSnippetGroup] + subdirectoryGroups.sorted {
            $0.name < $1.name
        }

        return snippetGroups.filter { !$0.snippets.isEmpty }
    }
}

SnippetBuildCommand.main()
