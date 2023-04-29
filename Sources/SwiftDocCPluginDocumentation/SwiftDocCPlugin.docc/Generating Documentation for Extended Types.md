# Generating Documentation for Extended Types

Generate documentation for the extensions you make to types from other modules.

## Overview

The Swift-DocC plugin allows you to document extensions you make to types that are not from the module you're generating documentation for.

To enable/disable extension support, add the `--include-extended-types` or `--exclude-extended-types` flag to your invocations, respectively:

    $ swift package generate-documentation --include-extended-types

    $ swift package generate-documentation --exclude-extended-types

> Note: Extension support is available when using Swift 5.8 or later and the Swift-DocC plugin 1.2 or later. Extension support is enabled by default starting swith Swift 5.9 and the Swift-DocC plugin 1.3.

## Understanding What is an Extended Type

Not every type you add an extension to is an extended type. If the extension is declared in the same target as the type it is extending, the extension's contents will always be included in the documentation. Only extensions you make to types from other targets are represented as an external type in your documentation archive.

```swift
public struct Sloth { }

extension Sloth {
    // This function is always included
    // in the documentation.
    public func wake() { /* ... */ }
}

// `Collection` is from the standard library,
// not the `SlothCreator` library, so this is
// what we call an "extended type".
extension Collection where Element == Sloth {
    // This property is only included in
    // the documentation if extension
    // support is enabled.
    public func wake() {
        for sloth in self {
            sloth.wake()
        }
    }
}
```

## Finding Extended Types in your Documentation

Extended Types are part of the documentation archive of the target that declares the extensions.

![The rendered documentation for SlothCreator/Swift/Collection](extended-type-example)

Within that documentation archive, Extended Types are grouped by the Extended Module they belong to. You can find the latter on your documentation's landing page in a section called "Extended Modules". In our example from above, we have one Extended Module called "Swift" - the name of the standard library. This page can be referenced like this: ` ``SlothCreator/Swift`` `.

The Extended Type ` ``SlothCreator/Swift/Collection`` ` is a child of the Extended Module and is listed under "Extended Protocols" on the ` ``SlothCreator/Swift`` ` page.

> Note: The references above use the full path, including the name of the catalog's target, `SlothCreator`. This should help to understand the symbol's exact location, but usually isn't necessary.

<!-- Copyright (c) 2023 Apple Inc and the Swift Project authors. All Rights Reserved. -->
