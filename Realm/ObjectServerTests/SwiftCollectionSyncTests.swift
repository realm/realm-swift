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

class ListSyncTests: SwiftSyncTestCase {
    private func roundTrip<T: _ManagedPropertyType>(keyPath: KeyPath<SwiftCollectionSyncObject, List<T>>,
                                                    values: [T],
                                                    partitionValue: String = #function) throws {
        let user = logInUser(for: basicCredentials(withName: partitionValue,
                                                   register: isParent))
        let realm = try openRealm(partitionValue: partitionValue, user: user)
        if isParent {
            checkCount(expected: 0, realm, SwiftCollectionSyncObject.self)
            executeChild()
            waitForDownloads(for: realm)
            checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
            // Run the child again to add the values
            executeChild()
            waitForDownloads(for: realm)
            checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
            let object = realm.objects(SwiftCollectionSyncObject.self).first!
            let collection = object[keyPath: keyPath]
            XCTAssertEqual(collection.count, values.count*2)
            for (el, ex) in zip(collection, values + values) {
                if let person = el as? SwiftPerson, let otherPerson = ex as? SwiftPerson {
                    XCTAssertEqual(person.firstName, otherPerson.firstName, "\(el) is not equal to \(ex)")
                } else {
                    XCTAssertEqual(el, ex)
                }
            }
            // Run the child again to delete the last 3 objects
            executeChild()
            waitForDownloads(for: realm)
            XCTAssertEqual(collection.count, values.count)
            // Run the child again to modify the first element
            executeChild()
            waitForDownloads(for: realm)
            if T.self is SwiftPerson.Type {
                XCTAssertEqual((collection as! List<SwiftPerson>)[0].firstName,
                               (values as! [SwiftPerson])[1].firstName)
            } else {
                XCTAssertEqual(collection[0], values[1])
            }
        } else {
            guard let object = realm.objects(SwiftCollectionSyncObject.self).first else {
                try realm.write({
                    realm.add(SwiftCollectionSyncObject())
                })
                waitForUploads(for: realm)
                checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
                return
            }
            let collection = object[keyPath: keyPath]

            if collection.count == 0 {
                try realm.write({
                    collection.append(objectsIn: values + values)
                })
                XCTAssertEqual(collection.count, values.count*2)
            } else if collection.count == 6 {
                try realm.write({
                    collection.removeSubrange(3...5)
                })
                XCTAssertEqual(collection.count, values.count)
            } else {
                if T.self is SwiftPerson.Type {
                    try realm.write({
                        (collection as! List<SwiftPerson>)[0].firstName
                            = (values as! [SwiftPerson])[1].firstName
                    })
                    XCTAssertEqual((collection as! List<SwiftPerson>)[0].firstName,
                                   (values as! [SwiftPerson])[1].firstName)
                } else {
                    try realm.write({
                        collection[0] = values[1]
                    })
                    XCTAssertEqual(collection[0], values[1])
                }
            }
            waitForUploads(for: realm)
            checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
        }
    }

    func testIntList() {
        do {
            try roundTrip(keyPath: \.intList, values: [1, 2, 3])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testBoolList() {
        do {
            try roundTrip(keyPath: \.boolList, values: [true, false, false])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testStringList() {
        do {
            try roundTrip(keyPath: \.stringList, values: ["Hey", "Hi", "Bye"])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDataList() {
        do {
            try roundTrip(keyPath: \.dataList, values: [Data(repeating: 0, count: 64),
                                                        Data(repeating: 1, count: 64),
                                                        Data(repeating: 2, count: 64)])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDateList() {
        do {
            try roundTrip(keyPath: \.dateList, values: [Date(timeIntervalSince1970: 10000000),
                                                        Date(timeIntervalSince1970: 20000000),
                                                        Date(timeIntervalSince1970: 30000000)])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDoubleList() {
        do {
            try roundTrip(keyPath: \.doubleList, values: [123.456, 234.456, 567.333])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testObjectIdList() {
        do {
            try roundTrip(keyPath: \.objectIdList, values: [.init("6058f12b957ba06156586a7c"),
                                                            .init("6058f12682b2fbb1f334ef1d"),
                                                            .init("6058f12d42e5a393e67538d0")])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDecimalList() {
        do {
            try roundTrip(keyPath: \.decimalList, values: [123.345,
                                                           213.345,
                                                           321.345])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUuidList() {
        do {
            try roundTrip(keyPath: \.uuidList, values: [UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fd")!,
                                                        UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fe")!,
                                                        UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90ff")!])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testObjectList() {
        do {
            try roundTrip(keyPath: \.objectList, values: [SwiftPerson(firstName: "Peter", lastName: "Parker"),
                                                          SwiftPerson(firstName: "Bruce", lastName: "Wayne"),
                                                          SwiftPerson(firstName: "Stephen", lastName: "Strange")])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}

class SetSyncTests: SwiftSyncTestCase {

    private typealias MutableSetKeyPath<T: RealmCollectionValue> = KeyPath<SwiftCollectionSyncObject, MutableSet<T>>
    private typealias MutableSetKeyValues<T: RealmCollectionValue> = (keyPath: MutableSetKeyPath<T>, values: [T])

    private func roundTrip<T: _ManagedPropertyType>(set: MutableSetKeyValues<T>,
                                                    otherSet: MutableSetKeyValues<T>,
                                                    partitionValue: String = #function) throws {
        let user = logInUser(for: basicCredentials(withName: partitionValue, register: isParent))
        let realm = try openRealm(partitionValue: partitionValue, user: user)
        if isParent {
            checkCount(expected: 0, realm, SwiftCollectionSyncObject.self)
            executeChild()
            waitForDownloads(for: realm)
            checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
            let object = realm.objects(SwiftCollectionSyncObject.self).first!
            // Run the child again to insert the values
            executeChild()
            waitForDownloads(for: realm)
            checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
            let collection = object[keyPath: set.keyPath]
            let otherCollection = object[keyPath: otherSet.keyPath]
            XCTAssertEqual(collection.count, set.values.count)
            XCTAssertEqual(otherCollection.count, otherSet.values.count)
            // Run the child again to intersect the values
            executeChild()
            waitForDownloads(for: realm)
            checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
            if !(T.self is SwiftPerson.Type) {
                XCTAssertTrue(collection.intersects(object[keyPath: otherSet.keyPath]))
                XCTAssertEqual(collection.count, 1)
            }
            // The intersection should have assigned the last value from `values`
            if !(T.self is SwiftPerson.Type) {
                XCTAssertTrue(collection.contains(set.values.last!))
            }
            // Run the child again to delete the objects in the sets.
            executeChild()
            waitForDownloads(for: realm)
            XCTAssertEqual(collection.count, 0)
            XCTAssertEqual(otherCollection.count, 0)
        } else {
            guard let object = realm.objects(SwiftCollectionSyncObject.self).first else {
                try realm.write({
                    realm.add(SwiftCollectionSyncObject())
                })
                waitForUploads(for: realm)
                checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
                return
            }
            let collection = object[keyPath: set.keyPath]
            let otherCollection = object[keyPath: otherSet.keyPath]
            if collection.count == 0,
               otherCollection.count == 0 {
                try realm.write({
                    collection.insert(objectsIn: set.values)
                    otherCollection.insert(objectsIn: otherSet.values)
                })
                XCTAssertEqual(collection.count, set.values.count)
                XCTAssertEqual(otherCollection.count, otherSet.values.count)
            } else if collection.count == 3,
                      otherCollection.count == 3 {
                if !(T.self is SwiftPerson.Type) {
                    try realm.write({
                        collection.formIntersection(otherCollection)
                    })
                } else {
                    try realm.write({
                        // formIntersection won't work with unique Objects
                        collection.removeAll()
                        collection.insert(set.values[0])
                    })
                }
                XCTAssertEqual(collection.count, 1)
                XCTAssertEqual(otherCollection.count, otherSet.values.count)
            } else {
                try realm.write({
                    collection.removeAll()
                    otherCollection.removeAll()
                })
                XCTAssertEqual(collection.count, 0)
                XCTAssertEqual(otherCollection.count, 0)
            }
            waitForUploads(for: realm)
            checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
        }
    }

    func testIntSet() {
        do {
            try roundTrip(set: (\.intSet, [1, 2, 3]), otherSet: (\.otherIntSet, [3, 4, 5]))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testStringSet() {
        do {
            try roundTrip(set: (\.stringSet, ["Who", "What", "When"]),
                          otherSet: (\.otherStringSet, ["When", "Strings", "Collide"]))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDataSet() {
        do {
            try roundTrip(set: (\.dataSet, [Data(repeating: 1, count: 64),
                                            Data(repeating: 2, count: 64),
                                            Data(repeating: 3, count: 64)]),
                          otherSet: (\.otherDataSet, [Data(repeating: 3, count: 64),
                                                      Data(repeating: 4, count: 64),
                                                      Data(repeating: 5, count: 64)]))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDateSet() {
        do {
            try roundTrip(set: (\.dateSet, [Date(timeIntervalSince1970: 10000000),
                                            Date(timeIntervalSince1970: 20000000),
                                            Date(timeIntervalSince1970: 30000000)]),
                          otherSet: (\.otherDateSet, [Date(timeIntervalSince1970: 30000000),
                                                      Date(timeIntervalSince1970: 40000000),
                                                      Date(timeIntervalSince1970: 50000000)]))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDoubleSet() {
        do {
            try roundTrip(set: (\.doubleSet, [123.456, 345.456, 789.456]),
                          otherSet: (\.otherDoubleSet, [789.456,
                                                        888.456,
                                                        987.456]))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testObjectIdSet() {
        do {
            try roundTrip(set: (\.objectIdSet, [.init("6058f12b957ba06156586a7c"),
                                                .init("6058f12682b2fbb1f334ef1d"),
                                                .init("6058f12d42e5a393e67538d0")]),
                          otherSet: (\.otherObjectIdSet, [.init("6058f12d42e5a393e67538d0"),
                                                          .init("6058f12682b2fbb1f334ef1f"),
                                                          .init("6058f12d42e5a393e67538d1")]))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDecimalSet() {
        do {
            try roundTrip(set: (\.decimalSet, [123.345,
                                               213.345,
                                               321.345]),
                          otherSet: (\.otherDecimalSet, [321.345,
                                                         333.345,
                                                         444.345]))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUuidSet() {
        do {
            try roundTrip(set: (\.uuidSet, [UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fd")!,
                                            UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fe")!,
                                            UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90ff")!]),
                          otherSet: (\.otherUuidSet, [UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90ff")!,
                                                      UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90ae")!,
                                                      UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90bf")!]))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testObjectSet() {
        do {
            try roundTrip(set: (\.objectSet, [SwiftPerson(firstName: "Peter", lastName: "Parker"),
                                              SwiftPerson(firstName: "Bruce", lastName: "Wayne"),
                                              SwiftPerson(firstName: "Stephen", lastName: "Strange")]),
                          otherSet: (\.otherObjectSet, [SwiftPerson(firstName: "Stephen", lastName: "Strange"),
                                                        SwiftPerson(firstName: "Tony", lastName: "Stark"),
                                                        SwiftPerson(firstName: "Clark", lastName: "Kent")]))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
