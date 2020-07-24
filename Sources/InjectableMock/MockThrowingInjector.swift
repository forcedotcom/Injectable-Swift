/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

import Foundation
@testable import Injectable

/// A subclass of `ThrowingInjector` that can be used in unit tests to override dependency resolution and
/// capture resolution events.
///
/// - Important: The `Mock` type must be conform to the `Service` type. The swift type-system does not currently allow
///              this to be enforced at compile-time. If a `Mock` cannot be converted into `Service`, it will fail at run-time.
///
/// See `MockInjector` for more information.
public class MockThrowingInjector<Mock, Service, Parameters>: ThrowingInjector<Service, Parameters>,
AnyMockInjector {

    private let mockResolutionClosure: (Parameters) throws -> Mock

    public var resolutions: [(params: Parameters, mock: Result<Mock, Error>)] = []

    public required init(resolutionClosure: @escaping (Parameters) throws -> Mock) {
        self.mockResolutionClosure = resolutionClosure
        super.init {
            Self.convertMockToService(try resolutionClosure($0))
        }
    }

    public required init(resolutionClosure: @escaping (Parameters) -> Mock) {
        self.mockResolutionClosure = resolutionClosure
        super.init {
            Self.convertMockToService(resolutionClosure($0))
        }
    }

    public convenience init(
        for: Service.Type,
        _ resolutionClosure: @escaping (Parameters) throws -> Mock
    ) {
        self.init(resolutionClosure: resolutionClosure)
    }

    public override func resolve(_ params: Parameters) throws -> Service {
        do {
            let resolvedMock = try mockResolutionClosure(params)
            let mockAsService = Self.convertMockToService(resolvedMock)
            self.resolutions.append((params, .success(resolvedMock)))
            return mockAsService
        } catch {
            self.resolutions.append((params, .failure(error)))
            throw error
        }
    }

}

public extension MockThrowingInjector where Mock: AnyObject {

    /// Finds the parameters used to resolve the given mock object.
    /// - Parameter mockToFind: The mock object to retrieve the resolution parameters for.
    /// - Returns: The parameters that were pased to the `resolve(_:)` function when the
    ///            given mock was created.
    func resolutionParameters(for mockToFind: Mock) -> Parameters? {
        resolutions
            .first {
                guard let mock = try? $0.mock.get() else { return false }
                return mock === mockToFind
            }?
            .params
    }

}

public extension MockThrowingInjector where Mock: BaseInjectableMock {

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
                try self.resolve($0)
            }
            return self
    }

}

public extension MockThrowingInjector where Mock: ThrowingInjectableMock,
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
    convenience init(mockType: Mock.Type) {
        self.init {
            let createdMock = try Mock.makeMockInjectedInstance($0)
            guard let mock = createdMock as? Mock else {
                fatalError("\(type(of: createdMock)) cannot be cast as Mock \(Mock.self)")
            }
            return mock
        }
    }

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

public extension ThrowingInjector {
    /// Typealias on `Injector` for easy declaration of `MockInjector`s.
    ///
    /// # Example:
    /// `Injector<A, B>.Mock<C> == MockInjector<C, A, B>`
    typealias Mock<M> = MockThrowingInjector<M, Service, Parameters>
}
