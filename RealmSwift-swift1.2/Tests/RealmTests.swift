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
    func testPath() {
        XCTAssertEqual(testRealmPath(), realmWithTestPath().path)
    }

    func testReadOnly() {
        autoreleasepool {
            XCTAssertEqual(Realm().readOnly, false)
            Realm().write {
                Realm().create(SwiftIntObject.self, value: [100])
            }
        }

        let readOnlyRealm = Realm(configuration: Realm.Configuration(path: defaultRealmPath(), readOnly: true))!
        XCTAssertEqual(true, readOnlyRealm.readOnly)
        XCTAssertEqual(1, readOnlyRealm.objects(SwiftIntObject).count)

        assertThrows(Realm(), "Realm has different readOnly settings")
    }

    func testSchema() {
        let schema = Realm().schema
        XCTAssert(schema as AnyObject is Schema)
        XCTAssertEqual(1, schema.objectSchema.filter({ $0.className == "SwiftStringObject" }).count)
    }

    func testIsEmpty() {
        let realm = Realm()
        XCTAssert(realm.isEmpty, "Realm should be empty on creation.")

        realm.beginWrite()
        realm.create(SwiftStringObject.self, value: ["a"])
        XCTAssertFalse(realm.isEmpty, "Realm should not be empty within a write transaction after adding an object.")
        realm.cancelWrite()

        XCTAssertTrue(realm.isEmpty, "Realm should be empty after canceling a write transaction that added an object.")

        realm.beginWrite()
        realm.create(SwiftStringObject.self, value: ["a"])
        realm.commitWrite()
        XCTAssertFalse(realm.isEmpty, "Realm should not be empty after committing a write transaction that added an object.")
    }

    func testInit() {
        XCTAssertEqual(Realm(path: testRealmPath()).path, testRealmPath())
        assertThrows(Realm(path: ""))
    }

    func testInitFailable() {
        var error: NSError?
        autoreleasepool {
            Realm()
            XCTAssertNil(error)
        }

        NSFileManager.defaultManager().createFileAtPath(defaultRealmPath(),
            contents: "a".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false),
            attributes: nil)
        XCTAssertNil(Realm(configuration: Realm.Configuration.defaultConfiguration, error: &error), "Should not throw with error")
        XCTAssertNotNil(error)

        assertThrows(Realm(configuration: Realm.Configuration.defaultConfiguration, error: nil))
        assertThrows(Realm(configuration: Realm.Configuration.defaultConfiguration))
    }

    func testInitInMemory() {
        autoreleasepool {
            var realm = inMemoryRealm("identifier")
            realm.write {
                realm.create(SwiftIntObject.self, value: [1])
                return
            }
        }
        var realm = inMemoryRealm("identifier")
        XCTAssertEqual(realm.objects(SwiftIntObject).count, 0)

        realm.write {
            realm.create(SwiftIntObject.self, value: [1])
            XCTAssertEqual(realm.objects(SwiftIntObject).count, 1)

            inMemoryRealm("identifier").create(SwiftIntObject.self, value: [1])
            XCTAssertEqual(realm.objects(SwiftIntObject).count, 2)
        }

        var realm2 = inMemoryRealm("identifier2")
        XCTAssertEqual(realm2.objects(SwiftIntObject).count, 0)
    }

    func testInitCustomClassList() {
        let configuration = Realm.Configuration(path: Realm.Configuration.defaultConfiguration.path, objectTypes: [SwiftStringObject.self])
        let realm = Realm(configuration: configuration)!
        XCTAssertEqual(["SwiftStringObject"], realm.schema.objectSchema.map { $0.className })
    }

    func testWrite() {
        Realm().write {
            self.assertThrows(Realm().beginWrite())
            self.assertThrows(Realm().write { })
            Realm().create(SwiftStringObject.self, value: ["1"])
            XCTAssertEqual(Realm().objects(SwiftStringObject).count, 1)
        }
        XCTAssertEqual(Realm().objects(SwiftStringObject).count, 1)
    }

    func testDynamicWrite() {
        Realm().write {
            self.assertThrows(Realm().beginWrite())
            self.assertThrows(Realm().write { })
            Realm().dynamicCreate("SwiftStringObject", value: ["1"])
            XCTAssertEqual(Realm().objects(SwiftStringObject).count, 1)
        }
        XCTAssertEqual(Realm().objects(SwiftStringObject).count, 1)
    }

    func testDynamicWriteSubscripting() {
        Realm().beginWrite()
        let object = Realm().dynamicCreate("SwiftStringObject", value: ["1"])
        Realm().commitWrite()

        XCTAssertNotNil(object, "Dynamic Object Creation Failed")

        let stringVal = object["stringCol"] as! String
        XCTAssertEqual(stringVal, "1", "Object Subscripting Failed")
    }

    func testBeginWrite() {
        Realm().beginWrite()
        assertThrows(Realm().beginWrite())
        Realm().cancelWrite()
        Realm().beginWrite()
        Realm().create(SwiftStringObject.self, value: ["1"])
        XCTAssertEqual(Realm().objects(SwiftStringObject).count, 1)
    }

    func testCommitWrite() {
        Realm().beginWrite()
        Realm().create(SwiftStringObject.self, value: ["1"])
        Realm().commitWrite()
        XCTAssertEqual(Realm().objects(SwiftStringObject).count, 1)
        Realm().beginWrite()
    }

    func testCancelWrite() {
        assertThrows(Realm().cancelWrite())
        Realm().beginWrite()
        Realm().create(SwiftStringObject.self, value: ["1"])
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
        Realm().write {
            Realm().create(SwiftIntObject.self, value: [100])
            Realm().create(SwiftIntObject.self, value: [200])
            Realm().create(SwiftIntObject.self, value: [300])
        }

        XCTAssertEqual(0, Realm().objects(SwiftStringObject).count)
        XCTAssertEqual(3, Realm().objects(SwiftIntObject).count)
        XCTAssertEqual(3, Realm().objects(SwiftIntObject).count)
        assertThrows(Realm().objects(Object))
    }

    func testDynamicObjects() {
        Realm().write {
            Realm().create(SwiftIntObject.self, value: [100])
            Realm().create(SwiftIntObject.self, value: [200])
            Realm().create(SwiftIntObject.self, value: [300])
        }

        XCTAssertEqual(0, Realm().dynamicObjects("SwiftStringObject").count)
        XCTAssertEqual(3, Realm().dynamicObjects("SwiftIntObject").count)
        assertThrows(Realm().dynamicObjects("Object"))
    }

    func testDynamicObjectProperties() {
        Realm().write {
            Realm().create(SwiftObject)
        }

        let object = Realm().dynamicObjects("SwiftObject")[0]
        let dictionary = SwiftObject.defaultValues()

        XCTAssertEqual(object["boolCol"] as? NSNumber, dictionary["boolCol"] as! NSNumber?)
        XCTAssertEqual(object["intCol"] as? NSNumber, dictionary["intCol"] as! NSNumber?)
        XCTAssertEqual(object["floatCol"] as? NSNumber, dictionary["floatCol"] as! Float?)
        XCTAssertEqual(object["doubleCol"] as? NSNumber, dictionary["doubleCol"] as! Double?)
        XCTAssertEqual(object["stringCol"] as! String?, dictionary["stringCol"] as! String?)
        XCTAssertEqual(object["binaryCol"] as! NSData?, (dictionary["binaryCol"] as! NSData?))
        XCTAssertEqual(object["dateCol"] as! NSDate?, (dictionary["dateCol"] as! NSDate?))
        XCTAssertEqual(object["objectCol"]?.boolCol, false)
    }

    func testDynamicObjectOptionalProperties() {
        Realm().write {
            Realm().create(SwiftOptionalDefaultValuesObject)
        }

        let object = Realm().dynamicObjects("SwiftOptionalDefaultValuesObject")[0]
        let dictionary = SwiftOptionalDefaultValuesObject.defaultValues()

        XCTAssertEqual(object["optIntCol"] as? NSNumber, dictionary["optIntCol"] as? NSNumber)
        XCTAssertEqual(object["optInt8Col"] as? NSNumber, dictionary["optInt8Col"] as? NSNumber)
        XCTAssertEqual(object["optInt16Col"] as? NSNumber, dictionary["optInt16Col"] as? NSNumber)
        XCTAssertEqual(object["optInt32Col"] as? NSNumber, dictionary["optInt32Col"] as? NSNumber)
        XCTAssertEqual(object["optInt64Col"] as? NSNumber, dictionary["optInt64Col"] as? NSNumber)
        XCTAssertEqual(object["optFloatCol"] as? NSNumber, dictionary["optFloatCol"] as? NSNumber)
        XCTAssertEqual(object["optDoubleCol"] as? NSNumber, dictionary["optDoubleCol"] as? NSNumber)
        XCTAssertEqual(object["optStringCol"] as! String?, dictionary["optStringCol"] as! String?)
        XCTAssertEqual(object["optNSStringCol"] as! String?, (dictionary["optNSStringCol"] as! String?))
        XCTAssertEqual(object["optBinaryCol"] as! NSData?, (dictionary["optBinaryCol"] as! NSData?))
        XCTAssertEqual(object["optDateCol"] as! NSDate?, (dictionary["optDateCol"] as! NSDate?))
        XCTAssertEqual(object["optObjectCol"]?.boolCol, true)
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

    func testDynamicObjectForPrimaryKey() {
        let realm = Realm()
        realm.write {
            realm.create(SwiftPrimaryStringObject.self, value: ["a", 1])
            realm.create(SwiftPrimaryStringObject.self, value: ["b", 2])
        }

        XCTAssertNotNil(realm.dynamicObjectForPrimaryKey("SwiftPrimaryStringObject", key: "a"))
        XCTAssertNil(realm.dynamicObjectForPrimaryKey("SwiftPrimaryStringObject", key: "z"))
    }

    func testDynamicObjectForPrimaryKeySubscripting() {
        let realm = Realm()
        realm.write {
            realm.create(SwiftPrimaryStringObject.self, value: ["a", 1])
        }

        let object = realm.dynamicObjectForPrimaryKey("SwiftPrimaryStringObject", key: "a")

        let stringVal = object!["stringCol"] as! String

        XCTAssertEqual(stringVal, "a", "Object Subscripting Failed!")
    }

    func testAddNotificationBlock() {
        let realm = Realm()
        var notificationCalled = false
        let token = realm.addNotificationBlock { (notification, realm) -> Void in
            XCTAssertEqual(realm.path, self.defaultRealmPath())
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
            XCTAssertEqual(realm.path, self.defaultRealmPath())
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

        dispatchSyncNewThread {
            Realm().write {
                Realm().create(SwiftStringObject.self, value: ["string"])
            }
        }
        waitForExpectationsWithTimeout(1, handler: nil)
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

        dispatchSyncNewThread {
            Realm().write {
                Realm().create(SwiftStringObject.self, value: ["string"])
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
        let path = defaultRealmPath().stringByDeletingLastPathComponent.stringByAppendingPathComponent("copy.realm")
        XCTAssertNil(realm.writeCopyToPath(path))
        autoreleasepool {
            let copy = Realm(path: path)
            XCTAssertEqual(1, copy.objects(SwiftObject).count)
        }
        NSFileManager.defaultManager().removeItemAtPath(path, error: nil)
    }

    func testEquals() {
        let realm = Realm()
        XCTAssertTrue(realm == Realm())

        let testRealm = realmWithTestPath()
        XCTAssertFalse(realm == testRealm)

        dispatchSyncNewThread {
            let otherThreadRealm = Realm()
            XCTAssertFalse(realm == otherThreadRealm)
        }
    }
}
