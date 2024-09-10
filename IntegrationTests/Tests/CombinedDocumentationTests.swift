// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import XCTest

final class CombinedDocumentationTests: ConcurrencyRequiringTestCase {
    func testCombinedDocumentation() throws {
#if compiler(>=6.0)
        let result = try swiftPackage(
            "generate-documentation",
            "--enable-experimental-combined-documentation",
            "--verbose", // Necessary to see the 'docc convert' calls in the log and verify their parameters.
            workingDirectory: try setupTemporaryDirectoryForFixture(named: "TargetsWithDependencies")
        )
        
        result.assertExitStatusEquals(0)
        let outputArchives = result.referencedDocCArchives
        XCTAssertEqual(outputArchives.count, 1)
        XCTAssertEqual(outputArchives.map(\.lastPathComponent), [
            "TargetsWithDependencies.doccarchive",
        ])
        
        // Verify that the combined archive contains all target's documentation
        
        let combinedArchiveURL = try XCTUnwrap(outputArchives.first)
        let combinedDataDirectoryContents = try filesIn(.dataSubdirectory, of: combinedArchiveURL)
            .map(\.relativePath)
            .sorted()
        
        XCTAssertEqual(combinedDataDirectoryContents, [
            "documentation.json",
            "documentation/innerfirst.json",
            "documentation/innerfirst/somethingpublic.json",
            "documentation/innersecond.json",
            "documentation/innersecond/somethingpublic.json",
            "documentation/nestedinner.json",
            "documentation/nestedinner/somethingpublic.json",
            "documentation/outer.json",
            "documentation/outer/somethingpublic.json",
        ])
        
        // Verify that each 'docc convert' call was passed the expected dependencies
        
        let doccConvertCalls = result.standardOutput
            .components(separatedBy: .newlines)
            .filter { line in
                line.hasPrefix("docc invocation: '") && line.utf8.contains("docc convert ".utf8)
            }.map { line in
                line.trimmingCharacters(in: CharacterSet(charactersIn: "'"))
                    .components(separatedBy: .whitespaces)
                    .drop(while: { $0 != "convert" })
            }
        
        XCTAssertEqual(doccConvertCalls.count, 4)
        
        func extractDependencyArchives(targetName: String, file: StaticString = #filePath, line: UInt = #line) throws -> [String] {
            let arguments = try XCTUnwrap(
                doccConvertCalls.first(where: { $0.contains(["--fallback-display-name", targetName]) }),
                file: file, line: line
            )
            var dependencyPaths: [URL] = []
            
            var remaining = arguments[...]
            while !remaining.isEmpty {
                remaining = remaining.drop(while: { $0 != "--dependency" }).dropFirst(/* the '--dependency' element */)
                if let path = remaining.popFirst() {
                    dependencyPaths.append(URL(fileURLWithPath: path))
                }
            }
            
            return dependencyPaths.map { $0.lastPathComponent }.sorted()
        }
        // Outer
        // ├─ InnerFirst
        // ╰─ InnerSecond
        //    ╰─ NestedInner
        
        XCTAssertEqual(try extractDependencyArchives(targetName: "Outer"), [
            "InnerFirst.doccarchive",
            "InnerSecond.doccarchive",
        ], "The outer target has depends on both inner targets")
        
        XCTAssertEqual(try extractDependencyArchives(targetName: "InnerFirst"), [], "The first inner target has no dependencies")
        
        XCTAssertEqual(try extractDependencyArchives(targetName: "InnerSecond"), [
            "NestedInner.doccarchive",
        ], "The second inner target has depends on the nested inner target")
        
        XCTAssertEqual(try extractDependencyArchives(targetName: "NestedInner"), [], "The nested inner target has no dependencies")
#else
        XCTSkip("This test requires a Swift-DocC version that support the link-dependencies feature")
#endif
    }
}
