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

#if os(macOS)

import Combine
import Realm
import Realm.Private
@_spi(RealmSwiftExperimental) import RealmSwift
import XCTest

#if canImport(RealmTestSupport)
import RealmSwiftSyncTestSupport
import RealmSyncTestSupport
import RealmTestSupport
import RealmSwiftTestSupport
#endif

func assertAppError(_ error: AppError, _ code: AppError.Code, _ message: String,
                    line: UInt = #line, file: StaticString = #filePath) {
    XCTAssertEqual(error.code, code, file: file, line: line)
    XCTAssertEqual(error.localizedDescription, message, file: file, line: line)
}

func assertSyncError(_ error: Error, _ code: SyncError.Code, _ message: String,
                     line: UInt = #line, file: StaticString = #filePath) {
    let e = error as NSError
    XCTAssertEqual(e.domain, RLMSyncErrorDomain, file: file, line: line)
    XCTAssertEqual(e.code, code.rawValue, file: file, line: line)
    XCTAssertEqual(e.localizedDescription, message, file: file, line: line)
}

@available(macOS 13.0, *)
@objc(SwiftObjectServerTests)
class SwiftObjectServerTests: SwiftSyncTestCase {
    override var objectTypes: [ObjectBase.Type] {
        [
            SwiftCustomColumnObject.self,
            SwiftPerson.self,
            SwiftTypesSyncObject.self,
            SwiftHugeSyncObject.self,
            SwiftIntPrimaryKeyObject.self,
            SwiftUUIDPrimaryKeyObject.self,
            SwiftStringPrimaryKeyObject.self,
            SwiftMissingObject.self,
            SwiftAnyRealmValueObject.self,
        ]
    }

    func testUpdateBaseUrl() {
        let app = App(id: appId)
        XCTAssertEqual(app.baseURL, "https://services.cloud.mongodb.com")

        app.updateBaseUrl(to: "http://localhost:9090").await(self)
        XCTAssertEqual(app.baseURL, "http://localhost:9090")

        app.updateBaseUrl(to: "http://127.0.0.1:9090").await(self)
        XCTAssertEqual(app.baseURL, "http://127.0.0.1:9090")

        app.updateBaseUrl(to: nil).awaitFailure(self)
        XCTAssertEqual(app.baseURL, "http://127.0.0.1:9090")
    }

    @MainActor
    func testBasicSwiftSync() throws {
        XCTAssert(try openRealm().isEmpty, "Freshly synced Realm was not empty...")
    }

    @MainActor
    func testSwiftAddObjects() throws {
        let realm = try openRealm()
        checkCount(expected: 0, realm, SwiftPerson.self)
        checkCount(expected: 0, realm, SwiftTypesSyncObject.self)

        try write { realm in
            realm.add(SwiftPerson(firstName: "Ringo", lastName: "Starr"))
            realm.add(SwiftPerson(firstName: "John", lastName: "Lennon"))
            realm.add(SwiftPerson(firstName: "Paul", lastName: "McCartney"))
            realm.add(SwiftTypesSyncObject(person: SwiftPerson(firstName: "George", lastName: "Harrison")))
        }

        waitForDownloads(for: realm)
        checkCount(expected: 4, realm, SwiftPerson.self)
        checkCount(expected: 1, realm, SwiftTypesSyncObject.self)

        let obj = realm.objects(SwiftTypesSyncObject.self).first!
        XCTAssertEqual(obj.boolCol, true)
        XCTAssertEqual(obj.intCol, 1)
        XCTAssertEqual(obj.doubleCol, 1.1)
        XCTAssertEqual(obj.stringCol, "string")
        XCTAssertEqual(obj.binaryCol, Data("string".utf8))
        XCTAssertEqual(obj.decimalCol, Decimal128(1))
        XCTAssertEqual(obj.dateCol, Date(timeIntervalSince1970: -1))
        XCTAssertEqual(obj.longCol, Int64(1))
        XCTAssertEqual(obj.uuidCol, UUID(uuidString: "85d4fbee-6ec6-47df-bfa1-615931903d7e")!)
        XCTAssertEqual(obj.anyCol.intValue, 1)
        XCTAssertEqual(obj.objectCol!.firstName, "George")
    }

    @MainActor
    func testSwiftRountripForDistinctPrimaryKey() throws {
        let realm = try openRealm()
        checkCount(expected: 0, realm, SwiftPerson.self) // ObjectId
        checkCount(expected: 0, realm, SwiftUUIDPrimaryKeyObject.self)
        checkCount(expected: 0, realm, SwiftStringPrimaryKeyObject.self)
        checkCount(expected: 0, realm, SwiftIntPrimaryKeyObject.self)

        try write { realm in
            let swiftPerson = SwiftPerson(firstName: "Ringo", lastName: "Starr")
            swiftPerson._id = ObjectId("1234567890ab1234567890ab")
            realm.add(swiftPerson)
            realm.add(SwiftUUIDPrimaryKeyObject(id: UUID(uuidString: "85d4fbee-6ec6-47df-bfa1-615931903d7e")!, strCol: "Steve", intCol: 10))
            realm.add(SwiftStringPrimaryKeyObject(id: "1234567890ab1234567890ab", strCol: "Paul", intCol: 20))
            realm.add(SwiftIntPrimaryKeyObject(id: 1234567890, strCol: "Jackson", intCol: 30))
        }

        waitForDownloads(for: realm)
        checkCount(expected: 1, realm, SwiftPerson.self)
        checkCount(expected: 1, realm, SwiftUUIDPrimaryKeyObject.self)
        checkCount(expected: 1, realm, SwiftStringPrimaryKeyObject.self)
        checkCount(expected: 1, realm, SwiftIntPrimaryKeyObject.self)

        let swiftOjectIdPrimaryKeyObject = realm.object(ofType: SwiftPerson.self,
                                                        forPrimaryKey: ObjectId("1234567890ab1234567890ab"))!
        XCTAssertEqual(swiftOjectIdPrimaryKeyObject.firstName, "Ringo")
        XCTAssertEqual(swiftOjectIdPrimaryKeyObject.lastName, "Starr")

        let swiftUUIDPrimaryKeyObject = realm.object(ofType: SwiftUUIDPrimaryKeyObject.self,
                                                     forPrimaryKey: UUID(uuidString: "85d4fbee-6ec6-47df-bfa1-615931903d7e")!)!
        XCTAssertEqual(swiftUUIDPrimaryKeyObject.strCol, "Steve")
        XCTAssertEqual(swiftUUIDPrimaryKeyObject.intCol, 10)

        let swiftStringPrimaryKeyObject = realm.object(ofType: SwiftStringPrimaryKeyObject.self,
                                                       forPrimaryKey: "1234567890ab1234567890ab")!
        XCTAssertEqual(swiftStringPrimaryKeyObject.strCol, "Paul")
        XCTAssertEqual(swiftStringPrimaryKeyObject.intCol, 20)

        let swiftIntPrimaryKeyObject = realm.object(ofType: SwiftIntPrimaryKeyObject.self,
                                                    forPrimaryKey: 1234567890)!
        XCTAssertEqual(swiftIntPrimaryKeyObject.strCol, "Jackson")
        XCTAssertEqual(swiftIntPrimaryKeyObject.intCol, 30)
    }

    @MainActor
    func testSwiftAddObjectsWithNilPartitionValue() throws {
        // Use a fresh app as other tests touch the nil partition on the shared app
        let app = app(id: try RealmServer.shared.createApp(types: [SwiftPerson.self]))
        var config = createUser(for: app).configuration(partitionValue: .null)
        config.objectTypes = [SwiftPerson.self]

        let realm = try Realm(configuration: config)
        checkCount(expected: 0, realm, SwiftPerson.self)

        try autoreleasepool {
            var config = createUser(for: app).configuration(partitionValue: .null)
            config.objectTypes = [SwiftPerson.self]
            let realm = try Realm(configuration: config)
            try realm.write {
                realm.add(SwiftPerson(firstName: "Ringo", lastName: "Starr"))
                realm.add(SwiftPerson(firstName: "John", lastName: "Lennon"))
                realm.add(SwiftPerson(firstName: "Paul", lastName: "McCartney"))
            }
            waitForUploads(for: realm)
        }

        waitForDownloads(for: realm)
        checkCount(expected: 3, realm, SwiftPerson.self)
    }

    @MainActor
    func testSwiftDeleteObjects() throws {
        let realm = try openRealm()
        try realm.write {
            realm.add(SwiftPerson(firstName: "Ringo", lastName: "Starr"))
            realm.add(SwiftPerson(firstName: "John", lastName: "Lennon"))
            realm.add(SwiftPerson(firstName: "Paul", lastName: "McCartney"))
            realm.add(SwiftTypesSyncObject(person: SwiftPerson(firstName: "George", lastName: "Harrison")))
        }
        waitForUploads(for: realm)
        checkCount(expected: 4, realm, SwiftPerson.self)
        checkCount(expected: 1, realm, SwiftTypesSyncObject.self)

        try write { realm in
            realm.deleteAll()
        }

        checkCount(expected: 0, realm, SwiftPerson.self)
        checkCount(expected: 0, realm, SwiftTypesSyncObject.self)
    }

    @MainActor
    func testMultiplePartitions() throws {
        let partitionValueA = name
        let partitionValueB = "\(name)bar"
        let partitionValueC = "\(name)baz"

        let user1 = createUser()

        let realmA = try openRealm(user: user1, partitionValue: partitionValueA)
        let realmB = try openRealm(user: user1, partitionValue: partitionValueB)
        let realmC = try openRealm(user: user1, partitionValue: partitionValueC)
        checkCount(expected: 0, realmA, SwiftPerson.self)
        checkCount(expected: 0, realmB, SwiftPerson.self)
        checkCount(expected: 0, realmC, SwiftPerson.self)

        try autoreleasepool {
            let user2 = createUser()

            let realmA = try openRealm(user: user2, partitionValue: partitionValueA)
            try realmA.write {
                realmA.add(SwiftPerson(firstName: "Ringo", lastName: "Starr"))
                realmA.add(SwiftPerson(firstName: "John", lastName: "Lennon"))
                realmA.add(SwiftPerson(firstName: "Paul", lastName: "McCartney"))
            }

            let realmB = try openRealm(user: user2, partitionValue: partitionValueB)
            try realmB.write {
                realmB.add(SwiftPerson(firstName: "John", lastName: "Lennon"))
                realmB.add(SwiftPerson(firstName: "Paul", lastName: "McCartney"))
            }

            let realmC = try openRealm(user: user2, partitionValue: partitionValueC)
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
        }

        waitForDownloads(for: realmA)
        waitForDownloads(for: realmB)
        waitForDownloads(for: realmC)

        checkCount(expected: 3, realmA, SwiftPerson.self)
        checkCount(expected: 2, realmB, SwiftPerson.self)
        checkCount(expected: 5, realmC, SwiftPerson.self)

        XCTAssertEqual(realmA.objects(SwiftPerson.self).filter("firstName == %@", "Ringo").count, 1)
        XCTAssertEqual(realmB.objects(SwiftPerson.self).filter("firstName == %@", "Ringo").count, 0)
    }

    @MainActor
    func testConnectionState() throws {
        let realm = try openRealm(wait: false)
        let session = realm.syncSession!

        func wait(forState desiredState: SyncSession.ConnectionState) {
            let ex = expectation(description: "Wait for connection state: \(desiredState)")
            let token = session.observe(\SyncSession.connectionState, options: .initial) { s, _ in
                if s.connectionState == desiredState {
                    ex.fulfill()
                }
            }
            waitForExpectations(timeout: 5.0)
            token.invalidate()
        }

        wait(forState: .connected)

        session.suspend()
        wait(forState: .disconnected)

        session.resume()
        wait(forState: .connecting)
        wait(forState: .connected)
    }

    // MARK: - Progress notifiers
    @MainActor
    @available(*, deprecated)
    func testStreamingDownloadNotifier() throws {
        let realm = try openRealm(wait: false)
        let session = try XCTUnwrap(realm.syncSession)
        var callCount = 0
        var progress: SyncSession.Progress?
        let token = session.addProgressNotification(for: .download, mode: .reportIndefinitely) { p in
            DispatchQueue.main.async { @MainActor in
                // Verify that progress doesn't decrease, but sometimes it won't
                // have increased since the last call
                if let progress = progress {
                    XCTAssertGreaterThanOrEqual(p.progressEstimate, progress.progressEstimate)
                }
                progress = p
                callCount += 1
            }
        }
        XCTAssertNotNil(token)

        try populateRealm()
        waitForDownloads(for: realm)

        XCTAssertGreaterThanOrEqual(callCount, 1)
        let p1 = try XCTUnwrap(progress)
        XCTAssertEqual(p1.transferredBytes, p1.transferrableBytes)
        XCTAssertEqual(p1.progressEstimate, 1.0)
        XCTAssertTrue(p1.isTransferComplete)
        let initialCallCount = callCount

        // Run a second time to upload more data and verify that the callback continues to be called
        try populateRealm()
        waitForDownloads(for: realm)

        XCTAssertGreaterThan(callCount, initialCallCount)
        let p2 = try XCTUnwrap(progress)
        XCTAssertEqual(p2.transferredBytes, p2.transferrableBytes)
        XCTAssertEqual(p2.progressEstimate, 1.0)
        XCTAssertTrue(p2.isTransferComplete)

        token!.invalidate()
    }

    @MainActor
    @available(*, deprecated)
    func testStreamingUploadNotifier() throws {
        let realm = try openRealm(wait: false)
        let session = try XCTUnwrap(realm.syncSession)

        let progress = Locked<SyncSession.Progress?>(nil)

        let token = session.addProgressNotification(for: .upload, mode: .reportIndefinitely) { p in
            progress.withLock { progress in
                if let progress {
                    XCTAssertGreaterThanOrEqual(p.progressEstimate, progress.progressEstimate)
                }
                progress = p
            }
        }
        XCTAssertNotNil(token)
        waitForUploads(for: realm)

        for _ in 0..<5 {
            progress.value = nil
            try realm.write {
                for _ in 0..<SwiftSyncTestCase.bigObjectCount {
                    realm.add(SwiftHugeSyncObject.create())
                }
            }

            waitForUploads(for: realm)
        }
        token!.invalidate()

        let p = try XCTUnwrap(progress.value)
        XCTAssertEqual(p.transferredBytes, p.transferrableBytes)
        XCTAssertEqual(p.progressEstimate, 1.0)
        XCTAssertTrue(p.isTransferComplete)
    }

    @MainActor func testStreamingNotifierInvalidate() throws {
        let realm = try openRealm()
        let session = try XCTUnwrap(realm.syncSession)
        let downloadCount = Locked(0)
        let uploadCount = Locked(0)
        let tokenDownload = session.addProgressNotification(for: .download, mode: .reportIndefinitely) { _ in
            downloadCount.wrappedValue += 1
        }
        let tokenUpload = session.addProgressNotification(for: .upload, mode: .reportIndefinitely) { _ in
            uploadCount.wrappedValue += 1
        }

        try populateRealm()
        waitForDownloads(for: realm)
        try realm.write {
            realm.add(SwiftHugeSyncObject.create())
        }
        waitForUploads(for: realm)

        tokenDownload!.invalidate()
        tokenUpload!.invalidate()
        RLMSyncSession.notificationsQueue().sync { }

        XCTAssertGreaterThan(downloadCount.wrappedValue, 1)
        XCTAssertGreaterThan(uploadCount.wrappedValue, 1)

        // There's inherently a race condition here: notification callbacks can
        // be called up to one more time after they're invalidated if the sync
        // worker thread is in the middle of processing a change at the time
        // that the invalidation is requested, and there's no way to wait for that.
        // This whole test takes 250ms, so we don't need a very long sleep.
        Thread.sleep(forTimeInterval: 0.2)

        downloadCount.wrappedValue = 0
        uploadCount.wrappedValue = 0

        try populateRealm()
        waitForDownloads(for: realm)
        try realm.write {
            realm.add(SwiftHugeSyncObject.create())
        }
        waitForUploads(for: realm)

        // We check that the notification block is not called after we reset the
        // counters on the notifiers and call invalidated().
        XCTAssertEqual(downloadCount.wrappedValue, 0)
        XCTAssertEqual(uploadCount.wrappedValue, 0)
    }

    // MARK: - Download Realm

    @MainActor
    func testDownloadRealm() throws {
        try populateRealm()

        let ex = expectation(description: "download-realm")
        let config = try configuration()
        let pathOnDisk = ObjectiveCSupport.convert(object: config).pathOnDisk
        XCTAssertFalse(FileManager.default.fileExists(atPath: pathOnDisk))
        Realm.asyncOpen(configuration: config) { result in
            switch result {
            case .success(let realm):
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
            case .failure(let error):
                XCTFail("No realm on async open: \(error)")
            }
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

    @MainActor
    func testDownloadRealmToCustomPath() throws {
        try populateRealm()

        let ex = expectation(description: "download-realm")
        var config = try configuration()
        config.fileURL = realmURLForFile("copy")
        let pathOnDisk = ObjectiveCSupport.convert(object: config).pathOnDisk
        XCTAssertEqual(pathOnDisk, config.fileURL!.path)
        XCTAssertFalse(FileManager.default.fileExists(atPath: pathOnDisk))
        Realm.asyncOpen(configuration: config) { result in
            switch result {
            case .success(let realm):
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
            case .failure(let error):
                XCTFail("No realm on async open: \(error)")
            }
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

    @MainActor
    func testCancelDownloadRealm() throws {
        try populateRealm()

        // Use a serial queue for asyncOpen to ensure that the first one adds
        // the completion block before the second one cancels it
        let queue = DispatchQueue(label: "io.realm.asyncOpen")
        RLMSetAsyncOpenQueue(queue)

        let ex = expectation(description: "async open")
        ex.expectedFulfillmentCount = 2
        let config = try configuration()
        let completion = { (result: Result<Realm, Error>) in
            guard case .failure = result else {
                XCTFail("No error on cancelled async open")
                return ex.fulfill()
            }
            ex.fulfill()
        }
        Realm.asyncOpen(configuration: config, callback: completion)
        let task = Realm.asyncOpen(configuration: config, callback: completion)
        queue.sync { task.cancel() }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    @MainActor func testAsyncOpenProgress() throws {
        try populateRealm()

        let ex1 = expectation(description: "async open")
        let ex2 = expectation(description: "download progress")
        let config = try configuration()
        let task = Realm.asyncOpen(configuration: config) { result in
            XCTAssertNotNil(try? result.get())
            ex1.fulfill()
        }

        task.addProgressNotification { progress in
            if progress.isTransferComplete {
                ex2.fulfill()
            }
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    @MainActor
    func config(baseURL: String, transport: RLMNetworkTransport, syncTimeouts: SyncTimeoutOptions? = nil) throws -> Realm.Configuration {
        let appId = try RealmServer.shared.createApp(types: [])
        let appConfig = AppConfiguration(baseURL: baseURL, transport: transport, syncTimeouts: syncTimeouts)
        let app = App(id: appId, configuration: appConfig)

        let user = try logInUser(for: basicCredentials(app: app), app: app)
        var config = user.configuration(partitionValue: name, cancelAsyncOpenOnNonFatalErrors: true)
        config.objectTypes = []
        return config
    }

    @MainActor
    func testAsyncOpenTimeout() throws {
        let proxy = TimeoutProxyServer(port: 5678, targetPort: 9090)
        try proxy.start()

        let config = try config(baseURL: "http://localhost:5678",
                                transport: AsyncOpenConnectionTimeoutTransport(),
                                syncTimeouts: .init(connectTimeout: 2000, connectionLingerTime: 1))

        // Two second timeout with a one second delay should work
        autoreleasepool {
            proxy.delay = 1.0
            let ex = expectation(description: "async open")
            Realm.asyncOpen(configuration: config) { result in
                let realm = try? result.get()
                XCTAssertNotNil(realm)
                realm?.syncSession?.suspend()
                ex.fulfill()
            }
            waitForExpectations(timeout: 10.0, handler: nil)
        }

        // The client doesn't disconnect immediately, and there isn't a good way
        // to wait for it. In practice this should take more like 10ms to happen
        // so a 1s sleep is plenty.
        sleep(1)

        // Two second timeout with a two second delay should fail
        autoreleasepool {
            proxy.delay = 3.0
            let ex = expectation(description: "async open")
            Realm.asyncOpen(configuration: config) { result in
                guard case .failure(let error) = result else {
                    XCTFail("Did not fail: \(result)")
                    return
                }
                if let error = error as NSError? {
                    XCTAssertEqual(error.code, Int(ETIMEDOUT))
                    XCTAssertEqual(error.domain, NSPOSIXErrorDomain)
                }
                ex.fulfill()
            }
            waitForExpectations(timeout: 20.0, handler: nil)
        }

        proxy.stop()
    }

    class LocationOverrideTransport: RLMNetworkTransport, Sendable {
        let hostname: String
        let wsHostname: String
        init(hostname: String = "http://localhost:9090", wsHostname: String = "ws://invalid.com:9090") {
            self.hostname = hostname
            self.wsHostname = wsHostname
        }

        override func sendRequest(toServer request: RLMRequest, completion: @escaping RLMNetworkTransportCompletionBlock) {
            if request.url.hasSuffix("location") {
                let response = RLMResponse()
                response.httpStatusCode = 200
                response.body = "{\"deployment_model\":\"GLOBAL\",\"location\":\"US-VA\",\"hostname\":\"\(hostname)\",\"ws_hostname\":\"\(wsHostname)\"}"
                completion(response)
            } else {
                super.sendRequest(toServer: request, completion: completion)
            }
        }
    }

    @MainActor
    func testDNSError() throws {
        let config = try config(baseURL: "http://localhost:9090", transport: LocationOverrideTransport(wsHostname: "ws://invalid.com:9090"))
        Realm.asyncOpen(configuration: config).awaitFailure(self, timeout: 40) { error in
            assertSyncError(error, .connectionFailed, "Failed to connect to sync: Host not found (authoritative)")
        }
    }

    @MainActor
    func testTLSError() throws {
        let config = try config(baseURL: "http://localhost:9090", transport: LocationOverrideTransport(wsHostname: "wss://localhost:9090"))
        Realm.asyncOpen(configuration: config).awaitFailure(self) { error in
            assertSyncError(error, .tlsHandshakeFailed, "TLS handshake failed: SecureTransport error: record overflow (-9847)")
        }
    }

    func testAppCredentialSupport() {
        XCTAssertEqual(ObjectiveCSupport.convert(object: Credentials.facebook(accessToken: "accessToken")),
                       RLMCredentials(facebookToken: "accessToken"))

        XCTAssertEqual(ObjectiveCSupport.convert(object: Credentials.google(serverAuthCode: "serverAuthCode")),
                       RLMCredentials(googleAuthCode: "serverAuthCode"))

        XCTAssertEqual(ObjectiveCSupport.convert(object: Credentials.apple(idToken: "idToken")),
                       RLMCredentials(appleToken: "idToken"))

        XCTAssertEqual(ObjectiveCSupport.convert(object: Credentials.emailPassword(email: "email", password: "password")),
                       RLMCredentials(email: "email", password: "password"))

        XCTAssertEqual(ObjectiveCSupport.convert(object: Credentials.jwt(token: "token")),
                       RLMCredentials(jwt: "token"))

        XCTAssertEqual(ObjectiveCSupport.convert(object: Credentials.function(payload: ["dog": ["name": "fido"]])),
                       RLMCredentials(functionPayload: ["dog": ["name" as NSString: "fido" as NSString] as NSDictionary]))

        XCTAssertEqual(ObjectiveCSupport.convert(object: Credentials.userAPIKey("key")),
                       RLMCredentials(userAPIKey: "key"))

        XCTAssertEqual(ObjectiveCSupport.convert(object: Credentials.serverAPIKey("key")),
                       RLMCredentials(serverAPIKey: "key"))

        XCTAssertEqual(ObjectiveCSupport.convert(object: Credentials.anonymous),
                       RLMCredentials.anonymous())
    }

    func testAppBaseUrl() {
        let appConfig = AppConfiguration()
        XCTAssertEqual(appConfig.baseURL, "https://services.cloud.mongodb.com")

        appConfig.baseURL = "https://foo.bar"
        XCTAssertEqual(appConfig.baseURL, "https://foo.bar")

        appConfig.baseURL = nil
        XCTAssertEqual(appConfig.baseURL, "https://services.cloud.mongodb.com")
    }

    // MARK: - Authentication

    @MainActor func testInvalidCredentials() throws {
        let email = "testInvalidCredentialsEmail"
        let credentials = basicCredentials()
        let user = try logInUser(for: credentials)
        XCTAssertEqual(user.state, .loggedIn)

        let credentials2 = Credentials.emailPassword(email: email, password: "NOT_A_VALID_PASSWORD")
        let ex = expectation(description: "Should fail to log in the user")

        self.app.login(credentials: credentials2) { result in
            guard case .failure = result else {
                XCTFail("Login should not have been successful")
                return ex.fulfill()
            }
            ex.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testCustomTokenAuthentication() {
        let user = logInUser(for: jwtCredential(withAppId: appId))
        XCTAssertEqual(user.profile.metadata["anotherName"], "Bar Foo")
        XCTAssertEqual(user.profile.metadata["name"], "Foo Bar")
        XCTAssertEqual(user.profile.metadata["occupation"], "firefighter")
    }

    // MARK: - User-specific functionality

    @MainActor func testUserExpirationCallback() throws {
        let user = createUser()

        // Set a callback on the user
        let blockCalled = Locked(false)
        let ex = expectation(description: "Error callback should fire upon receiving an error")
        app.syncManager.errorHandler = { @Sendable (error, _) in
            assertSyncError(error, .clientUserError, "Unable to refresh the user access token: signature is invalid")
            blockCalled.value = true
            ex.fulfill()
        }

        // Screw up the token on the user.
        setInvalidTokensFor(user)
        // Try to open a Realm with the user; this will cause our errorHandler block defined above to be fired.
        XCTAssertFalse(blockCalled.value)
        var config = user.configuration(partitionValue: name)
        config.objectTypes = [SwiftPerson.self]
        _ = try Realm(configuration: config)

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    private func realmURLForFile(_ fileName: String) -> URL {
        let testDir = RLMRealmPathForFile("mongodb-realm")
        let directory = URL(fileURLWithPath: testDir, isDirectory: true)
        return directory.appendingPathComponent(fileName, isDirectory: false)
    }

    // MARK: - App tests

    private func appConfig() -> AppConfiguration {
        return AppConfiguration(baseURL: "http://localhost:9090")
    }

    func testAppInit() {
        let appName = "translate-utwuv"

        let appWithNoConfig = App(id: appName)
        XCTAssertEqual(appWithNoConfig.allUsers.count, 0)

        let appWithConfig = App(id: appName, configuration: appConfig())
        XCTAssertEqual(appWithConfig.allUsers.count, 0)
    }

    func testAppLogin() {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)

        app.emailPasswordAuth.registerUser(email: email, password: password).await(self)
        let syncUser = app.login(credentials: Credentials.emailPassword(email: email, password: password)).await(self)

        XCTAssertEqual(syncUser.id, app.currentUser?.id)
        XCTAssertEqual(app.allUsers.count, 1)
    }

    func testAppSwitchAndRemove() {
        let email1 = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password1 = randomString(10)
        let email2 = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password2 = randomString(10)

        app.emailPasswordAuth.registerUser(email: email1, password: password1).await(self)
        app.emailPasswordAuth.registerUser(email: email2, password: password2).await(self)

        let syncUser1 = app.login(credentials: Credentials.emailPassword(email: email1, password: password1)).await(self)
        let syncUser2 = app.login(credentials: Credentials.emailPassword(email: email2, password: password2)).await(self)

        XCTAssertEqual(app.allUsers.count, 2)

        XCTAssertEqual(syncUser2.id, app.currentUser!.id)

        app.switch(to: syncUser1)
        XCTAssertTrue(syncUser1.id == app.currentUser?.id)

        syncUser1.remove().await(self)

        XCTAssertEqual(syncUser2.id, app.currentUser!.id)
        XCTAssertEqual(app.allUsers.count, 1)
    }

    func testSafelyRemoveUser() throws {
        // A user can have its state updated asynchronously so we need to make sure
        // that remotely disabling / deleting a user is handled correctly in the
        // sync error handler.
        let user = createUser()
        _ = try RealmServer.shared.removeUserForApp(appId, userId: user.id).get()

        // Set a callback on the user
        let ex = expectation(description: "Error callback should fire upon receiving an error")
        ex.assertForOverFulfill = false // error handler can legally be called multiple times
        app.syncManager.errorHandler = { @Sendable (error, _) in
            // Connecting to sync with a deleted user sometimes triggers an
            // internal server error instead of the desired error
            if (error as NSError).code == SyncError.clientSessionError.rawValue && error.localizedDescription == "error" {
                ex.fulfill()
                return
            }
            assertSyncError(error, .clientUserError, "Unable to refresh the user access token: invalid session: failed to find refresh token")
            ex.fulfill()
        }

        // Try to open a Realm with the user; this will cause our errorHandler block defined above to be fired.
        var config = user.configuration(partitionValue: name)
        config.objectTypes = [SwiftPerson.self]
        _ = try Realm(configuration: config)
        wait(for: [ex], timeout: 20.0)
    }

    func testDeleteUser() {
        func userExistsOnServer(_ user: User) -> Bool {
            var userExists = false
            switch RealmServer.shared.retrieveUser(appId, userId: user.id) {
            case .success(let u):
                let u = u as! [String: Any]
                XCTAssertEqual(u["_id"] as! String, user.id)
                userExists = true
            case .failure:
                userExists = false
            }
            return userExists
        }

        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)

        app.emailPasswordAuth.registerUser(email: email, password: password).await(self)

        let syncUser = app.login(credentials: Credentials.emailPassword(email: email, password: password)).await(self)
        XCTAssertTrue(userExistsOnServer(syncUser))

        XCTAssertEqual(syncUser.id, app.currentUser?.id)
        XCTAssertEqual(app.allUsers.count, 1)

        syncUser.delete().await(self)

        XCTAssertFalse(userExistsOnServer(syncUser))
        XCTAssertNil(app.currentUser)
        XCTAssertEqual(app.allUsers.count, 0)
    }

    func testAppLinkUser() {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)
        app.emailPasswordAuth.registerUser(email: email, password: password).await(self)
        let credentials = Credentials.emailPassword(email: email, password: password)
        let syncUser = app.login(credentials: Credentials.anonymous).await(self)
        syncUser.linkUser(credentials: credentials).await(self)
        XCTAssertEqual(syncUser.id, app.currentUser?.id)
        XCTAssertEqual(syncUser.identities.count, 2)
    }

    // MARK: - Provider Clients

    func testEmailPasswordProviderClient() {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)
        app.emailPasswordAuth.registerUser(email: email, password: password).await(self)

        app.emailPasswordAuth.confirmUser("atoken", tokenId: "atokenid").awaitFailure(self) {
            assertAppError($0, .badRequest, "invalid token data")
        }
        app.emailPasswordAuth.resendConfirmationEmail(email: "atoken").awaitFailure(self) {
            assertAppError($0, .userNotFound, "user not found")
        }
        app.emailPasswordAuth.retryCustomConfirmation(email: email).awaitFailure(self) {
            assertAppError($0, .unknown,
                                "cannot run confirmation for \(email): automatic confirmation is enabled")
        }
        app.emailPasswordAuth.sendResetPasswordEmail(email: "atoken").awaitFailure(self) {
            assertAppError($0, .userNotFound, "user not found")
        }
        app.emailPasswordAuth.resetPassword(to: "password", token: "atoken", tokenId: "tokenId").awaitFailure(self) {
            assertAppError($0, .badRequest, "invalid token data")
        }
        app.emailPasswordAuth.callResetPasswordFunction(email: email,
                                                        password: randomString(10),
                                                        args: [[:]]).awaitFailure(self) {
            assertAppError($0, .unknown, "failed to reset password for user \"\(email)\"")
        }
    }

    func testUserAPIKeyProviderClient() {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)
        app.emailPasswordAuth.registerUser(email: email, password: password).await(self)

        let credentials = Credentials.emailPassword(email: email, password: password)
        let syncUser = app.login(credentials: credentials).await(self)

        let apiKey = syncUser.apiKeysAuth.createAPIKey(named: "my-api-key").await(self)
        XCTAssertEqual(apiKey.name, "my-api-key")
        XCTAssertNotNil(apiKey.key)
        XCTAssertNotEqual(apiKey.key!, "my-api-key")
        XCTAssertFalse(apiKey.key!.isEmpty)

        syncUser.apiKeysAuth.fetchAPIKey(apiKey.objectId).await(self)

        let apiKeys = syncUser.apiKeysAuth.fetchAPIKeys().await(self)
        XCTAssertEqual(apiKeys.count, 1)

        syncUser.apiKeysAuth.disableAPIKey(apiKey.objectId).await(self)
        syncUser.apiKeysAuth.enableAPIKey(apiKey.objectId).await(self)
        syncUser.apiKeysAuth.deleteAPIKey(apiKey.objectId).await(self)

        let apiKeys2 = syncUser.apiKeysAuth.fetchAPIKeys().await(self)
        XCTAssertEqual(apiKeys2.count, 0)
    }

    func testCallFunction() {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)
        app.emailPasswordAuth.registerUser(email: email, password: password).await(self)

        let credentials = Credentials.emailPassword(email: email, password: password)
        let syncUser = app.login(credentials: credentials).await(self)

        let bson = syncUser.functions.sum(1, 2, 3, 4, 5).await(self)
        guard case let .int32(sum) = bson else {
            XCTFail("unexpected bson type in sum: \(bson)")
            return
        }
        XCTAssertEqual(sum, 15)
    }

    func testPushRegistration() {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)

        app.emailPasswordAuth.registerUser(email: email, password: password).await(self)
        let credentials = Credentials.emailPassword(email: email, password: password)
        app.login(credentials: credentials).await(self)

        let client = app.pushClient(serviceName: "gcm")
        client.registerDevice(token: "some-token", user: app.currentUser!).await(self)
        client.deregisterDevice(user: app.currentUser!).await(self)
    }

    func testCustomUserData() {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)

        let credentials = Credentials.emailPassword(email: email, password: password)
        app.emailPasswordAuth.registerUser(email: email, password: password).await(self)
        let user = app.login(credentials: credentials).await(self)
        user.functions.updateUserData(["favourite_colour": "green", "apples": 10]).await(self)

        let customData = user.refreshCustomData().await(self)
        XCTAssertEqual(customData["apples"] as! Int, 10)
        XCTAssertEqual(customData["favourite_colour"] as! String, "green")

        XCTAssertEqual(user.customData["favourite_colour"], .string("green"))
        XCTAssertEqual(user.customData["apples"], .int64(10))
    }

    // MARK: User Profile

    func testUserProfileInitialization() {
        let profile = UserProfile()
        XCTAssertNil(profile.name)
        XCTAssertNil(profile.maxAge)
        XCTAssertNil(profile.minAge)
        XCTAssertNil(profile.birthday)
        XCTAssertNil(profile.gender)
        XCTAssertNil(profile.firstName)
        XCTAssertNil(profile.lastName)
        XCTAssertNil(profile.pictureURL)
        XCTAssertEqual(profile.metadata, [:])
    }

    // MARK: Seed file path

    func testSeedFilePathOpenLocalToSync() throws {
        var config = Realm.Configuration()
        config.fileURL = RLMTestRealmURL()
        config.objectTypes = [SwiftHugeSyncObject.self]
        let realm = try Realm(configuration: config)
        try realm.write {
            for _ in 0..<SwiftSyncTestCase.bigObjectCount {
                realm.add(SwiftHugeSyncObject.create())
            }
        }

        let seedURL = RLMTestRealmURL().deletingLastPathComponent().appendingPathComponent("seed.realm")
        let user = createUser()
        var destinationConfig = user.configuration(partitionValue: name)
        destinationConfig.fileURL = seedURL
        destinationConfig.objectTypes = [SwiftHugeSyncObject.self]

        try realm.writeCopy(configuration: destinationConfig)

        var syncConfig = user.configuration(partitionValue: name)
        syncConfig.seedFilePath = seedURL
        syncConfig.objectTypes = [SwiftHugeSyncObject.self]

        // Open the realm and immediately check data
        let destinationRealm = try Realm(configuration: syncConfig)
        checkCount(expected: SwiftSyncTestCase.bigObjectCount, destinationRealm, SwiftHugeSyncObject.self)

        try destinationRealm.write {
            destinationRealm.add(SwiftHugeSyncObject.create())
        }
        waitForUploads(for: destinationRealm)
        checkCount(expected: SwiftSyncTestCase.bigObjectCount + 1, destinationRealm, SwiftHugeSyncObject.self)
    }

    @MainActor func testSeedFilePathOpenSyncToSync() throws {
        // user1 creates and writeCopies a realm to be opened by another user
        var config = try configuration()
        config.objectTypes = [SwiftHugeSyncObject.self]
        let realm = try Realm(configuration: config)
        try realm.write {
            for _ in 0..<SwiftSyncTestCase.bigObjectCount {
                realm.add(SwiftHugeSyncObject.create())
            }
        }
        waitForUploads(for: realm)

        // user2 creates a configuration that will use user1's realm as a seed
        var destinationConfig = try configuration()
        let originalFilePath = destinationConfig.fileURL
        destinationConfig.seedFilePath = RLMTestRealmURL()
        destinationConfig.objectTypes = [SwiftHugeSyncObject.self]
        destinationConfig.fileURL = RLMTestRealmURL()

        try realm.writeCopy(configuration: destinationConfig)

        // Reset the fileURL so that we use the users folder to store the realm.
        destinationConfig.fileURL = originalFilePath

        // Open the realm and immediately check data
        let destinationRealm = try Realm(configuration: destinationConfig)
        checkCount(expected: SwiftSyncTestCase.bigObjectCount, destinationRealm, SwiftHugeSyncObject.self)

        try destinationRealm.write {
            destinationRealm.add(SwiftHugeSyncObject.create())
        }
        waitForUploads(for: destinationRealm)
        checkCount(expected: SwiftSyncTestCase.bigObjectCount + 1, destinationRealm, SwiftHugeSyncObject.self)
    }

    @MainActor func testSeedFilePathOpenSyncToLocal() throws {
        let seedURL = RLMTestRealmURL().deletingLastPathComponent().appendingPathComponent("seed.realm")
        let user1 = try logInUser(for: basicCredentials())
        var syncConfig = user1.configuration(partitionValue: name)
        syncConfig.objectTypes = [SwiftHugeSyncObject.self]

        let syncRealm = try Realm(configuration: syncConfig)

        try syncRealm.write {
            syncRealm.add(SwiftHugeSyncObject.create())
        }
        waitForUploads(for: syncRealm)
        checkCount(expected: 1, syncRealm, SwiftHugeSyncObject.self)

        var exportConfig = Realm.Configuration()
        exportConfig.fileURL = seedURL
        exportConfig.objectTypes = [SwiftHugeSyncObject.self]
        // Export for use as a local Realm.
        try syncRealm.writeCopy(configuration: exportConfig)

        var localConfig = Realm.Configuration()
        localConfig.seedFilePath = seedURL
        localConfig.fileURL = RLMDefaultRealmURL()
        localConfig.objectTypes = [SwiftHugeSyncObject.self]
        localConfig.schemaVersion = 1

        let realm = try Realm(configuration: localConfig)
        try realm.write {
            for _ in 0..<SwiftSyncTestCase.bigObjectCount {
                realm.add(SwiftHugeSyncObject.create())
            }
        }

        checkCount(expected: SwiftSyncTestCase.bigObjectCount + 1, realm, SwiftHugeSyncObject.self)
    }

    // MARK: Write Copy For Configuration

    @MainActor func testWriteCopySyncedRealm() throws {
        // user1 creates and writeCopies a realm to be opened by another user
        var config = try configuration()
        config.objectTypes = [SwiftHugeSyncObject.self]
        let syncedRealm = try Realm(configuration: config)
        try syncedRealm.write {
            for _ in 0..<SwiftSyncTestCase.bigObjectCount {
                syncedRealm.add(SwiftHugeSyncObject.create())
            }
        }
        waitForUploads(for: syncedRealm)

        // user2 creates a configuration that will use user1's realm as a seed
        var destinationConfig = try configuration()
        destinationConfig.objectTypes = [SwiftHugeSyncObject.self]
        destinationConfig.fileURL = RLMTestRealmURL()
        try syncedRealm.writeCopy(configuration: destinationConfig)

        // Open the realm and immediately check data
        let destinationRealm = try Realm(configuration: destinationConfig)
        checkCount(expected: SwiftSyncTestCase.bigObjectCount, destinationRealm, SwiftHugeSyncObject.self)

        // Create an object in the destination realm which does not exist in the original realm.
        let obj1 = SwiftHugeSyncObject.create()
        try destinationRealm.write {
            destinationRealm.add(obj1)
        }

        waitForUploads(for: destinationRealm)
        waitForDownloads(for: syncedRealm)

        // Check if the object created in the destination realm is synced to the original realm
        let obj2 = syncedRealm.objects(SwiftHugeSyncObject.self).where { $0._id == obj1._id }.first
        XCTAssertNotNil(obj2)
        XCTAssertEqual(obj1.data, obj2?.data)

        // Create an object in the original realm which does not exist in the destination realm.
        let obj3 = SwiftHugeSyncObject.create()
        try syncedRealm.write {
            syncedRealm.add(obj3)
        }

        waitForUploads(for: syncedRealm)
        waitForDownloads(for: destinationRealm)

        // Check if the object created in the original realm is synced to the destination realm
        let obj4 = destinationRealm.objects(SwiftHugeSyncObject.self).where { $0._id == obj3._id }.first
        XCTAssertNotNil(obj4)
        XCTAssertEqual(obj3.data, obj4?.data)
    }

    @MainActor func testWriteCopyLocalRealmToSync() throws {
        var localConfig = Realm.Configuration()
        localConfig.objectTypes = [SwiftPerson.self]
        localConfig.fileURL = realmURLForFile("test.realm")

        var syncConfig = try configuration()
        syncConfig.objectTypes = [SwiftPerson.self]

        let localRealm = try Realm(configuration: localConfig)
        try localRealm.write {
            localRealm.add(SwiftPerson(firstName: "John", lastName: "Doe"))
        }

        try localRealm.writeCopy(configuration: syncConfig)

        let syncedRealm = try Realm(configuration: syncConfig)
        XCTAssertEqual(syncedRealm.objects(SwiftPerson.self).count, 1)
        waitForDownloads(for: syncedRealm)

        try syncedRealm.write {
            syncedRealm.add(SwiftPerson(firstName: "Jane", lastName: "Doe"))
        }

        waitForUploads(for: syncedRealm)
        let syncedResults = syncedRealm.objects(SwiftPerson.self)
        XCTAssertEqual(syncedResults.where { $0.firstName == "John" }.count, 1)
        XCTAssertEqual(syncedResults.where { $0.firstName == "Jane" }.count, 1)
    }

    @MainActor func testWriteCopySynedRealmToLocal() throws {
        var syncConfig = try configuration()
        syncConfig.objectTypes = [SwiftPerson.self]
        let syncedRealm = try Realm(configuration: syncConfig)
        waitForDownloads(for: syncedRealm)

        try syncedRealm.write {
            syncedRealm.add(SwiftPerson(firstName: "Jane", lastName: "Doe"))
        }
        waitForUploads(for: syncedRealm)
        XCTAssertEqual(syncedRealm.objects(SwiftPerson.self).count, 1)

        var localConfig = Realm.Configuration()
        localConfig.objectTypes = [SwiftPerson.self]
        localConfig.fileURL = realmURLForFile("test.realm")
        // `realm_id` will be removed in the local realm, so we need to bump
        // the schema version.
        localConfig.schemaVersion = 1

        try syncedRealm.writeCopy(configuration: localConfig)

        let localRealm = try Realm(configuration: localConfig)
        try localRealm.write {
            localRealm.add(SwiftPerson(firstName: "John", lastName: "Doe"))
        }

        let results = localRealm.objects(SwiftPerson.self)
        XCTAssertEqual(results.where { $0.firstName == "John" }.count, 1)
        XCTAssertEqual(results.where { $0.firstName == "Jane" }.count, 1)
    }

    @MainActor func testWriteCopyLocalRealmForSyncWithExistingData() throws {
        var initialSyncConfig = try configuration()
        initialSyncConfig.objectTypes = [SwiftPerson.self]

        // Make sure objects with confliciting primary keys sync ok.
        let conflictingObjectId = ObjectId.generate()
        let person = SwiftPerson(firstName: "Foo", lastName: "Bar")
        person._id = conflictingObjectId
        let initialRealm = try Realm(configuration: initialSyncConfig)
        try initialRealm.write {
            initialRealm.add(person)
            initialRealm.add(SwiftPerson(firstName: "Foo2", lastName: "Bar2"))
        }
        waitForUploads(for: initialRealm)

        var localConfig = Realm.Configuration()
        localConfig.objectTypes = [SwiftPerson.self]
        localConfig.fileURL = realmURLForFile("test.realm")

        var syncConfig = try configuration()
        syncConfig.objectTypes = [SwiftPerson.self]

        let localRealm = try Realm(configuration: localConfig)
        // `person2` will override what was previously stored on the server.
        let person2 = SwiftPerson(firstName: "John", lastName: "Doe")
        person2._id = conflictingObjectId
        try localRealm.write {
            localRealm.add(person2)
            localRealm.add(SwiftPerson(firstName: "Foo3", lastName: "Bar3"))
        }

        try localRealm.writeCopy(configuration: syncConfig)

        let syncedRealm = try Realm(configuration: syncConfig)
        waitForDownloads(for: syncedRealm)
        XCTAssertTrue(syncedRealm.objects(SwiftPerson.self).count == 3)

        try syncedRealm.write {
            syncedRealm.add(SwiftPerson(firstName: "Jane", lastName: "Doe"))
        }

        waitForUploads(for: syncedRealm)
        let syncedResults = syncedRealm.objects(SwiftPerson.self)
        XCTAssertEqual(syncedResults.where {
            $0.firstName == "John" &&
            $0.lastName == "Doe" &&
            $0._id == conflictingObjectId
        }.count, 1)
        XCTAssertTrue(syncedRealm.objects(SwiftPerson.self).count == 4)
    }

    @MainActor func testWriteCopyFailBeforeSynced() throws {
        var user1Config = try configuration()
        user1Config.objectTypes = [SwiftPerson.self]
        let user1Realm = try Realm(configuration: user1Config)
        // Suspend the session so that changes cannot be uploaded
        user1Realm.syncSession?.suspend()
        try user1Realm.write {
            user1Realm.add(SwiftPerson())
        }

        var user2Config = try configuration()
        user2Config.objectTypes = [SwiftPerson.self]
        let pathOnDisk = ObjectiveCSupport.convert(object: user2Config).pathOnDisk
        XCTAssertFalse(FileManager.default.fileExists(atPath: pathOnDisk))

        let realm = try Realm(configuration: user1Config)
        realm.syncSession?.suspend()
        try realm.write {
            realm.add(SwiftPerson())
        }

        // Changes have yet to be uploaded so expect an exception
        XCTAssertThrowsError(try realm.writeCopy(configuration: user2Config)) { error in
            XCTAssertEqual(error.localizedDescription, "All client changes must be integrated in server before writing copy")
        }
    }

    func testServerSchemaValidationWithCustomColumnNames() throws {
        let appId = try RealmServer.shared.createApp(types: [SwiftCustomColumnObject.self])
        let className = "SwiftCustomColumnObject \(appId)"
        RealmServer.shared.retrieveSchemaProperties(appId, className: className) { result in
            switch result {
            case .failure(let error):
                XCTFail("Couldn't retrieve schema properties for \(className): \(error)")
            case .success(let properties):
                for (_, value) in customColumnPropertiesMapping {
                    XCTAssertTrue(properties.contains(where: { $0 == value }))
                }
            }
        }
    }

    @MainActor func testVerifyDocumentsWithCustomColumnNames() throws {
        let collection = try setupMongoCollection(for: SwiftCustomColumnObject.self)
        let objectId = ObjectId.generate()
        let linkedObjectId = ObjectId.generate()

        try write { realm in
            let object = SwiftCustomColumnObject()
            object.id = objectId
            let linkedObject = SwiftCustomColumnObject()
            linkedObject.id = linkedObjectId
            object.objectCol = linkedObject
            realm.add(object)
        }
        waitForCollectionCount(collection, 2)

        let filter: Document = ["_id": .objectId(objectId)]
        collection.findOneDocument(filter: filter)
            .await(self) { document in
                XCTAssertNotNil(document)
                XCTAssertEqual(document?["_id"]??.objectIdValue, objectId)
                XCTAssertNil(document?["id"] as Any?)
                XCTAssertEqual(document?["custom_boolCol"]??.boolValue, true)
                XCTAssertNil(document?["boolCol"] as Any?)
                XCTAssertEqual(document?["custom_intCol"]??.int64Value, 1)
                XCTAssertNil(document?["intCol"] as Any?)
                XCTAssertEqual(document?["custom_stringCol"]??.stringValue, "string")
                XCTAssertNil(document?["stringCol"] as Any?)
                XCTAssertEqual(document?["custom_decimalCol"]??.decimal128Value, Decimal128(1))
                XCTAssertNil(document?["decimalCol"] as Any?)
                XCTAssertEqual(document?["custom_objectCol"]??.objectIdValue, linkedObjectId)
                XCTAssertNil(document?["objectCol"] as Any?)
            }
    }

    /// The purpose of this test is to confirm that when an Object is set on a mixed Column and an old
    /// version of an app does not have that Realm Object / Schema we can still access that object via
    /// `AnyRealmValue.dynamicSchema`.
    @MainActor func testMissingSchema() throws {
        try autoreleasepool {
            // Imagine this is v2 of an app with 3 classes
            var config = createUser().configuration(partitionValue: name)
            config.objectTypes = [SwiftPerson.self, SwiftAnyRealmValueObject.self, SwiftMissingObject.self]
            let realm = try openRealm(configuration: config)
            try realm.write {
                let so1 = SwiftPerson()
                so1.firstName = "Rick"
                so1.lastName = "Sanchez"
                let so2 = SwiftPerson()
                so2.firstName = "Squidward"
                so2.lastName = "Tentacles"

                let syncObj2 = SwiftMissingObject()
                syncObj2.objectCol = so1
                syncObj2.anyCol = .object(so1)

                let syncObj = SwiftMissingObject()
                syncObj.objectCol = so1
                syncObj.anyCol = .object(syncObj2)
                let obj = SwiftAnyRealmValueObject()
                obj.anyCol = .object(syncObj)
                obj.otherAnyCol = .object(so2)
                realm.add(obj)
            }
            waitForUploads(for: realm)
        }

        // Imagine this is v1 of an app with just 2 classes, `SwiftMissingObject`
        // did not exist when this version was shipped,
        // but v2 managed to sync `SwiftMissingObject` to this Realm.
        var config = createUser().configuration(partitionValue: name)
        config.objectTypes = [SwiftAnyRealmValueObject.self, SwiftPerson.self]
        let realm = try openRealm(configuration: config)
        let obj = realm.objects(SwiftAnyRealmValueObject.self).first
        // SwiftMissingObject.anyCol -> SwiftMissingObject.anyCol -> SwiftPerson.firstName
        let anyCol = ((obj!.anyCol.dynamicObject?.anyCol as? Object)?["anyCol"] as? Object)
        XCTAssertEqual((anyCol?["firstName"] as? String), "Rick")
        try realm.write {
            anyCol?["firstName"] = "Morty"
        }
        XCTAssertEqual((anyCol?["firstName"] as? String), "Morty")
        let objectCol = (obj!.anyCol.dynamicObject?.objectCol as? Object)
        XCTAssertEqual((objectCol?["firstName"] as? String), "Morty")
    }

    func testRevokeUserSessions() {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)

        app.emailPasswordAuth.registerUser(email: email, password: password).await(self)

        let syncUser = app.login(credentials: Credentials.emailPassword(email: email, password: password)).await(self)

        // Should succeed refreshing custom data
        syncUser.refreshCustomData().await(self)

        _ = try? RealmServer.shared.revokeUserSessions(appId, userId: syncUser.id).get()

        // Should fail refreshing custom data. This verifies we're correctly handling the error in RLMSessionDelegate
        syncUser.refreshCustomData().awaitFailure(self)

        // This verifies that we don't crash in RLMEventSessionDelegate when creating a watch stream
        // with a revoked user. See https://github.com/realm/realm-swift/issues/8519
        let watchTestUtility = WatchTestUtility(testCase: self, expectError: true)
        _ = syncUser.collection(for: Dog.self, app: app).watch(delegate: watchTestUtility)
        watchTestUtility.waitForOpen()
        watchTestUtility.waitForClose()

        let didCloseError = watchTestUtility.didCloseError! as NSError
        XCTAssertNotNil(didCloseError)
        XCTAssertEqual(didCloseError.localizedDescription, "URLSession HTTP error code: 403")
        XCTAssertNil(didCloseError.userInfo[NSUnderlyingErrorKey])
    }
}

#endif // os(macOS)
