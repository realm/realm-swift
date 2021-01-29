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

// MARK: - Schema

enum RealmVersion: Int, CaseIterable {
    case v0
    case v1
    case v2
    case v3
}

let schemaVersion = RealmVersion.v3

// Changes from previous version:
// rename the `Dog` object to `Pet`
// add a `kind` property to `Pet`
// change the `dogs` property on `Person`:
// - rename to `pets`
// - change type to `List<Pet>`

// Renaming tables is not supported yet: https://github.com/realm/realm-cocoa/issues/2491
// The recommended way is to create a new type instead and migrate the old type.
// Here we create `Pet` and migrate its data from `Dog` so simulate renaming the table.

class Pet: Object {
    @objc dynamic var name = ""
    @objc dynamic var kind = ""
}

class Person: Object {
    @objc dynamic var fullName = ""
    @objc dynamic var age = 0
    let pets = List<Pet>()
}

// MARK: - Migration

// Migration block to migrate from *any* previous version to this version.
let migrationBlock: MigrationBlock = { migration, oldSchemaVersion in
    if oldSchemaVersion < 1 {
        migration.enumerateObjects(ofType: Person.className()) { oldObject, newObject in
            // combine name fields into a single field
            let firstName = oldObject!["firstName"] as! String
            let lastName = oldObject!["lastName"] as! String
            newObject!["fullName"] = "\(firstName) \(lastName)"
        }
    }
    if oldSchemaVersion < 2 {
        migration.enumerateObjects(ofType: Person.className()) { _, newObject in
            // Add a pet to a specific person
            if newObject!["fullName"] as! String == "John Doe" {
                // `Dog` was changes to `Pet` in v2 already, but we still need to account for this
                // if upgrading from pre v2 to v3.
                let dogs = newObject!["pets"] as! List<MigrationObject>
                let marley = migration.create(Pet.className(), value: ["Marley", "dog"])
                let lassie = migration.create(Pet.className(), value: ["Lassie", "dog"])
                dogs.append(marley)
                dogs.append(lassie)
            } else if newObject!["fullName"] as! String == "Jane Doe" {
                let dogs = newObject!["pets"] as! List<MigrationObject>
                let toto = migration.create(Pet.className(), value: ["Toto", "dog"])
                dogs.append(toto)
            }
        }
        let slinkey = migration.create(Pet.className(), value: ["Slinkey", "dog"])
    }
    if oldSchemaVersion == 2 {
        // This branch is only relevant for version 2. If we are migration from a previous
        // version, we would not be able to access `dogs` since they did not exist back there.
        // Migration from v0 and v1 to v3 is done in the previous blocks.
        // Related issue: https://github.com/realm/realm-cocoa/issues/6263
        migration.enumerateObjects(ofType: "Person") { oldObject, newObject in
            let pets = newObject!["pets"] as! List<MigrationObject>
            for dog in oldObject!["dogs"] as! List<DynamicObject> {
                let pet = migration.create(Pet.className(), value: [dog["name"], "dog"])
                pets.append(pet)
            }
        }
        // We migrate over the old dog list to make sure all dogs get added, even those without
        // an owner.
        // Related issue: https://github.com/realm/realm-cocoa/issues/6734
        // TODO foo
        migration.enumerateObjects(ofType: "Dog") { oldObject, _ in
            migration.delete(oldObject!)
        }
        //        migration.deleteData(forType: "dog")
    }
}

// MARK: - Example data

// Example data for this schema version.
let exampleData: (Realm) -> Void = { realm in
    let person1 = Person(value: ["John Doe", 42])
    let person2 = Person(value: ["Jane Doe", 43])
    let person3 = Person(value: ["John Smith", 44])
    let pet1 = Pet(value: ["Marley", "dog"])
    let pet2 = Pet(value: ["Lassie", "dog"])
    let pet3 = Pet(value: ["Toto", "dog"])
    let pet4 = Pet(value: ["Slinkey", "dog"])
    realm.add([person1, person2, person3])
    person1.pets.append(pet1)
    person1.pets.append(pet2)
    person2.pets.append(pet3)
    // pet1, pet2 and pet3 get added automatically by adding them to a list.
    // pet4 has to be added manually though since it's not attached to a person yet.
    realm.add(pet4)
}
