////////////////////////////////////////////////////////////////////////////
//
// Copyright 2022 Realm Inc.
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

import XCTest
import RealmSwift

// MARK: - Custom Column Object Factory

protocol CustomColumnObjectFactory {
    associatedtype Root: Object

    static func create(primaryKey: ObjectId, nestedObject: Root?) -> Root
    static func createValues(primaryKey: ObjectId) -> [String: Any]
}

// MARK: - Models

let propertiesModernCustomMapping: [String: String] =  ["pk": "custom_pk",
                                                        "intCol": "custom_intCol",
                                                        "anyCol": "custom_anyCol",
                                                        "intEnumCol": "custom_intEnumCol",
                                                        "objectCol": "custom_objectCol",
                                                        "arrayCol": "custom_arrayCol",
                                                        "setCol": "custom_setCol",
                                                        "mapCol": "custom_mapCol",
                                                        "embeddedObject": "custom_embeddedObject",
                                                        "arrayIntCol": "custom_arrayIntCol",
                                                        "setIntCol": "custom_setIntCol",
                                                        "mapIntCol": "custom_mapIntCol"]
class ModernCustomObject: Object {
    @Persisted(primaryKey: true) var pk: ObjectId
    @Persisted var intCol: Int
    @Persisted var anyCol: AnyRealmValue
    @Persisted var intEnumCol: ModernIntEnum

    @Persisted var objectCol: ModernCustomObject?
    @Persisted var arrayCol = List<ModernCustomObject>()
    @Persisted var setCol = MutableSet<ModernCustomObject>()
    @Persisted var mapCol = Map<String, ModernCustomObject?>()

    @Persisted var embeddedObject: EmbeddedModernCustomObject?

    @Persisted var arrayIntCol = List<Int>()
    @Persisted var setIntCol = MutableSet<Int>()
    @Persisted var mapIntCol = Map<String, Int>()

    override class func propertiesMapping() -> [String: String] {
        propertiesModernCustomMapping
    }

    convenience init(pk: ObjectId) {
        self.init()
        self.pk = pk
    }
}

let propertiesModernEmbeddedCustomMapping: [String: String] =  ["intCol": "custom_intCol"]
class EmbeddedModernCustomObject: EmbeddedObject {
    @Persisted var intCol: Int

    override class func propertiesMapping() -> [String: String] {
        propertiesModernEmbeddedCustomMapping
    }
}

extension ModernCustomObject: CustomColumnObjectFactory {
    typealias Root = ModernCustomObject

    static func create(primaryKey: ObjectId, nestedObject: ModernCustomObject?) -> ModernCustomObject {
        let object = ModernCustomObject()
        object.pk = primaryKey

        let linkedObject = ModernCustomObject()
        linkedObject.pk = ObjectId.generate()
        linkedObject.embeddedObject = EmbeddedModernCustomObject()

        object.embeddedObject = EmbeddedModernCustomObject()

        if let nestedObject = nestedObject {
            object.anyCol = .object(nestedObject)
            object.objectCol = nestedObject
            object.arrayCol.append(nestedObject)
            object.setCol.insert(nestedObject)
            object.mapCol["key"] = nestedObject
        }
        return object
    }

    static func createValues(primaryKey: ObjectId) -> [String: Any] {
        return [
            "pk": primaryKey,
            "intCol": 123,
            "anyCol": AnyRealmValue.int(345),
            "intEnumCol": ModernIntEnum.value2,
            "objectCol": ModernCustomObject(),
            "arrayCol": [ModernCustomObject()],
            "setCol": [ModernCustomObject()],
            "mapCol": ["key": ModernCustomObject()],
            "embeddedObject": EmbeddedModernCustomObject(),
            "arrayIntCol": [123],
            "setIntCol": [345],
            "mapIntCol": ["key": 123]
        ]
    }
}

let propertiesCustomMapping: [String: String] = {
    ["pk": "custom_pk",
     "intCol": "custom_intCol",
     "objectCol": "custom_objectCol",
     "arrayCol": "custom_arrayCol",
     "setCol": "custom_setCol",
     "mapCol": "custom_mapCol",
     "anyCol": "custom_anyCol",
     "intEnumCol": "custom_intEnumCol",
     "embeddedObject": "custom_embeddedObject",
     "arrayIntCol": "custom_arrayIntCol",
     "setIntCol": "custom_setIntCol",
     "mapIntCol": "custom_mapIntCol"]
}()

class OldCustomObject: Object {
    @objc dynamic var pk = ObjectId.generate()
    @objc dynamic var intCol = 123
    var anyCol = RealmProperty<AnyRealmValue>()
    @objc dynamic var intEnumCol = IntEnum.value1

    @objc dynamic var objectCol: OldCustomObject?
    let arrayCol = List<OldCustomObject>()
    let setCol = MutableSet<OldCustomObject>()
    let mapCol = Map<String, OldCustomObject?>()

    @objc dynamic var embeddedObject: EmbeddedCustomObject?

    let arrayIntCol = List<Int>()
    let setIntCol = MutableSet<Int>()
    let mapIntCol = Map<String, Int?>()

    override class func primaryKey() -> String? {
        return "pk"
    }
    override class func propertiesMapping() -> [String: String] {
        propertiesCustomMapping
    }
}

extension OldCustomObject: CustomColumnObjectFactory {
    typealias Root = OldCustomObject

    static func create(primaryKey: ObjectId, nestedObject: OldCustomObject?) -> OldCustomObject {
        let object = OldCustomObject()
        object.pk = primaryKey
        object.embeddedObject = EmbeddedCustomObject()

        let linkedObject = OldCustomObject()
        linkedObject.pk = ObjectId.generate()
        linkedObject.embeddedObject = EmbeddedCustomObject()

        if let nestedObject = nestedObject {
            object.objectCol = nestedObject
            object.arrayCol.append(nestedObject)
            object.setCol.insert(nestedObject)
            object.mapCol["key"] = nestedObject
        }
        return object
    }

    static func createValues(primaryKey: ObjectId) -> [String: Any] {
        return [
            "pk": primaryKey,
            "intCol": 123,
            "anyCol": AnyRealmValue.int(345),
            "intEnumCol": IntEnum.value2,
            "objectCol": OldCustomObject(),
            "arrayCol": [OldCustomObject()],
            "setCol": [OldCustomObject()],
            "mapCol": ["key": OldCustomObject()],
            "embeddedObject": EmbeddedCustomObject(),
            "arrayIntCol": [123],
            "setIntCol": [345],
            "mapIntCol": ["key": 123]
        ]
    }
}

let propertiesEmbeddedCustomMapping: [String: String] = {
    ["intCol": "custom_intCol"]
}()

class EmbeddedCustomObject: EmbeddedObject {
    @objc dynamic var intCol = 123

    override class func propertiesMapping() -> [String: String] {
        propertiesEmbeddedCustomMapping
    }
}

// MARK: - Schema Discovery

class CustomColumnNamesSchemaTest: TestCase, @unchecked Sendable {
    func testCustomColumnNameSchema() {
        let modernCustomObjectSchema = ModernCustomObject().objectSchema
        for property in modernCustomObjectSchema.properties {
            XCTAssertEqual(propertiesModernCustomMapping[property.name], property.columnName)
        }

        let modernEmbeddedCustomObjectSchema = EmbeddedModernCustomObject().objectSchema
        for property in modernEmbeddedCustomObjectSchema.properties {
            XCTAssertEqual(propertiesModernEmbeddedCustomMapping[property.name], property.columnName)
        }

        let oldCustomObjectSchema = OldCustomObject().objectSchema
        for property in oldCustomObjectSchema.properties {
            XCTAssertEqual(propertiesCustomMapping[property.name], property.columnName)
        }

        let oldEmbeddedCustomObjectSchema = EmbeddedCustomObject().objectSchema
        for property in oldEmbeddedCustomObjectSchema.properties {
            XCTAssertEqual(propertiesEmbeddedCustomMapping[property.name], property.columnName)
        }
    }

    func testDescriptionWithCustomColumnName() {
        let modernCustomObjectSchema = ModernCustomObject().objectSchema
        let modernObjectExpected = """
        ModernCustomObject {
            pk {
                type = object id;
                columnName = custom_pk;
                indexed = YES;
                isPrimary = YES;
                array = NO;
                set = NO;
                dictionary = NO;
                optional = NO;
            }
            intCol {
                type = int;
                columnName = custom_intCol;
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = NO;
                dictionary = NO;
                optional = NO;
            }
            anyCol {
                type = mixed;
                columnName = custom_anyCol;
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = NO;
                dictionary = NO;
                optional = NO;
            }
            intEnumCol {
                type = int;
                columnName = custom_intEnumCol;
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = NO;
                dictionary = NO;
                optional = NO;
            }
            objectCol {
                type = object;
                objectClassName = ModernCustomObject;
                linkOriginPropertyName = (null);
                columnName = custom_objectCol;
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = NO;
                dictionary = NO;
                optional = YES;
            }
            arrayCol {
                type = object;
                objectClassName = ModernCustomObject;
                linkOriginPropertyName = (null);
                columnName = custom_arrayCol;
                indexed = NO;
                isPrimary = NO;
                array = YES;
                set = NO;
                dictionary = NO;
                optional = NO;
            }
            setCol {
                type = object;
                objectClassName = ModernCustomObject;
                linkOriginPropertyName = (null);
                columnName = custom_setCol;
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = YES;
                dictionary = NO;
                optional = NO;
            }
            mapCol {
                type = object;
                objectClassName = ModernCustomObject;
                linkOriginPropertyName = (null);
                columnName = custom_mapCol;
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = NO;
                dictionary = YES;
                optional = YES;
            }
            embeddedObject {
                type = object;
                objectClassName = EmbeddedModernCustomObject;
                linkOriginPropertyName = (null);
                columnName = custom_embeddedObject;
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = NO;
                dictionary = NO;
                optional = YES;
            }
            arrayIntCol {
                type = int;
                columnName = custom_arrayIntCol;
                indexed = NO;
                isPrimary = NO;
                array = YES;
                set = NO;
                dictionary = NO;
                optional = NO;
            }
            setIntCol {
                type = int;
                columnName = custom_setIntCol;
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = YES;
                dictionary = NO;
                optional = NO;
            }
            mapIntCol {
                type = int;
                columnName = custom_mapIntCol;
                indexed = NO;
                isPrimary = NO;
                array = NO;
                set = NO;
                dictionary = YES;
                optional = NO;
            }
        }
        """
        XCTAssertEqual(modernCustomObjectSchema.description, modernObjectExpected.replacingOccurrences(of: "    ", with: "\t"))
    }
}

class CustomColumnModernDynamicObjectTest: TestCase, @unchecked Sendable {
    var realm: Realm!

    override func setUp() {
        super.setUp()
        realm = inMemoryRealm("CustomColumnTests")
        let object = ModernCustomObject.create(primaryKey: ObjectId("6058f12682b2fbb1f334ef1d"), nestedObject: nil)
        object.anyCol = .object(ModernCustomObject())
        try! realm.write {
            realm.add(object)
        }
    }

    override func tearDown() {
        realm = nil
        super.tearDown()
    }

    func testCustomColumnDynamicObjectSubscript() throws {
        let object = realm.object(ofType: ModernCustomObject.self, forPrimaryKey: ObjectId("6058f12682b2fbb1f334ef1d"))!
        guard let dynamicObject: DynamicObject = object.anyCol.dynamicObject else {
            return XCTFail("DynamicObject does not exist")
        }

        // Set Value / Get Value
        try realm.write {
            dynamicObject[_name(for: \ModernCustomObject.intCol)] = 56789
        }
        XCTAssertEqual(dynamicObject[_name(for: \ModernCustomObject.intCol)] as! Int, 56789)
    }

    func testCustomColumnDynamicObjectSetValue() throws {
        let dynamicObjects = realm.dynamicObjects("ModernCustomObject")
        XCTAssertEqual(dynamicObjects.count, 2)
        let dynamicObject = dynamicObjects.first!
        XCTAssertNotNil(dynamicObject)

        try realm.write {
            dynamicObject.setValue(45678, forUndefinedKey: _name(for: \ModernCustomObject.intCol))
        }
        XCTAssertEqual(dynamicObject.value(forUndefinedKey: _name(for: \ModernCustomObject.intCol)) as! Int, 45678)
    }

    func testCustomColumnDynamicObjectMemberLookUp() throws {
        let dynamicObjects = realm.dynamicObjects("ModernCustomObject")
        XCTAssertEqual(dynamicObjects.count, 2)
        let dynamicObject = dynamicObjects.first!
        XCTAssertNotNil(dynamicObject)

        try realm.write {
            dynamicObject.intCol = 98765
        }
        XCTAssertEqual( dynamicObject.intCol as! Int, 98765)
    }

    func testCustomColumnDynamicSchema() throws {
        let dynamicObjects = realm.dynamicObjects("ModernCustomObject")
        XCTAssertEqual(dynamicObjects.count, 2)
        let dynamicObject = dynamicObjects.first!
        XCTAssertNotNil(dynamicObject)

        let schema = dynamicObject.objectSchema
        for property in schema.properties {
            XCTAssertEqual(propertiesModernCustomMapping[property.name], property.columnName)
        }
    }
}

class CustomColumnTestsBase<O: CustomColumnObjectFactory, F: CustomColumnTypeFactoryBase>: TestCase, @unchecked Sendable where O.Root == F.Root {
    var realm: Realm!
    public var notificationTokens: [NotificationToken] = []

    var object: O.Root!
    var nestedObject: O.Root!
    var primaryKey: ObjectId!

    override func setUp() {
        realm = inMemoryRealm("CustomColumnTests")
        try! realm.write {
            primaryKey = ObjectId("61184062c1d8f096a3695045")
            nestedObject = O.create(primaryKey: ObjectId.generate(), nestedObject: nil)
            object = O.create(primaryKey: primaryKey, nestedObject: nestedObject)
            for (keyPath, value) in F.keyPaths {
                object.setValue(value, forKeyPath: _name(for: keyPath))
            }
            realm.add(object)
        }
    }

    override func tearDown() {
        object = nil
        realm = nil
        for token in notificationTokens {
            token.invalidate()
        }
        notificationTokens = []
    }

    func setValue(_ value: F.ValueType, for keyPath: KeyPath<O.Root, F.ValueType>) throws {
        try realm.write {
            let keyPathString = _name(for: keyPath)
            if keyPathString.components(separatedBy: ".").count > 1 {
                nestedObject[keyPathString.components(separatedBy: ".").last!] = value
            } else {
                object[keyPathString] = value
            }
        }
    }

    override func invokeTest() {
        autoreleasepool { super.invokeTest() }
    }
}

class CustomColumnResultsTestBase<O: CustomColumnObjectFactory, F: CustomColumnTypeFactoryBase>: CustomColumnTestsBase<O, F>, @unchecked Sendable where O.Root == F.Root, F.ValueType: Equatable {
    var results: Results<O.Root>!

    override func setUp() {
        super.setUp()
        results = realm.objects(O.Root.self)
    }

    override func tearDown() {
        results = nil
        super.tearDown()
    }
}

class CustomColumnResultsTest<O: CustomColumnObjectFactory, F: CustomColumnResultsTypeFactory>: CustomColumnResultsTestBase<O, F>, @unchecked Sendable where O.Root == F.Root, F.ValueType: Equatable {
    // MARK: - Create Object

    func testCustomColumnResultsCreate() throws {
        let primaryKey = ObjectId.generate()
        let objectValues = O.createValues(primaryKey: primaryKey)
        try realm.write {
            realm.create(O.Root.self, value: objectValues)
        }
        XCTAssertNotNil(realm.object(ofType: O.Root.self, forPrimaryKey: primaryKey))
    }

    // MARK: - Results Queries

    func testCustomColumnResultsByPrimaryKey() throws {
        XCTAssertEqual(realm.object(ofType: O.Root.self, forPrimaryKey: primaryKey), object)
    }

    // MARK: - Results Queries

    func testCustomColumnResultsQueries() throws {
        // Assert Queries
        for (keyPath, query) in F.query {
            assertQuery(query, keyPath: keyPath, expectedCount: 1)
        }
    }

    func testCustomColumnResultsIndexMatching() throws {
        // Assert Query Index Matching
        for (_, query) in F.query {
            assertIndexMatching(query, expectedIndex: 0)
        }
    }

    // MARK: - Results Distinct & Sort

    func testCustomColumnResultsDistinct() throws {
        // Distinct by KeyPath
        for (keyPath, count) in F.distincts {
            assertDistinct(for: keyPath, count: count)
        }
    }

    func testCustomColumnResultsSort() throws {
        let object2 = O.create(primaryKey: ObjectId.generate(), nestedObject: O.create(primaryKey: ObjectId.generate(), nestedObject: nil))
        try realm.write {
            realm.add(object2)
        }
        // Sort by KeyPath
        for (keyPath, value) in F.sort {
            try realm.write {
                object2.setValue(value, forKeyPath: _name(for: keyPath))
            }
            assertSort(for: keyPath, value: value)
        }
    }

    // MARK: - Get/Set ValueForKey

    func testCustomColumnResultsSetGetValueForKey() throws {
        for (keyPath, value) in F.values {
            try realm.write {
                results.setValue(value, forKey: _name(for: keyPath))

                let valuesForKey = results.value(forKey: _name(for: keyPath)) as! [F.ValueType]
                XCTAssertNotNil(valuesForKey)
            }
        }
    }

    func testCustomColumnResultsGetValueForKeyPath() throws {
        for (keyPath, _) in F.keyPaths {
            let valuesForKeyPath = results.value(forKeyPath: _name(for: keyPath)) as! [F.ValueType?]
            XCTAssertNotNil(valuesForKeyPath)
        }
    }

    // MARK: - Observation

    func testCustomColumnResultsPropertyObservation() throws {
        for (keyPath, value) in F.values {
            let ex = XCTestExpectation(description: "Notification to be called")
            let notificationToken = results.observe(keyPaths: [keyPath]) { changes in
                switch changes {
                case .update(_, _, _, let modifications):
                    XCTAssertGreaterThan(modifications.count, 0)
                    ex.fulfill()
                case .initial: break
                default:
                    XCTFail("No other changes are done to the object")
                }
            }
            notificationTokens.append(notificationToken)
            try setValue(value, for: keyPath)

            wait(for: [ex], timeout: 1.0)
        }
    }

    // MARK: - Private

    private func assertQuery(_ query: ((Query<O.Root>) -> Query<Bool>),
                             keyPath: PartialKeyPath<O.Root>,
                             expectedCount: Int) {
        // TSQ
        let tsqResults: Results<O.Root> = results.where(query)
        XCTAssertEqual(tsqResults.count, expectedCount)

        let (queryStr, constructedValues) = query(Query<O.Root>._constructForTesting())._constructPredicate()

        // NSPredicate
        let predicate = NSPredicate(format: queryStr, argumentArray: constructedValues)
        let predicateResults: Results<O.Root> = results.filter(predicate)
        XCTAssertEqual(predicateResults.count, expectedCount)
    }

    private func assertIndexMatching(_ query: ((Query<O.Root>) -> Query<Bool>),
                                     expectedIndex: Int?) {
        let indexOf = results.index(matching: query)
        XCTAssertEqual(indexOf, expectedIndex)
    }

    private func assertDistinct(for keyPath: PartialKeyPath<O.Root>,
                                count expectedCount: Int) {
        let distincts = results.distinct(by: [_name(for: keyPath)])
        XCTAssertEqual(distincts.count, expectedCount)
    }

    private func assertSort(for keyPath: PartialKeyPath<O.Root>,
                            value expectedValue: F.ValueType) {
        let sortDescriptor = SortDescriptor(keyPath: _name(for: keyPath), ascending: true)
        let results: Results<O.Root> = results.sorted(by: [sortDescriptor])
        let sortValue = results.first![keyPath: keyPath] as! F.ValueType
        XCTAssertEqual(sortValue, expectedValue)
    }
}

class CustomColumnResultsAggregatesTest<O: CustomColumnObjectFactory, F: CustomColumnAggregatesTypeFactory>: CustomColumnResultsTestBase<O, F>, @unchecked Sendable where O.Root == F.Root, F.ValueType: Equatable {
    // MARK: - Aggregates

    func testCustomColumnResultsAggregateAvg() throws {
        // Sort by KeyPath
        for (keyPath, value) in F.average {
            assertAverage(for: keyPath, value: value)
        }
    }

    func testCustomColumnResultsAggregateSum() throws {
        // Sum by KeyPath
        for (keyPath, value) in F.sum {
            assertSum(for: keyPath, value: value)
        }
    }

    func testCustomColumnResultsAggregateMax() throws {
        // Max by KeyPath
        for (keyPath, value) in F.max {
            assertMax(for: keyPath, value: value)
        }
    }

    func testCustomColumnResultsAggregateMin() throws {
        // Min by KeyPath
        for (keyPath, value) in F.min {
            assertMin(for: keyPath, value: value)
        }
    }

    // MARK: - Private

    private func assertAverage(for keyPath: KeyPath<O.Root, F.ValueType>, value: F.ValueType) {
        XCTAssertEqual(results.average(of: keyPath), value)
        let average: F.ValueType? = results.average(ofProperty: _name(for: keyPath))
        XCTAssertEqual(average, value)
    }

    private func assertSum(for keyPath: KeyPath<O.Root, F.ValueType>, value: F.ValueType) {
        XCTAssertEqual(results.sum(of: keyPath), value)
        let average: F.ValueType? = results.sum(ofProperty: _name(for: keyPath))
        XCTAssertEqual(average, value)
    }

    private func assertMax(for keyPath: KeyPath<O.Root, F.ValueType>, value: F.ValueType) {
        XCTAssertEqual(results.max(of: keyPath), value)
        let average: F.ValueType? = results.max(ofProperty: _name(for: keyPath))
        XCTAssertEqual(average, value)
    }

    private func assertMin(for keyPath: KeyPath<O.Root, F.ValueType>, value: F.ValueType) {
        XCTAssertEqual(results.min(of: keyPath), value)
        let average: F.ValueType? = results.min(ofProperty: _name(for: keyPath))
        XCTAssertEqual(average, value)
    }
}

class CustomColumnResultsSectionedTest<O: CustomColumnObjectFactory, F: CustomColumnResultsSectionedTypeFactory>: CustomColumnResultsTestBase<O, F>, @unchecked Sendable where O.Root == F.Root {
    // MARK: - Sectioned

    func testCustomColumnSectionedResults() throws {
        for (keyPath, sectionCount) in F.sectioned {
            let sectioned = results.sectioned(by: keyPath, ascending: true)
            XCTAssertEqual(sectioned.allKeys.count, sectionCount)
            for section in sectioned {
                XCTAssertEqual(section.count, 1)
            }
        }
    }
}

class CustomColumnObjectTest<O: CustomColumnObjectFactory, F: ObjectCustomColumnObjectTypeFactory>: CustomColumnTestsBase<O, F>, @unchecked Sendable where O: ObjectBase, O.Root == F.Root, F.ValueType: Equatable {
    // MARK: - Subscript

    func testCustomColumnObjectKVC() throws {
        for (keyPath, value) in F.propertyValues {
            try setValue(value, for: keyPath)
        }
    }

    // MARK: - Dynamic Listing

    func testCustomColumnObjectDynamicListing() throws {
        for (keyPath, count) in F.dynamicListProperty {
            XCTAssertEqual(object.dynamicList(_name(for: keyPath)).count, count)
        }
    }

    func testCustomColumnObjectDynamicMutableSet() throws {
        for (keyPath, count) in F.dynamicMutableSetProperty {
            XCTAssertEqual(object.dynamicMutableSet(_name(for: keyPath)).count, count)
        }
    }

    // MARK: - Observation

    func testCustomColumnObjectPropertyObservation() throws {
        for (keyPath, value) in F.propertyValues {
            let ex = XCTestExpectation(description: "Notification to be called")
            let notificationToken = object.observe(keyPaths: [keyPath]) { changes in
                switch changes {
                case .change(_, let propertyChanges):
                    XCTAssertGreaterThan(propertyChanges.count, 0)
                    ex.fulfill()
                default:
                    XCTFail("No other changes are done to the object")
                }
            }
            notificationTokens.append(notificationToken)
            try setValue(value, for: keyPath)

            wait(for: [ex], timeout: 1.0)
        }
    }

    // MARK: - Private

    private func assertObjectGetKVCProperty(for keyPath: KeyPath<O.Root, F.ValueType>) {
        let value: F.ValueType = object[_name(for: keyPath)] as! F.ValueType
        XCTAssertNotNil(value)
    }
}

class CustomColumnKeyedObjectTest<O: CustomColumnObjectFactory, F: ObjectCustomColumnObjectTypeFactory>: CustomColumnTestsBase<O, F>, @unchecked Sendable where O: ObjectBase, O.Root == F.Root, F.ValueType: RealmKeyedCollection {
    func testCustomColumnObjectDynamicMap() throws {
        func testCustomColumnObjectDynamicMap() throws {
            for (keyPath, count) in F.dynamicMutableSetProperty {
                let map: Map<String, DynamicObject?> = object.dynamicMap(_name(for: keyPath))
                XCTAssertEqual(map.count, count)
            }
        }
    }
}

class CustomColumnListTest<O: CustomColumnObjectFactory, F: CustomColumnTypeFactoryBase>: CustomColumnTestsBase<O, F>, @unchecked Sendable where O.Root == F.Root, F.ValueType: RealmCollectionValue {
    var list: List<O.Root>!

    override func setUp() {
        super.setUp()

        var listObjects: [O.Root] = []
        for _ in 0...2 {
            let newObject = O.create(primaryKey: ObjectId.generate(), nestedObject: O.create(primaryKey: ObjectId.generate(), nestedObject: nil))
            for (keyPath, value) in F.keyPaths {
                newObject[_name(for: keyPath)] = value
            }
            listObjects.append(newObject)
        }

        try! realm.write {
            object[_name(for: F.listKeyPath)] = listObjects
        }
        list = object[_name(for: F.listKeyPath)] as? List<O.Root>
    }

    override func tearDown() {
        list = nil
        super.tearDown()
    }

    // MARK: - ValueForKey

    func testCustomColumnListGetValueForKey() throws {
        for (keyPath, value) in F.keyPaths {
            let valuesArray: [AnyObject] = list.value(forKey: _name(for: keyPath))
            let expectedArray = valuesArray as! [F.ValueType]
            XCTAssertEqual(expectedArray.count, 3)
            XCTAssertEqual(expectedArray.first!, value)

            let valuesArrayKeyPath: [AnyObject] = list.value(forKeyPath: _name(for: keyPath))
            let expectedArrayKeyPath = valuesArrayKeyPath as! [F.ValueType]
            XCTAssertEqual(expectedArrayKeyPath.count, 3)
            XCTAssertEqual(expectedArrayKeyPath.first!, value)
        }
    }
}

class CustomColumnSetTest<O: CustomColumnObjectFactory, F: CustomColumnTypeFactoryBase>: CustomColumnTestsBase<O, F>, @unchecked Sendable where O.Root == F.Root, F.ValueType: RealmCollectionValue {
    var set: MutableSet<O.Root>!

    override func setUp() {
        super.setUp()

        let setObjects: MutableSet<O.Root> = MutableSet<O.Root>()
        for _ in 0...2 {
            let newObject = O.create(primaryKey: ObjectId.generate(), nestedObject: O.create(primaryKey: ObjectId.generate(), nestedObject: nil))
            for (keyPath, value) in F.keyPaths {
                newObject[_name(for: keyPath)] = value
            }
            setObjects.insert(newObject)
        }

        try! realm.write {
            object[_name(for: F.setKeyPath)] = setObjects
        }
        set = object[_name(for: F.setKeyPath)] as? MutableSet<O.Root>
    }

    override func tearDown() {
        set = nil
        super.tearDown()
    }

    // MARK: - ValueForKey

    func testCustomColumnListGetValueForKey() throws {
        for (keyPath, value) in F.keyPaths {
            let valuesSet: [AnyObject]  = set.value(forKey: _name(for: keyPath))
            let expectedSet = valuesSet as! [F.ValueType]
            XCTAssertEqual(expectedSet.count, 1)
            XCTAssertEqual(expectedSet.first!, value)
        }
    }
}

class CustomColumnMapTestBase<O: CustomColumnObjectFactory, F: CustomColumnMapTypeBaseFactory>: CustomColumnTestsBase<O, F>, @unchecked Sendable where O.Root == F.Root {
    var map: Map<String, O.Root?>!

    override func setUp() {
        super.setUp()

        let mapObjects: Map<String, O.Root> = Map<String, O.Root>()
        for (key, (keyPath, value)) in F.keyValues {
            let newObject = O.create(primaryKey: ObjectId.generate(), nestedObject: O.create(primaryKey: ObjectId.generate(), nestedObject: nil))
            newObject[_name(for: keyPath)] = value
            mapObjects[key] = newObject
        }

        try! realm.write {
            object[_name(for: F.mapKeyPath)] = mapObjects
        }
        map = object[_name(for: F.mapKeyPath)] as? Map<String, O.Root?>
    }

    override func tearDown() {
        map = nil
        super.tearDown()
    }
}

class CustomColumnMapTest<O: CustomColumnObjectFactory, F: CustomColumnMapTypeFactory>: CustomColumnMapTestBase<O, F>, @unchecked Sendable where O.Root == F.Root, F.ValueType: Equatable {
    // MARK: - ValueForKey

    func testCustomColumnMapGetValueForKey() throws {
        for (keyPath, value) in F.keyPaths {
            let valuesMap: AnyObject? = map.value(forKey: "key0")
            let expectedValue = valuesMap as! O.Root
            XCTAssertEqual(expectedValue[_name(for: keyPath)] as! F.ValueType, value)
        }
    }

    func testCustomColumnMapSetValueForKey() throws {
        for (keyPath, value) in F.values {
            try realm.write {
                let newObject = O.create(primaryKey: ObjectId.generate(), nestedObject: O.create(primaryKey: ObjectId.generate(), nestedObject: nil))
                newObject[_name(for: keyPath)] = value
                map.setValue(newObject, forKey: "key0")
            }

            let valuesMapKeyPath: AnyObject? = map.value(forKeyPath: "key0")
            let expectedKeyPathValue = valuesMapKeyPath as! O.Root
            XCTAssertEqual(expectedKeyPathValue[_name(for: keyPath)] as! F.ValueType, value)
        }
    }

    // MARK: - Observation

    func testCustomColumnMapPropertyObservation() throws {
        for (keyPath, value) in F.values {
            let ex = XCTestExpectation(description: "Notification to be called")
            let notificationToken = map.observe(keyPaths: [_name(for: keyPath)]) { changes in
                switch changes {
                case .update(_, _, _, let mapChanges):
                    XCTAssertEqual(mapChanges.count, 1)
                    ex.fulfill()
                case .initial: break
                default:
                    XCTFail("No other changes are done to the object")
                }
            }
            notificationTokens.append(notificationToken)

            try realm.write {
                let map = object[_name(for: F.mapKeyPath)] as! Map<String, O.Root?>
                let mapObject = map["key0"]
                mapObject!![_name(for: keyPath)] = value
            }
            wait(for: [ex], timeout: 1.0)
        }
    }

    func testCustomColumnMapSortedObservation() throws {
        for (keyPath, value) in F.sort {
            let mapSorted: Results<O.Root?> = map.sorted(byKeyPath: _name(for: keyPath), ascending: true)
            XCTAssertEqual(mapSorted.first!![_name(for: keyPath)] as! F.ValueType, value)
        }
    }
}

class CustomColumnAggregatesMapTest<O: CustomColumnObjectFactory, F: CustomColumnMapAggregatesTypeFactory>: CustomColumnMapTestBase<O, F>, @unchecked Sendable where O.Root == F.Root, F.ValueType: RealmCollectionValue {
    // MARK: - Aggregates

    func testCustomColumnResultsAggregateAvg() throws {
        // Sort by KeyPath
        for (keyPath, value) in F.average {
            assertAverage(for: keyPath, value: value)
        }
    }

    func testCustomColumnResultsAggregateSum() throws {
        // Sum by KeyPath
        for (keyPath, value) in F.sum {
            assertSum(for: keyPath, value: value)
        }
    }

    func testCustomColumnResultsAggregateMax() throws {
        // Max by KeyPath
        for (keyPath, value) in F.max {
            assertMax(for: keyPath, value: value)
        }
    }

    func testCustomColumnResultsAggregateMin() throws {
        // Min by KeyPath
        for (keyPath, value) in F.min {
            assertMin(for: keyPath, value: value)
        }
    }

    // MARK: - Private

    private func assertAverage(for keyPath: KeyPath<O.Root, F.ValueType>, value: F.ValueType) {
        XCTAssertEqual(map.average(of: keyPath), value)
        let average: F.ValueType? = map.average(ofProperty: _name(for: keyPath))
        XCTAssertEqual(average, value)
    }

    private func assertSum(for keyPath: KeyPath<O.Root, F.ValueType>, value: F.ValueType) {
        XCTAssertEqual(map.sum(of: keyPath), value)
        let average: F.ValueType? = map.sum(ofProperty: _name(for: keyPath))
        XCTAssertEqual(average, value)
    }

    private func assertMax(for keyPath: KeyPath<O.Root, F.ValueType>, value: F.ValueType) {
        XCTAssertEqual(map.max(of: keyPath), value)
        let average: F.ValueType? = map.max(ofProperty: _name(for: keyPath))
        XCTAssertEqual(average, value)
    }

    private func assertMin(for keyPath: KeyPath<O.Root, F.ValueType>, value: F.ValueType) {
        XCTAssertEqual(map.min(of: keyPath), value)
        let average: F.ValueType? = map.min(ofProperty: _name(for: keyPath))
        XCTAssertEqual(average, value)
    }
}

class CustomObjectTests: TestCase, @unchecked Sendable {
    override class var defaultTestSuite: XCTestSuite {
        let suite = XCTestSuite(name: "CustomColumnNameTests")

        // MARK: - Results
        // ModernCustomObject
        CustomColumnResultsTest<ModernCustomObject, ModernResultsIntType>.defaultTestSuite.tests.forEach(suite.addTest)
        CustomColumnResultsTest<ModernCustomObject, ModernListResultsIntType>.defaultTestSuite.tests.forEach(suite.addTest)
        CustomColumnResultsTest<ModernCustomObject, ModernMutableSetResultsIntType>.defaultTestSuite.tests.forEach(suite.addTest)
        CustomColumnResultsTest<ModernCustomObject, ModernMapResultsIntType>.defaultTestSuite.tests.forEach(suite.addTest)

        // OldCustomObject
        CustomColumnResultsTest<OldCustomObject, OldResultsIntType>.defaultTestSuite.tests.forEach(suite.addTest)
        CustomColumnResultsTest<OldCustomObject, OldListResultsIntType>.defaultTestSuite.tests.forEach(suite.addTest)
        CustomColumnResultsTest<OldCustomObject, OldMutableSetResultsIntType>.defaultTestSuite.tests.forEach(suite.addTest)
        CustomColumnResultsTest<OldCustomObject, OldMapResultsIntType>.defaultTestSuite.tests.forEach(suite.addTest)

        // MARK: - Results Aggregates
        // ModernCustomObject
        CustomColumnResultsAggregatesTest<ModernCustomObject, ModernResultsIntType>.defaultTestSuite.tests.forEach(suite.addTest)

        // OldCustomObject
        CustomColumnResultsAggregatesTest<OldCustomObject, OldResultsIntType>.defaultTestSuite.tests.forEach(suite.addTest)

        // MARK: - Results Sectioned
        // ModernCustomObject
        CustomColumnResultsSectionedTest<ModernCustomObject, ModernResultsIntType>.defaultTestSuite.tests.forEach(suite.addTest)

        // OldCustomObject
        CustomColumnResultsSectionedTest<OldCustomObject, OldResultsIntType>.defaultTestSuite.tests.forEach(suite.addTest)

        // MARK: - Object
        // ModernCustomObject
        CustomColumnObjectTest<ModernCustomObject, ModernResultsIntType>.defaultTestSuite.tests.forEach(suite.addTest)
        CustomColumnObjectTest<ModernCustomObject, ModernListResultsIntType>.defaultTestSuite.tests.forEach(suite.addTest)
        CustomColumnObjectTest<ModernCustomObject, ModernMutableSetResultsIntType>.defaultTestSuite.tests.forEach(suite.addTest)
        CustomColumnObjectTest<ModernCustomObject, ModernMapResultsIntType>.defaultTestSuite.tests.forEach(suite.addTest)

        // OldCustomObject
        CustomColumnObjectTest<OldCustomObject, OldResultsIntType>.defaultTestSuite.tests.forEach(suite.addTest)
        CustomColumnObjectTest<OldCustomObject, OldListResultsIntType>.defaultTestSuite.tests.forEach(suite.addTest)
        CustomColumnObjectTest<OldCustomObject, OldMutableSetResultsIntType>.defaultTestSuite.tests.forEach(suite.addTest)
        CustomColumnObjectTest<OldCustomObject, OldMapResultsIntType>.defaultTestSuite.tests.forEach(suite.addTest)

        // MARK: - Object Keyed Property
        // ModernCustomObject
        CustomColumnKeyedObjectTest<ModernCustomObject, ModernMapResultsIntType>.defaultTestSuite.tests.forEach(suite.addTest)

        // OldCustomObject
        CustomColumnKeyedObjectTest<OldCustomObject, OldMapResultsIntType>.defaultTestSuite.tests.forEach(suite.addTest)

        // MARK: - List
        // ModernCustomObject
        CustomColumnListTest<ModernCustomObject, ModernListIntType>.defaultTestSuite.tests.forEach(suite.addTest)

        // OldCustomObject
        CustomColumnListTest<OldCustomObject, OldListIntType>.defaultTestSuite.tests.forEach(suite.addTest)

        // MARK: - MutableSet
        // ModernCustomObject
        CustomColumnSetTest<ModernCustomObject, ModernSetIntType>.defaultTestSuite.tests.forEach(suite.addTest)

        // OldCustomObject
        CustomColumnSetTest<OldCustomObject, OldSetIntType>.defaultTestSuite.tests.forEach(suite.addTest)

        // MARK: - Map
        // ModernCustomObject
        CustomColumnMapTest<ModernCustomObject, ModernMapIntType>.defaultTestSuite.tests.forEach(suite.addTest)
        CustomColumnAggregatesMapTest<ModernCustomObject, ModernMapIntType>.defaultTestSuite.tests.forEach(suite.addTest)

        // OldCustomObject
        CustomColumnMapTest<OldCustomObject, OldMapIntType>.defaultTestSuite.tests.forEach(suite.addTest)
        CustomColumnAggregatesMapTest<OldCustomObject, OldMapIntType>.defaultTestSuite.tests.forEach(suite.addTest)
        return suite
    }
}

// MARK: - Custom Column Tests Factory

protocol CustomColumnTypeFactoryBase {
    associatedtype Root
    associatedtype ValueType

    static var keyPaths: [KeyPath<Root, ValueType>: ValueType] { get }

    static var listKeyPath: PartialKeyPath<Root> { get }
    static var setKeyPath: PartialKeyPath<Root> { get }
    static var mapKeyPath: PartialKeyPath<Root> { get }
}

protocol CustomColumnResultsTypeFactory: CustomColumnTypeFactoryBase {
    static var query: [KeyPath<Root, ValueType>: (Query<Root>) -> Query<Bool>] { get }
    static var distincts: [KeyPath<Root, ValueType>: Int] { get }
    static var sort: [KeyPath<Root, ValueType>: ValueType] { get }
    static var values: [KeyPath<Root, ValueType>: ValueType] { get }
}

protocol CustomColumnAggregatesTypeFactory: CustomColumnTypeFactoryBase where ValueType: _HasPersistedType, ValueType.PersistedType: AddableType & MinMaxType {
    // Nested keyPaths are not available in Aggregates
    static var average: [KeyPath<Root, ValueType>: ValueType] { get }
    static var sum: [KeyPath<Root, ValueType>: ValueType] { get }
    static var max: [KeyPath<Root, ValueType>: ValueType] { get }
    static var min: [KeyPath<Root, ValueType>: ValueType] { get }
}

protocol CustomColumnResultsSectionedTypeFactory: CustomColumnTypeFactoryBase where ValueType: _Persistable & Hashable {
    static var sectioned: [KeyPath<Root, ValueType>: Int] { get }
}

protocol ObjectCustomColumnObjectTypeFactory: CustomColumnTypeFactoryBase {
    // Nested keyPaths are not available in Object Subscripts/Observation
    static var propertyValues: [KeyPath<Root, ValueType>: ValueType] { get }
    static var dynamicListProperty: [KeyPath<Root, ValueType>: Int] { get }
    static var dynamicMutableSetProperty: [KeyPath<Root, ValueType>: Int] { get }
}

protocol CustomColumnMapTypeBaseFactory: CustomColumnTypeFactoryBase {
    static var keyValues: [String: (KeyPath<Root, ValueType>, ValueType)] { get }
}

protocol CustomColumnObjectKeyedTypeFactory: CustomColumnTypeFactoryBase where ValueType: RealmKeyedCollection {
    static var dynamicMapValue: [KeyPath<Root, ValueType>: Int] { get }
}

protocol CustomColumnMapTypeFactory: CustomColumnMapTypeBaseFactory {
    static var values: [KeyPath<Root, ValueType>: ValueType] { get }
    static var sort: [KeyPath<Root, ValueType>: ValueType] { get }
}

protocol CustomColumnMapAggregatesTypeFactory: CustomColumnMapTypeBaseFactory, CustomColumnAggregatesTypeFactory {}

// MARK: - ModernCustom Object Factory

struct ModernResultsIntType: CustomColumnResultsTypeFactory {
    typealias Root = ModernCustomObject
    typealias ValueType = Int

    static var listKeyPath: PartialKeyPath<ModernCustomObject> { fatalError() } // Not Applicable
    static var setKeyPath: PartialKeyPath<ModernCustomObject> { fatalError() } // Not Applicable
    static var mapKeyPath: PartialKeyPath<ModernCustomObject> { fatalError() } // Not Applicable

    static var keyPaths: [KeyPath<ModernCustomObject, Int>: Int] {
        [\ModernCustomObject.intCol: 123,
          \ModernCustomObject.objectCol!.intCol: 345,
          \ModernCustomObject.embeddedObject!.intCol: 567,
          \ModernCustomObject.objectCol!.embeddedObject!.intCol: 789]
    }

    static var query: [KeyPath<ModernCustomObject, Int>: (Query<ModernCustomObject>) -> Query<Bool>] {
        [\ModernCustomObject.intCol: { $0.intCol == 123 },
          \ModernCustomObject.objectCol!.intCol: { $0.objectCol.intCol == 345 },
          \ModernCustomObject.embeddedObject!.intCol: { $0.embeddedObject.intCol == 567 },
          \ModernCustomObject.objectCol!.embeddedObject!.intCol: { $0.objectCol.embeddedObject.intCol == 789 }]
    }

    static var distincts: [KeyPath<ModernCustomObject, Int>: Int] {
        [\ModernCustomObject.intCol: 2,
          \ModernCustomObject.objectCol!.intCol: 1,
          \ModernCustomObject.embeddedObject!.intCol: 2,
          \ModernCustomObject.objectCol!.embeddedObject!.intCol: 1]
    }

    static var sort: [KeyPath<ModernCustomObject, Int>: Int] {
        [\ModernCustomObject.intCol: 0,
          \ModernCustomObject.objectCol!.intCol: 0,
          \ModernCustomObject.embeddedObject!.intCol: 0,
          \ModernCustomObject.objectCol!.embeddedObject!.intCol: 0]
    }

    static var propertyValues: [KeyPath<ModernCustomObject, Int>: Int] {
        [\ModernCustomObject.intCol: 111,
          \ModernCustomObject.objectCol!.intCol: 999]
    }
}

extension ModernResultsIntType: CustomColumnAggregatesTypeFactory {
    // Nested keyPaths are not available in Aggregates
    static var average: [KeyPath<ModernCustomObject, Int>: Int] {
        [\ModernCustomObject.intCol: 234]
    }

    static var sum: [KeyPath<ModernCustomObject, Int>: Int] {
        [\ModernCustomObject.intCol: 468]
    }

    static var max: [KeyPath<ModernCustomObject, Int>: Int] {
        [\ModernCustomObject.intCol: 345]
    }

    static var min: [KeyPath<ModernCustomObject, Int>: Int] {
        [\ModernCustomObject.intCol: 123]
    }
}

extension ModernResultsIntType: CustomColumnResultsSectionedTypeFactory {
    static var sectioned: [KeyPath<ModernCustomObject, Int>: Int] {
       [\ModernCustomObject.intCol: 2]
    }
}

extension ModernResultsIntType: ObjectCustomColumnObjectTypeFactory {
    static var values: [KeyPath<ModernCustomObject, Int>: Int] {
        [\ModernCustomObject.intCol: 256]
    }

    static var dynamicListProperty: [KeyPath<ModernCustomObject, Int>: Int] { [:] } // Not Applicable
    static var dynamicMutableSetProperty: [KeyPath<ModernCustomObject, Int>: Int] { [:] } // Not Applicable
}

struct ModernListResultsIntType: CustomColumnResultsTypeFactory {
    typealias Root = ModernCustomObject
    typealias ValueType = List<Int>

    static var listKeyPath: PartialKeyPath<ModernCustomObject> { fatalError() } // Not Applicable
    static var setKeyPath: PartialKeyPath<ModernCustomObject> { fatalError() } // Not Applicable
    static var mapKeyPath: PartialKeyPath<ModernCustomObject> { fatalError() } // Not Applicable

    static var keyPaths: [KeyPath<ModernCustomObject, List<Int>>: List<Int>] {
        let list = List<Int>()
        list.append(objectsIn: [123, 345, 567, 789, 901])
        return [\ModernCustomObject.arrayIntCol: list]
    }

    static var query: [KeyPath<ModernCustomObject, List<Int>>: (Query<ModernCustomObject>) -> Query<Bool>] {
        [\ModernCustomObject.arrayIntCol: { $0.arrayIntCol.contains(123) }]
    }

    static var distincts: [KeyPath<ModernCustomObject, List<Int>>: Int] { [:] } // Not Applicable
    static var sort: [KeyPath<ModernCustomObject, List<Int>>: ValueType] { [:] } // Not Applicable

    static var propertyValues: [KeyPath<ModernCustomObject, List<Int>>: List<Int>] {
        let list = List<Int>()
        list.append(objectsIn: [111, 222, 333, 444])
        return [\ModernCustomObject.arrayIntCol: list]
    }
}

extension ModernListResultsIntType: ObjectCustomColumnObjectTypeFactory {
    static var values: [KeyPath<ModernCustomObject, List<Int>>: List<Int>] {
        let list = List<Int>()
        list.append(objectsIn: [987, 765, 543, 321])
        return [\ModernCustomObject.arrayIntCol: list]
    }

    static var dynamicListProperty: [KeyPath<ModernCustomObject, List<Int>>: Int] {
        [\ModernCustomObject.arrayIntCol: 5]
    }

    static var dynamicMutableSetProperty: [KeyPath<ModernCustomObject, List<Int>>: Int] { [:] } // Not Applicable
}

struct ModernMutableSetResultsIntType: CustomColumnResultsTypeFactory {
    typealias Root = ModernCustomObject
    typealias ValueType = MutableSet<Int>

    static var listKeyPath: PartialKeyPath<ModernCustomObject> { fatalError() } // Not Applicable
    static var setKeyPath: PartialKeyPath<ModernCustomObject> { fatalError() } // Not Applicable
    static var mapKeyPath: PartialKeyPath<ModernCustomObject> { fatalError() } // Not Applicable

    static var keyPaths: [KeyPath<ModernCustomObject, MutableSet<Int>>: MutableSet<Int>] {
        let set = MutableSet<Int>()
        set.insert(objectsIn: [123, 345, 567, 789, 901])
        return [\ModernCustomObject.setIntCol: set]
    }

    static var query: [KeyPath<ModernCustomObject, MutableSet<Int>>: (Query<ModernCustomObject>) -> Query<Bool>] {
        [\ModernCustomObject.setIntCol: { $0.setIntCol.contains(123) }]
    }

    static var distincts: [KeyPath<ModernCustomObject, ValueType>: Int] { [:] } // Not Applicable
    static var sort: [KeyPath<ModernCustomObject, ValueType>: ValueType] { [:] } // Not Applicable

    static var propertyValues: [KeyPath<ModernCustomObject, MutableSet<Int>>: MutableSet<Int>] {
        let set = MutableSet<Int>()
        set.insert(objectsIn: [111, 222, 333, 444])
        return [\ModernCustomObject.setIntCol: set]
    }
}

extension ModernMutableSetResultsIntType: ObjectCustomColumnObjectTypeFactory {
    static var values: [KeyPath<ModernCustomObject, MutableSet<Int>>: MutableSet<Int>] {
        let set = MutableSet<Int>()
        set.insert(objectsIn: [987, 765, 543, 321])
        return [\ModernCustomObject.setIntCol: set]
    }

    static var dynamicListProperty: [KeyPath<ModernCustomObject, MutableSet<Int>>: Int] { [:] } // Not Applicable

    static var dynamicMutableSetProperty: [KeyPath<ModernCustomObject, MutableSet<Int>>: Int] {
        [\ModernCustomObject.setIntCol: 5]
    }
}

struct ModernMapResultsIntType: CustomColumnResultsTypeFactory {
    typealias Root = ModernCustomObject
    typealias ValueType = Map<String, Int>

    static var listKeyPath: PartialKeyPath<ModernCustomObject> { fatalError() } // Not Applicable
    static var setKeyPath: PartialKeyPath<ModernCustomObject> { fatalError() } // Not Applicable
    static var mapKeyPath: PartialKeyPath<ModernCustomObject> { fatalError() } // Not Applicable

    static var keyPaths: [KeyPath<ModernCustomObject, Map<String, Int>>: Map<String, Int>] {
        let map = Map<String, Int>()
        map["key"] = 123
        map["key1"] = 345
        map["key3"] = 567
        map["key3"] = 879
        return [\ModernCustomObject.mapIntCol: map]
    }

    static var query: [KeyPath<ModernCustomObject, ValueType>: (Query<ModernCustomObject>) -> Query<Bool>] {
        [\ModernCustomObject.mapIntCol: { $0.mapIntCol.keys.contains("key") }]
    }

    static var distincts: [KeyPath<ModernCustomObject, Map<String, Int>>: Int] { [:] } // Not Applicable
    static var sort: [KeyPath<ModernCustomObject, Map<String, Int>>: Map<String, Int>] { [:] } // Not Applicable

    static var propertyValues: [KeyPath<ModernCustomObject, Map<String, Int>>: Map<String, Int>] {
        let map = Map<String, Int>()
        map["key"] = 111
        map["key1"] = 222
        map["key3"] = 333
        map["key3"] = 444
        return [\ModernCustomObject.mapIntCol: map]
    }
}

extension ModernMapResultsIntType: ObjectCustomColumnObjectTypeFactory {
    static var values: [KeyPath<ModernCustomObject, Map<String, Int>>: Map<String, Int>] {
        let map = Map<String, Int>()
        map["key"] = 123
        map["key1"] = 345
        map["key3"] = 567
        map["key3"] = 879
        return [\ModernCustomObject.mapIntCol: map]
    }

    static var dynamicListProperty: [KeyPath<ModernCustomObject, Map<String, Int>>: Int] { [:] } // Not Applicable
    static var dynamicMutableSetProperty: [KeyPath<ModernCustomObject, Map<String, Int>>: Int] { [:] } // Not Applicable
}

extension ModernMapResultsIntType: CustomColumnObjectKeyedTypeFactory {
    static var dynamicMapValue: [KeyPath<ModernCustomObject, Map<String, Int>>: Int] {
        [\ModernCustomObject.mapIntCol: 5]
    }
}

struct ModernListIntType: CustomColumnTypeFactoryBase {
    typealias Root = ModernCustomObject
    typealias ValueType = Int

    static var listKeyPath: PartialKeyPath<ModernCustomObject> {
        \.arrayCol
    }

    static var setKeyPath: PartialKeyPath<ModernCustomObject> { fatalError() } // Not Applicable
    static var mapKeyPath: PartialKeyPath<ModernCustomObject> { fatalError() } // Not Applicable

    static var keyPaths: [KeyPath<ModernCustomObject, Int>: Int] {
        [\ModernCustomObject.intCol: 102]
    }
}

struct ModernSetIntType: CustomColumnTypeFactoryBase {
    typealias Root = ModernCustomObject
    typealias ValueType = Int

    static var setKeyPath: PartialKeyPath<ModernCustomObject> {
        \.setCol
    }

    static var listKeyPath: PartialKeyPath<ModernCustomObject> { fatalError() } // Not Applicable
    static var mapKeyPath: PartialKeyPath<ModernCustomObject> { fatalError() } // Not Applicable

    static var keyPaths: [KeyPath<ModernCustomObject, Int>: Int] {
       [\ModernCustomObject.intCol: 938]
    }
}

struct ModernMapIntType: CustomColumnMapTypeFactory {
    typealias Root = ModernCustomObject
    typealias ValueType = Int

    static var mapKeyPath: PartialKeyPath<ModernCustomObject> {
        \.mapCol
    }

    static var listKeyPath: PartialKeyPath<ModernCustomObject> { fatalError() } // Not Applicable
    static var setKeyPath: PartialKeyPath<ModernCustomObject> { fatalError() } // Not Applicable

    static var keyValues: [String: (KeyPath<Root, Int>, Int)] {
        ["key0": (\ModernCustomObject.intCol, 938),
         "key1": (\ModernCustomObject.intCol, 588),
         "key2": (\ModernCustomObject.intCol, 610)]
    }

    static var keyPaths: [KeyPath<ModernCustomObject, Int>: Int] {
        [\ModernCustomObject.intCol: 938]
    }

    static var values: [KeyPath<ModernCustomObject, Int>: Int] {
        [\ModernCustomObject.intCol: 1234]
    }

    static var sort: [KeyPath<Root, Int>: Int] {
        [\ModernCustomObject.intCol: 588]
    }
}

extension ModernMapIntType: CustomColumnMapAggregatesTypeFactory {
    static var average: [KeyPath<ModernCustomObject, Int>: Int] {
        [\ModernCustomObject.intCol: 712]
    }

    static var sum: [KeyPath<ModernCustomObject, Int>: Int] {
        [\ModernCustomObject.intCol: 2136]
    }

    static var max: [KeyPath<ModernCustomObject, Int>: Int] {
        [\ModernCustomObject.intCol: 938]
    }

    static var min: [KeyPath<ModernCustomObject, Int>: Int] {
        [\ModernCustomObject.intCol: 588]
    }
}

// MARK: - Old Object Factory

struct OldResultsIntType: CustomColumnResultsTypeFactory {
    typealias Root = OldCustomObject
    typealias ValueType = Int

    static var listKeyPath: PartialKeyPath<OldCustomObject> { fatalError() } // Not Applicable
    static var setKeyPath: PartialKeyPath<OldCustomObject> { fatalError() } // Not Applicable
    static var mapKeyPath: PartialKeyPath<OldCustomObject> { fatalError() } // Not Applicable

    static var keyPaths: [KeyPath<OldCustomObject, Int>: Int] {
        [\OldCustomObject.intCol: 12,
          \OldCustomObject.objectCol!.intCol: 24,
          \OldCustomObject.embeddedObject!.intCol: 36,
          \OldCustomObject.objectCol!.embeddedObject!.intCol: 48]
    }

    static var query: [KeyPath<OldCustomObject, Int>: (Query<OldCustomObject>) -> Query<Bool>] {
        [\OldCustomObject.intCol: { $0.intCol == 12 },
          \OldCustomObject.objectCol!.intCol: { $0.objectCol.intCol == 24 },
          \OldCustomObject.embeddedObject!.intCol: { $0.embeddedObject.intCol == 36 },
          \OldCustomObject.objectCol!.embeddedObject!.intCol: { $0.objectCol.embeddedObject.intCol == 48 }]
    }

    static var distincts: [KeyPath<OldCustomObject, Int>: Int] {
        [\OldCustomObject.intCol: 2,
          \OldCustomObject.objectCol!.intCol: 1,
          \OldCustomObject.embeddedObject!.intCol: 2,
          \OldCustomObject.objectCol!.embeddedObject!.intCol: 1]
    }

    static var sort: [KeyPath<OldCustomObject, Int>: Int] {
        [\OldCustomObject.intCol: 0,
          \OldCustomObject.objectCol!.intCol: 0,
          \OldCustomObject.embeddedObject!.intCol: 0,
          \OldCustomObject.objectCol!.embeddedObject!.intCol: 0]
    }

    static var propertyValues: [KeyPath<OldCustomObject, Int>: Int] {
        [\OldCustomObject.intCol: 111]
    }
}

extension OldResultsIntType: CustomColumnAggregatesTypeFactory {
    // Nested keyPaths are not available in Aggregates
    static var average: [KeyPath<OldCustomObject, Int>: Int] {
        [\OldCustomObject.intCol: 18]
    }

    static var sum: [KeyPath<OldCustomObject, Int>: Int] {
        [\OldCustomObject.intCol: 36]
    }

    static var max: [KeyPath<OldCustomObject, Int>: Int] {
        [\OldCustomObject.intCol: 24]
    }

    static var min: [KeyPath<OldCustomObject, Int>: Int] {
        [\OldCustomObject.intCol: 12]
    }
}

extension OldResultsIntType: CustomColumnResultsSectionedTypeFactory {
    static var sectioned: [KeyPath<OldCustomObject, Int>: Int] {
       [\OldCustomObject.intCol: 2]
    }
}

extension OldResultsIntType: ObjectCustomColumnObjectTypeFactory {
    static var values: [KeyPath<OldCustomObject, Int>: Int] {
        [\OldCustomObject.intCol: 96]
    }

    static var dynamicListProperty: [KeyPath<OldCustomObject, Int>: Int] { [:] } // Not Applicable
    static var dynamicMutableSetProperty: [KeyPath<OldCustomObject, Int>: Int] { [:] } // Not Applicable
}

struct OldListResultsIntType: CustomColumnResultsTypeFactory {
    typealias Root = OldCustomObject
    typealias ValueType = List<Int>

    static var listKeyPath: PartialKeyPath<OldCustomObject> { fatalError() } // Not Applicable
    static var setKeyPath: PartialKeyPath<OldCustomObject> { fatalError() } // Not Applicable
    static var mapKeyPath: PartialKeyPath<OldCustomObject> { fatalError() } // Not Applicable

    static var keyPaths: [KeyPath<OldCustomObject, List<Int>>: List<Int>] {
        let list = List<Int>()
        list.append(objectsIn: [56, 12, 34, 67])
        return [\OldCustomObject.arrayIntCol: list]
    }

    static var query: [KeyPath<OldCustomObject, List<Int>>: (Query<OldCustomObject>) -> Query<Bool>] {
        [\OldCustomObject.arrayIntCol: { $0.arrayIntCol.contains(34) }]
    }

    static var distincts: [KeyPath<OldCustomObject, List<Int>>: Int] { [:] } // Not Applicable
    static var sort: [KeyPath<OldCustomObject, List<Int>>: ValueType] { [:] } // Not Applicable

    static var propertyValues: [KeyPath<OldCustomObject, List<Int>>: List<Int>] {
        let list = List<Int>()
        list.append(objectsIn: [99, 88, 22, 11])
        return [\OldCustomObject.arrayIntCol: list]
    }

    static var valueKeyPath: [KeyPath<OldCustomObject, List<Int>>: List<Int>] {
        let list = List<Int>()
        list.append(objectsIn: [56, 12, 34, 67])
        return [\OldCustomObject.arrayIntCol: list]
    }
}

extension OldListResultsIntType: ObjectCustomColumnObjectTypeFactory {
    static var values: [KeyPath<OldCustomObject, List<Int>>: List<Int>] {
        let list = List<Int>()
        list.append(objectsIn: [43, 87, 23, 18])
        return [\OldCustomObject.arrayIntCol: list]
    }

    static var dynamicListProperty: [KeyPath<OldCustomObject, List<Int>>: Int] {
        [\OldCustomObject.arrayIntCol: 4]
    }

    static var dynamicMutableSetProperty: [KeyPath<OldCustomObject, List<Int>>: Int] { [:] } // Not Applicable
}

struct OldMutableSetResultsIntType: CustomColumnResultsTypeFactory {
    typealias Root = OldCustomObject
    typealias ValueType = MutableSet<Int>

    static var listKeyPath: PartialKeyPath<OldCustomObject> { fatalError() } // Not Applicable
    static var setKeyPath: PartialKeyPath<OldCustomObject> { fatalError() } // Not Applicable
    static var mapKeyPath: PartialKeyPath<OldCustomObject> { fatalError() } // Not Applicable

    static var keyPaths: [KeyPath<OldCustomObject, MutableSet<Int>>: MutableSet<Int>] {
        let set = MutableSet<Int>()
        set.insert(objectsIn: [56, 93, 67, 22])
        return [\OldCustomObject.setIntCol: set]
    }

    static var query: [KeyPath<OldCustomObject, MutableSet<Int>>: (Query<OldCustomObject>) -> Query<Bool>] {
        [\OldCustomObject.setIntCol: { $0.setIntCol.contains(22) }]
    }

    static var distincts: [KeyPath<OldCustomObject, ValueType>: Int] { [:] } // Not Applicable
    static var sort: [KeyPath<OldCustomObject, ValueType>: ValueType] { [:] } // Not Applicable

    static var propertyValues: [KeyPath<OldCustomObject, MutableSet<Int>>: MutableSet<Int>] {
        let set = MutableSet<Int>()
        set.insert(objectsIn: [67, 45, 27, 84])
        return [\OldCustomObject.setIntCol: set]
    }
}

extension OldMutableSetResultsIntType: ObjectCustomColumnObjectTypeFactory {
    static var values: [KeyPath<OldCustomObject, RealmSwift.MutableSet<Int>>: RealmSwift.MutableSet<Int>] {
        let set = MutableSet<Int>()
        set.insert(objectsIn: [23, 45, 36, 28])
        return [\OldCustomObject.setIntCol: set]
    }

    static var dynamicListProperty: [KeyPath<OldCustomObject, MutableSet<Int>>: Int] { [:] } // Not Applicable

    static var dynamicMutableSetProperty: [KeyPath<OldCustomObject, MutableSet<Int>>: Int] {
        [\OldCustomObject.setIntCol: 4]
    }
}

struct OldMapResultsIntType: CustomColumnResultsTypeFactory {
    typealias Root = OldCustomObject
    typealias ValueType = Map<String, Int?>

    static var listKeyPath: PartialKeyPath<OldCustomObject> { fatalError() } // Not Applicable
    static var setKeyPath: PartialKeyPath<OldCustomObject> { fatalError() } // Not Applicable
    static var mapKeyPath: PartialKeyPath<OldCustomObject> { fatalError() } // Not Applicable

    static var keyPaths: [KeyPath<OldCustomObject, Map<String, Int?>>: Map<String, Int?>] {
        let map = Map<String, Int?>()
        map["key"] = 123
        map["key1"] = 345
        map["key3"] = 567
        map["key3"] = 879
        return [\OldCustomObject.mapIntCol: map]
    }

    static var query: [KeyPath<OldCustomObject, ValueType>: (Query<OldCustomObject>) -> Query<Bool>] {
        [\OldCustomObject.mapIntCol: { $0.mapIntCol.keys.contains("key") }]
    }

    static var distincts: [KeyPath<OldCustomObject, Map<String, Int?>>: Int] { [:] } // Not Applicable
    static var sort: [KeyPath<OldCustomObject, Map<String, Int?>>: Map<String, Int?>] { [:] } // Not Applicable

    static var propertyValues: [KeyPath<OldCustomObject, Map<String, Int?>>: Map<String, Int?>] {
        let map = Map<String, Int?>()
        map["key"] = 111
        map["key1"] = 222
        map["key3"] = 333
        map["key3"] = 444
        return [\OldCustomObject.mapIntCol: map]
    }
}

extension OldMapResultsIntType: ObjectCustomColumnObjectTypeFactory {
    static var values: [KeyPath<OldCustomObject, Map<String, Int?>>: Map<String, Int?>] {
        let map = Map<String, Int?>()
        map["key"] = 123
        map["key1"] = 345
        map["key3"] = 567
        map["key3"] = 879
        return [\OldCustomObject.mapIntCol: map]
    }

    static var dynamicListProperty: [KeyPath<OldCustomObject, Map<String, Int?>>: Int] { [:] } // Not Applicable
    static var dynamicMutableSetProperty: [KeyPath<OldCustomObject, Map<String, Int?>>: Int] { [:] } // Not Applicable
}

extension OldMapResultsIntType: CustomColumnObjectKeyedTypeFactory {
    static var dynamicMapValue: [KeyPath<OldCustomObject, Map<String, Int?>>: Int] {
        [\OldCustomObject.mapIntCol: 4]
    }
}

struct OldListIntType: CustomColumnTypeFactoryBase {
    typealias Root = OldCustomObject
    typealias ValueType = Int

    static var listKeyPath: PartialKeyPath<OldCustomObject> {
        \.arrayCol
    }

    static var setKeyPath: PartialKeyPath<OldCustomObject> { fatalError() } // Not Applicable
    static var mapKeyPath: PartialKeyPath<OldCustomObject> { fatalError() } // Not Applicable

    static var keyPaths: [KeyPath<OldCustomObject, Int>: Int] {
        [\OldCustomObject.intCol: 102]
    }
}

struct OldSetIntType: CustomColumnTypeFactoryBase {
    typealias Root = OldCustomObject
    typealias ValueType = Int

    static var setKeyPath: PartialKeyPath<OldCustomObject> {
        \.setCol
    }

    static var listKeyPath: PartialKeyPath<OldCustomObject> { fatalError() } // Not Applicable
    static var mapKeyPath: PartialKeyPath<OldCustomObject> { fatalError() } // Not Applicable

    static var keyPaths: [KeyPath<OldCustomObject, Int>: Int] {
       [\OldCustomObject.intCol: 938]
    }
}

struct OldMapIntType: CustomColumnMapTypeFactory {
    typealias Root = OldCustomObject
    typealias ValueType = Int

    static var mapKeyPath: PartialKeyPath<OldCustomObject> {
        \.mapCol
    }

    static var listKeyPath: PartialKeyPath<OldCustomObject> { fatalError() } // Not Applicable
    static var setKeyPath: PartialKeyPath<OldCustomObject> { fatalError() } // Not Applicable

    static var keyValues: [String: (KeyPath<Root, Int>, Int)] {
        ["key0": (\OldCustomObject.intCol, 938),
         "key1": (\OldCustomObject.intCol, 588),
         "key2": (\OldCustomObject.intCol, 610)]
    }

    static var keyPaths: [KeyPath<OldCustomObject, Int>: Int] {
        [\OldCustomObject.intCol: 938]
    }

    static var values: [KeyPath<OldCustomObject, Int>: Int] {
        [\OldCustomObject.intCol: 1234]
    }

    static var sort: [KeyPath<Root, Int>: Int] {
        [\OldCustomObject.intCol: 588]
    }
}

extension OldMapIntType: CustomColumnMapAggregatesTypeFactory {
    static var average: [KeyPath<OldCustomObject, Int>: Int] {
        [\OldCustomObject.intCol: 712]
    }

    static var sum: [KeyPath<OldCustomObject, Int>: Int] {
        [\OldCustomObject.intCol: 2136]
    }

    static var max: [KeyPath<OldCustomObject, Int>: Int] {
        [\OldCustomObject.intCol: 938]
    }

    static var min: [KeyPath<OldCustomObject, Int>: Int] {
        [\OldCustomObject.intCol: 588]
    }
}
