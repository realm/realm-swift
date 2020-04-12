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
            // FIXME: [realmapp] add logout
            // user.logOut()
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

    // MARK: - Authentication

    func testInvalidCredentials() {
        do {
            let username = "testInvalidCredentialsUsername"
            let credentials = AppCredentials.usernamePassword(username: username,
                                                               password: "THIS_IS_A_PASSWORD")
            _ = try synchronouslyLogInUser(for: credentials, server: authURL)
            // Now log in the same user, but with a bad password.
            let ex = expectation(description: "wait for user login")
            let credentials2 = AppCredentials.usernamePassword(username: username, password: "NOT_A_VALID_PASSWORD")

            // FIXME: [realmapp] This should call the new login method with invalid credentials
            fatalError("test not implemented")
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
    
    //MARK: - RealmApp tests
    
    private func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    let appName = "translate-utwuv"
    
    private func realmAppConfig() -> AppConfiguration {

        return AppConfiguration.init(baseURL: "http://localhost:9090",
                                     transport: nil,
                                     localAppName: "auth-integration-tests",
                                     localAppVersion: "20180301")
    }
    
    func testRealmAppInit() {
        let appWithNoConfig = RealmApp(appName, nil)
        XCTAssertTrue(appWithNoConfig.allUsers.capacity == 0)
        
        let appWithConfig = RealmApp(appName, realmAppConfig())
        XCTAssertTrue(appWithConfig.allUsers.capacity == 0)
    }
    
    func testRealmAppLogin() {
        let app = RealmApp(appName, nil)
        
        let email = "realm_tests_do_autoverify\(randomString(length: 7))@\(randomString(length: 7)).com"
        let password = randomString(length: 10)
        
        let registerUserEx = expectation(description: "Register user")
        
        app.usernamePasswordProviderClient().register(withEmail: email, password) { (error) in
            XCTAssertTrue(error == nil)
            registerUserEx.fulfill()
        }
        self.wait(for: [registerUserEx], timeout: 4.0)
        
        let loginEx = expectation(description: "Login user")
        var syncUser: SyncUser?
        
        app.loginWithCredential(AppCredentials.usernamePassword(username: email, password: password)) { (user, error) in
            XCTAssertTrue(error == nil)
            syncUser = user
            loginEx.fulfill()
        }

        self.wait(for: [loginEx], timeout: 4.0)
        
        XCTAssertTrue(syncUser?.identity == app.currentUser?.identity)
        XCTAssertTrue(app.allUsers.count == 1)
    }
    
    func testRealmAppSwitchAndRemove() {
        let app = RealmApp(appName, nil)
        
        let email1 = "realm_tests_do_autoverify\(randomString(length: 7))@\(randomString(length: 7)).com"
        let password1 = randomString(length: 10)
        let email2 = "realm_tests_do_autoverify\(randomString(length: 7))@\(randomString(length: 7)).com"
        let password2 = randomString(length: 10)
        
        let registerUser1Ex = expectation(description: "Register user 1")
        let registerUser2Ex = expectation(description: "Register user 2")

        app.usernamePasswordProviderClient().register(withEmail: email1, password1) { (error) in
            XCTAssertTrue(error == nil)
            registerUser1Ex.fulfill()
        }
        
        app.usernamePasswordProviderClient().register(withEmail: email2, password2) { (error) in
            XCTAssertTrue(error == nil)
            registerUser2Ex.fulfill()
        }
        
        self.wait(for: [registerUser1Ex, registerUser2Ex], timeout: 4.0)
        
        let login1Ex = expectation(description: "Login user 1")
        let login2Ex = expectation(description: "Login user 2")

        var syncUser1: SyncUser?
        var syncUser2: SyncUser?

        app.loginWithCredential(AppCredentials.usernamePassword(username: email1, password: password1)) { (user, error) in
            XCTAssertTrue(error == nil)
            syncUser1 = user
            login1Ex.fulfill()
        }
        
        self.wait(for: [login1Ex], timeout: 4.0)

        app.loginWithCredential(AppCredentials.usernamePassword(username: email2, password: password2)) { (user, error) in
            XCTAssertTrue(error == nil)
            syncUser2 = user
            login2Ex.fulfill()
        }

        self.wait(for: [login2Ex], timeout: 4.0)
        
        XCTAssertTrue(app.allUsers.count == 2)
        
        XCTAssertTrue(syncUser2!.identity == app.currentUser!.identity)

        app.switchToUser(syncUser1!)
        XCTAssertTrue(syncUser1!.identity == app.currentUser!.identity)
        
        let removeEx = expectation(description: "Remove user 1")

        app.removeUser(syncUser1!) { (error) in
            XCTAssertTrue(error == nil)
            removeEx.fulfill()
        }
        
        self.wait(for: [removeEx], timeout: 4.0)

        XCTAssertTrue(syncUser2!.identity == app.currentUser!.identity)
        XCTAssertTrue(app.allUsers.count == 1)

    }
    
    func testRealmAppLinkUser() {
        let app = RealmApp(appName, nil)
        
        let email = "realm_tests_do_autoverify\(randomString(length: 7))@\(randomString(length: 7)).com"
        let password = randomString(length: 10)
        
        let registerUserEx = expectation(description: "Register user")
        
        app.usernamePasswordProviderClient().register(withEmail: email, password) { (error) in
            XCTAssertTrue(error == nil)
            registerUserEx.fulfill()
        }
        self.wait(for: [registerUserEx], timeout: 4.0)
        
        let loginEx = expectation(description: "Login user")
        var syncUser: SyncUser?
        
        let credentials = AppCredentials.usernamePassword(username: email, password: password)
        
        app.loginWithCredential(AppCredentials.anonymous()) { (user, error) in
            XCTAssertTrue(error == nil)
            syncUser = user
            loginEx.fulfill()
        }
        
        self.wait(for: [loginEx], timeout: 4.0)

        let linkEx = expectation(description: "Link user")

        app.linkUser(syncUser!, credentials) { (user, error) in
            XCTAssertTrue(error == nil)
            syncUser = user
            linkEx.fulfill()
        }
        
        self.wait(for: [linkEx], timeout: 4.0)

        XCTAssertTrue(syncUser?.identity == app.currentUser?.identity)
        XCTAssertTrue(syncUser?.identities().count == 2)

    }
    
    //MARK: - Provider Clients
    
    func testUsernamePasswordProviderClient() {
        let app = RealmApp(appName, nil)
        
        let email = "realm_tests_do_autoverify\(randomString(length: 7))@\(randomString(length: 7)).com"
        let password = randomString(length: 10)
        
        let registerUserEx = expectation(description: "Register user")
        
        app.usernamePasswordProviderClient().register(withEmail: email, password) { (error) in
            XCTAssertTrue(error == nil)
            registerUserEx.fulfill()
        }
        self.wait(for: [registerUserEx], timeout: 4.0)
        
        let confirmUserEx = expectation(description: "Confirm user")

        app.usernamePasswordProviderClient().confirm(withToken: "atoken", "atokenid") { (error) in
            XCTAssertNotNil(error)
            confirmUserEx.fulfill()
        }
        self.wait(for: [confirmUserEx], timeout: 4.0)
        
        let resendEmailEx = expectation(description: "Resend email confirmation")

        app.usernamePasswordProviderClient().resendConfirmationEmail("atoken") { (error) in
            XCTAssertNotNil(error)
            resendEmailEx.fulfill()
        }
        self.wait(for: [resendEmailEx], timeout: 4.0)
        
        let resendResetPasswordEx = expectation(description: "Resend reset password email")

        app.usernamePasswordProviderClient().sendResetPasswordEmail("atoken") { (error) in
            XCTAssertNotNil(error)
            resendResetPasswordEx.fulfill()
        }
        self.wait(for: [resendResetPasswordEx], timeout: 4.0)

        let resetPasswordEx = expectation(description: "Reset password email")

        app.usernamePasswordProviderClient().resetPassword(to: "password", "atoken", "tokenId") { (error) in
            XCTAssertNotNil(error)
            resetPasswordEx.fulfill()
        }
        self.wait(for: [resetPasswordEx], timeout: 4.0)
        
        let callResetFunctionEx = expectation(description: "Reset password function")

        app.usernamePasswordProviderClient().callResetPasswordFunction(email, password: password, args: "") { (error) in
            XCTAssertNotNil(error)
            callResetFunctionEx.fulfill()
        }
        self.wait(for: [callResetFunctionEx], timeout: 4.0)
    }
    
    func testUserAPIKeyProviderClient() {
        let app = RealmApp(appName, nil)
        
        let email = "realm_tests_do_autoverify\(randomString(length: 7))@\(randomString(length: 7)).com"
        let password = randomString(length: 10)
        
        let registerUserEx = expectation(description: "Register user")
        
        app.usernamePasswordProviderClient().register(withEmail: email, password) { (error) in
            XCTAssertTrue(error == nil)
            registerUserEx.fulfill()
        }
        self.wait(for: [registerUserEx], timeout: 4.0)
        
        let loginEx = expectation(description: "Login user")        
        let credentials = AppCredentials.usernamePassword(username: email, password: password)
                
        app.loginWithCredential(credentials) { (user, error) in
            XCTAssertTrue(error == nil)
            loginEx.fulfill()
        }
        
        self.wait(for: [loginEx], timeout: 4.0)
        
        let createAPIKeyEx = expectation(description: "Create user api key")

        var apiKey:UserAPIKey?
        app.userAPIKeyProviderClient().createAPIKey("my-api-key") { (key, error) in
            XCTAssertNotNil(key)
            XCTAssertNil(error)
            apiKey = key
            createAPIKeyEx.fulfill()
        }
        self.wait(for: [createAPIKeyEx], timeout: 4.0)

        let fetchAPIKeyEx = expectation(description: "Fetch user api key")
        app.userAPIKeyProviderClient().fetchAPIKey(apiKey!) { (key, error) in
            XCTAssertNotNil(key)
            XCTAssertNil(error)
            fetchAPIKeyEx.fulfill()
        }
        self.wait(for: [fetchAPIKeyEx], timeout: 4.0)

        let fetchAPIKeysEx = expectation(description: "Fetch user api keys")
        app.userAPIKeyProviderClient().fetchAPIKeys() { (keys, error) in
            XCTAssertNotNil(keys)
            XCTAssert(keys!.count == 1)
            XCTAssertNil(error)
            fetchAPIKeysEx.fulfill()
        }
        self.wait(for: [fetchAPIKeysEx], timeout: 4.0)
        
        let disableKeyEx = expectation(description: "Disable API key")
        app.userAPIKeyProviderClient().disable(apiKey!) { (error) in
            XCTAssertNil(error)
            disableKeyEx.fulfill()
        }
        self.wait(for: [disableKeyEx], timeout: 4.0)
        
        let enableKeyEx = expectation(description: "Enable API key")
        app.userAPIKeyProviderClient().enable(apiKey!) { (error) in
            XCTAssertNil(error)
            enableKeyEx.fulfill()
        }
        self.wait(for: [enableKeyEx], timeout: 4.0)
        
        let deleteKeyEx = expectation(description: "Delete API key")
        app.userAPIKeyProviderClient().delete(apiKey!) { (error) in
            XCTAssertNil(error)
            deleteKeyEx.fulfill()
        }
        self.wait(for: [deleteKeyEx], timeout: 4.0)
    }
    
}
