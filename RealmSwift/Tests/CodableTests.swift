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

#if swift(>=4.1)
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

    @objc dynamic var stringOpt: String?
    @objc dynamic var dataOpt: Data?
    @objc dynamic var dateOpt: Date?
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
}

class CodableTests: TestCase {
    func decode<T: RealmOptionalType & Codable>(_ type: T.Type, _ str: String) -> RealmOptional<T> {
        let decoder = JSONDecoder()
        return try! decoder.decode([RealmOptional<T>].self, from: str.data(using: .utf8)!).first!
    }

    func encode<T: RealmOptionalType & Codable>(_ value: T?) -> String {
        let encoder = JSONEncoder()
        let opt = RealmOptional<T>()
        opt.value = value
        return try! String(data: encoder.encode([opt]), encoding: .utf8)!
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

        let expected = "{\"int64Opt\":123,\"int\":123,\"intOptList\":[123],\"boolList\":[true],\"doubleList\":[2.5],\"dateList\":[2.5],\"int32OptList\":[123],\"dateOptList\":[2.5],\"int64OptList\":[123],\"doubleOptList\":[2.5],\"int64List\":[123],\"int8List\":[123],\"string\":\"abc\",\"dataOptList\":[\"ZGVm\"],\"intOpt\":123,\"double\":2.5,\"float\":2.5,\"int32Opt\":123,\"dateOpt\":2.5,\"boolOpt\":true,\"int16Opt\":123,\"stringList\":[\"abc\"],\"dataList\":[\"ZGVm\"],\"boolOptList\":[true],\"date\":2.5,\"int16\":123,\"data\":\"ZGVm\",\"stringOpt\":\"abc\",\"int32\":123,\"int16List\":[123],\"stringOptList\":[\"abc\"],\"dataOpt\":\"ZGVm\",\"int8OptList\":[123],\"int32List\":[123],\"int8\":123,\"int16OptList\":[123],\"intList\":[123],\"int8Opt\":123,\"floatOptList\":[2.5],\"floatOpt\":2.5,\"doubleOpt\":2.5,\"bool\":true,\"floatList\":[2.5],\"int64\":123}"
        let encoder = JSONEncoder()
        XCTAssertEqual(try! String(data: encoder.encode(obj), encoding: .utf8), expected)
    }
}
#endif
