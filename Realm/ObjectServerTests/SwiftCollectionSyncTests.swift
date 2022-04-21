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

class CollectionSyncTestCase: SwiftSyncTestCase {
    var readRealm: Realm!
    var writeRealm: Realm!

    override func setUp() {
        super.setUp()

        let readUser = logInUser(for: basicCredentials(name: self.name + " read user", register: true))
        let writeUser = logInUser(for: basicCredentials(name: self.name + " write user", register: true))
        // This autoreleasepool is needed to ensure that the Realms are closed
        // immediately in tearDown() rather than escaping to an outer pool.
        autoreleasepool {
            readRealm = try! openRealm(partitionValue: self.name, user: readUser)
            writeRealm = try! openRealm(partitionValue: self.name, user: writeUser)
        }
    }

    override func tearDown() {
        readRealm = nil
        writeRealm = nil
        super.tearDown()
    }

    func write(_ fn: (Realm) -> Void) throws {
        try writeRealm.write {
            fn(writeRealm)
        }
        waitForUploads(for: writeRealm)
        waitForDownloads(for: readRealm)
    }

    func assertEqual<T: RealmCollectionValue>(_ left: T, _ right: T, _ line: UInt = #line) {
        if let person = left as? SwiftPerson, let otherPerson = right as? SwiftPerson {
            XCTAssertEqual(person.firstName, otherPerson.firstName, line: line)
        } else {
            XCTAssertEqual(left, right, line: line)
        }
    }

    private func roundTrip<T>(keyPath: KeyPath<SwiftCollectionSyncObject, List<T>>,
                              values: [T], partitionValue: String = #function) throws {
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
    }

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

    private func roundTrip<T>(set: MutableSetKeyValues<T>,
                              otherSet: MutableSetKeyValues<T>,
                              partitionValue: String = #function) throws {
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
                collection.insert(set.values[0])
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
    }

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

    private func roundTrip<T>(keyPath: MapKeyPath<T>, values: [T],
                              partitionValue: String = #function) throws {
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
    }

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
