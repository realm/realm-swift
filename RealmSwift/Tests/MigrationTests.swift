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
import Realm.Private
import Foundation

private func realmWithCustomSchema(path: String, schema :RLMSchema) -> RLMRealm {
    return RLMRealm(path: path, key: nil, readOnly: false, inMemory: false, dynamic: true, schema: schema, error: nil)!
}

private func realmWithSingleClass(path: String, objectSchema: RLMObjectSchema) -> RLMRealm {
    let schema = RLMSchema()
    schema.objectSchema = [objectSchema]
    return realmWithCustomSchema(path, schema)
}

private func realmWithSingleClassProperties(path: String, className: String, properties: [AnyObject]) -> RLMRealm {
    let objectSchema = RLMObjectSchema(className: className, objectClass: MigrationObject.self, properties: properties)
    return realmWithSingleClass(path, objectSchema)
}

class MigrationTests: TestCase {

    // MARK Utility methods

    // create realm at path and test version is 0
    private func createAndTestRealmAtPath(realmPath: String) {
        autoreleasepool { () -> () in
            Realm(path: realmPath)
            return
        }
        XCTAssertEqual(UInt(0), schemaVersionAtPath(realmPath)!, "Initial version should be 0")
    }

    // migrate realm at path and ensure migration
    private func migrateAndTestRealm(realmPath: String, shouldRun: Bool = true, schemaVersion: UInt = 1, autoMigration: Bool = false, block: MigrationBlock? = nil) {
        var didRun = false
        setSchemaVersion(schemaVersion, realmPath, { migration, oldSchemaVersion in
            if let block = block {
                block(migration: migration, oldSchemaVersion: oldSchemaVersion)
            }
            didRun = true
            return
        })

        if autoMigration {
            Realm(path: realmPath)
        }
        else {
            migrateRealm(realmPath, encryptionKey: nil)
        }

        XCTAssertEqual(didRun, shouldRun)
    }

    // MARK Test cases

    func testSetDefaultRealmSchemaVersion() {
        createAndTestRealmAtPath(defaultRealmPath())
        var didRun = false
        setDefaultRealmSchemaVersion(1, { migration, oldSchemaVersion in
            didRun = true
            return
        })
        migrateRealm(defaultRealmPath(), encryptionKey: nil)

        XCTAssertEqual(didRun, true)
        XCTAssertEqual(UInt(1), schemaVersionAtPath(defaultRealmPath())!)
    }

    func testSetSchemaVersion() {
        createAndTestRealmAtPath(testRealmPath())
        migrateAndTestRealm(testRealmPath())

        XCTAssertEqual(UInt(1), schemaVersionAtPath(testRealmPath())!)
    }

    func testSchemaVersionAtPath() {
        var error : NSError? = nil
        XCTAssertNil(schemaVersionAtPath(defaultRealmPath(), error: &error), "Version should be nil before Realm creation")
        XCTAssertNotNil(error, "Error should be set")

        defaultRealm()
        XCTAssertEqual(UInt(0), schemaVersionAtPath(defaultRealmPath())!, "Initial version should be 0")
    }

    func testMigrateRealm() {
        createAndTestRealmAtPath(testRealmPath())

        // manually migrate (autoMigration == false)
        migrateAndTestRealm(testRealmPath(), shouldRun: true, autoMigration: false)

        // calling again should be no-op
        migrateAndTestRealm(testRealmPath(), shouldRun: false, autoMigration: false)

        // test auto-migration
        migrateAndTestRealm(testRealmPath(), schemaVersion: 2, shouldRun: true, autoMigration: true)
    }

    func testMigrationProperties() {
        let prop = RLMProperty(name: "stringCol", type: RLMPropertyType.Int, objectClassName: nil, indexed: false)
        autoreleasepool { () -> () in
            realmWithSingleClassProperties(defaultRealmPath(), "SwiftStringObject", [prop])
            return
        }

        migrateAndTestRealm(defaultRealmPath(), block: { migration, oldSchemaVersion in
            XCTAssertEqual(migration.oldSchema.objectSchema.count, 1)
            XCTAssertGreaterThan(migration.newSchema.objectSchema.count, 1)
            XCTAssertEqual(migration.oldSchema.objectSchema[0].properties.count, 1)
            XCTAssertEqual(migration.newSchema["SwiftStringObject"]!.properties.count, 1)
            XCTAssertEqual(migration.oldSchema["SwiftStringObject"]!.properties[0].type, PropertyType.Int)
            XCTAssertEqual(migration.newSchema["SwiftStringObject"]!["stringCol"]!.type, PropertyType.String)
        })
    }

    func testEnumerate() {
        self.migrateAndTestRealm(defaultRealmPath(), block: { migration, oldSchemaVersion in
            migration.enumerate("SwiftStringObject", { oldObj, newObj in
                XCTFail("No objects to enumerate")
            })
        })

        // add object
        defaultRealm().write({
            SwiftStringObject.createInRealm(defaultRealm(), withObject: ["string"])
            return
        })

        migrateAndTestRealm(defaultRealmPath(), schemaVersion: 2, block: { migration, oldSchemaVersion in
            var count = 0
            migration.enumerate("SwiftStringObject", { oldObj, newObj in
                XCTAssertEqual(newObj.objectSchema.className, "SwiftStringObject")
                XCTAssertEqual(oldObj.objectSchema.className, "SwiftStringObject")
                XCTAssertEqual(newObj["stringCol"] as String, "string")
                XCTAssertEqual(oldObj["stringCol"] as String, "string")
                count++
            })
            XCTAssertEqual(count, 1)
        })
    }

    func testCreate() {
        migrateAndTestRealm(defaultRealmPath(), block: { migration, oldSchemaVersion in
            migration.create("SwiftStringObject", withObject:["string"])
            migration.create("SwiftStringObject", withObject:["stringCol": "string"])

            var count = 0
            migration.enumerate("SwiftStringObject", { oldObj, newObj in
                XCTAssertEqual(newObj["stringCol"] as String, "string")
                XCTAssertNil(oldObj["stringCol"], "Objects created during migration have nil oldObj")
                count++
            })
            XCTAssertEqual(count, 2)
        })

        XCTAssertEqual(objects(SwiftStringObject.self).count, 2)
    }

    func testDelete() {
        autoreleasepool { () -> () in
            defaultRealm().write({
                SwiftStringObject.createInRealm(defaultRealm(), withObject: ["string1"])
                SwiftStringObject.createInRealm(defaultRealm(), withObject: ["string2"])
                return
            })

            self.migrateAndTestRealm(defaultRealmPath(), block: { migration, oldSchemaVersion in
                var deleted = false;
                migration.enumerate("SwiftStringObject", { oldObj, newObj in
                    if deleted == false {
                        migration.delete(newObj)
                        deleted = true
                    }
                })
            })
        }

        XCTAssertEqual(objects(SwiftStringObject.self).count, 1)
    }

    // test getting/setting all property types
    func testMigrationObject() {
        defaultRealm().write({
            var object = SwiftObject()
            object.boolCol = true
            object.objectCol = SwiftBoolObject(object:[true])
            object.arrayCol.append(SwiftBoolObject(object:[false]))
            defaultRealm().add(object)
            return
        })

        self.migrateAndTestRealm(defaultRealmPath(), block: { migration, oldSchemaVersion in
            var count = 0
            migration.enumerate("SwiftObject", { oldObj, newObj in
                XCTAssertEqual(oldObj["boolCol"] as Bool, true)
                XCTAssertEqual(newObj["boolCol"] as Bool, true)
                XCTAssertEqual(oldObj["intCol"] as Int, 123)
                XCTAssertEqual(newObj["intCol"] as Int, 123)
                XCTAssertEqual(oldObj["floatCol"] as Float, 1.23 as Float)
                XCTAssertEqual(newObj["floatCol"] as Float, 1.23 as Float)
                XCTAssertEqual(oldObj["doubleCol"] as Double, 12.3 as Double)
                XCTAssertEqual(newObj["doubleCol"] as Double, 12.3 as Double)

                var binaryCol = "a".dataUsingEncoding(NSUTF8StringEncoding)!
                XCTAssertEqual(oldObj["binaryCol"] as NSData, binaryCol)
                XCTAssertEqual(newObj["binaryCol"] as NSData, binaryCol)

                var dateCol = NSDate(timeIntervalSince1970: 1)
                XCTAssertEqual(oldObj["dateCol"] as NSDate, dateCol)
                XCTAssertEqual(newObj["dateCol"] as NSDate, dateCol)

                // FIXME - test that casting to SwiftBoolObject throws
                XCTAssertEqual((oldObj["objectCol"] as MigrationObject)["boolCol"] as Bool, true)
                XCTAssertEqual((newObj["objectCol"] as MigrationObject)["boolCol"] as Bool, true)

                XCTAssertEqual((oldObj["arrayCol"] as List<MigrationObject>).count, 1)
                XCTAssertEqual((oldObj["arrayCol"] as List<MigrationObject>)[0]["boolCol"] as Bool, false)
                XCTAssertEqual((newObj["arrayCol"] as List<MigrationObject>).count, 1)
                XCTAssertEqual((newObj["arrayCol"] as List<MigrationObject>)[0]["boolCol"] as Bool, false)

                count += 1
            })
            XCTAssertEqual(count, 1)
        })
    }
}

