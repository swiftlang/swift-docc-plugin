# Generating Documentation for Extended Types

Generate documentation for the extensions you make to types from other modules.

## Overview

By default, the Swift-DocC plugin ignores extensions that you make to types that are not from the module you're generating documentation for.

```swift
import OtherModule

public struct LocalType { }

public extension LocalType {
    /// This function is included in the
    /// documentation by default.
    func foo() { }
}

// ExternalType is from OtherModule, so
// this what we call an "extended type".
public extension ExternalType {
    /// This function is not included in
    /// the documentation by default.
    func foo() { }
}
```

To include documentation for extended types, add the `--include-extended-types` flag to your invocations:

    $ swift package generate-documentation --include-extended-types

> Note: Swift 5.8 or higher and the Swift-DocC plugin version 1.2 or higher is required in order to use this flag.

<!-- Copyright (c) 2023 Apple Inc and the Swift Project authors. All Rights Reserved. -->
