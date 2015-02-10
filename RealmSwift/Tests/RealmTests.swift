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

class RealmTests: TestCase {
    override func setUp() {
        super.setUp()
        realmWithTestPath().write {
            SwiftStringObject.createInRealm(self.realmWithTestPath(), withObject: ["1"])
            SwiftStringObject.createInRealm(self.realmWithTestPath(), withObject: ["2"])
            SwiftStringObject.createInRealm(self.realmWithTestPath(), withObject: ["3"])
        }

        defaultRealm().write {
            SwiftIntObject.createInRealm(defaultRealm(), withObject: [100])
            SwiftIntObject.createInRealm(defaultRealm(), withObject: [200])
            SwiftIntObject.createInRealm(defaultRealm(), withObject: [300])
        }
    }

    func testObjects() {
        XCTAssertEqual(0, objects(SwiftStringObject).count)
        XCTAssertEqual(3, objects(SwiftIntObject).count)
        XCTAssertEqual(3, objects(SwiftIntObject.self, inRealm: defaultRealm()).count)
    }

    func testDefaultRealmPath() {
        let defaultPath =  defaultRealm().path
        XCTAssertEqual(defaultRealmPath, defaultPath)

        let newPath = defaultPath.stringByAppendingPathExtension("new")!
        defaultRealmPath = newPath
        XCTAssertEqual(defaultRealmPath, newPath)

        // we have to clean up
        defaultRealmPath = defaultPath
    }

    func testDefaultRealm() {
        XCTAssertNotNil(defaultRealm())
        XCTAssertTrue(defaultRealm() as AnyObject is Realm)
    }

    func testSetEncryptionKey() {
        setEncryptionKey(NSMutableData(length: 64), forRealmsAtPath: defaultRealmPath)
        setEncryptionKey(nil, forRealmsAtPath: defaultRealmPath)
        XCTAssert(true, "setting those keys should not throw")
    }

    func testPath() {
        let realm = Realm(path: defaultRealmPath)
        XCTAssertEqual(defaultRealmPath, realm.path)
    }

//    func testReadOnly() {
//        var path: String!
//        autoreleasepool {
//            let realm = self.realmWithTestPath()
//            path = realm.path
//            realm.write {
//                _ = SwiftStringObject.createInRealm(realm, withObject: ["a"])
//            }
//        }
//
//        let readOnlyRealm = Realm(path: path, readOnly: true, error: nil)!
//        XCTAssertEqual(true, readOnlyRealm.readOnly)
//        XCTAssertEqual(1, objects(SwiftStringObject.self, inRealm: readOnlyRealm).count)
//    }

    func testSchema() {
        let schema = defaultRealm().schema
        XCTAssert(schema as AnyObject is Schema)
        XCTAssertEqual(1, schema.objectSchema.filter({ $0.className == "SwiftStringObject" }).count)
    }

    func testAutorefresh() {
        let realm = realmWithTestPath()
        XCTAssertTrue(realm.autorefresh, "Autorefresh should default to true")
        realm.autorefresh = false
        XCTAssertFalse(realm.autorefresh)
        realm.autorefresh = true
        XCTAssertTrue(realm.autorefresh)
    }

    func testWriteCopyToPath() {
        let realm = defaultRealm()
        realm.write {
            realm.add(SwiftObject())
        }
        var error: NSError?
        let path = defaultRealmPath.stringByDeletingLastPathComponent.stringByAppendingPathComponent("copy.realm")
        XCTAssertTrue(realm.writeCopyToPath(path, error: &error))
        XCTAssertNil(error)
        autoreleasepool {
            let copy = Realm(path: path)
            XCTAssertEqual(1, objects(SwiftObject.self, inRealm: copy).count)
        }
        NSFileManager.defaultManager().removeItemAtPath(path, error: nil)
    }

    func testAddSingleObject() {
        let realm = defaultRealm()
        XCTAssertEqual(0, objects(SwiftObject).count)
        realm.write {
            let obj = SwiftObject()
            realm.add(obj)
            XCTAssertEqual(1, objects(SwiftObject).count)
        }
        XCTAssertEqual(1, objects(SwiftObject).count)
    }

    func testAddMultipleObjects() {
        let realm = defaultRealm()
        XCTAssertEqual(0, objects(SwiftObject).count)
        realm.write {
            let objs = [SwiftObject(), SwiftObject()]
            realm.add(objs)
            XCTAssertEqual(2, objects(SwiftObject).count)
        }
        XCTAssertEqual(2, objects(SwiftObject).count)
    }

    func testAddOrUpdateSingleObject() {
        let realm = defaultRealm()
        XCTAssertEqual(0, objects(SwiftPrimaryStringObject).count)
        realm.write {
            let obj = SwiftPrimaryStringObject()
            realm.addOrUpdate(obj)
            XCTAssertEqual(1, objects(SwiftPrimaryStringObject).count)
        }
        XCTAssertEqual(1, objects(SwiftPrimaryStringObject).count)
    }

    func testAddOrUpdateMultipleObjects() {
        let realm = defaultRealm()
        XCTAssertEqual(0, objects(SwiftPrimaryStringObject).count)
        realm.write {
            let objs = [SwiftPrimaryStringObject(), SwiftPrimaryStringObject()]
            realm.addOrUpdate(objs)
            XCTAssertEqual(1, objects(SwiftPrimaryStringObject).count)
        }
        XCTAssertEqual(1, objects(SwiftPrimaryStringObject).count)
    }

    func testDeleteSingleObject() {
        let realm = defaultRealm()
        XCTAssertEqual(0, objects(SwiftObject).count)
        realm.write {
            let obj = SwiftObject()
            realm.add(obj)
            XCTAssertEqual(1, objects(SwiftObject).count)
            realm.delete(obj)
            XCTAssertEqual(0, objects(SwiftObject).count)
        }
        XCTAssertEqual(0, objects(SwiftObject).count)
    }

    func testDeleteListOfObjects() {
        let realm = defaultRealm()
        XCTAssertEqual(0, objects(SwiftCompanyObject).count)
        realm.write {
            let obj = SwiftCompanyObject()
            obj.employees.append(SwiftEmployeeObject())
            realm.add(obj)
            XCTAssertEqual(1, objects(SwiftEmployeeObject).count)
            realm.delete(obj.employees)
            XCTAssertEqual(0, objects(SwiftEmployeeObject).count)
        }
        XCTAssertEqual(0, objects(SwiftEmployeeObject).count)
    }

    func testDeleteSequenceOfObjects() {
        let realm = defaultRealm()
        XCTAssertEqual(0, objects(SwiftObject).count)
        realm.write {
            let objs = [SwiftObject(), SwiftObject()]
            realm.add(objs)
            XCTAssertEqual(2, objects(SwiftObject).count)
            realm.delete(objs)
            XCTAssertEqual(0, objects(SwiftObject).count)
        }
        XCTAssertEqual(0, objects(SwiftObject).count)
    }

    func testDeleteAll() {
        let realm = defaultRealm()
        realm.write {
            realm.add(SwiftObject())
            XCTAssertEqual(1, objects(SwiftObject).count)
            realm.deleteAll()
            XCTAssertEqual(0, objects(SwiftObject).count)
        }
        XCTAssertEqual(0, objects(SwiftObject).count)
    }

    func testAddNotificationBlock() {
        let realm = defaultRealm()
        var notificationCalled = false
        let token = realm.addNotificationBlock { (notification, realm) -> Void in
            XCTAssertEqual(realm.path, defaultRealmPath)
            notificationCalled = true
        }
        XCTAssertFalse(notificationCalled)
        realm.write {}
        XCTAssertTrue(notificationCalled)
    }

    func testRemoveNotification() {
        let realm = defaultRealm()
        var notificationCalled = false
        let token = realm.addNotificationBlock { (notification, realm) -> Void in
            XCTAssertEqual(realm.path, defaultRealmPath)
            notificationCalled = true
        }
        realm.removeNotification(token)
        realm.write {}
        XCTAssertFalse(notificationCalled)
    }
}
