/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

import XCTest

/// An observer that can
public class TestObserver: NSObject, XCTestObservation {

    public private(set) var isObserving = false
    private var isValid = true
    var onTestCompletion: ((XCTestCase) -> Void)?

    public init(onTestCompletion: ((XCTestCase) -> Void)? = nil) {
        self.onTestCompletion = onTestCompletion
    }

    public func startObserving() {
        if isObserving { return }
        guard isValid else {
            XCTFail("TestObserver has been invalidated.")
            return
        }

        XCTestObservationCenter.shared.addTestObserver(self)
        isObserving = true
    }

    public func testCaseDidFinish(_ testCase: XCTestCase) {
        onTestCompletion?(testCase)
        XCTestObservationCenter.shared.removeTestObserver(self)
        isObserving = false
    }

    public func invalidate() {
        onTestCompletion = nil
        isValid = false
    }

}
