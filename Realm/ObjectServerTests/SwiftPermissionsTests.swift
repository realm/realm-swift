////////////////////////////////////////////////////////////////////////////
//
// Copyright 2018 Realm Inc.
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

final class PermissionUser: Object {
    // A class with a name that conflicts with an Object class from RealmSwift to verify
    // that it doesn't break anything
}

class SwiftPermissionsAPITests: SwiftSyncTestCase {
    var userA: SyncUser!
    var userB: SyncUser!
    var userC: SyncUser!

    override func setUp() {
        super.setUp()
        let baseName = UUID().uuidString
        userA = try! synchronouslyLogInUser(for: .usernamePassword(username: baseName + "-a", password: "a", register: true),
                                            server: SwiftSyncTestCase.authServerURL())
        userB = try! synchronouslyLogInUser(for: .usernamePassword(username: baseName + "-b", password: "a", register: true),
                                            server: SwiftSyncTestCase.authServerURL())
        userC = try! synchronouslyLogInUser(for: .usernamePassword(username: baseName + "-c", password: "a", register: true),
                                            server: SwiftSyncTestCase.authServerURL())
    }

    override func tearDown() {
        userA.logOut()
        userB.logOut()
        userC.logOut()
        super.tearDown()
    }

    // MARK: Helper functions

    func openRealm(_ url: URL, _ user: SyncUser) -> Realm {
        let realm = try! Realm(configuration: user.configuration(realmURL: url))
        waitForSync(realm)
        return realm
    }

    func subscribe<T: Object>(realm: Realm, type: T.Type, _ filter: String = "TRUEPREDICATE") {
        let subscription = realm.objects(type).filter(filter).subscribe()
        let ex = expectation(description: "Waiting for subscription completion")
        let token = subscription.observe(\.state, options: .initial) { state in
            if state == .complete {
                ex.fulfill()
            }
        }
        waitForExpectations(timeout: 20.0)
        token.invalidate()
    }

    func waitForSync(_ realm: Realm) {
        waitForUploads(for: realm)
        waitForDownloads(for: realm)
        realm.refresh()
    }

    func createRealm(name: String, permissions: (Realm) -> Void) -> URL {
        // Create a new Realm with an admin user
        let admin = createAdminUser(for: SwiftSyncTestCase.authServerURL(),
                                    username: UUID().uuidString + "-admin")
        let url = URL(string: "realm://127.0.0.1:9080/\(name.replacingOccurrences(of: "()", with: ""))")!
        let adminRealm = openRealm(url, admin)
        // FIXME: we currently need to add a subscription to get the permissions types sent to us
        subscribe(realm: adminRealm, type: SwiftSyncObject.self)

        // Set up permissions on the Realm
        try! adminRealm.write {
            adminRealm.create(SwiftSyncObject.self, value: ["obj 1"])
            permissions(adminRealm)
        }

        // FIXME: we currently need to also add the old realm-level permissions
        let ex1 = expectation(description: "Setting a permission should work.")
        let ex2 = expectation(description: "Setting a permission should work.")
        let ex3 = expectation(description: "Setting a permission should work.")
        admin.apply(SyncPermission(realmPath: url.path, identity: userA.identity!, accessLevel: .read)) { error in
            XCTAssertNil(error)
            ex1.fulfill()
        }
        admin.apply(SyncPermission(realmPath: url.path, identity: userB.identity!, accessLevel: .read)) { error in
            XCTAssertNil(error)
            ex2.fulfill()
        }
        admin.apply(SyncPermission(realmPath: url.path, identity: userC.identity!, accessLevel: .read)) { error in
            XCTAssertNil(error)
            ex3.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
        waitForSync(adminRealm)

        return url
    }

    func createDefaultPermisisons(_ permissions: List<Permission>) {
        var p = permissions.findOrCreate(forRoleNamed: "everyone")
        p.canCreate = false
        p.canRead = false
        p.canQuery = false
        p.canDelete = false
        p.canUpdate = false
        p.canModifySchema = false
        p.canSetPermissions = false

        p = permissions.findOrCreate(forRoleNamed: "reader")
        p.canRead = true
        p.canQuery = true

        p = permissions.findOrCreate(forRoleNamed: "writer")
        p.canUpdate = true
        p.canCreate = true
        p.canDelete = true

        p = permissions.findOrCreate(forRoleNamed: "admin")
        p.canSetPermissions = true
    }

    func add(user: SyncUser, toRole roleName: String, inRealm realm: Realm) {
        let user = realm.create(RealmSwift.PermissionUser.self, value: [user.identity!], update: .modified)
        realm.create(PermissionRole.self, value: [roleName], update: .modified).users.append(user)
    }


    // MARK: Tests

    func testAsyncOpenWaitsForPermissions() {
        let url = createRealm(name: #function) { realm in
            createDefaultPermisisons(realm.permissions)
            add(user: userA, toRole: "reader", inRealm: realm)
        }

        let ex = expectation(description: "asyncOpen")
        var subscription: SyncSubscription!
        var token: NotificationToken!
        Realm.asyncOpen(configuration: userA.configuration(realmURL: url)) { realm, error in
            XCTAssertNil(error)
            // Will crash if the __Class object for swiftSyncObject wasn't downloaded
            _ = realm!.permissions(forType: SwiftSyncObject.self)

            // Make sure that the dummy subscription we created hasn't interfered
            // with adding new subscriptions.
            subscription = realm!.objects(SwiftSyncObject.self).subscribe()
            token = subscription.observe(\.state, options: .initial) { state in
                if state == .complete {
                    ex.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 10.0, handler: nil)
        token.invalidate()
    }

    func testRealmRead() {
        let url = createRealm(name: "testRealmRead") { realm in
            createDefaultPermisisons(realm.permissions)
            add(user: userA, toRole: "reader", inRealm: realm)
        }

        // userA should now be able to open the Realm and see objects
        let realmA = openRealm(url, userA)
        subscribe(realm: realmA, type: SwiftSyncObject.self)
        XCTAssertEqual(realmA.getPrivileges(), [.read])
        XCTAssertEqual(realmA.getPrivileges(SwiftSyncObject.self), [.read, .subscribe])
        XCTAssertEqual(realmA.getPrivileges(realmA.objects(SwiftSyncObject.self).first!), [.read])

        // userA should not be able to create new objects
        XCTAssertEqual(realmA.objects(SwiftSyncObject.self).count, 1)
        try! realmA.write {
            realmA.create(SwiftSyncObject.self, value: ["obj 2"])
        }
        XCTAssertEqual(realmA.objects(SwiftSyncObject.self).count, 2)
        waitForSync(realmA)
        XCTAssertEqual(realmA.objects(SwiftSyncObject.self).count, 1)

        // userB should not be able to read any objects
        let realmB = openRealm(url, userB)
        subscribe(realm: realmB, type: SwiftSyncObject.self)
        XCTAssertEqual(realmB.getPrivileges(), [])
        XCTAssertEqual(realmB.getPrivileges(SwiftSyncObject.self), [])
        XCTAssertEqual(realmB.objects(SwiftSyncObject.self).count, 0)
    }

    func testRealmWrite() {
        let url = createRealm(name: "testRealmWrite") { realm in
            createDefaultPermisisons(realm.permissions)
            add(user: userA, toRole: "reader", inRealm: realm)
            add(user: userA, toRole: "writer", inRealm: realm)
            add(user: userB, toRole: "reader", inRealm: realm)
        }

        // userA should now be able to open the Realm and see objects
        let realmA = openRealm(url, userA)
        subscribe(realm: realmA, type: SwiftSyncObject.self)
        XCTAssertEqual(realmA.getPrivileges(), [.read, .update])
        XCTAssertEqual(realmA.getPrivileges(SwiftSyncObject.self),
                       [.read, .subscribe, .update, .create, .setPermissions])
        XCTAssertEqual(realmA.getPrivileges(realmA.objects(SwiftSyncObject.self).first!),
                       [.read, .update, .delete, .setPermissions])

        // userA should be able to create new objects
        XCTAssertEqual(realmA.objects(SwiftSyncObject.self).count, 1)
        try! realmA.write {
            realmA.create(SwiftSyncObject.self, value: ["obj 2"])
        }
        XCTAssertEqual(realmA.objects(SwiftSyncObject.self).count, 2)
        waitForSync(realmA)
        XCTAssertEqual(realmA.objects(SwiftSyncObject.self).count, 2)

        // userB's insertions should be reverted
        let realmB = openRealm(url, userB)
        subscribe(realm: realmB, type: SwiftSyncObject.self)
        XCTAssertEqual(realmB.objects(SwiftSyncObject.self).count, 2)
        try! realmB.write {
            realmB.create(SwiftSyncObject.self, value: ["obj 3"])
        }
        XCTAssertEqual(realmB.objects(SwiftSyncObject.self).count, 3)
        waitForSync(realmB)
        XCTAssertEqual(realmB.objects(SwiftSyncObject.self).count, 2)
    }
    func testRealmSetPermissions() {

    }
    func testRealmModifySchema() {

    }

    func testClassRead() {
        let url = createRealm(name: "testClassRead") { realm in
            createDefaultPermisisons(realm.permissions(forType: SwiftSyncObject.self))
            add(user: userA, toRole: "reader", inRealm: realm)
        }

        // userA should now be able to open the Realm and see objects
        let realmA = openRealm(url, userA)
        subscribe(realm: realmA, type: SwiftSyncObject.self)
        XCTAssertEqual(realmA.getPrivileges(), [.read, .update, .setPermissions, .modifySchema])
        XCTAssertEqual(realmA.getPrivileges(SwiftSyncObject.self), [.read, .subscribe])
        XCTAssertEqual(realmA.getPrivileges(realmA.objects(SwiftSyncObject.self).first!), [.read])

        // userA should not be able to create new objects
        XCTAssertEqual(realmA.objects(SwiftSyncObject.self).count, 1)
        try! realmA.write {
            realmA.create(SwiftSyncObject.self, value: ["obj 2"])
        }
        XCTAssertEqual(realmA.objects(SwiftSyncObject.self).count, 2)
        waitForSync(realmA)
        XCTAssertEqual(realmA.objects(SwiftSyncObject.self).count, 1)

        // userB should not be able to read any objects
        let realmB = openRealm(url, userB)
        subscribe(realm: realmB, type: SwiftSyncObject.self)
        XCTAssertEqual(realmB.getPrivileges(), [.read, .update, .setPermissions, .modifySchema])
        XCTAssertEqual(realmB.getPrivileges(SwiftSyncObject.self), [])
        XCTAssertEqual(realmB.objects(SwiftSyncObject.self).count, 0)
    }
    func testClassWrite() {

    }
    func testClassSetPermissions() {

    }
}
