////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
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
