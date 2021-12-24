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
import Realm.Private

class ModernObjectCreationTests: TestCase {
    var values: [String: Any]!
    override func setUp() {
        values = [
            "boolCol": true,
            "intCol": 10,
            "int8Col": 11 as Int8,
            "int16Col": 12 as Int16,
            "int32Col": 13 as Int32,
            "int64Col": 14 as Int64,
            "floatCol": 15 as Float,
            "doubleCol": 16 as Double,
            "stringCol": "a",
            "binaryCol": "b".data(using: .utf8)!,
            "dateCol": Date(timeIntervalSince1970: 17),
            "decimalCol": 18 as Decimal128,
            "objectIdCol": ObjectId.generate(),
            "objectCol": ModernAllTypesObject(value: ["intCol": 1]),
            "arrayCol": [
                ModernAllTypesObject(value: ["intCol": 2]),
                ModernAllTypesObject(value: ["intCol": 3])
            ],
            "setCol": [
                ModernAllTypesObject(value: ["intCol": 4]),
                ModernAllTypesObject(value: ["intCol": 5]),
                ModernAllTypesObject(value: ["intCol": 6])
            ],
            "anyCol": AnyRealmValue.int(20),
            "uuidCol": UUID(),
            "intEnumCol": ModernIntEnum.value2,
            "stringEnumCol": ModernStringEnum.value3,

            "optBoolCol": false,
            "optIntCol": 30,
            "optInt8Col": 31 as Int8,
            "optInt16Col": 32 as Int16,
            "optInt32Col": 33 as Int32,
            "optInt64Col": 34 as Int64,
            "optFloatCol": 35 as Float,
            "optDoubleCol": 36 as Double,
            "optStringCol": "c",
            "optBinaryCol": "d".data(using: .utf8)!,
            "optDateCol": Date(timeIntervalSince1970: 37),
            "optDecimalCol": 38 as Decimal128,
            "optObjectIdCol": ObjectId.generate(),
            "optUuidCol": UUID(),
            "optIntEnumCol": ModernIntEnum.value1,
            "optStringEnumCol": ModernStringEnum.value1,

            "arrayBool": [true, false] as [Bool],
            "arrayInt": [1, 1, 2, 3] as [Int],
            "arrayInt8": [1, 2, 3, 1] as [Int8],
            "arrayInt16": [1, 2, 3, 1] as [Int16],
            "arrayInt32": [1, 2, 3, 1] as [Int32],
            "arrayInt64": [1, 2, 3, 1] as [Int64],
            "arrayFloat": [1 as Float, 2 as Float, 3 as Float, 1 as Float],
            "arrayDouble": [1 as Double, 2 as Double, 3 as Double, 1 as Double],
            "arrayString": ["a", "b", "c"] as [String],
            "arrayBinary": ["a".data(using: .utf8)!] as [Data],
            "arrayDate": [Date(), Date()] as [Date],
            "arrayDecimal": [1 as Decimal128, 2 as Decimal128],
            "arrayObjectId": [ObjectId.generate(), ObjectId.generate()],
            "arrayAny": [.none, .int(1), .string("a"), .none] as [AnyRealmValue],
            "arrayUuid": [UUID(), UUID(), UUID()],

            "arrayOptBool": [true, false, nil] as [Bool?],
            "arrayOptInt": [1, 1, 2, 3, nil] as [Int?],
            "arrayOptInt8": [1, 2, 3, 1, nil] as [Int8?],
            "arrayOptInt16": [1, 2, 3, 1, nil] as [Int16?],
            "arrayOptInt32": [1, 2, 3, 1, nil] as [Int32?],
            "arrayOptInt64": [1, 2, 3, 1, nil] as [Int64?],
            "arrayOptFloat": [1 as Float, 2 as Float, 3 as Float, 1 as Float, nil],
            "arrayOptDouble": [1 as Double, 2 as Double, 3 as Double, 1 as Double, nil],
            "arrayOptString": ["a", "b", "c", nil],
            "arrayOptBinary": ["a".data(using: .utf8)!, nil],
            "arrayOptDate": [Date(), Date(), nil],
            "arrayOptDecimal": [1 as Decimal128, 2 as Decimal128, nil],
            "arrayOptObjectId": [ObjectId.generate(), ObjectId.generate(), nil],
            "arrayOptUuid": [UUID(), UUID(), UUID(), nil],

            "setBool": [true, false] as [Bool],
            "setInt": [1, 1, 2, 3] as [Int],
            "setInt8": [1, 2, 3, 1] as [Int8],
            "setInt16": [1, 2, 3, 1] as [Int16],
            "setInt32": [1, 2, 3, 1] as [Int32],
            "setInt64": [1, 2, 3, 1] as [Int64],
            "setFloat": [1 as Float, 2 as Float, 3 as Float, 1 as Float],
            "setDouble": [1 as Double, 2 as Double, 3 as Double, 1 as Double],
            "setString": ["a", "b", "c"] as [String],
            "setBinary": ["a".data(using: .utf8)!] as [Data],
            "setDate": [Date(), Date()] as [Date],
            "setDecimal": [1 as Decimal128, 2 as Decimal128],
            "setObjectId": [ObjectId.generate(), ObjectId.generate()],
            "setAny": [.none, .int(1), .string("a"), .none] as [AnyRealmValue],
            "setUuid": [UUID(), UUID(), UUID()],

            "setOptBool": [true, false, nil] as [Bool?],
            "setOptInt": [1, 1, 2, 3, nil] as [Int?],
            "setOptInt8": [1, 2, 3, 1, nil] as [Int8?],
            "setOptInt16": [1, 2, 3, 1, nil] as [Int16?],
            "setOptInt32": [1, 2, 3, 1, nil] as [Int32?],
            "setOptInt64": [1, 2, 3, 1, nil] as [Int64?],
            "setOptFloat": [1 as Float, 2 as Float, 3 as Float, 1 as Float, nil],
            "setOptDouble": [1 as Double, 2 as Double, 3 as Double, 1 as Double, nil],
            "setOptString": ["a", "b", "c", nil],
            "setOptBinary": ["a".data(using: .utf8)!, nil],
            "setOptDate": [Date(), Date(), nil],
            "setOptDecimal": [1 as Decimal128, 2 as Decimal128, nil],
            "setOptObjectId": [ObjectId.generate(), ObjectId.generate(), nil],
            "setOptUuid": [UUID(), UUID(), UUID(), nil],

            "mapBool": ["1": true, "2": false] as [String: Bool],
            "mapInt": ["1": 1, "2": 1, "3": 2, "4": 3] as [String: Int],
            "mapInt8": ["1": 1, "2": 2, "3": 3, "4": 1] as [String: Int8],
            "mapInt16": ["1": 1, "2": 2, "3": 3, "4": 1] as [String: Int16],
            "mapInt32": ["1": 1, "2": 2, "3": 3, "4": 1] as [String: Int32],
            "mapInt64": ["1": 1, "2": 2, "3": 3, "4": 1] as [String: Int64],
            "mapFloat": ["1": 1 as Float, "2": 2 as Float, "3": 3 as Float, "4": 1 as Float],
            "mapDouble": ["1": 1 as Double, "2": 2 as Double, "3": 3 as Double, "4": 1 as Double],
            "mapString": ["1": "a", "2": "b", "3": "c"] as [String: String],
            "mapBinary": ["1": "a".data(using: .utf8)!] as [String: Data],
            "mapDate": ["1": Date(), "2": Date()] as [String: Date],
            "mapDecimal": ["1": 1 as Decimal128, "2": 2 as Decimal128],
            "mapObjectId": ["1": ObjectId.generate(), "2": ObjectId.generate()],
            "mapAny": ["1": .none, "2": .int(1), "3": .string("a"), "4": .none] as [String: AnyRealmValue],
            "mapUuid": ["1": UUID(), "2": UUID(), "3": UUID()],

            "mapOptBool": ["1": true, "2": false, "3": nil] as [String: Bool?],
            "mapOptInt": ["1": 1, "2": 1, "3": 2, "4": 3, "5": nil] as [String: Int?],
            "mapOptInt8": ["1": 1, "2": 2, "3": 3, "4": 1, "5": nil] as [String: Int8?],
            "mapOptInt16": ["1": 1, "2": 2, "3": 3, "4": 1, "5": nil] as [String: Int16?],
            "mapOptInt32": ["1": 1, "2": 2, "3": 3, "4": 1, "5": nil] as [String: Int32?],
            "mapOptInt64": ["1": 1, "2": 2, "3": 3, "4": 1, "5": nil] as [String: Int64?],
            "mapOptFloat": ["1": 1 as Float, "2": 2 as Float, "3": 3 as Float, "4": 1 as Float, "5": nil],
            "mapOptDouble": ["1": 1 as Double, "2": 2 as Double, "3": 3 as Double, "4": 1 as Double, "5": nil],
            "mapOptString": ["1": "a", "2": "b", "3": "c", "4": nil],
            "mapOptBinary": ["1": "a".data(using: .utf8)!, "2": nil],
            "mapOptDate": ["1": Date(), "2": Date(), "3": nil],
            "mapOptDecimal": ["1": 1 as Decimal128, "2": 2 as Decimal128, "3": nil],
            "mapOptObjectId": ["1": ObjectId.generate(), "2": ObjectId.generate(), "3": nil],
            "mapOptUuid": ["1": UUID(), "2": UUID(), "3": UUID(), "4": nil],
        ]
        super.setUp()
    }

    override func tearDown() {
        values = nil
        super.tearDown()
    }

    func nullValues() -> [String: Any] {
        return values.merging([
            "objectCol": NSNull(),
            "anyCol": AnyRealmValue.none,

            "optBoolCol": NSNull(),
            "optIntCol": NSNull(),
            "optInt8Col": NSNull(),
            "optInt16Col": NSNull(),
            "optInt32Col": NSNull(),
            "optInt64Col": NSNull(),
            "optFloatCol": NSNull(),
            "optDoubleCol": NSNull(),
            "optStringCol": NSNull(),
            "optBinaryCol": NSNull(),
            "optDateCol": NSNull(),
            "optDecimalCol": NSNull(),
            "optObjectIdCol": NSNull(),
            "optUuidCol": NSNull(),
            "optIntEnumCol": NSNull(),
            "optStringEnumCol": NSNull(),

            "arrayAny": [AnyRealmValue.none],
            "arrayOptBool": [NSNull()],
            "arrayOptInt": [NSNull()],
            "arrayOptInt8": [NSNull()],
            "arrayOptInt16": [NSNull()],
            "arrayOptInt32": [NSNull()],
            "arrayOptInt64": [NSNull()],
            "arrayOptFloat": [NSNull()],
            "arrayOptDouble": [NSNull()],
            "arrayOptString": [NSNull()],
            "arrayOptBinary": [NSNull()],
            "arrayOptDate": [NSNull()],
            "arrayOptDecimal": [NSNull()],
            "arrayOptObjectId": [NSNull()],
            "arrayOptUuid": [NSNull()],

            "setAny": [AnyRealmValue.none],
            "setOptBool": [NSNull()],
            "setOptInt": [NSNull()],
            "setOptInt8": [NSNull()],
            "setOptInt16": [NSNull()],
            "setOptInt32": [NSNull()],
            "setOptInt64": [NSNull()],
            "setOptFloat": [NSNull()],
            "setOptDouble": [NSNull()],
            "setOptString": [NSNull()],
            "setOptBinary": [NSNull()],
            "setOptDate": [NSNull()],
            "setOptDecimal": [NSNull()],
            "setOptObjectId": [NSNull()],
            "setOptUuid": [NSNull()],

            "mapAny": ["1": AnyRealmValue.none],
            "mapOptBool": ["1": NSNull()],
            "mapOptInt": ["1": NSNull()],
            "mapOptInt8": ["1": NSNull()],
            "mapOptInt16": ["1": NSNull()],
            "mapOptInt32": ["1": NSNull()],
            "mapOptInt64": ["1": NSNull()],
            "mapOptFloat": ["1": NSNull()],
            "mapOptDouble": ["1": NSNull()],
            "mapOptString": ["1": NSNull()],
            "mapOptBinary": ["1": NSNull()],
            "mapOptDate": ["1": NSNull()],
            "mapOptDecimal": ["1": NSNull()],
            "mapOptObjectId": ["1": NSNull()],
            "mapOptUuid": ["1": NSNull()]
        ] as [String: Any]) { _, null in null }
    }

    func assertSetEquals<T: RealmCollectionValue>(_ set: MutableSet<T>, _ expected: Array<T>) {
        XCTAssertEqual(set.count, Set(expected).count)
        XCTAssertEqual(Set(set), Set(expected))
    }

    func assertEquivalent(_ actual: AnyRealmCollection<ModernAllTypesObject>,
                          _ expected: Array<ModernAllTypesObject>,
                          expectedShouldBeCopy: Bool) {
        XCTAssertEqual(actual.count, expected.count)
        for obj in expected {
            if expectedShouldBeCopy {
                XCTAssertTrue(actual.contains { $0.pk == obj.pk })
            } else {
                XCTAssertTrue(actual.contains(obj))
            }
        }
    }

    func assertMapEquals<T: RealmCollectionValue>(_ actual: Map<String, T>, _ expected: Dictionary<String, T>) {
        XCTAssertEqual(actual.count, expected.count)
        for (key, value) in expected {
            XCTAssertEqual(actual[key], value)
        }
    }

    func verifyObject(_ obj: ModernAllTypesObject, expectedShouldBeCopy: Bool = true) {
        XCTAssertEqual(obj.boolCol, values["boolCol"] as! Bool)
        XCTAssertEqual(obj.intCol, values["intCol"] as! Int)
        XCTAssertEqual(obj.int8Col, values["int8Col"] as! Int8)
        XCTAssertEqual(obj.int16Col, values["int16Col"] as! Int16)
        XCTAssertEqual(obj.int32Col, values["int32Col"] as! Int32)
        XCTAssertEqual(obj.int64Col, values["int64Col"] as! Int64)
        XCTAssertEqual(obj.floatCol, values["floatCol"] as! Float)
        XCTAssertEqual(obj.doubleCol, values["doubleCol"] as! Double)
        XCTAssertEqual(obj.stringCol, values["stringCol"] as! String)
        XCTAssertEqual(obj.binaryCol, values["binaryCol"] as! Data)
        XCTAssertEqual(obj.dateCol, values["dateCol"] as! Date)
        XCTAssertEqual(obj.decimalCol, values["decimalCol"] as! Decimal128)
        XCTAssertEqual(obj.objectIdCol, values["objectIdCol"] as! ObjectId)
        XCTAssertEqual(obj.objectCol!.pk, (values["objectCol"] as! ModernAllTypesObject?)!.pk)
        assertEquivalent(AnyRealmCollection(obj.arrayCol),
                         values["arrayCol"] as! [ModernAllTypesObject],
                         expectedShouldBeCopy: expectedShouldBeCopy)
        assertEquivalent(AnyRealmCollection(obj.setCol),
                         values["setCol"] as! [ModernAllTypesObject],
                         expectedShouldBeCopy: expectedShouldBeCopy)
        XCTAssertEqual(obj.anyCol, values["anyCol"] as! AnyRealmValue)
        XCTAssertEqual(obj.uuidCol, values["uuidCol"] as! UUID)
        XCTAssertEqual(obj.intEnumCol, values["intEnumCol"] as! ModernIntEnum)
        XCTAssertEqual(obj.stringEnumCol, values["stringEnumCol"] as! ModernStringEnum)

        XCTAssertEqual(obj.optBoolCol, values["optBoolCol"] as! Bool?)
        XCTAssertEqual(obj.optIntCol, values["optIntCol"] as! Int?)
        XCTAssertEqual(obj.optInt8Col, values["optInt8Col"] as! Int8?)
        XCTAssertEqual(obj.optInt16Col, values["optInt16Col"] as! Int16?)
        XCTAssertEqual(obj.optInt32Col, values["optInt32Col"] as! Int32?)
        XCTAssertEqual(obj.optInt64Col, values["optInt64Col"] as! Int64?)
        XCTAssertEqual(obj.optFloatCol, values["optFloatCol"] as! Float?)
        XCTAssertEqual(obj.optDoubleCol, values["optDoubleCol"] as! Double?)
        XCTAssertEqual(obj.optStringCol, values["optStringCol"] as! String?)
        XCTAssertEqual(obj.optBinaryCol, values["optBinaryCol"] as! Data?)
        XCTAssertEqual(obj.optDateCol, values["optDateCol"] as! Date?)
        XCTAssertEqual(obj.optDecimalCol, values["optDecimalCol"] as! Decimal128?)
        XCTAssertEqual(obj.optObjectIdCol, values["optObjectIdCol"] as! ObjectId?)
        XCTAssertEqual(obj.optUuidCol, values["optUuidCol"] as! UUID?)
        XCTAssertEqual(obj.optIntEnumCol, values["optIntEnumCol"] as! ModernIntEnum?)
        XCTAssertEqual(obj.optStringEnumCol, values["optStringEnumCol"] as! ModernStringEnum?)

        XCTAssertEqual(Array(obj.arrayBool), values["arrayBool"] as! [Bool])
        XCTAssertEqual(Array(obj.arrayInt), values["arrayInt"] as! [Int])
        XCTAssertEqual(Array(obj.arrayInt8), values["arrayInt8"] as! [Int8])
        XCTAssertEqual(Array(obj.arrayInt16), values["arrayInt16"] as! [Int16])
        XCTAssertEqual(Array(obj.arrayInt32), values["arrayInt32"] as! [Int32])
        XCTAssertEqual(Array(obj.arrayInt64), values["arrayInt64"] as! [Int64])
        XCTAssertEqual(Array(obj.arrayFloat), values["arrayFloat"] as! [Float])
        XCTAssertEqual(Array(obj.arrayDouble), values["arrayDouble"] as! [Double])
        XCTAssertEqual(Array(obj.arrayString), values["arrayString"] as! [String])
        XCTAssertEqual(Array(obj.arrayBinary), values["arrayBinary"] as! [Data])
        XCTAssertEqual(Array(obj.arrayDate), values["arrayDate"] as! [Date])
        XCTAssertEqual(Array(obj.arrayDecimal), values["arrayDecimal"] as! [Decimal128])
        XCTAssertEqual(Array(obj.arrayObjectId), values["arrayObjectId"] as! [ObjectId])
        XCTAssertEqual(Array(obj.arrayAny), values["arrayAny"] as! [AnyRealmValue])
        XCTAssertEqual(Array(obj.arrayUuid), values["arrayUuid"] as! [UUID])

        XCTAssertEqual(Array(obj.arrayOptBool), values["arrayOptBool"] as! [Bool?])
        XCTAssertEqual(Array(obj.arrayOptInt), values["arrayOptInt"] as! [Int?])
        XCTAssertEqual(Array(obj.arrayOptInt8), values["arrayOptInt8"] as! [Int8?])
        XCTAssertEqual(Array(obj.arrayOptInt16), values["arrayOptInt16"] as! [Int16?])
        XCTAssertEqual(Array(obj.arrayOptInt32), values["arrayOptInt32"] as! [Int32?])
        XCTAssertEqual(Array(obj.arrayOptInt64), values["arrayOptInt64"] as! [Int64?])
        XCTAssertEqual(Array(obj.arrayOptFloat), values["arrayOptFloat"] as! [Float?])
        XCTAssertEqual(Array(obj.arrayOptDouble), values["arrayOptDouble"] as! [Double?])
        XCTAssertEqual(Array(obj.arrayOptString), values["arrayOptString"] as! [String?])
        XCTAssertEqual(Array(obj.arrayOptBinary), values["arrayOptBinary"] as! [Data?])
        XCTAssertEqual(Array(obj.arrayOptDate), values["arrayOptDate"] as! [Date?])
        XCTAssertEqual(Array(obj.arrayOptDecimal), values["arrayOptDecimal"] as! [Decimal128?])
        XCTAssertEqual(Array(obj.arrayOptObjectId), values["arrayOptObjectId"] as! [ObjectId?])
        XCTAssertEqual(Array(obj.arrayOptUuid), values["arrayOptUuid"] as! [UUID?])

        assertSetEquals(obj.setBool, values["setBool"] as! [Bool])
        assertSetEquals(obj.setInt, values["setInt"] as! [Int])
        assertSetEquals(obj.setInt8, values["setInt8"] as! [Int8])
        assertSetEquals(obj.setInt16, values["setInt16"] as! [Int16])
        assertSetEquals(obj.setInt32, values["setInt32"] as! [Int32])
        assertSetEquals(obj.setInt64, values["setInt64"] as! [Int64])
        assertSetEquals(obj.setFloat, values["setFloat"] as! [Float])
        assertSetEquals(obj.setDouble, values["setDouble"] as! [Double])
        assertSetEquals(obj.setString, values["setString"] as! [String])
        assertSetEquals(obj.setBinary, values["setBinary"] as! [Data])
        assertSetEquals(obj.setDate, values["setDate"] as! [Date])
        assertSetEquals(obj.setDecimal, values["setDecimal"] as! [Decimal128])
        assertSetEquals(obj.setObjectId, values["setObjectId"] as! [ObjectId])
        assertSetEquals(obj.setAny, values["setAny"] as! [AnyRealmValue])
        assertSetEquals(obj.setUuid, values["setUuid"] as! [UUID])

        assertSetEquals(obj.setOptBool, values["setOptBool"] as! [Bool?])
        assertSetEquals(obj.setOptInt, values["setOptInt"] as! [Int?])
        assertSetEquals(obj.setOptInt8, values["setOptInt8"] as! [Int8?])
        assertSetEquals(obj.setOptInt16, values["setOptInt16"] as! [Int16?])
        assertSetEquals(obj.setOptInt32, values["setOptInt32"] as! [Int32?])
        assertSetEquals(obj.setOptInt64, values["setOptInt64"] as! [Int64?])
        assertSetEquals(obj.setOptFloat, values["setOptFloat"] as! [Float?])
        assertSetEquals(obj.setOptDouble, values["setOptDouble"] as! [Double?])
        assertSetEquals(obj.setOptString, values["setOptString"] as! [String?])
        assertSetEquals(obj.setOptBinary, values["setOptBinary"] as! [Data?])
        assertSetEquals(obj.setOptDate, values["setOptDate"] as! [Date?])
        assertSetEquals(obj.setOptDecimal, values["setOptDecimal"] as! [Decimal128?])
        assertSetEquals(obj.setOptObjectId, values["setOptObjectId"] as! [ObjectId?])
        assertSetEquals(obj.setOptUuid, values["setOptUuid"] as! [UUID?])

        assertMapEquals(obj.mapBool, values["mapBool"] as! [String: Bool])
        assertMapEquals(obj.mapInt, values["mapInt"] as! [String: Int])
        assertMapEquals(obj.mapInt8, values["mapInt8"] as! [String: Int8])
        assertMapEquals(obj.mapInt16, values["mapInt16"] as! [String: Int16])
        assertMapEquals(obj.mapInt32, values["mapInt32"] as! [String: Int32])
        assertMapEquals(obj.mapInt64, values["mapInt64"] as! [String: Int64])
        assertMapEquals(obj.mapFloat, values["mapFloat"] as! [String: Float])
        assertMapEquals(obj.mapDouble, values["mapDouble"] as! [String: Double])
        assertMapEquals(obj.mapString, values["mapString"] as! [String: String])
        assertMapEquals(obj.mapBinary, values["mapBinary"] as! [String: Data])
        assertMapEquals(obj.mapDate, values["mapDate"] as! [String: Date])
        assertMapEquals(obj.mapDecimal, values["mapDecimal"] as! [String: Decimal128])
        assertMapEquals(obj.mapObjectId, values["mapObjectId"] as! [String: ObjectId])
        assertMapEquals(obj.mapAny, values["mapAny"] as! [String: AnyRealmValue])
        assertMapEquals(obj.mapUuid, values["mapUuid"] as! [String: UUID])

        assertMapEquals(obj.mapOptBool, values["mapOptBool"] as! [String: Bool?])
        assertMapEquals(obj.mapOptInt, values["mapOptInt"] as! [String: Int?])
        assertMapEquals(obj.mapOptInt8, values["mapOptInt8"] as! [String: Int8?])
        assertMapEquals(obj.mapOptInt16, values["mapOptInt16"] as! [String: Int16?])
        assertMapEquals(obj.mapOptInt32, values["mapOptInt32"] as! [String: Int32?])
        assertMapEquals(obj.mapOptInt64, values["mapOptInt64"] as! [String: Int64?])
        assertMapEquals(obj.mapOptFloat, values["mapOptFloat"] as! [String: Float?])
        assertMapEquals(obj.mapOptDouble, values["mapOptDouble"] as! [String: Double?])
        assertMapEquals(obj.mapOptString, values["mapOptString"] as! [String: String?])
        assertMapEquals(obj.mapOptBinary, values["mapOptBinary"] as! [String: Data?])
        assertMapEquals(obj.mapOptDate, values["mapOptDate"] as! [String: Date?])
        assertMapEquals(obj.mapOptDecimal, values["mapOptDecimal"] as! [String: Decimal128?])
        assertMapEquals(obj.mapOptObjectId, values["mapOptObjectId"] as! [String: ObjectId?])
        assertMapEquals(obj.mapOptUuid, values["mapOptUuid"] as! [String: UUID?])
    }

    func verifyDefault(_ obj: ModernAllTypesObject) {
        XCTAssertEqual(obj.boolCol, false)
        XCTAssertEqual(obj.intCol, 0)
        XCTAssertEqual(obj.int8Col, 1)
        XCTAssertEqual(obj.int16Col, 2)
        XCTAssertEqual(obj.int32Col, 3)
        XCTAssertEqual(obj.int64Col, 4)
        XCTAssertEqual(obj.floatCol, 5)
        XCTAssertEqual(obj.doubleCol, 6)
        XCTAssertEqual(obj.stringCol, "")
        XCTAssertEqual(obj.binaryCol, Data())
        XCTAssertEqual(obj.decimalCol, 0)
        XCTAssertNotEqual(obj.objectIdCol, ObjectId()) // should have generated a random ObjectId
        XCTAssertEqual(obj.objectCol, nil)
        XCTAssertEqual(obj.arrayCol.count, 0)
        XCTAssertEqual(obj.setCol.count, 0)
        XCTAssertEqual(obj.anyCol, .none)
        XCTAssertNotEqual(obj.uuidCol, UUID()) // should have generated a random UUID
        XCTAssertEqual(obj.intEnumCol, .value1)
        XCTAssertEqual(obj.stringEnumCol, .value1)

        XCTAssertNil(obj.optIntCol)
        XCTAssertNil(obj.optInt8Col)
        XCTAssertNil(obj.optInt16Col)
        XCTAssertNil(obj.optInt32Col)
        XCTAssertNil(obj.optInt64Col)
        XCTAssertNil(obj.optFloatCol)
        XCTAssertNil(obj.optDoubleCol)
        XCTAssertNil(obj.optBoolCol)
        XCTAssertNil(obj.optStringCol)
        XCTAssertNil(obj.optBinaryCol)
        XCTAssertNil(obj.optDateCol)
        XCTAssertNil(obj.optDecimalCol)
        XCTAssertNil(obj.optObjectIdCol)
        XCTAssertNil(obj.optUuidCol)
        XCTAssertNil(obj.optIntEnumCol)
        XCTAssertNil(obj.optStringEnumCol)

        XCTAssertEqual(obj.arrayBool.count, 0)
        XCTAssertEqual(obj.arrayInt.count, 0)
        XCTAssertEqual(obj.arrayInt8.count, 0)
        XCTAssertEqual(obj.arrayInt16.count, 0)
        XCTAssertEqual(obj.arrayInt32.count, 0)
        XCTAssertEqual(obj.arrayInt64.count, 0)
        XCTAssertEqual(obj.arrayFloat.count, 0)
        XCTAssertEqual(obj.arrayDouble.count, 0)
        XCTAssertEqual(obj.arrayString.count, 0)
        XCTAssertEqual(obj.arrayBinary.count, 0)
        XCTAssertEqual(obj.arrayDate.count, 0)
        XCTAssertEqual(obj.arrayDecimal.count, 0)
        XCTAssertEqual(obj.arrayObjectId.count, 0)
        XCTAssertEqual(obj.arrayAny.count, 0)
        XCTAssertEqual(obj.arrayUuid.count, 0)

        XCTAssertEqual(obj.arrayOptBool.count, 0)
        XCTAssertEqual(obj.arrayOptInt.count, 0)
        XCTAssertEqual(obj.arrayOptInt8.count, 0)
        XCTAssertEqual(obj.arrayOptInt16.count, 0)
        XCTAssertEqual(obj.arrayOptInt32.count, 0)
        XCTAssertEqual(obj.arrayOptInt64.count, 0)
        XCTAssertEqual(obj.arrayOptFloat.count, 0)
        XCTAssertEqual(obj.arrayOptDouble.count, 0)
        XCTAssertEqual(obj.arrayOptString.count, 0)
        XCTAssertEqual(obj.arrayOptBinary.count, 0)
        XCTAssertEqual(obj.arrayOptDate.count, 0)
        XCTAssertEqual(obj.arrayOptDecimal.count, 0)
        XCTAssertEqual(obj.arrayOptObjectId.count, 0)
        XCTAssertEqual(obj.arrayOptUuid.count, 0)

        XCTAssertEqual(obj.setBool.count, 0)
        XCTAssertEqual(obj.setInt.count, 0)
        XCTAssertEqual(obj.setInt8.count, 0)
        XCTAssertEqual(obj.setInt16.count, 0)
        XCTAssertEqual(obj.setInt32.count, 0)
        XCTAssertEqual(obj.setInt64.count, 0)
        XCTAssertEqual(obj.setFloat.count, 0)
        XCTAssertEqual(obj.setDouble.count, 0)
        XCTAssertEqual(obj.setString.count, 0)
        XCTAssertEqual(obj.setBinary.count, 0)
        XCTAssertEqual(obj.setDate.count, 0)
        XCTAssertEqual(obj.setDecimal.count, 0)
        XCTAssertEqual(obj.setObjectId.count, 0)
        XCTAssertEqual(obj.setAny.count, 0)
        XCTAssertEqual(obj.setUuid.count, 0)

        XCTAssertEqual(obj.setOptBool.count, 0)
        XCTAssertEqual(obj.setOptInt.count, 0)
        XCTAssertEqual(obj.setOptInt8.count, 0)
        XCTAssertEqual(obj.setOptInt16.count, 0)
        XCTAssertEqual(obj.setOptInt32.count, 0)
        XCTAssertEqual(obj.setOptInt64.count, 0)
        XCTAssertEqual(obj.setOptFloat.count, 0)
        XCTAssertEqual(obj.setOptDouble.count, 0)
        XCTAssertEqual(obj.setOptString.count, 0)
        XCTAssertEqual(obj.setOptBinary.count, 0)
        XCTAssertEqual(obj.setOptDate.count, 0)
        XCTAssertEqual(obj.setOptDecimal.count, 0)
        XCTAssertEqual(obj.setOptObjectId.count, 0)
        XCTAssertEqual(obj.setOptUuid.count, 0)
    }

    func verifyNil(_ obj: ModernAllTypesObject) {
        // "anyCol": .none,

        XCTAssertNil(obj.objectCol)
        XCTAssertNil(obj.optBoolCol)
        XCTAssertNil(obj.optIntCol)
        XCTAssertNil(obj.optInt8Col)
        XCTAssertNil(obj.optInt16Col)
        XCTAssertNil(obj.optInt32Col)
        XCTAssertNil(obj.optInt64Col)
        XCTAssertNil(obj.optFloatCol)
        XCTAssertNil(obj.optDoubleCol)
        XCTAssertNil(obj.optStringCol)
        XCTAssertNil(obj.optBinaryCol)
        XCTAssertNil(obj.optDateCol)
        XCTAssertNil(obj.optDecimalCol)
        XCTAssertNil(obj.optObjectIdCol)
        XCTAssertNil(obj.optUuidCol)
        XCTAssertNil(obj.optIntEnumCol)
        XCTAssertNil(obj.optStringEnumCol)

        XCTAssertEqual(obj.arrayAny[0], .none)
        XCTAssertNil(obj.arrayOptBool[0])
        XCTAssertNil(obj.arrayOptInt[0])
        XCTAssertNil(obj.arrayOptInt8[0])
        XCTAssertNil(obj.arrayOptInt16[0])
        XCTAssertNil(obj.arrayOptInt32[0])
        XCTAssertNil(obj.arrayOptInt64[0])
        XCTAssertNil(obj.arrayOptFloat[0])
        XCTAssertNil(obj.arrayOptDouble[0])
        XCTAssertNil(obj.arrayOptString[0])
        XCTAssertNil(obj.arrayOptBinary[0])
        XCTAssertNil(obj.arrayOptDate[0])
        XCTAssertNil(obj.arrayOptDecimal[0])
        XCTAssertNil(obj.arrayOptObjectId[0])
        XCTAssertNil(obj.arrayOptUuid[0])

        XCTAssertEqual(obj.setAny.first!, .none)
        XCTAssertNil(obj.setOptBool.first!)
        XCTAssertNil(obj.setOptInt.first!)
        XCTAssertNil(obj.setOptInt8.first!)
        XCTAssertNil(obj.setOptInt16.first!)
        XCTAssertNil(obj.setOptInt32.first!)
        XCTAssertNil(obj.setOptInt64.first!)
        XCTAssertNil(obj.setOptFloat.first!)
        XCTAssertNil(obj.setOptDouble.first!)
        XCTAssertNil(obj.setOptString.first!)
        XCTAssertNil(obj.setOptBinary.first!)
        XCTAssertNil(obj.setOptDate.first!)
        XCTAssertNil(obj.setOptDecimal.first!)
        XCTAssertNil(obj.setOptObjectId.first!)
        XCTAssertNil(obj.setOptUuid.first!)

        XCTAssertEqual(obj.mapAny["1"], .some(.none))
        XCTAssertEqual(obj.mapOptBool["1"], .some(nil))
        XCTAssertEqual(obj.mapOptInt["1"], .some(nil))
        XCTAssertEqual(obj.mapOptInt8["1"], .some(nil))
        XCTAssertEqual(obj.mapOptInt16["1"], .some(nil))
        XCTAssertEqual(obj.mapOptInt32["1"], .some(nil))
        XCTAssertEqual(obj.mapOptInt64["1"], .some(nil))
        XCTAssertEqual(obj.mapOptFloat["1"], .some(nil))
        XCTAssertEqual(obj.mapOptDouble["1"], .some(nil))
        XCTAssertEqual(obj.mapOptString["1"], .some(nil))
        XCTAssertEqual(obj.mapOptBinary["1"], .some(nil))
        XCTAssertEqual(obj.mapOptDate["1"], .some(nil))
        XCTAssertEqual(obj.mapOptDecimal["1"], .some(nil))
        XCTAssertEqual(obj.mapOptObjectId["1"], .some(nil))
        XCTAssertEqual(obj.mapOptUuid["1"], .some(nil))
    }

    func testInitDefault() {
        verifyDefault(ModernAllTypesObject())
    }

    func testInitWithArray() {
        var arrayValues = ModernAllTypesObject.sharedSchema()!.properties.map { values[$0.name] }
        arrayValues[0] = ObjectId.generate()
        verifyObject(ModernAllTypesObject(value: arrayValues), expectedShouldBeCopy: false)
    }

    func testInitWithDictionary() {
        verifyObject(ModernAllTypesObject(value: values!), expectedShouldBeCopy: false)
    }

    func testInitWithObject() {
        let obj = ModernAllTypesObject(value: values!)
        verifyObject(ModernAllTypesObject(value: obj), expectedShouldBeCopy: false)
    }

    func testInitNil() {
        verifyNil(ModernAllTypesObject(value: nullValues()))
    }

    func testCreateDefault() {
        let realm = try! Realm()
        let obj = try! realm.write {
            return realm.create(ModernAllTypesObject.self)
        }
        verifyDefault(obj)
    }

    func testCreateWithArray() {
        let realm = try! Realm()
        var arrayValues = ModernAllTypesObject.sharedSchema()!.properties.map { values[$0.name] }
        arrayValues[0] = ObjectId.generate()
        let obj = try! realm.write {
            return realm.create(ModernAllTypesObject.self, value: arrayValues)
        }
        verifyObject(obj)
    }

    func testCreateWithDictionary() {
        let realm = try! Realm()
        let obj = try! realm.write {
            return realm.create(ModernAllTypesObject.self, value: values!)
        }
        verifyObject(obj)
    }

    func testCreateWithObject() {
        let realm = try! Realm()
        let obj = try! realm.write {
            return realm.create(ModernAllTypesObject.self, value: ModernAllTypesObject(value: values!))
        }
        verifyObject(obj)
    }

    func testCreateNil() {
        let realm = try! Realm()
        let obj = try! realm.write {
            return realm.create(ModernAllTypesObject.self, value: nullValues())
        }
        verifyNil(obj)
    }

    func testAddDefault() {
        let obj = ModernAllTypesObject()
        let realm = try! Realm()
        try! realm.write {
            realm.add(obj)
        }
        verifyDefault(obj)
    }

    func testAdd() {
        let obj = ModernAllTypesObject(value: values!)
        let realm = try! Realm()
        try! realm.write {
            realm.add(obj)
        }
        verifyObject(obj, expectedShouldBeCopy: false)
    }

    func testAddNil() {
        let obj = ModernAllTypesObject(value: nullValues())
        let realm = try! Realm()
        try! realm.write {
            realm.add(obj)
        }
        verifyNil(obj)
    }

    func testCreateEmbeddedWithDictionary() {
        let realm = try! Realm()
        realm.beginWrite()
        let parent = realm.create(ModernEmbeddedParentObject.self, value: [
            "object": ["value": 5, "child": ["value": 6], "children": [[7], [8]]],
            "array": [[9], [10]]
        ])
        XCTAssertEqual(parent.object!.value, 5)
        XCTAssertEqual(parent.object!.child!.value, 6)
        XCTAssertEqual(parent.object!.children.count, 2)
        XCTAssertEqual(parent.object!.children[0].value, 7)
        XCTAssertEqual(parent.object!.children[1].value, 8)
        XCTAssertEqual(parent.array.count, 2)
        XCTAssertEqual(parent.array[0].value, 9)
        XCTAssertEqual(parent.array[1].value, 10)

        XCTAssertTrue(parent.isSameObject(as: parent.object!.parent1.first!))
        XCTAssertTrue(parent.isSameObject(as: parent.array[0].parent2.first!))
        XCTAssertTrue(parent.isSameObject(as: parent.array[1].parent2.first!))
        XCTAssertTrue(parent.object!.isSameObject(as: parent.object!.child!.parent3.first!))
        XCTAssertTrue(parent.object!.isSameObject(as: parent.object!.children[0].parent4.first!))
        XCTAssertTrue(parent.object!.isSameObject(as: parent.object!.children[1].parent4.first!))

        realm.cancelWrite()
    }

    func testCreateEmbeddedWithUnmanagedObjects() {
        let sourceObject = ModernEmbeddedParentObject()
        sourceObject.object = .init(value: [5])
        sourceObject.object!.child = .init(value: [6])
        sourceObject.object!.children.append(.init(value: [7]))
        sourceObject.object!.children.append(.init(value: [8]))
        sourceObject.array.append(.init(value: [9]))
        sourceObject.array.append(.init(value: [10]))

        let realm = try! Realm()
        realm.beginWrite()
        let parent = realm.create(ModernEmbeddedParentObject.self, value: sourceObject)
        XCTAssertNil(sourceObject.realm)
        XCTAssertEqual(parent.object!.value, 5)
        XCTAssertEqual(parent.object!.child!.value, 6)
        XCTAssertEqual(parent.object!.children.count, 2)
        XCTAssertEqual(parent.object!.children[0].value, 7)
        XCTAssertEqual(parent.object!.children[1].value, 8)
        XCTAssertEqual(parent.array.count, 2)
        XCTAssertEqual(parent.array[0].value, 9)
        XCTAssertEqual(parent.array[1].value, 10)
        realm.cancelWrite()
    }

    func testCreateEmbeddedFromManagedObjectInSameRealm() {
        let realm = try! Realm()
        realm.beginWrite()
        let parent = realm.create(ModernEmbeddedParentObject.self, value: [
            "object": ["value": 5, "child": ["value": 6], "children": [[7], [8]]],
            "array": [[9], [10]]
        ])
        let copy = realm.create(ModernEmbeddedParentObject.self, value: parent)
        XCTAssertNotEqual(parent, copy)
        XCTAssertEqual(copy.object!.value, 5)
        XCTAssertEqual(copy.object!.child!.value, 6)
        XCTAssertEqual(copy.object!.children.count, 2)
        XCTAssertEqual(copy.object!.children[0].value, 7)
        XCTAssertEqual(copy.object!.children[1].value, 8)
        XCTAssertEqual(copy.array.count, 2)
        XCTAssertEqual(copy.array[0].value, 9)
        XCTAssertEqual(copy.array[1].value, 10)
        realm.cancelWrite()
    }

    func testCreateEmbeddedFromManagedObjectInDifferentRealm() {
        let realmA = realmWithTestPath()
        let realmB = try! Realm()
        realmA.beginWrite()
        let parent = realmA.create(ModernEmbeddedParentObject.self, value: [
            "object": ["value": 5, "child": ["value": 6], "children": [[7], [8]]],
            "array": [[9], [10]]
        ])
        try! realmA.commitWrite()

        realmB.beginWrite()
        let copy = realmB.create(ModernEmbeddedParentObject.self, value: parent)
        XCTAssertNotEqual(parent, copy)
        XCTAssertEqual(copy.object!.value, 5)
        XCTAssertEqual(copy.object!.child!.value, 6)
        XCTAssertEqual(copy.object!.children.count, 2)
        XCTAssertEqual(copy.object!.children[0].value, 7)
        XCTAssertEqual(copy.object!.children[1].value, 8)
        XCTAssertEqual(copy.array.count, 2)
        XCTAssertEqual(copy.array[0].value, 9)
        XCTAssertEqual(copy.array[1].value, 10)
        realmB.cancelWrite()
    }

    // MARK: - Add tests

    class ModernEmbeddedObjectFactory {
        private var value = 0
        var objects = [EmbeddedObject]()

        func create<T: ModernEmbeddedTreeObject>() -> T {
            let obj = T()
            obj.value = value
            value += 1
            objects.append(obj)
            return obj
        }
    }

    func testAddEmbedded() {
        let objectFactory = ModernEmbeddedObjectFactory()
        let parent = ModernEmbeddedParentObject()
        parent.object = objectFactory.create()
        parent.object!.child = objectFactory.create()
        parent.object!.children.append(objectFactory.create())
        parent.object!.children.append(objectFactory.create())
        parent.array.append(objectFactory.create())
        parent.array.append(objectFactory.create())

        let realm = try! Realm()
        realm.beginWrite()
        realm.add(parent)
        for (i, object) in objectFactory.objects.enumerated() {
            XCTAssertEqual(object.realm, realm)
            XCTAssertEqual((object as! ModernEmbeddedTreeObject).value, i)
        }
        XCTAssertEqual(parent.object!.value, 0)
        XCTAssertEqual(parent.object!.child!.value, 1)
        XCTAssertEqual(parent.object!.children.count, 2)
        XCTAssertEqual(parent.object!.children[0].value, 2)
        XCTAssertEqual(parent.object!.children[1].value, 3)
        XCTAssertEqual(parent.array.count, 2)
        XCTAssertEqual(parent.array[0].value, 4)
        XCTAssertEqual(parent.array[1].value, 5)
        realm.cancelWrite()
    }

    func testAddAndUpdateEmbedded() {
        let objectFactory = ModernEmbeddedObjectFactory()
        let parent = ModernEmbeddedPrimaryParentObject()
        parent.object = objectFactory.create()
        parent.object!.child = objectFactory.create()
        parent.object!.children.append(objectFactory.create())
        parent.object!.children.append(objectFactory.create())
        parent.array.append(objectFactory.create())
        parent.array.append(objectFactory.create())

        let parent2 = ModernEmbeddedPrimaryParentObject()
        parent2.object = objectFactory.create()
        parent2.object!.child = objectFactory.create()
        parent2.object!.children.append(objectFactory.create())
        parent2.object!.children.append(objectFactory.create())
        parent2.array.append(objectFactory.create())
        parent2.array.append(objectFactory.create())

        let realm = try! Realm()
        realm.beginWrite()
        realm.add(parent)
        realm.add(parent2, update: .all)

        // update all deletes the old embedded objects and creates new ones
        for (i, object) in objectFactory.objects.enumerated() {
            XCTAssertEqual(object.realm, realm)
            if i < 6 {
                XCTAssertTrue(object.isInvalidated)
            } else {
                XCTAssertEqual((object as! ModernEmbeddedTreeObject).value, i)
            }
        }
        XCTAssertTrue(parent.isSameObject(as: parent2))
        XCTAssertEqual(parent.object!.value, 6)
        XCTAssertEqual(parent.object!.child!.value, 7)
        XCTAssertEqual(parent.object!.children.count, 2)
        XCTAssertEqual(parent.object!.children[0].value, 8)
        XCTAssertEqual(parent.object!.children[1].value, 9)
        XCTAssertEqual(parent.array.count, 2)
        XCTAssertEqual(parent.array[0].value, 10)
        XCTAssertEqual(parent.array[1].value, 11)
        realm.cancelWrite()
    }

    func testAddAndUpdateChangedWithExisingNestedObjects() {
        try! Realm().beginWrite()
        let existingObject = try! Realm().create(SwiftPrimaryStringObject.self, value: ["primary", 1])
        try! Realm().commitWrite()

        try! Realm().beginWrite()
        let object = SwiftLinkToPrimaryStringObject(value: ["primary", ["primary", 2], []])
        try! Realm().add(object, update: .modified)
        try! Realm().commitWrite()

        XCTAssertNotNil(object.realm)
        XCTAssertEqual(object.object!, existingObject) // the existing object should be updated
        XCTAssertEqual(existingObject.intCol, 2)
    }

    func testAddAndUpdateChangedEmbedded() {
        let objectFactory = ModernEmbeddedObjectFactory()
        let parent = ModernEmbeddedPrimaryParentObject()
        parent.object = objectFactory.create()
        parent.object!.child = objectFactory.create()
        parent.object!.children.append(objectFactory.create())
        parent.object!.children.append(objectFactory.create())
        parent.array.append(objectFactory.create())
        parent.array.append(objectFactory.create())

        let parent2 = ModernEmbeddedPrimaryParentObject()
        parent2.object = objectFactory.create()
        parent2.object!.child = objectFactory.create()
        parent2.object!.children.append(objectFactory.create())
        parent2.object!.children.append(objectFactory.create())
        parent2.array.append(objectFactory.create())
        parent2.array.append(objectFactory.create())

        let realm = try! Realm()
        realm.beginWrite()
        realm.add(parent)
        realm.add(parent2, update: .modified)

        // update modified modifies the existing embedded objects
        for (i, object) in objectFactory.objects.enumerated() {
            XCTAssertEqual(object.realm, realm)
            XCTAssertEqual((object as! ModernEmbeddedTreeObject).value, i < 6 ? i + 6 : i)
        }
        XCTAssertTrue(parent.isSameObject(as: parent2))
        XCTAssertEqual(parent.object!.value, 6)
        XCTAssertEqual(parent.object!.child!.value, 7)
        XCTAssertEqual(parent.object!.children.count, 2)
        XCTAssertEqual(parent.object!.children[0].value, 8)
        XCTAssertEqual(parent.object!.children[1].value, 9)
        XCTAssertEqual(parent.array.count, 2)
        XCTAssertEqual(parent.array[0].value, 10)
        XCTAssertEqual(parent.array[1].value, 11)
        realm.cancelWrite()
    }

    func testAddObjectCycle() {
        weak var weakObj1: ModernCircleObject? = nil, weakObj2: ModernCircleObject? = nil

        autoreleasepool {
            let obj1 = ModernCircleObject(value: [])
            let obj2 = ModernCircleObject(value: [obj1, [obj1]])
            obj1.obj = obj2
            obj1.array.append(obj2)

            weakObj1 = obj1
            weakObj2 = obj2

            let realm = try! Realm()
            try! realm.write {
                realm.add(obj1)
            }

            XCTAssertEqual(obj1.realm, realm)
            XCTAssertEqual(obj2.realm, realm)
        }

        XCTAssertNil(weakObj1)
        XCTAssertNil(weakObj2)
    }
}

private func mapValues<T>(_ values: [T]) -> [String: T] {
    var map = [String: T]()
    for (i, v) in values.enumerated() {
        map["\(i)"] = v
    }
    return map
}

class ModernEnumObjectCreationTests: TestCase {
    let values: [String: Any] = [
        "listInt": EnumInt.values(),
        "listInt8": EnumInt8.values(),
        "listInt16": EnumInt16.values(),
        "listInt32": EnumInt32.values(),
        "listInt64": EnumInt64.values(),
        "listFloat": EnumFloat.values(),
        "listDouble": EnumDouble.values(),
        "listString": EnumString.values(),

        "listIntOpt": EnumInt?.values(),
        "listInt8Opt": EnumInt8?.values(),
        "listInt16Opt": EnumInt16?.values(),
        "listInt32Opt": EnumInt32?.values(),
        "listInt64Opt": EnumInt64?.values(),
        "listFloatOpt": EnumFloat?.values(),
        "listDoubleOpt": EnumDouble?.values(),
        "listStringOpt": EnumString?.values(),

        "setInt": EnumInt.values(),
        "setInt8": EnumInt8.values(),
        "setInt16": EnumInt16.values(),
        "setInt32": EnumInt32.values(),
        "setInt64": EnumInt64.values(),
        "setFloat": EnumFloat.values(),
        "setDouble": EnumDouble.values(),
        "setString": EnumString.values(),

        "setIntOpt": EnumInt?.values(),
        "setInt8Opt": EnumInt8?.values(),
        "setInt16Opt": EnumInt16?.values(),
        "setInt32Opt": EnumInt32?.values(),
        "setInt64Opt": EnumInt64?.values(),
        "setFloatOpt": EnumFloat?.values(),
        "setDoubleOpt": EnumDouble?.values(),
        "setStringOpt": EnumString?.values(),

        "mapInt": mapValues(EnumInt.values()),
        "mapInt8": mapValues(EnumInt8.values()),
        "mapInt16": mapValues(EnumInt16.values()),
        "mapInt32": mapValues(EnumInt32.values()),
        "mapInt64": mapValues(EnumInt64.values()),
        "mapFloat": mapValues(EnumFloat.values()),
        "mapDouble": mapValues(EnumDouble.values()),
        "mapString": mapValues(EnumString.values()),

        "mapIntOpt": mapValues(EnumInt?.values()),
        "mapInt8Opt": mapValues(EnumInt8?.values()),
        "mapInt16Opt": mapValues(EnumInt16?.values()),
        "mapInt32Opt": mapValues(EnumInt32?.values()),
        "mapInt64Opt": mapValues(EnumInt64?.values()),
        "mapFloatOpt": mapValues(EnumFloat?.values()),
        "mapDoubleOpt": mapValues(EnumDouble?.values()),
        "mapStringOpt": mapValues(EnumString?.values())
    ]

    func assertMapEqual<T: RealmCollectionValue>(_ actual: Map<String, T>, _ expected: Dictionary<String, T>) {
        XCTAssertEqual(actual.count, expected.count)
        for (key, value) in expected {
            XCTAssertEqual(actual[key], value)
        }
    }

    func verifyObject(_ obj: ModernCollectionsOfEnums) {
        XCTAssertEqual(Array(obj.listInt), EnumInt.values())
        XCTAssertEqual(Array(obj.listInt8), EnumInt8.values())
        XCTAssertEqual(Array(obj.listInt16), EnumInt16.values())
        XCTAssertEqual(Array(obj.listInt32), EnumInt32.values())
        XCTAssertEqual(Array(obj.listInt64), EnumInt64.values())
        XCTAssertEqual(Array(obj.listFloat), EnumFloat.values())
        XCTAssertEqual(Array(obj.listDouble), EnumDouble.values())
        XCTAssertEqual(Array(obj.listString), EnumString.values())

        XCTAssertEqual(Array(obj.listIntOpt), EnumInt?.values())
        XCTAssertEqual(Array(obj.listInt8Opt), EnumInt8?.values())
        XCTAssertEqual(Array(obj.listInt16Opt), EnumInt16?.values())
        XCTAssertEqual(Array(obj.listInt32Opt), EnumInt32?.values())
        XCTAssertEqual(Array(obj.listInt64Opt), EnumInt64?.values())
        XCTAssertEqual(Array(obj.listFloatOpt), EnumFloat?.values())
        XCTAssertEqual(Array(obj.listDoubleOpt), EnumDouble?.values())
        XCTAssertEqual(Array(obj.listStringOpt), EnumString?.values())

        XCTAssertEqual(Set(obj.setInt), Set(EnumInt.values()))
        XCTAssertEqual(Set(obj.setInt8), Set(EnumInt8.values()))
        XCTAssertEqual(Set(obj.setInt16), Set(EnumInt16.values()))
        XCTAssertEqual(Set(obj.setInt32), Set(EnumInt32.values()))
        XCTAssertEqual(Set(obj.setInt64), Set(EnumInt64.values()))
        XCTAssertEqual(Set(obj.setFloat), Set(EnumFloat.values()))
        XCTAssertEqual(Set(obj.setDouble), Set(EnumDouble.values()))
        XCTAssertEqual(Set(obj.setString), Set(EnumString.values()))

        XCTAssertEqual(Set(obj.setIntOpt), Set(EnumInt?.values()))
        XCTAssertEqual(Set(obj.setInt8Opt), Set(EnumInt8?.values()))
        XCTAssertEqual(Set(obj.setInt16Opt), Set(EnumInt16?.values()))
        XCTAssertEqual(Set(obj.setInt32Opt), Set(EnumInt32?.values()))
        XCTAssertEqual(Set(obj.setInt64Opt), Set(EnumInt64?.values()))
        XCTAssertEqual(Set(obj.setFloatOpt), Set(EnumFloat?.values()))
        XCTAssertEqual(Set(obj.setDoubleOpt), Set(EnumDouble?.values()))
        XCTAssertEqual(Set(obj.setStringOpt), Set(EnumString?.values()))

        assertMapEqual(obj.mapInt, mapValues(EnumInt.values()))
        assertMapEqual(obj.mapInt8, mapValues(EnumInt8.values()))
        assertMapEqual(obj.mapInt16, mapValues(EnumInt16.values()))
        assertMapEqual(obj.mapInt32, mapValues(EnumInt32.values()))
        assertMapEqual(obj.mapInt64, mapValues(EnumInt64.values()))
        assertMapEqual(obj.mapFloat, mapValues(EnumFloat.values()))
        assertMapEqual(obj.mapDouble, mapValues(EnumDouble.values()))
        assertMapEqual(obj.mapString, mapValues(EnumString.values()))

        assertMapEqual(obj.mapIntOpt, mapValues(EnumInt?.values()))
        assertMapEqual(obj.mapInt8Opt, mapValues(EnumInt8?.values()))
        assertMapEqual(obj.mapInt16Opt, mapValues(EnumInt16?.values()))
        assertMapEqual(obj.mapInt32Opt, mapValues(EnumInt32?.values()))
        assertMapEqual(obj.mapInt64Opt, mapValues(EnumInt64?.values()))
        assertMapEqual(obj.mapFloatOpt, mapValues(EnumFloat?.values()))
        assertMapEqual(obj.mapDoubleOpt, mapValues(EnumDouble?.values()))
        assertMapEqual(obj.mapStringOpt, mapValues(EnumString?.values()))
    }

    func verifyDefault(_ obj: ModernCollectionsOfEnums) {
        XCTAssertEqual(obj.listInt.count, 0)
        XCTAssertEqual(obj.listInt8.count, 0)
        XCTAssertEqual(obj.listInt16.count, 0)
        XCTAssertEqual(obj.listInt32.count, 0)
        XCTAssertEqual(obj.listInt64.count, 0)
        XCTAssertEqual(obj.listFloat.count, 0)
        XCTAssertEqual(obj.listDouble.count, 0)
        XCTAssertEqual(obj.listString.count, 0)

        XCTAssertEqual(obj.listIntOpt.count, 0)
        XCTAssertEqual(obj.listInt8Opt.count, 0)
        XCTAssertEqual(obj.listInt16Opt.count, 0)
        XCTAssertEqual(obj.listInt32Opt.count, 0)
        XCTAssertEqual(obj.listInt64Opt.count, 0)
        XCTAssertEqual(obj.listFloatOpt.count, 0)
        XCTAssertEqual(obj.listDoubleOpt.count, 0)
        XCTAssertEqual(obj.listStringOpt.count, 0)

        XCTAssertEqual(obj.setInt.count, 0)
        XCTAssertEqual(obj.setInt8.count, 0)
        XCTAssertEqual(obj.setInt16.count, 0)
        XCTAssertEqual(obj.setInt32.count, 0)
        XCTAssertEqual(obj.setInt64.count, 0)
        XCTAssertEqual(obj.setFloat.count, 0)
        XCTAssertEqual(obj.setDouble.count, 0)
        XCTAssertEqual(obj.setString.count, 0)

        XCTAssertEqual(obj.setIntOpt.count, 0)
        XCTAssertEqual(obj.setInt8Opt.count, 0)
        XCTAssertEqual(obj.setInt16Opt.count, 0)
        XCTAssertEqual(obj.setInt32Opt.count, 0)
        XCTAssertEqual(obj.setInt64Opt.count, 0)
        XCTAssertEqual(obj.setFloatOpt.count, 0)
        XCTAssertEqual(obj.setDoubleOpt.count, 0)
        XCTAssertEqual(obj.setStringOpt.count, 0)

        XCTAssertEqual(obj.mapInt.count, 0)
        XCTAssertEqual(obj.mapInt8.count, 0)
        XCTAssertEqual(obj.mapInt16.count, 0)
        XCTAssertEqual(obj.mapInt32.count, 0)
        XCTAssertEqual(obj.mapInt64.count, 0)
        XCTAssertEqual(obj.mapFloat.count, 0)
        XCTAssertEqual(obj.mapDouble.count, 0)
        XCTAssertEqual(obj.mapString.count, 0)

        XCTAssertEqual(obj.mapIntOpt.count, 0)
        XCTAssertEqual(obj.mapInt8Opt.count, 0)
        XCTAssertEqual(obj.mapInt16Opt.count, 0)
        XCTAssertEqual(obj.mapInt32Opt.count, 0)
        XCTAssertEqual(obj.mapInt64Opt.count, 0)
        XCTAssertEqual(obj.mapFloatOpt.count, 0)
        XCTAssertEqual(obj.mapDoubleOpt.count, 0)
        XCTAssertEqual(obj.mapStringOpt.count, 0)
    }

    func testInitDefault() {
        verifyDefault(ModernCollectionsOfEnums())
    }

    func testInitWithArray() {
        let arrayValues = ModernCollectionsOfEnums.sharedSchema()!.properties.map { values[$0.name] }
        verifyObject(ModernCollectionsOfEnums(value: arrayValues))
    }

    func testInitWithDictionary() {
        verifyObject(ModernCollectionsOfEnums(value: values))
    }

    func testInitWithObject() {
        let obj = ModernCollectionsOfEnums(value: values)
        verifyObject(ModernCollectionsOfEnums(value: obj))
    }

    func testCreateDefault() {
        let realm = try! Realm()
        let obj = try! realm.write {
            return realm.create(ModernCollectionsOfEnums.self)
        }
        verifyDefault(obj)
    }

    func testCreateWithArray() {
        let realm = try! Realm()
        let arrayValues = ModernCollectionsOfEnums.sharedSchema()!.properties.map { values[$0.name] }
        let obj = try! realm.write {
            return realm.create(ModernCollectionsOfEnums.self, value: arrayValues)
        }
        verifyObject(obj)
    }

    func testCreateWithDictionary() {
        let realm = try! Realm()
        let obj = try! realm.write {
            return realm.create(ModernCollectionsOfEnums.self, value: values)
        }
        verifyObject(obj)
    }

    func testCreateWithObject() {
        let realm = try! Realm()
        let obj = try! realm.write {
            return realm.create(ModernCollectionsOfEnums.self, value: ModernCollectionsOfEnums(value: values))
        }
        verifyObject(obj)
    }

    func testAddDefault() {
        let obj = ModernCollectionsOfEnums()
        let realm = try! Realm()
        try! realm.write {
            realm.add(obj)
        }
        verifyDefault(obj)
    }

    func testAdd() {
        let obj = ModernCollectionsOfEnums(value: values)
        let realm = try! Realm()
        try! realm.write {
            realm.add(obj)
        }
        verifyObject(obj)
    }
}
