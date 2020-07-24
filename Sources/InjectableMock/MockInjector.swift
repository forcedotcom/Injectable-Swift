/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

import Foundation
@testable import Injectable

public protocol AnyMockInjector {

    associatedtype Mock
    associatedtype Service
    associatedtype Parameters

    init(resolutionClosure: @escaping (Parameters) -> Mock)

    func resolve(_ params: Parameters) throws -> Service

}

extension AnyMockInjector {

    static func convertMockToService(_ mock: Mock) -> Service {
        guard let mockAsService = mock as? Service else {
            fatalError("Mock type \(type(of: mock)) cannot be cast as Service type \(Service.self)")
        }
        return mockAsService
    }

}

public extension AnyMockInjector where Mock: AnyInjectableMock,
Mock.InjectionParameters == Parameters {

    /// A convenience initializer that uses the `makeMockInjectedInstance()` function to resolve the injected mock.
    ///
    /// - Important: This can only be used when the `InjectableMock` returns an instance of `Self`
    ///              from `makeMockInjectedInstance()`. The swift type-system does not currently allow
    ///              this to be enforced at compile-time. If this condition is not met, it will fail at run-time.
    init() {
        self.init {
            let createdMock = Mock.makeMockInjectedInstance($0)
            guard let mock = createdMock as? Mock else {
                fatalError("\(type(of: createdMock)) cannot be cast as Mock \(Mock.self)")
            }
            return mock
        }
    }

}

public extension AnyMockInjector where Mock: AnyInjectableMock,
Mock.InjectionParameters == Void {

    /// A convenience initializer that uses the `makeMockInjectedInstance()` function to resolve the injected mock.
    ///
    /// - Important: This can only be used when the `InjectableMock` returns an instance of `Self`
    ///              from `makeMockInjectedInstance()`. The swift type-system does not currently allow
    ///              this to be enforced at compile-time. If this condition is not met, it will fail at run-time.
    init() {
        self.init { _ in
            let createdMock = Mock.makeMockInjectedInstance(())
            guard let mock = createdMock as? Mock else {
                fatalError("\(type(of: createdMock)) cannot be cast as Mock \(Mock.self)")
            }
            return mock
        }
    }

}

public extension AnyMockInjector where Mock: InjectableMock,
    Mock.TypeMocked.InjectedService == Service,
    Mock.InjectionParameters == Parameters,
Mock.InjectionParameters == Mock.TypeMocked.InjectionParameters {

    /// A convenience initializer that uses the `makeMockInjectedInstance()` function to resolve the injected mock.
    ///
    /// - Important: This can only be used when the `InjectableMock` returns an instance of `Self`
    ///              from `makeMockInjectedInstance()`. The swift type-system does not currently allow
    ///              this to be enforced at compile-time. If this condition is not met, it will fail at run-time.
    ///
    /// - Parameter mockType: The `InjectableMock` type to make a ` MockInjector` for.
    init(mockType: Mock.Type) {
        self.init()
    }

}

/// A subclass of `Injector` that can be used in unit tests to override dependency resolution and capture resolution events.
///
/// - Important: The `Mock` type must be conform to the `Service` type. The swift type-system does not currently allow
///              this to be enforced at compile-time. If a `Mock` cannot be converted into `Service`, it will fail at run-time.
///
/// An `Injector` of the mock's type can be created and passed through to unit tests itself, but the `MockInjector` provides
/// additional functionality.
/// 1. It captures the parameters and mock returned each time `resolve` is called, allowing unit tests to verify
///   dependency resolution behavior.
/// 2. When the `Service` is an `Injectable`, it allows for the mock resolver function to override any resolutions of the
///   `Injectable` via `Service.resolve(_ params:)` in addition to `MockInjector.resolve(_ params:)`.
///   To enable this behavior, just call `inject()` on the `MockInjector`.
public class MockInjector<Mock, Service, Parameters>: Injector<Service, Parameters>, AnyMockInjector {

    private let mockResolutionClosure: (Parameters) -> Mock

    public var resolutions: [(params: Parameters, mock: Mock)] = []

    public required init(resolutionClosure: @escaping (Parameters) -> Mock) {
        self.mockResolutionClosure = resolutionClosure
        super.init {
            Self.convertMockToService(resolutionClosure($0))
        }
    }

    public convenience init(for: Service.Type, _ resolutionClosure: @escaping (Parameters) -> Mock) {
        self.init(resolutionClosure: resolutionClosure)
    }

    public override func resolve(_ params: Parameters) -> Service {
        let resolvedMock = mockResolutionClosure(params)
        let mockAsService = Self.convertMockToService(resolvedMock)
        self.resolutions.append((params, resolvedMock))
        return mockAsService
    }

}

public extension MockInjector where Mock: AnyObject {

    /// Finds the parameters used to resolve the given mock object.
    /// - Parameter mockToFind: The mock object to retrieve the resolution parameters for.
    /// - Returns: The parameters that were pased to the `resolve(_:)` function when the
    ///            given mock was created.
    func resolutionParameters(for mockToFind: Mock) -> Parameters? {
        resolutions.first { $0.mock === mockToFind }?.params
    }

}

public extension MockInjector where Mock: BaseInjectableMock {

    /// Injects the `MockInjector`, activating it's `mockResolutionClosure` for all resolutions of the `Injectable` type.
    ///
    /// If `inject()` is not called, the default resolution of the `Injectable` will not be replaced for
    /// calls to `Service.resolve(_ params:)`. Calls to `MockInjector.resolve(_ params:)`
    /// will still resolve using the `mockResolutionClosure`.
    ///
    /// - Note: To ensure test isolation, after each individual unit test, dependency injection will be reset to the default behavior.
    ///         The mock should be injected for each test as needed.
    func inject<T: Injectable>(as serviceType: T.Type) -> Self
        where T.InjectedService == Service, T.InjectionParameters == Parameters {
            FactoryMockInjection.setFactoryResolver(for: T.self) {
                self.resolve($0)
            }
            return self
    }

    /// Injects the `MockInjector`, activating it's `mockResolutionClosure` for all resolutions of the `Injectable` type.
    ///
    /// If `inject()` is not called, the default resolution of the `Injectable` will not be replaced for
    /// calls to `Service.resolve(_ params:)`. Calls to `MockInjector.resolve(_ params:)`
    /// will still resolve using the `mockResolutionClosure`.
    ///
    /// - Note: To ensure test isolation, after each individual unit test, dependency injection will be reset to the default behavior.
    ///         The mock should be injected for each test as needed.
    func inject<T: ThrowingInjectable>(as serviceType: T.Type) -> Self
        where T.InjectedService == Service, T.InjectionParameters == Parameters {
            FactoryMockInjection.setFactoryResolver(for: T.self) {
                self.resolve($0)
            }
            return self
    }

    /// Injects the `MockInjector`, activating it's `mockResolutionClosure` for all resolutions of the `Injectable` type.
    ///
    /// If `inject()` is not called, the default resolution of the `Injectable` will not be replaced for
    /// calls to `Service.resolve(_ params:)`. Calls to `MockInjector.resolve(_ params:)`
    /// will still resolve using the `mockResolutionClosure`.
    ///
    /// - Note: To ensure test isolation, after each individual unit test, dependency injection will be reset to the default behavior.
    ///         The mock should be injected for each test as needed.
    func inject<T: Injectable & ThrowingInjectable>(as serviceType: T.Type) -> Self
        where T.InjectedService == Service, T.InjectionParameters == Parameters {
            FactoryMockInjection.setFactoryResolver(for: T.self) {
                self.resolve($0)
            }
            return self
    }

}

public extension MockInjector where Mock: InjectableMock,
    Mock.TypeMocked.InjectedService == Service,
    Mock.InjectionParameters == Parameters,
Mock.InjectionParameters == Mock.TypeMocked.InjectionParameters {

    /// Injects the `MockInjector`, activating it's `mockResolutionClosure` for all resolutions of
    /// the `Mock.TypeMocked` type.
    ///
    /// If `inject()` is not called, the default resolution of the `Injectable` will not be replaced for
    /// calls to `Mock.TypeMocked.resolve(_ params:)`. Calls to `MockInjector.resolve(_ params:)`
    /// will still resolve using the `mockResolutionClosure`.
    ///
    /// - Note: To ensure test isolation, after each individual unit test, dependency injection will be reset to the default behavior.
    ///         The mock should be injected for each test as needed.
    func inject() -> Self {
        self.inject(as: Mock.TypeMocked.self)
    }
}

public extension Injector {
    /// Typealias on `Injector` for easy declaration of `MockInjector`s.
    ///
    /// # Example:
    /// `Injector<A, B>.Mock<C> == MockInjector<C, A, B>`
    typealias Mock<M> = MockInjector<M, Service, Parameters>
}
