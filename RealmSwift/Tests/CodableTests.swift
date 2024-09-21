////////////////////////////////////////////////////////////////////////////
//
// Copyright 2019 Realm Inc.
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

@available(*, deprecated) // Silence deprecation warnings for RealmOptional
final class CodableObject: Object, Codable {
    @objc dynamic var string: String = ""
    @objc dynamic var data: Data = Data()
    @objc dynamic var date: Date = Date()
    @objc dynamic var int: Int = 0
    @objc dynamic var int8: Int8 = 0
    @objc dynamic var int16: Int16 = 0
    @objc dynamic var int32: Int32 = 0
    @objc dynamic var int64: Int64 = 0
    @objc dynamic var float: Float = 0
    @objc dynamic var double: Double = 0
    @objc dynamic var bool: Bool = false
    @objc dynamic var decimal: Decimal128 = 0
    @objc dynamic var objectId = ObjectId()
    @objc dynamic var uuid = UUID()

    @objc dynamic var stringOpt: String?
    @objc dynamic var dataOpt: Data?
    @objc dynamic var dateOpt: Date?
    @objc dynamic var decimalOpt: Decimal128?
    @objc dynamic var objectIdOpt: ObjectId?
    var intOpt = RealmOptional<Int>()
    var int8Opt = RealmOptional<Int8>()
    var int16Opt = RealmOptional<Int16>()
    var int32Opt = RealmOptional<Int32>()
    var int64Opt = RealmOptional<Int64>()
    var floatOpt = RealmOptional<Float>()
    var doubleOpt = RealmOptional<Double>()
    var boolOpt = RealmOptional<Bool>()

    var otherInt = RealmProperty<Int?>()
    var otherInt8 = RealmProperty<Int8?>()
    var otherInt16 = RealmProperty<Int16?>()
    var otherInt32 = RealmProperty<Int32?>()
    var otherInt64 = RealmProperty<Int64?>()
    var otherFloat = RealmProperty<Float?>()
    var otherDouble = RealmProperty<Double?>()
    var otherBool = RealmProperty<Bool?>()
    var otherEnum = RealmProperty<IntEnum?>()

    @objc dynamic var uuidOpt: UUID?

    var boolList = List<Bool>()
    var intList = List<Int>()
    var int8List = List<Int8>()
    var int16List = List<Int16>()
    var int32List = List<Int32>()
    var int64List = List<Int64>()
    var floatList = List<Float>()
    var doubleList = List<Double>()
    var stringList = List<String>()
    var dataList = List<Data>()
    var dateList = List<Date>()
    var decimalList = List<Decimal128>()
    var objectIdList = List<ObjectId>()
    var uuidList = List<UUID>()

    var boolOptList = List<Bool?>()
    var intOptList = List<Int?>()
    var int8OptList = List<Int8?>()
    var int16OptList = List<Int16?>()
    var int32OptList = List<Int32?>()
    var int64OptList = List<Int64?>()
    var floatOptList = List<Float?>()
    var doubleOptList = List<Double?>()
    var stringOptList = List<String?>()
    var dataOptList = List<Data?>()
    var dateOptList = List<Date?>()
    var decimalOptList = List<Decimal128?>()
    var objectIdOptList = List<ObjectId?>()
    var uuidOptList = List<UUID?>()

    var boolSet = MutableSet<Bool>()
    var intSet = MutableSet<Int>()
    var int8Set = MutableSet<Int8>()
    var int16Set = MutableSet<Int16>()
    var int32Set = MutableSet<Int32>()
    var int64Set = MutableSet<Int64>()
    var floatSet = MutableSet<Float>()
    var doubleSet = MutableSet<Double>()
    var stringSet = MutableSet<String>()
    var dataSet = MutableSet<Data>()
    var dateSet = MutableSet<Date>()
    var decimalSet = MutableSet<Decimal128>()
    var objectIdSet = MutableSet<ObjectId>()
    var uuidSet = MutableSet<UUID>()

    var boolOptSet = MutableSet<Bool?>()
    var intOptSet = MutableSet<Int?>()
    var int8OptSet = MutableSet<Int8?>()
    var int16OptSet = MutableSet<Int16?>()
    var int32OptSet = MutableSet<Int32?>()
    var int64OptSet = MutableSet<Int64?>()
    var floatOptSet = MutableSet<Float?>()
    var doubleOptSet = MutableSet<Double?>()
    var stringOptSet = MutableSet<String?>()
    var dataOptSet = MutableSet<Data?>()
    var dateOptSet = MutableSet<Date?>()
    var decimalOptSet = MutableSet<Decimal128?>()
    var objectIdOptSet = MutableSet<ObjectId?>()
    var uuidOptSet = MutableSet<UUID?>()

    var boolMap = Map<String, Bool>()
    var intMap = Map<String, Int>()
    var int8Map = Map<String, Int8>()
    var int16Map = Map<String, Int16>()
    var int32Map = Map<String, Int32>()
    var int64Map = Map<String, Int64>()
    var floatMap = Map<String, Float>()
    var doubleMap = Map<String, Double>()
    var stringMap = Map<String, String>()
    var dataMap = Map<String, Data>()
    var dateMap = Map<String, Date>()
    var decimalMap = Map<String, Decimal128>()
    var objectIdMap = Map<String, ObjectId>()
    var uuidMap = Map<String, UUID>()

    var boolOptMap = Map<String, Bool?>()
    var intOptMap = Map<String, Int?>()
    var int8OptMap = Map<String, Int8?>()
    var int16OptMap = Map<String, Int16?>()
    var int32OptMap = Map<String, Int32?>()
    var int64OptMap = Map<String, Int64?>()
    var floatOptMap = Map<String, Float?>()
    var doubleOptMap = Map<String, Double?>()
    var stringOptMap = Map<String, String?>()
    var dataOptMap = Map<String, Data?>()
    var dateOptMap = Map<String, Date?>()
    var decimalOptMap = Map<String, Decimal128?>()
    var objectIdOptMap = Map<String, ObjectId?>()
    var uuidOptMap = Map<String, UUID?>()
}

final class ModernCodableObject: Object, Codable {
    @Persisted var string: String
    @Persisted var data: Data
    @Persisted var date: Date
    @Persisted var int: Int
    @Persisted var int8: Int8
    @Persisted var int16: Int16
    @Persisted var int32: Int32
    @Persisted var int64: Int64
    @Persisted var float: Float
    @Persisted var double: Double
    @Persisted var bool: Bool
    @Persisted var decimal: Decimal128
    @Persisted var objectId: ObjectId
    @Persisted var uuid: UUID

    @Persisted var stringOpt: String?
    @Persisted var dataOpt: Data?
    @Persisted var dateOpt: Date?
    @Persisted var decimalOpt: Decimal128?
    @Persisted var objectIdOpt: ObjectId?
    @Persisted var intOpt: Int?
    @Persisted var int8Opt: Int8?
    @Persisted var int16Opt: Int16?
    @Persisted var int32Opt: Int32?
    @Persisted var int64Opt: Int64?
    @Persisted var floatOpt: Float?
    @Persisted var doubleOpt: Double?
    @Persisted var boolOpt: Bool?
    @Persisted var uuidOpt: UUID?
    @Persisted var objectOpt: CodableTopLevelObject?
    @Persisted var embeddedObjectOpt: CodableEmbeddedObject?

    @Persisted var boolList: List<Bool>
    @Persisted var intList: List<Int>
    @Persisted var int8List: List<Int8>
    @Persisted var int16List: List<Int16>
    @Persisted var int32List: List<Int32>
    @Persisted var int64List: List<Int64>
    @Persisted var floatList: List<Float>
    @Persisted var doubleList: List<Double>
    @Persisted var stringList: List<String>
    @Persisted var dataList: List<Data>
    @Persisted var dateList: List<Date>
    @Persisted var decimalList: List<Decimal128>
    @Persisted var objectIdList: List<ObjectId>
    @Persisted var uuidList: List<UUID>
    @Persisted var objectList: List<CodableTopLevelObject>
    @Persisted var embeddedObjectList: List<CodableEmbeddedObject>

    @Persisted var boolOptList: List<Bool?>
    @Persisted var intOptList: List<Int?>
    @Persisted var int8OptList: List<Int8?>
    @Persisted var int16OptList: List<Int16?>
    @Persisted var int32OptList: List<Int32?>
    @Persisted var int64OptList: List<Int64?>
    @Persisted var floatOptList: List<Float?>
    @Persisted var doubleOptList: List<Double?>
    @Persisted var stringOptList: List<String?>
    @Persisted var dataOptList: List<Data?>
    @Persisted var dateOptList: List<Date?>
    @Persisted var decimalOptList: List<Decimal128?>
    @Persisted var objectIdOptList: List<ObjectId?>
    @Persisted var uuidOptList: List<UUID?>

    @Persisted var boolSet: MutableSet<Bool>
    @Persisted var intSet: MutableSet<Int>
    @Persisted var int8Set: MutableSet<Int8>
    @Persisted var int16Set: MutableSet<Int16>
    @Persisted var int32Set: MutableSet<Int32>
    @Persisted var int64Set: MutableSet<Int64>
    @Persisted var floatSet: MutableSet<Float>
    @Persisted var doubleSet: MutableSet<Double>
    @Persisted var stringSet: MutableSet<String>
    @Persisted var dataSet: MutableSet<Data>
    @Persisted var dateSet: MutableSet<Date>
    @Persisted var decimalSet: MutableSet<Decimal128>
    @Persisted var objectIdSet: MutableSet<ObjectId>
    @Persisted var uuidSet: MutableSet<UUID>
    @Persisted var objectSet: MutableSet<CodableTopLevelObject>

    @Persisted var boolOptSet: MutableSet<Bool?>
    @Persisted var intOptSet: MutableSet<Int?>
    @Persisted var int8OptSet: MutableSet<Int8?>
    @Persisted var int16OptSet: MutableSet<Int16?>
    @Persisted var int32OptSet: MutableSet<Int32?>
    @Persisted var int64OptSet: MutableSet<Int64?>
    @Persisted var floatOptSet: MutableSet<Float?>
    @Persisted var doubleOptSet: MutableSet<Double?>
    @Persisted var stringOptSet: MutableSet<String?>
    @Persisted var dataOptSet: MutableSet<Data?>
    @Persisted var dateOptSet: MutableSet<Date?>
    @Persisted var decimalOptSet: MutableSet<Decimal128?>
    @Persisted var objectIdOptSet: MutableSet<ObjectId?>
    @Persisted var uuidOptSet: MutableSet<UUID?>

    @Persisted var boolMap: Map<String, Bool>
    @Persisted var intMap: Map<String, Int>
    @Persisted var int8Map: Map<String, Int8>
    @Persisted var int16Map: Map<String, Int16>
    @Persisted var int32Map: Map<String, Int32>
    @Persisted var int64Map: Map<String, Int64>
    @Persisted var floatMap: Map<String, Float>
    @Persisted var doubleMap: Map<String, Double>
    @Persisted var stringMap: Map<String, String>
    @Persisted var dataMap: Map<String, Data>
    @Persisted var dateMap: Map<String, Date>
    @Persisted var decimalMap: Map<String, Decimal128>
    @Persisted var objectIdMap: Map<String, ObjectId>
    @Persisted var uuidMap: Map<String, UUID>

    @Persisted var boolOptMap: Map<String, Bool?>
    @Persisted var intOptMap: Map<String, Int?>
    @Persisted var int8OptMap: Map<String, Int8?>
    @Persisted var int16OptMap: Map<String, Int16?>
    @Persisted var int32OptMap: Map<String, Int32?>
    @Persisted var int64OptMap: Map<String, Int64?>
    @Persisted var floatOptMap: Map<String, Float?>
    @Persisted var doubleOptMap: Map<String, Double?>
    @Persisted var stringOptMap: Map<String, String?>
    @Persisted var dataOptMap: Map<String, Data?>
    @Persisted var dateOptMap: Map<String, Date?>
    @Persisted var decimalOptMap: Map<String, Decimal128?>
    @Persisted var objectIdOptMap: Map<String, ObjectId?>
    @Persisted var uuidOptMap: Map<String, UUID?>
    @Persisted var objectOptMap: Map<String, CodableTopLevelObject?>
    @Persisted var embeddedObjectOptMap: Map<String, CodableEmbeddedObject?>
}

final class CodableTopLevelObject: Object, Codable {
    @Persisted var value: Int
}

final class CodableEmbeddedObject: EmbeddedObject, Codable {
    @Persisted var value: Int
}

@available(*, deprecated) // Silence deprecation warnings for RealmOptional
class CodableTests: TestCase, @unchecked Sendable {
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()

    func decode<T: RealmOptionalType & Codable & _RealmSchemaDiscoverable>(_ type: T.Type, _ str: String) -> RealmOptional<T> {
        return decode(RealmOptional<T>.self, str)
    }
    func decode<T: Codable>(_ type: T.Type, _ str: String) -> T {
        return try! decoder.decode([T].self, from: str.data(using: .utf8)!).first!
    }

    func encode<T: RealmOptionalType & Codable & _RealmSchemaDiscoverable>(_ value: T?) -> String {
        let opt = RealmOptional<T>()
        opt.value = value
        return try! String(data: encoder.encode([opt]), encoding: .utf8)!
    }
    func encode<T: Codable>(_ value: T?) -> String {
        return try! String(data: encoder.encode([value]), encoding: .utf8)!
    }

    func legacyObjectString(_ nullRealmProperty: Bool = false) -> String {
        """
        {
            "bool": true,
            "string": "abc",
            "int": 123,
            "int8": 123,
            "int16": 123,
            "int32": 123,
            "int64": 123,
            "float": 2.5,
            "double": 2.5,
            "date": 2.5,
            "data": "\(Data("def".utf8).base64EncodedString())",
            "decimal": "1.5e2",
            "objectId": "1234567890abcdef12345678",
            "uuid": "00000000-0000-0000-0000-000000000000",

            "boolOpt": true,
            "stringOpt": "abc",
            "intOpt": 123,
            "int8Opt": 123,
            "int16Opt": 123,
            "int32Opt": 123,
            "int64Opt": 123,
            "floatOpt": 2.5,
            "doubleOpt": 2.5,
            "dateOpt": 2.5,
            "dataOpt": "\(Data("def".utf8).base64EncodedString())",
            "decimalOpt": "1.5e2",
            "objectIdOpt": "1234567890abcdef12345678",
            "uuidOpt": "00000000-0000-0000-0000-000000000000",

            "otherBool": \(nullRealmProperty ? "null" : "true"),
            "otherInt": \(nullRealmProperty ? "null" : "123"),
            "otherInt8": \(nullRealmProperty ? "null" : "123"),
            "otherInt16": \(nullRealmProperty ? "null" : "123"),
            "otherInt32": \(nullRealmProperty ? "null" : "123"),
            "otherInt64": \(nullRealmProperty ? "null" : "123"),
            "otherFloat": \(nullRealmProperty ? "null" : "2.5"),
            "otherDouble": \(nullRealmProperty ? "null" : "2.5"),
            "otherEnum": \(nullRealmProperty ? "null" : "1"),
            "otherAny": \(nullRealmProperty ? "null" : "1"),

            "boolList": [true],
            "stringList": ["abc"],
            "intList": [123],
            "int8List": [123],
            "int16List": [123],
            "int32List": [123],
            "int64List": [123],
            "floatList": [2.5],
            "doubleList": [2.5],
            "dateList": [2.5],
            "dataList": ["\(Data("def".utf8).base64EncodedString())"],
            "decimalList": ["1.5e2"],
            "objectIdList": ["1234567890abcdef12345678"],
            "uuidList": ["00000000-0000-0000-0000-000000000000"],

            "boolOptList": [true],
            "stringOptList": ["abc"],
            "intOptList": [123],
            "int8OptList": [123],
            "int16OptList": [123],
            "int32OptList": [123],
            "int64OptList": [123],
            "floatOptList": [2.5],
            "doubleOptList": [2.5],
            "dateOptList": [2.5],
            "dataOptList": ["\(Data("def".utf8).base64EncodedString())"],
            "decimalOptList": ["1.5e2"],
            "objectIdOptList": ["1234567890abcdef12345678"],
            "uuidOptList": ["00000000-0000-0000-0000-000000000000"],

            "boolSet": [true],
            "stringSet": ["abc"],
            "intSet": [123],
            "int8Set": [123],
            "int16Set": [123],
            "int32Set": [123],
            "int64Set": [123],
            "floatSet": [2.5],
            "doubleSet": [2.5],
            "dateSet": [2.5],
            "dataSet": ["\(Data("def".utf8).base64EncodedString())"],
            "decimalSet": ["1.5e2"],
            "objectIdSet": ["1234567890abcdef12345678"],
            "uuidSet": ["00000000-0000-0000-0000-000000000000"],

            "boolOptSet": [true],
            "stringOptSet": ["abc"],
            "intOptSet": [123],
            "int8OptSet": [123],
            "int16OptSet": [123],
            "int32OptSet": [123],
            "int64OptSet": [123],
            "floatOptSet": [2.5],
            "doubleOptSet": [2.5],
            "dateOptSet": [2.5],
            "dataOptSet": ["\(Data("def".utf8).base64EncodedString())"],
            "decimalOptSet": ["1.5e2"],
            "objectIdOptSet": ["1234567890abcdef12345678"],
            "uuidOptSet": ["00000000-0000-0000-0000-000000000000"],

            "boolMap": {"foo": true},
            "stringMap": {"foo": "abc"},
            "intMap": {"foo": 123},
            "int8Map": {"foo": 123},
            "int16Map": {"foo": 123},
            "int32Map": {"foo": 123},
            "int64Map": {"foo": 123},
            "floatMap": {"foo": 2.5},
            "doubleMap": {"foo": 2.5},
            "dateMap": {"foo": 2.5},
            "dataMap": {"foo": "\(Data("def".utf8).base64EncodedString())"},
            "decimalMap": {"foo": "1.5e2"},
            "objectIdMap": {"foo": "1234567890abcdef12345678"},
            "uuidMap": {"foo": "00000000-0000-0000-0000-000000000000"},

            "boolOptMap": {"foo": true},
            "stringOptMap": {"foo": "abc"},
            "intOptMap": {"foo": 123},
            "int8OptMap": {"foo": 123},
            "int16OptMap": {"foo": 123},
            "int32OptMap": {"foo": 123},
            "int64OptMap": {"foo": 123},
            "floatOptMap": {"foo": 2.5},
            "doubleOptMap": {"foo": 2.5},
            "dateOptMap": {"foo": 2.5},
            "dataOptMap": {"foo": "\(Data("def".utf8).base64EncodedString())"},
            "decimalOptMap": {"foo": "1.5e2"},
            "objectIdOptMap": {"foo": "1234567890abcdef12345678"},
            "uuidOptMap": {"foo": "00000000-0000-0000-0000-000000000000"}
        }
        """
    }

    func testBool() {
        XCTAssertEqual(true, decode(Bool.self, "[true]").value)
        XCTAssertNil(decode(Bool.self, "[null]").value)
        XCTAssertEqual(encode(true), "[true]")
        XCTAssertEqual(encode(nil as Bool?), "[null]")
    }

    func testInt() {
        XCTAssertEqual(1, decode(Int.self, "[1]").value)
        XCTAssertNil(decode(Int.self, "[null]").value)
        XCTAssertEqual(encode(10), "[10]")
        XCTAssertEqual(encode(nil as Int?), "[null]")
    }

    func testFloat() {
        XCTAssertEqual(2.2, decode(Float.self, "[2.2]").value)
        XCTAssertNil(decode(Float.self, "[null]").value)
        XCTAssertEqual(encode(2.25), "[2.25]")
        XCTAssertEqual(encode(nil as Float?), "[null]")
    }

    func testDouble() {
        XCTAssertEqual(2.2, decode(Double.self, "[2.2]").value)
        XCTAssertNil(decode(Double.self, "[null]").value)
        XCTAssertEqual(encode(2.25), "[2.25]")
        XCTAssertEqual(encode(nil as Double?), "[null]")
    }

    func testDecimal() {
        XCTAssertEqual("2.2", decode(Decimal128.self, "[2.2]"))
        XCTAssertEqual("1234567890e123", decode(Decimal128.self, "[\"1234567890e123\"]"))
        XCTAssertEqual(nil, decode(Decimal128?.self, "[null]"))
        XCTAssertEqual("[\"1.23456789E132\"]", encode("1234567890e123" as Decimal128))
    }

    func testNullableRealmProperty() {
        let decoder = JSONDecoder()
        let obj = try! decoder.decode(CodableObject.self, from: Data(legacyObjectString(true).utf8))

        XCTAssertEqual(obj.otherBool.value, nil)
        XCTAssertEqual(obj.otherInt.value, nil)
        XCTAssertEqual(obj.otherInt8.value, nil)
        XCTAssertEqual(obj.otherInt16.value, nil)
        XCTAssertEqual(obj.otherInt32.value, nil)
        XCTAssertEqual(obj.otherInt64.value, nil)
        XCTAssertEqual(obj.otherFloat.value, nil)
        XCTAssertEqual(obj.otherDouble.value, nil)
        XCTAssertEqual(obj.otherDouble.value, .none)
    }

    func testObject() throws {
        let decoder = JSONDecoder()
        let obj = try decoder.decode(CodableObject.self, from: Data(legacyObjectString().utf8))

        XCTAssertEqual(obj.bool, true)
        XCTAssertEqual(obj.int, 123)
        XCTAssertEqual(obj.int8, 123)
        XCTAssertEqual(obj.int16, 123)
        XCTAssertEqual(obj.int32, 123)
        XCTAssertEqual(obj.int64, 123)
        XCTAssertEqual(obj.float, 2.5)
        XCTAssertEqual(obj.double, 2.5)
        XCTAssertEqual(obj.string, "abc")
        XCTAssertEqual(obj.date, Date(timeIntervalSinceReferenceDate: 2.5))
        XCTAssertEqual(obj.data, Data("def".utf8))
        XCTAssertEqual(obj.decimal, "1.5e2")
        XCTAssertEqual(obj.objectId, ObjectId("1234567890abcdef12345678"))

        XCTAssertEqual(obj.boolOpt.value, true)
        XCTAssertEqual(obj.intOpt.value, 123)
        XCTAssertEqual(obj.int8Opt.value, 123)
        XCTAssertEqual(obj.int16Opt.value, 123)
        XCTAssertEqual(obj.int32Opt.value, 123)
        XCTAssertEqual(obj.int64Opt.value, 123)
        XCTAssertEqual(obj.floatOpt.value, 2.5)
        XCTAssertEqual(obj.doubleOpt.value, 2.5)
        XCTAssertEqual(obj.stringOpt, "abc")
        XCTAssertEqual(obj.dateOpt, Date(timeIntervalSinceReferenceDate: 2.5))
        XCTAssertEqual(obj.dataOpt, Data("def".utf8))
        XCTAssertEqual(obj.decimalOpt, "1.5e2")
        XCTAssertEqual(obj.objectIdOpt, ObjectId("1234567890abcdef12345678"))

        XCTAssertEqual(obj.otherBool.value, true)
        XCTAssertEqual(obj.otherInt.value, 123)
        XCTAssertEqual(obj.otherInt8.value, 123)
        XCTAssertEqual(obj.otherInt16.value, 123)
        XCTAssertEqual(obj.otherInt32.value, 123)
        XCTAssertEqual(obj.otherInt64.value, 123)
        XCTAssertEqual(obj.otherFloat.value, 2.5)
        XCTAssertEqual(obj.otherDouble.value, 2.5)
        XCTAssertEqual(obj.otherEnum.value, .value1)

        XCTAssertEqual(obj.boolList.first, true)
        XCTAssertEqual(obj.intList.first, 123)
        XCTAssertEqual(obj.int8List.first, 123)
        XCTAssertEqual(obj.int16List.first, 123)
        XCTAssertEqual(obj.int32List.first, 123)
        XCTAssertEqual(obj.int64List.first, 123)
        XCTAssertEqual(obj.floatList.first, 2.5)
        XCTAssertEqual(obj.doubleList.first, 2.5)
        XCTAssertEqual(obj.stringList.first, "abc")
        XCTAssertEqual(obj.dateList.first, Date(timeIntervalSinceReferenceDate: 2.5))
        XCTAssertEqual(obj.dataList.first, Data("def".utf8))
        XCTAssertEqual(obj.decimalList.first, "1.5e2")
        XCTAssertEqual(obj.objectIdList.first, ObjectId("1234567890abcdef12345678"))

        XCTAssertEqual(obj.boolOptList.first, true)
        XCTAssertEqual(obj.intOptList.first, 123)
        XCTAssertEqual(obj.int8OptList.first, 123)
        XCTAssertEqual(obj.int16OptList.first, 123)
        XCTAssertEqual(obj.int32OptList.first, 123)
        XCTAssertEqual(obj.int64OptList.first, 123)
        XCTAssertEqual(obj.floatOptList.first, 2.5)
        XCTAssertEqual(obj.doubleOptList.first, 2.5)
        XCTAssertEqual(obj.stringOptList.first, "abc")
        XCTAssertEqual(obj.dateOptList.first, Date(timeIntervalSinceReferenceDate: 2.5))
        XCTAssertEqual(obj.dataOptList.first, Data("def".utf8))
        XCTAssertEqual(obj.decimalOptList.first, "1.5e2")
        XCTAssertEqual(obj.objectIdOptList.first, ObjectId("1234567890abcdef12345678"))

        XCTAssertEqual(obj.boolSet.first, true)
        XCTAssertEqual(obj.intSet.first, 123)
        XCTAssertEqual(obj.int8Set.first, 123)
        XCTAssertEqual(obj.int16Set.first, 123)
        XCTAssertEqual(obj.int32Set.first, 123)
        XCTAssertEqual(obj.int64Set.first, 123)
        XCTAssertEqual(obj.floatSet.first, 2.5)
        XCTAssertEqual(obj.doubleSet.first, 2.5)
        XCTAssertEqual(obj.stringSet.first, "abc")
        XCTAssertEqual(obj.dateSet.first, Date(timeIntervalSinceReferenceDate: 2.5))
        XCTAssertEqual(obj.dataSet.first, Data("def".utf8))
        XCTAssertEqual(obj.decimalSet.first, "1.5e2")
        XCTAssertEqual(obj.objectIdSet.first, ObjectId("1234567890abcdef12345678"))

        XCTAssertEqual(obj.boolOptSet.first, true)
        XCTAssertEqual(obj.intOptSet.first, 123)
        XCTAssertEqual(obj.int8OptSet.first, 123)
        XCTAssertEqual(obj.int16OptSet.first, 123)
        XCTAssertEqual(obj.int32OptSet.first, 123)
        XCTAssertEqual(obj.int64OptSet.first, 123)
        XCTAssertEqual(obj.floatOptSet.first, 2.5)
        XCTAssertEqual(obj.doubleOptSet.first, 2.5)
        XCTAssertEqual(obj.stringOptSet.first, "abc")
        XCTAssertEqual(obj.dateOptSet.first, Date(timeIntervalSinceReferenceDate: 2.5))
        XCTAssertEqual(obj.dataOptSet.first, Data("def".utf8))
        XCTAssertEqual(obj.decimalOptSet.first, "1.5e2")
        XCTAssertEqual(obj.objectIdOptSet.first, ObjectId("1234567890abcdef12345678"))

        XCTAssertEqual(obj.boolMap["foo"], true)
        XCTAssertEqual(obj.intMap["foo"], 123)
        XCTAssertEqual(obj.int8Map["foo"], 123)
        XCTAssertEqual(obj.int16Map["foo"], 123)
        XCTAssertEqual(obj.int32Map["foo"], 123)
        XCTAssertEqual(obj.int64Map["foo"], 123)
        XCTAssertEqual(obj.floatMap["foo"], 2.5)
        XCTAssertEqual(obj.doubleMap["foo"], 2.5)
        XCTAssertEqual(obj.stringMap["foo"], "abc")
        XCTAssertEqual(obj.dateMap["foo"], Date(timeIntervalSinceReferenceDate: 2.5))
        XCTAssertEqual(obj.dataMap["foo"], Data("def".utf8))
        XCTAssertEqual(obj.decimalMap["foo"], "1.5e2")
        XCTAssertEqual(obj.objectIdMap["foo"], ObjectId("1234567890abcdef12345678"))

        XCTAssertEqual(obj.boolOptMap["foo"], true)
        XCTAssertEqual(obj.intOptMap["foo"], 123)
        XCTAssertEqual(obj.int8OptMap["foo"], 123)
        XCTAssertEqual(obj.int16OptMap["foo"], 123)
        XCTAssertEqual(obj.int32OptMap["foo"], 123)
        XCTAssertEqual(obj.int64OptMap["foo"], 123)
        XCTAssertEqual(obj.floatOptMap["foo"], 2.5)
        XCTAssertEqual(obj.doubleOptMap["foo"], 2.5)
        XCTAssertEqual(obj.stringOptMap["foo"], "abc")
        XCTAssertEqual(obj.dateOptMap["foo"], Date(timeIntervalSinceReferenceDate: 2.5))
        XCTAssertEqual(obj.dataOptMap["foo"], Data("def".utf8))
        XCTAssertEqual(obj.decimalOptMap["foo"], "1.5e2")
        XCTAssertEqual(obj.objectIdOptMap["foo"], ObjectId("1234567890abcdef12345678"))

        let expected = "{\"doubleOptMap\":{\"foo\":2.5},\"floatSet\":[2.5],\"int8\":123,\"otherInt32\":123,\"int16Map\":{\"foo\":123},\"stringOpt\":\"abc\",\"uuidOptSet\":[\"00000000-0000-0000-0000-000000000000\"],\"int8OptMap\":{\"foo\":123},\"dataOptSet\":[\"ZGVm\"],\"stringOptSet\":[\"abc\"],\"doubleMap\":{\"foo\":2.5},\"int16OptMap\":{\"foo\":123},\"decimalOpt\":\"1.5E2\",\"decimalOptSet\":[\"1.5E2\"],\"uuidList\":[\"00000000-0000-0000-0000-000000000000\"],\"otherFloat\":2.5,\"dateOptSet\":[2.5],\"uuid\":\"00000000-0000-0000-0000-000000000000\",\"floatOpt\":2.5,\"int32OptSet\":[123],\"string\":\"abc\",\"dataOpt\":\"ZGVm\",\"int8Opt\":123,\"int16\":123,\"floatMap\":{\"foo\":2.5},\"decimalMap\":{\"foo\":\"1.5E2\"},\"dateOpt\":2.5,\"int64List\":[123],\"otherBool\":true,\"floatOptList\":[2.5],\"boolOptList\":[true],\"intOptSet\":[123],\"int32\":123,\"floatList\":[2.5],\"date\":2.5,\"dataSet\":[\"ZGVm\"],\"uuidOptList\":[\"00000000-0000-0000-0000-000000000000\"],\"int8Set\":[123],\"intOptList\":[123],\"int32Set\":[123],\"int32OptMap\":{\"foo\":123},\"dateSet\":[2.5],\"int32List\":[123],\"objectId\":\"1234567890abcdef12345678\",\"stringOptMap\":{\"foo\":\"abc\"},\"doubleOpt\":2.5,\"objectIdOptMap\":{\"foo\":\"1234567890abcdef12345678\"},\"boolOptSet\":[true],\"otherInt16\":123,\"intOpt\":123,\"intMap\":{\"foo\":123},\"objectIdOptSet\":[\"1234567890abcdef12345678\"],\"stringOptList\":[\"abc\"],\"int8OptList\":[123],\"int32Opt\":123,\"double\":2.5,\"stringSet\":[\"abc\"],\"otherDouble\":2.5,\"decimal\":\"1.5E2\",\"int32Map\":{\"foo\":123},\"int8OptSet\":[123],\"boolMap\":{\"foo\":true},\"int64OptList\":[123],\"dateOptList\":[2.5],\"intOptMap\":{\"foo\":123},\"bool\":true,\"int32OptList\":[123],\"intSet\":[123],\"dataOptList\":[\"ZGVm\"],\"float\":2.5,\"floatOptSet\":[2.5],\"decimalOptMap\":{\"foo\":\"1.5E2\"},\"uuidMap\":{\"foo\":\"00000000-0000-0000-0000-000000000000\"},\"int\":123,\"decimalSet\":[\"1.5E2\"],\"int16List\":[123],\"dataList\":[\"ZGVm\"],\"uuidOptMap\":{\"foo\":\"00000000-0000-0000-0000-000000000000\"},\"dataOptMap\":{\"foo\":\"ZGVm\"},\"otherEnum\":1,\"int8List\":[123],\"objectIdSet\":[\"1234567890abcdef12345678\"],\"objectIdOptList\":[\"1234567890abcdef12345678\"],\"otherInt64\":123,\"doubleOptList\":[2.5],\"floatOptMap\":{\"foo\":2.5},\"intList\":[123],\"int64Set\":[123],\"dateOptMap\":{\"foo\":2.5},\"int16OptList\":[123],\"boolList\":[true],\"doubleOptSet\":[2.5],\"doubleSet\":[2.5],\"stringMap\":{\"foo\":\"abc\"},\"int64OptSet\":[123],\"decimalOptList\":[\"1.5E2\"],\"otherInt\":123,\"dateList\":[2.5],\"objectIdList\":[\"1234567890abcdef12345678\"],\"stringList\":[\"abc\"],\"boolOpt\":true,\"objectIdMap\":{\"foo\":\"1234567890abcdef12345678\"},\"doubleList\":[2.5],\"dataMap\":{\"foo\":\"ZGVm\"},\"int16Set\":[123],\"int64\":123,\"int8Map\":{\"foo\":123},\"int64Opt\":123,\"boolSet\":[true],\"int64Map\":{\"foo\":123},\"dateMap\":{\"foo\":2.5},\"uuidOpt\":\"00000000-0000-0000-0000-000000000000\",\"int64OptMap\":{\"foo\":123},\"boolOptMap\":{\"foo\":true},\"otherInt8\":123,\"objectIdOpt\":\"1234567890abcdef12345678\",\"data\":\"ZGVm\",\"int16OptSet\":[123],\"decimalList\":[\"1.5E2\"],\"int16Opt\":123,\"uuidSet\":[\"00000000-0000-0000-0000-000000000000\"]}"

        let expectedData = expected.data(using: .utf8)!
        let expectedDictionary = try JSONSerialization.jsonObject(with: expectedData, options: []) as? [String: Any]
        let encodedDictionary  = try JSONSerialization.jsonObject(with: encoder.encode(obj), options: []) as? [String: Any]
        XCTAssertEqual(expectedDictionary! as NSDictionary, encodedDictionary! as NSDictionary)
    }

    func testLegacyObjectOptionalNotRequired() {
        let str = """
        {
            "bool": true,
            "string": "abc",
            "int": 123,
            "int8": 123,
            "int16": 123,
            "int32": 123,
            "int64": 123,
            "float": 2.5,
            "double": 2.5,
            "date": 2.5,
            "data": "\(Data("def".utf8).base64EncodedString())",
            "decimal": "1.5e2",
            "objectId": "1234567890abcdef12345678",
            "uuid": "00000000-0000-0000-0000-000000000000",

            "intOpt": null,
            "int8Opt": null,
            "int16Opt": null,
            "int32Opt": null,
            "int64Opt": null,
            "floatOpt": null,
            "doubleOpt": null,
            "boolOpt": null,

            "otherBool": true,
            "otherInt": 123,
            "otherInt8": 123,
            "otherInt16": 123,
            "otherInt32": 123,
            "otherInt64": 123,
            "otherFloat": 2.5,
            "otherDouble": 2.5,
            "otherEnum": 1,
            "otherAny": 1,

            "boolList": [true],
            "stringList": ["abc"],
            "intList": [123],
            "int8List": [123],
            "int16List": [123],
            "int32List": [123],
            "int64List": [123],
            "floatList": [2.5],
            "doubleList": [2.5],
            "dateList": [2.5],
            "dataList": ["\(Data("def".utf8).base64EncodedString())"],
            "decimalList": ["1.5e2"],
            "objectIdList": ["1234567890abcdef12345678"],
            "uuidList": ["00000000-0000-0000-0000-000000000000"],

            "boolOptList": [true],
            "stringOptList": ["abc"],
            "intOptList": [123],
            "int8OptList": [123],
            "int16OptList": [123],
            "int32OptList": [123],
            "int64OptList": [123],
            "floatOptList": [2.5],
            "doubleOptList": [2.5],
            "dateOptList": [2.5],
            "dataOptList": ["\(Data("def".utf8).base64EncodedString())"],
            "decimalOptList": ["1.5e2"],
            "objectIdOptList": ["1234567890abcdef12345678"],
            "uuidOptList": ["00000000-0000-0000-0000-000000000000"],

            "boolSet": [true],
            "stringSet": ["abc"],
            "intSet": [123],
            "int8Set": [123],
            "int16Set": [123],
            "int32Set": [123],
            "int64Set": [123],
            "floatSet": [2.5],
            "doubleSet": [2.5],
            "dateSet": [2.5],
            "dataSet": ["\(Data("def".utf8).base64EncodedString())"],
            "decimalSet": ["1.5e2"],
            "objectIdSet": ["1234567890abcdef12345678"],
            "uuidSet": ["00000000-0000-0000-0000-000000000000"],

            "boolOptSet": [true],
            "stringOptSet": ["abc"],
            "intOptSet": [123],
            "int8OptSet": [123],
            "int16OptSet": [123],
            "int32OptSet": [123],
            "int64OptSet": [123],
            "floatOptSet": [2.5],
            "doubleOptSet": [2.5],
            "dateOptSet": [2.5],
            "dataOptSet": ["\(Data("def".utf8).base64EncodedString())"],
            "decimalOptSet": ["1.5e2"],
            "objectIdOptSet": ["1234567890abcdef12345678"],
            "uuidOptSet": ["00000000-0000-0000-0000-000000000000"],

            "boolMap": {"foo": true},
            "stringMap": {"foo": "abc"},
            "intMap": {"foo": 123},
            "int8Map": {"foo": 123},
            "int16Map": {"foo": 123},
            "int32Map": {"foo": 123},
            "int64Map": {"foo": 123},
            "floatMap": {"foo": 2.5},
            "doubleMap": {"foo": 2.5},
            "dateMap": {"foo": 2.5},
            "dataMap": {"foo": "\(Data("def".utf8).base64EncodedString())"},
            "decimalMap": {"foo": "1.5e2"},
            "objectIdMap": {"foo": "1234567890abcdef12345678"},
            "uuidMap": {"foo": "00000000-0000-0000-0000-000000000000"},

            "boolOptMap": {"foo": true},
            "stringOptMap": {"foo": "abc"},
            "intOptMap": {"foo": 123},
            "int8OptMap": {"foo": 123},
            "int16OptMap": {"foo": 123},
            "int32OptMap": {"foo": 123},
            "int64OptMap": {"foo": 123},
            "floatOptMap": {"foo": 2.5},
            "doubleOptMap": {"foo": 2.5},
            "dateOptMap": {"foo": 2.5},
            "dataOptMap": {"foo": "\(Data("def".utf8).base64EncodedString())"},
            "decimalOptMap": {"foo": "1.5e2"},
            "objectIdOptMap": {"foo": "1234567890abcdef12345678"},
            "uuidOptMap": {"foo": "00000000-0000-0000-0000-000000000000"}
        }
        """
        let decoder = JSONDecoder()
        let obj = try! decoder.decode(CodableObject.self, from: Data(str.utf8))

        XCTAssertNil(obj.stringOpt)
        XCTAssertNil(obj.dateOpt)
        XCTAssertNil(obj.dataOpt)
        XCTAssertNil(obj.decimalOpt)
        XCTAssertNil(obj.objectIdOpt)
    }

    func testModernObject() throws {
        // Note: "ZGVm" is Data("def".utf8).base64EncodedString()
        // This string needs to exactly match what JSONEncoder produces so that
        // we can validate round-tripping
        let str = if #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, *) {
            """
            {
              "bool" : true,
              "boolList" : [
                true
              ],
              "boolMap" : {
                "foo" : true
              },
              "boolOpt" : true,
              "boolOptList" : [
                true
              ],
              "boolOptMap" : {
                "foo" : true
              },
              "boolOptSet" : [
                true
              ],
              "boolSet" : [
                true
              ],
              "data" : "ZGVm",
              "dataList" : [
                "ZGVm"
              ],
              "dataMap" : {
                "foo" : "ZGVm"
              },
              "dataOpt" : "ZGVm",
              "dataOptList" : [
                "ZGVm"
              ],
              "dataOptMap" : {
                "foo" : "ZGVm"
              },
              "dataOptSet" : [
                "ZGVm"
              ],
              "dataSet" : [
                "ZGVm"
              ],
              "date" : 2.5,
              "dateList" : [
                2.5
              ],
              "dateMap" : {
                "foo" : 2.5
              },
              "dateOpt" : 2.5,
              "dateOptList" : [
                2.5
              ],
              "dateOptMap" : {
                "foo" : 2.5
              },
              "dateOptSet" : [
                2.5
              ],
              "dateSet" : [
                2.5
              ],
              "decimal" : "1.5E2",
              "decimalList" : [
                "1.5E2"
              ],
              "decimalMap" : {
                "foo" : "1.5E2"
              },
              "decimalOpt" : "1.5E2",
              "decimalOptList" : [
                "1.5E2"
              ],
              "decimalOptMap" : {
                "foo" : "1.5E2"
              },
              "decimalOptSet" : [
                "1.5E2"
              ],
              "decimalSet" : [
                "1.5E2"
              ],
              "double" : 2.5,
              "doubleList" : [
                2.5
              ],
              "doubleMap" : {
                "foo" : 2.5
              },
              "doubleOpt" : 2.5,
              "doubleOptList" : [
                2.5
              ],
              "doubleOptMap" : {
                "foo" : 2.5
              },
              "doubleOptSet" : [
                2.5
              ],
              "doubleSet" : [
                2.5
              ],
              "embeddedObjectList" : [
                {
                  "value" : 8
                }
              ],
              "embeddedObjectOpt" : {
                "value" : 6
              },
              "embeddedObjectOptMap" : {
                "b" : {
                  "value" : 10
                }
              },
              "float" : 2.5,
              "floatList" : [
                2.5
              ],
              "floatMap" : {
                "foo" : 2.5
              },
              "floatOpt" : 2.5,
              "floatOptList" : [
                2.5
              ],
              "floatOptMap" : {
                "foo" : 2.5
              },
              "floatOptSet" : [
                2.5
              ],
              "floatSet" : [
                2.5
              ],
              "int" : 123,
              "int16" : 123,
              "int16List" : [
                123
              ],
              "int16Map" : {
                "foo" : 123
              },
              "int16Opt" : 123,
              "int16OptList" : [
                123
              ],
              "int16OptMap" : {
                "foo" : 123
              },
              "int16OptSet" : [
                123
              ],
              "int16Set" : [
                123
              ],
              "int32" : 123,
              "int32List" : [
                123
              ],
              "int32Map" : {
                "foo" : 123
              },
              "int32Opt" : 123,
              "int32OptList" : [
                123
              ],
              "int32OptMap" : {
                "foo" : 123
              },
              "int32OptSet" : [
                123
              ],
              "int32Set" : [
                123
              ],
              "int64" : 123,
              "int64List" : [
                123
              ],
              "int64Map" : {
                "foo" : 123
              },
              "int64Opt" : 123,
              "int64OptList" : [
                123
              ],
              "int64OptMap" : {
                "foo" : 123
              },
              "int64OptSet" : [
                123
              ],
              "int64Set" : [
                123
              ],
              "int8" : 123,
              "int8List" : [
                123
              ],
              "int8Map" : {
                "foo" : 123
              },
              "int8Opt" : 123,
              "int8OptList" : [
                123
              ],
              "int8OptMap" : {
                "foo" : 123
              },
              "int8OptSet" : [
                123
              ],
              "int8Set" : [
                123
              ],
              "intList" : [
                123
              ],
              "intMap" : {
                "foo" : 123
              },
              "intOpt" : 123,
              "intOptList" : [
                123
              ],
              "intOptMap" : {
                "foo" : 123
              },
              "intOptSet" : [
                123
              ],
              "intSet" : [
                123
              ],
              "objectId" : "1234567890abcdef12345678",
              "objectIdList" : [
                "1234567890abcdef12345678"
              ],
              "objectIdMap" : {
                "foo" : "1234567890abcdef12345678"
              },
              "objectIdOpt" : "1234567890abcdef12345678",
              "objectIdOptList" : [
                "1234567890abcdef12345678"
              ],
              "objectIdOptMap" : {
                "foo" : "1234567890abcdef12345678"
              },
              "objectIdOptSet" : [
                "1234567890abcdef12345678"
              ],
              "objectIdSet" : [
                "1234567890abcdef12345678"
              ],
              "objectList" : [
                {
                  "value" : 7
                }
              ],
              "objectOpt" : {
                "value" : 5
              },
              "objectOptMap" : {
                "a" : {
                  "value" : 9
                }
              },
              "objectSet" : [
                {
                  "value" : 9
                }
              ],
              "string" : "abc",
              "stringList" : [
                "abc"
              ],
              "stringMap" : {
                "foo" : "abc"
              },
              "stringOpt" : "abc",
              "stringOptList" : [
                "abc"
              ],
              "stringOptMap" : {
                "foo" : "abc"
              },
              "stringOptSet" : [
                "abc"
              ],
              "stringSet" : [
                "abc"
              ],
              "uuid" : "00000000-0000-0000-0000-000000000000",
              "uuidList" : [
                "00000000-0000-0000-0000-000000000000"
              ],
              "uuidMap" : {
                "foo" : "00000000-0000-0000-0000-000000000000"
              },
              "uuidOpt" : "00000000-0000-0000-0000-000000000000",
              "uuidOptList" : [
                "00000000-0000-0000-0000-000000000000"
              ],
              "uuidOptMap" : {
                "foo" : "00000000-0000-0000-0000-000000000000"
              },
              "uuidOptSet" : [
                "00000000-0000-0000-0000-000000000000"
              ],
              "uuidSet" : [
                "00000000-0000-0000-0000-000000000000"
              ]
            }
            """
        } else {
            """
            {
              "bool" : true,
              "boolList" : [
                true
              ],
              "boolMap" : {
                "foo" : true
              },
              "boolOpt" : true,
              "boolOptList" : [
                true
              ],
              "boolOptMap" : {
                "foo" : true
              },
              "boolOptSet" : [
                true
              ],
              "boolSet" : [
                true
              ],
              "data" : "ZGVm",
              "dataList" : [
                "ZGVm"
              ],
              "dataMap" : {
                "foo" : "ZGVm"
              },
              "dataOpt" : "ZGVm",
              "dataOptList" : [
                "ZGVm"
              ],
              "dataOptMap" : {
                "foo" : "ZGVm"
              },
              "dataOptSet" : [
                "ZGVm"
              ],
              "dataSet" : [
                "ZGVm"
              ],
              "date" : 2.5,
              "dateList" : [
                2.5
              ],
              "dateMap" : {
                "foo" : 2.5
              },
              "dateOpt" : 2.5,
              "dateOptList" : [
                2.5
              ],
              "dateOptMap" : {
                "foo" : 2.5
              },
              "dateOptSet" : [
                2.5
              ],
              "dateSet" : [
                2.5
              ],
              "decimal" : "1.5E2",
              "decimalList" : [
                "1.5E2"
              ],
              "decimalMap" : {
                "foo" : "1.5E2"
              },
              "decimalOpt" : "1.5E2",
              "decimalOptList" : [
                "1.5E2"
              ],
              "decimalOptMap" : {
                "foo" : "1.5E2"
              },
              "decimalOptSet" : [
                "1.5E2"
              ],
              "decimalSet" : [
                "1.5E2"
              ],
              "double" : 2.5,
              "doubleList" : [
                2.5
              ],
              "doubleMap" : {
                "foo" : 2.5
              },
              "doubleOpt" : 2.5,
              "doubleOptList" : [
                2.5
              ],
              "doubleOptMap" : {
                "foo" : 2.5
              },
              "doubleOptSet" : [
                2.5
              ],
              "doubleSet" : [
                2.5
              ],
              "embeddedObjectList" : [
                {
                  "value" : 8
                }
              ],
              "embeddedObjectOpt" : {
                "value" : 6
              },
              "embeddedObjectOptMap" : {
                "b" : {
                  "value" : 10
                }
              },
              "float" : 2.5,
              "floatList" : [
                2.5
              ],
              "floatMap" : {
                "foo" : 2.5
              },
              "floatOpt" : 2.5,
              "floatOptList" : [
                2.5
              ],
              "floatOptMap" : {
                "foo" : 2.5
              },
              "floatOptSet" : [
                2.5
              ],
              "floatSet" : [
                2.5
              ],
              "int" : 123,
              "int8" : 123,
              "int8List" : [
                123
              ],
              "int8Map" : {
                "foo" : 123
              },
              "int8Opt" : 123,
              "int8OptList" : [
                123
              ],
              "int8OptMap" : {
                "foo" : 123
              },
              "int8OptSet" : [
                123
              ],
              "int8Set" : [
                123
              ],
              "int16" : 123,
              "int16List" : [
                123
              ],
              "int16Map" : {
                "foo" : 123
              },
              "int16Opt" : 123,
              "int16OptList" : [
                123
              ],
              "int16OptMap" : {
                "foo" : 123
              },
              "int16OptSet" : [
                123
              ],
              "int16Set" : [
                123
              ],
              "int32" : 123,
              "int32List" : [
                123
              ],
              "int32Map" : {
                "foo" : 123
              },
              "int32Opt" : 123,
              "int32OptList" : [
                123
              ],
              "int32OptMap" : {
                "foo" : 123
              },
              "int32OptSet" : [
                123
              ],
              "int32Set" : [
                123
              ],
              "int64" : 123,
              "int64List" : [
                123
              ],
              "int64Map" : {
                "foo" : 123
              },
              "int64Opt" : 123,
              "int64OptList" : [
                123
              ],
              "int64OptMap" : {
                "foo" : 123
              },
              "int64OptSet" : [
                123
              ],
              "int64Set" : [
                123
              ],
              "intList" : [
                123
              ],
              "intMap" : {
                "foo" : 123
              },
              "intOpt" : 123,
              "intOptList" : [
                123
              ],
              "intOptMap" : {
                "foo" : 123
              },
              "intOptSet" : [
                123
              ],
              "intSet" : [
                123
              ],
              "objectId" : "1234567890abcdef12345678",
              "objectIdList" : [
                "1234567890abcdef12345678"
              ],
              "objectIdMap" : {
                "foo" : "1234567890abcdef12345678"
              },
              "objectIdOpt" : "1234567890abcdef12345678",
              "objectIdOptList" : [
                "1234567890abcdef12345678"
              ],
              "objectIdOptMap" : {
                "foo" : "1234567890abcdef12345678"
              },
              "objectIdOptSet" : [
                "1234567890abcdef12345678"
              ],
              "objectIdSet" : [
                "1234567890abcdef12345678"
              ],
              "objectList" : [
                {
                  "value" : 7
                }
              ],
              "objectOpt" : {
                "value" : 5
              },
              "objectOptMap" : {
                "a" : {
                  "value" : 9
                }
              },
              "objectSet" : [
                {
                  "value" : 9
                }
              ],
              "string" : "abc",
              "stringList" : [
                "abc"
              ],
              "stringMap" : {
                "foo" : "abc"
              },
              "stringOpt" : "abc",
              "stringOptList" : [
                "abc"
              ],
              "stringOptMap" : {
                "foo" : "abc"
              },
              "stringOptSet" : [
                "abc"
              ],
              "stringSet" : [
                "abc"
              ],
              "uuid" : "00000000-0000-0000-0000-000000000000",
              "uuidList" : [
                "00000000-0000-0000-0000-000000000000"
              ],
              "uuidMap" : {
                "foo" : "00000000-0000-0000-0000-000000000000"
              },
              "uuidOpt" : "00000000-0000-0000-0000-000000000000",
              "uuidOptList" : [
                "00000000-0000-0000-0000-000000000000"
              ],
              "uuidOptMap" : {
                "foo" : "00000000-0000-0000-0000-000000000000"
              },
              "uuidOptSet" : [
                "00000000-0000-0000-0000-000000000000"
              ],
              "uuidSet" : [
                "00000000-0000-0000-0000-000000000000"
              ]
            }
            """
        }

        let decoder = JSONDecoder()
        let obj = try decoder.decode(ModernCodableObject.self, from: Data(str.utf8))

        XCTAssertEqual(obj.bool, true)
        XCTAssertEqual(obj.int, 123)
        XCTAssertEqual(obj.int8, 123)
        XCTAssertEqual(obj.int16, 123)
        XCTAssertEqual(obj.int32, 123)
        XCTAssertEqual(obj.int64, 123)
        XCTAssertEqual(obj.float, 2.5)
        XCTAssertEqual(obj.double, 2.5)
        XCTAssertEqual(obj.string, "abc")
        XCTAssertEqual(obj.date, Date(timeIntervalSinceReferenceDate: 2.5))
        XCTAssertEqual(obj.data, Data("def".utf8))
        XCTAssertEqual(obj.decimal, "1.5e2")
        XCTAssertEqual(obj.objectId, ObjectId("1234567890abcdef12345678"))

        XCTAssertEqual(obj.boolOpt, true)
        XCTAssertEqual(obj.intOpt, 123)
        XCTAssertEqual(obj.int8Opt, 123)
        XCTAssertEqual(obj.int16Opt, 123)
        XCTAssertEqual(obj.int32Opt, 123)
        XCTAssertEqual(obj.int64Opt, 123)
        XCTAssertEqual(obj.floatOpt, 2.5)
        XCTAssertEqual(obj.doubleOpt, 2.5)
        XCTAssertEqual(obj.stringOpt, "abc")
        XCTAssertEqual(obj.dateOpt, Date(timeIntervalSinceReferenceDate: 2.5))
        XCTAssertEqual(obj.dataOpt, Data("def".utf8))
        XCTAssertEqual(obj.decimalOpt, "1.5e2")
        XCTAssertEqual(obj.objectIdOpt, ObjectId("1234567890abcdef12345678"))

        XCTAssertEqual(obj.boolList.first, true)
        XCTAssertEqual(obj.intList.first, 123)
        XCTAssertEqual(obj.int8List.first, 123)
        XCTAssertEqual(obj.int16List.first, 123)
        XCTAssertEqual(obj.int32List.first, 123)
        XCTAssertEqual(obj.int64List.first, 123)
        XCTAssertEqual(obj.floatList.first, 2.5)
        XCTAssertEqual(obj.doubleList.first, 2.5)
        XCTAssertEqual(obj.stringList.first, "abc")
        XCTAssertEqual(obj.dateList.first, Date(timeIntervalSinceReferenceDate: 2.5))
        XCTAssertEqual(obj.dataList.first, Data("def".utf8))
        XCTAssertEqual(obj.decimalList.first, "1.5e2")
        XCTAssertEqual(obj.objectIdList.first, ObjectId("1234567890abcdef12345678"))

        XCTAssertEqual(obj.boolOptList.first, true)
        XCTAssertEqual(obj.intOptList.first, 123)
        XCTAssertEqual(obj.int8OptList.first, 123)
        XCTAssertEqual(obj.int16OptList.first, 123)
        XCTAssertEqual(obj.int32OptList.first, 123)
        XCTAssertEqual(obj.int64OptList.first, 123)
        XCTAssertEqual(obj.floatOptList.first, 2.5)
        XCTAssertEqual(obj.doubleOptList.first, 2.5)
        XCTAssertEqual(obj.stringOptList.first, "abc")
        XCTAssertEqual(obj.dateOptList.first, Date(timeIntervalSinceReferenceDate: 2.5))
        XCTAssertEqual(obj.dataOptList.first, Data("def".utf8))
        XCTAssertEqual(obj.decimalOptList.first, "1.5e2")
        XCTAssertEqual(obj.objectIdOptList.first, ObjectId("1234567890abcdef12345678"))

        XCTAssertEqual(obj.boolSet.first, true)
        XCTAssertEqual(obj.intSet.first, 123)
        XCTAssertEqual(obj.int8Set.first, 123)
        XCTAssertEqual(obj.int16Set.first, 123)
        XCTAssertEqual(obj.int32Set.first, 123)
        XCTAssertEqual(obj.int64Set.first, 123)
        XCTAssertEqual(obj.floatSet.first, 2.5)
        XCTAssertEqual(obj.doubleSet.first, 2.5)
        XCTAssertEqual(obj.stringSet.first, "abc")
        XCTAssertEqual(obj.dateSet.first, Date(timeIntervalSinceReferenceDate: 2.5))
        XCTAssertEqual(obj.dataSet.first, Data("def".utf8))
        XCTAssertEqual(obj.decimalSet.first, "1.5e2")
        XCTAssertEqual(obj.objectIdSet.first, ObjectId("1234567890abcdef12345678"))

        XCTAssertEqual(obj.boolOptSet.first, true)
        XCTAssertEqual(obj.intOptSet.first, 123)
        XCTAssertEqual(obj.int8OptSet.first, 123)
        XCTAssertEqual(obj.int16OptSet.first, 123)
        XCTAssertEqual(obj.int32OptSet.first, 123)
        XCTAssertEqual(obj.int64OptSet.first, 123)
        XCTAssertEqual(obj.floatOptSet.first, 2.5)
        XCTAssertEqual(obj.doubleOptSet.first, 2.5)
        XCTAssertEqual(obj.stringOptSet.first, "abc")
        XCTAssertEqual(obj.dateOptSet.first, Date(timeIntervalSinceReferenceDate: 2.5))
        XCTAssertEqual(obj.dataOptSet.first, Data("def".utf8))
        XCTAssertEqual(obj.decimalOptSet.first, "1.5e2")
        XCTAssertEqual(obj.objectIdOptSet.first, ObjectId("1234567890abcdef12345678"))

        XCTAssertEqual(obj.boolMap["foo"], true)
        XCTAssertEqual(obj.intMap["foo"], 123)
        XCTAssertEqual(obj.int8Map["foo"], 123)
        XCTAssertEqual(obj.int16Map["foo"], 123)
        XCTAssertEqual(obj.int32Map["foo"], 123)
        XCTAssertEqual(obj.int64Map["foo"], 123)
        XCTAssertEqual(obj.floatMap["foo"], 2.5)
        XCTAssertEqual(obj.doubleMap["foo"], 2.5)
        XCTAssertEqual(obj.stringMap["foo"], "abc")
        XCTAssertEqual(obj.dateMap["foo"], Date(timeIntervalSinceReferenceDate: 2.5))
        XCTAssertEqual(obj.dataMap["foo"], Data("def".utf8))
        XCTAssertEqual(obj.decimalMap["foo"], "1.5e2")
        XCTAssertEqual(obj.objectIdMap["foo"], ObjectId("1234567890abcdef12345678"))

        XCTAssertEqual(obj.boolOptMap["foo"], true)
        XCTAssertEqual(obj.intOptMap["foo"], 123)
        XCTAssertEqual(obj.int8OptMap["foo"], 123)
        XCTAssertEqual(obj.int16OptMap["foo"], 123)
        XCTAssertEqual(obj.int32OptMap["foo"], 123)
        XCTAssertEqual(obj.int64OptMap["foo"], 123)
        XCTAssertEqual(obj.floatOptMap["foo"], 2.5)
        XCTAssertEqual(obj.doubleOptMap["foo"], 2.5)
        XCTAssertEqual(obj.stringOptMap["foo"], "abc")
        XCTAssertEqual(obj.dateOptMap["foo"], Date(timeIntervalSinceReferenceDate: 2.5))
        XCTAssertEqual(obj.dataOptMap["foo"], Data("def".utf8))
        XCTAssertEqual(obj.decimalOptMap["foo"], "1.5e2")
        XCTAssertEqual(obj.objectIdOptMap["foo"], ObjectId("1234567890abcdef12345678"))

        XCTAssertEqual(obj.objectOpt?.value, 5)
        XCTAssertEqual(obj.embeddedObjectOpt?.value, 6)
        XCTAssertEqual(obj.objectList.first?.value, 7)
        XCTAssertEqual(obj.embeddedObjectList.first?.value, 8)
        XCTAssertEqual(obj.objectSet.first?.value, 9)
        XCTAssertEqual(obj.objectOptMap["a"]??.value, 9)
        XCTAssertEqual(obj.embeddedObjectOptMap["b"]??.value, 10)

        // Verify that it encodes to exactly the original string (which requires
        // that the original string be formatted how JSONEncoder formats things)
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let actual = try XCTUnwrap(String(data: encoder.encode(obj), encoding: .utf8))
        XCTAssertEqual(str, actual)

        let realm = try! Realm()
        try! realm.write {
            realm.add(obj)
        }

        XCTAssertThrowsError(try encoder.encode(obj))
    }

    func testModernObjectNil() throws {
        // Note: "ZGVm" is Data("def".utf8).base64EncodedString()
        // This string needs to exactly match what JSONEncoder produces so that
        // we can validate round-tripping
        let str = if #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, *) {
            """
            {
              "bool" : true,
              "boolList" : [
                true
              ],
              "boolMap" : {
                "foo" : true
              },
              "boolOpt" : null,
              "boolOptList" : [
                null
              ],
              "boolOptMap" : {
                "foo" : null
              },
              "boolOptSet" : [
                null
              ],
              "boolSet" : [
                true
              ],
              "data" : "ZGVm",
              "dataList" : [
                "ZGVm"
              ],
              "dataMap" : {
                "foo" : "ZGVm"
              },
              "dataOpt" : null,
              "dataOptList" : [
                null
              ],
              "dataOptMap" : {
                "foo" : null
              },
              "dataOptSet" : [
                null
              ],
              "dataSet" : [
                "ZGVm"
              ],
              "date" : 2.5,
              "dateList" : [
                2.5
              ],
              "dateMap" : {
                "foo" : 2.5
              },
              "dateOpt" : null,
              "dateOptList" : [
                null
              ],
              "dateOptMap" : {
                "foo" : null
              },
              "dateOptSet" : [
                null
              ],
              "dateSet" : [
                2.5
              ],
              "decimal" : "1.5E2",
              "decimalList" : [
                "1.5E2"
              ],
              "decimalMap" : {
                "foo" : "1.5E2"
              },
              "decimalOpt" : null,
              "decimalOptList" : [
                null
              ],
              "decimalOptMap" : {
                "foo" : null
              },
              "decimalOptSet" : [
                null
              ],
              "decimalSet" : [
                "1.5E2"
              ],
              "double" : 2.5,
              "doubleList" : [
                2.5
              ],
              "doubleMap" : {
                "foo" : 2.5
              },
              "doubleOpt" : null,
              "doubleOptList" : [
                null
              ],
              "doubleOptMap" : {
                "foo" : null
              },
              "doubleOptSet" : [
                null
              ],
              "doubleSet" : [
                2.5
              ],
              "embeddedObjectList" : [

              ],
              "embeddedObjectOpt" : null,
              "embeddedObjectOptMap" : {
                "foo" : null
              },
              "float" : 2.5,
              "floatList" : [
                2.5
              ],
              "floatMap" : {
                "foo" : 2.5
              },
              "floatOpt" : null,
              "floatOptList" : [
                null
              ],
              "floatOptMap" : {
                "foo" : null
              },
              "floatOptSet" : [
                null
              ],
              "floatSet" : [
                2.5
              ],
              "int" : 123,
              "int16" : 123,
              "int16List" : [
                123
              ],
              "int16Map" : {
                "foo" : 123
              },
              "int16Opt" : null,
              "int16OptList" : [
                null
              ],
              "int16OptMap" : {
                "foo" : null
              },
              "int16OptSet" : [
                null
              ],
              "int16Set" : [
                123
              ],
              "int32" : 123,
              "int32List" : [
                123
              ],
              "int32Map" : {
                "foo" : 123
              },
              "int32Opt" : null,
              "int32OptList" : [
                null
              ],
              "int32OptMap" : {
                "foo" : null
              },
              "int32OptSet" : [
                null
              ],
              "int32Set" : [
                123
              ],
              "int64" : 123,
              "int64List" : [
                123
              ],
              "int64Map" : {
                "foo" : 123
              },
              "int64Opt" : null,
              "int64OptList" : [
                null
              ],
              "int64OptMap" : {
                "foo" : null
              },
              "int64OptSet" : [
                null
              ],
              "int64Set" : [
                123
              ],
              "int8" : 123,
              "int8List" : [
                123
              ],
              "int8Map" : {
                "foo" : 123
              },
              "int8Opt" : null,
              "int8OptList" : [
                null
              ],
              "int8OptMap" : {
                "foo" : null
              },
              "int8OptSet" : [
                null
              ],
              "int8Set" : [
                123
              ],
              "intList" : [
                123
              ],
              "intMap" : {
                "foo" : 123
              },
              "intOpt" : null,
              "intOptList" : [
                null
              ],
              "intOptMap" : {
                "foo" : null
              },
              "intOptSet" : [
                null
              ],
              "intSet" : [
                123
              ],
              "objectId" : "1234567890abcdef12345678",
              "objectIdList" : [
                "1234567890abcdef12345678"
              ],
              "objectIdMap" : {
                "foo" : "1234567890abcdef12345678"
              },
              "objectIdOpt" : null,
              "objectIdOptList" : [
                null
              ],
              "objectIdOptMap" : {
                "foo" : null
              },
              "objectIdOptSet" : [
                null
              ],
              "objectIdSet" : [
                "1234567890abcdef12345678"
              ],
              "objectList" : [

              ],
              "objectOpt" : null,
              "objectOptMap" : {
                "foo" : null
              },
              "objectSet" : [

              ],
              "string" : "abc",
              "stringList" : [
                "abc"
              ],
              "stringMap" : {
                "foo" : "abc"
              },
              "stringOpt" : null,
              "stringOptList" : [
                null
              ],
              "stringOptMap" : {
                "foo" : null
              },
              "stringOptSet" : [
                null
              ],
              "stringSet" : [
                "abc"
              ],
              "uuid" : "00000000-0000-0000-0000-000000000000",
              "uuidList" : [
                "00000000-0000-0000-0000-000000000000"
              ],
              "uuidMap" : {
                "foo" : "00000000-0000-0000-0000-000000000000"
              },
              "uuidOpt" : null,
              "uuidOptList" : [
                null
              ],
              "uuidOptMap" : {
                "foo" : null
              },
              "uuidOptSet" : [
                null
              ],
              "uuidSet" : [
                "00000000-0000-0000-0000-000000000000"
              ]
            }
            """
        } else {
            """
            {
              "bool" : true,
              "boolList" : [
                true
              ],
              "boolMap" : {
                "foo" : true
              },
              "boolOpt" : null,
              "boolOptList" : [
                null
              ],
              "boolOptMap" : {
                "foo" : null
              },
              "boolOptSet" : [
                null
              ],
              "boolSet" : [
                true
              ],
              "data" : "ZGVm",
              "dataList" : [
                "ZGVm"
              ],
              "dataMap" : {
                "foo" : "ZGVm"
              },
              "dataOpt" : null,
              "dataOptList" : [
                null
              ],
              "dataOptMap" : {
                "foo" : null
              },
              "dataOptSet" : [
                null
              ],
              "dataSet" : [
                "ZGVm"
              ],
              "date" : 2.5,
              "dateList" : [
                2.5
              ],
              "dateMap" : {
                "foo" : 2.5
              },
              "dateOpt" : null,
              "dateOptList" : [
                null
              ],
              "dateOptMap" : {
                "foo" : null
              },
              "dateOptSet" : [
                null
              ],
              "dateSet" : [
                2.5
              ],
              "decimal" : "1.5E2",
              "decimalList" : [
                "1.5E2"
              ],
              "decimalMap" : {
                "foo" : "1.5E2"
              },
              "decimalOpt" : null,
              "decimalOptList" : [
                null
              ],
              "decimalOptMap" : {
                "foo" : null
              },
              "decimalOptSet" : [
                null
              ],
              "decimalSet" : [
                "1.5E2"
              ],
              "double" : 2.5,
              "doubleList" : [
                2.5
              ],
              "doubleMap" : {
                "foo" : 2.5
              },
              "doubleOpt" : null,
              "doubleOptList" : [
                null
              ],
              "doubleOptMap" : {
                "foo" : null
              },
              "doubleOptSet" : [
                null
              ],
              "doubleSet" : [
                2.5
              ],
              "embeddedObjectList" : [

              ],
              "embeddedObjectOpt" : null,
              "embeddedObjectOptMap" : {
                "foo" : null
              },
              "float" : 2.5,
              "floatList" : [
                2.5
              ],
              "floatMap" : {
                "foo" : 2.5
              },
              "floatOpt" : null,
              "floatOptList" : [
                null
              ],
              "floatOptMap" : {
                "foo" : null
              },
              "floatOptSet" : [
                null
              ],
              "floatSet" : [
                2.5
              ],
              "int" : 123,
              "int8" : 123,
              "int8List" : [
                123
              ],
              "int8Map" : {
                "foo" : 123
              },
              "int8Opt" : null,
              "int8OptList" : [
                null
              ],
              "int8OptMap" : {
                "foo" : null
              },
              "int8OptSet" : [
                null
              ],
              "int8Set" : [
                123
              ],
              "int16" : 123,
              "int16List" : [
                123
              ],
              "int16Map" : {
                "foo" : 123
              },
              "int16Opt" : null,
              "int16OptList" : [
                null
              ],
              "int16OptMap" : {
                "foo" : null
              },
              "int16OptSet" : [
                null
              ],
              "int16Set" : [
                123
              ],
              "int32" : 123,
              "int32List" : [
                123
              ],
              "int32Map" : {
                "foo" : 123
              },
              "int32Opt" : null,
              "int32OptList" : [
                null
              ],
              "int32OptMap" : {
                "foo" : null
              },
              "int32OptSet" : [
                null
              ],
              "int32Set" : [
                123
              ],
              "int64" : 123,
              "int64List" : [
                123
              ],
              "int64Map" : {
                "foo" : 123
              },
              "int64Opt" : null,
              "int64OptList" : [
                null
              ],
              "int64OptMap" : {
                "foo" : null
              },
              "int64OptSet" : [
                null
              ],
              "int64Set" : [
                123
              ],
              "intList" : [
                123
              ],
              "intMap" : {
                "foo" : 123
              },
              "intOpt" : null,
              "intOptList" : [
                null
              ],
              "intOptMap" : {
                "foo" : null
              },
              "intOptSet" : [
                null
              ],
              "intSet" : [
                123
              ],
              "objectId" : "1234567890abcdef12345678",
              "objectIdList" : [
                "1234567890abcdef12345678"
              ],
              "objectIdMap" : {
                "foo" : "1234567890abcdef12345678"
              },
              "objectIdOpt" : null,
              "objectIdOptList" : [
                null
              ],
              "objectIdOptMap" : {
                "foo" : null
              },
              "objectIdOptSet" : [
                null
              ],
              "objectIdSet" : [
                "1234567890abcdef12345678"
              ],
              "objectList" : [

              ],
              "objectOpt" : null,
              "objectOptMap" : {
                "foo" : null
              },
              "objectSet" : [

              ],
              "string" : "abc",
              "stringList" : [
                "abc"
              ],
              "stringMap" : {
                "foo" : "abc"
              },
              "stringOpt" : null,
              "stringOptList" : [
                null
              ],
              "stringOptMap" : {
                "foo" : null
              },
              "stringOptSet" : [
                null
              ],
              "stringSet" : [
                "abc"
              ],
              "uuid" : "00000000-0000-0000-0000-000000000000",
              "uuidList" : [
                "00000000-0000-0000-0000-000000000000"
              ],
              "uuidMap" : {
                "foo" : "00000000-0000-0000-0000-000000000000"
              },
              "uuidOpt" : null,
              "uuidOptList" : [
                null
              ],
              "uuidOptMap" : {
                "foo" : null
              },
              "uuidOptSet" : [
                null
              ],
              "uuidSet" : [
                "00000000-0000-0000-0000-000000000000"
              ]
            }
            """
        }
        let decoder = JSONDecoder()
        let obj = try decoder.decode(ModernCodableObject.self, from: Data(str.utf8))

        XCTAssertNil(obj.boolOpt)
        XCTAssertNil(obj.intOpt)
        XCTAssertNil(obj.int8Opt)
        XCTAssertNil(obj.int16Opt)
        XCTAssertNil(obj.int32Opt)
        XCTAssertNil(obj.int64Opt)
        XCTAssertNil(obj.floatOpt)
        XCTAssertNil(obj.doubleOpt)
        XCTAssertNil(obj.stringOpt)
        XCTAssertNil(obj.dateOpt)
        XCTAssertNil(obj.dataOpt)
        XCTAssertNil(obj.decimalOpt)
        XCTAssertNil(obj.objectIdOpt)

        XCTAssertNil(obj.boolOptList.first!)
        XCTAssertNil(obj.intOptList.first!)
        XCTAssertNil(obj.int8OptList.first!)
        XCTAssertNil(obj.int16OptList.first!)
        XCTAssertNil(obj.int32OptList.first!)
        XCTAssertNil(obj.int64OptList.first!)
        XCTAssertNil(obj.floatOptList.first!)
        XCTAssertNil(obj.doubleOptList.first!)
        XCTAssertNil(obj.stringOptList.first!)
        XCTAssertNil(obj.dateOptList.first!)
        XCTAssertNil(obj.dataOptList.first!)
        XCTAssertNil(obj.decimalOptList.first!)
        XCTAssertNil(obj.objectIdOptList.first!)

        XCTAssertNil(obj.boolOptSet.first!)
        XCTAssertNil(obj.intOptSet.first!)
        XCTAssertNil(obj.int8OptSet.first!)
        XCTAssertNil(obj.int16OptSet.first!)
        XCTAssertNil(obj.int32OptSet.first!)
        XCTAssertNil(obj.int64OptSet.first!)
        XCTAssertNil(obj.floatOptSet.first!)
        XCTAssertNil(obj.doubleOptSet.first!)
        XCTAssertNil(obj.stringOptSet.first!)
        XCTAssertNil(obj.dateOptSet.first!)
        XCTAssertNil(obj.dataOptSet.first!)
        XCTAssertNil(obj.decimalOptSet.first!)
        XCTAssertNil(obj.objectIdOptSet.first!)

        XCTAssertNil(obj.boolOptMap["foo"]!)
        XCTAssertNil(obj.intOptMap["foo"]!)
        XCTAssertNil(obj.int8OptMap["foo"]!)
        XCTAssertNil(obj.int16OptMap["foo"]!)
        XCTAssertNil(obj.int32OptMap["foo"]!)
        XCTAssertNil(obj.int64OptMap["foo"]!)
        XCTAssertNil(obj.floatOptMap["foo"]!)
        XCTAssertNil(obj.doubleOptMap["foo"]!)
        XCTAssertNil(obj.stringOptMap["foo"]!)
        XCTAssertNil(obj.dateOptMap["foo"]!)
        XCTAssertNil(obj.dataOptMap["foo"]!)
        XCTAssertNil(obj.decimalOptMap["foo"]!)
        XCTAssertNil(obj.objectIdOptMap["foo"]!)

        XCTAssertNil(obj.objectOptMap["foo"]!)
        XCTAssertNil(obj.embeddedObjectOptMap["foo"]!)

        // Verify that it encodes to exactly the original string (which requires
        // that the original string be formatted how JSONEncoder formats things)
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let actual = try String(data: encoder.encode(obj), encoding: .utf8)
        XCTAssertEqual(str, actual)
    }

    func testModernObjectOptionalNotRequired() throws {
        let str = """
        {
            "bool": true,
            "string": "abc",
            "int": 123,
            "int8": 123,
            "int16": 123,
            "int32": 123,
            "int64": 123,
            "float": 2.5,
            "double": 2.5,
            "date": 2.5,
            "data": "\(Data("def".utf8).base64EncodedString())",
            "decimal": "1.5e2",
            "objectId": "1234567890abcdef12345678",
            "uuid": "00000000-0000-0000-0000-000000000000",

            "otherBool": true,
            "otherInt": 123,
            "otherInt8": 123,
            "otherInt16": 123,
            "otherInt32": 123,
            "otherInt64": 123,
            "otherFloat": 2.5,
            "otherDouble": 2.5,
            "otherEnum": 1,

            "boolList": [true],
            "stringList": ["abc"],
            "intList": [123],
            "int8List": [123],
            "int16List": [123],
            "int32List": [123],
            "int64List": [123],
            "floatList": [2.5],
            "doubleList": [2.5],
            "dateList": [2.5],
            "dataList": ["\(Data("def".utf8).base64EncodedString())"],
            "decimalList": ["1.5e2"],
            "objectIdList": ["1234567890abcdef12345678"],
            "uuidList": ["00000000-0000-0000-0000-000000000000"],
            "objectList": [],
            "embeddedObjectList": [],

            "boolOptList": [null],
            "stringOptList": [null],
            "intOptList": [null],
            "int8OptList": [null],
            "int16OptList": [null],
            "int32OptList": [null],
            "int64OptList": [null],
            "floatOptList": [null],
            "doubleOptList": [null],
            "dateOptList": [null],
            "dataOptList": [null],
            "decimalOptList": [null],
            "objectIdOptList": [null],
            "uuidOptList": [null],

            "boolSet": [true],
            "stringSet": ["abc"],
            "intSet": [123],
            "int8Set": [123],
            "int16Set": [123],
            "int32Set": [123],
            "int64Set": [123],
            "floatSet": [2.5],
            "doubleSet": [2.5],
            "dateSet": [2.5],
            "dataSet": ["\(Data("def".utf8).base64EncodedString())"],
            "decimalSet": ["1.5e2"],
            "objectIdSet": ["1234567890abcdef12345678"],
            "uuidSet": ["00000000-0000-0000-0000-000000000000"],
            "objectSet": [],

            "boolOptSet": [null],
            "stringOptSet": [null],
            "intOptSet": [null],
            "int8OptSet": [null],
            "int16OptSet": [null],
            "int32OptSet": [null],
            "int64OptSet": [null],
            "floatOptSet": [null],
            "doubleOptSet": [null],
            "dateOptSet": [null],
            "dataOptSet": [null],
            "decimalOptSet": [null],
            "objectIdOptSet": [null],
            "uuidOptSet": [null],

            "boolMap": {"foo": true},
            "stringMap": {"foo": "abc"},
            "intMap": {"foo": 123},
            "int8Map": {"foo": 123},
            "int16Map": {"foo": 123},
            "int32Map": {"foo": 123},
            "int64Map": {"foo": 123},
            "floatMap": {"foo": 2.5},
            "doubleMap": {"foo": 2.5},
            "dateMap": {"foo": 2.5},
            "dataMap": {"foo": "\(Data("def".utf8).base64EncodedString())"},
            "decimalMap": {"foo": "1.5e2"},
            "objectIdMap": {"foo": "1234567890abcdef12345678"},
            "uuidMap": {"foo": "00000000-0000-0000-0000-000000000000"},

            "boolOptMap": {"foo": null},
            "stringOptMap": {"foo": null},
            "intOptMap": {"foo": null},
            "int8OptMap": {"foo": null},
            "int16OptMap": {"foo": null},
            "int32OptMap": {"foo": null},
            "int64OptMap": {"foo": null},
            "floatOptMap": {"foo": null},
            "doubleOptMap": {"foo": null},
            "dateOptMap": {"foo": null},
            "dataOptMap": {"foo": null},
            "decimalOptMap": {"foo": null},
            "objectIdOptMap": {"foo": null},
            "uuidOptMap": {"foo": null},
            "objectOptMap": {"foo": null},
            "embeddedObjectOptMap": {"foo": null}
        }
        """
        let decoder = JSONDecoder()
        let obj = try decoder.decode(ModernCodableObject.self, from: Data(str.utf8))

        XCTAssertNil(obj.boolOpt)
        XCTAssertNil(obj.intOpt)
        XCTAssertNil(obj.int8Opt)
        XCTAssertNil(obj.int16Opt)
        XCTAssertNil(obj.int32Opt)
        XCTAssertNil(obj.int64Opt)
        XCTAssertNil(obj.floatOpt)
        XCTAssertNil(obj.doubleOpt)
        XCTAssertNil(obj.stringOpt)
        XCTAssertNil(obj.dateOpt)
        XCTAssertNil(obj.dataOpt)
        XCTAssertNil(obj.decimalOpt)
        XCTAssertNil(obj.objectIdOpt)
    }

    func testCustomDateEncoding() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            try "custom: \(date.timeIntervalSince1970)".encode(to: encoder)
        }

        let obj = ModernCodableObject()
        obj.date = Date(timeIntervalSince1970: 1)
        obj.dateOpt = Date(timeIntervalSince1970: 2)
        obj.dateList.append(Date(timeIntervalSince1970: 3))
        obj.dateOptList.append(Date(timeIntervalSince1970: 4))
        obj.dateSet.insert(Date(timeIntervalSince1970: 5))
        obj.dateOptSet.insert(Date(timeIntervalSince1970: 6))
        obj.dateMap["a"] = Date(timeIntervalSince1970: 7)
        obj.dateOptMap["b"] = Date(timeIntervalSince1970: 8)

        let encoded = try encoder.encode(obj)
        let dict = try JSONSerialization.jsonObject(with: encoded, options: []) as! [String: Any]
        XCTAssertEqual(dict["date"] as! String, "custom: 1.0")
        XCTAssertEqual(dict["dateOpt"] as! String, "custom: 2.0")
        XCTAssertEqual(dict["dateList"] as! [String], ["custom: 3.0"])
        XCTAssertEqual(dict["dateOptList"] as! [String], ["custom: 4.0"])
        XCTAssertEqual(dict["dateSet"] as! [String], ["custom: 5.0"])
        XCTAssertEqual(dict["dateOptSet"] as! [String], ["custom: 6.0"])
        XCTAssertEqual(dict["dateMap"] as! [String: String], ["a": "custom: 7.0"])
        XCTAssertEqual(dict["dateOptMap"] as! [String: String], ["b": "custom: 8.0"])
    }

    func testCustomDataEncoding() throws {
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .custom { data, encoder in
            try "length: \(data.count)".encode(to: encoder)
        }

        let obj = ModernCodableObject()
        obj.data = Data(repeating: 0, count: 1)
        obj.dataOpt = Data(repeating: 0, count: 2)
        obj.dataList.append(Data(repeating: 0, count: 3))
        obj.dataOptList.append(Data(repeating: 0, count: 4))
        obj.dataSet.insert(Data(repeating: 0, count: 5))
        obj.dataOptSet.insert(Data(repeating: 0, count: 6))
        obj.dataMap["a"] = Data(repeating: 0, count: 7)
        obj.dataOptMap["b"] = Data(repeating: 0, count: 8)

        let encoded = try encoder.encode(obj)
        let dict = try JSONSerialization.jsonObject(with: encoded, options: []) as! [String: Any]
        XCTAssertEqual(dict["data"] as! String, "length: 1")
        XCTAssertEqual(dict["dataOpt"] as! String, "length: 2")
        XCTAssertEqual(dict["dataList"] as! [String], ["length: 3"])
        XCTAssertEqual(dict["dataOptList"] as! [String], ["length: 4"])
        XCTAssertEqual(dict["dataSet"] as! [String], ["length: 5"])
        XCTAssertEqual(dict["dataOptSet"] as! [String], ["length: 6"])
        XCTAssertEqual(dict["dataMap"] as! [String: String], ["a": "length: 7"])
        XCTAssertEqual(dict["dataOptMap"] as! [String: String], ["b": "length: 8"])
    }

    func testKeyEncodingStrategy() throws {
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.sortedKeys]
        let obj = ModernCodableObject()
        obj.objectId = ObjectId("1234567890abcdef12345678")
        obj.uuid = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        obj.date = Date(timeIntervalSince1970: 0)
        let actual = try XCTUnwrap(String(data: encoder.encode(obj), encoding: .utf8))
        // Before the 2024 OS versions, int8 was sorted before int16
        let expected = if #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, *) {
            #"{"bool":false,"bool_list":[],"bool_map":{},"bool_opt":null,"bool_opt_list":[],"bool_opt_map":{},"bool_opt_set":[],"bool_set":[],"data":"","data_list":[],"data_map":{},"data_opt":null,"data_opt_list":[],"data_opt_map":{},"data_opt_set":[],"data_set":[],"date":-978307200,"date_list":[],"date_map":{},"date_opt":null,"date_opt_list":[],"date_opt_map":{},"date_opt_set":[],"date_set":[],"decimal":"0","decimal_list":[],"decimal_map":{},"decimal_opt":null,"decimal_opt_list":[],"decimal_opt_map":{},"decimal_opt_set":[],"decimal_set":[],"double":0,"double_list":[],"double_map":{},"double_opt":null,"double_opt_list":[],"double_opt_map":{},"double_opt_set":[],"double_set":[],"embedded_object_list":[],"embedded_object_opt":null,"embedded_object_opt_map":{},"float":0,"float_list":[],"float_map":{},"float_opt":null,"float_opt_list":[],"float_opt_map":{},"float_opt_set":[],"float_set":[],"int":0,"int16":0,"int16_list":[],"int16_map":{},"int16_opt":null,"int16_opt_list":[],"int16_opt_map":{},"int16_opt_set":[],"int16_set":[],"int32":0,"int32_list":[],"int32_map":{},"int32_opt":null,"int32_opt_list":[],"int32_opt_map":{},"int32_opt_set":[],"int32_set":[],"int64":0,"int64_list":[],"int64_map":{},"int64_opt":null,"int64_opt_list":[],"int64_opt_map":{},"int64_opt_set":[],"int64_set":[],"int8":0,"int8_list":[],"int8_map":{},"int8_opt":null,"int8_opt_list":[],"int8_opt_map":{},"int8_opt_set":[],"int8_set":[],"int_list":[],"int_map":{},"int_opt":null,"int_opt_list":[],"int_opt_map":{},"int_opt_set":[],"int_set":[],"object_id":"1234567890abcdef12345678","object_id_list":[],"object_id_map":{},"object_id_opt":null,"object_id_opt_list":[],"object_id_opt_map":{},"object_id_opt_set":[],"object_id_set":[],"object_list":[],"object_opt":null,"object_opt_map":{},"object_set":[],"string":"","string_list":[],"string_map":{},"string_opt":null,"string_opt_list":[],"string_opt_map":{},"string_opt_set":[],"string_set":[],"uuid":"00000000-0000-0000-0000-000000000000","uuid_list":[],"uuid_map":{},"uuid_opt":null,"uuid_opt_list":[],"uuid_opt_map":{},"uuid_opt_set":[],"uuid_set":[]}"#
        } else {
            #"{"bool":false,"bool_list":[],"bool_map":{},"bool_opt":null,"bool_opt_list":[],"bool_opt_map":{},"bool_opt_set":[],"bool_set":[],"data":"","data_list":[],"data_map":{},"data_opt":null,"data_opt_list":[],"data_opt_map":{},"data_opt_set":[],"data_set":[],"date":-978307200,"date_list":[],"date_map":{},"date_opt":null,"date_opt_list":[],"date_opt_map":{},"date_opt_set":[],"date_set":[],"decimal":"0","decimal_list":[],"decimal_map":{},"decimal_opt":null,"decimal_opt_list":[],"decimal_opt_map":{},"decimal_opt_set":[],"decimal_set":[],"double":0,"double_list":[],"double_map":{},"double_opt":null,"double_opt_list":[],"double_opt_map":{},"double_opt_set":[],"double_set":[],"embedded_object_list":[],"embedded_object_opt":null,"embedded_object_opt_map":{},"float":0,"float_list":[],"float_map":{},"float_opt":null,"float_opt_list":[],"float_opt_map":{},"float_opt_set":[],"float_set":[],"int":0,"int_list":[],"int_map":{},"int_opt":null,"int_opt_list":[],"int_opt_map":{},"int_opt_set":[],"int_set":[],"int8":0,"int8_list":[],"int8_map":{},"int8_opt":null,"int8_opt_list":[],"int8_opt_map":{},"int8_opt_set":[],"int8_set":[],"int16":0,"int16_list":[],"int16_map":{},"int16_opt":null,"int16_opt_list":[],"int16_opt_map":{},"int16_opt_set":[],"int16_set":[],"int32":0,"int32_list":[],"int32_map":{},"int32_opt":null,"int32_opt_list":[],"int32_opt_map":{},"int32_opt_set":[],"int32_set":[],"int64":0,"int64_list":[],"int64_map":{},"int64_opt":null,"int64_opt_list":[],"int64_opt_map":{},"int64_opt_set":[],"int64_set":[],"object_id":"1234567890abcdef12345678","object_id_list":[],"object_id_map":{},"object_id_opt":null,"object_id_opt_list":[],"object_id_opt_map":{},"object_id_opt_set":[],"object_id_set":[],"object_list":[],"object_opt":null,"object_opt_map":{},"object_set":[],"string":"","string_list":[],"string_map":{},"string_opt":null,"string_opt_list":[],"string_opt_map":{},"string_opt_set":[],"string_set":[],"uuid":"00000000-0000-0000-0000-000000000000","uuid_list":[],"uuid_map":{},"uuid_opt":null,"uuid_opt_list":[],"uuid_opt_map":{},"uuid_opt_set":[],"uuid_set":[]}"#
        }
        XCTAssertEqual(expected, actual)
    }
}
