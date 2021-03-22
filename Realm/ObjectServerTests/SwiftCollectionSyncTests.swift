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

class ListSwiftCollectionSyncTests: SwiftSyncTestCase {
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
                    XCTAssert(el == ex, "\(el) is not equal to \(ex)")
                }
                // Run the child again to delete the last 3 objects
                executeChild()
                waitForDownloads(for: realm)
                XCTAssertEqual(object[keyPath: keyPath].count, values.count)
                // Run the child again to modify the first element
                executeChild()
                waitForDownloads(for: realm)
                XCTAssertEqual(object[keyPath: keyPath][0], values[1])
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
                    try realm.write({
                        object[keyPath: keyPath][0] = values[1]
                    })
                    XCTAssertEqual(object[keyPath: keyPath][0], values[1])
                }
                waitForUploads(for: realm)
                checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
            }
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    func testIntList() {
        roundTrip(keyPath: \.intList, values: [1,2,3])
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
    func testAnyList() {
        roundTrip(keyPath: \.anyList, values: [.int(12345), .string("Hello"), .none])
    }
}

//class SetSwiftCollectionsyncTests: SwiftCollectionSyncTests {
//    func testSetOperations() {
//        do {
//            let user = try logInUser(for: basicCredentials())
//            let realm = try openRealm(partitionValue: #function, user: user)
//            if isParent {
//                waitForDownloads(for: realm)
//                checkCount(expected: 0, realm, SwiftCollectionSyncObject.self)
//                executeChild()
//                waitForDownloads(for: realm)
//                checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
//
//                let obj = realm.objects(SwiftCollectionSyncObject.self).first!
//
//                // 1, 2 ∪ 2, 3
//                XCTAssertFalse(obj.intSet1.isSubset(of: obj.intSet0))
//                // 1, 2 ∩ 2, 3
//                XCTAssertTrue(obj.intSet1.intersects(obj.intSet0))
//
//                try realm.write {
//                    realm.deleteAll()
//                }
//                waitForUploads(for: realm)
//            } else {
//                try realm.write({
//                    realm.add(SwiftCollectionSyncObject())
//                })
//                waitForUploads(for: realm)
//                checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
//            }
//        } catch {
//            XCTFail("Got an error: \(error)")
//        }
//
//    }
//    func testIntSet() {
//        roundTrip(type: MutableSet<Int>(), propertyName: "intSet")
//    }
//    func testStringSet() {
//        roundTrip(type: MutableSet<String>(), propertyName: "stringSet")
//    }
//    // !!!: Failure, reverses order?
//    func testDataSet() {
//        roundTrip(type: MutableSet<Data>(), propertyName: "dataSet")
//    }
//    // !!!: Failure, reverses order?
//    func testDateSet() {
//        roundTrip(type: MutableSet<Date>(), propertyName: "dateSet")
//    }
//    func testDoubleSet() {
//        roundTrip(type: MutableSet<Double>(), propertyName: "doubleSet")
//    }
//    func testObjectIdSet() {
//        roundTrip(type: MutableSet<ObjectId>(), propertyName: "objectIdSet")
//    }
//    // !!!: Failure, reverses order?
//    func testDecimalSet() {
//        roundTrip(type: MutableSet<Decimal128>(), propertyName: "decimalSet")
//    }
//    // !!!: Failure, reverses order?
//    func testUuidSet() {
//        roundTrip(type: MutableSet<UUID>(), propertyName: "uuidSet")
//    }
//
//}
