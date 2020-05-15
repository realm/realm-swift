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

    func testConnectionState() {
        let user = try! synchronouslyLogInUser(for: basicCredentials(register: true), server: authURL)
        let realm = try! synchronouslyOpenRealm(url: realmURL, user: user)
        let session = realm.syncSession!

        func wait(forState desiredState: SyncSession.ConnectionState) {
            let ex = expectation(description: "Wait for connection state: \(desiredState)")
            let token = session.observe(\SyncSession.connectionState, options: .initial) { s, _ in
                if s.connectionState == desiredState {
                    ex.fulfill()
                }
            }
            waitForExpectations(timeout: 2.0)
            token.invalidate()
        }

        wait(forState: .connected)

        session.suspend()
        wait(forState: .disconnected)

        session.resume()
        wait(forState: .connecting)
        wait(forState: .connected)
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

    let bigObjectCount = 2

    func populateRealm(user: SyncUser, url: URL) {
        let realm = try! synchronouslyOpenRealm(url: realmURL, user: user)
        try! realm.write {
            for _ in 0..<bigObjectCount {
                realm.add(SwiftHugeSyncObject())
            }
        }
        waitForUploads(for: realm)
        checkCount(expected: bigObjectCount, realm, SwiftHugeSyncObject.self)
    }

    func testStreamingDownloadNotifier() {
        let user = try! synchronouslyLogInUser(for: basicCredentials(register: isParent), server: authURL)
        if !isParent {
            populateRealm(user: user, url: realmURL)
            return
        }

        var callCount = 0
        var transferred = 0
        var transferrable = 0
        let realm = try! synchronouslyOpenRealm(url: realmURL, user: user)

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
    }

    func testStreamingUploadNotifier() {
        do {
            var transferred = 0
            var transferrable = 0
            let user = try synchronouslyLogInUser(for: basicCredentials(register: isParent), server: authURL)
            let realm = try synchronouslyOpenRealm(url: realmURL, user: user)
            let session = realm.syncSession
            XCTAssertNotNil(session)
            var ex = expectation(description: "initial upload")
            let token = session!.addProgressNotification(for: .upload, mode: .reportIndefinitely) { p in
                XCTAssert(p.transferredBytes >= transferred)
                XCTAssert(p.transferrableBytes >= transferrable)
                transferred = p.transferredBytes
                transferrable = p.transferrableBytes
                if p.transferredBytes > 0 && p.isTransferComplete {
                    ex.fulfill()
                }
            }
            waitForExpectations(timeout: 10.0, handler: nil)
            ex = expectation(description: "write transaction upload")
            try realm.write {
                for _ in 0..<bigObjectCount {
                    realm.add(SwiftHugeSyncObject())
                }
            }
            waitForExpectations(timeout: 10.0, handler: nil)
            token!.invalidate()
            XCTAssert(transferred >= transferrable)
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    // MARK: - Download Realm

    func testDownloadRealm() {
        let user = try! synchronouslyLogInUser(for: basicCredentials(register: isParent), server: authURL)
        if !isParent {
            populateRealm(user: user, url: realmURL)
            return
        }

        // Wait for the child process to upload everything.
        executeChild()

        let ex = expectation(description: "download-realm")
        let config = user.configuration(realmURL: realmURL, fullSynchronization: true)
        let pathOnDisk = ObjectiveCSupport.convert(object: config).pathOnDisk
        XCTAssertFalse(FileManager.default.fileExists(atPath: pathOnDisk))
        Realm.asyncOpen(configuration: config) { realm, error in
            XCTAssertNil(error)
            self.checkCount(expected: self.bigObjectCount, realm!, SwiftHugeSyncObject.self)
            ex.fulfill()
        }
        func fileSize(path: String) -> Int {
            if let attr = try? FileManager.default.attributesOfItem(atPath: path) {
                return attr[.size] as! Int
            }
            return 0
        }
        XCTAssertFalse(RLMHasCachedRealmForPath(pathOnDisk))
        waitForExpectations(timeout: 10.0, handler: nil)
        XCTAssertGreaterThan(fileSize(path: pathOnDisk), 0)
        XCTAssertFalse(RLMHasCachedRealmForPath(pathOnDisk))
    }

    func testDownloadRealmToCustomPath() {
        let user = try! synchronouslyLogInUser(for: basicCredentials(register: isParent), server: authURL)
        if !isParent {
            populateRealm(user: user, url: realmURL)
            return
        }

        // Wait for the child process to upload everything.
        executeChild()

        let ex = expectation(description: "download-realm")
        let customFileURL = realmURLForFile("copy")
        var config = user.configuration(realmURL: realmURL, fullSynchronization: true)
        config.fileURL = customFileURL
        let pathOnDisk = ObjectiveCSupport.convert(object: config).pathOnDisk
        XCTAssertEqual(pathOnDisk, customFileURL.path)
        XCTAssertFalse(FileManager.default.fileExists(atPath: pathOnDisk))
        Realm.asyncOpen(configuration: config) { realm, error in
            XCTAssertNil(error)
            self.checkCount(expected: self.bigObjectCount, realm!, SwiftHugeSyncObject.self)
            ex.fulfill()
        }
        func fileSize(path: String) -> Int {
            if let attr = try? FileManager.default.attributesOfItem(atPath: path) {
                return attr[.size] as! Int
            }
            return 0
        }
        XCTAssertFalse(RLMHasCachedRealmForPath(pathOnDisk))
        waitForExpectations(timeout: 10.0, handler: nil)
        XCTAssertGreaterThan(fileSize(path: pathOnDisk), 0)
        XCTAssertFalse(RLMHasCachedRealmForPath(pathOnDisk))
    }


    func testCancelDownloadRealm() {
        let user = try! synchronouslyLogInUser(for: basicCredentials(register: isParent), server: authURL)
        if !isParent {
            populateRealm(user: user, url: realmURL)
            return
        }

        // Wait for the child process to upload everything.
        executeChild()

        // Use a serial queue for asyncOpen to ensure that the first one adds
        // the completion block before the second one cancels it
        RLMSetAsyncOpenQueue(DispatchQueue(label: "io.realm.asyncOpen"))

        let ex = expectation(description: "async open")
        let config = user.configuration(realmURL: realmURL, fullSynchronization: true)
        Realm.asyncOpen(configuration: config) { _, error in
            XCTAssertNotNil(error)
            ex.fulfill()
        }
        let task = Realm.asyncOpen(configuration: config) { _, _ in
            XCTFail("Cancelled completion handler was called")
        }
        task.cancel()
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testAsyncOpenProgress() {
        let user = try! synchronouslyLogInUser(for: basicCredentials(register: isParent), server: authURL)
        if !isParent {
            populateRealm(user: user, url: realmURL)
            return
        }

        // Wait for the child process to upload everything.
        executeChild()

        let ex1 = expectation(description: "async open")
        let ex2 = expectation(description: "download progress")
        let config = user.configuration(realmURL: realmURL, fullSynchronization: true)
        let task = Realm.asyncOpen(configuration: config) { _, error in
            XCTAssertNil(error)
            ex1.fulfill()
        }
        task.addProgressNotification { progress in
            if progress.isTransferComplete {
                ex2.fulfill()
            }
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testAsyncOpenTimeout() {
        let syncTimeoutOptions = SyncTimeoutOptions()
        syncTimeoutOptions.connectTimeout = 3000
        SyncManager.shared.timeoutOptions = syncTimeoutOptions

        // The server proxy adds a 2 second delay, so a 3 second timeout should succeed
        autoreleasepool {
            let user = try! synchronouslyLogInUser(for: basicCredentials(register: true), server: slowConnectAuthURL)
            let config = user.configuration(cancelAsyncOpenOnNonFatalErrors: true)
            let ex = expectation(description: "async open")
            Realm.asyncOpen(configuration: config) { _, error in
                XCTAssertNil(error)
                ex.fulfill()
            }
            waitForExpectations(timeout: 10.0, handler: nil)
            user.logOut()
        }

        self.resetSyncManager()
        self.setupSyncManager()

        // and a 1 second timeout should fail
        autoreleasepool {
            let user = try! synchronouslyLogInUser(for: basicCredentials(register: true), server: slowConnectAuthURL)
            let config = user.configuration(cancelAsyncOpenOnNonFatalErrors: true)

            syncTimeoutOptions.connectTimeout = 1000
            SyncManager.shared.timeoutOptions = syncTimeoutOptions

            let ex = expectation(description: "async open")
            Realm.asyncOpen(configuration: config) { _, error in
                XCTAssertNotNil(error)
                if let error = error as NSError? {
                    XCTAssertEqual(error.code, Int(ETIMEDOUT))
                    XCTAssertEqual(error.domain, NSPOSIXErrorDomain)
                }
                ex.fulfill()
            }
            waitForExpectations(timeout: 4.0, handler: nil)
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

    // MARK: - Certificate Pinning

    func testSecureConnectionToLocalhostWithDefaultSecurity() {
        let user = try! synchronouslyLogInUser(for: basicCredentials(), server: authURL)
        let config = user.configuration(realmURL: URL(string: "realms://localhost:9443/~/default"),
                                        serverValidationPolicy: .system)

        let ex = expectation(description: "Waiting for error handler to be called")
        SyncManager.shared.errorHandler = { (error, session) in
            ex.fulfill()
        }

        _ = try! Realm(configuration: config)
        self.waitForExpectations(timeout: 4.0)
    }

    func testSecureConnectionToLocalhostWithValidationDisabled() {
        let user = try! synchronouslyLogInUser(for: basicCredentials(), server: authURL)
        let config = user.configuration(realmURL: URL(string: "realms://localhost:9443/~/default"),
                                        serverValidationPolicy: .none)
        SyncManager.shared.errorHandler = { (error, session) in
            XCTFail("Unexpected connection failure: \(error)")
        }

        let realm = try! Realm(configuration: config)
        self.waitForUploads(for: realm)
    }

    func testSecureConnectionToLocalhostWithPinnedCertificate() {
        let user = try! synchronouslyLogInUser(for: basicCredentials(), server: authURL)
        let certURL = URL(string: #file)!
            .deletingLastPathComponent()
            .appendingPathComponent("certificates")
            .appendingPathComponent("localhost.cer")

        let config = user.configuration(realmURL: URL(string: "realms://localhost:9443/~/default"),
                                        serverValidationPolicy: .pinCertificate(path: certURL))
        SyncManager.shared.errorHandler = { (error, session) in
            XCTFail("Unexpected connection failure: \(error)")
        }

        let realm = try! Realm(configuration: config)
        self.waitForUploads(for: realm)
    }

    func testSecureConnectionToLocalhostWithIncorrectPinnedCertificate() {
        let user = try! synchronouslyLogInUser(for: basicCredentials(), server: authURL)
        let certURL = URL(string: #file)!
            .deletingLastPathComponent()
            .appendingPathComponent("certificates")
            .appendingPathComponent("localhost-other.cer")
        let config = user.configuration(realmURL: URL(string: "realms://localhost:9443/~/default"),
                                        serverValidationPolicy: .pinCertificate(path: certURL))

        let ex = expectation(description: "Waiting for error handler to be called")
        SyncManager.shared.errorHandler = { (error, session) in
            ex.fulfill()
        }

        _ = try! Realm(configuration: config)
        self.waitForExpectations(timeout: 4.0)
    }

    private func realmURLForFile(_ fileName: String) -> URL {
        let testDir = RLMRealmPathForFile("realm-object-server")
        let directory = URL(fileURLWithPath: testDir, isDirectory: true)
        return directory.appendingPathComponent(fileName, isDirectory: false)
    }
}
