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
        let token = results.addNotificationBlock { (error) in
            XCTAssertNil(error, "Notification returned error '\(error!)' when running test at \(file):\(line)")
            if results.count == expected {
                ex.fulfill()
            }
        }
        waitForExpectations(timeout: 2.0, handler: nil)
        token.stop()
    }

    private func get(permission: SyncPermissionValue,
                     from results: SyncPermissionResults,
                     file: StaticString = #file,
                     line: UInt = #line) -> SyncPermissionValue? {
        let ex = expectation(description: "Retrieving permission")
        var finalValue: SyncPermissionValue?
        let token = results.addNotificationBlock { (error) in
            XCTAssertNil(error, "Notification returned error '\(error!)' when running test at \(file):\(line)")
            for result in results where result == permission {
                finalValue = result
                ex.fulfill()
                return
            }
        }
        waitForExpectations(timeout: 2.0, handler: nil)
        token.stop()
        return finalValue
    }

    /// Ensure the absence of a permission from a results after an elapsed time interval.
    /// This method is intended to be used to check that a permission never becomes
    /// present within a results to begin with.
    private func ensureAbsence(of permission: SyncPermissionValue,
                               from results: SyncPermissionResults,
                               after wait: Double = 0.5,
                               file: StaticString = #file,
                               line: UInt = #line) {
        let ex = expectation(description: "Looking for permission")
        var isPresent = false
        let token = results.addNotificationBlock { (error) in
            XCTAssertNil(error, "Notification returned error '\(error!)' when running test at \(file):\(line)")
            isPresent = results.contains(permission)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
            ex.fulfill()
        }
        waitForExpectations(timeout: wait + 1.0, handler: nil)
        token.stop()
        XCTAssertFalse(isPresent, "Permission '\(permission)' was spuriously present (\(file):\(line))")
    }

    private static func makeExpected(from original: SyncPermissionValue,
                                     owner: SyncUser,
                                     name: String) -> SyncPermissionValue {
        return SyncPermissionValue(realmPath: "/\(owner.identity!)/\(name)",
                                   userID: original.userId!,
                                   accessLevel: original.accessLevel)
    }

    /// Setting a permission should work, and then that permission should be able to be retrieved.
    func testSettingPermissions() {
        // First, there should be no permissions.
        let ex = expectation(description: "No permissions for newly created user.")
        var results: SyncPermissionResults!
        userA.retrievePermissions { (r, error) in
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
        let p = SyncPermissionValue(realmPath: url.path, userID: userB.identity!, accessLevel: .read)

        // Set the permission.
        let ex2 = expectation(description: "Setting a permission should work.")
        userA.applyPermission(p) { (error) in
            XCTAssertNil(error)
            ex2.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)

        // Now retrieve the permissions again and make sure the new permission is properly set.
        let ex3 = expectation(description: "One permission in results after setting the permission.")
        userA.retrievePermissions { (r, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(r)
            results = r
            ex3.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
        // Expected permission: applies to user B, but for user A's Realm.
        let expectedPermission = SwiftPermissionsAPITests.makeExpected(from: p, owner: userA, name: uuid)
        let finalValue = get(permission: expectedPermission, from: results)
        XCTAssertNotNil(finalValue, "Did not find the permission \(expectedPermission)")

        // Check getting permission by its index.
        let index = results.index(ofObject: expectedPermission)
        XCTAssertNotEqual(index, NSNotFound)
        XCTAssertTrue(expectedPermission == results.object(at: index))
    }

    /// Observing permission changes should work.
    func testObservingPermissions() {
        // Get a reference to the permission results.
        let ex = expectation(description: "Retrieve permission results.")
        var results: SyncPermissionResults!
        userA.retrievePermissions { (r, error) in
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
        let token = results.addNotificationBlock { (error) in
            XCTAssertNil(error)
            if results.count > 0 {
                noteEx.fulfill()
            }
        }

        // Give user B read permissions to that Realm.
        let p = SyncPermissionValue(realmPath: url.path, userID: userB.identity!, accessLevel: .read)

        // Set the permission.
        let ex2 = expectation(description: "Setting a permission should work.")
        userA.applyPermission(p) { (error) in
            XCTAssertNil(error)
            ex2.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)

        // Wait for the notification to be fired.
        wait(for: [noteEx], timeout: 2.0)
        token.stop()
        let expectedPermission = SwiftPermissionsAPITests.makeExpected(from: p, owner: userA, name: uuid)
        let finalValue = get(permission: expectedPermission, from: results)
        XCTAssertNotNil(finalValue, "Did not find the permission \(expectedPermission)")
    }

    /// User should not be able to change a permission for a Realm they don't own.
    func testSettingUnownedRealmPermission() {
        // Open a Realm for user A.
        let uuid = UUID().uuidString
        let url = SwiftSyncTestCase.uniqueRealmURL(customName: uuid)
        _ = try! synchronouslyOpenRealm(url: url, user: userA)

        // Try to have user B give user C permissions to that Realm.
        let p = SyncPermissionValue(realmPath: url.path, userID: userC.identity!, accessLevel: .read)

        // Attempt to set the permission.
        let ex2 = expectation(description: "Setting an invalid permission should fail.")
        userB.applyPermission(p) { (error) in
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

        let expectedPermission = SwiftPermissionsAPITests.makeExpected(from: p, owner: userA, name: uuid)
        ensureAbsence(of: expectedPermission, from: results)
    }
}
