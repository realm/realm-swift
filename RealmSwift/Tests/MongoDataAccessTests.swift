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
    
    @Persisted var optStrCol: String?
    @Persisted var optIntCol: Int?
    
    @Persisted var subdocument: Subdocument?
    
    convenience init(_id: ObjectId,
                     strCol: String,
                     intCol: Int,
                     binaryCol: Data,
                     arrayStrCol: List<String>,
                     arrayIntCol: List<Int>,
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
                                    ], arrayDate: [
                                        Date()
                                    ], optString: nil, optInt: nil, optInt64: nil, optDouble: nil, optBinary: nil, subdocument: .init(foo: "bar"), arraySubdocument: [.init(foo: "baz"), .init(foo: "qux")])
        let data = try encoder.encode(allTypes1)
        let decoder = ExtJSONDecoder()
        let allTypes2 = try decoder.decode(AllTypeTest.self, from: data)
        let mirror1 = Mirror(reflecting: allTypes1)
        let mirror2 = Mirror(reflecting: allTypes2)
        
        XCTAssertEqual(allTypes1.date.timeIntervalSince1970,
                       allTypes2.date.timeIntervalSince1970,
                       accuracy: 0.1)
        
        for (d1, d2) in zip(allTypes1.arrayDate.map(\.timeIntervalSince1970),
                            allTypes2.arrayDate.map(\.timeIntervalSince1970)) {
            XCTAssertEqual(d1, d2, accuracy: 0.1)
        }
        //        zip(allTypes1.arrayDate, allTypes2.arrayDate)
        //            .forEach(XCTAssertEqual)
        //        XCTAssertEqual(allTypes1.arrayDate.map(\.timeIntervalSince1970),
        //                       allTypes2.arrayDate.map(\.timeIntervalSince1970),
        //                       accuracy: 0.001)
        XCTAssertEqual(allTypes1.arrayData, allTypes2.arrayData)
        XCTAssertEqual(allTypes1.binary, allTypes2.binary)
        XCTAssertEqual(allTypes1.arraySubdocument, allTypes2.arraySubdocument)
        XCTAssertEqual(allTypes1.subdocument, allTypes2.subdocument)
        XCTAssertEqual(allTypes1.optString, allTypes2.optString)
        XCTAssertEqual(allTypes1.optInt, allTypes2.optInt)
        XCTAssertEqual(allTypes1.optInt64, allTypes2.optInt64)
        XCTAssertEqual(allTypes1.optDouble, allTypes2.optDouble)
        //        XCTAssertEqual(allTypes1, allTypes2)
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
    
    func run<T : Codable & Equatable>(test: String,
                                      answers: [T],
                                      lossy: Bool = false) throws {
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
            XCTAssertEqual(parsedEntry, answers[entryIdx])
            let encoder = ExtJSONEncoder()
            XCTAssertEqual(try encoder.encode(parsedEntry),
                           try encoder.encode(answers[entryIdx]))
        }
    }
    
    struct ArrayTest : Codable, Equatable {
        let a: [Int]
    }
    func testArray() throws {
        try run(test: "array", answers: [
            ArrayTest(a: []),
            ArrayTest(a: [10]),
            ArrayTest(a: [10]),
            ArrayTest(a: [10]),
            ArrayTest(a: [10, 20]),
        ])
    }
    
    struct BoolTest : Codable, Equatable {
        let b: Bool
    }
    func testBoolean() throws {
        try run(test: "boolean", answers: [
            BoolTest(b: true),
            BoolTest(b: false)
        ])
    }
    
    struct DateTest : Codable, Equatable {
        let a: Date
    }
    func testDate() throws {
        try run(test: "datetime", answers: [
            DateTest(a: .init(timeIntervalSince1970: 0)),
            DateTest(a: .init(timeIntervalSince1970: 1356351330501/1000)),
            DateTest(a: .init(timeIntervalSince1970: -284643869501/1000)),
            DateTest(a: .init(timeIntervalSince1970: 253402300800000/1000)),
            DateTest(a: .init(timeIntervalSince1970: 1356351330001/1000))
        ])
    }
    //
    //    @BSONCodable struct DecimalTest : Equatable {
    //        let d: Decimal128
    //    }
    //    public func testDecimal() throws {
    //        try run(test: "decimal128-1", answers: [
    //            DecimalTest(d: .init(floatLiteral: .nan)),
    //            DecimalTest(d: .init(floatLiteral: .nan)),
    //            DecimalTest(d: .init(floatLiteral: .nan)),
    //            DecimalTest(d: .init(floatLiteral: .nan)),
    //            DecimalTest(d: .init(floatLiteral: .nan)),
    //            DecimalTest(d: .init(floatLiteral: .nan)),
    //            DecimalTest(d: .init(floatLiteral: .infinity)),
    //            DecimalTest(d: .init(floatLiteral: .infinity * -1)),
    //            DecimalTest(d: .init(floatLiteral: 0)),
    //            DecimalTest(d: .init(floatLiteral: -0)),
    //            DecimalTest(d: 0E+3),
    //            DecimalTest(d: 0.000001234567890123456789012345678901234)
    //        ], lossy: true)
    //    }
    //
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
            try buildFilter(query(Query()).node, subqueryCount: 0),
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
}
