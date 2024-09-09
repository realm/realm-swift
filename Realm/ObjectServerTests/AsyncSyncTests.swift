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

#if os(macOS) && swift(>=5.8)

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

// SE-0392 exposes this functionality directly, but for now we have to call the
// internal standard library function
@_silgen_name("swift_job_run")
private func _swiftJobRun(_ job: UnownedJob, _ executor: UnownedSerialExecutor)

@available(macOS 13, *)
class AsyncAwaitSyncTests: SwiftSyncTestCase {
    override class var defaultTestSuite: XCTestSuite {
        // async/await is currently incompatible with thread sanitizer and will
        // produce many false positives
        // https://bugs.swift.org/browse/SR-15444
        if RLMThreadSanitizerEnabled() {
            return XCTestSuite(name: "\(type(of: self))")
        }
        return super.defaultTestSuite
    }

    override var objectTypes: [ObjectBase.Type] {
        [
            SwiftCustomColumnObject.self,
            SwiftHugeSyncObject.self,
            SwiftPerson.self,
            SwiftTypesSyncObject.self,
        ]
    }

    @MainActor func populateRealm() async throws {
        try await write { realm in
            realm.add(SwiftHugeSyncObject.create())
            realm.add(SwiftHugeSyncObject.create())
        }
    }

    func assertThrowsError<T: Sendable, E: Error>(
        _ expression: @autoclosure () async throws -> T,
        file: StaticString = #filePath, line: UInt = #line,
        _ errorHandler: (_ error: E) -> Void
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expression should have thrown an error", file: file, line: line)
        } catch let error as E {
            errorHandler(error)
        } catch {
            XCTFail("Expected error of type \(E.self) but got \(error)")
        }
    }

    func testUpdateBaseUrl() async throws {
        let app = App(id: appId)
        XCTAssertEqual(app.baseURL, "https://services.cloud.mongodb.com")

        try await app.updateBaseUrl(to: "http://localhost:9090")
        XCTAssertEqual(app.baseURL, "http://localhost:9090")

        try await app.updateBaseUrl(to: "http://127.0.0.1:9090")
        XCTAssertEqual(app.baseURL, "http://127.0.0.1:9090")

        // Fails as this appId doesn't exist in prod
        await assertThrowsError(try await app.updateBaseUrl(to: nil)) { (error: AppError) in
            XCTAssertEqual(error.code, .unknown)
        }
    }

    @MainActor func testAsyncOpenStandalone() async throws {
        try autoreleasepool {
            let configuration = Realm.Configuration(objectTypes: [SwiftPerson.self])
            let realm = try Realm(configuration: configuration)
            try realm.write {
                (0..<10).forEach { _ in realm.add(SwiftPerson(firstName: "Charlie", lastName: "Bucket")) }
            }
        }
        let configuration = Realm.Configuration(objectTypes: [SwiftPerson.self])
        let realm = try await Realm(configuration: configuration)
        XCTAssertEqual(realm.objects(SwiftPerson.self).count, 10)
    }

    @MainActor func testAsyncOpenSync() async throws {
        try await populateRealm()
        let realm = try await openRealm()
        XCTAssertEqual(realm.objects(SwiftHugeSyncObject.self).count, 2)
    }

    @MainActor func testAsyncOpenDownloadBehaviorNever() async throws {
        try await populateRealm()
        let config = try configuration()

        // Should not have any objects as it just opens immediately without waiting
        let realm = try await Realm(configuration: config, downloadBeforeOpen: .never)
        XCTAssertEqual(realm.objects(SwiftHugeSyncObject.self).count, 0)
        waitForDownloads(for: realm)
        XCTAssertEqual(realm.objects(SwiftHugeSyncObject.self).count, 2)
    }

    @MainActor func testAsyncOpenDownloadBehaviorOnce() async throws {
        try await populateRealm()
        let config = try configuration()

        // Should have the objects
        try await Task {
            let realm = try await Realm(configuration: config, downloadBeforeOpen: .once)
            XCTAssertEqual(realm.objects(SwiftHugeSyncObject.self).count, 2)
        }.value

        // Add some more objects
        try await write { realm in
            realm.add(SwiftHugeSyncObject.create())
            realm.add(SwiftHugeSyncObject.create())
        }

        // Will not wait for the new objects to download
        try await Task {
            let realm = try await Realm(configuration: config, downloadBeforeOpen: .once)
            XCTAssertEqual(realm.objects(SwiftHugeSyncObject.self).count, 2)
            try XCTUnwrap(realm.syncSession).suspend()
        }.value
    }

    @MainActor func testAsyncOpenDownloadBehaviorAlwaysWithCachedRealm() async throws {
        try await populateRealm()
        let config = try configuration()

        // Should have the objects
        let realm = try await Realm(configuration: config, downloadBeforeOpen: .always)
        XCTAssertEqual(realm.objects(SwiftHugeSyncObject.self).count, 2)
        try XCTUnwrap(realm.syncSession).suspend()


        // Add some more objects
        try await populateRealm()

        // Should resume the session and wait for the new objects to download
        _ = try await Realm(configuration: config, downloadBeforeOpen: .always)
        XCTAssertEqual(realm.objects(SwiftHugeSyncObject.self).count, 4)
    }

    @MainActor func testAsyncOpenDownloadBehaviorAlwaysWithFreshRealm() async throws {
        try await populateRealm()
        let config = try configuration()

        // Open in a Task so that the Realm is closed and re-opened later
        _ = try await Task {
            let realm = try await Realm(configuration: config, downloadBeforeOpen: .always)
            XCTAssertEqual(realm.objects(SwiftHugeSyncObject.self).count, 2)
        }.value

        // Add some more objects
        try await populateRealm()

        // Should wait for the new objects to download
        let realm = try await Realm(configuration: config, downloadBeforeOpen: .always)
        XCTAssertEqual(realm.objects(SwiftHugeSyncObject.self).count, 4)
    }

    @MainActor func testDownloadPBSRealmCustomColumnNames() async throws {
        let objectId = ObjectId.generate()
        let linkedObjectId = ObjectId.generate()

        try await write { realm in
            let object = SwiftCustomColumnObject()
            object.id = objectId
            object.binaryCol = Data("string".utf8)
            let linkedObject = SwiftCustomColumnObject()
            linkedObject.id = linkedObjectId
            object.objectCol = linkedObject
            realm.add(object)
        }

        // Should have the objects
        let realm = try await openRealm()
        XCTAssertEqual(realm.objects(SwiftCustomColumnObject.self).count, 2)

        let object = try XCTUnwrap(realm.object(ofType: SwiftCustomColumnObject.self, forPrimaryKey: objectId))
        XCTAssertEqual(object.id, objectId)
        XCTAssertEqual(object.boolCol, true)
        XCTAssertEqual(object.intCol, 1)
        XCTAssertEqual(object.doubleCol, 1.1)
        XCTAssertEqual(object.stringCol, "string")
        XCTAssertEqual(object.binaryCol, Data("string".utf8))
        XCTAssertEqual(object.dateCol, Date(timeIntervalSince1970: -1))
        XCTAssertEqual(object.longCol, 1)
        XCTAssertEqual(object.decimalCol, Decimal128(1))
        XCTAssertEqual(object.uuidCol, UUID(uuidString: "85d4fbee-6ec6-47df-bfa1-615931903d7e")!)
        XCTAssertNil(object.objectIdCol)
        XCTAssertEqual(object.objectCol!.id, linkedObjectId)
    }

    // A custom executor which cancels the task after the requested number of
    // invocations. This is a very naive executor which just synchronously
    // invokes jobs, which generally is not a legal thing to do
    final class CancellingExecutor: SerialExecutor, @unchecked Sendable {
        private var remaining: Locked<Int>
        private var pendingJob: UnownedJob?
        var task: Task<Void, any Error>? {
            didSet {
                if let pendingJob = pendingJob {
                    self.pendingJob = nil
                    enqueue(pendingJob)
                }
            }
        }

        init(cancelAfter: Int) {
            remaining = Locked(cancelAfter)
        }

        func enqueue(_ job: UnownedJob) {
            // The body of the task is enqueued before the task variable is
            // set, so we need to defer invoking the very first job
            guard let task = task else {
                precondition(pendingJob == nil)
                pendingJob = job
                return
            }

            remaining.withLock { remaining in
                if remaining == 0 {
                    task.cancel()
                }
                remaining -= 1

                // S#-0392 exposes all the stuff we need for this in the public
                // API (Which hopefully will arrive in Swift 5.9), but for now
                // invoking a job requires some private things.
                _swiftJobRun(job, self.asUnownedSerialExecutor())
            }
        }

        func asUnownedSerialExecutor() -> UnownedSerialExecutor {
            UnownedSerialExecutor(ordinary: self)
        }
    }

    // An actor that does nothing other than have a custom executor
    actor CustomExecutorActor {
        nonisolated let executor: UnownedSerialExecutor
        init(_ executor: UnownedSerialExecutor) {
            self.executor = executor
        }
        nonisolated var unownedExecutor: UnownedSerialExecutor {
            executor
        }
    }

    @MainActor func testAsyncOpenTaskCancellation() async throws {
        try await populateRealm()

        let configuration = try configuration()
        func isolatedOpen(_ actor: isolated CustomExecutorActor) async throws {
#if compiler(<6)
            _ = try await Realm(configuration: configuration, actor: actor, downloadBeforeOpen: .always)
#else
            _ = try await Realm.open(configuration: configuration, downloadBeforeOpen: .always)
#endif
        }


        // Try opening the Realm with the Task being cancelled at every possible
        // point between executor invocations. This doesn't really test that
        // cancellation is *correct*; just that cancellation never results in
        // a hang or crash.
        for i in 0 ..< .max {
            RLMWaitForRealmToClose(configuration.fileURL!.path)
            _ = try Realm.deleteFiles(for: configuration)

            let executor = CancellingExecutor(cancelAfter: i)
            executor.task = Task {
                try await isolatedOpen(.init(executor.asUnownedSerialExecutor()))
            }
            do {
                try await executor.task!.value
                break
            } catch is CancellationError {
                // pass
            } catch {
                XCTFail("Expected CancellationError but got \(error)")
            }
        }

        // Repeat the above, but with a cached Realm so that we hit that code path instead
        let cachedRealm = try await Realm(configuration: configuration, downloadBeforeOpen: .always)
        for i in 0 ..< .max {
            let executor = CancellingExecutor(cancelAfter: i)
            executor.task = Task {
                try await isolatedOpen(.init(executor.asUnownedSerialExecutor()))
            }
            do {
                try await executor.task!.value
                break
            } catch is CancellationError {
                // pass
            } catch {
                XCTFail("Expected CancellationError but got \(error)")
            }
        }
        cachedRealm.invalidate()
    }

    func testCallResetPasswordAsyncAwait() async throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)
        try await app.emailPasswordAuth.registerUser(email: email, password: password)
        let auth = app.emailPasswordAuth
        await assertThrowsError(try await auth.callResetPasswordFunction(email: email,
                                                                         password: randomString(10),
                                                                         args: [[:]])) {
            assertAppError($0, .unknown, "failed to reset password for user \"\(email)\"")
        }
    }

    func testAppLinkUserAsyncAwait() async throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)
        try await app.emailPasswordAuth.registerUser(email: email, password: password)

        let syncUser = try await self.app.login(credentials: Credentials.anonymous)

        let credentials = Credentials.emailPassword(email: email, password: password)
        let linkedUser = try await syncUser.linkUser(credentials: credentials)
        XCTAssertEqual(linkedUser.id, app.currentUser?.id)
        XCTAssertEqual(linkedUser.identities.count, 2)
    }

    func testUserCallFunctionAsyncAwait() async throws {
        let user = try await self.app.login(credentials: basicCredentials())
        guard case let .int32(sum) = try await user.functions.sum(1, 2, 3, 4, 5) else {
            return XCTFail("Should be int32")
        }
        XCTAssertEqual(sum, 15)
    }

    // MARK: - Objective-C async await
    func testPushRegistrationAsyncAwait() async throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)
        try await app.emailPasswordAuth.registerUser(email: email, password: password)

        _ = try await app.login(credentials: Credentials.emailPassword(email: email, password: password))

        let client = app.pushClient(serviceName: "gcm")
        try await client.registerDevice(token: "some-token", user: app.currentUser!)
        try await client.deregisterDevice(user: app.currentUser!)
    }

    func testEmailPasswordProviderClientAsyncAwait() async throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)
        let auth = app.emailPasswordAuth
        try await auth.registerUser(email: email, password: password)

        await assertThrowsError(try await auth.confirmUser("atoken", tokenId: "atokenid")) {
            assertAppError($0, .badRequest, "invalid token data")
        }
        await assertThrowsError(try await auth.resendConfirmationEmail(email)) {
            assertAppError($0, .userAlreadyConfirmed, "already confirmed")
        }
        await assertThrowsError(try await auth.retryCustomConfirmation(email)) {
            assertAppError($0, .unknown,
                           "cannot run confirmation for \(email): automatic confirmation is enabled")
        }
        await assertThrowsError(try await auth.sendResetPasswordEmail("atoken")) {
            assertAppError($0, .userNotFound, "user not found")
        }
    }

    func testUserAPIKeyProviderClientAsyncAwait() async throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)
        try await app.emailPasswordAuth.registerUser(email: email, password: password)

        let credentials = Credentials.emailPassword(email: email, password: password)
        let syncUser = try await self.app.login(credentials: credentials)
        let apiKey = try await syncUser.apiKeysAuth.createAPIKey(named: "my-api-key")
        XCTAssertNotNil(apiKey)

        let fetchedApiKey = try await syncUser.apiKeysAuth.fetchAPIKey(apiKey.objectId)
        XCTAssertNotNil(fetchedApiKey)

        let fetchedApiKeys = try await syncUser.apiKeysAuth.fetchAPIKeys()
        XCTAssertNotNil(fetchedApiKeys)
        XCTAssertEqual(fetchedApiKeys.count, 1)

        try await syncUser.apiKeysAuth.disableAPIKey(apiKey.objectId)
        try await syncUser.apiKeysAuth.enableAPIKey(apiKey.objectId)
        try await syncUser.apiKeysAuth.deleteAPIKey(apiKey.objectId)

        let newFetchedApiKeys = try await syncUser.apiKeysAuth.fetchAPIKeys()
        XCTAssertNotNil(newFetchedApiKeys)
        XCTAssertEqual(newFetchedApiKeys.count, 0)
    }

    func testCustomUserDataAsyncAwait() async throws {
        let user = try await createUser()
        _ = try await user.functions.updateUserData(["favourite_colour": "green", "apples": 10])

        try await user.refreshCustomData()
        XCTAssertEqual(user.customData["favourite_colour"], .string("green"))
        XCTAssertEqual(user.customData["apples"], .int64(10))
    }

    func testDeleteUserAsyncAwait() async throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)
        let credentials: Credentials = .emailPassword(email: email, password: password)
        try await app.emailPasswordAuth.registerUser(email: email, password: password)

        let user = try await self.app.login(credentials: credentials)

        XCTAssertNotNil(app.currentUser)
        try await user.delete()

        XCTAssertNil(app.currentUser)
        XCTAssertEqual(app.allUsers.count, 0)
    }

    @MainActor
    func testSwiftAddObjectsAsync() async throws {
        let realm = try await openRealm()
        checkCount(expected: 0, realm, SwiftPerson.self)
        checkCount(expected: 0, realm, SwiftTypesSyncObject.self)

        try await write { realm in
            realm.add(SwiftPerson(firstName: "Ringo", lastName: "Starr"))
            realm.add(SwiftPerson(firstName: "John", lastName: "Lennon"))
            realm.add(SwiftPerson(firstName: "Paul", lastName: "McCartney"))
            realm.add(SwiftTypesSyncObject(person: SwiftPerson(firstName: "George", lastName: "Harrison")))
        }

        try await realm.syncSession?.wait(for: .download)
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
}

@available(macOS 13, *)
class AsyncFlexibleSyncTests: SwiftSyncTestCase {
    override class var defaultTestSuite: XCTestSuite {
        // async/await is currently incompatible with thread sanitizer and will
        // produce many false positives
        // https://bugs.swift.org/browse/SR-15444
        if RLMThreadSanitizerEnabled() || true {
            return XCTestSuite(name: "\(type(of: self))")
        }
        return super.defaultTestSuite
    }

    override var objectTypes: [ObjectBase.Type] {
        [SwiftCustomColumnObject.self, SwiftPerson.self, SwiftTypesSyncObject.self]
    }

    override func configuration(user: User) -> Realm.Configuration {
        user.flexibleSyncConfiguration()
    }

    override func createApp() throws -> String {
        try createFlexibleSyncApp()
    }

    @MainActor
    func populateSwiftPerson(_ count: Int = 10) async throws {
        try await write { realm in
            for i in 1...count {
                let person = SwiftPerson(firstName: "\(self.name)",
                                         lastName: "lastname_\(i)",
                                         age: i)
                realm.add(person)
            }
        }
    }

    @MainActor
    func testFlexibleSyncAppAddQueryAsyncAwait() async throws {
        try await populateSwiftPerson(25)

        let realm = try await openRealm()
        checkCount(expected: 0, realm, SwiftPerson.self)

        let subscriptions = realm.subscriptions
        XCTAssertEqual(subscriptions.count, 0)

        try await subscriptions.update {
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_15") {
                $0.age > 15 && $0.firstName == "\(name)"
            })
        }
        XCTAssertEqual(subscriptions.state, .complete)
        XCTAssertEqual(subscriptions.count, 1)

        checkCount(expected: 10, realm, SwiftPerson.self)
    }

    @MainActor
    func testFlexibleSyncInitInMemory() async throws {
        try await populateSwiftPerson(5)

        let user = try await createUser()
        let name = self.name
        try await Task {
            var config = user.flexibleSyncConfiguration(initialSubscriptions: { subs in
                subs.append(QuerySubscription<SwiftPerson> {
                    $0.age > 0 && $0.firstName == name
                })
            })
            config.objectTypes = [SwiftPerson.self]
            config.inMemoryIdentifier = "identifier"
            let inMemoryRealm = try await Realm(configuration: config, downloadBeforeOpen: .always)
            XCTAssertEqual(inMemoryRealm.objects(SwiftPerson.self).count, 5)
            try! inMemoryRealm.write {
                let person = SwiftPerson(firstName: self.name,
                                         lastName: "lastname_10",
                                         age: 10)
                inMemoryRealm.add(person)
            }
            XCTAssertEqual(inMemoryRealm.objects(SwiftPerson.self).count, 6)
            try await inMemoryRealm.syncSession?.wait(for: .upload)
        }.value

        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subs in
            subs.append(QuerySubscription<SwiftPerson> {
                $0.age > 5 && $0.firstName == name
            })
        })
        config.objectTypes = [SwiftPerson.self]
        config.inMemoryIdentifier = "identifier"
        let inMemoryRealm = try await Realm(configuration: config, downloadBeforeOpen: .always)
        XCTAssertEqual(inMemoryRealm.objects(SwiftPerson.self).count, 1)

        var config2 = user.flexibleSyncConfiguration(initialSubscriptions: { subs in
            subs.append(QuerySubscription<SwiftPerson> {
                $0.age > 0 && $0.firstName == name
            })
        })
        config2.objectTypes = [SwiftPerson.self]
        config2.inMemoryIdentifier = "identifier2"
        let inMemoryRealm2 = try await Realm(configuration: config2, downloadBeforeOpen: .always)
        XCTAssertEqual(inMemoryRealm2.objects(SwiftPerson.self).count, 6)
    }

    @MainActor
    func testStates() async throws {
        let realm = try await openRealm()
        let subscriptions = realm.subscriptions
        XCTAssertEqual(subscriptions.count, 0)

        // should complete
        try await subscriptions.update {
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_15") {
                $0.age > 15 && $0.firstName == "\(name)"
            })
        }
        XCTAssertEqual(subscriptions.state, .complete)
        // should error
        do {
            try await subscriptions.update {
                subscriptions.append(QuerySubscription<SwiftTypesSyncObject>(name: "swiftObject_longCol") {
                    $0.longCol == Int64(1)
                })
            }
            XCTFail("Invalid query should have failed")
        } catch Realm.Error.subscriptionFailed {
            guard case .error = subscriptions.state else {
                return XCTFail("Adding a query for a not queryable field should change the subscription set state to error")
            }
        }
    }

    @MainActor
    func testFlexibleSyncNotInitialSubscriptions() async throws {
        let realm = try await openRealm()
        XCTAssertEqual(realm.subscriptions.count, 0)
    }

    @MainActor
    func testFlexibleSyncInitialSubscriptionsAsync() async throws {
        try await write { realm in
            for i in 1...20 {
                realm.add(SwiftPerson(firstName: "\(self.name)",
                                      lastName: "lastname_\(i)",
                                      age: i))
            }
        }

        let user = try await createUser()
        let name = self.name
        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_10") {
                $0.age > 10 && $0.firstName == "\(name)"
            })
        })
        config.objectTypes = [SwiftPerson.self]

        XCTAssertNotNil(config.syncConfiguration?.initialSubscriptions)
        XCTAssertNotNil(config.syncConfiguration?.initialSubscriptions?.callback)
        XCTAssertEqual(config.syncConfiguration?.initialSubscriptions?.rerunOnOpen, false)

        let realm = try await Realm(configuration: config, downloadBeforeOpen: .once)
        XCTAssertEqual(realm.subscriptions.count, 1)
        checkCount(expected: 10, realm, SwiftPerson.self)
    }

    @MainActor
    func testFlexibleSyncInitialSubscriptionsNotRerunOnOpen() async throws {
        let name = self.name
        let user = try await createUser()
        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_10") {
                $0.age > 10 && $0.firstName == "\(name)"
            })
        })
        config.objectTypes = [SwiftPerson.self]
        let realm = try await Realm(configuration: config, downloadBeforeOpen: .once)
        XCTAssertEqual(realm.subscriptions.count, 1)

        let realm2 = try await Realm(configuration: config, downloadBeforeOpen: .once)
        XCTAssertNotNil(realm2)
        XCTAssertEqual(realm.subscriptions.count, 1)
    }

    @MainActor
    func testFlexibleSyncInitialSubscriptionsRerunOnOpenNamedQuery() async throws {
        let user = try await createUser()
        let name = self.name
        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            if subscriptions.first(named: "person_age_10") == nil {
                subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_10") {
                    $0.age > 20 && $0.firstName == "\(name)"
                })
            }
        }, rerunOnOpen: true)
        config.objectTypes = [SwiftPerson.self]

        XCTAssertNotNil(config.syncConfiguration?.initialSubscriptions)
        XCTAssertNotNil(config.syncConfiguration?.initialSubscriptions?.callback)
        XCTAssertEqual(config.syncConfiguration?.initialSubscriptions?.rerunOnOpen, false)

        try await Task {
            let realm = try await Realm(configuration: config, downloadBeforeOpen: .once)
            XCTAssertEqual(realm.subscriptions.count, 1)
        }.value

        try await Task {
            let realm2 = try await Realm(configuration: config, downloadBeforeOpen: .once)
            XCTAssertNotNil(realm2)
            XCTAssertEqual(realm2.subscriptions.count, 1)
        }.value
    }

    @MainActor
    func testFlexibleSyncInitialSubscriptionsRerunOnOpenUnnamedQuery() async throws {
        try await write { realm in
            for i in 1...30 {
                let object = SwiftTypesSyncObject()
                object.stringCol = self.name
                object.dateCol = Calendar.current.date(
                    byAdding: .hour,
                    value: -i,
                    to: Date())!
                realm.add(object)
            }
        }

        let user = try await createUser()
        let isFirstOpen = Locked(true)
        let name = self.name
        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            subscriptions.append(QuerySubscription<SwiftTypesSyncObject>(query: {
                let date = isFirstOpen.wrappedValue ? Calendar.current.date(
                    byAdding: .hour,
                    value: -10,
                    to: Date()) : Calendar.current.date(
                        byAdding: .hour,
                        value: -20,
                        to: Date())
                isFirstOpen.wrappedValue = false
                return $0.stringCol == name && $0.dateCol < Date() && $0.dateCol > date!
            }))
        }, rerunOnOpen: true)
        config.objectTypes = [SwiftTypesSyncObject.self, SwiftPerson.self]
        let c = config
        try await Task {
            let realm = try await Realm(configuration: c, downloadBeforeOpen: .always)
            XCTAssertEqual(realm.subscriptions.count, 1)
            checkCount(expected: 9, realm, SwiftTypesSyncObject.self)
        }.value

        try await Task {
            let realm = try await Realm(configuration: c, downloadBeforeOpen: .always)
            XCTAssertEqual(realm.subscriptions.count, 2)
            checkCount(expected: 19, realm, SwiftTypesSyncObject.self)
        }.value
    }

    @MainActor
    func testFlexibleSyncInitialSubscriptionsThrows() async throws {
        let user = try await createUser()
        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            subscriptions.append(QuerySubscription<SwiftTypesSyncObject>(query: {
                $0.uuidCol == UUID()
            }))
        })
        config.objectTypes = [SwiftTypesSyncObject.self, SwiftPerson.self]
        do {
           _ = try await Realm(configuration: config, downloadBeforeOpen: .once)
        } catch let error as Realm.Error {
            XCTAssertEqual(error.code, .subscriptionFailed)
        }
    }

    @MainActor
    func testFlexibleSyncInitialSubscriptionsDefaultConfiguration() async throws {
        let user = try await createUser()
        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            subscriptions.append(QuerySubscription<SwiftTypesSyncObject>())
        })
        config.objectTypes = [SwiftTypesSyncObject.self, SwiftPerson.self]
        Realm.Configuration.defaultConfiguration = config

        let realm = try await Realm(downloadBeforeOpen: .once)
        XCTAssertEqual(realm.subscriptions.count, 1)
    }

    // MARK: Subscribe

    @MainActor
    func testSubscribe() async throws {
        try await populateSwiftPerson()

        let realm = try await openRealm()
        let results0 = try await realm.objects(SwiftPerson.self).where { $0.age >= 6 }.subscribe()
        XCTAssertEqual(results0.count, 5)
        XCTAssertEqual(realm.subscriptions.count, 1)
        let results1 = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == self.name && $0.lastName == "lastname_3" }
            .subscribe()
        XCTAssertEqual(results1.count, 1)
        XCTAssertEqual(results0.count, 5)
        XCTAssertEqual(realm.subscriptions.count, 2)
        let results2 = realm.objects(SwiftPerson.self)
        XCTAssertEqual(results2.count, 6)
    }

    @MainActor
    func testSubscribeReassign() async throws {
        try await populateSwiftPerson()
        let realm = try await openRealm()

        var results0 = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == self.name && $0.age >= 8 }
            .subscribe()
        XCTAssertEqual(results0.count, 3)
        XCTAssertEqual(realm.subscriptions.count, 1)
        // results0 local query is { $0.age >= 8 AND $0.age < 8 }
        results0 = try await results0.where { $0.age < 8 }.subscribe()
        XCTAssertEqual(results0.count, 0) // no matches because local query is impossible
        // two subscriptions: "$0.age >= 8 AND $0.age < 8" and "$0.age >= 8"
        XCTAssertEqual(realm.subscriptions.count, 2)
        let results1 = realm.objects(SwiftPerson.self)
        XCTAssertEqual(results1.count, 3) // three objects from "$0.age >= 8". None "$0.age >= 8 AND $0.age < 8".
    }

    @MainActor
    func testSubscribeSameQueryNoName() async throws {
        try await populateSwiftPerson()
        let realm = try await openRealm()

        let results0 = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age >= 8 }
            .subscribe()
        let ex = XCTestExpectation(description: "no attempt to re-create subscription, returns immediately")
        realm.syncSession!.suspend()
        let task = Task {
            _ = try await realm.objects(SwiftPerson.self)
                .where { $0.firstName == name && $0.age >= 8 }.subscribe()
            _ = try await results0.subscribe()
            ex.fulfill()
        }
        await fulfillment(of: [ex], timeout: 1.0)
        try await task.value
        XCTAssertEqual(realm.subscriptions.count, 1)
    }

    @MainActor
    func testSubscribeSameQuerySameName() async throws {
        try await populateSwiftPerson()
        let realm = try await openRealm()

        let results0 = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age >= 8 }
            .subscribe(name: "8 or older")
        realm.syncSession!.suspend()
        let ex = XCTestExpectation(description: "no attempt to re-create subscription, returns immediately")
        Task { @MainActor in
            _ = try await realm.objects(SwiftPerson.self)
                .where { $0.firstName == name && $0.age >= 8 }
                .subscribe(name: "8 or older")
            _ = try await results0.subscribe(name: "8 or older")
            XCTAssertEqual(realm.subscriptions.count, 1)
            ex.fulfill()
        }
        await fulfillment(of: [ex], timeout: 5.0)
        XCTAssertEqual(realm.subscriptions.count, 1)
    }

    @MainActor
    func testSubscribeSameQueryDifferentName() async throws {
        try await populateSwiftPerson()
        let realm = try await openRealm()

        let results0 = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age >= 8 }.subscribe()
        _ = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age >= 8 }.subscribe(name: "8 or older")
        _ = try await results0.subscribe(name: "older than 7")
        XCTAssertEqual(realm.subscriptions.count, 3)
        let subscriptions = realm.subscriptions
        XCTAssertNil(subscriptions[0]!.name)
        XCTAssertEqual(subscriptions[1]!.name, "8 or older")
        XCTAssertEqual(subscriptions[2]!.name, "older than 7")
    }

    @MainActor
    func testSubscribeDifferentQuerySameName() async throws {
        try await populateSwiftPerson()
        let realm = try await openRealm()

        _ = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age > 8 }.subscribe(name: "group1")
        _ = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age > 5 }.subscribe(name: "group1")
        XCTAssertEqual(realm.subscriptions.count, 1)
        XCTAssertNotNil(realm.subscriptions.first(ofType: SwiftPerson.self) { $0.firstName == name && $0.age > 5 })
    }

    @MainActor
    func testSubscribeOnRealmConfinedActor() async throws {
        try await populateSwiftPerson()
        try await populateSwiftPerson()

        let user = try await createUser()
        var config = user.flexibleSyncConfiguration()
        config.objectTypes = [SwiftPerson.self]
        let realm = try await Realm(configuration: config)
        let results1 = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age > 8 }.subscribe(waitForSync: .onCreation)
        XCTAssertEqual(results1.count, 2)
        let results2 = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age > 6 }.subscribe(waitForSync: .always)
        XCTAssertEqual(results2.count, 4)
        let results3 = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age > 4 }.subscribe(waitForSync: .never)
        XCTAssertEqual(results3.count, 4)
        XCTAssertEqual(realm.subscriptions.count, 3)
    }

    @CustomGlobalActor
    func testSubscribeOnRealmConfinedCustomActor() async throws {
        nonisolated(unsafe) let unsafeSelf = self
        try await unsafeSelf.populateSwiftPerson()

        let user = try await createUser()
        var config = user.flexibleSyncConfiguration()
        config.objectTypes = [SwiftPerson.self]
#if compiler(<6)
        let realm = try await Realm(configuration: config, actor: CustomGlobalActor.shared)
#else
        let realm = try await Realm.open(configuration: config)
#endif
        let name = self.name
        let results1 = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age > 8 }.subscribe(waitForSync: .onCreation)
        XCTAssertEqual(results1.count, 2)
        let results2 = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age > 6 }.subscribe(waitForSync: .always)
        XCTAssertEqual(results2.count, 4)
        let results3 = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age > 4 }.subscribe(waitForSync: .never)
        XCTAssertEqual(results3.count, 4)
        XCTAssertEqual(realm.subscriptions.count, 3)
    }

    @MainActor
    func testUnsubscribe() async throws {
        try await populateSwiftPerson()
        let realm = try await openRealm()

        let results1 = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.lastName == "lastname_3" }.subscribe()
        XCTAssertEqual(realm.subscriptions.count, 1)
        results1.unsubscribe()
        XCTAssertEqual(realm.subscriptions.count, 0)
    }

    @MainActor
    func testUnsubscribeAfterReassign() async throws {
        try await populateSwiftPerson()
        let realm = try await openRealm()

        var results0 = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age >= 8 }.subscribe()
        XCTAssertEqual(results0.count, 3)
        XCTAssertEqual(realm.subscriptions.count, 1)
        results0 = try await results0
            .where { $0.firstName == name && $0.age < 8 }.subscribe() // subscribes to "age >= 8 && age < 8" because that's the local query
        XCTAssertEqual(results0.count, 0)
        XCTAssertEqual(realm.subscriptions.count, 2) // Two subs present:1) "age >= 8" 2) "age >= 8 && age < 8"
        let results1 = realm.objects(SwiftPerson.self)
        XCTAssertEqual(results1.count, 3)
        results0.unsubscribe() // unsubscribes from "age >= 8 && age < 8"
        XCTAssertEqual(realm.subscriptions.count, 1)
        XCTAssertNotNil(realm.subscriptions.first(ofType: SwiftPerson.self) { $0.firstName == name && $0.age >= 8 })
        XCTAssertEqual(results0.count, 0) // local query is still "age >= 8 && age < 8".
        XCTAssertEqual(results1.count, 3)
    }

    @MainActor
    func testUnsubscribeWithoutSubscriptionExistingNamed() async throws {
        try await populateSwiftPerson()
        let realm = try await openRealm()

        _ = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age >= 8 }.subscribe(name: "sub1")
        XCTAssertEqual(realm.subscriptions.count, 1)
        let results = realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age >= 8 }
        results.unsubscribe()
        XCTAssertEqual(realm.subscriptions.count, 1)
        XCTAssertEqual(realm.subscriptions.first!.name, "sub1")
    }

    @MainActor
    func testUnsubscribeNoExistingMatch() async throws {
        try await populateSwiftPerson()
        let realm = try await openRealm()

        XCTAssertEqual(realm.subscriptions.count, 0)
        _ = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age >= 8 }.subscribe(name: "age_older_8")
        let results0 = realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age >= 8 }
        XCTAssertEqual(realm.subscriptions.count, 1)
        XCTAssertEqual(results0.count, 3)
        results0.unsubscribe()
        XCTAssertEqual(realm.subscriptions.count, 1)
        XCTAssertEqual(results0.count, 3) // Results are not modified because there is no subscription associated to the unsubscribed result
    }

    @MainActor
    func testUnsubscribeNamed() async throws {
        try await populateSwiftPerson()
        let realm = try await openRealm()

        _ = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age >= 8 }.subscribe()
        _ = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age >= 8 }.subscribe(name: "first_named")
        let results = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age >= 8 }.subscribe(name: "second_named")
        XCTAssertEqual(realm.subscriptions.count, 3)

        results.unsubscribe()
        XCTAssertEqual(realm.subscriptions.count, 2)
        XCTAssertEqual(realm.subscriptions[0]!.name, nil)
        XCTAssertEqual(realm.subscriptions[1]!.name, "first_named")
        results.unsubscribe() // check again for case when subscription doesn't exist
        XCTAssertEqual(realm.subscriptions.count, 2)
        XCTAssertEqual(realm.subscriptions[0]!.name, nil)
        XCTAssertEqual(realm.subscriptions[1]!.name, "first_named")
    }

    @MainActor
    func testUnsubscribeReassign() async throws {
        try await populateSwiftPerson()
        let realm = try await openRealm()

        _ = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age >= 8 }.subscribe(name: "first_named")
        var results = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age >= 8 }.subscribe(name: "second_named")
        // expect `results` associated subscription to be reassigned to the id which matches the unnamed subscription
        results = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age >= 8 }.subscribe()
        XCTAssertEqual(realm.subscriptions.count, 3)

        results.unsubscribe()
        // so the two named subscriptions remain.
        XCTAssertEqual(realm.subscriptions.count, 2)
        XCTAssertEqual(realm.subscriptions[0]!.name, "first_named")
        XCTAssertEqual(realm.subscriptions[1]!.name, "second_named")
    }

    @MainActor
    func testUnsubscribeSameQueryDifferentName() async throws {
        try await populateSwiftPerson()
        let realm = try await openRealm()

        _ = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age >= 8 }.subscribe()
        let results2 = realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age >= 8 }
        XCTAssertEqual(realm.subscriptions.count, 1)
        results2.unsubscribe()
        XCTAssertEqual(realm.subscriptions.count, 0)
    }

    @MainActor
    func testSubscribeNameAcrossTypes() async throws {
        try await populateSwiftPerson()
        let realm = try await openRealm()

        let results = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age >= 8 }.subscribe(name: "sameName")
        XCTAssertEqual(realm.subscriptions.count, 1)
        XCTAssertEqual(results.count, 3)
        _ = try await realm.objects(SwiftTypesSyncObject.self).subscribe(name: "sameName")
        XCTAssertEqual(realm.subscriptions.count, 1)
        XCTAssertEqual(results.count, 0)
    }

    @MainActor
    func testSubscribeOnCreation() async throws {
        try await populateSwiftPerson()
        let realm = try await openRealm()

        var results = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age >= 8 }.subscribe(waitForSync: .onCreation)
        XCTAssertEqual(results.count, 3)
        let expectation = XCTestExpectation(description: "method doesn't hang")
        realm.syncSession!.suspend()
        let task = Task {
            results = try await realm.objects(SwiftPerson.self)
                .where { $0.firstName == name && $0.age >= 8 }
                .subscribe(waitForSync: .onCreation)
            XCTAssertEqual(results.count, 3) // expect method to return immediately, and not hang while no connection
            XCTAssertEqual(realm.subscriptions.count, 1)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2.0)
        try await task.value
    }

    @MainActor
    func testSubscribeAlways() async throws {
        let collection = anonymousUser.collection(for: SwiftPerson.self, app: app)
        try await populateSwiftPerson()
        let realm = try await openRealm()

        var results = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age >= 9 }.subscribe(waitForSync: .always)
        XCTAssertEqual(results.count, 2)

        // suspend session on client. Add a document that isn't on the client.
        realm.syncSession!.suspend()
        let serverObject: Document = [
            "_id": .objectId(ObjectId.generate()),
            "firstName": .string(name),
            "lastName": .string("M"),
            "age": .int32(30)
        ]
        collection.insertOne(serverObject).await(self, timeout: 10.0)

        // Resume the client session.
        realm.syncSession!.resume()
        XCTAssertEqual(results.count, 2)
        results = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age >= 9 }.subscribe(waitForSync: .always)
        // Expect this subscribe call to wait for sync downloads, even though the subscription already existed
        XCTAssertEqual(results.count, 3) // Count is 3 because it includes the object/document that was created while offline.
        XCTAssertEqual(realm.subscriptions.count, 1)
    }

    @MainActor
    func testSubscribeNever() async throws {
        try await populateSwiftPerson()
        let realm = try await openRealm()

        let expectation = XCTestExpectation(description: "test doesn't hang")
        Task {
            let results = try await realm.objects(SwiftPerson.self)
                .where { $0.firstName == name && $0.age >= 8 }.subscribe(waitForSync: .never)
            XCTAssertEqual(results.count, 0) // expect no objects to be able to sync because of immediate return
            XCTAssertEqual(realm.subscriptions.count, 1)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1)
    }

    @MainActor
    func testSubscribeTimeout() async throws {
        try await populateSwiftPerson()
        let realm = try await openRealm()

        realm.syncSession!.suspend()
        let timeout = 1.0
        do {
            _ = try await realm.objects(SwiftPerson.self)
                .where { $0.firstName == name && $0.age >= 8 }
                .subscribe(waitForSync: .always, timeout: timeout)
            XCTFail("subscribe did not time out")
        } catch let error as NSError {
            XCTAssertEqual(error.code, Int(ETIMEDOUT))
            XCTAssertEqual(error.domain, NSPOSIXErrorDomain)
            XCTAssertEqual(error.localizedDescription, "Waiting for update timed out after \(timeout) seconds.")
        }
    }

    @MainActor
    func testSubscribeTimeoutSucceeds() async throws {
        try await populateSwiftPerson()

        let realm = try await openRealm()
        let results0 = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.age >= 6 }.subscribe(timeout: 2.0)
        XCTAssertEqual(results0.count, 5)
        XCTAssertEqual(realm.subscriptions.count, 1)
        let results1 = try await realm.objects(SwiftPerson.self)
            .where { $0.firstName == name && $0.lastName == "lastname_3" }.subscribe(timeout: 2.0)
        XCTAssertEqual(results1.count, 1)
        XCTAssertEqual(results0.count, 5)
        XCTAssertEqual(realm.subscriptions.count, 2)

        let results2 = realm.objects(SwiftPerson.self)
        XCTAssertEqual(results2.count, 6)
    }

    // MARK: - Custom Column

    @MainActor
    func testCustomColumnFlexibleSyncSchema() throws {
        let realm = try openRealm()
        for property in realm.schema.objectSchema.first(where: { $0.className == "SwiftCustomColumnObject" })!.properties {
            XCTAssertEqual(customColumnPropertiesMapping[property.name], property.columnName)
        }
    }

    @MainActor
    func testCreateCustomColumnFlexibleSyncSubscription() async throws {
        let objectId = ObjectId.generate()
        try await write { realm in
            let valuesDictionary: [String: Any] = ["id": objectId,
                                                   "boolCol": true,
                                                   "intCol": 365,
                                                   "doubleCol": 365.365,
                                                   "stringCol": "@#¢∞¬÷÷",
                                                   "binaryCol": Data("string".utf8),
                                                   "dateCol": Date(timeIntervalSince1970: -365),
                                                   "longCol": 365,
                                                   "decimalCol": Decimal128(365),
                                                   "uuidCol": UUID(uuidString: "629bba42-97dc-4fee-97ff-78af054952ec")!,
                                                   "objectIdCol": ObjectId.generate()]

            realm.create(SwiftCustomColumnObject.self, value: valuesDictionary)
        }

        let user = try await createUser()
        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            subscriptions.append(QuerySubscription<SwiftCustomColumnObject>())
        })
        config.objectTypes = [SwiftCustomColumnObject.self]
        let realm = try await Realm(configuration: config, downloadBeforeOpen: .once)
        XCTAssertEqual(realm.subscriptions.count, 1)

        let foundObject = realm.object(ofType: SwiftCustomColumnObject.self, forPrimaryKey: objectId)
        XCTAssertNotNil(foundObject)
        XCTAssertEqual(foundObject!.id, objectId)
        XCTAssertEqual(foundObject!.boolCol, true)
        XCTAssertEqual(foundObject!.intCol, 365)
        XCTAssertEqual(foundObject!.doubleCol, 365.365)
        XCTAssertEqual(foundObject!.stringCol, "@#¢∞¬÷÷")
        XCTAssertEqual(foundObject!.binaryCol, Data("string".utf8))
        XCTAssertEqual(foundObject!.dateCol, Date(timeIntervalSince1970: -365))
        XCTAssertEqual(foundObject!.longCol, 365)
        XCTAssertEqual(foundObject!.decimalCol, Decimal128(365))
        XCTAssertEqual(foundObject!.uuidCol, UUID(uuidString: "629bba42-97dc-4fee-97ff-78af054952ec")!)
        XCTAssertNotNil(foundObject?.objectIdCol)
        XCTAssertNil(foundObject?.objectCol)
    }

    @MainActor
    func testCustomColumnFlexibleSyncSubscriptionNSPredicate() async throws {
        let objectId = ObjectId.generate()
        let linkedObjectId = ObjectId.generate()
        try await write { realm in
            let object = SwiftCustomColumnObject()
            object.id = objectId
            object.binaryCol = Data("string".utf8)
            let linkedObject = SwiftCustomColumnObject()
            linkedObject.id = linkedObjectId
            object.objectCol = linkedObject
            realm.add(object)
        }
        let user = try await createUser()

        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            subscriptions.append(QuerySubscription<SwiftCustomColumnObject>(where: NSPredicate(format: "id == %@ || id == %@", objectId, linkedObjectId)))
        })
        config.objectTypes = [SwiftCustomColumnObject.self]
        let realm = try await Realm(configuration: config, downloadBeforeOpen: .once)
        XCTAssertEqual(realm.subscriptions.count, 1)
        checkCount(expected: 2, realm, SwiftCustomColumnObject.self)

        let foundObject = realm.objects(SwiftCustomColumnObject.self).where { $0.id == objectId }.first
        XCTAssertNotNil(foundObject)
        XCTAssertEqual(foundObject!.id, objectId)
        XCTAssertEqual(foundObject!.boolCol, true)
        XCTAssertEqual(foundObject!.intCol, 1)
        XCTAssertEqual(foundObject!.doubleCol, 1.1)
        XCTAssertEqual(foundObject!.stringCol, "string")
        XCTAssertEqual(foundObject!.binaryCol, Data("string".utf8))
        XCTAssertEqual(foundObject!.dateCol, Date(timeIntervalSince1970: -1))
        XCTAssertEqual(foundObject!.longCol, 1)
        XCTAssertEqual(foundObject!.decimalCol, Decimal128(1))
        XCTAssertEqual(foundObject!.uuidCol, UUID(uuidString: "85d4fbee-6ec6-47df-bfa1-615931903d7e")!)
        XCTAssertNil(foundObject?.objectIdCol)
        XCTAssertEqual(foundObject!.objectCol!.id, linkedObjectId)
    }

    @MainActor
    func testCustomColumnFlexibleSyncSubscriptionFilter() async throws {
        let objectId = ObjectId.generate()
        let linkedObjectId = ObjectId.generate()
        try await write { realm in
            let object = SwiftCustomColumnObject()
            object.id = objectId
            object.binaryCol = Data("string".utf8)
            let linkedObject = SwiftCustomColumnObject()
            linkedObject.id = linkedObjectId
            object.objectCol = linkedObject
            realm.add(object)
        }
        let user = try await createUser()

        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            subscriptions.append(QuerySubscription<SwiftCustomColumnObject>(where: "id == %@ || id == %@", objectId, linkedObjectId))
        })
        config.objectTypes = [SwiftCustomColumnObject.self]
        let realm = try await Realm(configuration: config, downloadBeforeOpen: .once)
        XCTAssertEqual(realm.subscriptions.count, 1)
        checkCount(expected: 2, realm, SwiftCustomColumnObject.self)

        let foundObject = realm.objects(SwiftCustomColumnObject.self).where { $0.id == objectId }.first
        XCTAssertNotNil(foundObject)
        XCTAssertEqual(foundObject!.id, objectId)
        XCTAssertEqual(foundObject!.boolCol, true)
        XCTAssertEqual(foundObject!.intCol, 1)
        XCTAssertEqual(foundObject!.doubleCol, 1.1)
        XCTAssertEqual(foundObject!.stringCol, "string")
        XCTAssertEqual(foundObject!.binaryCol, Data("string".utf8))
        XCTAssertEqual(foundObject!.dateCol, Date(timeIntervalSince1970: -1))
        XCTAssertEqual(foundObject!.longCol, 1)
        XCTAssertEqual(foundObject!.decimalCol, Decimal128(1))
        XCTAssertEqual(foundObject!.uuidCol, UUID(uuidString: "85d4fbee-6ec6-47df-bfa1-615931903d7e")!)
        XCTAssertNil(foundObject?.objectIdCol)
        XCTAssertEqual(foundObject!.objectCol!.id, linkedObjectId)
    }

    @MainActor
    func testCustomColumnFlexibleSyncSubscriptionQuery() async throws {
        let objectId = ObjectId.generate()
        let linkedObjectId = ObjectId.generate()
        try await write { realm in
            let object = SwiftCustomColumnObject()
            object.id = objectId
            object.binaryCol = Data("string".utf8)
            let linkedObject = SwiftCustomColumnObject()
            linkedObject.id = linkedObjectId
            object.objectCol = linkedObject
            realm.add(object)
        }
        let user = try await createUser()

        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            subscriptions.append(QuerySubscription<SwiftCustomColumnObject> {
                $0.id == objectId || $0.id == linkedObjectId
            })
        })
        config.objectTypes = [SwiftCustomColumnObject.self]
        let realm = try await Realm(configuration: config, downloadBeforeOpen: .once)
        XCTAssertEqual(realm.subscriptions.count, 1)
        checkCount(expected: 2, realm, SwiftCustomColumnObject.self)

        let foundObject = realm.objects(SwiftCustomColumnObject.self).where { $0.id == objectId }.first

        XCTAssertNotNil(foundObject)
        XCTAssertEqual(foundObject!.id, objectId)
        XCTAssertEqual(foundObject!.boolCol, true)
        XCTAssertEqual(foundObject!.intCol, 1)
        XCTAssertEqual(foundObject!.doubleCol, 1.1)
        XCTAssertEqual(foundObject!.stringCol, "string")
        XCTAssertEqual(foundObject!.binaryCol, Data("string".utf8))
        XCTAssertEqual(foundObject!.dateCol, Date(timeIntervalSince1970: -1))
        XCTAssertEqual(foundObject!.longCol, 1)
        XCTAssertEqual(foundObject!.decimalCol, Decimal128(1))
        XCTAssertEqual(foundObject!.uuidCol, UUID(uuidString: "85d4fbee-6ec6-47df-bfa1-615931903d7e")!)
        XCTAssertNil(foundObject?.objectIdCol)
        XCTAssertEqual(foundObject!.objectCol!.id, linkedObjectId)
    }
}

@available(macOS 13, *)
@globalActor actor CustomGlobalActor: GlobalActor {
    static let shared = CustomGlobalActor()
}

#endif // os(macOS) && swift(>=5.8)
