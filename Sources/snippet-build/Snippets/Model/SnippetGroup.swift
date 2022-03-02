// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation

/// A group of snippets.
public struct SnippetGroup {
    /// The identifier of the group, assumed to be namespaced within a module or package.
    var name: String

    /// The base directory that contained the snippets.
    var baseDirectory: URL?

    /// The snippets comprising the group.
    var snippets: [Snippet]

    /// A short abstract explaining the theme of the group.
    var explanation: String

    /// Create a group of snippets from already parsed snippets.
    init(name: String, baseDirectory: URL?, snippets: [Snippet], explanation: String) {
        self.name = name
        self.baseDirectory = baseDirectory
        self.snippets = snippets
        self.explanation = explanation
        for index in self.snippets.indices {
            self.snippets[index].groupName = baseDirectory?.lastPathComponent
        }
    }
}
