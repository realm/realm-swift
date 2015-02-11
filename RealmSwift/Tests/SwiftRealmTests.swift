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
import RealmSwift

class SwiftRealmTests: TestCase {

    func testRealmExists() {
        var realm = realmWithTestPath()
        XCTAssertNotNil(realm, "realm should not be nil");
        XCTAssertTrue((realm as AnyObject) is Realm, "realm should be of class Realm")
    }

    func testDefaultRealmPath() {
        XCTAssertEqual(defaultRealm().path, defaultRealmPath(), "Default Realm path should be correct.")
    }

    func testEmptyWriteTransaction() {
        var realm = realmWithTestPath()
        realm.beginWrite()
        realm.commitWrite()
    }

    func testRealmAddAndRemoveObjects() {
        var realm = realmWithTestPath()
        realm.beginWrite()
        SwiftStringObject.createInRealm(realm, withObject: ["a"])
        SwiftStringObject.createInRealm(realm, withObject: ["b"])
        SwiftStringObject.createInRealm(realm, withObject: ["c"])
        XCTAssertEqual(realm.objects(SwiftStringObject).count, Int(3), "Expecting 3 objects")
        realm.commitWrite()

        // test again after write transaction
        var objects = realm.objects(SwiftStringObject)
        XCTAssertEqual(objects.count, Int(3), "Expecting 3 objects")
        XCTAssertEqual(objects[0].stringCol, "a", "Expecting column to be 'a'")

        realm.beginWrite()
        realm.delete(objects[2])
        realm.delete(objects[0])
        XCTAssertEqual(realm.objects(SwiftStringObject).count, Int(1), "Expecting 1 object")
        realm.commitWrite()

        objects = realm.objects(SwiftStringObject)
        XCTAssertEqual(objects.count, Int(1), "Expecting 1 object")
        XCTAssertEqual(objects[0].stringCol, "b", "Expecting column to be 'b'")
    }

    func testRealmIsUpdatedAfterBackgroundUpdate() {
        let realm = realmWithTestPath()

        // we have two notifications, one for opening the realm, and a second when performing our transaction
        let notificationFired = expectationWithDescription("notification fired")
        let token = realm.addNotificationBlock { _, realm in
            XCTAssertNotNil(realm, "Realm should not be nil")
            notificationFired.fulfill()
        }

        dispatch_async(dispatch_queue_create("background", nil)) {
            let realm = self.realmWithTestPath()
            realm.beginWrite()
            SwiftStringObject.createInRealm(realm, withObject: ["string"])
            realm.commitWrite()
        }
        waitForExpectationsWithTimeout(2, handler: nil)
        realm.removeNotification(token)

        // get object
        let objects = realm.objects(SwiftStringObject)
        XCTAssertEqual(objects.count, Int(1), "There should be 1 object of type StringObject")
        XCTAssertEqual(objects[0].stringCol, "string", "Value of first column should be 'string'")
    }

    func testRealmIgnoresProperties() {
        let realm = realmWithTestPath()

        let object = SwiftIgnoredPropertiesObject()
        XCTAssertEqual(object.runtimeDefaultProperty, "property")
        realm.beginWrite()
        object.name = "@fz"
        object.age = 31
        realm.add(object)
        realm.commitWrite()

        // This shouldn't do anything.
        realm.beginWrite()
        object.runtimeProperty = NSObject()
        realm.commitWrite()

        let objects = realm.objects(SwiftIgnoredPropertiesObject)
        XCTAssertEqual(objects.count, Int(1), "There should be 1 object of type SwiftIgnoredPropertiesObject")
        XCTAssertNil(objects[0].runtimeProperty, "Ignored property should be nil")
        XCTAssertEqual(objects[0].runtimeDefaultProperty, "property")
        XCTAssertEqual(objects[0].name, "@fz", "Value of the name column doesn't match the assigned one.")
    }

    func testUpdatingSortedArrayAfterBackgroundUpdate() {
        let realm = realmWithTestPath()
        let objs = realm.objects(SwiftIntObject)
        let objects = objs.sorted("intCol")
        let updateComplete = expectationWithDescription("background update complete")

        let token = realm.addNotificationBlock { _, _ in
            XCTAssertEqual(objs.count, Int(2))
            XCTAssertEqual(objs.sorted("intCol").count, Int(2))
            XCTAssertEqual(objects.count, Int(2))
            updateComplete.fulfill()
        }

        dispatch_async(dispatch_queue_create("background", nil)) {
            let realm = self.realmWithTestPath()
            realm.write {
                var obj = SwiftIntObject()
                obj.intCol = 2
                realm.add(obj)

                obj = SwiftIntObject()
                obj.intCol = 1
                realm.add(obj)
            }
        }

        waitForExpectationsWithTimeout(2, handler: nil)
        realm.removeNotification(token)
    }

    func testRealmIsUpdatedImmediatelyAfterBackgroundUpdate() {
        let realm = realmWithTestPath()

        let notificationFired = expectationWithDescription("notification fired")
        let token = realm.addNotificationBlock { _, realm in
            XCTAssertNotNil(realm, "Realm should not be nil")
            notificationFired.fulfill()
        }

        dispatch_async(dispatch_queue_create("background", nil)) {
            let realm = self.realmWithTestPath()
            let obj = SwiftStringObject(object: ["string"])
            realm.write { realm.add(obj) }

            let objects = realm.objects(SwiftStringObject)
            XCTAssertEqual(objects.count, Int(1), "There should be 1 object of type StringObject")
            XCTAssertEqual(objects[0].stringCol, "string", "Value of first column should be 'string'")
        }

        waitForExpectationsWithTimeout(2, handler: nil)
        realm.removeNotification(token)

        // get object
        let objects = realm.objects(SwiftStringObject)
        XCTAssertEqual(objects.count, Int(1), "There should be 1 object of type RLMTestObject")
        XCTAssertEqual(objects[0].stringCol, "string", "Value of first column should be 'string'")
    }
}
