////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

import XCTest
import Realm
import Realm.Private

class InitLinkedToClass: RLMObject {
    dynamic var value = SwiftIntObject(value: [0])
}

class SwiftRecursingSchemaTestObject : RLMObject {
    dynamic var propertyWithIllegalDefaultValue: SwiftIntObject? = {
        if mayAccessSchema {
            let realm = RLMRealm.defaultRealm()
            return SwiftIntObject.allObjects().firstObject() as! SwiftIntObject?
        } else {
            return nil
        }
    }()

    static var mayAccessSchema = false
}


class SwiftSchemaTests: RLMMultiProcessTestCase {
    func testWorksAtAll() {
        if isParent {
            XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
        }
    }

    func testSchemaInitWithLinkedToObjectUsingInitWithValue() {
        if isParent {
            XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
            return
        }

        // registerClasses:count: happens to initialize the schemas in the same
        // order as the classes appear in the array, so this initializes the
        // schema for `InitLinkedToClass` before `IntObject` to verify that
        // `initWithValue:` does not throw in that scenario
        RLMSchema.registerClasses([InitLinkedToClass.self, SwiftIntObject.self], count: 2)
    }

    func testPreventsDeadLocks() {
        if isParent {
            XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
            return
        }

        SwiftRecursingSchemaTestObject.mayAccessSchema = true
        assertThrowsWithReasonMatching(RLMSchema.sharedSchema(), ".*recursive.*")
    }
}
