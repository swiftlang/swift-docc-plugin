// This source file is part of the Swift.org open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

/// The comment syntax used by a language for snippet markers and explanations
public enum CommentStyle: Sendable {
    /// Line comment with a given prefix, e.g. `//` or `#`
    case lineComment(String)
    /// Block comment with a prefix and suffix, e.g. `<!--` and `-->`
    ///
    /// Both single-line (e.g. `<!-- snippet.hide -->`) and multiline block
    /// comments are supported as snippet markers. A multiline block comment
    /// is recognized as a snippet marker only when the sole non-whitespace
    /// content between the prefix and suffix is a valid snippet command
    case blockComment(prefix: String, suffix: String)

    /// Inline comment style using `//`
    public static var slashSlash: Self { 
        .lineComment("//")
    }
    
    /// Inline comment style using `#`
    public static var hash: Self { 
        .lineComment("#")
    }

    /// Default comment style for XML/HTML comments
    public static var xml: Self {
        .blockComment(prefix: "<!--", suffix: "-->")
    }

    /// C-style block comment `/* ... */`
    public static var cBlock: Self {
        .blockComment(prefix: "/*", suffix: "*/")
    }
}

/// A programming language supported for code snippets
public enum SnippetLanguage: String, CaseIterable, Sendable {
    case swift
    case java
    case kotlin
    case c
    case cpp = "c++"
    case objectiveC = "objective-c"
    case csharp
    case go
    case rust
    case javascript
    case typescript
    case scala
    case groovy
    case python
    case ruby
    case bash
    case zsh
    case xml
    case html
    case yaml
    case toml

    /// The language identifier used in symbol graphs and for syntax highlighting
    public var id: String {
        rawValue
    }

    /// The comment styles used by this language
    public var commentStyles: [CommentStyle] {
        switch self {
        case .python, .bash, .zsh, .ruby, .yaml, .toml:
            return [.hash]
        case .xml, .html:
            return [.xml]
        default:
            return [.slashSlash, .cBlock]
        }
    }

    /// The file extensions associated with this language
    public var fileExtensions: [String] {
        switch self {
        case .swift:       return ["swift"]
        case .java:        return ["java"]
        case .kotlin:      return ["kt"]
        case .c:           return ["c", "h"]
        case .cpp:         return ["cpp", "hpp", "cc", "cxx"]
        case .objectiveC:  return ["m", "mm"]
        case .csharp:      return ["cs"]
        case .go:          return ["go"]
        case .rust:        return ["rs"]
        case .javascript:  return ["js", "jsx"]
        case .typescript:  return ["ts", "tsx"]
        case .scala:       return ["scala"]
        case .groovy:      return ["groovy"]
        case .python:      return ["py"]
        case .ruby:        return ["rb"]
        case .bash:        return ["sh", "bash"]
        case .zsh:         return ["zsh"]
        case .html:        return ["html", "htm", "xhtml"]
        case .xml:         return ["xml"]
        case .yaml:        return ["yaml", "yml"]
        case .toml:        return ["toml"]
        }
    }

    /// All file extensions supported for snippet extraction
    public static var supportedFileExtensions: Set<String> {
        Set(allCases.flatMap(\.fileExtensions))
    }

    /// Look up the language for a given file extension
    ///
    /// - Parameter ext: A file extension (without the leading dot), e.g. `"swift"`, `"java"`, `"cpp"`
    /// - Returns: The matching language, or `nil` if the extension is not supported
    public static func language(forFileExtension ext: String) -> SnippetLanguage? {
        let lowered = ext.lowercased()
        return allCases.first { $0.fileExtensions.contains(lowered) }
    }

    /// Look up the comment styles for a given file extension
    ///
    /// For unknown extensions, falls back to `//` line comments first,
    /// then `#` line comments, covering the most common comment syntaxes
    public static func commentStyles(forFileExtension ext: String) -> [CommentStyle] {
        if let knownLanguage = language(forFileExtension: ext) {
            knownLanguage.commentStyles
        } else {
            // wild guess, let's assume those are fine
            [.slashSlash, .hash]
        }
    }
}
