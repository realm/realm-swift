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
import RealmSwift
import XCTest

#if canImport(RealmTestSupport)
import RealmSwiftSyncTestSupport
import RealmSyncTestSupport
import RealmTestSupport
import SwiftUI
#endif

class SwiftFlexibleSyncTestCase: SwiftSyncTestCase {
    func openFlexibleSyncRealmForUser(_ user: User) throws -> Realm {
        var config = user.flexibleSyncConfiguration()
        if config.objectTypes == nil {
            config.objectTypes = [SwiftPerson.self,
                                  SwiftTypesSyncObject.self]
        }
        let realm = try Realm(configuration: config)
        return realm
    }

    func openFlexibleSyncRealm() throws -> Realm {
        let appId = try RealmServer.shared.createAppForSyncMode(.flx(["age", "boolCol", "dateCol", "firstName", "lastName", "stringCol", "intCol"]))
        let flexibleApp = app(fromAppId: appId)
        let user = try logInUser(for: basicCredentials(app: flexibleApp), app: flexibleApp)
        return try openFlexibleSyncRealmForUser(user)
    }
}

class SwiftFlexibleSyncTests: SwiftFlexibleSyncTestCase {
    func testCreateFlexibleSyncApp() throws {
        let appId = try RealmServer.shared.createAppForSyncMode(.flx(["age"]))
        let flexibleApp = app(fromAppId: appId)
        let user = try logInUser(for: basicCredentials(app: flexibleApp), app: flexibleApp)
        XCTAssertNotNil(user)
    }

    func testFlexibleSyncOpenRealm() throws {
        let realm = try openFlexibleSyncRealm()
        XCTAssertNotNil(realm)
    }

    func testGetSubscriptionsWhenLocalRealm() throws {
        let realm = try Realm()
        XCTAssertNil(realm.subscriptions)
    }
 
    func testGetSubscriptionsWhenPbsRealm() throws {
        let user = try logInUser(for: basicCredentials())
        let realm = try openRealm(partitionValue: #function, user: user)
        XCTAssertNil(realm.subscriptions)
    }

    func testGetSubscriptions() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions!
        XCTAssertEqual(subscriptions.count, 0)
    }

    func testWriteEmptyBlock() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions!
        try subscriptions.write {
        }

        XCTAssertEqual(subscriptions.count, 0)
    }

    func testAddOneSubscriptionWithoutName() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions!
        try subscriptions.write {
            subscriptions.append {
                QuerySubscription<SwiftPerson> {
                    $0.age > 15
                }
            }
        }

        XCTAssertEqual(subscriptions.count, 1)
    }

    func testAddOneSubscriptionWithName() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions!
        try subscriptions.write {
            subscriptions.append {
                QuerySubscription<SwiftPerson>(name: "person_age") {
                    $0.age > 15
                }
            }
        }

        XCTAssertEqual(subscriptions.count, 1)
    }


    func testAddSubscriptionsInDifferentBlocks() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions!
        try subscriptions.write {
            subscriptions.append {
                QuerySubscription<SwiftPerson>(name: "person_age") {
                    $0.age > 15
                }
            }
        }
        try subscriptions.write {
            subscriptions.append {
                QuerySubscription<SwiftTypesSyncObject> {
                    $0.boolCol == true
                }
            }
        }

        XCTAssertEqual(subscriptions.count, 2)
    }

    func testAddSeveralSubscriptionsWithoutName() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions!
        try subscriptions.write {
            #if swift(>=5.5)
            subscriptions.append {
                QuerySubscription<SwiftPerson> {
                    $0.age > 15
                }
                QuerySubscription<SwiftPerson> {
                    $0.age > 20
                }
                QuerySubscription<SwiftPerson> {
                    $0.age > 25
                }
            }
            #else
            subscriptions.append {
                QuerySubscription<SwiftPerson> {
                    $0.age > 15
                }
            }
            subscriptions.append {
                QuerySubscription<SwiftPerson> {
                    $0.age > 20
                }
            }
            subscriptions.append {
                QuerySubscription<SwiftPerson> {
                    $0.age > 25
                }
            }
            #endif // swift(>=5.5)
        }

        XCTAssertEqual(subscriptions.count, 3)
    }

    func testAddSeveralSubscriptionsWithName() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions!
        try subscriptions.write {
            #if swift(>=5.5)
            subscriptions.append {
                QuerySubscription<SwiftPerson>(name: "person_age_15") {
                    $0.age > 15
                }
                QuerySubscription<SwiftPerson>(name: "person_age_20") {
                    $0.age > 20
                }
                QuerySubscription<SwiftPerson>(name: "person_age_25") {
                    $0.age > 25
                }
            }
            #else
            subscriptions.append {
                QuerySubscription<SwiftPerson>(name: "person_age_15") {
                    $0.age > 15
                }
            }
            subscriptions.append {
                QuerySubscription<SwiftPerson>(name: "person_age_20") {
                    $0.age > 20
                }
            }
            subscriptions.append {
                QuerySubscription<SwiftPerson>(name: "person_age_25") {
                    $0.age > 25
                }
            }
            #endif // swift(>=5.5)
        }
        XCTAssertEqual(subscriptions.count, 3)
    }

    func testAddMixedSubscriptions() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions!
        try subscriptions.write {
            subscriptions.append {
                QuerySubscription<SwiftPerson>(name: "person_age_15") {
                    $0.age > 15
                }
            }
            #if swift(>=5.5)
            subscriptions.append {
                QuerySubscription<SwiftTypesSyncObject> {
                    $0.boolCol == true
                }
                QuerySubscription<SwiftTypesSyncObject>(name: "object_date_now") {
                    $0.dateCol <= Date()
                }
            }
            #else
            subscriptions.append {
                QuerySubscription<SwiftTypesSyncObject> {
                    $0.boolCol == true
                }
            }
            subscriptions.append {
                QuerySubscription<SwiftTypesSyncObject>(name: "object_date_now") {
                    $0.dateCol <= Date()
                }
            }
            #endif // swift(>=5.5)
        }
        XCTAssertEqual(subscriptions.count, 3)
    }

    func testAddDuplicateSubscriptions() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions!
        try subscriptions.write {
            #if swift(>=5.5)
            subscriptions.append {
                QuerySubscription<SwiftPerson> {
                    $0.age > 15
                }
                QuerySubscription<SwiftPerson> {
                    $0.age > 15
                }
            }
            #else
            subscriptions.append {
                QuerySubscription<SwiftPerson> {
                    $0.age > 15
                }
            }
            subscriptions.append {
                QuerySubscription<SwiftPerson> {
                    $0.age > 15
                }
            }
            #endif // swift(>=5.5)
        }
        XCTAssertEqual(subscriptions.count, 1)
    }

    func testAddDuplicateSubscriptionWithDifferentName() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions!
        try subscriptions.write {
            #if swift(>=5.5)
            subscriptions.append {
                QuerySubscription<SwiftPerson>(name: "person_age_1") {
                    $0.age > 15
                }
                QuerySubscription<SwiftPerson>(name: "person_age_2") {
                    $0.age > 15
                }
            }
            #else
            subscriptions.append {
                QuerySubscription<SwiftPerson>(name: "person_age_1") {
                    $0.age > 15
                }
            }
            subscriptions.append {
                QuerySubscription<SwiftPerson>(name: "person_age_2") {
                    $0.age > 15
                }
            }
            #endif // swift(>=5.5)
        }
        XCTAssertEqual(subscriptions.count, 2)
    }

    // Test duplicate named subscription handle error
    func testSameNamedSubscriptionThrows() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions!
        try subscriptions.write {
            #if swift(>=5.5)
            subscriptions.append {
                QuerySubscription<SwiftPerson>(name: "person_age_1") {
                    $0.age > 15
                }
                QuerySubscription<SwiftPerson>(name: "person_age_1") {
                    $0.age > 20
                }
            }
            #else
            subscriptions.append {
                QuerySubscription<SwiftPerson>(name: "person_age_1") {
                    $0.age > 15
                }
            }
            subscriptions.append {
                QuerySubscription<SwiftPerson>(name: "person_age_1") {
                    $0.age > 20
                }
            }
            #endif // swift(>=5.5)
        }
        XCTAssertEqual(subscriptions.count, 1)
    }

    func testFindSubscriptionByName() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions!
        try subscriptions.write {
            #if swift(>=5.5)
            subscriptions.append {
                QuerySubscription<SwiftPerson>(name: "person_age_15") {
                    $0.age > 15
                }
                QuerySubscription<SwiftPerson>(name: "person_age_20") {
                    $0.age > 20
                }
            }
            #else
            subscriptions.append {
                QuerySubscription<SwiftPerson>(name: "person_age_15") {
                    $0.age > 15
                }
            }
            subscriptions.append {
                QuerySubscription<SwiftPerson>(name: "person_age_20") {
                    $0.age > 20
                }
            }
            #endif // swift(>=5.5)
        }
        XCTAssertEqual(subscriptions.count, 2)

        let foundSubscription1 = subscriptions.first(named: "person_age_15")
        XCTAssertNotNil(foundSubscription1)
        XCTAssertEqual(foundSubscription1!.name, "person_age_15")

        let foundSubscription2 = subscriptions.first(named: "person_age_20")
        XCTAssertNotNil(foundSubscription2)
        XCTAssertEqual(foundSubscription2!.name, "person_age_20")
    }

    func testFindSubscriptionByQuery() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions!
        try subscriptions.write {
            subscriptions.append {
                QuerySubscription<SwiftPerson>(name: "person_firstname_james") {
                    $0.firstName == "James"
                }
            }
            subscriptions.append {
                QuerySubscription<SwiftTypesSyncObject>(name: "object_int_more_than_zero") {
                    $0.intCol > 0
                }
            }
        }
        XCTAssertEqual(subscriptions.count, 2)

        let foundSubscription1 = subscriptions.first {
            QuerySubscription<SwiftPerson> {
                $0.firstName.contains("J")
            }
        }
        XCTAssertNotNil(foundSubscription1)
        XCTAssertEqual(foundSubscription1!.name, "person_firstname_james")

        let foundSubscription2 = subscriptions.first {
            QuerySubscription<SwiftTypesSyncObject>(name: "object_int_more_than_zero") {
                $0.intCol > 0
            }
        }
        XCTAssertNotNil(foundSubscription2)
        XCTAssertEqual(foundSubscription2!.name, "object_int_more_than_zero")
    }

    func testRemoveSubscriptionByName() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions!
        try subscriptions.write {
            subscriptions.append {
                QuerySubscription<SwiftPerson>(name: "person_firstname_james") {
                    $0.firstName == "James"
                }
            }
            #if swift(>=5.5)
            subscriptions.append {
                QuerySubscription<SwiftTypesSyncObject>(name: "object_int_more_than_zero") {
                    $0.intCol > 0
                }
                QuerySubscription<SwiftTypesSyncObject>(name: "object_string") {
                    $0.stringCol == "John" || $0.stringCol == "Tom"
                }
            }
            #else
            subscriptions.append {
                QuerySubscription<SwiftTypesSyncObject>(name: "object_int_more_than_zero") {
                    $0.intCol > 0
                }
            }
            subscriptions.append {
                QuerySubscription<SwiftTypesSyncObject>(name: "object_string") {
                    $0.stringCol == "John" || $0.stringCol == "Tom"
                }
            }
            #endif // swift(>=5.5)
        }
        XCTAssertEqual(subscriptions.count, 3)

        try subscriptions.write {
            subscriptions.remove(named: "person_firstname_james")
        }
        XCTAssertEqual(subscriptions.count, 2)
    }

    func testRemoveSubscriptionByQuery() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions!
        try subscriptions.write {
            #if swift(>=5.5)
            subscriptions.append {
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Alex"
                }
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Belle"
                }
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Charles"
                }
            }
            #else
            subscriptions.append {
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Alex"
                }
            }
            subscriptions.append {
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Belle"
                }
            }
            subscriptions.append {
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Charles"
                }
            }
            #endif // swift(>=5.5)
            subscriptions.append {
                QuerySubscription<SwiftTypesSyncObject> {
                    $0.intCol > 0
                }
            }
        }
        XCTAssertEqual(subscriptions.count, 4)

        try subscriptions.write {
            #if swift(>=5.5)
            subscriptions.remove {
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Alex"
                }
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Belle"
                }
            }
            #else
            subscriptions.remove {
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Alex"
                }
            }
            subscriptions.remove {
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Belle"
                }
            }
            #endif // swift(>=5.5)
            subscriptions.remove {
                QuerySubscription<SwiftTypesSyncObject> {
                    $0.intCol > 0
                }
            }
        }
        XCTAssertEqual(subscriptions.count, 1)
    }

    func testRemoveSubscription() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions!
        try subscriptions.write {
            subscriptions.append {
                QuerySubscription<SwiftPerson>(name: "person_names") {
                    $0.firstName != "Alex" && $0.lastName != "Roy"
                }
            }
            subscriptions.append {
                QuerySubscription<SwiftTypesSyncObject> {
                    $0.intCol > 0
                }
            }
        }
        XCTAssertEqual(subscriptions.count, 2)

        let foundSubscription1 = subscriptions.first(named: "person_names")
        XCTAssertNotNil(foundSubscription1)
        try subscriptions.write {
            subscriptions.remove(foundSubscription1!)
        }

        XCTAssertEqual(subscriptions.count, 1)

        let foundSubscription2 = subscriptions.first {
            QuerySubscription<SwiftTypesSyncObject> {
                $0.intCol > 0
            }
        }
        XCTAssertNotNil(foundSubscription2)
        try subscriptions.write {
            subscriptions.remove(foundSubscription2!)
        }

        XCTAssertEqual(subscriptions.count, 0)
    }

    func testRemoveSubscriptionByType() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions!
        try subscriptions.write {
            #if swift(>=5.5)
            subscriptions.append {
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Alex"
                }
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Belle"
                }
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Charles"
                }
            }
            #else
            subscriptions.append {
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Alex"
                }
            }
            subscriptions.append {
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Belle"
                }
            }
            subscriptions.append {
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Charles"
                }
            }
            #endif // swift(>=5.5)
            subscriptions.append {
                QuerySubscription<SwiftTypesSyncObject> {
                    $0.intCol > 0
                }
            }
        }
        XCTAssertEqual(subscriptions.count, 4)

        try subscriptions.write {
            subscriptions.removeAll(ofType: SwiftPerson.self)
        }
        XCTAssertEqual(subscriptions.count, 1)

        try subscriptions.write {
            subscriptions.removeAll(ofType: SwiftTypesSyncObject.self)
        }
        XCTAssertEqual(subscriptions.count, 0)
    }

    func testRemoveAllSubscriptions() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions!
        try subscriptions.write {
            #if swift(>=5.5)
            subscriptions.append {
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Alex"
                }
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Belle"
                }
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Charles"
                }
            }
            #else
            subscriptions.append {
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Alex"
                }
            }
            subscriptions.append {
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Belle"
                }
            }
            subscriptions.append {
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Charles"
                }
            }
            #endif // swift(>=5.5)
            subscriptions.append {
                QuerySubscription<SwiftTypesSyncObject> {
                    $0.intCol > 0
                }
            }
        }
        XCTAssertEqual(subscriptions.count, 4)

        try subscriptions.write {
            subscriptions.removeAll()
        }

        XCTAssertEqual(subscriptions.count, 0)
    }

    func testSubscriptionSetIterate() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions!

        let numberOfSubs = 50
        try subscriptions.write {
            for i in 1...numberOfSubs {
                subscriptions.append {
                    QuerySubscription<SwiftPerson>(name: "person_age_\(i)") {
                        $0.age > i
                    }
                }
            }
        }

        XCTAssertEqual(subscriptions.count, numberOfSubs)

        var count = 0
        for subscription in subscriptions {
            XCTAssertNotNil(subscription)
            count += 1
        }

        XCTAssertEqual(count, numberOfSubs)
    }

    func testSubscriptionSetFirstAndLast() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions!

        let numberOfSubs = 20
        try subscriptions.write {
            for i in 1...numberOfSubs {
                subscriptions.append {
                    QuerySubscription<SwiftPerson>(name: "person_age_\(i)") {
                        $0.age > i
                    }
                }
            }
        }

        XCTAssertEqual(subscriptions.count, numberOfSubs)

        let firstSubscription = subscriptions.first
        XCTAssertNotNil(firstSubscription!)
        XCTAssertEqual(firstSubscription!.name, "person_age_1")

        let lastSubscription = subscriptions.last
        XCTAssertNotNil(lastSubscription!)
        XCTAssertEqual(lastSubscription!.name, "person_age_\(numberOfSubs)")
    }

    func testSubscriptionSetSubscript() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions!

        let numberOfSubs = 20
        try subscriptions.write {
            for i in 1...numberOfSubs {
                subscriptions.append {
                    QuerySubscription<SwiftPerson>(name: "person_age_\(i)") {
                        $0.age > i
                    }
                }
            }
        }

        XCTAssertEqual(subscriptions.count, numberOfSubs)

        let firstSubscription = subscriptions[0]
        XCTAssertNotNil(firstSubscription!)
        XCTAssertEqual(firstSubscription!.name, "person_age_1")

        let lastSubscription = subscriptions[numberOfSubs-1]
        XCTAssertNotNil(lastSubscription!)
        XCTAssertEqual(lastSubscription!.name, "person_age_\(numberOfSubs)")
    }

    func testUpdateQueries() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions!
        try subscriptions.write {
            #if swift(>=5.5)
            subscriptions.append {
                QuerySubscription<SwiftPerson>(name: "person_age_15") {
                    $0.age > 15
                }
                QuerySubscription<SwiftPerson>(name: "person_age_20") {
                    $0.age > 20
                }
            }
            #else
            subscriptions.append {
                QuerySubscription<SwiftPerson>(name: "person_age_15") {
                    $0.age > 15
                }
            }
            subscriptions.append {
                QuerySubscription<SwiftPerson>(name: "person_age_20") {
                    $0.age > 20
                }
            }
            #endif // swift(>=5.5)
        }
        XCTAssertEqual(subscriptions.count, 2)

        let foundSubscription1 = subscriptions.first(named: "person_age_15")
        let foundSubscription2 = subscriptions.first(named: "person_age_20")

        try subscriptions.write {
            foundSubscription1?.update { QuerySubscription<SwiftPerson> { $0.age > 0 } }
            foundSubscription2?.update { QuerySubscription<SwiftPerson> { $0.age > 0 } }
        }

        XCTAssertEqual(subscriptions.count, 2)
    }
}

// MARK: - Completion Block
class SwiftFlexibleSyncServerTests: SwiftFlexibleSyncTestCase {
    func testFlexibleSyncAppWithoutQuery() {
        
    }
}

// MARK: - Async Await
#if swift(>=5.5) && canImport(_Concurrency)
@available(macOS 12.0.0, *)
extension SwiftFlexibleSyncServerTests {
}
#endif // canImport(_Concurrency)
#endif // os(macOS)
