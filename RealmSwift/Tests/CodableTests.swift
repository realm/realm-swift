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

        let expected = "{\"int64Opt\":123,\"int\":123,\"intOptList\":[123],\"boolList\":[true],\"doubleList\":[2.5],\"dateList\":[2.5],\"int32OptList\":[123],\"decimalList\":[\"1.5E2\"],\"dateOptList\":[2.5],\"int64OptList\":[123],\"doubleOptList\":[2.5],\"decimalOpt\":\"1.5E2\",\"int64List\":[123],\"objectIdList\":[\"1234567890abcdef12345678\"],\"int8List\":[123],\"string\":\"abc\",\"objectId\":\"1234567890abcdef12345678\",\"dataOptList\":[\"ZGVm\"],\"intOpt\":123,\"double\":2.5,\"float\":2.5,\"decimal\":\"1.5E2\",\"dateOpt\":2.5,\"boolOpt\":true,\"int32Opt\":123,\"int16Opt\":123,\"stringList\":[\"abc\"],\"dataList\":[\"ZGVm\"],\"boolOptList\":[true],\"date\":2.5,\"int16\":123,\"data\":\"ZGVm\",\"stringOpt\":\"abc\",\"int32\":123,\"int16List\":[123],\"stringOptList\":[\"abc\"],\"objectIdOptList\":[\"1234567890abcdef12345678\"],\"dataOpt\":\"ZGVm\",\"int8OptList\":[123],\"int32List\":[123],\"decimalOptList\":[\"1.5E2\"],\"int8\":123,\"int16OptList\":[123],\"intList\":[123],\"int8Opt\":123,\"floatOptList\":[2.5],\"floatOpt\":2.5,\"doubleOpt\":2.5,\"objectIdOpt\":\"1234567890abcdef12345678\",\"bool\":true,\"floatList\":[2.5],\"int64\":123}"
        let encoder = JSONEncoder()
        XCTAssertEqual(try! String(data: encoder.encode(obj), encoding: .utf8), expected)
    }
}
