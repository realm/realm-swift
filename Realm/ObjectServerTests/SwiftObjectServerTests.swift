////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#if swift(>=3.0)
class SwiftObjectServerTests: SwiftSyncTestCase {
    /// It should be possible to successfully open a Realm configured for sync.
    func testBasicSwiftSync() {
        let url = URL(string: "realm://localhost:9080/~/testBasicSync")!
        do {
            let user = try synchronouslyLogInUser(for: basicCredentials(register: true), server: authURL)
            let realm = try synchronouslyOpenRealm(url: url, user: user)
            XCTAssert(realm.isEmpty, "Freshly synced Realm was not empty...")
        } catch {
            XCTFail("Got an error: \(error)")
        }
    }

    /// If client B adds objects to a Realm, client A should see those new objects.
    func testSwiftAddObjects() {
        do {
            let user = try synchronouslyLogInUser(for: basicCredentials(register: isParent), server: authURL)
            let realm = try synchronouslyOpenRealm(url: realmURL, user: user)
            if isParent {
                user.waitForDownload(toFinish: realmURL)
                checkCount(expected: 0, realm, SwiftSyncObject.self)
                executeChild()
                user.waitForDownload(toFinish: realmURL)
                checkCount(expected: 3, realm, SwiftSyncObject.self)
            } else {
                // Add objects
                try realm.write {
                    realm.add(SwiftSyncObject(value: ["child-1"]))
                    realm.add(SwiftSyncObject(value: ["child-2"]))
                    realm.add(SwiftSyncObject(value: ["child-3"]))
                }
                user.waitForUpload(toFinish: realmURL)
                checkCount(expected: 3, realm, SwiftSyncObject.self)
            }
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    /// If client B removes objects from a Realm, client A should see those changes.
    func testSwiftDeleteObjects() {
        do {
            let user = try synchronouslyLogInUser(for: basicCredentials(register: isParent), server: authURL)
            let realm = try synchronouslyOpenRealm(url: realmURL, user: user)
            if isParent {
                try realm.write {
                    realm.add(SwiftSyncObject(value: ["child-1"]))
                    realm.add(SwiftSyncObject(value: ["child-2"]))
                    realm.add(SwiftSyncObject(value: ["child-3"]))
                }
                user.waitForUpload(toFinish: realmURL)
                checkCount(expected: 3, realm, SwiftSyncObject.self)
                executeChild()
                user.waitForDownload(toFinish: realmURL)
                checkCount(expected: 0, realm, SwiftSyncObject.self)
            } else {
                try realm.write {
                    realm.deleteAll()
                }
                user.waitForUpload(toFinish: realmURL)
                checkCount(expected:0, realm, SwiftSyncObject.self)
            }
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    // MARK: Permissions

    func testPermissionChange() {
        do {
            let userA = try synchronouslyLogInUser(for: basicCredentials(register: isParent, usernameSuffix: "_A"), server: authURL)
            let userB = try synchronouslyLogInUser(for: basicCredentials(register: isParent, usernameSuffix: "_B"), server: authURL)
            _ = try synchronouslyOpenRealm(url: realmURL, user: userA)

            let adminPermissions = [
                [true, true, true],
                [false, true, true],
                [true, false, true],
                [false, false, true]
            ]
            let readWritePermissions = [[true, true, false]]
            let readOnlyPermissions = [[true, false, false]]
            let noAccessPermissions: [[Bool?]] = [
                [false, false, false],
                [nil, nil, nil]
            ]
            let permissions = [adminPermissions, readWritePermissions, readOnlyPermissions, noAccessPermissions]
            let statusMessages = [
                "administrative access",
                "read-write access",
                "read-only access",
                "no access"
            ]

            for (accessPermissions, statusMessage) in zip(permissions, statusMessages) {
                for permissions in accessPermissions {
                    let permissionChange = SyncPermissionChange(
                        realmURL: realmURL.absoluteString,
                        userID: userB.identity!,
                        mayRead: permissions[0],
                        mayWrite: permissions[1],
                        mayManage: permissions[2]
                    )
                    try verifyChangePermission(change: permissionChange, statusMessage: statusMessage, owner: userA)
                }
            }
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    func verifyChangePermission(change: SyncPermissionChange, statusMessage: String, owner: SyncUser) throws {
        let managementRealm = try owner.managementRealm()

        let exp = expectation(description: "A new permission will be granted by the server")
        let token = managementRealm.objects(SyncPermissionChange.self).filter("id = %@", change.id).addNotificationBlock { changes in
            if case .update(let change, _, _, _) = changes, let statusCode = change[0].statusCode.value {
                XCTAssertEqual(statusCode, 0)
                XCTAssertEqual(change[0].status, .success)
                XCTAssertNotNil(change[0].statusMessage?.range(of: statusMessage))
                exp.fulfill()
            }
        }

        try managementRealm.write {
            managementRealm.add(change)
        }

        waitForExpectations(timeout: 2)
        token.stop()
    }
}
#else
class SwiftObjectServerTests: SwiftSyncTestCase {
    /// It should be possible to successfully open a Realm configured for sync.
    func testBasicSwiftSync() {
        let url = NSURL(string: "realm://localhost:9080/~/testBasicSync")!
        do {
            let user = try synchronouslyLogInUser(for: basicCredentials(register: true), server: authURL)
            let realm = try synchronouslyOpenRealm(url: url, user: user)
            XCTAssert(realm.isEmpty, "Freshly synced Realm was not empty...")
        } catch {
            XCTFail("Got an error: \(error)")
        }
    }

    /// If client B adds objects to a Realm, client A should see those new objects.
    func testSwiftAddObjects() {
        do {
            let user = try synchronouslyLogInUser(for: basicCredentials(register: isParent), server: authURL)
            let realm = try synchronouslyOpenRealm(url: realmURL, user: user)
            if isParent {
                user.waitForDownloadToFinish(realmURL)
                checkCount(expected: 0, realm, SwiftSyncObject.self)
                executeChild()
                user.waitForDownloadToFinish(realmURL)
                checkCount(expected: 3, realm, SwiftSyncObject.self)
            } else {
                // Add objects
                try realm.write {
                    realm.add(SwiftSyncObject(value: ["child-1"]))
                    realm.add(SwiftSyncObject(value: ["child-2"]))
                    realm.add(SwiftSyncObject(value: ["child-3"]))
                }
                user.waitForUploadToFinish(realmURL)
                checkCount(expected: 3, realm, SwiftSyncObject.self)
            }
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    /// If client B removes objects from a Realm, client A should see those changes.
    func testSwiftDeleteObjects() {
        do {
            let user = try synchronouslyLogInUser(for: basicCredentials(register: isParent), server: authURL)
            let realm = try synchronouslyOpenRealm(url: realmURL, user: user)
            if isParent {
                try realm.write {
                    realm.add(SwiftSyncObject(value: ["child-1"]))
                    realm.add(SwiftSyncObject(value: ["child-2"]))
                    realm.add(SwiftSyncObject(value: ["child-3"]))
                }
                user.waitForUploadToFinish(realmURL)
                checkCount(expected: 3, realm, SwiftSyncObject.self)
                executeChild()
                user.waitForDownloadToFinish(realmURL)
                checkCount(expected: 0, realm, SwiftSyncObject.self)
            } else {
                try realm.write {
                    realm.deleteAll()
                }
                user.waitForUploadToFinish(realmURL)
                checkCount(expected:0, realm, SwiftSyncObject.self)
            }
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    // MARK: Permissions

    func testPermissionChange() {
        do {
            let userA = try synchronouslyLogInUser(for: basicCredentials(register: isParent, usernameSuffix: "_A"), server: authURL)
            let userB = try synchronouslyLogInUser(for: basicCredentials(register: isParent, usernameSuffix: "_B"), server: authURL)
            _ = try synchronouslyOpenRealm(url: realmURL, user: userA)

            let adminPermissions: [[Bool?]] = [
                [true, true, true],
                [false, true, true],
                [true, false, true],
                [false, false, true]
            ]
            let readWritePermissions: [[Bool?]] = [[true, true, false]]
            let readOnlyPermissions: [[Bool?]] = [[true, false, false]]
            let noAccessPermissions: [[Bool?]] = [
                [false, false, false],
                [nil, nil, nil]
            ]
            let permissions: [[[Bool?]]] = [adminPermissions, readWritePermissions, readOnlyPermissions, noAccessPermissions]
            let statusMessages = [
                "administrative access",
                "read-write access",
                "read-only access",
                "no access"
            ]

            for (accessPermissions, statusMessage) in zip(permissions, statusMessages) {
                for permissions in accessPermissions {
                    let permissionChange = SyncPermissionChange(
                        realmURL: realmURL.absoluteString,
                        userID: userB.identity!,
                        mayRead: permissions[0],
                        mayWrite: permissions[1],
                        mayManage: permissions[2]
                    )
                    try verifyChangePermission(change: permissionChange, statusMessage: statusMessage, owner: userA)
                }
            }
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    func verifyChangePermission(change change: SyncPermissionChange, statusMessage: String, owner: SyncUser) throws {
        let managementRealm = try owner.managementRealm()

        let exp = expectationWithDescription("A new permission will be granted by the server")
        let token = managementRealm.objects(SyncPermissionChange.self).filter("id = %@", change.id).addNotificationBlock { changes in
            if case .Update(let change, _, _, _) = changes, let statusCode = change[0].statusCode.value {
                XCTAssertEqual(statusCode, 0)
                XCTAssertEqual(change[0].status, SyncManagementObjectStatus.Success)
                XCTAssertNotNil(change[0].statusMessage?.rangeOfString(statusMessage))
                exp.fulfill()
            }
        }

        try managementRealm.write {
            managementRealm.add(change)
        }

        waitForExpectationsWithTimeout(2, handler: nil)
        token.stop()
    }
}
#endif
