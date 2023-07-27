import Foundation
import MongoDataAccessMacros
import MongoDataAccess
import XCTest
import SwiftSyntaxMacrosTestSupport

@BSONCodable struct Address {
    let city: String
    let state: String
}

@BSONCodable struct Person {
    let name: String
    let age: Int
    let address: Address
}

class MongoDataAccessMacrosTests : XCTestCase {
    // TODO: Fix spacing in macro expansion
    func testWithoutAnyCustomization() throws {
        assertMacroExpansion(
            """
            @BSONCodable struct Person {
                let name: String
                let age: Int
            }
            """,
            expandedSource:
                """
                struct Person {
                    let name: String
                    let age: Int
                    init(name: String, age: Int) {
                        self.name = name
                    self.age = age
                    }
                    init(from document: Document) throws {
                        guard let name = document["name"] else {
                        throw BSONError.missingKey("name")
                    }
                    guard let name: String = try name?.as() else {
                        throw BSONError.invalidType(key: "name")
                    }
                    self.name = name
                    guard let age = document["age"] else {
                        throw BSONError.missingKey("age")
                    }
                    guard let age: Int = try age?.as() else {
                        throw BSONError.invalidType(key: "age")
                    }
                    self.age = age
                    }
                    func encode(to document: inout Document) {
                        document["name"] = AnyBSON(name)
                    document["age"] = AnyBSON(age)
                    }
                    struct Filter : BSONFilter {
                        var documentRef = DocumentRef()
                        var name: BSONQuery<String>
                    var age: BSONQuery<Int>
                        init() {
                            name = BSONQuery<String>(identifier: "name", documentRef: documentRef)
                        age = BSONQuery<Int>(identifier: "age", documentRef: documentRef)
                        }
                        mutating func encode() -> Document {
                            return documentRef.document
                        }
                    }
                }
                extension Person: BSONCodable {
                }
                """, macros: ["BSONCodable" : BSONCodableMacro.self]
        )
    }
}

class MongoDataAccessTests : XCTestCase {
    func testCodableGeneratedInit() {
        let person = Person(name: "Jason", age: 32, address: Address(city: "Austin", state: "TX"))
        XCTAssertEqual(person.name, "Jason")
        XCTAssertEqual(person.age, 32)
        XCTAssertEqual(person.address.city, "Austin")
        XCTAssertEqual(person.address.state, "TX")
    }
    
    func testCodableGeneratedDecode() throws {
        let person = try Person(from: ["name" : "Jason", "age": 32, "address": ["city": "Austin", "state": "TX"]])
        XCTAssertEqual(person.name, "Jason")
        XCTAssertEqual(person.age, 32)
        XCTAssertEqual(person.address.city, "Austin")
        XCTAssertEqual(person.address.state, "TX")
    }
    
    func testCodableGeneratedEncode() throws {
        var document = Document()
        let person = Person(name: "Jason", age: 32, address: Address(city: "Austin", state: "TX"))
        person.encode(to: &document)
        XCTAssertEqual(document["name"], "Jason")
        XCTAssertEqual(document["age"], 32)
        XCTAssertEqual(document["address"]??.documentValue?["city"], "Austin")
        XCTAssertEqual(document["address"]??.documentValue?["state"], "TX")
    }
    
    func testMongoCollection() async throws {
        let app = App(id: "car-wsney")
        let user = try await app.login(credentials: .anonymous)
        let collection = user.mongoClient("mongodb-atlas")
            .database(named: "car", type: Person.self)
            .collection(named: "persons")
        
        let person = Person(name: "Jason", age: 32, address: Address(city: "Austin", state: "TX"))
        let id = try await collection.insertOne(person)
        XCTAssertNotNil(id.objectIdValue)
        guard let foundPerson = try await collection.findOne() else {
            return XCTFail("Could not find inserted Person")
        }
        XCTAssertEqual(foundPerson.name, "Jason")
        XCTAssertEqual(foundPerson.age, 32)
        XCTAssertEqual(foundPerson.address.city, "Austin")
        XCTAssertEqual(foundPerson.address.state, "TX")
        let deleteCount = try await collection.deleteOne()
        XCTAssertEqual(deleteCount, 1)
        let nilPerson = try await collection.findOne()
        XCTAssertNil(nilPerson)
    }
    
    func testMongoCollectionFilters() async throws {
        let app = App(id: "car-wsney")
        let user = try await app.login(credentials: .anonymous)
        let collection = user.mongoClient("mongodb-atlas")
            .database(named: "car", type: Person.self)
            .collection(named: "persons")
        
        let id1 = try await collection
            .insertOne(Person(name: "John",
                              age: 32,
                              address: Address(city: "Austin", state: "TX")))
        XCTAssertNotNil(id1.objectIdValue)
        let id2 = try await collection
            .insertOne(Person(name: "Jane",
                              age: 29,
                              address: Address(city: "Austin", state: "TX")))
        XCTAssertNotNil(id2.objectIdValue)
        var count = try await collection.count()
        XCTAssertEqual(count, 2)
        
        // MARK: $lt query
        guard let meghna = try await collection.findOne({ person in
            person.age < 30
        }) else {
            return XCTFail()
        }
        XCTAssertNotNil(meghna)
        XCTAssertEqual(meghna.name, "Jane")
        XCTAssertEqual(meghna.age, 29)
        
        // MARK: $gt query
        guard let jason = try await collection.findOne({ person in
            person.age > 30
        }) else {
            return XCTFail()
        }
        XCTAssertNotNil(jason)
        XCTAssertEqual(jason.name, "John")
        XCTAssertEqual(jason.age, 32)
        
        // MARK: nested query $eq
        count = try await collection.find(filter: { person in
            person.address.city == "Austin"
        }).count
        XCTAssertEqual(count, 2)
        count = try await collection.find(filter: { person in
            person.address.city == "NYC"
        }).count
        XCTAssertEqual(count, 0)
        
        count = try await collection.deleteOne {
            $0.age > 30
        }
        XCTAssertEqual(count, 1)
        
        count = try await collection.count()
        XCTAssertEqual(count, 1)
        
        count = try await collection.deleteOne {
            $0.age < 30
        }
        XCTAssertEqual(count, 1)
        _ = try await collection.deleteMany()
    }
}
