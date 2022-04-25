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

class SwiftFlexibleSyncTests: SwiftSyncTestCase {
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
        assertThrows(realm.subscriptions)
    }

    // FIXME: Using `assertThrows` within a Server test will crash on tear down
    func skip_testGetSubscriptionsWhenPbsRealm() throws {
        let user = try logInUser(for: basicCredentials())
        let realm = try openRealm(partitionValue: #function, user: user)
        assertThrows(realm.subscriptions)
    }

    func testFlexibleSyncPath() throws {
        let user = try logInUser(for: basicCredentials(app: flexibleSyncApp), app: flexibleSyncApp)
        let config = user.flexibleSyncConfiguration()
        XCTAssertTrue(config.fileURL!.path.hasSuffix("mongodb-realm/\(flexibleSyncAppId)/\(user.id)/flx_sync_default.realm"))
    }

    func testGetSubscriptions() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        XCTAssertEqual(subscriptions.count, 0)
    }

    func testWriteEmptyBlock() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        subscriptions.update {
        }

        XCTAssertEqual(subscriptions.count, 0)
    }

    func testAddOneSubscriptionWithoutName() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        subscriptions.update {
            subscriptions.append(QuerySubscription<SwiftPerson> {
                $0.age > 15
            })
        }

        XCTAssertEqual(subscriptions.count, 1)
    }

    func testAddOneSubscriptionWithName() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        subscriptions.update {
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age") {
                $0.age > 15
            })
        }

        XCTAssertEqual(subscriptions.count, 1)
    }

    func testAddSubscriptionsInDifferentBlocks() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        subscriptions.update {
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age") {
                $0.age > 15
            })
        }
        subscriptions.update {
            subscriptions.append(QuerySubscription<SwiftTypesSyncObject> {
                $0.boolCol == true
            })
        }

        XCTAssertEqual(subscriptions.count, 2)
    }

    func testAddSeveralSubscriptionsWithoutName() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        subscriptions.update {
            subscriptions.append(
                QuerySubscription<SwiftPerson> {
                    $0.age > 15
                },
                QuerySubscription<SwiftPerson> {
                    $0.age > 20
                },
                QuerySubscription<SwiftPerson> {
                    $0.age > 25
                })
        }

        XCTAssertEqual(subscriptions.count, 3)
    }

    func testAddSeveralSubscriptionsWithName() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        subscriptions.update {
            subscriptions.append(
                QuerySubscription<SwiftPerson>(name: "person_age_15") {
                    $0.age > 15
                },
                QuerySubscription<SwiftPerson>(name: "person_age_20") {
                    $0.age > 20
                },
                QuerySubscription<SwiftPerson>(name: "person_age_25") {
                    $0.age > 25
                })
        }
        XCTAssertEqual(subscriptions.count, 3)
    }

    func testAddMixedSubscriptions() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        subscriptions.update {
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_15") {
                $0.age > 15
            })
            subscriptions.append(
                QuerySubscription<SwiftTypesSyncObject> {
                    $0.boolCol == true
                },
                QuerySubscription<SwiftTypesSyncObject>(name: "object_date_now") {
                    $0.dateCol <= Date()
                })
        }
        XCTAssertEqual(subscriptions.count, 3)
    }

    func testAddDuplicateSubscriptions() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        subscriptions.update {
            subscriptions.append(
                QuerySubscription<SwiftPerson> {
                    $0.age > 15
                },
                QuerySubscription<SwiftPerson> {
                    $0.age > 15
                })
        }
        XCTAssertEqual(subscriptions.count, 1)
    }

    func testAddDuplicateSubscriptionWithDifferentName() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        subscriptions.update {
            subscriptions.append(
                QuerySubscription<SwiftPerson>(name: "person_age_1") {
                    $0.age > 15
                },
                QuerySubscription<SwiftPerson>(name: "person_age_2") {
                    $0.age > 15
                })
        }
        XCTAssertEqual(subscriptions.count, 2)
    }

    // FIXME: Using `assertThrows` within a Server test will crash on tear down
    func skip_testSameNamedSubscriptionThrows() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        subscriptions.update {
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_1") {
                $0.age > 15
            })
            assertThrows(subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_1") {
                $0.age > 20
            }))
        }
        XCTAssertEqual(subscriptions.count, 1)
    }

    // FIXME: Using `assertThrows` within a Server test will crash on tear down
    func skip_testAddSubscriptionOutsideWriteThrows() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        assertThrows(subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_1") {
            $0.age > 15
        }))
    }

    func testFindSubscriptionByName() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        subscriptions.update {
            subscriptions.append(
                QuerySubscription<SwiftPerson>(name: "person_age_15") {
                    $0.age > 15
                },
                QuerySubscription<SwiftPerson>(name: "person_age_20") {
                    $0.age > 20
                })
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
        let subscriptions = realm.subscriptions
        subscriptions.update {
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_firstname_james") {
                $0.firstName == "James"
            })
            subscriptions.append(QuerySubscription<SwiftTypesSyncObject>(name: "object_int_more_than_zero") {
                $0.intCol > 0
            })
        }
        XCTAssertEqual(subscriptions.count, 2)

        let foundSubscription1 = subscriptions.first(ofType: SwiftPerson.self, where: {
            $0.firstName == "James"
        })
        XCTAssertNotNil(foundSubscription1)
        XCTAssertEqual(foundSubscription1!.name, "person_firstname_james")

        let foundSubscription2 = subscriptions.first(ofType: SwiftTypesSyncObject.self, where: {
            $0.intCol > 0
        })
        XCTAssertNotNil(foundSubscription2)
        XCTAssertEqual(foundSubscription2!.name, "object_int_more_than_zero")
    }

    func testRemoveSubscriptionByName() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        subscriptions.update {
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_firstname_james") {
                $0.firstName == "James"
            })
            subscriptions.append(
                QuerySubscription<SwiftTypesSyncObject>(name: "object_int_more_than_zero") {
                    $0.intCol > 0
                },
                QuerySubscription<SwiftTypesSyncObject>(name: "object_string") {
                    $0.stringCol == "John" || $0.stringCol == "Tom"
                })
        }
        XCTAssertEqual(subscriptions.count, 3)

        subscriptions.update {
            subscriptions.remove(named: "person_firstname_james")
        }
        XCTAssertEqual(subscriptions.count, 2)
    }

    func testRemoveSubscriptionByQuery() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        subscriptions.update {
            subscriptions.append(
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Alex"
                },
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Belle"
                },
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Charles"
                })
            subscriptions.append(QuerySubscription<SwiftTypesSyncObject> {
                $0.intCol > 0
            })
        }
        XCTAssertEqual(subscriptions.count, 4)

        subscriptions.update {
            subscriptions.remove(ofType: SwiftPerson.self, {
                $0.firstName == "Alex"
            })
            subscriptions.remove(ofType: SwiftPerson.self, {
                $0.firstName == "Belle"
            })
            subscriptions.remove(ofType: SwiftTypesSyncObject.self, {
                $0.intCol > 0
            })
        }
        XCTAssertEqual(subscriptions.count, 1)
    }

    func testRemoveSubscription() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        subscriptions.update {
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_names") {
                $0.firstName != "Alex" && $0.lastName != "Roy"
            })
            subscriptions.append(QuerySubscription<SwiftTypesSyncObject> {
                $0.intCol > 0
            })
        }
        XCTAssertEqual(subscriptions.count, 2)

        let foundSubscription1 = subscriptions.first(named: "person_names")
        XCTAssertNotNil(foundSubscription1)
        subscriptions.update {
            subscriptions.remove(foundSubscription1!)
        }

        XCTAssertEqual(subscriptions.count, 1)

        let foundSubscription2 = subscriptions.first(ofType: SwiftTypesSyncObject.self, where: {
            $0.intCol > 0
        })
        XCTAssertNotNil(foundSubscription2)
        subscriptions.update {
            subscriptions.remove(foundSubscription2!)
        }

        XCTAssertEqual(subscriptions.count, 0)
    }

    func testRemoveSubscriptionsByType() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        subscriptions.update {
            subscriptions.append(
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Alex"
                },
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Belle"
                },
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Charles"
                })
            subscriptions.append(QuerySubscription<SwiftTypesSyncObject> {
                $0.intCol > 0
            })
        }
        XCTAssertEqual(subscriptions.count, 4)

        subscriptions.update {
            subscriptions.removeAll(ofType: SwiftPerson.self)
        }
        XCTAssertEqual(subscriptions.count, 1)

        subscriptions.update {
            subscriptions.removeAll(ofType: SwiftTypesSyncObject.self)
        }
        XCTAssertEqual(subscriptions.count, 0)
    }

    func testRemoveAllSubscriptions() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        subscriptions.update {
            subscriptions.append(
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Alex"
                },
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Belle"
                },
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Charles"
                })
            subscriptions.append(QuerySubscription<SwiftTypesSyncObject> {
                $0.intCol > 0
            })
        }
        XCTAssertEqual(subscriptions.count, 4)

        subscriptions.update {
            subscriptions.removeAll()
        }

        XCTAssertEqual(subscriptions.count, 0)
    }

    func testSubscriptionSetIterate() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions

        let numberOfSubs = 50
        subscriptions.update {
            for i in 1...numberOfSubs {
                subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_\(i)") {
                    $0.age > i
                })
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
        let subscriptions = realm.subscriptions

        let numberOfSubs = 20
        subscriptions.update {
            for i in 1...numberOfSubs {
                subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_\(i)") {
                    $0.age > i
                })
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
        let subscriptions = realm.subscriptions

        let numberOfSubs = 20
        subscriptions.update {
            for i in 1...numberOfSubs {
                subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_\(i)") {
                    $0.age > i
                })
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
        let subscriptions = realm.subscriptions
        subscriptions.update {
            subscriptions.append(
                QuerySubscription<SwiftPerson>(name: "person_age_15") {
                    $0.age > 15
                },
                QuerySubscription<SwiftPerson>(name: "person_age_20") {
                    $0.age > 20
                })
        }
        XCTAssertEqual(subscriptions.count, 2)

        let foundSubscription1 = subscriptions.first(named: "person_age_15")
        let foundSubscription2 = subscriptions.first(named: "person_age_20")

        subscriptions.update {
            foundSubscription1?.updateQuery(toType: SwiftPerson.self, where: { $0.age > 0 })
            foundSubscription2?.updateQuery(toType: SwiftPerson.self, where: { $0.age > 0 })
        }

        XCTAssertEqual(subscriptions.count, 2)
    }

    func testUpdateQueriesWithoutName() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        subscriptions.update {
            subscriptions.append(
                QuerySubscription<SwiftPerson> {
                    $0.age > 15
                },
                QuerySubscription<SwiftPerson> {
                    $0.age > 20
                })
        }
        XCTAssertEqual(subscriptions.count, 2)

        let foundSubscription1 = subscriptions.first(ofType: SwiftPerson.self, where: {
            $0.age > 15
        })
        let foundSubscription2 = subscriptions.first(ofType: SwiftPerson.self, where: {
            $0.age > 20
        })

        subscriptions.update {
            foundSubscription1?.updateQuery(toType: SwiftPerson.self, where: { $0.age > 0 })
            foundSubscription2?.updateQuery(toType: SwiftPerson.self, where: { $0.age > 5 })
        }

        XCTAssertEqual(subscriptions.count, 2)
    }

    // FIXME: Using `assertThrows` within a Server test will crash on tear down
    func skip_testFlexibleSyncAppUpdateQueryWithDifferentObjectTypeWillThrow() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        subscriptions.update {
            subscriptions.append(
                QuerySubscription<SwiftPerson>(name: "person_age_15") {
                    $0.age > 15
                })
        }
        XCTAssertEqual(subscriptions.count, 1)

        let foundSubscription1 = subscriptions.first(named: "person_age_15")

        subscriptions.update {
            assertThrows(foundSubscription1?.updateQuery(toType: SwiftTypesSyncObject.self, where: { $0.intCol > 0 }))
        }
    }


    func testFlexibleSyncTransactionsWithPredicateFormatAndNSPredicate() throws {
        let realm = try openFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        subscriptions.update {
            subscriptions.append(
                QuerySubscription<SwiftPerson>(name: "name_alex", where: "firstName == %@", "Alex"),
                QuerySubscription<SwiftPerson>(name: "name_charles", where: "firstName == %@", "Charles"),
                QuerySubscription<SwiftPerson>(where: NSPredicate(format: "firstName == 'Belle'")))
            subscriptions.append(QuerySubscription<SwiftTypesSyncObject>(where: NSPredicate(format: "intCol > 0")))
        }
        XCTAssertEqual(subscriptions.count, 4)

        let foundSubscription1 = subscriptions.first(ofType: SwiftPerson.self, where: "firstName == %@", "Alex")
        XCTAssertNotNil(foundSubscription1)
        let foundSubscription2 = subscriptions.first(ofType: SwiftTypesSyncObject.self, where: NSPredicate(format: "intCol > 0"))
        XCTAssertNotNil(foundSubscription2)

        subscriptions.update {
            subscriptions.remove(ofType: SwiftPerson.self, where: NSPredicate(format: "firstName == 'Belle'"))
            subscriptions.remove(ofType: SwiftPerson.self, where: "firstName == %@", "Charles")

            foundSubscription1?.updateQuery(to: NSPredicate(format: "lastName == 'Wightman'"))
            foundSubscription2?.updateQuery(to: "stringCol == %@", "string")
        }

        XCTAssertEqual(subscriptions.count, 2)
    }
}

// MARK: - Completion Block
class SwiftFlexibleSyncServerTests: SwiftSyncTestCase {
    func testFlexibleSyncAppWithoutQuery() throws {
        try populateFlexibleSyncData { realm in
            for i in 1...21 {
                // Using firstname to query only objects from this test
                let person = SwiftPerson(firstName: "\(#function)",
                                         lastName: "lastname_\(i)",
                                         age: i)
                realm.add(person)
            }
        }

        let realm = try flexibleSyncRealm()
        XCTAssertNotNil(realm)
        checkCount(expected: 0, realm, SwiftPerson.self)

        let subscriptions = realm.subscriptions
        XCTAssertNotNil(subscriptions)
        XCTAssertEqual(subscriptions.count, 0)

        waitForDownloads(for: realm)
        checkCount(expected: 0, realm, SwiftPerson.self)
    }

    func testFlexibleSyncAppAddQuery() throws {
        try populateFlexibleSyncData { realm in
            for i in 1...21 {
                let person = SwiftPerson(firstName: "\(#function)",
                                         lastName: "lastname_\(i)",
                                         age: i)
                realm.add(person)
            }
        }

        let realm = try flexibleSyncRealm()
        XCTAssertNotNil(realm)
        checkCount(expected: 0, realm, SwiftPerson.self)

        let subscriptions = realm.subscriptions
        XCTAssertNotNil(subscriptions)
        XCTAssertEqual(subscriptions.count, 0)

        let ex = expectation(description: "state change complete")
        subscriptions.update({
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_15") {
                $0.age > 15 && $0.firstName == "\(#function)"
            })
        }, onComplete: { error in
            if error == nil {
                ex.fulfill()
            } else {
                XCTFail("Subscription Set could not complete with \(error!)")
            }
        })

        waitForExpectations(timeout: 20.0, handler: nil)

        waitForDownloads(for: realm)
        checkCount(expected: 6, realm, SwiftPerson.self)
    }

    func testFlexibleSyncAppMultipleQuery() throws {
        try populateFlexibleSyncData { realm in
            for i in 1...21 {
                let person = SwiftPerson(firstName: "\(#function)",
                                         lastName: "lastname_\(i)",
                                         age: i)
                realm.add(person)
            }
            let swiftTypes = SwiftTypesSyncObject()
            swiftTypes.stringCol = "\(#function)"
            realm.add(swiftTypes)
        }

        let realm = try flexibleSyncRealm()
        XCTAssertNotNil(realm)
        checkCount(expected: 0, realm, SwiftPerson.self)

        let subscriptions = realm.subscriptions
        XCTAssertNotNil(subscriptions)
        XCTAssertEqual(subscriptions.count, 0)

        let ex = expectation(description: "state change complete")
        subscriptions.update({
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_10") {
                $0.age > 10 && $0.firstName == "\(#function)"
            })
            subscriptions.append(QuerySubscription<SwiftTypesSyncObject>(name: "swift_object_equal_1") {
                $0.intCol == 1 && $0.stringCol == "\(#function)"
            })
        }, onComplete: { error in
            if error == nil {
                ex.fulfill()
            } else {
                XCTFail("Subscription Set could not complete with \(error!)")
            }
        })
        waitForExpectations(timeout: 20.0, handler: nil)

        waitForDownloads(for: realm)
        checkCount(expected: 11, realm, SwiftPerson.self)
        checkCount(expected: 1, realm, SwiftTypesSyncObject.self)
    }

    func testFlexibleSyncAppRemoveQuery() throws {
        try populateFlexibleSyncData { realm in
            for i in 1...21 {
                let person = SwiftPerson(firstName: "\(#function)",
                                         lastName: "lastname_\(i)",
                                         age: i)
                realm.add(person)
            }
            let swiftTypes = SwiftTypesSyncObject()
            swiftTypes.stringCol = "\(#function)"
            realm.add(swiftTypes)
        }

        let realm = try flexibleSyncRealm()
        XCTAssertNotNil(realm)
        checkCount(expected: 0, realm, SwiftPerson.self)

        let subscriptions = realm.subscriptions
        XCTAssertNotNil(subscriptions)
        XCTAssertEqual(subscriptions.count, 0)

        let ex = expectation(description: "state change complete")
        subscriptions.update({
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_5") {
                $0.age > 5 && $0.firstName == "\(#function)"
            })
            subscriptions.append(QuerySubscription<SwiftTypesSyncObject>(name: "swift_object_equal_1") {
                $0.intCol == 1 && $0.stringCol == "\(#function)"
            })
        }, onComplete: { error in
            if error == nil {
                ex.fulfill()
            } else {
                XCTFail("Subscription Set could not complete with \(error!)")
            }
        })
        waitForExpectations(timeout: 20.0, handler: nil)

        waitForDownloads(for: realm)
        checkCount(expected: 16, realm, SwiftPerson.self)
        checkCount(expected: 1, realm, SwiftTypesSyncObject.self)

        let ex2 = expectation(description: "state change complete")
        subscriptions.update({
            subscriptions.remove(named: "person_age_5")
        }, onComplete: { error in
            if error == nil {
                ex2.fulfill()
            } else {
                XCTFail("Subscription Set could not complete with \(error!)")
            }
        })
        waitForExpectations(timeout: 20.0, handler: nil)

        waitForDownloads(for: realm)
        checkCount(expected: 0, realm, SwiftPerson.self)
        checkCount(expected: 1, realm, SwiftTypesSyncObject.self)
    }

    func testFlexibleSyncAppRemoveAllQueries() throws {
        try populateFlexibleSyncData { realm in
            for i in 1...21 {
                let person = SwiftPerson(firstName: "\(#function)",
                                         lastName: "lastname_\(i)",
                                         age: i)
                realm.add(person)
            }
            let swiftTypes = SwiftTypesSyncObject()
            swiftTypes.stringCol = "\(#function)"
            realm.add(swiftTypes)
        }

        let realm = try flexibleSyncRealm()
        XCTAssertNotNil(realm)
        checkCount(expected: 0, realm, SwiftPerson.self)

        let subscriptions = realm.subscriptions
        XCTAssertNotNil(subscriptions)
        XCTAssertEqual(subscriptions.count, 0)

        let ex = expectation(description: "state change complete")
        subscriptions.update({
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_5") {
                $0.age > 5 && $0.firstName == "\(#function)"
            })
            subscriptions.append(QuerySubscription<SwiftTypesSyncObject>(name: "swift_object_equal_1") {
                $0.intCol == 1 && $0.stringCol == "\(#function)"
            })
        }, onComplete: { error in
            if error == nil {
                ex.fulfill()
            } else {
                XCTFail("Subscription Set could not complete with \(error!)")
            }
        })

        waitForExpectations(timeout: 20.0, handler: nil)

        waitForDownloads(for: realm)
        checkCount(expected: 16, realm, SwiftPerson.self)
        checkCount(expected: 1, realm, SwiftTypesSyncObject.self)

        let ex2 = expectation(description: "state change complete")
        subscriptions.update({
            subscriptions.removeAll()
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_20") {
                $0.age > 20 && $0.firstName == "\(#function)"
            })
        }, onComplete: { error in
            if error == nil {
                ex2.fulfill()
            } else {
                XCTFail("Subscription Set could not complete with \(error!)")
            }
        })
        waitForExpectations(timeout: 20.0, handler: nil)

        waitForDownloads(for: realm)
        checkCount(expected: 1, realm, SwiftPerson.self)
        checkCount(expected: 0, realm, SwiftTypesSyncObject.self)
    }

    func testFlexibleSyncAppRemoveQueriesByType() throws {
        try populateFlexibleSyncData { realm in
            for i in 1...21 {
                let person = SwiftPerson(firstName: "\(#function)",
                                         lastName: "lastname_\(i)",
                                         age: i)
                realm.add(person)
            }
            let swiftTypes = SwiftTypesSyncObject()
            swiftTypes.stringCol = "\(#function)"
            realm.add(swiftTypes)
        }

        let realm = try flexibleSyncRealm()
        XCTAssertNotNil(realm)
        checkCount(expected: 0, realm, SwiftPerson.self)

        let subscriptions = realm.subscriptions
        XCTAssertNotNil(subscriptions)
        XCTAssertEqual(subscriptions.count, 0)

        let ex = expectation(description: "state change complete")
        subscriptions.update({
            subscriptions.append(
                QuerySubscription<SwiftPerson>(name: "person_age_5") {
                    $0.age > 20 && $0.firstName == "\(#function)"
                },
                QuerySubscription<SwiftPerson>(name: "person_age_10") {
                    $0.lastName == "lastname_1" && $0.firstName == "\(#function)"
                })
            subscriptions.append(QuerySubscription<SwiftTypesSyncObject>(name: "swift_object_equal_1") {
                $0.intCol == 1 && $0.stringCol == "\(#function)"
            })
        }, onComplete: { error in
            if error == nil {
                ex.fulfill()
            } else {
                XCTFail("Subscription Set could not complete with \(error!)")
            }
        })
        waitForExpectations(timeout: 20.0, handler: nil)

        waitForDownloads(for: realm)
        checkCount(expected: 2, realm, SwiftPerson.self)
        checkCount(expected: 1, realm, SwiftTypesSyncObject.self)

        let ex2 = expectation(description: "state change complete")
        subscriptions.update({
            subscriptions.removeAll(ofType: SwiftPerson.self)
        }, onComplete: { error in
            if error == nil {
                ex2.fulfill()
            } else {
                XCTFail("Subscription Set could not complete with \(error!)")
            }
        })
        waitForExpectations(timeout: 20.0, handler: nil)

        waitForDownloads(for: realm)
        checkCount(expected: 0, realm, SwiftPerson.self)
        checkCount(expected: 1, realm, SwiftTypesSyncObject.self)
    }

    func testFlexibleSyncAppUpdateQuery() throws {
        try populateFlexibleSyncData { realm in
            for i in 1...21 {
                let person = SwiftPerson(firstName: "\(#function)",
                                         lastName: "lastname_\(i)",
                                         age: i)
                realm.add(person)
            }
        }

        let realm = try flexibleSyncRealm()
        XCTAssertNotNil(realm)
        checkCount(expected: 0, realm, SwiftPerson.self)

        let subscriptions = realm.subscriptions
        XCTAssertNotNil(subscriptions)
        XCTAssertEqual(subscriptions.count, 0)

        let ex = expectation(description: "state change complete")
        subscriptions.update({
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age") {
                $0.age > 20 && $0.firstName == "\(#function)"
            })
        }, onComplete: { error in
            if error == nil {
                ex.fulfill()
            } else {
                XCTFail("Subscription Set could not complete with \(error!)")
            }
        })
        waitForExpectations(timeout: 20.0, handler: nil)

        waitForDownloads(for: realm)
        checkCount(expected: 1, realm, SwiftPerson.self)

        let foundSubscription = subscriptions.first(named: "person_age")
        XCTAssertNotNil(foundSubscription)

        let ex2 = expectation(description: "state change complete")
        subscriptions.update({
            foundSubscription?.updateQuery(toType: SwiftPerson.self, where: {
                $0.age > 5 && $0.firstName == "\(#function)"
            })
        }, onComplete: { error in
            if error == nil {
                ex2.fulfill()
            } else {
                XCTFail("Subscription Set could not complete with \(error!)")
            }
        })
        waitForExpectations(timeout: 20.0, handler: nil)

        waitForDownloads(for: realm)
        checkCount(expected: 16, realm, SwiftPerson.self)
    }
}

// MARK: - Async Await
#if swift(>=5.6) && canImport(_Concurrency)
@available(macOS 12.0.0, *)
class SwiftAsyncFlexibleSyncTests: SwiftSyncTestCase {
    override class var defaultTestSuite: XCTestSuite {
        // async/await is currently incompatible with thread sanitizer and will
        // produce many false positives
        // https://bugs.swift.org/browse/SR-15444
        if RLMThreadSanitizerEnabled() {
            return XCTestSuite(name: "\(type(of: self))")
        }
        return super.defaultTestSuite
    }

    @MainActor
    private func populateFlexibleSyncData(_ block: @escaping (Realm) -> Void) async throws {
        var config = (try await self.flexibleSyncApp.login(credentials: .anonymous)).flexibleSyncConfiguration()
        if config.objectTypes == nil {
            config.objectTypes = [SwiftPerson.self,
                                  SwiftTypesSyncObject.self]
        }
        let realm = try await Realm(configuration: config)

        let subscriptions = realm.subscriptions
        try await subscriptions.update {
            subscriptions.append(QuerySubscription<SwiftPerson> {
                $0.age >= 0
            })
            subscriptions.append(QuerySubscription<SwiftTypesSyncObject> {
                $0.boolCol == true
            })
        }

        try realm.write {
            block(realm)
        }
    }

    @MainActor
    func testFlexibleSyncAppAddQueryAsyncAwait() async throws {
        try await populateFlexibleSyncData { realm in
            for i in 1...21 {
                let person = SwiftPerson(firstName: "\(#function)",
                                         lastName: "lastname_\(i)",
                                         age: i)
                realm.add(person)
            }
        }

        var config = try await self.flexibleSyncApp.login(credentials: basicCredentials(app: self.flexibleSyncApp)).flexibleSyncConfiguration()
        config.objectTypes = [SwiftPerson.self, SwiftTypesSyncObject.self]
        let realm = try await Realm(configuration: config)
        XCTAssertNotNil(realm)
        checkCount(expected: 0, realm, SwiftPerson.self)

        let subscriptions = realm.subscriptions
        XCTAssertNotNil(subscriptions)
        XCTAssertEqual(subscriptions.count, 0)

        try await subscriptions.update {
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_15") {
                $0.age > 15 && $0.firstName == "\(#function)"
            })
        }

        checkCount(expected: 6, realm, SwiftPerson.self)
    }

    @MainActor
    func testStates() async throws {
        var config = (try await self.flexibleSyncApp.login(credentials: .anonymous))
            .flexibleSyncConfiguration()
        config.objectTypes = [SwiftPerson.self, SwiftTypesSyncObject.self]
        let realm = try await Realm(configuration: config)
        XCTAssertNotNil(realm)

        let subscriptions = realm.subscriptions
        XCTAssertEqual(subscriptions.count, 0)

        // should complete
        try await subscriptions.update {
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_15") {
                $0.age > 15 && $0.firstName == "\(#function)"
            })
        }
        XCTAssertEqual(subscriptions.state, .complete)
        // should error
        do {
            try await subscriptions.update {
                subscriptions.append(QuerySubscription<SwiftTypesSyncObject>(name: "swiftObject_longCol") {
                    $0.longCol == Int64(1)
                })
            }
            XCTFail("Invalid query should have failed")
        } catch let error {
            if let error = error as NSError? {
                XCTAssertTrue(error.domain == RLMFlexibleSyncErrorDomain)
                XCTAssertTrue(error.code == 2)
            }

            guard case .error = subscriptions.state else {
                return XCTFail("Adding a query for a not queryable field should change the subscription set state to error")
            }
        }
    }
}

#endif // canImport(_Concurrency)
#endif // os(macOS)
