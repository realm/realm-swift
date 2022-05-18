////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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

#if os(macOS)
import Realm
import Realm.Private
import RealmSwift
import XCTest

#if canImport(RealmTestSupport)
import RealmSwiftSyncTestSupport
import RealmSyncTestSupport
import RealmTestSupport
#endif

public class SwiftObjectAsymmetric: AsymmetricObject {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var string: String
    @Persisted var int: Int
    @Persisted var bool: Bool
    @Persisted var double: Double = 1.1
    @Persisted var long: Int64 = 1
    @Persisted var decimal: Decimal128 = Decimal128(1)
    @Persisted var uuid: UUID = UUID(uuidString: "85d4fbee-6ec6-47df-bfa1-615931903d7e")!
    @Persisted var objectId: ObjectId = ObjectId("6058f12682b2fbb1f334ef1d")

    @Persisted public var intList: List<Int>
    @Persisted public var boolList: List<Bool>
    @Persisted public var stringList: List<String>
    @Persisted public var dataList: List<Data>
    @Persisted public var dateList: List<Date>
    @Persisted public var doubleList: List<Double>
    @Persisted public var objectIdList: List<ObjectId>
    @Persisted public var decimalList: List<Decimal128>
    @Persisted public var uuidList: List<UUID>
    @Persisted public var anyList: List<AnyRealmValue>

    @Persisted public var intSet: MutableSet<Int>
    @Persisted public var stringSet: MutableSet<String>
    @Persisted public var dataSet: MutableSet<Data>
    @Persisted public var dateSet: MutableSet<Date>
    @Persisted public var doubleSet: MutableSet<Double>
    @Persisted public var objectIdSet: MutableSet<ObjectId>
    @Persisted public var decimalSet: MutableSet<Decimal128>
    @Persisted public var uuidSet: MutableSet<UUID>
    @Persisted public var anySet: MutableSet<AnyRealmValue>

    @Persisted public var otherIntSet: MutableSet<Int>
    @Persisted public var otherStringSet: MutableSet<String>
    @Persisted public var otherDataSet: MutableSet<Data>
    @Persisted public var otherDateSet: MutableSet<Date>
    @Persisted public var otherDoubleSet: MutableSet<Double>
    @Persisted public var otherObjectIdSet: MutableSet<ObjectId>
    @Persisted public var otherDecimalSet: MutableSet<Decimal128>
    @Persisted public var otherUuidSet: MutableSet<UUID>
    @Persisted public var otherAnySet: MutableSet<AnyRealmValue>

    @Persisted public var intMap: Map<String, Int>
    @Persisted public var stringMap: Map<String, String>
    @Persisted public var dataMap: Map<String, Data>
    @Persisted public var dateMap: Map<String, Date>
    @Persisted public var doubleMap: Map<String, Double>
    @Persisted public var objectIdMap: Map<String, ObjectId>
    @Persisted public var decimalMap: Map<String, Decimal128>
    @Persisted public var uuidMap: Map<String, UUID>
    @Persisted public var anyMap: Map<String, AnyRealmValue>

    public override class func _realmIgnoreClass() -> Bool {
        return true
    }

    public convenience init(id: ObjectId, string: String, int: Int, bool: Bool) {
        self.init()
        self._id = id
        self.string = string
        self.int = int
        self.bool = bool
    }
}

class SwiftAsymmetricSyncTests: SwiftSyncTestCase {
    override class var defaultTestSuite: XCTestSuite {
        // async/await is currently incompatible with thread sanitizer and will
        // produce many false positives
        // https://bugs.swift.org/browse/SR-15444
        if RLMThreadSanitizerEnabled() {
            return XCTestSuite(name: "\(type(of: self))")
        }
        return super.defaultTestSuite
    }

    var asymmetricApp: App {
        var appId = SwiftAsymmetricSyncTests.asymmetricAppId
        if appId == nil {
            do {
                let objectSchema = RLMObjectSchema(forObjectClass: SwiftObjectAsymmetric.self)
                appId = try RealmServer.shared.createAppForAsymmetricSchema([objectSchema])
                SwiftAsymmetricSyncTests.asymmetricAppId = appId
            } catch {
                XCTFail("Failed to create Asymmetric app: \(error)")
            }
        }

        let appConfig = AppConfiguration(baseURL: "http://localhost:9090",
                                         transport: nil,
                                         localAppName: nil,
                                         localAppVersion: nil)
        return App(id: appId!, configuration: appConfig)
    }
    static var asymmetricAppId: String?

    override func tearDown() {
        let user = try! logInUser(for: .anonymous, app: asymmetricApp)
        let mongoClient = user.mongoClient("mongodb1")
        let database = mongoClient.database(named: "test_data")
        let collection =  database.collection(withName: "SwiftObjectAsymmetric")
        removeAllFromCollection(collection)
        super.tearDown()
    }

    func testAsymmetricObjectSchema() throws {
        var configuration = (try logInUser(for: basicCredentials(app: asymmetricApp), app: asymmetricApp)).flexibleSyncConfiguration()
        configuration.objectTypes = [SwiftObjectAsymmetric.self]
        let realm = try Realm(configuration: configuration)
        XCTAssertTrue(realm.schema.objectSchema[0].isAsymmetric)
    }

    func testOpenLocalRealmWithAsymmetricObjectError() throws {
        let configuration = Realm.Configuration(objectTypes: [SwiftObjectAsymmetric.self])
        do {
            _ = try Realm(configuration: configuration)
            XCTFail("Opening a local Realm with an `Asymmetric` table should fail")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // FIXME: Enable this test when this is implemented on core. Core should validate if the schema includes an asymmetric table for a PBS configuration and throw an error.
//    func testOpenPBSConfigurationRealmWithAsymmetricObjectError() throws {
//        let user = try logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)
//        var configuration = user.configuration(partitionValue: #function)
//        configuration.objectTypes = [SwiftObjectAsymmetric.self]
//
//        do {
//            _ = try Realm(configuration: configuration)
//            XCTFail("Opening a local Realm with an `Asymmetric` table should fail")
//        } catch {
//            XCTAssertNotNil(error)
//        }
//    }
}

#if swift(>=5.6) && canImport(_Concurrency)
@available(macOS 12.0, *)
extension SwiftAsymmetricSyncTests {
    func config() async throws -> Realm.Configuration {
        var config = (try await asymmetricApp.login(credentials: basicCredentials(app: asymmetricApp))).flexibleSyncConfiguration()
        config.objectTypes = [SwiftObjectAsymmetric.self]
        return config
    }

    func realm() async throws -> Realm {
        let realm = try await Realm(configuration: config())
        return realm
    }

    @MainActor
    func setupCollection() async throws -> MongoCollection {
        let user = try await asymmetricApp.login(credentials: .anonymous)
        let mongoClient = user.mongoClient("mongodb1")
        let database = mongoClient.database(named: "test_data")
        let collection =  database.collection(withName: "SwiftObjectAsymmetric")
        return collection
    }

    @MainActor
    func testCreateAsymmetricObject() async throws {
        let realm = try await realm()
        XCTAssertNotNil(realm)

        // Create Asymmetric Objects and create them on the Realm
        for i in 1...15 {
            try realm.write {
                let personAsymmetric = SwiftObjectAsymmetric(id: ObjectId.generate(),
                                                             string: "name_\(#function)_\(i)",
                                                             int: i,
                                                             bool: Bool.random())
                realm.create(personAsymmetric)
            }
        }
        waitForUploads(for: realm)

        // We use the Mongo client API to check if the documents were create,
        // because we cannot query `AsymmetricObject`s directly.
        let collection = try await setupCollection()
        let documents = try await collection.find(filter: [:])
        XCTAssertEqual(documents.count, 15)
    }

    @MainActor
    func testPropertyTypesAsymmetricObject() async throws {
        let realm = try await realm()
        XCTAssertNotNil(realm)

        // Create Asymmetric Objects and create them on the Realm
        try realm.write {

            let personAsymmetric = SwiftObjectAsymmetric(id: ObjectId.generate(),
                                                         string: "name_\(#function)",
                                                         int: 15,
                                                         bool: true)
            realm.create(personAsymmetric)
        }
        waitForUploads(for: realm)

        // We use the Mongo client API to check if the documents were create,
        // because we cannot query AsymmetricObjects directly.
        let collection = try await setupCollection()
        let documents = try await collection.find(filter: [:])
        XCTAssertEqual(documents.count, 1)

        let document = documents[0]
        XCTAssertEqual(document["string"]??.stringValue, "name_\(#function)")
        XCTAssertEqual(document["int"]??.int64Value, 15)
        XCTAssertEqual(document["bool"]??.boolValue, true)
        XCTAssertEqual(document["double"]??.doubleValue, 1.1)
        XCTAssertEqual(document["long"]??.int64Value, 1)
        XCTAssertEqual(document["decimal"]??.decimal128Value, Decimal128(1))
        XCTAssertEqual(document["uuid"]??.uuidValue, UUID(uuidString: "85d4fbee-6ec6-47df-bfa1-615931903d7e")!)
        XCTAssertEqual(document["objectId"]??.objectIdValue, ObjectId("6058f12682b2fbb1f334ef1d"))
    }
}
#endif // canImport(_Concurrency)
#endif // os(macOS)
