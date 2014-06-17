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

class SwiftRealmTests: RLMTestCase {
    
    func testRealmExists() {
        var realm = realmWithTestPath()
        XCTAssertNotNil(realm, "realm should not be nil");
        XCTAssertTrue((realm as AnyObject) is RLMRealm, "realm should be of class RLMRealm")
    }
    
    func testEmptyWriteTransaction() {
        var realm = realmWithTestPath()
        realm.beginWriteTransaction()
        realm.commitWriteTransaction()
    }
    
    func testRealmAddAndRemoveObjects() {
        var realm = realmWithTestPath()
        realm.beginWriteTransaction()
        RLMTestObject.createInRealm(realm, withObject: ["a"])
        RLMTestObject.createInRealm(realm, withObject: ["b"])
        RLMTestObject.createInRealm(realm, withObject: ["c"])
        XCTAssertEqual(realm.objects(RLMTestObject.className(), `where`: nil).count, 3, "Expecting 3 objects")
        realm.commitWriteTransaction()
        
        // test again after write transaction
        var objects = realm.allObjects(RLMTestObject.className())
        XCTAssertEqual(objects.count, 3, "Expecting 3 objects")
        XCTAssertEqualObjects(objects.firstObject().column, "a", "Expecting column to be 'a'")
        
        realm.beginWriteTransaction()
        realm.deleteObject(objects[2] as RLMTestObject)
        realm.deleteObject(objects[0] as RLMTestObject)
        XCTAssertEqual(realm.objects(RLMTestObject.className(), `where`: nil).count, 1, "Expecting 1 object")
        realm.commitWriteTransaction()
        
        objects = realm.allObjects(RLMTestObject.className())
        XCTAssertEqual(objects.count, 1, "Expecting 1 object")
        XCTAssertEqualObjects(objects.firstObject().column, "b", "Expecting column to be 'b'")
    }
    
    func testRealmIsUpdatedAfterBackgroundUpdate() {
        let realm = realmWithTestPath()
        let token = realm.addNotificationBlock() { note, realm in
            XCTAssertNotNil(realm, "Realm should not be nil")
            self.notify(XCTAsyncTestCaseStatusSucceeded)
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            let realm = self.realmWithTestPath()
            realm.beginWriteTransaction()
            RLMTestObject.createInRealm(realm, withObject: ["string"])
            realm.commitWriteTransaction()
        }
        
        waitForStatus(XCTAsyncTestCaseStatusSucceeded, timeout: 2)
        realm.removeNotification(token)
    }
    
    func testRealmIsUpdatedImmediatelyAfterBackgroundUpdate() {
        let realm = realmWithTestPath()
        let token = realm.addNotificationBlock() { note, realm in
            XCTAssertNotNil(realm, "Realm should not be nil")
            self.notify(XCTAsyncTestCaseStatusSucceeded)
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            let realm = self.realmWithTestPath()
            let obj = RLMTestObject()
            obj.column = "string"
            realm.beginWriteTransaction()
            realm.addObject(obj)
            realm.commitWriteTransaction()
        }
        
        // this should complete very fast before the timer
        waitForStatus(XCTAsyncTestCaseStatusSucceeded, timeout: 2)
        realm.removeNotification(token)
        
        // get object
        let objects = realm.objects(RLMTestObject.className(), `where`: nil)
        XCTAssertEqual(objects.count, 1, "There should be 1 object of type RLMTestObject")
        XCTAssertEqualObjects((objects[0] as RLMTestObject).column, "string", "Value of first column should be 'string'")
    }
}
