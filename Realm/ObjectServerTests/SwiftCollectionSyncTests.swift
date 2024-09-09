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

import Realm
import RealmSwift
import XCTest

#if canImport(RealmTestSupport)
import RealmSwiftSyncTestSupport
import RealmSyncTestSupport
import RealmTestSupport
#endif

@available(macOS 13, *)
class CollectionSyncTestCase: SwiftSyncTestCase {
    var readRealm: Realm!

    override var objectTypes: [ObjectBase.Type] {
        [SwiftCollectionSyncObject.self, SwiftPerson.self]
    }

    @MainActor
    func write(_ fn: (Realm) -> Void) throws {
        try super.write(fn)
        waitForDownloads(for: readRealm)
    }

    func assertEqual<T: RealmCollectionValue>(_ left: T, _ right: T, _ line: UInt = #line) {
        if let person = left as? SwiftPerson, let otherPerson = right as? SwiftPerson {
            XCTAssertEqual(person.firstName, otherPerson.firstName, line: line)
        } else {
            XCTAssertEqual(left, right, line: line)
        }
    }

    @MainActor
    private func roundTrip<T>(keyPath: KeyPath<SwiftCollectionSyncObject, List<T>>,
                              values: [T], partitionValue: String = #function) throws {
        autoreleasepool {
            readRealm = try! openRealm()
        }

        checkCount(expected: 0, readRealm, SwiftCollectionSyncObject.self)

        // Create the object
        try write { realm in
            realm.add(SwiftCollectionSyncObject())
        }
        checkCount(expected: 1, readRealm, SwiftCollectionSyncObject.self)
        let object = readRealm.objects(SwiftCollectionSyncObject.self).first!
        let collection = object[keyPath: keyPath]
        XCTAssertEqual(collection.count, 0)

        // Populate the collection
        try write { realm in
            let object = realm.objects(SwiftCollectionSyncObject.self).first!
            object[keyPath: keyPath].append(objectsIn: values + values)
        }
        checkCount(expected: 1, readRealm, SwiftCollectionSyncObject.self)
        XCTAssertEqual(collection.count, values.count*2)
        for (el, ex) in zip(collection, values + values) {
            assertEqual(el, ex)
        }

        // Remove the last three objects from the collection
        try write { realm in
            let object = realm.objects(SwiftCollectionSyncObject.self).first!
            object[keyPath: keyPath].removeSubrange(3...5)
        }
        XCTAssertEqual(collection.count, values.count)

        // Modify the first element
        try write { realm in
            let object = realm.objects(SwiftCollectionSyncObject.self).first!
            let collection = object[keyPath: keyPath]
            if T.self is SwiftPerson.Type {
                (collection as! List<SwiftPerson>)[0].firstName
                    = (values as! [SwiftPerson])[1].firstName
            } else {
                collection[0] = values[1]
            }
        }
        assertEqual(collection[0], values[1])

        try write { realm in
            realm.deleteAll()
        }

        readRealm = nil
    }

    @MainActor
    func testLists() throws {
        try roundTrip(keyPath: \.intList, values: [1, 2, 3])
        try roundTrip(keyPath: \.boolList, values: [true, false, false])
        try roundTrip(keyPath: \.stringList, values: ["Hey", "Hi", "Bye"])
        try roundTrip(keyPath: \.dataList, values: [Data(repeating: 0, count: 64),
                                                    Data(repeating: 1, count: 64),
                                                    Data(repeating: 2, count: 64)])
        try roundTrip(keyPath: \.dateList, values: [Date(timeIntervalSince1970: 10000000),
                                                    Date(timeIntervalSince1970: 20000000),
                                                    Date(timeIntervalSince1970: 30000000)])
        try roundTrip(keyPath: \.doubleList, values: [123.456, 234.456, 567.333])
        try roundTrip(keyPath: \.objectIdList, values: [.init("6058f12b957ba06156586a7c"),
                                                        .init("6058f12682b2fbb1f334ef1d"),
                                                        .init("6058f12d42e5a393e67538d0")])
        try roundTrip(keyPath: \.decimalList, values: [123.345, 213.345, 321.345])
        try roundTrip(keyPath: \.uuidList, values: [UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fd")!,
                                                    UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fe")!,
                                                    UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90ff")!])
        try roundTrip(keyPath: \.objectList, values: [SwiftPerson(firstName: "Peter", lastName: "Parker"),
                                                      SwiftPerson(firstName: "Bruce", lastName: "Wayne"),
                                                      SwiftPerson(firstName: "Stephen", lastName: "Strange")])
        try roundTrip(keyPath: \.anyList, values: [.int(12345), .string("Hello"), .none])
    }

    private typealias MutableSetKeyPath<T: RealmCollectionValue> = KeyPath<SwiftCollectionSyncObject, MutableSet<T>>
    private typealias MutableSetKeyValues<T: RealmCollectionValue> = (keyPath: MutableSetKeyPath<T>, values: [T])

    @MainActor
    private func roundTrip<T>(set: MutableSetKeyValues<T>,
                              otherSet: MutableSetKeyValues<T>,
                              partitionValue: String = #function) throws {
        autoreleasepool {
            readRealm = try! openRealm()
        }
        checkCount(expected: 0, readRealm, SwiftCollectionSyncObject.self)

        // Create the object
        try write { realm in
            realm.add(SwiftCollectionSyncObject())
        }
        checkCount(expected: 1, readRealm, SwiftCollectionSyncObject.self)
        let object = readRealm.objects(SwiftCollectionSyncObject.self).first!
        let collection = object[keyPath: set.keyPath]
        let otherCollection = object[keyPath: otherSet.keyPath]
        XCTAssertEqual(collection.count, 0)
        XCTAssertEqual(otherCollection.count, 0)

        // Populate the collection
        try write { realm in
            let object = realm.objects(SwiftCollectionSyncObject.self).first!
            object[keyPath: set.keyPath].insert(objectsIn: set.values)
            object[keyPath: otherSet.keyPath].insert(objectsIn: otherSet.values)
        }
        checkCount(expected: 1, readRealm, SwiftCollectionSyncObject.self)
        XCTAssertEqual(collection.count, set.values.count)
        XCTAssertEqual(otherCollection.count, otherSet.values.count)

        // Intersect the values
        try write { realm in
            let object = realm.objects(SwiftCollectionSyncObject.self).first!
            let collection = object[keyPath: set.keyPath]
            let otherCollection = object[keyPath: otherSet.keyPath]
            if T.self is SwiftPerson.Type {
                // formIntersection won't work with unique Objects
                collection.removeAll()
                collection.insert(realm.create(SwiftPerson.self, value: set.values[0], update: .all) as! T)
            } else {
                collection.formIntersection(otherCollection)
            }
        }

        if !(T.self is SwiftPerson.Type) {
            XCTAssertTrue(collection.intersects(object[keyPath: otherSet.keyPath]))
            XCTAssertEqual(collection.count, 1)
            // The intersection should have assigned the last value from `values`
            XCTAssertTrue(collection.contains(set.values.last!))
        }

        // Delete the objects from the sets
        try write { realm in
            let object = realm.objects(SwiftCollectionSyncObject.self).first!
            object[keyPath: set.keyPath].removeAll()
            object[keyPath: otherSet.keyPath].removeAll()
        }
        XCTAssertEqual(collection.count, 0)
        XCTAssertEqual(otherCollection.count, 0)

        try write { realm in
            realm.deleteAll()
        }
        readRealm = nil
    }

    @MainActor
    func testSets() throws {
        try roundTrip(set: (\.intSet, [1, 2, 3]), otherSet: (\.otherIntSet, [3, 4, 5]))
        try roundTrip(set: (\.stringSet, ["Who", "What", "When"]),
                      otherSet: (\.otherStringSet, ["When", "Strings", "Collide"]))
        try roundTrip(set: (\.dataSet, [Data(repeating: 1, count: 64),
                                        Data(repeating: 2, count: 64),
                                        Data(repeating: 3, count: 64)]),
                      otherSet: (\.otherDataSet, [Data(repeating: 3, count: 64),
                                                  Data(repeating: 4, count: 64),
                                                  Data(repeating: 5, count: 64)]))
        try roundTrip(set: (\.dateSet, [Date(timeIntervalSince1970: 10000000),
                                        Date(timeIntervalSince1970: 20000000),
                                        Date(timeIntervalSince1970: 30000000)]),
                      otherSet: (\.otherDateSet, [Date(timeIntervalSince1970: 30000000),
                                                  Date(timeIntervalSince1970: 40000000),
                                                  Date(timeIntervalSince1970: 50000000)]))
        try roundTrip(set: (\.doubleSet, [123.456, 345.456, 789.456]),
                      otherSet: (\.otherDoubleSet, [789.456,
                                                    888.456,
                                                    987.456]))
        try roundTrip(set: (\.objectIdSet, [.init("6058f12b957ba06156586a7c"),
                                            .init("6058f12682b2fbb1f334ef1d"),
                                            .init("6058f12d42e5a393e67538d0")]),
                      otherSet: (\.otherObjectIdSet, [.init("6058f12d42e5a393e67538d0"),
                                                      .init("6058f12682b2fbb1f334ef1f"),
                                                      .init("6058f12d42e5a393e67538d1")]))
        try roundTrip(set: (\.decimalSet, [123.345,
                                           213.345,
                                           321.345]),
                      otherSet: (\.otherDecimalSet, [321.345,
                                                     333.345,
                                                     444.345]))
        try roundTrip(set: (\.uuidSet, [UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fd")!,
                                        UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fe")!,
                                        UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90ff")!]),
                      otherSet: (\.otherUuidSet, [UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90ff")!,
                                                  UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90ae")!,
                                                  UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90bf")!]))
        try roundTrip(set: (\.objectSet, [SwiftPerson(firstName: "Peter", lastName: "Parker"),
                                          SwiftPerson(firstName: "Bruce", lastName: "Wayne"),
                                          SwiftPerson(firstName: "Stephen", lastName: "Strange")]),
                      otherSet: (\.otherObjectSet, [SwiftPerson(firstName: "Stephen", lastName: "Strange"),
                                                    SwiftPerson(firstName: "Tony", lastName: "Stark"),
                                                    SwiftPerson(firstName: "Clark", lastName: "Kent")]))
        try roundTrip(set: (\.anySet, [.int(12345), .none, .string("Hello")]),
                      otherSet: (\.otherAnySet, [.string("Hello"), .double(765.6543), .objectId(.generate())]))
    }

    private typealias MapKeyPath<T: RealmCollectionValue> = KeyPath<SwiftCollectionSyncObject, Map<String, T>>

    @MainActor
    private func roundTrip<T>(keyPath: MapKeyPath<T>, values: [T],
                              partitionValue: String = #function) throws {
        autoreleasepool {
            readRealm = try! openRealm()
        }

        checkCount(expected: 0, readRealm, SwiftCollectionSyncObject.self)

        // Create the object
        try write { realm in
            realm.add(SwiftCollectionSyncObject())
        }
        checkCount(expected: 1, readRealm, SwiftCollectionSyncObject.self)
        let object = readRealm.objects(SwiftCollectionSyncObject.self).first!
        let collection = object[keyPath: keyPath]
        XCTAssertEqual(collection.count, 0)

        // Populate the collection
        try write { realm in
            let object = realm.objects(SwiftCollectionSyncObject.self).first!
            let collection = object[keyPath: keyPath]
            for (i, value) in values.enumerated() {
                collection["\(i)"] = value
            }
        }
        checkCount(expected: 1, readRealm, SwiftCollectionSyncObject.self)
        XCTAssertEqual(collection.count, values.count)
        for (i, value) in values.enumerated() {
            assertEqual(collection["\(i)"]!, value)
        }

        // Remove the last three objects from the collection
        try write { realm in
            let object = realm.objects(SwiftCollectionSyncObject.self).first!
            let collection = object[keyPath: keyPath]
            for i in 0..<3 {
                collection.removeObject(for: "\(i)")
            }
        }
        XCTAssertEqual(collection.count, values.count - 3)

        // Modify the first element
        try write { realm in
            let object = realm.objects(SwiftCollectionSyncObject.self).first!
            let collection = object[keyPath: keyPath]
            collection["3"] = collection["4"]
        }
        assertEqual(collection["3"]!, values[4])

        try write { realm in
            realm.deleteAll()
        }
        readRealm = nil
    }

    @MainActor
    func testMaps() throws {
        try roundTrip(keyPath: \.intMap, values: [1, 2, 3, 4, 5])
        try roundTrip(keyPath: \.stringMap, values: ["Who", "What", "When", "Strings", "Collide"])
        try roundTrip(keyPath: \.dataMap, values: [Data(repeating: 1, count: 64),
                                                   Data(repeating: 2, count: 64),
                                                   Data(repeating: 3, count: 64),
                                                   Data(repeating: 4, count: 64),
                                                   Data(repeating: 5, count: 64)])
        try roundTrip(keyPath: \.dateMap, values: [Date(timeIntervalSince1970: 10000000),
                                                   Date(timeIntervalSince1970: 20000000),
                                                   Date(timeIntervalSince1970: 30000000),
                                                   Date(timeIntervalSince1970: 40000000),
                                                   Date(timeIntervalSince1970: 50000000)])
        try roundTrip(keyPath: \.doubleMap, values: [123.456, 345.456, 789.456, 888.456, 987.456])
        try roundTrip(keyPath: \.objectIdMap, values: [ObjectId("6058f12b957ba06156586a7c"),
                                                       ObjectId("6058f12682b2fbb1f334ef1d"),
                                                       ObjectId("6058f12d42e5a393e67538d0"),
                                                       ObjectId("6058f12682b2fbb1f334ef1f"),
                                                       ObjectId("6058f12d42e5a393e67538d1")])
        try roundTrip(keyPath: \.decimalMap, values: [Decimal128(123.345),
                                                      Decimal128(213.345),
                                                      Decimal128(321.345),
                                                      Decimal128(333.345),
                                                      Decimal128(444.345)])
        try roundTrip(keyPath: \.uuidMap, values: [UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fd")!,
                                                   UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fe")!,
                                                   UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90ff")!,
                                                   UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90ae")!,
                                                   UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90bf")!])
        // FIXME: We need to add a test where a value in a map of objects is `null`. currently the server
        // is throwing a bad changeset error when that happens.
        try roundTrip(keyPath: \.objectMap, values: [SwiftPerson(firstName: "Peter", lastName: "Parker"),
                                                     SwiftPerson(firstName: "Bruce", lastName: "Wayne"),
                                                     SwiftPerson(firstName: "Stephen", lastName: "Strange"),
                                                     SwiftPerson(firstName: "Tony", lastName: "Stark"),
                                                     SwiftPerson(firstName: "Clark", lastName: "Kent")])
        try roundTrip(keyPath: \.anyMap, values: [.int(12345), .none, .string("Hello"), .double(765.6543),
                                                  .objectId(ObjectId("507f1f77bcf86cd799439011"))])
    }
}

@available(macOS 13, *)
class AsyncAnyRealmValueSyncTest: SwiftSyncTestCase {
    override class var defaultTestSuite: XCTestSuite {
        // async/await is currently incompatible with thread sanitizer and will
        // produce many false positives
        // https://bugs.swift.org/browse/SR-15444
        if RLMThreadSanitizerEnabled() {
            return XCTestSuite(name: "\(type(of: self))")
        }
        return super.defaultTestSuite
    }

    override func configuration(user: User) -> Realm.Configuration {
        user.flexibleSyncConfiguration(initialSubscriptions: {
            $0.append(QuerySubscription<SwiftTypesSyncObject>())
            $0.append(QuerySubscription<SwiftPerson>())
        })
    }

    override var objectTypes: [ObjectBase.Type] {
        [SwiftTypesSyncObject.self, SwiftPerson.self]
    }

    override func createApp() throws -> String {
        try createFlexibleSyncApp()
    }

    private var sampleData: Array<AnyRealmValue> {
        let so = SwiftPerson()
        so.firstName = name
        let oid = ObjectId.generate()
        let uuid = UUID()
        let date = Date()
        return [
            .string("hello"),
            .bool(false),
            .int(234),
            .double(12345.678901),
            .float(12.34),
            .data(Data("a".utf8)),
            .date(date),
            .object(so),
            .objectId(oid),
            .uuid(uuid),
            .decimal128(Decimal128(number: 567))
        ]
    }

    private func assertValue(_ value: AnyRealmValue, _ expectedValue: AnyRealmValue) {
        switch value {
        case .object:
            XCTAssertEqual(value.object(SwiftPerson.self)?.firstName, expectedValue.object(SwiftPerson.self)?.firstName)
        case .double:
            // All float values are converted to doubles in the server.
            if let floatValue = expectedValue.floatValue {
                XCTAssertEqual(value, .double(Double(floatValue)))
            } else {
                XCTAssertEqual(value, expectedValue)
            }
        case .date:
            // Date is not exact when synced
            XCTAssertTrue(Calendar.current.isDate(value.dateValue!, equalTo: expectedValue.dateValue!, toGranularity: .second))
        default:
            XCTAssertEqual(value, expectedValue)
        }
    }

    private func assertListEqual(_ object: SwiftTypesSyncObject, _ index: Int, _ expectedValue: AnyRealmValue) {
        let value: AnyRealmValue? = object.anyCol.listValue?[index]
        assertValue(value!, expectedValue)
    }

    private func assertDictionaryEqual(_ object: SwiftTypesSyncObject, _ key: String, _ expectedValue: AnyRealmValue) {
        let value: AnyRealmValue? = object.anyCol.dictionaryValue?[key]
        assertValue(value!, expectedValue)
    }

    @MainActor func testSyncAnyRealmValue() async throws {
        let list = sampleData
        try await write { realm in
            for (index, expectedValue) in list.enumerated() {
                let object = SwiftTypesSyncObject()
                object.anyCol = expectedValue
                object.stringCol = "\(self.name)_\(index)"
                realm.add(object)
            }
        }

        let realm = try await openRealm()
        for (index, expectedValue) in list.enumerated() {
            let results = realm.objects(SwiftTypesSyncObject.self).where { $0.stringCol == "\(self.name)_\(index)" }
            assertValue(results.first!.anyCol, expectedValue)
        }
    }

    @MainActor func testSyncMixedArray() async throws {
        let list = sampleData
        try await write { realm in
            let object = SwiftTypesSyncObject()
            object.anyCol = AnyRealmValue.fromArray(list)
            object.stringCol = self.name
            realm.add(object)
        }

        let realm = try await openRealm()
        let results = realm.objects(SwiftTypesSyncObject.self).where { $0.stringCol == name }
        XCTAssertEqual(results.count, 1)

        let obj = results.first!
        for (index, value) in list.enumerated() {
            assertListEqual(obj, index, value)
        }
    }

    @MainActor func testSyncMixedDictionary() async throws {
        let dictionary = Dictionary(uniqueKeysWithValues: sampleData.enumerated().map { ("\($0)", $1) })
        try await write { realm in
            let object = SwiftTypesSyncObject()
            object.anyCol = AnyRealmValue.fromDictionary(dictionary)
            object.stringCol = self.name
            realm.add(object)
        }

        let realm = try await openRealm()
        let results = realm.objects(SwiftTypesSyncObject.self).where { $0.stringCol == name }
        XCTAssertEqual(results.count, 1)

        let obj = results.first!
        for (key, value) in dictionary {
            assertDictionaryEqual(obj, key, value)
        }
    }

    @MainActor func testSyncMixedNestedArray() async throws {
        let so = SwiftPerson()
        so.firstName = "Doe"
        let subArray3: AnyRealmValue = AnyRealmValue.fromArray([ .object(so), .double(123.456) ])
        let subArray2: AnyRealmValue = AnyRealmValue.fromArray([ subArray3 ])
        let subArray1: AnyRealmValue = AnyRealmValue.fromArray([ subArray2 ])
        let array: Array<AnyRealmValue> = [
            subArray1, .bool(false)
        ]
        try await write { realm in
            let object = SwiftTypesSyncObject()
            object.anyCol = AnyRealmValue.fromArray(array)
            object.stringCol = self.name
            realm.add(object)
        }

        let realm = try await openRealm()
        let results = try await realm.objects(SwiftTypesSyncObject.self).where { $0.stringCol == name }.subscribe()
        XCTAssertEqual(results.count, 1)

        let listValue = results.first!.anyCol.listValue
        XCTAssertEqual(listValue?[1], .bool(false))
        XCTAssertEqual(listValue?[0].listValue?[0].listValue?[0].listValue?[1], .double(123.456))

        XCTAssertEqual(listValue?[0].listValue?[0].listValue?[0].listValue?[0].object(SwiftPerson.self)?.firstName, so.firstName)
        XCTAssertEqual(listValue?[1].boolValue, false)
        XCTAssertEqual(listValue?[0].listValue?[0].listValue?[0].listValue?[1].doubleValue, 123.456)
    }

    @MainActor func testSyncMixedNestedDictionary() async throws {
        let so = SwiftPerson()
        so.firstName = "Doe"
        let subDict3: AnyRealmValue = AnyRealmValue.fromDictionary([ "key4": .object(so), "key5": .int(1202) ])
        let subDict2: AnyRealmValue = AnyRealmValue.fromDictionary([ "key3": subDict3 ])
        let subDict1: AnyRealmValue = AnyRealmValue.fromDictionary([ "key2": subDict2 ])
        let dictionary: Dictionary<String, AnyRealmValue> = [
            "key0": subDict1,
            "key1": .bool(false)
        ]
        try await write { realm in
            let object = SwiftTypesSyncObject()
            object.anyCol = AnyRealmValue.fromDictionary(dictionary)
            object.stringCol = self.name
            realm.add(object)
        }

        let realm = try await openRealm()
        let results = realm.objects(SwiftTypesSyncObject.self).where { $0.stringCol == name }
        XCTAssertEqual(results.count, 1)

        let dictionaryValue = results.first!.anyCol.dictionaryValue
        XCTAssertEqual(dictionaryValue?["key1"], .bool(false))
        XCTAssertEqual(dictionaryValue?["key0"]?.dictionaryValue?["key2"]?.dictionaryValue?["key3"]?.dictionaryValue?["key5"], .int(1202))

        XCTAssertEqual(dictionaryValue?["key0"]?.dictionaryValue?["key2"]?.dictionaryValue?["key3"]?.dictionaryValue?["key4"]?.object(SwiftPerson.self)?.firstName, so.firstName)
        XCTAssertEqual(dictionaryValue?["key1"]?.boolValue, false)
        XCTAssertEqual(dictionaryValue?["key0"]?.dictionaryValue?["key2"]?.dictionaryValue?["key3"]?.dictionaryValue?["key5"]?.intValue, 1202)
    }

    @MainActor func testSyncMixedNestedCollection() async throws {
        let so = SwiftPerson()
        so.firstName = "Doe"
        let subArray2: AnyRealmValue = AnyRealmValue.fromArray([ .object(so), .decimal128(Decimal128(number: 457)) ])
        let subDict2: AnyRealmValue = AnyRealmValue.fromDictionary([ "key1": subArray2 ])
        let subArray3: AnyRealmValue = AnyRealmValue.fromArray([ subArray2, subDict2])
        let subDict3: AnyRealmValue = AnyRealmValue.fromDictionary([ "key2": subArray3 ])
        let subArray4: AnyRealmValue = AnyRealmValue.fromArray([ subDict3 ])
        let subDict4: AnyRealmValue = AnyRealmValue.fromDictionary([ "key3": subArray4 ])
        let subArray5: AnyRealmValue = AnyRealmValue.fromArray([ subDict4 ])
        let subDict5: AnyRealmValue = AnyRealmValue.fromDictionary([ "key4": subArray5 ])
        let subArray6: AnyRealmValue = AnyRealmValue.fromArray([ subDict5 ])
        let subDict6: AnyRealmValue = AnyRealmValue.fromDictionary([ "key5": subArray6 ])
        let dictionary: Dictionary<String, AnyRealmValue> = [
            "key0": subDict6,
        ]

        try await write { realm in
            let object = SwiftTypesSyncObject()
            object.anyCol = AnyRealmValue.fromDictionary(dictionary)
            object.stringCol = self.name
            realm.add(object)
        }

        let realm = try await openRealm()
        let results = realm.objects(SwiftTypesSyncObject.self).where { $0.stringCol == name }
        XCTAssertEqual(results.count, 1)

        let obj = results.first!
        let baseNested: List<AnyRealmValue>? = obj.anyCol.dictionaryValue?["key0"]?.dictionaryValue?["key5"]?.listValue?[0].dictionaryValue?["key4"]?.listValue?[0].dictionaryValue?["key3"]?.listValue
        let nested1: String? = baseNested?[0].dictionaryValue?["key2"]?.listValue?[0].listValue?[0].object(SwiftPerson.self)?.firstName
        XCTAssertEqual(nested1, so.firstName)
        let nested2: AnyRealmValue? = baseNested?[0].dictionaryValue?["key2"]?.listValue?[0].listValue?[1]
        XCTAssertEqual(nested2, .decimal128(Decimal128(number: 457)))
        let nested3: String? = baseNested?[0].dictionaryValue?["key2"]?.listValue?[1].dictionaryValue?["key1"]?.listValue?[0].object(SwiftPerson.self)?.firstName
        XCTAssertEqual(nested3, so.firstName)
        let nested4: AnyRealmValue? = baseNested?[0].dictionaryValue?["key2"]?.listValue?[1].dictionaryValue?["key1"]?.listValue?[1]
        XCTAssertEqual(nested4, .decimal128(Decimal128(number: 457)))

        XCTAssertEqual(nested2?.decimal128Value, Decimal128(number: 457))
        XCTAssertEqual(nested4?.decimal128Value, Decimal128(number: 457))
    }

    @MainActor func testUpdateMixedList() async throws {
        let realm1 = try await openRealm()
        let results1 = realm1.objects(SwiftTypesSyncObject.self).where { $0.stringCol == name }

        let realm2 = try await openRealm()
        let results2 = realm2.objects(SwiftTypesSyncObject.self).where { $0.stringCol == name }

        // Add initial list
        try realm1.write {
            let object = SwiftTypesSyncObject()
            object.anyCol = AnyRealmValue.fromArray([])
            object.stringCol = self.name
            realm1.add(object)
        }
        try await realm1.syncSession?.wait(for: .upload)
        try await realm2.syncSession?.wait(for: .download)
        await realm2.asyncRefresh()
        XCTAssertNotEqual(results2.first?.anyCol, .int(1))
        XCTAssertEqual(results2.first?.anyCol.listValue?.count, 0)

        let list = sampleData
        // Append new value to list
        for (index, value) in list.enumerated() {
            try realm1.write {
                results1.first?.anyCol.listValue?.append(value)
            }
            try await realm1.syncSession?.wait(for: .upload)
            try await realm2.syncSession?.wait(for: .download)
            await realm2.asyncRefresh()

            XCTAssertEqual(results1.first?.anyCol.listValue?.count, results2.first?.anyCol.listValue?.count)
            assertListEqual(results1.first!, index, value)
            assertListEqual(results2.first!, index, value)
        }

        // Remove value from list
        for value in list {
            try realm1.write {
                results1.first?.anyCol.listValue?.remove(at: 0)
            }
            try await realm1.syncSession?.wait(for: .upload)
            try await realm2.syncSession?.wait(for: .download)
            await realm2.asyncRefresh()

            XCTAssertEqual(results1.first?.anyCol.listValue?.count, results2.first?.anyCol.listValue?.count)
            XCTAssertFalse(results1.first?.anyCol.listValue?.contains(value) ?? true)
            XCTAssertFalse(results2.first?.anyCol.listValue?.contains(value) ?? true)
        }

        // insert value at index
        for value in list {
            try realm1.write {
                results1.first?.anyCol.listValue?.insert(value, at: 0)
            }
            try await realm1.syncSession?.wait(for: .upload)
            try await realm2.syncSession?.wait(for: .download)
            await realm2.asyncRefresh()

            XCTAssertEqual(results1.first?.anyCol.listValue?.count, results2.first?.anyCol.listValue?.count)
            assertListEqual(results1.first!, 0, value)
            assertListEqual(results2.first!, 0, value)
        }

        try realm1.write {
            results1.first?.anyCol.listValue?.removeAll()
        }
        try await realm1.syncSession?.wait(for: .upload)
        try await realm2.syncSession?.wait(for: .download)
        await realm2.asyncRefresh()
        XCTAssertEqual(results1.first?.anyCol.listValue?.count, results2.first?.anyCol.listValue?.count)
        XCTAssertEqual(results1.first?.anyCol.listValue?.count, 0)
        XCTAssertEqual(results2.first?.anyCol.listValue?.count, 0)
    }

    @MainActor func testUpdateMixedDictionary() async throws {
        let realm1 = try await openRealm()
        let results1 = realm1.objects(SwiftTypesSyncObject.self).where { $0.stringCol == name }

        let realm2 = try await openRealm()
        let results2 = realm2.objects(SwiftTypesSyncObject.self).where { $0.stringCol == name }

        // Add initial list
        try realm1.write {
            let object = SwiftTypesSyncObject()
            object.anyCol = AnyRealmValue.fromDictionary([:])
            object.stringCol = self.name
            realm1.add(object)
        }
        try await realm1.syncSession?.wait(for: .upload)
        try await realm2.syncSession?.wait(for: .download)
        await realm2.asyncRefresh()
        XCTAssertNotEqual(results2.first?.anyCol, .int(1))
        XCTAssertEqual(results2.first?.anyCol.dictionaryValue?.count, 0)

        let dictionary = Dictionary(uniqueKeysWithValues: sampleData.enumerated().map { ("\($0)", $1) })
        // Append new value to dictionary
        for (key, value) in dictionary {
            try realm1.write {
                results1.first?.anyCol.dictionaryValue?[key] = value
            }
            try await realm1.syncSession?.wait(for: .upload)
            try await realm2.syncSession?.wait(for: .download)
            await realm2.asyncRefresh()

            XCTAssertEqual(results1.first?.anyCol.dictionaryValue?.count, results2.first?.anyCol.dictionaryValue?.count)
            assertDictionaryEqual(results1.first!, key, value)
            assertDictionaryEqual(results2.first!, key, value)
        }

        // Remove value from list
        for (key, _) in dictionary {
            try realm1.write {
                results1.first?.anyCol.dictionaryValue?[key] = nil
            }
            try await realm1.syncSession?.wait(for: .upload)
            try await realm2.syncSession?.wait(for: .download)
            await realm2.asyncRefresh()

            XCTAssertEqual(results1.first?.anyCol.dictionaryValue?.count, results2.first?.anyCol.dictionaryValue?.count)
            XCTAssertFalse(results1.first?.anyCol.dictionaryValue?.contains(where: { $0.key == key }) ?? true)
            XCTAssertFalse(results2.first?.anyCol.dictionaryValue?.contains(where: { $0.key == key }) ?? true)
        }

        // insert value at index
        for (key, value) in dictionary {
            try realm1.write {
                results1.first?.anyCol.dictionaryValue?.setValue(value, forKey: key)
            }
            try await realm1.syncSession?.wait(for: .upload)
            try await realm2.syncSession?.wait(for: .download)
            await realm2.asyncRefresh()

            XCTAssertEqual(results1.first?.anyCol.dictionaryValue?.count, results2.first?.anyCol.dictionaryValue?.count)
            assertDictionaryEqual(results1.first!, key, value)
            assertDictionaryEqual(results2.first!, key, value)
        }

        try realm1.write {
            results1.first?.anyCol.dictionaryValue?.removeAll()
        }
        try await realm1.syncSession?.wait(for: .upload)
        try await realm2.syncSession?.wait(for: .download)
        await realm2.asyncRefresh()
        XCTAssertEqual(results1.first?.anyCol.dictionaryValue?.count, results2.first?.anyCol.dictionaryValue?.count)
        XCTAssertEqual(results1.first?.anyCol.dictionaryValue?.count, 0)
        XCTAssertEqual(results2.first?.anyCol.dictionaryValue?.count, 0)
    }

    @MainActor func testUpdateListTwoUsers() async throws {
        let realm1 = try await openRealm()
        let results1 = realm1.objects(SwiftTypesSyncObject.self).where { $0.stringCol == name }

        let realm2 = try await openRealm()
        let results2 = realm2.objects(SwiftTypesSyncObject.self).where { $0.stringCol == name }

        // Add initial list
        try realm1.write {
            let object = SwiftTypesSyncObject()
            object.anyCol = AnyRealmValue.fromArray([.string("John")])
            object.stringCol = self.name
            realm1.add(object)
        }
        try await realm1.syncSession?.wait(for: .upload)
        try await realm2.syncSession?.wait(for: .download)
        await realm2.asyncRefresh()

        try realm1.write {
            results1.first?.anyCol.listValue?.append(.bool(false))
        }

        try realm2.write {
            results2.first?.anyCol.listValue?.append(.bool(true))
        }

        try await realm1.syncSession?.wait(for: .upload)
        try await realm2.syncSession?.wait(for: .upload)
        try await realm1.syncSession?.wait(for: .download)
        try await realm2.syncSession?.wait(for: .download)

        XCTAssertEqual(results1.first?.anyCol.listValue?.count, results2.first?.anyCol.listValue?.count)
        (1..<3).forEach {
            XCTAssertEqual(results1.first?.anyCol.listValue?[$0], results2.first?.anyCol.listValue?[$0])
        }

        try realm1.write {
            results1.first?.anyCol.listValue?.insert(.int(32), at: 0)
        }

        try realm2.write {
            results2.first?.anyCol.listValue?.insert(.int(32), at: 0)
        }

        try await realm1.syncSession?.wait(for: .upload)
        try await realm2.syncSession?.wait(for: .upload)
        try await realm1.syncSession?.wait(for: .download)
        try await realm2.syncSession?.wait(for: .download)

        XCTAssertEqual(results1.first?.anyCol.listValue?.count, results2.first?.anyCol.listValue?.count)
        (1..<4).forEach {
            XCTAssertEqual(results1.first?.anyCol.listValue?[$0], results2.first?.anyCol.listValue?[$0])
        }

        try realm1.write {
            results1.first?.anyCol.listValue?.remove(at: 0)
        }

        try realm2.write {
            results2.first?.anyCol.listValue?.remove(at: 0)
        }

        try await realm1.syncSession?.wait(for: .upload)
        try await realm2.syncSession?.wait(for: .upload)
        try await realm1.syncSession?.wait(for: .download)
        try await realm2.syncSession?.wait(for: .download)

        XCTAssertEqual(results1.first?.anyCol.listValue?.count, results2.first?.anyCol.listValue?.count)
        (1..<3).forEach {
            XCTAssertEqual(results1.first?.anyCol.listValue?[$0], results2.first?.anyCol.listValue?[$0])
        }
    }

    @MainActor func testUpdateDictionaryTwoUsers() async throws {
        let realm1 = try await openRealm()
        let results1 = realm1.objects(SwiftTypesSyncObject.self).where { $0.stringCol == name }

        let realm2 = try await openRealm()
        let results2 = realm2.objects(SwiftTypesSyncObject.self).where { $0.stringCol == name }

        // Add initial list
        try realm1.write {
            let object = SwiftTypesSyncObject()
            object.anyCol = AnyRealmValue.fromDictionary(["\(0)": .string("John")])
            object.stringCol = self.name
            realm1.add(object)
        }
        try await realm1.syncSession?.wait(for: .upload)
        try await realm2.syncSession?.wait(for: .download)

        try realm1.write {
            results1.first?.anyCol.dictionaryValue?["\(1)"] = .bool(false)
        }

        try realm2.write {
            results2.first?.anyCol.dictionaryValue?["\(1)"] = .bool(true)
        }

        try await realm1.syncSession?.wait(for: .upload)
        try await realm2.syncSession?.wait(for: .upload)
        try await realm1.syncSession?.wait(for: .download)
        try await realm2.syncSession?.wait(for: .download)

        XCTAssertEqual(results1.first?.anyCol.dictionaryValue?.count, results2.first?.anyCol.dictionaryValue?.count)
        (1..<3).forEach {
            XCTAssertEqual(results1.first?.anyCol.dictionaryValue?["\($0)"], results2.first?.anyCol.dictionaryValue?["\($0)"])
        }

        XCTAssertEqual(results1.first?.anyCol.dictionaryValue?.count, results2.first?.anyCol.dictionaryValue?.count)
        (1..<2).forEach {
            XCTAssertEqual(results1.first?.anyCol.dictionaryValue?["\($0)"], results2.first?.anyCol.dictionaryValue?["\($0)"])
        }

        try realm1.write {
            results1.first?.anyCol.dictionaryValue?["\(0)"] = nil
        }

        try realm2.write {
            results2.first?.anyCol.dictionaryValue?["\(0)"] = nil
        }

        try await realm1.syncSession?.wait(for: .upload)
        try await realm2.syncSession?.wait(for: .upload)
        try await realm1.syncSession?.wait(for: .download)
        try await realm2.syncSession?.wait(for: .download)

        XCTAssertEqual(results1.first?.anyCol.dictionaryValue?.count, results2.first?.anyCol.dictionaryValue?.count)
        (1..<2).forEach {
            XCTAssertEqual(results1.first?.anyCol.dictionaryValue?["\($0)"], results2.first?.anyCol.dictionaryValue?["\($0)"])
        }
    }

    @MainActor func testAssignMixedListWithSamePrimaryKey() async throws {
        let realm1 = try await openRealm()
        let results1 = realm1.objects(SwiftTypesSyncObject.self).where { $0.stringCol == name }

        let realm2 = try await openRealm()
        let results2 = realm2.objects(SwiftTypesSyncObject.self).where { $0.stringCol == name }

        let primaryKey = ObjectId.generate()

        let object = SwiftTypesSyncObject(id: primaryKey)
        object.stringCol = name
        object.anyCol = AnyRealmValue.fromArray([.string("John")])
        try realm1.write {
            realm1.add(object)
        }

        let object2 = SwiftTypesSyncObject(id: primaryKey)
        object2.stringCol = name
        object2.anyCol = AnyRealmValue.fromArray([.string("Marie")])
        try realm2.write {
            realm2.add(object2)
        }

        try await realm1.syncSession?.wait(for: .upload)
        try await realm2.syncSession?.wait(for: .upload)
        try await realm1.syncSession?.wait(for: .download)
        try await realm2.syncSession?.wait(for: .download)

        XCTAssertEqual(results1.first?.anyCol.listValue?.count, 1)
        XCTAssertEqual(results2.first?.anyCol.listValue?.count, 1)
        XCTAssertEqual(results1.first?.anyCol.listValue?[0], results2.first?.anyCol.listValue?[0])
    }

    @MainActor func testAssignMixedDictionaryWithSamePrimaryKey() async throws {
        let realm1 = try await openRealm()
        let results1 = realm1.objects(SwiftTypesSyncObject.self).where { $0.stringCol == name }

        let realm2 = try await openRealm()
        let results2 = realm2.objects(SwiftTypesSyncObject.self).where { $0.stringCol == name }

        let primaryKey = ObjectId.generate()

        let object = SwiftTypesSyncObject(id: primaryKey)
        object.stringCol = name
        object.anyCol = AnyRealmValue.fromDictionary(["key": .string("John")])
        try realm1.write {
            realm1.add(object)
        }

        let object2 = SwiftTypesSyncObject(id: primaryKey)
        object2.stringCol = name
        object2.anyCol = AnyRealmValue.fromDictionary(["key1": .string("Marie")])
        try realm2.write {
            realm2.add(object2)
        }

        try await realm1.syncSession?.wait(for: .upload)
        try await realm2.syncSession?.wait(for: .upload)
        try await realm1.syncSession?.wait(for: .download)
        try await realm2.syncSession?.wait(for: .download)

        XCTAssertEqual(results1.first?.anyCol.dictionaryValue?.count, 1)
        XCTAssertEqual(results2.first?.anyCol.dictionaryValue?.count, 1)
    }
}
