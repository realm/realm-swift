////////////////////////////////////////////////////////////////////////////
//
// Copyright 2024 Realm Inc.
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
@testable import RealmSwift
import XCTest
import Combine

#if canImport(RealmTestSupport)
import RealmSwiftSyncTestSupport
import RealmSyncTestSupport
import RealmTestSupport
import SwiftUI
import RealmSwiftTestSupport
#endif

@available(macOS 13.0, *)
class SyncMigrationTests: SwiftSyncTestCase {
    override func configuration(user: User) -> Realm.Configuration {
        user.flexibleSyncConfiguration()
    }

    lazy var user: User = createUser()
    
    override func createApp() throws -> String {
        try RealmServer.shared.createApp(fields: [], types: [DogV0.self, CatV0.self], typeUpdates: [[DogV1.self, CatV0.self], [DogV2.self, CatV0.self], [DogV3.self]])
    }
    
    func createConfiguration(schemaVersion: UInt64, dog: ObjectBase.Type, cat: ObjectBase.Type? = nil) throws -> Realm.Configuration {
        var config = configuration(user: user)
        config.schemaVersion = schemaVersion
        config.objectTypes = [dog, cat].compactMap { $0 }
        config.cache = false
        
        return config
    }
    
    func openRealm(config: Realm.Configuration, block: (Realm) throws ->Void = {_ in }) throws {
        let realm = Realm.asyncOpen(configuration: config).await(self)
        RLMRealmSubscribeToAll(ObjectiveCSupport.convert(object: realm))
        waitForDownloads(for: realm)
        
        try block(realm)
        
        realm.close()
    }
    
    func test_SchemaMigration_Consecutive() throws {
        do {
            let config = try createConfiguration(schemaVersion: 0, dog: DogV0.self)
            XCTAssertEqual(false, Realm.requiresMigration(for: config))
            try openRealm(config: config)
        }
        app.syncManager.waitForSessionTermination()
        
        do {
            let config = try createConfiguration(schemaVersion: 1, dog: DogV1.self)
            XCTAssertEqual(true, Realm.requiresMigration(for: config))
            try openRealm(config: config)
        }
        app.syncManager.waitForSessionTermination()
        
        do {
            let config = try createConfiguration(schemaVersion: 2, dog: DogV2.self)
            XCTAssertEqual(true, Realm.requiresMigration(for: config))
            try openRealm(config: config)
        }
        app.syncManager.waitForSessionTermination()
        
        do {
            let config = try createConfiguration(schemaVersion: 3, dog: DogV3.self)
            XCTAssertEqual(true, Realm.requiresMigration(for: config))
            try openRealm(config: config)
        }
    }
    
    func test_SchemaMigration_SkippingVersions() throws {
        do {
            let config = try createConfiguration(schemaVersion: 0, dog: DogV0.self)
            XCTAssertEqual(false, Realm.requiresMigration(for: config))
            try openRealm(config: config)
        }
        app.syncManager.waitForSessionTermination()
        
        do {
            let config = try createConfiguration(schemaVersion: 2, dog: DogV2.self)
            XCTAssertEqual(true, Realm.requiresMigration(for: config))
            try openRealm(config: config)
        }
    }
    
    func test_SchemaMigration_Downgrade() throws {
        do {
            let config = try createConfiguration(schemaVersion: 2, dog: DogV2.self)
            XCTAssertEqual(false, Realm.requiresMigration(for: config))
            try openRealm(config: config)
        }
        
        app.syncManager.waitForSessionTermination()
        
        do {
            let config = try createConfiguration(schemaVersion: 0, dog: DogV0.self)
            XCTAssertEqual(true, Realm.requiresMigration(for: config))
            try openRealm(config: config)
        }
    }
    
    func test_DataMigration_consecutive() throws {
        // DogV0 is incompatible with DogV3 changes

        // There is an issue in the baas server that prevents
        // from bootstrapping when a property type changes.
        //
        // see https://jira.mongodb.org/browse/BAAS-31935
        
//        do {
//            let realm = try openMigrationRealm(schemaVersion: 0, dog: DogV0.self, cat: CatV0.self)
//        }
        
        do {
            let config = try createConfiguration(schemaVersion: 1, dog: DogV1.self, cat: CatV0.self)
            XCTAssertEqual(false, Realm.requiresMigration(for: config))
            try openRealm(config: config) { realm in
                XCTAssertEqual(0, realm.objects(DogV1.self).where { $0.name == "v0"}.count)
                XCTAssertEqual(0, realm.objects(DogV1.self).where { $0.name == "v1"}.count)
                XCTAssertEqual(0, realm.objects(DogV1.self).where { $0.name == "v2"}.count)
                XCTAssertEqual(0, realm.objects(DogV1.self).where { $0.name == "v3"}.count)
                
                try realm.write {
                    realm.add(DogV1(owner: "hellen", name: "v1"))
                }
                
                XCTAssertEqual(1, realm.objects(DogV1.self).where { $0.name == "v1"}.count)
                waitForUploads(for: realm)
            }
        }
        
        app.syncManager.waitForSessionTermination()
        
        do {
            let config = try createConfiguration(schemaVersion: 2, dog: DogV2.self, cat: CatV0.self)
            XCTAssertEqual(true, Realm.requiresMigration(for: config))
            try openRealm(config: config) { realm in
                XCTAssertEqual(0, realm.objects(DogV2.self).where { $0.name == "v0"}.count)
                XCTAssertEqual(1, realm.objects(DogV2.self).where { $0.name == "v1"}.count)
                XCTAssertEqual(0, realm.objects(DogV2.self).where { $0.name == "v2"}.count)
                XCTAssertEqual(0, realm.objects(DogV2.self).where { $0.name == "v3"}.count)
                
                try realm.write {
                    realm.add(DogV2(owner: "hellen", name: "v2"))
                }
                
                XCTAssertEqual(1, realm.objects(DogV2.self).where { $0.name == "v2"}.count)
                waitForUploads(for: realm)
            }
        }
        
        app.syncManager.waitForSessionTermination()

        
        do {
            let config = try createConfiguration(schemaVersion: 3, dog: DogV3.self)
            XCTAssertEqual(true, Realm.requiresMigration(for: config))
            try openRealm(config: config) { realm in
                XCTAssertEqual(0, realm.objects(DogV3.self).where { $0.name == "v0"}.count)
                XCTAssertEqual(1, realm.objects(DogV3.self).where { $0.name == "v1"}.count)
                XCTAssertEqual(1, realm.objects(DogV3.self).where { $0.name == "v2"}.count)
                XCTAssertEqual(0, realm.objects(DogV3.self).where { $0.name == "v3"}.count)
                
                try realm.write {
                    realm.add(DogV3(owner: "hellen", name: "v3", breed: ObjectId.generate()))
                }
                
                XCTAssertEqual(1, realm.objects(DogV3.self).where { $0.name == "v3"}.count)
            }
        }
    }
    
    func test_DataMigration_downgrade() throws {
        do {
            let config = try createConfiguration(schemaVersion: 3, dog: DogV3.self)
            XCTAssertEqual(false, Realm.requiresMigration(for: config))
            try openRealm(config: config) { realm in
                XCTAssertEqual(0, realm.objects(DogV3.self).where { $0.name == "v0"}.count)
                XCTAssertEqual(0, realm.objects(DogV3.self).where { $0.name == "v1"}.count)
                XCTAssertEqual(0, realm.objects(DogV3.self).where { $0.name == "v2"}.count)
                XCTAssertEqual(0, realm.objects(DogV3.self).where { $0.name == "v3"}.count)
                
                try realm.write {
                    realm.add(DogV3(owner: "hellen", name: "v3", breed: ObjectId.generate()))
                }
                
                XCTAssertEqual(1, realm.objects(DogV3.self).where { $0.name == "v3"}.count)
                waitForUploads(for: realm)
            }
        }
        
        app.syncManager.waitForSessionTermination()
        
        do {
            let config = try createConfiguration(schemaVersion: 1, dog: DogV1.self, cat: CatV0.self)
            XCTAssertEqual(true, Realm.requiresMigration(for: config))
            try openRealm(config: config) { realm in
                XCTAssertEqual(0, realm.objects(DogV1.self).where { $0.name == "v0"}.count)
                XCTAssertEqual(0, realm.objects(DogV1.self).where { $0.name == "v1"}.count)
                XCTAssertEqual(0, realm.objects(DogV1.self).where { $0.name == "v2"}.count)
                XCTAssertEqual(1, realm.objects(DogV1.self).where { $0.name == "v3"}.count)
                
                try realm.write {
                    realm.add(DogV1(owner: "hellen", name: "v1"))
                }
                
                XCTAssertEqual(1, realm.objects(DogV1.self).where { $0.name == "v1"}.count)
            }
        }
    }

    func test_nonExistingSchemaVersion_fails() throws {
        var config = try configuration()
        config.schemaVersion = 4
        config.objectTypes = [DogV3.self]

        Realm.asyncOpen(configuration: config).awaitFailure(self) { error in
            let expected = "Client provided invalid schema version: client presented schema version \"4\" is greater than latest schema version \"3\""
            XCTAssertTrue(error.localizedDescription.localizedStandardContains(expected), "Expected \(error.localizedDescription) to contain \(expected)")
        }
    }

    func test_nonExistingSchemaVersionDuringMigration_fails() throws {
        do {
            let config = try createConfiguration(schemaVersion: 2, dog: DogV2.self)
            XCTAssertEqual(false, Realm.requiresMigration(for: config))
            try openRealm(config: config)
        }
        
        app.syncManager.waitForSessionTermination()
        
        var config = configuration(user: user)
        config.schemaVersion = 4
        config.objectTypes = [DogV3.self]

        Realm.asyncOpen(configuration: config).awaitFailure(self) { error in
            let expected = "Client provided invalid schema version: client presented schema version \"4\" is greater than latest schema version \"3\""
            XCTAssertTrue(error.localizedDescription.localizedStandardContains(expected), "Expected \(error.localizedDescription) to contain \(expected)")
        }
    }
    
    func test_bumpVersionNotSchema() throws {
        do {
            let config = try createConfiguration(schemaVersion: 0, dog: DogV0.self)
            XCTAssertEqual(false, Realm.requiresMigration(for: config))
            try openRealm(config: config)
        }
        
        do {
            let config = try createConfiguration(schemaVersion: 1, dog: DogV0.self)
            XCTAssertEqual(true, Realm.requiresMigration(for: config))
            try openRealm(config: config)
        }
    }
    
    func test_bumpSchemaNotVersion() throws {
        do {
            let config = try createConfiguration(schemaVersion: 0, dog: DogV0.self)
            XCTAssertEqual(false, Realm.requiresMigration(for: config))
            try openRealm(config: config)
        }
        
        do {
            let config = try createConfiguration(schemaVersion: 0, dog: DogV1.self)
            XCTAssertEqual(false, Realm.requiresMigration(for: config))
            try openRealm(config: config)
        }
    }
}

#endif // os(macOS)
