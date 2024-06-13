// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation

/// A target that can have a documentation task in the build graph
protocol DocumentationBuildGraphTarget {
    typealias ID = String
    /// The unique identifier of this target
    var id: ID { get }
    /// The unique identifiers of this target's direct dependencies (non-transitive).
    var dependencyIDs: [ID] { get }
}

/// A build graph of documentation tasks.
struct DocumentationBuildGraph<Target: DocumentationBuildGraphTarget> {
    fileprivate typealias ID = Target.ID
    /// All the documentation tasks
    let tasks: [Task]
    
    /// Creates a new documentation build graph for a series of targets with dependencies.
    init(targets: some Sequence<Target>) {
        // Create tasks
        let taskLookup: [ID: Task] = targets.reduce(into: [:]) { acc, target in
            acc[target.id] = Task(target: target)
        }
        // Add dependency information to each task
        for task in taskLookup.values {
            task.dependencies = task.target.dependencyIDs.compactMap { taskLookup[$0] }
        }
        
        tasks = Array(taskLookup.values)
    }
    
    /// Creates a list of dependent operations to perform the given work for each task in the build graph.
    ///
    /// You can add these operations to an `OperationQueue` to perform them in reverse dependency order
    /// (dependencies before dependents). The queue can run these operations concurrently.
    ///
    /// - Parameter work: The work to perform for each task in the build graph.
    /// - Returns: A list of dependent operations that performs `work` for each documentation task task.
    func makeOperations(performing work: @escaping (Task) -> Void) -> [Operation] {
        var builder = OperationBuilder(work: work)
        for task in tasks {
            builder.buildOperationHierarchy(for: task)
        }
        
        return Array(builder.operationsByID.values)
    }
}

extension DocumentationBuildGraph {
    /// A documentation task in the build graph
    final class Task {
        /// The target to build documentation for
        let target: Target
        /// The unique identifier of the task
        fileprivate var id: ID { target.id }
        /// The other documentation tasks that this task depends on.
        fileprivate(set) var dependencies: [Task]
        
        init(target: Target) {
            self.target = target
            self.dependencies = []
        }
    }
}

extension DocumentationBuildGraph {
    /// A type that builds a hierarchy of dependent operations
    private struct OperationBuilder {
        /// The work that each operation should perform
        let work: (Task) -> Void
        /// A lookup of operations by their ID
        private(set) var operationsByID: [ID: Operation] = [:]
        
        /// Adds new dependent operations to the builder.
        ///
        /// You can access the created dependent operations using `operationsByID.values`.
        mutating func buildOperationHierarchy(for task: Task) {
            let operation = makeOperation(for: task)
            for dependency in task.dependencies {
                let dependentOperation = makeOperation(for: dependency)
                operation.addDependency(dependentOperation)
                
                buildOperationHierarchy(for: dependency)
            }
        }
        
        /// Returns the existing operation for the given task or creates a new operation if the builder didn't already have an operation for this task.
        private mutating func makeOperation(for task: Task) -> Operation {
            if let existing = operationsByID[task.id] {
                return existing
            }
            // Copy the closure and the target into a block operation object
            let new = BlockOperation { [work, task] in
                work(task)
            }
            operationsByID[task.id] = new
            return new
        }
    }
}
