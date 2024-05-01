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

@available(macOS 13.0, *)
class SwiftFlexibleSyncTests: SwiftSyncTestCase {
    override func configuration(user: User) -> Realm.Configuration {
        user.flexibleSyncConfiguration()
    }

    override var objectTypes: [ObjectBase.Type] {
        [SwiftPerson.self, SwiftTypesSyncObject.self, SwiftHugeSyncObject.self]
    }

    override func createApp() throws -> String {
        try createFlexibleSyncApp()
    }

    func testCreateFlexibleSyncApp() throws {
        let appId = try RealmServer.shared.createApp(fields: ["age"], types: [SwiftPerson.self])
        let flexibleApp = app(id: appId)
        _ = try logInUser(for: basicCredentials(app: flexibleApp), app: flexibleApp)
    }

    func testGetSubscriptionsWhenLocalRealm() throws {
        var configuration = Realm.Configuration.defaultConfiguration
        configuration.objectTypes = [SwiftPerson.self]
        let realm = try Realm(configuration: configuration)
        assertThrows(realm.subscriptions)
    }

    // FIXME: Using `assertThrows` within a Server test will crash on tear down
    func skip_testGetSubscriptionsWhenPbsRealm() throws {
        let realm = try Realm(configuration: createUser().configuration(partitionValue: name))
        assertThrows(realm.subscriptions)
    }

    func testFlexibleSyncPath() throws {
        let config = try configuration()
        let user = config.syncConfiguration!.user
        XCTAssertTrue(config.fileURL!.path.hasSuffix("mongodb-realm/\(appId)/\(user.id)/flx_sync_default.realm"))
    }

    func testGetSubscriptions() throws {
        let realm = try openRealm()
        let subscriptions = realm.subscriptions
        XCTAssertEqual(subscriptions.count, 0)
    }

    func testWriteEmptyBlock() throws {
        let realm = try openRealm()
        let subscriptions = realm.subscriptions
        subscriptions.update {}

        XCTAssertEqual(subscriptions.count, 0)
    }

    func testAddOneSubscriptionWithoutName() throws {
        let realm = try openRealm()
        let subscriptions = realm.subscriptions
        subscriptions.update {
            subscriptions.append(QuerySubscription<SwiftPerson> {
                $0.age > 15
            })
        }

        XCTAssertEqual(subscriptions.count, 1)
    }

    func testAddOneSubscriptionWithName() throws {
        let realm = try openRealm()
        let subscriptions = realm.subscriptions
        subscriptions.update {
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age") {
                $0.age > 15
            })
        }

        XCTAssertEqual(subscriptions.count, 1)
    }

    func testAddSubscriptionsInDifferentBlocks() throws {
        let realm = try openRealm()
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
        let realm = try openRealm()
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
        let realm = try openRealm()
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
        let realm = try openRealm()
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
        let realm = try openRealm()
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
        let realm = try openRealm()
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
        let realm = try openRealm()
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
        let realm = try openRealm()
        let subscriptions = realm.subscriptions
        assertThrows(subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_1") {
            $0.age > 15
        }))
    }

    func testFindSubscriptionByName() throws {
        let realm = try openRealm()
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
        let realm = try openRealm()
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
        let realm = try openRealm()
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
        let realm = try openRealm()
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
        let realm = try openRealm()
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
        let realm = try openRealm()
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
        let realm = try openRealm()
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

    func testRemoveAllUnnamedSubscriptions() throws {
        let realm = try openRealm()
        let subscriptions = realm.subscriptions
        subscriptions.update {
            subscriptions.append(
                QuerySubscription<SwiftPerson>(name: "alex") {
                    $0.firstName == "Alex"
                },
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Belle"
                },
                QuerySubscription<SwiftPerson> {
                    $0.firstName == "Charles"
                })
            subscriptions.append(QuerySubscription<SwiftTypesSyncObject>(name: "zero") {
                $0.intCol > 0
            })
        }
        XCTAssertEqual(subscriptions.count, 4)

        subscriptions.update {
            subscriptions.removeAll(unnamedOnly: true)
        }

        XCTAssertEqual(subscriptions.count, 2)
    }

    func testSubscriptionSetIterate() throws {
        let realm = try openRealm()
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
        let realm = try openRealm()
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
        let realm = try openRealm()
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
        let realm = try openRealm()
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
        let realm = try openRealm()
        let subscriptions = realm.subscriptions
        subscriptions.update {
            subscriptions.append(
                QuerySubscription<SwiftPerson> { $0.age > 15 },
                QuerySubscription<SwiftPerson> { $0.age > 20 })
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
        let realm = try openRealm()
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
        let realm = try openRealm()
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

    func populateSwiftPerson(count: Int = 10) throws {
        try write { realm in
            for i in 1...count {
                realm.add(SwiftPerson(firstName: self.name, lastName: "lastname_\(i)", age: i))
            }
        }
    }

    func populateSwiftTypesObject(count: Int = 1) throws {
        try write { realm in
            for _ in 1...count {
                let swiftTypes = SwiftTypesSyncObject()
                swiftTypes.stringCol = self.name
                realm.add(swiftTypes)
            }
        }
    }

    func testFlexibleSyncAppWithoutQuery() throws {
        try populateSwiftPerson()

        let realm = try openRealm()
        checkCount(expected: 0, realm, SwiftPerson.self)

        let subscriptions = realm.subscriptions
        XCTAssertEqual(subscriptions.count, 0)

        waitForDownloads(for: realm)
        checkCount(expected: 0, realm, SwiftPerson.self)
    }

    func testFlexibleSyncAppAddQuery() throws {
        try populateSwiftPerson(count: 25)

        let realm = try openRealm()
        checkCount(expected: 0, realm, SwiftPerson.self)

        let subscriptions = realm.subscriptions
        XCTAssertEqual(subscriptions.count, 0)

        let ex = expectation(description: "state change complete")
        subscriptions.update({
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_15") {
                $0.age > 15 && $0.firstName == name
            })
        }, onComplete: { error in
            XCTAssertNil(error)
            ex.fulfill()
        })

        waitForExpectations(timeout: 20.0, handler: nil)

        waitForDownloads(for: realm)
        checkCount(expected: 10, realm, SwiftPerson.self)
    }

    func testFlexibleSyncAppMultipleQuery() throws {
        try populateSwiftPerson(count: 20)
        try populateSwiftTypesObject()

        let realm = try openRealm()
        checkCount(expected: 0, realm, SwiftPerson.self)

        let subscriptions = realm.subscriptions
        XCTAssertEqual(subscriptions.count, 0)

        let ex = expectation(description: "state change complete")
        subscriptions.update({
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_10") {
                $0.age > 10 && $0.firstName == name
            })
            subscriptions.append(QuerySubscription<SwiftTypesSyncObject>(name: "swift_object_equal_1") {
                $0.intCol == 1 && $0.stringCol == name
            })
        }, onComplete: { error in
            XCTAssertNil(error)
            ex.fulfill()
        })
        waitForExpectations(timeout: 20.0, handler: nil)

        waitForDownloads(for: realm)
        checkCount(expected: 10, realm, SwiftPerson.self)
        checkCount(expected: 1, realm, SwiftTypesSyncObject.self)
    }

    func testFlexibleSyncAppRemoveQuery() throws {
        try populateSwiftPerson(count: 30)
        try populateSwiftTypesObject()

        let realm = try openRealm()
        checkCount(expected: 0, realm, SwiftPerson.self)

        let subscriptions = realm.subscriptions
        XCTAssertEqual(subscriptions.count, 0)

        let ex = expectation(description: "state change complete")
        subscriptions.update({
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_5") {
                $0.age > 5 && $0.firstName == name
            })
            subscriptions.append(QuerySubscription<SwiftTypesSyncObject>(name: "swift_object_equal_1") {
                $0.intCol == 1 && $0.stringCol == name
            })
        }, onComplete: { error in
            XCTAssertNil(error)
            ex.fulfill()
        })
        waitForExpectations(timeout: 20.0, handler: nil)

        waitForDownloads(for: realm)
        checkCount(expected: 25, realm, SwiftPerson.self)
        checkCount(expected: 1, realm, SwiftTypesSyncObject.self)

        let ex2 = expectation(description: "state change complete")
        subscriptions.update({
            subscriptions.remove(named: "person_age_5")
        }, onComplete: { error in
            XCTAssertNil(error)
            ex2.fulfill()
        })
        waitForExpectations(timeout: 20.0, handler: nil)

        waitForDownloads(for: realm)
        checkCount(expected: 0, realm, SwiftPerson.self)
        checkCount(expected: 1, realm, SwiftTypesSyncObject.self)
    }

    func testFlexibleSyncAppRemoveAllQueries() throws {
        try populateSwiftPerson(count: 25)
        try populateSwiftTypesObject()

        let realm = try openRealm()
        checkCount(expected: 0, realm, SwiftPerson.self)

        let subscriptions = realm.subscriptions
        XCTAssertEqual(subscriptions.count, 0)

        let ex = expectation(description: "state change complete")
        subscriptions.update({
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_5") {
                $0.age > 5 && $0.firstName == name
            })
            subscriptions.append(QuerySubscription<SwiftTypesSyncObject>(name: "swift_object_equal_1") {
                $0.intCol == 1 && $0.stringCol == name
            })
        }, onComplete: { error in
            XCTAssertNil(error)
            ex.fulfill()
        })

        waitForExpectations(timeout: 20.0, handler: nil)

        waitForDownloads(for: realm)
        checkCount(expected: 20, realm, SwiftPerson.self)
        checkCount(expected: 1, realm, SwiftTypesSyncObject.self)

        let ex2 = expectation(description: "state change complete")
        subscriptions.update({
            subscriptions.removeAll()
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_20") {
                $0.age > 20 && $0.firstName == name
            })
        }, onComplete: { error in
            XCTAssertNil(error)
            ex2.fulfill()
        })
        waitForExpectations(timeout: 20.0, handler: nil)

        waitForDownloads(for: realm)
        checkCount(expected: 5, realm, SwiftPerson.self)
        checkCount(expected: 0, realm, SwiftTypesSyncObject.self)
    }

    func testFlexibleSyncAppRemoveQueriesByType() throws {
        try populateSwiftPerson(count: 21)
        try populateSwiftTypesObject()

        let realm = try openRealm()
        checkCount(expected: 0, realm, SwiftPerson.self)

        let subscriptions = realm.subscriptions
        XCTAssertEqual(subscriptions.count, 0)

        let ex = expectation(description: "state change complete")
        subscriptions.update({
            subscriptions.append(
                QuerySubscription<SwiftPerson>(name: "person_age_5") {
                    $0.age > 20 && $0.firstName == name
                },
                QuerySubscription<SwiftPerson>(name: "person_age_10") {
                    $0.lastName == "lastname_1" && $0.firstName == name
                })
            subscriptions.append(QuerySubscription<SwiftTypesSyncObject>(name: "swift_object_equal_1") {
                $0.intCol == 1 && $0.stringCol == name
            })
        }, onComplete: { error in
            XCTAssertNil(error)
            ex.fulfill()
        })
        waitForExpectations(timeout: 20.0, handler: nil)

        waitForDownloads(for: realm)
        checkCount(expected: 2, realm, SwiftPerson.self)
        checkCount(expected: 1, realm, SwiftTypesSyncObject.self)

        let ex2 = expectation(description: "state change complete")
        subscriptions.update({
            subscriptions.removeAll(ofType: SwiftPerson.self)
        }, onComplete: { error in
            XCTAssertNil(error)
            ex2.fulfill()
        })
        waitForExpectations(timeout: 20.0, handler: nil)

        waitForDownloads(for: realm)
        checkCount(expected: 0, realm, SwiftPerson.self)
        checkCount(expected: 1, realm, SwiftTypesSyncObject.self)
    }

    func testFlexibleSyncAppUpdateQuery() throws {
        try populateSwiftPerson(count: 25)

        let realm = try openRealm()
        checkCount(expected: 0, realm, SwiftPerson.self)

        let subscriptions = realm.subscriptions
        XCTAssertEqual(subscriptions.count, 0)

        let ex = expectation(description: "state change complete")
        subscriptions.update({
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age") {
                $0.age > 20 && $0.firstName == name
            })
        }, onComplete: { error in
            XCTAssertNil(error)
            ex.fulfill()
        })
        waitForExpectations(timeout: 20.0, handler: nil)

        waitForDownloads(for: realm)
        checkCount(expected: 5, realm, SwiftPerson.self)

        let foundSubscription = subscriptions.first(named: "person_age")
        XCTAssertNotNil(foundSubscription)

        let ex2 = expectation(description: "state change complete")
        subscriptions.update({
            foundSubscription?.updateQuery(toType: SwiftPerson.self, where: {
                $0.age > 5 && $0.firstName == name
            })
        }, onComplete: { error in
            XCTAssertNil(error)
            ex2.fulfill()
        })
        waitForExpectations(timeout: 20.0, handler: nil)

        waitForDownloads(for: realm)
        checkCount(expected: 20, realm, SwiftPerson.self)
    }

    func testFlexibleSyncInitialSubscriptions() throws {
        try populateSwiftPerson(count: 20)

        let user = createUser()
        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_10") {
                $0.age > 10 && $0.firstName == self.name
            })
        })
        config.objectTypes = [SwiftPerson.self, SwiftTypesSyncObject.self]
        let realm = try Realm(configuration: config)
        let subscriptions = realm.subscriptions
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
        let app = App(id: appId, configuration: appConfig)

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

    // MARK: - Progress notifiers
    func testAsyncOpenProgress() throws {
        try populateRealm()

        let asyncOpenEx = expectation(description: "async open")

        let user = createUser()
        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            subscriptions.append(QuerySubscription<SwiftHugeSyncObject>())
        })
        config.objectTypes = objectTypes
        var downloadRealm: Realm?
        let task = Realm.asyncOpen(configuration: config) { result in
            XCTAssertNotNil(try? result.get())
            downloadRealm = try! result.get()
            asyncOpenEx.fulfill()
        }

        var callCount = 0
        var progress: SyncSession.Progress?

        task.addProgressNotification { p in
            DispatchQueue.main.async {
                if let progress = progress {
                    if progress.progressEstimate < 1.0 {
                        XCTAssertGreaterThanOrEqual(p.progressEstimate, progress.progressEstimate)
                    }
                }
                progress = p
                callCount += 1
            }
        }

        waitForExpectations(timeout: 10.0, handler: nil)

        XCTAssertEqual(try XCTUnwrap(downloadRealm).objects(SwiftHugeSyncObject.self).count, 2)

        let p1 = try XCTUnwrap(progress)
        XCTAssertEqual(p1.progressEstimate, 1.0)
        XCTAssertTrue(p1.isTransferComplete)
    }

    func testNonStreamingDownloadNotifier() throws {
        try populateRealm()

        let realm = try openRealm(wait: false)

        let session = try XCTUnwrap(realm.syncSession)
        var ex = expectation(description: "first download")
        var callCount = 0
        var progress: SyncSession.Progress?
        let token = session.addProgressNotification(for: .download, mode: .forCurrentlyOutstandingWork) { p in
            DispatchQueue.main.async {
                // Verify that progress increases.
                if let progress = progress {
                    XCTAssertGreaterThanOrEqual(p.progressEstimate, progress.progressEstimate)
                }
                progress = p
                callCount += 1
            }
        }
        XCTAssertNotNil(token)

        let subscriptions = realm.subscriptions
        subscriptions.update({
            subscriptions.append(QuerySubscription<SwiftHugeSyncObject>(name: "huge_objects"))
        }, onComplete: { err in
            DispatchQueue.main.async {
                XCTAssertNil(err)
                ex.fulfill()
            }
        })

        waitForExpectations(timeout: 60.0)

        XCTAssertEqual(realm.objects(SwiftHugeSyncObject.self).count, SwiftSyncTestCase.bigObjectCount)

        XCTAssertGreaterThanOrEqual(callCount, 1)
        let p1 = try XCTUnwrap(progress)
        XCTAssertEqual(p1.progressEstimate, 1.0)
        XCTAssertTrue(p1.isTransferComplete)
        let initialCallCount = callCount
        progress = nil

        // Run a second time to upload more data and verify that the callback continues to be called
        ex = expectation(description: "second download")
        try populateRealm()

        session.wait(for: .download) { e in
            DispatchQueue.main.async {
                XCTAssertNil(e)
                ex.fulfill()
            }
        }

        waitForExpectations(timeout: 60.0)

        XCTAssertEqual(realm.objects(SwiftHugeSyncObject.self).count, 2*SwiftSyncTestCase.bigObjectCount)

        // We expect that the progress notifier is not called again since those objects were
        // added after it has completed.
        XCTAssertEqual(callCount, initialCallCount)
        XCTAssertNil(progress)

        token!.invalidate()
    }

    func testStreamingDownloadNotifier() throws {
        try populateRealm()

        let realm = try openRealm(wait: false)

        let session = try XCTUnwrap(realm.syncSession)
        var ex = expectation(description: "first download")
        var callCount = 0
        var progress: SyncSession.Progress?
        let token = session.addProgressNotification(for: .download, mode: .reportIndefinitely) { p in
            DispatchQueue.main.async {
                // Verify that progress increases. If it has reached 1.0, it may decrease again
                // since we're adding more data
                if let progress = progress {
                    if progress.progressEstimate < 1.0 {
                        XCTAssertGreaterThanOrEqual(p.progressEstimate, progress.progressEstimate)
                    }
                }
                progress = p
                callCount += 1
            }
        }
        XCTAssertNotNil(token)

        let subscriptions = realm.subscriptions
        subscriptions.update({
            subscriptions.append(QuerySubscription<SwiftHugeSyncObject>(name: "huge_objects"))
        }, onComplete: { err in
            DispatchQueue.main.async {
                XCTAssertNil(err)
                ex.fulfill()
            }
        })

        waitForExpectations(timeout: 60.0)

        XCTAssertEqual(realm.objects(SwiftHugeSyncObject.self).count, SwiftSyncTestCase.bigObjectCount)

        XCTAssertGreaterThanOrEqual(callCount, 1)
        let p1 = try XCTUnwrap(progress)
        XCTAssertEqual(p1.progressEstimate, 1.0)
        XCTAssertTrue(p1.isTransferComplete)
        let initialCallCount = callCount
        progress = nil

        // Run a second time to upload more data and verify that the callback continues to be called
        ex = expectation(description: "second download")
        try populateRealm()

        session.wait(for: .download) { e in
            DispatchQueue.main.async {
                XCTAssertNil(e)
                ex.fulfill()
            }
        }

        waitForExpectations(timeout: 60.0)

        XCTAssertEqual(realm.objects(SwiftHugeSyncObject.self).count, 2*SwiftSyncTestCase.bigObjectCount)

        XCTAssertGreaterThan(callCount, initialCallCount)
        let p2 = try XCTUnwrap(progress)
        XCTAssertEqual(p2.progressEstimate, 1.0)
        XCTAssertTrue(p2.isTransferComplete)

        token!.invalidate()
    }

    func testStreamingUploadNotifier() throws {
        let realm = try openRealm(wait: false)
        let subscriptions = realm.subscriptions
        subscriptions.update {
            subscriptions.append(QuerySubscription<SwiftHugeSyncObject>(name: "huge_objects"))
        }
        let session = try XCTUnwrap(realm.syncSession)

        var ex = expectation(description: "initial upload")
        var progress: SyncSession.Progress?

        let token = session.addProgressNotification(for: .upload, mode: .reportIndefinitely) { p in
            DispatchQueue.main.async {
                if let progress = progress {
                    if progress.progressEstimate < 1 {
                        XCTAssertGreaterThanOrEqual(p.progressEstimate, progress.progressEstimate)
                    }
                }
                progress = p
            }
        }
        XCTAssertNotNil(token)

        session.wait(for: .upload) { err in
            DispatchQueue.main.async {
                XCTAssertNil(err)
                ex.fulfill()
            }
        }

        waitForExpectations(timeout: 10.0, handler: nil)

        for i in 0..<5 {
            ex = expectation(description: "write transaction upload \(i)")
            progress = nil
            try realm.write {
                for _ in 0..<SwiftSyncTestCase.bigObjectCount {
                    realm.add(SwiftHugeSyncObject.create())
                }
            }

            session.wait(for: .upload) { err in
                DispatchQueue.main.async {
                    XCTAssertNil(err)
                    ex.fulfill()
                }
            }

            waitForExpectations(timeout: 10.0, handler: nil)
        }
        token!.invalidate()

        let p = try XCTUnwrap(progress)
        XCTAssertEqual(p.progressEstimate, 1.0)
        XCTAssertTrue(p.isTransferComplete)
    }

    func testStreamingNotifierInvalidate() throws {
        let realm = try openRealm()
        RLMRealmSubscribeToAll(ObjectiveCSupport.convert(object: realm))

        let session = try XCTUnwrap(realm.syncSession)
        let downloadCount = Locked(0)
        let uploadCount = Locked(0)
        let tokenDownload = session.addProgressNotification(for: .download, mode: .reportIndefinitely) { _ in
            downloadCount.wrappedValue += 1
        }
        let tokenUpload = session.addProgressNotification(for: .upload, mode: .reportIndefinitely) { _ in
            uploadCount.wrappedValue += 1
        }

        try populateRealm()
        waitForDownloads(for: realm)
        try realm.write {
            realm.add(SwiftHugeSyncObject.create())
        }
        waitForUploads(for: realm)

        tokenDownload!.invalidate()
        tokenUpload!.invalidate()
        RLMSyncSession.notificationsQueue().sync { }

        XCTAssertGreaterThan(downloadCount.wrappedValue, 1)
        XCTAssertGreaterThan(uploadCount.wrappedValue, 1)

        // There's inherently a race condition here: notification callbacks can
        // be called up to one more time after they're invalidated if the sync
        // worker thread is in the middle of processing a change at the time
        // that the invalidation is requested, and there's no way to wait for that.
        // This whole test takes 250ms, so we don't need a very long sleep.
        Thread.sleep(forTimeInterval: 0.2)

        downloadCount.wrappedValue = 0
        uploadCount.wrappedValue = 0

        try populateRealm()
        waitForDownloads(for: realm)
        try realm.write {
            realm.add(SwiftHugeSyncObject.create())
        }
        waitForUploads(for: realm)

        // We check that the notification block is not called after we reset the
        // counters on the notifiers and call invalidated().
        XCTAssertEqual(downloadCount.wrappedValue, 0)
        XCTAssertEqual(uploadCount.wrappedValue, 0)
    }
}

#endif // os(macOS)
