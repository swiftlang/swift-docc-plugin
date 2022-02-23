// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import NIOCore
import NIOPosix
import XCTest

extension XCTestCase {
    /// Returns a port number that is available on the system at the moment
    /// this function returns.
    ///
    /// This allows tests to more reliably run in parallel and in CI where
    /// we can't be sure which ports will be available.
    func getAvailablePort() throws -> Int {
        // Start up the server.
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let server = ServerBootstrap(group: eventLoopGroup)
        
        // Bind to port '0' on localhost. '0' is a reserved port on the system
        // so binding to it will cause the OS to allocate an available port to the server.
        // Then we can read that allocated port number and return it.
        let channel = try server.bind(host: "localhost", port: 0).wait()
        let port = try XCTUnwrap(channel.localAddress?.port)
        
        // Shut down the server
        try channel.close().wait()
        try eventLoopGroup.syncShutdownGracefully()
        
        return port
    }
}

