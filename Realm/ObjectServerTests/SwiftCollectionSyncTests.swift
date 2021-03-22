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

@available(OSX 10.14, *)
@objc(SwiftSyncCollectionSyncTests)
class SwiftCollectionSyncTests: SwiftSyncTestCase {
    func roundTrip<T: RealmCollectionBase>(type: T, propertyName: String) {
        do {
            guard SwiftCollectionSyncObject()[propertyName] != nil else {
                XCTFail("Property name does not exist on object")
                return
            }
            let user = try logInUser(for: basicCredentials())
            let realm = try openRealm(partitionValue: #function, user: user)

            if isParent {
                waitForDownloads(for: realm)
                checkCount(expected: 0, realm, SwiftCollectionSyncObject.self)
                executeChild()
                waitForDownloads(for: realm)
                checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)

                let obj = realm.objects(SwiftCollectionSyncObject.self).first!
                let collection = obj[propertyName] as! T
                let expected = SwiftCollectionSyncObject()[propertyName] as! T
                for (el, ex) in zip(collection, expected) {
                    XCTAssert(el == ex, "\(el) is not equal to \(ex)")
                }

                try realm.write {
                    realm.deleteAll()
                }
                waitForUploads(for: realm)
            } else {
                try realm.write({
                    realm.add(SwiftCollectionSyncObject())
                })
                waitForUploads(for: realm)
                checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
            }
        } catch {
            XCTFail("Got an error: \(error)")
        }
    }
}

class ListSwiftCollectionSyncTests: SwiftCollectionSyncTests {
    func testIntList() {
        roundTrip(type: List<Int>(), propertyName: "intList")
    }
    func testBoolList() {
        roundTrip(type: List<Bool>(), propertyName: "boolList")
    }
    func testStringList() {
        roundTrip(type: List<String>(), propertyName: "stringList")
    }
    func testDataList() {
        roundTrip(type: List<Data>(), propertyName: "dataList")
    }
    func testDateList() {
        roundTrip(type: List<Date>(), propertyName: "dateList")
    }
    func testDoubleList() {
        roundTrip(type: List<Double>(), propertyName: "doubleList")
    }
    func testObjectIdList() {
        roundTrip(type: List<ObjectId>(), propertyName: "objectIdList")
    }
    func testDecimalList() {
        roundTrip(type: List<Decimal128>(), propertyName: "decimalList")
    }
    func testUuidList() {
        roundTrip(type: List<UUID>(), propertyName: "uuidList")
    }
    func testAnyList() {
        roundTrip(type: List<AnyRealmValue>(), propertyName: "anyList")
    }
}

class SetSwiftCollectionsyncTests: SwiftCollectionSyncTests {
    func testSetOperations() {
        do {
            let user = try logInUser(for: basicCredentials())
            let realm = try openRealm(partitionValue: #function, user: user)
            if isParent {
                waitForDownloads(for: realm)
                checkCount(expected: 0, realm, SwiftCollectionSyncObject.self)
                executeChild()
                waitForDownloads(for: realm)
                checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)

                let obj = realm.objects(SwiftCollectionSyncObject.self).first!

                // 1, 2 ∪ 2, 3
                XCTAssertFalse(obj.intSet1.isSubset(of: obj.intSet0))
                // 1, 2 ∩ 2, 3
                XCTAssertTrue(obj.intSet1.intersects(obj.intSet0))

                try realm.write {
                    realm.deleteAll()
                }
                waitForUploads(for: realm)
            } else {
                try realm.write({
                    realm.add(SwiftCollectionSyncObject())
                })
                waitForUploads(for: realm)
                checkCount(expected: 1, realm, SwiftCollectionSyncObject.self)
            }
        } catch {
            XCTFail("Got an error: \(error)")
        }

    }
    func testIntSet() {
        roundTrip(type: MutableSet<Int>(), propertyName: "intSet")
    }
    func testStringSet() {
        roundTrip(type: MutableSet<String>(), propertyName: "stringSet")
    }
    // !!!: Failure, reverses order?
    func testDataSet() {
        roundTrip(type: MutableSet<Data>(), propertyName: "dataSet")
    }
    // !!!: Failure, reverses order?
    func testDateSet() {
        roundTrip(type: MutableSet<Date>(), propertyName: "dateSet")
    }
    func testDoubleSet() {
        roundTrip(type: MutableSet<Double>(), propertyName: "doubleSet")
    }
    func testObjectIdSet() {
        roundTrip(type: MutableSet<ObjectId>(), propertyName: "objectIdSet")
    }
    // !!!: Failure, reverses order?
    func testDecimalSet() {
        roundTrip(type: MutableSet<Decimal128>(), propertyName: "decimalSet")
    }
    // !!!: Failure, reverses order?
    func testUuidSet() {
        roundTrip(type: MutableSet<UUID>(), propertyName: "uuidSet")
    }

}
