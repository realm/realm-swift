////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
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

import XCTest
import RealmSwift

class SwiftPermissionsAPITests: SwiftSyncTestCase {
    var userA: SyncUser!
    var userB: SyncUser!
    var userC: SyncUser!

    override func setUp() {
        super.setUp()
        let baseName = UUID().uuidString
        userA = try! synchronouslyLogInUser(for: .usernamePassword(username: baseName + "a", password: "a", register: true),
                                            server: SwiftSyncTestCase.authServerURL())
        userB = try! synchronouslyLogInUser(for: .usernamePassword(username: baseName + "b", password: "a", register: true),
                                            server: SwiftSyncTestCase.authServerURL())
        userC = try! synchronouslyLogInUser(for: .usernamePassword(username: baseName + "c", password: "a", register: true),
                                            server: SwiftSyncTestCase.authServerURL())
    }

    override func tearDown() {
        userA.logOut()
        userB.logOut()
        userC.logOut()
        super.tearDown()
    }

    private func checkPermissionCount(results: SyncPermissionResults,
                                      expected: Int,
                                      file: StaticString = #file,
                                      line: UInt = #line) {
        let ex = expectation(description: "Checking permission count")
        let token = results.observe { (change) in
            if case let .error(theError) = change {
                XCTFail("Notification returned error '\(theError)' when running test at \(file):\(line)")
                return
            }
            if results.count == expected {
                ex.fulfill()
            }
        }
        waitForExpectations(timeout: 2.0, handler: nil)
        token.invalidate()
    }

    private func get(permission: SyncPermission,
                     from results: SyncPermissionResults,
                     file: StaticString = #file,
                     line: UInt = #line) -> SyncPermission? {
        let ex = expectation(description: "Retrieving permission")
        var finalValue: SyncPermission?
        let token = results.observe { (change) in
            if case let .error(theError) = change {
                XCTFail("Notification returned error '\(theError)' when running test at \(file):\(line)")
                return
            }
            for result in results where result == permission {
                finalValue = result
                ex.fulfill()
                return
            }
        }
        waitForExpectations(timeout: 2.0, handler: nil)
        token.invalidate()
        return finalValue
    }

    /// Ensure the absence of a permission from a results after an elapsed time interval.
    /// This method is intended to be used to check that a permission never becomes
    /// present within a results to begin with.
    private func ensureAbsence(of permission: SyncPermission,
                               from results: SyncPermissionResults,
                               after wait: Double = 0.5,
                               file: StaticString = #file,
                               line: UInt = #line) {
        let ex = expectation(description: "Looking for permission")
        var isPresent = false
        let token = results.observe { (change) in
            if case let .error(theError) = change {
                XCTFail("Notification returned error '\(theError)' when running test at \(file):\(line)")
                return
            }
            isPresent = results.contains(permission)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
            ex.fulfill()
        }
        waitForExpectations(timeout: wait + 1.0, handler: nil)
        token.invalidate()
        XCTAssertFalse(isPresent, "Permission '\(permission)' was spuriously present (\(file):\(line))")
    }

    private func tildeSubstitutedURL(for url: URL, user: SyncUser) -> URL {
        XCTAssertNotNil(user.identity)
        let identity = user.identity!
        return URL(string: url.absoluteString.replacingOccurrences(of: "~", with: identity))!
    }

    /// Setting a permission should work, and then that permission should be able to be retrieved.
    func testSettingPermissions() {
        // First, there should be no permissions.
        let ex = expectation(description: "No permissions for newly created user.")
        var results: SyncPermissionResults!
        userB.retrievePermissions { (r, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(r)
            results = r
            ex.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
        checkPermissionCount(results: results, expected: 0)

        // Open a Realm for user A.
        let uuid = UUID().uuidString
        let url = SwiftSyncTestCase.uniqueRealmURL(customName: uuid)
        _ = try! synchronouslyOpenRealm(url: url, user: userA)

        // Give user B read permissions to that Realm.
        let p = SyncPermission(realmPath: tildeSubstitutedURL(for: url, user: userA).path,
                               identity: userB.identity!,
                               accessLevel: .read)

        // Set the permission.
        let ex2 = expectation(description: "Setting a permission should work.")
        userA.apply(p) { (error) in
            XCTAssertNil(error)
            ex2.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)

        // Now retrieve the permissions again and make sure the new permission is properly set.
        let ex3 = expectation(description: "One permission in results after setting the permission.")
        userB.retrievePermissions { (r, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(r)
            results = r
            ex3.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
        // Expected permission: applies to user B, but for user A's Realm.
        let finalValue = get(permission: p, from: results)
        XCTAssertNotNil(finalValue, "Did not find the permission \(p)")

        // Check getting permission by its index.
        let index = results.index(of: p)
        XCTAssertNotNil(index)
        XCTAssertTrue(p == results[index!])
    }

    /// Observing permission changes should work.
    func testObservingPermissions() {
        // Get a reference to the permission results.
        let ex = expectation(description: "Retrieve permission results.")
        var results: SyncPermissionResults!
        userB.retrievePermissions { (r, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(r)
            results = r
            ex.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)

        // Open a Realm for user A.
        let uuid = UUID().uuidString
        let url = SwiftSyncTestCase.uniqueRealmURL(customName: uuid)
        _ = try! synchronouslyOpenRealm(url: url, user: userA)

        // Register notifications.
        let noteEx = expectation(description: "Notification should fire")
        let token = results.observe { (change) in
            if case .error = change {
                XCTFail("Should not return an error")
                return
            }
            if results.count > 0 {
                noteEx.fulfill()
            }
        }

        // Give user B read permissions to that Realm.
        let p = SyncPermission(realmPath: tildeSubstitutedURL(for: url, user: userA).path,
                               identity: userB.identity!,
                               accessLevel: .read)

        // Set the permission.
        let ex2 = expectation(description: "Setting a permission should work.")
        userA.apply(p) { (error) in
            XCTAssertNil(error)
            ex2.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)

        // Wait for the notification to be fired.
        wait(for: [noteEx], timeout: 2.0)
        token.invalidate()
        let finalValue = get(permission: p, from: results)
        XCTAssertNotNil(finalValue, "Did not find the permission \(p)")
    }

    /// User should not be able to change a permission for a Realm they don't own.
    func testSettingUnownedRealmPermission() {
        // Open a Realm for user A.
        let uuid = UUID().uuidString
        let url = SwiftSyncTestCase.uniqueRealmURL(customName: uuid)
        _ = try! synchronouslyOpenRealm(url: url, user: userA)

        // Try to have user B give user C permissions to that Realm.
        let p = SyncPermission(realmPath: url.path, identity: userC.identity!, accessLevel: .read)

        // Attempt to set the permission.
        let ex2 = expectation(description: "Setting an invalid permission should fail.")
        userB.apply(p) { (error) in
            XCTAssertNotNil(error)
            ex2.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)

        // Now retrieve the permissions again and make sure the new permission was not set.
        var results: SyncPermissionResults!
        let ex3 = expectation(description: "Retrieving the results should work.")
        userB.retrievePermissions { (r, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(r)
            results = r
            ex3.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
        ensureAbsence(of: p, from: results)
    }

    // MARK: - Offer/response

    func testPermissionOffer() {
        do {
            _ = try synchronouslyOpenRealm(url: realmURL, user: userA)

            let managementRealm = try userA.managementRealm()
            let permissionOffer = SyncPermissionOffer(realmURL: tildeSubstitutedURL(for: realmURL, user: userA).absoluteString,
                                                      expiresAt: Date(timeIntervalSinceNow: 30 * 24 * 60 * 60),
                                                      mayRead: true,
                                                      mayWrite: true,
                                                      mayManage: false)

            let exp = expectation(description: "A new permission offer will be processed by the server")

            let results = managementRealm.objects(SyncPermissionOffer.self).filter("id = %@", permissionOffer.id)
            let notificationToken = results.observe { (changes) in
                if case .update(let change, _, _, _) = changes, let statusCode = change[0].statusCode.value {
                    XCTAssertEqual(statusCode, 0)
                    XCTAssertEqual(change[0].status, .success)
                    exp.fulfill()
                }
            }

            try managementRealm.write {
                managementRealm.add(permissionOffer)
            }

            waitForExpectations(timeout: 2)
            notificationToken.invalidate()
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    func testPermissionOfferResponse() {
        do {
            _ = try synchronouslyOpenRealm(url: realmURL, user: userA)

            var managementRealm = try userA.managementRealm()
            let permissionOffer = SyncPermissionOffer(realmURL: tildeSubstitutedURL(for: realmURL, user: userA).absoluteString,
                                                      expiresAt: Date(timeIntervalSinceNow: 30 * 24 * 60 * 60),
                                                      mayRead: true,
                                                      mayWrite: true,
                                                      mayManage: false)

            var permissionToken: String?

            var exp = expectation(description: "A new permission offer will be processed by the server")

            let permissionOfferNotificationToken = managementRealm
                .objects(SyncPermissionOffer.self)
                .filter("id = %@", permissionOffer.id)
                .observe { (changes) in
                    if case .update(let change, _, _, _) = changes, let statusCode = change[0].statusCode.value {
                        XCTAssertEqual(statusCode, 0)
                        XCTAssertEqual(change[0].status, .success)

                        permissionToken = change[0].token
                        exp.fulfill()
                    }
            }

            try managementRealm.write {
                managementRealm.add(permissionOffer)
            }

            waitForExpectations(timeout: 2)
            permissionOfferNotificationToken.invalidate()

            _ = try synchronouslyOpenRealm(url: realmURL, user: userB)

            managementRealm = try userB.managementRealm()

            XCTAssertNotNil(permissionToken)

            var responseRealmUrl: String?
            let permissionOfferResponse = SyncPermissionOfferResponse(token: permissionToken!)

            exp = expectation(description: "A new permission offer response will be processed by the server")

            let userAIdentity = userA.identity!
            let permissionOfferResponseNotificationToken = managementRealm
                .objects(SyncPermissionOfferResponse.self)
                .filter("id = %@", permissionOfferResponse.id)
                .observe { (changes) in
                    if case .update(let change, _, _, _) = changes, let statusCode = change[0].statusCode.value {
                        XCTAssertEqual(statusCode, 0)
                        XCTAssertEqual(change[0].status, .success)
                        XCTAssertEqual(change[0].realmUrl, String(format: "realm://localhost:9080/%@/testBasicSync", userAIdentity))

                        responseRealmUrl = change[0].realmUrl

                        exp.fulfill()
                    }
            }

            try managementRealm.write {
                managementRealm.add(permissionOfferResponse)
            }

            waitForExpectations(timeout: 2)
            permissionOfferResponseNotificationToken.invalidate()

            _ = try synchronouslyOpenRealm(url: URL(string: responseRealmUrl!)!, user: userB)
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }
}
