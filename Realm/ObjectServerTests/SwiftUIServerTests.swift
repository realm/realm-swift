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
#endif

@available(OSX 11, *)
@MainActor
class SwiftUIServerTests: SwiftSyncTestCase {

    enum OpenType {
        case configuration(Realm.Configuration)
        case pbs(String)
        case flexibleSync
    }

    // Configuration for tests
    private func configuration<T: BSON>(user: User, partition: T) -> Realm.Configuration {
        var userConfiguration = user.configuration(partitionValue: partition)
        userConfiguration.objectTypes = [SwiftHugeSyncObject.self]
        return userConfiguration
    }

    override func tearDown() {
        cancellables.forEach { $0.cancel() }
        cancellables = []
        super.tearDown()
    }

    var cancellables: Set<AnyCancellable> = []

    // MARK: - AsyncOpen
    func asyncOpen(appId: String? = nil, openType: OpenType, timeout: UInt? = nil,
                   handler: @escaping (AsyncOpenState) -> Void) {
        let asyncOpen: AsyncOpen
        switch openType {
        case .configuration(let configuration):
            asyncOpen = AsyncOpen(appId: appId,
                                  configuration: configuration,
                                  timeout: timeout)
        case .pbs(let partitionValue):
            asyncOpen = AsyncOpen(appId: appId,
                                  partitionValue: partitionValue,
                                  timeout: timeout)
        case .flexibleSync:
            asyncOpen = AsyncOpen(appId: appId,
                                  timeout: timeout)
        }

        _ = asyncOpen.wrappedValue // Retrieving the wrappedValue to simulate a SwiftUI environment where this is called when initialising the view.
        asyncOpen.projectedValue
            .sink(receiveValue: handler)
            .store(in: &cancellables)
        waitForExpectations(timeout: 10.0)
        asyncOpen.cancel()
    }

    func testAsyncOpenOpenRealm() throws {
        _ = try logInUser(for: basicCredentials())

        let ex = expectation(description: "download-realm-async-open")
        asyncOpen(appId: appId, openType: .pbs(#function)) { asyncOpenState in
            if case let .open(realm) = asyncOpenState {
                XCTAssertNotNil(realm)
                ex.fulfill()
            }
        }
    }

    func testAsyncOpenDownloadRealm() throws {
        let user = try logInUser(for: basicCredentials())
        if !isParent {
            return try populateRealm(user: user, partitionValue: #function)
        }
        executeChild()

        let ex = expectation(description: "download-populated-realm-async-open")
        asyncOpen(appId: appId, openType: .pbs(#function)) { asyncOpenState in
            if case let .open(realm) = asyncOpenState {
                XCTAssertNotNil(realm)
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                ex.fulfill()
            }
        }
    }

    func testAsyncOpenWaitingForUserWithoutUserLoggedIn() throws {
        let user = try logInUser(for: basicCredentials())
        user.logOut { _ in } // Logout current user

        let ex = expectation(description: "download-realm-async-open-not-logged")
        asyncOpen(appId: appId, openType: .pbs(#function)) { asyncOpenState in
            if case .waitingForUser = asyncOpenState {
                ex.fulfill()
            }
        }
    }

    // In case of no internet connection AsyncOpen should return an error if there is a timeout
    func testAsyncOpenFailWithoutInternetConnection() throws {
        let proxy = TimeoutProxyServer(port: 5678, targetPort: 9090)
        try proxy.start()

        let appId = try RealmServer.shared.createApp()
        let appConfig = AppConfiguration(baseURL: "http://localhost:5678",
                                         transport: AsyncOpenConnectionTimeoutTransport())
        let app = App(id: appId, configuration: appConfig)
        _ = try logInUser(for: basicCredentials(app: app), app: app)

        proxy.dropConnections = true
        let ex = expectation(description: "download-realm-async-open-no-connection")
        asyncOpen(appId: appId, openType: .pbs(#function), timeout: 1000) { asyncOpenState in
            if case let .error(error) = asyncOpenState,
               let nsError = error as NSError? {
                XCTAssertEqual(nsError.code, Int(ETIMEDOUT))
                XCTAssertEqual(nsError.domain, NSPOSIXErrorDomain)
                ex.fulfill()
            }
        }

        proxy.stop()
        try RealmServer.shared.deleteApp(appId)
    }

    @MainActor
    func testAsyncOpenProgressNotification() throws {
        let user = try logInUser(for: basicCredentials())
        if !isParent {
            return try populateRealm(user: user, partitionValue: #function)
        }
        executeChild()

        let ex = expectation(description: "progress-async-open")
        asyncOpen(appId: appId, openType: .pbs(#function)) { asyncOpenState in
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
        let user = try logInUser(for: basicCredentials())
        if !isParent {
            return try populateRealm(user: user, partitionValue: #function)
        }
        executeChild()

        let ex = expectation(description: "download-cached-app-async-open")
        asyncOpen(openType: .pbs(#function)) { asyncOpenState in
            if case let .open(realm) = asyncOpenState {
                XCTAssertNotNil(realm)
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                ex.fulfill()
            }
        }
    }

    func testAsyncOpenThrowExceptionWithoutCachedApp() throws {
        resetAppCache()
        assertThrows(AsyncOpen(partitionValue: #function),
                     reason: "Cannot AsyncOpen the Realm because no appId was found. You must either explicitly pass an appId or initialize an App before displaying your View.")
    }

    func testAsyncOpenThrowExceptionWithMoreThanOneCachedApp() throws {
        _ = App(id: "fake 1")
        _ = App(id: "fake 2")
        assertThrows(AsyncOpen(partitionValue: #function),
                     reason: "Cannot AsyncOpen the Realm because more than one appId was found. When using multiple Apps you must explicitly pass an appId to indicate which to use.")
    }

    func testAsyncOpenWithDifferentPartitionValues() throws {
        let partitionValueA = #function
        let partitionValueB = "\(#function)bar"

        let user = try logInUser(for: basicCredentials())
        if !isParent {
            return try populateRealm(user: user, partitionValue: partitionValueA)
        }
        executeChild()

        let ex = expectation(description: "download-partition-value-async-open")
        asyncOpen(openType: .pbs(partitionValueA)) { asyncOpenState in
            if case let .open(realm) = asyncOpenState {
                XCTAssertNotNil(realm)
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                ex.fulfill()
            }
        }

        let ex2 = expectation(description: "download-other-partition-value-async-open")
        asyncOpen(openType: .pbs(partitionValueB)) { asyncOpenState in
            if case let .open(realm) = asyncOpenState {
                XCTAssertNotNil(realm)
                self.checkCount(expected: 0, realm, SwiftHugeSyncObject.self)
                ex2.fulfill()
            }
        }
    }

    func testAsyncOpenWithMultiUserApp() throws {
        let partitionValueA = #function
        let partitionValueB = "\(#function)bar"

        let syncUser1 = try logInUser(for: basicCredentials())
        let syncUser2 = try logInUser(for: basicCredentials())
        XCTAssertEqual(app.allUsers.count, 2)
        XCTAssertEqual(syncUser2.id, app.currentUser!.id)

        if !isParent {
            return try populateRealm(user: syncUser1, partitionValue: partitionValueA)
        }
        executeChild()

        let ex = expectation(description: "test-multiuser1-app-async-open")
        asyncOpen(appId: appId, openType: .pbs(partitionValueB)) { asyncOpenState in
            if case let .open(realm) = asyncOpenState {
                XCTAssertNotNil(realm)
                self.checkCount(expected: 0, realm, SwiftHugeSyncObject.self)
                ex.fulfill()
            }
        }

        app.switch(to: syncUser1)
        XCTAssertEqual(app.allUsers.count, 2)
        XCTAssertEqual(syncUser1.id, app.currentUser!.id)

        let ex2 = expectation(description: "test-multiuser2-app-async-open")
        asyncOpen(appId: appId, openType: .pbs(partitionValueA)) { asyncOpenState in
            if case let .open(realm) = asyncOpenState {
                XCTAssertNotNil(realm)
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                ex2.fulfill()
            }
        }
    }

    func testAsyncOpenWithUserAfterLogoutFromAnonymous() throws {
        let partitionValueA = #function
        let partitionValueB = "\(#function)bar"

        let user = try logInUser(for: basicCredentials())
        if !isParent {
            return try populateRealm(user: user, partitionValue: partitionValueB)
        }
        executeChild()

        _ = try logInUser(for: .anonymous)
        let ex = expectation(description: "download-realm-anonymous-user-async-open")
        asyncOpen(appId: appId, openType: .pbs(partitionValueA)) { asyncOpenState in
            if case let .open(realm) = asyncOpenState {
                XCTAssertNotNil(realm)
                self.checkCount(expected: 0, realm, SwiftHugeSyncObject.self)
                ex.fulfill()
            }
        }

        app.currentUser?.logOut { _ in } // Logout anonymous user

        let ex2 = expectation(description: "download-realm-after-logout-async-open")
        asyncOpen(appId: appId, openType: .pbs(partitionValueB)) { asyncOpenState in
            if case let .open(realm) = asyncOpenState {
                XCTAssertNotNil(realm)
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                ex2.fulfill()
            }
        }
    }

    func testAsyncOpenFlexibleSyncInit() throws {
        try populateFlexibleSyncData { realm in
            for i in 1...10 {
                // Using firstname to query only objects from this test
                let person = SwiftPerson(firstName: "\(#function)",
                                         lastName: "lastname_\(i)",
                                         age: i)
                realm.add(person)
            }
        }

        _ = try logInUser(for: basicCredentials(app: flexibleSyncApp), app: flexibleSyncApp)

        let ex = expectation(description: "download-realm-flexible-async-open")
        asyncOpen(appId: flexibleSyncAppId, openType: .flexibleSync, timeout: 1000) { asyncOpenState in
            if case let .open(realm) = asyncOpenState {
                XCTAssertNotNil(realm)
                XCTAssertTrue(realm.isEmpty) // should not have downloaded anything, because there are no subscriptions
                ex.fulfill()
            }
        }
    }

    func testAsyncOpenFlexibleSyncConfiguration() throws {
        try populateFlexibleSyncData { realm in
            for i in 1...10 {
                // Using firstname to query only objects from this test
                let person = SwiftPerson(firstName: "\(#function)",
                                         lastName: "lastname_\(i)",
                                         age: i)
                realm.add(person)
            }
        }

        let user = try logInUser(for: basicCredentials(app: flexibleSyncApp), app: flexibleSyncApp)

        var configuration = user.flexibleSyncConfiguration(initialSubscriptions: { subs in
            subs.append(QuerySubscription<SwiftPerson> {
                $0.firstName == "\(#function)" && $0.age > 0
            })
        })
        configuration.objectTypes = [SwiftPerson.self]

        let ex = expectation(description: "download-realm-flexible-async-open")
        asyncOpen(appId: flexibleSyncAppId, openType: .configuration(configuration), timeout: 1000) { asyncOpenState in
            if case let .open(realm) = asyncOpenState {
                XCTAssertNotNil(realm)
                self.checkCount(expected: 10, realm, SwiftPerson.self)
                ex.fulfill()
            }
        }
    }

    func testAsyncOpenPBSWithConfiguration() throws {
        let user = try logInUser(for: basicCredentials())
        if !isParent {
            populateRealm(user: user, partitionValue: #function)
            return
        }
        executeChild()

        var configuration = user.configuration(partitionValue: #function)
        configuration.objectTypes = [SwiftHugeSyncObject.self]

        let ex = expectation(description: "download-populated-realm-async-open")
        asyncOpen(appId: appId, openType: .configuration(configuration)) { asyncOpenState in
            if case let .open(realm) = asyncOpenState {
                XCTAssertNotNil(realm)
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                ex.fulfill()
            }
        }
    }

    func testAsyncOpenPBSWithClientReset() throws {
        let user = try logInUser(for: basicCredentials())
        var configuration = user.configuration(partitionValue: #function, clientResetMode: .manual(errorHandler: { _, _ in }))
        configuration.objectTypes = [SwiftPerson.self]

        let ex = expectation(description: "download-populated-realm-async-open")
        asyncOpen(appId: appId, openType: .configuration(configuration)) { asyncOpenState in
            if case let .open(realm) = asyncOpenState {
                XCTAssertNotNil(realm)
                switch configuration.syncConfiguration!.clientResetMode {
                case .manual(let block):
                    XCTAssertNotNil(block)
                default:
                    XCTFail("Should be set to manual")
                }
                ex.fulfill()
            }
        }
    }

    func testAsyncOpenFlexibleSyncWithClientReset() throws {
        let user = try logInUser(for: basicCredentials(app: flexibleSyncApp), app: flexibleSyncApp)
        var configuration = user.flexibleSyncConfiguration(clientResetMode: .manual(errorHandler: { _, _ in }))
        configuration.objectTypes = [SwiftPerson.self]

        let ex = expectation(description: "download-populated-realm-async-open")
        asyncOpen(appId: flexibleSyncAppId, openType: .configuration(configuration)) { asyncOpenState in
            if case let .open(realm) = asyncOpenState {
                XCTAssertNotNil(realm)
                switch configuration.syncConfiguration!.clientResetMode {
                case .manual(let block):
                    XCTAssertNotNil(block)
                default:
                    XCTFail("Should be set to manual")
                }
                ex.fulfill()
            }
        }
    }

    // MARK: - AutoOpen
    func autoOpen(appId: String? = nil, openType: OpenType, timeout: UInt? = nil, handler: @escaping (AsyncOpenState) -> Void) {
        let autoOpen: AutoOpen
        switch openType {
        case .configuration(let configuration):
            autoOpen = AutoOpen(appId: appId,
                                configuration: configuration,
                                timeout: timeout)
        case .pbs(let partitionValue):
            autoOpen = AutoOpen(appId: appId,
                                partitionValue: partitionValue,
                                timeout: timeout)
        case .flexibleSync:
            autoOpen = AutoOpen(appId: appId,
                                timeout: timeout)
        }

        _ = autoOpen.wrappedValue // Retrieving the wrappedValue to simulate a SwiftUI environment where this is called when initialising the view.
        autoOpen.projectedValue
            .sink(receiveValue: handler)
            .store(in: &cancellables)
        waitForExpectations(timeout: 10.0)
        autoOpen.cancel()
    }

    func testAutoOpenOpenRealm() throws {
        _ = try logInUser(for: basicCredentials())

        let ex = expectation(description: "download-realm-auto-open")
        autoOpen(appId: appId, openType: .pbs(#function)) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                XCTAssertNotNil(realm)
                ex.fulfill()
            }
        }
    }

    func testAutoOpenDownloadRealm() throws {
        let user = try logInUser(for: basicCredentials())

        if !isParent {
            return try populateRealm(user: user, partitionValue: #function)
        }
        executeChild()

        let ex = expectation(description: "download-populated-realm-auto-open")
        autoOpen(appId: appId, openType: .pbs(#function)) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                XCTAssertNotNil(realm)
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                ex.fulfill()
            }
        }
    }

    @MainActor
    func testAutoOpenWaitingForUserWithoutUserLoggedIn() throws {
        let user = try logInUser(for: basicCredentials())
        user.logOut { _ in } // Logout current user

        let ex = expectation(description: "download-realm-auto-open-not-logged")
        autoOpen(appId: appId, openType: .pbs(#function)) { autoOpenState in
            if case .waitingForUser = autoOpenState {
                ex.fulfill()
            }
        }
    }

    // In case of no internet connection AutoOpen should return an opened Realm, offline-first approach
    func testAutoOpenOpenRealmWithoutInternetConnection() throws {
        try autoreleasepool {
            let user = try logInUser(for: basicCredentials(app: self.app), app: self.app)
            try populateRealm(user: user, partitionValue: #function)
        }
        resetAppCache()

        let proxy = TimeoutProxyServer(port: 5678, targetPort: 9090)
        try proxy.start()
        let appConfig = AppConfiguration(baseURL: "http://localhost:5678",
                                         transport: AsyncOpenConnectionTimeoutTransport())
        let app = App(id: appId, configuration: appConfig)
        _ = try logInUser(for: basicCredentials(app: app), app: app)
        proxy.dropConnections = true
        let ex = expectation(description: "download-realm-auto-open-no-connection")
        autoOpen(appId: appId, openType: .pbs(#function), timeout: 1000) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                XCTAssertTrue(realm.isEmpty) // should not have downloaded anything
                ex.fulfill()
            }
        }

        // Clear cache to avoid leaking our app which connects to the proxy
        App.resetAppCache()
        proxy.stop()
    }

    // In case of no internet connection AutoOpen should return an opened Realm, offline-first approach
    func testAutoOpenOpenForFlexibleSyncConfigWithoutInternetConnection() throws {
        try autoreleasepool {
            try populateFlexibleSyncData { realm in
                for i in 1...10 {
                    // Using firstname to query only objects from this test
                    let person = SwiftPerson(firstName: "\(#function)",
                                             lastName: "lastname_\(i)",
                                             age: i)
                    realm.add(person)
                }
            }
        }
        resetAppCache()

        let proxy = TimeoutProxyServer(port: 5678, targetPort: 9090)
        try proxy.start()
        let appConfig = AppConfiguration(baseURL: "http://localhost:5678",
                                         transport: AsyncOpenConnectionTimeoutTransport())
        let app = App(id: flexibleSyncAppId, configuration: appConfig)
        _ = try logInUser(for: basicCredentials(app: app), app: app)

        proxy.dropConnections = true
        let ex = expectation(description: "download-realm-flexible-auto-open-no-connection")
        autoOpen(appId: flexibleSyncAppId, openType: .flexibleSync, timeout: 1000) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                XCTAssertTrue(realm.isEmpty) // should not have downloaded anything
                ex.fulfill()
            }
        }

        App.resetAppCache()
        proxy.stop()
    }

    func testAutoOpenProgressNotification() throws {
        try autoreleasepool {
            let user = try logInUser(for: basicCredentials())
            try populateRealm(user: user, partitionValue: #function)
        }

        _ = try logInUser(for: basicCredentials())
        let ex = expectation(description: "progress-auto-open")
        autoOpen(appId: appId, openType: .pbs(#function)) { autoOpenState in
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
        let user = try logInUser(for: basicCredentials())
        if !isParent {
            return try populateRealm(user: user, partitionValue: #function)
        }
        executeChild()

        let ex = expectation(description: "download-cached-app-auto-open")
        autoOpen(openType: .pbs(#function)) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                XCTAssertNotNil(realm)
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                ex.fulfill()
            }
        }
    }

    func testAutoOpenThrowExceptionWithoutCachedApp() throws {
        resetAppCache()
        assertThrows(AutoOpen(partitionValue: #function),
                     reason: "Cannot AsyncOpen the Realm because no appId was found. You must either explicitly pass an appId or initialize an App before displaying your View.")
    }

    @MainActor
    func testAutoOpenThrowExceptionWithMoreThanOneCachedApp() throws {
        _ = App(id: "fake 1")
        _ = App(id: "fake 2")
        assertThrows(AutoOpen(partitionValue: #function),
                     reason: "Cannot AsyncOpen the Realm because more than one appId was found. When using multiple Apps you must explicitly pass an appId to indicate which to use.")
    }

    @MainActor
    func testAutoOpenWithMultiUserApp() throws {
        let partitionValueA = #function
        let partitionValueB = "\(#function)bar"

        let syncUser1 = try logInUser(for: basicCredentials())
        let syncUser2 = try logInUser(for: basicCredentials())
        XCTAssertEqual(app.allUsers.count, 2)
        XCTAssertEqual(syncUser2.id, app.currentUser!.id)

        if !isParent {
            return try populateRealm(user: syncUser1, partitionValue: partitionValueA)
        }
        executeChild()

        let ex = expectation(description: "test-multiuser1-app-auto-open")
        autoOpen(appId: appId, openType: .pbs(partitionValueB)) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                XCTAssertNotNil(realm)
                self.checkCount(expected: 0, realm, SwiftHugeSyncObject.self)
                ex.fulfill()
            }
        }

        app.switch(to: syncUser1)
        XCTAssertEqual(app.allUsers.count, 2)
        XCTAssertEqual(syncUser1.id, app.currentUser!.id)

        let ex2 = expectation(description: "test-multiuser2-app-auto-open")
        autoOpen(appId: appId, openType: .pbs(partitionValueA)) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                XCTAssertNotNil(realm)
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                ex2.fulfill()
            }
        }
    }

    func testAutoOpenWithUserAfterLogoutFromAnonymous() throws {
        let partitionValueA = #function
        let partitionValueB = "\(#function)bar"

        _ = try logInUser(for: .anonymous)
        let ex = expectation(description: "download-realm-anonymous-user-auto-open")
        autoOpen(appId: appId, openType: .pbs(partitionValueA)) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                XCTAssertNotNil(realm)
                self.checkCount(expected: 0, realm, SwiftHugeSyncObject.self)
                ex.fulfill()
            }
        }

        app.currentUser?.logOut { _ in } // Logout anonymous user

        let user = try logInUser(for: basicCredentials())
        if !isParent {
            return try populateRealm(user: user, partitionValue: partitionValueB)
        }
        executeChild()

        let ex2 = expectation(description: "download-realm-after-logout-auto-open")
        autoOpen(appId: appId, openType: .pbs(partitionValueB)) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                XCTAssertNotNil(realm)
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                ex2.fulfill()
            }
        }
    }

    func testAutoOpenWithDifferentPartitionValues() throws {
        let partitionValueA = #function
        let partitionValueB = "\(#function)bar"

        let user = try logInUser(for: basicCredentials())
        if !isParent {
            return try populateRealm(user: user, partitionValue: partitionValueA)
        }
        executeChild()

        let ex = expectation(description: "download-partition-value-auto-open")
        autoOpen(openType: .pbs(partitionValueA)) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                XCTAssertNotNil(realm)
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                ex.fulfill()
            }
        }

        let ex2 = expectation(description: "download-other-partition-value-auto-open")
        autoOpen(openType: .pbs(partitionValueB)) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                XCTAssertNotNil(realm)
                self.checkCount(expected: 0, realm, SwiftHugeSyncObject.self)
                ex2.fulfill()
            }
        }
    }

    // MARK: - Mixed AsyncOpen & AutoOpen
    func testCombineAsyncOpenAutoOpenWithDifferentPartitionValues() throws {
        let partitionValueA = #function
        let partitionValueB = "\(#function)bar"

        let user = try logInUser(for: basicCredentials())
        if !isParent {
            return try populateRealm(user: user, partitionValue: partitionValueA)
        }
        executeChild()

        let ex = expectation(description: "download-partition-value-async-open-mixed")
        asyncOpen(openType: .pbs(partitionValueA)) { asyncOpenState in
            if case let .open(realm) = asyncOpenState {
                XCTAssertNotNil(realm)
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                ex.fulfill()
            }
        }

        let ex2 = expectation(description: "download-partition-value-auto-open-mixed")
        autoOpen(openType: .pbs(partitionValueB)) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                XCTAssertNotNil(realm)
                self.checkCount(expected: 0, realm, SwiftHugeSyncObject.self)
                ex2.fulfill()
            }
        }
    }

    func testCombineAsyncOpenAutoOpenWithMultiUserApp() throws {
        let partitionValueA = #function
        let partitionValueB = "\(#function)bar"

        let syncUser1 = try logInUser(for: basicCredentials())
        let syncUser2 = try logInUser(for: basicCredentials())
        XCTAssertEqual(app.allUsers.count, 2)
        XCTAssertEqual(syncUser2.id, app.currentUser!.id)

        if !isParent {
            return try populateRealm(user: syncUser1, partitionValue: partitionValueA)
        }
        executeChild()

        let ex = expectation(description: "test-combine-multiuser1-app-auto-open")
        autoOpen(appId: appId, openType: .pbs(partitionValueB)) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                XCTAssertNotNil(realm)
                self.checkCount(expected: 0, realm, SwiftHugeSyncObject.self)
                ex.fulfill()
            }
        }

        app.switch(to: syncUser1)
        XCTAssertEqual(app.allUsers.count, 2)
        XCTAssertEqual(syncUser1.id, app.currentUser!.id)

        let ex2 = expectation(description: "test-combine-multiuser2-app-auto-open")
        asyncOpen(appId: appId, openType: .pbs(partitionValueA)) { asyncOpenState in
            if case let .open(realm) = asyncOpenState {
                XCTAssertNotNil(realm)
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                ex2.fulfill()
            }
        }
    }

    func testAutoOpenFlexibleSyncInit() throws {
        try populateFlexibleSyncData { realm in
            for i in 1...10 {
                // Using firstname to query only objects from this test
                let person = SwiftPerson(firstName: "\(#function)",
                                         lastName: "lastname_\(i)",
                                         age: i)
                realm.add(person)
            }
        }

        _ = try logInUser(for: basicCredentials(app: flexibleSyncApp), app: flexibleSyncApp)

        let ex = expectation(description: "download-realm-flexible-async-open")
        autoOpen(appId: flexibleSyncAppId, openType: .flexibleSync, timeout: 1000) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                XCTAssertNotNil(realm)
                XCTAssertTrue(realm.isEmpty) // should not have downloaded anything, because there are no subscriptions
                ex.fulfill()
            }
        }
    }

    func testAutoOpenFlexibleSyncConfiguration() throws {
        try populateFlexibleSyncData { realm in
            for i in 1...10 {
                // Using firstname to query only objects from this test
                let person = SwiftPerson(firstName: "\(#function)",
                                         lastName: "lastname_\(i)",
                                         age: i)
                realm.add(person)
            }
        }

        let user = try logInUser(for: basicCredentials(app: flexibleSyncApp), app: flexibleSyncApp)

        var configuration = user.flexibleSyncConfiguration(initialSubscriptions: { subs in
            subs.append(QuerySubscription<SwiftPerson> {
                $0.firstName == "\(#function)" && $0.age > 0
            })
        })
        configuration.objectTypes = [SwiftPerson.self]

        let ex = expectation(description: "download-realm-flexible-async-open")
        autoOpen(appId: flexibleSyncAppId, openType: .configuration(configuration), timeout: 1000) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                XCTAssertNotNil(realm)
                self.checkCount(expected: 10, realm, SwiftPerson.self)
                ex.fulfill()
            }
        }
    }

    func testAutoOpenPBSWithConfiguration() throws {
        let user = try logInUser(for: basicCredentials())
        if !isParent {
            populateRealm(user: user, partitionValue: #function)
            return
        }
        executeChild()

        var configuration = user.configuration(partitionValue: #function)
        configuration.objectTypes = [SwiftHugeSyncObject.self]

        let ex = expectation(description: "download-populated-realm-async-open")
        autoOpen(appId: appId, openType: .configuration(configuration)) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                XCTAssertNotNil(realm)
                self.checkCount(expected: SwiftSyncTestCase.bigObjectCount, realm, SwiftHugeSyncObject.self)
                ex.fulfill()
            }
        }
    }

    func testAutoOpenPBSWithClientReset() throws {
        let user = try logInUser(for: basicCredentials())
        var configuration = user.configuration(partitionValue: #function, clientResetMode: .manual(errorHandler: { _, _ in }))
        configuration.objectTypes = [SwiftPerson.self]

        let ex = expectation(description: "download-populated-realm-async-open")
        autoOpen(appId: appId, openType: .configuration(configuration)) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                XCTAssertNotNil(realm)
                switch configuration.syncConfiguration!.clientResetMode {
                case .manual(let block):
                    XCTAssertNotNil(block)
                default:
                    XCTFail("Should be set to manual")
                }
                ex.fulfill()
            }
        }
    }

    func testAutoOpenFlexibleSyncWithClientReset() throws {
        let user = try logInUser(for: basicCredentials(app: flexibleSyncApp), app: flexibleSyncApp)
        var configuration = user.flexibleSyncConfiguration(clientResetMode: .manual(errorHandler: { _, _ in }))
        configuration.objectTypes = [SwiftPerson.self]

        let ex = expectation(description: "download-populated-realm-async-open")
        autoOpen(appId: flexibleSyncAppId, openType: .configuration(configuration)) { autoOpenState in
            if case let .open(realm) = autoOpenState {
                XCTAssertNotNil(realm)
                switch configuration.syncConfiguration!.clientResetMode {
                case .manual(let block):
                    XCTAssertNotNil(block)
                default:
                    XCTFail("Should be set to manual")
                }
                ex.fulfill()
            }
        }
    }
}
