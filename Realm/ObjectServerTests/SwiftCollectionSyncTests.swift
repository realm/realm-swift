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
                                                    values: [T]) {
        do {
            let user = try logInUser(for: basicCredentials())
            let realm = try openRealm(partitionValue: #function, user: user)
            if isParent {
                try realm.write {
                    realm.deleteAll()
                }
                waitForDownloads(for: realm)
                checkCount(expected: 0, realm, SwiftCollectionSyncObject.self)
                executeChild()
                waitForDownloads(for: realm)
                checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
                // Run the child again to add the values
                executeChild()
                waitForDownloads(for: realm)
                checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
                let object = realm.objects(SwiftCollectionSyncObject.self).first!
                XCTAssertEqual(object[keyPath: keyPath].count, values.count*2)
                for (el, ex) in zip(object[keyPath: keyPath], values + values) {
                    if let person = el as? SwiftPerson,
                       let otherPerson = ex as? SwiftPerson {
                        XCTAssert(person.firstName == otherPerson.firstName, "\(el) is not equal to \(ex)")

                    } else {
                        XCTAssert(el == ex, "\(el) is not equal to \(ex)")
                    }
                }
                // Run the child again to delete the last 3 objects
                executeChild()
                waitForDownloads(for: realm)
                XCTAssertEqual(object[keyPath: keyPath].count, values.count)
                // Run the child again to modify the first element
                executeChild()
                waitForDownloads(for: realm)
                if T.self is SwiftPerson.Type {
                    XCTAssertEqual((object[keyPath: keyPath] as! List<SwiftPerson>)[0].firstName,
                                   (values as! [SwiftPerson])[1].firstName)
                } else {
                    XCTAssertEqual(object[keyPath: keyPath][0], values[1])
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

                if object[keyPath: keyPath].count == 0 {
                    try realm.write({
                        object[keyPath: keyPath].append(objectsIn: values + values)
                    })
                    XCTAssertEqual(object[keyPath: keyPath].count, values.count*2)
                } else if object[keyPath: keyPath].count == 6 {
                    try realm.write({
                        object[keyPath: keyPath].removeSubrange(3...5)
                    })
                    XCTAssertEqual(object[keyPath: keyPath].count, values.count)
                } else {
                    if T.self is SwiftPerson.Type {
                        try realm.write({
                            (object[keyPath: keyPath] as! List<SwiftPerson>)[0].firstName
                                = (values as! [SwiftPerson])[1].firstName
                        })
                        XCTAssertEqual((object[keyPath: keyPath] as! List<SwiftPerson>)[0].firstName,
                                       (values as! [SwiftPerson])[1].firstName)
                    } else {
                        try realm.write({
                            object[keyPath: keyPath][0] = values[1]
                        })
                        XCTAssertEqual(object[keyPath: keyPath][0], values[1])
                    }
                }
                waitForUploads(for: realm)
                checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
            }
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    func testIntList() {
        roundTrip(keyPath: \.intList, values: [1, 2, 3])
    }

    func testBoolList() {
        roundTrip(keyPath: \.boolList, values: [true, false, false])
    }

    func testStringList() {
        roundTrip(keyPath: \.stringList, values: ["Hey", "Hi", "Bye"])
    }

    func testDataList() {
        roundTrip(keyPath: \.dataList, values: [Data(repeating: 0, count: 1024*8*1024),
                                                Data(repeating: 1, count: 256),
                                                Data(repeating: 2, count: 64)])
    }

    func testDateList() {
        roundTrip(keyPath: \.dateList, values: [Date(timeIntervalSince1970: 10000000),
                                                Date(timeIntervalSince1970: 20000000),
                                                Date(timeIntervalSince1970: 30000000)])
    }

    func testDoubleList() {
        roundTrip(keyPath: \.doubleList, values: [123.456, 234.456, 567.333])
    }

    func testObjectIdList() {
        roundTrip(keyPath: \.objectIdList, values: [.init("6058f12b957ba06156586a7c"),
                                                    .init("6058f12682b2fbb1f334ef1d"),
                                                    .init("6058f12d42e5a393e67538d0")])
    }

    func testDecimalList() {
        roundTrip(keyPath: \.decimalList, values: [123.345,
                                                   213.345,
                                                   321.345])
    }

    func testUuidList() {
        roundTrip(keyPath: \.uuidList, values: [UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fd")!,
                                                UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fe")!,
                                                UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90ff")!])
    }

    func testObjectList() {
        roundTrip(keyPath: \.objectList, values: [SwiftPerson(firstName: "Peter", lastName: "Parker"),
                                                  SwiftPerson(firstName: "Bruce", lastName: "Wayne"),
                                                  SwiftPerson(firstName: "Stephen", lastName: "Strange")])
    }
}

class SetSyncTests: SwiftSyncTestCase {

    private typealias MutableSetKeyPath<T: RealmCollectionValue> = KeyPath<SwiftCollectionSyncObject, MutableSet<T>>
    private typealias MutableSetKeyValues<T: RealmCollectionValue> = (keyPath: MutableSetKeyPath<T>, values: [T])

    private func roundTrip<T: _ManagedPropertyType>(set: MutableSetKeyValues<T>,
                                                    otherSet: MutableSetKeyValues<T>) throws {
        let user = try logInUser(for: basicCredentials())
        let realm = try openRealm(partitionValue: #function, user: user)
        if isParent {
            try realm.write {
                realm.deleteAll()
            }
            waitForDownloads(for: realm)
            checkCount(expected: 0, realm, SwiftCollectionSyncObject.self)
            executeChild()
            waitForDownloads(for: realm)
            checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
            let object = realm.objects(SwiftCollectionSyncObject.self).first!
            // Run the child again to insert the values
            executeChild()
            waitForDownloads(for: realm)
            checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
            XCTAssertEqual(object[keyPath: set.keyPath].count, set.values.count)
            XCTAssertEqual(object[keyPath: otherSet.keyPath].count, otherSet.values.count)
            // Run the child again to intersect the values
            executeChild()
            waitForDownloads(for: realm)
            checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
            if !(T.self is SwiftPerson.Type) {
                XCTAssertTrue(object[keyPath: set.keyPath].intersects(object[keyPath: otherSet.keyPath]))
                XCTAssertEqual(object[keyPath: set.keyPath].count, 1)
            }
            // The intersection should have assigned the last value from `values`
            if !(T.self is SwiftPerson.Type) {
                XCTAssertTrue(object[keyPath: set.keyPath].contains(set.values.last!))
            }
            // Run the child again to delete the objects in the sets.
            executeChild()
            waitForDownloads(for: realm)
            XCTAssertEqual(object[keyPath: set.keyPath].count, 0)
            XCTAssertEqual(object[keyPath: otherSet.keyPath].count, 0)
        } else {
            guard let object = realm.objects(SwiftCollectionSyncObject.self).first else {
                try realm.write({
                    realm.add(SwiftCollectionSyncObject())
                })
                waitForUploads(for: realm)
                checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
                return
            }
            if object[keyPath: set.keyPath].count == 0,
               object[keyPath: otherSet.keyPath].count == 0 {
                try realm.write({
                    object[keyPath: set.keyPath].insert(objectsIn: set.values)
                    object[keyPath: otherSet.keyPath].insert(objectsIn: otherSet.values)
                })
                XCTAssertEqual(object[keyPath: set.keyPath].count, set.values.count)
                XCTAssertEqual(object[keyPath: otherSet.keyPath].count, otherSet.values.count)
            } else if object[keyPath: set.keyPath].count == 3,
                      object[keyPath: otherSet.keyPath].count == 3 {
                if !(T.self is SwiftPerson.Type) {
                    try realm.write({
                        object[keyPath: set.keyPath].formIntersection(object[keyPath: otherSet.keyPath])
                    })
                } else {
                    try realm.write({
                        // formIntersection won't work with unique Objects
                        object[keyPath: set.keyPath].removeAll()
                        object[keyPath: set.keyPath].insert(set.values[0])
                    })
                }
                XCTAssertEqual(object[keyPath: set.keyPath].count, 1)
                XCTAssertEqual(object[keyPath: otherSet.keyPath].count, otherSet.values.count)
            } else {
                try realm.write({
                    object[keyPath: set.keyPath].removeAll()
                    object[keyPath: otherSet.keyPath].removeAll()
                })
                XCTAssertEqual(object[keyPath: set.keyPath].count, 0)
                XCTAssertEqual(object[keyPath: otherSet.keyPath].count, 0)
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
// FIXME: needs investigation on core side
//    func testDataSet() {
//        do {
//            try roundTrip(set: (\.dataSet, [Data(repeating: 1, count: 1024),
//                                            Data(repeating: 1, count: 256),
//                                            Data(repeating: 2, count: 64)]),
//                          otherSet: (\.otherDataSet, [Data(repeating: 2, count: 64),
//                                                      Data(repeating: 3, count: 256),
//                                                      Data(repeating: 4, count: 1024)]))
//        } catch {
//            XCTFail(error.localizedDescription)
//        }
//    }

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
