# Generating Documentation for Hosting Online

Generate documentation for hosting online at static hosts like 
GitHub Pages or on your own server.

## Overview

By default, the Swift-DocC plugin will generate an index of content that is useful for IDE's,
like Xcode, to render a navigator of all included documentation in the archive. Since this index
isn't relevant when hosting online, you can pass the `--disable-indexing` flag
when generating documentation thats intended for an online host.

    $ swift package generate-documentation --target [target-name] --disable-indexing

You'll likely want to pass an output path to Swift-DocC to send the relevant files
to a specific directory. 

> Important: Remember to pass the `--allow-writing-to-directory` flag
> to include that directory in the SwiftPM sandboxing environment for the Swift-DocC plugin.

    $ swift package --allow-writing-to-directory [output-directory-path] \ 
        generate-documentation --target [target-name] --disable-indexing \
        --output-path [output-directory-path]

The files at the passed `[output-directory-path]` are now ready to be published online. Please
see the documentation 
[here](https://www.swift.org/documentation/docc/distributing-documentation-to-other-developers#Host-a-Documentation-Archive-on-Your-Website)
that explains how to configure the necessary routing rules for hosting a Swift-DocC archive
on your local server.

## Transforming for Static Hosting

Alternatively, if you'd like to avoid setting custom routing rules on your server or are
hosting in an environment where this isn't possible, you can generate documentation that
has been transformed for static hosting.

    $ swift package --allow-writing-to-directory [output-directory-path] \ 
        generate-documentation --target [target-name] --disable-indexing \
        --output-path [output-directory-path] \
        --transform-for-static-hosting

This addition of the `--transform-for-static-hosting` flag removes the need of setting
any custom routing rules on your website, as long as you're hosting the documentation
at the root of your website. If you'd like to host your documentation at a sub-path, you
can use the `--hosting-base-path` argument.

    $ swift package --allow-writing-to-directory [output-directory-path] \ 
        generate-documentation --target [target-name] --disable-indexing \
        --output-path [output-directory-path] \
        --transform-for-static-hosting \
        --hosting-base-path [hosting-base-path]

<!-- Copyright (c) 2022 Apple Inc and the Swift Project authors. All Rights Reserved. -->
