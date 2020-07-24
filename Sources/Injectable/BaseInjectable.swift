/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

/// Defines an entity that can inject a dependency of the `InjectedService` type by providing a default dependency resolver
/// that can create the dependency given some `InjectionParameters`.

/// - Note: `BaseInjectable` **is a base protocol which other protocols inherit from. External types should conform to**
/// `Injectable`, `OptionalInjectable`, **or** `ThrowingInjectable`.
///
/// Often the conforming object is the dependency being injected itself, but the `Injectable` may also be a factory or other
/// object that has the responsibility of providing the dependency. This is possible because the `InjectedService` type
/// can be any arbitrarily provided type, rather than `Self`.
///
/// The default injected dependency can be replaced with another entity of the same `InjectedService` type by overriding
/// the behavior of the `DependencyFactory` for this dependency. For injecting test mocks, `InjectableMock` can be used.
///
/// Because `Injectable` requires knowledge of the concrete injected type (rather than an inverted dependency protocol),
/// it should only be used when you have direct knowledge of the concrete type being resolved. Usually at the highest levels of
/// an application structure. This is useful, for example, when replacing a typically concrete dependency with a mock object
/// for unit testing purposes.
///
/// It is recommended that dependencies are resolved once at the highest level possible and then injected to lower level
/// consumers via manual dependency injection methods, such as initializer injection and property injection. This allows
/// for clear dependency inversion through dependency on protocols; makes it simple to explicity pass mocks in unit tests;
/// provides explicit visibility into dependency hierarchy; and simplifies debugging of dependency resolution.
///
/// When the resolution of dependencies must occur at lower levels, consider using `Injector` to wrap your dependency.
/// `Injector` allows for dependency inversion and resolution of dependencies on-demand.
/// This is especially useful when a dependency should be created lazily or must be created just-in-time given runtime parameters.
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
/// let dependencyA: A = B.resolve()
///
/// // Injected via Initializer Parameter
///
/// class C {
///   let dependency: A
///
///   init(dependency: A) {
///     self.dependency = dependency
///   }
/// }
///
/// let c = C(dependency: dependencyA)
///
/// // Property Injection
///
/// class D {
///   var dependency: A
/// }
///
/// let d = D()
/// d.dependency = dependencyA
/// ```
public protocol BaseInjectable {

    /// The type of the dependency that can be resolved using the `Injectable`.
    ///
    /// Often the `InjectedService` is the `Injectable` type itself, but the `Injectable` may also be a factory or other
    /// object that has the responsibility of providing the dependency. This is possible because the `InjectedService` type
    /// can be any arbitrarily provided type, rather than `Self`.
    associatedtype InjectedService = Self

    /// The parameters required to resolve a dependency of the `InjectedService` type.
    ///
    /// If the dependency can be resolved with no additional parameters, the `InjectionParameters` may be `Void`.
    /// If multiple parameters are needed to resolve the dependency, a tuple or a struct may be used to capture the parameters.
    associatedtype InjectionParameters = Void

    /// Makes and returns the injected instance of the dependency given the required parameters. This is called each time
    /// the default dependency is resolved (ie. if the `DependencyFactory` for the dependency has not been overridden with
    /// a different injected resolver).
    ///
    /// - Parameter params: The `InjectionParameters` that should be used to resolve the dependency.
    static func makeInjectedInstance(_ params: InjectionParameters) throws -> InjectedService
}
