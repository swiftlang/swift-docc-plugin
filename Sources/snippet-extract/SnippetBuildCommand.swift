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
struct SnippetExtractCommand {
    enum OptionName: String {
        case moduleName = "--module-name"
        case outputFile = "--output"
    }

    enum Argument {
        case moduleName(String)
        case outputFile(String)
        case inputFile(String)
    }

    enum ArgumentError: Error, CustomStringConvertible {
        case missingOption(OptionName)
        case missingOptionValue(OptionName)
        case snippetNotContainedInSnippetsDirectory(URL)

        var description: String {
            switch self {
            case .missingOption(let optionName):
                return "Missing required option \(optionName.rawValue)"
            case .missingOptionValue(let optionName):
                return "Missing required option value for \(optionName.rawValue)"
            case .snippetNotContainedInSnippetsDirectory(let snippetFileURL):
                return "Snippet file '\(snippetFileURL.path)' is not contained in a directory called 'Snippets' at any level, so this tool is not able to compute the path components that would be used for linking to the snippet. It may exist in a subdirectory, but one of its parent directories must be named 'Snippets'."
            }
        }
    }

    var snippetFiles = [String]()
    var outputFile: String
    var moduleName: String

    static func printUsage() {
        let usage = """
            USAGE: snippet-extract --output <output file> --module-name <module name> <input files>

            ARGUMENTS:
                <output file> (Required)
                    The path of the output Symbol Graph JSON file representing the snippets for the a module or package
                <module name> (Required)
                    The module name to use for the Symbol Graph (typically should be the package name)
                <input files>
                    One or more absolute paths to snippet files to interpret as snippets
            """
        print(usage)
    }

    init(arguments: [String]) throws {
        var arguments = arguments

        var parsedOutputFile: String? = nil
        var parsedModuleName: String? = nil

        while let argument = try arguments.parseSnippetArgument() {
            switch argument {
            case .inputFile(let inputFile):
                snippetFiles.append(inputFile)
            case .moduleName(let moduleName):
                parsedModuleName = moduleName
            case .outputFile(let outputFile):
                parsedOutputFile = outputFile
            }
        }

        guard let parsedOutputFile else {
            throw ArgumentError.missingOption(.outputFile)
        }
        self.outputFile = parsedOutputFile

        guard let parsedModuleName else {
            throw ArgumentError.missingOption(.moduleName)
        }
        self.moduleName = parsedModuleName
    }

    func run() throws {
        let snippets = try snippetFiles.map {
            try Snippet(parsing: URL(fileURLWithPath: $0))
        }
        guard snippets.count > 0 else { return }
        let symbolGraphFilename = URL(fileURLWithPath: outputFile)
        try emitSymbolGraph(for: snippets, to: symbolGraphFilename, moduleName: moduleName)
    }

    func emitSymbolGraph(for snippets: [Snippet], to emitFilename: URL, moduleName: String) throws {
        let snippetSymbols = try snippets.map { try SymbolGraph.Symbol($0, moduleName: moduleName) }
        let metadata = SymbolGraph.Metadata(formatVersion: .init(major: 0, minor: 1, patch: 0), generator: "snippet-extract")
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

    static func main() throws {
        if CommandLine.arguments.count == 1 || CommandLine.arguments.contains("-h") || CommandLine.arguments.contains("--help") {
            printUsage()
            exit(0)
        }
        do {
            let snippetExtract = try SnippetExtractCommand(arguments: Array(CommandLine.arguments.dropFirst(1)))
            try snippetExtract.run()
        } catch let error as ArgumentError {
            printUsage()
            throw error
        }
    }
}

extension Array where Element == String {
    mutating func parseSnippetArgument() throws -> SnippetExtractCommand.Argument? {
        guard let thisArgument = first else {
            return nil
        }
        removeFirst()
        switch thisArgument {
        case "--module-name":
            guard let nextArgument = first else {
                throw SnippetExtractCommand.ArgumentError.missingOptionValue(.moduleName)
            }
            removeFirst()
            return .moduleName(nextArgument)
        case "--output":
            guard let nextArgument = first else {
                throw SnippetExtractCommand.ArgumentError.missingOptionValue(.outputFile)
            }
            removeFirst()
            return .outputFile(nextArgument)
        default:
            return .inputFile(thisArgument)
        }
    }
}
