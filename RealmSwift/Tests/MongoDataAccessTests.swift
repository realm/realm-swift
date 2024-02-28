import Foundation
import XCTest
import Realm
import RealmSwift

//
//@BSONCodable struct AllTypesBSONObject {
//    @BSONCodable struct AllTypesA : Equatable {
//        @BSONCodable struct AllTypesB : Equatable {
//            let intB: Int
//            let stringB: String
//        }
//        let intA: Int
//        let stringA: String
//        let allTypesB: AllTypesB
//    }
//    let int: Int
//    let intArray: [Int]
//    let intOpt: Int?
//    
//    let string: String
//    let bool: Bool
//    let double: Double
////    let data: Data
//    let long: Int64
////    let decimal: Decimal128
////    let uuid: UUID
//    let object: AllTypesA
//    let objectArray: [AllTypesA]
//    let objectOpt: AllTypesA?
//    var anyValue: Any
//}
//
//@BSONCodable final class RealmPerson : Object {
//    @Persisted(primaryKey: true) var _id: ObjectId = .generate()
//    @Persisted var name: String
//    @Persisted var age: Int
//    @Persisted var address: RealmAddress?
//    @Persisted var dogs: List<RealmDog>
//}
//
//@BSONCodable final class RealmAddress : EmbeddedObject {
//    @Persisted var city: String
//    @Persisted var state: String
//}
//
//@BSONCodable final class RealmDog : Object {
//    @Persisted(primaryKey: true) var _id: ObjectId = .generate()
//    @Persisted var owner: RealmPerson?
//    @Persisted var name: String
//    @Persisted var age: Int
//}
//
//@BSONCodable struct RegexTest {
//    let a: Regex<Substring>
//}
//
//extension RegexTest : Equatable {
//    static func == (lhs: Self,
//                    rhs: Self) -> Bool {
////        lhs.a.regex._literalPattern
//        return "\(lhs.a)" == "\(rhs.a)"
//    }
//}
////
////extension Regex : BSON {
////    public static func == (lhs: Regex, rhs: Regex) -> Bool {
////        "\(lhs)" == "\(rhs)"
////    }
////}
////
//
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
                       accuracy: 0.001)
        
        for (d1, d2) in zip(allTypes1.arrayDate.map(\.timeIntervalSince1970),
                            allTypes2.arrayDate.map(\.timeIntervalSince1970)) {
            XCTAssertEqual(d1, d2, accuracy: 0.001)
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
    //
    //    @BSONCodable struct MultiTypeTest : Equatable {
    //        let _id: ObjectId
    //        @BSONCodable(key: "String") let string: String
    //        @BSONCodable(key: "Int32") let int32: Int
    //        @BSONCodable(key: "Int64") let int64: Int64
    //        @BSONCodable(key: "Double") let double: Double
    //        @BSONCodable(key: "Binary") let binary: Data
    //
    //        @BSONCodable struct Subdocument : Equatable {
    //            let foo: String
    //        }
    //        @BSONCodable(key: "Subdocument") let subdocument: Subdocument
    //        @BSONCodable(key: "Array") let array: [Int]
    ////        @BSONCodable(key: "Timestamp") let timestamp: Date
    //        @BSONCodable(key: "DatetimeEpoch") let datetimeEpoch: Date
    //        @BSONCodable(key: "DatetimePositive") let datetimePositive: Date
    //        @BSONCodable(key: "DatetimeNegative") let datetimeNegative: Date
    //        @BSONCodable(key: "True") let `true`: Bool
    //        @BSONCodable(key: "False") let `false`: Bool
    ////        @BSONCodable(key: "MinKey") let minKey: MinKey
    ////        @BSONCodable(key: "MaxKey") let maxKey: MaxKey
    //        @BSONCodable(key: "Null") let null: Optional<String>
    //
    //        struct NonComformantType : Equatable {}
    //        @BSONCodable(ignore: true) let nonComformantType: NonComformantType = .init()
    //        @BSONCodable(ignore: true) let nonComformantTypeOptional: NonComformantType?
    //    }
    ////    {\"_id\": {\"$oid\": \"57e193d7a9cc81b4027498b5\"}, \"String\": \"string\", \"Int32\": {\"$numberInt\": \"42\"}, \"Int64\": {\"$numberLong\": \"42\"}, \"Double\": {\"$numberDouble\": \"-1.0\"}, \"Binary\": { \"$binary\" : {\"base64\": \"o0w498Or7cijeBSpkquNtg==\", \"subType\": \"03\"}}, \"BinaryUserDefined\": { \"$binary\" : {\"base64\": \"AQIDBAU=\", \"subType\": \"80\"}}, \"Code\": {\"$code\": \"function() {}\"}, \"CodeWithScope\": {\"$code\": \"function() {}\", \"$scope\": {}}, \"Subdocument\": {\"foo\": \"bar\"}, \"Array\": [{\"$numberInt\": \"1\"}, {\"$numberInt\": \"2\"}, {\"$numberInt\": \"3\"}, {\"$numberInt\": \"4\"}, {\"$numberInt\": \"5\"}], \"Timestamp\": {\"$timestamp\": {\"t\": 42, \"i\": 1}}, \"Regex\": {\"$regularExpression\": {\"pattern\": \"pattern\", \"options\": \"\"}}, \"DatetimeEpoch\": {\"$date\": {\"$numberLong\": \"0\"}}, \"DatetimePositive\": {\"$date\": {\"$numberLong\": \"2147483647\"}}, \"DatetimeNegative\": {\"$date\": {\"$numberLong\": \"-2147483648\"}}, \"True\": true, \"False\": false, \"DBRef\": {\"$ref\": \"collection\", \"$id\": {\"$oid\": \"57fd71e96e32ab4225b723fb\"}, \"$db\": \"database\"}, \"Minkey\": {\"$minKey\": 1}, \"Maxkey\": {\"$maxKey\": 1}, \"Null\": null}"
    //    func testMultiType() throws {
    //        try run(test: "multi-type", answers: [
    //            MultiTypeTest(_id: .init("57e193d7a9cc81b4027498b5"),
    //                          string: "string",
    //                          int32: 42,
    //                          int64: 42,
    //                          double: -1.0,
    //                          binary: Data(base64Encoded: "o0w498Or7cijeBSpkquNtg==")!,
    //                          subdocument: MultiTypeTest.Subdocument(foo: "bar"),
    //                          array: [1, 2, 3, 4, 5],
    ////                          timestamp: Date(timeIntervalSince1970: 42),
    //                          datetimeEpoch: Date(timeIntervalSince1970: 0),
    //                          datetimePositive: Date(timeIntervalSince1970: 2147483647),
    //                          datetimeNegative: Date(timeIntervalSince1970: -2147483648),
    //                          true: true,
    //                          false: false,
    ////                          minKey: MinKey(),
    ////                          maxKey: MaxKey(),
    //                          null: nil,
    //                          nonComformantTypeOptional: nil)
    //        ])
    //    }
    ////    // TODO: Fix spacing in macro expansion
    ////    func testWithoutAnyCustomization() throws {
    ////        assertMacroExpansion(
    ////            """
    ////            @BSONCodable struct Person {
    ////                let name: String
    ////                let age: Int
    ////            }
    ////            """,
    ////            expandedSource:
    ////                """
    ////                struct Person {
    ////                    let name: String
    ////                    let age: Int
    ////                    init(name: String, age: Int) {
    ////                        self.name = name
    ////                    self.age = age
    ////                    }
    ////                    init(from document: Document) throws {
    ////                        guard let name = document["name"] else {
    ////                        throw BSONError.missingKey("name")
    ////                    }
    ////                    guard let name: String = try name?.as() else {
    ////                        throw BSONError.invalidType(key: "name")
    ////                    }
    ////                    self.name = name
    ////                    guard let age = document["age"] else {
    ////                        throw BSONError.missingKey("age")
    ////                    }
    ////                    guard let age: Int = try age?.as() else {
    ////                        throw BSONError.invalidType(key: "age")
    ////                    }
    ////                    self.age = age
    ////                    }
    ////                    func encode(to document: inout Document) {
    ////                        document["name"] = AnyBSON(name)
    ////                    document["age"] = AnyBSON(age)
    ////                    }
    ////                    struct Filter : BSONFilter {
    ////                        var documentRef = DocumentRef()
    ////                        var name: BSONQuery<String>
    ////                    var age: BSONQuery<Int>
    ////                        init() {
    ////                            name = BSONQuery<String>(identifier: "name", documentRef: documentRef)
    ////                        age = BSONQuery<Int>(identifier: "age", documentRef: documentRef)
    ////                        }
    ////                        mutating func encode() -> Document {
    ////                            return documentRef.document
    ////                        }
    ////                    }
    ////                }
    ////                extension Person: BSONCodable {
    ////                }
    ////                """, macros: ["BSONCodable" : BSONCodableMacro.self]
    ////        )
    ////    }
    ////}
    ////
    ////
    ////extension MongoCollection {
    ////    subscript<V>(keyPath: String) -> V {
    ////        Mirror(reflecting: self).descendant(keyPath) as! V
    ////    }
    ////}
    ////
    ////@freestanding(declaration, names: arbitrary)
    ////private macro mock<T: AnyObject>(object: T, _ block: () -> ()) =
    ////    #externalMacro(module: "MongoDataAccessMacros", type: "MockMacro2")
    ////
    ////@objc class MongoDataAccessTests : XCTestCase {
    ////    func testFind() async throws {
    ////        let app = App(id: "test")
    ////        #mock(object: app) {
    ////            func login(withCredential: RLMCredentials, completion: RLMUserCompletionBlock) {
    ////                completion(class_createInstance(RLMUser.self, 0) as? RLMUser, nil)
    ////            }
    ////        }
    ////        let user = try await app.login(credentials: .anonymous)
    ////        let collection = user.mongoClient("mongodb-atlas")
    ////            .database(named: "my_app")
    ////            .collection(named: "persons", type: Person.self)
    ////
    ////        let underlying: RLMMongoCollection = collection["mongoCollection"]
    ////        // find error
    ////        #mock(object: underlying) {
    ////            func findWhere(_ document: Dictionary<NSString, RLMBSON>,
    ////                           options: RLMFindOptions,
    ////                           completion: RLMMongoFindBlock) {
    ////                completion(nil, SyncError(_bridgedNSError: .init(domain: "MongoClient", code: 42)))
    ////           }
    ////        }
    ////        do {
    ////            _ = try await collection.find()
    ////            XCTFail()
    ////        } catch {
    ////        }
    ////        // find empty
    ////        #mock(object: underlying) {
    ////            func findWhere(_ document: Dictionary<NSString, RLMBSON>,
    ////                           options: RLMFindOptions,
    ////                           completion: RLMMongoFindBlock) {
    ////                completion([], nil)
    ////           }
    ////        }
    ////        var persons = try await collection.find()
    ////        XCTAssert(persons.isEmpty)
    ////        // find one
    ////        #mock(object: underlying) {
    ////            func findWhere(_ document: Dictionary<NSString, RLMBSON>,
    ////                           options: RLMFindOptions,
    ////                           completion: RLMMongoFindBlock) {
    ////                let document: Document = [
    ////                    "name": "Jason",
    ////                    "age": 32,
    ////                    "address": ["city": "Austin", "state": "TX"]
    ////                ]
    ////                completion([ObjectiveCSupport.convert(document)], nil)
    ////           }
    ////        }
    ////        persons = try await collection.find()
    ////        let person = Person(name: "Jason", age: 32, address: Address(city: "Austin", state: "TX"))
    ////        XCTAssertEqual(person.name, "Jason")
    ////        XCTAssertEqual(person.age, 32)
    ////        XCTAssertEqual(person.address.city, "Austin")
    ////        XCTAssertEqual(person.address.state, "TX")
    ////        XCTAssertEqual(persons.first, person)
    ////        // find many
    ////        #mock(object: underlying) {
    ////            func findWhere(_ document: Dictionary<String, RLMBSON>,
    ////                           options: RLMFindOptions,
    ////                           completion: RLMMongoFindBlock) {
    ////                XCTAssertEqual(ObjectiveCSupport.convert(document), [
    ////                    "$or": [ ["name": "Jason"], ["name" : "Lee"] ]
    ////                ])
    ////                let document: [Document] = [
    ////                    [
    ////                    "name": "Jason",
    ////                    "age": 32,
    ////                    "address": ["city": "Austin", "state": "TX"]
    ////                    ],
    ////                    [
    ////                        "name": "Lee",
    ////                        "age": 10,
    ////                        "address": ["city": "Dublin", "state": "DUBLIN"]
    ////                    ]
    ////                ]
    ////                completion(document.map(ObjectiveCSupport.convert), nil)
    ////           }
    ////        }
    ////        persons = try await collection.find {
    ////            $0.name == "Jason" || $0.name == "Lee"
    ////        }
    ////        let person2 = Person(name: "Lee", age: 10, address: Address(city: "Dublin", state: "DUBLIN"))
    ////        XCTAssertEqual(persons[0], person)
    ////        XCTAssertEqual(persons[1], person2)
    ////    }
    ////
    ////    func testCodableGeneratedDecode() throws {
    ////        let person = try Person(from: ["name" : "Jason", "age": 32, "address": ["city": "Austin", "state": "TX"]])
    ////        XCTAssertEqual(person.name, "Jason")
    ////        XCTAssertEqual(person.age, 32)
    ////        XCTAssertEqual(person.address.city, "Austin")
    ////        XCTAssertEqual(person.address.state, "TX")
    ////    }
    ////
    ////    func testCodableGeneratedEncode() throws {
    ////        var document = Document()
    ////        let person = Person(name: "Jason", age: 32, address: Address(city: "Austin", state: "TX"))
    ////
    ////        person.encode(to: &document)
    ////        XCTAssertEqual(document["name"], "Jason")
    ////        XCTAssertEqual(document["age"], 32)
    ////        XCTAssertEqual(document["address"]??.documentValue?["city"], "Austin")
    ////        XCTAssertEqual(document["address"]??.documentValue?["state"], "TX")
    ////
    ////        XCTAssertEqual(try DocumentEncoder().encode(person), document)
    ////    }
    ////
}
