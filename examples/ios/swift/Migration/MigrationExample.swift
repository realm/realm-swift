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

    static func execute() {
        for realmVersion in RealmVersion.allCases {
            let realmUrl = URL(for: realmVersion, usingTemplate: true)
            let schemaVersion = UInt64(RealmVersion.mostRecentVersion.rawValue)
            let realmConfiguration = Realm.Configuration(fileURL: realmUrl, schemaVersion: schemaVersion, migrationBlock: migrationBlock)
            try! Realm.performMigration(for: realmConfiguration)
        }
    }

}
