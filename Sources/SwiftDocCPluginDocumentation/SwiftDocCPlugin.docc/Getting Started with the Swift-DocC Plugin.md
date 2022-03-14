# Getting Started with the Swift-DocC Plugin

Add the Swift-DocC plugin as a dependency of your package and generate Swift-DocC documentation. 

## Overview

To use the Swift-DocC Plugin with your package, first add it as a dependency:

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

> Important: Swift 5.6 is required in order to run the plugin. 

You can then invoke the plugin from the root of your repository like so:

    $ swift package generate-documentation

<!-- Copyright (c) 2022 Apple Inc and the Swift Project authors. All Rights Reserved. -->
