////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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
import Realm
import RealmSwift

class SwiftBSONTests: XCTestCase {
    private func testBSONRoundTrip<T>(_ value: T,
                                      funcName: String = #function,
                                      line: Int = #line,
                                      column: Int = #column) where T: BSON {
        let rlmBSON: RLMBSON? = ObjectiveCSupport.convert(object: AnyBSON(value))

        XCTAssertEqual(rlmBSON as? T, value)
        let bson: AnyBSON? = ObjectiveCSupport.convert(object: rlmBSON)
        XCTAssertEqual(bson?.value(), value)
    }

    func testNilRoundTrip() {
        var anyBSONNil: AnyBSON?
        var rlmBSONNil: RLMBSON?
        XCTAssertNil(ObjectiveCSupport.convert(object: anyBSONNil))
        XCTAssertNil(ObjectiveCSupport.convert(object: rlmBSONNil))

        anyBSONNil = .null
        rlmBSONNil = NSNull()
        XCTAssertNil(ObjectiveCSupport.convert(object: anyBSONNil))
        XCTAssertNil(ObjectiveCSupport.convert(object: rlmBSONNil))
    }

    func testIntRoundTrip() {
        testBSONRoundTrip(42)
        testBSONRoundTrip(Int32(42))
        testBSONRoundTrip(Int64(42))
    }

    func testBoolRoundTrip() {
        testBSONRoundTrip(true)
        testBSONRoundTrip(false)
    }

    func testDoubleRoundTrip() {
        testBSONRoundTrip(1.0001220703125)
        testBSONRoundTrip(-1.0001220703125)
    }

    func testStringRoundTrip() {
        testBSONRoundTrip("abc")
    }

    func testBinaryRoundTrip() {
        testBSONRoundTrip(Data([1, 2, 3]))
    }

    func testDatetimeRoundTrip() {
        testBSONRoundTrip(Date(timeIntervalSince1970: 42))
    }

    func testObjectIdRoundTxrip() {
        testBSONRoundTrip(ObjectId.generate())
    }

    func testDecimal128RoundTrip() {
        testBSONRoundTrip(Decimal128("1.234E-3"))
    }

    func testRegularExpressionRoundTrip() {
        testBSONRoundTrip(try! NSRegularExpression(pattern: "Trolol", options: .caseInsensitive))
    }

    func testMaxKeyRoundTrip() {
        testBSONRoundTrip(MaxKey())
    }

    func testMinKeyRoundTrip() {
        testBSONRoundTrip(MinKey())
    }

    func testDocumentRoundTrip() throws {
        let swiftDocument: Document =  [
            "string": "test string",
            "true": true,
            "false": false,
            "int": 25,
            "int32": .int32(5),
            "int64": .int64(10000000000),
            "double": 15.0,
            "decimal128": .decimal128(Decimal128("1.2E+10")),
            "minkey": .minKey,
            "maxkey": .maxKey,
            "date": .datetime(Date(timeIntervalSince1970: 500.004)),
            "nestedarray": [[.int32(1), .int32(2)], [.int32(3), .int32(4)]],
            "nesteddoc": ["a": .int32(1), "b": .int32(2), "c": false, "d": [.int32(3), .int32(4)]],
            "oid": .objectId(ObjectId("507f1f77bcf86cd799439011")),
            "regex": .regex(try NSRegularExpression(pattern: "^abc", options: [])),
            "array1": [.int32(1), .int32(2)],
            "array2": ["string1", "string2"],
            "null": nil
        ]

        let rlmBSON: RLMBSON? = ObjectiveCSupport.convert(object: .document(swiftDocument))
        guard let dictionary = rlmBSON as? NSDictionary else {
            XCTFail("RLMBSON was not of type NSDictionary")
            return
        }

        XCTAssertEqual(dictionary.count, swiftDocument.count)
        dictionary.forEach { (arg0) in
            guard let key = arg0.key as? String,
                let value = arg0.value as? RLMBSON else {
                    XCTFail("RLMBSON Document has illegal types")
                return
            }
            XCTAssertEqual(swiftDocument[key], ObjectiveCSupport.convert(object: value))
        }
        let bson: AnyBSON? = ObjectiveCSupport.convert(object: rlmBSON)
        XCTAssertEqual(bson?.value(), swiftDocument)
    }

    func testArrayRoundTrip() throws {
        // NSNumber does not guarantee that it will preserve the input type of
        // ints if the number fits in a smaller type, and in practice it does
        // convert everything which fits in Int32 to Int32 on platforms which
        // use tagged pointers to represent NSNumber. This means that round-tripping
        // to the correct enum case requires Ints to have values that don't fit
        // in Int32 on 64-bit platforms, and values which do on 32-bit platforms.
#if arch(i386) || arch(arm)
        let swiftArray: Array<AnyBSON?> = [
            "test string",
            true,
            false,
            25,
            .int32(5),
            .int64(5000000000),
            15.0,
            .decimal128(Decimal128("1.2E+10")),
            .minKey,
            .maxKey,
            .datetime(Date(timeIntervalSince1970: 500.004)),
            [[10, 20], [.int32(3), .int32(4)]],
            ["a": .int32(1), "b": .int32(2), "c": false, "d": [.int32(3), .int32(4)]],
            .objectId(ObjectId("507f1f77bcf86cd799439011")),
            .regex(try NSRegularExpression(pattern: "^abc", options: [])),
            [10, 20],
            ["string1", "string2"],
            nil
        ]
#else
        let swiftArray: Array<AnyBSON?> = [
            "test string",
            true,
            false,
            25,
            .int32(5),
            .int64(5000000000),
            15.0,
            .decimal128(Decimal128("1.2E+10")),
            .minKey,
            .maxKey,
            .datetime(Date(timeIntervalSince1970: 500.004)),
            [[10000000000, 20000000000], [.int32(3), .int32(4)]],
            ["a": .int32(1), "b": .int32(2), "c": false, "d": [.int32(3), .int32(4)]],
            .objectId(ObjectId("507f1f77bcf86cd799439011")),
            .regex(try NSRegularExpression(pattern: "^abc", options: [])),
            [10000000000, 20000000000],
            ["string1", "string2"],
            nil
        ]
#endif
        let rlmBSON: RLMBSON? = ObjectiveCSupport.convert(object: .array(swiftArray))
        guard let array = rlmBSON as? NSArray else {
            XCTFail("RLMBSON was not of type NSDictionary")
            return
        }

        XCTAssertEqual(array.count, swiftArray.count)
        for idx in 0..<array.count {
            guard let value = array[idx] as? RLMBSON else {
                    XCTFail("RLMBSON Document has illegal types")
                return
            }
            XCTAssertEqual(swiftArray[idx], ObjectiveCSupport.convert(object: value))
        }
        let bson: AnyBSON? = ObjectiveCSupport.convert(object: rlmBSON)
        XCTAssertEqual(bson?.value(), swiftArray)
    }
}
