// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors


import Foundation

/// A type that runs tasks for each target in a build graph in dependency order.
struct DocumentationBuildGraphRunner<Target: DocumentationBuildGraphTarget> {
    
    let buildGraph: DocumentationBuildGraph<Target>
    
    typealias Work<Result> = (DocumentationBuildGraph<Target>.Task) throws -> Result
    
    func perform<Result>(_ work: @escaping Work<Result>) throws -> [Result] {
        // Create a serial queue to perform each documentation build task
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        // Operations can't raise errors. Instead we catch the error from 'performBuildTask(_:)'
        // and cancel the remaining tasks.
        let resultLock = NSLock()
        var caughtError: Error?
        var results: [Result] = []
        
        let operations = buildGraph.makeOperations { [work] task in
            do {
                let result = try work(task)
                resultLock.withLock {
                    results.append(result)
                }
            } catch {
                resultLock.withLock {
                    caughtError = error
                    queue.cancelAllOperations()
                }
            }
        }
        
        // Run all the documentation build tasks in dependency order (dependencies before dependents).
        queue.addOperations(operations, waitUntilFinished: true)
        
        // If any of the build tasks raised an error. Re-throw that error.
        if let caughtError {
            throw caughtError
        }
        
        return results
    }
}
