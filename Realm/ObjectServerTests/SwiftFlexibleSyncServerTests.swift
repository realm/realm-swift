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
            config.objectTypes = [SwiftPerson.self]
        }
        let realm = try Realm(configuration: config)
        waitForDownloads(for: realm)
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

    func testAddSubscription() throws {
//        let realm = try getFlexibleSyncRealm()
//        let subscriptions = realm.subscriptions
//        try subscriptions.write {
////            subscriptions.append {
//              let subscription1 =  SyncSubscription<SwiftPerson>(name: "person_age") {
//                    $0.age > 15
//                }
//        let subscription2 = SyncSubscription<SwiftPerson>(name: "person_age") {
//              $0.age > 15
//          }
//        let arraySub = [AnySyncSubscription(subscription1), AnySyncSubscription(subscription2)]
//
////            }
////        }
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
