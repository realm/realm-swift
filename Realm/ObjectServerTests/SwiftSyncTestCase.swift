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
import XCTest
import RealmSwift

#if canImport(RealmTestSupport)
import RealmTestSupport
import RealmSyncTestSupport
import RealmSwiftTestSupport
#endif

public extension User {
    func configuration<T: BSON>(testName: T) -> Realm.Configuration {
        var config = self.configuration(partitionValue: testName)
        config.objectTypes = [SwiftPerson.self, SwiftHugeSyncObject.self, SwiftTypesSyncObject.self, SwiftCustomColumnObject.self]
        return config
    }
}

public func randomString(_ length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).map { _ in letters.randomElement()! })
}

public typealias ChildProcessEnvironment = RLMChildProcessEnvironment

public enum ProcessKind {
    case parent
    case child(environment: ChildProcessEnvironment)

    public static var current: ProcessKind {
        if getenv("RLMProcessIsChild") == nil {
            return .parent
        } else {
            return .child(environment: ChildProcessEnvironment.current())
        }
    }
}

@available(macOS 10.15, *)
@MainActor
open class SwiftSyncTestCase: RLMSyncTestCase {
    public func executeChild(file: StaticString = #file, line: UInt = #line) {
        XCTAssert(0 == runChildAndWait(), "Tests in child process failed", file: file, line: line)
    }

    public func basicCredentials(usernameSuffix: String = "", app: App? = nil) -> Credentials {
        let email = "\(randomString(10))\(usernameSuffix)"
        let password = "abcdef"
        let credentials = Credentials.emailPassword(email: email, password: password)
        let ex = expectation(description: "Should register in the user properly")
        (app ?? self.app).emailPasswordAuth.registerUser(email: email, password: password, completion: { error in
            XCTAssertNil(error)
            ex.fulfill()
        })
        waitForExpectations(timeout: 40, handler: nil)
        return credentials
    }

    public func openRealm(partitionValue: AnyBSON, user: User) throws -> Realm {
        let config = user.configuration(partitionValue: partitionValue)
        return try openRealm(configuration: config)
    }

    public func openRealm<T: BSON>(partitionValue: T,
                                   user: User,
                                   clientResetMode: ClientResetMode? = .recoverUnsyncedChanges(),
                                   file: StaticString = #file,
                                   line: UInt = #line) throws -> Realm {
        let config: Realm.Configuration
        if clientResetMode != nil {
            config = user.configuration(partitionValue: partitionValue, clientResetMode: clientResetMode!)
        } else {
            config = user.configuration(partitionValue: partitionValue)
        }
        return try openRealm(configuration: config)
    }

    public func openRealm(configuration: Realm.Configuration) throws -> Realm {
        var configuration = configuration
        if configuration.objectTypes == nil {
            configuration.objectTypes = [SwiftPerson.self,
                                         SwiftHugeSyncObject.self,
                                         SwiftCollectionSyncObject.self,
                                         SwiftUUIDPrimaryKeyObject.self,
                                         SwiftStringPrimaryKeyObject.self,
                                         SwiftIntPrimaryKeyObject.self,
                                         SwiftTypesSyncObject.self]
        }
        let realm = try Realm(configuration: configuration)
        waitForDownloads(for: realm)
        return realm
    }

    public func immediatelyOpenRealm(partitionValue: String, user: User) throws -> Realm {
        var configuration = user.configuration(partitionValue: partitionValue)
        if configuration.objectTypes == nil {
            configuration.objectTypes = [SwiftPerson.self,
                                         SwiftHugeSyncObject.self,
                                         SwiftTypesSyncObject.self]
        }
        return try Realm(configuration: configuration)
    }

    open func logInUser(for credentials: Credentials, app: App? = nil) throws -> User {
        let user = (app ?? self.app).login(credentials: credentials).await(self, timeout: 60.0)
        XCTAssertTrue(user.isLoggedIn)
        return user
    }

    public func waitForUploads(for realm: Realm) {
        waitForUploads(for: ObjectiveCSupport.convert(object: realm))
    }

    public func waitForDownloads(for realm: Realm) {
        waitForDownloads(for: ObjectiveCSupport.convert(object: realm))
    }

    public func checkCount<T: Object>(expected: Int,
                                      _ realm: Realm,
                                      _ type: T.Type,
                                      file: StaticString = #file,
                                      line: UInt = #line) {
        realm.refresh()
        let actual = realm.objects(type).count
        XCTAssertEqual(actual, expected,
                       "Error: expected \(expected) items, but got \(actual) (process: \(isParent ? "parent" : "child"))",
            file: file,
            line: line)
    }

    var exceptionThrown = false

    public func assertThrows<T>(_ block: @autoclosure () -> T, named: String? = RLMExceptionName,
                                _ message: String? = nil, fileName: String = #file, lineNumber: UInt = #line) {
        exceptionThrown = true
        RLMAssertThrowsWithName(self, { _ = block() }, named, message, fileName, lineNumber)
    }

    public func assertThrows<T>(_ block: @autoclosure () -> T, reason: String,
                                _ message: String? = nil, fileName: String = #file, lineNumber: UInt = #line) {
        exceptionThrown = true
        RLMAssertThrowsWithReason(self, { _ = block() }, reason, message, fileName, lineNumber)
    }

    public func assertThrows<T>(_ block: @autoclosure () -> T, reasonMatching regexString: String,
                                _ message: String? = nil, fileName: String = #file, lineNumber: UInt = #line) {
        exceptionThrown = true
        RLMAssertThrowsWithReasonMatching(self, { _ = block() }, regexString, message, fileName, lineNumber)
    }

    public static let bigObjectCount = 2
    public func populateRealm<T: BSON>(user: User? = nil, partitionValue: T) throws {
        try autoreleasepool {
            let user = try (user ?? logInUser(for: basicCredentials()))
            let config = user.configuration(testName: partitionValue)

            let realm = try openRealm(configuration: config)
            try realm.write {
                for _ in 0..<SwiftSyncTestCase.bigObjectCount {
                    realm.add(SwiftHugeSyncObject.create())
                }
            }
            waitForUploads(for: realm)
            realm.syncSession?.suspend()
        }
    }

    // MARK: - Flexible Sync Use Cases

    public func openFlexibleSyncRealmForUser(_ user: User) throws -> Realm {
        var config = user.flexibleSyncConfiguration()
        if config.objectTypes == nil {
            config.objectTypes = [SwiftPerson.self,
                                  SwiftTypesSyncObject.self]
        }
        let realm = try Realm(configuration: config)
        waitForDownloads(for: realm)
        return realm
    }

    public func openFlexibleSyncRealm() throws -> Realm {
        let user = try logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)
        var config = user.flexibleSyncConfiguration()
        if config.objectTypes == nil {
            config.objectTypes = [SwiftPerson.self,
                                  SwiftTypesSyncObject.self]
        }
        return try Realm(configuration: config)
    }

    public func flexibleSyncRealm() throws -> Realm {
        let user = try logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)
        return try openFlexibleSyncRealmForUser(user)
    }

    public func populateFlexibleSyncData(_ block: @escaping (Realm) -> Void) throws {
        try writeToFlxRealm { realm in
            try realm.write {
                block(realm)
            }
            self.waitForUploads(for: realm)
        }
    }

    public func updateAllPeopleSubscription(_ subscriptions: SyncSubscriptionSet) {
        let expectation = expectation(description: "register subscription")
        subscriptions.update {
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "all_people"))
        } onComplete: { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }

    public func writeToFlxRealm(_ block: @escaping (Realm) throws -> Void) throws {
        let realm = try flexibleSyncRealm()
        let subscriptions = realm.subscriptions
        XCTAssertNotNil(subscriptions)
        let ex = expectation(description: "state change complete")
        subscriptions.update({
            subscriptions.append(QuerySubscription<SwiftPerson>())
            subscriptions.append(QuerySubscription<SwiftTypesSyncObject>())
        }, onComplete: { error in
            XCTAssertNil(error)
            ex.fulfill()
        })
        XCTAssertEqual(subscriptions.count, 2)

        waitForExpectations(timeout: 20.0, handler: nil)
        try block(realm)
    }

    // MARK: - Mongo Client

    public func setupMongoCollection(for collection: String) throws -> MongoCollection {
        let user = try logInUser(for: basicCredentials())
        let mongoClient = user.mongoClient("mongodb1")
        let database = mongoClient.database(named: "test_data")
        let collection = database.collection(withName: collection)
        removeAllFromCollection(collection)
        return collection
    }

    public func removeAllFromCollection(_ collection: MongoCollection) {
        let deleteEx = expectation(description: "Delete all from Mongo collection")
        collection.deleteManyDocuments(filter: [:]) { result in
            if case .failure = result {
                XCTFail("Should delete")
            }
            deleteEx.fulfill()
        }
        wait(for: [deleteEx], timeout: 30.0)
    }
}

@available(macOS 12.0, *)
extension SwiftSyncTestCase {
    public func basicCredentials(usernameSuffix: String = "", app: App? = nil) async throws -> Credentials {
        let email = "\(randomString(10))\(usernameSuffix)"
        let password = "abcdef"
        let credentials = Credentials.emailPassword(email: email, password: password)
        try await (app ?? self.app).emailPasswordAuth.registerUser(email: email, password: password)
        return credentials
    }

    // MARK: - Flexible Sync Async Use Cases

    public func flexibleSyncConfig() async throws -> Realm.Configuration {
        var config = (try await self.flexibleSyncApp.login(credentials: basicCredentials(app: flexibleSyncApp))).flexibleSyncConfiguration()
        if config.objectTypes == nil {
            config.objectTypes = [SwiftPerson.self,
                                  SwiftTypesSyncObject.self,
                                  SwiftCustomColumnObject.self]
        }
        return config
    }

    @MainActor
    public func flexibleSyncRealm() async throws -> Realm {
        let realm = try await Realm(configuration: flexibleSyncConfig())
        return realm
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
public extension Publisher {
    func expectValue(_ testCase: XCTestCase, _ expectation: XCTestExpectation,
                     receiveValue: (@Sendable (Self.Output) -> Void)? = nil) -> AnyCancellable {
        sink(receiveCompletion: { result in
            if case .failure(let error) = result {
                XCTFail("Unexpected failure: \(error)")
            }
        }, receiveValue: { value in
            receiveValue?(value)
            expectation.fulfill()
        })
    }

    @MainActor
    func await(_ testCase: XCTestCase, timeout: TimeInterval = 20.0, receiveValue: (@Sendable (Self.Output) -> Void)? = nil) {
        let expectation = testCase.expectation(description: "Async combine pipeline")
        let cancellable = self.expectValue(testCase, expectation, receiveValue: receiveValue)
        testCase.wait(for: [expectation], timeout: timeout)
        cancellable.cancel()
    }

    @discardableResult
    @MainActor
    func await(_ testCase: XCTestCase, timeout: TimeInterval = 20.0) -> Self.Output {
        let expectation = testCase.expectation(description: "Async combine pipeline")
        let value = Locked(Self.Output?.none)
        let cancellable = self.expectValue(testCase, expectation, receiveValue: { value.wrappedValue = $0 })
        testCase.wait(for: [expectation], timeout: timeout)
        cancellable.cancel()
        return value.wrappedValue!
    }

    @MainActor
    func awaitFailure(_ testCase: XCTestCase, timeout: TimeInterval = 20.0,
                      _ errorHandler: (@Sendable (Self.Failure) -> Void)? = nil) {
        let expectation = testCase.expectation(description: "Async combine pipeline should fail")
        let cancellable = sink(receiveCompletion: { @Sendable result in
            if case .failure(let error) = result {
                errorHandler?(error)
                expectation.fulfill()
            }
        }, receiveValue: { @Sendable value in
            XCTFail("Should have failed but got \(value)")
        })
        testCase.wait(for: [expectation], timeout: timeout)
        cancellable.cancel()
    }

    @MainActor
    func awaitFailure<E: Error>(_ testCase: XCTestCase, timeout: TimeInterval = 20.0,
                                _ errorHandler: @escaping (@Sendable (E) -> Void)) {
        awaitFailure(testCase, timeout: timeout) { error in
            guard let error = error as? E else {
                XCTFail("Expected error of type \(E.self), got \(error)")
                return
            }
            errorHandler(error)
        }
    }
}

#endif // os(macOS)
