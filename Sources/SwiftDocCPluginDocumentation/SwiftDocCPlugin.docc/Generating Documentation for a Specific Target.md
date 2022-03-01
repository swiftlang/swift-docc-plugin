# Generating Documentation for a Specific Target

Generate documentation for a specific target in your package.

## Overview

By default, the Swift-DocC plugin will generate documentation for every
compatible target in the current package and its dependencies.

    $ swift package generate-documentation

To limit to a specific target defined in your package, pass the name of the target to the 
`generate-documentation` command.

    $ swift package generate-documentation --target SwiftMarkdown

To limit to a specific product defined in your package _or one of its dependencies_, pass the
name of the product to the `generate-documentation` command.

    $ swift package generate-documentation --product ArgumentParser

<!-- Copyright (c) 2022 Apple Inc and the Swift Project authors. All Rights Reserved. -->
