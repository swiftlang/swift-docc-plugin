# ``SwiftDocCPlugin``

Produce Swift-DocC documentation for Swift Package libraries and executables.

@Metadata {
    @DisplayName("Swift-DocC Plugin")
}

## Overview

The Swift-DocC plugin is a Swift Package Manager command plugin that supports building
documentation for SwiftPM libraries and executables.

To use the Swift-DocC plugin with your package, first add it as a dependency:

```swift
let package = Package(
    // name, platforms, products, etc.
    dependencies: [
        // other dependencies
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        // targets
    ]
)
```

> Note: Swift 5.6 or higher is required in order to run the plugin.

Then, build documentation for the libraries and executables in that package and its dependencies by running the
following from the command-line:

    $ swift package generate-documentation

The documentation on this site is focused on the Swift-DocC plugin specifically. For more
general documentation on how to use Swift-DocC, see the documentation 
[here](https://www.swift.org/documentation/docc/).

## Topics

### Getting Started

- <doc:Generating-Documentation-for-a-Specific-Target>
- <doc:Previewing-Documentation>

### Publishing Documentation

- <doc:Generating-Documentation-for-Hosting-Online>
- <doc:Publishing-to-GitHub-Pages>

<!-- Copyright (c) 2022 Apple Inc and the Swift Project authors. All Rights Reserved. -->
