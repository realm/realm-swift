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

    convenience init(string: String, int: Int, bool: Bool) {
        self.init()
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

@available(macOS 13, *)
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

    nonisolated static let objectTypes = [
        HugeObjectAsymmetric.self,
        SwiftCustomColumnAsymmetricObject.self,
        SwiftObjectAsymmetric.self,
    ]

    override func createApp() throws -> String {
        try RealmServer.shared.createApp(fields: [], types: SwiftAsymmetricSyncTests.objectTypes, persistent: true)
    }

    override var objectTypes: [ObjectBase.Type] {
        SwiftAsymmetricSyncTests.objectTypes
    }

    override func configuration(user: User) -> Realm.Configuration {
        user.flexibleSyncConfiguration()
    }

    @MainActor
    func testAsymmetricObjectSchema() throws {
        let realm = try openRealm()
        XCTAssertTrue(realm.schema.objectSchema[0].isAsymmetric)
    }

    func testOpenLocalRealmWithAsymmetricObjectError() throws {
        let configuration = Realm.Configuration(objectTypes: [SwiftObjectAsymmetric.self])
        XCTAssertThrowsError(try Realm(configuration: configuration)) { error in
            XCTAssertEqual(error.localizedDescription, "Schema validation failed due to the following errors:\n- Asymmetric table \'SwiftObjectAsymmetric\' not allowed in a local Realm")
        }
    }

    func testOpenPBSConfigurationRealmWithAsymmetricObjectError() throws {
        let user = createUser()
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

@available(macOS 13.0, *)
extension SwiftAsymmetricSyncTests {
    @MainActor
    func setupCollection(_ type: ObjectBase.Type) async throws -> MongoCollection {
        let user = try await app.login(credentials: .anonymous)
        let collection = user.collection(for: type, app: app)
        if try await collection.count(filter: [:]) > 0 {
            removeAllFromCollection(collection)
        }
        return collection
    }

    @MainActor
    func checkCountInMongo(_ expectedCount: Int, type: ObjectBase.Type) async throws {
        let waitStart = Date()
        let user = try await app.login(credentials: .anonymous)
        let collection = user.collection(for: type, app: app)
        while try await collection.count(filter: [:]) < expectedCount && waitStart.timeIntervalSinceNow > -600.0 {
            try await Task.sleep(for: .seconds(5))
        }

        XCTAssertEqual(collection.count(filter: [:]).await(self), expectedCount)
    }

    @MainActor
    func testCreateAsymmetricObject() async throws {
        _ = try await setupCollection(SwiftObjectAsymmetric.self)
        let realm = try await openRealm()

        try realm.write {
            for i in 1...15 {
                realm.create(SwiftObjectAsymmetric.self,
                             value: SwiftObjectAsymmetric(string: "name_\(#function)_\(i)",
                                                          int: i, bool: Bool.random()))
            }
        }
        waitForUploads(for: realm)

        try await checkCountInMongo(15, type: SwiftObjectAsymmetric.self)
    }

    @MainActor
    func testPropertyTypesAsymmetricObject() async throws {
        let collection = try await setupCollection(SwiftObjectAsymmetric.self)
        let realm = try await openRealm()

        try realm.write {
            realm.create(SwiftObjectAsymmetric.self,
                         value: SwiftObjectAsymmetric(string: "name_\(#function)",
                                                      int: 15, bool: true))
        }
        waitForUploads(for: realm)

        try await checkCountInMongo(1, type: SwiftObjectAsymmetric.self)

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
        _ = try await setupCollection(HugeObjectAsymmetric.self)
        let realm = try await openRealm()

        // Create Asymmetric Objects
        try realm.write {
            for _ in 0..<2 {
                realm.create(HugeObjectAsymmetric.self, value: ["data": Data(repeating: 16, count: 1000000)])
            }
        }
        waitForUploads(for: realm)

        try await checkCountInMongo(2, type: HugeObjectAsymmetric.self)
    }

    @MainActor
    func testCreateCustomAsymmetricObject() async throws {
        let collection = try await setupCollection(SwiftCustomColumnAsymmetricObject.self)
        let realm = try await openRealm()

        let objectId = ObjectId.generate()
        let valuesDictionary: [String: Any] = ["id": objectId,
                                               "boolCol": false,
                                               "intCol": 1234,
                                               "doubleCol": 1234.1234,
                                               "stringCol": "$%&/("]

        // Create Asymmetric Objects
        try realm.write {
            realm.create(SwiftCustomColumnAsymmetricObject.self, value: valuesDictionary)
        }
        waitForUploads(for: realm)

        try await checkCountInMongo(1, type: SwiftCustomColumnAsymmetricObject.self)

        let filter: Document = ["_id": .objectId(objectId)]
        let document = try await collection.findOneDocument(filter: filter)
        XCTAssertNotNil(document)

        XCTAssertEqual(document!["_id"], AnyBSON(objectId))
        XCTAssertEqual(document!["custom_boolCol"], AnyBSON(false))
        XCTAssertEqual(document!["custom_intCol"], AnyBSON(1234))
        XCTAssertEqual(document!["custom_doubleCol"], AnyBSON(1234.1234))
        XCTAssertEqual(document!["custom_stringCol"], AnyBSON("$%&/("))
    }
}
#endif // os(macOS)
