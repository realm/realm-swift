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
            let schemaVersion = RealmVersion.mostRecentVersion
            let realmConfiguration = Realm.Configuration(fileURL: realmUrl, schemaVersion: schemaVersion, migrationBlock: migrationBlock)
            try! Realm.performMigration(for: realmConfiguration)
            // Print out the results of the migration.
            print("Migration result (migrating from version \(realmVersion.rawValue) to \(schemaVersion):")
//            let pets = try! Realm(configuration: realmConfiguration).objects(Pet.self)
//            let petNames = pets.reduce("") { (result, pet) -> String in
//                result + " " + pet.name
//            }
//            print("Pets:\(petNames)")
//            let persons = try! Realm(configuration: realmConfiguration).objects(Person.self)
//            let namesAndDogs = persons.reduce("") { (result, person) -> String in
//                result + " " + person.fullName + " \(person.pets.count)"
//            }
//            print("Persons:\(namesAndDogs)")
        }
    }
    
}
