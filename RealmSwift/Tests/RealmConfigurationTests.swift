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
import RealmSwift
import class Realm.Private.RLMRealmConfiguration

class RealmConfigurationTests: TestCase {
    func testDefaultConfiguration() {
        let defaultConfiguration = Realm.Configuration.defaultConfiguration

        XCTAssertEqual(defaultConfiguration.fileURL, try! Realm().configuration.fileURL)
        XCTAssertNil(defaultConfiguration.inMemoryIdentifier)
        XCTAssertNil(defaultConfiguration.encryptionKey)
        XCTAssertFalse(defaultConfiguration.readOnly)
        XCTAssertEqual(defaultConfiguration.schemaVersion, 0)
        XCTAssert(defaultConfiguration.migrationBlock == nil)
    }

    func testSetDefaultConfiguration() {
        let fileURL = Realm.Configuration.defaultConfiguration.fileURL
        let configuration = Realm.Configuration(fileURL: URL(fileURLWithPath: "/dev/null"))
        Realm.Configuration.defaultConfiguration = configuration
        XCTAssertEqual(Realm.Configuration.defaultConfiguration.fileURL, URL(fileURLWithPath: "/dev/null"))
        Realm.Configuration.defaultConfiguration.fileURL = fileURL
    }

    func testCannotSetMutuallyExclusiveProperties() {
        var configuration = Realm.Configuration()
        configuration.readOnly = true
        configuration.deleteRealmIfMigrationNeeded = true
        assertThrows(try! Realm(configuration: configuration),
                     reason: "Cannot set `deleteRealmIfMigrationNeeded` when `readOnly` is set.")
    }
}
