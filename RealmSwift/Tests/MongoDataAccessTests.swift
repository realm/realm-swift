import Foundation
import XCTest
import Realm
import RealmSwift

class Subdocument : EmbeddedObject, Codable {
    @Persisted var strCol: String
    
    convenience init(strCol: String) {
        self.init()
        self.strCol = strCol
    }
}

@objc(_AllTypesExtJSONObject) private class AllTypesObject : Object, Codable {
    @Persisted var _id: ObjectId
    
    @Persisted var strCol: String
    @Persisted var intCol: Int
    @Persisted var binaryCol: Data
    
    @Persisted var arrayStrCol: List<String>
    @Persisted var arrayIntCol: List<Int>
    
    @Persisted var arrayOptStrCol: List<String?>
    @Persisted var arrayOptIntCol: List<Int?>
    
    @Persisted var optStrCol: String?
    @Persisted var optIntCol: Int?
    
    @Persisted var subdocument: Subdocument?
    
    convenience init(_id: ObjectId,
                     strCol: String,
                     intCol: Int,
                     binaryCol: Data,
                     arrayStrCol: List<String>,
                     arrayIntCol: List<Int>,
                     arrayOptStrCol: List<String?>,
                     arrayOptIntCol: List<Int?>,
                     optStrCol: String? = nil,
                     optIntCol: Int? = nil,
                     subdocument: Subdocument) {
        self.init()
        self._id = _id
        self.strCol = strCol
        self.intCol = intCol
        self.binaryCol = binaryCol
        self.arrayStrCol = arrayStrCol
        self.arrayIntCol = arrayIntCol
        self.optStrCol = optStrCol
        self.optIntCol = optIntCol
        self.subdocument = subdocument
    }
}



class MongoDataAccessMacrosTests : XCTestCase {
    struct MultiTypeTest : Codable, Equatable {
        enum CodingKeys: String, CodingKey {
            case _id
            case string = "String"
            case `true` = "True"
            case `false` = "False"
            case int32 = "Int32"
            case int64 = "Int64"
            case double = "Double"
            case binary = "Binary"
            case subdocument = "Subdocument"
            case array = "Array"
            case datetimeEpoch = "DatetimeEpoch"
            case datetimePositive = "DatetimePositive"
            case datetimeNegative = "DatetimeNegative"
            case null = "Null"
        }
        let _id: ObjectId
        let string: String
        let int32: Int
        let int64: Int64
        let double: Double
        let binary: Data
        //
        struct Subdocument : Codable, Equatable {
            let foo: String
        }
        let subdocument: Subdocument
        let array: [Int]
        //        //        @BSONCodable(key: "Timestamp") let timestamp: Date
        let datetimeEpoch: Date
        let datetimePositive: Date
        let datetimeNegative: Date
        let `true`: Bool
        let `false`: Bool
        //        @BSONCodable(key: "MinKey") let minKey: MinKey
        //        @BSONCodable(key: "MaxKey") let maxKey: MaxKey
        let null: Optional<String>
    }
    
    func testA() throws {
        let m = MultiTypeTest(_id: .init("57e193d7a9cc81b4027498b5"),
                              string: "foo",
                              int32: 42, int64: 42, double: -1,
                              binary: Data(base64Encoded: "o0w498Or7cijeBSpkquNtg==")!,
                              subdocument: .init(foo: "bar"),
                              array: [1, 2, 3, 4, 5],
                              datetimeEpoch: Date(timeIntervalSince1970: 0),
                              datetimePositive: Date(timeIntervalSince1970: 2147483647),
                              datetimeNegative: Date(timeIntervalSince1970: -2147483648),
                              true: true,
                              false: false,
                              null: nil)
        let encoded = try ExtJSONEncoder().encode(m)
        let jsonObject = try JSONSerialization.jsonObject(with: try ExtJSONSerialization.data(with: m)) as! NSDictionary
        let obj = try JSONSerialization.jsonObject(with: encoded) as! NSDictionary
        XCTAssertEqual(jsonObject, obj)
        XCTAssertEqual(obj["_id"] as? [String: String], [
            "$oid": "57e193d7a9cc81b4027498b5"
        ])
        XCTAssertEqual(obj["Subdocument"] as? [String: String], [
            "foo": "bar"
        ])
        XCTAssertEqual(obj["String"] as? String, "foo")
        XCTAssertEqual(obj["Int32"] as? [String: String], [
            "$numberInt": "42"
        ])
        XCTAssertEqual(obj["Int64"] as? [String: String], [
            "$numberLong": "42"
        ])
        XCTAssertEqual(obj["Double"] as? [String: String], [
            "$numberDouble": "-1.0"
        ])
        XCTAssertEqual(obj["True"] as? Bool, true)
        XCTAssertEqual(obj["False"] as? Bool, false)
        XCTAssertEqual(obj["Null"] as? NSNull, nil)
        guard let array = obj["Array"] as? [[String: String]] else {
            return XCTFail("\(obj) did not contain correct `Array` key")
        }
        XCTAssertEqual(array[0]["$numberInt"], "1")
        XCTAssertEqual(array[1]["$numberInt"], "2")
        XCTAssertEqual(array[2]["$numberInt"], "3")
        XCTAssertEqual(array[3]["$numberInt"], "4")
        XCTAssertEqual(array[4]["$numberInt"], "5")
        
        let m2 = try ExtJSONDecoder().decode(MultiTypeTest.self, from: encoded)
        XCTAssertEqual(m, m2)
    }
    
    struct AllTypeTest : Codable, Equatable {
        let _id: ObjectId
        let string: String
        let int32: Int
        let int64: Int64
        let double: Double
        let binary: Data
        let date: Date
        
        let arrayString: [String]
        let arrayInt: [Int]
        let arrayInt64: [Int64]
        let arrayBool: [Bool]
        let arrayDouble: [Double]
        let arrayData: [Data]
        let arrayDate: [Date]
        
        let arrayOptString: [String?]
        let arrayOptInt: [Int?]
        let arrayOptInt64: [Int64?]
        let arrayOptBool: [Bool?]
        let arrayOptDouble: [Double?]
        let arrayOptData: [Data?]
        let arrayOptDate: [Date?]
        
        let optString: Optional<String>
        let optInt: Optional<Int>
        let optInt64: Optional<Int64>
        let optDouble: Optional<Double>
        let optBinary: Optional<Data>
        
        struct Subdocument : Codable, Equatable {
            let foo: String
        }
        let subdocument: Subdocument
        let arraySubdocument: [Subdocument]
    }
    
    func testAllTypesRoundTrip() throws {
        let encoder = ExtJSONEncoder()
        let allTypes1 = AllTypeTest(_id: .init("57e193d7a9cc81b4027498b5"),
                                    string: "foo",
                                    int32: 42,
                                    int64: 42,
                                    double: -1,
                                    binary: Data([0, 1, 2, 3, 4]),
                                    date: Date(),
                                    arrayString: ["a", "b", "c", "d", "e"],
                                    arrayInt: [1, 2, 3, 4, 5],
                                    arrayInt64: [6, 7, 8, 9, 10],
                                    arrayBool: [true, false, true, false, true],
                                    arrayDouble: [-1, 0, 1, -42.42, 42.42],
                                    arrayData: [
                                        Data([0, 1, 2, 3, 4]),
                                        Data([5, 6, 7, 8, 9])
                                    ], arrayDate: [Date()],
                                    arrayOptString: ["foo", nil],
                                    arrayOptInt: [42, nil],
                                    arrayOptInt64: [nil, 42],
                                    arrayOptBool: [nil, true],
                                    arrayOptDouble: [42.42, nil],
                                    arrayOptData: [Data([1, 2, 3]), nil],
                                    arrayOptDate: [nil, .distantPast],
                                    optString: nil,
                                    optInt: nil,
                                    optInt64: nil,
                                    optDouble: nil,
                                    optBinary: nil,
                                    subdocument: .init(foo: "bar"),
                                    arraySubdocument: [.init(foo: "baz"), .init(foo: "qux")])
        let data = try encoder.encode(allTypes1)
        let decoder = ExtJSONDecoder()
        let allTypes2 = try decoder.decode(AllTypeTest.self, from: data)
        
        XCTAssertEqual(allTypes1.date.timeIntervalSince1970,
                       allTypes2.date.timeIntervalSince1970,
                       accuracy: 0.1)
        
        for (d1, d2) in zip(allTypes1.arrayDate.map(\.timeIntervalSince1970),
                            allTypes2.arrayDate.map(\.timeIntervalSince1970)) {
            XCTAssertEqual(d1, d2, accuracy: 0.1)
        }
        XCTAssertEqual(allTypes1.arrayData, allTypes2.arrayData)
        XCTAssertEqual(allTypes1.binary, allTypes2.binary)
        XCTAssertEqual(allTypes1.arraySubdocument, allTypes2.arraySubdocument)
        XCTAssertEqual(allTypes1.arrayOptString, allTypes2.arrayOptString)
        XCTAssertEqual(allTypes1.arrayOptInt, allTypes2.arrayOptInt)
        XCTAssertEqual(allTypes1.subdocument, allTypes2.subdocument)
        XCTAssertEqual(allTypes1.optString, allTypes2.optString)
        XCTAssertEqual(allTypes1.optInt, allTypes2.optInt)
        XCTAssertEqual(allTypes1.optInt64, allTypes2.optInt64)
        XCTAssertEqual(allTypes1.optDouble, allTypes2.optDouble)
    }
    
    struct Test : Codable, Equatable {
        struct Valid : Codable, Equatable {
            let description: String
            let canonical_extjson: String
        }
        let description: String
        let test_key: String?
        let valid: Array<Valid>
    }
    
    func run<T>(test: Test,
                answer: T,
                parsedEntry: T,
                line: UInt) where T: Codable, T: Equatable {
        XCTAssertEqual(parsedEntry, answer, line: line)
        let encoder = ExtJSONEncoder()
        XCTAssertEqual(try encoder.encode(parsedEntry),
                       try encoder.encode(answer), line: line)
    }
    func run<T : Codable & Equatable>(test: String,
                                      answers: [T],
                                      lossy: Bool = false,
                                      function: String = #function,
                                      line: UInt = #line) throws {
        #if SWIFT_PACKAGE
        let url = Bundle.module.url(forResource: "BsonCorpus/\(test)", withExtension: "json")!
        #else
        let url = Bundle(for: Self.self).url(forResource: "BsonCorpus/\(test)", withExtension: "json")!
        #endif
        let data = try Data(contentsOf: url)
        let test: Test = try ExtJSONDecoder().decode(Test.self, from: data)
        for entryIdx in test.valid.indices where entryIdx < answers.count {
            let parsedEntry: T = try ExtJSONDecoder().decode(T.self, from: test.valid[entryIdx].canonical_extjson
                .data(using: .utf8)!)
            guard !lossy else {
                continue
            }
            run(test: test, answer: answers[entryIdx], parsedEntry: parsedEntry, line: line)
        }
    }
    
//    func run<T>(test: String, @AnswerBuilder answers: (() -> [(T, UInt)])) throws
//    where T: Codable, T: Equatable {
//#if SWIFT_PACKAGE
//        let url = Bundle.module.url(forResource: "BsonCorpus/\(test)", withExtension: "json")!
//#else
//        let url = Bundle(for: Self.self).url(forResource: "BsonCorpus/\(test)", withExtension: "json")!
//#endif
//        let data = try Data(contentsOf: url)
//        let test: Test = try ExtJSONDecoder().decode(Test.self, from: data)
//        let answers = answers()
//        for entryIdx in test.valid.indices where entryIdx < answers.count {
//            let parsedEntry: T = try ExtJSONDecoder().decode(T.self, from: test.valid[entryIdx].canonical_extjson
//                .data(using: .utf8)!)
//            run(test: test, answer: answers[entryIdx].0, parsedEntry: parsedEntry, line: answers[entryIdx].1)
//        }
//    }
//    // MARK: Corpus Tests
//    func testArray() throws {
//        struct ArrayTest : Codable, Equatable {
//            let a: [Int]
//        }
////        try run(test: "array") {
////            ArrayTest(a: [])
////            ArrayTest(a: [10])
////            ArrayTest(a: [10])
////            ArrayTest(a: [10])
////            ArrayTest(a: [10, 20])
////        }
//    }
//    
//    func testBinary() throws {
//        struct BinaryTest: Codable, Equatable {
//            let x: Data
//        }
//        try run(test: "binary") {
//            BinaryTest(x: Data())
//            BinaryTest(x: Data())
//            BinaryTest(x: Data(base64Encoded: "//8=")!)
//            BinaryTest(x: Data(base64Encoded: "//8=")!)
//            BinaryTest(x: Data(base64Encoded: "//8=")!)
//            BinaryTest(x: Data(base64Encoded: "//8=")!)
//            BinaryTest(x: Data(base64Encoded: "c//SZESzTGmQ6OfR38A11A==")!)
//            BinaryTest(x: Data(base64Encoded: "c//SZESzTGmQ6OfR38A11A==")!)
//            BinaryTest(x: Data(base64Encoded: "c//SZESzTGmQ6OfR38A11A==")!)
//            BinaryTest(x: Data(base64Encoded: "c//SZESzTGmQ6OfR38A11A==")!)
//            BinaryTest(x: Data(base64Encoded: "c//SZESzTGmQ6OfR38A11A==")!)
//            BinaryTest(x: Data(base64Encoded: "c//SZESzTGmQ6OfR38A11A==")!)
//            BinaryTest(x: Data(base64Encoded: "//8=")!)
//        }
////        try run(test: "binary", answers: [
////            BinaryTest(x: Data()),
////            BinaryTest(x: Data()),
////            BinaryTest(x: Data(base64Encoded: "//8=")!),
////            BinaryTest(x: Data(base64Encoded: "//8=")!),
////            BinaryTest(x: Data(base64Encoded: "//8=")!),
////            BinaryTest(x: Data(base64Encoded: "//8=")!),
////            BinaryTest(x: Data(base64Encoded: "c//SZESzTGmQ6OfR38A11A==")!),
////            BinaryTest(x: Data(base64Encoded: "c//SZESzTGmQ6OfR38A11A==")!),
////            BinaryTest(x: Data(base64Encoded: "c//SZESzTGmQ6OfR38A11A==")!),
////            BinaryTest(x: Data(base64Encoded: "c//SZESzTGmQ6OfR38A11A==")!),
////            BinaryTest(x: Data(base64Encoded: "c//SZESzTGmQ6OfR38A11A==")!),
////            BinaryTest(x: Data(base64Encoded: "c//SZESzTGmQ6OfR38A11A==")!),
////            BinaryTest(x: Data(base64Encoded: "//8=")!)
////        ])
//    }
    
    func testBoolean() throws {
        struct BoolTest : Codable, Equatable {
            let b: Bool
        }
        try run(test: "boolean", answers: [
            BoolTest(b: true),
            BoolTest(b: false)
        ])
    }
    
    func testDate() throws {
        struct DateTest : Codable, Equatable {
            let a: Date
        }
        try run(test: "datetime", answers: [
            DateTest(a: Date(timeIntervalSince1970: 0)),
            DateTest(a: Date(timeIntervalSince1970: 1356351330501/1000)),
            DateTest(a: Date(timeIntervalSince1970: -284643869501/1000)),
            DateTest(a: Date(timeIntervalSince1970: 253402300800000/1000)),
            DateTest(a: Date(timeIntervalSince1970: 1356351330001/1000))
        ])
    }
    
    struct DecimalTest : Codable, Equatable {
        let d: Decimal128
    }
    public func testDecimal() throws {
        try run(test: "decimal128-1", answers: [
            DecimalTest(d: .init(floatLiteral: .nan)),
            DecimalTest(d: .init(floatLiteral: .nan)),
            DecimalTest(d: .init(floatLiteral: .nan)),
            DecimalTest(d: .init(floatLiteral: .nan)),
            DecimalTest(d: .init(floatLiteral: .nan)),
            DecimalTest(d: .init(floatLiteral: .nan)),
            DecimalTest(d: .init(floatLiteral: .infinity)),
            DecimalTest(d: .init(floatLiteral: .infinity * -1)),
            DecimalTest(d: .init(floatLiteral: 0)),
            DecimalTest(d: .init(floatLiteral: -0)),
            DecimalTest(d: 0E+3),
            DecimalTest(d: 0.000001234567890123456789012345678901234)
        ], lossy: true)
    }
    
    struct ObjectIdTest : Codable, Equatable {
        let a: ObjectId
    }
    func testObjectId() throws {
        try run(test: "oid", answers: [
            ObjectIdTest(a: .init("000000000000000000000000")),
            ObjectIdTest(a: .init("ffffffffffffffffffffffff")),
            ObjectIdTest(a: .init("56e1fc72e0c917e9c4714161"))
        ])
    }
    
    struct NullTest : Codable, Equatable {
        let a: Int?
    }
    func testNull() throws {
        try run(test: "null", answers: [
            NullTest(a: nil)
        ])
    }
    
    // MARK: Filters
    private static func compareQuery(_ query: (Query<AllTypesObject>) -> Query<Bool>,
                                     _ rhs: NSDictionary) throws {
        XCTAssertEqual(
            try buildFilter(query(Query()).node, subqueryCount: 0) as NSDictionary,
            rhs)
    }
    
    func testFilters() throws {
        try Self.compareQuery({
            $0.intCol > 42
        }, [
            "intCol": [
                "$gt": 42
            ]
        ])
        try Self.compareQuery({
            $0.optStrCol == nil && $0.intCol > 42
        }, [
            "$and": [
                [
                    "optStrCol": ["$eq": nil]
                ],
                [
                    "intCol": [
                        "$gt": 42
                    ]
                ]
            ]
        ])
    }
    
    func testSubdocumentFilters() throws {
        try Self.compareQuery({
            $0.subdocument.strCol == "foo"
        }, [
            "subdocument.strCol": ["$eq": "foo"]
        ])
    }
    
    func testCollectionFilters() throws {
        try Self.compareQuery({
            $0.arrayIntCol.containsAny(in: [1, 2, 3])
        }, [
            "arrayIntCol": [ "$in": [1, 2, 3] ]
        ])
    }
    // MARK: Encodable/Decodable tests
    private func compare(value: any Codable & Equatable, stringRepresentation: String) throws {
        let encoder = ExtJSONEncoder()
        let decoder = ExtJSONDecoder()
        
        func compare<T>(value: T, stringRepresentation: String) throws where T: Codable, T: Equatable {
            // encode the value
            let data = try encoder.encode(value)
            // assert the string representation is correct for the value
            XCTAssertEqual(String(data: data, encoding: .utf8), stringRepresentation)
            XCTAssertEqual(try decoder.decode(type(of: value), from: data), value)
        }
        func optionalCompare<T>(value: T, stringRepresentation: String) throws where T: Codable, T: Equatable {
            // encode the value as nil (but as the correct type)
            let data = try encoder.encode(nil as T?)
            // assert the null encoded value is represented correctly
            XCTAssertEqual(String(data: data, encoding: .utf8), "null")
            XCTAssertEqual(try decoder.decode(T?.self, from: data), nil)
            do {
                // assert the correct error is thrown
                _ = try decoder.decode(T.self, from: data)
                XCTFail()
            } catch DecodingError.valueNotFound(_, _) {
            } catch DecodingError.typeMismatch(_, _) {
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
        func arrayCompare<T>(value: T, stringRepresentation: String) throws where T: Codable, T: Equatable {
            // encode the value
            var data = try encoder.encode([value, value])
            // assert the string representation is correct for the value
            XCTAssertEqual(String(data: data, encoding: .utf8),
                           "[\(stringRepresentation),\(stringRepresentation)]")
            XCTAssertEqual(try decoder.decode(type(of: [value, value]), from: data),
                           [value, value])
            
            data = try encoder.encode([value, nil, nil])
            // assert the string representation is correct for the value
            XCTAssertEqual(String(data: data, encoding: .utf8),
                           "[\(stringRepresentation),null,null]")
            XCTAssertEqual(try decoder.decode(type(of: [value, nil, nil]), from: data),
                           [value, nil, nil])
        }
        try compare(value: value, stringRepresentation: stringRepresentation)
        try optionalCompare(value: value, stringRepresentation: stringRepresentation)
        try arrayCompare(value: value, stringRepresentation: stringRepresentation)
    }

    private func invoke<T>(_ fn: (T, String) throws -> Void, _ args: (T, String)) throws {
        try fn(args.0, args.1)
    }
    
    let str = ("foo", "\"foo\"")
    let int = (42,
                """
                {"$numberInt":"42"}
                """)
    let int32 = (Int32(42), """
                            {"$numberInt":"42"}
                            """)
    let int64 = (Int64(42), """
                            {"$numberLong":"42"}
                            """)
    var document: (any Codable & Equatable, String) {
        struct Document: Codable, Equatable {
            let strCol: String
            let optStrCol: String?
            let intCol: Int
            struct Subdocument: Codable, Equatable {
                let strCol: String
            }
            let subdocument: Subdocument
        }
        return (Document(strCol: "foo", optStrCol: nil, intCol: 42, subdocument: Document.Subdocument(strCol: "bar")),
                """
                {"intCol":{"$numberInt":"42"},"strCol":"foo","subdocument":{"strCol":"bar"}}
                """)
    }
    
    func testCompare() throws {
        try invoke(compare, str)
        try invoke(compare, int)
        try invoke(compare, int32)
        try invoke(compare, int64)
        try invoke(compare, document)
    }
    
    func testBehavior() throws {
        let encoder = JSONEncoder()
        XCTAssertEqual(try encoder.encode(1), "1".data(using: .utf8))
        XCTAssertEqual(try encoder.encode("foo"), "\"foo\"".data(using: .utf8))
        
        struct Person: Codable {
            let name: String
            let age: Int
        }
    }
}
