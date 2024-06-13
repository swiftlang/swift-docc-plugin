// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
@testable import SwiftDocCPluginUtilities
import XCTest

final class DocumentationBuildGraphTests: XCTestCase {
    func testSingleTask() {
        let target = TestTarget(id: "A")
        XCTAssertEqual(taskOrder(for: [target]), ["A"])
    }
    
    func testChainOfTasksRunInReverseOrder() {
        // A ──▶ B ──▶ C
        let a = TestTarget(id: "A", dependingOn: ["B"])
        let b = TestTarget(id: "B", dependingOn: ["C"])
        let c = TestTarget(id: "C")
        XCTAssertEqual(taskOrder(for: [a,b,c]), ["C", "B", "A"])
    }
    
    func testRepeatedDependencyOnlyRunsOnce() {
        // ┌───┬───┬───┐
        // │   ▼   ▼   ▼
        // A   B   C──▶D
        //     │   ▲   ▲
        //     └───┴───┘
        let a = TestTarget(id: "A", dependingOn: ["B", "C", "D"])
        let b = TestTarget(id: "B", dependingOn: ["C", "D"])
        let c = TestTarget(id: "C", dependingOn: ["D"])
        let d = TestTarget(id: "D")
        XCTAssertEqual(taskOrder(for: [a,b,c,d]), ["D", "C", "B", "A"])
    }
    
    // MARK: Test helper
    
    func taskOrder(for targets: [TestTarget]) -> [String] {
        let buildGraph = DocumentationBuildGraph(targets: targets)
        var processedTargets: [String] = []

        let operations = buildGraph.makeOperations(performing: { task in
            processedTargets.append(task.target.id)
        })
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.addOperations(operations, waitUntilFinished: true)
        
        return processedTargets
    }
}

struct TestTarget: DocumentationBuildGraphTarget {
    let id: ID
    var dependencyIDs: [ID]
    
    init(id: ID, dependingOn dependencyIDs: [ID] = []) {
        self.id = id
        self.dependencyIDs = dependencyIDs
    }
}
