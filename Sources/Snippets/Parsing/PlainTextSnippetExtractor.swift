// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

enum SnippetVisibility {
    case shown
    case hidden
}

extension StringProtocol {
    /// If the string is a line comment, attempt to parse
    /// a ``SnippetVisibility`` with `snippet.show` or `snippet.hide`.
    var parsedVisibilityMark: SnippetVisibility? {
        guard var comment = parsedLineCommentText else {
            return nil
        }

        comment = comment.drop { $0.isWhitespace }

        if comment.lowercased().starts(with: "snippet.show") {
            return SnippetVisibility.shown
        } else if comment.lowercased().starts(with: "snippet.hide") {
            return SnippetVisibility.hidden
        } else {
            return nil
        }
    }

    /// If the string is a line comment starting with `"//"`, return the
    /// contents with the comment marker stripped.
    var parsedLineCommentText: Self.SubSequence? {
        var trimmed = self.drop { $0.isWhitespace }
        guard trimmed.starts(with: "//") else {
            return nil
        }
        trimmed.removeFirst(2)
        return trimmed
    }

    var isEmptyOrWhiteSpace: Bool {
        return self.isEmpty || self.allSatisfy { $0.isWhitespace }
    }
}

extension String {
    /// Returns a re-indented string with the most indentation removed
    /// without changing the relative indentation between lines. This is
    /// useful for re-indenting some inner part of a block of nested code.
    mutating func trimExtraIndentation() {
        var lines = self.split(separator: "\n", maxSplits: Int.max,
                               omittingEmptySubsequences: false)
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
            .joined(separator: "\n")
    }
}

/// Extracts a ``Snippet`` structure from Swift source code.
///
/// - todo: In order to support different styles of comments, it might be
///   better to adopt SwiftSyntax if possible in the future.
struct PlainTextSnippetExtractor {
    var source: String
    var explanation = ""
    var presentationCode = ""
    private var currentVisibility = SnippetVisibility.shown

    init(source: String) {
        self.source = source
        var lines = source.split(separator: "\n", omittingEmptySubsequences: false)[...]
            .drop { $0.isEmptyOrWhiteSpace }

        var explanationLines = [Substring]()
        for line in lines {
            guard let commentText = line.parsedLineCommentText,
                  line.parsedVisibilityMark == nil else {
                break
            }
            explanationLines.append(commentText)
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
        self.explanation = explanationLines.joined(separator: "\n")

        lines.removeFirst(explanationLines.count)

        for line in lines {
            if let visibility = line.parsedVisibilityMark {
                self.currentVisibility = visibility
                continue
            }

            guard case .shown = currentVisibility else {
                continue
            }

            print(line, to: &presentationCode)
        }
        explanation = explanation.trimmingCharacters(in: ["\n"])
        presentationCode = presentationCode.trimmingCharacters(in: ["\n"])
        presentationCode.trimExtraIndentation()
    }
}
