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
import RealmSwift
import XCTest

#if canImport(RealmTestSupport)
import RealmSwiftSyncTestSupport
import RealmSyncTestSupport
import RealmTestSupport
#endif

func assertAppError(_ error: AppError, _ code: AppError.Code, _ message: String,
                    line: UInt = #line, file: StaticString = #file) {
    XCTAssertEqual(error.code, code, file: file, line: line)
    XCTAssertEqual(error.localizedDescription, message, file: file, line: line)
}

@available(OSX 10.14, *)
@objc(SwiftObjectServerTests)
class SwiftObjectServerTests: SwiftSyncTestCase {
    func setupMongoCollection(user: User, collectionName: String) -> MongoCollection {
        let mongoClient = user.mongoClient("mongodb1")
        let database = mongoClient.database(named: "test_data")
        let collection = database.collection(withName: collectionName)
        removeAllFromCollection(collection)
        return collection
    }

    /// It should be possible to successfully open a Realm configured for sync.
    func testBasicSwiftSync() throws {
        let user = try logInUser(for: basicCredentials())
        let realm = try openRealm(partitionValue: #function, user: user)
        XCTAssert(realm.isEmpty, "Freshly synced Realm was not empty...")
    }

    func testBasicSwiftSyncWithAnyBSONPartitionValue() throws {
        let user = try logInUser(for: basicCredentials())
        let realm = try openRealm(partitionValue: .string(#function), user: user)
        XCTAssert(realm.isEmpty, "Freshly synced Realm was not empty...")
    }

    /// If client B adds objects to a Realm, client A should see those new objects.
    func testSwiftAddObjects() throws {
        let user = try logInUser(for: basicCredentials())
        let realm = try openRealm(partitionValue: #function, user: user)
        if isParent {
            checkCount(expected: 0, realm, SwiftPerson.self)
            checkCount(expected: 0, realm, SwiftTypesSyncObject.self)
            executeChild()
            waitForDownloads(for: realm)
            checkCount(expected: 4, realm, SwiftPerson.self)
            checkCount(expected: 1, realm, SwiftTypesSyncObject.self)

            let obj = realm.objects(SwiftTypesSyncObject.self).first!
            XCTAssertEqual(obj.boolCol, true)
            XCTAssertEqual(obj.intCol, 1)
            XCTAssertEqual(obj.doubleCol, 1.1)
            XCTAssertEqual(obj.stringCol, "string")
            XCTAssertEqual(obj.binaryCol, "string".data(using: String.Encoding.utf8)!)
            XCTAssertEqual(obj.decimalCol, Decimal128(1))
            XCTAssertEqual(obj.dateCol, Date(timeIntervalSince1970: -1))
            XCTAssertEqual(obj.longCol, Int64(1))
            XCTAssertEqual(obj.uuidCol, UUID(uuidString: "85d4fbee-6ec6-47df-bfa1-615931903d7e")!)
            XCTAssertEqual(obj.anyCol.intValue, 1)
            XCTAssertEqual(obj.objectCol!.firstName, "George")

        } else {
            // Add objects
            try realm.write {
                realm.add(SwiftPerson(firstName: "Ringo", lastName: "Starr"))
                realm.add(SwiftPerson(firstName: "John", lastName: "Lennon"))
                realm.add(SwiftPerson(firstName: "Paul", lastName: "McCartney"))
                realm.add(SwiftTypesSyncObject(person: SwiftPerson(firstName: "George", lastName: "Harrison")))
            }
            waitForUploads(for: realm)
            checkCount(expected: 4, realm, SwiftPerson.self)
            checkCount(expected: 1, realm, SwiftTypesSyncObject.self)
        }
    }

    func testSwiftRountripForDistinctPrimaryKey() throws {
        let user = try logInUser(for: basicCredentials())
        let realm = try openRealm(partitionValue: #function, user: user)
        if isParent {
            checkCount(expected: 0, realm, SwiftPerson.self) // ObjectId
            checkCount(expected: 0, realm, SwiftUUIDPrimaryKeyObject.self)
            checkCount(expected: 0, realm, SwiftStringPrimaryKeyObject.self)
            checkCount(expected: 0, realm, SwiftIntPrimaryKeyObject.self)
            executeChild()
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
        } else {
            try realm.write {
                let swiftPerson = SwiftPerson(firstName: "Ringo", lastName: "Starr")
                swiftPerson._id = ObjectId("1234567890ab1234567890ab")
                realm.add(swiftPerson)
                realm.add(SwiftUUIDPrimaryKeyObject(id: UUID(uuidString: "85d4fbee-6ec6-47df-bfa1-615931903d7e")!, strCol: "Steve", intCol: 10))
                realm.add(SwiftStringPrimaryKeyObject(id: "1234567890ab1234567890ab", strCol: "Paul", intCol: 20))
                realm.add(SwiftIntPrimaryKeyObject(id: 1234567890, strCol: "Jackson", intCol: 30))
            }
            waitForUploads(for: realm)
            checkCount(expected: 1, realm, SwiftPerson.self)
            checkCount(expected: 1, realm, SwiftUUIDPrimaryKeyObject.self)
            checkCount(expected: 1, realm, SwiftStringPrimaryKeyObject.self)
            checkCount(expected: 1, realm, SwiftIntPrimaryKeyObject.self)
        }
    }

    func testSwiftAddObjectsWithNilPartitionValue() throws {
        let user = try logInUser(for: basicCredentials())
        let realm = try openRealm(partitionValue: .null, user: user)

        if isParent {
            // This test needs the database to be empty of any documents with a nil partition
            try realm.write {
                realm.deleteAll()
            }
            waitForUploads(for: realm)

            checkCount(expected: 0, realm, SwiftPerson.self)
            executeChild()
            waitForDownloads(for: realm)
            checkCount(expected: 3, realm, SwiftPerson.self)

            try realm.write {
                realm.deleteAll()
            }
            waitForUploads(for: realm)
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
    }

    /// If client B removes objects from a Realm, client A should see those changes.
    func testSwiftDeleteObjects() throws {
        let user = try logInUser(for: basicCredentials())
        let realm = try openRealm(partitionValue: #function, user: user)
        if isParent {
            try realm.write {
                realm.add(SwiftPerson(firstName: "Ringo", lastName: "Starr"))
                realm.add(SwiftPerson(firstName: "John", lastName: "Lennon"))
                realm.add(SwiftPerson(firstName: "Paul", lastName: "McCartney"))
                realm.add(SwiftTypesSyncObject(person: SwiftPerson(firstName: "George", lastName: "Harrison")))
            }
            waitForUploads(for: realm)
            checkCount(expected: 4, realm, SwiftPerson.self)
            checkCount(expected: 1, realm, SwiftTypesSyncObject.self)
            executeChild()
        } else {
            checkCount(expected: 4, realm, SwiftPerson.self)
            checkCount(expected: 1, realm, SwiftTypesSyncObject.self)
            try realm.write {
                realm.deleteAll()
            }
            waitForUploads(for: realm)
            checkCount(expected: 0, realm, SwiftPerson.self)
            checkCount(expected: 0, realm, SwiftTypesSyncObject.self)
        }
    }

    /// A client should be able to open multiple Realms and add objects to each of them.
    func testMultipleRealmsAddObjects() throws {
        let partitionValueA = #function
        let partitionValueB = "\(#function)bar"
        let partitionValueC = "\(#function)baz"

        let user = try logInUser(for: basicCredentials())

        let realmA = try openRealm(partitionValue: partitionValueA, user: user)
        let realmB = try openRealm(partitionValue: partitionValueB, user: user)
        let realmC = try openRealm(partitionValue: partitionValueC, user: user)

        if self.isParent {
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

            XCTAssertEqual(realmA.objects(SwiftPerson.self).filter("firstName == %@", "Ringo").count, 1)
            XCTAssertEqual(realmB.objects(SwiftPerson.self).filter("firstName == %@", "Ringo").count, 0)
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
    }

    func testConnectionState() throws {
        let user = try logInUser(for: basicCredentials())
        let realm = try immediatelyOpenRealm(partitionValue: #function, user: user)
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

    // MARK: - Client reset

    func waitForSyncDisabled(flexibleSync: Bool = false, appServerId: String, syncServiceId: String) {
        XCTAssertTrue(try RealmServer.shared.isSyncEnabled(flexibleSync: flexibleSync, appServerId: appServerId, syncServiceId: syncServiceId))
        _ = expectSuccess(RealmServer.shared.disableSync(
            flexibleSync: flexibleSync, appServerId: appServerId, syncServiceId: syncServiceId))
        XCTAssertFalse(try RealmServer.shared.isSyncEnabled(appServerId: appServerId, syncServiceId: syncServiceId))
    }

    func waitForSyncEnabled(flexibleSync: Bool = false, appServerId: String, syncServiceId: String, syncServiceConfig: [String: Any]) {
        _ = expectSuccess(RealmServer.shared.enableSync(
            flexibleSync: flexibleSync, appServerId: appServerId,
            syncServiceId: syncServiceId, syncServiceConfiguration: syncServiceConfig))
        XCTAssertTrue(try RealmServer.shared.isSyncEnabled(flexibleSync: flexibleSync, appServerId: appServerId, syncServiceId: syncServiceId))
    }

    func waitForDevModeEnabled(appServerId: String, syncServiceId: String, syncServiceConfig: [String: Any]) throws {
        let devModeEnabled = try RealmServer.shared.isDevModeEnabled(appServerId: appServerId, syncServiceId: syncServiceId)
        if !devModeEnabled {
            _ = expectSuccess(RealmServer.shared.enableDevMode(
                appServerId: appServerId, syncServiceId: syncServiceId,
                syncServiceConfiguration: syncServiceConfig))
        }
        XCTAssertTrue(try RealmServer.shared.isDevModeEnabled(appServerId: appServerId, syncServiceId: syncServiceId))
    }

    // Uses admin API to toggle recovery mode on the baas server
    func waitForEditRecoveryMode(flexibleSync: Bool = false, appId: String, disable: Bool) throws {
        // Retrieve server IDs
        let appServerId = try RealmServer.shared.retrieveAppServerId(appId)
        let syncServiceId = try RealmServer.shared.retrieveSyncServiceId(appServerId: appServerId)
        guard let syncServiceConfig = try RealmServer.shared.getSyncServiceConfiguration(appServerId: appServerId, syncServiceId: syncServiceId) else { fatalError("precondition failure: no sync service configuration found") }

        _ = expectSuccess(RealmServer.shared.patchRecoveryMode(
            flexibleSync: flexibleSync, disable: disable, appServerId,
            syncServiceId, syncServiceConfig))
    }

    // This function disables sync, executes a block while the sync service is disabled, then re-enables the sync service and dev mode.
    func executeBlockOffline(flexibleSync: Bool = false, appId: String, block: () throws -> Void) throws {
        let appServerId = try RealmServer.shared.retrieveAppServerId(appId)
        let syncServiceId = try RealmServer.shared.retrieveSyncServiceId(appServerId: appServerId)
        guard let syncServiceConfig = try RealmServer.shared.getSyncServiceConfiguration(appServerId: appServerId, syncServiceId: syncServiceId) else { fatalError("precondition failure: no sync service configuration found") }

        waitForSyncDisabled(flexibleSync: flexibleSync, appServerId: appServerId, syncServiceId: syncServiceId)

        try autoreleasepool(invoking: block)

        waitForSyncEnabled(flexibleSync: flexibleSync, appServerId: appServerId, syncServiceId: syncServiceId, syncServiceConfig: syncServiceConfig)
        try waitForDevModeEnabled(appServerId: appServerId, syncServiceId: syncServiceId, syncServiceConfig: syncServiceConfig)
    }

    func expectSyncError(_ fn: () -> Void) -> SyncError? {
        var error: SyncError?
        let ex = expectation(description: "Waiting for error handler to be called...")
        app.syncManager.errorHandler = { (e, _) in
            if let e = e as? SyncError {
                error = e
            } else {
                XCTFail("Error \(e) was not a sync error. Something is wrong.")
            }
            ex.fulfill()
        }

        fn()

        waitForExpectations(timeout: 10, handler: nil)
        XCTAssertNotNil(error)
        return error
    }

    func testClientReset() throws {
        let user = try logInUser(for: basicCredentials())
        let realm = try openRealm(partitionValue: #function, user: user, clientResetMode: .manual())

        let e = expectSyncError {
            user.simulateClientResetError(forSession: #function)
        }
        guard let error = e else { return }
        XCTAssertEqual(error.code, .clientResetError)
        XCTAssertNotNil(error.clientResetInfo())
        guard let resetInfo = error.clientResetInfo() else {
            return
        }
        XCTAssertTrue(resetInfo.0.contains("mongodb-realm/\(self.appId)/recovered-realms/recovered_realm"))
        XCTAssertNotNil(realm)
    }

    func testClientResetManualInitiation() throws {
        let user = try logInUser(for: basicCredentials())

        let e: SyncError? = try autoreleasepool {
            let realm = try openRealm(partitionValue: #function, user: user, clientResetMode: .manual())
            return expectSyncError {
                user.simulateClientResetError(forSession: #function)
                realm.invalidate()
            }
        }
        guard let error = e else { return }
        let (path, errorToken) = error.clientResetInfo()!
        XCTAssertFalse(FileManager.default.fileExists(atPath: path))
        SyncSession.immediatelyHandleError(errorToken, syncManager: self.app.syncManager)
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
    }

    // After restarting sync, the sync history translator service needs time
    // to resynthesize the new history from existing objects on the server
    // This method waits for the realm to receive "Paul" from the server
    // as confirmation.
    func waitForServerHistoryAfterRestart(realm: Realm) {
        let start = Date()
        while realm.isEmpty && start.timeIntervalSinceNow > -60.0 {
            self.waitForDownloads(for: realm)
            sleep(1) // Wait between requests
        }
        if realm.objects(SwiftPerson.self).count > 0 {
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
            XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "Paul")
        } else {
            XCTFail("Waited longer than one minute for history to resynthesize")
            return
        }
    }

    func prepareClientReset(_ partition: String, _ user: User) throws {
        let collection = setupMongoCollection(user: user, collectionName: "SwiftPerson")

        // Initialize the local file so that we have conflicting history
        try autoreleasepool {
            var configuration = user.configuration(partitionValue: partition)
            configuration.objectTypes = [SwiftPerson.self]
            let realm = try Realm(configuration: configuration)
            waitForUploads(for: realm)
        }

        // Create an object on the server which should be present after client reset
        let serverObject: Document = [
            "realm_id": .string(partition),
            "_id": .objectId(ObjectId.generate()),
            "firstName": .string("Paul"),
            "lastName": .string("M"),
            "age": .int32(30)
        ]
        collection.insertOne(serverObject).await(self, timeout: 30.0)

        // Sync is disabled, block executed, sync re-enabled
        try executeBlockOffline(appId: appId) {
            var configuration = user.configuration(partitionValue: partition)
            configuration.objectTypes = [SwiftPerson.self]
            let realm = try Realm(configuration: configuration)
            realm.syncSession!.suspend()
            // Add an object to the local realm that will not be in the server realm (because sync is disabled).
            try realm.write {
                realm.add(SwiftPerson(firstName: "John", lastName: "L"))
            }
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
        }

        // After restarting sync, the sync history translator service needs time
        // to resynthesize the new history from existing objects on the server
        // The following creates a new realm with the same partition and wait for
        // downloads to ensure the the new history has been created.
        try autoreleasepool {
            var newConfig = user.configuration(partitionValue: partition)
            newConfig.fileURL = RLMTestRealmURL()
            newConfig.objectTypes = [SwiftPerson.self]
            let newRealm = try Realm(configuration: newConfig)

            waitForServerHistoryAfterRestart(realm: newRealm)
        }
    }
    func prepareFlexibleClientReset(_ user: User) throws {
        let collection = setupMongoCollection(user: user, collectionName: "SwiftPerson")

        // Initialize the local file so that we have conflicting history
        try autoreleasepool {
            var configuration = user.flexibleSyncConfiguration()
            configuration.objectTypes = [SwiftPerson.self]
            let realm = try Realm(configuration: configuration)
            let subscriptions = realm.subscriptions
            updateAllPeopleSubscription(subscriptions)
        }

        // Create an object on the server which should be present after client reset
        let serverObject: Document = [
            "_id": .objectId(ObjectId.generate()),
            "firstName": .string("Paul"),
            "lastName": .string("M"),
            "age": .int32(30)
        ]
        collection.insertOne(serverObject).await(self, timeout: 30.0)

        // Sync is disabled, block executed, sync re-enabled
        try executeBlockOffline(flexibleSync: true, appId: flexibleSyncAppId) {
            var configuration = user.flexibleSyncConfiguration()
            configuration.objectTypes = [SwiftPerson.self]
            let realm = try Realm(configuration: configuration)
            realm.syncSession!.suspend()

            // There is enough time between the collection insert and the server
            // being turned off for the subscription sync to sync "Paul M".
            if realm.objects(SwiftPerson.self).count > 0 {
                try realm.write {
                    realm.deleteAll()
                }
            }

            // Add an object to the local realm that will not be in the server realm (because sync is disabled).
            try realm.write {
                realm.add(SwiftPerson(firstName: "John", lastName: "L"))
            }
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
        }

        // After restarting sync, the sync history translator service needs time
        // to resynthesize the new history from existing objects on the server
        // The following creates a new realm with the same partition and wait for
        // downloads to ensure the the new history has been created.
        try autoreleasepool {
            var newConfig = user.flexibleSyncConfiguration()
            newConfig.fileURL = RLMTestRealmURL()
            newConfig.objectTypes = [SwiftPerson.self]
            let newRealm = try Realm(configuration: newConfig)

            let subscriptions = newRealm.subscriptions
            updateAllPeopleSubscription(subscriptions)
            waitForServerHistoryAfterRestart(realm: newRealm)
        }
    }

    func assertManualClientReset(_ user: User, flexibleSync: Bool = false) -> ErrorReportingBlock {
        let ex = self.expectation(description: "get client reset error")
        return { error, session in
            guard let error = error as? SyncError else {
                XCTFail("Bad error type: \(error)")
                return
            }
            XCTAssertEqual(error.code, .clientResetError)
            XCTAssertEqual(session?.state, .inactive)
            XCTAssertEqual(session?.connectionState, .disconnected)
            XCTAssertEqual(session?.parentUser()?.id, user.id)
            guard let (resetInfo) = error.clientResetInfo() else {
                XCTAssertNotNil(error.clientResetInfo())
                return
            }
            let id = flexibleSync ? self.flexibleSyncAppId : self.appId
            XCTAssertTrue(resetInfo.0.contains("mongodb-realm/\(id)/recovered-realms/recovered_realm"))
            let manager = flexibleSync ? self.flexibleSyncApp.syncManager : self.app.syncManager
            SyncSession.immediatelyHandleError(resetInfo.1, syncManager: manager)
            ex.fulfill()
        }
    }

    func assertDiscardLocal() -> ((Realm) -> Void, (Realm, Realm) -> Void) {
        let beforeCallbackEx = expectation(description: "before reset callback")
        let beforeClientResetBlock: (Realm) -> Void = { before in
            let results = before.objects(SwiftPerson.self)
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual(results.filter("firstName == 'John'").count, 1)

            beforeCallbackEx.fulfill()
        }
        let afterCallbackEx = expectation(description: "before reset callback")
        let afterClientResetBlock: (Realm, Realm) -> Void = { before, after in
            let results = before.objects(SwiftPerson.self)
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual(results.filter("firstName == 'John'").count, 1)

            let results2 = after.objects(SwiftPerson.self)
            XCTAssertEqual(results2.count, 1)
            XCTAssertEqual(results2.filter("firstName == 'Paul'").count, 1)

            afterCallbackEx.fulfill()
        }
        return (beforeClientResetBlock, afterClientResetBlock)
    }

    func assertRecover() -> ((Realm) -> Void, (Realm, Realm) -> Void) {
        let beforeCallbackEx = expectation(description: "before reset callback")
        let beforeClientResetBlock: (Realm) -> Void = { local in
            let results = local.objects(SwiftPerson.self)
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual(results.filter("firstName == 'John'").count, 1)
            beforeCallbackEx.fulfill()
        }
        let afterCallbackEx = expectation(description: "after reset callback")
        let afterClientResetBlock: (Realm, Realm) -> Void = { before, after in
            let results = before.objects(SwiftPerson.self)
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual(results.filter("firstName == 'John'").count, 1)

            let results2 = after.objects(SwiftPerson.self)
            XCTAssertEqual(results2.count, 2)
            XCTAssertEqual(results2.filter("firstName == 'John'").count, 1)
            XCTAssertEqual(results2.filter("firstName == 'Paul'").count, 1)

            afterCallbackEx.fulfill()
        }
        return (beforeClientResetBlock, afterClientResetBlock)
    }

    func testClientResetManual() throws {
        let creds = basicCredentials()
        try autoreleasepool {
            let user = try logInUser(for: creds)
            try prepareClientReset(#function, user)

            var configuration = user.configuration(partitionValue: #function, clientResetMode: .manual())
            configuration.objectTypes = [SwiftPerson.self]

            let syncManager = self.app.syncManager
            syncManager.errorHandler = assertManualClientReset(user)

            try autoreleasepool {
                let realm = try Realm(configuration: configuration)
                waitForExpectations(timeout: 15.0)
                // The locally created object should still be present as we didn't
                // actually handle the client reset
                XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
                XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "John")
            }
        }

        let user = try logInUser(for: creds)
        var configuration = user.configuration(partitionValue: #function)
        configuration.objectTypes = [SwiftPerson.self]

        try autoreleasepool {
            let realm = try Realm(configuration: configuration)
            waitForDownloads(for: realm)
            // After reopening, the old Realm file should have been moved aside
            // and we should now have the data from the server
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
            XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "Paul")
        }
    }

    func testClientResetManualWithEnumCallback() throws {
        let creds = basicCredentials()
        try autoreleasepool {
            let user = try logInUser(for: creds)
            try prepareClientReset(#function, user)

            var configuration = user.configuration(partitionValue: #function, clientResetMode: .manual(errorHandler: assertManualClientReset(user)))
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
                // The locally created object should still be present as we didn't
                // actually handle the client reset
                XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
                XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "John")
            }
        }

        let user = try logInUser(for: creds)
        var configuration = user.configuration(partitionValue: #function, clientResetMode: .manual())
        configuration.objectTypes = [SwiftPerson.self]

        try autoreleasepool {
            let realm = try Realm(configuration: configuration)
            waitForDownloads(for: realm)
            // After reopening, the old Realm file should have been moved aside
            // and we should now have the data from the server
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
            XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "Paul")
        }
    }

    func testClientResetManualManagerFallback() throws {
        let creds = basicCredentials()
        try autoreleasepool {
            let user = try logInUser(for: creds)
            try prepareClientReset(#function, user)

            // No callback is passed into enum `.manual`, but a syncManager.errorHandler exists,
            // so expect that to be used instead.
            var configuration = user.configuration(partitionValue: #function, clientResetMode: .manual())
            configuration.objectTypes = [SwiftPerson.self]

            let syncManager = self.app.syncManager
            syncManager.errorHandler = assertManualClientReset(user)

            try autoreleasepool {
                let realm = try Realm(configuration: configuration)
                waitForExpectations(timeout: 15.0) // Wait for expectations in asssertManualClientReset
                // The locally created object should still be present as we didn't
                // actually handle the client reset
                XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
                XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "John")
            }
        }

        let user = try logInUser(for: creds)
        var configuration = user.configuration(partitionValue: #function)
        configuration.objectTypes = [SwiftPerson.self]

        try autoreleasepool {
            let realm = try Realm(configuration: configuration)
            waitForDownloads(for: realm)
            // After reopening, the old Realm file should have been moved aside
            // and we should now have the data from the server
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
            XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "Paul")
        }
    }

    // If the syncManager.ErrorHandler and manual enum callback
    // are both set, use the enum callback.
    func testClientResetManualEnumCallbackNotManager() throws {
        let creds = basicCredentials()
        try autoreleasepool {
            let user = try logInUser(for: creds)
            try prepareClientReset(#function, user)

            var configuration = user.configuration(partitionValue: #function, clientResetMode: .manual(errorHandler: assertManualClientReset(user)))
            configuration.objectTypes = [SwiftPerson.self]

            switch configuration.syncConfiguration!.clientResetMode {
            case .manual(let block):
                XCTAssertNotNil(block)
            default:
                XCTFail("Should be set to manual")
            }

            let syncManager = self.app.syncManager
            syncManager.errorHandler = { error, _ in
                guard nil != error as? SyncError else {
                    XCTFail("Bad error type: \(error)")
                    return
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

        let user = try logInUser(for: creds)
        var configuration = user.configuration(partitionValue: #function)
        configuration.objectTypes = [SwiftPerson.self]

        try autoreleasepool {
            let realm = try Realm(configuration: configuration)
            waitForDownloads(for: realm)
            // After reopening, the old Realm file should have been moved aside
            // and we should now have the data from the server
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
            XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "Paul")
        }
    }

    func testClientResetManualWithoutLiveRealmInstance() throws {
        let creds = basicCredentials()
        let user = try logInUser(for: creds)
        try prepareClientReset(#function, user)

        var configuration = user.configuration(partitionValue: #function, clientResetMode: .manual())
        configuration.objectTypes = [SwiftPerson.self]

        let syncManager = self.app.syncManager
        syncManager.errorHandler = assertManualClientReset(user)

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

    func testClientResetDiscardLocal() throws {
        let user = try logInUser(for: basicCredentials())
        try prepareClientReset(#function, user)

        let (assertBeforeBlock, assertAfterBlock) = assertDiscardLocal()
        var configuration = user.configuration(partitionValue: #function,
                                               clientResetMode: .discardLocal(beforeReset: assertBeforeBlock, afterReset: assertAfterBlock))
        configuration.objectTypes = [SwiftPerson.self]

        guard let syncConfig = configuration.syncConfiguration else { fatalError("Test condition failure. SyncConfiguration not set.") }
        switch syncConfig.clientResetMode {
        case .discardUnsyncedChanges(let before, let after):
            XCTAssertNotNil(before)
            XCTAssertNotNil(after)
        default:
            XCTFail("Should be set to discardLocal")
        }

        try autoreleasepool {
            let realm = try Realm(configuration: configuration)
            waitForExpectations(timeout: 15.0)
            // The Person created locally ("John") should have been discarded,
            // while the one from the server ("Paul") should be present
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
            XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "Paul")
        }
    }

    func testClientResetDiscardUnsyncedChanges() throws {
        let user = try logInUser(for: basicCredentials())
        try prepareClientReset(#function, user)

        let (assertBeforeBlock, assertAfterBlock) = assertDiscardLocal()
        var configuration = user.configuration(partitionValue: #function,
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
            // The Person created locally ("John") should have been discarded,
            // while the one from the server ("Paul") should be present
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
            XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "Paul")
        }
    }

    func testClientResetDiscardLocalAsyncOpen() throws {
        let user = try logInUser(for: basicCredentials())
        try prepareClientReset(#function, user)

        let (assertBeforeBlock, assertAfterBlock) = assertDiscardLocal()
        var configuration = user.configuration(partitionValue: #function, clientResetMode: .discardLocal(beforeReset: assertBeforeBlock, afterReset: assertAfterBlock))
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

    func testClientResetRecover() throws {
        let user = try logInUser(for: basicCredentials())
        try prepareClientReset(#function, user)

        let (assertBeforeBlock, assertAfterBlock) = assertRecover()
        var configuration = user.configuration(partitionValue: #function, clientResetMode: .recoverUnsyncedChanges(beforeReset: assertBeforeBlock, afterReset: assertAfterBlock))
        configuration.objectTypes = [SwiftPerson.self]

        guard let syncConfig = configuration.syncConfiguration else { fatalError("Test condition failure. SyncConfiguration not set.") }
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

    func testClientResetRecoverOrDiscardLocalFailedRecovery() throws {
        // Disable recovery mode on the server.
        // This attempts to simulate a case where recovery mode fails when
        // using RecoverOrDiscardLocal
        try waitForEditRecoveryMode(appId: appId, disable: true)

        let user = try logInUser(for: basicCredentials())
        try prepareClientReset(#function, user)

        // Expect the recovery to fail back to discardLocal logic
        let (assertBeforeBlock, assertAfterBlock) = assertDiscardLocal()
        var configuration = user.configuration(partitionValue: #function, clientResetMode: .recoverOrDiscardUnsyncedChanges(beforeReset: assertBeforeBlock, afterReset: assertAfterBlock))
        configuration.objectTypes = [SwiftPerson.self]

        guard let syncConfig = configuration.syncConfiguration else { fatalError("Test condition failure. SyncConfiguration not set.") }
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
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
            // The Person created locally ("John") should have been discarded,
            // while the one from the server ("Paul") should be present.
            XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "Paul")
        }
        try waitForEditRecoveryMode(appId: appId, disable: false)
    }

    func testFlexibleSyncDiscardLocalClientReset() throws {
        let user = try logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)
        try prepareFlexibleClientReset(user)

        let (assertBeforeBlock, assertAfterBlock) = assertDiscardLocal()
        var config = user.flexibleSyncConfiguration(clientResetMode: .discardLocal(beforeReset: assertBeforeBlock, afterReset: assertAfterBlock))
        config.objectTypes = [SwiftPerson.self]
        guard let syncConfig = config.syncConfiguration else {
            fatalError("Test condition failure. SyncConfiguration not set.")
        }
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
            XCTAssertEqual(subscriptions.first?.name, "all_people")

            waitForExpectations(timeout: 15.0)
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
            XCTAssertEqual(realm.objects(SwiftPerson.self).first?.firstName, "Paul")
        }
    }

    func testFlexibleSyncDiscardUnsyncedChangesClientReset() throws {
        let user = try logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)
        try prepareFlexibleClientReset(user)

        let (assertBeforeBlock, assertAfterBlock) = assertDiscardLocal()
        var config = user.flexibleSyncConfiguration(clientResetMode: .discardUnsyncedChanges(beforeReset: assertBeforeBlock, afterReset: assertAfterBlock))
        config.objectTypes = [SwiftPerson.self]
        guard let syncConfig = config.syncConfiguration else {
            fatalError("Test condition failure. SyncConfiguration not set.")
        }
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
            XCTAssertEqual(subscriptions.first?.name, "all_people")

            waitForExpectations(timeout: 15.0)
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
            XCTAssertEqual(realm.objects(SwiftPerson.self).first?.firstName, "Paul")
        }
    }

    func testFlexibleSyncClientResetRecover() throws {
        let user = try logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)
        try prepareFlexibleClientReset(user)

        let (assertBeforeBlock, assertAfterBlock) = assertRecover()
        var config = user.flexibleSyncConfiguration(clientResetMode: .recoverUnsyncedChanges(beforeReset: assertBeforeBlock, afterReset: assertAfterBlock))
        config.objectTypes = [SwiftPerson.self]
        guard let syncConfig = config.syncConfiguration else {
            fatalError("Test condition failure. SyncConfiguration not set.")
        }
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
            XCTAssertEqual(subscriptions.first?.name, "all_people")

            waitForExpectations(timeout: 15.0) // wait for expectations in assertRecover
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 2)
            // The object created locally (John) and the object created on the server (Paul)
            // should both be integrated into the new realm file.
            XCTAssertEqual(realm.objects(SwiftPerson.self).filter("firstName == 'John'").count, 1)
            XCTAssertEqual(realm.objects(SwiftPerson.self).filter("firstName == 'Paul'").count, 1)
        }
    }

    func testFlexibleSyncClientResetRecoverWithInitialSubscriptions() throws {
        let user = try logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)
        try prepareFlexibleClientReset(user)

        let (assertBeforeBlock, assertAfterBlock) = assertRecover()
        var config = user.flexibleSyncConfiguration(clientResetMode: .recoverUnsyncedChanges(beforeReset: assertBeforeBlock, afterReset: assertAfterBlock), initialSubscriptions: { subscriptions in
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "all_people"))
        })
        config.objectTypes = [SwiftPerson.self]
        guard let syncConfig = config.syncConfiguration else {
            fatalError("Test condition failure. SyncConfiguration not set.")
        }
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
            XCTAssertEqual(subscriptions.count, 1)
            XCTAssertEqual(subscriptions.first?.name, "all_people")

            waitForExpectations(timeout: 15.0)
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 2)
            // The object created locally (John) and the object created on the server (Paul)
            // should both be integrated into the new realm file.
            XCTAssertEqual(realm.objects(SwiftPerson.self).filter("firstName == 'John'").count, 1)
            XCTAssertEqual(realm.objects(SwiftPerson.self).filter("firstName == 'Paul'").count, 1)
        }
    }

    func testFlexibleSyncClientResetDiscardLocalWithInitialSubscriptions() throws {
        let user = try logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)
        try prepareFlexibleClientReset(user)

        let (assertBeforeBlock, assertAfterBlock) = assertDiscardLocal()
        var config = user.flexibleSyncConfiguration(clientResetMode: .discardLocal(beforeReset: assertBeforeBlock, afterReset: assertAfterBlock), initialSubscriptions: { subscriptions in
            subscriptions.append(QuerySubscription<SwiftPerson>(name: "all_people"))
        })
        config.objectTypes = [SwiftPerson.self]
        guard let syncConfig = config.syncConfiguration else {
            fatalError("Test condition failure. SyncConfiguration not set.")
        }
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
            XCTAssertEqual(subscriptions.count, 1)
            XCTAssertEqual(subscriptions.first?.name, "all_people")

            waitForExpectations(timeout: 15.0)
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
            // The Person created locally ("John") should have been discarded,
            // while the one from the server ("Paul") should be present
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
            XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "Paul")
        }
    }

    func testFlexibleSyncClientResetRecoverOrDiscardLocalFailedRecovery() throws {
        // Disable recovery mode on the server.
        // This attempts to simulate a case where recovery mode fails when
        // using RecoverOrDiscardLocal
        try waitForEditRecoveryMode(flexibleSync: true, appId: self.flexibleSyncAppId, disable: true)

        let user = try logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)
        try prepareFlexibleClientReset(user)

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
            XCTAssertEqual(subscriptions.first?.name, "all_people")

            waitForExpectations(timeout: 15.0)
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
            // The Person created locally ("John") should have been discarded,
            // while the one from the server ("Paul") should be present.
            XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "Paul")
        }
        try waitForEditRecoveryMode(flexibleSync: true, appId: self.flexibleSyncAppId, disable: false)
    }

    func testFlexibleClientResetManual() throws {
        let credentials =  basicCredentials(app: self.flexibleSyncApp)
        try autoreleasepool {
            let user = try logInUser(for: credentials, app: self.flexibleSyncApp)
            try prepareFlexibleClientReset(user)

            var config = user.flexibleSyncConfiguration(clientResetMode: .manual(errorHandler: assertManualClientReset(user, flexibleSync: true)))
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

        let user = try logInUser(for: credentials, app: self.flexibleSyncApp)
        var config = user.flexibleSyncConfiguration(clientResetMode: .manual())
        config.objectTypes = [SwiftPerson.self]

        try autoreleasepool {
            let realm = try Realm(configuration: config)
            let subscriptions = realm.subscriptions
            updateAllPeopleSubscription(subscriptions)
            XCTAssertEqual(subscriptions.count, 1)
            waitForDownloads(for: realm)

            // After reopening, the old Realm file should have been moved aside
            // and we should now have the data from the server
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
            XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "Paul")
        }
    }

    func testDefaultClientResetMode() throws {
        let user = try logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)
        let fConfig = user.flexibleSyncConfiguration()
        let pConfig = user.configuration(partitionValue: #function)

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

    // MARK: - Progress notifiers
    func testStreamingDownloadNotifier() throws {
        let user = try logInUser(for: basicCredentials())
        if !isParent {
            populateRealm(user: user, partitionValue: #function)
            return
        }

        var callCount = 0
        var transferred = 0
        var transferrable = 0
        let realm = try immediatelyOpenRealm(partitionValue: #function, user: user)

        guard let session = realm.syncSession else {
            XCTFail("Session must not be nil")
            return

        }
        let ex = expectation(description: "streaming-downloads-expectation")
        var hasBeenFulfilled = false

        let token = session.addProgressNotification(for: .download, mode: .reportIndefinitely) { p in
            callCount += 1
            XCTAssertGreaterThanOrEqual(p.transferredBytes, transferred)
            XCTAssertGreaterThanOrEqual(p.transferrableBytes, transferrable)
            transferred = p.transferredBytes
            transferrable = p.transferrableBytes
            if p.transferredBytes > 0 && p.isTransferComplete && !hasBeenFulfilled {
                ex.fulfill()
                hasBeenFulfilled = true
            }
        }
        XCTAssertNotNil(token)

        // Wait for the child process to upload all the data.
        executeChild()

        waitForExpectations(timeout: 60.0, handler: nil)
        token!.invalidate()
        XCTAssert(callCount > 1)
        XCTAssert(transferred >= transferrable)
    }

    func testStreamingUploadNotifier() throws {
        var transferred = 0
        var transferrable = 0
        let user = try logInUser(for: basicCredentials())
        let config = user.configuration(testName: #function)
        let realm = try openRealm(configuration: config)
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
            for _ in 0..<SwiftSyncTestCase.bigObjectCount {
                realm.add(SwiftHugeSyncObject.create())
            }
        }
        waitForExpectations(timeout: 10.0, handler: nil)
        token!.invalidate()
        XCTAssert(transferred >= transferrable)
    }

    func testStreamingNotifierInvalidate() throws {
        let user = try logInUser(for: basicCredentials())
        if !isParent {
            let config = user.configuration(testName: #function)
            let realm = try openRealm(configuration: config)
            try realm.write {
                for _ in 0..<SwiftSyncTestCase.bigObjectCount {
                    realm.add(SwiftHugeSyncObject.create())
                }
            }
            waitForUploads(for: realm)
            return
        }

        let realm = try immediatelyOpenRealm(partitionValue: #function, user: user)
        guard let session = realm.syncSession else {
            XCTFail("Session must not be nil")
            return

        }
        var downloadCount = 0
        var uploadCount = 0
        let tokenDownload = session.addProgressNotification(for: .download, mode: .reportIndefinitely) { _ in
            downloadCount += 1
        }
        let tokenUpload = session.addProgressNotification(for: .upload, mode: .reportIndefinitely) { _ in
            uploadCount += 1
        }

        executeChild()
        waitForDownloads(for: realm)
        try realm.write {
            realm.add(SwiftHugeSyncObject.create())
        }
        waitForUploads(for: realm)

        XCTAssert(downloadCount > 1)
        XCTAssert(uploadCount > 1)

        tokenDownload!.invalidate()
        tokenUpload!.invalidate()

        downloadCount = 0
        uploadCount = 0

        executeChild()
        waitForDownloads(for: realm)
        try realm.write {
            realm.add(SwiftHugeSyncObject.create())
        }
        waitForUploads(for: realm)

        // We check that the notification block is not called after we reset the counters on the notifiers and call invalidated().
        XCTAssertEqual(downloadCount, 0)
        XCTAssertEqual(uploadCount, 0)
    }

    // MARK: - Download Realm

    func testDownloadRealm() throws {
        let user = try logInUser(for: basicCredentials())
        if !isParent {
            populateRealm(user: user, partitionValue: #function)
            return
        }

        // Wait for the child process to upload everything.
        executeChild()

        let ex = expectation(description: "download-realm")
        let config = user.configuration(testName: #function)
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

    func testDownloadRealmToCustomPath() throws {
        let user = try logInUser(for: basicCredentials())
        if !isParent {
            populateRealm(user: user, partitionValue: #function)
            return
        }

        // Wait for the child process to upload everything.
        executeChild()

        let ex = expectation(description: "download-realm")
        let customFileURL = realmURLForFile("copy")
        var config = user.configuration(testName: #function)
        config.fileURL = customFileURL
        let pathOnDisk = ObjectiveCSupport.convert(object: config).pathOnDisk
        XCTAssertEqual(pathOnDisk, customFileURL.path)
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

    func testCancelDownloadRealm() throws {
        let user = try logInUser(for: basicCredentials())
        if !isParent {
            populateRealm(user: user, partitionValue: #function)
            return
        }

        // Wait for the child process to upload everything.
        executeChild()

        // Use a serial queue for asyncOpen to ensure that the first one adds
        // the completion block before the second one cancels it
        RLMSetAsyncOpenQueue(DispatchQueue(label: "io.realm.asyncOpen"))

        let ex = expectation(description: "async open")
        let config = user.configuration(testName: #function)
        Realm.asyncOpen(configuration: config) { result in
            guard case .failure = result else {
                XCTFail("No error on cancelled async open")
                return ex.fulfill()
            }
            ex.fulfill()
        }
        let task = Realm.asyncOpen(configuration: config) { _ in
            XCTFail("Cancelled completion handler was called")
        }
        task.cancel()
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testAsyncOpenProgress() throws {
        let user = try logInUser(for: basicCredentials())
        if !isParent {
            populateRealm(user: user, partitionValue: #function)
            return
        }

        // Wait for the child process to upload everything.
        executeChild()
        let ex1 = expectation(description: "async open")
        let ex2 = expectation(description: "download progress")
        let config = user.configuration(testName: #function)
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

    func testAsyncOpenTimeout() throws {
        let proxy = TimeoutProxyServer(port: 5678, targetPort: 9090)
        try proxy.start()

        let appId = try RealmServer.shared.createApp()
        let appConfig = AppConfiguration(baseURL: "http://localhost:5678",
                                         transport: AsyncOpenConnectionTimeoutTransport(),
                                         localAppName: nil, localAppVersion: nil)
        let app = App(id: appId, configuration: appConfig)

        let syncTimeoutOptions = SyncTimeoutOptions()
        syncTimeoutOptions.connectTimeout = 2000
        app.syncManager.timeoutOptions = syncTimeoutOptions

        let user = try logInUser(for: basicCredentials(app: app), app: app)
        var config = user.configuration(partitionValue: #function, cancelAsyncOpenOnNonFatalErrors: true)
        config.objectTypes = []

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

    // MARK: - Authentication

    func testInvalidCredentials() throws {
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

    func assertSyncError(_ error: Error, _ code: SyncError.Code, _ message: String,
                         line: UInt = #line, file: StaticString = #file) {
        let e = error as NSError
        XCTAssertEqual(e.domain, RLMSyncErrorDomain, file: file, line: line)
        XCTAssertEqual(e.code, code.rawValue, file: file, line: line)
        XCTAssertEqual(e.localizedDescription, "Unable to refresh the user access token.",
                       file: file, line: line)
    }

    func testUserExpirationCallback() throws {
        let user = try logInUser(for: basicCredentials())

        // Set a callback on the user
        var blockCalled = false
        let ex = expectation(description: "Error callback should fire upon receiving an error")
        app.syncManager.errorHandler = { (error, _) in
            self.assertSyncError(error, .clientUserError, "Unable to refresh the user access token.")
            blockCalled = true
            ex.fulfill()
        }

        // Screw up the token on the user.
        manuallySetAccessToken(for: user, value: badAccessToken())
        manuallySetRefreshToken(for: user, value: badAccessToken())
        // Try to open a Realm with the user; this will cause our errorHandler block defined above to be fired.
        XCTAssertFalse(blockCalled)
        _ = try immediatelyOpenRealm(partitionValue: "realm_id", user: user)

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    private func realmURLForFile(_ fileName: String) -> URL {
        let testDir = RLMRealmPathForFile("mongodb-realm")
        let directory = URL(fileURLWithPath: testDir, isDirectory: true)
        return directory.appendingPathComponent(fileName, isDirectory: false)
    }

    // MARK: - App tests

    private func appConfig() -> AppConfiguration {
        return AppConfiguration(baseURL: "http://localhost:9090",
                                transport: nil,
                                localAppName: "auth-integration-tests",
                                localAppVersion: "20180301")
    }

    func expectSuccess<T>(_ result: Result<T, Error>) -> T? {
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            XCTFail("unexpected error: \(error)")
            return nil
        }
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
        app.login(credentials: .anonymous).await(self)

        let user = app.currentUser!
        _ = expectSuccess(RealmServer.shared.removeUserForApp(appId, userId: user.id))

        // Set a callback on the user
        let ex = expectation(description: "Error callback should fire upon receiving an error")
        ex.assertForOverFulfill = false // error handler can legally be called multiple times
        app.syncManager.errorHandler = { (error, _) in
            self.assertSyncError(error, .clientUserError, "Unable to refresh the user access token.")
            ex.fulfill()
        }

        // Try to open a Realm with the user; this will cause our errorHandler block defined above to be fired.
        _ = try immediatelyOpenRealm(partitionValue: #function, user: user)
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
            assertAppError($0, .unknown, "failed to reset password for user \(email)")
        }
    }

    func testUserAPIKeyProviderClient() {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)
        app.emailPasswordAuth.registerUser(email: email, password: password).await(self)

        let credentials = Credentials.emailPassword(email: email, password: password)
        let syncUser = app.login(credentials: credentials).await(self)

        let apiKey = syncUser.apiKeysAuth.createAPIKey(named: "my-api-key").await(self)

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

        let bson = syncUser.functions.sum([1, 2, 3, 4, 5]).await(self)
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
        user.functions.updateUserData([["favourite_colour": "green", "apples": 10]]).await(self)

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
        let user = try logInUser(for: basicCredentials())
        var destinationConfig = user.configuration(partitionValue: #function)
        destinationConfig.fileURL = seedURL
        destinationConfig.objectTypes = [SwiftHugeSyncObject.self]

        try realm.writeCopy(configuration: destinationConfig)

        var syncConfig = user.configuration(partitionValue: #function)
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

    func testSeedFilePathOpenSyncToSync() throws {
        // user1 creates and writeCopies a realm to be opened by another user
        let user1 = try logInUser(for: basicCredentials())
        var config = user1.configuration(testName: #function)

        config.objectTypes = [SwiftHugeSyncObject.self]
        let realm = try Realm(configuration: config)
        try realm.write {
            for _ in 0..<SwiftSyncTestCase.bigObjectCount {
                realm.add(SwiftHugeSyncObject.create())
            }
        }
        waitForUploads(for: realm)

        // user2 creates a configuration that will use user1's realm as a seed
        let user2 = try logInUser(for: basicCredentials())
        XCTAssertNotEqual(user1.id, user2.id)
        var destinationConfig = user2.configuration(partitionValue: #function)
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

    func testSeedFilePathOpenSyncToLocal() throws {
        let seedURL = RLMTestRealmURL().deletingLastPathComponent().appendingPathComponent("seed.realm")
        let user1 = try logInUser(for: basicCredentials())
        var syncConfig = user1.configuration(partitionValue: #function)
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

    func testWriteCopySyncedRealm() throws {
        // user1 creates and writeCopies a realm to be opened by another user
        let user1 = try logInUser(for: basicCredentials())
        var config = user1.configuration(testName: #function)

        config.objectTypes = [SwiftHugeSyncObject.self]
        let syncedRealm = try Realm(configuration: config)
        try syncedRealm.write {
            for _ in 0..<SwiftSyncTestCase.bigObjectCount {
                syncedRealm.add(SwiftHugeSyncObject.create())
            }
        }
        waitForUploads(for: syncedRealm)

        // user2 creates a configuration that will use user1's realm as a seed
        let user2 = try logInUser(for: basicCredentials())
        var destinationConfig = user2.configuration(partitionValue: #function)
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

    func testWriteCopyLocalRealmToSync() throws {
        var localConfig = Realm.Configuration()
        localConfig.objectTypes = [SwiftPerson.self]
        localConfig.fileURL = realmURLForFile("test.realm")

        let user = try logInUser(for: basicCredentials())
        var syncConfig = user.configuration(partitionValue: #function)
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

    func testWriteCopySynedRealmToLocal() throws {
        let user = try logInUser(for: basicCredentials())
        var syncConfig = user.configuration(partitionValue: #function)
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

    func testWriteCopyLocalRealmForSyncWithExistingData() throws {
        let initialUser = try logInUser(for: basicCredentials())
        var initialSyncConfig = initialUser.configuration(partitionValue: #function)
        initialSyncConfig.objectTypes = [SwiftPerson.self]

        // Make sure objects with confliciting primary keys sync ok.
        let conflictingObjectId = ObjectId.generate()
        let person = SwiftPerson(value: ["_id": conflictingObjectId,
                                         "firstName": "Foo", "lastName": "Bar"])
        let initialRealm = try Realm(configuration: initialSyncConfig)
        try initialRealm.write {
            initialRealm.add(person)
            initialRealm.add(SwiftPerson(firstName: "Foo2", lastName: "Bar2"))
        }
        waitForUploads(for: initialRealm)

        var localConfig = Realm.Configuration()
        localConfig.objectTypes = [SwiftPerson.self]
        localConfig.fileURL = realmURLForFile("test.realm")

        let user = try logInUser(for: basicCredentials())
        var syncConfig = user.configuration(partitionValue: #function)
        syncConfig.objectTypes = [SwiftPerson.self]

        let localRealm = try Realm(configuration: localConfig)
        // `person2` will override what was previously stored on the server.
        let person2 = SwiftPerson(value: ["_id": conflictingObjectId,
                                          "firstName": "John", "lastName": "Doe"])
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

    func testWriteCopyFailBeforeSynced() throws {
        let user1 = try logInUser(for: basicCredentials())
        var user1Config = user1.configuration(partitionValue: #function)
        user1Config.objectTypes = [SwiftPerson.self]
        let user1Realm = try Realm(configuration: user1Config)
        // Suspend the session so that changes cannot be uploaded
        user1Realm.syncSession?.suspend()
        try user1Realm.write {
            user1Realm.add(SwiftPerson())
        }

        let user2 = try logInUser(for: basicCredentials())
        XCTAssertNotEqual(user1.id, user2.id)
        var user2Config = user2.configuration(partitionValue: #function)
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
            XCTAssertEqual(error.localizedDescription, "Could not write file as not all client changes are integrated in server")
        }
    }
}

class AnyRealmValueSyncTests: SwiftSyncTestCase {
    /// The purpose of this test is to confirm that when an Object is set on a mixed Column and an old
    /// version of an app does not have that Realm Object / Schema we can still access that object via
    /// `AnyRealmValue.dynamicSchema`.
    func testMissingSchema() throws {
        let user = try logInUser(for: basicCredentials())

        if !isParent {
            // Imagine this is v2 of an app with 3 classes
            var config = user.configuration(partitionValue: #function)
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
            return
        }
        executeChild()

        // Imagine this is v1 of an app with just 2 classes, `SwiftMissingObject`
        // did not exist when this version was shipped,
        // but v2 managed to sync `SwiftMissingObject` to this Realm.
        var config = user.configuration(partitionValue: #function)
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
}

// XCTest doesn't care about the @available on the class and will try to run
// the tests even on older versions. Putting this check inside `defaultTestSuite`
// results in a warning about it being redundant due to the enclosing check, so
// it needs to be out of line.
func hasCombine() -> Bool {
    if #available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *) {
        return true
    }
    return false
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
extension Publisher {
    func expectValue(_ testCase: XCTestCase, _ expectation: XCTestExpectation,
                     receiveValue: ((Self.Output) -> Void)? = nil) -> AnyCancellable {
        return self.sink(receiveCompletion: { result in
            if case .failure(let error) = result {
                XCTFail("Unexpected failure: \(error)")
            }
        }, receiveValue: { value in
            receiveValue?(value)
            expectation.fulfill()
        })
    }

    func await(_ testCase: XCTestCase, timeout: TimeInterval = 20.0, receiveValue: ((Self.Output) -> Void)? = nil) {
        let expectation = testCase.expectation(description: "Async combine pipeline")
        let cancellable = self.expectValue(testCase, expectation, receiveValue: receiveValue)
        testCase.wait(for: [expectation], timeout: timeout)
        cancellable.cancel()
    }

    @discardableResult
    func await(_ testCase: XCTestCase, timeout: TimeInterval = 20.0) -> Self.Output {
        let expectation = testCase.expectation(description: "Async combine pipeline")
        var value: Self.Output?
        let cancellable = self.expectValue(testCase, expectation, receiveValue: { value = $0 })
        testCase.wait(for: [expectation], timeout: timeout)
        cancellable.cancel()
        return value!
    }

    func awaitFailure(_ testCase: XCTestCase, timeout: TimeInterval = 20.0,
                      _ errorHandler: ((Self.Failure) -> Void)? = nil) {
        let expectation = testCase.expectation(description: "Async combine pipeline should fail")
        let cancellable = self.sink(receiveCompletion: { result in
            if case .failure(let error) = result {
                errorHandler?(error)
                expectation.fulfill()
            }
        }, receiveValue: { value in
            XCTFail("Should have failed but got \(value)")
        })
        testCase.wait(for: [expectation], timeout: timeout)
        cancellable.cancel()
    }

    func awaitFailure<E: Error>(_ testCase: XCTestCase, timeout: TimeInterval = 20.0,
                                _ errorHandler: @escaping ((E) -> Void)) {
        awaitFailure(testCase, timeout: timeout) { error in
            guard let error = error as? E else {
                XCTFail("Expected error of type \(E.self), got \(error)")
                return
            }
            errorHandler(error)
        }
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
@objc(CombineObjectServerTests)
class CombineObjectServerTests: SwiftSyncTestCase {
    override class var defaultTestSuite: XCTestSuite {
        if hasCombine() {
            return super.defaultTestSuite
        }
        return XCTestSuite(name: "\(type(of: self))")
    }

    var subscriptions: Set<AnyCancellable> = []

    override func tearDown() {
        subscriptions.forEach { $0.cancel() }
        subscriptions = []
        super.tearDown()
    }

    func setupMongoCollection() throws -> MongoCollection {
        let user = try logInUser(for: basicCredentials())
        let mongoClient = user.mongoClient("mongodb1")
        let database = mongoClient.database(named: "test_data")
        let collection = database.collection(withName: "Dog")
        removeAllFromCollection(collection)
        return collection
    }

    // swiftlint:disable multiple_closures_with_trailing_closure
    func testWatchCombine() throws {
        let sema = DispatchSemaphore(value: 0)
        let sema2 = DispatchSemaphore(value: 0)
        let openSema = DispatchSemaphore(value: 0)
        let openSema2 = DispatchSemaphore(value: 0)
        let collection = try setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]

        let watchEx1 = expectation(description: "Watch 3 document events")
        watchEx1.expectedFulfillmentCount = 3
        let watchEx2 = expectation(description: "Watch 3 document events")
        watchEx2.expectedFulfillmentCount = 3

        collection.watch()
            .onOpen {
                openSema.signal()
            }
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.global())
            .sink(receiveCompletion: { _ in }) { _ in
                watchEx1.fulfill()
                XCTAssertFalse(Thread.isMainThread)
                sema.signal()
            }.store(in: &subscriptions)

        collection.watch()
            .onOpen {
                openSema2.signal()
            }
            .subscribe(on: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }) { _ in
                watchEx2.fulfill()
                XCTAssertTrue(Thread.isMainThread)
                sema2.signal()
            }.store(in: &subscriptions)

        DispatchQueue.global().async {
            openSema.wait()
            openSema2.wait()
            for _ in 0..<3 {
                collection.insertOne(document) { result in
                    if case .failure(let error) = result {
                        XCTFail("Failed to insert: \(error)")
                    }
                }
                sema.wait()
                sema2.wait()
            }
            DispatchQueue.main.async {
                self.subscriptions.forEach { $0.cancel() }
            }
        }
        wait(for: [watchEx1, watchEx2], timeout: 60.0)
    }

    func testWatchCombineWithFilterIds() throws {
        let sema1 = DispatchSemaphore(value: 0)
        let sema2 = DispatchSemaphore(value: 0)
        let openSema1 = DispatchSemaphore(value: 0)
        let openSema2 = DispatchSemaphore(value: 0)
        let collection = try setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]
        let document2: Document = ["name": "rex", "breed": "cane corso"]
        let document3: Document = ["name": "john", "breed": "cane corso"]
        let document4: Document = ["name": "ted", "breed": "bullmastiff"]
        var objectIds = [ObjectId]()

        let insertManyEx = expectation(description: "Insert many documents")
        collection.insertMany([document, document2, document3, document4]) { result in
            switch result {
            case .success(let objIds):
                XCTAssertEqual(objIds.count, 4)
                objectIds = objIds.map { $0.objectIdValue! }
            case .failure:
                XCTFail("Should insert")
            }
            insertManyEx.fulfill()
        }
        wait(for: [insertManyEx], timeout: 20.0)

        let watchEx1 = expectation(description: "Watch 3 document events")
        watchEx1.expectedFulfillmentCount = 3
        let watchEx2 = expectation(description: "Watch 3 document events")
        watchEx2.expectedFulfillmentCount = 3

        collection.watch(filterIds: [objectIds[0]])
            .onOpen {
                openSema1.signal()
            }
            .subscribe(on: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }) { changeEvent in
                XCTAssertTrue(Thread.isMainThread)
                guard let doc = changeEvent.documentValue else {
                    return
                }

                let objectId = doc["fullDocument"]??.documentValue!["_id"]??.objectIdValue!
                if objectId == objectIds[0] {
                    watchEx1.fulfill()
                    sema1.signal()
                }
            }.store(in: &subscriptions)

        collection.watch(filterIds: [objectIds[1]])
            .onOpen {
                openSema2.signal()
            }
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.global())
            .sink(receiveCompletion: { _ in }) { (changeEvent) in
                XCTAssertFalse(Thread.isMainThread)
                guard let doc = changeEvent.documentValue else {
                    return
                }

                let objectId = doc["fullDocument"]??.documentValue!["_id"]??.objectIdValue!
                if objectId == objectIds[1] {
                    watchEx2.fulfill()
                    sema2.signal()
                }
            }.store(in: &subscriptions)

        DispatchQueue.global().async {
            openSema1.wait()
            openSema2.wait()
            for i in 0..<3 {
                let name: AnyBSON = .string("fido-\(i)")
                collection.updateOneDocument(filter: ["_id": AnyBSON.objectId(objectIds[0])],
                                             update: ["name": name, "breed": "king charles"]) { result in
                    if case .failure(let error) = result {
                        XCTFail("Failed to update: \(error)")
                    }
                }
                collection.updateOneDocument(filter: ["_id": AnyBSON.objectId(objectIds[1])],
                                             update: ["name": name, "breed": "king charles"]) { result in
                    if case .failure(let error) = result {
                        XCTFail("Failed to update: \(error)")
                    }
                }
                sema1.wait()
                sema2.wait()
            }
            DispatchQueue.main.async {
                self.subscriptions.forEach { $0.cancel() }
            }
        }
        wait(for: [watchEx1, watchEx2], timeout: 60.0)
    }

    func testWatchCombineWithMatchFilter() throws {
        let sema1 = DispatchSemaphore(value: 0)
        let sema2 = DispatchSemaphore(value: 0)
        let openSema1 = DispatchSemaphore(value: 0)
        let openSema2 = DispatchSemaphore(value: 0)
        let collection = try setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]
        let document2: Document = ["name": "rex", "breed": "cane corso"]
        let document3: Document = ["name": "john", "breed": "cane corso"]
        let document4: Document = ["name": "ted", "breed": "bullmastiff"]
        var objectIds = [ObjectId]()

        let insertManyEx = expectation(description: "Insert many documents")
        collection.insertMany([document, document2, document3, document4]) { result in
            switch result {
            case .success(let objIds):
                XCTAssertEqual(objIds.count, 4)
                objectIds = objIds.map { $0.objectIdValue! }
            case .failure(let error):
                XCTFail("Failed to insert: \(error)")
            }
            insertManyEx.fulfill()
        }
        wait(for: [insertManyEx], timeout: 20.0)

        let watchEx1 = expectation(description: "Watch 3 document events")
        watchEx1.expectedFulfillmentCount = 3
        let watchEx2 = expectation(description: "Watch 3 document events")
        watchEx2.expectedFulfillmentCount = 3

        collection.watch(matchFilter: ["fullDocument._id": AnyBSON.objectId(objectIds[0])])
            .onOpen {
                openSema1.signal()
            }
            .subscribe(on: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }) { changeEvent in
                XCTAssertTrue(Thread.isMainThread)
                guard let doc = changeEvent.documentValue else {
                    return
                }

                let objectId = doc["fullDocument"]??.documentValue!["_id"]??.objectIdValue!
                if objectId == objectIds[0] {
                    watchEx1.fulfill()
                    sema1.signal()
                }
        }.store(in: &subscriptions)

        collection.watch(matchFilter: ["fullDocument._id": AnyBSON.objectId(objectIds[1])])
            .onOpen {
                openSema2.signal()
            }
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.global())
            .sink(receiveCompletion: { _ in }) { changeEvent in
                XCTAssertFalse(Thread.isMainThread)
                guard let doc = changeEvent.documentValue else {
                    return
                }

                let objectId = doc["fullDocument"]??.documentValue!["_id"]??.objectIdValue!
                if objectId == objectIds[1] {
                    watchEx2.fulfill()
                    sema2.signal()
                }
        }.store(in: &subscriptions)

        DispatchQueue.global().async {
            openSema1.wait()
            openSema2.wait()
            for i in 0..<3 {
                let name: AnyBSON = .string("fido-\(i)")
                collection.updateOneDocument(filter: ["_id": AnyBSON.objectId(objectIds[0])],
                                             update: ["name": name, "breed": "king charles"]) { result in
                    if case .failure = result {
                        XCTFail("Should update")
                    }
                }
                collection.updateOneDocument(filter: ["_id": AnyBSON.objectId(objectIds[1])],
                                             update: ["name": name, "breed": "king charles"]) { result in
                    if case .failure = result {
                        XCTFail("Should update")
                    }
                }
                sema1.wait()
                sema2.wait()
            }
            DispatchQueue.main.async {
                self.subscriptions.forEach { $0.cancel() }
            }
        }
        wait(for: [watchEx1, watchEx2], timeout: 60.0)
    }

    // MARK: - Combine promises

    func testAppLoginCombine() {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)

        let loginEx = expectation(description: "Login user")
        let appEx = expectation(description: "App changes triggered")
        var triggered = 0
        app.objectWillChange.sink { _ in
            triggered += 1
            if triggered == 2 {
                appEx.fulfill()
            }
        }.store(in: &subscriptions)

        app.emailPasswordAuth.registerUser(email: email, password: password)
            .flatMap { self.app.login(credentials: .emailPassword(email: email, password: password)) }
            .sink(receiveCompletion: { result in
                if case let .failure(error) = result {
                    XCTFail("Should have completed login chain: \(error.localizedDescription)")
                }
            }, receiveValue: { user in
                user.objectWillChange.sink { user in
                    XCTAssert(!user.isLoggedIn)
                    loginEx.fulfill()
                }.store(in: &self.subscriptions)
                XCTAssertEqual(user.id, self.app.currentUser?.id)
                user.logOut { _ in } // logout user and make sure it is observed
            })
            .store(in: &subscriptions)
        wait(for: [loginEx, appEx], timeout: 30.0)
        XCTAssertEqual(self.app.allUsers.count, 1)
        XCTAssertEqual(triggered, 2)
    }

    func testAsyncOpenCombine() {
        if isParent {
            let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
            let password = randomString(10)
            app.emailPasswordAuth.registerUser(email: email, password: password)
                .flatMap { self.app.login(credentials: .emailPassword(email: email, password: password)) }
                .flatMap { user in
                    Realm.asyncOpen(configuration: user.configuration(testName: #function))
                }
                .await(self, timeout: 30.0) { realm in
                    try! realm.write {
                        realm.add(SwiftHugeSyncObject.create())
                        realm.add(SwiftHugeSyncObject.create())
                    }
                    let progressEx = self.expectation(description: "Should upload")
                    let token = realm.syncSession!.addProgressNotification(for: .upload, mode: .forCurrentlyOutstandingWork) {
                        if $0.isTransferComplete {
                            progressEx.fulfill()
                        }
                    }
                    self.wait(for: [progressEx], timeout: 30.0)
                    token?.invalidate()
                }
            executeChild()
        } else {
            let chainEx = expectation(description: "Should chain realm login => realm async open")
            let progressEx = expectation(description: "Should receive progress notification")
            app.login(credentials: .anonymous)
                .flatMap {
                    Realm.asyncOpen(configuration: $0.configuration(testName: #function)).onProgressNotification {
                        if $0.isTransferComplete {
                            progressEx.fulfill()
                        }
                    }
                }
                .expectValue(self, chainEx) { realm in
                    XCTAssertEqual(realm.objects(SwiftHugeSyncObject.self).count, 2)
                }.store(in: &subscriptions)
            wait(for: [chainEx, progressEx], timeout: 30.0)
        }
    }

    func testAsyncOpenStandaloneCombine() throws {
        try autoreleasepool {
            let realm = try Realm()
            try realm.write {
                (0..<10000).forEach { _ in realm.add(SwiftPerson(firstName: "Charlie", lastName: "Bucket")) }
            }
        }

        Realm.asyncOpen().await(self) { realm in
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 10000)
        }
    }

    func testDeleteUserCombine() {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)

        let deleteEx = expectation(description: "Delete user")
        let appEx = expectation(description: "App changes triggered")
        var triggered = 0
        app.objectWillChange.sink { _ in
            triggered += 1
            if triggered == 2 {
                appEx.fulfill()
            }
        }.store(in: &subscriptions)

        app.emailPasswordAuth.registerUser(email: email, password: password)
            .flatMap { self.app.login(credentials: .emailPassword(email: email, password: password)) }
            .flatMap { $0.delete() }
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    XCTFail("Should have completed login chain: \(error.localizedDescription)")
                }
            }, receiveValue: {
                deleteEx.fulfill()
            })
            .store(in: &subscriptions)
        wait(for: [deleteEx, appEx], timeout: 30.0)
        XCTAssertEqual(self.app.allUsers.count, 0)
        XCTAssertEqual(triggered, 2)
    }

    func testMongoCollectionInsertCombine() throws {
        let collection = try setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]
        let document2: Document = ["name": "rex", "breed": "tibetan mastiff"]

        collection.insertOne(document).await(self)
        collection.insertMany([document, document2])
            .await(self) { objectIds in
                XCTAssertEqual(objectIds.count, 2)
            }
        collection.find(filter: [:])
            .await(self) { findResult in
                XCTAssertEqual(findResult.map({ $0["name"]??.stringValue }), ["fido", "fido", "rex"])
            }
    }

    func testMongoCollectionFindCombine() throws {
        let collection = try setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]
        let document2: Document = ["name": "rex", "breed": "tibetan mastiff"]
        let document3: Document = ["name": "rex", "breed": "tibetan mastiff", "coat": ["fawn", "brown", "white"]]
        let findOptions = FindOptions(1, nil, nil)

        collection.find(filter: [:], options: findOptions)
            .await(self) { findResult in
                XCTAssertEqual(findResult.count, 0)
            }
        collection.insertMany([document, document2, document3]).await(self)
        collection.find(filter: [:])
            .await(self) { findResult in
                XCTAssertEqual(findResult.map({ $0["name"]??.stringValue }), ["fido", "rex", "rex"])
            }
        collection.find(filter: [:], options: findOptions)
            .await(self) { findResult in
                XCTAssertEqual(findResult.count, 1)
                XCTAssertEqual(findResult[0]["name"]??.stringValue, "fido")
            }
        collection.find(filter: document3, options: findOptions)
            .await(self) { findResult in
                XCTAssertEqual(findResult.count, 1)
            }
        collection.findOneDocument(filter: document).await(self)

        collection.findOneDocument(filter: document, options: findOptions).await(self)
    }

    func testMongoCollectionCountAndAggregateCombine() throws {
        let collection = try setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]

        collection.insertMany([document]).await(self)
        collection.aggregate(pipeline: [["$match": ["name": "fido"]], ["$group": ["_id": "$name"]]])
            .await(self)
        collection.count(filter: document).await(self) { count in
            XCTAssertEqual(count, 1)
        }
        collection.count(filter: document, limit: 1).await(self) { count in
            XCTAssertEqual(count, 1)
        }
    }

    func testMongoCollectionDeleteOneCombine() throws {
        let collection = try setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]
        let document2: Document = ["name": "rex", "breed": "cane corso"]

        collection.deleteOneDocument(filter: document).await(self) { count in
            XCTAssertEqual(count, 0)
        }
        collection.insertMany([document, document2]).await(self)
        collection.deleteOneDocument(filter: document).await(self) { count in
            XCTAssertEqual(count, 1)
        }
    }

    func testMongoCollectionDeleteManyCombine() throws {
        let collection = try setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]
        let document2: Document = ["name": "rex", "breed": "cane corso"]

        collection.deleteManyDocuments(filter: document).await(self) { count in
            XCTAssertEqual(count, 0)
        }
        collection.insertMany([document, document2]).await(self)
        collection.deleteManyDocuments(filter: ["breed": "cane corso"]).await(self) { count in
            XCTAssertEqual(count, 2)
        }
    }

    func testMongoCollectionUpdateOneCombine() throws {
        let collection = try setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]
        let document2: Document = ["name": "rex", "breed": "cane corso"]
        let document3: Document = ["name": "john", "breed": "cane corso"]
        let document4: Document = ["name": "ted", "breed": "bullmastiff"]
        let document5: Document = ["name": "bill", "breed": "great dane"]

        collection.insertMany([document, document2, document3, document4]).await(self)
        collection.updateOneDocument(filter: document, update: document2).await(self) { updateResult in
            XCTAssertEqual(updateResult.matchedCount, 1)
            XCTAssertEqual(updateResult.modifiedCount, 1)
            XCTAssertNil(updateResult.documentId)
        }

        collection.updateOneDocument(filter: document5, update: document2, upsert: true).await(self) { updateResult in
            XCTAssertEqual(updateResult.matchedCount, 0)
            XCTAssertEqual(updateResult.modifiedCount, 0)
            XCTAssertNotNil(updateResult.documentId)
        }
    }

    func testMongoCollectionUpdateManyCombine() throws {
        let collection = try setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]
        let document2: Document = ["name": "rex", "breed": "cane corso"]
        let document3: Document = ["name": "john", "breed": "cane corso"]
        let document4: Document = ["name": "ted", "breed": "bullmastiff"]
        let document5: Document = ["name": "bill", "breed": "great dane"]

        collection.insertMany([document, document2, document3, document4]).await(self)
        collection.updateManyDocuments(filter: document, update: document2).await(self) { updateResult in
            XCTAssertEqual(updateResult.matchedCount, 1)
            XCTAssertEqual(updateResult.modifiedCount, 1)
            XCTAssertNil(updateResult.documentId)
        }
        collection.updateManyDocuments(filter: document5, update: document2, upsert: true).await(self) { updateResult in
            XCTAssertEqual(updateResult.matchedCount, 0)
            XCTAssertEqual(updateResult.modifiedCount, 0)
            XCTAssertNotNil(updateResult.documentId)
        }
    }

    func testMongoCollectionFindAndUpdateCombine() throws {
        let collection = try setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]
        let document2: Document = ["name": "rex", "breed": "cane corso"]
        let document3: Document = ["name": "john", "breed": "cane corso"]

        collection.findOneAndUpdate(filter: document, update: document2).await(self)

        let options1 = FindOneAndModifyOptions(["name": 1], ["_id": 1], true, true)
        collection.findOneAndUpdate(filter: document2, update: document3, options: options1).await(self) { updateResult in
            guard let updateResult = updateResult else {
                XCTFail("Should find")
                return
            }
            XCTAssertEqual(updateResult["name"]??.stringValue, "john")
        }

        let options2 = FindOneAndModifyOptions(["name": 1], ["_id": 1], true, true)
        collection.findOneAndUpdate(filter: document, update: document2, options: options2).await(self) { updateResult in
            guard let updateResult = updateResult else {
                XCTFail("Should find")
                return
            }
            XCTAssertEqual(updateResult["name"]??.stringValue, "rex")
        }
    }

    func testMongoCollectionFindAndReplaceCombine() throws {
        let collection = try setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]
        let document2: Document = ["name": "rex", "breed": "cane corso"]
        let document3: Document = ["name": "john", "breed": "cane corso"]

        collection.findOneAndReplace(filter: document, replacement: document2).await(self) { updateResult in
            XCTAssertNil(updateResult)
        }

        let options1 = FindOneAndModifyOptions(["name": 1], ["_id": 1], true, true)
        collection.findOneAndReplace(filter: document2, replacement: document3, options: options1).await(self) { updateResult in
            guard let updateResult = updateResult else {
                XCTFail("Should find")
                return
            }
            XCTAssertEqual(updateResult["name"]??.stringValue, "john")
        }

        let options2 = FindOneAndModifyOptions(["name": 1], ["_id": 1], true, false)
        collection.findOneAndReplace(filter: document, replacement: document2, options: options2).await(self) { updateResult in
            XCTAssertNil(updateResult)
        }
    }

    func testMongoCollectionFindAndDeleteCombine() throws {
        let collection = try setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]
        collection.insertMany([document]).await(self)

        collection.findOneAndDelete(filter: document).await(self) { updateResult in
            XCTAssertNotNil(updateResult)
        }
        collection.findOneAndDelete(filter: document).await(self) { updateResult in
            XCTAssertNil(updateResult)
        }

        collection.insertMany([document]).await(self)
        let options1 = FindOneAndModifyOptions(projection: ["name": 1], sort: ["_id": 1], upsert: false, shouldReturnNewDocument: false)
        collection.findOneAndDelete(filter: document, options: options1).await(self) { deleteResult in
            XCTAssertNotNil(deleteResult)
        }
        collection.findOneAndDelete(filter: document, options: options1).await(self) { deleteResult in
            XCTAssertNil(deleteResult)
        }

        collection.insertMany([document]).await(self)
        let options2 = FindOneAndModifyOptions(["name": 1], ["_id": 1])
        collection.findOneAndDelete(filter: document, options: options2).await(self) { deleteResult in
            XCTAssertNotNil(deleteResult)
        }
        collection.findOneAndDelete(filter: document, options: options2).await(self) { deleteResult in
            XCTAssertNil(deleteResult)
        }

        collection.insertMany([document]).await(self)
        collection.find(filter: [:]).await(self) { updateResult in
            XCTAssertEqual(updateResult.count, 1)
        }
    }

    func testCallFunctionCombine() {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)

        app.emailPasswordAuth.registerUser(email: email, password: password).await(self)

        let credentials = Credentials.emailPassword(email: email, password: password)
        app.login(credentials: credentials).await(self) { user in
            XCTAssertNotNil(user)
        }

        app.currentUser?.functions.sum([1, 2, 3, 4, 5]).await(self) { bson in
            guard case let .int32(sum) = bson else {
                XCTFail("Should be int32")
                return
            }
            XCTAssertEqual(sum, 15)
        }

        app.currentUser?.functions.updateUserData([["favourite_colour": "green", "apples": 10]]).await(self) { bson in
            guard case let .bool(upd) = bson else {
                XCTFail("Should be bool")
                return
            }
            XCTAssertTrue(upd)
        }
    }

    func testAPIKeyAuthCombine() {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)

        app.emailPasswordAuth.registerUser(email: email, password: password).await(self)

        let user = app.login(credentials: Credentials.emailPassword(email: email, password: password)).await(self)

        let apiKey = user.apiKeysAuth.createAPIKey(named: "my-api-key").await(self)
        user.apiKeysAuth.fetchAPIKey(apiKey.objectId).await(self)
        user.apiKeysAuth.fetchAPIKeys().await(self) { userApiKeys in
            XCTAssertEqual(userApiKeys.count, 1)
        }

        user.apiKeysAuth.disableAPIKey(apiKey.objectId).await(self)
        user.apiKeysAuth.enableAPIKey(apiKey.objectId).await(self)
        user.apiKeysAuth.deleteAPIKey(apiKey.objectId).await(self)
    }

    func testPushRegistrationCombine() {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)

        app.emailPasswordAuth.registerUser(email: email, password: password).await(self)
        app.login(credentials: Credentials.emailPassword(email: email, password: password)).await(self)

        let client = app.pushClient(serviceName: "gcm")
        client.registerDevice(token: "some-token", user: app.currentUser!).await(self)
        client.deregisterDevice(user: app.currentUser!).await(self)
    }
}

#if swift(>=5.6) && canImport(_Concurrency)

@available(macOS 12.0, *)
class AsyncAwaitObjectServerTests: SwiftSyncTestCase {
    override class var defaultTestSuite: XCTestSuite {
        // async/await is currently incompatible with thread sanitizer and will
        // produce many false positives
        // https://bugs.swift.org/browse/SR-15444
        if RLMThreadSanitizerEnabled() {
            return XCTestSuite(name: "\(type(of: self))")
        }
        return super.defaultTestSuite
    }

    func assertThrowsError<T, E: Error>(_ expression: @autoclosure () async throws -> T,
                                        file: StaticString = #filePath, line: UInt = #line,
                                        _ errorHandler: (_ error: E) -> Void) async {
        do {
            _ = try await expression()
            XCTFail("Expression should have thrown an error", file: file, line: line)
        } catch let error as E {
            errorHandler(error)
        } catch {
            XCTFail("Expected error of type \(E.self) but got \(error)")
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
        let user = try await self.app.login(credentials: basicCredentials())
        let realm = try await Realm(configuration: user.configuration(testName: #function))
        try realm.write {
            realm.add(SwiftHugeSyncObject.create())
            realm.add(SwiftHugeSyncObject.create())
        }
        waitForUploads(for: realm)

        let user2 = try await app.login(credentials: .anonymous)
        let realm2 = try await Realm(configuration: user2.configuration(testName: #function),
                                    downloadBeforeOpen: .once)
        XCTAssertEqual(realm2.objects(SwiftHugeSyncObject.self).count, 2)
    }

    @MainActor func testAsyncOpenDownloadBehaviorNever() async throws {
        // Populate the Realm on the server
        let user1 = try await self.app.login(credentials: basicCredentials())
        let realm1 = try await Realm(configuration: user1.configuration(testName: #function))
        try realm1.write {
            realm1.add(SwiftHugeSyncObject.create())
            realm1.add(SwiftHugeSyncObject.create())
        }
        waitForUploads(for: realm1)

        // Should not have any objects as it just opens immediately without waiting
        let user2 = try await app.login(credentials: .anonymous)
        let realm2 = try await Realm(configuration: user2.configuration(testName: #function),
                                    downloadBeforeOpen: .never)
        XCTAssertEqual(realm2.objects(SwiftHugeSyncObject.self).count, 0)
    }

    @MainActor func testAsyncOpenDownloadBehaviorOnce() async throws {
        // Populate the Realm on the server
        let user1 = try await self.app.login(credentials: basicCredentials())
        let realm1 = try await Realm(configuration: user1.configuration(testName: #function))
        try realm1.write {
            realm1.add(SwiftHugeSyncObject.create())
            realm1.add(SwiftHugeSyncObject.create())
        }
        waitForUploads(for: realm1)

        // Should have the objects
        let user2 = try await app.login(credentials: .anonymous)
        let realm2 = try await Realm(configuration: user2.configuration(testName: #function),
                                     downloadBeforeOpen: .once)
        XCTAssertEqual(realm2.objects(SwiftHugeSyncObject.self).count, 2)
        realm2.syncSession?.suspend()

        // Add some more objects
        try realm1.write {
            realm1.add(SwiftHugeSyncObject.create())
            realm1.add(SwiftHugeSyncObject.create())
        }
        waitForUploads(for: realm1)

        // Will not wait for the new objects to download
        let realm3 = try await Realm(configuration: user2.configuration(testName: #function),
                                     downloadBeforeOpen: .once)
        XCTAssertEqual(realm3.objects(SwiftHugeSyncObject.self).count, 2)
    }


    @MainActor func testAsyncOpenDownloadBehaviorAlways() async throws {
        // Populate the Realm on the server
        let user1 = try await self.app.login(credentials: basicCredentials())
        let realm1 = try await Realm(configuration: user1.configuration(testName: #function))
        try realm1.write {
            realm1.add(SwiftHugeSyncObject.create())
            realm1.add(SwiftHugeSyncObject.create())
        }
        waitForUploads(for: realm1)

        // Should have the objects
        let user2 = try await app.login(credentials: .anonymous)
        let realm2 = try await Realm(configuration: user2.configuration(testName: #function),
                                     downloadBeforeOpen: .always)
        XCTAssertEqual(realm2.objects(SwiftHugeSyncObject.self).count, 2)
        realm2.syncSession?.suspend()

        // Add some more objects
        try realm1.write {
            realm1.add(SwiftHugeSyncObject.create())
            realm1.add(SwiftHugeSyncObject.create())
        }
        waitForUploads(for: realm1)

        // Should wait for the new objects to download
        let realm3 = try await Realm(configuration: user2.configuration(testName: #function),
                                     downloadBeforeOpen: .always)
        XCTAssertEqual(realm3.objects(SwiftHugeSyncObject.self).count, 4)
    }

    func testCallResetPasswordAsyncAwait() async throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)
        try await app.emailPasswordAuth.registerUser(email: email, password: password)
        let auth = app.emailPasswordAuth
        await assertThrowsError(try await auth.callResetPasswordFunction(email: email,
                                                                         password: randomString(10),
                                                                         args: [[:]])) {
            assertAppError($0, .unknown, "failed to reset password for user \(email)")
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
        guard case let .int32(sum) = try await user.functions.sum([1, 2, 3, 4, 5]) else {
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
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)
        try await app.emailPasswordAuth.registerUser(email: email, password: password)

        let user = try await self.app.login(credentials: .anonymous)
        XCTAssertNotNil(user)

        _ = try await user.functions.updateUserData([
            ["favourite_colour": "green", "apples": 10]
        ])

        try await app.currentUser?.refreshCustomData()
        XCTAssertEqual(app.currentUser?.customData["favourite_colour"], .string("green"))
        XCTAssertEqual(app.currentUser?.customData["apples"], .int64(10))
    }

    func testDeleteUserAsyncAwait() async throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)
        let credentials: Credentials = .emailPassword(email: email, password: password)
        try await app.emailPasswordAuth.registerUser(email: email, password: password)

        let user = try await self.app.login(credentials: credentials)
        XCTAssertNotNil(user)

        XCTAssertNotNil(app.currentUser)
        try await user.delete()

        XCTAssertNil(app.currentUser)
        XCTAssertEqual(app.allUsers.count, 0)
    }
}

#endif // swift(>=5.6)
#endif // os(macOS)
