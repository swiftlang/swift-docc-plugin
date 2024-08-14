// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022-2024 Apple Inc. and the Swift project authors
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
              --verbose               Increase verbosity to include informational output.
            
            SYMBOL GRAPH OPTIONS:
              --experimental-skip-synthesized-symbols
                                      Exclude synthesized symbols from the generated documentation.
                    Experimental feature that produces a DocC archive without compiler synthesized symbols.\(extendedTypesSection)
              --symbol-graph-minimum-access-level
                                      Include symbols with this access level or more. (default: public)
                    Supported access level values are: `open`, `public`, `internal`, `private`, `fileprivate`

            DOCC INPUTS & OUTPUTS:
              <catalog-path>          Path to a '.docc' documentation catalog directory.
              --additional-symbol-graph-dir <additional-symbol-graph-dir>
                                      A path to a directory of additional symbol graph files.
              -o, --output-path, --output-dir <output-path>
                                      The location where the documentation compiler writes the built documentation.

            DOCC AVAILABILITY OPTIONS:
              --platform <platform>   Specify information about the current release of a platform.
                    Each platform's information is specified via separate "--platform" values using the following format: "name={platform name},version={semantic version}".
                    Optionally, the platform information can include a 'beta={true|false}' component. If no beta information is provided, the platform is considered not in beta.

            DOCC SOURCE REPOSITORY OPTIONS:
              --checkout-path <checkout-path>
                                      The root path on disk of the repository's checkout.
              --source-service <source-service>
                                      The source code service used to host the project's sources.
                    Required when using '--source-service-base-url'. Supported values are 'github', 'gitlab', and 'bitbucket'.
              --source-service-base-url <source-service-base-url>
                                      The base URL where the source service hosts the project's sources.
                    Required when using '--source-service'. For example, 'https://github.com/my-org/my-repo/blob/main'.

            DOCC HOSTING OPTIONS:
              --hosting-base-path <hosting-base-path>
                                      The base path your documentation website will be hosted at.
                    For example, if you deploy your site to 'example.com/my_name/my_project/documentation' instead of 'example.com/documentation', pass '/my_name/my_project' as the base path.
              --transform-for-static-hosting/--no-transform-for-static-hosting
                                      Produce a DocC archive that supports static hosting environments. (default: --transform-for-static-hosting)

            DOCC DIAGNOSTIC OPTIONS:
              --analyze               Include 'note'/'information' level diagnostics in addition to warnings and errors.
              --diagnostics-file, --diagnostics-output-path <diagnostics-file>
                                      The location where the documentation compiler writes the diagnostics file.
                    Specifying a diagnostic file path implies '--ide-console-output'.
              --diagnostic-filter, --diagnostic-level <diagnostic-filter>
                                      Filter diagnostics with a lower severity than this level.
                    This option is ignored if `--analyze` is passed.

                    This filter level is inclusive. If a level of 'note' is specified, diagnostics with a severity up to and including 'note' will be printed.
                    The supported diagnostic filter levels are:
                     - error
                     - warning
                     - note, info, information
                     - hint, notice
              --ide-console-output, --emit-fixits
                                      Format output to the console intended for an IDE or other tool to parse.
              --warnings-as-errors    Treat warnings as errors

            DOCC INFO.PLIST FALLBACKS:
              --default-code-listing-language <default-code-listing-language>
                                      A fallback default language for code listings if no value is provided in the documentation catalogs's Info.plist file.
              --fallback-display-name, --display-name <fallback-display-name>
                                      A fallback display name if no value is provided in the documentation catalogs's Info.plist file.
                    If no display name is provided in the catalogs's Info.plist file or via the '--fallback-display-name' option, DocC will infer a display name from the documentation catalog base name or from the module name
                    from the symbol graph files provided via the '--additional-symbol-graph-dir' option.
              --fallback-bundle-identifier, --bundle-identifier <fallback-bundle-identifier>
                                      A fallback bundle identifier if no value is provided in the documentation catalogs's Info.plist file.
                    If no bundle identifier is provided in the catalogs's Info.plist file or via the '--fallback-bundle-identifier' option, DocC will infer a bundle identifier from the display name.
              --fallback-default-module-kind <fallback-default-module-kind>
                                      A fallback default module kind if no value is provided in the documentation catalogs's Info.plist file.
                    If no module kind is provided in the catalogs's Info.plist file or via the '--fallback-default-module-kind' option, DocC will display the module kind as a "Framework".

            DOCC DOCUMENTATION COVERAGE (EXPERIMENTAL):
              --experimental-documentation-coverage
                                      Generate documentation coverage output.
                    Detailed documentation coverage information will be written to 'documentation-coverage.json' in the output directory.
              --coverage-summary-level <symbol-kind>
                                      The level of documentation coverage information to write on standard out. (default: brief)
                    The '--coverage-summary-level' level has no impact on the information in the 'documentation-coverage.json' file.
                    The supported coverage summary levels are 'brief' and 'detailed'.
              --coverage-symbol-kind-filter <symbol-kind>
                                      Filter documentation coverage to only analyze symbols of the specified symbol kinds.
                    Specify a list of symbol kind values to filter the documentation coverage to only those types symbols.
                    The supported symbol kind values are: associated-type, class, dictionary, enumeration, enumeration-case, function, global-variable, http-request, initializer, instance-method, instance-property,
                    instance-subcript, instance-variable, module, operator, protocol, structure, type-alias, type-method, type-property, type-subscript, typedef

            DOCC LINK RESOLUTION OPTIONS (EXPERIMENTAL):
              --dependency <dependency>
                                      A path to a documentation archive to resolve external links against.
                    Only documentation archives built with '--enable-experimental-external-link-support' are supported as dependencies.

            DOCC FEATURE FLAGS:
              --experimental-enable-custom-templates
                                      Allows for custom templates, like `header.html`.
              --enable-inherited-docs Inherit documentation for inherited symbols
              --allow-arbitrary-catalog-directories
                                      Experimental: allow catalog directories without the `.docc` extension.
              --enable-experimental-external-link-support
                                      Support external links to this documentation output.
                    Write additional link metadata files to the output directory to support resolving documentation links to the documentation in that output directory.
              --emit-digest           Write additional metadata files to the output directory.
              --emit-lmdb-index       Writes an LMDB representation of the navigator index to the output directory.
                    A JSON representation of the navigator index is emitted by default.

            DOCC OPTIONS:
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
              --disable-sandbox       Disable using the sandbox when executing subprocesses.
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
              --verbose               Increase verbosity to include informational output.
            
            SYMBOL GRAPH OPTIONS:
              --experimental-skip-synthesized-symbols
                                      Exclude synthesized symbols from the generated documentation.
                    Experimental feature that produces a DocC archive without compiler synthesized symbols.\(extendedTypesSection)
              --symbol-graph-minimum-access-level
                                      Include symbols with this access level or more. (default: public)
                    Supported access level values are: `open`, `public`, `internal`, `private`, `fileprivate`

            DOCC PREVIEW OPTIONS:
              -p, --port <port-number>
                                      Port number to use for the preview web server. (default: 8080)
              <catalog-path>          Path to a '.docc' documentation catalog directory.
              --additional-symbol-graph-dir <additional-symbol-graph-dir>
                                      A path to a directory of additional symbol graph files.
              -o, --output-path, --output-dir <output-path>
                                      The location where the documentation compiler writes the built documentation.
              --platform <platform>   Specify information about the current release of a platform.
                    Each platform's information is specified via separate "--platform" values using the following format: "name={platform name},version={semantic version}".
                    Optionally, the platform information can include a 'beta={true|false}' component. If no beta information is provided, the platform is considered not in beta.
              --checkout-path <checkout-path>
                                      The root path on disk of the repository's checkout.
              --source-service <source-service>
                                      The source code service used to host the project's sources.
                    Required when using '--source-service-base-url'. Supported values are 'github', 'gitlab', and 'bitbucket'.
              --source-service-base-url <source-service-base-url>
                                      The base URL where the source service hosts the project's sources.
                    Required when using '--source-service'. For example, 'https://github.com/my-org/my-repo/blob/main'.
              --hosting-base-path <hosting-base-path>
                                      The base path your documentation website will be hosted at.
                    For example, if you deploy your site to 'example.com/my_name/my_project/documentation' instead of 'example.com/documentation', pass '/my_name/my_project' as the base path.
              --transform-for-static-hosting/--no-transform-for-static-hosting
                                      Produce a DocC archive that supports static hosting environments. (default: --transform-for-static-hosting)
              --analyze               Include 'note'/'information' level diagnostics in addition to warnings and errors.
              --diagnostics-file, --diagnostics-output-path <diagnostics-file>
                                      The location where the documentation compiler writes the diagnostics file.
                    Specifying a diagnostic file path implies '--ide-console-output'.
              --diagnostic-filter, --diagnostic-level <diagnostic-filter>
                                      Filter diagnostics with a lower severity than this level.
                    This option is ignored if `--analyze` is passed.

                    This filter level is inclusive. If a level of 'note' is specified, diagnostics with a severity up to and including 'note' will be printed.
                    The supported diagnostic filter levels are:
                     - error
                     - warning
                     - note, info, information
                     - hint, notice
              --ide-console-output, --emit-fixits
                                      Format output to the console intended for an IDE or other tool to parse.
              --warnings-as-errors    Treat warnings as errors
              --default-code-listing-language <default-code-listing-language>
                                      A fallback default language for code listings if no value is provided in the documentation catalogs's Info.plist file.
              --fallback-display-name, --display-name <fallback-display-name>
                                      A fallback display name if no value is provided in the documentation catalogs's Info.plist file.
                    If no display name is provided in the catalogs's Info.plist file or via the '--fallback-display-name' option, DocC will infer a display name from the documentation catalog base name or from the module name
                    from the symbol graph files provided via the '--additional-symbol-graph-dir' option.
              --fallback-bundle-identifier, --bundle-identifier <fallback-bundle-identifier>
                                      A fallback bundle identifier if no value is provided in the documentation catalogs's Info.plist file.
                    If no bundle identifier is provided in the catalogs's Info.plist file or via the '--fallback-bundle-identifier' option, DocC will infer a bundle identifier from the display name.
              --fallback-default-module-kind <fallback-default-module-kind>
                                      A fallback default module kind if no value is provided in the documentation catalogs's Info.plist file.
                    If no module kind is provided in the catalogs's Info.plist file or via the '--fallback-default-module-kind' option, DocC will display the module kind as a "Framework".
              --experimental-documentation-coverage
                                      Generate documentation coverage output.
                    Detailed documentation coverage information will be written to 'documentation-coverage.json' in the output directory.
              --coverage-summary-level <symbol-kind>
                                      The level of documentation coverage information to write on standard out. (default: brief)
                    The '--coverage-summary-level' level has no impact on the information in the 'documentation-coverage.json' file.
                    The supported coverage summary levels are 'brief' and 'detailed'.
              --coverage-symbol-kind-filter <symbol-kind>
                                      Filter documentation coverage to only analyze symbols of the specified symbol kinds.
                    Specify a list of symbol kind values to filter the documentation coverage to only those types symbols.
                    The supported symbol kind values are: associated-type, class, dictionary, enumeration, enumeration-case, function, global-variable, http-request, initializer, instance-method, instance-property,
                    instance-subcript, instance-variable, module, operator, protocol, structure, type-alias, type-method, type-property, type-subscript, typedef
              --dependency <dependency>
                                      A path to a documentation archive to resolve external links against.
                    Only documentation archives built with '--enable-experimental-external-link-support' are supported as dependencies.
              --experimental-enable-custom-templates
                                      Allows for custom templates, like `header.html`.
              --enable-inherited-docs Inherit documentation for inherited symbols
              --allow-arbitrary-catalog-directories
                                      Experimental: allow catalog directories without the `.docc` extension.
              --enable-experimental-external-link-support
                                      Support external links to this documentation output.
                    Write additional link metadata files to the output directory to support resolving documentation links to the documentation in that output directory.
              --emit-digest           Write additional metadata files to the output directory.
              --emit-lmdb-index       Writes an LMDB representation of the navigator index to the output directory.
                    A JSON representation of the navigator index is emitted by default.

            DOCC OPTIONS:
              -h, --help              Show help information.
            
            """
        )
    }
}

#if swift(>=5.8)
private let extendedTypesSection = """

  --include-extended-types / --exclude-extended-types
                          Control whether extended types from other modules are shown in the produced DocC archive. (default: \(extendedTypesDefault))
        Allows documenting symbols that a target adds to its dependencies.
"""
#else
private let extendedTypesSection = ""
#endif

#if swift(>=5.9)
private let extendedTypesDefault = "--include-extended-types"
#else
private let extendedTypesDefault = "--exclude-extended-types"
#endif
