////////////////////////////////////////////////////////////////////////////
//
// Copyright 2023 Realm Inc.
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

import Realm
import Realm.Private
import RealmSwift
import XCTest

#if canImport(RealmTestSupport)
import RealmSwiftSyncTestSupport
import RealmSyncTestSupport
import RealmTestSupport
import RealmSwiftTestSupport
#endif

// Uses admin API to toggle recovery mode on the baas server
func waitForEditRecoveryMode(flexibleSync: Bool = false, appId: String, disable: Bool) throws {
    // Retrieve server IDs
    let appServerId = try RealmServer.shared.retrieveAppServerId(appId)
    let syncServiceId = try RealmServer.shared.retrieveSyncServiceId(appServerId: appServerId)
    guard let syncServiceConfig = try RealmServer.shared.getSyncServiceConfiguration(appServerId: appServerId, syncServiceId: syncServiceId) else { fatalError("precondition failure: no sync service configuration found") }

    _ = try RealmServer.shared.patchRecoveryMode(
        flexibleSync: flexibleSync, disable: disable, appServerId,
        syncServiceId, syncServiceConfig).get()
}

@available(macOS 13, *)
class ClientResetTests: SwiftSyncTestCase {
    @MainActor
    func prepareClientReset(app: App? = nil) throws -> User {
        let app = app ?? self.app
        let config = try configuration(app: app)
        let user = config.syncConfiguration!.user
        try autoreleasepool {
            let realm = try openRealm(configuration: config)
            realm.syncSession!.suspend()

            try RealmServer.shared.triggerClientReset(app.appId, realm)

            // Add an object to the local realm that won't be synced due to the suspend
            try realm.write {
                realm.add(SwiftPerson(firstName: "John", lastName: name))
            }
        }

        // Add an object which should be present post-reset
        try write(app: app) { realm in
            realm.add(SwiftPerson(firstName: "Paul", lastName: self.name))
        }

        return user
    }

    @MainActor
    func expectSyncError(_ fn: () -> Void) -> SyncError? {
        let error = Locked(SyncError?.none)
        let ex = expectation(description: "Waiting for error handler to be called...")
        app.syncManager.errorHandler = { @Sendable (e, _) in
            if let e = e as? SyncError {
                error.value = e
            } else {
                XCTFail("Error \(e) was not a sync error. Something is wrong.")
            }
            ex.fulfill()
        }

        fn()

        waitForExpectations(timeout: 10, handler: nil)
        XCTAssertNotNil(error.value)
        return error.value
    }

    func assertManualClientReset(_ user: User, app: App) -> ErrorReportingBlock {
        let ex = self.expectation(description: "get client reset error")
        return { error, session in
            guard let error = error as? SyncError else {
                return XCTFail("Bad error type: \(error)")
            }
            XCTAssertEqual(error.code, .clientResetError)
            XCTAssertEqual(session?.state, .inactive)
            XCTAssertEqual(session?.connectionState, .disconnected)
            XCTAssertEqual(session?.parentUser()?.id, user.id)
            guard let (path, token) = error.clientResetInfo() else {
                return XCTAssertNotNil(error.clientResetInfo())
            }
            XCTAssertTrue(path.contains("mongodb-realm/\(app.appId)/recovered-realms/recovered_realm"))
            XCTAssertFalse(FileManager.default.fileExists(atPath: path))
            SyncSession.immediatelyHandleError(token)
            XCTAssertTrue(FileManager.default.fileExists(atPath: path))
            ex.fulfill()
        }
    }

    func assertDiscardLocal() -> (@Sendable (Realm) -> Void, @Sendable (Realm, Realm) -> Void) {
        let beforeCallbackEx = expectation(description: "before reset callback")
        @Sendable func beforeClientReset(_ before: Realm) {
            let results = before.objects(SwiftPerson.self)
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual(results.filter("firstName == 'John'").count, 1)

            beforeCallbackEx.fulfill()
        }
        let afterCallbackEx = expectation(description: "before reset callback")
        @Sendable func afterClientReset(_ before: Realm, _ after: Realm) {
            let results = before.objects(SwiftPerson.self)
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual(results.filter("firstName == 'John'").count, 1)

            let results2 = after.objects(SwiftPerson.self)
            XCTAssertEqual(results2.count, 1)
            XCTAssertEqual(results2.filter("firstName == 'Paul'").count, 1)

            // Fulfill on the main thread to make it harder to hit a race
            // condition where the test completes before the client reset finishes
            // unwinding. This does not fully fix the problem.
            DispatchQueue.main.async {
                afterCallbackEx.fulfill()
            }
        }
        return (beforeClientReset, afterClientReset)
    }

    func assertRecover() -> (@Sendable (Realm) -> Void, @Sendable (Realm, Realm) -> Void) {
        let beforeCallbackEx = expectation(description: "before reset callback")
        @Sendable func beforeClientReset(_ before: Realm) {
            let results = before.objects(SwiftPerson.self)
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual(results.filter("firstName == 'John'").count, 1)
            beforeCallbackEx.fulfill()
        }
        let afterCallbackEx = expectation(description: "after reset callback")
        @Sendable func afterClientReset(_ before: Realm, _ after: Realm) {
            let results = before.objects(SwiftPerson.self)
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual(results.filter("firstName == 'John'").count, 1)

            let results2 = after.objects(SwiftPerson.self)
            XCTAssertEqual(results2.count, 2)
            XCTAssertEqual(results2.filter("firstName == 'John'").count, 1)
            XCTAssertEqual(results2.filter("firstName == 'Paul'").count, 1)

            // Fulfill on the main thread to make it harder to hit a race
            // condition where the test completes before the client reset finishes
            // unwinding. This does not fully fix the problem.
            DispatchQueue.main.async {
                afterCallbackEx.fulfill()
            }
        }
        return (beforeClientReset, afterClientReset)
    }

    func verifyClientResetDiscardedLocalChanges(_ user: User) throws {
        try autoreleasepool {
            var configuration = user.configuration(partitionValue: name)
            configuration.objectTypes = [SwiftPerson.self]

            let realm = try Realm(configuration: configuration)
            waitForDownloads(for: realm)
            // After reopening, the old Realm file should have been moved aside
            // and we should now have the data from the server
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
            XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "Paul")
        }
    }
}

@available(macOS 13, *)
class PBSClientResetTests: ClientResetTests {
    @MainActor
    func testClientResetManual() throws {
        let user = try prepareClientReset()
        try autoreleasepool {
            var configuration = user.configuration(partitionValue: name, clientResetMode: .manual())
            configuration.objectTypes = [SwiftPerson.self]

            let syncManager = app.syncManager
            syncManager.errorHandler = assertManualClientReset(user, app: app)

            try autoreleasepool {
                let realm = try Realm(configuration: configuration)
                waitForExpectations(timeout: 15.0)
                realm.refresh()
                // The locally created object should still be present as we didn't
                // actually handle the client reset
                XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
                XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "John")
            }
        }
        app.syncManager.waitForSessionTermination()
        try verifyClientResetDiscardedLocalChanges(user)
    }

    @MainActor
    func testClientResetManualWithEnumCallback() throws {
        let user = try prepareClientReset()
        try autoreleasepool {
            var configuration = user.configuration(partitionValue: name, clientResetMode: .manual(errorHandler: assertManualClientReset(user, app: app)))
            configuration.objectTypes = [SwiftPerson.self]

            switch configuration.syncConfiguration!.clientResetMode {
            case .manual(let block):
                XCTAssertNotNil(block)
            default:
                XCTFail("Should be set to manual")
            }

            try autoreleasepool {
                let realm = try Realm(configuration: configuration)
                waitForExpectations(timeout: 15.0)
                realm.refresh()
                // The locally created object should still be present as we didn't
                // actually handle the client reset
                XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
                XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "John")
            }
        }
        try verifyClientResetDiscardedLocalChanges(user)
    }

    @MainActor
    func testClientResetManualManagerFallback() throws {
        let user = try prepareClientReset()

        try autoreleasepool {
            // No callback is passed into enum `.manual`, but a syncManager.errorHandler exists,
            // so expect that to be used instead.
            var configuration = user.configuration(partitionValue: name, clientResetMode: .manual())
            configuration.objectTypes = [SwiftPerson.self]

            let syncManager = self.app.syncManager
            syncManager.errorHandler = assertManualClientReset(user, app: app)

            try autoreleasepool {
                let realm = try Realm(configuration: configuration)
                waitForExpectations(timeout: 15.0) // Wait for expectations in asssertManualClientReset
                // The locally created object should still be present as we didn't
                // actually handle the client reset
                XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
                XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "John")
            }
        }

        try verifyClientResetDiscardedLocalChanges(user)
    }

    // If the syncManager.ErrorHandler and manual enum callback
    // are both set, use the enum callback.
    @MainActor
    func testClientResetManualEnumCallbackNotManager() throws {
        let user = try prepareClientReset()

        try autoreleasepool {
            var configuration = user.configuration(partitionValue: name, clientResetMode: .manual(errorHandler: assertManualClientReset(user, app: app)))
            configuration.objectTypes = [SwiftPerson.self]

            switch configuration.syncConfiguration!.clientResetMode {
            case .manual(let block):
                XCTAssertNotNil(block)
            default:
                XCTFail("Should be set to manual")
            }

            let syncManager = self.app.syncManager
            syncManager.errorHandler = { error, _ in
                guard error is SyncError else {
                    return XCTFail("Bad error type: \(error)")
                }
                XCTFail("Expected the syncManager.ErrorHandler to not be called")
            }

            try autoreleasepool {
                let realm = try Realm(configuration: configuration)
                waitForExpectations(timeout: 15.0)
                // The locally created object should still be present as we didn't
                // actually handle the client reset
                XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
                XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "John")
            }
        }

        try verifyClientResetDiscardedLocalChanges(user)
    }

    @MainActor
    func testClientResetManualWithoutLiveRealmInstance() throws {
        let user = try prepareClientReset()

        var configuration = user.configuration(partitionValue: name, clientResetMode: .manual())
        configuration.objectTypes = [SwiftPerson.self]

        let syncManager = app.syncManager
        syncManager.errorHandler = assertManualClientReset(user, app: app)

        try autoreleasepool {
            _ = try Realm(configuration: configuration)
            // We have to wait for the error to arrive (or the session will just
            // transition to inactive without calling the error handler), but we
            // need to ensure the Realm is deallocated before the error handler
            // is invoked on the main thread.
            sleep(1)
        }
        waitForExpectations(timeout: 15.0)
        syncManager.waitForSessionTermination()
        resetSyncManager()
    }

    @MainActor
    @available(*, deprecated) // .discardLocal
    func testClientResetDiscardLocal() throws {
        let user = try prepareClientReset()

        let (assertBeforeBlock, assertAfterBlock) = assertDiscardLocal()
        var configuration = user.configuration(partitionValue: name,
                                               clientResetMode: .discardLocal(beforeReset: assertBeforeBlock, afterReset: assertAfterBlock))
        configuration.objectTypes = [SwiftPerson.self]

        let syncConfig = try XCTUnwrap(configuration.syncConfiguration)
        switch syncConfig.clientResetMode {
        case .discardUnsyncedChanges(let before, let after):
            XCTAssertNotNil(before)
            XCTAssertNotNil(after)
        default:
            XCTFail("Should be set to discardLocal")
        }

        try autoreleasepool {
            let realm = try Realm(configuration: configuration)
            let results = realm.objects(SwiftPerson.self)
            XCTAssertEqual(results.count, 1)
            waitForExpectations(timeout: 15.0)
            realm.refresh() // expectation is potentially fulfilled before autorefresh
            // The Person created locally ("John") should have been discarded,
            // while the one from the server ("Paul") should be present
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
            XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "Paul")
        }
    }

    @MainActor
    func testClientResetDiscardUnsyncedChanges() throws {
        let user = try prepareClientReset()

        let (assertBeforeBlock, assertAfterBlock) = assertDiscardLocal()
        var configuration = user.configuration(partitionValue: name,
                                               clientResetMode: .discardUnsyncedChanges(beforeReset: assertBeforeBlock, afterReset: assertAfterBlock))
        configuration.objectTypes = [SwiftPerson.self]

        guard let syncConfig = configuration.syncConfiguration else { fatalError("Test condition failure. SyncConfiguration not set.") }
        switch syncConfig.clientResetMode {
        case .discardUnsyncedChanges(let before, let after):
            XCTAssertNotNil(before)
            XCTAssertNotNil(after)
        default:
            XCTFail("Should be set to discardUnsyncedChanges")
        }

        try autoreleasepool {
            let realm = try Realm(configuration: configuration)
            waitForExpectations(timeout: 15.0)
            realm.refresh()
            // The Person created locally ("John") should have been discarded,
            // while the one from the server ("Paul") should be present
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
            XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "Paul")
        }
    }

    @MainActor
    @available(*, deprecated) // .discardLocal
    func testClientResetDiscardLocalAsyncOpen() throws {
        let user = try prepareClientReset()

        let (assertBeforeBlock, assertAfterBlock) = assertDiscardLocal()
        var configuration = user.configuration(partitionValue: name, clientResetMode: .discardLocal(beforeReset: assertBeforeBlock, afterReset: assertAfterBlock))
        configuration.objectTypes = [SwiftPerson.self]

        let asyncOpenEx = expectation(description: "async open")
        Realm.asyncOpen(configuration: configuration) { result in
            let realm = try! result.get()
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
            XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "Paul")
            asyncOpenEx.fulfill()
        }
        waitForExpectations(timeout: 15.0)
    }

    @MainActor
    func testClientResetRecover() throws {
        let user = try prepareClientReset()

        let (assertBeforeBlock, assertAfterBlock) = assertRecover()
        var configuration = user.configuration(partitionValue: name, clientResetMode: .recoverUnsyncedChanges(beforeReset: assertBeforeBlock, afterReset: assertAfterBlock))
        configuration.objectTypes = [SwiftPerson.self]

        let syncConfig = try XCTUnwrap(configuration.syncConfiguration)
        switch syncConfig.clientResetMode {
        case .recoverUnsyncedChanges(let before, let after):
            XCTAssertNotNil(before)
            XCTAssertNotNil(after)
        default:
            XCTFail("Should be set to recover")
        }
        try autoreleasepool {
            let realm = try Realm(configuration: configuration)
            waitForExpectations(timeout: 15.0)
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 2)
            // The object created locally (John) and the object created on the server (Paul)
            // should both be integrated into the new realm file.
            XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "John")
            XCTAssertEqual(realm.objects(SwiftPerson.self)[1].firstName, "Paul")
        }
    }

    @MainActor
    func testClientResetRecoverAsyncOpen() throws {
        let user = try prepareClientReset()

        let (assertBeforeBlock, assertAfterBlock) = assertRecover()
        var configuration = user.configuration(partitionValue: name, clientResetMode: .recoverUnsyncedChanges(beforeReset: assertBeforeBlock, afterReset: assertAfterBlock))
        configuration.objectTypes = [SwiftPerson.self]

        let syncConfig = try XCTUnwrap(configuration.syncConfiguration)
        switch syncConfig.clientResetMode {
        case .recoverUnsyncedChanges(let before, let after):
            XCTAssertNotNil(before)
            XCTAssertNotNil(after)
        default:
            XCTFail("Should be set to recover")
        }
        autoreleasepool {
            let realm = Realm.asyncOpen(configuration: configuration).await(self)
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 2)
            // The object created locally (John) and the object created on the server (Paul)
            // should both be integrated into the new realm file.
            XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "John")
            XCTAssertEqual(realm.objects(SwiftPerson.self)[1].firstName, "Paul")
            waitForExpectations(timeout: 15.0)
        }
    }

    @MainActor
    func testClientResetRecoverWithSchemaChanges() throws {
        let user = try prepareClientReset()

        let beforeCallbackEx = expectation(description: "before reset callback")
        @Sendable func beforeClientReset(_ before: Realm) {
            let person = before.objects(SwiftPersonWithAdditionalProperty.self).first!
            XCTAssertEqual(person.objectSchema.properties.map(\.name),
                           ["_id", "firstName", "lastName", "age", "newProperty"])
            XCTAssertEqual(person.newProperty, 0)
            beforeCallbackEx.fulfill()
        }
        let afterCallbackEx = expectation(description: "after reset callback")
        @Sendable func afterClientReset(_ before: Realm, _ after: Realm) {
            let beforePerson = before.objects(SwiftPersonWithAdditionalProperty.self).first!
            XCTAssertEqual(beforePerson.objectSchema.properties.map(\.name),
                           ["_id", "firstName", "lastName", "age", "newProperty"])
            XCTAssertEqual(beforePerson.newProperty, 0)
            let afterPerson = after.objects(SwiftPersonWithAdditionalProperty.self).first!
            XCTAssertEqual(afterPerson.objectSchema.properties.map(\.name),
                           ["_id", "firstName", "lastName", "age", "newProperty"])
            XCTAssertEqual(afterPerson.newProperty, 0)

            // Fulfill on the main thread to make it harder to hit a race
            // condition where the test completes before the client reset finishes
            // unwinding. This does not fully fix the problem.
            DispatchQueue.main.async {
                afterCallbackEx.fulfill()
            }
        }

        var configuration = user.configuration(partitionValue: name, clientResetMode: .recoverUnsyncedChanges(beforeReset: beforeClientReset, afterReset: afterClientReset))
        configuration.objectTypes = [SwiftPersonWithAdditionalProperty.self]

        autoreleasepool {
            _ = Realm.asyncOpen(configuration: configuration).await(self)
            waitForExpectations(timeout: 15.0)
        }
    }

    @MainActor
    func testClientResetRecoverOrDiscardLocalFailedRecovery() throws {
        let appId = try RealmServer.shared.createApp(types: [SwiftPerson.self])
        // Disable recovery mode on the server.
        // This attempts to simulate a case where recovery mode fails when
        // using RecoverOrDiscardLocal
        try waitForEditRecoveryMode(appId: appId, disable: true)

        let user = try prepareClientReset(app: self.app(id: appId))
        // Expect the recovery to fail back to discardLocal logic
        let (assertBeforeBlock, assertAfterBlock) = assertDiscardLocal()
        var configuration = user.configuration(partitionValue: name, clientResetMode: .recoverOrDiscardUnsyncedChanges(beforeReset: assertBeforeBlock, afterReset: assertAfterBlock))
        configuration.objectTypes = [SwiftPerson.self]

        let syncConfig = try XCTUnwrap(configuration.syncConfiguration)
        switch syncConfig.clientResetMode {
        case .recoverOrDiscardUnsyncedChanges(let before, let after):
            XCTAssertNotNil(before)
            XCTAssertNotNil(after)
        default:
            XCTFail("Should be set to recoverOrDiscard")
        }

        // Expect the recovery to fail back to discardLocal logic
        try autoreleasepool {
            let realm = try Realm(configuration: configuration)
            waitForExpectations(timeout: 15.0)
            realm.refresh()
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
            // The Person created locally ("John") should have been discarded,
            // while the one from the server ("Paul") should be present.
            XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "Paul")
        }
    }
}

@available(macOS 13, *)
class FLXClientResetTests: ClientResetTests {
    override func createApp() throws -> String {
        try createFlexibleSyncApp()
    }

    override func configuration(user: User) -> Realm.Configuration {
        let name = self.name
        return user.flexibleSyncConfiguration { subscriptions in
            subscriptions.append(QuerySubscription<SwiftPerson> { $0.lastName == name })
        }
    }

    @MainActor
    @available(*, deprecated) // .discardLocal
    func testFlexibleSyncDiscardLocalClientReset() throws {
        let user = try prepareClientReset()

        let (assertBeforeBlock, assertAfterBlock) = assertDiscardLocal()
        var config = user.flexibleSyncConfiguration(clientResetMode: .discardLocal(beforeReset: assertBeforeBlock, afterReset: assertAfterBlock))
        config.objectTypes = [SwiftPerson.self]
        let syncConfig = try XCTUnwrap(config.syncConfiguration)
        switch syncConfig.clientResetMode {
        case .discardUnsyncedChanges(let before, let after):
            XCTAssertNotNil(before)
            XCTAssertNotNil(after)
        default:
            XCTFail("Should be set to discardUnsyncedChanges")
        }

        try autoreleasepool {
            XCTAssertEqual(user.flexibleSyncConfiguration().fileURL, config.fileURL)
            let realm = try Realm(configuration: config)
            let subscriptions = realm.subscriptions
            XCTAssertEqual(subscriptions.count, 1) // subscription created during prepareFlexibleSyncClientReset

            waitForExpectations(timeout: 15.0)
            realm.refresh()
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
            XCTAssertEqual(realm.objects(SwiftPerson.self).first?.firstName, "Paul")
        }
    }

    @MainActor
    func testFlexibleSyncDiscardUnsyncedChangesClientReset() throws {
        let user = try prepareClientReset()

        let (assertBeforeBlock, assertAfterBlock) = assertDiscardLocal()
        var config = user.flexibleSyncConfiguration(clientResetMode: .discardUnsyncedChanges(beforeReset: assertBeforeBlock, afterReset: assertAfterBlock))
        config.objectTypes = [SwiftPerson.self]
        let syncConfig = try XCTUnwrap(config.syncConfiguration)
        switch syncConfig.clientResetMode {
        case .discardUnsyncedChanges(let before, let after):
            XCTAssertNotNil(before)
            XCTAssertNotNil(after)
        default:
            XCTFail("Should be set to discardUnsyncedChanges")
        }

        try autoreleasepool {
            XCTAssertEqual(user.flexibleSyncConfiguration().fileURL, config.fileURL)
            let realm = try Realm(configuration: config)
            let subscriptions = realm.subscriptions
            XCTAssertEqual(subscriptions.count, 1) // subscription created during prepareFlexibleSyncClientReset

            waitForExpectations(timeout: 15.0)
            realm.refresh()
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
            XCTAssertEqual(realm.objects(SwiftPerson.self).first?.firstName, "Paul")
        }
    }

    @MainActor
    func testFlexibleSyncClientResetRecover() throws {
        let user = try prepareClientReset()

        let (assertBeforeBlock, assertAfterBlock) = assertRecover()
        var config = user.flexibleSyncConfiguration(clientResetMode: .recoverUnsyncedChanges(beforeReset: assertBeforeBlock, afterReset: assertAfterBlock))
        config.objectTypes = [SwiftPerson.self]
        let syncConfig = try XCTUnwrap(config.syncConfiguration)
        switch syncConfig.clientResetMode {
        case .recoverUnsyncedChanges(let before, let after):
            XCTAssertNotNil(before)
            XCTAssertNotNil(after)
        default:
            XCTFail("Should be set to recover")
        }

        try autoreleasepool {
            XCTAssertEqual(user.flexibleSyncConfiguration().fileURL, config.fileURL)
            let realm = try Realm(configuration: config)
            let subscriptions = realm.subscriptions
            XCTAssertEqual(subscriptions.count, 1) // subscription created during prepareFlexibleSyncClientReset

            waitForExpectations(timeout: 15.0) // wait for expectations in assertRecover
            realm.refresh()
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 2)
            // The object created locally (John) and the object created on the server (Paul)
            // should both be integrated into the new realm file.
            XCTAssertEqual(realm.objects(SwiftPerson.self).filter("firstName == 'John'").count, 1)
            XCTAssertEqual(realm.objects(SwiftPerson.self).filter("firstName == 'Paul'").count, 1)
        }
    }

    @MainActor
    func testFlexibleSyncClientResetRecoverOrDiscardLocalFailedRecovery() throws {
        let appId = try RealmServer.shared.createApp(fields: ["lastName"], types: [SwiftPerson.self])
        try waitForEditRecoveryMode(flexibleSync: true, appId: appId, disable: true)
        let user = try prepareClientReset(app: app(id: appId))

        // Expect the client reset process to discard the local changes
        let (assertBeforeBlock, assertAfterBlock) = assertDiscardLocal()
        var config = user.flexibleSyncConfiguration(clientResetMode: .recoverOrDiscardUnsyncedChanges(beforeReset: assertBeforeBlock, afterReset: assertAfterBlock))
        config.objectTypes = [SwiftPerson.self]
        guard let syncConfig = config.syncConfiguration else {
            fatalError("Test condition failure. SyncConfiguration not set.")
        }
        switch syncConfig.clientResetMode {
        case .recoverOrDiscardUnsyncedChanges(let before, let after):
            XCTAssertNotNil(before)
            XCTAssertNotNil(after)
        default:
            XCTFail("Should be set to recoverOrDiscard")
        }

        try autoreleasepool {
            XCTAssertEqual(user.flexibleSyncConfiguration().fileURL, config.fileURL)
            let realm = try Realm(configuration: config)
            let subscriptions = realm.subscriptions
            XCTAssertEqual(subscriptions.count, 1) // subscription created during prepareFlexibleSyncClientReset

            waitForExpectations(timeout: 15.0)
            realm.refresh()
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
            // The Person created locally ("John") should have been discarded,
            // while the one from the server ("Paul") should be present.
            XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "Paul")
        }
    }

    @MainActor
    func testFlexibleClientResetManual() throws {
        let user = try prepareClientReset()
        try autoreleasepool {
            var config = user.flexibleSyncConfiguration(clientResetMode: .manual(errorHandler: assertManualClientReset(user, app: app)))
            config.objectTypes = [SwiftPerson.self]

            switch config.syncConfiguration!.clientResetMode {
            case .manual(let block):
                XCTAssertNotNil(block)
            default:
                XCTFail("Should be set to manual")
            }
            try autoreleasepool {
                let realm = try Realm(configuration: config)
                waitForExpectations(timeout: 15.0)
                // The locally created object should still be present as we didn't
                // actually handle the client reset
                XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
                XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "John")
            }
        }

        let name = self.name
        var config = user.flexibleSyncConfiguration { subscriptions in
            subscriptions.append(QuerySubscription<SwiftPerson> { $0.lastName == name })
        }
        config.objectTypes = [SwiftPerson.self]

        try autoreleasepool {
            let realm = try openRealm(configuration: config)
            XCTAssertEqual(realm.subscriptions.count, 1)

            // After reopening, the old Realm file should have been moved aside
            // and we should now have the data from the server
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
            XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "Paul")
        }
    }

    func testDefaultClientResetMode() throws {
        let user = createUser()
        let fConfig = user.flexibleSyncConfiguration()
        let pConfig = user.configuration(partitionValue: name)

        switch fConfig.syncConfiguration!.clientResetMode {
        case .recoverUnsyncedChanges:
            return
        default:
            XCTFail("expected recover mode")
        }
        switch pConfig.syncConfiguration!.clientResetMode {
        case .recoverUnsyncedChanges:
            return
        default:
            XCTFail("expected recover mode")
        }
    }
}

#endif // os(macOS)
