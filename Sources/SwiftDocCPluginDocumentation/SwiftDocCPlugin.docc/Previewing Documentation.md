# Previewing Documentation

Use your web browser to preview the documentation for a target in your package.

## Overview

The Swift-DocC plugin supports running a local web server to allow for exploring the documentation
in a project or previewing the documentation you're writing.

Because the `preview-documentation` command uses a local web server, you'll need to disable
the SwiftPM plugin's sandboxing functionality which blocks all network access by default.

To preview documentation for a specific target in your project, run the following from
the root of the Swift Package containing the target you'd like to preview:

    $ swift package --disable-sandbox --target [target-name] preview-documentation

Swift-DocC will print something like the following:

    ========================================
    Starting Local Preview Server
         Address: http://localhost:8000/documentation/swiftdoccplugin
    ========================================
    Monitoring /Developer/swift-docc-plugin/Sources/SwiftDocCPluginDocumentation/SwiftDocCPlugin.docc for changes...

Navigate to the printed address in your browser to preview documentation for the target.

<!-- Copyright (c) 2022 Apple Inc and the Swift Project authors. All Rights Reserved. -->
