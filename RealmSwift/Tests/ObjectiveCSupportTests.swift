////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

import XCTest
import Realm
@testable import RealmSwift
import Foundation

class ObjectiveCSupportTests: TestCase {

    #if swift(>=3.0)

    func testSupport() {

        let realm = try! Realm()

        try! realm.write {
            realm.add(SwiftObject())
            return
        }

        let results = realm.objects(SwiftStringObject.self)
        XCTAssertEqual(results.rlmResults,
                       ObjectiveCSupport.convert(object: results),
                       "RLMResults must stay the same")

        let list = List<SwiftStringObject>()
        XCTAssertEqual(list._rlmArray,
                       ObjectiveCSupport.convert(object: list),
                       "RLMArray must stay the same")

        let linkingObjects = LinkingObjects(fromType: SwiftStringObject.self, property: "linkCol")
        XCTAssertEqual(linkingObjects.rlmResults,
                       ObjectiveCSupport.convert(object: linkingObjects),
                       "RLMResults of LinkingObjects must stay the same")

        XCTAssertEqual(realm.rlmRealm,
                       ObjectiveCSupport.convert(object: realm))

        let _ = Realm.Configuration(schemaVersion: 1, migrationBlock: { migration, _ in
            XCTAssertEqual(migration.rlmMigration,
                           ObjectiveCSupport.convert(object: migration),
                           "rlmMigration must stay the same")
        })

        let objectSchema = realm.schema["SwiftObject"]
        XCTAssertEqual(objectSchema!.rlmObjectSchema,
                       ObjectiveCSupport.convert(object: objectSchema!),
                       "RLMObjectSchema must stay the same")

        let property = objectSchema!.properties[0]
        XCTAssertEqual(property.rlmProperty,
                       ObjectiveCSupport.convert(object: property),
                       "RLMProperty must stay the same")

        XCTAssertEqual(realm.schema.rlmSchema,
                       ObjectiveCSupport.convert(object: realm.schema),
                       "RLMSchema must stay the same")

        let sortDescriptor: RealmSwift.SortDescriptor = "property"
        XCTAssertEqual(sortDescriptor.rlmSortDescriptorValue.property,
                       ObjectiveCSupport.convert(object: sortDescriptor).property,
                       "SortDescriptor.property must be equal to RLMSortDescriptor.property")
        XCTAssertEqual(sortDescriptor.rlmSortDescriptorValue.ascending,
                       ObjectiveCSupport.convert(object: sortDescriptor).ascending,
                       "SortDescriptor.ascending must be equal to RLMSortDescriptor.ascending")

        let credentials = SyncCredentials.usernamePassword(username: "test", password: "1234", register: false)
        XCTAssertEqual(RLMSyncCredentials(credentials).token,
                       ObjectiveCSupport.convert(object: credentials).token,
                       "SyncCredentials.token must be equal to RLMSyncCredentials.token")
        XCTAssertEqual(RLMSyncCredentials(credentials).provider,
                       ObjectiveCSupport.convert(object: credentials).provider,
                       "SyncCredentials.provider must be equal to RLMSyncCredentials.provider")
    }

    func testConfigurationSupport() {

        let realm = try! Realm()

        try! realm.write {
            realm.add(SwiftObject())
            return
        }

        XCTAssertEqual(realm.configuration.rlmConfiguration.fileURL,
                       ObjectiveCSupport.convert(object: realm.configuration).fileURL,
                       "Configuration.fileURL must be equal to RLMConfiguration.fileURL")

        XCTAssertEqual(realm.configuration.rlmConfiguration.inMemoryIdentifier,
                       ObjectiveCSupport.convert(object: realm.configuration).inMemoryIdentifier,
                       "Configuration.inMemoryIdentifier must be equal to RLMConfiguration.inMemoryIdentifier")

        XCTAssertEqual(realm.configuration.rlmConfiguration.syncConfiguration,
                       ObjectiveCSupport.convert(object: realm.configuration).syncConfiguration,
                       "Configuration.syncConfiguration must be equal to RLMConfiguration.syncConfiguration")

        XCTAssertEqual(realm.configuration.rlmConfiguration.encryptionKey,
                       ObjectiveCSupport.convert(object: realm.configuration).encryptionKey,
                       "Configuration.encryptionKey must be equal to RLMConfiguration.encryptionKey")

        XCTAssertEqual(realm.configuration.rlmConfiguration.readOnly,
                       ObjectiveCSupport.convert(object: realm.configuration).readOnly,
                       "Configuration.readOnly must be equal to RLMConfiguration.readOnly")

        XCTAssertEqual(realm.configuration.rlmConfiguration.schemaVersion,
                       ObjectiveCSupport.convert(object: realm.configuration).schemaVersion,
                       "Configuration.schemaVersion must be equal to RLMConfiguration.schemaVersion")

        XCTAssertEqual(realm.configuration.rlmConfiguration.deleteRealmIfMigrationNeeded,
                       ObjectiveCSupport.convert(object: realm.configuration).deleteRealmIfMigrationNeeded,
                       "Configuration.deleteRealmIfMigrationNeeded must be equal to RLMConfiguration.deleteRealmIfMigrationNeeded")

        XCTAssertEqual(realm.configuration.rlmConfiguration.disableFormatUpgrade,
                       ObjectiveCSupport.convert(object: realm.configuration).disableFormatUpgrade,
                       "Configuration.disableFormatUpgrade must be equal to RLMConfiguration.disableFormatUpgrade")
    }

    #else

    func testSupport() {

        let realm = try! Realm()

        try! realm.write {
            realm.add(SwiftObject())
            return
        }

        let results = realm.objects(SwiftStringObject.self)
        XCTAssertEqual(results.rlmResults,
                       ObjectiveCSupport.convert(results),
                       "RLMResults must stay the same")

        let list = List<SwiftStringObject>()
        XCTAssertEqual(list._rlmArray,
                       ObjectiveCSupport.convert(list),
                       "RLMArray must stay the same")

        let linkingObjects = LinkingObjects(fromType: SwiftStringObject.self, property: "linkCol")
        XCTAssertEqual(linkingObjects.rlmResults,
                       ObjectiveCSupport.convert(linkingObjects),
                       "RLMResults of LinkingObjects must stay the same")

        XCTAssertEqual(realm.rlmRealm,
                       ObjectiveCSupport.convert(realm))

        let _ = Realm.Configuration(schemaVersion: 1, migrationBlock: { migration, _ in
            XCTAssertEqual(migration.rlmMigration,
                ObjectiveCSupport.convert(migration),
                "rlmMigration must stay the same")
        })

        let objectSchema = realm.schema["SwiftObject"]
        XCTAssertEqual(objectSchema!.rlmObjectSchema,
                       ObjectiveCSupport.convert(objectSchema!),
                       "RLMObjectSchema must stay the same")

        let property = objectSchema!.properties[0]
        XCTAssertEqual(property.rlmProperty,
                       ObjectiveCSupport.convert(property),
                       "RLMProperty must stay the same")

        XCTAssertEqual(realm.schema.rlmSchema,
                       ObjectiveCSupport.convert(realm.schema),
                       "RLMSchema must stay the same")

        let sortDescriptor: RealmSwift.SortDescriptor = "property"
        XCTAssertEqual(sortDescriptor.rlmSortDescriptorValue.property,
                       ObjectiveCSupport.convert(sortDescriptor).property,
                       "SortDescriptor.property must be equal to RLMSortDescriptor.property")
        XCTAssertEqual(sortDescriptor.rlmSortDescriptorValue.ascending,
                       ObjectiveCSupport.convert(sortDescriptor).ascending,
                       "SortDescriptor.ascending must be equal to RLMSortDescriptor.ascending")

        let credentials = SyncCredentials.usernamePassword("test", password: "1234", register: false)
        XCTAssertEqual(RLMSyncCredentials(credentials).token,
                       ObjectiveCSupport.convert(credentials).token,
                       "SyncCredentials.token must be equal to RLMSyncCredentials.token")
        XCTAssertEqual(RLMSyncCredentials(credentials).provider,
                       ObjectiveCSupport.convert(credentials).provider,
                       "SyncCredentials.provider must be equal to RLMSyncCredentials.provider")
    }

    func testConfigurationSupport() {

        let realm = try! Realm()

        try! realm.write {
            realm.add(SwiftObject())
            return
        }

        XCTAssertEqual(realm.configuration.rlmConfiguration.fileURL,
                       ObjectiveCSupport.convert(realm.configuration).fileURL,
                       "Configuration.fileURL must be equal to RLMConfiguration.fileURL")

        XCTAssertEqual(realm.configuration.rlmConfiguration.inMemoryIdentifier,
                       ObjectiveCSupport.convert(realm.configuration).inMemoryIdentifier,
                       "Configuration.inMemoryIdentifier must be equal to RLMConfiguration.inMemoryIdentifier")

        XCTAssertEqual(realm.configuration.rlmConfiguration.syncConfiguration,
                       ObjectiveCSupport.convert(realm.configuration).syncConfiguration,
                       "Configuration.syncConfiguration must be equal to RLMConfiguration.syncConfiguration")

        XCTAssertEqual(realm.configuration.rlmConfiguration.encryptionKey,
                       ObjectiveCSupport.convert(realm.configuration).encryptionKey,
                       "Configuration.encryptionKey must be equal to RLMConfiguration.encryptionKey")

        XCTAssertEqual(realm.configuration.rlmConfiguration.readOnly,
                       ObjectiveCSupport.convert(realm.configuration).readOnly,
                       "Configuration.readOnly must be equal to RLMConfiguration.readOnly")

        XCTAssertEqual(realm.configuration.rlmConfiguration.schemaVersion,
                       ObjectiveCSupport.convert(realm.configuration).schemaVersion,
                       "Configuration.schemaVersion must be equal to RLMConfiguration.schemaVersion")

        XCTAssertEqual(realm.configuration.rlmConfiguration.deleteRealmIfMigrationNeeded,
                       ObjectiveCSupport.convert(realm.configuration).deleteRealmIfMigrationNeeded,
                       "Configuration.deleteRealmIfMigrationNeeded must be equal to RLMConfiguration.deleteRealmIfMigrationNeeded")

        XCTAssertEqual(realm.configuration.rlmConfiguration.disableFormatUpgrade,
                       ObjectiveCSupport.convert(realm.configuration).disableFormatUpgrade,
                       "Configuration.disableFormatUpgrade must be equal to RLMConfiguration.disableFormatUpgrade")
    }

    #endif
}
