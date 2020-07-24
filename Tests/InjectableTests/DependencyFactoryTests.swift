/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

import Nimble
import XCTest

@testable import Injectable

class DependencyFactoryTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        AnyDependencyFactory.reset()
    }

    // MARK: - Injectable Tests

    func test__resolve__VoidDependency() {
        expect(MockDependencyVoid.resolve()).to(beAnInstanceOf(MockDependencyVoid.self))
    }

    func test__resolve__VoidDependency_afterInjectingSubclass() {
        // given
        InjectableFactory<MockDependencyVoid>.shared.resolver = { _ in
            MockDependencyVoid2()
        }

        // then
        expect(MockDependencyVoid.resolve()).to(beAnInstanceOf(MockDependencyVoid2.self))
    }

    func test__resolve__VoidDependency2_afterInjectingSubclass() {
        expect(MockDependencyVoid2.resolve()).to(beAnInstanceOf(MockDependencyVoid2.self))
    }

    func test__resolve__StringDependency() {
        // given
        for expected in ["Test1", "Test String 2", "String 3"] {

            //when
            let actual = MockDependencyString.resolve(expected)

            expect(actual.string).to(equal(expected))
        }
    }

    func test__resolve__StringDependencies_afterInjectingSubclasses() {
        // given
        InjectableFactory<MockDependencyString>.shared.resolver = { string in
            MockDependencyString2(string)
        }

        // then
        expect(MockDependencyString.resolve("test")).to(beAnInstanceOf(MockDependencyString2.self))
    }

    func test__resolve__TupleDependency() {
        // given
        let params = [
            ("Test1", 1),
            ("Test String 2", 2),
            ("String 3", 3)
        ]

        for expected in params {

            //when
            let actual = MockDependencyTuple.resolve(expected)

            expect(actual.string).to(equal(expected.0))
            expect(actual.int).to(equal(expected.1))
        }
    }

    // MARK: - ThrowingInjectable Tests

    func test__resolve__givenShouldThrow_throwsOrResolves() {
        // given
        let tests = [
            ("Test1", true),
            ("Test String 2", true),
            ("String 3", false),
            ("Test String 4", false)
        ]

        for expected in tests {
            //when
            MockDependencyThrowingString.shouldThrow = { _ in expected.1 }

            // then
            switch expected.1 {
            case true:
                expect(try MockDependencyThrowingString.resolve(expected.0)).to(throwError())

            case false:
                let actual = try? MockDependencyThrowingString.resolve(expected.0)
                expect(actual?.string).to(equal(expected.0))
            }
        }

        // after
        MockDependencyThrowingString.shouldThrow = { _ in false }
    }

    func test__resolve__givenThrowingAndNonThrowingInjectable_resolvesFromNonThrowingInjectableFactory() {
        // given
        var didResolveFromCorrectFactory = false

        InjectableFactory<MockDependencyThrowingAndNonThrowingVoid>.shared.resolver = { _ in
            didResolveFromCorrectFactory = true
            return MockDependencyThrowingAndNonThrowingVoid()
        }

        ThrowingInjectableFactory<MockDependencyThrowingAndNonThrowingVoid>.shared.resolver = { _ in
            fail()
            return MockDependencyThrowingAndNonThrowingVoid()
        }

        // when
        let actual = MockDependencyThrowingAndNonThrowingVoid.resolve()

        // then
        expect(didResolveFromCorrectFactory).to(beTrue())
        expect(actual).toNot(beNil())
    }

    func test__resolve__givenNonThrowingSubclassOfThrowingInjectable_resolvesFromNonThrowingInjectableFactory() {
        // given
        var didResolveFromCorrectFactory = false

        InjectableFactory<MockDependencyNonThrowingSubclassOfThrowingVoid>.shared.resolver = { _ in
            didResolveFromCorrectFactory = true
            return MockDependencyNonThrowingSubclassOfThrowingVoid()
        }

        ThrowingInjectableFactory<MockDependencyNonThrowingSubclassOfThrowingVoid>.shared.resolver = { _ in
            fail()
            return MockDependencyNonThrowingSubclassOfThrowingVoid()
        }

        // when
        let actual = MockDependencyNonThrowingSubclassOfThrowingVoid.resolve()

        // then
        expect(didResolveFromCorrectFactory).to(beTrue())
        expect(actual).toNot(beNil())
    }

    func test__makeOnThrowingInjectableFactory__givenNonThrowingSubclassOfThrowingInjectable_resolvesFromNonThrowingInjectableFactory() {
        // given
        var didResolveFromCorrectFactory = false

        InjectableFactory<MockDependencyNonThrowingSubclassOfThrowingVoid>.shared.resolver = { _ in
            didResolveFromCorrectFactory = true
            return MockDependencyNonThrowingSubclassOfThrowingVoid()
        }

        ThrowingInjectableFactory<MockDependencyNonThrowingSubclassOfThrowingVoid>.shared.resolver = { _ in
            fail()
            return MockDependencyNonThrowingSubclassOfThrowingVoid()
        }

        // when
        let actual = try? ThrowingInjectableFactory<MockDependencyNonThrowingSubclassOfThrowingVoid>
            .shared.make(with: ())

        // then
        expect(didResolveFromCorrectFactory).to(beTrue())
        expect(actual).toNot(beNil())
    }

    // MARK: - Injector Tests

    func test__injector_resolve__VoidDependency() {
        // given
        let subject = Injector(MockDependencyVoid.self)

        // when
        let actual = subject.resolve(())

        // then
        expect(actual).to(beAnInstanceOf(MockDependencyVoid.self))
    }

    func test__injector_resolve__VoidDependency_afterInjectingSubclass() {
        // given
        InjectableFactory<MockDependencyVoid>.shared.resolver = { _ in
            MockDependencyVoid2()
        }

        let subject = Injector(MockDependencyVoid.self)

        // when
        let actual = subject.resolve(())

        // then
        expect(actual).to(beAnInstanceOf(MockDependencyVoid2.self))
    }

    func test__injector_resolve__VoidDependency2() {
        // given
        let subject = Injector(MockDependencyVoid2.self)

        // when
        let actual = subject.resolve(())

        // then
        expect(actual).to(beAnInstanceOf(MockDependencyVoid2.self))
    }

    // MARK: - ThrowingInjector Tests

    func test__throwingInjector_resolve__VoidDependency() {
        // given
        MockDependencyThrowingVoid.shouldThrow = { false }
        let subject = ThrowingInjector(MockDependencyThrowingVoid.self)

        // when
        let actual = try? subject.resolve(())

        // then
        expect(actual).to(beAnInstanceOf(MockDependencyThrowingVoid.self))
    }

    func test__throwingInjector_resolve__VoidDependency_afterInjectingSubclass() {
        // given
        MockDependencyThrowingVoid.shouldThrow = { false }
        ThrowingInjectableFactory<MockDependencyThrowingVoid>.shared.resolver = { _ in
            MockDependencyThrowingVoid2()
        }

        let subject = ThrowingInjector(MockDependencyThrowingVoid.self)

        // when
        let actual = try? subject.resolve(())

        // then
        expect(actual).to(beAnInstanceOf(MockDependencyThrowingVoid2.self))
    }

    func test__throwingInjector_resolve__givenShouldThrow_throws() {
        // given
        MockDependencyThrowingVoid.shouldThrow = { true }

        // when
        let subject = ThrowingInjector(MockDependencyThrowingVoid.self)

        // then
        expect(try subject.resolve(())).to(throwError())

        // after
        MockDependencyThrowingVoid.shouldThrow = { false }
    }

    func test__throwingInjector_resolve__givenNeverThrowingDependency_resolves() {
        // given
        let subject = ThrowingInjector(MockDependencyNeverThrowingVoid.self)

        // when
        let actual = try? subject.resolve(())

        // then
        expect(actual).to(beAnInstanceOf(MockDependencyNeverThrowingVoid.self))
    }

    // MARK: - Reset Tests

    func test__reset__singleDependency_afterInjectingSubclass() {
        // given
        InjectableFactory<MockDependencyVoid>.shared.resolver = { _ in
            MockDependencyVoid2()
        }

        // when
        InjectableFactory<MockDependencyVoid>.reset()

        // then
        expect(MockDependencyVoid.resolve()).to(beAnInstanceOf(MockDependencyVoid.self))
    }

    func test__reset__allDependencies_afterInjectingSubclasses() {
        // given
        InjectableFactory<MockDependencyVoid>.shared.resolver = { _ in
            MockDependencyVoid2()
        }

        InjectableFactory<MockDependencyString>.shared.resolver = { string in
            MockDependencyString2(string)
        }

        // when
        AnyDependencyFactory.reset()

        // then
        expect(MockDependencyVoid.resolve()).to(beAnInstanceOf(MockDependencyVoid.self))
        expect(MockDependencyString.resolve("test")).to(beAnInstanceOf(MockDependencyString.self))
    }

}

// MARK: - Mock Objects

private class MockDependencyVoid: Injectable {
    required init() {}

    class func makeInjectedInstance(_: Void) -> MockDependencyVoid {
        self.init()
    }
}

private class MockDependencyVoid2: MockDependencyVoid {
}

private class MockDependencyString: Injectable {
    let string: String

    required init(_ string: String) {
        self.string = string
    }

    static func makeInjectedInstance(_ params: String) -> MockDependencyString {
        self.init(params)
    }
}

private class MockDependencyString2: MockDependencyString {
}

private class MockDependencyInt: Injectable {
    required init(_ params: Int) {}

    static func makeInjectedInstance(_ params: Int) -> MockDependencyInt {
        self.init(params)
    }
}

private class MockDependencyTuple: Injectable {
    let string: String
    let int: Int

    required init(_ params: (string: String, int: Int)) {
        self.string = params.string
        self.int = params.int
    }

    static func makeInjectedInstance(_ params: (string: String, int: Int)) -> MockDependencyTuple {
        self.init(params)
    }
}

private class MockDependencyThrowingVoid: ThrowingInjectable {
    static var shouldThrow: () -> Bool = { false }

    required init() {}

    class func makeInjectedInstance(_: Void) throws -> MockDependencyThrowingVoid {
        if shouldThrow() { throw MockError() }
        return self.init()
    }
}

private class MockDependencyThrowingVoid2: MockDependencyThrowingVoid {
}

private class MockDependencyNeverThrowingVoid: ThrowingInjectable {
    required init() {}

    static func makeInjectedInstance(_: Void) -> MockDependencyNeverThrowingVoid {
        self.init()
    }
}

private class MockDependencyThrowingString: ThrowingInjectable {
    let string: String
    static var shouldThrow: (String) -> Bool = { _ in false }

    required init(_ string: String) {
        self.string = string
    }

    static func makeInjectedInstance(_ params: String) throws -> MockDependencyThrowingString {
        if shouldThrow(params) { throw MockError() }
        return self.init(params)
    }
}

private class MockDependencyThrowingAndNonThrowingVoid: ThrowingInjectable, Injectable {

    required init() {}

    static func makeInjectedInstance(_: Void) -> MockDependencyThrowingAndNonThrowingVoid {
        return self.init()
    }
}

private class MockDependencyNonThrowingSubclassOfThrowingVoid: MockDependencyThrowingVoid, Injectable {

    required init() {}

    override class func makeInjectedInstance(_: Void) -> MockDependencyThrowingVoid {
        return self.init()
    }
}

class MockError: Swift.Error {
    
}
