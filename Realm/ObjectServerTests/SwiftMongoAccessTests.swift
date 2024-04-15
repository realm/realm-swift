import Foundation
import RealmSwift
#if canImport(RealmTestSupport)
import RealmSwiftSyncTestSupport
import RealmSyncTestSupport
import RealmTestSupport
import RealmSwiftTestSupport
#endif

// MARK: Models
struct Person : Codable, Equatable {
    struct Address : Codable, Equatable {
        let city: String
        let state: String
    }
    let name: String
    let age: Int
    let address: Address
}

@objc(AllTypesObject) private class AllTypesObject : Object, Codable {
    @objc(Subdocument) class Subdocument : EmbeddedObject, Codable {
        @Persisted var strCol: String
        
        convenience init(strCol: String) {
            self.init()
            self.strCol = strCol
        }
    }
    @Persisted(primaryKey: true) var _id: ObjectId
    
    @Persisted var strCol: String
    @Persisted var intCol: Int
    @Persisted var boolCol: Bool
    @Persisted var binaryCol: Data
    @Persisted var dateCol: Date
    @Persisted var subdocumentCol: Subdocument?
    
    @Persisted var arrayStrCol: List<String>
    @Persisted var arrayIntCol: List<Int>
    @Persisted var arrayBinaryCol: List<Data>
    @Persisted var arrayDateCol: List<Date>
    @Persisted var arraySubdocumentCol: List<Subdocument>
    
    @Persisted var optStrCol: String?
    @Persisted var optIntCol: Int?
    @Persisted var optBinaryCol: Data?
    @Persisted var optDateCol: Date?
    
    convenience init(_id: ObjectId, strCol: String, intCol: Int, boolCol: Bool, binaryCol: Data, dateCol: Date, subdocumentCol: Subdocument? = nil, arrayStrCol: List<String>, arrayIntCol: List<Int>, arrayBinaryCol: List<Data>, arrayDateCol: List<Date>, arraySubdocumentCol: List<Subdocument>, optStrCol: String? = nil, optIntCol: Int? = nil, optBinaryCol: Data? = nil, optDateCol: Date? = nil) {
        self.init()
        self._id = _id
        self.strCol = strCol
        self.intCol = intCol
        self.boolCol = boolCol
        self.binaryCol = binaryCol
        self.dateCol = dateCol
        self.subdocumentCol = subdocumentCol
        self.arrayStrCol = arrayStrCol
        self.arrayIntCol = arrayIntCol
        self.arrayBinaryCol = arrayBinaryCol
        self.arrayDateCol = arrayDateCol
        self.arraySubdocumentCol = arraySubdocumentCol
        self.optStrCol = optStrCol
        self.optIntCol = optIntCol
        self.optBinaryCol = optBinaryCol
        self.optDateCol = optDateCol
    }
}

extension AllTypesObject {
    func compare(to other: AllTypesObject) {
        XCTAssertEqual(strCol, other.strCol)
        XCTAssertEqual(self.intCol, other.intCol)
        XCTAssertEqual(self.boolCol, other.boolCol)
        XCTAssertEqual(self.binaryCol, other.binaryCol)
        XCTAssertEqual(self.dateCol.timeIntervalSince1970,
                       other.dateCol.timeIntervalSince1970,
                       accuracy: 0.1)
        XCTAssertEqual(self.subdocumentCol?.strCol, other.subdocumentCol?.strCol)
        XCTAssertEqual(self.arrayStrCol, other.arrayStrCol)
        XCTAssertEqual(self.arrayIntCol, other.arrayIntCol)
        XCTAssertEqual(self.arrayBinaryCol, other.arrayBinaryCol)
        XCTAssertEqual(self.arrayDateCol, other.arrayDateCol)
        XCTAssertEqual(self.arraySubdocumentCol.map(\.strCol),
                       other.arraySubdocumentCol.map(\.strCol))
        XCTAssertEqual(self.optStrCol, other.optStrCol)
        XCTAssertEqual(self.optIntCol, other.optIntCol)
        XCTAssertEqual(self.optBinaryCol, other.optBinaryCol)
        XCTAssertEqual(self.optDateCol, other.optDateCol)
    }
}

// MARK: CRUD/Types tests
class MongoDataAccessCollectionTests : SwiftSyncTestCase {
    struct AllTypes : Codable, Equatable {
        struct Subdocument : Codable, Equatable {
            let strCol: String
        }
        let _id: ObjectId
        
        let strCol: String
        let intCol: Int
        let binaryCol: Data
        
        let arrayStrCol: [String]
        let arrayIntCol: [Int]
        
        let optStrCol: String?
        let optIntCol: Int?
        
        let subdocument: Subdocument
    }
    
    func testMongoCollection() async throws {
        let app = self.app(id: try RealmServer.shared.createApp(fields: ["_id"], types: [Person.self]))
        let user = try await app.login(credentials: .anonymous)
        let collection = user.mongoClient("mongodb1")
            .database(named: "test_data")
            .collection(named: "Person", type: Person.self)
        _ = try await collection.deleteMany()
        let person = Person(name: "Jason", age: 32, address: Person.Address(city: "Austin", state: "TX"))

        _ = try await collection.insertOne(person)

        guard let foundPerson = try await collection.findOne() else {
            return XCTFail("Could not find inserted Person")
        }
        XCTAssertEqual(foundPerson.name, "Jason")
        XCTAssertEqual(foundPerson.age, 32)
        XCTAssertEqual(foundPerson.address.city, "Austin")
        XCTAssertEqual(foundPerson.address.state, "TX")
        let deleteCount = try await collection.deleteOne()
        XCTAssertEqual(deleteCount.deletedCount, 1)
        let nilPerson = try await collection.findOne()
        XCTAssertNil(nilPerson)
    }
    
    func testAllTypes() async throws {
        let app = self.app(id: try RealmServer.shared.createApp(fields: ["_id"], 
                                                                types: [AllTypes.self]))
        let user = try await app.login(credentials: .anonymous)
        let collection = user.mongoClient("mongodb1")
            .database(named: "test_data")
            .collection(named: "AllTypes", type: AllTypes.self)
        _ = try await collection.deleteMany()
        
        let oid = ObjectId.generate()
        let allTypes = AllTypes(_id: oid,
                              strCol: "foo",
                              intCol: 42,
                              binaryCol: Data([1, 2, 3]),
                              arrayStrCol: ["bar", "baz"],
                              arrayIntCol: [1, 2],
                              optStrCol: nil,
                              optIntCol: nil,
                              subdocument: .init(strCol: "qux"))

        _ = try await collection.insertOne(allTypes)

        guard let foundPerson = try await collection.findOne() else {
            return XCTFail("Could not find inserted Person")
        }
        XCTAssertEqual(foundPerson.strCol, "foo")
        XCTAssertEqual(foundPerson.intCol, 42)
        XCTAssertEqual(foundPerson.binaryCol, Data([1, 2, 3]))
        XCTAssertEqual(foundPerson.arrayStrCol, ["bar", "baz"])
        XCTAssertEqual(foundPerson.arrayIntCol, [1, 2])
        XCTAssertEqual(foundPerson.subdocument, AllTypes.Subdocument(strCol: "qux"))

        let deleteCount = try await collection.deleteOne()
        XCTAssertEqual(deleteCount.deletedCount, 1)
        let nilPerson = try await collection.findOne()
        XCTAssertNil(nilPerson)
    }
    
    func testAllTypesObject() async throws {
        let app = self.app(id: try RealmServer.shared.createApp(fields: ["_id"],
                                                                types: [AllTypes.self]))
        let user = try await app.login(credentials: .anonymous)
        let collection = user.mongoClient("mongodb1")
            .database(named: "test_data")
            .collection(named: "AllTypes", type: AllTypesObject.self)
        let oid = ObjectId.generate()
        
        _ = try await collection.deleteMany()
        let allTypes = AllTypesObject(_id: oid,
                                      strCol: "foo",
                                      intCol: 42,
                                      boolCol: true,
                                      binaryCol: Data([1, 2, 3]),
                                      dateCol: Date(),
                                      subdocumentCol: .init(strCol: "qux"),
                                      arrayStrCol: ["bar", "baz"],
                                      arrayIntCol: [1, 2],
                                      arrayBinaryCol: [Data([1,2,3]),Data([4,5,6])],
                                      arrayDateCol: [.distantPast, .distantFuture],
                                      arraySubdocumentCol: [.init(strCol: "meep"),
                                                            .init(strCol: "moop")],
                                      optStrCol: nil,
                                      optIntCol: nil,
                                      optDateCol: nil)

        _ = try await collection.insertOne(allTypes)
        guard var foundPerson = try await collection.findOne() else {
            return XCTFail("Could not find inserted Person")
        }
        XCTAssertEqual(foundPerson.strCol, "foo")
        XCTAssertEqual(foundPerson.intCol, 42)
        XCTAssertEqual(foundPerson.binaryCol, Data([1, 2, 3]))
        XCTAssertEqual(foundPerson.arrayStrCol, ["bar", "baz"])
        XCTAssertEqual(foundPerson.arrayIntCol, [1, 2])
        XCTAssertEqual(foundPerson.arrayBinaryCol, [Data([1,2,3]),Data([4,5,6])])
        XCTAssertEqual(foundPerson.arrayDateCol, [.distantPast, .distantFuture])
        XCTAssertEqual(foundPerson.subdocumentCol?.strCol, AllTypes.Subdocument(strCol: "qux").strCol)

        let objects = try await collection.find {
            $0._id == oid && $0.intCol == 42
        }
        foundPerson = objects[0]
        XCTAssertEqual(foundPerson.strCol, "foo")
        XCTAssertEqual(foundPerson.optStrCol, nil)
        XCTAssertEqual(foundPerson.intCol, 42)
        XCTAssertEqual(foundPerson.binaryCol, Data([1, 2, 3]))
        XCTAssertEqual(foundPerson.arrayStrCol, ["bar", "baz"])
        XCTAssertEqual(foundPerson.arrayIntCol, [1, 2])
        XCTAssertEqual(foundPerson.subdocumentCol?.strCol, AllTypes.Subdocument(strCol: "qux").strCol)
        func buildQuery(_ query: (Query<AllTypesObject>) -> Query<Bool>) -> [String: Any] {
            fatalError()
        }
        var count = try await collection.find {
            $0.intCol == 41
        }.count
        XCTAssertEqual(count, 0)
        let deleteCount = try await collection.deleteOne()
        XCTAssertEqual(deleteCount.deletedCount, 1)
        count = try await collection.find {
            $0.optStrCol == nil && $0.intCol > 42
        }.count
        XCTAssertEqual(count, 0)
        let nilPerson = try await collection.findOne()
        XCTAssertNil(nilPerson)
    }
    
    // MARK: Query Tests
    override var appId: String {
        Self.appId
    }
    static var appId: String!
    override class func setUp() {
        super.setUp()
        Self.appId = try! RealmServer.shared.createApp(fields: ["_id"],
                                                       types: AllTypesObject.self)
        
    }
    private var collection: MongoTypedCollection<AllTypesObject>!
    override func setUp() async throws {
        try await super.setUp()
        let app = self.app(id: Self.appId)
        let user = try await app.login(credentials: .anonymous)
        self.collection = user.mongoClient("mongodb1")
            .database(named: "test_data")
            .collection(named: "AllTypesObject", type: AllTypesObject.self)
        _ = try await collection.deleteMany()
    }

    override func tearDown() {
        
    }
    override class func tearDown() {
        try? RealmServer.shared.deleteApp(appId)
    }
    
    fileprivate var defaultAllTypesObject: AllTypesObject {
        AllTypesObject(_id: .generate(),
                       strCol: "foo",
                       intCol: 42,
                       boolCol: true,
                       binaryCol: Data([1, 2, 3]),
                       dateCol: Date(),
                       subdocumentCol: .init(strCol: "qux"),
                       arrayStrCol: ["bar", "baz"],
                       arrayIntCol: [1, 2],
                       arrayBinaryCol: [Data([1,2,3]),Data([4,5,6])],
                       arrayDateCol: [.distantPast, .distantFuture],
                       arraySubdocumentCol: [.init(strCol: "meep"),
                                             .init(strCol: "moop")],
                       optStrCol: nil,
                       optIntCol: nil,
                       optDateCol: nil)
    }
    
    // MARK: FindOne
    func testFindOne() async throws {
        let defaultAllTypesObject = self.defaultAllTypesObject
        var foundDocument = try await collection.findOne()
        XCTAssertNil(foundDocument)
        let insertedId = try await self.collection.insertOne(defaultAllTypesObject).insertedId
        XCTAssertEqual(insertedId, .objectId(defaultAllTypesObject._id))
        foundDocument = try await self.collection.findOne()
        foundDocument?.compare(to: defaultAllTypesObject) ?? XCTFail("Could not find document.")
        foundDocument = try await self.collection.findOne(["_id": defaultAllTypesObject._id])
        foundDocument?.compare(to: defaultAllTypesObject) ?? XCTFail("Could not find document.")
        foundDocument = try await self.collection.findOne({ $0._id == defaultAllTypesObject._id })
        foundDocument?.compare(to: defaultAllTypesObject) ?? XCTFail("Could not find document.")
        foundDocument = try await self.collection.findOne { $0._id == .generate() }
        XCTAssertNil(foundDocument)
    }
    
    // MARK: Update
    func testUpdateOne() async throws {
        let defaultAllTypesObject = self.defaultAllTypesObject
        let default2 = self.defaultAllTypesObject
        let value = try await self.collection.insertMany([defaultAllTypesObject,
                                                         default2])
        XCTAssertEqual(value.insertedIds.count, 2)
        defaultAllTypesObject.intCol = 84
        var update = try await self.collection.updateOne(filter: {
            $0.intCol == self.defaultAllTypesObject.intCol
        }, update: defaultAllTypesObject)
        XCTAssertEqual(update.matchedCount, 1)
        XCTAssertEqual(update.modifiedCount, 1)
        XCTAssertEqual(update.upsertedId, nil)
        default2.intCol = -42
        default2.strCol = randomString(32)
        default2._id = .generate()
        update = try await self.collection.updateOne(filter: {
            $0.intCol == -42 && $0._id == default2._id
        }, update: default2, upsert: true)
        XCTAssertEqual(update.matchedCount, 0)
        XCTAssertEqual(update.modifiedCount, 0)
        XCTAssertEqual(update.upsertedId, .objectId(default2._id))
    }
    
    func testUpdateMany() async throws {
        let allTypesObject = self.defaultAllTypesObject
        let allTypesObject2 = AllTypesObject(_id: .generate(),
                                            strCol: "fee",
                                            intCol: 64,
                                            boolCol: false,
                                            binaryCol: .init([60, 57, 100]),
                                            dateCol: .now, arrayStrCol: ["fi", "fo", "fum"],
                                             arrayIntCol: [98, 11, 7], 
                                             arrayBinaryCol: [.init([47, 89, 108])], 
                                             arrayDateCol: [
                                                .distantFuture, .distantPast
                                             ], arraySubdocumentCol: [
                                                .init(strCol: "dum")
                                             ])
        _ = try await self.collection.insertMany([allTypesObject, allTypesObject2])
        allTypesObject.intCol = 84
        var update = try await self.collection.updateMany(filter: {
            $0.intCol == self.defaultAllTypesObject.intCol
        }, update: allTypesObject)
        XCTAssertEqual(update.matchedCount, 1)
        update = try await self.collection.updateMany(filter: {
            $0.strCol == self.defaultAllTypesObject.strCol
        }, update: allTypesObject)
        XCTAssertEqual(update.matchedCount, 1)
    }
    // MARK: $eq
    func testFind_QueryEq() async throws {
        let defaultAllTypesObject = self.defaultAllTypesObject
        _ = try await self.collection.insertOne(defaultAllTypesObject)
        try await XCTAssertEqualAsync(await self.collection.count {
            $0.intCol == self.defaultAllTypesObject.intCol
        }, 1)
        try await XCTAssertEqualAsync(await self.collection.count {
            $0.intCol == self.defaultAllTypesObject.intCol + 1
        }, 0)
        try await XCTAssertEqualAsync(await self.collection.count {
            $0.boolCol
        }, 1)
        try await XCTAssertEqualAsync(await self.collection.count {
            !$0.boolCol
        }, 0)
    }

    // MARK: $ne
    func testFind_QueryNe() async throws {
        let defaultAllTypesObject = self.defaultAllTypesObject
        _ = try await self.collection.insertOne(defaultAllTypesObject)
        try await XCTAssertEqualAsync(await self.collection.count {
            $0.intCol != self.defaultAllTypesObject.intCol
        }, 0)
        try await XCTAssertEqualAsync(await self.collection.count {
            $0.intCol != self.defaultAllTypesObject.intCol + 1
        }, 1)
    }
    
    // MARK: $not
    func testFind_QueryNot() async throws {
        let defaultAllTypesObject = self.defaultAllTypesObject
        _ = try await self.collection.insertOne(defaultAllTypesObject)
        try await XCTAssertEqualAsync(await self.collection.count {
            !($0.intCol == self.defaultAllTypesObject.intCol)
        }, 0)
        try await XCTAssertEqualAsync(await self.collection.count {
            !($0.intCol == self.defaultAllTypesObject.intCol + 1)
        }, 1)
    }

    // MARK: $gt
    func testFind_QueryGt() async throws {
        let defaultAllTypesObject = self.defaultAllTypesObject
        _ = try await self.collection.insertOne(defaultAllTypesObject)
        var count = try await self.collection.count {
            $0.dateCol > Date.distantPast
        }
        XCTAssertEqual(count, 1)
        count = try await self.collection.count {
            $0.dateCol > Date.distantFuture
        }
        XCTAssertEqual(count, 0)
        await XCTAssertEqualAsync(try await self.collection.count {
            $0.intCol > 24
        }, 1)
        await XCTAssertEqualAsync(try await self.collection.count {
            $0.intCol > 42
        }, 0)
    }
    
    // MARK: $gte
    func testFind_QueryGte() async throws {
        let defaultAllTypesObject = self.defaultAllTypesObject
        _ = try await self.collection.insertOne(defaultAllTypesObject)
        var count = try await self.collection.count {
            $0.dateCol >= Date.distantPast
        }
        XCTAssertEqual(count, 1)
        count = try await self.collection.count {
            $0.dateCol >= Date.distantFuture
        }
        XCTAssertEqual(count, 0)
        await XCTAssertEqualAsync(try await self.collection.count {
            $0.intCol >= 24
        }, 1)
        await XCTAssertEqualAsync(try await self.collection.count {
            $0.intCol >= 43
        }, 0)
    }
    
    // MARK: BETWEEN
    func testFind_QueryBetween() async throws {
        let defaultAllTypesObject = self.defaultAllTypesObject
        _ = try await self.collection.insertOne(defaultAllTypesObject)
        var count = try await self.collection.count {
            $0.dateCol >= Date.distantPast
        }
        XCTAssertEqual(count, 1)
        count = try await self.collection.count {
            $0.dateCol >= Date.distantFuture
        }
        XCTAssertEqual(count, 0)
        await XCTAssertEqualAsync(try await self.collection.count {
            $0.intCol.contains(41..<43)
        }, 1)
        await XCTAssertEqualAsync(try await self.collection.count {
            $0.intCol.contains(43..<45)
        }, 0)
    }
    
    // MARK: subdocument
    func testFind_QuerySubdocument() async throws {
        let defaultAllTypesObject = self.defaultAllTypesObject
        _ = try await self.collection.insertOne(defaultAllTypesObject)
        var count = try await self.collection.find {
            $0.subdocumentCol.strCol.contains("q")
        }.count
        XCTAssertEqual(count, 1)
        count = try await self.collection.find {
            $0.subdocumentCol.strCol.contains("z")
        }.count
        XCTAssertEqual(count, 0)
        count = try await self.collection.find {
            $0.subdocumentCol.strCol == "qux"
        }.count
        XCTAssertEqual(count, 1)
        count = try await self.collection.find {
            $0.subdocumentCol.strCol != "qux"
        }.count
        XCTAssertEqual(count, 0)
    }
    
    // MARK: $in
    func testFind_QueryArrayIn() async throws {
        let defaultAllTypesObject = self.defaultAllTypesObject
        _ = try await self.collection.insertOne(defaultAllTypesObject)
        var count = Int(try await self.collection.count {
            $0.arrayIntCol.containsAny(in: [1, 3])
        })
        XCTAssertEqual(count, 1)
        count = try await self.collection.find {
            $0.arrayIntCol.containsAny(in: [4, 3])
        }.count
        XCTAssertEqual(count, 0)
        count = try await self.collection.find {
            $0.arrayIntCol.contains(1)
        }.count
        XCTAssertEqual(count, 1)
        count = try await self.collection.find {
            $0.arrayIntCol.contains(3)
        }.count
        XCTAssertEqual(count, 0)
    }
}

@_unsafeInheritExecutor
func XCTAssertEqualAsync<T>(_ lhs: @autoclosure () async throws -> T,
                            _ rhs: @autoclosure  () async throws -> T) async where T: Equatable {
    do {
        let lhsValue = try await lhs()
        let rhsValue = try await rhs()
        XCTAssertEqual(lhsValue, rhsValue)
    } catch {
        XCTFail(error.localizedDescription)
    }
}
