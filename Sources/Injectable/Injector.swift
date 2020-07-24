/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

/// A dependency injection wrapper that functions as a factory for resolving inverted (abstract) dependencies on-demand.
/// Use an `Injector` when you need to initialize an abstract dependency without knowing it's concrete type.
///
/// An `Injector` is initialized with an implementation that resolves a concrete instance, but then only exposes the
/// abstract `Service` type to its consumers to enable dependency inversion.
///
/// When a dependency is inverted via a protocol or abstract class, typically, we should inject that dependency manually using
/// an injected initializer parameter or property injection. However, when the dependency resolution should occur at a later time,
/// we can use an `Injector` wrapper.
///
/// Common situations in which this is utilized are when resolving a dependency lazily or when resolution relies on runtime
/// parameters (such as user input) provided by the object that has the dependency. By using `Injector` we are able to
/// resolve the dependency on-demand and utilize dependency inversion. Additionally, beacuse the `Injector` must be
/// injected itself, we maintain a clear, explicit dependency hierarchy.
///
/// # Example:
/// ```
/// protocol A { }
///
/// struct B: A, Injectable {
///   static func makeInjectedInstance(_: Void) -> A {
///     return B()
///   }
/// }
///
/// // Lazy Resolution
/// class C {
///   private let aInjector: Injector<A, Void>
///   private(set) lazy var dependency: A = aInjector.resolve()
///
///   init(dependency: Injector<A, Void>) {
///     self.aInjector = dependency
///   }
/// }
///
/// let c = C(dependency: Injector(B.self))
///
/// // Resolution with Parameters
///
/// struct D: A, Injectable {
///   let name: String
///
///   static func makeInjectedInstance(_ name: String) -> A {
///     return D(name: name)
///   }
/// }
///
/// typealias AInjector = Injector<A, String>
/// class E {
///   private let aInjector: AInjector
///
///   init(dependency: AInjector) {
///     self.aInjector = dependency
///   }
///
///   func dependency(with name: String) -> A {
///     aInjector.resolve(name)
///   }
///
/// }
///
/// let e = E(dependency: Injector(D.self))
///
/// // Resolution via closure (Instead of Injectable Resolution)
///
/// struct F: A {
///   let name: String
/// }
///
/// let eWithClosureInjector = E(dependency: Injector { F(name: $0) })
/// ```
public class Injector<Service, Parameters> {

    private let resolutionClosure: (Parameters) -> Service

    /// Initializer for an `Injectable` type using the `Injectable`'s dependency resolution.
    /// The injector with resolve the dependency just as the `Injectable` would itself,
    /// by calling the `injectableType`'s `resolve(_ params:)` function.
    ///
    /// - Parameter injectableType: The `Injectable` type to be injected.
    public init<T: Injectable>(_ injectableType: T.Type)
        where T.InjectedService == Service, T.InjectionParameters == Parameters {
            resolutionClosure = injectableType.resolve
    }

    /// Initializer using a closure that will be called to resolve the dependency each time `resolve(_ params:)`
    /// is called on the receiver.
    ///
    /// - Parameter resolutionClosure: The resolution closure used to resolve dependencies with the `Injector`.
    public init(resolutionClosure: @escaping (Parameters) -> Service) {
        self.resolutionClosure = resolutionClosure
    }

    /// Resolves the injected dependency with the current resolution implementation
    /// provided by the `DependencyFactory` for the `Injectable` type the `Injector` was initialized with.
    ///
    /// - Parameter params: The `Parameters` that should be used to resolve the dependency.
    /// - Returns: The resolved dependency
    public func resolve(_ params: Parameters) -> Service {
        resolutionClosure(params)
    }

}
