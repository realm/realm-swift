////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import Foundation
import RealmSwift
import XCTest

final public class WatchTestUtility: ChangeEventDelegate {
    private let testCase: XCTestCase
    private let matchingObjectId: ObjectId?
    private let openExpectation: XCTestExpectation
    private let closeExpectation: XCTestExpectation
    private var changeExpectation: XCTestExpectation?
    private let expectError: Bool
    public var didCloseError: Error?

    public init(testCase: XCTestCase, matchingObjectId: ObjectId? = nil, expectError: Bool = false) {
        self.testCase = testCase
        self.matchingObjectId = matchingObjectId
        self.expectError = expectError
        openExpectation = testCase.expectation(description: "Open watch stream")
        closeExpectation = testCase.expectation(description: "Close watch stream")
    }

    public func waitForOpen() {
        testCase.wait(for: [openExpectation], timeout: 20.0)
    }

    public func waitForClose() {
        testCase.wait(for: [closeExpectation], timeout: 20.0)
    }

    public func expectEvent() {
        XCTAssertNil(changeExpectation)
        changeExpectation = testCase.expectation(description: "Watch change event")
    }

    public func waitForEvent() throws {
        try testCase.wait(for: [XCTUnwrap(changeExpectation)], timeout: 20.0)
        changeExpectation = nil
    }

    public func changeStreamDidOpen(_ changeStream: ChangeStream) {
        openExpectation.fulfill()
    }

    public func changeStreamDidClose(with error: Error?) {
        if expectError {
            XCTAssertNotNil(error)
        } else {
            XCTAssertNil(error)
        }

        didCloseError = error
        closeExpectation.fulfill()
    }

    public func changeStreamDidReceive(error: Error) {
        XCTAssertNil(error)
    }

    public func changeStreamDidReceive(changeEvent: AnyBSON?) {
        XCTAssertNotNil(changeEvent)
        XCTAssertNotNil(changeExpectation)
        guard let changeEvent = changeEvent else { return }
        guard let document = changeEvent.documentValue else { return }

        if let matchingObjectId = matchingObjectId {
            let objectId = document["fullDocument"]??.documentValue!["_id"]??.objectIdValue!
            XCTAssertEqual(objectId, matchingObjectId)
        }
        changeExpectation?.fulfill()
    }
}
