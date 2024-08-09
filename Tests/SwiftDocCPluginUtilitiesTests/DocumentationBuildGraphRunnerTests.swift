
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

final class DocumentationBuildGraphRunnerTests: XCTestCase {
    
    func testSingleTask() {
        let a = TestTarget(id: "A")
        let runner = DocumentationBuildGraphRunner(buildGraph: .init(targets: [a]))
        
        // All tasks succeeding
        assertExpectedResult(
            performing: {
                $0.target.id.lowercased()
            },
            with: runner,
            expectedTaskStatus: [
                .init(id: "A", status: .finished),
            ],
            expectedResult: ["a"]
        )
        
        // All tasks failing
        assertExpectedError(
            performing: { task -> Int in
                throw TestError(task: task)
            },
            with: runner,
            expectedTaskStatus: [
                .init(id: "A", status: .started),
            ],
            expectedError: TestError("Failure from A")
        )
    }
    func testChainOfTasksRunInReverseOrder() {
        // A ──▶ B ──▶ C
        let a = TestTarget(id: "A", dependingOn: ["B"])
        let b = TestTarget(id: "B", dependingOn: ["C"])
        let c = TestTarget(id: "C")
        
        let runner = DocumentationBuildGraphRunner(buildGraph: .init(targets: [a,b,c]))
        
        // All tasks succeeding
        assertExpectedResult(
            performing: {
                $0.target.id.lowercased()
            },
            with: runner,
            expectedTaskStatus: [
                .init(id: "C", status: .finished),
                .init(id: "B", status: .finished),
                .init(id: "A", status: .finished),
            ],
            expectedResult: ["c", "b", "a"]
        )
        
        // All tasks failing
        assertExpectedError(
            performing: { task -> Int in
                throw TestError(task: task)
            },
            with: runner,
            expectedTaskStatus: [
                .init(id: "C", status: .started),
            ],
            expectedError: TestError("Failure from C")
        )
        
        // Last tasks failing
        assertExpectedError(
            performing: {
                if $0.target.id == "A" {
                    throw TestError(task: $0)
                } else {
                    return $0.target.id.lowercased()
                }
            },
            with: runner,
            expectedTaskStatus: [
                .init(id: "C", status: .finished),
                .init(id: "B", status: .finished),
                .init(id: "A", status: .started),
            ],
            expectedError: TestError("Failure from A")
        )
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
        
        let runner = DocumentationBuildGraphRunner(buildGraph: .init(targets: [a,b,c,d]))
        
        // All tasks succeeding
        assertExpectedResult(
            performing: {
                $0.target.id.lowercased()
            },
            with: runner,
            expectedTaskStatus: [
                .init(id: "D", status: .finished),
                .init(id: "C", status: .finished),
                .init(id: "B", status: .finished),
                .init(id: "A", status: .finished),
            ],
            expectedResult: ["d", "c", "b", "a"]
        )
        
        // All tasks failing
        assertExpectedError(
            performing: { task -> Int in
                throw TestError(task: task)
            },
            with: runner,
            expectedTaskStatus: [
                .init(id: "D", status: .started),
            ],
            expectedError: TestError("Failure from D")
        )
        
        // Last tasks failing
        assertExpectedError(
            performing: {
                if $0.target.id == "A" {
                    throw TestError(task: $0)
                } else {
                    return $0.target.id.lowercased()
                }
            },
            with: runner,
            expectedTaskStatus: [
                .init(id: "D", status: .finished),
                .init(id: "C", status: .finished),
                .init(id: "B", status: .finished),
                .init(id: "A", status: .started),
            ],
            expectedError: TestError("Failure from A")
        )
    }
    
    // MARK: Test helpers
    
    private func assertExpectedResult<TaskResult: Equatable, Target>(
        performing work: @escaping DocumentationBuildGraphRunner<Target>.Work<TaskResult>,
        with runner: DocumentationBuildGraphRunner<Target>,
        expectedTaskStatus: [TaskStatus],
        expectedResult: [TaskResult],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let (taskOrder, result) = runner.processedTargetsAndResult(performing: work)
        XCTAssertEqual(taskOrder.map(\.id), expectedTaskStatus.map(\.id), "Unexpected task order", file: file, line: line)
        for (got, expected) in zip(taskOrder, expectedTaskStatus) {
            XCTAssertEqual(got.status, expected.status, "Unexpected task status for \(got.id)", file: file, line: line)
        }
        switch result {
        case .success(let success):
            XCTAssertEqual(success, expectedResult, file: file, line: line)
        case .failure(let failure):
            XCTFail("Unexpected failure \(failure)", file: file, line: line)
        }
    }
    
    private func assertExpectedError<TaskResult: Equatable, Target, ExpectedError: Error & Equatable>(
        performing work: @escaping DocumentationBuildGraphRunner<Target>.Work<TaskResult>,
        with runner: DocumentationBuildGraphRunner<Target>,
        expectedTaskStatus: [TaskStatus],
        expectedError: ExpectedError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let (taskOrder, result) = runner.processedTargetsAndResult(performing: work)
        XCTAssertEqual(taskOrder.map(\.id), expectedTaskStatus.map(\.id), "Unexpected task order", file: file, line: line)
        for (got, expected) in zip(taskOrder, expectedTaskStatus) {
            
            XCTAssertEqual(got.status, expected.status, "Unexpected task status for \(got.id)", file: file, line: line)
        }
        switch result {
        case .success(let success):
            XCTFail("Unexpected success \(success)", file: file, line: line)
        case .failure(let failure):
            XCTAssertEqual(failure as? ExpectedError, expectedError)
        }
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

private struct TestError: Error, Equatable {
    var message: String
    init(_ message: String) {
        self.message = message
    }
    init(task: DocumentationBuildGraph<TestTarget>.Task) {
        self.message = "Failure from \(task.target.id)"
    }
}

private struct TaskStatus: Equatable {
    var id: DocumentationBuildGraphTarget.ID
    var status: Status
    enum Status: Equatable {
        case started, finished
    }
}

private extension DocumentationBuildGraphRunner {
    /// A test helper that runs tasks for a build graph and separately aggregates the status of each task.
    func processedTargetsAndResult<TaskResult>(
        performing work: @escaping Work<TaskResult>
    ) -> (processedTargets: [TaskStatus], result: Result<[TaskResult], any Error>) {
        var processedTargets: [TaskStatus] = []
        let lock = NSLock()
        
        let result = Swift.Result(catching: {
            try self.perform { task in
                lock.withLock {
                    processedTargets.append(.init(id: task.target.id, status: .started))
                }
                
                let result = try work(task)
                
                lock.withLock {
                    let index = processedTargets.firstIndex(of: .init(id: task.target.id, status: .started))!
                    processedTargets[index] = .init(id: task.target.id, status: .finished)
                }
                
                return result
            }
        })
        return (processedTargets, result)
    }
}
