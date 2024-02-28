import Foundation
#if canImport(RealmTestSupport)
import RealmSwiftSyncTestSupport
import RealmSyncTestSupport
import RealmTestSupport
import RealmSwiftTestSupport
#endif

struct Person : Codable, Equatable {
    struct Address : Codable, Equatable {
        let city: String
        let state: String
    }
    let name: String
    let age: Int
    let address: Address
}

class MongoDataAccessCollectionTests : SwiftSyncTestCase {
    func testMongoCollection() async throws {
        let user = try await self.app.login(credentials: .anonymous)
//        let app = App(id: "car-wsney")
//        let user = try await app.login(credentials: .anonymous)
        let collection = user.mongoClient("mongodb-atlas")
            .database(named: "car")
            .collection(named: "persons", type: Person.self)
        try await collection.deleteMany()
        let person = Person(name: "Jason", age: 32, address: Person.Address(city: "Austin", state: "TX"))
//        let try await collection.findOne()
        let id = try await collection.insertOne(person)
//        XCTAssertNotNil(id.objectIdValue)
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
//////
//    @MainActor func testMongoCollectionFilters() async throws {
//        let app = App(id: "application-1-iyczo")
//        let user = try await app.login(credentials: .anonymous)
//        let realm = try await Realm(configuration: user.flexibleSyncConfiguration())
//        let subscriptions = realm.subscriptions
//        try await subscriptions.update {
//            subscriptions.append(
//                RealmPerson.self,
//                RealmDog.self
//            )
//        }
//        let dog = RealmDog(owner: nil, name: "Murphy", age: 2)
//        let person = RealmPerson(name: "Jason",
//                                 age: 32,
//                                 address: RealmAddress(city: "Marlboro", state: "NJ"),
//                                 dogs: [dog])
//        dog.owner = person
//
//        try realm.write {
//            realm.add(person)
//        }
//        try await realm.syncSession?.waitForUpload()
//        try await realm.syncSession?.waitForDownload()
//        let collection = user.mongoClient("mongodb-atlas")
//            .database(named: "static-queries")
//            .collection(named: "RealmPerson", type: RealmPerson.self)
//
//        guard let foundPerson = try await collection.findOne([
//            "_id": person._id
//        ]) else {
//            return XCTFail()
//        }
//
//        XCTAssertEqual(person._id,
//                       foundPerson._id)
//        XCTAssertEqual(person.name,
//                       foundPerson.name)
//        XCTAssertEqual(person.age,
//                       foundPerson.age)
//        XCTAssertEqual(person.address?.city,
//                       foundPerson.address?.city)
//        XCTAssertEqual(person.address?.state,
//                       foundPerson.address?.state)
////        XCTAssertEqual(person.dog?.name,
////                       foundPerson.dog?.name)
////        XCTAssertEqual(person.dog?.age,
////                       foundPerson.dog?.age)
//
////        try? realm.write {
////            realm.deleteAll()
////        }
////        try await realm.syncSession?.waitForUpload()
////        try await realm.syncSession?.waitForDownload()
////        let dogCollection = user.mongoClient("mongodb-atlas")
////            .database(named: "car")
////            .collection(named: "Dog", type: Dog.self)
////        let id1 = try await collection
////            .insertOne(Person(name: "John",
////                              age: 32,
////                              address: Address(city: "Austin", state: "TX")))
////        XCTAssertNotNil(id1.objectIdValue)
////        let id2 = try await collection
////            .insertOne(Person(name: "Jane",
////                              age: 29,
////                              address: Address(city: "Austin", state: "TX")))
////        XCTAssertNotNil(id2.objectIdValue)
////        var count = try await collection.count()
////        XCTAssertEqual(count, 2)
////
////        // MARK: $lt query
////        guard let meghna = try await collection.findOne({ person in
////            person.age < 30
////        }) else {
////            return XCTFail()
////        }
////        XCTAssertNotNil(meghna)
////        XCTAssertEqual(meghna.name, "Jane")
////        XCTAssertEqual(meghna.age, 29)
////
////        // MARK: $gt query
////        guard let jason = try await collection.findOne({ person in
////            person.age > 30
////        }) else {
////            return XCTFail()
////        }
////        XCTAssertNotNil(jason)
////        XCTAssertEqual(jason.name, "John")
////        XCTAssertEqual(jason.age, 32)
////
////        // MARK: nested query $eq
////        count = try await collection.find(filter: { person in
////            person.address.city == "Austin"
////        }).count
////        XCTAssertEqual(count, 2)
////        count = try await collection.find(filter: { person in
////            person.address.city == "NYC"
////        }).count
////        XCTAssertEqual(count, 0)
////
////        count = try await collection.deleteOne {
////            $0.age > 30
////        }
////        XCTAssertEqual(count, 1)
////
////        count = try await collection.count()
////        XCTAssertEqual(count, 1)
////
////        count = try await collection.deleteOne {
////            $0.age < 30
////        }
////        XCTAssertEqual(count, 1)
////        _ = try await collection.deleteMany()
//    }
//}
}
