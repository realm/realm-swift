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

            Realm().write {
                Realm().create(SwiftIntObject.self, value: [100])
                Realm().create(SwiftIntObject.self, value: [200])
                Realm().create(SwiftIntObject.self, value: [300])
            }
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
        XCTAssertEqual(3, readOnlyRealm.objects(SwiftIntObject).count)

        assertThrows(Realm(), "Realm has different readOnly settings")
    }

    func testSchema() {
        let schema = Realm().schema
        XCTAssert(schema as AnyObject is Schema)
        XCTAssertEqual(1, schema.objectSchema.filter({ $0.className == "SwiftStringObject" }).count)
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
                realm.create(SwiftIntObject.self, value: [1])
                return
            }
        }
        var realm = Realm(inMemoryIdentifier: "identifier")
        XCTAssertEqual(realm.objects(SwiftIntObject).count, 0)

        realm.write {
            realm.create(SwiftIntObject.self, value: [1])
            XCTAssertEqual(realm.objects(SwiftIntObject).count, 1)

            Realm(inMemoryIdentifier: "identifier").create(SwiftIntObject.self, value: [1])
            XCTAssertEqual(realm.objects(SwiftIntObject).count, 2)
        }

        var realm2 = Realm(inMemoryIdentifier: "identifier2")
        XCTAssertEqual(realm2.objects(SwiftIntObject).count, 0)
    }

    func testWrite() {
        Realm().write {
            self.assertThrows(Realm().beginWrite())
            self.assertThrows(Realm().write { })
            Realm().create(SwiftStringObject.self, value:["1"])
            XCTAssertEqual(Realm().objects(SwiftStringObject).count, 1)
        }
        XCTAssertEqual(Realm().objects(SwiftStringObject).count, 1)
    }

    func testBeginWrite() {
        Realm().beginWrite()
        assertThrows(Realm().beginWrite())
        Realm().cancelWrite()
        Realm().beginWrite()
        Realm().create(SwiftStringObject.self, value:["1"])
        XCTAssertEqual(Realm().objects(SwiftStringObject).count, 1)
    }

    func testCommitWrite() {
        Realm().beginWrite()
        Realm().create(SwiftStringObject.self, value:["1"])
        Realm().commitWrite()
        XCTAssertEqual(Realm().objects(SwiftStringObject).count, 1)
        Realm().beginWrite()
    }

    func testCancelWrite() {
        assertThrows(Realm().cancelWrite())
        Realm().beginWrite()
        Realm().create(SwiftStringObject.self, value:["1"])
        Realm().cancelWrite()
        XCTAssertEqual(Realm().objects(SwiftStringObject).count, 0)

        Realm().write {
            self.assertThrows(self.realmWithTestPath().cancelWrite())
            let object = Realm().create(SwiftStringObject)
            Realm().cancelWrite()
            XCTAssertTrue(object.invalidated)
            XCTAssertEqual(Realm().objects(SwiftStringObject).count, 0)
        }
        XCTAssertEqual(Realm().objects(SwiftStringObject).count, 0)
    }

    func testInWriteTransaction() {
        let realm = Realm()
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
        let realm = Realm()
        assertThrows(realm.add(SwiftObject()))
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
            self.assertThrows(testRealm.add(defaultRealmObject))
        }
    }

    func testAddWithUpdateSingleObject() {
        let realm = Realm()
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
            self.assertThrows(testRealm.add(defaultRealmObject, update: true))
        }
    }

    func testAddMultipleObjects() {
        let realm = Realm()
        assertThrows(realm.add([SwiftObject(), SwiftObject()]))
        XCTAssertEqual(0, realm.objects(SwiftObject).count)
        realm.write {
            let objs = [SwiftObject(), SwiftObject()]
            realm.add(objs)
            XCTAssertEqual(2, realm.objects(SwiftObject).count)
        }
        XCTAssertEqual(2, realm.objects(SwiftObject).count)

        let testRealm = realmWithTestPath()
        testRealm.write {
            self.assertThrows(testRealm.add(realm.objects(SwiftObject)))
        }
    }

    func testAddWithUpdateMultipleObjects() {
        let realm = Realm()
        XCTAssertEqual(0, realm.objects(SwiftPrimaryStringObject).count)
        realm.write {
            let objs = [SwiftPrimaryStringObject(), SwiftPrimaryStringObject()]
            realm.add(objs, update: true)
            XCTAssertEqual(1, realm.objects(SwiftPrimaryStringObject).count)
        }
        XCTAssertEqual(1, realm.objects(SwiftPrimaryStringObject).count)

        let testRealm = realmWithTestPath()
        testRealm.write {
            self.assertThrows(testRealm.add(realm.objects(SwiftPrimaryStringObject), update: true))
        }
    }

    // create() tests are in ObjectCreationTests.swift

    func testDeleteSingleObject() {
        let realm = Realm()
        XCTAssertEqual(0, realm.objects(SwiftObject).count)
        assertThrows(realm.delete(SwiftObject()))
        var defaultRealmObject: SwiftObject!
        realm.write {
            defaultRealmObject = SwiftObject()
            self.assertThrows(realm.delete(defaultRealmObject))
            XCTAssertEqual(0, realm.objects(SwiftObject).count)
            realm.add(defaultRealmObject)
            XCTAssertEqual(1, realm.objects(SwiftObject).count)
            realm.delete(defaultRealmObject)
            XCTAssertEqual(0, realm.objects(SwiftObject).count)
        }
        assertThrows(realm.delete(defaultRealmObject))
        XCTAssertEqual(0, realm.objects(SwiftObject).count)

        let testRealm = realmWithTestPath()
        assertThrows(testRealm.delete(defaultRealmObject))
        testRealm.write {
            self.assertThrows(testRealm.delete(defaultRealmObject))
        }
    }

    func testDeleteSequenceOfObjects() {
        let realm = Realm()
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
        assertThrows(testRealm.delete(objs))
        testRealm.write {
            self.assertThrows(testRealm.delete(objs))
        }
    }

    func testDeleteListOfObjects() {
        let realm = Realm()
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
        let realm = Realm(path: testRealmPath())
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
        let realm = Realm()
        realm.write {
            realm.add(SwiftObject())
            XCTAssertEqual(1, realm.objects(SwiftObject).count)
            realm.deleteAll()
            XCTAssertEqual(0, realm.objects(SwiftObject).count)
        }
        XCTAssertEqual(0, realm.objects(SwiftObject).count)
    }

    func testObjects() {
        XCTAssertEqual(0, Realm().objects(SwiftStringObject).count)
        XCTAssertEqual(3, Realm().objects(SwiftIntObject).count)
        XCTAssertEqual(3, Realm().objects(SwiftIntObject).count)
        assertThrows(Realm().objects(Object))
    }

    func testObjectForPrimaryKey() {
        let realm = Realm()
        realm.write {
            realm.create(SwiftPrimaryStringObject.self, value: ["a", 1])
            realm.create(SwiftPrimaryStringObject.self, value: ["b", 2])
        }

        XCTAssertNotNil(realm.objectForPrimaryKey(SwiftPrimaryStringObject.self, key: "a"))
        XCTAssertNil(realm.objectForPrimaryKey(SwiftPrimaryStringObject.self, key: "z"))
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
                Realm().create(SwiftStringObject.self, value: ["string"])
                return
            }
        }
        waitForExpectationsWithTimeout(2, handler: nil)
        Realm().removeNotification(token)

        // get object
        let results = Realm().objects(SwiftStringObject)
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

        let results = realm.objects(SwiftStringObject)
        XCTAssertEqual(results.count, Int(0), "There should be 1 object of type StringObject")

        dispatch_async(dispatch_queue_create("background", nil)) {
            Realm().write {
                Realm().create(SwiftStringObject.self, value: ["string"])
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
        let realm = Realm()
        realm.write {
            realm.add(SwiftObject())
        }
        let path = Realm.defaultPath.stringByDeletingLastPathComponent.stringByAppendingPathComponent("copy.realm")
        XCTAssertNil(realm.writeCopyToPath(path))
        autoreleasepool {
            let copy = Realm(path: path)
            XCTAssertEqual(1, copy.objects(SwiftObject).count)
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
