// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
import SwiftDocCPluginUtilities
import XCTest

final class CommandLineArgumentsTests: XCTestCase {
    typealias Flag   = CommandLineArgument.Flag
    typealias Option = CommandLineArgument.Option
    
    func testExtractingRawFlagsAndOptions() {
        var arguments = CommandLineArguments(["--some-flag", "--this-option", "this-value", "--another-option", "another-value", "--", "--some-literal-value"])
        
        XCTAssertEqual(arguments.extractFlag(rawName: "--some-flag"), [true])
        XCTAssertEqual(arguments.remainingArguments, ["--this-option", "this-value", "--another-option", "another-value", "--", "--some-literal-value"])
        
        XCTAssertEqual(arguments.extractFlag(rawName: "--some--literal-value"), [], "Shouldn't extract the literal/positional value")
        XCTAssertEqual(arguments.remainingArguments, ["--this-option", "this-value", "--another-option", "another-value", "--", "--some-literal-value"])
        
        XCTAssertEqual(arguments.extractOption(rawName: "--another-option"), ["another-value"])
        XCTAssertEqual(arguments.remainingArguments, ["--this-option", "this-value", "--", "--some-literal-value"])
        
        XCTAssertEqual(arguments.extractOption(rawName: "--not-found"), [])
        XCTAssertEqual(arguments.remainingArguments, ["--this-option", "this-value", "--", "--some-literal-value"])
        
        XCTAssertEqual(arguments.extractOption(rawName: "--this-option"), ["this-value"])
        XCTAssertEqual(arguments.remainingArguments, ["--", "--some-literal-value"])
    }
    
    func testInsertFlagsAndOptions() {
        var arguments = CommandLineArguments(["--some-flag", "--this-option", "this-value", "--", "--some-literal-value"])
        
        // Insert
        
        XCTAssertTrue(arguments.insertIfMissing(Flag(preferred: "--some-flag")), "Already contains '--some-flag'")
        XCTAssertEqual(arguments.remainingArguments, ["--some-flag", "--this-option", "this-value", "--", "--some-literal-value"])
        
        XCTAssertFalse(arguments.insertIfMissing(Flag(preferred: "--other-flag")), "Didn't previously contain '--other-flag'")
        XCTAssertEqual(arguments.remainingArguments, ["--some-flag", "--this-option", "this-value", "--other-flag", "--", "--some-literal-value"])
        
        XCTAssertTrue(arguments.insertIfMissing(Option(preferred: "--this-option"), value: "new-value"), "Already contains '--this-option'")
        XCTAssertEqual(arguments.remainingArguments, ["--some-flag", "--this-option", "this-value", "--other-flag", "--", "--some-literal-value"])
        
        XCTAssertFalse(arguments.insertIfMissing(Option(preferred: "--another-option"), value: "another-value"), "Didn't previously contain '--another-option'")
        XCTAssertEqual(arguments.remainingArguments, ["--some-flag", "--this-option", "this-value", "--other-flag", "--another-option", "another-value", "--", "--some-literal-value"])
        
        // Override
        
        XCTAssertTrue(arguments.overrideOrInsert(.init(preferred: "--this-option"), newValue: "new-value"), "Already contains '--this-option'")
        XCTAssertEqual(arguments.remainingArguments, ["--some-flag", "--other-flag", "--another-option", "another-value", "--this-option", "new-value", "--", "--some-literal-value"])
        
        XCTAssertFalse(arguments.overrideOrInsert(.init(preferred: "--yet-another-option"), newValue: "another-new-value"), "Didn't previously contain '--yet-another-option'")
        XCTAssertEqual(arguments.remainingArguments, ["--some-flag", "--other-flag", "--another-option", "another-value", "--this-option", "new-value", "--yet-another-option", "another-new-value", "--", "--some-literal-value"])
    }
    
    func testInsertSameSingleValueOptionWithDifferentValues() {
        let optionName = "--some-option"
        let optionNameAlternate = "--some-option-alternate"
        let option = CommandLineArgument.Option(
            preferred: optionName,
            alternatives: [optionNameAlternate],
            kind: .singleValue // the default
        )
        
        for initialArguments in [
            ["\(optionName)=first"],
            [optionNameAlternate, "second"],
        ] {
            var arguments = CommandLineArguments(initialArguments)
            
            XCTAssertTrue(arguments.insertIfMissing(option, value: "first"), "The arguments already contains some other value for this option")
            XCTAssertEqual(arguments.remainingArguments, initialArguments)
            
            XCTAssertTrue(arguments.insertIfMissing(option, value: "second"), "The arguments already contains some other value for this option")
            XCTAssertEqual(arguments.remainingArguments, initialArguments)
            
            XCTAssertTrue(arguments.insertIfMissing(option, value: "third"), "The arguments already contains some other value for this option")
            XCTAssertEqual(arguments.remainingArguments, initialArguments)
        }
    }
    
    func testInsertSameArrayOfValuesOptionWithDifferentValues() {
        let optionName = "--some-option"
        let optionNameAlternate = "--some-option-alternate"
        let option = CommandLineArgument.Option(
            preferred: optionName,
            alternatives: [optionNameAlternate],
            kind: .arrayOfValues
        )
        
        var arguments = CommandLineArguments([
            "\(optionName)=first",
            optionNameAlternate, "second",
        ])
        
        XCTAssertTrue(arguments.insertIfMissing(option, value: "first"), "The arguments already contains this value (using the preferred option spelling)")
        XCTAssertEqual(arguments.remainingArguments, [
            "\(optionName)=first",
            optionNameAlternate, "second",
        ])
        
        XCTAssertTrue(arguments.insertIfMissing(option, value: "second"), "The arguments already contains this value (using the alternate option spelling)")
        XCTAssertEqual(arguments.remainingArguments, [
            "\(optionName)=first",
            optionNameAlternate, "second",
        ])
        
        XCTAssertFalse(arguments.insertIfMissing(option, value: "third"), "This value is new (doesn't exist among the arguments yet)")
        XCTAssertEqual(arguments.remainingArguments, [
            "\(optionName)=first",
            optionNameAlternate, "second",
            optionName, "third",
        ])
        
        XCTAssertFalse(arguments.insertIfMissing(option, value: "fourth"), "Third value us also new ... (doesn't exist among the arguments yet)")
        XCTAssertEqual(arguments.remainingArguments, [
            "\(optionName)=first",
            optionNameAlternate, "second",
            optionName, "third",
            optionName, "fourth",
        ])
        
        XCTAssertTrue(arguments.insertIfMissing(option, value: "fourth"), "... but now it exists (after inserting it above)")
        XCTAssertEqual(arguments.remainingArguments, [
            "\(optionName)=first",
            optionNameAlternate, "second",
            optionName, "third",
            optionName, "fourth",
        ])
    }
    
    func testExtractDifferentArgumentSpellings() {
        // Options
        do {
            var arguments = CommandLineArguments(["--spelling-one", "value-one", "--spelling-two=value-two", "-s", "value-three", "-s=value-four", "--spelling-one", "value-five", "--", "--spelling-one", "value-six"])
            
            let extractedValues = arguments.extract(
                CommandLineArgument.Option(preferred: "--spelling-one", alternatives: ["--spelling-two", "-s"])
            )
            XCTAssertEqual(extractedValues, ["value-one", "value-two", "value-three", "value-four", "value-five"])
            XCTAssertEqual(arguments.remainingArguments, ["--", "--spelling-one", "value-six"])
        }
        
        // Flags
        do {
            var arguments = CommandLineArguments(["--spelling-one", "--spelling-two", "-s", "--spelling-one", "--", "--spelling-one"])
            
            let extractedValues = arguments.extractFlag(named:
                .init(preferred: "--spelling-one", alternatives: ["--spelling-two", "-s"])
            )
            XCTAssertEqual(extractedValues, [true, true, true, true])
            XCTAssertEqual(arguments.remainingArguments, ["--", "--spelling-one"])
        }
        
        // Flags with inverse names
        do {
            var arguments = CommandLineArguments(["--spelling-one", "--spelling-two", "--negative-spelling-one", "--negative-spelling-two", "-s", "--spelling-one", "-ns", "--", "--spelling-one", "--negative-spelling-two"])
            
            let extractedValues = arguments.extractFlag(
                named:        .init(preferred: "--spelling-one", alternatives: ["--spelling-two", "-s"]),
                inverseNames: .init(preferred: "--negative-spelling-one", alternatives: ["--negative-spelling-two", "-ns"])
            )
            XCTAssertEqual(extractedValues, [true, true, false, false, true, true, false])
            XCTAssertEqual(arguments.remainingArguments, ["--", "--spelling-one", "--negative-spelling-two"])
        }
    }
    
    func testInsertDifferentArgumentSpellings() {
        // Options
        for existing in [ ["--spelling-one", "existing-value"], ["--spelling-two=existing-value"], ["-s", "existing-value"] ] {
            var arguments = CommandLineArguments(existing + ["--other-flag"])
            let original = arguments.remainingArguments
            
            let option = CommandLineArgument.Option(preferred: "--spelling-one", alternatives: ["--spelling-two", "-s"])
            XCTAssertTrue(arguments.insertIfMissing(option, value: "new-value"))
            XCTAssertEqual(arguments.remainingArguments, original)
            
            XCTAssertTrue(arguments.overrideOrInsert(option, newValue: "new-value"))
            XCTAssertEqual(arguments.remainingArguments, ["--other-flag", "--spelling-one", "new-value"])
        }
        
        // Flags
        for existing in ["--spelling-one", "--spelling-two",  "-s"] {
            var arguments = CommandLineArguments([existing, "--other-flag"])
            let original = arguments.remainingArguments
            
            XCTAssertTrue(arguments.insertIfMissing(Flag(preferred: "--spelling-one", alternatives: ["--spelling-two", "-s"])))
            XCTAssertEqual(arguments.remainingArguments, original)
        }
    }
}

private extension CommandLineArguments {
    // MARK: Extract raw
    
    mutating func extractOption(rawName: String) -> [String] {
        extract(CommandLineArgument.Option(preferred: rawName))
    }

    mutating func extractFlag(rawName: String) -> [Bool] {
        extractFlag(named: .init(preferred: rawName))
    }
}
