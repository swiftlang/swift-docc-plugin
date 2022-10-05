// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation

extension StringProtocol {
    var isEmptyOrWhiteSpace: Bool {
        return self.isEmpty || self.allSatisfy { $0.isWhitespace }
    }
}

extension Array where Element == Substring {
    /// Returns a re-indented string with the most indentation removed
    /// without changing the relative indentation between lines. This is
    /// useful for re-indenting some inner part of a block of nested code.
    mutating func trimExtraIndentation() {
        var lines = self
        
        lines = Array(lines
                        .drop(while: { $0.isEmptyOrWhiteSpace })
                        .reversed()
                        .drop(while: { $0.isEmptyOrWhiteSpace })
                        .reversed())

        let minimumIndentation = lines.map {
            guard !$0.isEmpty else {
                return Int.max
            }
            return $0.prefix { $0 == " " }.count
        }.min() ?? 0

        guard minimumIndentation > 0 else {
            return
        }

        self = lines.map { $0.dropFirst(minimumIndentation) }
    }
    
    mutating func trimEmptyOrWhitespaceLines() {
        while let last = last , last.isEmptyOrWhiteSpace {
            removeLast()
        }
        self = Array(drop { $0.isEmptyOrWhiteSpace })
    }
}

extension Substring {
    // If the substring starts with `prefix`, remove it and return `true`, otherwise return `false`.
    mutating func trimExpectedPrefix<S: StringProtocol>(_ prefix: S, considerCase: Bool = true) -> Bool {
        if considerCase {
            guard starts(with: prefix) else {
                return false
            }
            removeFirst(prefix.count)
        } else {
            let lowercasePrefix = prefix.lowercased()
            guard lowercased().starts(with: lowercasePrefix) else {
                return false
            }
            removeFirst(lowercasePrefix.count)
        }
        
        return true
    }
}

/// Extracts a ``Snippet`` structure from Swift source code.
///
/// - todo: In order to support different styles of comments, it might be
///   better to adopt SwiftSyntax if possible in the future.
struct SnippetParser {
    var source: String
    var explanationLines = [Substring]()
    var presentationLines = [Substring]()
    var slices = [String: Range<Int>]()
    var currentSlice: (identifier: String, startLine: Int)? = nil
    private var isVisible = true
    
    mutating func startNewSlice(identifier: String, from lineNumber: Int) {
        if currentSlice != nil {
            endSlice()
        }
        currentSlice = (identifier, lineNumber)
    }
    
    mutating func endSlice() {
        guard let currentSlice = currentSlice else {
            return
        }
        guard currentSlice.startLine < presentationLines.count else {
            self.currentSlice = nil
            return
        }
        slices[currentSlice.identifier] = currentSlice.startLine..<presentationLines.count
        self.currentSlice = nil
    }
    
    mutating func extractExplanation(from lines: inout ArraySlice<Substring>) {
        var explanationLines = [Substring]()
        for var line in lines {
            guard !line.isEmptyOrWhiteSpace,
                  SnippetParser.tryParseSnippetMarker(from: line) == nil else {
                break
            }
            guard SnippetParser.tryParseCommentMarkerPrefix(from: &line) else {
                break
            }
            explanationLines.append(line)
        }
        
        // Indentation to be removed from subsequent lines is measured
        // from the first comment line with content.
        let measuredIndentationFromFirstLineWithContent = explanationLines.first {
            !$0.isEmptyOrWhiteSpace
        }?.prefix { $0.isWhitespace }.count ?? 0
        explanationLines = explanationLines.map {
            let whitespaceAmountOnThisLine = $0.prefix { $0.isWhitespace }.count
            return $0.dropFirst(min(whitespaceAmountOnThisLine, measuredIndentationFromFirstLineWithContent))
        }
        lines.removeFirst(explanationLines.count)
        explanationLines.trimEmptyOrWhitespaceLines()
        self.explanationLines = explanationLines
    }
    
    init(source: String) {
        self.source = source
        var lines = source.split(separator: "\n", omittingEmptySubsequences: false)[...]
            .drop { $0.isEmptyOrWhiteSpace }
        
        extractExplanation(from: &lines)
                
        var lineNumber = 0
        for line in lines {
            switch SnippetParser.parseContent(from: line) {
            case let .visibilityChange(isVisible):
                self.isVisible = isVisible
            case let .startSlice(identifier: identifier):
                if isVisible {
                    startNewSlice(identifier: identifier, from: lineNumber)
                }
            case .endSlice:
                endSlice()
            case .presentationLine:
                if isVisible &&
                    // Don't include leading empty lines in the presentation content.
                    !(presentationLines.isEmpty && line.isEmptyOrWhiteSpace){
                    presentationLines.append(line)
                    lineNumber += 1
                }
            }
        }
        
        endSlice()
        slices = slices.mapValues {
            // Trim leading and trailing blank lines from slice ranges.
            var lowerBound = $0.lowerBound
            var upperBound = $0.upperBound
            while lowerBound < upperBound && presentationLines[lowerBound].isEmptyOrWhiteSpace {
                lowerBound += 1
            }
            while lowerBound < upperBound && presentationLines[upperBound - 1].isEmptyOrWhiteSpace {
                upperBound -= 1
            }
            return lowerBound..<upperBound
        }
        
        presentationLines.trimExtraIndentation()
        // Trim only trailing empty lines so as not to invalidate slice line ranges.
        while let last = presentationLines.last, last.isEmptyOrWhiteSpace {
            presentationLines.removeLast()
        }
    }
}

// MARK: Parsing Functions
extension SnippetParser {
    enum LineParseResult: Equatable {
        case visibilityChange(isVisible: Bool)
        case startSlice(identifier: String)
        case endSlice
        case presentationLine
    }
    
    static func tryParseSnippetMarker(from line: Substring) -> LineParseResult? {
        var line = line
        guard SnippetParser.tryParseCommentMarkerPrefix(from: &line) else {
            return nil
        }
        
        line = line.drop { $0.isWhitespace }
            
        guard line.trimExpectedPrefix("snippet.", considerCase: false) else {
            return nil
        }
        
        if line.trimExpectedPrefix("show", considerCase: false) {
            return .visibilityChange(isVisible: true)
        } else if line.trimExpectedPrefix("hide", considerCase: false) {
            return .visibilityChange(isVisible: false)
        } else if line.trimExpectedPrefix("end", considerCase: false) {
            return .endSlice
        } else {
            let identifier = String(line.prefix(while: { !$0.isWhitespace }))
            guard CharacterSet(charactersIn: identifier).isSubset(of: CharacterSet.urlPathAllowed) else {
                // TODO: Collect an error message.
                return nil
            }
            return .startSlice(identifier: identifier)
        }
    }
    
    static func tryParseCommentMarkerPrefix(from line: inout Substring) -> Bool {
        var trimmed = line.drop { $0.isWhitespace }
        guard trimmed.trimExpectedPrefix("//") else {
            return false
        }
        line = trimmed
        return true
    }
    
    static func parseContent(from line: Substring) -> LineParseResult {
        if let marker = tryParseSnippetMarker(from: line) {
            return marker
        }
        return .presentationLine
    }
}
