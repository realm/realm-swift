////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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

class SwiftRealmTests: RLMTestCase {

    // No models

    func testRealmExists() {
        let realm = realmWithTestPath()
        XCTAssertNotNil(realm, "realm should not be nil");
        XCTAssertTrue((realm as AnyObject) is RLMRealm, "realm should be of class RLMRealm")
    }

    func testEmptyWriteTransaction() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        realm.commitWriteTransaction()
    }

    // Swift models

    func testRealmAddAndRemoveObjects() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        SwiftStringObject.createInRealm(realm, withValue: ["a"])
        SwiftStringObject.createInRealm(realm, withValue: ["b"])
        SwiftStringObject.createInRealm(realm, withValue: ["c"])
        XCTAssertEqual(SwiftStringObject.allObjectsInRealm(realm).count, UInt(3), "Expecting 3 objects")
        realm.commitWriteTransaction()

        // test again after write transaction
        var objects = SwiftStringObject.allObjectsInRealm(realm)
        XCTAssertEqual(objects.count, UInt(3), "Expecting 3 objects")
        XCTAssertEqual((objects[0] as! SwiftStringObject).stringCol, "a", "Expecting column to be 'a'")

        realm.beginWriteTransaction()
        realm.deleteObject(objects[2] as! SwiftStringObject)
        realm.deleteObject(objects[0] as! SwiftStringObject)
        XCTAssertEqual(SwiftStringObject.allObjectsInRealm(realm).count, UInt(1), "Expecting 1 object")
        realm.commitWriteTransaction()

        objects = SwiftStringObject.allObjectsInRealm(realm)
        XCTAssertEqual(objects.count, UInt(1), "Expecting 1 object")
        XCTAssertEqual((objects[0] as! SwiftStringObject).stringCol, "b", "Expecting column to be 'b'")
    }

    func testRealmIsUpdatedAfterBackgroundUpdate() {
        let realm = realmWithTestPath()

        // we have two notifications, one for opening the realm, and a second when performing our transaction
        let notificationFired = expectationWithDescription("notification fired")
        let token = realm.addNotificationBlock { note, realm in
            XCTAssertNotNil(realm, "Realm should not be nil")
            notificationFired.fulfill()
        }

        dispatchAsync {
            let realm = self.realmWithTestPath()
            realm.beginWriteTransaction()
            SwiftStringObject.createInRealm(realm, withValue: ["string"])
            realm.commitWriteTransaction()
        }
        waitForExpectationsWithTimeout(2.0, handler: nil)
        token.stop()

        // get object
        let objects = SwiftStringObject.allObjectsInRealm(realm)
        XCTAssertEqual(objects.count, UInt(1), "There should be 1 object of type StringObject")
        XCTAssertEqual((objects[0] as! SwiftStringObject).stringCol, "string", "Value of first column should be 'string'")
    }

    func testRealmIgnoresProperties() {
        let realm = realmWithTestPath()

        let object = SwiftIgnoredPropertiesObject()
        realm.beginWriteTransaction()
        object.name = "@fz"
        object.age = 31
        realm.addObject(object)
        realm.commitWriteTransaction()

        // This shouldn't do anything.
        realm.beginWriteTransaction()
        object.runtimeProperty = NSObject()
        realm.commitWriteTransaction()

        let objects = SwiftIgnoredPropertiesObject.allObjectsInRealm(realm)
        XCTAssertEqual(objects.count, UInt(1), "There should be 1 object of type SwiftIgnoredPropertiesObject")
        let retrievedObject = objects[0] as! SwiftIgnoredPropertiesObject
        XCTAssertNil(retrievedObject.runtimeProperty, "Ignored property should be nil")
        XCTAssertEqual(retrievedObject.name, "@fz", "Value of the name column doesn't match the assigned one.")
        XCTAssertEqual(retrievedObject.objectSchema.properties.count, 2, "Only 'name' and 'age' properties should be detected by Realm")
    }

    func testUpdatingSortedArrayAfterBackgroundUpdate() {
        let realm = realmWithTestPath()
        let objs = SwiftIntObject.allObjectsInRealm(realm)
        let objects = SwiftIntObject.allObjectsInRealm(realm).sortedResultsUsingProperty("intCol", ascending: true)
        let updateComplete = expectationWithDescription("background update complete")

        let token = realm.addNotificationBlock() { (_, _) in
            XCTAssertEqual(objs.count, UInt(2))
            XCTAssertEqual(objs.sortedResultsUsingProperty("intCol", ascending: true).count, UInt(2))
            XCTAssertEqual(objects.count, UInt(2))
            updateComplete.fulfill()
        }

        dispatchAsync {
            let realm = self.realmWithTestPath()
            realm.transactionWithBlock() {
                var obj = SwiftIntObject()
                obj.intCol = 2;
                realm.addObject(obj)

                obj = SwiftIntObject()
                obj.intCol = 1;
                realm.addObject(obj)
            }
        }

        waitForExpectationsWithTimeout(2.0, handler: nil)
        token.stop()
    }

    func testRealmIsUpdatedImmediatelyAfterBackgroundUpdate() {
        let realm = realmWithTestPath()

        let notificationFired = expectationWithDescription("notification fired")
        let token = realm.addNotificationBlock { note, realm in
            XCTAssertNotNil(realm, "Realm should not be nil")
            notificationFired.fulfill()
        }

        dispatchAsync {
            let realm = self.realmWithTestPath()
            let obj = SwiftStringObject(value: ["string"])
            realm.beginWriteTransaction()
            realm.addObject(obj)
            realm.commitWriteTransaction()

            let objects = SwiftStringObject.allObjectsInRealm(realm)
            XCTAssertEqual(objects.count, UInt(1), "There should be 1 object of type StringObject")
            XCTAssertEqual((objects[0] as! SwiftStringObject).stringCol, "string", "Value of first column should be 'string'")
        }

        waitForExpectationsWithTimeout(2.0, handler: nil)
        token.stop()

        // get object
        let objects = SwiftStringObject.allObjectsInRealm(realm)
        XCTAssertEqual(objects.count, UInt(1), "There should be 1 object of type RLMTestObject")
        XCTAssertEqual((objects[0] as! SwiftStringObject).stringCol, "string", "Value of first column should be 'string'")
    }

    // Objective-C models

    func testRealmAddAndRemoveObjects_objc() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        StringObject.createInRealm(realm, withValue: ["a"])
        StringObject.createInRealm(realm, withValue: ["b"])
        StringObject.createInRealm(realm, withValue: ["c"])
        XCTAssertEqual(StringObject.allObjectsInRealm(realm).count, UInt(3), "Expecting 3 objects")
        realm.commitWriteTransaction()

        // test again after write transaction
        var objects = StringObject.allObjectsInRealm(realm)
        XCTAssertEqual(objects.count, UInt(3), "Expecting 3 objects")
        XCTAssertEqual((objects[0] as! StringObject).stringCol!, "a", "Expecting column to be 'a'")

        realm.beginWriteTransaction()
        realm.deleteObject(objects[2] as! StringObject)
        realm.deleteObject(objects[0] as! StringObject)
        XCTAssertEqual(StringObject.allObjectsInRealm(realm).count, UInt(1), "Expecting 1 object")
        realm.commitWriteTransaction()

        objects = StringObject.allObjectsInRealm(realm)
        XCTAssertEqual(objects.count, UInt(1), "Expecting 1 object")
        XCTAssertEqual((objects[0] as! StringObject).stringCol!, "b", "Expecting column to be 'b'")
    }

    func testRealmIsUpdatedAfterBackgroundUpdate_objc() {
        let realm = realmWithTestPath()

        // we have two notifications, one for opening the realm, and a second when performing our transaction
        let notificationFired = expectationWithDescription("notification fired")
        let token = realm.addNotificationBlock { note, realm in
            XCTAssertNotNil(realm, "Realm should not be nil")
            if note == RLMRealmDidChangeNotification {
                notificationFired.fulfill()
            }
        }

        dispatchAsync {
            let realm = self.realmWithTestPath()
            realm.beginWriteTransaction()
            StringObject.createInRealm(realm, withValue: ["string"])
            realm.commitWriteTransaction()
        }
        waitForExpectationsWithTimeout(2.0, handler: nil)
        token.stop()

        // get object
        let objects = StringObject.allObjectsInRealm(realm)
        XCTAssertEqual(objects.count, UInt(1), "There should be 1 object of type StringObject")
        XCTAssertEqual((objects[0] as! StringObject).stringCol!, "string", "Value of first column should be 'string'")
    }

    func testRealmIsUpdatedImmediatelyAfterBackgroundUpdate_objc() {
        let realm = realmWithTestPath()

        // we have two notifications, one for opening the realm, and a second when performing our transaction
        let notificationFired = expectationWithDescription("notification fired")
        let token = realm.addNotificationBlock { note, realm in
            XCTAssertNotNil(realm, "Realm should not be nil")
            notificationFired.fulfill()
        }

        dispatchAsync {
            let realm = self.realmWithTestPath()
            let obj = StringObject(value: ["string"])
            realm.transactionWithBlock() {
                realm.addObject(obj)
            }

            let objects = StringObject.allObjectsInRealm(realm)
            XCTAssertEqual(objects.count, UInt(1), "There should be 1 object of type StringObject")
            XCTAssertEqual((objects[0] as! StringObject).stringCol!, "string", "Value of first column should be 'string'")
        }

        waitForExpectationsWithTimeout(2.0, handler: nil)
        token.stop()

        // get object
        let objects = StringObject.allObjectsInRealm(realm)
        XCTAssertEqual(objects.count, UInt(1), "There should be 1 object of type RLMTestObject")
        XCTAssertEqual((objects[0] as! StringObject).stringCol!, "string", "Value of first column should be 'string'")
    }
}
