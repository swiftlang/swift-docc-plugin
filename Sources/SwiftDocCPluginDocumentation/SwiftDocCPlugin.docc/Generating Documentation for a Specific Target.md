# Generating Documentation for a Specific Target

Generate documentation for a specific target in your package.

## Overview

By default, the Swift-DocC plugin will generate documentation for every
compatible target in a package.

    $ swift package generate-documentation

To limit to a specific target, pass the name of the target to the `swift package` command.

    $ swift package --target [target-name] generate-documentation

<!-- Copyright (c) 2022 Apple Inc and the Swift Project authors. All Rights Reserved. -->
