/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

import Foundation

/// An abstract base class for a factory used internally for storing the resolver functions
/// used to resolve an `Injectable` dependency.
///
/// - Note: This class should not be initialized directly. Concrete subclasses must implement the functionality to
/// store dependency resolution methods.
class AbstractDependencyFactory<T: BaseInjectable> {

    /// Lazily loads the `DependencyFactory` for a given `Injectable` dependency.
    static var shared: Self<T> {
        guard let factory =
            AnyDependencyFactory.factories.first(where: { $0.instance is Self })?.instance
                as? Self else {
                    let factory = Self()
                    AnyDependencyFactory.factories.append(AnyDependencyFactory(factory))
                    return factory
        }
        return factory
    }

    required init() {}

    /// Resets the factory's resolution function to the default resolver for the `Injectable`
    static func reset() {
        shared.reset()
    }

    // MARK: Abstract Functions

    /// Resets the factory's resolution function to the default resolver for the `Injectable`
    ///
    /// - Note: This must be implemented by subclasses
    @available(*, message: "Abstract function implementation must be overridden by subclass")
    func reset() {}

}

// MARK: -
/// A type-erased wrapper for a `DependencyFactory`. Used to store all created `AbstractDependencyFactory` instances.
final class AnyDependencyFactory {

    fileprivate static var factories: [AnyDependencyFactory] = []

    static func reset() {
        factories = []
    }

    let instance: Any

    init<T: BaseInjectable>(_ instance: AbstractDependencyFactory<T>) {
        self.instance = instance
    }

}

// MARK: -
final class InjectableFactory<T: Injectable>: AbstractDependencyFactory<T> {

    typealias Resolver = (T.InjectionParameters) -> T.InjectedService

    required init() {
        resolver = defaultResolver
    }

    // MARK: DI Closures

    private let defaultResolver: Resolver = { T.makeInjectedInstance($0) }

    /// The resolver function used to resolve the `Injectable` dependency.
    /// This property is internal, but can be overridden in unit tests to inject mock objects by
    /// importing with the `@testable` directive.
    var resolver: Resolver

    // MARK: Factory Methods

    func make(with params: T.InjectionParameters) -> T.InjectedService {
        return resolver(params)
    }

    override func reset() {
        resolver = defaultResolver
    }

}

// MARK: -
final class ThrowingInjectableFactory<T: ThrowingInjectable>: AbstractDependencyFactory<T> {

    typealias Resolver = (T.InjectionParameters) throws -> T.InjectedService

    required init() {
        resolver = defaultResolver
    }

    // MARK: DI Closures

    private let defaultResolver: Resolver = { try T.makeInjectedInstance($0) }

    /// The resolver function used to resolve the `Injectable` dependency.
    /// This property is internal, but can be overridden in unit tests to inject mock objects by
    /// importing with the `@testable` directive.
    var resolver: Resolver

    // MARK: Factory Methods

    override func reset() {
        resolver = defaultResolver
    }

}

extension ThrowingInjectableFactory {
    func make(with params: T.InjectionParameters) throws -> T.InjectedService {
        return try resolver(params)
    }
}

extension ThrowingInjectableFactory where T: Injectable {
    func make(with params: T.InjectionParameters) throws -> T.InjectedService {
        return InjectableFactory<T>.shared.make(with: params)
    }
}
