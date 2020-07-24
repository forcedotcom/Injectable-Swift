/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

import Foundation
@testable import Injectable

public protocol BaseInjectableMock {

    /// The dependency that the mock can be injected as a replacement of.
    associatedtype InjectedService

    /// The parameters required to resolve a dependency of the `InjectedService` type.
    associatedtype InjectionParameters

    /// Makes and returns a mock instance of the dependency given the required parameters. Once the mock is injected, this is
    /// called each time dependency is resolved, overriding the default resolver function for the `Injectable`.
    ///
    /// - Parameter params: The `InjectionParameters` that should be used to resolve the dependency.
    static func makeMockInjectedInstance(_ params: InjectionParameters) throws -> InjectedService
}

public extension BaseInjectableMock {

    /// Injects the concrete instance, replacing the default resolution when a given `ThrowingInjectable` is resolved.
    /// This ignore's any parameters passed into the `resolve(_:)` function, explicity returning the reciever.
    ///
    /// - Note: To ensure test isolation, after each individual unit test, dependency injection will be reset to the default behavior.
    ///         A new mock should be created and injected for each test as needed.
    ///
    /// - Parameter serviceType: The `Injectable` type to replace the resolution function for.
    @discardableResult
    func inject<T: Injectable>(as serviceType: T.Type) -> Self {
        FactoryMockInjection.setFactoryResolver(for: T.self) { _ in
            guard let selfAsService = self as? T.InjectedService else {
                fatalError("\(type(of: self)) cannot be cast as" +
                    "serviceType \(T.InjectedService.self)")
            }
            return selfAsService
        }
        return self
    }

    /// Injects the concrete instance, replacing the default resolution when a given `ThrowingInjectable` is resolved.
    /// This ignore's any parameters passed into the `resolve(_:)` function, explicity returning the reciever.
    ///
    /// - Note: To ensure test isolation, after each individual unit test, dependency injection will be reset to the default behavior.
    ///         A new mock should be created and injected for each test as needed.
    ///
    /// - Parameter serviceType: The `Injectable` type to replace the resolution function for.
    @discardableResult
    func inject<T: ThrowingInjectable>(as serviceType: T.Type) -> Self {
        FactoryMockInjection.setFactoryResolver(for: T.self) { _ in
            guard let selfAsService = self as? T.InjectedService else {
                fatalError("\(type(of: self)) cannot be cast as" +
                    "serviceType \(T.InjectedService.self)")
            }
            return selfAsService
        }
        return self
    }

    /// Injects the concrete instance, replacing the default resolution when a given `Injectable` is resolved.
    /// This ignore's any parameters passed into the `resolve(_:)` function, explicity returning the reciever.
    ///
    /// - Note: To ensure test isolation, after each individual unit test, dependency injection will be reset to the default behavior.
    ///         A new mock should be created and injected for each test as needed.
    ///
    /// - Parameter serviceType: The `Injectable` type to replace the resolution function for.
    @discardableResult
    func inject<T: Injectable & ThrowingInjectable>(as serviceType: T.Type) -> Self {
        FactoryMockInjection.setFactoryResolver(for: T.self) { _ in
            guard let selfAsService = self as? T.InjectedService else {
                fatalError("\(type(of: self)) cannot be cast as" +
                    "serviceType \(T.InjectedService.self)")
            }
            return selfAsService
        }
        return self
    }

    /// Injects the mock type, replacing the default resolution when a given `ThrowingInjectable` is resolved.
    /// This replaces the default resolution with the receiver's `makeMockInjectedInstance(_ params:)` function.
    ///
    /// - Note: To ensure test isolation, after each individual unit test, dependency injection will be reset to the default behavior.
    ///         The mock should be injected for each test as needed.
    ///
    /// - Parameter serviceType: The `Injectable` type to replace the resolution function for.
    @discardableResult
    static func inject<T: ThrowingInjectable>(as serviceType: T.Type) -> Self.Type
        where T.InjectionParameters == Self.InjectionParameters {
            FactoryMockInjection.setFactoryResolver(for: T.self) { params in
                guard let instance =
                    try self.makeMockInjectedInstance(params) as? T.InjectedService else {
                        fatalError("\(self) cannot be cast as" +
                            "serviceType \(T.self)")
                }
                return instance
            }
            return self
    }
}

// MARK: -
/// Represents a mock object used for unit testing that replaces an `Injectable` dependency.
/// Can replace any `Injectable` that has the same `InjectedService` type.
public protocol AnyInjectableMock: BaseInjectableMock {
    static func makeMockInjectedInstance(_ params: InjectionParameters) -> InjectedService
}

public extension AnyInjectableMock {

    /// Injects the mock type, replacing the default resolution when a given `Injectable` is resolved.
    /// This replaces the default resolution with the receiver's `makeMockInjectedInstance(_ params:)` function.
    ///
    /// - Note: To ensure test isolation, after each individual unit test, dependency injection will be reset to the default behavior.
    ///         The mock should be injected for each test as needed.
    ///
    /// - Parameter serviceType: The `Injectable` type to replace the resolution function for.
    @discardableResult
    static func inject<T: Injectable>(as serviceType: T.Type) -> Self.Type
        where T.InjectionParameters == Self.InjectionParameters {
            FactoryMockInjection.setFactoryResolver(for: T.self) { params in
                guard let instance = self.makeMockInjectedInstance(params) as? T.InjectedService else {
                    fatalError("\(self) cannot be cast as" +
                        "serviceType \(T.self)")
                }
                return instance
            }
            return self
    }

    /// Injects the mock type, replacing the default resolution when a given `Injectable` is resolved.
    /// This replaces the default resolution with the receiver's `makeMockInjectedInstance(_ params:)` function.
    ///
    /// - Note: To ensure test isolation, after each individual unit test, dependency injection will be reset to the default behavior.
    ///         The mock should be injected for each test as needed.
    ///
    /// - Parameter serviceType: The `Injectable` type to replace the resolution function for.
    @discardableResult
    static func inject<T: Injectable & ThrowingInjectable>(as serviceType: T.Type) -> Self.Type
        where T.InjectionParameters == Self.InjectionParameters {
            FactoryMockInjection.setFactoryResolver(for: T.self) { params in
                guard let instance =
                    self.makeMockInjectedInstance(params) as? T.InjectedService else {
                        fatalError("\(self) cannot be cast as" +
                            "serviceType \(T.self)")
                }
                return instance
            }
            return self
    }

}

// MARK: -
/// Represents a mock object used for unit testing that replaces an `Injectable` dependency.
/// Provides additional convenience over `AnyInjectableMock` by requiring that the `Injectable` type being replaced is
/// defined as the `TypeMock`.
public protocol InjectableMock: AnyInjectableMock {
    /// The `Injectable` that is being replaced by the mock dependency.
    /// The mock must inject the same service as the `TypeMocked`.
    associatedtype TypeMocked: Injectable where TypeMocked.InjectedService == Self.InjectedService
}

public extension InjectableMock {

    /// Injects the concrete instance, replacing the default resolution when the `TypeMocked` is resolved.
    /// This ignore's any parameters passed into the `resolve(_:)` function, explicity returning the reciever.
    ///
    /// - Note: To ensure test isolation, after each individual unit test, dependency injection will be reset to the default behavior.
    ///         A new mock should be created and injected for each test as needed.
    @discardableResult
    func inject() -> Self {
        FactoryMockInjection.setFactoryResolver(for: Self.TypeMocked.self) { _ in
            guard let selfAsService = self as? InjectedService else {
                fatalError("\(type(of: self)) cannot be cast as " +
                    "InjectedService \(InjectedService.self)")
            }
            return selfAsService
        }
        return self
    }

}

public extension InjectableMock
where TypeMocked.InjectionParameters == Self.InjectionParameters {

    /// Injects the mock type, replacing the default resolution when the `TypeMocked` is resolved.
    /// This replaces the default resolution with the receiver's `makeMockInjectedInstance(_ params:)` function.
    ///
    /// - Note: To ensure test isolation, after each individual unit test, dependency injection will be reset to the default behavior.
    ///         The mock should be injected for each test as needed.
    @discardableResult
    static func inject() -> Self.Type {
        FactoryMockInjection.setFactoryResolver(for: self.TypeMocked.self){ params in
            self.makeMockInjectedInstance(params)
        }
        return self
    }
}

// MARK: -
public protocol AnyThrowingInjectableMock: BaseInjectableMock { }

public extension AnyThrowingInjectableMock {

    /// Injects the mock type, replacing the default resolution when a given `ThrowingInjectable` is resolved.
    /// This replaces the default resolution with the receiver's `makeMockInjectedInstance(_ params:)` function.
    ///
    /// - Note: To ensure test isolation, after each individual unit test, dependency injection will be reset to the default behavior.
    ///         The mock should be injected for each test as needed.
    ///
    /// - Parameter serviceType: The `Injectable` type to replace the resolution function for.
    @discardableResult
    static func inject<T: ThrowingInjectable>(as serviceType: T.Type) -> Self.Type
        where T.InjectionParameters == Self.InjectionParameters {
            FactoryMockInjection.setFactoryResolver(for: T.self) { params in
                guard let instance =
                    try self.makeMockInjectedInstance(params) as? T.InjectedService else {
                        fatalError("\(self) cannot be cast as" +
                            "serviceType \(T.self)")
                }
                return instance
            }
            return self
    }
}

// MARK: -
public protocol ThrowingInjectableMock: AnyThrowingInjectableMock {
    /// The `Injectable` that is being replaced by the mock dependency.
    /// The mock must inject the same service as the `TypeMocked`.
    associatedtype TypeMocked: ThrowingInjectable
        where TypeMocked.InjectedService == Self.InjectedService
}

public extension ThrowingInjectableMock {

    /// Injects the concrete instance, replacing the default resolution when the `TypeMocked` is resolved.
    /// This ignore's any parameters passed into the `resolve(_:)` function, explicity returning the reciever.
    ///
    /// - Note: To ensure test isolation, after each individual unit test, dependency injection will be reset to the default behavior.
    ///         A new mock should be created and injected for each test as needed.
    @discardableResult
    func inject() -> Self {
        FactoryMockInjection.setFactoryResolver(for: Self.TypeMocked.self) { _ in
            guard let selfAsService = self as? InjectedService else {
                fatalError("\(type(of: self)) cannot be cast as " +
                    "InjectedService \(InjectedService.self)")
            }
            return selfAsService
        }

        return self
    }

}

public extension ThrowingInjectableMock where Self: InjectableMock {

    /// Injects the concrete instance, replacing the default resolution when the `TypeMocked` is resolved.
    /// This ignore's any parameters passed into the `resolve(_:)` function, explicity returning the reciever.
    ///
    /// - Note: To ensure test isolation, after each individual unit test, dependency injection will be reset to the default behavior.
    ///         A new mock should be created and injected for each test as needed.
    @discardableResult
    func inject() -> Self {
        FactoryMockInjection.setFactoryResolver(for: Self.TypeMocked.self) { _ in
            guard let selfAsService = self as? InjectedService else {
                fatalError("\(type(of: self)) cannot be cast as " +
                    "InjectedService \(InjectedService.self)")
            }
            return selfAsService
        }
        return self
    }

}

public extension ThrowingInjectableMock
where TypeMocked.InjectionParameters == Self.InjectionParameters {

    /// Injects the mock type, replacing the default resolution when the `TypeMocked` is resolved.
    /// This replaces the default resolution with the receiver's `makeMockInjectedInstance(_ params:)` function.
    ///
    /// - Note: To ensure test isolation, after each individual unit test, dependency injection will be reset to the default behavior.
    ///         The mock should be injected for each test as needed.
    @discardableResult
    static func inject() -> Self.Type {
        FactoryMockInjection.setFactoryResolver(for: self.TypeMocked.self) { params in
            try self.makeMockInjectedInstance(params)
        }
        return self
    }
}

public extension ThrowingInjectableMock where Self: InjectableMock,
TypeMocked.InjectionParameters == Self.InjectionParameters {

    /// Injects the mock type, replacing the default resolution when the `TypeMocked` is resolved.
    /// This replaces the default resolution with the receiver's `makeMockInjectedInstance(_ params:)` function.
    ///
    /// - Note: To ensure test isolation, after each individual unit test, dependency injection will be reset to the default behavior.
    ///         The mock should be injected for each test as needed.
    @discardableResult
    static func inject() -> Self.Type {
        FactoryMockInjection.setFactoryResolver(for: self.TypeMocked.self) { params in
            self.makeMockInjectedInstance(params)
        }
        return self
    }
}

// MARK: - Factory Configuration Helpers

enum FactoryMockInjection {
    static func setFactoryResolver<T: Injectable>(
        for serviceType: T.Type,
        resolutionClosure: @escaping InjectableFactory<T>.Resolver
    ) {
        afterTestResetDependencyFactory(for: T.self)
        InjectableFactory<T>.shared.resolver = resolutionClosure
    }

    static func setFactoryResolver<T: ThrowingInjectable>(
        for serviceType: T.Type,
        resolutionClosure: @escaping ThrowingInjectableFactory<T>.Resolver
    ) {
        afterTestResetDependencyFactory(for: T.self)
        ThrowingInjectableFactory<T>.shared.resolver = resolutionClosure
    }

    static func setFactoryResolver<T: Injectable & ThrowingInjectable>(
        for serviceType: T.Type,
        resolutionClosure: @escaping InjectableFactory<T>.Resolver
    ) {
        afterTestResetDependencyFactory(for: T.self)
        InjectableFactory<T>.shared.resolver = resolutionClosure
        ThrowingInjectableFactory<T>.shared.resolver = resolutionClosure
    }

    static func afterTestResetDependencyFactory<T: Injectable>(for serviceType: T.Type) {
        TestObserver { _ in
            InjectableFactory<T>.reset()
        }.startObserving()
    }

    static func afterTestResetDependencyFactory<T: ThrowingInjectable>(for serviceType: T.Type) {
        TestObserver { _ in
            ThrowingInjectableFactory<T>.reset()
        }.startObserving()
    }

    static func afterTestResetDependencyFactory<T: Injectable & ThrowingInjectable>(
        for serviceType: T.Type
    ) {
        TestObserver { _ in
            InjectableFactory<T>.reset()
            ThrowingInjectableFactory<T>.reset()
        }.startObserving()
    }
}
