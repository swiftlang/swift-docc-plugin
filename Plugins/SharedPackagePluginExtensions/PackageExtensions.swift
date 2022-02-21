// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors

import Foundation
import PackagePlugin

extension Package {
    /// Any targets defined in this package and its dependencies.
    var allTargets: [Target] {
        var insertedTargetIds = Set<Target.ID>()
        var relevantTargets = [Target]()
        
        func addTargets(_ targets: [Target]) {
            for target in targets {
                guard !insertedTargetIds.contains(target.id) else {
                    continue
                }
                
                relevantTargets.append(target)
                insertedTargetIds.insert(target.id)
            }
        }
        
        func addTargetDependencies(_ target: Target) {
            for dependency in target.dependencies {
                switch dependency {
                case .product(let product):
                    addTargets(product.targets)
                case .target(let target):
                    addTargets([target])
                #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
                @unknown default:
                    return
                #endif
                }
            }
        }
        
        // Begin by adding the targets defined in the products
        // vended by this package as these are the most likely to be documented.
        for product in products {
            addTargets(product.targets)
        }
        
        // Then add the remaining targets defined in this package
        addTargets(targets)
        
        // Make a copy of al the targets directly defined in this package
        let topLevelTargets = relevantTargets
        
        // Iterate through them and add their dependencies. This ensures
        // that we always list targets defined in the package before
        // any we depend on from other packages.
        for topLevelTarget in topLevelTargets {
            addTargetDependencies(topLevelTarget)
        }
        
        return relevantTargets
    }
    
    /// Any regular products defined in this package and its dependencies.
    var allProducts: [Product] {
        return products + dependencies.flatMap(\.package.products)
    }
    
    /// All targets defined in this package and its dependencies that
    /// can produce documentation.
    var allDocumentableTargets: [SwiftSourceModuleTarget] {
        return allTargets.documentableTargets
    }
    
    /// All products defined in this package and its dependencies that
    /// can produce documentation.
    var allDocumentableProducts: [Product] {
        return allProducts.filter { product in
            !product.targets.documentableTargets.isEmpty
        }
    }
    
    /// All targets defined directly in this package that produce documentation.
    ///
    /// Excludes targets defined in dependencies.
    var topLevelDocumentableTargets: [SwiftSourceModuleTarget] {
        var insertedTargetIds = Set<Target.ID>()
        var topLevelTargets = [Target]()
        
        func addTargets(_ targets: [Target]) {
            for target in targets {
                guard !insertedTargetIds.contains(target.id) else {
                    continue
                }
                
                topLevelTargets.append(target)
                insertedTargetIds.insert(target.id)
            }
        }
        
        for product in products {
            addTargets(product.targets)
        }
        
        addTargets(targets)
        
        return topLevelTargets.documentableTargets
    }
    
    /// A list of targets that are compatible with this plugin, suitable for presentation.
    var compatibleTargets: String {
        guard !allDocumentableTargets.isEmpty else {
            return "none"
        }
        
        return allDocumentableTargets.map(\.name.singleQuoted).joined(separator: ", ")
    }
    
    /// A list of products that are compatible with this plugin, suitable for presentation.
    var compatibleProducts: String {
        guard !allDocumentableProducts.isEmpty else {
            return "none"
        }
        
        return allDocumentableProducts.map(\.name.singleQuoted).joined(separator: ", ")
    }
}

private extension Collection where Element == Target {
    var documentableTargets: [SwiftSourceModuleTarget] {
        return compactMap { target in
            guard let swiftSourceModuleTarget = target as? SwiftSourceModuleTarget else {
                return nil
            }
            
            guard swiftSourceModuleTarget.kind != .test else {
                return nil
            }
            
            return swiftSourceModuleTarget
        }
    }
}
