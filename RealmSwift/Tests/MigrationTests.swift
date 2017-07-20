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
import RealmSwift
import Realm
import Realm.Dynamic
import Foundation

@discardableResult
private func realmWithSingleClassProperties(_ fileURL: URL, className: String, properties: [AnyObject]) -> RLMRealm {
    let schema = RLMSchema()
    let objectSchema = RLMObjectSchema(className: className, objectClass: MigrationObject.self, properties: properties)
    schema.objectSchema = [objectSchema]
    let config = RLMRealmConfiguration()
    config.fileURL = fileURL
    config.customSchema = schema
    return try! RLMRealm(configuration: config)
}

private func dynamicRealm(_ fileURL: URL) -> RLMRealm {
    let config = RLMRealmConfiguration()
    config.fileURL = fileURL
    config.dynamic = true
    return try! RLMRealm(configuration: config)
}

class MigrationTests: TestCase {

    // MARK: Utility methods

    // create realm at path and test version is 0
    private func createAndTestRealmAtURL(_ fileURL: URL) {
        autoreleasepool {
            _ = try! Realm(fileURL: fileURL)
            return
        }
        XCTAssertEqual(0, try! schemaVersionAtURL(fileURL), "Initial version should be 0")
    }

    // migrate realm at path and ensure migration
    private func migrateAndTestRealm(_ fileURL: URL, shouldRun: Bool = true, schemaVersion: UInt64 = 1,
                                     autoMigration: Bool = false, block: MigrationBlock? = nil) {
        var didRun = false
        let config = Realm.Configuration(fileURL: fileURL, schemaVersion: schemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                if let block = block {
                    block(migration, oldSchemaVersion)
                }
                didRun = true
                return
        })

        if autoMigration {
            autoreleasepool {
                _ = try! Realm(configuration: config)
            }
        } else {
            try! Realm.performMigration(for: config)
        }

        XCTAssertEqual(didRun, shouldRun)
    }

    private func migrateAndTestDefaultRealm(_ schemaVersion: UInt64 = 1, block: @escaping MigrationBlock) {
        migrateAndTestRealm(defaultRealmURL(), schemaVersion: schemaVersion, block: block)
        let config = Realm.Configuration(fileURL: defaultRealmURL(),
                                         schemaVersion: schemaVersion)
        Realm.Configuration.defaultConfiguration = config
    }

    // MARK: Test cases

    func testSetDefaultRealmSchemaVersion() {
        createAndTestRealmAtURL(defaultRealmURL())

        var didRun = false
        let config = Realm.Configuration(fileURL: defaultRealmURL(), schemaVersion: 1,
                                         migrationBlock: { _, _ in didRun = true })
        Realm.Configuration.defaultConfiguration = config

        try! Realm.performMigration()

        XCTAssertEqual(didRun, true)
        XCTAssertEqual(1, try! schemaVersionAtURL(defaultRealmURL()))
    }

    func testSetSchemaVersion() {
        createAndTestRealmAtURL(testRealmURL())
        migrateAndTestRealm(testRealmURL())

        XCTAssertEqual(1, try! schemaVersionAtURL(testRealmURL()))
    }

    func testSchemaVersionAtURL() {
        assertFails(.fail) {
            // Version should throw before Realm creation
            try schemaVersionAtURL(defaultRealmURL())
        }

        _ = try! Realm()
        XCTAssertEqual(0, try! schemaVersionAtURL(defaultRealmURL()),
                       "Initial version should be 0")
        assertFails(.fail) {
            try schemaVersionAtURL(URL(fileURLWithPath: "/dev/null"))
        }
    }

    func testMigrateRealm() {
        createAndTestRealmAtURL(testRealmURL())

        // manually migrate (autoMigration == false)
        migrateAndTestRealm(testRealmURL(), shouldRun: true, autoMigration: false)

        // calling again should be no-op
        migrateAndTestRealm(testRealmURL(), shouldRun: false, autoMigration: false)

        // test auto-migration
        migrateAndTestRealm(testRealmURL(), shouldRun: true, schemaVersion: 2, autoMigration: true)
    }

    func testMigrationProperties() {
        let prop = RLMProperty(name: "stringCol", type: RLMPropertyType.int, objectClassName: nil,
                               linkOriginPropertyName: nil, indexed: false, optional: false)
        _ = autoreleasepool {
            realmWithSingleClassProperties(defaultRealmURL(), className: "SwiftStringObject", properties: [prop])
        }

        migrateAndTestDefaultRealm { migration, _ in
            XCTAssertEqual(migration.oldSchema.objectSchema.count, 1)
            XCTAssertGreaterThan(migration.newSchema.objectSchema.count, 1)
            XCTAssertEqual(migration.oldSchema.objectSchema[0].properties.count, 1)
            XCTAssertEqual(migration.newSchema["SwiftStringObject"]!.properties.count, 1)
            XCTAssertEqual(migration.oldSchema["SwiftStringObject"]!.properties[0].type, PropertyType.int)
            XCTAssertEqual(migration.newSchema["SwiftStringObject"]!["stringCol"]!.type, PropertyType.string)
        }
    }

    func testEnumerate() {
        autoreleasepool {
            _ = try! Realm()
        }

        migrateAndTestDefaultRealm { migration, _ in
            migration.enumerateObjects(ofType: "SwiftStringObject", { _, _ in
                XCTFail("No objects to enumerate")
            })

            migration.enumerateObjects(ofType: "NoSuchClass", { _, _ in }) // shouldn't throw
        }

        autoreleasepool {
            // add object
            try! Realm().write {
                try! Realm().create(SwiftStringObject.self, value: ["string"])
                return
            }
        }

        migrateAndTestDefaultRealm(2) { migration, _ in
            var count = 0
            migration.enumerateObjects(ofType: "SwiftStringObject", { oldObj, newObj in
                XCTAssertEqual(newObj!.objectSchema.className, "SwiftStringObject")
                XCTAssertEqual(oldObj!.objectSchema.className, "SwiftStringObject")
                XCTAssertEqual((newObj!["stringCol"] as! String), "string")
                XCTAssertEqual((oldObj!["stringCol"] as! String), "string")
                self.assertThrows(oldObj!["noSuchCol"] as! String)
                self.assertThrows(newObj!["noSuchCol"] as! String)
                count += 1
            })
            XCTAssertEqual(count, 1)
        }

        autoreleasepool {
            try! Realm().write {
                try! Realm().create(SwiftArrayPropertyObject.self, value: ["string", [["array"]], [[2]]])
            }
        }

        migrateAndTestDefaultRealm(3) { migration, _ in
            migration.enumerateObjects(ofType: "SwiftArrayPropertyObject") { oldObject, newObject in
                XCTAssertTrue(oldObject! as AnyObject is MigrationObject)
                XCTAssertTrue(newObject! as AnyObject is MigrationObject)
                XCTAssertTrue(oldObject!["array"]! is List<MigrationObject>)
                XCTAssertTrue(newObject!["array"]! is List<MigrationObject>)
            }
        }

        autoreleasepool {
            try! Realm().write {
                let soo = SwiftOptionalObject()
                soo.optNSStringCol = "NSString"
                soo.optStringCol = "String"
                soo.optBinaryCol = Data()
                soo.optDateCol = Date()
                soo.optIntCol.value = 1
                soo.optInt8Col.value = 2
                soo.optInt16Col.value = 3
                soo.optInt32Col.value = 4
                soo.optInt64Col.value = 5
                soo.optFloatCol.value = 6.1
                soo.optDoubleCol.value = 7.2
                soo.optBoolCol.value = true
                try! Realm().add(soo)
            }
        }

        migrateAndTestDefaultRealm(4) { migration, _ in
            migration.enumerateObjects(ofType: "SwiftOptionalObject") { oldObject, newObject in
                XCTAssertTrue(oldObject! as AnyObject is MigrationObject)
                XCTAssertTrue(newObject! as AnyObject is MigrationObject)
                XCTAssertTrue(oldObject!["optNSStringCol"]! is NSString)
                XCTAssertTrue(newObject!["optNSStringCol"]! is NSString)
                XCTAssertTrue(oldObject!["optStringCol"]! is String)
                XCTAssertTrue(newObject!["optStringCol"]! is String)
                XCTAssertTrue(oldObject!["optBinaryCol"]! is Data)
                XCTAssertTrue(newObject!["optBinaryCol"]! is Data)
                XCTAssertTrue(oldObject!["optDateCol"]! is Date)
                XCTAssertTrue(newObject!["optDateCol"]! is Date)
                XCTAssertTrue(oldObject!["optIntCol"]! is Int)
                XCTAssertTrue(newObject!["optIntCol"]! is Int)
                XCTAssertTrue(oldObject!["optInt8Col"]! is Int)
                XCTAssertTrue(newObject!["optInt8Col"]! is Int)
                XCTAssertTrue(oldObject!["optInt16Col"]! is Int)
                XCTAssertTrue(newObject!["optInt16Col"]! is Int)
                XCTAssertTrue(oldObject!["optInt32Col"]! is Int)
                XCTAssertTrue(newObject!["optInt32Col"]! is Int)
                XCTAssertTrue(oldObject!["optInt64Col"]! is Int)
                XCTAssertTrue(newObject!["optInt64Col"]! is Int)
                XCTAssertTrue(oldObject!["optFloatCol"]! is Float)
                XCTAssertTrue(newObject!["optFloatCol"]! is Float)
                XCTAssertTrue(oldObject!["optDoubleCol"]! is Double)
                XCTAssertTrue(newObject!["optDoubleCol"]! is Double)
                XCTAssertTrue(oldObject!["optBoolCol"]! is Bool)
                XCTAssertTrue(newObject!["optBoolCol"]! is Bool)
            }
        }
    }

    func testEnumerateObjectsAfterDeleteObjects() {
        autoreleasepool {
            // add object
            try! Realm().write {
                try! Realm().create(SwiftStringObject.self, value: ["1"])
                try! Realm().create(SwiftStringObject.self, value: ["2"])
                try! Realm().create(SwiftStringObject.self, value: ["3"])
                try! Realm().create(SwiftIntObject.self, value: [1])
                try! Realm().create(SwiftIntObject.self, value: [2])
                try! Realm().create(SwiftIntObject.self, value: [3])
                try! Realm().create(SwiftBoolObject.self, value: [true])
                try! Realm().create(SwiftBoolObject.self, value: [false])
                try! Realm().create(SwiftBoolObject.self, value: [true])
            }
        }

        migrateAndTestDefaultRealm(1) { migration, _ in
            var count = 0
            migration.enumerateObjects(ofType: "SwiftStringObject") { oldObj, newObj in
                XCTAssertEqual(newObj!["stringCol"] as! String, oldObj!["stringCol"] as! String)
                if oldObj!["stringCol"] as! String == "2" {
                    migration.delete(newObj!)
                }
            }
            migration.enumerateObjects(ofType: "SwiftStringObject") { oldObj, newObj in
                XCTAssertEqual(newObj!["stringCol"] as! String, oldObj!["stringCol"] as! String)
                count += 1
            }
            XCTAssertEqual(count, 2)

            count = 0
            migration.enumerateObjects(ofType: "SwiftIntObject") { oldObj, newObj in
                XCTAssertEqual(newObj!["intCol"] as! Int, oldObj!["intCol"] as! Int)
                if oldObj!["intCol"] as! Int == 1 {
                    migration.delete(newObj!)
                }
            }
            migration.enumerateObjects(ofType: "SwiftIntObject") { oldObj, newObj in
                XCTAssertEqual(newObj!["intCol"] as! Int, oldObj!["intCol"] as! Int)
                count += 1
            }
            XCTAssertEqual(count, 2)

            migration.enumerateObjects(ofType: "SwiftBoolObject") { oldObj, newObj in
                XCTAssertEqual(newObj!["boolCol"] as! Bool, oldObj!["boolCol"] as! Bool)
                migration.delete(newObj!)
            }
            migration.enumerateObjects(ofType: "SwiftBoolObject") { _, _ in
                XCTFail("This line should not executed since all objects have been deleted.")
            }
        }
    }

    func testEnumerateObjectsAfterDeleteInsertObjects() {
        autoreleasepool {
            // add object
            try! Realm().write {
                try! Realm().create(SwiftStringObject.self, value: ["1"])
                try! Realm().create(SwiftStringObject.self, value: ["2"])
                try! Realm().create(SwiftStringObject.self, value: ["3"])
                try! Realm().create(SwiftIntObject.self, value: [1])
                try! Realm().create(SwiftIntObject.self, value: [2])
                try! Realm().create(SwiftIntObject.self, value: [3])
                try! Realm().create(SwiftBoolObject.self, value: [true])
                try! Realm().create(SwiftBoolObject.self, value: [false])
                try! Realm().create(SwiftBoolObject.self, value: [true])
            }
        }

        migrateAndTestDefaultRealm(1) { migration, _ in
            var count = 0
            migration.enumerateObjects(ofType: "SwiftStringObject") { oldObj, newObj in
                XCTAssertEqual(newObj!["stringCol"] as! String, oldObj!["stringCol"] as! String)
                if oldObj!["stringCol"] as! String == "2" {
                    migration.delete(newObj!)
                    migration.create("SwiftStringObject", value: ["A"])
                }
            }
            migration.enumerateObjects(ofType: "SwiftStringObject") { oldObj, newObj in
                XCTAssertEqual(newObj!["stringCol"] as! String, oldObj!["stringCol"] as! String)
                count += 1
            }
            XCTAssertEqual(count, 2)

            count = 0
            migration.enumerateObjects(ofType: "SwiftIntObject") { oldObj, newObj in
                XCTAssertEqual(newObj!["intCol"] as! Int, oldObj!["intCol"] as! Int)
                if oldObj!["intCol"] as! Int == 1 {
                    migration.delete(newObj!)
                    migration.create("SwiftIntObject", value: [0])
                }
            }
            migration.enumerateObjects(ofType: "SwiftIntObject") { oldObj, newObj in
                XCTAssertEqual(newObj!["intCol"] as! Int, oldObj!["intCol"] as! Int)
                count += 1
            }
            XCTAssertEqual(count, 2)

            migration.enumerateObjects(ofType: "SwiftBoolObject") { oldObj, newObj in
                XCTAssertEqual(newObj!["boolCol"] as! Bool, oldObj!["boolCol"] as! Bool)
                migration.delete(newObj!)
                migration.create("SwiftBoolObject", value: [false])
            }
            migration.enumerateObjects(ofType: "SwiftBoolObject") { _, _ in
                XCTFail("This line should not executed since all objects have been deleted.")
            }
        }
    }

    func testCreate() {
        autoreleasepool {
            _ = try! Realm()
        }

        migrateAndTestDefaultRealm { migration, _ in
            migration.create("SwiftStringObject", value: ["string"])
            migration.create("SwiftStringObject", value: ["stringCol": "string"])
            migration.create("SwiftStringObject")

            self.assertThrows(migration.create("NoSuchObject", value: []))
        }

        let objects = try! Realm().objects(SwiftStringObject.self)
        XCTAssertEqual(objects.count, 3)

        XCTAssertEqual(objects[0].stringCol, "string")
        XCTAssertEqual(objects[1].stringCol, "string")
        XCTAssertEqual(objects[2].stringCol, "")
    }

    func testDelete() {
        autoreleasepool {
            try! Realm().write {
                try! Realm().create(SwiftStringObject.self, value: ["string1"])
                try! Realm().create(SwiftStringObject.self, value: ["string2"])
                return
            }
        }

        migrateAndTestDefaultRealm { migration, _ in
            var deleted = false
            migration.enumerateObjects(ofType: "SwiftStringObject", { _, newObj in
                if deleted == false {
                    migration.delete(newObj!)
                    deleted = true
                }
            })
        }

        XCTAssertEqual(try! Realm().objects(SwiftStringObject.self).count, 1)
    }

    func testDeleteData() {
        autoreleasepool {
            let prop = RLMProperty(name: "id", type: .int, objectClassName: nil,
                                   linkOriginPropertyName: nil, indexed: false, optional: false)
            let realm = realmWithSingleClassProperties(defaultRealmURL(),
                className: "DeletedClass", properties: [prop])
            try! realm.transaction {
                realm.createObject("DeletedClass", withValue: [0])
            }
        }

        migrateAndTestDefaultRealm { migration, oldSchemaVersion in
            XCTAssertEqual(oldSchemaVersion, 0, "Initial schema version should be 0")

            XCTAssertTrue(migration.deleteData(forType: "DeletedClass"))
            XCTAssertFalse(migration.deleteData(forType: "NoSuchClass"))

            migration.create(SwiftStringObject.className(), value: ["migration"])
            XCTAssertTrue(migration.deleteData(forType: SwiftStringObject.className()))
        }

        let realm = dynamicRealm(defaultRealmURL())
        XCTAssertNil(realm.schema.schema(forClassName: "DeletedClass"))
        XCTAssertEqual(0, realm.allObjects("SwiftStringObject").count)
    }

    func testRenameProperty() {
        autoreleasepool {
            let prop = RLMProperty(name: "before_stringCol", type: .string, objectClassName: nil,
                linkOriginPropertyName: nil, indexed: false, optional: false)
            autoreleasepool {
                let realm = realmWithSingleClassProperties(defaultRealmURL(), className: "SwiftStringObject",
                    properties: [prop])
                try! realm.transaction {
                    realm.createObject("SwiftStringObject", withValue: ["a"])
                }
            }

            migrateAndTestDefaultRealm { migration, _ in
                XCTAssertEqual(migration.oldSchema.objectSchema[0].properties.count, 1)
                migration.renameProperty(onType: "SwiftStringObject", from: "before_stringCol",
                                         to: "stringCol")
            }

            let realm = dynamicRealm(defaultRealmURL())
            XCTAssertEqual(realm.schema.schema(forClassName: "SwiftStringObject")!.properties.count, 1)
            XCTAssertEqual(1, realm.allObjects("SwiftStringObject").count)
            XCTAssertEqual("a", (realm.allObjects("SwiftStringObject").firstObject() as! RLMObject?)?["stringCol"] as? String)
        }
    }

    // test getting/setting all property types
    func testMigrationObject() {
        autoreleasepool {
            try! Realm().write {
                let object = SwiftObject()
                object.boolCol = true
                object.objectCol = SwiftBoolObject(value: [true])
                object.arrayCol.append(SwiftBoolObject(value: [false]))
                try! Realm().add(object)
                return
            }
        }

        migrateAndTestDefaultRealm { migration, _ in
            var enumerated = false
            migration.enumerateObjects(ofType: "SwiftObject", { oldObj, newObj in
                XCTAssertEqual((oldObj!["boolCol"] as! Bool), true)
                XCTAssertEqual((newObj!["boolCol"] as! Bool), true)
                XCTAssertEqual((oldObj!["intCol"] as! Int), 123)
                XCTAssertEqual((newObj!["intCol"] as! Int), 123)
                XCTAssertEqual((oldObj!["floatCol"] as! Float), 1.23 as Float)
                XCTAssertEqual((newObj!["floatCol"] as! Float), 1.23 as Float)
                XCTAssertEqual((oldObj!["doubleCol"] as! Double), 12.3 as Double)
                XCTAssertEqual((newObj!["doubleCol"] as! Double), 12.3 as Double)

                let binaryCol = "a".data(using: String.Encoding.utf8)!
                XCTAssertEqual((oldObj!["binaryCol"] as! Data), binaryCol)
                XCTAssertEqual((newObj!["binaryCol"] as! Data), binaryCol)

                let dateCol = Date(timeIntervalSince1970: 1)
                XCTAssertEqual((oldObj!["dateCol"] as! Date), dateCol)
                XCTAssertEqual((newObj!["dateCol"] as! Date), dateCol)

                // FIXME - test that casting to SwiftBoolObject throws
                XCTAssertEqual(((oldObj!["objectCol"] as! MigrationObject)["boolCol"] as! Bool), true)
                XCTAssertEqual(((newObj!["objectCol"] as! MigrationObject)["boolCol"] as! Bool), true)

                XCTAssertEqual((oldObj!["arrayCol"] as! List<MigrationObject>).count, 1)
                XCTAssertEqual(((oldObj!["arrayCol"] as! List<MigrationObject>)[0]["boolCol"] as! Bool), false)
                XCTAssertEqual((newObj!["arrayCol"] as! List<MigrationObject>).count, 1)
                XCTAssertEqual(((newObj!["arrayCol"] as! List<MigrationObject>)[0]["boolCol"] as! Bool), false)

                // edit all values
                newObj!["boolCol"] = false
                newObj!["intCol"] = 1
                newObj!["floatCol"] = 1.0
                newObj!["doubleCol"] = 10.0
                newObj!["binaryCol"] = Data(bytes: "b", count: 1)
                newObj!["dateCol"] = Date(timeIntervalSince1970: 2)

                let falseObj = SwiftBoolObject(value: [false])
                newObj!["objectCol"] = falseObj

                var list = newObj!["arrayCol"] as! List<MigrationObject>
                list[0]["boolCol"] = true
                list.append(newObj!["objectCol"] as! MigrationObject)

                let trueObj = migration.create(SwiftBoolObject.className(), value: [true])
                list.append(trueObj)

                // verify list property
                list = newObj!["arrayCol"] as! List<MigrationObject>
                XCTAssertEqual(list.count, 3)
                XCTAssertEqual((list[0]["boolCol"] as! Bool), true)
                XCTAssertEqual((list[1]["boolCol"] as! Bool), false)
                XCTAssertEqual((list[2]["boolCol"] as! Bool), true)

                self.assertThrows(newObj!.value(forKey: "noSuchKey"))
                self.assertThrows(newObj!.setValue(1, forKey: "noSuchKey"))

                // set it again
                newObj!["arrayCol"] = [falseObj, trueObj]

                enumerated = true
            })
            XCTAssertEqual(enumerated, true)
        }

        // refresh to update realm
        try! Realm().refresh()

        // check edited values
        let object = try! Realm().objects(SwiftObject.self).first!
        XCTAssertEqual(object.boolCol, false)
        XCTAssertEqual(object.intCol, 1)
        XCTAssertEqual(object.floatCol, 1.0 as Float)
        XCTAssertEqual(object.doubleCol, 10.0)
        XCTAssertEqual(object.binaryCol, Data(bytes: "b", count: 1))
        XCTAssertEqual(object.dateCol, Date(timeIntervalSince1970: 2))
        XCTAssertEqual(object.objectCol!.boolCol, false)
        XCTAssertEqual(object.arrayCol.count, 2)
        XCTAssertEqual(object.arrayCol[0].boolCol, false)
        XCTAssertEqual(object.arrayCol[1].boolCol, true)

        // make sure we added new bool objects as object property and in the list
        XCTAssertEqual(try! Realm().objects(SwiftBoolObject.self).count, 4)
    }

    func testFailOnSchemaMismatch() {
        let prop = RLMProperty(name: "name", type: RLMPropertyType.string, objectClassName: nil,
                               linkOriginPropertyName: nil, indexed: false, optional: false)
        _ = autoreleasepool {
            realmWithSingleClassProperties(defaultRealmURL(), className: "SwiftEmployeeObject", properties: [prop])
        }

        let config = Realm.Configuration(fileURL: defaultRealmURL(), objectTypes: [SwiftEmployeeObject.self])
        autoreleasepool {
            assertFails(.schemaMismatch) {
                try Realm(configuration: config)
            }
        }
    }

    func testDeleteRealmIfMigrationNeededWithSetCustomSchema() {
        let prop = RLMProperty(name: "name", type: RLMPropertyType.string, objectClassName: nil,
                               linkOriginPropertyName: nil, indexed: false, optional: false)
        _ = autoreleasepool {
            realmWithSingleClassProperties(defaultRealmURL(), className: "SwiftEmployeeObject", properties: [prop])
        }

        var config = Realm.Configuration(fileURL: defaultRealmURL(), objectTypes: [SwiftEmployeeObject.self])
        config.migrationBlock = { _, _ in
            XCTFail("Migration block should not be called")
        }
        config.deleteRealmIfMigrationNeeded = true

        autoreleasepool {
            assertSucceeds {
                _ = try Realm(configuration: config)
            }
        }
    }

    func testDeleteRealmIfMigrationNeeded() {
        autoreleasepool { _ = try! Realm(configuration: Realm.Configuration(fileURL: defaultRealmURL())) }

        let objectSchema = RLMObjectSchema(forObjectClass: SwiftEmployeeObject.self)
        objectSchema.properties = Array(objectSchema.properties[0..<1])

        let metaClass: AnyClass = objc_getMetaClass("RLMSchema") as! AnyClass
        let imp = imp_implementationWithBlock(unsafeBitCast({ () -> RLMSchema in
            let schema = RLMSchema()
            schema.objectSchema = [objectSchema]
            return schema
        } as @convention(block)() -> (RLMSchema), to: AnyObject.self))

        let originalImp = class_getMethodImplementation(metaClass, #selector(RLMObjectBase.sharedSchema))
        class_replaceMethod(metaClass, #selector(RLMObjectBase.sharedSchema), imp, "@@:")

        autoreleasepool {
            assertFails(.schemaMismatch) {
                try Realm()
            }
        }

        let migrationBlock: MigrationBlock = { _, _ in
            XCTFail("Migration block should not be called")
        }
        let config = Realm.Configuration(fileURL: defaultRealmURL(),
                                         migrationBlock: migrationBlock,
                                         deleteRealmIfMigrationNeeded: true)

        assertSucceeds {
            _ = try Realm(configuration: config)
        }

        class_replaceMethod(metaClass, #selector(RLMObjectBase.sharedSchema), originalImp!, "@@:")
    }
}
