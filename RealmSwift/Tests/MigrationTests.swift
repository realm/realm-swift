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

        do {
            _ = try schemaVersionAtURL(URL(fileURLWithPath: "/dev/null"))
            XCTFail("Expected .filePermissionDenied or .fileAccess, but no error was raised")
        } catch Realm.Error.filePermissionDenied {
            // Success!
        } catch Realm.Error.fileAccess {
            // Success!
        } catch {
            XCTFail("Expected .filePermissionDenied or .fileAccess, got \(error)")
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
                try! Realm().create(SwiftMutableSetPropertyObject.self, value: ["string", [["set"]], [[2]]])
                try! Realm().create(SwiftMapPropertyObject.self, value: ["string", ["key": ["value"]], [:]])
            }
        }

        migrateAndTestDefaultRealm(3) { migration, _ in
            migration.enumerateObjects(ofType: "SwiftArrayPropertyObject") { oldObject, newObject in
                XCTAssertTrue(oldObject! as AnyObject is MigrationObject)
                XCTAssertTrue(newObject! as AnyObject is MigrationObject)
                XCTAssertTrue(oldObject!["array"]! is List<MigrationObject>)
                XCTAssertTrue(newObject!["array"]! is List<MigrationObject>)
            }
            migration.enumerateObjects(ofType: "SwiftMutableSetPropertyObject") { oldObject, newObject in
                XCTAssertTrue(oldObject! as AnyObject is MigrationObject)
                XCTAssertTrue(newObject! as AnyObject is MigrationObject)
                XCTAssertTrue(oldObject!["set"]! is MutableSet<MigrationObject>)
                XCTAssertTrue(newObject!["set"]! is MutableSet<MigrationObject>)
            }
            migration.enumerateObjects(ofType: "SwiftMapPropertyObject") { oldObject, newObject in
                XCTAssertTrue(oldObject! as AnyObject is MigrationObject)
                XCTAssertTrue(newObject! as AnyObject is MigrationObject)
                XCTAssertTrue(oldObject!["map"]! is Map<String, MigrationObject?>)
                XCTAssertTrue(newObject!["map"]! is Map<String, MigrationObject?>)
            }
        }
    }

    func testBasicTypesInEnumerate() {
        autoreleasepool {
            let realm = try! Realm()
            try! realm.write {
                realm.add(SwiftObject())
            }
        }

        migrateAndTestDefaultRealm { migration, _ in
            migration.enumerateObjects(ofType: "SwiftObject") { oldObject, newObject in
                XCTAssertTrue(oldObject!.boolCol is Bool)
                XCTAssertTrue(newObject!.boolCol is Bool)
                XCTAssertTrue(oldObject!.intCol is Int)
                XCTAssertTrue(newObject!.intCol is Int)
                XCTAssertTrue(oldObject!.int8Col is Int)
                XCTAssertTrue(newObject!.int8Col is Int)
                XCTAssertTrue(oldObject!.int16Col is Int)
                XCTAssertTrue(newObject!.int16Col is Int)
                XCTAssertTrue(oldObject!.int32Col is Int)
                XCTAssertTrue(newObject!.int32Col is Int)
                XCTAssertTrue(oldObject!.int64Col is Int)
                XCTAssertTrue(newObject!.int64Col is Int)
                XCTAssertTrue(oldObject!.intEnumCol is Int)
                XCTAssertTrue(newObject!.intEnumCol is Int)
                XCTAssertTrue(oldObject!.floatCol is Float)
                XCTAssertTrue(newObject!.floatCol is Float)
                XCTAssertTrue(oldObject!.doubleCol is Double)
                XCTAssertTrue(newObject!.doubleCol is Double)
                XCTAssertTrue(oldObject!.stringCol is String)
                XCTAssertTrue(newObject!.stringCol is String)
                XCTAssertTrue(oldObject!.binaryCol is Data)
                XCTAssertTrue(newObject!.binaryCol is Data)
                XCTAssertTrue(oldObject!.dateCol is Date)
                XCTAssertTrue(newObject!.dateCol is Date)
                XCTAssertTrue(oldObject!.decimalCol is Decimal128)
                XCTAssertTrue(newObject!.decimalCol is Decimal128)
                XCTAssertTrue(oldObject!.objectIdCol is ObjectId)
                XCTAssertTrue(newObject!.objectIdCol is ObjectId)
                XCTAssertTrue(oldObject!.objectCol is DynamicObject)
                XCTAssertTrue(newObject!.objectCol is DynamicObject)
                XCTAssertTrue(oldObject!.uuidCol is UUID)
                XCTAssertTrue(newObject!.uuidCol is UUID)
                XCTAssertNil(oldObject!.anyCol)
                XCTAssertNil(newObject!.anyCol)
            }
        }
    }

    func testAnyInEnumerate() {
        autoreleasepool {
            let realm = try! Realm()
            try! realm.write {
                realm.add(SwiftObject())
            }
        }

        var version = UInt64(1)
        func write(_ value: @autoclosure () -> AnyRealmValue, test: @escaping (Any?, Any?) -> Void) {
            autoreleasepool {
                let realm = try! Realm()
                try! realm.write {
                    realm.objects(SwiftObject.self).first!.anyCol.value = value()
                }
            }
            migrateAndTestDefaultRealm(version) { migration, _ in
                migration.enumerateObjects(ofType: "SwiftObject") { oldObject, newObject in
                    test(oldObject!.anyCol, newObject!.anyCol)
                }
            }
            version += 1
        }

        write(.int(1)) { oldValue, newValue in
            XCTAssertTrue(oldValue is Int)
            XCTAssertTrue(newValue is Int)
        }
        write(.float(1)) { oldValue, newValue in
            XCTAssertTrue(oldValue is Float)
            XCTAssertTrue(newValue is Float)
        }
        write(.double(1)) { oldValue, newValue in
            XCTAssertTrue(oldValue is Double)
            XCTAssertTrue(newValue is Double)
        }
        write(.double(1)) { oldValue, newValue in
            XCTAssertTrue(oldValue is Double)
            XCTAssertTrue(newValue is Double)
        }
        write(.bool(true)) { oldValue, newValue in
            XCTAssertTrue(oldValue is Bool)
            XCTAssertTrue(newValue is Bool)
        }
        write(.string("")) { oldValue, newValue in
            XCTAssertTrue(oldValue is String)
            XCTAssertTrue(newValue is String)
        }
        write(.data(Data())) { oldValue, newValue in
            XCTAssertTrue(oldValue is Data)
            XCTAssertTrue(newValue is Data)
        }
        write(.date(Date())) { oldValue, newValue in
            XCTAssertTrue(oldValue is Date)
            XCTAssertTrue(newValue is Date)
        }
        write(.objectId(ObjectId())) { oldValue, newValue in
            XCTAssertTrue(oldValue is ObjectId)
            XCTAssertTrue(newValue is ObjectId)
        }
        write(.decimal128(Decimal128())) { oldValue, newValue in
            XCTAssertTrue(oldValue is Decimal128)
            XCTAssertTrue(newValue is Decimal128)
        }
        write(.uuid(UUID())) { oldValue, newValue in
            XCTAssertTrue(oldValue is UUID)
            XCTAssertTrue(newValue is UUID)
        }
        write(.object(SwiftIntObject())) { oldValue, newValue in
            XCTAssertTrue(oldValue! is DynamicObject)
            XCTAssertTrue(newValue! is DynamicObject)
        }
    }

    @available(*, deprecated) // Silence deprecation warnings for RealmOptional
    func testOptionalsInEnumerate() {
        autoreleasepool {
            let realm = try! Realm()
            try! realm.write {
                realm.add(SwiftOptionalObject())
            }
        }

        migrateAndTestDefaultRealm { migration, _ in
            migration.enumerateObjects(ofType: "SwiftOptionalObject") { oldObject, newObject in
                XCTAssertTrue(oldObject! as AnyObject is MigrationObject)
                XCTAssertTrue(newObject! as AnyObject is MigrationObject)
                XCTAssertNil(oldObject!.optNSStringCol)
                XCTAssertNil(newObject!.optNSStringCol)
                XCTAssertNil(oldObject!.optStringCol)
                XCTAssertNil(newObject!.optStringCol)
                XCTAssertNil(oldObject!.optBinaryCol)
                XCTAssertNil(newObject!.optBinaryCol)
                XCTAssertNil(oldObject!.optDateCol)
                XCTAssertNil(newObject!.optDateCol)
                XCTAssertNil(oldObject!.optIntCol)
                XCTAssertNil(newObject!.optIntCol)
                XCTAssertNil(oldObject!.optInt8Col)
                XCTAssertNil(newObject!.optInt8Col)
                XCTAssertNil(oldObject!.optInt16Col)
                XCTAssertNil(newObject!.optInt16Col)
                XCTAssertNil(oldObject!.optInt32Col)
                XCTAssertNil(newObject!.optInt32Col)
                XCTAssertNil(oldObject!.optInt64Col)
                XCTAssertNil(newObject!.optInt64Col)
                XCTAssertNil(oldObject!.optFloatCol)
                XCTAssertNil(newObject!.optFloatCol)
                XCTAssertNil(oldObject!.optDoubleCol)
                XCTAssertNil(newObject!.optDoubleCol)
                XCTAssertNil(oldObject!.optBoolCol)
                XCTAssertNil(newObject!.optBoolCol)
                XCTAssertNil(oldObject!.optDecimalCol)
                XCTAssertNil(newObject!.optDecimalCol)
                XCTAssertNil(oldObject!.optObjectIdCol)
                XCTAssertNil(newObject!.optObjectIdCol)
            }
        }

        autoreleasepool {
            let realm = try! Realm()
            try! realm.write {
                let soo = realm.objects(SwiftOptionalObject.self).first!
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
                soo.optDecimalCol = 8.3
                soo.optObjectIdCol = ObjectId("1234567890bc1234567890bc")
                soo.optBoolCol.value = true
            }
        }

        migrateAndTestDefaultRealm(2) { migration, _ in
            migration.enumerateObjects(ofType: "SwiftOptionalObject") { oldObject, newObject in
                XCTAssertTrue(oldObject! as AnyObject is MigrationObject)
                XCTAssertTrue(newObject! as AnyObject is MigrationObject)
                XCTAssertTrue(oldObject!.optNSStringCol! is NSString)
                XCTAssertTrue(newObject!.optNSStringCol! is NSString)
                XCTAssertTrue(oldObject!.optStringCol! is String)
                XCTAssertTrue(newObject!.optStringCol! is String)
                XCTAssertTrue(oldObject!.optBinaryCol! is Data)
                XCTAssertTrue(newObject!.optBinaryCol! is Data)
                XCTAssertTrue(oldObject!.optDateCol! is Date)
                XCTAssertTrue(newObject!.optDateCol! is Date)
                XCTAssertTrue(oldObject!.optIntCol! is Int)
                XCTAssertTrue(newObject!.optIntCol! is Int)
                XCTAssertTrue(oldObject!.optInt8Col! is Int)
                XCTAssertTrue(newObject!.optInt8Col! is Int)
                XCTAssertTrue(oldObject!.optInt16Col! is Int)
                XCTAssertTrue(newObject!.optInt16Col! is Int)
                XCTAssertTrue(oldObject!.optInt32Col! is Int)
                XCTAssertTrue(newObject!.optInt32Col! is Int)
                XCTAssertTrue(oldObject!.optInt64Col! is Int)
                XCTAssertTrue(newObject!.optInt64Col! is Int)
                XCTAssertTrue(oldObject!.optFloatCol! is Float)
                XCTAssertTrue(newObject!.optFloatCol! is Float)
                XCTAssertTrue(oldObject!.optDoubleCol! is Double)
                XCTAssertTrue(newObject!.optDoubleCol! is Double)
                XCTAssertTrue(oldObject!.optBoolCol! is Bool)
                XCTAssertTrue(newObject!.optBoolCol! is Bool)
                XCTAssertTrue(oldObject!.optDecimalCol! is Decimal128)
                XCTAssertTrue(newObject!.optDecimalCol! is Decimal128)
                XCTAssertTrue(oldObject!.optObjectIdCol! is ObjectId)
                XCTAssertTrue(newObject!.optObjectIdCol! is ObjectId)
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
                try! Realm().create(SwiftInt8Object.self, value: [Int8(1)])
                try! Realm().create(SwiftInt8Object.self, value: [Int8(2)])
                try! Realm().create(SwiftInt8Object.self, value: [Int8(3)])
                try! Realm().create(SwiftInt16Object.self, value: [Int16(1)])
                try! Realm().create(SwiftInt16Object.self, value: [Int16(2)])
                try! Realm().create(SwiftInt16Object.self, value: [Int16(3)])
                try! Realm().create(SwiftInt32Object.self, value: [Int32(1)])
                try! Realm().create(SwiftInt32Object.self, value: [Int32(2)])
                try! Realm().create(SwiftInt32Object.self, value: [Int32(3)])
                try! Realm().create(SwiftInt64Object.self, value: [Int64(1)])
                try! Realm().create(SwiftInt64Object.self, value: [Int64(2)])
                try! Realm().create(SwiftInt64Object.self, value: [Int64(3)])
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

            count = 0
            migration.enumerateObjects(ofType: "SwiftInt8Object") { oldObj, newObj in
                XCTAssertEqual(newObj!["int8Col"] as! Int8, oldObj!["int8Col"] as! Int8)
                if oldObj!["int8Col"] as! Int8 == 1 {
                    migration.delete(newObj!)
                }
            }
            migration.enumerateObjects(ofType: "SwiftInt8Object") { oldObj, newObj in
                XCTAssertEqual(newObj!["int8Col"] as! Int8, oldObj!["int8Col"] as! Int8)
                count += 1
            }
            XCTAssertEqual(count, 2)

            count = 0
            migration.enumerateObjects(ofType: "SwiftInt16Object") { oldObj, newObj in
                XCTAssertEqual(newObj!["int16Col"] as! Int16, oldObj!["int16Col"] as! Int16)
                if oldObj!["int16Col"] as! Int16 == 1 {
                    migration.delete(newObj!)
                }
            }
            migration.enumerateObjects(ofType: "SwiftInt16Object") { oldObj, newObj in
                XCTAssertEqual(newObj!["int16Col"] as! Int16, oldObj!["int16Col"] as! Int16)
                count += 1
            }
            XCTAssertEqual(count, 2)

            count = 0
            migration.enumerateObjects(ofType: "SwiftInt32Object") { oldObj, newObj in
                XCTAssertEqual(newObj!["int32Col"] as! Int32, oldObj!["int32Col"] as! Int32)
                if oldObj!["int32Col"] as! Int32 == 1 {
                    migration.delete(newObj!)
                }
            }
            migration.enumerateObjects(ofType: "SwiftInt32Object") { oldObj, newObj in
                XCTAssertEqual(newObj!["int32Col"] as! Int32, oldObj!["int32Col"] as! Int32)
                count += 1
            }
            XCTAssertEqual(count, 2)

            count = 0
            migration.enumerateObjects(ofType: "SwiftInt64Object") { oldObj, newObj in
                XCTAssertEqual(newObj!["int64Col"] as! Int64, oldObj!["int64Col"] as! Int64)
                if oldObj!["int64Col"] as! Int64 == 1 {
                    migration.delete(newObj!)
                }
            }
            migration.enumerateObjects(ofType: "SwiftInt64Object") { oldObj, newObj in
                XCTAssertEqual(newObj!["int64Col"] as! Int64, oldObj!["int64Col"] as! Int64)
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
                try! Realm().create(SwiftInt8Object.self, value: [Int8(1)])
                try! Realm().create(SwiftInt8Object.self, value: [Int8(2)])
                try! Realm().create(SwiftInt8Object.self, value: [Int8(3)])
                try! Realm().create(SwiftInt16Object.self, value: [Int16(1)])
                try! Realm().create(SwiftInt16Object.self, value: [Int16(2)])
                try! Realm().create(SwiftInt16Object.self, value: [Int16(3)])
                try! Realm().create(SwiftInt32Object.self, value: [Int32(1)])
                try! Realm().create(SwiftInt32Object.self, value: [Int32(2)])
                try! Realm().create(SwiftInt32Object.self, value: [Int32(3)])
                try! Realm().create(SwiftInt64Object.self, value: [Int64(1)])
                try! Realm().create(SwiftInt64Object.self, value: [Int64(2)])
                try! Realm().create(SwiftInt64Object.self, value: [Int64(3)])
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

            count = 0
            migration.enumerateObjects(ofType: "SwiftInt8Object") { oldObj, newObj in
                XCTAssertEqual(newObj!["int8Col"] as! Int8, oldObj!["int8Col"] as! Int8)
                if oldObj!["int8Col"] as! Int8 == 1 {
                    migration.delete(newObj!)
                    migration.create("SwiftInt8Object", value: [0])
                }
            }
            migration.enumerateObjects(ofType: "SwiftInt8Object") { oldObj, newObj in
                XCTAssertEqual(newObj!["int8Col"] as! Int8, oldObj!["int8Col"] as! Int8)
                count += 1
            }
            XCTAssertEqual(count, 2)

            count = 0
            migration.enumerateObjects(ofType: "SwiftInt16Object") { oldObj, newObj in
                XCTAssertEqual(newObj!["int16Col"] as! Int16, oldObj!["int16Col"] as! Int16)
                if oldObj!["int16Col"] as! Int16 == 1 {
                    migration.delete(newObj!)
                    migration.create("SwiftInt16Object", value: [0])
                }
            }
            migration.enumerateObjects(ofType: "SwiftInt16Object") { oldObj, newObj in
                XCTAssertEqual(newObj!["int16Col"] as! Int16, oldObj!["int16Col"] as! Int16)
                count += 1
            }
            XCTAssertEqual(count, 2)

            count = 0
            migration.enumerateObjects(ofType: "SwiftInt32Object") { oldObj, newObj in
                XCTAssertEqual(newObj!["int32Col"] as! Int32, oldObj!["int32Col"] as! Int32)
                if oldObj!["int32Col"] as! Int32 == 1 {
                    migration.delete(newObj!)
                    migration.create("SwiftInt32Object", value: [0])
                }
            }
            migration.enumerateObjects(ofType: "SwiftInt32Object") { oldObj, newObj in
                XCTAssertEqual(newObj!["int32Col"] as! Int32, oldObj!["int32Col"] as! Int32)
                count += 1
            }
            XCTAssertEqual(count, 2)

            count = 0
            migration.enumerateObjects(ofType: "SwiftInt64Object") { oldObj, newObj in
                XCTAssertEqual(newObj!["int64Col"] as! Int64, oldObj!["int64Col"] as! Int64)
                if oldObj!["int64Col"] as! Int64 == 1 {
                    migration.delete(newObj!)
                    migration.create("SwiftInt64Object", value: [0])
                }
            }
            migration.enumerateObjects(ofType: "SwiftInt64Object") { oldObj, newObj in
                XCTAssertEqual(newObj!["int64Col"] as! Int64, oldObj!["int64Col"] as! Int64)
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

    func testEnumerateObjectsAfterDeleteData() {
        autoreleasepool {
            // add object
            try! Realm().write {
                try! Realm().create(SwiftStringObject.self, value: ["1"])
                try! Realm().create(SwiftStringObject.self, value: ["2"])
                try! Realm().create(SwiftStringObject.self, value: ["3"])
            }
        }

        migrateAndTestDefaultRealm(1) { migration, _ in
            var count = 0
            migration.enumerateObjects(ofType: "SwiftStringObject") { _, _ in
                count += 1
            }
            XCTAssertEqual(count, 3)

            migration.deleteData(forType: "SwiftStringObject")
            migration.create("SwiftStringObject", value: ["A"])

            count = 0
            migration.enumerateObjects(ofType: "SwiftStringObject") { _, _ in
                count += 1
            }
            XCTAssertEqual(count, 0)
        }
    }

    func testCreate() {
        autoreleasepool {
            _ = try! Realm()
        }

        migrateAndTestDefaultRealm { migration, _ in
            migration.create("SwiftStringObject", value: ["string1"])
            migration.create("SwiftStringObject", value: ["stringCol": "string2"])
            migration.create("SwiftStringObject", value: ["stringCol": ModernStringEnum.value1])
            migration.create("SwiftStringObject", value: ["stringCol": StringWrapper(persistedValue: "string3")])
            migration.create("SwiftStringObject")

            self.assertThrows(migration.create("NoSuchObject", value: []))
        }

        let objects = try! Realm().objects(SwiftStringObject.self)
        XCTAssertEqual(objects.count, 5)

        XCTAssertEqual(objects[0].stringCol, "string1")
        XCTAssertEqual(objects[1].stringCol, "string2")
        XCTAssertEqual(objects[2].stringCol, ModernStringEnum.value1.rawValue)
        XCTAssertEqual(objects[3].stringCol, "string3")
        XCTAssertEqual(objects[4].stringCol, "")
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
            XCTAssertEqual("a", realm.allObjects("SwiftStringObject").firstObject()?["stringCol"] as? String)
        }
    }

    // test getting/setting all property types
    func testMigrationObject() {
        autoreleasepool {
            let realm = try! Realm()
            let nulledMapObj = SwiftBoolObject(value: [false])
            try! realm.write {
                let object = SwiftObject()
                object.anyCol.value = .string("hello!")
                object.boolCol = true
                object.objectCol = SwiftBoolObject(value: [true])
                object.arrayCol.append(SwiftBoolObject(value: [false]))
                object.setCol.insert(SwiftBoolObject(value: [false]))
                object.mapCol["key"] = SwiftBoolObject(value: [false])
                object.mapCol["nulledObj"] = nulledMapObj

                realm.add(object)
            }

            try! realm.write {
                realm.delete(nulledMapObj)
            }
        }

        migrateAndTestDefaultRealm { migration, _ in
            var enumerated = false
            migration.enumerateObjects(ofType: "SwiftObject", { oldObj, newObj in
                XCTAssertEqual((oldObj!["boolCol"] as! Bool), true)
                XCTAssertEqual((newObj!["boolCol"] as! Bool), true)
                XCTAssertEqual((oldObj!["intCol"] as! Int), 123)
                XCTAssertEqual((newObj!["intCol"] as! Int), 123)
                XCTAssertEqual((oldObj!["int8Col"] as! Int8), 123)
                XCTAssertEqual((newObj!["int8Col"] as! Int8), 123)
                XCTAssertEqual((oldObj!["int16Col"] as! Int16), 123)
                XCTAssertEqual((newObj!["int16Col"] as! Int16), 123)
                XCTAssertEqual((oldObj!["int32Col"] as! Int32), 123)
                XCTAssertEqual((newObj!["int32Col"] as! Int32), 123)
                XCTAssertEqual((oldObj!["int64Col"] as! Int64), 123)
                XCTAssertEqual((newObj!["int64Col"] as! Int64), 123)
                XCTAssertEqual((oldObj!["intEnumCol"] as! Int), 1)
                XCTAssertEqual((newObj!["intEnumCol"] as! Int), 1)
                XCTAssertEqual((oldObj!["floatCol"] as! Float), 1.23 as Float)
                XCTAssertEqual((newObj!["floatCol"] as! Float), 1.23 as Float)
                XCTAssertEqual((oldObj!["doubleCol"] as! Double), 12.3 as Double)
                XCTAssertEqual((newObj!["doubleCol"] as! Double), 12.3 as Double)
                XCTAssertEqual((oldObj!["decimalCol"] as! Decimal128), 123e4 as Decimal128)
                XCTAssertEqual((newObj!["decimalCol"] as! Decimal128), 123e4 as Decimal128)

                let binaryCol = "a".data(using: String.Encoding.utf8)!
                XCTAssertEqual((oldObj!["binaryCol"] as! Data), binaryCol)
                XCTAssertEqual((newObj!["binaryCol"] as! Data), binaryCol)

                let dateCol = Date(timeIntervalSince1970: 1)
                XCTAssertEqual((oldObj!["dateCol"] as! Date), dateCol)
                XCTAssertEqual((newObj!["dateCol"] as! Date), dateCol)

                let objectIdCol = ObjectId("1234567890ab1234567890ab")
                XCTAssertEqual((oldObj!["objectIdCol"] as! ObjectId), objectIdCol)
                XCTAssertEqual((newObj!["objectIdCol"] as! ObjectId), objectIdCol)

                // FIXME - test that casting to SwiftBoolObject throws
                XCTAssertEqual(((oldObj!["objectCol"] as! MigrationObject)["boolCol"] as! Bool), true)
                XCTAssertEqual(((newObj!["objectCol"] as! MigrationObject)["boolCol"] as! Bool), true)

                XCTAssertEqual((oldObj!["arrayCol"] as! List<MigrationObject>).count, 1)
                XCTAssertEqual(((oldObj!["arrayCol"] as! List<MigrationObject>)[0]["boolCol"] as! Bool), false)
                XCTAssertEqual((newObj!["arrayCol"] as! List<MigrationObject>).count, 1)
                XCTAssertEqual(((newObj!["arrayCol"] as! List<MigrationObject>)[0]["boolCol"] as! Bool), false)

                XCTAssertEqual((oldObj!["setCol"] as! MutableSet<MigrationObject>).count, 1)
                XCTAssertEqual(((oldObj!["setCol"] as! MutableSet<MigrationObject>)[0]["boolCol"] as! Bool), false)
                XCTAssertEqual((newObj!["setCol"] as! MutableSet<MigrationObject>).count, 1)
                XCTAssertEqual(((newObj!["setCol"] as! MutableSet<MigrationObject>)[0]["boolCol"] as! Bool), false)

                XCTAssertEqual((oldObj!["mapCol"] as! Map<String, MigrationObject?>).count, 2)
                XCTAssertEqual(((oldObj!["mapCol"] as! Map<String, MigrationObject?>)["key"]?!["boolCol"] as! Bool), false)
                XCTAssertEqual((newObj!["mapCol"] as! Map<String, MigrationObject?>).count, 2)
                XCTAssertEqual(((newObj!["mapCol"] as! Map<String, MigrationObject?>)["key"]?!["boolCol"] as! Bool), false)

                let uuidCol: UUID = UUID(uuidString: "137decc8-b300-4954-a233-f89909f4fd89")!
                XCTAssertEqual((newObj!["uuidCol"] as! UUID), uuidCol)
                XCTAssertEqual((oldObj!["uuidCol"] as! UUID), uuidCol)

                let anyValue = AnyRealmValue.string("hello!")
                XCTAssertEqual(((newObj!["anyCol"] as! String)), anyValue.stringValue)
                XCTAssertEqual(((oldObj!["anyCol"] as! String)), anyValue.stringValue)

                // edit all values
                newObj!["boolCol"] = false
                newObj!["intCol"] = 1
                newObj!["int8Col"] = Int8(1)
                newObj!["int16Col"] = Int16(1)
                newObj!["int32Col"] = Int32(1)
                newObj!["int64Col"] = Int64(1)
                newObj!["intEnumCol"] = IntEnum.value2.rawValue
                newObj!["floatCol"] = 1.0
                newObj!["doubleCol"] = 10.0
                newObj!["binaryCol"] = Data(bytes: "b", count: 1)
                newObj!["dateCol"] = Date(timeIntervalSince1970: 2)
                newObj!["decimalCol"] = Decimal128(number: 567e8)
                newObj!["objectIdCol"] = ObjectId("abcdef123456abcdef123456")
                newObj!["anyCol"] = 12345

                let falseObj = SwiftBoolObject(value: [false])
                newObj!["objectCol"] = falseObj

                var list = newObj!["arrayCol"] as! List<MigrationObject>
                list[0]["boolCol"] = true
                list.append(newObj!["objectCol"] as! MigrationObject)

                let trueObj = migration.create(SwiftBoolObject.className(), value: [true])
                list.append(trueObj)

                var set = newObj!["setCol"] as! MutableSet<MigrationObject>
                set[0]["boolCol"] = true
                set.insert(newObj!["objectCol"] as! MigrationObject)
                set.insert(trueObj)

                // verify list property
                list = newObj!["arrayCol"] as! List<MigrationObject>
                XCTAssertEqual(list.count, 3)
                XCTAssertEqual((list[0]["boolCol"] as! Bool), true)
                XCTAssertEqual((list[1]["boolCol"] as! Bool), false)
                XCTAssertEqual((list[2]["boolCol"] as! Bool), true)

                list = newObj!.dynamicList("arrayCol")
                XCTAssertEqual(list.count, 3)
                XCTAssertEqual((list[0]["boolCol"] as! Bool), true)
                XCTAssertEqual((list[1]["boolCol"] as! Bool), false)
                XCTAssertEqual((list[2]["boolCol"] as! Bool), true)

                // verify set property
                set = newObj!["setCol"] as! MutableSet<MigrationObject>
                XCTAssertEqual(set.count, 3)
                XCTAssertEqual((set[0]["boolCol"] as! Bool), true)
                XCTAssertEqual((set[1]["boolCol"] as! Bool), false)
                XCTAssertEqual((set[2]["boolCol"] as! Bool), true)

                set = newObj!.dynamicMutableSet("setCol")
                XCTAssertEqual(set.count, 3)
                XCTAssertEqual((set[0]["boolCol"] as! Bool), true)
                XCTAssertEqual((set[1]["boolCol"] as! Bool), false)
                XCTAssertEqual((set[2]["boolCol"] as! Bool), true)

                // verify map property
                var map = newObj!["mapCol"] as! Map<String, MigrationObject?>
                XCTAssertEqual(map["key"]?!["boolCol"] as! Bool, false)
                XCTAssertEqual(map.count, 2)

                map["key"]?!["boolCol"] = true
                map = newObj!.dynamicMap("mapCol")
                XCTAssertEqual(map.count, 2)
                XCTAssertEqual((map["key"]?!["boolCol"] as! Bool), true)

                self.assertThrows(newObj!.value(forKey: "noSuchKey"))
                self.assertThrows(newObj!.setValue(1, forKey: "noSuchKey"))

                // set it again
                newObj!["arrayCol"] = [falseObj, trueObj]
                XCTAssertEqual(list.count, 2)

                newObj!["arrayCol"] = [SwiftBoolObject(value: [false])]
                XCTAssertEqual(list.count, 1)
                XCTAssertEqual((list[0]["boolCol"] as! Bool), false)

                newObj!["setCol"] = [falseObj, trueObj]
                XCTAssertEqual(set.count, 2)

                newObj!["setCol"] = [SwiftBoolObject(value: [false])]
                XCTAssertEqual(set.count, 1)
                XCTAssertEqual((set[0]["boolCol"] as! Bool), false)

                // test null in Map
                XCTAssertEqual(map.count, 2)
                XCTAssertEqual(map["nulledObj"], Optional<MigrationObject?>.some(nil))

                newObj!["mapCol"] = ["key": SwiftBoolObject(value: [false])]
                XCTAssertEqual(map.count, 1)
                XCTAssertEqual((map["key"]?!["boolCol"] as! Bool), false)

                let expected = """
                SwiftObject \\{
                    boolCol = 0;
                    intCol = 1;
                    int8Col = 1;
                    int16Col = 1;
                    int32Col = 1;
                    int64Col = 1;
                    intEnumCol = 3;
                    floatCol = 1;
                    doubleCol = 10;
                    stringCol = a;
                    binaryCol = <.*62.*>;
                    dateCol = 1970-01-01 00:00:02 \\+0000;
                    decimalCol = 56700000000;
                    objectIdCol = abcdef123456abcdef123456;
                    objectCol = SwiftBoolObject \\{
                        boolCol = 0;
                    \\};
                    uuidCol = 137DECC8-B300-4954-A233-F89909F4FD89;
                    anyCol = 12345;
                    arrayCol = List<SwiftBoolObject> <0x[0-9a-f]+> \\(
                        \\[0\\] SwiftBoolObject \\{
                            boolCol = 0;
                        \\}
                    \\);
                    setCol = MutableSet<SwiftBoolObject> <0x[0-9a-f]+> \\(
                        \\[0\\] SwiftBoolObject \\{
                            boolCol = 0;
                        \\}
                    \\);
                    mapCol = Map<string, SwiftBoolObject> <0x[0-9a-f]+> \\(
                    \\[key\\]: SwiftBoolObject \\{
                            boolCol = 0;
                        \\}
                    \\);
                \\}
                """
                self.assertMatches(newObj!.description, expected.replacingOccurrences(of: "    ", with: "\t"))

                enumerated = true
            })
            XCTAssertEqual(enumerated, true)

            let newObj = migration.create(SwiftObject.className())
            newObj["anyCol"] = "Some String"
            let expected = """
            SwiftObject \\{
                boolCol = 0;
                intCol = 123;
                int8Col = 123;
                int16Col = 123;
                int32Col = 123;
                int64Col = 123;
                intEnumCol = 1;
                floatCol = 1.23;
                doubleCol = 12.3;
                stringCol = a;
                binaryCol = <.*61.*>;
                dateCol = 1970-01-01 00:00:01 \\+0000;
                decimalCol = 1.23E6;
                objectIdCol = 1234567890ab1234567890ab;
                objectCol = SwiftBoolObject \\{
                    boolCol = 0;
                \\};
                uuidCol = 137DECC8-B300-4954-A233-F89909F4FD89;
                anyCol = Some String;
                arrayCol = List<SwiftBoolObject> <0x[0-9a-f]+> \\(
                \\
                \\);
                setCol = MutableSet<SwiftBoolObject> <0x[0-9a-f]+> \\(
                \\
                \\);
                mapCol = Map<string, SwiftBoolObject> <0x[0-9a-f]+> \\(
                \\
                \\);
            \\}
            """
            self.assertMatches(newObj.description, expected.replacingOccurrences(of: "    ", with: "\t"))
        }

        // refresh to update realm
        try! Realm().refresh()

        // check edited values
        let object = try! Realm().objects(SwiftObject.self).first!
        XCTAssertEqual(object.boolCol, false)
        XCTAssertEqual(object.intCol, 1)
        XCTAssertEqual(object.int8Col, Int8(1))
        XCTAssertEqual(object.int16Col, Int16(1))
        XCTAssertEqual(object.int32Col, Int32(1))
        XCTAssertEqual(object.int64Col, Int64(1))
        XCTAssertEqual(object.floatCol, 1.0 as Float)
        XCTAssertEqual(object.doubleCol, 10.0)
        XCTAssertEqual(object.binaryCol, Data(bytes: "b", count: 1))
        XCTAssertEqual(object.dateCol, Date(timeIntervalSince1970: 2))
        XCTAssertEqual(object.objectCol!.boolCol, false)
        XCTAssertEqual(object.arrayCol.count, 1)
        XCTAssertEqual(object.arrayCol[0].boolCol, false)
        XCTAssertEqual(object.setCol.count, 1)
        XCTAssertEqual(object.setCol[0].boolCol, false)
        XCTAssertEqual(object.mapCol.count, 1)
        XCTAssertEqual(object.mapCol["key"]!?.boolCol, false)

        // make sure we added new bool objects as object property and in the list
        XCTAssertEqual(try! Realm().objects(SwiftBoolObject.self).count, 10)
    }

    func testCollectionAccess() {
        autoreleasepool {
            let realm = try! Realm()
            try! realm.write {
                realm.add(ModernAllTypesObject())
            }
        }
        migrateAndTestDefaultRealm { migration, _ in
            var enumerated = false
            migration.enumerateObjects(ofType: "ModernAllTypesObject", { oldObj, _ in

                XCTAssertEqual((oldObj!["arrayCol"] as! List<MigrationObject>).count, 0)
                XCTAssertEqual((oldObj!["setCol"] as! MutableSet<MigrationObject>).count, 0)
                XCTAssertEqual((oldObj!["mapCol"] as! Map<String, MigrationObject?>).count, 0)

                XCTAssertEqual((oldObj!["arrayBool"] as! List<Bool>).count, 0)
                XCTAssertEqual((oldObj!["arrayInt"] as! List<Int>).count, 0)
                XCTAssertEqual((oldObj!["arrayInt8"] as! List<Int>).count, 0)
                XCTAssertEqual((oldObj!["arrayInt16"] as! List<Int>).count, 0)
                XCTAssertEqual((oldObj!["arrayInt32"] as! List<Int>).count, 0)
                XCTAssertEqual((oldObj!["arrayInt64"] as! List<Int>).count, 0)
                XCTAssertEqual((oldObj!["arrayFloat"] as! List<Float>).count, 0)
                XCTAssertEqual((oldObj!["arrayDouble"] as! List<Double>).count, 0)
                XCTAssertEqual((oldObj!["arrayString"] as! List<String>).count, 0)
                XCTAssertEqual((oldObj!["arrayBinary"] as! List<Data>).count, 0)
                XCTAssertEqual((oldObj!["arrayDate"] as! List<Date>).count, 0)
                XCTAssertEqual((oldObj!["arrayDecimal"] as! List<Decimal128>).count, 0)
                XCTAssertEqual((oldObj!["arrayObjectId"] as! List<ObjectId>).count, 0)
                XCTAssertEqual((oldObj!["arrayAny"] as! List<AnyRealmValue>).count, 0)
                XCTAssertEqual((oldObj!["arrayUuid"] as! List<UUID>).count, 0)

                XCTAssertEqual((oldObj!["arrayOptBool"] as! List<Bool?>).count, 0)
                XCTAssertEqual((oldObj!["arrayOptInt"] as! List<Int?>).count, 0)
                XCTAssertEqual((oldObj!["arrayOptInt8"] as! List<Int?>).count, 0)
                XCTAssertEqual((oldObj!["arrayOptInt16"] as! List<Int?>).count, 0)
                XCTAssertEqual((oldObj!["arrayOptInt32"] as! List<Int?>).count, 0)
                XCTAssertEqual((oldObj!["arrayOptInt64"] as! List<Int?>).count, 0)
                XCTAssertEqual((oldObj!["arrayOptFloat"] as! List<Float?>).count, 0)
                XCTAssertEqual((oldObj!["arrayOptDouble"] as! List<Double?>).count, 0)
                XCTAssertEqual((oldObj!["arrayOptString"] as! List<String?>).count, 0)
                XCTAssertEqual((oldObj!["arrayOptBinary"] as! List<Data?>).count, 0)
                XCTAssertEqual((oldObj!["arrayOptDate"] as! List<Date?>).count, 0)
                XCTAssertEqual((oldObj!["arrayOptDecimal"] as! List<Decimal128?>).count, 0)
                XCTAssertEqual((oldObj!["arrayOptObjectId"] as! List<ObjectId?>).count, 0)
                XCTAssertEqual((oldObj!["arrayOptUuid"] as! List<UUID?>).count, 0)

                XCTAssertEqual((oldObj!["setBool"] as! MutableSet<Bool>).count, 0)
                XCTAssertEqual((oldObj!["setInt"] as! MutableSet<Int>).count, 0)
                XCTAssertEqual((oldObj!["setInt8"] as! MutableSet<Int>).count, 0)
                XCTAssertEqual((oldObj!["setInt16"] as! MutableSet<Int>).count, 0)
                XCTAssertEqual((oldObj!["setInt32"] as! MutableSet<Int>).count, 0)
                XCTAssertEqual((oldObj!["setInt64"] as! MutableSet<Int>).count, 0)
                XCTAssertEqual((oldObj!["setFloat"] as! MutableSet<Float>).count, 0)
                XCTAssertEqual((oldObj!["setDouble"] as! MutableSet<Double>).count, 0)
                XCTAssertEqual((oldObj!["setString"] as! MutableSet<String>).count, 0)
                XCTAssertEqual((oldObj!["setBinary"] as! MutableSet<Data>).count, 0)
                XCTAssertEqual((oldObj!["setDate"] as! MutableSet<Date>).count, 0)
                XCTAssertEqual((oldObj!["setDecimal"] as! MutableSet<Decimal128>).count, 0)
                XCTAssertEqual((oldObj!["setObjectId"] as! MutableSet<ObjectId>).count, 0)
                XCTAssertEqual((oldObj!["setAny"] as! MutableSet<AnyRealmValue>).count, 0)
                XCTAssertEqual((oldObj!["setUuid"] as! MutableSet<UUID>).count, 0)

                XCTAssertEqual((oldObj!["setOptBool"] as! MutableSet<Bool?>).count, 0)
                XCTAssertEqual((oldObj!["setOptInt"] as! MutableSet<Int?>).count, 0)
                XCTAssertEqual((oldObj!["setOptInt8"] as! MutableSet<Int?>).count, 0)
                XCTAssertEqual((oldObj!["setOptInt16"] as! MutableSet<Int?>).count, 0)
                XCTAssertEqual((oldObj!["setOptInt32"] as! MutableSet<Int?>).count, 0)
                XCTAssertEqual((oldObj!["setOptInt64"] as! MutableSet<Int?>).count, 0)
                XCTAssertEqual((oldObj!["setOptFloat"] as! MutableSet<Float?>).count, 0)
                XCTAssertEqual((oldObj!["setOptDouble"] as! MutableSet<Double?>).count, 0)
                XCTAssertEqual((oldObj!["setOptString"] as! MutableSet<String?>).count, 0)
                XCTAssertEqual((oldObj!["setOptBinary"] as! MutableSet<Data?>).count, 0)
                XCTAssertEqual((oldObj!["setOptDate"] as! MutableSet<Date?>).count, 0)
                XCTAssertEqual((oldObj!["setOptDecimal"] as! MutableSet<Decimal128?>).count, 0)
                XCTAssertEqual((oldObj!["setOptObjectId"] as! MutableSet<ObjectId?>).count, 0)
                XCTAssertEqual((oldObj!["setOptUuid"] as! MutableSet<UUID?>).count, 0)

                XCTAssertEqual((oldObj!["mapBool"] as! Map<String, Bool>).count, 0)
                XCTAssertEqual((oldObj!["mapInt"] as! Map<String, Int>).count, 0)
                XCTAssertEqual((oldObj!["mapInt8"] as! Map<String, Int>).count, 0)
                XCTAssertEqual((oldObj!["mapInt16"] as! Map<String, Int>).count, 0)
                XCTAssertEqual((oldObj!["mapInt32"] as! Map<String, Int>).count, 0)
                XCTAssertEqual((oldObj!["mapInt64"] as! Map<String, Int>).count, 0)
                XCTAssertEqual((oldObj!["mapFloat"] as! Map<String, Float>).count, 0)
                XCTAssertEqual((oldObj!["mapDouble"] as! Map<String, Double>).count, 0)
                XCTAssertEqual((oldObj!["mapString"] as! Map<String, String>).count, 0)
                XCTAssertEqual((oldObj!["mapBinary"] as! Map<String, Data>).count, 0)
                XCTAssertEqual((oldObj!["mapDate"] as! Map<String, Date>).count, 0)
                XCTAssertEqual((oldObj!["mapDecimal"] as! Map<String, Decimal128>).count, 0)
                XCTAssertEqual((oldObj!["mapObjectId"] as! Map<String, ObjectId>).count, 0)
                XCTAssertEqual((oldObj!["mapAny"] as! Map<String, AnyRealmValue>).count, 0)
                XCTAssertEqual((oldObj!["mapUuid"] as! Map<String, UUID>).count, 0)

                XCTAssertEqual((oldObj!["mapOptBool"] as! Map<String, Bool?>).count, 0)
                XCTAssertEqual((oldObj!["mapOptInt"] as! Map<String, Int?>).count, 0)
                XCTAssertEqual((oldObj!["mapOptInt8"] as! Map<String, Int?>).count, 0)
                XCTAssertEqual((oldObj!["mapOptInt16"] as! Map<String, Int?>).count, 0)
                XCTAssertEqual((oldObj!["mapOptInt32"] as! Map<String, Int?>).count, 0)
                XCTAssertEqual((oldObj!["mapOptInt64"] as! Map<String, Int?>).count, 0)
                XCTAssertEqual((oldObj!["mapOptFloat"] as! Map<String, Float?>).count, 0)
                XCTAssertEqual((oldObj!["mapOptDouble"] as! Map<String, Double?>).count, 0)
                XCTAssertEqual((oldObj!["mapOptString"] as! Map<String, String?>).count, 0)
                XCTAssertEqual((oldObj!["mapOptBinary"] as! Map<String, Data?>).count, 0)
                XCTAssertEqual((oldObj!["mapOptDate"] as! Map<String, Date?>).count, 0)
                XCTAssertEqual((oldObj!["mapOptDecimal"] as! Map<String, Decimal128?>).count, 0)
                XCTAssertEqual((oldObj!["mapOptObjectId"] as! Map<String, ObjectId?>).count, 0)
                XCTAssertEqual((oldObj!["mapOptUuid"] as! Map<String, UUID?>).count, 0)

                enumerated = true
            })
            XCTAssertTrue(enumerated)
        }
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
