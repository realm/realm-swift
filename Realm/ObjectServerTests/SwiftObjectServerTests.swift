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

    func removeAllFromCollection(_ collection: MongoCollection) {
        let ex = expectation(description: "delete objects")
        collection.deleteManyDocuments(filter: [:]) { result in
            switch result {
            case .success:
                ex.fulfill()
            case .failure(let error):
                XCTFail("Error: \(error.localizedDescription)")
            }
        }
        wait(for: [ex], timeout: 30.0)
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

    func waitForSyncDisabled(appServerId: String, syncServiceId: String) {
        XCTAssertTrue(try RealmServer.shared.syncEnabled(appServerId: appServerId, syncServiceId: syncServiceId))
        let exp = expectation(description: "disable sync")
        RealmServer.shared.disableSync(appServerId: appServerId, syncServiceId: syncServiceId) { results in
            switch results {
            case .success:
                exp.fulfill()
            case .failure(let error):
                XCTFail("Error: \(error.localizedDescription)")
            }
        }
        waitForExpectations(timeout: 6, handler: nil)
        XCTAssertFalse(try RealmServer.shared.syncEnabled(appServerId: appServerId, syncServiceId: syncServiceId))
    }

    func waitForSyncEnabled(appServerId: String, syncServiceId: String, syncServiceConfig: [String: Any]) {
        let exp = expectation(description: "enable sync")
        RealmServer.shared.enableSync(appServerId: appServerId, syncServiceId: syncServiceId, syncServiceConfiguration: syncServiceConfig) { results in
            switch results {
            case .success:
                exp.fulfill()
            case .failure(let error):
                XCTFail("Error: \(error.localizedDescription)")
            }
        }
        waitForExpectations(timeout: 20, handler: nil)
        XCTAssertTrue(try RealmServer.shared.syncEnabled(appServerId: appServerId, syncServiceId: syncServiceId))
    }

    func waitForDevModeEnabled(appServerId: String, syncServiceId: String, syncServiceConfig: [String: Any]) throws {
        let devModeEnabled = try RealmServer.shared.devModeEnabled(appServerId: appServerId, syncServiceId: syncServiceId)
        let exp = expectation(description: "enable dev mode")
        if !devModeEnabled {
            RealmServer.shared.enableDevMode(appServerId: appServerId, syncServiceId: syncServiceId, syncServiceConfiguration: syncServiceConfig) { results in
                switch results {
                case .success:
                    exp.fulfill()
                case .failure(let error):
                    XCTFail("Error: \(error.localizedDescription)")
                }
            }
        }
        waitForExpectations(timeout: 6, handler: nil)
        XCTAssertTrue(try RealmServer.shared.devModeEnabled(appServerId: appServerId, syncServiceId: syncServiceId))
    }

    // This function disables sync, executes a block while the sync service is disabled, then re-enables the sync service and dev mode.
    func executeBlockOffline(block: () throws -> Void) throws {
        let appServerId = try RealmServer.shared.retrieveAppServerId(appId)
        let syncServiceId = try RealmServer.shared.retrieveSyncServiceId(appServerId: appServerId)
        guard let syncServiceConfig = try RealmServer.shared.getSyncServiceConfiguration(appServerId: appServerId, syncServiceId: syncServiceId) else { fatalError("precondition failure: no sync service configuration found") }

        waitForSyncDisabled(appServerId: appServerId, syncServiceId: syncServiceId)

        try block()

        waitForSyncEnabled(appServerId: appServerId, syncServiceId: syncServiceId, syncServiceConfig: syncServiceConfig)
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
        let realm = try openRealm(partitionValue: #function, user: user)

        let e = expectSyncError {
            user.simulateClientResetError(forSession: #function)
        }
        guard let error = e else { return }
        XCTAssertTrue(error.code == SyncError.Code.clientResetError)
        guard let resetInfo = error.clientResetInfo() else {
            XCTAssertNotNil(error.clientResetInfo())
            return
        }
        XCTAssertTrue(resetInfo.0.contains("mongodb-realm/\(self.appId)/recovered-realms/recovered_realm"))
        XCTAssertNotNil(realm)
    }

    func testClientResetManualInitiation() throws {
        let user = try logInUser(for: basicCredentials())

        let e: SyncError? = try autoreleasepool {
            let realm = try openRealm(partitionValue: #function, user: user)
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
        try executeBlockOffline {
            try autoreleasepool {
                var configuration = user.configuration(partitionValue: partition)
                configuration.objectTypes = [SwiftPerson.self]
                let realm = try Realm(configuration: configuration)
                // Add an object to the local realm that will not be in the server realm (because sync is disabled).
                try realm.write {
                    realm.add(SwiftPerson(firstName: "John", lastName: "L"))
                }
                XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
            }
        }

        // After restarting sync, the sync history translator service needs time
        // to resynthesize the new history from existing objects on the server
        // The following creates a new realm with the same parition and wait for
        // downloads to ensure the the new history has been created.
        try autoreleasepool {
            var newConfig = user.configuration(partitionValue: partition)
            newConfig.fileURL = RLMTestRealmURL()
            newConfig.objectTypes = [SwiftPerson.self]
            let newRealm = try Realm(configuration: newConfig)

            let start = Date()
            while newRealm.isEmpty && start.timeIntervalSinceNow > -60.0 {
                self.waitForDownloads(for: newRealm)
                sleep(1) // Wait between requests
            }
            if newRealm.objects(SwiftPerson.self).count > 0 {
                XCTAssertEqual(newRealm.objects(SwiftPerson.self).count, 1)
                XCTAssertEqual(newRealm.objects(SwiftPerson.self)[0].firstName, "Paul")
            } else {
                XCTFail("Waited longer than one minute for history to resynthesize")
                return
            }
        }
    }

    func testClientResetDiscardLocal() throws {
        let user = try logInUser(for: basicCredentials())
        try prepareClientReset(#function, user)

        // Define the blocks that will be passed into the sync configuration initializer.
        let beforeCallbackEx = expectation(description: "before reset callback")
        let beforeClientResetBlock: (Realm) -> Void = { local in
            let results = local.objects(SwiftPerson.self)
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

        var configuration = user.configuration(partitionValue: #function, clientResetMode: .discardLocal(beforeClientResetBlock, afterClientResetBlock))
        configuration.objectTypes = [SwiftPerson.self]

        guard let syncConfig = configuration.syncConfiguration else { fatalError("Test condition failure. SyncConfiguration not set.") }
        switch syncConfig.clientResetMode {
        case .manual:
            XCTFail("Should be set to discardLocal")
        case .discardLocal(let before, let after):
            XCTAssertNotNil(before)
            XCTAssertNotNil(after)
        }

        try autoreleasepool {
            let realm = try Realm(configuration: configuration)
            wait(for: [beforeCallbackEx, afterCallbackEx], timeout: 60.0)
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1) // Expect the server realm (one object) to have overwritten the local realm (2 objects)
            XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "Paul")
        }
    }

    func testClientResetDiscardLocalAsyncOpen() throws {
        let user = try logInUser(for: basicCredentials())
        try prepareClientReset(#function, user)

        let beforeCallbackEx = expectation(description: "before reset callback")
        let beforeClientResetBlock: (Realm) -> Void = { local in
            let results = local.objects(SwiftPerson.self)
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

        var configuration = user.configuration(partitionValue: #function, clientResetMode: .discardLocal(beforeClientResetBlock, afterClientResetBlock))
        configuration.objectTypes = [SwiftPerson.self]

        let asyncOpenEx = expectation(description: "async open")
        Realm.asyncOpen(configuration: configuration) { result in
            let realm = try! result.get()
            XCTAssertEqual(realm.objects(SwiftPerson.self).count, 1)
            XCTAssertEqual(realm.objects(SwiftPerson.self)[0].firstName, "Paul")
            asyncOpenEx.fulfill()
        }
        wait(for: [beforeCallbackEx, afterCallbackEx, asyncOpenEx], timeout: 60.0)
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
            waitForExpectations(timeout: 4.0, handler: nil)
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

    func testUserExpirationCallback() throws {
        let user = try logInUser(for: basicCredentials())

        // Set a callback on the user
        var blockCalled = false
        let ex = expectation(description: "Error callback should fire upon receiving an error")
        app.syncManager.errorHandler = { (error, _) in
            XCTAssertNotNil(error)
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

        let registerUserEx = expectation(description: "Register user")

        app.emailPasswordAuth.registerUser(email: email, password: password) { (error) in
            XCTAssertNil(error)
            registerUserEx.fulfill()
        }
        wait(for: [registerUserEx], timeout: 4.0)

        let loginEx = expectation(description: "Login user")
        var syncUser: User?

        app.login(credentials: Credentials.emailPassword(email: email, password: password)) { result in
            switch result {
            case .success(let user):
                syncUser = user
            case .failure:
                XCTFail("Should login user")
            }
            loginEx.fulfill()
        }

        wait(for: [loginEx], timeout: 4.0)

        XCTAssertEqual(syncUser?.id, app.currentUser?.id)
        XCTAssertEqual(app.allUsers.count, 1)
    }

    func testAppSwitchAndRemove() {
        let email1 = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password1 = randomString(10)
        let email2 = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password2 = randomString(10)

        let registerUser1Ex = expectation(description: "Register user 1")
        let registerUser2Ex = expectation(description: "Register user 2")

        app.emailPasswordAuth.registerUser(email: email1, password: password1) { (error) in
            XCTAssertNil(error)
            registerUser1Ex.fulfill()
        }

        app.emailPasswordAuth.registerUser(email: email2, password: password2) { (error) in
            XCTAssertNil(error)
            registerUser2Ex.fulfill()
        }

        wait(for: [registerUser1Ex, registerUser2Ex], timeout: 4.0)

        let login1Ex = expectation(description: "Login user 1")
        let login2Ex = expectation(description: "Login user 2")

        var syncUser1: User?
        var syncUser2: User?

        app.login(credentials: Credentials.emailPassword(email: email1, password: password1)) { result in
            if case .success(let user) = result {
                syncUser1 = user
            } else {
                XCTFail("Should login user 1")
            }
            login1Ex.fulfill()
        }

        wait(for: [login1Ex], timeout: 4.0)

        app.login(credentials: Credentials.emailPassword(email: email2, password: password2)) { result in
            if case .success(let user) = result {
                syncUser2 = user
            } else {
                XCTFail("Should login user 2")
            }
            login2Ex.fulfill()
        }

        wait(for: [login2Ex], timeout: 4.0)

        XCTAssertEqual(app.allUsers.count, 2)

        XCTAssertEqual(syncUser2!.id, app.currentUser!.id)

        app.switch(to: syncUser1!)
        XCTAssertTrue(syncUser1!.id == app.currentUser?.id)

        let removeEx = expectation(description: "Remove user 1")

        syncUser1?.remove { (error) in
            XCTAssertNil(error)
            removeEx.fulfill()
        }

        wait(for: [removeEx], timeout: 4.0)

        XCTAssertEqual(syncUser2!.id, app.currentUser!.id)
        XCTAssertEqual(app.allUsers.count, 1)
    }

    func testSafelyRemoveUser() throws {
        // A user can have its state updated asynchronously so we need to make sure
        // that remotely disabling / deleting a user is handled correctly in the
        // sync error handler.
        let loginEx = expectation(description: "login-user")
        app.login(credentials: .anonymous) { result in
            switch result {
            case .success:
                loginEx.fulfill()
            case .failure:
                XCTFail("Should login user")
            }
        }
        wait(for: [loginEx], timeout: 4.0)

        let user = app.currentUser!

        // Set a callback on the user
        var blockCalled = false
        let ex = expectation(description: "Error callback should fire upon receiving an error")
        app.syncManager.errorHandler = { (error, _) in
            XCTAssertNotNil(error)
            blockCalled = true
            ex.fulfill()
        }

        let deleteUserEx = expectation(description: "delete-user")
        RealmServer.shared.removeUserForApp(appId, userId: user.id) { result in
            switch result {
            case .success:
                break
            case .failure:
                XCTFail("Should delete User")
            }
            deleteUserEx.fulfill()
        }
        wait(for: [deleteUserEx], timeout: 4.0)

        // Try to open a Realm with the user; this will cause our errorHandler block defined above to be fired.
        XCTAssertFalse(blockCalled)
        _ = try immediatelyOpenRealm(partitionValue: #function, user: user)

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testDeleteUser() {
        func userExistsOnServer(_ user: User) -> Bool {
            let serverEx = expectation(description: "server-user")
            var userExists = false
            RealmServer.shared.retrieveUser(appId, userId: user.id) { result in
                switch result {
                case .success(let u):
                    let u = u as! [String: Any]
                    XCTAssertEqual(u["_id"] as! String, user.id)
                    userExists = true
                case .failure:
                    userExists = false
                }
                serverEx.fulfill()
            }
            wait(for: [serverEx], timeout: 4.0)
            return userExists
        }

        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)

        let registerUserEx = expectation(description: "Register user")

        app.emailPasswordAuth.registerUser(email: email, password: password) { (error) in
            XCTAssertNil(error)
            registerUserEx.fulfill()
        }
        wait(for: [registerUserEx], timeout: 4.0)

        let loginEx = expectation(description: "Login user")
        var syncUser: User?

        app.login(credentials: Credentials.emailPassword(email: email, password: password)) { result in
            switch result {
            case .success(let user):
                syncUser = user
            case .failure:
                XCTFail("Should login user")
            }
            loginEx.fulfill()
        }

        wait(for: [loginEx], timeout: 4.0)
        XCTAssertTrue(userExistsOnServer(syncUser!))

        XCTAssertEqual(syncUser?.id, app.currentUser?.id)
        XCTAssertEqual(app.allUsers.count, 1)

        let deleteEx = expectation(description: "Delete user")

        XCTAssertNotNil(syncUser)

        syncUser?.delete { (error) in
            XCTAssertNil(error)
            deleteEx.fulfill()
        }

        wait(for: [deleteEx], timeout: 4.0)

        XCTAssertFalse(userExistsOnServer(syncUser!))
        XCTAssertNil(app.currentUser)
        XCTAssertEqual(app.allUsers.count, 0)
    }

    func testAppLinkUser() {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)

        let registerUserEx = expectation(description: "Register user")

        app.emailPasswordAuth.registerUser(email: email, password: password) { (error) in
            XCTAssertNil(error)
            registerUserEx.fulfill()
        }
        wait(for: [registerUserEx], timeout: 4.0)

        let loginEx = expectation(description: "Login user")
        var syncUser: User!

        let credentials = Credentials.emailPassword(email: email, password: password)

        app.login(credentials: Credentials.anonymous) { result in
            if case .success(let user) = result {
                syncUser = user
            } else {
                XCTFail("Should login user")
            }
            loginEx.fulfill()
        }
        wait(for: [loginEx], timeout: 4.0)

        let linkEx = expectation(description: "Link user")
        syncUser.linkUser(credentials: credentials) { result in
            switch result {
            case .success(let user):
                syncUser = user
            case .failure:
                XCTFail("Should link user")
            }
            linkEx.fulfill()
        }

        wait(for: [linkEx], timeout: 4.0)

        XCTAssertEqual(syncUser?.id, app.currentUser?.id)
        XCTAssertEqual(syncUser?.identities.count, 2)
    }

    // MARK: - Provider Clients

    func testEmailPasswordProviderClient() {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)

        let registerUserEx = expectation(description: "Register user")

        app.emailPasswordAuth.registerUser(email: email, password: password) { (error) in
            XCTAssertNil(error)
            registerUserEx.fulfill()
        }
        wait(for: [registerUserEx], timeout: 4.0)

        let confirmUserEx = expectation(description: "Confirm user")

        app.emailPasswordAuth.confirmUser("atoken", tokenId: "atokenid") { (error) in
            XCTAssertNotNil(error)
            confirmUserEx.fulfill()
        }
        wait(for: [confirmUserEx], timeout: 4.0)

        let resendEmailEx = expectation(description: "Resend email confirmation")

        app.emailPasswordAuth.resendConfirmationEmail("atoken") { (error) in
            XCTAssertNotNil(error)
            resendEmailEx.fulfill()
        }
        wait(for: [resendEmailEx], timeout: 4.0)

        let retryCustomEx = expectation(description: "Retry custom confirmation")

        app.emailPasswordAuth.retryCustomConfirmation(email) { (error) in
            XCTAssertNotNil(error)
            retryCustomEx.fulfill()
        }
        wait(for: [retryCustomEx], timeout: 4.0)

        let resendResetPasswordEx = expectation(description: "Resend reset password email")

        app.emailPasswordAuth.sendResetPasswordEmail("atoken") { (error) in
            XCTAssertNotNil(error)
            resendResetPasswordEx.fulfill()
        }
        wait(for: [resendResetPasswordEx], timeout: 4.0)

        let resetPasswordEx = expectation(description: "Reset password email")

        app.emailPasswordAuth.resetPassword(to: "password", token: "atoken", tokenId: "tokenId") { (error) in
            XCTAssertNotNil(error)
            resetPasswordEx.fulfill()
        }
        wait(for: [resetPasswordEx], timeout: 4.0)

        let callResetFunctionEx = expectation(description: "Reset password function")
        app.emailPasswordAuth.callResetPasswordFunction(email: email,
                                                        password: randomString(10),
                                                        args: [[:]]) { (error) in
            XCTAssertNotNil(error)
            callResetFunctionEx.fulfill()
        }
        wait(for: [callResetFunctionEx], timeout: 4.0)
    }

    func testUserAPIKeyProviderClient() {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)

        let registerUserEx = expectation(description: "Register user")

        app.emailPasswordAuth.registerUser(email: email, password: password) { (error) in
            XCTAssertNil(error)
            registerUserEx.fulfill()
        }
        wait(for: [registerUserEx], timeout: 4.0)

        let loginEx = expectation(description: "Login user")
        let credentials = Credentials.emailPassword(email: email, password: password)

        var syncUser: User?
        app.login(credentials: credentials) { result in
            switch result {
            case .success(let user):
                syncUser = user
            case .failure:
                XCTFail("Should link user")
            }
            loginEx.fulfill()
        }

        wait(for: [loginEx], timeout: 4.0)

        let createAPIKeyEx = expectation(description: "Create user api key")

        var apiKey: UserAPIKey?
        syncUser?.apiKeysAuth.createAPIKey(named: "my-api-key") { (key, error) in
            XCTAssertNotNil(key)
            XCTAssertNil(error)
            apiKey = key
            createAPIKeyEx.fulfill()
        }
        wait(for: [createAPIKeyEx], timeout: 4.0)

        let fetchAPIKeyEx = expectation(description: "Fetch user api key")
        syncUser?.apiKeysAuth.fetchAPIKey(apiKey!.objectId) { (key, error) in
            XCTAssertNotNil(key)
            XCTAssertNil(error)
            fetchAPIKeyEx.fulfill()
        }
        wait(for: [fetchAPIKeyEx], timeout: 4.0)

        let fetchAPIKeysEx = expectation(description: "Fetch user api keys")
        syncUser?.apiKeysAuth.fetchAPIKeys(completion: { (keys, error) in
            XCTAssertNotNil(keys)
            XCTAssertEqual(keys!.count, 1)
            XCTAssertNil(error)
            fetchAPIKeysEx.fulfill()
        })
        wait(for: [fetchAPIKeysEx], timeout: 4.0)

        let disableKeyEx = expectation(description: "Disable API key")
        syncUser?.apiKeysAuth.disableAPIKey(apiKey!.objectId) { (error) in
            XCTAssertNil(error)
            disableKeyEx.fulfill()
        }
        wait(for: [disableKeyEx], timeout: 4.0)

        let enableKeyEx = expectation(description: "Enable API key")
        syncUser?.apiKeysAuth.enableAPIKey(apiKey!.objectId) { (error) in
            XCTAssertNil(error)
            enableKeyEx.fulfill()
        }
        wait(for: [enableKeyEx], timeout: 4.0)

        let deleteKeyEx = expectation(description: "Delete API key")
        syncUser?.apiKeysAuth.deleteAPIKey(apiKey!.objectId) { (error) in
            XCTAssertNil(error)
            deleteKeyEx.fulfill()
        }
        wait(for: [deleteKeyEx], timeout: 4.0)
    }

    func testApiKeyAuthResultCompletion() {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)

        let registerUserEx = expectation(description: "Register user")
        app.emailPasswordAuth.registerUser(email: email, password: password) { (error) in
            XCTAssertNil(error)
            registerUserEx.fulfill()
        }
        wait(for: [registerUserEx], timeout: 4.0)

        let loginEx = expectation(description: "Login user")
        let credentials = Credentials.emailPassword(email: email, password: password)
        var syncUser: User?
        app.login(credentials: credentials) { result in
            switch result {
            case .success(let user):
                syncUser = user
            case .failure:
                XCTFail("Should login")
            }
            loginEx.fulfill()
        }
        wait(for: [loginEx], timeout: 4.0)

        let createAPIKeyEx = expectation(description: "Create user api key")
        var apiKey: UserAPIKey?
        syncUser?.apiKeysAuth.createAPIKey(named: "my-api-key") { result in
            switch result {
            case .success(let userAPIKey):
                apiKey = userAPIKey
            case .failure:
                XCTFail("Should create api key")
            }
            createAPIKeyEx.fulfill()
        }
        wait(for: [createAPIKeyEx], timeout: 4.0)

        let fetchAPIKeyEx = expectation(description: "Fetch user api key")
        syncUser?.apiKeysAuth.fetchAPIKey(apiKey!.objectId as! ObjectId, { result in
            if case .failure = result {
                XCTFail("Should fetch api key")
            }
            fetchAPIKeyEx.fulfill()
        })
        wait(for: [fetchAPIKeyEx], timeout: 4.0)

        let fetchAPIKeysEx = expectation(description: "Fetch user api keys")
        syncUser?.apiKeysAuth.fetchAPIKeys { result in
            switch result {
            case .success(let userAPIKeys):
                XCTAssertEqual(userAPIKeys.count, 1)
            case .failure:
                XCTFail("Should fetch api key")
            }
            fetchAPIKeysEx.fulfill()
        }
        wait(for: [fetchAPIKeysEx], timeout: 4.0)
    }

    func testCallFunction() {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)

        let registerUserEx = expectation(description: "Register user")

        app.emailPasswordAuth.registerUser(email: email, password: password) { (error) in
            XCTAssertNil(error)
            registerUserEx.fulfill()
        }
        wait(for: [registerUserEx], timeout: 4.0)

        let loginEx = expectation(description: "Login user")

        let credentials = Credentials.emailPassword(email: email, password: password)
        app.login(credentials: credentials) { result in
            switch result {
            case .success(let user):
                XCTAssertNotNil(user)
            case .failure:
                XCTFail("Should link user")
            }
            loginEx.fulfill()
        }
        wait(for: [loginEx], timeout: 4.0)

        let callFunctionEx = expectation(description: "Call function")
        app.currentUser?.functions.sum([1, 2, 3, 4, 5]) { bson, error in
            guard let bson = bson else {
                XCTFail(error!.localizedDescription)
                return
            }

            guard case let .int32(sum) = bson else {
                XCTFail(error!.localizedDescription)
                return
            }

            XCTAssertNil(error)
            XCTAssertEqual(sum, 15)
            callFunctionEx.fulfill()
        }
        wait(for: [callFunctionEx], timeout: 4.0)

        // Test function with completion handler (Result<AnyBSON, Error>) -> Void
        let callFunctionResultEx = expectation(description: "Call function")
        app.currentUser?.functions.sum([1, 2, 3, 4, 5]) { result in
            switch result {
            case .success(let bson):
                guard case let .int32(sum) = bson else {
                    XCTFail("Should be an int32")
                    return
                }
                XCTAssertEqual(sum, 15)
            case .failure(let error):
                XCTFail("Function should not fail \(error)")
            }
            callFunctionResultEx.fulfill()
        }
        wait(for: [callFunctionResultEx], timeout: 4.0)
    }

    func testPushRegistration() {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)

        let registerUserEx = expectation(description: "Register user")

        app.emailPasswordAuth.registerUser(email: email, password: password) { (error) in
            XCTAssertNil(error)
            registerUserEx.fulfill()
        }
        wait(for: [registerUserEx], timeout: 4.0)

        let loginExpectation = expectation(description: "Login user")

        let credentials = Credentials.emailPassword(email: email, password: password)
        app.login(credentials: credentials) { result in
            if case .failure = result {
                XCTFail("Should link user")
            }
            loginExpectation.fulfill()
        }
        wait(for: [loginExpectation], timeout: 4.0)

        let registerDeviceExpectation = expectation(description: "Register Device")
        let client = app.pushClient(serviceName: "gcm")
        client.registerDevice(token: "some-token", user: app.currentUser!) { error in
            XCTAssertNil(error)
            registerDeviceExpectation.fulfill()
        }
        wait(for: [registerDeviceExpectation], timeout: 4.0)

        let dergisterDeviceExpectation = expectation(description: "Deregister Device")
        client.deregisterDevice(user: app.currentUser!, completion: { error in
            XCTAssertNil(error)
            dergisterDeviceExpectation.fulfill()
        })
        wait(for: [dergisterDeviceExpectation], timeout: 4.0)
    }

    func testCustomUserData() {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)

        let registerUserEx = expectation(description: "Register user")

        app.emailPasswordAuth.registerUser(email: email, password: password) { (error) in
            XCTAssertNil(error)
            registerUserEx.fulfill()
        }
        wait(for: [registerUserEx], timeout: 4.0)

        let loginEx = expectation(description: "Login user")
        let credentials = Credentials.emailPassword(email: email, password: password)
        app.login(credentials: credentials) { result in
            switch result {
            case .success(let user):
                XCTAssertNotNil(user)
            case .failure:
                XCTFail("Should link user")
            }
            loginEx.fulfill()
        }
        wait(for: [loginEx], timeout: 4.0)

        let userDataEx = expectation(description: "Update user data")
        app.currentUser?.functions.updateUserData([["favourite_colour": "green", "apples": 10]]) { _, error  in
            XCTAssertNil(error)
            userDataEx.fulfill()
        }
        wait(for: [userDataEx], timeout: 4.0)

        let refreshDataEx = expectation(description: "Refresh user data")
        app.currentUser?.refreshCustomData { customData, error in
            XCTAssertNil(error)
            XCTAssertNotNil(customData)
            XCTAssertEqual(customData?["apples"] as! Int, 10)
            XCTAssertEqual(customData?["favourite_colour"] as! String, "green")
            refreshDataEx.fulfill()
        }
        wait(for: [refreshDataEx], timeout: 4.0)

        XCTAssertEqual(app.currentUser?.customData["favourite_colour"], .string("green"))
        XCTAssertEqual(app.currentUser?.customData["apples"], .int64(10))
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

    func testWriteCopyFailBeforeSynced() {
        var didFail = false
        do {
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
            try realm.writeCopy(configuration: user2Config)
            XCTFail("writeCopy() should have thrown an error")
        } catch {
            XCTAssertEqual(error.localizedDescription, "Could not write file as not all client changes are integrated in server")
            didFail = true
        }
        XCTAssertTrue(didFail)
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
    func expectValue(_ testCase: XCTestCase, _ expectation: XCTestExpectation, receiveValue: ((Self.Output) -> Void)? = nil) -> AnyCancellable {
        return self.sink(receiveCompletion: { result in
            if case .failure(let error) = result {
                XCTFail("Unexpected failure: \(error)")
            }
        }, receiveValue: { value in
            receiveValue?(value)
            expectation.fulfill()
        })
    }

    func await(_ testCase: XCTestCase, timeout: TimeInterval = 4.0, receiveValue: ((Self.Output) -> Void)? = nil) {
        let expectation = testCase.expectation(description: "Async combine pipeline")
        let cancellable = self.expectValue(testCase, expectation, receiveValue: receiveValue)
        testCase.wait(for: [expectation], timeout: timeout)
        cancellable.cancel()
    }

    @discardableResult
    func await(_ testCase: XCTestCase, timeout: TimeInterval = 4.0) -> Self.Output {
        let expectation = testCase.expectation(description: "Async combine pipeline")
        var value: Self.Output?
        let cancellable = self.expectValue(testCase, expectation, receiveValue: { value = $0 })
        testCase.wait(for: [expectation], timeout: timeout)
        cancellable.cancel()
        return value!
    }

    func awaitFailure(_ testCase: XCTestCase, timeout: TimeInterval = 4.0,
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

    func removeAllFromCollection(_ collection: MongoCollection) {
        collection.deleteManyDocuments(filter: [:]).await(self)
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
        wait(for: [insertManyEx], timeout: 4.0)

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
        wait(for: [insertManyEx], timeout: 4.0)

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

    func testEmailPasswordAuthenticationCombine() {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)
        let auth = app.emailPasswordAuth

        auth.registerUser(email: email, password: password).await(self)
        auth.confirmUser("atoken", tokenId: "atokenid").awaitFailure(self)
        auth.resendConfirmationEmail(email: "atoken").awaitFailure(self)
        auth.retryCustomConfirmation(email: email).awaitFailure(self)
        auth.sendResetPasswordEmail(email: "atoken").awaitFailure(self)
        auth.resetPassword(to: "password", token: "atoken", tokenId: "tokenId").awaitFailure(self)
        auth.callResetPasswordFunction(email: email, password: randomString(10), args: [[:]]).awaitFailure(self)
    }

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

    func testRefreshCustomDataCombine() {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)

        app.emailPasswordAuth.registerUser(email: email, password: password).await(self)

        let credentials = Credentials.emailPassword(email: email, password: password)
        app.login(credentials: credentials)
            .await(self) { user in
                XCTAssertNotNil(user)
            }

        let userDataEx = expectation(description: "Update user data")
        app.currentUser?.functions.updateUserData([["favourite_colour": "green", "apples": 10]]) { _, error  in
            XCTAssertNil(error)
            userDataEx.fulfill()
        }
        wait(for: [userDataEx], timeout: 4.0)

        app.currentUser?.refreshCustomData()
            .await(self) { customData in
                XCTAssertEqual(customData["apples"] as! Int, 10)
                XCTAssertEqual(customData["favourite_colour"] as! String, "green")
            }

        XCTAssertEqual(app.currentUser?.customData["favourite_colour"], .string("green"))
        XCTAssertEqual(app.currentUser?.customData["apples"], .int64(10))
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
            XCTAssertNil(updateResult.objectId)
        }

        collection.updateOneDocument(filter: document5, update: document2, upsert: true).await(self) { updateResult in
            XCTAssertEqual(updateResult.matchedCount, 0)
            XCTAssertEqual(updateResult.modifiedCount, 0)
            XCTAssertNotNil(updateResult.objectId)
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
            XCTAssertNil(updateResult.objectId)
        }
        collection.updateManyDocuments(filter: document5, update: document2, upsert: true).await(self) { updateResult in
            XCTAssertEqual(updateResult.matchedCount, 0)
            XCTAssertEqual(updateResult.modifiedCount, 0)
            XCTAssertNotNil(updateResult.objectId)
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

        var syncUser: User?
        app.login(credentials: Credentials.emailPassword(email: email, password: password)).await(self) { user in
            syncUser = user
        }

        var apiKey: UserAPIKey?
        syncUser?.apiKeysAuth.createAPIKey(named: "my-api-key").await(self) { userApiKey in
            apiKey = userApiKey
        }

        var objId: ObjectId? = try? ObjectId(string: apiKey!.objectId.stringValue)
        syncUser?.apiKeysAuth.fetchAPIKey(objId!).await(self) { userApiKey in
            apiKey = userApiKey
        }

        syncUser?.apiKeysAuth.fetchAPIKeys().await(self) { userApiKeys in
            XCTAssertEqual(userApiKeys.count, 1)
        }

        objId = try? ObjectId(string: apiKey!.objectId.stringValue)
        syncUser?.apiKeysAuth.disableAPIKey(objId!).await(self)
        syncUser?.apiKeysAuth.enableAPIKey(objId!).await(self)
        syncUser?.apiKeysAuth.deleteAPIKey(objId!).await(self)
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

    @MainActor func testAsyncOpenStandalone() async throws {
        try autoreleasepool {
            let realm = try Realm()
            try realm.write {
                (0..<10).forEach { _ in realm.add(SwiftPerson(firstName: "Charlie", lastName: "Bucket")) }
            }
        }
        let realm = try await Realm()
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
        do {
            try await app.emailPasswordAuth.callResetPasswordFunction(email: email,
                                                                      password: randomString(10),
                                                                      args: [[:]])
            XCTFail("Call reset password function should fail")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testAppLinkUserAsyncAwait() async throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)
        try await app.emailPasswordAuth.registerUser(email: email, password: password)

        let syncUser = try await self.app.login(credentials: Credentials.anonymous)
        XCTAssertNotNil(syncUser)

        let credentials = Credentials.emailPassword(email: email, password: password)
        let linkedUser = try await syncUser.linkUser(credentials: credentials)
        XCTAssertNotNil(linkedUser)
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
        XCTAssertTrue(true)
    }

    func testEmailPasswordProviderClientAsyncAwait() async throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let password = randomString(10)
        try await app.emailPasswordAuth.registerUser(email: email, password: password)

        do {
            try await app.emailPasswordAuth.confirmUser("atoken", tokenId: "atokenid")
        } catch {
            XCTAssertNotNil(error)
        }

        do {
            try await app.emailPasswordAuth.resendConfirmationEmail(email)
            XCTFail("Confirm user function should fail")
        } catch {
            XCTAssertNotNil(error)
        }

        do {
            try await app.emailPasswordAuth.retryCustomConfirmation(email)
        } catch {
            XCTAssertNotNil(error)
        }

        do {
            try await app.emailPasswordAuth.sendResetPasswordEmail("atoken")
        } catch {
            XCTAssertNotNil(error)
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
