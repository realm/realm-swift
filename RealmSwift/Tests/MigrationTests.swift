////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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

class MigrationTests: TestCase {

    // create realm at path and test version is 0
    private func createRealmAtPath(realmPath: String) {
        autoreleasepool { () -> () in
            Realm(path: realmPath)
            return
        }
        XCTAssertEqual(UInt(0), schemaVersionAtPath(realmPath)!, "Initial version should be 0")
    }

    func testSetDefaultRealmSchemaVersion() {
        createRealmAtPath(defaultRealmPath())

        var migrationCount = 0
        setDefaultRealmSchemaVersion(1, { migration, oldSchemaVersion in
            migrationCount++
            return
        })

        // accessing Realm should automigrate
        defaultRealm()
        XCTAssertEqual(1, migrationCount)
        XCTAssertEqual(UInt(1), schemaVersionAtPath(defaultRealmPath())!)
    }

    func testSetSchemaVersion() {
        createRealmAtPath(testRealmPath())

        var migrationCount = 0
        setSchemaVersion(1, testRealmPath(), { migration, oldSchemaVersion in
            migrationCount++
            return
        })
        XCTAssertEqual(0, migrationCount)

        // accessing Realm should automigrate
        realmWithTestPath()
        XCTAssertEqual(1, migrationCount)
        XCTAssertEqual(UInt(1), schemaVersionAtPath(testRealmPath())!)
    }

    func testSchemaVersionAtPath() {
        var error : NSError? = nil
        XCTAssertNil(schemaVersionAtPath(defaultRealmPath(), error: &error), "Version should be nil before Realm creation")
        XCTAssertNotNil(error, "Error should be set")

        defaultRealm()
        XCTAssertEqual(UInt(0), schemaVersionAtPath(defaultRealmPath())!, "Initial version should be 0")
    }

    func testMigrateRealm() {
        createRealmAtPath(testRealmPath())

        var migrationCount = 0
        setSchemaVersion(1, testRealmPath(), { migration, oldSchemaVersion in
            migrationCount++
            return
        })

        migrateRealm(testRealmPath())
        XCTAssertEqual(1, migrationCount)
    }
}

