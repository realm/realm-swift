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

class IgnoredLinkPropertyObject : RLMObject {
    dynamic var value = 0
    var obj = SwiftIntObject()

    override class func ignoredProperties() -> [AnyObject]? {
        return ["obj"]
    }
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

        let config = RLMRealmConfiguration.defaultConfiguration()
        config.objectClasses = [IgnoredLinkPropertyObject.self]
        config.inMemoryIdentifier = __FUNCTION__
        let r = RLMRealm(configuration: config, error: nil)!
        r.transactionWithBlock {
            IgnoredLinkPropertyObject.createInRealm(r, withValue: [1])
        }
    }

    func testCreateStandaloneObjectWhichCreatesAnotherClassDuringSchemaInit() {
        if isParent {
            XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
            return
        }

        // Should not throw (or crash) despite creating an object with an
        // unintialized schema during schema init
        let _ = InitLinkedToClass()
    }

    func testCreateStandaloneObjectWithLinkPropertyWithoutSharedSchemaInitialized() {
        if isParent {
            XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
            return
        }

        // This is different from the above test in that it links to an
        // unintialized type rather than creating one
        let _ = SwiftCompanyObject()
    }

    func testInitStandaloneObjectNotInClassSubsetDuringSchemaInit() {
        if isParent {
            XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
            return
        }

        let config = RLMRealmConfiguration.defaultConfiguration()
        config.objectClasses = [IgnoredLinkPropertyObject.self]
        config.inMemoryIdentifier = __FUNCTION__
        let _ = RLMRealm(configuration: config, error: nil)!
        let r = RLMRealm(configuration: RLMRealmConfiguration.defaultConfiguration(), error: nil)!
        r.transactionWithBlock {
            IgnoredLinkPropertyObject.createInRealm(r, withValue: [1])
        }
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
