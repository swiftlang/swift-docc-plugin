# Contributing to Swift-DocC Plugin

## Introduction

### Welcome

Thank you for considering contributing to the Swift-DocC Plugin.

Please know that everyone is welcome to contribute to Swift-DocC.
Contributing doesn’t just mean submitting pull requests—there are 
many different ways for you to get involved,
including answering questions on the 
[Swift Forums](https://forums.swift.org/c/development/swift-docc),
reporting or screening bugs, and writing documentation. 

No matter how you want to get involved,
we ask that you first learn what’s expected of anyone who participates in
the project by reading the [Swift Community Guidelines](https://swift.org/community/)
as well as our [Code of Conduct](/CODE_OF_CONDUCT.md).

This document focuses on how to contribute code and documentation to
this repository.

### Legal

By submitting a pull request, you represent that you have the right to license your
contribution to Apple and the community, and agree by submitting the patch that your 
contributions are licensed under the Apache 2.0 license (see [`LICENSE.txt`](/LICENSE.txt)).

## Contributions Overview

The Swift-DocC plugin is an open source project and we encourage contributions
from the community.

### Contributing Code and Documentation

Before contributing code or documentation to the Swift-DocC plugin,
we encourage you to first create an issue on [Swift JIRA](https://bugs.swift.org/).
This will allow us to provide feedback on the proposed change.
However, this is not a requirement. If your contribution is small in scope,
feel free to open a PR without first creating an issue.

All changes to the Swift-DocC plugin source must go through the PR review process before
being merged into the `main` branch.
See the [Code Contribution Guidelines](#code-contribution-guidelines) below for
more details.

## Building the Swift-DocC Plugin

### Prerequisites

The Swift-DocC plugin is a SwiftPM command plugin package. 
If you're new to Swift package manager,
the [documentation here](https://swift.org/getting-started#using-the-package-manager)
provides an explanation of how to get started and the software you'll need installed.

Note that Swift 5.6 is required in order to run the plugin. 
Development snapshots that include Swift 5.6 can be found
on [Swift.org](https://www.swift.org/download/#snapshots).

### Build Steps

1. Checkout this repository using:

    ```bash
    git clone git@github.com:apple/swift-docc-plugin.git
    ```

2. Navigate to the root of your cloned repository with:

    ```bash
    cd swift-docc-plugin
    ```

3. Create a new branch off of `main` for your change using:

    ```bash
    git checkout -b branch-name-here
    ```

    Note that `main` (the repository's default branch) will always hold the most
    recent approved changes. In most cases, you should branch off of `main` when
    starting your work and open a PR against `main` when you're ready to merge
    that work.

4. Run the Swift-DocC plugin from the command line by running:

    ```bash
    swift package generate-documentation
    ```

## Code Contribution Guidelines

### Overview

- Do your best to keep the git history easy to understand.
  
- Use informative commit titles and descriptions.
  - Include a brief summary of changes as the first line.
  - Describe everything that was added, removed, or changed, and why.

- All changes must go through the pull request review process.

- Follow the [Swift API Design guidelines](https://swift.org/documentation/api-design-guidelines/).

### Pull Request Preparedness Checklist

When you're ready to have your change reviewed, please make sure you've completed the following
requirements:

- [x] Add tests to cover any new functionality or to prevent regressions of a bug fix.

- [x] Run the `/bin/test` script and confirm that the test suite passes.
  (See [Testing Swift-DocC](#testing-swift-docc).)

- [x] Add source code documentation to all added or modified APIs that explains
  the new behavior.

### Opening a Pull Request

When opening a pull request, please make sure to fill out the pull request template
and complete all tasks mentioned there.

Your PR should mention the number of the [Swift JIRA](https://bugs.swift.org/)
issue your work is addressing (SR-NNNNN).
  
Most PRs should be against the `main` branch. If your change is intended 
for a specific release, you should also create a separate branch 
that cherry-picks your commit onto the associated release branch.

### Code Review Process

All PRs will need approval from someone on the core team
(someone with write access to the repository) before being merged.

All PRs must pass the required continuous integration tests as well.
If you have commit access, you can run the required tests by commenting the following on your PR:

```
@swift-ci  Please test
```

If you do not have commit access, please ask one of the code owners to trigger them for you.
For more details on Swift-DocC's continuous integration, see the
[Continous Integration](#continuous-integration) section below.

## Testing Swift-DocC

The Swift-DocC plugin is committed to maintaining a high level of code quality.
Before opening a pull request, we ask that you:

1. Run the full test suite and confirm that it passes.

2. Write new tests to cover any changes you made.

The test suite can be run with the provided [`test`](/bin/test) script
by navigating to the root of the repository and running the following:

  ```bash
  bin/test
  ```

By running tests locally with the `test` script you will be best prepared for
automated testing in CI as well.

The Swift-DocC plugin maintains two test suites. Whenever possible, new code should be added
to the `SwiftDocCPluginUtilities` library instead of directly to a plugin. This allows the logic to be
unit tested within `SwiftDocCPluginUtilitiesTests`. 

Integration tests can be added to the `IntegrationTests` sub-package that is a part of this repo. 
This allows for writing end-to-end tests that invoke both the Swift Package Manager and Swift-DocC 
to ensure the plugin is functioning as expected.

### Using Docker to Test Swift-DocC Plugin for Linux

Today, the Swift-DocC plugin supports both macOS and Linux. While most Swift APIs are
cross-platform, there are some minor differences.
Because of this, all PRs will be automatically tested in both macOS
and Linux environments.

macOS users can test that their changes are compatible with Linux
by running the test suite in a Docker environment that simulates Swift on Linux.

1. Install [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop).

2. Run the following command from the root of this repository
   to build the Swift-DocC Docker image:

    ```bash
    docker build -t swift-docc-plugin:latest .
    ```

3. Run the following command to run the test suite:

    ```bash
    docker run -v `pwd`:/swift-docc-plugin swift-docc-plugin sh -c "cd /swift-docc-plugin && ./bin/test"
    ```
    
## Continuous Integration

Swift-DocC plugin uses [swift-ci](https://ci.swift.org) infrastructure for its continuous integration
testing. The tests can be triggered on pull-requests if you have commit access. 
If you do not have commit access, please ask one of the code owners to trigger them for you.

1. **Test:** Run the project's unit tests on macOS and Linux, along with a selection
   of compatibility suite tests on macOS by commenting the following:

    ```
    @swift-ci Please test
    ```
    
    <details>
     <summary>Platform specific instructions:</summary>
     
     1. Run the project's unit tests on **macOS**, along with a selection of compatibility suite
        tests by commenting the following:
     
         ```
         @swift-ci Please test macOS platform
         ```
     
     2. Run the project's unit tests on **Linux** by commenting the following:
     
         ```
         @swift-ci Please test Linux platform
         ```
     
    </details>
    
<!-- Copyright (c) 2022 Apple Inc and the Swift Project authors. All Rights Reserved. -->
