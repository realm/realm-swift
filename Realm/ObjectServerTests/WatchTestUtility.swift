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

class WatchTestUtility: ChangeEventDelegate {

    typealias WatchTestUtilityBlock = ((Error?) -> Void)
    private var completion: WatchTestUtilityBlock
    private var targetEventCount: Int
    private var changeEventCount = 0
    private var didOpenWasCalled = false
    private var matchingObjectId: ObjectId?

    init(targetEventCount: Int, matchingObjectId: ObjectId? = nil, completion: @escaping WatchTestUtilityBlock) {
        self.targetEventCount = targetEventCount
        self.completion = completion
        self.matchingObjectId = matchingObjectId
    }

    func changeStreamDidOpen(_ changeStream: ChangeStream) {
        didOpenWasCalled = true
    }

    func changeStreamDidClose(with error: Error?) {
        guard let error = error else {
            if (changeEventCount == targetEventCount) && didOpenWasCalled {
                completion(nil)
            }
            return
        }
        completion(error)
    }

    func changeStreamDidReceive(error: Error) {
        completion(error)
    }

    func changeStreamDidReceive(changeEvent: AnyBSON?) {
        changeEventCount+=1

        guard let document = changeEvent?.documentValue else {
            completion(NSError())
            return
        }

        guard let matchingObjectId = matchingObjectId else {
            return
        }

        let objectId = document["fullDocument"]??.documentValue!["_id"]??.objectIdValue!

        if objectId != matchingObjectId {
            completion(NSError())
        }
    }
}
