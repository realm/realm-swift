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

import Foundation
import Realm
import RealmSwift
import XCTest

class ObjectiveCSupportTests: TestCase {

    func testSupport() {

        let realm = try! Realm()

        try! realm.write {
            realm.add(SwiftObject())
            return
        }

        let results = realm.objects(SwiftObject.self)
        let rlmResults = ObjectiveCSupport.convert(object: results)
        XCTAssert(rlmResults.isKind(of: RLMResults<AnyObject>.self))
        XCTAssertEqual(rlmResults.count, 1)
        XCTAssertEqual(unsafeBitCast(rlmResults.firstObject(), to: SwiftObject.self).intCol, 123)

        let list = List<SwiftObject>()
        list.append(SwiftObject())
        let rlmArray = ObjectiveCSupport.convert(object: list)
        XCTAssert(rlmArray.isKind(of: RLMArray<AnyObject>.self))
        XCTAssertEqual(unsafeBitCast(rlmArray.firstObject(), to: SwiftObject.self).floatCol, 1.23)
        XCTAssertEqual(rlmArray.count, 1)

        let rlmRealm = ObjectiveCSupport.convert(object: realm)
        XCTAssert(rlmRealm.isKind(of: RLMRealm.self))
        XCTAssertEqual(rlmRealm.allObjects("SwiftObject").count, 1)

        let sortDescriptor: RealmSwift.SortDescriptor = "property"
        XCTAssertEqual(sortDescriptor.keyPath,
                       ObjectiveCSupport.convert(object: sortDescriptor).keyPath,
                       "SortDescriptor.keyPath must be equal to RLMSortDescriptor.keyPath")
        XCTAssertEqual(sortDescriptor.ascending,
                       ObjectiveCSupport.convert(object: sortDescriptor).ascending,
                       "SortDescriptor.ascending must be equal to RLMSortDescriptor.ascending")
    }

    func testConfigurationSupport() {

        let realm = try! Realm()

        try! realm.write {
            realm.add(SwiftObject())
            return
        }

        XCTAssertEqual(realm.configuration.fileURL,
                       ObjectiveCSupport.convert(object: realm.configuration).fileURL,
                       "Configuration.fileURL must be equal to RLMConfiguration.fileURL")

        XCTAssertEqual(realm.configuration.inMemoryIdentifier,
                       ObjectiveCSupport.convert(object: realm.configuration).inMemoryIdentifier,
                       "Configuration.inMemoryIdentifier must be equal to RLMConfiguration.inMemoryIdentifier")

        XCTAssertEqual(realm.configuration.syncConfiguration?.realmURL,
                       ObjectiveCSupport.convert(object: realm.configuration).syncConfiguration?.realmURL,
                       "Configuration.syncConfiguration must be equal to RLMConfiguration.syncConfiguration")

        XCTAssertEqual(realm.configuration.encryptionKey,
                       ObjectiveCSupport.convert(object: realm.configuration).encryptionKey,
                       "Configuration.encryptionKey must be equal to RLMConfiguration.encryptionKey")

        XCTAssertEqual(realm.configuration.readOnly,
                       ObjectiveCSupport.convert(object: realm.configuration).readOnly,
                       "Configuration.readOnly must be equal to RLMConfiguration.readOnly")

        XCTAssertEqual(realm.configuration.schemaVersion,
                       ObjectiveCSupport.convert(object: realm.configuration).schemaVersion,
                       "Configuration.schemaVersion must be equal to RLMConfiguration.schemaVersion")

        XCTAssertEqual(realm.configuration.deleteRealmIfMigrationNeeded,
                       ObjectiveCSupport.convert(object: realm.configuration).deleteRealmIfMigrationNeeded,
                       "Configuration.deleteRealmIfMigrationNeeded must be equal to RLMConfiguration.deleteRealmIfMigrationNeeded")
    }
}
