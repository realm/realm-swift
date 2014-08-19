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
import TestFramework

class SwiftRealmTests: SwiftTestCase {

    // No models

    func testRealmExists() {
        var realm = realmWithTestPath()
        XCTAssertNotNil(realm, "realm should not be nil");
        XCTAssertTrue((realm as AnyObject) is RLMRealm, "realm should be of class RLMRealm")
    }

    func testDefaultRealmPath() {
        XCTAssertEqual(RLMRealm.defaultRealm().path!, RLMRealm.defaultRealmPath(), "Default Realm path should be correct.")
    }

    func testEmptyWriteTransaction() {
        var realm = realmWithTestPath()
        realm.beginWriteTransaction()
        realm.commitWriteTransaction()
    }

    // Swift models
    
    func testRealmAddAndRemoveObjects() {
        var realm = realmWithTestPath()
        realm.beginWriteTransaction()
        SwiftStringObject.createInRealm(realm, withObject: ["a"])
        SwiftStringObject.createInRealm(realm, withObject: ["b"])
        SwiftStringObject.createInRealm(realm, withObject: ["c"])
        XCTAssertEqual(SwiftStringObject.allObjectsInRealm(realm).count, 3, "Expecting 3 objects")
        realm.commitWriteTransaction()
        
        // test again after write transaction
        var objects = SwiftStringObject.allObjectsInRealm(realm)
        XCTAssertEqual(objects.count, 3, "Expecting 3 objects")
        XCTAssertEqual((objects[0] as SwiftStringObject).stringCol, "a", "Expecting column to be 'a'")

        realm.beginWriteTransaction()
        realm.deleteObject(objects[2] as SwiftStringObject)
        realm.deleteObject(objects[0] as SwiftStringObject)
        XCTAssertEqual(SwiftStringObject.allObjectsInRealm(realm).count, 1, "Expecting 1 object")
        realm.commitWriteTransaction()

        objects = SwiftStringObject.allObjectsInRealm(realm)
        XCTAssertEqual(objects.count, 1, "Expecting 1 object")
        XCTAssertEqual((objects[0] as SwiftStringObject).stringCol, "b", "Expecting column to be 'b'")
    }

    func testRealmIsUpdatedAfterBackgroundUpdate() {
        let realm = realmWithTestPath()

        // we have two notifications, one for opening the realm, and a second when performing our transaction
        let notificationFired = expectationWithDescription("notification fired")
        let token = realm.addNotificationBlock { note, realm in
            XCTAssertNotNil(realm, "Realm should not be nil")
            notificationFired.fulfill()
        }

        dispatch_async(dispatch_queue_create("background", nil)) {
            let realm = self.realmWithTestPath()
            realm.beginWriteTransaction()
            SwiftStringObject.createInRealm(realm, withObject: ["string"])
            realm.commitWriteTransaction()
        }
        waitForExpectationsWithTimeout(2.0, handler: nil)
        realm.removeNotification(token)

        // get object
        let objects = SwiftStringObject.allObjectsInRealm(realm)
        XCTAssertEqual(objects.count, 1, "There should be 1 object of type StringObject")
        XCTAssertEqual((objects[0] as SwiftStringObject).stringCol, "string", "Value of first column should be 'string'")
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
        XCTAssertEqual(objects.count, 1, "There should be 1 object of type SwiftIgnoredPropertiesObject")
        XCTAssertNil((objects[0] as SwiftIgnoredPropertiesObject).runtimeProperty, "Ignored property should be nil")
        XCTAssertEqual((objects[0] as SwiftIgnoredPropertiesObject).name, "@fz", "Value of the name column doesn't match the assigned one.")
    }

// FIXME: https://app.asana.com/0/861870036984/14552787865017
//
//    func testRealmIsUpdatedImmediatelyAfterBackgroundUpdate() {
//        let realm = realmWithTestPath()
//
//        // we have two notifications, one for opening the realm, and a second when performing our transaction
//        var noteCount = 0
//        let notificationFired = expectationWithDescription("notification fired")
//        let token = realm.addNotificationBlock { note, realm in
//            XCTAssertNotNil(realm, "Realm should not be nil")
//            if ++noteCount == 2 {
//                notificationFired.fulfill()
//            }
//        }
//
//        dispatch_async(dispatch_queue_create("background", nil)) {
//            let realm = self.realmWithTestPath()
//            let obj = SwiftStringObject(object: ["string"])
//            realm.beginWriteTransaction()
//            realm.addObject(obj)
//            realm.commitWriteTransaction()
//
//            let objects = SwiftStringObject.allObjectsInRealm(realm)
//            XCTAssertEqual(objects.count, 1, "There should be 1 object of type StringObject")
//            XCTAssertEqual((objects[0] as SwiftStringObject).stringCol, "string", "Value of first column should be 'string'")
//        }
//        
//        // this should complete very fast before the timer
//        waitForExpectationsWithTimeout(0.01, handler: nil)
//        realm.removeNotification(token)
//        
//        // get object
//        let objects = SwiftStringObject.allObjectsInRealm(realm)
//        XCTAssertEqual(objects.count, 1, "There should be 1 object of type RLMTestObject")
//        XCTAssertEqual((objects[0] as SwiftStringObject).stringCol, "string", "Value of first column should be 'string'")
//    }

    // Objective-C models

    func testRealmAddAndRemoveObjects_objc() {
        var realm = realmWithTestPath()
        realm.beginWriteTransaction()
        StringObject.createInRealm(realm, withObject: ["a"])
        StringObject.createInRealm(realm, withObject: ["b"])
        StringObject.createInRealm(realm, withObject: ["c"])
        XCTAssertEqual(StringObject.allObjectsInRealm(realm).count, 3, "Expecting 3 objects")
        realm.commitWriteTransaction()

        // test again after write transaction
        var objects = StringObject.allObjectsInRealm(realm)
        XCTAssertEqual(objects.count, 3, "Expecting 3 objects")
        XCTAssertEqual((objects[0] as StringObject).stringCol!, "a", "Expecting column to be 'a'")

        realm.beginWriteTransaction()
        realm.deleteObject(objects[2] as StringObject)
        realm.deleteObject(objects[0] as StringObject)
        XCTAssertEqual(StringObject.allObjectsInRealm(realm).count, 1, "Expecting 1 object")
        realm.commitWriteTransaction()

        objects = StringObject.allObjectsInRealm(realm)
        XCTAssertEqual(objects.count, 1, "Expecting 1 object")
        XCTAssertEqual((objects[0] as StringObject).stringCol!, "b", "Expecting column to be 'b'")
    }

    func testRealmIsUpdatedAfterBackgroundUpdate_objc() {
        let realm = realmWithTestPath()

        // we have two notifications, one for opening the realm, and a second when performing our transaction
        let notificationFired = expectationWithDescription("notification fired")
        let token = realm.addNotificationBlock { note, realm in
            XCTAssertNotNil(realm, "Realm should not be nil")
            notificationFired.fulfill()
        }

        dispatch_async(dispatch_queue_create("background", nil)) {
            let realm = self.realmWithTestPath()
            realm.beginWriteTransaction()
            StringObject.createInRealm(realm, withObject: ["string"])
            realm.commitWriteTransaction()
        }
        waitForExpectationsWithTimeout(2.0, handler: nil)
        realm.removeNotification(token)

        // get object
        let objects = StringObject.allObjectsInRealm(realm)
        XCTAssertEqual(objects.count, 1, "There should be 1 object of type StringObject")
        XCTAssertEqual((objects[0] as StringObject).stringCol!, "string", "Value of first column should be 'string'")
    }

// FIXME: Test passes ~50% of the time. Asana: https://app.asana.com/0/861870036984/14552787865017
//    func testRealmIsUpdatedImmediatelyAfterBackgroundUpdate_objc() {
//        let realm = realmWithTestPath()
//
//        // we have two notifications, one for opening the realm, and a second when performing our transaction
//        var noteCount = 0
//        let notificationFired = expectationWithDescription("notification fired")
//        let token = realm.addNotificationBlock { note, realm in
//            XCTAssertNotNil(realm, "Realm should not be nil")
//            if ++noteCount == 2 {
//                notificationFired.fulfill()
//            }
//        }
//
//        dispatch_async(dispatch_queue_create("background", nil)) {
//            let realm = self.realmWithTestPath()
//            let obj = StringObject(object: ["string"])
//            realm.beginWriteTransaction()
//            realm.addObject(obj)
//            realm.commitWriteTransaction()
//
//            let objects = StringObject.allObjectsInRealm(realm)
//            XCTAssertEqual(objects.count, 1, "There should be 1 object of type StringObject")
//            XCTAssertEqual((objects[0] as StringObject).stringCol, "string", "Value of first column should be 'string'")
//        }
//
//        // this should complete very fast before the timer
//        waitForExpectationsWithTimeout(0.01, handler: nil)
//        realm.removeNotification(token)
//
//        // get object
//        let objects = StringObject.allObjectsInRealm(realm)
//        XCTAssertEqual(objects.count, 1, "There should be 1 object of type RLMTestObject")
//        XCTAssertEqual((objects[0] as StringObject).stringCol, "string", "Value of first column should be 'string'")
//    }
}
