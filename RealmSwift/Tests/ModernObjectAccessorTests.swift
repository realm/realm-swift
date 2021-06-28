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
import Realm.Private
import RealmSwift
import Foundation

class ModernObjectAccessorTests: TestCase {
    let data = "b".data(using: .utf8, allowLossyConversion: false)!
    let date = Date(timeIntervalSinceReferenceDate: 2)
    let oid1 = ObjectId("1234567890ab1234567890ab")
    let oid2 = ObjectId("abcdef123456abcdef123456")
    let utf8TestString = "值значен™👍☞⎠‱௹♣︎☐▼❒∑⨌⧭иеمرحبا"
    let uuid = UUID()

    func setAndTestAllPropertiesViaNormalAccess(_ object: ModernAllTypesObject) {
        func test<T: Equatable>(_ keyPath: ReferenceWritableKeyPath<ModernAllTypesObject, T>, _ values: T...) {
            for value in values {
                object[keyPath: keyPath] = value
                XCTAssertEqual(object[keyPath: keyPath], value)
            }
        }

        test(\.boolCol, true, false)
        test(\.intCol, -1, 0, 1)
        test(\.int8Col, -1, 0, 1)
        test(\.int16Col, -1, 0, 1)
        test(\.int32Col, -1, 0, 1)
        test(\.int64Col, -1, 0, 1)
        test(\.floatCol, -Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, 20, 20.2)
        test(\.doubleCol, -Double.greatestFiniteMagnitude, Double.greatestFiniteMagnitude, 20, 20.2, 16777217)
        test(\.stringCol, "", utf8TestString)
        test(\.binaryCol, data)
        test(\.dateCol, date)
        test(\.decimalCol, "inf", 1, 0, "0", -1, "-inf")
        test(\.objectIdCol, oid1, oid2)
        test(\.uuidCol, uuid)
        test(\.objectCol, ModernAllTypesObject(), nil)
        test(\.intEnumCol, .value1, .value2)
        test(\.stringEnumCol, .value1, .value2)

        test(\.optBoolCol, true, false, nil)
        test(\.optIntCol, Int.min, 0, Int.max, nil)
        test(\.optInt8Col, Int8.min, 0, Int8.max, nil)
        test(\.optInt16Col, Int16.min, 0, Int16.max, nil)
        test(\.optInt32Col, Int32.min, 0, Int32.max, nil)
        test(\.optInt64Col, Int64.min, 0, Int64.max, nil)
        test(\.optFloatCol, -Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, 20, 20.2, nil)
        test(\.optDoubleCol, -Double.greatestFiniteMagnitude, Double.greatestFiniteMagnitude, 20, 20.2, 16777217, nil)
        test(\.optStringCol, "", utf8TestString, nil)
        test(\.optBinaryCol, data, nil)
        test(\.optDateCol, date, nil)
        test(\.optDecimalCol, "inf", 1, 0, "0", -1, "-inf", nil)
        test(\.optObjectIdCol, oid1, oid2, nil)
        test(\.optUuidCol, uuid, nil)
        test(\.optIntEnumCol, .value1, .value2, nil)
        test(\.optStringEnumCol, .value1, .value2, nil)

        test(\.anyCol, .none, .int(1), .bool(false), .float(2.2),
                           .double(3.3), .string("str"), .data(data), .date(date),
                           .object(ModernAllTypesObject()), .objectId(oid1),
                           .decimal128(5), .uuid(UUID()))

        object.decimalCol = "nan"
        XCTAssertTrue(object.decimalCol.isNaN)
        object.optDecimalCol = "nan"
        XCTAssertTrue(object.optDecimalCol!.isNaN)

        object["optIntEnumCol"] = 10
        XCTAssertNil(object.optIntEnumCol)

        object.objectCol = ModernAllTypesObject()
        if object.realm == nil {
            XCTAssertEqual(object.objectCol!.linkingObjects.count, 0)
        } else {
            XCTAssertEqual(object.objectCol!.linkingObjects.count, 1)
            XCTAssertEqual(object.objectCol!.linkingObjects[0], object)
        }
    }

    func setAndTestAllPropertiesViaSubscript(_ object: ModernAllTypesObject) {
        func testNoConversion<T: Equatable>(_ keyPath: String, _ type: T.Type, _ values: T...) {
            for value in values {
                object[keyPath] = value
                XCTAssertEqual(object[keyPath] as! T, value)
            }
            for value in values {
                object.setValue(value, forKey: keyPath)
                XCTAssertEqual(object.value(forKey: keyPath) as! T, value)
            }
        }

        testNoConversion("boolCol", Bool.self, true, false)
        testNoConversion("intCol", Int.self, -1, 0, 1)
        testNoConversion("int8Col", Int8.self, -1, 0, 1)
        testNoConversion("int16Col", Int16.self, -1, 0, 1)
        testNoConversion("int32Col", Int32.self, -1, 0, 1)
        testNoConversion("int64Col", Int64.self, -1, 0, 1)
        testNoConversion("floatCol", Float.self, -Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, 20, 20.2)
        testNoConversion("doubleCol", Double.self, -Double.greatestFiniteMagnitude, Double.greatestFiniteMagnitude, 20, 20.2, 16777217)
        testNoConversion("stringCol", String.self, "", utf8TestString)
        testNoConversion("binaryCol", Data.self, data)
        testNoConversion("dateCol", Date.self, date)
        testNoConversion("decimalCol", Decimal128.self, "inf", 1, 0, "0", -1, "-inf")
        testNoConversion("objectIdCol", ObjectId.self, oid1, oid2)
        testNoConversion("uuidCol", UUID.self, uuid)
        testNoConversion("objectCol", ModernAllTypesObject?.self, ModernAllTypesObject(), nil)

        testNoConversion("optBoolCol", Bool?.self, true, false, nil)
        testNoConversion("optIntCol", Int?.self, Int.min, 0, Int.max, nil)
        testNoConversion("optInt8Col", Int8?.self, Int8.min, 0, Int8.max, nil)
        testNoConversion("optInt16Col", Int16?.self, Int16.min, 0, Int16.max, nil)
        testNoConversion("optInt32Col", Int32?.self, Int32.min, 0, Int32.max, nil)
        testNoConversion("optInt64Col", Int64?.self, Int64.min, 0, Int64.max, nil)
        testNoConversion("optFloatCol", Float?.self, -Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, 20, 20.2, nil)
        testNoConversion("optDoubleCol", Double?.self, -Double.greatestFiniteMagnitude, Double.greatestFiniteMagnitude, 20, 20.2, 16777217, nil)
        testNoConversion("optStringCol", String?.self, "", utf8TestString, nil)
        testNoConversion("optBinaryCol", Data?.self, data, nil)
        testNoConversion("optDateCol", Date?.self, date, nil)
        testNoConversion("optDecimalCol", Decimal128?.self, "inf", 1, 0, "0", -1, "-inf", nil)
        testNoConversion("optObjectIdCol", ObjectId?.self, oid1, oid2, nil)
        testNoConversion("optUuidCol", UUID?.self, uuid, nil)

        func testConversion<Expected: Equatable>(_ keyPath: String, _ value: Any, _ expected: Expected) {
            object[keyPath] = value
            XCTAssertEqual(object[keyPath] as! Expected, expected)
            object.setValue(value, forKey: keyPath)
            XCTAssertEqual(object.value(forKey: keyPath) as! Expected, expected)
        }

        testConversion("decimalCol", 1, 1 as Decimal128)
        testConversion("decimalCol", 2.2 as Float, 2.2 as Decimal128)
        testConversion("decimalCol", 3.3 as Double, 3.3 as Decimal128)
        testConversion("decimalCol", "4.4", 4.4 as Decimal128)
        testConversion("decimalCol", Decimal(5.5), 5.5 as Decimal128)

        testConversion("intEnumCol", ModernIntEnum.value1, ModernIntEnum.value1.rawValue)
        testConversion("intEnumCol", ModernIntEnum.value2, ModernIntEnum.value2.rawValue)
        testConversion("stringEnumCol", ModernStringEnum.value1, ModernStringEnum.value1.rawValue)
        testConversion("stringEnumCol", ModernStringEnum.value2, ModernStringEnum.value2.rawValue)

        testConversion("optDecimalCol", 1, 1 as Decimal128)
        testConversion("optDecimalCol", 2.2 as Float, 2.2 as Decimal128)
        testConversion("optDecimalCol", 3.3 as Double, 3.3 as Decimal128)
        testConversion("optDecimalCol", "4.4", 4.4 as Decimal128)
        testConversion("optDecimalCol", Decimal(5.5), 5.5 as Decimal128)
        testConversion("optDecimalCol", NSNull(), nil as Decimal128?)

        testConversion("optIntEnumCol", ModernIntEnum.value2, ModernIntEnum.value2.rawValue)
        testConversion("optIntEnumCol", nil as ModernIntEnum? as Any, nil as ModernIntEnum?)
        testConversion("optStringEnumCol", ModernStringEnum.value1, ModernStringEnum.value1.rawValue)
        testConversion("optStringEnumCol", nil as ModernStringEnum? as Any, nil as ModernStringEnum?)

        let obj = ModernAllTypesObject()
        testConversion("anyCol", AnyRealmValue.int(1), 1)
        testConversion("anyCol", AnyRealmValue.bool(false), false)
        testConversion("anyCol", AnyRealmValue.float(2.2), 2.2 as Float)
        testConversion("anyCol", AnyRealmValue.double(3.3), 3.3)
        testConversion("anyCol", AnyRealmValue.string("str"), "str")
        testConversion("anyCol", AnyRealmValue.data(data), data)
        testConversion("anyCol", AnyRealmValue.date(date), date)
        testConversion("anyCol", AnyRealmValue.object(obj), obj)
        testConversion("anyCol", AnyRealmValue.objectId(oid1), oid1)
        testConversion("anyCol", AnyRealmValue.decimal128(5), Decimal128(5))
        testConversion("anyCol", AnyRealmValue.uuid(uuid), uuid)

        object["anyCol"] = AnyRealmValue.none
        if case Optional<Any>.none = object["anyCol"] {
        } else {
            XCTFail("\(String(describing: object["anyCol"])) should be nil")
        }
        object.setValue(AnyRealmValue.none, forKey: "anyCol")
        if case Optional<Any>.none = object["anyCol"] {
        } else {
            XCTFail("\(String(describing: object["anyCol"])) should be nil")
        }

        object["decimalCol"] = Decimal128("nan")
        XCTAssertTrue((object["decimalCol"] as! Decimal128).isNaN)
        object["optDecimalCol"] = Decimal128("nan")
        XCTAssertTrue((object["optDecimalCol"] as! Decimal128).isNaN)

        object["optIntEnumCol"] = 10
        XCTAssertNil(object["optIntEnumCol"])

        object.objectCol = ModernAllTypesObject()
        let linkingObjects = (object["objectCol"]! as! ModernAllTypesObject)["linkingObjects"] as! LinkingObjects<ModernAllTypesObject>
        if object.realm == nil {
            XCTAssertEqual(linkingObjects.count, 0)
        } else {
            XCTAssertEqual(linkingObjects.count, 1)
            XCTAssertEqual(linkingObjects[0], object)
        }
    }

    func get(_ object: ObjectBase, _ propertyName: String) -> Any {
        let prop = RLMObjectBaseObjectSchema(object)!.properties.first { $0.name == propertyName }!
        return prop.swiftAccessor!.get(prop, on: object)
    }
    func set(_ object: ObjectBase, _ propertyName: String, _ value: Any) {
        let prop = RLMObjectBaseObjectSchema(object)!.properties.first { $0.name == propertyName }!
        prop.swiftAccessor!.set(prop, on: object, to: value)
    }

    func assertEqual<T: Equatable>(_ lhs: Any, _ rhs: T) {
        if rhs is NSNull {
            XCTAssertTrue(lhs is NSNull)
        } else if lhs is NSNull {
            XCTAssertEqual((T.self as! ExpressibleByNilLiteral.Type).init(nilLiteral: ()) as! T, rhs)
        } else {
            XCTAssertEqual(lhs as! T, rhs)
        }
    }

    func setAndTestAllPropertiesViaAccessor(_ object: ModernAllTypesObject) {
        func testNoConversion<T: Equatable>(_ keyPath: String, _ type: T.Type, _ values: T...) {
            for value in values {
                set(object, keyPath, value)
                assertEqual(get(object, keyPath), value)
            }
        }

        testNoConversion("boolCol", Bool.self, true, false)
        testNoConversion("intCol", Int.self, -1, 0, 1)
        testNoConversion("int8Col", Int8.self, -1, 0, 1)
        testNoConversion("int16Col", Int16.self, -1, 0, 1)
        testNoConversion("int32Col", Int32.self, -1, 0, 1)
        testNoConversion("int64Col", Int64.self, -1, 0, 1)
        testNoConversion("floatCol", Float.self, -Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, 20, 20.2)
        testNoConversion("doubleCol", Double.self, -Double.greatestFiniteMagnitude, Double.greatestFiniteMagnitude, 20, 20.2, 16777217)
        testNoConversion("stringCol", String.self, "", utf8TestString)
        testNoConversion("binaryCol", Data.self, data)
        testNoConversion("dateCol", Date.self, date)
        testNoConversion("decimalCol", Decimal128.self, "inf", 1, 0, "0", -1, "-inf")
        testNoConversion("objectIdCol", ObjectId.self, oid1, oid2)
        testNoConversion("uuidCol", UUID.self, uuid)
        testNoConversion("objectCol", ModernAllTypesObject?.self, ModernAllTypesObject(), nil)

        testNoConversion("optBoolCol", Bool?.self, true, false, nil)
        testNoConversion("optIntCol", Int?.self, Int.min, 0, Int.max, nil)
        testNoConversion("optInt8Col", Int8?.self, Int8.min, 0, Int8.max, nil)
        testNoConversion("optInt16Col", Int16?.self, Int16.min, 0, Int16.max, nil)
        testNoConversion("optInt32Col", Int32?.self, Int32.min, 0, Int32.max, nil)
        testNoConversion("optInt64Col", Int64?.self, Int64.min, 0, Int64.max, nil)
        testNoConversion("optFloatCol", Float?.self, -Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, 20, 20.2, nil)
        testNoConversion("optDoubleCol", Double?.self, -Double.greatestFiniteMagnitude, Double.greatestFiniteMagnitude, 20, 20.2, 16777217, nil)
        testNoConversion("optStringCol", String?.self, "", utf8TestString, nil)
        testNoConversion("optBinaryCol", Data?.self, data, nil)
        testNoConversion("optDateCol", Date?.self, date, nil)
        testNoConversion("optDecimalCol", Decimal128?.self, "inf", 1, 0, "0", -1, "-inf", nil)
        testNoConversion("optObjectIdCol", ObjectId?.self, oid1, oid2, nil)
        testNoConversion("optUuidCol", UUID?.self, uuid, nil)

        func testAny<T: Equatable>(_ value: T) {
            set(object, "anyCol", value)
            XCTAssertEqual(get(object, "anyCol") as! T, value)
        }

        testAny(NSNull())
        testAny(1)
        testAny(false)
        testAny(2.2 as Float)
        testAny(3.3)
        testAny("str")
        testAny(data)
        testAny(date)
        testAny(ModernAllTypesObject())
        testAny(oid1)
        testAny(Decimal128(5))
        testAny(uuid)

        func testConversion<Expected: Equatable>(_ keyPath: String, _ value: Any, _ expected: Expected) {
            set(object, keyPath, value)
            assertEqual(get(object, keyPath), expected)
        }

        testConversion("decimalCol", 1, 1 as Decimal128)
        testConversion("decimalCol", 2.2 as Float, 2.2 as Decimal128)
        testConversion("decimalCol", 3.3 as Double, 3.3 as Decimal128)
        testConversion("decimalCol", "4.4", 4.4 as Decimal128)
        testConversion("decimalCol", Decimal(5.5), 5.5 as Decimal128)

        testConversion("intEnumCol", ModernIntEnum.value1, ModernIntEnum.value1.rawValue)
        testConversion("intEnumCol", ModernIntEnum.value2, ModernIntEnum.value2.rawValue)
        testConversion("stringEnumCol", ModernStringEnum.value1, ModernStringEnum.value1.rawValue)
        testConversion("stringEnumCol", ModernStringEnum.value2, ModernStringEnum.value2.rawValue)

        testConversion("optDecimalCol", 1, 1 as Decimal128)
        testConversion("optDecimalCol", 2.2 as Float, 2.2 as Decimal128)
        testConversion("optDecimalCol", 3.3 as Double, 3.3 as Decimal128)
        testConversion("optDecimalCol", "4.4", 4.4 as Decimal128)
        testConversion("optDecimalCol", Decimal(5.5), 5.5 as Decimal128)
        testConversion("optDecimalCol", NSNull(), nil as Decimal128?)

        testConversion("optIntEnumCol", ModernIntEnum.value2, ModernIntEnum.value2.rawValue)
        testConversion("optIntEnumCol", nil as ModernIntEnum? as Any, nil as ModernIntEnum?)
        testConversion("optStringEnumCol", ModernStringEnum.value1, ModernStringEnum.value1.rawValue)
        testConversion("optStringEnumCol", nil as ModernStringEnum? as Any, nil as ModernStringEnum?)

        let obj = ModernAllTypesObject()
        testConversion("anyCol", AnyRealmValue.none, NSNull())
        testConversion("anyCol", AnyRealmValue.int(1), 1)
        testConversion("anyCol", AnyRealmValue.bool(false), false)
        testConversion("anyCol", AnyRealmValue.float(2.2), 2.2 as Float)
        testConversion("anyCol", AnyRealmValue.double(3.3), 3.3)
        testConversion("anyCol", AnyRealmValue.string("str"), "str")
        testConversion("anyCol", AnyRealmValue.data(data), data)
        testConversion("anyCol", AnyRealmValue.date(date), date)
        testConversion("anyCol", AnyRealmValue.object(obj), obj)
        testConversion("anyCol", AnyRealmValue.objectId(oid1), oid1)
        testConversion("anyCol", AnyRealmValue.decimal128(5), Decimal128(5))
        testConversion("anyCol", AnyRealmValue.uuid(uuid), uuid)

        object["decimalCol"] = Decimal128("nan")
        XCTAssertTrue((object["decimalCol"] as! Decimal128).isNaN)
        object["optDecimalCol"] = Decimal128("nan")
        XCTAssertTrue((object["optDecimalCol"] as! Decimal128).isNaN)
    }

    func setAndTestList(_ object: ModernAllTypesObject) {
        func test<T: RealmCollectionValue>(_ name: String, _ keyPath: ReferenceWritableKeyPath<ModernAllTypesObject, List<T>>, _ values: T...) {
            // Getter should return correct type
            XCTAssertTrue(get(object, name) is List<T>)
            // Getter should return the same object each time
            XCTAssertTrue(get(object, name) as AnyObject === get(object, name) as AnyObject)

            // Which should be the same object as is obtained from reading the property directly
            let list = object[keyPath: keyPath]
            XCTAssertTrue(get(object, name) as! List<T> === list)

            // Assigning a list to the property should copy the contents of the list, and not set
            // the property pointing to the assigned list
            let list2 = List<T>()
            list2.append(objectsIn: values)
            object[keyPath: keyPath] = list2
            XCTAssertEqual(Array(list), values)
            XCTAssertFalse(list2 === get(object, name) as AnyObject)

            // Self-assignment should be a no-op and not clear the list
            object[keyPath: keyPath] = object[keyPath: keyPath]
            XCTAssertEqual(Array(list), values)
            object.setValue(object.value(forKey: name), forKey: name)
            XCTAssertEqual(Array(list), values)

            // Setting via the accessor directly should do the same thing as assigning to the
            // property
            list.removeAll()
            set(object, name, list2)
            XCTAssertEqual(Array(list), values)
            XCTAssertFalse(list2 === get(object, name) as AnyObject)

            set(object, name, get(object, name))
            XCTAssertEqual(Array(list), values)
            set(object, name, RLMDynamicGetByName(object, name)!)
            XCTAssertEqual(Array(list), values)

            // The accessor should accept any enumerable type and not just List, so we should be
            // able to assign an array directly
            list.removeAll()
            set(object, name, values)
            XCTAssertEqual(Array(list), values)
            XCTAssertTrue(get(object, name) as! List<T> === list)

            // Assigning null to a List clears it
            set(object, name, NSNull())
            XCTAssertEqual(list.count, 0)
        }

        test("arrayBool", \.arrayBool, false, true)
        test("arrayInt", \.arrayInt, Int.min, 0, Int.max)
        test("arrayInt8", \.arrayInt8, Int8.min, 0, Int8.max)
        test("arrayInt16", \.arrayInt16, Int16.min, 0, Int16.max)
        test("arrayInt32", \.arrayInt32, Int32.min, 0, Int32.max)
        test("arrayInt64", \.arrayInt64, Int64.min, 0, Int64.max)
        test("arrayFloat", \.arrayFloat, -Float.greatestFiniteMagnitude, 0, Float.greatestFiniteMagnitude)
        test("arrayDouble", \.arrayDouble, -Double.greatestFiniteMagnitude, 0, Double.greatestFiniteMagnitude)
        test("arrayString", \.arrayString, "a", "b", "c")
        test("arrayBinary", \.arrayBinary, data)
        test("arrayDate", \.arrayDate, date)
        test("arrayDecimal", \.arrayDecimal, Decimal128(1), Decimal128(2))
        test("arrayObjectId", \.arrayObjectId, oid1, oid2)
        test("arrayUuid", \.arrayUuid, uuid)

        test("arrayOptBool", \.arrayOptBool, false, true, nil)
        test("arrayOptInt", \.arrayOptInt, Int.min, 0, Int.max, nil)
        test("arrayOptInt8", \.arrayOptInt8, Int8.min, 0, Int8.max, nil)
        test("arrayOptInt16", \.arrayOptInt16, Int16.min, 0, Int16.max, nil)
        test("arrayOptInt32", \.arrayOptInt32, Int32.min, 0, Int32.max, nil)
        test("arrayOptInt64", \.arrayOptInt64, Int64.min, 0, Int64.max, nil)
        test("arrayOptFloat", \.arrayOptFloat, -Float.greatestFiniteMagnitude, 0, Float.greatestFiniteMagnitude, nil)
        test("arrayOptDouble", \.arrayOptDouble, -Double.greatestFiniteMagnitude, 0, Double.greatestFiniteMagnitude, nil)
        test("arrayOptString", \.arrayOptString, "a", "b", "c", nil)
        test("arrayOptBinary", \.arrayOptBinary, data, nil)
        test("arrayOptDate", \.arrayOptDate, date, nil)
        test("arrayOptDecimal", \.arrayOptDecimal, Decimal128(1), Decimal128(2), nil)
        test("arrayOptObjectId", \.arrayOptObjectId, oid1, oid2, nil)
        test("arrayOptUuid", \.arrayOptUuid, uuid, nil)

        let obj = ModernAllTypesObject()
        test("arrayAny", \.arrayAny, .none, .int(1), .bool(false), .float(2.2), .double(3.3),
             .string("str"), .data(data), .date(date), .object(obj), .objectId(oid1),
             .decimal128(5), .uuid(uuid))
    }

    func assertSetEquals<T: RealmCollectionValue>(_ set: MutableSet<T>, _ expected: Array<T>) {
        XCTAssertEqual(set.count, expected.count)
        XCTAssertEqual(Set(set), Set(expected))
    }

    func setAndTestSet(_ object: ModernAllTypesObject) {
        func test<T: RealmCollectionValue>(_ name: String, _ keyPath: ReferenceWritableKeyPath<ModernAllTypesObject, MutableSet<T>>, _ values: T...) {
            // Getter should return correct type
            XCTAssertTrue(get(object, name) is MutableSet<T>)
            // Getter should return the same object each time
            XCTAssertTrue(get(object, name) as AnyObject === get(object, name) as AnyObject)

            // Which should be the same object as is obtained from reading the property directly
            let collection = object[keyPath: keyPath]
            XCTAssertTrue(get(object, name) as! MutableSet<T> === collection)

            // Assigning a collection to the property should copy the contents of the list, and not set
            // the property pointing to the assigned collection
            let collection2 = MutableSet<T>()
            collection2.insert(objectsIn: values)
            object[keyPath: keyPath] = collection2
            assertSetEquals(collection, values)
            XCTAssertFalse(collection2 === get(object, name) as AnyObject)

            // Self-assignment should be a no-op and not clear the collection
            object[keyPath: keyPath] = object[keyPath: keyPath]
            assertSetEquals(collection, values)
            object.setValue(object.value(forKey: name), forKey: name)
            assertSetEquals(collection, values)

            // Setting via the accessor directly should do the same thing as assigning to the
            // property
            collection.removeAll()
            set(object, name, collection2)
            assertSetEquals(collection, values)
            XCTAssertFalse(collection2 === get(object, name) as AnyObject)
            set(object, name, get(object, name))
            assertSetEquals(collection, values)

            // The accessor should accept any enumerable type and not just Set, so we should be
            // able to assign an set directly
            collection.removeAll()
            set(object, name, values)
            assertSetEquals(collection, values)
            XCTAssertTrue(get(object, name) as! MutableSet<T> === collection)

            // Assigning null to a Set clears it
            set(object, name, NSNull())
            XCTAssertEqual(collection.count, 0)
        }

        test("setBool", \.setBool, false, true)
        test("setInt", \.setInt, Int.min, 0, Int.max)
        test("setInt8", \.setInt8, Int8.min, 0, Int8.max)
        test("setInt16", \.setInt16, Int16.min, 0, Int16.max)
        test("setInt32", \.setInt32, Int32.min, 0, Int32.max)
        test("setInt64", \.setInt64, Int64.min, 0, Int64.max)
        test("setFloat", \.setFloat, -Float.greatestFiniteMagnitude, 0, Float.greatestFiniteMagnitude)
        test("setDouble", \.setDouble, -Double.greatestFiniteMagnitude, 0, Double.greatestFiniteMagnitude)
        test("setString", \.setString, "a", "b", "c")
        test("setBinary", \.setBinary, data)
        test("setDate", \.setDate, date)
        test("setDecimal", \.setDecimal, Decimal128(1), Decimal128(2))
        test("setObjectId", \.setObjectId, oid1, oid2)
        test("setUuid", \.setUuid, uuid)

        test("setOptBool", \.setOptBool, false, true, nil)
        test("setOptInt", \.setOptInt, Int.min, 0, Int.max, nil)
        test("setOptInt8", \.setOptInt8, Int8.min, 0, Int8.max, nil)
        test("setOptInt16", \.setOptInt16, Int16.min, 0, Int16.max, nil)
        test("setOptInt32", \.setOptInt32, Int32.min, 0, Int32.max, nil)
        test("setOptInt64", \.setOptInt64, Int64.min, 0, Int64.max, nil)
        test("setOptFloat", \.setOptFloat, -Float.greatestFiniteMagnitude, 0, Float.greatestFiniteMagnitude, nil)
        test("setOptDouble", \.setOptDouble, -Double.greatestFiniteMagnitude, 0, Double.greatestFiniteMagnitude, nil)
        test("setOptString", \.setOptString, "a", "b", "c", nil)
        test("setOptBinary", \.setOptBinary, data, nil)
        test("setOptDate", \.setOptDate, date, nil)
        test("setOptDecimal", \.setOptDecimal, Decimal128(1), Decimal128(2), nil)
        test("setOptObjectId", \.setOptObjectId, oid1, oid2, nil)
        test("setOptUuid", \.setOptUuid, uuid, nil)

        let obj = ModernAllTypesObject()
        test("setAny", \.setAny, .none, .int(1), .bool(false), .float(2.2), .double(3.3),
             .string("str"), .data(data), .date(date), .object(obj), .objectId(oid1),
             .decimal128(5), .uuid(uuid))
    }

    func assertMapEquals<T: RealmCollectionValue>(_ map: Map<String, T>, _ expected: Array<T>) {
        XCTAssertEqual(map.count, expected.count)
        for (i, value) in expected.enumerated() {
            XCTAssertEqual(map["\(i)"], value)
        }
    }

    func setAndTestMap(_ object: ModernAllTypesObject) {
        func test<T: RealmCollectionValue>(_ name: String,
                                           _ keyPath: ReferenceWritableKeyPath<ModernAllTypesObject, Map<String, T>>,
                                           _ values: T...) {
            var dictValues = [String: T]()
            for (i, value) in values.enumerated() {
                dictValues["\(i)"] = value
            }

            // Getter should return correct type
            XCTAssertTrue(get(object, name) is Map<String, T>)
            // Getter should return the same object each time
            XCTAssertTrue(get(object, name) as AnyObject === get(object, name) as AnyObject)

            // Which should be the same object as is obtained from reading the property directly
            let collection = object[keyPath: keyPath]
            XCTAssertTrue(get(object, name) as! Map<String, T> === collection)

            // Assigning a collection to the property should copy the contents of the list, and not set
            // the property pointing to the assigned collection
            let collection2 = Map<String, T>()
            collection2.merge(dictValues) { $1 }
            object[keyPath: keyPath] = collection2
            assertMapEquals(collection, values)
            XCTAssertFalse(collection2 === get(object, name) as AnyObject)

            // Self-assignment should be a no-op and not clear the collection
            object[keyPath: keyPath] = object[keyPath: keyPath]
            assertMapEquals(collection, values)
            object.setValue(object.value(forKey: name), forKey: name)
            assertMapEquals(collection, values)

            // setting via the accessor directly should do the same thing as assigning to the
            // property
            collection.removeAll()
            set(object, name, collection2)
            assertMapEquals(collection, values)
            XCTAssertFalse(collection2 === get(object, name) as AnyObject)
            set(object, name, get(object, name))
            assertMapEquals(collection, values)

            // The accessor should accept any enumerable type and not just map, so we should be
            // able to assign a dictionary directly
            collection.removeAll()
            set(object, name, dictValues)
            assertMapEquals(collection, values)
            XCTAssertTrue(get(object, name) as! Map<String, T> === collection)

            // Assigning null to a map clears it
            set(object, name, NSNull())
            XCTAssertEqual(collection.count, 0)
        }

        test("mapBool", \.mapBool, false, true)
        test("mapInt", \.mapInt, Int.min, 0, Int.max)
        test("mapInt8", \.mapInt8, Int8.min, 0, Int8.max)
        test("mapInt16", \.mapInt16, Int16.min, 0, Int16.max)
        test("mapInt32", \.mapInt32, Int32.min, 0, Int32.max)
        test("mapInt64", \.mapInt64, Int64.min, 0, Int64.max)
        test("mapFloat", \.mapFloat, -Float.greatestFiniteMagnitude, 0, Float.greatestFiniteMagnitude)
        test("mapDouble", \.mapDouble, -Double.greatestFiniteMagnitude, 0, Double.greatestFiniteMagnitude)
        test("mapString", \.mapString, "a", "b", "c")
        test("mapBinary", \.mapBinary, data)
        test("mapDate", \.mapDate, date)
        test("mapDecimal", \.mapDecimal, Decimal128(1), Decimal128(2))
        test("mapObjectId", \.mapObjectId, oid1, oid2)
        test("mapUuid", \.mapUuid, uuid)

        test("mapOptBool", \.mapOptBool, false, true, nil)
        test("mapOptInt", \.mapOptInt, Int.min, 0, Int.max, nil)
        test("mapOptInt8", \.mapOptInt8, Int8.min, 0, Int8.max, nil)
        test("mapOptInt16", \.mapOptInt16, Int16.min, 0, Int16.max, nil)
        test("mapOptInt32", \.mapOptInt32, Int32.min, 0, Int32.max, nil)
        test("mapOptInt64", \.mapOptInt64, Int64.min, 0, Int64.max, nil)
        test("mapOptFloat", \.mapOptFloat, -Float.greatestFiniteMagnitude, 0, Float.greatestFiniteMagnitude, nil)
        test("mapOptDouble", \.mapOptDouble, -Double.greatestFiniteMagnitude, 0, Double.greatestFiniteMagnitude, nil)
        test("mapOptString", \.mapOptString, "a", "b", "c", nil)
        test("mapOptBinary", \.mapOptBinary, data, nil)
        test("mapOptDate", \.mapOptDate, date, nil)
        test("mapOptDecimal", \.mapOptDecimal, Decimal128(1), Decimal128(2), nil)
        test("mapOptObjectId", \.mapOptObjectId, oid1, oid2, nil)
        test("mapOptUuid", \.mapOptUuid, uuid, nil)

        let obj = ModernAllTypesObject()
        test("mapAny", \.mapAny, .none, .int(1), .bool(false), .float(2.2), .double(3.3),
             .string("str"), .data(data), .date(date), .object(obj), .objectId(oid1),
             .decimal128(5), .uuid(uuid))
    }

    func testUnmanagedAccessors() {
        setAndTestAllPropertiesViaNormalAccess(ModernAllTypesObject())
        setAndTestAllPropertiesViaSubscript(ModernAllTypesObject())
        setAndTestAllPropertiesViaAccessor(ModernAllTypesObject())
        setAndTestList(ModernAllTypesObject())
        setAndTestSet(ModernAllTypesObject())
        setAndTestMap(ModernAllTypesObject())
    }

    func testManagedAccessorsReadFromRealm() {
        let realm = try! Realm()
        realm.beginWrite()
        let object = realm.create(ModernAllTypesObject.self)
        setAndTestAllPropertiesViaNormalAccess(object)
        setAndTestAllPropertiesViaSubscript(object)
        setAndTestAllPropertiesViaAccessor(object)
        setAndTestList(object)
        setAndTestSet(object)
        setAndTestMap(object)
        realm.cancelWrite()
    }

    func testManagedAccessorsAddedToRealm() {
        let realm = try! Realm()
        realm.beginWrite()
        let object = ModernAllTypesObject()
        realm.add(object)
        setAndTestAllPropertiesViaNormalAccess(object)
        setAndTestAllPropertiesViaSubscript(object)
        setAndTestAllPropertiesViaAccessor(object)
        setAndTestList(object)
        setAndTestSet(object)
        setAndTestMap(object)
        realm.cancelWrite()
    }

    func testThreadChecking() {
        let realm = try! Realm()
        var obj: ModernAllTypesObject!
        try! realm.write {
            obj = realm.create(ModernAllTypesObject.self)
            // Create the lazily-initialized List to test the cached codepath
            obj.arrayInt.removeAll()
            obj.arrayInt8.removeAll()
        }
        dispatchSyncNewThread {
            self.assertThrows(_ = obj.intCol, reason: "incorrect thread")
            self.assertThrows(obj.arrayInt.removeAll(), reason: "incorrect thread")
            self.assertThrows(obj.int8Col = 5, reason: "incorrect thread")
            self.assertThrows(obj.arrayInt8 = List<Int8>(), reason: "incorrect thread")
        }
    }

    func testInvalidationChecking() {
        let realm = try! Realm()
        var obj: ModernAllTypesObject!
        try! realm.write {
            obj = realm.create(ModernAllTypesObject.self)
            // Create the lazily-initialized List to test the cached codepath
            obj.arrayInt.removeAll()
            obj.arrayInt8.removeAll()
        }
        realm.invalidate()
        self.assertThrows(_ = obj.intCol, reason: "invalidated")
        self.assertThrows(obj.arrayInt.removeAll(), reason: "invalidated")
        self.assertThrows(obj.int8Col = 5, reason: "invalidated")
        self.assertThrows(obj.arrayInt8 = List<Int8>(), reason: "invalidated")
    }

    func testObjectWithArcMethodFamilies() {
        let obj = ObjectWithArcMethodCategoryNames()
        obj.allocValue = "a"
        obj.initValue = "b"
        obj.copyValue = "c"
        obj.mutableCopyValue = "d"
        obj.newValue = "e"
        XCTAssertEqual(obj.allocValue, "a")
        XCTAssertEqual(obj.initValue, "b")
        XCTAssertEqual(obj.copyValue, "c")
        XCTAssertEqual(obj.mutableCopyValue, "d")
        XCTAssertEqual(obj.newValue, "e")
    }
}
