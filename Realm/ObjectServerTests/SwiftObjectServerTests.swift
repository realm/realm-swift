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

class SwiftPerson: Object {
    @objc dynamic var _id: ObjectId = ObjectId.generate()
    @objc dynamic var firstName: String = ""
    @objc dynamic var lastName: String = ""

    convenience init(firstName: String, lastName: String) {
        self.init()
        self.firstName = firstName
        self.lastName = lastName
    }

    override class func primaryKey() -> String? {
        "_id"
    }
}

class SwiftObjectServerTests: SwiftSyncTestCase {
    /// It should be possible to successfully open a Realm configured for sync.
    func testBasicSwiftSync() {
        do {
            let user = try synchronouslyLogInUser(for: basicCredentials())
            let realm = try synchronouslyOpenRealm(partitionValue: "foo", user: user)
            XCTAssert(realm.isEmpty, "Freshly synced Realm was not empty...")
        } catch {
            XCTFail("Got an error: \(error)")
        }
    }


    /// If client B adds objects to a Realm, client A should see those new objects.
    func testSwiftAddObjects() {
        do {
            let user = try synchronouslyLogInUser(for: basicCredentials())
            let realm = try synchronouslyOpenRealm(partitionValue: "foo", user: user)
            if !isParent {
                waitForDownloads(for: realm)
                checkCount(expected: 0, realm, SwiftPerson.self)
                executeChild()
                waitForDownloads(for: realm)
                checkCount(expected: 3, realm, SwiftPerson.self)
            } else {
                // Add objects
                try realm.write {
                    realm.add(SwiftPerson(firstName: "Ringo", lastName: "Starr"))
                    realm.add(SwiftPerson(firstName: "John", lastName: "Lennon"))
                    realm.add(SwiftPerson(firstName: "Paul", lastName: "McCartney"))
                }
                waitForUploads(for: realm)
                checkCount(expected: 3, realm, SwiftPerson.self)
            }
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    /// If client B removes objects from a Realm, client A should see those changes.
    func testSwiftDeleteObjects() {
        do {
            let user = try synchronouslyLogInUser(for: basicCredentials())
            let realm = try synchronouslyOpenRealm(partitionValue: "realm_id", user: user)
            if isParent {
                try realm.write {
                    realm.add(SwiftPerson(firstName: "Ringo", lastName: "Starr"))
                    realm.add(SwiftPerson(firstName: "John", lastName: "Lennon"))
                    realm.add(SwiftPerson(firstName: "Paul", lastName: "McCartney"))
                }
                waitForUploads(for: realm)
                checkCount(expected: 3, realm, SwiftPerson.self)
                executeChild()
            } else {
                checkCount(expected: 0, realm, SwiftPerson.self)
                waitForDownloads(for: realm)
                checkCount(expected: 3, realm, SwiftPerson.self)
                try realm.write {
                    realm.deleteAll()
                }
                waitForUploads(for: realm)
                checkCount(expected: 0, realm, SwiftPerson.self)
            }
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    /// A client should be able to open multiple Realms and add objects to each of them.
    func testMultipleRealmsAddObjects() {
        let partitionValueA = "foo";
        let partitionValueB = "bar";
        let partitionValueC = "baz";

        do {
            let user = try synchronouslyLogInUser(for: basicCredentials())

            let realmA = try Realm(configuration: user.configuration(partitionValue: partitionValueA))
            let realmB = try Realm(configuration: user.configuration(partitionValue: partitionValueB))
            let realmC = try Realm(configuration: user.configuration(partitionValue: partitionValueC))

            if (self.isParent) {
                waitForDownloads(for: realmA)
                waitForDownloads(for: realmB)
                waitForDownloads(for: realmC)

                checkCount(expected: 0, realmA, SwiftPerson.self)
                checkCount(expected: 0, realmB, SwiftPerson.self)
                checkCount(expected: 0, realmC, SwiftPerson.self)
                executeChild()

                waitForDownloads(for: realmA)
                waitForDownloads(for: realmB)
                waitForDownloads(for: realmC)

                checkCount(expected: 3, realmA, SwiftPerson.self)
                checkCount(expected: 2, realmB, SwiftPerson.self)
                checkCount(expected: 5, realmC, SwiftPerson.self)

                XCTAssertEqual(realmA.objects(SwiftPerson.self).filter("firstName == %@", "Ringo").count,
                               1)
                XCTAssertEqual(realmB.objects(SwiftPerson.self).filter("firstName == %@", "Ringo").count,
                               0)
            } else {
                // Add objects.
                try realmA.write {
                    realmA.add(SwiftPerson(firstName: "Ringo", lastName: "Starr"))
                    realmA.add(SwiftPerson(firstName: "John", lastName: "Lennon"))
                    realmA.add(SwiftPerson(firstName: "Paul", lastName: "McCartney"))
                }
                try realmB.write {
                    realmB.add(SwiftPerson(firstName: "John", lastName: "Lennon"))
                    realmB.add(SwiftPerson(firstName: "Paul", lastName: "McCartney"))
                }
                try realmC.write {
                    realmC.add(SwiftPerson(firstName: "Ringo", lastName: "Starr"))
                    realmC.add(SwiftPerson(firstName: "John", lastName: "Lennon"))
                    realmC.add(SwiftPerson(firstName: "Paul", lastName: "McCartney"))
                    realmC.add(SwiftPerson(firstName: "George", lastName: "Harrison"))
                    realmC.add(SwiftPerson(firstName: "Pete", lastName: "Best"))
                }

                waitForUploads(for: realmA)
                waitForUploads(for: realmB)
                waitForUploads(for: realmC)

                checkCount(expected: 3, realmA, SwiftPerson.self)
                checkCount(expected: 2, realmB, SwiftPerson.self)
                checkCount(expected: 5, realmC, SwiftPerson.self)
            }
        } catch {
            XCTFail()
        }
    }

    func testConnectionState() {
        do {
            let user = try synchronouslyLogInUser(for: basicCredentials())
            let realm = try synchronouslyOpenRealm(partitionValue: "foo", user: user)
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
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }
    
    // MARK: - Client reset

    func testClientReset() {
        do {
            let user = try synchronouslyLogInUser(for: basicCredentials())
            let realm = try synchronouslyOpenRealm(partitionValue: "foo", user: user)

            var theError: SyncError?
            let ex = expectation(description: "Waiting for error handler to be called...")
            app().sharedManager().errorHandler = { (error, session) in
                if let error = error as? SyncError {
                    theError = error
                } else {
                    XCTFail("Error \(error) was not a sync error. Something is wrong.")
                }
                ex.fulfill()
            }
            user.simulateClientResetError(forSession: "foo")
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
            let user = try synchronouslyLogInUser(for: basicCredentials())
            var theError: SyncError?

            try autoreleasepool {
                let realm = try synchronouslyOpenRealm(partitionValue: "foo", user: user)
                let ex = expectation(description: "Waiting for error handler to be called...")
                 app().sharedManager().errorHandler = { (error, session) in
                    if let error = error as? SyncError {
                        theError = error
                    } else {
                        XCTFail("Error \(error) was not a sync error. Something is wrong.")
                    }
                    ex.fulfill()
                }
                user.simulateClientResetError(forSession: "foo")
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

    func populateRealm(user: SyncUser, partitionKey: String) {
        do {

            let user = try synchronouslyLogInUser(for: basicCredentials())
            let realm = try synchronouslyOpenRealm(partitionValue: "foo", user: user)
            try! realm.write {
                for _ in 0..<bigObjectCount {
                    realm.add(SwiftPerson())
                }
            }
            waitForUploads(for: realm)
            checkCount(expected: bigObjectCount, realm, SwiftPerson.self)
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    // FIXME: Dependancy on Stitch deployment
    #if false
    func testStreamingDownloadNotifier() {
        do {
            let user = try synchronouslyLogInUser(for: basicCredentials())
            if !isParent {
                populateRealm(user: user, partitionKey: "realm_id")
                //return
            }

            var callCount = 0
            var transferred = 0
            var transferrable = 0
            let realm = try synchronouslyOpenRealm(partitionValue: "realm_id", user: user)

            let session = realm.syncSession
            XCTAssertNotNil(session)
            let ex = expectation(description: "streaming-downloads-expectation")
            var hasBeenFulfilled = false
            
            let token = session!.addProgressNotification(for: .download, mode: .forCurrentlyOutstandingWork) { p in
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

            waitForExpectations(timeout: 60.0, handler: nil)
            token!.invalidate()
            XCTAssert(callCount > 1)
            XCTAssert(transferred >= transferrable)
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }
    #endif
    
    func testStreamingUploadNotifier() {
        do {
            var transferred = 0
            var transferrable = 0
            let user = try synchronouslyLogInUser(for: basicCredentials())
            let realm = try synchronouslyOpenRealm(partitionValue: "foo", user: user)
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
                    realm.add(SwiftPerson())
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
        do {
            let user = try synchronouslyLogInUser(for: basicCredentials())
            if !isParent {
                populateRealm(user: user, partitionKey: "foo")
                return
            }
            
            // Wait for the child process to upload everything.
            executeChild()
            
            let ex = expectation(description: "download-realm")
            let config = user.configuration(partitionValue: "foo")
            let pathOnDisk = ObjectiveCSupport.convert(object: config).pathOnDisk
            XCTAssertFalse(FileManager.default.fileExists(atPath: pathOnDisk))
            Realm.asyncOpen(configuration: config) { realm, error in
                XCTAssertNil(error)
                self.checkCount(expected: self.bigObjectCount, realm!, SwiftPerson.self)
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
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }
    
    func testDownloadRealmToCustomPath() {
        do {
            let user = try synchronouslyLogInUser(for: basicCredentials())
            if !isParent {
                populateRealm(user: user, partitionKey: "foo")
                return
            }
            
            // Wait for the child process to upload everything.
            executeChild()
            
            let ex = expectation(description: "download-realm")
            let customFileURL = realmURLForFile("copy")
            var config = user.configuration(partitionValue: "foo")
            config.fileURL = customFileURL
            let pathOnDisk = ObjectiveCSupport.convert(object: config).pathOnDisk
            XCTAssertEqual(pathOnDisk, customFileURL.path)
            XCTAssertFalse(FileManager.default.fileExists(atPath: pathOnDisk))
            Realm.asyncOpen(configuration: config) { realm, error in
                XCTAssertNil(error)
                self.checkCount(expected: self.bigObjectCount, realm!, SwiftPerson.self)
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
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    func testCancelDownloadRealm() {
        do {
            let user = try synchronouslyLogInUser(for: basicCredentials())
            if !isParent {
                populateRealm(user: user, partitionKey: "foo")
                return
            }
            
            // Wait for the child process to upload everything.
            executeChild()
            
            // Use a serial queue for asyncOpen to ensure that the first one adds
            // the completion block before the second one cancels it
            RLMSetAsyncOpenQueue(DispatchQueue(label: "io.realm.asyncOpen"))
            
            let ex = expectation(description: "async open")
            let config = user.configuration(partitionValue: "foo")
            Realm.asyncOpen(configuration: config) { _, error in
                XCTAssertNotNil(error)
                ex.fulfill()
            }
            let task = Realm.asyncOpen(configuration: config) { _, _ in
                XCTFail("Cancelled completion handler was called")
            }
            task.cancel()
            waitForExpectations(timeout: 10.0, handler: nil)
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }
    
    // FIXME: Dependancy on Stitch deployment
    #if false
    func testAsyncOpenProgress() {
        app().sharedManager().logLevel = .all
        do {
            let user = try synchronouslyLogInUser(for: basicCredentials())
            if !isParent {
                populateRealm(user: user, partitionKey: "realm_id")
                return
            }
            
            // Wait for the child process to upload everything.
            executeChild()
            let ex1 = expectation(description: "async open")
            let ex2 = expectation(description: "download progress")
            let config = user.configuration(partitionValue: "realm_id")
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
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }
    
    func testAsyncOpenTimeout() {
        let syncTimeoutOptions = SyncTimeoutOptions()
        syncTimeoutOptions.connectTimeout = 3000
        app().sharedManager().timeoutOptions = syncTimeoutOptions
        
        // The server proxy adds a 2 second delay, so a 3 second timeout should succeed
        autoreleasepool {
            do {
                let user = try synchronouslyLogInUser(for: basicCredentials())
                let config = user.configuration(partitionValue: "realm_id")
                let ex = expectation(description: "async open")
                Realm.asyncOpen(configuration: config) { _, error in
                    XCTAssertNil(error)
                    ex.fulfill()
                }
                waitForExpectations(timeout: 10.0, handler: nil)
                try synchronouslyLogOutUser(user)
            } catch {
                XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
            }
        }
        
        self.resetSyncManager()
        self.setupSyncManager()
        
        // and a 1 second timeout should fail
        autoreleasepool {
            do {
                let user = try synchronouslyLogInUser(for: basicCredentials())
                let config = user.configuration(partitionValue: "realm_id")
                
                syncTimeoutOptions.connectTimeout = 1000
                app().sharedManager().timeoutOptions = syncTimeoutOptions
                
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
                try synchronouslyLogOutUser(user)
            } catch {
                XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
            }
        }
    }
    
    #endif
    
    // MARK: - Authentication

    func testInvalidCredentials() {
        do {
            let username = "testInvalidCredentialsUsername"
            let credentials = basicCredentials()
            let user = try synchronouslyLogInUser(for: credentials)
            XCTAssertEqual(user.state, .loggedIn)
            
            let credentials2 = AppCredentials(username: username, password: "NOT_A_VALID_PASSWORD")
            let ex = expectation(description: "Should log in the user properly")

            self.app().login(withCredential: credentials2, completion: { user2, error in
                XCTAssertNil(user2)
                XCTAssertNotNil(error)
                ex.fulfill()
            })
            
            waitForExpectations(timeout: 10, handler: nil)
            
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    // MARK: - User-specific functionality

    func testUserExpirationCallback() {
        do {
            let user = try synchronouslyLogInUser(for: basicCredentials())

            // Set a callback on the user
            var blockCalled = false
            let ex = expectation(description: "Error callback should fire upon receiving an error")
            app().sharedManager().errorHandler = { (error, _) in
                XCTAssertNotNil(error)
                blockCalled = true
                ex.fulfill()
            }
                        
            // Screw up the token on the user.
            manuallySetAccessToken(for: user, value: badAccessToken())

            // Try to open a Realm with the user; this will cause our errorHandler block defined above to be fired.
            XCTAssertFalse(blockCalled)
            _ = try immediatelyOpenRealm(partitionValue: "realm_id", user: user)

            waitForExpectations(timeout: 10.0, handler: nil)
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    private func realmURLForFile(_ fileName: String) -> URL {
        let testDir = RLMRealmPathForFile("realm-object-server")
        let directory = URL(fileURLWithPath: testDir, isDirectory: true)
        return directory.appendingPathComponent(fileName, isDirectory: false)
    }

    // MARK: - RealmApp tests

    let appName = "translate-utwuv"

    private func realmAppConfig() -> AppConfiguration {

        return AppConfiguration(baseURL: "http://localhost:9090",
                                transport: nil,
                                localAppName: "auth-integration-tests",
                                localAppVersion: "20180301")
    }

    func testRealmAppInit() {
        let appWithNoConfig = RealmApp(appName, configuration: nil)
        XCTAssertEqual(appWithNoConfig.allUsers().count, 0)

        let appWithConfig = RealmApp(appName, configuration: realmAppConfig())
        XCTAssertEqual(appWithConfig.allUsers().count, 0)
    }

    func testRealmAppLogin() {

        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)

        let registerUserEx = expectation(description: "Register user")

        app().usernamePasswordProviderClient().registerEmail(email, password: password) { (error) in
            XCTAssertNil(error)
            registerUserEx.fulfill()
        }
        wait(for: [registerUserEx], timeout: 4.0)

        let loginEx = expectation(description: "Login user")
        var syncUser: SyncUser?

        app().login(withCredential: AppCredentials(username: email, password: password)) { (user, error) in
            XCTAssertNil(error)
            syncUser = user
            loginEx.fulfill()
        }

        wait(for: [loginEx], timeout: 4.0)

        XCTAssertEqual(syncUser?.identity, app().currentUser()?.identity)
        XCTAssertEqual(app().allUsers().count, 1)
    }

    func testRealmAppSwitchAndRemove() {

        let email1 = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password1 = randomString(10)
        let email2 = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password2 = randomString(10)

        let registerUser1Ex = expectation(description: "Register user 1")
        let registerUser2Ex = expectation(description: "Register user 2")

        app().usernamePasswordProviderClient().registerEmail(email1, password: password1) { (error) in
            XCTAssertNil(error)
            registerUser1Ex.fulfill()
        }

        app().usernamePasswordProviderClient().registerEmail(email2, password: password2) { (error) in
            XCTAssertNil(error)
            registerUser2Ex.fulfill()
        }

        wait(for: [registerUser1Ex, registerUser2Ex], timeout: 4.0)

        let login1Ex = expectation(description: "Login user 1")
        let login2Ex = expectation(description: "Login user 2")

        var syncUser1: SyncUser?
        var syncUser2: SyncUser?

        app().login(withCredential: AppCredentials(username: email1, password: password1)) { (user, error) in
            XCTAssertNil(error)
            syncUser1 = user
            login1Ex.fulfill()
        }

        wait(for: [login1Ex], timeout: 4.0)

        app().login(withCredential: AppCredentials(username: email2, password: password2)) { (user, error) in
            XCTAssertNil(error)
            syncUser2 = user
            login2Ex.fulfill()
        }

        wait(for: [login2Ex], timeout: 4.0)

        XCTAssertEqual(app().allUsers().count, 2)

        XCTAssertEqual(syncUser2!.identity, app().currentUser()!.identity)

        app().switch(to: syncUser1!)
        XCTAssertTrue(syncUser1!.identity == app().currentUser()?.identity)

        let removeEx = expectation(description: "Remove user 1")

        app().remove(syncUser1!) { (error) in
            XCTAssertNil(error)
            removeEx.fulfill()
        }

        wait(for: [removeEx], timeout: 4.0)

        XCTAssertEqual(syncUser2!.identity, app().currentUser()!.identity)
        XCTAssertEqual(app().allUsers().count, 1)
    }

    func testRealmAppLinkUser() {

        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)

        let registerUserEx = expectation(description: "Register user")

        app().usernamePasswordProviderClient().registerEmail(email, password: password) { (error) in
            XCTAssertNil(error)
            registerUserEx.fulfill()
        }
        wait(for: [registerUserEx], timeout: 4.0)

        let loginEx = expectation(description: "Login user")
        var syncUser: SyncUser?

        let credentials = AppCredentials(username: email, password: password)

        app().login(withCredential: AppCredentials.anonymous()) { (user, error) in
            XCTAssertNil(error)
            syncUser = user
            loginEx.fulfill()
        }

        wait(for: [loginEx], timeout: 4.0)

        let linkEx = expectation(description: "Link user")

        app().linkUser(syncUser!, credentials: credentials) { (user, error) in
            XCTAssertNil(error)
            syncUser = user
            linkEx.fulfill()
        }

        wait(for: [linkEx], timeout: 4.0)

        XCTAssertEqual(syncUser?.identity,app().currentUser()?.identity)
        XCTAssertEqual(syncUser?.identities().count, 2)
    }

    // MARK: - Provider Clients

    func testUsernamePasswordProviderClient() {

        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)

        let registerUserEx = expectation(description: "Register user")

        app().usernamePasswordProviderClient().registerEmail(email, password: password) { (error) in
            XCTAssertNil(error)
            registerUserEx.fulfill()
        }
        wait(for: [registerUserEx], timeout: 4.0)

        let confirmUserEx = expectation(description: "Confirm user")

        app().usernamePasswordProviderClient().confirmUser("atoken", tokenId: "atokenid") { (error) in
            XCTAssertNotNil(error)
            confirmUserEx.fulfill()
        }
        wait(for: [confirmUserEx], timeout: 4.0)

        let resendEmailEx = expectation(description: "Resend email confirmation")

        app().usernamePasswordProviderClient().resendConfirmationEmail("atoken") { (error) in
            XCTAssertNotNil(error)
            resendEmailEx.fulfill()
        }
        wait(for: [resendEmailEx], timeout: 4.0)

        let resendResetPasswordEx = expectation(description: "Resend reset password email")

        app().usernamePasswordProviderClient().sendResetPasswordEmail("atoken") { (error) in
            XCTAssertNotNil(error)
            resendResetPasswordEx.fulfill()
        }
        wait(for: [resendResetPasswordEx], timeout: 4.0)

        let resetPasswordEx = expectation(description: "Reset password email")

        app().usernamePasswordProviderClient().resetPassword(to: "password", token: "atoken", tokenId: "tokenId") { (error) in
            XCTAssertNotNil(error)
            resetPasswordEx.fulfill()
        }
        wait(for: [resetPasswordEx], timeout: 4.0)

//        let callResetFunctionEx = expectation(description: "Reset password function")
        //FIXME: Needs BSON
//        app().usernamePasswordProviderClient().callResetPasswordFunction(email, password: password, args: "") { (error) in
//            XCTAssertNotNil(error)
//            callResetFunctionEx.fulfill()
//        }
//        wait(for: [callResetFunctionEx], timeout: 4.0)
    }

    func testUserAPIKeyProviderClient() {

        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)

        let registerUserEx = expectation(description: "Register user")

        app().usernamePasswordProviderClient().registerEmail(email, password: password) { (error) in
            XCTAssertNil(error)
            registerUserEx.fulfill()
        }
        wait(for: [registerUserEx], timeout: 4.0)

        let loginEx = expectation(description: "Login user")
        let credentials = AppCredentials(username: email, password: password)

        app().login(withCredential: credentials) { (_, error) in
            XCTAssertNil(error)
            loginEx.fulfill()
        }

        wait(for: [loginEx], timeout: 4.0)

        let createAPIKeyEx = expectation(description: "Create user api key")

        var apiKey: UserAPIKey?
        app().userAPIKeyProviderClient().createApiKey(withName: "my-api-key") { (key, error) in
            XCTAssertNotNil(key)
            XCTAssertNil(error)
            apiKey = key
            createAPIKeyEx.fulfill()
        }
        wait(for: [createAPIKeyEx], timeout: 4.0)

        let fetchAPIKeyEx = expectation(description: "Fetch user api key")
        app().userAPIKeyProviderClient().fetchApiKey(apiKey!.objectId) { (key, error) in
            XCTAssertNotNil(key)
            XCTAssertNil(error)
            fetchAPIKeyEx.fulfill()
        }
        wait(for: [fetchAPIKeyEx], timeout: 4.0)

        let fetchAPIKeysEx = expectation(description: "Fetch user api keys")
        app().userAPIKeyProviderClient().fetchApiKeys(completion: { (keys, error) in
            XCTAssertNotNil(keys)
            XCTAssertEqual(keys!.count, 1)
            XCTAssertNil(error)
            fetchAPIKeysEx.fulfill()
        })
        wait(for: [fetchAPIKeysEx], timeout: 4.0)

        let disableKeyEx = expectation(description: "Disable API key")
        app().userAPIKeyProviderClient().disableApiKey(apiKey!.objectId) { (error) in
            XCTAssertNil(error)
            disableKeyEx.fulfill()
        }
        wait(for: [disableKeyEx], timeout: 4.0)

        let enableKeyEx = expectation(description: "Enable API key")
        app().userAPIKeyProviderClient().enableApiKey(apiKey!.objectId) { (error) in
            XCTAssertNil(error)
            enableKeyEx.fulfill()
        }
        wait(for: [enableKeyEx], timeout: 4.0)

        let deleteKeyEx = expectation(description: "Delete API key")
        app().userAPIKeyProviderClient().deleteApiKey(apiKey!.objectId) { (error) in
            XCTAssertNil(error)
            deleteKeyEx.fulfill()
        }
        wait(for: [deleteKeyEx], timeout: 4.0)
    }
}
