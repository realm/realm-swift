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

// SwiftSyncTestCase wraps RLMSyncTestCase to make it more pleasant to use from
// Swift. Most of the comments there apply to this as well.
@available(macOS 13, *)
open class SwiftSyncTestCase: RLMSyncTestCase {
    // overridden in subclasses to generate a FLX config instead of a PBS one
    open func configuration(user: User) -> Realm.Configuration {
        user.configuration(partitionValue: self.name)
    }

    // Must be overriden in each subclass to specify which types will be used
    // in this test case.
    nonisolated open var objectTypes: [ObjectBase.Type] {
        [SwiftPerson.self]
    }

    override open func defaultObjectTypes() -> [AnyClass] {
        objectTypes
    }

    public func executeChild(file: StaticString = #filePath, line: UInt = #line) {
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
        wait(for: [ex], timeout: 4)
        return credentials
    }

    @MainActor
    public func openRealm(app: App? = nil, wait: Bool = true) throws -> Realm {
        let realm = try Realm(configuration: configuration(app: app))
        if wait {
            waitForDownloads(for: realm)
        }
        return realm
    }

    @MainActor
    public func configuration(app: App? = nil) throws -> Realm.Configuration {
        let user = try createUser(app: app)
        var config = configuration(user: user)
        config.objectTypes = self.objectTypes
        return config
    }

    @MainActor
    public func openRealm(configuration: Realm.Configuration) throws -> Realm {
        Realm.asyncOpen(configuration: configuration).await(self)
    }

    @MainActor
    public func openRealm(user: User, partitionValue: String) throws -> Realm {
        var config = user.configuration(partitionValue: partitionValue)
        config.objectTypes = self.objectTypes
        return try openRealm(configuration: config)
    }

    @MainActor
    public func createUser(app: App? = nil) throws -> User {
        let app = app ?? self.app
        return try logInUser(for: basicCredentials(app: app), app: app)
    }

    @MainActor
    public func logInUser(for credentials: Credentials, app: App? = nil) throws -> User {
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

    // Populate the server-side data using the given block, which is called in
    // a write transaction. Note that unlike the obj-c versions, this works for
    // both PBS and FLX sync.
    @MainActor
    public func write(app: App? = nil, _ block: (Realm) throws -> Void) throws {
        try autoreleasepool {
            let realm = try openRealm(app: app)
            RLMRealmSubscribeToAll(ObjectiveCSupport.convert(object: realm))

            try realm.write {
                try block(realm)
            }
            waitForUploads(for: realm)

            let syncSession = try XCTUnwrap(realm.syncSession)
            syncSession.suspend()
            syncSession.parentUser()?.remove().await(self)
        }
    }

    public func checkCount<T: Object>(expected: Int,
                                      _ realm: Realm,
                                      _ type: T.Type,
                                      file: StaticString = #filePath,
                                      line: UInt = #line) {
        realm.refresh()
        let actual = realm.objects(type).count
        XCTAssertEqual(actual, expected,
                       "Error: expected \(expected) items, but got \(actual) (process: \(isParent ? "parent" : "child"))",
                       file: file, line: line)
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
    @MainActor
    public func populateRealm() throws {
        try write { realm in
            for _ in 0..<SwiftSyncTestCase.bigObjectCount {
                realm.add(SwiftHugeSyncObject.create(key: name))
            }
        }
    }

    // MARK: - Mongo Client

    public func setupMongoCollection(for type: ObjectBase.Type) throws -> MongoCollection {
        let collection = anonymousUser.collection(for: type, app: app)
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

    @MainActor
    public func waitForCollectionCount(_ collection: MongoCollection, _ count: Int) {
        let waitStart = Date()
        while collection.count(filter: [:]).await(self) < count && waitStart.timeIntervalSinceNow > -600.0 {
            sleep(1)
        }
        XCTAssertEqual(collection.count(filter: [:]).await(self), count)
    }

    // MARK: - Async helpers

    // These are async versions of the synchronous functions defined above.
    // They should function identically other than being async rather than using
    // expecatations to synchronously await things.
#if compiler(<6)
    public func basicCredentials(usernameSuffix: String = "", app: App? = nil) async throws -> Credentials {
        let email = "\(randomString(10))\(usernameSuffix)"
        let password = "abcdef"
        let credentials = Credentials.emailPassword(email: email, password: password)
        try await (app ?? self.app).emailPasswordAuth.registerUser(email: email, password: password)
        return credentials
    }
#else
    public func basicCredentials(
        usernameSuffix: String = "", app: App? = nil, _isolation: isolated (any Actor)? = #isolation
    ) async throws -> Credentials {
        let email = "\(randomString(10))\(usernameSuffix)"
        let password = "abcdef"
        let credentials = Credentials.emailPassword(email: email, password: password)
        try await (app ?? self.app).emailPasswordAuth.registerUser(email: email, password: password)
        return credentials
    }
#endif

    @MainActor
    @nonobjc public func openRealm() async throws -> Realm {
        try await Realm(configuration: configuration(), downloadBeforeOpen: .always)
    }

    @MainActor
    public func write(_ block: @escaping (Realm) throws -> Void) async throws {
        try await Task {
            let realm = try await openRealm()
            try await realm.asyncWrite {
                try block(realm)
            }
            let syncSession = try XCTUnwrap(realm.syncSession)
            try await syncSession.wait(for: .upload)
            syncSession.suspend()
            try await syncSession.parentUser()?.remove()
        }.value
    }

#if compiler(<6)
    public func createUser(app: App? = nil) async throws -> User {
        let credentials = try await basicCredentials(app: app)
        return try await (app ?? self.app).login(credentials: credentials)
    }
#else
    public func createUser(app: App? = nil, _isolation: isolated (any Actor)? = #isolation) async throws -> User {
        let credentials = try await basicCredentials(app: app)
        return try await (app ?? self.app).login(credentials: credentials)
    }
#endif
}

@available(macOS 10.15, watchOS 6.0, iOS 13.0, tvOS 13.0, *)
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

    // Synchronously await non-error completion of the publisher, calling the
    // `receiveValue` callback with the value if supplied.
    func await(_ testCase: XCTestCase, timeout: TimeInterval = 20.0, receiveValue: (@Sendable (Self.Output) -> Void)? = nil) {
        let expectation = testCase.expectation(description: "Async combine pipeline")
        let cancellable = self.expectValue(testCase, expectation, receiveValue: receiveValue)
        testCase.wait(for: [expectation], timeout: timeout)
        cancellable.cancel()
    }

    // Synchronously await non-error completion of the publisher, returning the published value.
    @discardableResult
    func await(_ testCase: XCTestCase, timeout: TimeInterval = 20.0) -> Self.Output {
        let expectation = testCase.expectation(description: "Async combine pipeline")
        let value = Locked(Self.Output?.none)
        let cancellable = self.expectValue(testCase, expectation, receiveValue: { value.wrappedValue = $0 })
        testCase.wait(for: [expectation], timeout: timeout)
        cancellable.cancel()
        return value.wrappedValue!
    }

    // Synchrously await error completion of the publisher
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
