/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

/// A dependency injection wrapper that functions as a factory for resolving inverted (abstract) dependencies
/// that may throw an error on-demand.
///
/// See `Injector` for more information.
public class ThrowingInjector<Service, Parameters> {

    private let resolutionClosure: (Parameters) throws -> Service

    /// Initializer for an `Injectable` type using the `Injectable`'s dependency resolution.
    /// The injector with resolve the dependency just as the `Injectable` would itself,
    /// by calling the `injectableType`'s `resolve(_ params:)` function.
    ///
    /// - Parameter injectableType: The `Injectable` type to be injected.
    public init<T: ThrowingInjectable>(_ injectableType: T.Type)
        where T.InjectedService == Service, T.InjectionParameters == Parameters {
            resolutionClosure = injectableType.resolve
    }

    /// Initializer using a closure that will be called to resolve the dependency each time `resolve(_ params:)`
    /// is called on the receiver.
    ///
    /// - Parameter resolutionClosure: The resolution closure used to resolve dependencies with the `Injector`.
    public init(resolutionClosure: @escaping (Parameters) throws -> Service) {
        self.resolutionClosure = resolutionClosure
    }

    /// Resolves the injected dependency with the current resolution implementation
    /// provided by the `DependencyFactory` for the `Injectable` type the `Injector` was initialized with.
    ///
    /// - Parameter params: The `Parameters` that should be used to resolve the dependency.
    /// - Returns: The resolved dependency
    public func resolve(_ params: Parameters) throws -> Service {
        try resolutionClosure(params)
    }
}
