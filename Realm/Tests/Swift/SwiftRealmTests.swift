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
        try! realm.commitWriteTransaction()
    }

    // Swift models

    func testRealmAddAndRemoveObjects() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        _ = SwiftStringObject.create(in: realm, withValue: ["a"])
        _ = SwiftStringObject.create(in: realm, withValue: ["b"])
        _ = SwiftStringObject.create(in: realm, withValue: ["c"])
        XCTAssertEqual(SwiftStringObject.allObjects(in: realm).count, UInt(3), "Expecting 3 objects")
        try! realm.commitWriteTransaction()

        // test again after write transaction
        var objects = SwiftStringObject.allObjects(in: realm)
        XCTAssertEqual(objects.count, UInt(3), "Expecting 3 objects")
        XCTAssertEqual((objects[0] as! SwiftStringObject).stringCol, "a", "Expecting column to be 'a'")

        realm.beginWriteTransaction()
        realm.delete(objects[2] as! SwiftStringObject)
        realm.delete(objects[0] as! SwiftStringObject)
        XCTAssertEqual(SwiftStringObject.allObjects(in: realm).count, UInt(1), "Expecting 1 object")
        try! realm.commitWriteTransaction()

        objects = SwiftStringObject.allObjects(in: realm)
        XCTAssertEqual(objects.count, UInt(1), "Expecting 1 object")
        XCTAssertEqual((objects[0] as! SwiftStringObject).stringCol, "b", "Expecting column to be 'b'")
    }

    func testRealmIsUpdatedAfterBackgroundUpdate() {
        let realm = realmWithTestPath()

        // we have two notifications, one for opening the realm, and a second when performing our transaction
        let notificationFired = expectation(description: "notification fired")
        let token = realm.addNotificationBlock { note, realm in
            XCTAssertNotNil(realm, "Realm should not be nil")
            notificationFired.fulfill()
        }

        dispatchAsync {
            let realm = self.realmWithTestPath()
            realm.beginWriteTransaction()
            _ = SwiftStringObject.create(in: realm, withValue: ["string"])
            try! realm.commitWriteTransaction()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
        token.invalidate()

        // get object
        let objects = SwiftStringObject.allObjects(in: realm)
        XCTAssertEqual(objects.count, UInt(1), "There should be 1 object of type StringObject")
        XCTAssertEqual((objects[0] as! SwiftStringObject).stringCol, "string", "Value of first column should be 'string'")
    }

    func testRealmIgnoresProperties() {
        let realm = realmWithTestPath()

        let object = SwiftIgnoredPropertiesObject()
        realm.beginWriteTransaction()
        object.name = "@fz"
        object.age = 31
        realm.add(object)
        try! realm.commitWriteTransaction()

        // This shouldn't do anything.
        realm.beginWriteTransaction()
        object.runtimeProperty = NSObject()
        try! realm.commitWriteTransaction()

        let objects = SwiftIgnoredPropertiesObject.allObjects(in: realm)
        XCTAssertEqual(objects.count, UInt(1), "There should be 1 object of type SwiftIgnoredPropertiesObject")
        let retrievedObject = objects[0] as! SwiftIgnoredPropertiesObject
        XCTAssertNil(retrievedObject.runtimeProperty, "Ignored property should be nil")
        XCTAssertEqual(retrievedObject.name, "@fz", "Value of the name column doesn't match the assigned one.")
        XCTAssertEqual(retrievedObject.objectSchema.properties.count, 2, "Only 'name' and 'age' properties should be detected by Realm")
    }

    func testUpdatingSortedArrayAfterBackgroundUpdate() {
        let realm = realmWithTestPath()
        let objs = SwiftIntObject.allObjects(in: realm)
        let objects = SwiftIntObject.allObjects(in: realm).sortedResults(usingKeyPath: "intCol", ascending: true)
        let updateComplete = expectation(description: "background update complete")

        let token = realm.addNotificationBlock() { (_, _) in
            XCTAssertEqual(objs.count, UInt(2))
            XCTAssertEqual(objs.sortedResults(usingKeyPath: "intCol", ascending: true).count, UInt(2))
            XCTAssertEqual(objects.count, UInt(2))
            updateComplete.fulfill()
        }

        dispatchAsync {
            let realm = self.realmWithTestPath()
            try! realm.transaction {
                var obj = SwiftIntObject()
                obj.intCol = 2;
                realm.add(obj)

                obj = SwiftIntObject()
                obj.intCol = 1;
                realm.add(obj)
            }
        }

        waitForExpectations(timeout: 2.0, handler: nil)
        token.invalidate()
    }

    func testRealmIsUpdatedImmediatelyAfterBackgroundUpdate() {
        let realm = realmWithTestPath()

        let notificationFired = expectation(description: "notification fired")
        let token = realm.addNotificationBlock { note, realm in
            XCTAssertNotNil(realm, "Realm should not be nil")
            notificationFired.fulfill()
        }

        dispatchAsync {
            let realm = self.realmWithTestPath()
            let obj = SwiftStringObject(value: ["string"])
            realm.beginWriteTransaction()
            realm.add(obj)
            try! realm.commitWriteTransaction()

            let objects = SwiftStringObject.allObjects(in: realm)
            XCTAssertEqual(objects.count, UInt(1), "There should be 1 object of type StringObject")
            XCTAssertEqual((objects[0] as! SwiftStringObject).stringCol, "string", "Value of first column should be 'string'")
        }

        waitForExpectations(timeout: 2.0, handler: nil)
        token.invalidate()

        // get object
        let objects = SwiftStringObject.allObjects(in: realm)
        XCTAssertEqual(objects.count, UInt(1), "There should be 1 object of type RLMTestObject")
        XCTAssertEqual((objects[0] as! SwiftStringObject).stringCol, "string", "Value of first column should be 'string'")
    }

    // Objective-C models

    func testRealmAddAndRemoveObjects_objc() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        _ = StringObject.create(in: realm, withValue: ["a"])
        _ = StringObject.create(in: realm, withValue: ["b"])
        _ = StringObject.create(in: realm, withValue: ["c"])
        XCTAssertEqual(StringObject.allObjects(in: realm).count, UInt(3), "Expecting 3 objects")
        try! realm.commitWriteTransaction()

        // test again after write transaction
        var objects = StringObject.allObjects(in: realm)
        XCTAssertEqual(objects.count, UInt(3), "Expecting 3 objects")
        XCTAssertEqual((objects[0] as! StringObject).stringCol!, "a", "Expecting column to be 'a'")

        realm.beginWriteTransaction()
        realm.delete(objects[2] as! StringObject)
        realm.delete(objects[0] as! StringObject)
        XCTAssertEqual(StringObject.allObjects(in: realm).count, UInt(1), "Expecting 1 object")
        try! realm.commitWriteTransaction()

        objects = StringObject.allObjects(in: realm)
        XCTAssertEqual(objects.count, UInt(1), "Expecting 1 object")
        XCTAssertEqual((objects[0] as! StringObject).stringCol!, "b", "Expecting column to be 'b'")
    }

    func testRealmIsUpdatedAfterBackgroundUpdate_objc() {
        let realm = realmWithTestPath()

        // we have two notifications, one for opening the realm, and a second when performing our transaction
        let notificationFired = expectation(description: "notification fired")
        let token = realm.addNotificationBlock { note, realm in
            XCTAssertNotNil(realm, "Realm should not be nil")
            if note == RLMNotification.DidChange {
                notificationFired.fulfill()
            }
        }

        dispatchAsync {
            let realm = self.realmWithTestPath()
            realm.beginWriteTransaction()
            _ = StringObject.create(in: realm, withValue: ["string"])
            try! realm.commitWriteTransaction()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
        token.invalidate()

        // get object
        let objects = StringObject.allObjects(in: realm)
        XCTAssertEqual(objects.count, UInt(1), "There should be 1 object of type StringObject")
        XCTAssertEqual((objects[0] as! StringObject).stringCol!, "string", "Value of first column should be 'string'")
    }

    func testRealmIsUpdatedImmediatelyAfterBackgroundUpdate_objc() {
        let realm = realmWithTestPath()

        // we have two notifications, one for opening the realm, and a second when performing our transaction
        let notificationFired = expectation(description: "notification fired")
        let token = realm.addNotificationBlock { note, realm in
            XCTAssertNotNil(realm, "Realm should not be nil")
            notificationFired.fulfill()
        }

        dispatchAsync {
            let realm = self.realmWithTestPath()
            let obj = StringObject(value: ["string"])
            try! realm.transaction {
                realm.add(obj)
            }

            let objects = StringObject.allObjects(in: realm)
            XCTAssertEqual(objects.count, UInt(1), "There should be 1 object of type StringObject")
            XCTAssertEqual((objects[0] as! StringObject).stringCol!, "string", "Value of first column should be 'string'")
        }

        waitForExpectations(timeout: 2.0, handler: nil)
        token.invalidate()

        // get object
        let objects = StringObject.allObjects(in: realm)
        XCTAssertEqual(objects.count, UInt(1), "There should be 1 object of type RLMTestObject")
        XCTAssertEqual((objects[0] as! StringObject).stringCol!, "string", "Value of first column should be 'string'")
    }
}
