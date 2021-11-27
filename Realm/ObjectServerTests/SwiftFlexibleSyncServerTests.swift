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
}

class SwiftFlexibleSyncServerTests: SwiftFlexibleSyncTestCase {
    func testCreateFlexibleSyncApp() {
        do {
            let appId = try RealmServer.shared.createAppForSyncMode(.flx)
            let app = app(fromAppId: appId)
            let user = try logInUser(for: basicCredentials(app: app), app: app)
            XCTAssertNotNil(user)
        } catch {
            XCTFail("Got an error: \(error)")
        }
    }

    func testBasicFlexibleSyncOpenRealm() {
        do {
            let appId = try RealmServer.shared.createAppForSyncMode(.flx)
            let app = app(fromAppId: appId)
            let user = try logInUser(for: basicCredentials(app: app), app: app)
            let realm = try openFlexibleSyncRealm(user: user)
            XCTAssertNotNil(realm)
            XCTAssert(realm.isEmpty, "Freshly synced Realm was not empty...")
        } catch {
            XCTFail("Got an error: \(error)")
        }
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
