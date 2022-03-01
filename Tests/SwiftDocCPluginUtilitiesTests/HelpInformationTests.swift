// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
@testable import SwiftDocCPluginUtilities
import XCTest

final class HelpInformationTests: XCTestCase {
    func testEmitHelpForConvertAction() throws {
        HelpInformation._doccHelp = { _, _ in
            return try self.testResourceAsString(named: "DocCConvertHelpFixture")
        }
        
        let convertHelpInformation = try HelpInformation.forAction(
            .convert,
            doccExecutableURL: URL(fileURLWithPath: "/")
        )
        
        XCTAssertEqual(
            convertHelpInformation,
            """
            OVERVIEW: Creates a Swift-DocC documentation archive from a Swift Package.
            
            USAGE: swift package [<package-manager-option>] generate-documentation [<plugin-options>] [<docc-options>]

            PACKAGE MANAGER OPTIONS:
              --allow-writing-to-package-directory
                                      Allow the plugin to write to the package directory.
              --allow-writing-to-directory <directory-path>
                                      Allow the plugin to write to an additional directory.

            PLUGIN OPTIONS:
              --target <target>       Generate documentation for the specified target.
              --product <product>     Generate documentation for the specified product.
              --disable-indexing, --no-indexing
                                      Disable indexing for the produced DocC archive.
                    Produces a DocC archive that is best-suited for hosting online but incompatible with Xcode.

            DOCC OPTIONS:
              --platform <platform>   Set the current release version of a platform.
                    Use the following format: "name={platform name},version={semantic version}".
              --analyze               Outputs additional analyzer style warnings in addition to standard warnings/errors.
              --emit-digest           Writes additional metadata files to the output directory.
              --index                 Writes the navigator index to the output directory.
              --emit-fixits/--no-emit-fixits
                                      Outputs fixits for common issues (default: false)
              --experimental-documentation-coverage
                                      Generates documentation coverage output. (currently Experimental)
              --level <level>         Desired level of documentation coverage output. (default: none)
              --kinds <kind>          The kinds of entities to filter generated documentation for.
              --experimental-enable-custom-templates
                                      Allows for custom templates, like `header.html`.
              --enable-inherited-docs Inherit documentation for inherited symbols
              --fallback-display-name, --display-name <fallback-display-name>
                                      A fallback display name if no value is provided in the documentation bundle's Info.plist file.
              --fallback-bundle-identifier, --bundle-identifier <fallback-bundle-identifier>
                                      A fallback bundle identifier if no value is provided in the documentation bundle's Info.plist
                                      file.
              --fallback-bundle-version, --bundle-version <fallback-bundle-version>
                                      A fallback bundle version if no value is provided in the documentation bundle's Info.plist
                                      file.
              --default-code-listing-language <default-code-listing-language>
                                      A fallback default language for code listings if no value is provided in the documentation
                                      bundle's Info.plist file.
              --fallback-default-module-kind <fallback-default-module-kind>
                                      A fallback default module kind if no value is provided in the documentation bundle's
                                      Info.plist file.
              --output-path, --output-dir <output-path>
                                      The location where the documentation compiler writes the built documentation.
              --additional-symbol-graph-dir <additional-symbol-graph-dir>
                                      A path to a directory of additional symbol graph files.
              --diagnostic-level <diagnostic-level>
                                      Filters diagnostics above this level from output
                    This filter level is inclusive. If a level of `information` is specified, diagnostics with a severity up to and
                    including `information` will be printed.
                    This option is ignored if `--analyze` is passed.
                    Must be one of "error", "warning", "information", or "hint"
              --transform-for-static-hosting
                                      Produce a Swift-DocC Archive that supports a static hosting environment.
              --hosting-base-path <hosting-base-path>
                                      The base path your documentation website will be hosted at.
                    For example, to deploy your site to 'example.com/my_name/my_project/documentation' instead of
                    'example.com/documentation', pass '/my_name/my_project' as the base path.
              -h, --help              Show help information.

            """
        )
    }
    
    func testEmitHelpForPreviewAction() throws {
        HelpInformation._doccHelp = { _, _ in
            return try self.testResourceAsString(named: "DocCPreviewHelpFixture")
        }
        
        let previewHelpInformation = try HelpInformation.forAction(
            .preview,
            doccExecutableURL: URL(fileURLWithPath: "/")
        )
        
        XCTAssertEqual(
            previewHelpInformation,
            """
            OVERVIEW: Creates and previews a Swift-DocC documentation archive from a Swift Package.

            USAGE: swift package --disable-sandbox [<package-manager-option>] preview-documentation [<plugin-options>] [<docc-options>]

            NOTE: This plugin is only able to preview a single target at a time. If your
                  package contains more than one documentable target, you must specify which
                  target should be previewed with the --target or --product option.

            PACKAGE MANAGER OPTIONS:
              --disable-sandbox
                                      Disable using the sandbox when executing subprocesses.
                    This flag is **required** when previewing documentation because Swift-DocC
                    preview requires local network access to run a local web server.
              --allow-writing-to-package-directory
                                      Allow the plugin to write to the package directory.
              --allow-writing-to-directory <directory-path>
                                      Allow the plugin to write to an additional directory.

            PLUGIN OPTIONS:
              --target <target>       Preview documentation for the specified target.
              --product <product>     Preview documentation for the specified product.
              --disable-indexing, --no-indexing
                                      Disable indexing for the produced DocC archive.
                    Produces a DocC archive that is best-suited for hosting online but incompatible with Xcode.
            
            DOCC OPTIONS:
              --platform <platform>   Set the current release version of a platform.
                    Use the following format: "name={platform name},version={semantic version}".
              --analyze               Outputs additional analyzer style warnings in addition to standard warnings/errors.
              --emit-digest           Writes additional metadata files to the output directory.
              --index                 Writes the navigator index to the output directory.
              --emit-fixits/--no-emit-fixits
                                      Outputs fixits for common issues (default: false)
              --experimental-documentation-coverage
                                      Generates documentation coverage output. (currently Experimental)
              --level <level>         Desired level of documentation coverage output. (default: none)
              --kinds <kind>          The kinds of entities to filter generated documentation for.
              --experimental-enable-custom-templates
                                      Allows for custom templates, like `header.html`.
              --enable-inherited-docs Inherit documentation for inherited symbols
              --fallback-display-name, --display-name <fallback-display-name>
                                      A fallback display name if no value is provided in the documentation bundle's Info.plist file.
              --fallback-bundle-identifier, --bundle-identifier <fallback-bundle-identifier>
                                      A fallback bundle identifier if no value is provided in the documentation bundle's Info.plist
                                      file.
              --fallback-bundle-version, --bundle-version <fallback-bundle-version>
                                      A fallback bundle version if no value is provided in the documentation bundle's Info.plist
                                      file.
              --default-code-listing-language <default-code-listing-language>
                                      A fallback default language for code listings if no value is provided in the documentation
                                      bundle's Info.plist file.
              --fallback-default-module-kind <fallback-default-module-kind>
                                      A fallback default module kind if no value is provided in the documentation bundle's
                                      Info.plist file.
              --output-path, --output-dir <output-path>
                                      The location where the documentation compiler writes the built documentation.
              --additional-symbol-graph-dir <additional-symbol-graph-dir>
                                      A path to a directory of additional symbol graph files.
              --diagnostic-level <diagnostic-level>
                                      Filters diagnostics above this level from output
                    This filter level is inclusive. If a level of `information` is specified, diagnostics with a severity up to and
                    including `information` will be printed.
                    This option is ignored if `--analyze` is passed.
                    Must be one of "error", "warning", "information", or "hint"
              --transform-for-static-hosting
                                      Produce a Swift-DocC Archive that supports a static hosting environment.
              --hosting-base-path <hosting-base-path>
                                      The base path your documentation website will be hosted at.
                    For example, to deploy your site to 'example.com/my_name/my_project/documentation' instead of
                    'example.com/documentation', pass '/my_name/my_project' as the base path.
              -p, --port <port-number>
                                      Port number to use for the preview web server. (default: 8000)
              -h, --help              Show help information.
            
            """
        )
    }
}

