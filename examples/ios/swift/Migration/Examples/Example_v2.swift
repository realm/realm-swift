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

let schemaVersion = RealmVersion.v2

// Changes from previous version:
// add a `Dog` object
// add a list of `dogs` to the `Person` object

class Dog: Object {
    @objc dynamic var name = ""
}

class Person: Object {
    @objc dynamic var fullName = ""
    @objc dynamic var age = 0
    let dogs = List<Dog>()
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
            if newObject!["fullName"] as! String == "John Smith" {
                let johnsDog = migration.create(Dog.className(), value: ["Jimbo"])
                let dogs = newObject!["dogs"] as! List<MigrationObject>
                dogs.append(johnsDog)
            }
        }
    }
}

// MARK: - Example data

// Example data for this schema version.
let exampleData: (Realm) -> Void = { realm in
    let person1 = Person(value: ["John Doe", 42])
    let person2 = Person(value: ["Jane Doe", 43])
    let person3 = Person(value: ["John Smith", 44])
    let pet1 = Dog(value: ["Marley"])
    let pet2 = Dog(value: ["Lassie"])
    let pet3 = Dog(value: ["Toto"])
    let pet4 = Dog(value: ["Slinkey"])
    realm.add([person1, person2, person3])
    person1.dogs.append(pet1)
    person1.dogs.append(pet2)
    person2.dogs.append(pet3)
    person2.dogs.append(pet4)
}
