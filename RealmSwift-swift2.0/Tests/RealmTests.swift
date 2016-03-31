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
#if DEBUG
    @testable import RealmSwift
#else
    import RealmSwift
#endif
import Foundation

class RealmTests: TestCase {
    func testPath() {
        XCTAssertEqual(try! Realm(path: testRealmPath()).path, testRealmPath())
    }

    func testReadOnly() {
        autoreleasepool {
            XCTAssertEqual(try! Realm().readOnly, false)

            try! Realm().write {
                try! Realm().create(SwiftIntObject.self, value: [100])
            }
        }
        let readOnlyRealm = try! Realm(configuration: Realm.Configuration(path: defaultRealmPath(), readOnly: true))
        XCTAssertEqual(true, readOnlyRealm.readOnly)
        XCTAssertEqual(1, readOnlyRealm.objects(SwiftIntObject).count)

        assertThrows(try! Realm(), "Realm has different readOnly settings")
    }

    func testOpeningInvalidPathThrows() {
        assertFails(Error.FileAccess) {
            try Realm(configuration: Realm.Configuration(path: "/dev/null/foo"))
        }
    }

    func testReadOnlyFile() {
        autoreleasepool {
            let realm = try! Realm(path: testRealmPath())
            try! realm.write {
                realm.create(SwiftStringObject.self, value: ["a"])
            }
        }

        let fileManager = NSFileManager.defaultManager()
        try! fileManager.setAttributes([ NSFileImmutable: NSNumber(bool: true) ], ofItemAtPath: testRealmPath())

        // Should not be able to open read-write
        assertFails(Error.Fail) {
            try Realm(path: testRealmPath())
        }

        assertSucceeds {
            let realm = try Realm(configuration: Realm.Configuration(path: self.testRealmPath(), readOnly: true))
            XCTAssertEqual(1, realm.objects(SwiftStringObject).count)
        }

        try! fileManager.setAttributes([ NSFileImmutable: NSNumber(bool: false) ], ofItemAtPath: testRealmPath())
    }

    func testReadOnlyRealmMustExist() {
        assertFails(Error.FileNotFound) {
            try Realm(configuration: Realm.Configuration(path: defaultRealmPath(), readOnly: true))
        }
    }

    func testFilePermissionDenied() {
        autoreleasepool {
            let _ = try! Realm(path: testRealmPath())
        }

        // Make Realm at test path temporarily unreadable
        let fileManager = NSFileManager.defaultManager()
        let permissions = try! fileManager.attributesOfItemAtPath(testRealmPath())[NSFilePosixPermissions] as! NSNumber
        try! fileManager.setAttributes([ NSFilePosixPermissions: NSNumber(int: 0000) ], ofItemAtPath: testRealmPath())

        assertFails(Error.FilePermissionDenied) {
            try Realm(path: testRealmPath())
        }

        try! fileManager.setAttributes([ NSFilePosixPermissions: permissions ], ofItemAtPath: testRealmPath())
    }

    #if DEBUG
    func testFileFormatUpgradeRequiredButDisabled() {
        var config = Realm.Configuration()
        var bundledRealmPath = NSBundle(forClass: RealmTests.self).pathForResource("fileformat-pre-null.realm",
                                                                                   ofType: nil)!
        try! NSFileManager.defaultManager.copyItemAtPath(bundledRealmPath, toPath: config.path)
        config.disableFormatUpgrade = true
        assertFails(Error.FileFormatUpgradeRequired) {
            try Realm(configuration: config)
        }
    }
    #endif

    func testSchema() {
        let schema = try! Realm().schema
        XCTAssert(schema as AnyObject is Schema)
        XCTAssertEqual(1, schema.objectSchema.filter({ $0.className == "SwiftStringObject" }).count)
    }

    func testIsEmpty() {
        let realm = try! Realm()
        XCTAssert(realm.isEmpty, "Realm should be empty on creation.")

        realm.beginWrite()
        realm.create(SwiftStringObject.self, value: ["a"])
        XCTAssertFalse(realm.isEmpty, "Realm should not be empty within a write transaction after adding an object.")
        realm.cancelWrite()

        XCTAssertTrue(realm.isEmpty, "Realm should be empty after canceling a write transaction that added an object.")

        realm.beginWrite()
        realm.create(SwiftStringObject.self, value: ["a"])
        try! realm.commitWrite()
        XCTAssertFalse(realm.isEmpty,
            "Realm should not be empty after committing a write transaction that added an object.")
    }

    func testInit() {
        XCTAssertEqual(try! Realm(path: testRealmPath()).path, testRealmPath())
        assertThrows(try! Realm(path: ""))
    }

    func testInitFailable() {
        autoreleasepool {
            _ = try! Realm()
        }

        NSFileManager.defaultManager().createFileAtPath(defaultRealmPath(),
            contents:"a".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false),
            attributes: nil)

        assertFails(Error.FileAccess) {
            _ = try Realm()
            XCTFail("Realm creation should have failed")
        }
    }

    func testInitInMemory() {
        autoreleasepool {
            let realm = inMemoryRealm("identifier")
            try! realm.write {
                realm.create(SwiftIntObject.self, value: [1])
                return
            }
        }
        let realm = inMemoryRealm("identifier")
        XCTAssertEqual(realm.objects(SwiftIntObject).count, 0)

        try! realm.write {
            realm.create(SwiftIntObject.self, value: [1])
            XCTAssertEqual(realm.objects(SwiftIntObject).count, 1)

            inMemoryRealm("identifier").create(SwiftIntObject.self, value: [1])
            XCTAssertEqual(realm.objects(SwiftIntObject).count, 2)
        }

        let realm2 = inMemoryRealm("identifier2")
        XCTAssertEqual(realm2.objects(SwiftIntObject).count, 0)
    }

    func testInitCustomClassList() {
        let configuration = Realm.Configuration(path: Realm.Configuration.defaultConfiguration.path,
            objectTypes: [SwiftStringObject.self])
        XCTAssert(configuration.objectTypes! is [SwiftStringObject.Type])
        let realm = try! Realm(configuration: configuration)
        XCTAssertEqual(["SwiftStringObject"], realm.schema.objectSchema.map { $0.className })
    }

    func testWrite() {
        try! Realm().write {
            self.assertThrows(try! Realm().beginWrite())
            self.assertThrows(try! Realm().write { })
            try! Realm().create(SwiftStringObject.self, value: ["1"])
            XCTAssertEqual(try! Realm().objects(SwiftStringObject).count, 1)
        }
        XCTAssertEqual(try! Realm().objects(SwiftStringObject).count, 1)
    }

    func testDynamicWrite() {
        try! Realm().write {
            self.assertThrows(try! Realm().beginWrite())
            self.assertThrows(try! Realm().write { })
            try! Realm().dynamicCreate("SwiftStringObject", value: ["1"])
            XCTAssertEqual(try! Realm().objects(SwiftStringObject).count, 1)
        }
        XCTAssertEqual(try! Realm().objects(SwiftStringObject).count, 1)
    }

    func testDynamicWriteSubscripting() {
        try! Realm().beginWrite()
        let object = try! Realm().dynamicCreate("SwiftStringObject", value: ["1"])
        try! Realm().commitWrite()

        XCTAssertNotNil(object, "Dynamic Object Creation Failed")

        let stringVal = object["stringCol"] as! String
        XCTAssertEqual(stringVal, "1", "Object Subscripting Failed")
    }

    func testBeginWrite() {
        try! Realm().beginWrite()
        assertThrows(try! Realm().beginWrite())
        try! Realm().cancelWrite()
        try! Realm().beginWrite()
        try! Realm().create(SwiftStringObject.self, value: ["1"])
        XCTAssertEqual(try! Realm().objects(SwiftStringObject).count, 1)
    }

    func testCommitWrite() {
        try! Realm().beginWrite()
        try! Realm().create(SwiftStringObject.self, value: ["1"])
        try! Realm().commitWrite()
        XCTAssertEqual(try! Realm().objects(SwiftStringObject).count, 1)
        try! Realm().beginWrite()
    }

    func testCancelWrite() {
        assertThrows(try! Realm().cancelWrite())
        try! Realm().beginWrite()
        try! Realm().create(SwiftStringObject.self, value: ["1"])
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
        try! realm.write {
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
        try! realm.write {
            defaultRealmObject = SwiftObject()
            realm.add(defaultRealmObject)
            XCTAssertEqual(1, realm.objects(SwiftObject).count)
            realm.add(defaultRealmObject)
            XCTAssertEqual(1, realm.objects(SwiftObject).count)
        }
        XCTAssertEqual(1, realm.objects(SwiftObject).count)

        let testRealm = realmWithTestPath()
        try! testRealm.write {
            self.assertThrows(_ = testRealm.add(defaultRealmObject))
        }
    }

    func testAddWithUpdateSingleObject() {
        let realm = try! Realm()
        XCTAssertEqual(0, realm.objects(SwiftPrimaryStringObject).count)
        var defaultRealmObject: SwiftPrimaryStringObject!
        try! realm.write {
            defaultRealmObject = SwiftPrimaryStringObject()
            realm.add(defaultRealmObject, update: true)
            XCTAssertEqual(1, realm.objects(SwiftPrimaryStringObject).count)
            realm.add(SwiftPrimaryStringObject(), update: true)
            XCTAssertEqual(1, realm.objects(SwiftPrimaryStringObject).count)
        }
        XCTAssertEqual(1, realm.objects(SwiftPrimaryStringObject).count)

        let testRealm = realmWithTestPath()
        try! testRealm.write {
            self.assertThrows(_ = testRealm.add(defaultRealmObject, update: true))
        }
    }

    func testAddMultipleObjects() {
        let realm = try! Realm()
        assertThrows(_ = realm.add([SwiftObject(), SwiftObject()]))
        XCTAssertEqual(0, realm.objects(SwiftObject).count)
        try! realm.write {
            let objs = [SwiftObject(), SwiftObject()]
            realm.add(objs)
            XCTAssertEqual(2, realm.objects(SwiftObject).count)
        }
        XCTAssertEqual(2, realm.objects(SwiftObject).count)

        let testRealm = realmWithTestPath()
        try! testRealm.write {
            self.assertThrows(_ = testRealm.add(realm.objects(SwiftObject)))
        }
    }

    func testAddWithUpdateMultipleObjects() {
        let realm = try! Realm()
        XCTAssertEqual(0, realm.objects(SwiftPrimaryStringObject).count)
        try! realm.write {
            let objs = [SwiftPrimaryStringObject(), SwiftPrimaryStringObject()]
            realm.add(objs, update: true)
            XCTAssertEqual(1, realm.objects(SwiftPrimaryStringObject).count)
        }
        XCTAssertEqual(1, realm.objects(SwiftPrimaryStringObject).count)

        let testRealm = realmWithTestPath()
        try! testRealm.write {
            self.assertThrows(_ = testRealm.add(realm.objects(SwiftPrimaryStringObject), update: true))
        }
    }

    // create() tests are in ObjectCreationTests.swift

    func testDeleteSingleObject() {
        let realm = try! Realm()
        XCTAssertEqual(0, realm.objects(SwiftObject).count)
        assertThrows(_ = realm.delete(SwiftObject()))
        var defaultRealmObject: SwiftObject!
        try! realm.write {
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
        try! testRealm.write {
            self.assertThrows(_ = testRealm.delete(defaultRealmObject))
        }
    }

    func testDeleteSequenceOfObjects() {
        let realm = try! Realm()
        XCTAssertEqual(0, realm.objects(SwiftObject).count)
        var objs: [SwiftObject]!
        try! realm.write {
            objs = [SwiftObject(), SwiftObject()]
            realm.add(objs)
            XCTAssertEqual(2, realm.objects(SwiftObject).count)
            realm.delete(objs)
            XCTAssertEqual(0, realm.objects(SwiftObject).count)
        }
        XCTAssertEqual(0, realm.objects(SwiftObject).count)

        let testRealm = realmWithTestPath()
        assertThrows(_ = testRealm.delete(objs))
        try! testRealm.write {
            self.assertThrows(_ = testRealm.delete(objs))
        }
    }

    func testDeleteListOfObjects() {
        let realm = try! Realm()
        XCTAssertEqual(0, realm.objects(SwiftCompanyObject).count)
        try! realm.write {
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
        try! realm.write {
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
        try! realm.write {
            realm.add(SwiftObject())
            XCTAssertEqual(1, realm.objects(SwiftObject).count)
            realm.deleteAll()
            XCTAssertEqual(0, realm.objects(SwiftObject).count)
        }
        XCTAssertEqual(0, realm.objects(SwiftObject).count)
    }

    func testObjects() {
        try! Realm().write {
            try! Realm().create(SwiftIntObject.self, value: [100])
            try! Realm().create(SwiftIntObject.self, value: [200])
            try! Realm().create(SwiftIntObject.self, value: [300])
        }

        XCTAssertEqual(0, try! Realm().objects(SwiftStringObject).count)
        XCTAssertEqual(3, try! Realm().objects(SwiftIntObject).count)
        assertThrows(try! Realm().objects(Object))
    }

    func testDynamicObjects() {
        try! Realm().write {
            try! Realm().create(SwiftIntObject.self, value: [100])
            try! Realm().create(SwiftIntObject.self, value: [200])
            try! Realm().create(SwiftIntObject.self, value: [300])
        }

        XCTAssertEqual(0, try! Realm().dynamicObjects("SwiftStringObject").count)
        XCTAssertEqual(3, try! Realm().dynamicObjects("SwiftIntObject").count)
        assertThrows(try! Realm().dynamicObjects("Object"))
    }

    func testDynamicObjectProperties() {
        try! Realm().write {
            try! Realm().create(SwiftObject)
        }

        let object = try! Realm().dynamicObjects("SwiftObject")[0]
        let dictionary = SwiftObject.defaultValues()

        XCTAssertEqual(object["boolCol"] as? NSNumber, dictionary["boolCol"] as! NSNumber?)
        XCTAssertEqual(object["intCol"] as? NSNumber, dictionary["intCol"] as! NSNumber?)
        XCTAssertEqual(object["floatCol"] as? NSNumber, dictionary["floatCol"] as! Float?)
        XCTAssertEqual(object["doubleCol"] as? NSNumber, dictionary["doubleCol"] as! Double?)
        XCTAssertEqual(object["stringCol"] as! String?, dictionary["stringCol"] as! String?)
        XCTAssertEqual(object["binaryCol"] as! NSData?, dictionary["binaryCol"] as! NSData?)
        XCTAssertEqual(object["dateCol"] as! NSDate?, dictionary["dateCol"] as! NSDate?)
        XCTAssertEqual(object["objectCol"]?.boolCol, false)
    }

    func testDynamicObjectOptionalProperties() {
        try! Realm().write {
            try! Realm().create(SwiftOptionalDefaultValuesObject)
        }

        let object = try! Realm().dynamicObjects("SwiftOptionalDefaultValuesObject")[0]
        let dictionary = SwiftOptionalDefaultValuesObject.defaultValues()

        XCTAssertEqual(object["optIntCol"] as? NSNumber, dictionary["optIntCol"] as! NSNumber?)
        XCTAssertEqual(object["optInt8Col"] as? NSNumber, dictionary["optInt8Col"] as! NSNumber?)
        XCTAssertEqual(object["optInt16Col"] as? NSNumber, dictionary["optInt16Col"] as! NSNumber?)
        XCTAssertEqual(object["optInt32Col"] as? NSNumber, dictionary["optInt32Col"] as! NSNumber?)
        XCTAssertEqual(object["optInt64Col"] as? NSNumber, dictionary["optInt64Col"] as! NSNumber?)
        XCTAssertEqual(object["optFloatCol"] as? NSNumber, dictionary["optFloatCol"] as! Float?)
        XCTAssertEqual(object["optDoubleCol"] as? NSNumber, dictionary["optDoubleCol"] as! Double?)
        XCTAssertEqual(object["optStringCol"] as! String?, dictionary["optStringCol"] as! String?)
        XCTAssertEqual(object["optNSStringCol"] as! String?, dictionary["optNSStringCol"] as! String?)
        XCTAssertEqual(object["optBinaryCol"] as! NSData?, dictionary["optBinaryCol"] as! NSData?)
        XCTAssertEqual(object["optDateCol"] as! NSDate?, dictionary["optDateCol"] as! NSDate?)
        XCTAssertEqual(object["optObjectCol"]?.boolCol, true)
    }

    func testObjectForPrimaryKey() {
        let realm = try! Realm()
        try! realm.write {
            realm.create(SwiftPrimaryStringObject.self, value: ["a", 1])
            realm.create(SwiftPrimaryStringObject.self, value: ["b", 2])
        }

        XCTAssertNotNil(realm.objectForPrimaryKey(SwiftPrimaryStringObject.self, key: "a"))

        // When this is directly inside the XCTAssertNil, it fails for some reason
        let missingObject = realm.objectForPrimaryKey(SwiftPrimaryStringObject.self, key: "z")
        XCTAssertNil(missingObject)
    }

    func testDynamicObjectForPrimaryKey() {
        let realm = try! Realm()
        try! realm.write {
            realm.create(SwiftPrimaryStringObject.self, value: ["a", 1])
            realm.create(SwiftPrimaryStringObject.self, value: ["b", 2])
        }

        XCTAssertNotNil(realm.dynamicObjectForPrimaryKey("SwiftPrimaryStringObject", key: "a"))
        XCTAssertNil(realm.dynamicObjectForPrimaryKey("SwiftPrimaryStringObject", key: "z"))
    }

    func testDynamicObjectForPrimaryKeySubscripting() {
        let realm = try! Realm()
        try! realm.write {
            realm.create(SwiftPrimaryStringObject.self, value: ["a", 1])
        }

        let object = realm.dynamicObjectForPrimaryKey("SwiftPrimaryStringObject", key: "a")

        let stringVal = object!["stringCol"] as! String

        XCTAssertEqual(stringVal, "a", "Object Subscripting Failed!")
    }

    func testAddNotificationBlock() {
        let realm = try! Realm()
        var notificationCalled = false
        let token = realm.addNotificationBlock { _, realm in
            XCTAssertEqual(realm.path, self.defaultRealmPath())
            notificationCalled = true
        }
        XCTAssertFalse(notificationCalled)
        try! realm.write {}
        XCTAssertTrue(notificationCalled)
        token.stop()
    }

    func testRemoveNotification() {
        let realm = try! Realm()
        var notificationCalled = false
        let token = realm.addNotificationBlock { (notification, realm) -> Void in
            XCTAssertEqual(realm.path, self.defaultRealmPath())
            notificationCalled = true
        }
        token.stop()
        try! realm.write {}
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
            try! realm.write {
                realm.create(SwiftStringObject.self, value: ["string"])
            }
        }
        waitForExpectationsWithTimeout(1, handler: nil)
        token.stop()

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
        token.stop()

        XCTAssertEqual(results.count, Int(0), "There should be 1 object of type StringObject")

        // refresh
        realm.refresh()

        XCTAssertEqual(results.count, Int(1), "There should be 1 object of type StringObject")
        XCTAssertEqual(results[0].stringCol, "string", "Value of first column should be 'string'")
    }

    func testInvalidate() {
        let realm = try! Realm()
        let object = SwiftObject()
        try! realm.write {
            realm.add(object)
            return
        }
        realm.invalidate()
        XCTAssertEqual(object.invalidated, true)

        try! realm.write {
            realm.add(SwiftObject())
            return
        }
        XCTAssertEqual(realm.objects(SwiftObject).count, 2)
        XCTAssertEqual(object.invalidated, true)
    }

    func testWriteCopyToPath() {
        let realm = try! Realm()
        try! realm.write {
            realm.add(SwiftObject())
        }
        let path = ((defaultRealmPath() as NSString).stringByDeletingLastPathComponent as NSString )
            .stringByAppendingPathComponent("copy.realm")
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
