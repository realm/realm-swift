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
    public let semaphore: DispatchSemaphore
    public let isOpenSemaphore: DispatchSemaphore
    private var targetEventCount: Int
    private var changeEventCount = 0
    private var didOpenWasCalled = false
    private var matchingObjectId: ObjectId?
    private weak var expectation: XCTestExpectation?

    public init(targetEventCount: Int, matchingObjectId: ObjectId? = nil, expectation: inout XCTestExpectation) {
        self.targetEventCount = targetEventCount
        self.matchingObjectId = matchingObjectId
        self.expectation = expectation
        semaphore = DispatchSemaphore(value: 0)
        isOpenSemaphore = DispatchSemaphore(value: 0)
    }

    public func changeStreamDidOpen(_ changeStream: ChangeStream) {
        didOpenWasCalled = true
        isOpenSemaphore.signal()
    }

    public func changeStreamDidClose(with error: Error?) {
        XCTAssertNil(error)
        XCTAssertTrue(didOpenWasCalled)
        XCTAssertEqual(changeEventCount, targetEventCount)
        expectation?.fulfill()
    }

    public func changeStreamDidReceive(error: Error) {
        XCTAssertNil(error)
    }

    public func changeStreamDidReceive(changeEvent: AnyBSON?) {
        changeEventCount+=1
        XCTAssertNotNil(changeEvent)
        guard let changeEvent = changeEvent else {
            return
        }

        guard let document = changeEvent.documentValue else {
            return
        }

        guard let matchingObjectId = matchingObjectId else {
            semaphore.signal()
            return
        }

        let objectId = document["fullDocument"]??.documentValue!["_id"]??.objectIdValue!
        XCTAssertEqual(objectId, matchingObjectId)
        semaphore.signal()
    }
}
