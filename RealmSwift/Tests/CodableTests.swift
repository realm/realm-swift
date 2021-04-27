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
}

class CodableTests: TestCase {
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()

    func decode<T: RealmOptionalType & Codable>(_ type: T.Type, _ str: String) -> RealmOptional<T> {
        return decode(RealmOptional<T>.self, str)
    }
    func decode<T: Codable>(_ type: T.Type, _ str: String) -> T {
        return try! decoder.decode([T].self, from: str.data(using: .utf8)!).first!
    }

    func encode<T: RealmOptionalType & Codable>(_ value: T?) -> String {
        let opt = RealmOptional<T>()
        opt.value = value
        return try! String(data: encoder.encode([opt]), encoding: .utf8)!
    }
    func encode<T: Codable>(_ value: T?) -> String {
        return try! String(data: encoder.encode([value]), encoding: .utf8)!
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
        XCTAssertEqual("[\"1.234567890E132\"]", encode("1234567890e123" as Decimal128))
    }

    func testObject() {
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

            "otherBool": true,
            "otherInt": 123,
            "otherInt8": 123,
            "otherInt16": 123,
            "otherInt32": 123,
            "otherInt64": 123,
            "otherFloat": 2.5,
            "otherDouble": 2.5,

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
        }
        """
        let decoder = JSONDecoder()
        let obj = try! decoder.decode(CodableObject.self, from: Data(str.utf8))

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

        let expected = "{\"double\":2.5,\"int16OptList\":[123],\"dateSet\":[2.5],\"intOpt\":123,\"dataOptSet\":[\"ZGVm\"],\"doubleOptSet\":[2.5],\"decimalList\":[\"1.5E2\"],\"boolOptSet\":[true],\"int64\":123,\"stringOpt\":\"abc\",\"int16List\":[123],\"boolSet\":[true],\"decimalOpt\":\"1.5E2\",\"uuidOpt\":\"00000000-0000-0000-0000-000000000000\",\"string\":\"abc\",\"int8Set\":[123],\"dataOptList\":[\"ZGVm\"],\"doubleSet\":[2.5],\"int32OptList\":[123],\"uuidOptSet\":[\"00000000-0000-0000-0000-000000000000\"],\"floatList\":[2.5],\"objectIdOptSet\":[\"1234567890abcdef12345678\"],\"otherInt8\":123,\"intOptSet\":[123],\"int\":123,\"dataSet\":[\"ZGVm\"],\"dataList\":[\"ZGVm\"],\"intList\":[123],\"int8List\":[123],\"objectIdOptList\":[\"1234567890abcdef12345678\"],\"dateOpt\":2.5,\"dateList\":[2.5],\"int8\":123,\"stringOptList\":[\"abc\"],\"otherBool\":true,\"otherInt32\":123,\"int64OptSet\":[123],\"uuid\":\"00000000-0000-0000-0000-000000000000\",\"intOptList\":[123],\"stringOptSet\":[\"abc\"],\"decimalOptList\":[\"1.5E2\"],\"boolOpt\":true,\"int16\":123,\"int8OptSet\":[123],\"otherInt16\":123,\"int8Opt\":123,\"decimalOptSet\":[\"1.5E2\"],\"otherInt\":123,\"floatSet\":[2.5],\"floatOpt\":2.5,\"int32\":123,\"dataOpt\":\"ZGVm\",\"data\":\"ZGVm\",\"boolOptList\":[true],\"otherDouble\":2.5,\"intSet\":[123],\"int32Set\":[123],\"int32Opt\":123,\"doubleOpt\":2.5,\"decimal\":\"1.5E2\",\"otherInt64\":123,\"stringSet\":[\"abc\"],\"objectIdSet\":[\"1234567890abcdef12345678\"],\"int32OptSet\":[123],\"int64List\":[123],\"floatOptList\":[2.5],\"float\":2.5,\"boolList\":[true],\"dateOptList\":[2.5],\"objectIdOpt\":\"1234567890abcdef12345678\",\"int16OptSet\":[123],\"int64Set\":[123],\"int8OptList\":[123],\"objectId\":\"1234567890abcdef12345678\",\"int64Opt\":123,\"uuidList\":[\"00000000-0000-0000-0000-000000000000\"],\"bool\":true,\"objectIdList\":[\"1234567890abcdef12345678\"],\"int16Opt\":123,\"doubleList\":[2.5],\"doubleOptList\":[2.5],\"otherFloat\":2.5,\"int16Set\":[123],\"dateOptSet\":[2.5],\"decimalSet\":[\"1.5E2\"],\"int64OptList\":[123],\"stringList\":[\"abc\"],\"uuidSet\":[\"00000000-0000-0000-0000-000000000000\"],\"int32List\":[123],\"date\":2.5,\"floatOptSet\":[2.5],\"uuidOptList\":[\"00000000-0000-0000-0000-000000000000\"]}"
        let encoder = JSONEncoder()
        XCTAssertEqual(try! String(data: encoder.encode(obj), encoding: .utf8), expected)
    }
}
