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
            SwiftStringObject.createInRealm(self.realmWithTestPath(), withObject: ["1"])
            SwiftStringObject.createInRealm(self.realmWithTestPath(), withObject: ["2"])
            SwiftStringObject.createInRealm(self.realmWithTestPath(), withObject: ["3"])
        }

        Realm().write {
            SwiftIntObject.createInRealm(Realm(), withObject: [100])
            SwiftIntObject.createInRealm(Realm(), withObject: [200])
            SwiftIntObject.createInRealm(Realm(), withObject: [300])
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
        autoreleasepool({
            Realm(path: Realm.defaultPath, readOnly: false)
            XCTAssertNil(error)
        })

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
        autoreleasepool({
            var realm = Realm(inMemoryIdentifier: "identifier")
            realm.write({
                SwiftIntObject.createInRealm(realm, withObject: [1])
                return
            })
        })
        var realm = Realm(inMemoryIdentifier: "identifier")
        XCTAssertEqual(realm.objects(SwiftIntObject).count, 0)

        realm.write({
            SwiftIntObject.createInRealm(realm, withObject: [1])
            XCTAssertEqual(realm.objects(SwiftIntObject).count, 1)

            SwiftIntObject.createInRealm(Realm(inMemoryIdentifier: "identifier"), withObject: [1])
            XCTAssertEqual(realm.objects(SwiftIntObject).count, 2)
        })

        var realm2 = Realm(inMemoryIdentifier: "identifier2")
        XCTAssertEqual(realm2.objects(SwiftIntObject).count, 0)
    }

//    func testWrite() {
//
//    }

//    func testBeginWrite() {
//    }

//    func testCommitWrite() {
//
//    }

//    func testCancelWrite() {
//
//    }

    func testAddSingleObject() {
        let realm = Realm()
        XCTAssertEqual(0, realm.objects(SwiftObject).count)
        realm.write {
            let obj = SwiftObject()
            realm.add(obj)
            XCTAssertEqual(1, realm.objects(SwiftObject).count)
        }
        XCTAssertEqual(1, realm.objects(SwiftObject).count)
    }

    func testAddMultipleObjects() {
        let realm = Realm()
        XCTAssertEqual(0, realm.objects(SwiftObject).count)
        realm.write {
            let objs = [SwiftObject(), SwiftObject()]
            realm.add(objs)
            XCTAssertEqual(2, realm.objects(SwiftObject).count)
        }
        XCTAssertEqual(2, realm.objects(SwiftObject).count)
    }

    func testAddOrUpdateSingleObject() {
        let realm = Realm()
        XCTAssertEqual(0, realm.objects(SwiftPrimaryStringObject).count)
        realm.write {
            let obj = SwiftPrimaryStringObject()
            realm.addOrUpdate(obj)
            XCTAssertEqual(1, realm.objects(SwiftPrimaryStringObject).count)
        }
        XCTAssertEqual(1, realm.objects(SwiftPrimaryStringObject).count)
    }

    func testAddOrUpdateMultipleObjects() {
        let realm = Realm()
        XCTAssertEqual(0, realm.objects(SwiftPrimaryStringObject).count)
        realm.write {
            let objs = [SwiftPrimaryStringObject(), SwiftPrimaryStringObject()]
            realm.addOrUpdate(objs)
            XCTAssertEqual(1, realm.objects(SwiftPrimaryStringObject).count)
        }
        XCTAssertEqual(1, realm.objects(SwiftPrimaryStringObject).count)
    }

    func testDeleteSingleObject() {
        let realm = Realm()
        XCTAssertEqual(0, realm.objects(SwiftObject).count)
        realm.write {
            let obj = SwiftObject()
            realm.add(obj)
            XCTAssertEqual(1, realm.objects(SwiftObject).count)
            realm.delete(obj)
            XCTAssertEqual(0, realm.objects(SwiftObject).count)
        }
        XCTAssertEqual(0, realm.objects(SwiftObject).count)
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
            XCTAssertEqual(0, realm.objects(SwiftEmployeeObject).count)
        }
        XCTAssertEqual(0, realm.objects(SwiftEmployeeObject).count)
    }

    func testDeleteSequenceOfObjects() {
        let realm = Realm()
        XCTAssertEqual(0, realm.objects(SwiftObject).count)
        realm.write {
            let objs = [SwiftObject(), SwiftObject()]
            realm.add(objs)
            XCTAssertEqual(2, realm.objects(SwiftObject).count)
            realm.delete(objs)
            XCTAssertEqual(0, realm.objects(SwiftObject).count)
        }
        XCTAssertEqual(0, realm.objects(SwiftObject).count)
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
        XCTAssertEqual(3, Realm().objects(SwiftIntObject.self).count)
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
        let realm = realmWithTestPath()
        XCTAssertTrue(realm.autorefresh, "Autorefresh should default to true")
        realm.autorefresh = false
        XCTAssertFalse(realm.autorefresh)
        realm.autorefresh = true
        XCTAssertTrue(realm.autorefresh)
    }

//    func testRefresh() {
//
//    }

//    func testInvalidate() {
//
//    }

    func testWriteCopyToPath() {
        let realm = Realm()
        realm.write {
            realm.add(SwiftObject())
        }
        let path = Realm.defaultPath.stringByDeletingLastPathComponent.stringByAppendingPathComponent("copy.realm")
        XCTAssertNil(realm.writeCopyToPath(path))
        autoreleasepool {
            let copy = Realm(path: path)
            XCTAssertEqual(1, copy.objects(SwiftObject.self).count)
        }
        NSFileManager.defaultManager().removeItemAtPath(path, error: nil)
    }

    func testSetEncryptionKey() {
        Realm.setEncryptionKey(NSMutableData(length: 64))
        Realm.setEncryptionKey(nil, forPath: Realm.defaultPath)
        XCTAssert(true, "setting those keys should not throw")
    }
}
