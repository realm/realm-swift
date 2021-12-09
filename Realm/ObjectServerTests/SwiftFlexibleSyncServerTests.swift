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
    func openFlexibleSyncRealm(user: User) throws -> Realm {
        var config = user.flexibleSyncConfiguration()
        if config.objectTypes == nil {
            config.objectTypes = [SwiftPerson.self,
                                  SwiftTypesSyncObject.self]
        }
        let realm = try Realm(configuration: config)
        return realm
    }

    func getFlexibleSyncRealm() throws -> Realm {
        let appId = try RealmServer.shared.createAppForSyncMode(.flx)
        let app = app(fromAppId: appId)
        let user = try logInUser(for: basicCredentials(app: app), app: app)
        return try openFlexibleSyncRealm(user: user)
    }
}

class SwiftFlexibleSyncServerTests: SwiftFlexibleSyncTestCase {
    func testCreateFlexibleSyncApp() throws {
        let appId = try RealmServer.shared.createAppForSyncMode(.flx)
        let app = app(fromAppId: appId)
        let user = try logInUser(for: basicCredentials(app: app), app: app)
        XCTAssertNotNil(user)
    }

    func testFlexibleSyncOpenRealm() throws {
        let realm = try getFlexibleSyncRealm()
        XCTAssertNotNil(realm)
    }

    func testGetSubscriptionsWhenLocalRealm() throws {
        let realm = try Realm()
        assertThrows(realm.subscriptions,
                     reason: "Realm was not build for a sync session")
    }

    func testGetSubscriptionsWhenPbsRealm() throws {
        let user = try logInUser(for: basicCredentials())
        let realm = try openRealm(partitionValue: #function, user: user)
        assertThrows(realm.subscriptions,
                     reason: "Realm sync session is not Flexible Sync")
    }

    func testGetSubscriptions() throws {
        let realm = try getFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        XCTAssertEqual(subscriptions.count, 0)
    }

    func testWriteEmptyBlock() throws {
        let realm = try getFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        try subscriptions.write {
        }

        XCTAssertEqual(subscriptions.count, 0)
    }

    func testAddOneSubscriptionWithoutName() throws {
        let realm = try getFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        try subscriptions.write {
            subscriptions.append {
                SyncSubscription<SwiftPerson> {
                    $0.age > 15
                }
            }
        }

        XCTAssertEqual(subscriptions.count, 1)
    }

    func testAddOneSubscriptionWithName() throws {
        let realm = try getFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        try subscriptions.write {
            subscriptions.append {
                SyncSubscription<SwiftPerson>(name: "person_age") {
                    $0.age > 15
                }
            }
        }

        XCTAssertEqual(subscriptions.count, 1)
    }

    func testAddSeveralSubscriptionsWithoutName() throws {
        let realm = try getFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        try subscriptions.write {
            subscriptions.append {
                SyncSubscription<SwiftPerson> {
                    $0.age > 15
                }
                SyncSubscription<SwiftPerson> {
                    $0.age > 20
                }
                SyncSubscription<SwiftPerson> {
                    $0.age > 25
                }
            }
        }

        XCTAssertEqual(subscriptions.count, 3)
    }

    func testAddSeveralSubscriptionsWithName() throws {
        let realm = try getFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        try subscriptions.write {
            subscriptions.append {
                SyncSubscription<SwiftPerson>(name: "person_age_15") {
                    $0.age > 15
                }
                SyncSubscription<SwiftPerson>(name: "person_age_20") {
                    $0.age > 20
                }
                SyncSubscription<SwiftPerson>(name: "person_age_25") {
                    $0.age > 25
                }
            }
        }
        XCTAssertEqual(subscriptions.count, 3)
    }

    func testAddMixedSubscriptions() throws {
        let realm = try getFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        try subscriptions.write {
            subscriptions.append {
                SyncSubscription<SwiftPerson>(name: "person_age_15") {
                    $0.age > 15
                }
            }
            subscriptions.append {
                SyncSubscription<SwiftTypesSyncObject> {
                    $0.boolCol == true
                }
                SyncSubscription<SwiftTypesSyncObject>(name: "object_date_now") {
                    $0.dateCol <= Date()
                }
            }
        }
        XCTAssertEqual(subscriptions.count, 3)
    }

    func testAddDuplicateSubscriptions() throws {
        let realm = try getFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        try subscriptions.write {
            subscriptions.append {
                SyncSubscription<SwiftPerson> {
                    $0.age > 15
                }
                SyncSubscription<SwiftPerson> {
                    $0.age > 15
                }
            }
        }
        XCTAssertEqual(subscriptions.count, 1)
    }

    func testAddDuplicateSubscriptionWithDifferentName() throws {
        let realm = try getFlexibleSyncRealm()
        let subscriptions = realm.subscriptions
        try subscriptions.write {
            subscriptions.append {
                SyncSubscription<SwiftPerson>(name: "person_age_1") {
                    $0.age > 15
                }
                SyncSubscription<SwiftPerson>(name: "person_age_2") {
                    $0.age > 15
                }
            }
        }
        XCTAssertEqual(subscriptions.count, 2)

        let foundSubscription1 = subscriptions.first(named: "person_age_1")
        XCTAssertNotNil(foundSubscription1)
        let foundSubscription2 = subscriptions.first(named: "person_age_2")
        XCTAssertNotNil(foundSubscription2)

        XCTAssertNotEqual(foundSubscription1!.name, foundSubscription2!.name)
    }

    // Test duplicate named subscription handle error
    func testSameNamedSubscriptionThrows() throws {
//        let realm = try getFlexibleSyncRealm()
//        let subscriptions = realm.subscriptions
//        try subscriptions.write {
//            subscriptions.append {
//                SyncSubscription<SwiftPerson>(name: "person_age_1") {
//                    $0.age > 15
//                }
//            }
//        }
//        XCTAssertEqual(subscriptions.count, 2)
    }
}
// MARK: - Completion Block
extension SwiftFlexibleSyncServerTests {
}

// MARK: - Async Await
#if swift(>=5.5) && canImport(_Concurrency)
@available(macOS 12.0.0, *)
extension SwiftFlexibleSyncServerTests {
}
#endif // canImport(_Concurrency)
#endif // os(macOS)
