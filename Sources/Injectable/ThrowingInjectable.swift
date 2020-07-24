/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

/// Defines an injectable entity for which resolution may throw an error.
///
/// See `BaseInjectable` for more information.
public protocol ThrowingInjectable: BaseInjectable { }

public extension ThrowingInjectable {

    /// Resolves the injected dependency with the current resolution implementation
    /// provided by `DependencyFactory<Self>`.
    ///
    /// - Parameter params: The `InjectionParameters` that should be used to resolve the dependency.
    /// - Returns: The resolved dependency
    static func resolve(_ params: InjectionParameters) throws -> InjectedService {
        try ThrowingInjectableFactory<Self>.shared.make(with: params)
    }
}

extension ThrowingInjectable where InjectionParameters == Void {

    /// Resolves the injected dependency with the current resolution implementation
    /// provided by `DependencyFactory<Self>`.
    ///
    /// - Returns: The resolved dependency
    public static func resolve() throws -> InjectedService {
        try resolve(())
    }
}

public extension ThrowingInjectable where Self: Injectable {

    /// Resolves the injected dependency with the current resolution implementation
    /// provided by `DependencyFactory<Self>`.
    ///
    /// - Parameter params: The `InjectionParameters` that should be used to resolve the dependency.
    /// - Returns: The resolved dependency
    static func resolve(_ params: InjectionParameters) -> InjectedService {
        InjectableFactory<Self>.shared.make(with: params)
    }
}

public extension ThrowingInjectable where Self: Injectable, InjectionParameters == Void {

    /// Resolves the injected dependency with the current resolution implementation
    /// provided by `DependencyFactory<Self>`.
    ///
    /// - Returns: The resolved dependency
    static func resolve() -> InjectedService {
        resolve(())
    }
}

/// Defines an injectable entity for which resolution may return `nil`.
///
/// This can be used when the `InjectedService` has a failable initializer (ie.: `init?()`).
///
/// See `BaseInjectable` for more information.
public protocol OptionalInjectable: BaseInjectable {
    static func makeInjectedInstance(_ params: InjectionParameters) -> InjectedService?
}
