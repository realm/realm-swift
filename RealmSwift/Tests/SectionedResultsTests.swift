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

#if canImport(RealmTestSupport)
import RealmTestSupport
#endif

class BaseSectionedResultsTests: RLMTestCaseBase {
    var realm: Realm?
    var obj: ModernAllTypesObject?

    override func tearDown() {
        obj = nil
        realm = nil
    }

    override func invokeTest() {
        autoreleasepool { super.invokeTest() }
    }
}

class BasePrimitiveSectionedResultsTests<TestData: SectionedResultsTestData>: RLMTestCaseBase {
    var realm: Realm?
    var obj: ModernAllTypesObject?

    override func setUp() {
        realm = try! Realm(configuration: .init(inMemoryIdentifier: "BasePrimitiveSectionedResultsTests",
                                                objectTypes: [ModernAllTypesObject.self]))
        obj = TestData.setupObject()
        try! realm?.write {
            realm?.add(obj!)
        }
        super.setUp()
    }

    override func tearDown() {
        obj = nil
        realm = nil
    }

    override func invokeTest() {
        autoreleasepool { super.invokeTest() }
    }

    private func assert<T: RealmCollection>(_ collection: T, asending: Bool = true) where T.Element == TestData.Element {
        let sectionedResults = collection.sectioned(by: TestData.sectionBlock, ascending: asending)
        var sectionCount = 0
        var elementCount = 0
        let keys = TestData.orderedKeys(ascending: asending)
        for section in sectionedResults {
            XCTAssertEqual(section.key, keys[sectionCount])
            sectionCount += 1
            let expValues = asending ? TestData.expectedSectionedValues[section.key] : TestData.expectedSectionedValues[section.key]!.reversed()
            for (i, value) in expValues!.enumerated() {
                XCTAssertEqual(section[i], value)
                elementCount += 1
            }
        }
        XCTAssertEqual(sectionCount, TestData.expectedSectionedValues.keys.count)
        XCTAssertEqual(elementCount, TestData.expectedSectionedValues.values.flatMap { $0 }.count)
    }

    func testCreationFromResults() {
        let results = TestData.results(obj!)
        assert(results)
        assert(results, asending: false)
    }

    func testCreationFromList() {
        let list = TestData.list(obj!)
        assert(list)
        assert(list, asending: false)
    }

    func testCreationFromMutableSet() {
        let set = TestData.mutableSet(obj!)
        assert(set)
        assert(set, asending: false)
    }

    func testCreationFromAnyRealmCollection() {
        let collection = TestData.anyRealmCollection(obj!)
        assert(collection)
        assert(collection, asending: false)
    }
}

class BaseOptionalPrimitiveSectionedResultsTests<TestData: OptionalSectionedResultsTestData>: BaseSectionedResultsTests {
    override func setUp() {
        realm = try! Realm(configuration: .init(inMemoryIdentifier: "BaseOptionalPrimitiveSectionedResultsTests",
                                                objectTypes: [ModernAllTypesObject.self]))
        obj = TestData.setupObject()
        try! realm?.write {
            realm?.add(obj!)
        }
        super.setUp()
    }

    private func assertOptional<T: RealmCollection>(_ collection: T, asending: Bool = true) where T.Element == Optional<TestData.Element> {
        let sectionedResults = collection.sectioned(by: TestData.sectionBlock, ascending: asending)
        var sectionCount = 0
        var elementCount = 0
        let keys = TestData.orderedKeysOpt(ascending: asending)
        for section in sectionedResults {
            XCTAssertEqual(section.key, keys[sectionCount])
            sectionCount += 1
            let expValues = asending ? TestData.expectedSectionedValuesOpt[section.key] : TestData.expectedSectionedValuesOpt[section.key]!.reversed()
            for (i, value) in expValues!.enumerated() {
                XCTAssertEqual(section[i], value)
                elementCount += 1
            }
        }
        XCTAssertEqual(sectionCount, TestData.expectedSectionedValuesOpt.keys.count)
        XCTAssertEqual(elementCount, TestData.expectedSectionedValuesOpt.values.flatMap { $0 }.count)
    }

    func testCreationFromResultsOptional() {
        let results = TestData.resultsOpt(obj!)
        assertOptional(results)
        assertOptional(results, asending: false)
    }

    func testCreationFromListOptional() {
        let list = TestData.listOpt(obj!)
        assertOptional(list)
        assertOptional(list, asending: false)
    }

    func testCreationFromMutableSetOptional() {
        let set = TestData.mutableSetOpt(obj!)
        assertOptional(set)
        assertOptional(set, asending: false)
    }

    func testCreationFromAnyRealmCollectionOptional() {
        let collection = TestData.anyRealmCollectionOpt(obj!)
        assertOptional(collection)
        assertOptional(collection, asending: false)
    }

    func testEquality() {
        let collection = TestData.anyRealmCollectionOpt(obj!)
        let sectionedResults = collection.sectioned(by: TestData.sectionBlock)
        let sectionedResults2 = collection.sectioned(by: TestData.sectionBlock)
        XCTAssertEqual(sectionedResults, sectionedResults)
        XCTAssertNotEqual(sectionedResults, sectionedResults2)
    }

    func testFrozen() {
        let collection = TestData.anyRealmCollectionOpt(obj!)
        let sectionedResults = collection.sectioned(by: TestData.sectionBlock)
        XCTAssertFalse(sectionedResults.isFrozen)
        let frozenCollection = collection.freeze()
        let frozenSectionedResults = frozenCollection.sectioned(by: TestData.sectionBlock)
        XCTAssertTrue(frozenSectionedResults.isFrozen)
    }
}

class PrimitiveSectionedResultsTests: TestCase {
    override class var defaultTestSuite: XCTestSuite {
        let suite = XCTestSuite(name: "Primitive SectionedResults Tests")

        BasePrimitiveSectionedResultsTests<SectionedResultsTestDataInt>.defaultTestSuite.tests.forEach(suite.addTest)
        BasePrimitiveSectionedResultsTests<SectionedResultsTestDataFloat>.defaultTestSuite.tests.forEach(suite.addTest)
        BasePrimitiveSectionedResultsTests<SectionedResultsTestDataDouble>.defaultTestSuite.tests.forEach(suite.addTest)
        BasePrimitiveSectionedResultsTests<SectionedResultsTestDataString>.defaultTestSuite.tests.forEach(suite.addTest)
        BasePrimitiveSectionedResultsTests<SectionedResultsTestDataAnyRealmValue>.defaultTestSuite.tests.forEach(suite.addTest)
        BasePrimitiveSectionedResultsTests<SectionedResultsTestDataBinary>.defaultTestSuite.tests.forEach(suite.addTest)
        BasePrimitiveSectionedResultsTests<SectionedResultsTestDataDate>.defaultTestSuite.tests.forEach(suite.addTest)
        BasePrimitiveSectionedResultsTests<SectionedResultsTestDataDecimal128>.defaultTestSuite.tests.forEach(suite.addTest)

        BaseOptionalPrimitiveSectionedResultsTests<SectionedResultsTestDataOptionalInt>.defaultTestSuite.tests.forEach(suite.addTest)
        BaseOptionalPrimitiveSectionedResultsTests<SectionedResultsTestDataOptionalFloat>.defaultTestSuite.tests.forEach(suite.addTest)
        BaseOptionalPrimitiveSectionedResultsTests<SectionedResultsTestDataOptionalDouble>.defaultTestSuite.tests.forEach(suite.addTest)
        BaseOptionalPrimitiveSectionedResultsTests<SectionedResultsTestDataOptionalString>.defaultTestSuite.tests.forEach(suite.addTest)
        BaseOptionalPrimitiveSectionedResultsTests<SectionedResultsTestDataOptionalBinary>.defaultTestSuite.tests.forEach(suite.addTest)
        BaseOptionalPrimitiveSectionedResultsTests<SectionedResultsTestDataOptionalDate>.defaultTestSuite.tests.forEach(suite.addTest)
        BaseOptionalPrimitiveSectionedResultsTests<SectionedResultsTestDataOptionalDecimal128>.defaultTestSuite.tests.forEach(suite.addTest)

        return suite
    }
}

class SectionedResultsTests: RLMTestCaseBase {
    func testCreationFromResults() {
        let realm = try! Realm()

        let results = realm.objects(ModernAllTypesObject.self)
        let sectionedResults = results.sectioned(by: \.stringCol, ascending: true)
        let sectionedResults2 = results.sectioned(by: \.stringCol, sortDescriptors: [SortDescriptor.init(keyPath: "stringCol", ascending: true)])
        print(sectionedResults)
    }

    func testCreationFromList() {

    }

    func testCreateFromMutableSet() {

    }

    func testObservation() {
        let realm = try! Realm()
        let results = realm.objects(ModernAllTypesObject.self)
//        let sectionedResults = results.sectioned(by: \.stringCol, ascending: true).observe { change in
//            switch change {
//            case .initial(let collection):
//                break
//            case let .update(collection, deletions: deletions, insertions: insertions, modifications: modifications,
//                             sectionsToInsert: sectionsToInsert, sectionsToDelete: sectionsToDelete):
//                break
//            case .error:
//                XCTFail("Should not return error.")
//            }
//        }

        let q = DispatchQueue(label: "testQueue")
        let sectionedResults = results.sectioned(by: \.stringCol, ascending: true).observe(on: q) { change in
            switch change {
            case .initial(let collection):
                break
            case let .update(collection, deletions: deletions, insertions: insertions, modifications: modifications,
                             sectionsToInsert: sectionsToInsert, sectionsToDelete: sectionsToDelete):
                let x = collection
                print(x)
                break
            case .error:
                XCTFail("Should not return error.")
            }
        }


        try! realm.write {
            realm.add(ModernAllTypesObject())
        }

        q.sync {

        }

        try! realm.write {
            realm.add(ModernAllTypesObject())
        }

        q.sync {

        }

        q.sync {
            let qr = try! Realm(configuration: .defaultConfiguration, queue: q)

            try! qr.write {
                print("")
            }
        }

        q.sync {

        }


        try! realm.write {
            realm.add(ModernAllTypesObject())
        }

        q.sync {

        }

        try! realm.write {
            realm.add(ModernAllTypesObject())
        }

        q.sync {

        }

        q.sync {
            let qr = try! Realm(configuration: .defaultConfiguration, queue: q)

            try! qr.write {
                print("")
            }
        }

        q.sync {

        }

    }

    func testObservationOnSection() {

    }
}

class SectionedResultsProjectionTests: RLMTestCaseBase {

}
protocol SectionedResultsTestData {
    associatedtype Key: _Persistable & Hashable
    associatedtype Element: RealmCollectionValue & SortableType & _Persistable

    static var values: [Element] { get }
    static var expectedSectionedValues: [Key: [Element]] { get }
    static func orderedKeys(ascending: Bool) -> [Key]
    static func setupObject() -> ModernAllTypesObject
    static func list(_ obj: ModernAllTypesObject) -> List<Element>
    static func mutableSet(_ obj: ModernAllTypesObject) -> MutableSet<Element>
    static func results(_ obj: ModernAllTypesObject) -> Results<Element>
    static func anyRealmCollection(_ obj: ModernAllTypesObject) -> AnyRealmCollection<Element>
    static func sectionBlock(_ element: Element) -> Key
}

protocol OptionalSectionedResultsTestData {
    associatedtype Key: _Persistable & Hashable
    associatedtype Element: _RealmCollectionValueInsideOptional & SortableType & _Persistable
    static var values: [Element] { get }
    static var expectedSectionedValuesOpt: [Key: [Element??]] { get }
    static func orderedKeysOpt(ascending: Bool) -> [Key]
    static func setupObject() -> ModernAllTypesObject
    static func listOpt(_ obj: ModernAllTypesObject) -> List<Element?>
    static func mutableSetOpt(_ obj: ModernAllTypesObject) -> MutableSet<Element?>
    static func resultsOpt(_ obj: ModernAllTypesObject) -> Results<Element?>
    static func anyRealmCollectionOpt(_ obj: ModernAllTypesObject) -> AnyRealmCollection<Element?>
    static func sectionBlock(_ element: Element?) -> Key
}

extension SectionedResultsTestData {
    static func anyRealmCollection(_ obj: ModernAllTypesObject) -> AnyRealmCollection<Element> {
        AnyRealmCollection(results(obj))
    }
}

extension OptionalSectionedResultsTestData {
    static func anyRealmCollectionOpt(_ obj: ModernAllTypesObject) -> AnyRealmCollection<Element?> {
        AnyRealmCollection(resultsOpt(obj))
    }
}

struct SectionedResultsTestDataInt: SectionedResultsTestData {

    static var values: [Int] {
        [5, 4, 3, 2, 1]
    }
    static var expectedSectionedValues: [Int: [Int]] {
        [1: [1, 3, 5], 0: [2, 4]]
    }

    static var expectedSectionedValuesOpt: [Int: [Int??]] {
        return [1: [1, 3, 5], 0: [2, 4], Int.max: [.some(.none)]]
    }

    static func orderedKeys(ascending: Bool) -> [Int] {
        return [1, 0]
    }

    static func orderedKeysOpt(ascending: Bool) -> [Int] {
        return ascending ? [Int.max, 1, 0] : [1, 0, Int.max]
    }

    static func setupObject() ->  ModernAllTypesObject {
        let object = ModernAllTypesObject()
        object.arrayInt.append(objectsIn: values)
        object.setInt.insert(objectsIn: values)
        object.arrayOptInt.append(objectsIn: values + [nil])
        object.setOptInt.insert(objectsIn: values + [nil])
        return object
    }

    static func list(_ obj: ModernAllTypesObject) -> List<Int> {
        obj.arrayInt
    }
    static func mutableSet(_ obj: ModernAllTypesObject) -> MutableSet<Int> {
        obj.setInt
    }
    static func results(_ obj: ModernAllTypesObject) -> Results<Int> {
        obj.arrayInt.sorted(ascending: true)
    }

    static func listOpt(_ obj: ModernAllTypesObject) -> List<Int?> {
        obj.arrayOptInt
    }
    static func mutableSetOpt(_ obj: ModernAllTypesObject) -> MutableSet<Int?> {
        obj.setOptInt
    }
    static func resultsOpt(_ obj: ModernAllTypesObject) -> Results<Int?> {
        obj.arrayOptInt.sorted(ascending: true)
    }

    static func sectionBlock(_ element: Int) -> Int {
        element % 2
    }

    static func sectionBlock(_ element: Int?) -> Int {
        guard let element = element else {
            return Int.max
        }
        return element % 2
    }
}

struct SectionedResultsTestDataOptionalInt: OptionalSectionedResultsTestData {
    static var values: [Int] {
        [5, 4, 3, 2, 1]
    }

    static var expectedSectionedValuesOpt: [Int: [Int??]] {
        return [1: [1, 3, 5], 0: [2, 4], Int.max: [.some(.none)]]
    }

    static func orderedKeysOpt(ascending: Bool) -> [Int] {
        return ascending ? [Int.max, 1, 0] : [1, 0, Int.max]
    }

    static func setupObject() ->  ModernAllTypesObject {
        let object = ModernAllTypesObject()
        object.arrayOptInt.append(objectsIn: values + [nil])
        object.setOptInt.insert(objectsIn: values + [nil])
        return object
    }

    static func listOpt(_ obj: ModernAllTypesObject) -> List<Int?> {
        obj.arrayOptInt
    }
    static func mutableSetOpt(_ obj: ModernAllTypesObject) -> MutableSet<Int?> {
        obj.setOptInt
    }
    static func resultsOpt(_ obj: ModernAllTypesObject) -> Results<Int?> {
        obj.arrayOptInt.sorted(ascending: true)
    }

    static func sectionBlock(_ element: Int?) -> Int {
        guard let element = element else {
            return Int.max
        }
        return element % 2
    }
}

struct SectionedResultsTestDataFloat: SectionedResultsTestData {
    static var values: [Float] {
        [5.5, 4.4, 3.3, 2.2, 1.1]
    }
    static var expectedSectionedValues: [String: [Float]] {
        ["small": [1.1, 2.2, 3.3, 4.4], "large": [5.5]]
    }

    static func orderedKeys(ascending: Bool) -> [String] {
        return ascending ? ["small", "large"] : ["large", "small"]
    }

    static func setupObject() ->  ModernAllTypesObject {
        let object = ModernAllTypesObject()
        object.arrayFloat.append(objectsIn: values)
        object.setFloat.insert(objectsIn: values)
        return object
    }

    static func list(_ obj: ModernAllTypesObject) -> List<Float> {
        obj.arrayFloat
    }
    static func mutableSet(_ obj: ModernAllTypesObject) -> MutableSet<Float> {
        obj.setFloat
    }
    static func results(_ obj: ModernAllTypesObject) -> Results<Float> {
        obj.arrayFloat.sorted(ascending: true)
    }

    static func sectionBlock(_ element: Float) -> String {
        return (element >= 5.0) ? "large" : "small"
    }
}

struct SectionedResultsTestDataOptionalFloat: OptionalSectionedResultsTestData {
    static var values: [Float] {
        [5.5, 4.4, 3.3, 2.2, 1.1]
    }

    static var expectedSectionedValuesOpt: [String: [Float??]] {
        return ["small": [1.1, 2.2, 3.3, 4.4], "large": [5.5], "empty": [.some(.none)]]
    }

    static func orderedKeysOpt(ascending: Bool) -> [String] {
        return ascending ? ["empty", "small", "large"] : ["large", "small", "empty"]
    }

    static func setupObject() ->  ModernAllTypesObject {
        let object = ModernAllTypesObject()
        object.arrayOptFloat.append(objectsIn: values + [nil])
        object.setOptFloat.insert(objectsIn: values + [nil])
        return object
    }

    static func listOpt(_ obj: ModernAllTypesObject) -> List<Float?> {
        obj.arrayOptFloat
    }
    static func mutableSetOpt(_ obj: ModernAllTypesObject) -> MutableSet<Float?> {
        obj.setOptFloat
    }
    static func resultsOpt(_ obj: ModernAllTypesObject) -> Results<Float?> {
        obj.arrayOptFloat.sorted(ascending: true)
    }

    static func sectionBlock(_ element: Float?) -> String {
        guard let element = element else {
            return "empty"
        }
        return (element >= 5.0) ? "large" : "small"
    }
}

struct SectionedResultsTestDataDouble: SectionedResultsTestData {
    static var values: [Double] {
        [5.5, 4.4, 3.3, 2.2, 1.1]
    }
    static var expectedSectionedValues: [String: [Double]] {
        ["small": [1.1, 2.2, 3.3, 4.4], "large": [5.5]]
    }

    static func orderedKeys(ascending: Bool) -> [String] {
        return ascending ? ["small", "large"] : ["large", "small"]
    }

    static func setupObject() ->  ModernAllTypesObject {
        let object = ModernAllTypesObject()
        object.arrayDouble.append(objectsIn: values)
        object.setDouble.insert(objectsIn: values)
        object.arrayOptDouble.append(objectsIn: values + [nil])
        object.setOptDouble.insert(objectsIn: values + [nil])
        return object
    }

    static func list(_ obj: ModernAllTypesObject) -> List<Double> {
        obj.arrayDouble
    }
    static func mutableSet(_ obj: ModernAllTypesObject) -> MutableSet<Double> {
        obj.setDouble
    }
    static func results(_ obj: ModernAllTypesObject) -> Results<Double> {
        obj.arrayDouble.sorted(ascending: true)
    }

    static func sectionBlock(_ element: Double) -> String {
        return (element >= 5.0) ? "large" : "small"
    }
}

struct SectionedResultsTestDataOptionalDouble: OptionalSectionedResultsTestData {
    static var values: [Double] {
        [5.5, 4.4, 3.3, 2.2, 1.1]
    }

    static var expectedSectionedValuesOpt: [String: [Double??]] {
        return ["small": [1.1, 2.2, 3.3, 4.4], "large": [5.5], "empty": [.some(.none)]]
    }

    static func orderedKeysOpt(ascending: Bool) -> [String] {
        return ascending ? ["empty", "small", "large"] : ["large", "small", "empty"]
    }

    static func setupObject() ->  ModernAllTypesObject {
        let object = ModernAllTypesObject()
        object.arrayDouble.append(objectsIn: values)
        object.setDouble.insert(objectsIn: values)
        object.arrayOptDouble.append(objectsIn: values + [nil])
        object.setOptDouble.insert(objectsIn: values + [nil])
        return object
    }

    static func listOpt(_ obj: ModernAllTypesObject) -> List<Double?> {
        obj.arrayOptDouble
    }
    static func mutableSetOpt(_ obj: ModernAllTypesObject) -> MutableSet<Double?> {
        obj.setOptDouble
    }
    static func resultsOpt(_ obj: ModernAllTypesObject) -> Results<Double?> {
        obj.arrayOptDouble.sorted(ascending: true)
    }
    static func sectionBlock(_ element: Double?) -> String {
        guard let element = element else {
            return "empty"
        }
        return (element >= 5.0) ? "large" : "small"
    }
}

struct SectionedResultsTestDataString: SectionedResultsTestData {
    static var values: [String] {
        ["apple", "banana", "any", "phone", "door"]
    }
    static var expectedSectionedValues: [String: [String]] {
        ["a": ["any", "apple"], "b": ["banana"], "d": ["door"], "p": ["phone"]]
    }

    static func orderedKeys(ascending: Bool) -> [String] {
        return ascending ? ["a", "b", "d", "p"] : ["p", "d", "b", "a"]
    }

    static func setupObject() ->  ModernAllTypesObject {
        let object = ModernAllTypesObject()
        object.arrayString.append(objectsIn: values)
        object.setString.insert(objectsIn: values)
        return object
    }

    static func list(_ obj: ModernAllTypesObject) -> List<String> {
        obj.arrayString
    }
    static func mutableSet(_ obj: ModernAllTypesObject) -> MutableSet<String> {
        obj.setString
    }
    static func results(_ obj: ModernAllTypesObject) -> Results<String> {
        obj.arrayString.sorted(ascending: true)
    }

    static func sectionBlock(_ element: String) -> String {
        String(element.first!)
    }
}

struct SectionedResultsTestDataOptionalString: OptionalSectionedResultsTestData {
    static var values: [String] {
        ["apple", "banana", "any", "phone", "door"]
    }
    static var expectedSectionedValuesOpt: [String : [String??]] {
        return ["a": ["any", "apple"], "b": ["banana"], "d": ["door"], "p": ["phone"], "empty": [.some(.none)]]
    }

    static func orderedKeysOpt(ascending: Bool) -> [String] {
        return ascending ? ["empty", "a", "b", "d", "p"] : ["p", "d", "b", "a", "empty"]
    }

    static func setupObject() ->  ModernAllTypesObject {
        let object = ModernAllTypesObject()
        object.arrayOptString.append(objectsIn: values + [nil])
        object.setOptString.insert(objectsIn: values + [nil])
        return object
    }

    static func listOpt(_ obj: ModernAllTypesObject) -> List<String?> {
        obj.arrayOptString
    }
    static func mutableSetOpt(_ obj: ModernAllTypesObject) -> MutableSet<String?> {
        obj.setOptString
    }
    static func resultsOpt(_ obj: ModernAllTypesObject) -> Results<String?> {
        obj.arrayOptString.sorted(ascending: true)
    }

    static func sectionBlock(_ element: String?) -> String {
        guard let element = element else {
            return "empty"
        }
        return String(element.first!)
    }
}

struct SectionedResultsTestDataAnyRealmValue: SectionedResultsTestData {
    static var values: [AnyRealmValue] {
        [.string("apple"), .int(2), .bool(true), .data(.init(repeating: 1, count: 1)), .decimal128(123.456)]
    }
    static var expectedSectionedValues: [String: [AnyRealmValue]] {
        ["alphanumeric": [.bool(true), .int(2), .decimal128(123.456), .string("apple")], "data": [.data(.init(repeating: 1, count: 1))]]
    }

    static func orderedKeys(ascending: Bool) -> [String] {
        return ["alphanumeric", "data"]
    }

    static func setupObject() ->  ModernAllTypesObject {
        let object = ModernAllTypesObject()
        object.arrayAny.append(objectsIn: values)
        object.setAny.insert(objectsIn: values)
        return object
    }

    static func list(_ obj: ModernAllTypesObject) -> List<AnyRealmValue> {
        obj.arrayAny
    }
    static func mutableSet(_ obj: ModernAllTypesObject) -> MutableSet<AnyRealmValue> {
        obj.setAny
    }
    static func results(_ obj: ModernAllTypesObject) -> Results<AnyRealmValue> {
        obj.arrayAny.sorted(ascending: true)
    }

    static func sectionBlock(_ element: AnyRealmValue) -> String {
        switch element {
        case .int:
            return "alphanumeric"
        case .bool:
            return "alphanumeric"
        case .string:
            return "alphanumeric"
        case .data:
            return "data"
        case .decimal128:
            return "alphanumeric"
        default:
            XCTFail("Element not supported")
            return ""
        }
    }
}

struct SectionedResultsTestDataBinary: SectionedResultsTestData {
    static var values: [Data] {
        [Data(base64Encoded: "more")!,
         Data(base64Encoded: "door")!,
         Data(base64Encoded: "absolute")!,
         Data(base64Encoded: "abstract")!]
    }
    static var expectedSectionedValues: [String: [Data]] {
        ["short": [Data(base64Encoded: "more")!,
                     Data(base64Encoded: "door")!],
         "long": [Data(base64Encoded: "absolute")!,
                     Data(base64Encoded: "abstract")!]]
    }

    static func orderedKeys(ascending: Bool) -> [String] {
        return ["short", "long"]
    }

    static func setupObject() ->  ModernAllTypesObject {
        let object = ModernAllTypesObject()
        object.arrayBinary.append(objectsIn: values)
        object.setBinary.insert(objectsIn: values)
        return object
    }

    static func list(_ obj: ModernAllTypesObject) -> List<Data> {
        obj.arrayBinary
    }
    static func mutableSet(_ obj: ModernAllTypesObject) -> MutableSet<Data> {
        obj.setBinary
    }
    static func results(_ obj: ModernAllTypesObject) -> Results<Data> {
        obj.arrayBinary.sorted(ascending: true)
    }

    static func sectionBlock(_ element: Data) -> String {
        return element.base64EncodedString().count == 4 ? "short" : "long"
    }
}

struct SectionedResultsTestDataOptionalBinary: OptionalSectionedResultsTestData {
    static var values: [Data] {
        [Data(base64Encoded: "more")!,
         Data(base64Encoded: "door")!,
         Data(base64Encoded: "absolute")!,
         Data(base64Encoded: "abstract")!]
    }
    static var expectedSectionedValuesOpt: [String: [Data??]] {
        ["short": [Data(base64Encoded: "more")!,
                     Data(base64Encoded: "door")!],
         "long": [Data(base64Encoded: "absolute")!,
                     Data(base64Encoded: "abstract")!],
         "empty": [.some(.none)]]
    }

    static func orderedKeysOpt(ascending: Bool) -> [String] {
        return ascending ? ["empty", "short", "long"] : ["short", "long", "empty"]
    }

    static func setupObject() ->  ModernAllTypesObject {
        let object = ModernAllTypesObject()
        object.arrayOptBinary.append(objectsIn: values + [nil])
        object.setOptBinary.insert(objectsIn: values + [nil])
        return object
    }

    static func listOpt(_ obj: ModernAllTypesObject) -> List<Data?> {
        obj.arrayOptBinary
    }
    static func mutableSetOpt(_ obj: ModernAllTypesObject) -> MutableSet<Data?> {
        obj.setOptBinary
    }
    static func resultsOpt(_ obj: ModernAllTypesObject) -> Results<Data?> {
        obj.arrayOptBinary.sorted(ascending: true)
    }

    static func sectionBlock(_ element: Data?) -> String {
        guard let element = element else {
            return "empty"
        }
        return element.base64EncodedString().count == 4 ? "short" : "long"
    }
}

struct SectionedResultsTestDataDate: SectionedResultsTestData {
    static var values: [Date] {
        [Date(timeIntervalSince1970: 1656547200), // 6-30-22
         Date(timeIntervalSince1970: 1653868800), // 5-30-22
         Date(timeIntervalSince1970: 1651276800), // 4-30-22
         Date(timeIntervalSince1970: 1650412800)] // 4-20-22
    }
    static var expectedSectionedValues: [Date: [Date]] {
        [Date(timeIntervalSince1970: 1653955200): [Date(timeIntervalSince1970: 1656547200)], // June
         Date(timeIntervalSince1970: 1651276800): [Date(timeIntervalSince1970: 1653868800)], // May
         Date(timeIntervalSince1970: 1648684800): [Date(timeIntervalSince1970: 1650412800), // April
                                                   Date(timeIntervalSince1970: 1651276800)]]
    }

    static func orderedKeys(ascending: Bool) -> [Date] {
        let keys = [Date(timeIntervalSince1970: 1648684800), Date(timeIntervalSince1970: 1651276800), Date(timeIntervalSince1970: 1653955200)]
        return ascending ? keys : keys.reversed()
    }

    static func setupObject() ->  ModernAllTypesObject {
        let object = ModernAllTypesObject()
        object.arrayDate.append(objectsIn: values)
        object.setDate.insert(objectsIn: values)
        return object
    }

    static func list(_ obj: ModernAllTypesObject) -> List<Date> {
        obj.arrayDate
    }
    static func mutableSet(_ obj: ModernAllTypesObject) -> MutableSet<Date> {
        obj.setDate
    }
    static func results(_ obj: ModernAllTypesObject) -> Results<Date> {
        obj.arrayDate.sorted(ascending: true)
    }

    static func sectionBlock(_ element: Date) -> Date {
        let comp = Calendar(identifier: .gregorian).dateComponents([.month, .year], from: element)
        let components = DateComponents(year: comp.year, month: comp.month, day: 0, hour: 1, minute: 0, second: 0)
        return Calendar(identifier: .gregorian).date(from: components)!
    }
}

struct SectionedResultsTestDataOptionalDate: OptionalSectionedResultsTestData {
    static var values: [Date] {
        [Date(timeIntervalSince1970: 1656547200), // 6-30-22
         Date(timeIntervalSince1970: 1653868800), // 5-30-22
         Date(timeIntervalSince1970: 1651276800), // 4-30-22
         Date(timeIntervalSince1970: 1650412800)] // 4-20-22
    }
    static var expectedSectionedValuesOpt: [Date: [Date??]] {
        [Date(timeIntervalSince1970: 0): [.some(.none)],
         Date(timeIntervalSince1970: 1653955200): [Date(timeIntervalSince1970: 1656547200)], // June
         Date(timeIntervalSince1970: 1651276800): [Date(timeIntervalSince1970: 1653868800)], // May
         Date(timeIntervalSince1970: 1648684800): [Date(timeIntervalSince1970: 1650412800), // April
                                                   Date(timeIntervalSince1970: 1651276800)]]
    }

    static func orderedKeysOpt(ascending: Bool) -> [Date] {
        let keys = [Date(timeIntervalSince1970: 0), Date(timeIntervalSince1970: 1648684800), Date(timeIntervalSince1970: 1651276800), Date(timeIntervalSince1970: 1653955200)]
        return ascending ? keys  : keys.reversed()
    }

    static func setupObject() ->  ModernAllTypesObject {
        let object = ModernAllTypesObject()
        object.arrayOptDate.append(objectsIn: values + [nil])
        object.setOptDate.insert(objectsIn: values + [nil])
        return object
    }

    static func listOpt(_ obj: ModernAllTypesObject) -> List<Date?> {
        obj.arrayOptDate
    }
    static func mutableSetOpt(_ obj: ModernAllTypesObject) -> MutableSet<Date?> {
        obj.setOptDate
    }
    static func resultsOpt(_ obj: ModernAllTypesObject) -> Results<Date?> {
        obj.arrayOptDate.sorted(ascending: true)
    }

    static func sectionBlock(_ element: Date?) -> Date {
        guard let date = element else {
            return Date(timeIntervalSince1970: 0)
        }
        let comp = Calendar(identifier: .gregorian).dateComponents([.month, .year], from: date)
        let components = DateComponents(year: comp.year, month: comp.month, day: 0, hour: 1, minute: 0, second: 0)
        return Calendar(identifier: .gregorian).date(from: components)!
    }
}

struct SectionedResultsTestDataDecimal128: SectionedResultsTestData {
    static var values: [Decimal128] {
        [Decimal128(1.0),
         Decimal128(3.0),
         Decimal128(2.0),
         Decimal128(4.0)]
    }
    static var expectedSectionedValues: [Decimal128: [Decimal128]] {
        [Decimal128(1.0): [Decimal128(1.0),
                           Decimal128(3.0)],
         Decimal128(2.0): [Decimal128(2.0),
                           Decimal128(4.0)]]
    }

    static func orderedKeys(ascending: Bool) -> [Decimal128] {
        let keys = [Decimal128(1.0), Decimal128(2.0)]
        return ascending ? keys : keys.reversed()
    }

    static func setupObject() ->  ModernAllTypesObject {
        let object = ModernAllTypesObject()
        object.arrayDecimal.append(objectsIn: values)
        object.setDecimal.insert(objectsIn: values)
        return object
    }

    static func list(_ obj: ModernAllTypesObject) -> List<Decimal128> {
        obj.arrayDecimal
    }
    static func mutableSet(_ obj: ModernAllTypesObject) -> MutableSet<Decimal128> {
        obj.setDecimal
    }
    static func results(_ obj: ModernAllTypesObject) -> Results<Decimal128> {
        obj.arrayDecimal.sorted(ascending: true)
    }

    static func sectionBlock(_ element: Decimal128) -> Decimal128 {
        return element.doubleValue.truncatingRemainder(dividingBy: 2.0) == 0 ? Decimal128(2.0) : Decimal128(1.0)
    }
}

struct SectionedResultsTestDataOptionalDecimal128: OptionalSectionedResultsTestData {
    static var values: [Decimal128] {
        [Decimal128(1.0),
         Decimal128(3.0),
         Decimal128(2.0),
         Decimal128(4.000)]
    }
    static var expectedSectionedValuesOpt: [Decimal128: [Decimal128??]] {
        [Decimal128(1.0): [Decimal128(1.0),
                           Decimal128(3.0)],
         Decimal128(2.0): [Decimal128(2.0),
                           Decimal128(4.0)],
         Decimal128(): [.some(.none)]]
    }

    static func orderedKeysOpt(ascending: Bool) -> [Decimal128] {
        let keys = [Decimal128(), Decimal128(1.0), Decimal128(2.0)]
        return ascending ? keys  : keys.reversed()
    }

    static func setupObject() ->  ModernAllTypesObject {
        let object = ModernAllTypesObject()
        object.arrayOptDecimal.append(objectsIn: values + [nil])
        object.setOptDecimal.insert(objectsIn: values + [nil])
        return object
    }

    static func listOpt(_ obj: ModernAllTypesObject) -> List<Decimal128?> {
        obj.arrayOptDecimal
    }
    static func mutableSetOpt(_ obj: ModernAllTypesObject) -> MutableSet<Decimal128?> {
        obj.setOptDecimal
    }
    static func resultsOpt(_ obj: ModernAllTypesObject) -> Results<Decimal128?> {
        obj.arrayOptDecimal.sorted(ascending: true)
    }

    static func sectionBlock(_ element: Decimal128?) -> Decimal128 {
        guard let decimal = element else {
            return Decimal128()
        }
        return decimal.doubleValue.truncatingRemainder(dividingBy: 2.0) == 0 ? Decimal128(2.0) : Decimal128(1.0)
    }
}
