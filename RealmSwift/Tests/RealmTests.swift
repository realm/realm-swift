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
        realmWithTestPath().write {
            self.realmWithTestPath().create(StringObject.self, value: ["1"])
            self.realmWithTestPath().create(StringObject.self, value: ["2"])
            self.realmWithTestPath().create(StringObject.self, value: ["3"])
        }

        Realm().write {
            Realm().create(IntObject.self, value: [100])
            Realm().create(IntObject.self, value: [200])
            Realm().create(IntObject.self, value: [300])
        }
    }

    func testPath() {
        XCTAssertEqual(Realm.defaultPath, Realm().path)
        XCTAssertEqual(testRealmPath(), realmWithTestPath().path)
    }

    func testReadOnly() {
        autoreleasepool {
            XCTAssertEqual(Realm().readOnly, false)
        }
        let readOnlyRealm = Realm(path: Realm.defaultPath, readOnly: true, error: nil)!
        XCTAssertEqual(true, readOnlyRealm.readOnly)
        XCTAssertEqual(3, readOnlyRealm.objects(IntObject).count)

        assertThrows(Realm(), "Realm has different readOnly settings")
    }

    func testSchema() {
        let schema = Realm().schema
        XCTAssert(schema as AnyObject is Schema)
        XCTAssertEqual(1, schema.objectSchema.filter({ $0.className == "StringObject" }).count)
    }

    func testDefaultPath() {
        let defaultPath =  Realm().path
        XCTAssertEqual(Realm.defaultPath, defaultPath)

        let newPath = defaultPath.stringByAppendingPathExtension("new")!
        Realm.defaultPath = newPath
        XCTAssertEqual(Realm.defaultPath, newPath)
        XCTAssertEqual(Realm().path, Realm.defaultPath)
    }

    func testInit() {
        XCTAssertEqual(Realm().path, Realm.defaultPath)
        XCTAssertEqual(Realm(path: testRealmPath()).path, testRealmPath())
        assertThrows(Realm(path: ""))
    }

    func testInitFailable() {
        var error: NSError?
        autoreleasepool {
            Realm(path: Realm.defaultPath, readOnly: false)
            XCTAssertNil(error)
        }

        NSFileManager.defaultManager().createFileAtPath(Realm.defaultPath,
            contents:"a".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false),
            attributes: nil)
        XCTAssertNil(Realm(path: Realm.defaultPath, readOnly: false, error: &error), "Should not throw with error")
        XCTAssertNotNil(error)

        assertThrows(Realm(path: Realm.defaultPath, readOnly: false, error: nil))
        assertThrows(Realm(path: Realm.defaultPath, readOnly: false))
        assertThrows(Realm(path: Realm.defaultPath, readOnly: false, encryptionKey: "asdf".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false), error: &error))
        assertThrows(Realm(path: "", readOnly: false, error: &error))
    }

    func testInitInMemory() {
        autoreleasepool {
            var realm = Realm(inMemoryIdentifier: "identifier")
            realm.write {
                realm.create(IntObject.self, value: [1])
                return
            }
        }
        var realm = Realm(inMemoryIdentifier: "identifier")
        XCTAssertEqual(realm.objects(IntObject).count, 0)

        realm.write {
            realm.create(IntObject.self, value: [1])
            XCTAssertEqual(realm.objects(IntObject).count, 1)

            Realm(inMemoryIdentifier: "identifier").create(IntObject.self, value: [1])
            XCTAssertEqual(realm.objects(IntObject).count, 2)
        }

        var realm2 = Realm(inMemoryIdentifier: "identifier2")
        XCTAssertEqual(realm2.objects(IntObject).count, 0)
    }

    func testWrite() {
        Realm().write {
            self.assertThrows(Realm().beginWrite())
            self.assertThrows(Realm().write { })
            Realm().create(StringObject.self, value:["1"])
            XCTAssertEqual(Realm().objects(StringObject).count, 1)
        }
        XCTAssertEqual(Realm().objects(StringObject).count, 1)
    }

    func testBeginWrite() {
        Realm().beginWrite()
        assertThrows(Realm().beginWrite())
        Realm().cancelWrite()
        Realm().beginWrite()
        Realm().create(StringObject.self, value:["1"])
        XCTAssertEqual(Realm().objects(StringObject).count, 1)
    }

    func testCommitWrite() {
        Realm().beginWrite()
        Realm().create(StringObject.self, value:["1"])
        Realm().commitWrite()
        XCTAssertEqual(Realm().objects(StringObject).count, 1)
        Realm().beginWrite()
    }

    func testCancelWrite() {
        assertThrows(Realm().cancelWrite())
        Realm().beginWrite()
        Realm().create(StringObject.self, value:["1"])
        Realm().cancelWrite()
        XCTAssertEqual(Realm().objects(StringObject).count, 0)

        Realm().write {
            self.assertThrows(self.realmWithTestPath().cancelWrite())
            let object = Realm().create(StringObject)
            Realm().cancelWrite()
            XCTAssertTrue(object.invalidated)
            XCTAssertEqual(Realm().objects(StringObject).count, 0)
        }
        XCTAssertEqual(Realm().objects(StringObject).count, 0)
    }

    func testAddSingleObject() {
        let realm = Realm()
        assertThrows(realm.add(AllTypesObject()))
        XCTAssertEqual(0, realm.objects(AllTypesObject).count)
        var defaultRealmObject: AllTypesObject!
        realm.write {
            defaultRealmObject = AllTypesObject()
            realm.add(defaultRealmObject)
            XCTAssertEqual(1, realm.objects(AllTypesObject).count)
            realm.add(defaultRealmObject)
            XCTAssertEqual(1, realm.objects(AllTypesObject).count)
        }
        XCTAssertEqual(1, realm.objects(AllTypesObject).count)

        let testRealm = realmWithTestPath()
        testRealm.write {
            self.assertThrows(testRealm.add(defaultRealmObject))
        }
    }

    func testAddWithUpdateSingleObject() {
        let realm = Realm()
        XCTAssertEqual(0, realm.objects(PrimaryStringObject).count)
        var defaultRealmObject: PrimaryStringObject!
        realm.write {
            defaultRealmObject = PrimaryStringObject()
            realm.add(defaultRealmObject, update: true)
            XCTAssertEqual(1, realm.objects(PrimaryStringObject).count)
            realm.add(PrimaryStringObject(), update: true)
            XCTAssertEqual(1, realm.objects(PrimaryStringObject).count)
        }
        XCTAssertEqual(1, realm.objects(PrimaryStringObject).count)

        let testRealm = realmWithTestPath()
        testRealm.write {
            self.assertThrows(testRealm.add(defaultRealmObject, update: true))
        }
    }

    func testAddMultipleObjects() {
        let realm = Realm()
        assertThrows(realm.add([AllTypesObject(), AllTypesObject()]))
        XCTAssertEqual(0, realm.objects(AllTypesObject).count)
        realm.write {
            let objs = [AllTypesObject(), AllTypesObject()]
            realm.add(objs)
            XCTAssertEqual(2, realm.objects(AllTypesObject).count)
        }
        XCTAssertEqual(2, realm.objects(AllTypesObject).count)

        let testRealm = realmWithTestPath()
        testRealm.write {
            self.assertThrows(testRealm.add(realm.objects(AllTypesObject)))
        }
    }

    func testAddWithUpdateMultipleObjects() {
        let realm = Realm()
        XCTAssertEqual(0, realm.objects(PrimaryStringObject).count)
        realm.write {
            let objs = [PrimaryStringObject(), PrimaryStringObject()]
            realm.add(objs, update: true)
            XCTAssertEqual(1, realm.objects(PrimaryStringObject).count)
        }
        XCTAssertEqual(1, realm.objects(PrimaryStringObject).count)

        let testRealm = realmWithTestPath()
        testRealm.write {
            self.assertThrows(testRealm.add(realm.objects(PrimaryStringObject), update: true))
        }
    }

    // create() tests are in ObjectCreationTests.swift

    func testDeleteSingleObject() {
        let realm = Realm()
        XCTAssertEqual(0, realm.objects(AllTypesObject).count)
        assertThrows(realm.delete(AllTypesObject()))
        var defaultRealmObject: AllTypesObject!
        realm.write {
            defaultRealmObject = AllTypesObject()
            self.assertThrows(realm.delete(defaultRealmObject))
            XCTAssertEqual(0, realm.objects(AllTypesObject).count)
            realm.add(defaultRealmObject)
            XCTAssertEqual(1, realm.objects(AllTypesObject).count)
            realm.delete(defaultRealmObject)
            XCTAssertEqual(0, realm.objects(AllTypesObject).count)
        }
        assertThrows(realm.delete(defaultRealmObject))
        XCTAssertEqual(0, realm.objects(AllTypesObject).count)

        let testRealm = realmWithTestPath()
        assertThrows(testRealm.delete(defaultRealmObject))
        testRealm.write {
            self.assertThrows(testRealm.delete(defaultRealmObject))
        }
    }

    func testDeleteSequenceOfObjects() {
        let realm = Realm()
        XCTAssertEqual(0, realm.objects(AllTypesObject).count)
        var objs: [AllTypesObject]!
        realm.write {
            objs = [AllTypesObject(), AllTypesObject()]
            realm.add(objs)
            XCTAssertEqual(2, realm.objects(AllTypesObject).count)
            realm.delete(objs)
            XCTAssertEqual(0, realm.objects(AllTypesObject).count)
        }
        XCTAssertEqual(0, realm.objects(AllTypesObject).count)

        let testRealm = realmWithTestPath()
        assertThrows(testRealm.delete(objs))
        testRealm.write {
            self.assertThrows(testRealm.delete(objs))
        }
    }

    func testDeleteListOfObjects() {
        let realm = Realm()
        XCTAssertEqual(0, realm.objects(CompanyObject).count)
        realm.write {
            let obj = CompanyObject()
            obj.employees.append(EmployeeObject())
            realm.add(obj)
            XCTAssertEqual(1, realm.objects(EmployeeObject).count)
            realm.delete(obj.employees)
            XCTAssertEqual(0, obj.employees.count)
            XCTAssertEqual(0, realm.objects(EmployeeObject).count)
        }
        XCTAssertEqual(0, realm.objects(EmployeeObject).count)
    }

    func testDeleteResults() {
        let realm = Realm(path: testRealmPath())
        XCTAssertEqual(0, realm.objects(CompanyObject).count)
        realm.write {
            realm.add(IntObject(value: [1]))
            realm.add(IntObject(value: [1]))
            realm.add(IntObject(value: [2]))
            XCTAssertEqual(3, realm.objects(IntObject).count)
            realm.delete(realm.objects(IntObject).filter("intCol = 1"))
            XCTAssertEqual(1, realm.objects(IntObject).count)
        }
        XCTAssertEqual(1, realm.objects(IntObject).count)
    }

    func testDeleteAll() {
        let realm = Realm()
        realm.write {
            realm.add(AllTypesObject())
            XCTAssertEqual(1, realm.objects(AllTypesObject).count)
            realm.deleteAll()
            XCTAssertEqual(0, realm.objects(AllTypesObject).count)
        }
        XCTAssertEqual(0, realm.objects(AllTypesObject).count)
    }

    func testObjects() {
        XCTAssertEqual(0, Realm().objects(StringObject).count)
        XCTAssertEqual(3, Realm().objects(IntObject).count)
        XCTAssertEqual(3, Realm().objects(IntObject.self).count)
        assertThrows(Realm().objects(Object))
    }

    func testObjectForPrimaryKey() {
        let realm = Realm()
        realm.write {
            realm.create(PrimaryStringObject.self, value: ["a", 1])
            realm.create(PrimaryStringObject.self, value: ["b", 2])
        }

        XCTAssertNotNil(realm.objectForPrimaryKey(PrimaryStringObject.self, key: "a"))
        XCTAssertNil(realm.objectForPrimaryKey(PrimaryStringObject.self, key: "z"))
    }

    func testAddNotificationBlock() {
        let realm = Realm()
        var notificationCalled = false
        let token = realm.addNotificationBlock { (notification, realm) -> Void in
            XCTAssertEqual(realm.path, Realm.defaultPath)
            notificationCalled = true
        }
        XCTAssertFalse(notificationCalled)
        realm.write {}
        XCTAssertTrue(notificationCalled)
    }

    func testRemoveNotification() {
        let realm = Realm()
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
        XCTAssertTrue(Realm().autorefresh, "Autorefresh should default to true")
        Realm().autorefresh = false
        XCTAssertFalse(Realm().autorefresh)
        Realm().autorefresh = true
        XCTAssertTrue(Realm().autorefresh)

        // test that autoreresh is applied
        // we have two notifications, one for opening the realm, and a second when performing our transaction
        let notificationFired = expectationWithDescription("notification fired")
        let token = Realm().addNotificationBlock { _, realm in
            XCTAssertNotNil(realm, "Realm should not be nil")
            notificationFired.fulfill()
        }

        dispatch_async(dispatch_queue_create("background", nil)) {
            Realm().write {
                Realm().create(StringObject.self, value: ["string"])
                return
            }
        }
        waitForExpectationsWithTimeout(2, handler: nil)
        Realm().removeNotification(token)

        // get object
        let results = Realm().objects(StringObject.self)
        XCTAssertEqual(results.count, Int(1), "There should be 1 object of type StringObject")
        XCTAssertEqual(results[0].stringCol, "string", "Value of first column should be 'string'")
    }

    func testRefresh() {
        let realm = Realm()
        realm.autorefresh = false

        // test that autoreresh is not applied
        // we have two notifications, one for opening the realm, and a second when performing our transaction
        let notificationFired = expectationWithDescription("notification fired")
        let token = realm.addNotificationBlock { _, realm in
            XCTAssertNotNil(realm, "Realm should not be nil")
            notificationFired.fulfill()
        }

        let results = realm.objects(StringObject.self)
        XCTAssertEqual(results.count, Int(0), "There should be 1 object of type StringObject")

        dispatch_async(dispatch_queue_create("background", nil)) {
            Realm().write {
                Realm().create(StringObject.self, value: ["string"])
                return
            }
        }
        waitForExpectationsWithTimeout(2, handler: nil)
        realm.removeNotification(token)

        XCTAssertEqual(results.count, Int(0), "There should be 1 object of type StringObject")

        // refresh 
        realm.refresh()

        XCTAssertEqual(results.count, Int(1), "There should be 1 object of type StringObject")
        XCTAssertEqual(results[0].stringCol, "string", "Value of first column should be 'string'")
    }

    func testInvalidate() {
        let realm = Realm()
        let object = AllTypesObject()
        realm.write {
            realm.add(object)
            return
        }
        realm.invalidate()
        XCTAssertEqual(object.invalidated, true)

        realm.write {
            realm.add(AllTypesObject())
            return
        }
        XCTAssertEqual(realm.objects(AllTypesObject).count, 2)
        XCTAssertEqual(object.invalidated, true)
    }

    func testWriteCopyToPath() {
        let realm = Realm()
        realm.write {
            realm.add(AllTypesObject())
        }
        let path = Realm.defaultPath.stringByDeletingLastPathComponent.stringByAppendingPathComponent("copy.realm")
        XCTAssertNil(realm.writeCopyToPath(path))
        autoreleasepool {
            let copy = Realm(path: path)
            XCTAssertEqual(1, copy.objects(AllTypesObject.self).count)
        }
        NSFileManager.defaultManager().removeItemAtPath(path, error: nil)
    }

    func testSetEncryptionKey() {
        Realm.setEncryptionKey(NSMutableData(length: 64))
        Realm.setEncryptionKey(nil, forPath: Realm.defaultPath)
        XCTAssert(true, "setting those keys should not throw")
    }

    func testEquals() {
        let realm = Realm()
        XCTAssertTrue(realm == Realm())

        let testRealm = realmWithTestPath()
        XCTAssertFalse(realm == testRealm)

        let fired = expectationWithDescription("fired")
        dispatch_async(dispatch_queue_create("background", nil)) {
            let otherThreadRealm = Realm()
            XCTAssertFalse(realm == otherThreadRealm)
            fired.fulfill()
        }
        waitForExpectationsWithTimeout(2, handler: nil)
    }
}
