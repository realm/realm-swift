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

class SwiftObjectAsymmetric: AsymmetricObject {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var string: String
    @Persisted var int: Int
    @Persisted var bool: Bool
    @Persisted var double: Double = 1.1
    @Persisted var long: Int64 = 1
    @Persisted var decimal: Decimal128 = Decimal128(1)
    @Persisted var uuid: UUID = UUID(uuidString: "85d4fbee-6ec6-47df-bfa1-615931903d7e")!
    @Persisted var objectId: ObjectId = ObjectId("6058f12682b2fbb1f334ef1d")

    @Persisted var intList: List<Int>
    @Persisted var boolList: List<Bool>
    @Persisted var stringList: List<String>
    @Persisted var dataList: List<Data>
    @Persisted var dateList: List<Date>
    @Persisted var doubleList: List<Double>
    @Persisted var objectIdList: List<ObjectId>
    @Persisted var decimalList: List<Decimal128>
    @Persisted var uuidList: List<UUID>
    @Persisted var anyList: List<AnyRealmValue>

    @Persisted var intSet: MutableSet<Int>
    @Persisted var stringSet: MutableSet<String>
    @Persisted var dataSet: MutableSet<Data>
    @Persisted var dateSet: MutableSet<Date>
    @Persisted var doubleSet: MutableSet<Double>
    @Persisted var objectIdSet: MutableSet<ObjectId>
    @Persisted var decimalSet: MutableSet<Decimal128>
    @Persisted var uuidSet: MutableSet<UUID>
    @Persisted var anySet: MutableSet<AnyRealmValue>

    @Persisted var otherIntSet: MutableSet<Int>
    @Persisted var otherStringSet: MutableSet<String>
    @Persisted var otherDataSet: MutableSet<Data>
    @Persisted var otherDateSet: MutableSet<Date>
    @Persisted var otherDoubleSet: MutableSet<Double>
    @Persisted var otherObjectIdSet: MutableSet<ObjectId>
    @Persisted var otherDecimalSet: MutableSet<Decimal128>
    @Persisted var otherUuidSet: MutableSet<UUID>
    @Persisted var otherAnySet: MutableSet<AnyRealmValue>

    @Persisted var intMap: Map<String, Int>
    @Persisted var stringMap: Map<String, String>
    @Persisted var dataMap: Map<String, Data>
    @Persisted var dateMap: Map<String, Date>
    @Persisted var doubleMap: Map<String, Double>
    @Persisted var objectIdMap: Map<String, ObjectId>
    @Persisted var decimalMap: Map<String, Decimal128>
    @Persisted var uuidMap: Map<String, UUID>
    @Persisted var anyMap: Map<String, AnyRealmValue>

    override class func _realmIgnoreClass() -> Bool {
        return true
    }

    convenience init(id: ObjectId, string: String, int: Int, bool: Bool) {
        self.init()
        self._id = id
        self.string = string
        self.int = int
        self.bool = bool
    }
}

class HugeObjectAsymmetric: AsymmetricObject {
    @Persisted(primaryKey: true) public var _id: ObjectId
    @Persisted public var data: Data?

    override class func _realmIgnoreClass() -> Bool {
        return true
    }
}

let customColumnAsymmetricPropertiesMapping: [String: String] = ["id": "_id",
                                                                 "boolCol": "custom_boolCol",
                                                                 "intCol": "custom_intCol",
                                                                 "doubleCol": "custom_doubleCol",
                                                                 "stringCol": "custom_stringCol"]

class SwiftCustomColumnAsymmetricObject: AsymmetricObject {
    @Persisted(primaryKey: true) public var id: ObjectId
    @Persisted public var boolCol: Bool = true
    @Persisted public var intCol: Int = 1
    @Persisted public var doubleCol: Double = 1.1
    @Persisted public var stringCol: String = "string"

    override class func propertiesMapping() -> [String: String] {
        customColumnAsymmetricPropertiesMapping
    }

    override class func _realmIgnoreClass() -> Bool {
        return true
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
                let objectSchemas = [SwiftObjectAsymmetric.self,
                                     HugeObjectAsymmetric.self,
                                     SwiftCustomColumnAsymmetricObject.self].map { RLMObjectSchema(forObjectClass: $0) }
                appId = try RealmServer.shared.createAppForAsymmetricSchema(objectSchemas)
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

    func testAsymmetricObjectSchema() throws {
        var configuration = (try logInUser(for: basicCredentials(app: asymmetricApp), app: asymmetricApp)).flexibleSyncConfiguration()
        configuration.objectTypes = [SwiftObjectAsymmetric.self]
        let realm = try Realm(configuration: configuration)
        XCTAssertTrue(realm.schema.objectSchema[0].isAsymmetric)
    }

    func testOpenLocalRealmWithAsymmetricObjectError() throws {
        let configuration = Realm.Configuration(objectTypes: [SwiftObjectAsymmetric.self])
        XCTAssertThrowsError(try Realm(configuration: configuration)) { error in
            XCTAssertEqual(error.localizedDescription, "Schema validation failed due to the following errors:\n- Asymmetric table \'SwiftObjectAsymmetric\' not allowed in a local Realm")
        }
    }

    func testOpenPBSConfigurationRealmWithAsymmetricObjectError() throws {
        let user = try logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)
        var configuration = user.configuration(partitionValue: #function)
        configuration.objectTypes = [SwiftObjectAsymmetric.self]

        XCTAssertThrowsError(try Realm(configuration: configuration)) { error in
            XCTAssert(error.localizedDescription.contains("Asymmetric table 'SwiftObjectAsymmetric' not allowed in partition based sync"))
        }
    }

    func testCustomColumnNameAsymmetricObjectSchema() {
        let modernCustomObjectSchema = SwiftCustomColumnAsymmetricObject().objectSchema
        for property in modernCustomObjectSchema.properties {
            XCTAssertEqual(customColumnAsymmetricPropertiesMapping[property.name], property.columnName)
        }
    }
}

#if swift(>=5.6) && canImport(_Concurrency)
@available(macOS 12.0, *)
extension SwiftAsymmetricSyncTests {
    func config() async throws -> Realm.Configuration {
        var config = (try await asymmetricApp.login(credentials: basicCredentials(app: asymmetricApp))).flexibleSyncConfiguration()
        config.objectTypes = [SwiftObjectAsymmetric.self, HugeObjectAsymmetric.self, SwiftCustomColumnAsymmetricObject.self]
        return config
    }

    func realm() async throws -> Realm {
        let realm = try await Realm(configuration: config())
        return realm
    }

    @MainActor
    func setupCollection(_ collection: String) async throws -> MongoCollection {
        let user = try await asymmetricApp.login(credentials: .anonymous)
        let mongoClient = user.mongoClient("mongodb1")
        let database = mongoClient.database(named: "test_data")
        let collection =  database.collection(withName: collection)
        if try await collection.count(filter: [:]) > 0 {
            removeAllFromCollection(collection)
        }
        return collection
    }

    @MainActor
    func checkCountInMongo(_ expectedCount: Int, forCollection collection: String) async throws {
        let waitStart = Date()
        let user = try await asymmetricApp.login(credentials: .anonymous)
        let mongoClient = user.mongoClient("mongodb1")
        let database = mongoClient.database(named: "test_data")
        let collection =  database.collection(withName: collection)
        while collection.count(filter: [:]).await(self) != expectedCount && waitStart.timeIntervalSinceNow > -600.0 {
            sleep(5)
        }

        XCTAssertEqual(collection.count(filter: [:]).await(self), expectedCount)
    }

    @MainActor
    func testCreateAsymmetricObject() async throws {
        let realm = try await realm()
        XCTAssertNotNil(realm)

        // Create Asymmetric Objects
        try realm.write {
            for i in 1...15 {
                realm.create(SwiftObjectAsymmetric.self, value: ["id": ObjectId.generate(),
                                                                 "string": "name_\(#function)_\(i)",
                                                                 "int": i,
                                                                 "bool": Bool.random()])
            }
        }
        waitForUploads(for: realm)

        // We use the Mongo client API to check if the documents were create,
        // because we cannot query `AsymmetricObject`s directly.
        try await checkCountInMongo(15, forCollection: "SwiftObjectAsymmetric")
    }

    @MainActor
    func testPropertyTypesAsymmetricObject() async throws {
        let collection = try await setupCollection("SwiftObjectAsymmetric")
        let realm = try await realm()
        XCTAssertNotNil(realm)

        // Create Asymmetric Objects
        try realm.write {
            realm.create(SwiftObjectAsymmetric.self, value: ["id": ObjectId.generate(),
                                                             "string": "name_\(#function)",
                                                             "int": 15,
                                                             "bool": true])
        }
        waitForUploads(for: realm)

        // We use the Mongo client API to check if the documents were create,
        // because we cannot query AsymmetricObjects directly.
        try await checkCountInMongo(1, forCollection: "SwiftObjectAsymmetric")

        let document = try await collection.find(filter: [:])[0]
        XCTAssertEqual(document["string"]??.stringValue, "name_\(#function)")
        XCTAssertEqual(document["int"]??.int64Value, 15)
        XCTAssertEqual(document["bool"]??.boolValue, true)
        XCTAssertEqual(document["double"]??.doubleValue, 1.1)
        XCTAssertEqual(document["long"]??.int64Value, 1)
        XCTAssertEqual(document["decimal"]??.decimal128Value, Decimal128(1))
        XCTAssertEqual(document["uuid"]??.uuidValue, UUID(uuidString: "85d4fbee-6ec6-47df-bfa1-615931903d7e")!)
        XCTAssertEqual(document["objectId"]??.objectIdValue, ObjectId("6058f12682b2fbb1f334ef1d"))
    }

    @MainActor
    func testCreateHugeAsymmetricObject() async throws {
        let realm = try await realm()
        XCTAssertNotNil(realm)

        // Create Asymmetric Objects
        try realm.write {
            for _ in 0..<2 {
                realm.create(HugeObjectAsymmetric.self, value: ["data": Data(repeating: 16, count: 1000000)])
            }
        }
        waitForUploads(for: realm)

        try await checkCountInMongo(2, forCollection: "HugeObjectAsymmetric")
    }

    @MainActor
    func testCreateCustomAsymmetricObject() async throws {
        let collection = try await setupCollection("SwiftCustomColumnAsymmetricObject")
        let realm = try await realm()
        XCTAssertNotNil(realm)

        let objectId = ObjectId.generate()
        let valuesDictionary: [String: any BSON] = ["id": objectId,
                                                    "boolCol": false,
                                                    "intCol": 1234,
                                                    "doubleCol": 1234.1234,
                                                    "stringCol": "$%&/("]

        // Create Asymmetric Objects
        try realm.write {
            realm.create(SwiftCustomColumnAsymmetricObject.self, value: valuesDictionary)
        }
        waitForUploads(for: realm)

        try await checkCountInMongo(1, forCollection: "SwiftCustomColumnAsymmetricObject")

        let filter: Document = ["_id": .objectId(objectId)]
        let document = try await collection.findOneDocument(filter: filter)
        XCTAssertNotNil(document)

        for (key, customKey) in customColumnAsymmetricPropertiesMapping {
            if let value = valuesDictionary[key] as? AnyBSON {
                XCTAssertEqual(document![customKey], AnyBSON(value))
            }
        }
    }
}
#endif // canImport(_Concurrency)
#endif // os(macOS)
