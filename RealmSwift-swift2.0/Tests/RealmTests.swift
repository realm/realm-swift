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
import RealmSwift
import Foundation

class RealmTests: TestCase {
    override func setUp() {
        super.setUp()

        autoreleasepool {
            self.realmWithTestPath().write {
                self.realmWithTestPath().create(SwiftStringObject.self, value: ["1"])
                self.realmWithTestPath().create(SwiftStringObject.self, value: ["2"])
                self.realmWithTestPath().create(SwiftStringObject.self, value: ["3"])
            }

            try! Realm().write {
                try! Realm().create(SwiftIntObject.self, value: [100])
                try! Realm().create(SwiftIntObject.self, value: [200])
                try! Realm().create(SwiftIntObject.self, value: [300])
            }
        }
    }

    func testPath() {
        XCTAssertEqual(Realm.defaultPath, try! Realm().path)
        XCTAssertEqual(testRealmPath(), realmWithTestPath().path)
    }

    func testReadOnly() {
        autoreleasepool {
            XCTAssertEqual(try! Realm().readOnly, false)
        }
        let readOnlyRealm = try! Realm(path: Realm.defaultPath, readOnly: true)
        XCTAssertEqual(true, readOnlyRealm.readOnly)
        XCTAssertEqual(3, readOnlyRealm.objects(SwiftIntObject).count)

        assertThrows(try! Realm(), "Realm has different readOnly settings")
    }

    func testSchema() {
        let schema = try! Realm().schema
        XCTAssert(schema as AnyObject is Schema)
        XCTAssertEqual(1, schema.objectSchema.filter({ $0.className == "SwiftStringObject" }).count)
    }

    func testDefaultPath() {
        let defaultPath =  try! Realm().path
        XCTAssertEqual(Realm.defaultPath, defaultPath)

        let newPath = (defaultPath as NSString).stringByAppendingPathExtension("new")!
        Realm.defaultPath = newPath
        XCTAssertEqual(Realm.defaultPath, newPath)
        XCTAssertEqual(try! Realm().path, Realm.defaultPath)
    }

    func testInit() {
        XCTAssertEqual(try! Realm().path, Realm.defaultPath)
        XCTAssertEqual(try! Realm(path: testRealmPath()).path, testRealmPath())
        assertThrows(try! Realm(path: ""))
    }

    func testInitFailable() {
        autoreleasepool {
            try! Realm(path: Realm.defaultPath, readOnly: false)
        }

        NSFileManager.defaultManager().createFileAtPath(Realm.defaultPath,
            contents:"a".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false),
            attributes: nil)
        do {
            _ = try Realm(path: Realm.defaultPath, readOnly: false)
            XCTFail("Realm creation should have failed")
        } catch {
        }

        assertThrows(try! Realm(path: Realm.defaultPath, readOnly: false, encryptionKey: "asdf".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)))
        assertThrows(try! Realm(path: "", readOnly: false))
    }

    func testInitInMemory() {
        autoreleasepool {
            let realm = inMemoryRealm("identifier")
            realm.write {
                realm.create(SwiftIntObject.self, value: [1])
                return
            }
        }
        let realm = inMemoryRealm("identifier")
        XCTAssertEqual(realm.objects(SwiftIntObject).count, 0)

        realm.write {
            realm.create(SwiftIntObject.self, value: [1])
            XCTAssertEqual(realm.objects(SwiftIntObject).count, 1)

            inMemoryRealm("identifier").create(SwiftIntObject.self, value: [1])
            XCTAssertEqual(realm.objects(SwiftIntObject).count, 2)
        }

        let realm2 = inMemoryRealm("identifier2")
        XCTAssertEqual(realm2.objects(SwiftIntObject).count, 0)
    }

    func testWrite() {
        try! Realm().write {
            self.assertThrows(try! Realm().beginWrite())
            self.assertThrows(try! Realm().write { })
            try! Realm().create(SwiftStringObject.self, value:["1"])
            XCTAssertEqual(try! Realm().objects(SwiftStringObject).count, 1)
        }
        XCTAssertEqual(try! Realm().objects(SwiftStringObject).count, 1)
    }

    func testBeginWrite() {
        try! Realm().beginWrite()
        assertThrows(try! Realm().beginWrite())
        try! Realm().cancelWrite()
        try! Realm().beginWrite()
        try! Realm().create(SwiftStringObject.self, value:["1"])
        XCTAssertEqual(try! Realm().objects(SwiftStringObject).count, 1)
    }

    func testCommitWrite() {
        try! Realm().beginWrite()
        try! Realm().create(SwiftStringObject.self, value:["1"])
        try! Realm().commitWrite()
        XCTAssertEqual(try! Realm().objects(SwiftStringObject).count, 1)
        try! Realm().beginWrite()
    }

    func testCancelWrite() {
        assertThrows(try! Realm().cancelWrite())
        try! Realm().beginWrite()
        try! Realm().create(SwiftStringObject.self, value:["1"])
        try! Realm().cancelWrite()
        XCTAssertEqual(try! Realm().objects(SwiftStringObject).count, 0)

        try! Realm().write {
            self.assertThrows(self.realmWithTestPath().cancelWrite())
            let object = try! Realm().create(SwiftStringObject)
            try! Realm().cancelWrite()
            XCTAssertTrue(object.invalidated)
            XCTAssertEqual(try! Realm().objects(SwiftStringObject).count, 0)
        }
        XCTAssertEqual(try! Realm().objects(SwiftStringObject).count, 0)
    }

    func testInWriteTransaction() {
        let realm = try! Realm()
        XCTAssertFalse(realm.inWriteTransaction)
        realm.beginWrite()
        XCTAssertTrue(realm.inWriteTransaction)
        realm.cancelWrite()
        realm.write {
            XCTAssertTrue(realm.inWriteTransaction)
            realm.cancelWrite()
            XCTAssertFalse(realm.inWriteTransaction)
        }

        realm.beginWrite()
        realm.invalidate()
        XCTAssertFalse(realm.inWriteTransaction)
    }

    func testAddSingleObject() {
        let realm = try! Realm()
        assertThrows(_ = realm.add(SwiftObject()))
        XCTAssertEqual(0, realm.objects(SwiftObject).count)
        var defaultRealmObject: SwiftObject!
        realm.write {
            defaultRealmObject = SwiftObject()
            realm.add(defaultRealmObject)
            XCTAssertEqual(1, realm.objects(SwiftObject).count)
            realm.add(defaultRealmObject)
            XCTAssertEqual(1, realm.objects(SwiftObject).count)
        }
        XCTAssertEqual(1, realm.objects(SwiftObject).count)

        let testRealm = realmWithTestPath()
        testRealm.write {
            self.assertThrows(_ = testRealm.add(defaultRealmObject))
        }
    }

    func testAddWithUpdateSingleObject() {
        let realm = try! Realm()
        XCTAssertEqual(0, realm.objects(SwiftPrimaryStringObject).count)
        var defaultRealmObject: SwiftPrimaryStringObject!
        realm.write {
            defaultRealmObject = SwiftPrimaryStringObject()
            realm.add(defaultRealmObject, update: true)
            XCTAssertEqual(1, realm.objects(SwiftPrimaryStringObject).count)
            realm.add(SwiftPrimaryStringObject(), update: true)
            XCTAssertEqual(1, realm.objects(SwiftPrimaryStringObject).count)
        }
        XCTAssertEqual(1, realm.objects(SwiftPrimaryStringObject).count)

        let testRealm = realmWithTestPath()
        testRealm.write {
            self.assertThrows(_ = testRealm.add(defaultRealmObject, update: true))
        }
    }

    func testAddMultipleObjects() {
        let realm = try! Realm()
        assertThrows(_ = realm.add([SwiftObject(), SwiftObject()]))
        XCTAssertEqual(0, realm.objects(SwiftObject).count)
        realm.write {
            let objs = [SwiftObject(), SwiftObject()]
            realm.add(objs)
            XCTAssertEqual(2, realm.objects(SwiftObject).count)
        }
        XCTAssertEqual(2, realm.objects(SwiftObject).count)

        let testRealm = realmWithTestPath()
        testRealm.write {
            self.assertThrows(_ = testRealm.add(realm.objects(SwiftObject)))
        }
    }

    func testAddWithUpdateMultipleObjects() {
        let realm = try! Realm()
        XCTAssertEqual(0, realm.objects(SwiftPrimaryStringObject).count)
        realm.write {
            let objs = [SwiftPrimaryStringObject(), SwiftPrimaryStringObject()]
            realm.add(objs, update: true)
            XCTAssertEqual(1, realm.objects(SwiftPrimaryStringObject).count)
        }
        XCTAssertEqual(1, realm.objects(SwiftPrimaryStringObject).count)

        let testRealm = realmWithTestPath()
        testRealm.write {
            self.assertThrows(_ = testRealm.add(realm.objects(SwiftPrimaryStringObject), update: true))
        }
    }

    // create() tests are in ObjectCreationTests.swift

    func testDeleteSingleObject() {
        let realm = try! Realm()
        XCTAssertEqual(0, realm.objects(SwiftObject).count)
        assertThrows(_ = realm.delete(SwiftObject()))
        var defaultRealmObject: SwiftObject!
        realm.write {
            defaultRealmObject = SwiftObject()
            self.assertThrows(_ = realm.delete(defaultRealmObject))
            XCTAssertEqual(0, realm.objects(SwiftObject).count)
            realm.add(defaultRealmObject)
            XCTAssertEqual(1, realm.objects(SwiftObject).count)
            realm.delete(defaultRealmObject)
            XCTAssertEqual(0, realm.objects(SwiftObject).count)
        }
        assertThrows(_ = realm.delete(defaultRealmObject))
        XCTAssertEqual(0, realm.objects(SwiftObject).count)

        let testRealm = realmWithTestPath()
        assertThrows(_ = testRealm.delete(defaultRealmObject))
        testRealm.write {
            self.assertThrows(_ = testRealm.delete(defaultRealmObject))
        }
    }

    func testDeleteSequenceOfObjects() {
        let realm = try! Realm()
        XCTAssertEqual(0, realm.objects(SwiftObject).count)
        var objs: [SwiftObject]!
        realm.write {
            objs = [SwiftObject(), SwiftObject()]
            realm.add(objs)
            XCTAssertEqual(2, realm.objects(SwiftObject).count)
            realm.delete(objs)
            XCTAssertEqual(0, realm.objects(SwiftObject).count)
        }
        XCTAssertEqual(0, realm.objects(SwiftObject).count)

        let testRealm = realmWithTestPath()
        assertThrows(_ = testRealm.delete(objs))
        testRealm.write {
            self.assertThrows(_ = testRealm.delete(objs))
        }
    }

    func testDeleteListOfObjects() {
        let realm = try! Realm()
        XCTAssertEqual(0, realm.objects(SwiftCompanyObject).count)
        realm.write {
            let obj = SwiftCompanyObject()
            obj.employees.append(SwiftEmployeeObject())
            realm.add(obj)
            XCTAssertEqual(1, realm.objects(SwiftEmployeeObject).count)
            realm.delete(obj.employees)
            XCTAssertEqual(0, obj.employees.count)
            XCTAssertEqual(0, realm.objects(SwiftEmployeeObject).count)
        }
        XCTAssertEqual(0, realm.objects(SwiftEmployeeObject).count)
    }

    func testDeleteResults() {
        let realm = try! Realm(path: testRealmPath())
        XCTAssertEqual(0, realm.objects(SwiftCompanyObject).count)
        realm.write {
            realm.add(SwiftIntObject(value: [1]))
            realm.add(SwiftIntObject(value: [1]))
            realm.add(SwiftIntObject(value: [2]))
            XCTAssertEqual(3, realm.objects(SwiftIntObject).count)
            realm.delete(realm.objects(SwiftIntObject).filter("intCol = 1"))
            XCTAssertEqual(1, realm.objects(SwiftIntObject).count)
        }
        XCTAssertEqual(1, realm.objects(SwiftIntObject).count)
    }

    func testDeleteAll() {
        let realm = try! Realm()
        realm.write {
            realm.add(SwiftObject())
            XCTAssertEqual(1, realm.objects(SwiftObject).count)
            realm.deleteAll()
            XCTAssertEqual(0, realm.objects(SwiftObject).count)
        }
        XCTAssertEqual(0, realm.objects(SwiftObject).count)
    }

    func testObjects() {
        XCTAssertEqual(0, try! Realm().objects(SwiftStringObject).count)
        XCTAssertEqual(3, try! Realm().objects(SwiftIntObject).count)
        XCTAssertEqual(3, try! Realm().objects(SwiftIntObject).count)
        assertThrows(try! Realm().objects(Object))
    }

    func testObjectForPrimaryKey() {
        let realm = try! Realm()
        realm.write {
            realm.create(SwiftPrimaryStringObject.self, value: ["a", 1])
            realm.create(SwiftPrimaryStringObject.self, value: ["b", 2])
        }

        XCTAssertNotNil(realm.objectForPrimaryKey(SwiftPrimaryStringObject.self, key: "a"))
        XCTAssertNil(realm.objectForPrimaryKey(SwiftPrimaryStringObject.self, key: "z"))
    }

    func testAddNotificationBlock() {
        let realm = try! Realm()
        var notificationCalled = false
        let token = realm.addNotificationBlock { _, realm in
            XCTAssertEqual(realm.path, Realm.defaultPath)
            notificationCalled = true
        }
        XCTAssertFalse(notificationCalled)
        realm.write {}
        XCTAssertTrue(notificationCalled)
        realm.removeNotification(token)
    }

    func testRemoveNotification() {
        let realm = try! Realm()
        var notificationCalled = false
        let token = realm.addNotificationBlock { (notification, realm) -> Void in
            XCTAssertEqual(realm.path, Realm.defaultPath)
            notificationCalled = true
        }
        realm.removeNotification(token)
        realm.write {}
        XCTAssertFalse(notificationCalled)
    }

    func testAutorefresh() {
        let realm = try! Realm()
        XCTAssertTrue(realm.autorefresh, "Autorefresh should default to true")
        realm.autorefresh = false
        XCTAssertFalse(realm.autorefresh)
        realm.autorefresh = true
        XCTAssertTrue(realm.autorefresh)

        // test that autoreresh is applied
        // we have two notifications, one for opening the realm, and a second when performing our transaction
        let notificationFired = expectationWithDescription("notification fired")
        let token = realm.addNotificationBlock { _, realm in
            XCTAssertNotNil(realm, "Realm should not be nil")
            notificationFired.fulfill()
        }

        dispatchSyncNewThread {
            let realm = try! Realm()
            realm.write {
                realm.create(SwiftStringObject.self, value: ["string"])
            }
        }
        waitForExpectationsWithTimeout(1, handler: nil)
        realm.removeNotification(token)

        // get object
        let results = realm.objects(SwiftStringObject)
        XCTAssertEqual(results.count, Int(1), "There should be 1 object of type StringObject")
        XCTAssertEqual(results[0].stringCol, "string", "Value of first column should be 'string'")
    }

    func testRefresh() {
        let realm = try! Realm()
        realm.autorefresh = false

        // test that autoreresh is not applied
        // we have two notifications, one for opening the realm, and a second when performing our transaction
        let notificationFired = expectationWithDescription("notification fired")
        let token = realm.addNotificationBlock { _, realm in
            XCTAssertNotNil(realm, "Realm should not be nil")
            notificationFired.fulfill()
        }

        let results = realm.objects(SwiftStringObject)
        XCTAssertEqual(results.count, Int(0), "There should be 1 object of type StringObject")

        dispatchSyncNewThread {
            try! Realm().write {
                try! Realm().create(SwiftStringObject.self, value: ["string"])
                return
            }
        }
        waitForExpectationsWithTimeout(1, handler: nil)
        realm.removeNotification(token)

        XCTAssertEqual(results.count, Int(0), "There should be 1 object of type StringObject")

        // refresh
        realm.refresh()

        XCTAssertEqual(results.count, Int(1), "There should be 1 object of type StringObject")
        XCTAssertEqual(results[0].stringCol, "string", "Value of first column should be 'string'")
    }

    func testInvalidate() {
        let realm = try! Realm()
        let object = SwiftObject()
        realm.write {
            realm.add(object)
            return
        }
        realm.invalidate()
        XCTAssertEqual(object.invalidated, true)

        realm.write {
            realm.add(SwiftObject())
            return
        }
        XCTAssertEqual(realm.objects(SwiftObject).count, 2)
        XCTAssertEqual(object.invalidated, true)
    }

    func testWriteCopyToPath() {
        let realm = try! Realm()
        realm.write {
            realm.add(SwiftObject())
        }
        let path = ((Realm.defaultPath as NSString).stringByDeletingLastPathComponent as NSString ).stringByAppendingPathComponent("copy.realm")
        do {
            try realm.writeCopyToPath(path)
        } catch {
            XCTFail("writeCopyToPath failed")
        }
        autoreleasepool {
            let copy = try! Realm(path: path)
            XCTAssertEqual(1, copy.objects(SwiftObject).count)
        }
        try! NSFileManager.defaultManager().removeItemAtPath(path)
    }

    func testSetEncryptionKey() {
        Realm.setEncryptionKey(NSMutableData(length: 64))
        Realm.setEncryptionKey(nil, forPath: Realm.defaultPath)
        XCTAssert(true, "setting those keys should not throw")
    }

    func testEquals() {
        let realm = try! Realm()
        XCTAssertTrue(try! realm == Realm())

        let testRealm = realmWithTestPath()
        XCTAssertFalse(realm == testRealm)

        dispatchSyncNewThread {
            let otherThreadRealm = try! Realm()
            XCTAssertFalse(realm == otherThreadRealm)
        }
    }
}
