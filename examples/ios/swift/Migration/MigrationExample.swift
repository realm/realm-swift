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

import Foundation
import RealmSwift

struct MigrationExample {

    func addExampleDataToRealm(_ exampleData: (Realm) -> Void) {
        let url = RealmVersion.mostRecentVersion.realmUrl(usingTemplate: false)
        let configuration = Realm.Configuration(fileURL: url, schemaVersion: UInt64(RealmVersion.mostRecentVersion.rawValue))
        let realm = try! Realm(configuration: configuration)

        try! realm.write {
            exampleData(realm)
        }

        // Uncomment the following line to print the location of the newly created Realm.
//        print("Realm created at: \(String(describing: configuration.fileURL!)).")
    }

    func performMigration() {
        for realmVersion in RealmVersion.allCases {
            let realmUrl = realmVersion.realmUrl(usingTemplate: true)
            let schemaVersion = UInt64(RealmVersion.mostRecentVersion.rawValue)
            let realmConfiguration = Realm.Configuration(fileURL: realmUrl, schemaVersion: schemaVersion, migrationBlock: migrationBlock)
            try! Realm.performMigration(for: realmConfiguration)
        }
    }

}
