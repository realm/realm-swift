import Foundation
import MongoDataAccessMacros
import MongoDataAccess
import XCTest
import SwiftSyntaxMacrosTestSupport
import Realm

@BSONCodable struct Person : Equatable {
    @BSONCodable struct Address : Equatable {
        let city: String
        let state: String
    }
    let name: String
    let age: Int
    let address: Address
}

@BSONCodable struct AllTypesBSONObject {
    let int: Int
    let string: String
    var bool: Bool
    var double: Double
//    let data: Data
//    let long: Int64
//    let decimal: Decimal128
//    let uuid: UUID
    let object: Person
    var anyValue: any RawDocumentRepresentable
}

@BSONCodable final class RealmPerson : Object {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var name: String
    @Persisted var age: Int
    @Persisted var address: RealmAddress?
    @Persisted var dogs: List<RealmDog>
}

@BSONCodable final class RealmAddress : EmbeddedObject {
    @Persisted var city: String
    @Persisted var state: String
}

@BSONCodable final class RealmDog : Object {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var owner: RealmPerson?
    @Persisted var name: String
    @Persisted var age: Int
}

//
//extension Regex : BSON {
//    public static func == (lhs: Regex, rhs: Regex) -> Bool {
//        "\(lhs)" == "\(rhs)"
//    }
//}
//
class MongoDataAccessMacrosTests : XCTestCase {
//    // TODO: Fix spacing in macro expansion
//    func testWithoutAnyCustomization() throws {
//        assertMacroExpansion(
//            """
//            @BSONCodable struct Person {
//                let name: String
//                let age: Int
//            }
//            """,
//            expandedSource:
//                """
//                struct Person {
//                    let name: String
//                    let age: Int
//                    init(name: String, age: Int) {
//                        self.name = name
//                    self.age = age
//                    }
//                    init(from document: Document) throws {
//                        guard let name = document["name"] else {
//                        throw BSONError.missingKey("name")
//                    }
//                    guard let name: String = try name?.as() else {
//                        throw BSONError.invalidType(key: "name")
//                    }
//                    self.name = name
//                    guard let age = document["age"] else {
//                        throw BSONError.missingKey("age")
//                    }
//                    guard let age: Int = try age?.as() else {
//                        throw BSONError.invalidType(key: "age")
//                    }
//                    self.age = age
//                    }
//                    func encode(to document: inout Document) {
//                        document["name"] = AnyBSON(name)
//                    document["age"] = AnyBSON(age)
//                    }
//                    struct Filter : BSONFilter {
//                        var documentRef = DocumentRef()
//                        var name: BSONQuery<String>
//                    var age: BSONQuery<Int>
//                        init() {
//                            name = BSONQuery<String>(identifier: "name", documentRef: documentRef)
//                        age = BSONQuery<Int>(identifier: "age", documentRef: documentRef)
//                        }
//                        mutating func encode() -> Document {
//                            return documentRef.document
//                        }
//                    }
//                }
//                extension Person: BSONCodable {
//                }
//                """, macros: ["BSONCodable" : BSONCodableMacro.self]
//        )
//    }
//}
//
//
//extension MongoCollection {
//    subscript<V>(keyPath: String) -> V {
//        Mirror(reflecting: self).descendant(keyPath) as! V
//    }
//}
//
//@freestanding(declaration, names: arbitrary)
//private macro mock<T: AnyObject>(object: T, _ block: () -> ()) =
//    #externalMacro(module: "MongoDataAccessMacros", type: "MockMacro2")
//
//@objc class MongoDataAccessTests : XCTestCase {
//    func testFind() async throws {
//        let app = App(id: "test")
//        #mock(object: app) {
//            func login(withCredential: RLMCredentials, completion: RLMUserCompletionBlock) {
//                completion(class_createInstance(RLMUser.self, 0) as? RLMUser, nil)
//            }
//        }
//        let user = try await app.login(credentials: .anonymous)
//        let collection = user.mongoClient("mongodb-atlas")
//            .database(named: "my_app")
//            .collection(named: "persons", type: Person.self)
//
//        let underlying: RLMMongoCollection = collection["mongoCollection"]
//        // find error
//        #mock(object: underlying) {
//            func findWhere(_ document: Dictionary<NSString, RLMBSON>,
//                           options: RLMFindOptions,
//                           completion: RLMMongoFindBlock) {
//                completion(nil, SyncError(_bridgedNSError: .init(domain: "MongoClient", code: 42)))
//           }
//        }
//        do {
//            _ = try await collection.find()
//            XCTFail()
//        } catch {
//        }
//        // find empty
//        #mock(object: underlying) {
//            func findWhere(_ document: Dictionary<NSString, RLMBSON>,
//                           options: RLMFindOptions,
//                           completion: RLMMongoFindBlock) {
//                completion([], nil)
//           }
//        }
//        var persons = try await collection.find()
//        XCTAssert(persons.isEmpty)
//        // find one
//        #mock(object: underlying) {
//            func findWhere(_ document: Dictionary<NSString, RLMBSON>,
//                           options: RLMFindOptions,
//                           completion: RLMMongoFindBlock) {
//                let document: Document = [
//                    "name": "Jason",
//                    "age": 32,
//                    "address": ["city": "Austin", "state": "TX"]
//                ]
//                completion([ObjectiveCSupport.convert(document)], nil)
//           }
//        }
//        persons = try await collection.find()
//        let person = Person(name: "Jason", age: 32, address: Address(city: "Austin", state: "TX"))
//        XCTAssertEqual(person.name, "Jason")
//        XCTAssertEqual(person.age, 32)
//        XCTAssertEqual(person.address.city, "Austin")
//        XCTAssertEqual(person.address.state, "TX")
//        XCTAssertEqual(persons.first, person)
//        // find many
//        #mock(object: underlying) {
//            func findWhere(_ document: Dictionary<String, RLMBSON>,
//                           options: RLMFindOptions,
//                           completion: RLMMongoFindBlock) {
//                XCTAssertEqual(ObjectiveCSupport.convert(document), [
//                    "$or": [ ["name": "Jason"], ["name" : "Lee"] ]
//                ])
//                let document: [Document] = [
//                    [
//                    "name": "Jason",
//                    "age": 32,
//                    "address": ["city": "Austin", "state": "TX"]
//                    ],
//                    [
//                        "name": "Lee",
//                        "age": 10,
//                        "address": ["city": "Dublin", "state": "DUBLIN"]
//                    ]
//                ]
//                completion(document.map(ObjectiveCSupport.convert), nil)
//           }
//        }
//        persons = try await collection.find {
//            $0.name == "Jason" || $0.name == "Lee"
//        }
//        let person2 = Person(name: "Lee", age: 10, address: Address(city: "Dublin", state: "DUBLIN"))
//        XCTAssertEqual(persons[0], person)
//        XCTAssertEqual(persons[1], person2)
//    }
//    
//    func testCodableGeneratedDecode() throws {
//        let person = try Person(from: ["name" : "Jason", "age": 32, "address": ["city": "Austin", "state": "TX"]])
//        XCTAssertEqual(person.name, "Jason")
//        XCTAssertEqual(person.age, 32)
//        XCTAssertEqual(person.address.city, "Austin")
//        XCTAssertEqual(person.address.state, "TX")
//    }
//    
//    func testCodableGeneratedEncode() throws {
//        var document = Document()
//        let person = Person(name: "Jason", age: 32, address: Address(city: "Austin", state: "TX"))
//        
//        person.encode(to: &document)
//        XCTAssertEqual(document["name"], "Jason")
//        XCTAssertEqual(document["age"], 32)
//        XCTAssertEqual(document["address"]??.documentValue?["city"], "Austin")
//        XCTAssertEqual(document["address"]??.documentValue?["state"], "TX")
//        
//        XCTAssertEqual(try DocumentEncoder().encode(person), document)
//    }
//    
//    func testMongoCollection() async throws {
//        let app = App(id: "car-wsney")
//        let user = try await app.login(credentials: .anonymous)
//        let collection = user.mongoClient("mongodb-atlas")
//            .database(named: "car")
//            .collection(named: "persons", type: Person.self)
//        
//        let person = Person(name: "Jason", age: 32, address: Address(city: "Austin", state: "TX"))
//        let id = try await collection.insertOne(person)
//        XCTAssertNotNil(id.objectIdValue)
//        guard let foundPerson = try await collection.findOne() else {
//            return XCTFail("Could not find inserted Person")
//        }
//        XCTAssertEqual(foundPerson.name, "Jason")
//        XCTAssertEqual(foundPerson.age, 32)
//        XCTAssertEqual(foundPerson.address.city, "Austin")
//        XCTAssertEqual(foundPerson.address.state, "TX")
//        let deleteCount = try await collection.deleteOne()
//        XCTAssertEqual(deleteCount, 1)
//        let nilPerson = try await collection.findOne()
//        XCTAssertNil(nilPerson)
//    }
////    
    func testMongoCollectionFilters() async throws {
        let app = App(id: "application-1-iyczo")
        let user = try await app.login(credentials: .anonymous)
        let realm = try await Realm(configuration: user.flexibleSyncConfiguration())
        let subscriptions = realm.subscriptions
        try await subscriptions.update {
            subscriptions.append(
                RealmPerson.self,
                RealmDog.self
            )
        }
        let dog = RealmDog(owner: nil, name: "Murphy", age: 2)
        let person = RealmPerson(name: "Jason",
                                 age: 32,
                                 address: RealmAddress(city: "Marlboro", state: "NJ"),
                                 dogs: [dog])
        dog.owner = person
        
        try realm.write {
            realm.add(person)
        }
        try await realm.syncSession?.waitForUpload()
        try await realm.syncSession?.waitForDownload()
        let collection = user.mongoClient("mongodb-atlas")
            .database(named: "static-queries")
            .collection(named: "RealmPerson", type: RealmPerson.self)
        
        guard let foundPerson = try await collection.findOne({
            $0._id == person._id
        }) else {
            return XCTFail()
        }
        
        XCTAssertEqual(person._id,
                       foundPerson._id)
        XCTAssertEqual(person.name,
                       foundPerson.name)
        XCTAssertEqual(person.age,
                       foundPerson.age)
        XCTAssertEqual(person.address?.city,
                       foundPerson.address?.city)
        XCTAssertEqual(person.address?.state,
                       foundPerson.address?.state)
//        XCTAssertEqual(person.dog?.name,
//                       foundPerson.dog?.name)
//        XCTAssertEqual(person.dog?.age,
//                       foundPerson.dog?.age)
        
//        try? realm.write {
//            realm.deleteAll()
//        }
//        try await realm.syncSession?.waitForUpload()
//        try await realm.syncSession?.waitForDownload()
//        let dogCollection = user.mongoClient("mongodb-atlas")
//            .database(named: "car")
//            .collection(named: "Dog", type: Dog.self)
//        let id1 = try await collection
//            .insertOne(Person(name: "John",
//                              age: 32,
//                              address: Address(city: "Austin", state: "TX")))
//        XCTAssertNotNil(id1.objectIdValue)
//        let id2 = try await collection
//            .insertOne(Person(name: "Jane",
//                              age: 29,
//                              address: Address(city: "Austin", state: "TX")))
//        XCTAssertNotNil(id2.objectIdValue)
//        var count = try await collection.count()
//        XCTAssertEqual(count, 2)
//        
//        // MARK: $lt query
//        guard let meghna = try await collection.findOne({ person in
//            person.age < 30
//        }) else {
//            return XCTFail()
//        }
//        XCTAssertNotNil(meghna)
//        XCTAssertEqual(meghna.name, "Jane")
//        XCTAssertEqual(meghna.age, 29)
//        
//        // MARK: $gt query
//        guard let jason = try await collection.findOne({ person in
//            person.age > 30
//        }) else {
//            return XCTFail()
//        }
//        XCTAssertNotNil(jason)
//        XCTAssertEqual(jason.name, "John")
//        XCTAssertEqual(jason.age, 32)
//        
//        // MARK: nested query $eq
//        count = try await collection.find(filter: { person in
//            person.address.city == "Austin"
//        }).count
//        XCTAssertEqual(count, 2)
//        count = try await collection.find(filter: { person in
//            person.address.city == "NYC"
//        }).count
//        XCTAssertEqual(count, 0)
//        
//        count = try await collection.deleteOne {
//            $0.age > 30
//        }
//        XCTAssertEqual(count, 1)
//        
//        count = try await collection.count()
//        XCTAssertEqual(count, 1)
//        
//        count = try await collection.deleteOne {
//            $0.age < 30
//        }
//        XCTAssertEqual(count, 1)
//        _ = try await collection.deleteMany()
    }
}
//
//// MARK: MongoDataAccessQueryTests
//class MongoDataAccessQueryTests : XCTestCase {
//    var collection: MongoCollection<Person>!
//    private var mockableCollection: RLMMongoCollection!
//    
//    override func setUp() async throws {
//        let app = App(id: "test")
//        #mock(object: app) {
//            func login(withCredential: RLMCredentials, completion: RLMUserCompletionBlock) {
//                completion(class_createInstance(RLMUser.self, 0) as? RLMUser, nil)
//            }
//        }
//        let user = try await app.login(credentials: .anonymous)
//        self.collection = user.mongoClient("mongodb-atlas")
//            .database(named: "my_app")
//            .collection(named: "persons", type: Person.self)
//
//        self.mockableCollection = collection["mongoCollection"]
//        // find error
//        #mock(object: mockableCollection) {
//            func findWhere(_ document: Dictionary<NSString, RLMBSON>,
//                           options: RLMFindOptions,
//                           completion: RLMMongoFindBlock) {
//                completion(nil, SyncError(_bridgedNSError: .init(domain: "MongoClient", code: 42)))
//           }
//        }
//    }
//    
//    func testAnd() async throws {
//        #mock(object: mockableCollection) {
//            func findWhere(_ document: Dictionary<NSString, RLMBSON>,
//                           options: RLMFindOptions,
//                           completion: RLMMongoFindBlock) {
//                completion(nil, SyncError(_bridgedNSError: .init(domain: "MongoClient", code: 42)))
//           }
//        }
//
//        _ = try await collection.find {
//            $0.age > 17 && $0.age < 30 && $0.name.contains(#/son/#)
//        }
//    }
//    
//    func testOr() async throws {
//        #mock(object: mockableCollection) {
//            func findWhere(_ document: Dictionary<String, RLMBSON>,
//                           options: RLMFindOptions,
//                           completion: RLMMongoFindBlock) {
//                let expectedDocument: Document = try! [
//                    "$or": [
//                        ["age": [
//                            "$gt": 17
//                        ]],
//                        ["age": [
//                            "$lt": 30
//                        ]],
//                        ["name": [
//                            "$regex": AnyBSON.regex(NSRegularExpression(pattern: "\(#/son/#)"))
//                        ]]
//                    ]
//                   ]
//                XCTAssertEqual(ObjectiveCSupport.convert(document),
//                                expectedDocument)
//                completion([], nil)
//           }
//        }
//
//        _ = try await collection.find {
//            $0.age > 17 || $0.age < 30 || $0.name.contains(#/son/#)
//        }
//    }
//}
//import RegexBuilder
class MongoDataAccessRawDocumentRepresentableTests : XCTestCase {
//    func testObjectId() throws {
//        let objectId = ObjectId.generate()
//        
//        let anyRaw = AnyRawDocumentRepresentable.objectId(objectId)
//        let data = try JSONEncoder().encode(anyRaw)
//        XCTAssertEqual(try JSONDecoder().decode(AnyRawDocumentRepresentable.self, from: data), anyRaw)
//        XCTAssertEqual(String(data: data, encoding: .utf8),
//                       """
//                       {"$oid":"\(objectId.stringValue)"}
//                       """)
//    }
//    
//    func testExpandRawDocument() {
//        let raw: RawDocument = [
//            "_id": ObjectId(),
//            "str": "Hello world",
//            "int32": Int32(42)
//        ]
//        XCTAssertEqual(
//            raw.description.trimmingCharacters(in: .whitespacesAndNewlines),
//            """
//            {"_id":{"$oid":"\(ObjectId())"},"str":"Hello world","int32":{"$numberInt":\(Int32(42))}}
//            """.trimmingCharacters(in: .whitespacesAndNewlines))
//    }
    
//    func testObjectSyntaxView() {
//        let objectId = ObjectId.generate()
//        let json = """
//        {"_id":{"$oid":"\(objectId)"}}
//        """
////        let syntaxView = FieldSyntaxView(for: json, at: json.startIndex)
////        XCTAssertEqual(syntaxView.key.string, "_id")
////        XCTAssertEqual((syntaxView.value as? ObjectSyntaxView)?.description,
////                       "{\"$oid\":\"\(objectId)\"}")
//        
//        let ast: RawObjectSyntaxView = [
//            "_id": [
//                "$oid": StringLiteralSyntaxView(stringLiteral: "\(objectId)")
//            ]
//        ]
//        XCTAssertEqual(ast.description, json)
//        var fields = ast.makeIterator()
//        var field = fields.next()!
//        XCTAssertNotNil(field)
//        XCTAssertEqual(field.key.string, "_id")
//        
//        guard let object = field.value as? RawObjectSyntaxView else { return XCTFail() }
//        fields = object.fieldList.fields
//        field = fields.next()!
//        XCTAssertEqual(field.key.string, "$oid")
//        XCTAssertEqual((field.value as? StringLiteralSyntaxView)?.string, "\(objectId)")
//        
//        guard let parsedObjectId = object.as(ObjectIdSyntaxView.self)?.objectId else {
//            return XCTFail()
//        }
//        XCTAssertEqual(objectId, parsedObjectId)
//    }
//    
//    func testFieldSyntaxView() {
//        let objectId = ObjectId.generate()
//        var json = """
//        "_id": {"$oid":"\(objectId)"}
//        """
//        let syntaxView = FieldSyntaxView(json: json, at: json.startIndex, allowedObjectTypes: [], fields: [:])
//        XCTAssertEqual(syntaxView.key.string, "_id")
//        XCTAssertEqual((syntaxView.value as? ObjectSyntaxView)?.description, 
//                       "{\"$oid\":\"\(objectId)\"}")
//        
//        json = """
//        {"_id":{"$oid":"\(objectId)"}}
//        """
//        
//        var ast: any SyntaxView = ObjectSyntaxView {
//            FieldSyntaxView(key: "_id", value: ObjectIdSyntaxView(objectId: objectId))
//        }
//        XCTAssertEqual(ast.description, json)
//        guard var fields = ast.as(ObjectSyntaxView.self)?.fieldList.fields,
//              let next = fields.next() else {
//            return XCTFail()
//        }
//        ast = next
//        XCTAssertEqual(ast.startIndex.utf16Offset(in: json),
//                       json.index(after: json.startIndex).utf16Offset(in: json))
//        XCTAssertEqual(ast.endIndex.utf16Offset(in: json),
//                       (json.lastIndex(of: "}") ?? json.endIndex).utf16Offset(in: json))
//        XCTAssertEqual("\"_id\":{\"$oid\":\"\(objectId)\"}", ast.description)
//    }
//    
//    func testNestedObjectSyntaxView() {
//        let objectId = ObjectId.generate()
//        let json = """
//        {
//            "_id": {"$oid": "\(objectId)"},
//            "name": "Jason",
//            "address": {
//                "city": "Austin",
//                "state": "TX",
//                "street": {
//                    "streetAddress": "101 Main Street",
//                    "zip": { "$numberInt": 11249 },
//                    "apartmentNo": "12A"
//                }
//            }
//        }
//        """
//        guard let parsedAST = ExtJSON(extJSON: json).parse() as? ObjectSyntaxView else {
//            return XCTFail()
//        }
//        let ast = ObjectSyntaxView {
//            FieldSyntaxView(key: "_id", value: ObjectIdSyntaxView(objectId: objectId))
//            FieldSyntaxView(key: "name", value: StringLiteralSyntaxView(stringLiteral: "Jason"))
//            FieldSyntaxView(key: "address", value: ObjectSyntaxView(fields: {
//                FieldSyntaxView(key: "city", value: StringLiteralSyntaxView(stringLiteral: "Austin"))
//                FieldSyntaxView(key: "state", value: StringLiteralSyntaxView(stringLiteral: "TX"))
//                FieldSyntaxView(key: "street", value: ObjectSyntaxView(fields: {
//                    FieldSyntaxView(key: "streetAddress", value: StringLiteralSyntaxView(stringLiteral: "101 Main Street"))
//                    FieldSyntaxView(key: "zip", value: IntSyntaxView(integerLiteral: 11249))
//                    FieldSyntaxView(key: "apartmentNo", value: StringLiteralSyntaxView(stringLiteral: "12A"))
//                }))
//            }))
//        }
//        var rawFields = ast.fieldList.fields
//        var parsedFields = parsedAST.fieldList.fields
//        guard let parsedNext = parsedFields.next(), let rawNext = rawFields.next() else { return XCTFail() }
//        XCTAssertEqual(parsedNext.key.string, "_id")
//        XCTAssertEqual(parsedNext.value.as(ObjectIdSyntaxView.self)?.objectId, objectId)
//        XCTAssertEqual(rawNext.key.string, "_id")
//        XCTAssertEqual(rawNext.value.as(ObjectIdSyntaxView.self)?.objectId, objectId)
//        guard let parsedNext = parsedFields.next(), let rawNext = rawFields.next() else { return XCTFail() }
//        XCTAssertEqual(parsedNext.key.string, "name")
//        XCTAssertEqual(parsedNext.value.as(StringLiteralSyntaxView.self)?.string, "Jason")
//        XCTAssertEqual(rawNext.key.string, "name")
//        XCTAssertEqual(rawNext.value.as(StringLiteralSyntaxView.self)?.string, "Jason")
//        guard let parsedNext = parsedFields.next(), let rawNext = rawFields.next() else { return XCTFail() }
//        XCTAssertEqual(parsedNext.key.string, "address")
//        XCTAssertEqual(rawNext.key.string, "address")
//        guard let parsedAddress = parsedNext.value.as(ObjectSyntaxView.self), let rawAddress = rawNext.value.as(ObjectSyntaxView.self) else {
//            return XCTFail()
//        }
//        parsedFields = parsedAddress.fieldList.fields
//        rawFields = rawAddress.fieldList.fields
//        guard let parsedNext = parsedFields.next(), let rawNext = rawFields.next() else { return XCTFail() }
//        XCTAssertEqual(parsedNext.key.string, "city")
//        XCTAssertEqual(parsedNext.value.as(StringLiteralSyntaxView.self)?.string, "Austin")
//        XCTAssertEqual(rawNext.key.string, "city")
//        XCTAssertEqual(rawNext.value.as(StringLiteralSyntaxView.self)?.string, "Austin")
//        guard let parsedNext = parsedFields.next(), let rawNext = rawFields.next() else { return XCTFail() }
//        XCTAssertEqual(parsedNext.key.string, "state")
//        XCTAssertEqual(parsedNext.value.as(StringLiteralSyntaxView.self)?.string, "TX")
//        XCTAssertEqual(rawNext.key.string, "state")
//        XCTAssertEqual(rawNext.value.as(StringLiteralSyntaxView.self)?.string, "TX")
//        guard let parsedNext = parsedFields.next(), let rawNext = rawFields.next() else { return XCTFail() }
//        XCTAssertEqual(parsedNext.key.string, "street")
//        XCTAssertEqual(rawNext.key.string, "street")
//        guard let parsedStreet = parsedNext.value.as(ObjectSyntaxView.self), let rawStreet = rawNext.value.as(ObjectSyntaxView.self) else {
//            return XCTFail()
//        }
//        parsedFields = parsedStreet.fieldList.fields
//        rawFields = rawStreet.fieldList.fields
//        guard let parsedNext = parsedFields.next(), let rawNext = rawFields.next() else { return XCTFail() }
//        XCTAssertEqual(parsedNext.key.string, "streetAddress")
//        XCTAssertEqual(parsedNext.value.as(StringLiteralSyntaxView.self)?.string, "101 Main Street")
//        XCTAssertEqual(rawNext.key.string, "streetAddress")
//        XCTAssertEqual(rawNext.value.as(StringLiteralSyntaxView.self)?.string, "101 Main Street")
//        guard let parsedNext = parsedFields.next(), let rawNext = rawFields.next() else { return XCTFail() }
//        XCTAssertEqual(parsedNext.key.string, "zip")
//        XCTAssertEqual(parsedNext.value.as(IntSyntaxView.self)?.integerLiteral, 11249)
//        XCTAssertEqual(rawNext.key.string, "zip")
//        XCTAssertEqual(rawNext.value.as(IntSyntaxView.self)?.integerLiteral, 11249)
//    }
//    
//    func testIntSyntaxView() {
//        let syntaxView = IntSyntaxView(integerLiteral: 42)
//        XCTAssertEqual(
//            syntaxView.description,
//            """
//            {"$numberInt":42}
//            """)
//        let fieldSyntaxView = FieldSyntaxView(key: "intKey", value: syntaxView)
//        XCTAssertEqual(
//            fieldSyntaxView.description,
//            """
//            "intKey":{"$numberInt":42}
//            """)
//        let objectSyntaxView = ObjectSyntaxView {
//            fieldSyntaxView
//        }
//        XCTAssertEqual(
//            objectSyntaxView.description,
//            """
//            {"intKey":{"$numberInt":42}}
//            """)
//    }
//    
//    func testObjectSyntaxViewIndices() {
//        var json = """
//        {"hello":"world"}
//        """
//        var view = ObjectSyntaxView(for: json, at: json.startIndex)
//        XCTAssertEqual(view.endIndex.utf16Offset(in: json), json.endIndex.utf16Offset(in: json))
//        let objectId = ObjectId.generate()
//        json = """
//        {"_id":{"$oid":"\(objectId)"}}
//        """
//        view = ObjectSyntaxView(for: json, at: json.startIndex)
//        XCTAssertEqual(view.endIndex.utf16Offset(in: json), json.endIndex.utf16Offset(in: json))
//        view = ObjectSyntaxView(for: json, at: json.index(json.startIndex, offsetBy: 7))
//        XCTAssertEqual(view.endIndex.utf16Offset(in: json),
//                       json.index(json.endIndex, offsetBy: -1).utf16Offset(in: json))
//        json = """
//        {
//            "_id": {
//                "$oid": "\(objectId)"
//            }
//        }
//        """
//        view = ObjectSyntaxView(for: json, at: json.startIndex)
//        XCTAssertEqual(view.endIndex.utf16Offset(in: json), json.endIndex.utf16Offset(in: json))
//        json = """
//        {
//            "_id": { "$oid": "\(objectId)" }
//        }
//        """
//        let secondObjectStart = json.indices.filter {
//            json[$0] == "{"
//        }[1]
//        view = ObjectSyntaxView(for: json, at: json.startIndex)
//        XCTAssertEqual(view.endIndex.utf16Offset(in: json), json.endIndex.utf16Offset(in: json))
//        view = ObjectSyntaxView(for: json, at: secondObjectStart)
//        XCTAssertEqual(view.endIndex.utf16Offset(in: json),
//                       json.index(json.endIndex, offsetBy: -2).utf16Offset(in: json))
//        let oid = view.as(ObjectIdSyntaxView.self)
//        XCTAssertEqual(oid?.objectId, objectId)
//    }
    
    func testPersonRoundTrip() throws {
        let person = Person(name: "Jason", age: 32, address: Person.Address(city: "Austin", state: "TX"))
        let ast = person.syntaxView
        XCTAssertEqual(ast.description,
                       """
                       {"name":"Jason","age":{"$numberLong":"32"},"address":{"city":"Austin","state":"TX"}}
                       """)
        let decodedPerson = ast.rawDocumentRepresentable
        XCTAssertEqual(person, decodedPerson as! Person)
    }
    
    func testAllTypesRoundTrip() throws {
        var allTypesObject = AllTypesBSONObject(int: 42,
                                                string: "hello", bool: true, double: 42.42,
                                                object: Person(name: "Jason",
                                                               age: 32,
                                                               address: Person.Address(city: "Austin",
                                                                                       state: "TX")),
                                                anyValue: 84)
        var ast = allTypesObject.syntaxView
        XCTAssertEqual(ast.description,
                       """
                       {"int":{"$numberInt":42},"string":"hello","bool":true,"double":{"$numberDouble":42.42},"object":{"name":"Jason","age":{"$numberInt":32},"address":{"city":"Austin","state":"TX"}},"anyValue":{"$numberInt":84}}
                       """)
        var decodedAllTypesObject = ast.rawDocumentRepresentable as! AllTypesBSONObject
        XCTAssertEqual(allTypesObject.int, decodedAllTypesObject.int)
        XCTAssertEqual(allTypesObject.string, decodedAllTypesObject.string)
        XCTAssertEqual(allTypesObject.bool, decodedAllTypesObject.bool)
        XCTAssertEqual(allTypesObject.object, decodedAllTypesObject.object)
        XCTAssertEqual(allTypesObject.anyValue as? Int, decodedAllTypesObject.anyValue as? Int)
        
        allTypesObject.anyValue = "world"
        allTypesObject.bool = false
        allTypesObject.double = .infinity
        ast = allTypesObject.syntaxView
        XCTAssertEqual(ast.description,
                       """
                       {"int":{"$numberInt":42},"string":"hello","bool":false,"double":{"$numberDouble":"Infinity"},"object":{"name":"Jason","age":{"$numberInt":32},"address":{"city":"Austin","state":"TX"}},"anyValue":"world"}
                       """)
        decodedAllTypesObject = ast.rawDocumentRepresentable as! AllTypesBSONObject
        XCTAssertEqual(allTypesObject.int, decodedAllTypesObject.int)
        XCTAssertEqual(allTypesObject.string, decodedAllTypesObject.string)
        XCTAssertEqual(allTypesObject.bool, decodedAllTypesObject.bool)
        XCTAssertEqual(allTypesObject.object, decodedAllTypesObject.object)
        XCTAssertEqual(allTypesObject.anyValue as? String, decodedAllTypesObject.anyValue as? String)
        
        allTypesObject.anyValue = Person(name: "Jason",
                                         age: 32,
                                         address: Person.Address(city: "Austin",
                                                                 state: "TX"))
        allTypesObject.double = -.infinity
        ast = AllTypesBSONObject.SyntaxView(from: allTypesObject)
        guard let fields = ((ast as? AllTypesBSONObject.SyntaxView)?.rawObjectSyntaxView) else {
            return XCTFail()
        }
//        XCTAssert(type(of: value) is AnyValueSyntaxView.Type)
        XCTAssertEqual(ast.description,
                       """
                       {"int":{"$numberLong":"42"},"string":"hello","bool":false,"double":{"$numberDouble":"-Infinity"},"object":{"name":"Jason","age":{"$numberLong":"32"},"address":{"city":"Austin","state":"TX"}},"anyValue":{"name":"Jason","age":{"$numberLong":"32"},"address":{"city":"Austin","state":"TX"}}}
                       """)
        decodedAllTypesObject = ast.rawDocumentRepresentable as! AllTypesBSONObject
        XCTAssertEqual(allTypesObject.int, decodedAllTypesObject.int)
        XCTAssertEqual(allTypesObject.string, decodedAllTypesObject.string)
        XCTAssertEqual(allTypesObject.bool, decodedAllTypesObject.bool)
        XCTAssertEqual(allTypesObject.object, decodedAllTypesObject.object)
        XCTAssertEqual(allTypesObject.anyValue as? Person, decodedAllTypesObject.anyValue as? Person)
        XCTAssertEqual((allTypesObject.anyValue as? Person)?.address, (decodedAllTypesObject.anyValue as? Person)?.address)
    }
}

// MARK: Realm Interop Tests
class MongoDataAccecssRealmInteropTests : XCTestCase {
//    func testPerson() {
//        let person = RealmPerson(name: "Jason", age: 32, address: RealmAddress(city: "Austin", state: "TX"), dog: nil)
//        let ast = person.syntaxView
//        XCTAssertEqual(ast.description,
//                       """
//                       {"name":"Jason","age":{"$numberInt":32},"address":{"city":"Austin","state":"TX"}}
//                       """)
//        let decodedPerson = ast.rawDocumentRepresentable
//        XCTAssertEqual(person, decodedPerson as! RealmPerson)
//    }
}

class MongoDataAccessSyntaxViewTests : XCTestCase {
    func testRawObjectSyntaxView() {
        let view: RawObjectSyntaxView = """
        {"_id": 42, "age": 30, "name": "Meghna"}
        """
        XCTAssertEqual(view.startIndex.utf16Offset(in: view.rawJSON), 0)
        XCTAssertEqual(view.endIndex.utf16Offset(in: view.rawJSON), view.rawJSON.endIndex.utf16Offset(in: view.rawJSON))
        XCTAssertNotNil(view["_id"])
        XCTAssertNotNil(view["age"])
        XCTAssertNotNil(view["name"])
    }
    
    func testRawObjectArraySyntaxView() {
        let view: RawArraySyntaxView = """
        [{"_id":{"$oid":"650a3e7015c136409dc53e70"},"address":{"city":"Marlboro","state":"NJ"},"age":{"$numberLong":"32"},"dog":{"_id":{"$oid":"650a3e7015c136409dc53e6e"},"age":{"$numberLong":"2"},"name":"Murphy"},"name":"Jason"}]
        """
        XCTAssertEqual(view.startIndex.utf16Offset(in: view.rawJSON), 0)
        XCTAssertEqual(view.endIndex.utf16Offset(in: view.rawJSON), 
                       view.rawJSON.endIndex.utf16Offset(in: view.rawJSON))
        guard let object = view[0] as? RawObjectSyntaxView else {
            return XCTFail()
        }
        XCTAssertEqual(object.startIndex.utf16Offset(in: object.rawJSON), 1)
        XCTAssertEqual(object.endIndex.utf16Offset(in: object.rawJSON), 221)
        
        guard object["_id"] is RawObjectSyntaxView else {
            return XCTFail()
        }
        var iter = object.makeIterator()
        XCTAssertEqual(iter.next()?.0, "_id")
        XCTAssertEqual(iter.next()?.0, "address")
        XCTAssertEqual(iter.next()?.0, "age")
        XCTAssertEqual(iter.next()?.0, "dog")
        XCTAssertEqual(iter.next()?.0, "name")
        XCTAssertNotNil(object["address"])
        XCTAssertNotNil(object["age"])
        XCTAssertEqual(object["dog"]?.startIndex.utf16Offset(in: view.rawJSON), 120)
        XCTAssertEqual(object["dog"]?.endIndex.utf16Offset(in: view.rawJSON), 205)
        XCTAssertNotNil(object["name"])
    }
    
    func testArgs() {
        let document: RawDocument = [
            "pipeline": [
                [
                    "$match": ["_id": ObjectId("650b22b9109c33ec9f13935f")]
                ],
                [
                    "$lookup": [
                        "from": "RealmDog",
                        "localField": "dog"
                    ]
                ]
            ]
        ]
        let syntaxView = document.syntaxView as! RawObjectSyntaxView
        let arraySyntaxView = syntaxView["pipeline"] as! RawArraySyntaxView
        var match = arraySyntaxView[0] as! RawObjectSyntaxView
        match = match["$match"] as! RawObjectSyntaxView
        match["_id"]
        XCTAssertEqual("""
        {"pipeline":[{"$match":{"_id":{"$oid":"650b22b9109c33ec9f13935f"}}},{"$lookup":{"from":"RealmDog","localField":"dog"}}]}
        """, syntaxView.description)
        let document2: RawDocument = [
            "pipeline": [
                "$match": ["_id": ObjectId("650b22b9109c33ec9f13935f")]
            ]
        ]
        XCTAssertEqual("""
        {"pipeline":{"$match":{"_id":{"$oid":"650b22b9109c33ec9f13935f"}}}}
        """, document2.syntaxView.description)
//        json    String    "\"pipeline\":[{\"$match\":{\"_id\":{\"$oid\":\"650b22b9109c33ec9f13935f\"}},{\"$lookup\":{\"from\":\"RealmDog\",\"localField\":\"dog\",\"foreignField\":\"_id\",\"as\":\"dog\"}},{\"$unwind\":{\"path\":\"$dog\",\"preserveNullAndEmptyArrays\":true}}]"
    }
}
