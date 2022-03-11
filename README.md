# Swift-DocC Plugin

The Swift-DocC plugin is a Swift Package Manager command plugin that supports building
documentation for SwiftPM libraries and executables.

## Usage

Please see 
[the plugin's documentation](https://apple.github.io/swift-docc-plugin/documentation/swiftdoccplugin/)
for more detailed usage instructions.

We anticipate releasing a `1.0` version of the Swift-DocC plugin aligned with
the release of Swift `5.6`.

### Adding the Swift-DocC Plugin as a Dependency

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

Swift 5.6 is required in order to run the plugin.

### Converting Documentation

You can then invoke the plugin from the root of your repository like so:

```shell
swift package generate-documentation
```

This will generate documentation for all compatible targets defined in your package and its dependencies 
and print the location of the resulting DocC archives.

If you'd like to generate documentation for a specific target and output that
to a specific directory, you can do something like the following:

```shell
swift package --allow-writing-to-directory ./docs \
    generate-documentation --target MyFramework --output-path ./docs
```

Notice that the output path must also be passed to SwiftPM via the 
`--allow-writing-to-directory` option. Otherwise SwiftPM will throw an error
as it's a sandbox violation for a plugin to write to a package directory without explicit
permission.

Any flag passed after the `generate-documentation` plugin invocation is passed
along to the `docc` command-line tool. For example, to take advantage of Swift-DocC's new support
for hosting in static environments like GitHub Pages, you could run the following:

```shell
swift package --allow-writing-to-directory ./docs \
    generate-documentation --target MyFramework --output-path ./docs \
    --transform-for-static-hosting --hosting-base-path MyFramework
```

### Previewing Documentation

The Swift-DocC plugin also supports previewing documentation with a local web server. However,
unlike converting documentation, previewing is limited to a single target a time.

To preview documentation for the MyFramework target, you could run the following:

```shell
swift package --disable-sandbox preview-documentation --target MyFramework
```

To preview documentation for a product defined by one of your package's dependencies,
you could run the following:

```shell
swift package --disable-sandbox preview-documentation --product OtherFramework
```

### Hosting Documentation

For details on how to best build documentation for hosting online and a specific
tutorial for publishing to GitHub Pages, please see 
[the plugin's documentation](https://apple.github.io/swift-docc-plugin/documentation/swiftdoccplugin/).

### Submitting a Feature Request

For feature requests, please feel free to create an issue
on [Swift JIRA](https://bugs.swift.org/) with the `New Feature` type
or start a discussion on the [Swift Forums](https://forums.swift.org/c/development/swift-docc).

Don't hesitate to submit a feature request if you see a way
the Swift-DocC plugin can be improved to better meet your needs.

All user-facing features must be discussed
in the [Swift Forums](https://forums.swift.org/c/development/swift-docc)
before being enabled by default.

## Contributing to the Swift-DocC Plugin

Please see the [contributing guide](/CONTRIBUTING.md) for more information.

<!-- Copyright (c) 2022 Apple Inc and the Swift Project authors. All Rights Reserved. -->
