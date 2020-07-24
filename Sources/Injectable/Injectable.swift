/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

/// Defines an injectable entity for which resolution will never throw or return `nil`.
/// The dependency will always be able to be resolved.
///
/// See `BaseInjectable` for more information.
public protocol Injectable: BaseInjectable {
    static func makeInjectedInstance(_ params: InjectionParameters) -> InjectedService
}

public extension Injectable {
    /// Resolves the injected dependency with the current resolution implementation
    /// provided by `DependencyFactory<Self>`.
    ///
    /// - Parameter params: The `InjectionParameters` that should be used to resolve the dependency.
    /// - Returns: The resolved dependency
    static func resolve(_ params: InjectionParameters) -> InjectedService {
        InjectableFactory<Self>.shared.make(with: params)
    }

    /// Typealias on `Injectable` for easy declaration of `Injector`s.
    ///
    /// # Example:
    /// ```
    /// struct Foo: Bar, Injectable {
    ///   let name: String
    ///
    ///   static func makeInjectedInstance(_ name: String) -> Bar {
    ///     return Foo(name: name)
    ///   }
    /// }
    ///
    /// Foo.InjectorType // Injector<Bar, String>
    /// ```
    typealias InjectorType = Injector<InjectedService, InjectionParameters>
}

extension Injectable where InjectionParameters == Void {

    /// Resolves the injected dependency with the current resolution implementation
    /// provided by `DependencyFactory<Self>`.
    ///
    /// - Returns: The resolved dependency
    public static func resolve() -> InjectedService {
        resolve(())
    }
}
