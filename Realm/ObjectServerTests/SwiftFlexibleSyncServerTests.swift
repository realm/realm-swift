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
import Combine

#if canImport(RealmTestSupport)
import RealmSwiftSyncTestSupport
import RealmSyncTestSupport
import RealmTestSupport
import SwiftUI
import RealmSwiftTestSupport
#endif

class SwiftFlexibleSyncTests: SwiftSyncTestCase {
    func testCreateFlexibleSyncApp() throws {
        let appId = try RealmServer.shared.createAppWithQueryableFields(["age"])
        let flexibleApp = app(withId: appId)
        let user = try logInUser(for: basicCredentials(app: flexibleApp), app: flexibleApp)
        XCTAssertNotNil(user)
        try RealmServer.shared.deleteApp(appId)
    }

    func testFlexibleSyncOpenRealm() throws {
        let realm = try openFlexibleSyncRealm()
        XCTAssertNotNil(realm)
    }

    func testGetSubscriptionsWhenLocalRealm() throws {
        var configuration = Realm.Configuration.defaultConfiguration
        configuration.objectTypes = [SwiftPerson.self]
        let realm = try Realm(configuration: configuration)
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
    private var cancellables: Set<AnyCancellable> = []

    override class var defaultTestSuite: XCTestSuite {
        if hasCombine() {
            return super.defaultTestSuite
        }
        return XCTestSuite(name: "\(type(of: self))")
    }

    override func tearDown() {
        cancellables.forEach { $0.cancel() }
        cancellables = []
        super.tearDown()
    }

    func testFlexibleSyncAppWithoutQuery() throws {
        try populateFlexibleSyncData { realm in
            for i in 1...10 {
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
            for i in 1...25 {
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
        checkCount(expected: 10, realm, SwiftPerson.self)
    }

    func testFlexibleSyncAppMultipleQuery() throws {
        try populateFlexibleSyncData { realm in
            for i in 1...20 {
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
        checkCount(expected: 10, realm, SwiftPerson.self)
        checkCount(expected: 1, realm, SwiftTypesSyncObject.self)
    }

    func testFlexibleSyncAppRemoveQuery() throws {
        try populateFlexibleSyncData { realm in
            for i in 1...30 {
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
        checkCount(expected: 25, realm, SwiftPerson.self)
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
            for i in 1...25 {
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
        checkCount(expected: 20, realm, SwiftPerson.self)
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
        checkCount(expected: 5, realm, SwiftPerson.self)
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
            for i in 1...25 {
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
        checkCount(expected: 5, realm, SwiftPerson.self)

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
        checkCount(expected: 20, realm, SwiftPerson.self)
    }

    func testFlexibleSyncInitialSubscriptions() throws {
        try populateFlexibleSyncData { realm in
            for i in 1...20 {
                let person = SwiftPerson(firstName: "\(#function)",
                                         lastName: "lastname_\(i)",
                                         age: i)
                realm.add(person)
            }
        }

        let user = try logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)
        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_10") {
                $0.age > 10 && $0.firstName == "\(#function)"
            })
        })
        if config.objectTypes == nil {
            config.objectTypes = [SwiftPerson.self,
                                  SwiftTypesSyncObject.self]
        }
        let realm = try Realm(configuration: config)
        let subscriptions = realm.subscriptions
        XCTAssertNotNil(subscriptions)
        XCTAssertEqual(subscriptions.count, 1)

        checkCount(expected: 0, realm, SwiftPerson.self)

        let start = Date()
        while subscriptions.state != .complete && start.timeIntervalSinceNow > -5.0 {
            sleep(1) // wait until state is on complete state
        }
        XCTAssertEqual(subscriptions.state, .complete)

        waitForDownloads(for: realm)
        checkCount(expected: 10, realm, SwiftPerson.self)
    }

    func testFlexibleSyncCancelOnNonFatalError() throws {
        let proxy = TimeoutProxyServer(port: 5678, targetPort: 9090)
        try proxy.start()

        let appConfig = AppConfiguration(baseURL: "http://localhost:5678",
                                         transport: AsyncOpenConnectionTimeoutTransport(),
                                         syncTimeouts: SyncTimeoutOptions(connectTimeout: 2000))
        let app = App(id: flexibleSyncAppId, configuration: appConfig)

        let user = try logInUser(for: basicCredentials(app: app), app: app)
        let config = user.flexibleSyncConfiguration(cancelAsyncOpenOnNonFatalErrors: true)

        autoreleasepool {
            proxy.delay = 3.0
            let ex = expectation(description: "async open")
            Realm.asyncOpen(configuration: config) { result in
                guard case .failure(let error) = result else {
                    XCTFail("Did not fail: \(result)")
                    return
                }
                if let error = error as NSError? {
                    XCTAssertEqual(error.code, Int(ETIMEDOUT))
                    XCTAssertEqual(error.domain, NSPOSIXErrorDomain)
                }
                ex.fulfill()
            }
            waitForExpectations(timeout: 20.0, handler: nil)
        }

        proxy.stop()
    }
}

// MARK: - Async Await
#if canImport(_Concurrency)
@available(macOS 12.0, *)
extension SwiftFlexibleSyncServerTests {
    @MainActor
    private func populateFlexibleSyncData(_ block: @escaping (Realm) -> Void) async throws {
        let realm = try await flexibleSyncRealm()
        let subscriptions = realm.subscriptions
        try await subscriptions.update {
            subscriptions.append(QuerySubscription<SwiftPerson>())
            subscriptions.append(QuerySubscription<SwiftTypesSyncObject>())
            subscriptions.append(QuerySubscription<SwiftCustomColumnObject>())
        }

        try realm.write {
            block(realm)
        }
    }

    @MainActor
    func setupCollection(_ collection: String) async throws -> MongoCollection {
        let user = try await flexibleSyncApp.login(credentials: .anonymous)
        let mongoClient = user.mongoClient("mongodb1")
        let database = mongoClient.database(named: "test_data")
        let collection =  database.collection(withName: collection)
        removeAllFromCollection(collection)
        return collection
    }

    @MainActor
    func testFlexibleSyncAppAddQueryAsyncAwait() async throws {
        try await populateFlexibleSyncData { realm in
            for i in 1...25 {
                let person = SwiftPerson(firstName: "\(#function)",
                                         lastName: "lastname_\(i)",
                                         age: i)
                realm.add(person)
            }
        }

        let realm = try await flexibleSyncRealm()
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

        checkCount(expected: 10, realm, SwiftPerson.self)
    }

#if false // FIXME: this is no longer an error and needs to be updated to something which is
    @MainActor
    func testStates() async throws {
        let realm = try await flexibleSyncRealm()
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
        } catch Realm.Error.subscriptionFailed {
            guard case .error = subscriptions.state else {
                return XCTFail("Adding a query for a not queryable field should change the subscription set state to error")
            }
        }
    }
#endif

    @MainActor
    func testFlexibleSyncAllDocumentsForType() async throws {
        try await populateFlexibleSyncData { realm in
            realm.deleteAll() // Remove all objects for a clean state
            for i in 1...28 {
                let person = SwiftPerson(firstName: "\(#function)",
                                         lastName: "lastname_\(i)",
                                         age: i)
                realm.add(person)
            }
        }

        let realm = try await flexibleSyncRealm()
        XCTAssertNotNil(realm)
        checkCount(expected: 0, realm, SwiftPerson.self)

        let subscriptions = realm.subscriptions
        XCTAssertNotNil(subscriptions)
        XCTAssertEqual(subscriptions.count, 0)

        try await subscriptions.update {
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_all"))
        }
        XCTAssertEqual(subscriptions.state, .complete)
        XCTAssertEqual(subscriptions.count, 1)
        checkCount(expected: 28, realm, SwiftPerson.self)
    }

    @MainActor
    func testFlexibleSyncNotInitialSubscriptions() async throws {
        let config = try await flexibleSyncConfig()
        let realm = try await Realm(configuration: config, downloadBeforeOpen: .always)
        XCTAssertNotNil(realm)

        XCTAssertEqual(realm.subscriptions.count, 0)
    }

    @MainActor
    func testFlexibleSyncInitialSubscriptionsAsync() async throws {
        try await populateFlexibleSyncData { realm in
            for i in 1...20 {
                let person = SwiftPerson(firstName: "\(#function)",
                                         lastName: "lastname_\(i)",
                                         age: i)
                realm.add(person)
            }
        }

        let user = try await logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)
        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_10") {
                $0.age > 10 && $0.firstName == "\(#function)"
            })
        })

        if config.objectTypes == nil {
            config.objectTypes = [SwiftPerson.self]
        }
        let realm = try await Realm(configuration: config, downloadBeforeOpen: .once)
        XCTAssertNotNil(realm)

        XCTAssertEqual(realm.subscriptions.count, 1)
        checkCount(expected: 10, realm, SwiftPerson.self)
    }

    @MainActor
    func testFlexibleSyncInitialSubscriptionsNotRerunOnOpen() async throws {
        let user = try await logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)
        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_10") {
                $0.age > 10 && $0.firstName == "\(#function)"
            })
        })

        if config.objectTypes == nil {
            config.objectTypes = [SwiftPerson.self]
        }
        let realm = try await Realm(configuration: config, downloadBeforeOpen: .once)
        XCTAssertNotNil(realm)
        XCTAssertEqual(realm.subscriptions.count, 1)

        let realm2 = try await Realm(configuration: config, downloadBeforeOpen: .once)
        XCTAssertNotNil(realm2)
        XCTAssertEqual(realm.subscriptions.count, 1)
    }

    @MainActor
    func testFlexibleSyncInitialSubscriptionsRerunOnOpenNamedQuery() async throws {
        let user = try await logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)
        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            if subscriptions.first(named: "person_age_10") == nil {
                subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_10") {
                    $0.age > 20 && $0.firstName == "\(#function)"
                })
            }
        }, rerunOnOpen: true)

        if config.objectTypes == nil {
            config.objectTypes = [SwiftPerson.self]
        }
        let realm = try await Realm(configuration: config, downloadBeforeOpen: .once)
        XCTAssertNotNil(realm)
        XCTAssertEqual(realm.subscriptions.count, 1)

        let realm2 = try await Realm(configuration: config, downloadBeforeOpen: .once)
        XCTAssertNotNil(realm2)
        XCTAssertEqual(realm.subscriptions.count, 1)
    }

    @MainActor
    func testFlexibleSyncInitialSubscriptionsRerunOnOpenUnnamedQuery() async throws {
        try await populateFlexibleSyncData { realm in
            for i in 1...30 {
                let object = SwiftTypesSyncObject()
                object.dateCol = Calendar.current.date(
                    byAdding: .hour,
                    value: -i,
                    to: Date())!
                realm.add(object)
            }
        }
        let user = try await logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)
        let isFirstOpen = Locked(true)
        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            subscriptions.append(QuerySubscription<SwiftTypesSyncObject>(query: {
                let date = isFirstOpen.wrappedValue ? Calendar.current.date(
                    byAdding: .hour,
                    value: -10,
                    to: Date()) : Calendar.current.date(
                        byAdding: .hour,
                        value: -20,
                        to: Date())
                isFirstOpen.wrappedValue = false
                return $0.dateCol < Date() && $0.dateCol > date!
            }))
        }, rerunOnOpen: true)

        if config.objectTypes == nil {
            config.objectTypes = [SwiftTypesSyncObject.self, SwiftPerson.self]
        }
        let c = config
        _ = try await Task { @MainActor in
            let realm = try await Realm(configuration: c, downloadBeforeOpen: .always)
            XCTAssertNotNil(realm)
            XCTAssertEqual(realm.subscriptions.count, 1)
            checkCount(expected: 9, realm, SwiftTypesSyncObject.self)
        }.value

        _ = try await Task { @MainActor in
            let realm = try await Realm(configuration: c, downloadBeforeOpen: .always)
            XCTAssertNotNil(realm)
            XCTAssertEqual(realm.subscriptions.count, 2)
            checkCount(expected: 19, realm, SwiftTypesSyncObject.self)
        }.value
    }

    @MainActor
    func testFlexibleSyncInitialSubscriptionsThrows() async throws {
        let user = try await logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)
        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            if subscriptions.first(named: "query_uuid") == nil {
                subscriptions.append(QuerySubscription<SwiftTypesSyncObject>(query: {
                    $0.uuidCol == UUID()
                }))
            }
        })

        if config.objectTypes == nil {
            config.objectTypes = [SwiftTypesSyncObject.self, SwiftPerson.self]
        }
        do {
           _ = try await Realm(configuration: config, downloadBeforeOpen: .once)
        } catch let error as Realm.Error {
            XCTAssertEqual(error.code, .subscriptionFailed)
        }
    }

    @MainActor
    func testFlexibleSyncInitialSubscriptionsDefaultConfiguration() async throws {
        let user = try await logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)
        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            subscriptions.append(QuerySubscription<SwiftTypesSyncObject>())
        })

        if config.objectTypes == nil {
            config.objectTypes = [SwiftTypesSyncObject.self, SwiftPerson.self]
        }
        Realm.Configuration.defaultConfiguration = config

        let realm = try await Realm(downloadBeforeOpen: .once)
        XCTAssertEqual(realm.subscriptions.count, 1)
    }

    // MARK: - Custom Column

    @MainActor
    func testCustomColumnFlexibleSyncSchema() async throws {
        let user = try await logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)
        var config = user.flexibleSyncConfiguration()
        config.objectTypes = [SwiftCustomColumnObject.self]
        let realm = try await Realm(configuration: config)

        for property in realm.schema.objectSchema.first(where: { $0.className == "SwiftCustomColumnObject" })!.properties {
            XCTAssertEqual(customColumnPropertiesMapping[property.name], property.columnName)
        }
    }

    @MainActor
    func testCreateCustomColumnFlexibleSyncSubscription() async throws {
        let objectId = ObjectId.generate()
        try await populateFlexibleSyncData { realm in
            let valuesDictionary: [String: Any] = ["id": objectId,
                                                   "boolCol": true,
                                                   "intCol": 365,
                                                   "doubleCol": 365.365,
                                                   "stringCol": "@#¢∞¬÷÷",
                                                   "binaryCol": "string".data(using: String.Encoding.utf8)!,
                                                   "dateCol": Date(timeIntervalSince1970: -365),
                                                   "longCol": 365,
                                                   "decimalCol": Decimal128(365),
                                                   "uuidCol": UUID(uuidString: "629bba42-97dc-4fee-97ff-78af054952ec")!,
                                                   "objectIdCol": ObjectId.generate()]

            realm.create(SwiftCustomColumnObject.self, value: valuesDictionary)
        }

        let user = try await logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)
        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            subscriptions.append(QuerySubscription<SwiftCustomColumnObject>())
        })
        config.objectTypes = [SwiftCustomColumnObject.self]
        let realm = try await Realm(configuration: config, downloadBeforeOpen: .once)
        XCTAssertNotNil(realm)
        XCTAssertEqual(realm.subscriptions.count, 1)

        let foundObject = realm.object(ofType: SwiftCustomColumnObject.self, forPrimaryKey: objectId)
        XCTAssertNotNil(foundObject)
        XCTAssertEqual(foundObject!.id, objectId)
        XCTAssertEqual(foundObject!.boolCol, true)
        XCTAssertEqual(foundObject!.intCol, 365)
        XCTAssertEqual(foundObject!.doubleCol, 365.365)
        XCTAssertEqual(foundObject!.stringCol, "@#¢∞¬÷÷")
        XCTAssertEqual(foundObject!.binaryCol, "string".data(using: String.Encoding.utf8)!)
        XCTAssertEqual(foundObject!.dateCol, Date(timeIntervalSince1970: -365))
        XCTAssertEqual(foundObject!.longCol, 365)
        XCTAssertEqual(foundObject!.decimalCol, Decimal128(365))
        XCTAssertEqual(foundObject!.uuidCol, UUID(uuidString: "629bba42-97dc-4fee-97ff-78af054952ec")!)
        XCTAssertNotNil(foundObject?.objectIdCol)
        XCTAssertNil(foundObject?.objectCol)
    }

    @MainActor
    func testCustomColumnFlexibleSyncSubscriptionNSPredicate() async throws {
        let objectId = ObjectId.generate()
        let linkedObjectId = ObjectId.generate()
        try await populateFlexibleSyncData { realm in
            let object = SwiftCustomColumnObject()
            object.id = objectId
            object.binaryCol = "string".data(using: String.Encoding.utf8)!
            let linkedObject = SwiftCustomColumnObject()
            linkedObject.id = linkedObjectId
            object.objectCol = linkedObject
            realm.add(object)
        }
        let user = try await logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)

        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            subscriptions.append(QuerySubscription<SwiftCustomColumnObject>(where: NSPredicate(format: "id == %@ || id == %@", objectId, linkedObjectId)))
        })
        config.objectTypes = [SwiftCustomColumnObject.self]
        let realm = try await Realm(configuration: config, downloadBeforeOpen: .once)
        XCTAssertNotNil(realm)
        XCTAssertEqual(realm.subscriptions.count, 1)
        checkCount(expected: 2, realm, SwiftCustomColumnObject.self)

        let foundObject = realm.objects(SwiftCustomColumnObject.self).where { $0.id == objectId }.first
        XCTAssertNotNil(foundObject)
        XCTAssertEqual(foundObject!.id, objectId)
        XCTAssertEqual(foundObject!.boolCol, true)
        XCTAssertEqual(foundObject!.intCol, 1)
        XCTAssertEqual(foundObject!.doubleCol, 1.1)
        XCTAssertEqual(foundObject!.stringCol, "string")
        XCTAssertEqual(foundObject!.binaryCol, "string".data(using: String.Encoding.utf8)!)
        XCTAssertEqual(foundObject!.dateCol, Date(timeIntervalSince1970: -1))
        XCTAssertEqual(foundObject!.longCol, 1)
        XCTAssertEqual(foundObject!.decimalCol, Decimal128(1))
        XCTAssertEqual(foundObject!.uuidCol, UUID(uuidString: "85d4fbee-6ec6-47df-bfa1-615931903d7e")!)
        XCTAssertNil(foundObject?.objectIdCol)
        XCTAssertEqual(foundObject!.objectCol!.id, linkedObjectId)
    }

    @MainActor
    func testCustomColumnFlexibleSyncSubscriptionFilter() async throws {
        let objectId = ObjectId.generate()
        let linkedObjectId = ObjectId.generate()
        try await populateFlexibleSyncData { realm in
            let object = SwiftCustomColumnObject()
            object.id = objectId
            object.binaryCol = "string".data(using: String.Encoding.utf8)!
            let linkedObject = SwiftCustomColumnObject()
            linkedObject.id = linkedObjectId
            object.objectCol = linkedObject
            realm.add(object)
        }
        let user = try await logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)

        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            subscriptions.append(QuerySubscription<SwiftCustomColumnObject>(where: "id == %@ || id == %@", objectId, linkedObjectId))
        })
        config.objectTypes = [SwiftCustomColumnObject.self]
        let realm = try await Realm(configuration: config, downloadBeforeOpen: .once)
        XCTAssertNotNil(realm)
        XCTAssertEqual(realm.subscriptions.count, 1)
        checkCount(expected: 2, realm, SwiftCustomColumnObject.self)

        let foundObject = realm.objects(SwiftCustomColumnObject.self).where { $0.id == objectId }.first
        XCTAssertNotNil(foundObject)
        XCTAssertEqual(foundObject!.id, objectId)
        XCTAssertEqual(foundObject!.boolCol, true)
        XCTAssertEqual(foundObject!.intCol, 1)
        XCTAssertEqual(foundObject!.doubleCol, 1.1)
        XCTAssertEqual(foundObject!.stringCol, "string")
        XCTAssertEqual(foundObject!.binaryCol, "string".data(using: String.Encoding.utf8)!)
        XCTAssertEqual(foundObject!.dateCol, Date(timeIntervalSince1970: -1))
        XCTAssertEqual(foundObject!.longCol, 1)
        XCTAssertEqual(foundObject!.decimalCol, Decimal128(1))
        XCTAssertEqual(foundObject!.uuidCol, UUID(uuidString: "85d4fbee-6ec6-47df-bfa1-615931903d7e")!)
        XCTAssertNil(foundObject?.objectIdCol)
        XCTAssertEqual(foundObject!.objectCol!.id, linkedObjectId)
    }

    @MainActor
    func testCustomColumnFlexibleSyncSubscriptionQuery() async throws {
        let objectId = ObjectId.generate()
        let linkedObjectId = ObjectId.generate()
        try await populateFlexibleSyncData { realm in
            let object = SwiftCustomColumnObject()
            object.id = objectId
            object.binaryCol = "string".data(using: String.Encoding.utf8)!
            let linkedObject = SwiftCustomColumnObject()
            linkedObject.id = linkedObjectId
            object.objectCol = linkedObject
            realm.add(object)
        }
        let user = try await logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)

        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            subscriptions.append(QuerySubscription<SwiftCustomColumnObject> {
                $0.id == objectId || $0.id == linkedObjectId
            })
        })
        config.objectTypes = [SwiftCustomColumnObject.self]
        let realm = try await Realm(configuration: config, downloadBeforeOpen: .once)
        XCTAssertNotNil(realm)
        XCTAssertEqual(realm.subscriptions.count, 1)
        checkCount(expected: 2, realm, SwiftCustomColumnObject.self)

        let foundObject = realm.objects(SwiftCustomColumnObject.self).where { $0.id == objectId }.first

        XCTAssertNotNil(foundObject)
        XCTAssertEqual(foundObject!.id, objectId)
        XCTAssertEqual(foundObject!.boolCol, true)
        XCTAssertEqual(foundObject!.intCol, 1)
        XCTAssertEqual(foundObject!.doubleCol, 1.1)
        XCTAssertEqual(foundObject!.stringCol, "string")
        XCTAssertEqual(foundObject!.binaryCol, "string".data(using: String.Encoding.utf8)!)
        XCTAssertEqual(foundObject!.dateCol, Date(timeIntervalSince1970: -1))
        XCTAssertEqual(foundObject!.longCol, 1)
        XCTAssertEqual(foundObject!.decimalCol, Decimal128(1))
        XCTAssertEqual(foundObject!.uuidCol, UUID(uuidString: "85d4fbee-6ec6-47df-bfa1-615931903d7e")!)
        XCTAssertNil(foundObject?.objectIdCol)
        XCTAssertEqual(foundObject!.objectCol!.id, linkedObjectId)
    }
}
#endif // canImport(_Concurrency)

// MARK: - Combine
#if !(os(iOS) && (arch(i386) || arch(arm)))
@available(macOS 10.15, *)
extension SwiftFlexibleSyncServerTests {
    func testFlexibleSyncCombineWrite() throws {
        try populateFlexibleSyncData { realm in
            for i in 1...25 {
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
        subscriptions.updateSubscriptions {
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_10") {
                $0.age > 10 && $0.firstName == "\(#function)"
            })
        }.sink(receiveCompletion: { @Sendable _ in },
               receiveValue: { @Sendable _ in ex.fulfill() }
        ).store(in: &cancellables)

        waitForExpectations(timeout: 20.0, handler: nil)

        waitForDownloads(for: realm)
        checkCount(expected: 15, realm, SwiftPerson.self)
    }

#if false // FIXME: this is no longer an error and needs to be updated to something which is
    func testFlexibleSyncCombineWriteFails() throws {
        let realm = try flexibleSyncRealm()
        XCTAssertNotNil(realm)
        checkCount(expected: 0, realm, SwiftPerson.self)

        let subscriptions = realm.subscriptions
        XCTAssertNotNil(subscriptions)
        XCTAssertEqual(subscriptions.count, 0)

        let ex = expectation(description: "state change error")
        subscriptions.updateSubscriptions {
            subscriptions.append(QuerySubscription<SwiftTypesSyncObject>(name: "swiftObject_longCol") {
                $0.longCol == Int64(1)
            })
        }
        .sink(receiveCompletion: { result in
            if case .failure(let error as Realm.Error) = result {
                XCTAssertEqual(error.code, .subscriptionFailed)
                guard case .error = subscriptions.state else {
                    return XCTFail("Adding a query for a not queryable field should change the subscription set state to error")
                }
            } else {
                XCTFail("Expected an error but got \(result)")
            }
            ex.fulfill()
        }, receiveValue: { _ in })
        .store(in: &cancellables)

        waitForExpectations(timeout: 20.0, handler: nil)

        waitForDownloads(for: realm)
        checkCount(expected: 0, realm, SwiftPerson.self)
    }
#endif
}
#endif // canImport(Combine)
#endif // os(macOS)
