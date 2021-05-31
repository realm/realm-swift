////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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

private var dynamicDefaultSeed = 0
private func nextDynamicDefaultSeed() -> Int {
    dynamicDefaultSeed += 1
    return dynamicDefaultSeed
}
class ModernDynamicDefaultObject: Object {
    @Persisted(primaryKey: true) var intCol = nextDynamicDefaultSeed()
    @Persisted var floatCol = Float(nextDynamicDefaultSeed())
    @Persisted var doubleCol = Double(nextDynamicDefaultSeed())
    @Persisted var dateCol = Date(timeIntervalSinceReferenceDate: TimeInterval(nextDynamicDefaultSeed()))
    @Persisted var stringCol = UUID().uuidString
    @Persisted var binaryCol = UUID().uuidString.data(using: .utf8)
}

class ModernObjectTests: TestCase {
    // init() Tests are in ObjectCreationTests.swift
    // init(value:) tests are in ObjectCreationTests.swift

    func testObjectSchema() {
        let object = ModernAllTypesObject()
        let schema = object.objectSchema
        XCTAssert(schema as AnyObject is ObjectSchema)
        XCTAssert(schema.properties as AnyObject is [Property])
        XCTAssertEqual(schema.className, "ModernAllTypesObject")
        XCTAssertEqual(schema.properties.map { $0.name },
                       ["pk", "boolCol", "intCol", "int8Col", "int16Col",
                        "int32Col", "int64Col", "floatCol", "doubleCol",
                        "stringCol", "binaryCol", "dateCol", "decimalCol",
                        "objectIdCol", "objectCol", "arrayCol", "setCol",
                        "anyCol", "uuidCol", "intEnumCol", "stringEnumCol",
                        "optIntCol", "optInt8Col", "optInt16Col",
                        "optInt32Col", "optInt64Col", "optFloatCol",
                        "optDoubleCol", "optBoolCol", "optStringCol",
                        "optBinaryCol", "optDateCol", "optDecimalCol",
                        "optObjectIdCol", "optUuidCol", "optObjectCol",
                        "optIntEnumCol", "optStringEnumCol", "arrayBool",
                        "arrayInt", "arrayInt8", "arrayInt16", "arrayInt32",
                        "arrayInt64", "arrayFloat", "arrayDouble",
                        "arrayString", "arrayBinary", "arrayDate",
                        "arrayDecimal", "arrayObjectId", "arrayAny",
                        "arrayUuid", "arrayObject", "arrayOptBool",
                        "arrayOptInt", "arrayOptInt8", "arrayOptInt16",
                        "arrayOptInt32", "arrayOptInt64", "arrayOptFloat",
                        "arrayOptDouble", "arrayOptString",
                        "arrayOptBinary", "arrayOptDate", "arrayOptDecimal",
                        "arrayOptObjectId", "arrayOptUuid", "setBool",
                        "setInt", "setInt8", "setInt16", "setInt32",
                        "setInt64", "setFloat", "setDouble", "setString",
                        "setBinary", "setDate", "setDecimal", "setObjectId",
                        "setAny", "setUuid", "setObject", "setOptBool",
                        "setOptInt", "setOptInt8", "setOptInt16",
                        "setOptInt32", "setOptInt64", "setOptFloat",
                        "setOptDouble", "setOptString", "setOptBinary",
                        "setOptDate", "setOptDecimal", "setOptObjectId",
                        "setOptUuid"])
    }

    func testObjectSchemaForObjectWithConvenienceInitializer() {
        let object = ModernConvenienceInitializerObject(stringCol: "abc")
        let schema = object.objectSchema
        XCTAssert(schema as AnyObject is ObjectSchema)
        XCTAssert(schema.properties as AnyObject is [Property])
        XCTAssertEqual(schema.className, "ModernConvenienceInitializerObject")
        XCTAssertEqual(schema.properties.map { $0.name }, ["stringCol"])
    }

    func testCannotUpdatePrimaryKey() {
        let primaryKeyReason = "Primary key can't be changed.* after an object is inserted."
        let realm = self.realmWithTestPath()
        realm.beginWrite()

        func test<O: ModernPrimaryKeyObject>(_ object: O, _ v1: O.PrimaryKey, _ v2: O.PrimaryKey) {
            // Unmanaged objects can mutate the primary key
            object.pk = v1
            XCTAssertEqual(object.pk, v1)
            object.pk = v2
            XCTAssertEqual(object.pk, v2)
            object["pk"] = v1
            XCTAssertEqual(object.pk, v1)
            object.setValue(v2, forKey: "pk")
            XCTAssertEqual(object.pk, v2)

            // Managed objects cannot mutate the pk
            realm.add(object)
            assertThrows(object.pk = v2, reasonMatching: primaryKeyReason)
            assertThrows(object["pk"] = v2, reasonMatching: primaryKeyReason)
            assertThrows(object.setValue(v2, forKey: "pk"), reasonMatching: primaryKeyReason)
        }

        test(ModernPrimaryIntObject(), 1, 2)
        test(ModernPrimaryInt8Object(), 1, 2)
        test(ModernPrimaryInt16Object(), 1, 2)
        test(ModernPrimaryInt32Object(), 1, 2)
        test(ModernPrimaryInt64Object(), 1, 2)
        test(ModernPrimaryOptionalIntObject(), 1, nil)
        test(ModernPrimaryOptionalInt8Object(), 1, nil)
        test(ModernPrimaryOptionalInt16Object(), 1, nil)
        test(ModernPrimaryOptionalInt32Object(), 1, nil)
        test(ModernPrimaryOptionalInt64Object(), 1, nil)

        test(ModernPrimaryStringObject(), "a", "b")
        test(ModernPrimaryOptionalStringObject(), "a", nil)
        test(ModernPrimaryUUIDObject(), UUID(), UUID())
        test(ModernPrimaryOptionalUUIDObject(), UUID(), nil)
        test(ModernPrimaryObjectIdObject(), ObjectId.generate(), ObjectId.generate())
        test(ModernPrimaryOptionalObjectIdObject(), ObjectId.generate(), nil)

        realm.cancelWrite()
    }

    func testDynamicDefaultPropertyValues() {
        func assertDifferentPropertyValues(_ obj1: ModernDynamicDefaultObject, _ obj2: ModernDynamicDefaultObject) {
            XCTAssertNotEqual(obj1.intCol, obj2.intCol)
            XCTAssertNotEqual(obj1.floatCol, obj2.floatCol)
            XCTAssertNotEqual(obj1.doubleCol, obj2.doubleCol)
            XCTAssertNotEqual(obj1.dateCol.timeIntervalSinceReferenceDate, obj2.dateCol.timeIntervalSinceReferenceDate,
                              accuracy: 0.01)
            XCTAssertNotEqual(obj1.stringCol, obj2.stringCol)
            XCTAssertNotEqual(obj1.binaryCol, obj2.binaryCol)
        }
        assertDifferentPropertyValues(ModernDynamicDefaultObject(), ModernDynamicDefaultObject())
        let realm = try! Realm()
        try! realm.write {
            assertDifferentPropertyValues(realm.create(ModernDynamicDefaultObject.self),
                                          realm.create(ModernDynamicDefaultObject.self))
        }
    }

    #if false
    func testValueForKeyLinkingObjects() {
        let test: (ModernDogObject) -> Void = { object in
            let owners = object.value(forKey: "owners") as! LinkingObjects<ModernOwnerObject>
            if object.realm != nil {
                XCTAssertEqual(owners.first!.name, "owner name")
            }
        }

        let dog = ModernDogObject()
        let owner = ModernOwnerObject(value: ["owner name", dog])
        test(dog)
        let realm = try! Realm()
        try! realm.write {
            test(realm.create(ModernOwnerObject.self, value: owner).dog!)
            realm.add(owner)
            test(dog)
        }
    }

    func testSettingUnmanagedObjectValuesWithModernDictionary() {
        let json: [String: Any] = ["name": "foo", "array": [["stringCol": "bar"]], "intArray": [["intCol": 50]]]
        let object = ModernArrayPropertyObject()
        json.keys.forEach { key in
            object.setValue(json[key], forKey: key)
        }
        XCTAssertEqual(object.name, "foo")
        XCTAssertEqual(object.array[0].stringCol, "bar")
        XCTAssertEqual(object.intArray[0].intCol, 50)

        let json2: [String: Any] = ["name": "foo", "set": [["stringCol": "bar"]], "intSet": [["intCol": 50]]]
        let object2 = ModernMutableSetPropertyObject()
        json2.keys.forEach { key in
            object2.setValue(json2[key], forKey: key)
        }
        XCTAssertEqual(object2.name, "foo")
        XCTAssertEqual(object2.set[0].stringCol, "bar")
        XCTAssertEqual(object2.intSet[0].intCol, 50)
    }

    func testSettingUnmanagedObjectValuesWithBadModernDictionary() {
        let json: [String: Any] = ["name": "foo", "array": [["stringCol": NSObject()]], "intArray": [["intCol": 50]]]
        let object = ModernArrayPropertyObject()
        assertThrows({ json.keys.forEach { key in object.setValue(json[key], forKey: key) } }())

        let json2: [String: Any] = ["name": "foo", "set": [["stringCol": NSObject()]], "intSet": [["intCol": 50]]]
        let object2 = ModernMutableSetPropertyObject()
        assertThrows({ json2.keys.forEach { key in object2.setValue(json2[key], forKey: key) } }())
    }
    #endif
}
