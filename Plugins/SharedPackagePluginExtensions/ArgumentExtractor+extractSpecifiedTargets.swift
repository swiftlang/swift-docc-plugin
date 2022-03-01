// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
import PackagePlugin

enum ArgumentParsingError: LocalizedError, CustomStringConvertible {
    case unknownProduct(_ productName: String, compatibleProducts: String)
    case unknownTarget(_ targetName: String, compatibleTargets: String)
    case productDoesNotContainSwiftSourceModuleTargets(String)
    case packageDoesNotContainSwiftSourceModuleTargets
    case targetIsNotSwiftSourceModule(String)
    case testTarget(String)
    
    var description: String {
        switch self {
        case .unknownProduct(let productName, let compatibleProducts):
            return """
                no product named '\(productName)'
                
                compatible products: \(compatibleProducts)
                """
        case .unknownTarget(let targetName, let compatibleTargets):
            return """
                no target named '\(targetName)'
                
                compatible targets: \(compatibleTargets)
                """
        case .productDoesNotContainSwiftSourceModuleTargets(let string):
            return "product '\(string)' does not contain any Swift source modules"
        case .targetIsNotSwiftSourceModule(let string):
            return "target '\(string)' is not a Swift source module"
        case .testTarget(let string):
            return "target '\(string)' is a test target; only library and executable targets are supported by Swift-DocC"
        case .packageDoesNotContainSwiftSourceModuleTargets:
            return "the current package does not contain any compatible Swift source modules"
        }
    }
    
    var errorDescription: String? {
        return description
    }
}

extension ArgumentExtractor {
    mutating func extractSpecifiedTargets(in package: Package) throws -> [SwiftSourceModuleTarget] {
        let specifiedProducts = extractOption(named: "product")
        let specifiedTargets = extractOption(named: "target")
        
        let productTargets = try specifiedProducts.flatMap { specifiedProduct -> [SwiftSourceModuleTarget] in
            let product = package.allProducts.first { product in
                product.name == specifiedProduct
            }
            
            guard let product = product else {
                throw ArgumentParsingError.unknownProduct(
                    specifiedProduct,
                    compatibleProducts: package.compatibleProducts
                )
            }
            
            let supportedSwiftSourceModuleTargets = product.targets.compactMap { target in
                target as? SwiftSourceModuleTarget
            }
            .filter { swiftSourceModuleTarget in
                return swiftSourceModuleTarget.kind != .test
            }
            
            guard !supportedSwiftSourceModuleTargets.isEmpty else {
                throw ArgumentParsingError.productDoesNotContainSwiftSourceModuleTargets(specifiedProduct)
            }
            
            return supportedSwiftSourceModuleTargets
        }
        
        let targets = try specifiedTargets.map { specifiedTarget -> SwiftSourceModuleTarget in
            let target = package.allTargets.first { target in
                target.name == specifiedTarget
            }
            
            guard let target = target else {
                throw ArgumentParsingError.unknownTarget(
                    specifiedTarget,
                    compatibleTargets: package.compatibleTargets
                )
            }
            
            guard let swiftSourceModuleTarget = target as? SwiftSourceModuleTarget else {
                throw ArgumentParsingError.targetIsNotSwiftSourceModule(specifiedTarget)
            }
            
            guard swiftSourceModuleTarget.kind != .test else {
                throw ArgumentParsingError.testTarget(specifiedTarget)
            }
            
            return swiftSourceModuleTarget
        }
        
        return productTargets + targets
    }
}
