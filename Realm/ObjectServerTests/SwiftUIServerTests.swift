////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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

import RealmSwift
import XCTest
import SwiftUI
import Combine

#if canImport(RealmTestSupport)
import RealmSwiftSyncTestSupport
import RealmSyncTestSupport
import RealmSwiftTestSupport
#endif

@MainActor protocol AsyncOpenStateWrapper {
    func cancel()
    var wrappedValue: AsyncOpenState { get }
    var projectedValue: Published<AsyncOpenState>.Publisher { get }
}
extension AutoOpen: AsyncOpenStateWrapper {}
extension AsyncOpen: AsyncOpenStateWrapper {}

@available(macOS 13, *)
@MainActor
class SwiftUIServerTests: SwiftSyncTestCase {
    override var objectTypes: [ObjectBase.Type] {
        [SwiftHugeSyncObject.self]
    }

    nonisolated let cancellables = Locked(Set<AnyCancellable>())
    override func tearDown() {
        cancellables.withLock {
            $0.forEach { $0.cancel() }
            $0 = []
        }
        super.tearDown()
    }

    override class var defaultTestSuite: XCTestSuite {
        // Don't run tests for the base class
        if self === SwiftUIServerTests.self {
            return XCTestSuite(name: "SwiftUIServerTests")
        }
        return super.defaultTestSuite
    }


    func awaitOpen(_ wrapper: some AsyncOpenStateWrapper,
                   handler: @escaping (AsyncOpenState) -> Void) {
        _ = wrapper.wrappedValue // Retrieving the wrappedValue to simulate a SwiftUI environment where this is called when initialising the view.
        wrapper.projectedValue
            .sink(receiveValue: handler)
            .store(in: cancellables)
        waitForExpectations(timeout: 10.0)
        wrapper.cancel()
    }

    // Configuration for tests
    func configuration(user: User, partition: String) -> Realm.Configuration {
        fatalError()
    }

    // MARK: - AsyncOpen
    func asyncOpen(appId: String?, partitionValue: String, configuration: Realm.Configuration,
                   timeout: UInt? = nil, handler: @escaping (AsyncOpenState) -> Void) {
        fatalError()
    }

    func asyncOpen(user: User, appId: String?, partitionValue: String, timeout: UInt? = nil,
                   handler: @escaping (AsyncOpenState) -> Void) {
        fatalError()
    }

    func asyncOpen(handler: @escaping (AsyncOpenState) -> Void) throws {
        asyncOpen(appId: appId, partitionValue: self.name, configuration: try configuration(),
                  handler: handler)
    }

    func testAsyncOpenOpenRealm() throws {
        let ex = expectation(description: "download-realm-async-open")
        try asyncOpen { asyncOpenState in
            if case .open = asyncOpenState {
                ex.fulfill()
            }
        }
    }

    func testAsyncOpenDownloadRealm() throws {
        try populateRealm()
        let ex = expectation(description: "download-populated-realm-async-open")
        try asyncOpen { asyncOpenState in
            if case let .open(realm) = asyncOpenState {
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                ex.fulfill()
            }
        }
    }

    func testAsyncOpenWaitingForUserWithoutUserLoggedIn() throws {
        let user = createUser()
        user.logOut().await(self)

        let ex = expectation(description: "download-realm-async-open-not-logged")
        asyncOpen(user: user, appId: appId, partitionValue: name) { asyncOpenState in
            if case .waitingForUser = asyncOpenState {
                ex.fulfill()
            }
        }
    }

    // In case of no internet connection AsyncOpen should return an error if there is a timeout
    func testAsyncOpenFailWithoutInternetConnection() throws {
        let proxy = TimeoutProxyServer(port: 5678, targetPort: 9090)
        try proxy.start()

        let appId = try RealmServer.shared.createApp(types: self.objectTypes)
        let appConfig = AppConfiguration(baseURL: "http://localhost:5678",
                                         transport: AsyncOpenConnectionTimeoutTransport())
        let app = App(id: appId, configuration: appConfig)
        let user = try createUser(app: app)

        proxy.dropConnections = true
        let ex = expectation(description: "download-realm-async-open-no-connection")
        asyncOpen(user: user, appId: appId,
                  partitionValue: name, timeout: 1000) { asyncOpenState in
            if case let .error(error) = asyncOpenState,
               let nsError = error as NSError? {
                XCTAssertEqual(nsError.code, Int(ETIMEDOUT))
                XCTAssertEqual(nsError.domain, NSPOSIXErrorDomain)
                ex.fulfill()
            }
        }

        proxy.stop()
    }

    @MainActor
    func testAsyncOpenProgressNotification() throws {
        try populateRealm()
        let ex = expectation(description: "progress-async-open")
        try asyncOpen { asyncOpenState in
            if case let .progress(progress) = asyncOpenState {
                XCTAssertTrue(progress.fractionCompleted > 0)
                if progress.isFinished {
                    ex.fulfill()
                }
            }
        }
    }

    // Cached App is already created on the setup of the test
    func testAsyncOpenWithACachedApp() throws {
        try populateRealm()
        let ex = expectation(description: "download-cached-app-async-open")
        asyncOpen(user: createUser(), appId: nil, partitionValue: name) { asyncOpenState in
            if case let .open(realm) = asyncOpenState {
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                ex.fulfill()
            }
        }
    }

    func testAsyncOpenThrowExceptionWithoutCachedApp() throws {
        resetAppCache()
        assertThrows(AsyncOpen(partitionValue: name),
                     reason: "Cannot AsyncOpen the Realm because no appId was found. You must either explicitly pass an appId or initialize an App before displaying your View.")
    }

    func testAsyncOpenThrowExceptionWithMoreThanOneCachedApp() throws {
        _ = App(id: "fake 1")
        _ = App(id: "fake 2")
        assertThrows(AsyncOpen(partitionValue: name),
                     reason: "Cannot AsyncOpen the Realm because more than one appId was found. When using multiple Apps you must explicitly pass an appId to indicate which to use.")
    }

    func testAsyncOpenWithDifferentPartitionValues() throws {
        try populateRealm()
        let emptyPartition = "\(name) empty partition"

        let ex = expectation(description: "download-partition-value-async-open")
        try asyncOpen { asyncOpenState in
            if case let .open(realm) = asyncOpenState {
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                ex.fulfill()
            }
        }

        let ex2 = expectation(description: "download-other-partition-value-async-open")
        asyncOpen(user: createUser(), appId: nil, partitionValue: emptyPartition) { asyncOpenState in
            if case let .open(realm) = asyncOpenState {
                self.checkCount(expected: 0, realm, SwiftHugeSyncObject.self)
                ex2.fulfill()
            }
        }
    }

    func testAsyncOpenWithMultiUserApp() throws {
        try populateRealm()

        let syncUser1 = createUser()
        let syncUser2 = createUser()
        XCTAssertEqual(app.allUsers.count, 2)
        XCTAssertEqual(syncUser2.id, app.currentUser?.id)

        let ex = expectation(description: "test-multiuser1-app-async-open")
        asyncOpen(user: syncUser2, appId: appId, partitionValue: name) { asyncOpenState in
            if case let .open(realm) = asyncOpenState {
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                XCTAssertEqual(realm.syncSession?.parentUser(), syncUser2)
                ex.fulfill()
            }
        }

        app.switch(to: syncUser1)
        XCTAssertEqual(app.allUsers.count, 2)
        XCTAssertEqual(syncUser1.id, app.currentUser?.id)

        let ex2 = expectation(description: "test-multiuser2-app-async-open")
        asyncOpen(user: syncUser1, appId: appId, partitionValue: name) { asyncOpenState in
            if case let .open(realm) = asyncOpenState {
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                XCTAssertEqual(realm.syncSession?.parentUser(), syncUser1)
                ex2.fulfill()
            }
        }
    }

    func testAsyncOpenWithUserAfterLogoutFromAnonymous() throws {
        try populateRealm()

        let anonymousUser = self.anonymousUser
        let ex = expectation(description: "download-realm-anonymous-user-async-open")
        asyncOpen(user: anonymousUser, appId: appId, partitionValue: name) { asyncOpenState in
            if case let .open(realm) = asyncOpenState {
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                ex.fulfill()
            }
        }

        anonymousUser.logOut().await(self)

        let ex2 = expectation(description: "download-realm-after-logout-async-open")
        asyncOpen(user: createUser(), appId: appId, partitionValue: name) { asyncOpenState in
            if case let .open(realm) = asyncOpenState {
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                ex2.fulfill()
            }
        }
    }

    // MARK: - AutoOpen
    func autoOpen(appId: String?, partitionValue: String, configuration: Realm.Configuration,
                  timeout: UInt?, handler: @escaping (AsyncOpenState) -> Void) {
        fatalError()
    }

    func autoOpen(user: User, appId: String?, partitionValue: String, timeout: UInt? = nil,
                  handler: @escaping (AsyncOpenState) -> Void) {
        fatalError()
    }

    func autoOpen(handler: @escaping (AsyncOpenState) -> Void) throws {
        autoOpen(appId: appId, partitionValue: self.name, configuration: try configuration(),
                 timeout: nil, handler: handler)
    }

    func testAutoOpenOpenRealm() throws {
        let ex = expectation(description: "download-realm-auto-open")
        try autoOpen { autoOpenState in
            if case .open = autoOpenState {
                ex.fulfill()
            }
        }
    }

    func testAutoOpenDownloadRealm() throws {
        try populateRealm()
        let ex = expectation(description: "download-populated-realm-auto-open")
        try autoOpen { autoOpenState in
            if case let .open(realm) = autoOpenState {
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                ex.fulfill()
            }
        }
    }

    @MainActor
    func testAutoOpenWaitingForUserWithoutUserLoggedIn() throws {
        let user = try logInUser(for: basicCredentials())
        user.logOut().await(self)

        let ex = expectation(description: "download-realm-auto-open-not-logged")
        autoOpen(user: user, appId: appId, partitionValue: name) { autoOpenState in
            if case .waitingForUser = autoOpenState {
                ex.fulfill()
            }
        }
    }

    // In case of no internet connection AutoOpen should return an opened Realm, offline-first approach
    func testAutoOpenOpenRealmWithoutInternetConnection() throws {
        try populateRealm()
        resetAppCache()

        let proxy = TimeoutProxyServer(port: 5678, targetPort: 9090)
        try proxy.start()
        let appConfig = AppConfiguration(baseURL: "http://localhost:5678",
                                         transport: AsyncOpenConnectionTimeoutTransport())
        let app = App(id: appId, configuration: appConfig)
        let user = try createUser(app: app)
        proxy.dropConnections = true
        let ex = expectation(description: "download-realm-auto-open-no-connection")
        autoOpen(user: user, appId: appId, partitionValue: name, timeout: 1000) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                XCTAssertTrue(realm.isEmpty) // should not have downloaded anything
                ex.fulfill()
            }
        }

        // Clear cache to avoid leaking our app which connects to the proxy
        App.resetAppCache()
        proxy.stop()
    }

    func testAutoOpenProgressNotification() throws {
        try populateRealm()

        let user = createUser()
        let ex = expectation(description: "progress-auto-open")
        autoOpen(user: user, appId: appId, partitionValue: name) { autoOpenState in
            if case let .progress(progress) = autoOpenState {
                XCTAssertTrue(progress.fractionCompleted > 0)
                if progress.isFinished {
                    ex.fulfill()
                }
            }
        }
    }

    // App is already created on the setup of the test
    func testAutoOpenWithACachedApp() throws {
        try populateRealm()

        let ex = expectation(description: "download-cached-app-auto-open")
        try autoOpen { autoOpenState in
            if case let .open(realm) = autoOpenState {
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                ex.fulfill()
            }
        }
    }

    func testAutoOpenThrowExceptionWithoutCachedApp() throws {
        resetAppCache()
        assertThrows(AutoOpen(partitionValue: name),
                     reason: "Cannot AsyncOpen the Realm because no appId was found. You must either explicitly pass an appId or initialize an App before displaying your View.")
    }

    @MainActor
    func testAutoOpenThrowExceptionWithMoreThanOneCachedApp() throws {
        _ = App(id: "fake 1")
        _ = App(id: "fake 2")
        assertThrows(AutoOpen(partitionValue: name),
                     reason: "Cannot AsyncOpen the Realm because more than one appId was found. When using multiple Apps you must explicitly pass an appId to indicate which to use.")
    }

    @MainActor
    func testAutoOpenWithMultiUserApp() throws {
        try populateRealm()
        let partitionValueA = name
        let partitionValueB = "\(name) 2"

        let syncUser1 = createUser()
        let syncUser2 = createUser()
        XCTAssertEqual(app.allUsers.count, 2)
        XCTAssertEqual(syncUser2.id, app.currentUser!.id)

        let ex = expectation(description: "test-multiuser1-app-auto-open")
        autoOpen(user: syncUser2, appId: appId, partitionValue: partitionValueB) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                self.checkCount(expected: 0, realm, SwiftHugeSyncObject.self)
                ex.fulfill()
            }
        }

        app.switch(to: syncUser1)
        XCTAssertEqual(app.allUsers.count, 2)
        XCTAssertEqual(syncUser1.id, app.currentUser!.id)

        let ex2 = expectation(description: "test-multiuser2-app-auto-open")
        autoOpen(user: syncUser1, appId: appId, partitionValue: partitionValueA) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                ex2.fulfill()
            }
        }
    }

    func testAutoOpenWithUserAfterLogoutFromAnonymous() throws {
        let partitionValueA = name
        let partitionValueB = "\(name) 2"
        try populateRealm()

        let anonymousUser = self.anonymousUser
        let ex = expectation(description: "download-realm-anonymous-user-auto-open")
        autoOpen(user: anonymousUser, appId: appId, partitionValue: partitionValueB) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                self.checkCount(expected: 0, realm, SwiftHugeSyncObject.self)
                ex.fulfill()
            }
        }

        anonymousUser.logOut().await(self)

        let ex2 = expectation(description: "download-realm-after-logout-auto-open")
        autoOpen(user: createUser(), appId: appId, partitionValue: partitionValueA) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                ex2.fulfill()
            }
        }
    }

    func testAutoOpenWithDifferentPartitionValues() throws {
        try populateRealm()
        let partitionValueA = name
        let partitionValueB = "\(name) 2"

        let user = createUser()
        let ex = expectation(description: "download-partition-value-auto-open")
        autoOpen(user: user, appId: nil, partitionValue: partitionValueA) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                ex.fulfill()
            }
        }

        let ex2 = expectation(description: "download-other-partition-value-auto-open")
        autoOpen(user: user, appId: nil, partitionValue: partitionValueB) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                self.checkCount(expected: 0, realm, SwiftHugeSyncObject.self)
                ex2.fulfill()
            }
        }
    }

    // MARK: - Mixed AsyncOpen & AutoOpen
    func testCombineAsyncOpenAutoOpenWithDifferentPartitionValues() throws {
        try populateRealm()
        let partitionValueA = name
        let partitionValueB = "\(name) 2"

        let user = createUser()
        let ex = expectation(description: "download-partition-value-async-open-mixed")
        asyncOpen(user: user, appId: nil, partitionValue: partitionValueA) { asyncOpenState in
            if case let .open(realm) = asyncOpenState {
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                ex.fulfill()
            }
        }

        let ex2 = expectation(description: "download-partition-value-auto-open-mixed")
        autoOpen(user: user, appId: nil, partitionValue: partitionValueB) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                self.checkCount(expected: 0, realm, SwiftHugeSyncObject.self)
                ex2.fulfill()
            }
        }
    }

    func testCombineAsyncOpenAutoOpenWithMultiUserApp() throws {
        try populateRealm()
        let partitionValueA = name
        let partitionValueB = "\(name) 2"

        let syncUser1 = createUser()
        let syncUser2 = createUser()
        XCTAssertEqual(app.allUsers.count, 2)
        XCTAssertEqual(syncUser2.id, app.currentUser!.id)

        anonymousUser.remove().await(self)

        let ex = expectation(description: "test-combine-multiuser1-app-auto-open")
        autoOpen(user: syncUser2, appId: appId, partitionValue: partitionValueB) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                self.checkCount(expected: 0, realm, SwiftHugeSyncObject.self)
                ex.fulfill()
            }
        }

        app.switch(to: syncUser1)
        XCTAssertEqual(app.allUsers.count, 2)
        XCTAssertEqual(syncUser1.id, app.currentUser!.id)

        let ex2 = expectation(description: "test-combine-multiuser2-app-auto-open")
        asyncOpen(user: syncUser1, appId: appId, partitionValue: partitionValueA) { asyncOpenState in
            if case let .open(realm) = asyncOpenState {
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                ex2.fulfill()
            }
        }
    }
}

@available(macOS 13, *)
@MainActor
class PBSSwiftUIServerTests: SwiftUIServerTests {
    override func configuration(user: User, partition: String) -> Realm.Configuration {
        var userConfiguration = user.configuration(partitionValue: partition)
        userConfiguration.objectTypes = self.objectTypes
        return userConfiguration
    }

    // MARK: - AsyncOpen
    override func asyncOpen(appId: String?, partitionValue: String, configuration: Realm.Configuration,
                            timeout: UInt? = nil, handler: @escaping (AsyncOpenState) -> Void) {
        let asyncOpen = AsyncOpen(appId: appId,
                                  partitionValue: partitionValue,
                                  configuration: configuration,
                                  timeout: timeout)
        awaitOpen(asyncOpen, handler: handler)
    }

    override func asyncOpen(user: User, appId: String?, partitionValue: String, timeout: UInt? = nil,
                            handler: @escaping (AsyncOpenState) -> Void) {
        let configuration = self.configuration(user: user, partition: partitionValue)
        asyncOpen(appId: appId,
                  partitionValue: partitionValue,
                  configuration: configuration,
                  timeout: timeout,
                  handler: handler)
    }

    override func autoOpen(appId: String?, partitionValue: String, configuration: Realm.Configuration,
                           timeout: UInt?, handler: @escaping (AsyncOpenState) -> Void) {
        let autoOpen = AutoOpen(appId: appId,
                                partitionValue: partitionValue,
                                configuration: configuration,
                                timeout: timeout)
        awaitOpen(autoOpen, handler: handler)
    }

    override func autoOpen(user: User, appId: String?, partitionValue: String, timeout: UInt? = nil,
                           handler: @escaping (AsyncOpenState) -> Void) {
        let configuration = self.configuration(user: user, partition: partitionValue)
        autoOpen(appId: appId,
                 partitionValue: partitionValue,
                 configuration: configuration,
                 timeout: timeout,
                 handler: handler)
    }
}

@available(macOS 13, *)
@MainActor
class FLXSwiftUIServerTests: SwiftUIServerTests, Sendable {
    override func createApp() throws -> String {
        try createFlexibleSyncApp()
    }

    override func configuration(user: User) -> Realm.Configuration {
        user.flexibleSyncConfiguration { subs in
            subs.append(QuerySubscription<SwiftHugeSyncObject> {
                $0.partition == self.name
            })
        }
    }

    override func configuration(user: User, partition: String) -> Realm.Configuration {
        var userConfiguration = user.flexibleSyncConfiguration { subs in
            subs.append(QuerySubscription<SwiftHugeSyncObject> {
                $0.partition == partition
            })
        }
        userConfiguration.objectTypes = self.objectTypes
        return userConfiguration
    }

    // MARK: - AsyncOpen
    override func asyncOpen(appId: String?, partitionValue: String, configuration: Realm.Configuration,
                            timeout: UInt? = nil, handler: @escaping (AsyncOpenState) -> Void) {
        let asyncOpen = AsyncOpen(appId: appId,
                                  configuration: configuration,
                                  timeout: timeout)
        awaitOpen(asyncOpen, handler: handler)
    }

    override func asyncOpen(user: User, appId: String?, partitionValue: String, timeout: UInt? = nil,
                            handler: @escaping (AsyncOpenState) -> Void) {
        let configuration = self.configuration(user: user, partition: partitionValue)
        asyncOpen(appId: appId,
                  partitionValue: partitionValue,
                  configuration: configuration,
                  timeout: timeout,
                  handler: handler)
    }

    override func autoOpen(appId: String?, partitionValue: String, configuration: Realm.Configuration,
                           timeout: UInt?, handler: @escaping (AsyncOpenState) -> Void) {
        let autoOpen = AutoOpen(appId: appId,
                                configuration: configuration,
                                timeout: timeout)
        awaitOpen(autoOpen, handler: handler)
    }

    override func autoOpen(user: User, appId: String?, partitionValue: String, timeout: UInt? = nil,
                           handler: @escaping (AsyncOpenState) -> Void) {
        let configuration = self.configuration(user: user, partition: partitionValue)
        autoOpen(appId: appId,
                 partitionValue: partitionValue,
                 configuration: configuration,
                 timeout: timeout,
                 handler: handler)
    }

    // These two tests are expecting different partition values to result in
    // different Realm files, which isn't applicable to FLX
    override func testAutoOpenWithDifferentPartitionValues() throws {}
    override func testCombineAsyncOpenAutoOpenWithDifferentPartitionValues() throws {}
}
