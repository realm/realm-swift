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

// Used by testOfflineClientReset
// The naming here is nonstandard as the sync-1.x.realm test file comes from the .NET unit tests.
// swiftlint:disable identifier_name
@objc(Person)
class Person: Object {
    @objc dynamic var FirstName: String?
    @objc dynamic var LastName: String?

    override class func shouldIncludeInDefaultSchema() -> Bool { return false }
}

class SwiftObjectServerTests: SwiftSyncTestCase {

    /// It should be possible to successfully open a Realm configured for sync.
    func testBasicSwiftSync() {
        let url = URL(string: "realm://127.0.0.1:9080/~/testBasicSync")!
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
                waitForDownloads(for: realm)
                checkCount(expected: 0, realm, SwiftSyncObject.self)
                executeChild()
                waitForDownloads(for: realm)
                checkCount(expected: 3, realm, SwiftSyncObject.self)
            } else {
                // Add objects
                try realm.write {
                    realm.add(SwiftSyncObject(value: ["child-1"]))
                    realm.add(SwiftSyncObject(value: ["child-2"]))
                    realm.add(SwiftSyncObject(value: ["child-3"]))
                }
                waitForUploads(for: realm)
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
                waitForUploads(for: realm)
                checkCount(expected: 3, realm, SwiftSyncObject.self)
                executeChild()
                waitForDownloads(for: realm)
                checkCount(expected: 0, realm, SwiftSyncObject.self)
            } else {
                try realm.write {
                    realm.deleteAll()
                }
                waitForUploads(for: realm)
                checkCount(expected: 0, realm, SwiftSyncObject.self)
            }
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    // MARK: - Client reset

    func testClientReset() {
        do {
            let user = try synchronouslyLogInUser(for: basicCredentials(register: isParent), server: authURL)
            let realm = try synchronouslyOpenRealm(url: realmURL, user: user)

            var theError: SyncError?
            let ex = expectation(description: "Waiting for error handler to be called...")
            SyncManager.shared.errorHandler = { (error, session) in
                if let error = error as? SyncError {
                    theError = error
                } else {
                    XCTFail("Error \(error) was not a sync error. Something is wrong.")
                }
                ex.fulfill()
            }
            user.simulateClientResetError(forSession: realmURL)
            waitForExpectations(timeout: 10, handler: nil)
            XCTAssertNotNil(theError)
            XCTAssertTrue(theError!.code == SyncError.Code.clientResetError)
            let resetInfo = theError!.clientResetInfo()
            XCTAssertNotNil(resetInfo)
            XCTAssertTrue(resetInfo!.0.contains("io.realm.object-server-recovered-realms/recovered_realm"))
            XCTAssertNotNil(realm)
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    func testClientResetManualInitiation() {
        do {
            let user = try synchronouslyLogInUser(for: basicCredentials(register: isParent), server: authURL)
            var theError: SyncError?

            try autoreleasepool {
                let realm = try synchronouslyOpenRealm(url: realmURL, user: user)
                let ex = expectation(description: "Waiting for error handler to be called...")
                SyncManager.shared.errorHandler = { (error, session) in
                    if let error = error as? SyncError {
                        theError = error
                    } else {
                        XCTFail("Error \(error) was not a sync error. Something is wrong.")
                    }
                    ex.fulfill()
                }
                user.simulateClientResetError(forSession: realmURL)
                waitForExpectations(timeout: 10, handler: nil)
                XCTAssertNotNil(theError)
                XCTAssertNotNil(realm)
            }
            let (path, errorToken) = theError!.clientResetInfo()!
            XCTAssertFalse(FileManager.default.fileExists(atPath: path))
            SyncSession.immediatelyHandleError(errorToken)
            XCTAssertTrue(FileManager.default.fileExists(atPath: path))
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    // MARK: - Progress notifiers

    func testStreamingDownloadNotifier() {
        let bigObjectCount = 2
        do {
            var callCount = 0
            var transferred = 0
            var transferrable = 0
            let user = try synchronouslyLogInUser(for: basicCredentials(register: isParent), server: authURL)
            let realm = try synchronouslyOpenRealm(url: realmURL, user: user)
            if isParent {
                let session = realm.syncSession
                XCTAssertNotNil(session)
                let ex = expectation(description: "streaming-downloads-expectation")
                var hasBeenFulfilled = false
                let token = session!.addProgressNotification(for: .download, mode: .reportIndefinitely) { p in
                    callCount += 1
                    XCTAssert(p.transferredBytes >= transferred)
                    XCTAssert(p.transferrableBytes >= transferrable)
                    transferred = p.transferredBytes
                    transferrable = p.transferrableBytes
                    if p.transferredBytes > 0 && p.isTransferComplete && !hasBeenFulfilled {
                        ex.fulfill()
                        hasBeenFulfilled = true
                    }
                }
                // Wait for the child process to upload all the data.
                executeChild()
                waitForExpectations(timeout: 10.0, handler: nil)
                token!.invalidate()
                XCTAssert(callCount > 1)
                XCTAssert(transferred >= transferrable)
            } else {
                try realm.write {
                    for _ in 0..<bigObjectCount {
                        realm.add(SwiftHugeSyncObject())
                    }
                }
                waitForUploads(for: realm)
                checkCount(expected: bigObjectCount, realm, SwiftHugeSyncObject.self)
            }
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    func testStreamingUploadNotifier() {
        let bigObjectCount = 2
        do {
            var callCount = 0
            var transferred = 0
            var transferrable = 0
            let user = try synchronouslyLogInUser(for: basicCredentials(register: isParent), server: authURL)
            let realm = try synchronouslyOpenRealm(url: realmURL, user: user)
            let session = realm.syncSession
            XCTAssertNotNil(session)
            let ex = expectation(description: "streaming-uploads-expectation")
            var hasBeenFulfilled = false
            let token = session!.addProgressNotification(for: .upload, mode: .reportIndefinitely) { p in
                callCount += 1
                XCTAssert(p.transferredBytes >= transferred)
                XCTAssert(p.transferrableBytes >= transferrable)
                transferred = p.transferredBytes
                transferrable = p.transferrableBytes
                if p.transferredBytes > 0 && p.isTransferComplete && !hasBeenFulfilled {
                    ex.fulfill()
                    hasBeenFulfilled = true
                }
            }
            try realm.write {
                for _ in 0..<bigObjectCount {
                    realm.add(SwiftHugeSyncObject())
                }
            }
            waitForExpectations(timeout: 10.0, handler: nil)
            token!.invalidate()
            XCTAssert(callCount > 1)
            XCTAssert(transferred >= transferrable)
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    // MARK: - Download Realm

    func testDownloadRealm() {
        let bigObjectCount = 2
        do {
            let user = try synchronouslyLogInUser(for: basicCredentials(register: isParent), server: authURL)
            if isParent {
                // Wait for the child process to upload everything.
                executeChild()
                let ex = expectation(description: "download-realm")
                let config = user.configuration(realmURL: realmURL, fullSynchronization: true)
                let pathOnDisk = ObjectiveCSupport.convert(object: config).pathOnDisk
                XCTAssertFalse(FileManager.default.fileExists(atPath: pathOnDisk))
                Realm.asyncOpen(configuration: config) { realm, error in
                    XCTAssertNil(error)
                    self.checkCount(expected: bigObjectCount, realm!, SwiftHugeSyncObject.self)
                    ex.fulfill()
                }
                func fileSize(path: String) -> Int {
                    if let attr = try? FileManager.default.attributesOfItem(atPath: path) {
                        return attr[.size] as! Int
                    }
                    return 0
                }
                let sizeBefore = fileSize(path: pathOnDisk)
                autoreleasepool {
                    // We have partial transaction logs but no data
                    XCTAssertGreaterThan(sizeBefore, 0)
                    XCTAssert(try! Realm(configuration: config).isEmpty)
                }
                XCTAssertFalse(RLMHasCachedRealmForPath(pathOnDisk))
                waitForExpectations(timeout: 10.0, handler: nil)
                XCTAssertGreaterThan(fileSize(path: pathOnDisk), sizeBefore)
                XCTAssertFalse(RLMHasCachedRealmForPath(pathOnDisk))
            } else {
                let realm = try synchronouslyOpenRealm(url: realmURL, user: user)
                // Write lots of data to the Realm, then wait for it to be uploaded.
                try realm.write {
                    for _ in 0..<bigObjectCount {
                        realm.add(SwiftHugeSyncObject())
                    }
                }
                waitForUploads(for: realm)
                checkCount(expected: bigObjectCount, realm, SwiftHugeSyncObject.self)
            }
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    // MARK: - Administration

    func testRetrieveUserInfo() {
        let adminUsername = "jyaku.swift"
        let nonAdminUsername = "meela.swift@realm.example.org"
        let password = "p"
        let server = SwiftObjectServerTests.authServerURL()

        // Create a non-admin user.
        _ = logInUser(for: .init(username: nonAdminUsername, password: password, register: true),
                      server: server)
        // Create an admin user.
        let adminUser = createAdminUser(for: server, username: adminUsername)

        // Look up information about the non-admin user from the admin user.
        let ex = expectation(description: "Should be able to look up user information")
        adminUser.retrieveInfo(forUser: nonAdminUsername, identityProvider: .usernamePassword) { (userInfo, err) in
            XCTAssertNil(err)
            XCTAssertNotNil(userInfo)
            guard let userInfo = userInfo else {
                return
            }
            let account = userInfo.accounts.first!
            XCTAssertEqual(account.providerUserIdentity, nonAdminUsername)
            XCTAssertEqual(account.provider, Provider.usernamePassword)
            XCTAssertFalse(userInfo.isAdmin)
            ex.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: - Authentication

    func testInvalidCredentials() {
        do {
            let username = "testInvalidCredentialsUsername"
            let credentials = SyncCredentials.usernamePassword(username: username,
                                                               password: "THIS_IS_A_PASSWORD",
                                                               register: true)
            _ = try synchronouslyLogInUser(for: credentials, server: authURL)
            // Now log in the same user, but with a bad password.
            let ex = expectation(description: "wait for user login")
            let credentials2 = SyncCredentials.usernamePassword(username: username, password: "NOT_A_VALID_PASSWORD")
            SyncUser.logIn(with: credentials2, server: authURL) { user, error in
                XCTAssertNil(user)
                XCTAssertTrue(error is SyncAuthError)
                let castError = error as! SyncAuthError
                XCTAssertEqual(castError.code, SyncAuthError.invalidCredential)
                ex.fulfill()
            }
            waitForExpectations(timeout: 2.0, handler: nil)
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    // MARK: - User-specific functionality

    func testUserExpirationCallback() {
        do {
            let user = try synchronouslyLogInUser(for: basicCredentials(), server: authURL)

            // Set a callback on the user
            var blockCalled = false
            let ex = expectation(description: "Error callback should fire upon receiving an error")
            user.errorHandler = { (u, error) in
                XCTAssertEqual(u.identity, user.identity)
                XCTAssertEqual(error.code, .accessDeniedOrInvalidPath)
                blockCalled = true
                ex.fulfill()
            }

            // Screw up the token on the user.
            manuallySetRefreshToken(for: user, value: "not-a-real-token")

            // Try to open a Realm with the user; this will cause our errorHandler block defined above to be fired.
            XCTAssertFalse(blockCalled)
            _ = try immediatelyOpenRealm(url: realmURL, user: user)
            waitForExpectations(timeout: 10.0, handler: nil)
            XCTAssertEqual(user.state, .loggedOut)
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    // MARK: - Offline client reset

    func testOfflineClientReset() {
        let user = try! synchronouslyLogInUser(for: basicCredentials(), server: authURL)

        let sourceFileURL = Bundle(for: type(of: self)).url(forResource: "sync-1.x", withExtension: "realm")!
        let fileName = "\(UUID()).realm"
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        try! FileManager.default.copyItem(at: sourceFileURL, to: fileURL)

        let syncConfig = RLMSyncConfiguration(user: user, realmURL: realmURL)
        syncConfig.customFileURL = fileURL
        let config = Realm.Configuration(syncConfiguration: ObjectiveCSupport.convert(object: syncConfig))
        do {
            _ = try Realm(configuration: config)
        } catch let e as Realm.Error where e.code == .incompatibleSyncedFile {
            var backupConfiguration = e.backupConfiguration
            XCTAssertNotNil(backupConfiguration)

            // Open the backup Realm with a schema subset since it was created using the schema from .NET's unit tests.
            backupConfiguration!.objectTypes = [Person.self]
            let backupRealm = try! Realm(configuration: backupConfiguration!)

            let people = backupRealm.objects(Person.self)
            XCTAssertEqual(people.count, 1)
            XCTAssertEqual(people[0].FirstName, "John")
            XCTAssertEqual(people[0].LastName, "Smith")

            // Verify that we can now successfully open the original synced Realm.
            _ = try! Realm(configuration: config)
        } catch {
            fatalError("Unexpected error: \(error)")
        }
    }

    // MARK: - Partial sync

// Partial sync subscriptions are only available in Swift 3.2 and newer.
#if swift(>=3.2)
    func testPartialSync() {
        autoreleasepool {
            // Log in and populate the Realm.
            autoreleasepool {
                let credentials = SyncCredentials.usernamePassword(username: "Swift.testPartialSync", password: "a", register: true)
                let user = try! synchronouslyLogInUser(for: credentials, server: authURL)
                let realm = try! synchronouslyOpenRealm(configuration: user.configuration())

                try! realm.write {
                    realm.add(SwiftPartialSyncObjectA(number: 0, string: "realm"))
                    realm.add(SwiftPartialSyncObjectA(number: 1, string: ""))
                    realm.add(SwiftPartialSyncObjectA(number: 2, string: ""))
                    realm.add(SwiftPartialSyncObjectA(number: 3, string: ""))
                    realm.add(SwiftPartialSyncObjectA(number: 4, string: "realm"))
                    realm.add(SwiftPartialSyncObjectA(number: 5, string: "sync"))
                    realm.add(SwiftPartialSyncObjectA(number: 6, string: "partial"))
                    realm.add(SwiftPartialSyncObjectA(number: 7, string: "partial"))
                    realm.add(SwiftPartialSyncObjectA(number: 8, string: "partial"))
                    realm.add(SwiftPartialSyncObjectA(number: 9, string: "partial"))
                    realm.add(SwiftPartialSyncObjectB(number: 0, firstString: "", secondString: ""))
                    realm.add(SwiftPartialSyncObjectB(number: 1, firstString: "", secondString: ""))
                    realm.add(SwiftPartialSyncObjectB(number: 2, firstString: "", secondString: ""))
                    realm.add(SwiftPartialSyncObjectB(number: 3, firstString: "", secondString: ""))
                    realm.add(SwiftPartialSyncObjectB(number: 4, firstString: "", secondString: ""))
                    realm.add(SwiftPartialSyncObjectB(number: 5, firstString: "", secondString: ""))
                    realm.add(SwiftPartialSyncObjectB(number: 6, firstString: "", secondString: ""))
                    realm.add(SwiftPartialSyncObjectB(number: 7, firstString: "", secondString: ""))
                    realm.add(SwiftPartialSyncObjectB(number: 8, firstString: "", secondString: ""))
                    realm.add(SwiftPartialSyncObjectB(number: 9, firstString: "", secondString: ""))
                }

                waitForUploads(for: realm)
            }

            // Log back in and do partial sync stuff.
            autoreleasepool {
                let credentials = SyncCredentials.usernamePassword(username: "Swift.testPartialSync", password: "a")
                let user = try! synchronouslyLogInUser(for: credentials, server: authURL)
                let realm = try! synchronouslyOpenRealm(configuration: user.configuration())

                let ex = expectation(description: "Should be able to successfully complete a query")
                let results = realm.objects(SwiftPartialSyncObjectA.self).filter("number > 5")
                let subscription = results.subscribe(named: "query")
                XCTAssertEqual(subscription.state, .creating)
                waitUntilStateMatches(subscription, expectation: ex) { state in state == .complete }

                // Verify that we got what we're looking for
                XCTAssertEqual(results.count, 4)
                for object in results {
                    XCTAssertGreaterThan(object.number, 5)
                    XCTAssertEqual(object.string, "partial")
                }

                // And that we didn't get anything else.
                XCTAssertEqual(realm.objects(SwiftPartialSyncObjectA.self).count, results.count)
                XCTAssertTrue(realm.objects(SwiftPartialSyncObjectB.self).isEmpty)

                // Re-subscribing to an existing named query may not report the query's state immediately,
                // but it should report it eventually.
                let ex2 = expectation(description: "Re-subscribing should fire the state change callback")
                let subscription2 = realm.objects(SwiftPartialSyncObjectA.self).filter("number > 5").subscribe(named: "query")
                waitUntilStateMatches(subscription2, expectation: ex2) { state in state == .complete }

                // Creating a subscription with the same name but different query should raise an error.
                let ex3 = expectation(description: "Waiting for error")
                let subscription3 = realm.objects(SwiftPartialSyncObjectA.self).filter("number < 5").subscribe(named: "query")
                waitUntilStateMatches(subscription3, expectation: ex3) { state in
                    if case .error(_) = state {
                        return true
                    }
                    return false
                }

                // Unsubscribing should move the subscription to the invalidated state.
                let ex4 = expectation(description: "Waiting for unsubscribe")
                subscription.unsubscribe()
                waitUntilStateMatches(subscription, expectation: ex4) { state in state == .invalidated }
            }
        }
    }

    func waitUntilStateMatches<T>(_ subscription: SyncSubscription<T>, expectation: XCTestExpectation,
                                  matcher: @escaping (SyncSubscriptionState) -> Bool) {
        let token = subscription.observe(\.state, options: .initial) { state in
            if matcher(state) {
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 20.0)
        token.invalidate()
    }
#endif // Swift >= 3.2
}
