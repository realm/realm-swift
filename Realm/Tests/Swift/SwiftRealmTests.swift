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
        XCTAssertTrue((realm as AnyObject) is Realm, "realm should be of class Realm")
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
        XCTAssertEqual(realm.objects(SwiftStringObject()).count, 3, "Expecting 3 objects")
        realm.commitWriteTransaction()
        
        // test again after write transaction
        var objects = realm.objects(SwiftStringObject())
        XCTAssertEqual(objects.count, 3, "Expecting 3 objects")
        XCTAssertEqualObjects(objects[0].stringCol, "a", "Expecting column to be 'a'")

        realm.beginWriteTransaction()
        realm.deleteObject(objects[2])
        realm.deleteObject(objects[0])
        XCTAssertEqual(realm.objects(SwiftStringObject()).count, 1, "Expecting 1 object")
        realm.commitWriteTransaction()

        objects = realm.objects(SwiftStringObject())
        XCTAssertEqual(objects.count, 1, "Expecting 1 object")
        XCTAssertEqualObjects(objects[0].stringCol, "b", "Expecting column to be 'b'")
    }

    func testRealmIsUpdatedAfterBackgroundUpdate() {
        let realm = realmWithTestPath()

        // we have two notifications, one for opening the realm, and a second when performing our transaction
        var noteCount = 0
        let notificationFired = expectationWithDescription("notification fired")
        let token = realm.addNotificationBlock { note, realm in
            XCTAssertNotNil(realm, "Realm should not be nil")
            if ++noteCount == 2 {
                notificationFired.fulfill()
            }
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
        let objects = realm.objects(SwiftStringObject())
        XCTAssertEqual(objects.count, 1, "There should be 1 object of type StringObject")
        XCTAssertEqualObjects(objects[0].stringCol, "string", "Value of first column should be 'string'")
    }

// FIXME: Test passes ~50% of the time. Asana: https://app.asana.com/0/861870036984/14552787865017
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
//            XCTAssertEqualObjects((objects[0] as SwiftStringObject).stringCol, "string", "Value of first column should be 'string'")
//        }
//        
//        // this should complete very fast before the timer
//        waitForExpectationsWithTimeout(0.01, handler: nil)
//        realm.removeNotification(token)
//        
//        // get object
//        let objects = SwiftStringObject.allObjectsInRealm(realm)
//        XCTAssertEqual(objects.count, 1, "There should be 1 object of type RLMTestObject")
//        XCTAssertEqualObjects((objects[0] as SwiftStringObject).stringCol, "string", "Value of first column should be 'string'")
//    }

    // Objective-C models

    func testRealmAddAndRemoveObjects_objc() {
        var realm = realmWithTestPath()
        realm.beginWriteTransaction()
        StringObject.createInRealm(realm, withObject: ["a"])
        StringObject.createInRealm(realm, withObject: ["b"])
        StringObject.createInRealm(realm, withObject: ["c"])
        XCTAssertEqual(realm.objects(StringObject()).count, 3, "Expecting 3 objects")
        realm.commitWriteTransaction()

        // test again after write transaction
        var objects = realm.objects(StringObject())
        XCTAssertEqual(objects.count, 3, "Expecting 3 objects")
        XCTAssertEqualObjects(objects[0].stringCol, "a", "Expecting column to be 'a'")

        realm.beginWriteTransaction()
        realm.deleteObject(objects[2])
        realm.deleteObject(objects[0])
        XCTAssertEqual(realm.objects(StringObject()).count, 1, "Expecting 1 object")
        realm.commitWriteTransaction()

        objects = realm.objects(StringObject())
        XCTAssertEqual(objects.count, 1, "Expecting 1 object")
        XCTAssertEqualObjects(objects[0].stringCol, "b", "Expecting column to be 'b'")
    }

    func testRealmIsUpdatedAfterBackgroundUpdate_objc() {
        let realm = realmWithTestPath()

        // we have two notifications, one for opening the realm, and a second when performing our transaction
        var noteCount = 0
        let notificationFired = expectationWithDescription("notification fired")
        let token = realm.addNotificationBlock { note, realm in
            XCTAssertNotNil(realm, "Realm should not be nil")
            if ++noteCount == 2 {
                notificationFired.fulfill()
            }
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
        let objects = realm.objects(StringObject())
        XCTAssertEqual(objects.count, 1, "There should be 1 object of type StringObject")
        XCTAssertEqualObjects(objects[0].stringCol, "string", "Value of first column should be 'string'")
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
//            XCTAssertEqualObjects((objects[0] as StringObject).stringCol, "string", "Value of first column should be 'string'")
//        }
//
//        // this should complete very fast before the timer
//        waitForExpectationsWithTimeout(0.01, handler: nil)
//        realm.removeNotification(token)
//
//        // get object
//        let objects = StringObject.allObjectsInRealm(realm)
//        XCTAssertEqual(objects.count, 1, "There should be 1 object of type RLMTestObject")
//        XCTAssertEqualObjects((objects[0] as StringObject).stringCol, "string", "Value of first column should be 'string'")
//    }
}
