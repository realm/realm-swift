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

#if SCHEMA_VERSION_2

import Foundation
import RealmSwift

// MARK: - Schema

let schemaVersion = 2

// Changes from previous version:
// add a `Dog` object
// add a list of `dogs` to the `Person` object

class Dog: Object {
    @Persisted var name = ""
    convenience init(name: String) {
        self.init()
        self.name = name
    }
}

class Person: Object {
    @Persisted var fullName = ""
    @Persisted var age = 0
    @Persisted var dogs: List<Dog>
    convenience init(fullName: String, age: Int) {
        self.init()
        self.fullName = fullName
        self.age = age
    }
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
                let dogs = newObject!["dogs"] as! List<MigrationObject>
                let marley = migration.create(Dog.className(), value: ["Marley"])
                let lassie = migration.create(Dog.className(), value: ["Lassie"])
                dogs.append(marley)
                dogs.append(lassie)
            } else if newObject!["fullName"] as! String == "Jane Doe" {
                let dogs = newObject!["dogs"] as! List<MigrationObject>
                let toto = migration.create(Dog.className(), value: ["Toto"])
                dogs.append(toto)
            }
        }
        let slinkey = migration.create(Dog.className(), value: ["Slinkey"])
    }
}

// This block checks if the migration led to the expected result.
// All older versions should have been migrated to the below stated `exampleData`.
let migrationCheck: (Realm) -> Void = { realm in
    let persons = realm.objects(Person.self)
    assert(persons.count == 3)
    assert(persons[0].fullName == "John Doe")
    assert(persons[0].age == 42)
    assert(persons[0].dogs.count == 2)
    assert(persons[0].dogs[0].name == "Marley")
    assert(persons[0].dogs[1].name == "Lassie")
    assert(persons[1].fullName == "Jane Doe")
    assert(persons[1].age == 43)
    assert(persons[1].dogs.count == 1)
    assert(persons[1].dogs[0].name == "Toto")
    assert(persons[2].fullName == "John Smith")
    assert(persons[2].age == 44)
    let dogs = realm.objects(Dog.self)
    assert(dogs.count == 4)
    assert(dogs.contains { $0.name == "Slinkey" })
}

// MARK: - Example data

// Example data for this schema version.
let exampleData: (Realm) -> Void = { realm in
    let person1 = Person(fullName: "John Doe", age: 42)
    let person2 = Person(fullName: "Jane Doe", age: 43)
    let person3 = Person(fullName: "John Smith", age: 44)
    let pet1 = Dog(name: "Marley")
    let pet2 = Dog(name: "Lassie")
    let pet3 = Dog(name: "Toto")
    let pet4 = Dog(name: "Slinkey")
    realm.add([person1, person2, person3])
    // pet1, pet2 and pet3 get added automatically by adding them to a list.
    // pet4 has to be added manually though since it's not attached to a person yet.
    realm.add(pet4)
    person1.dogs.append(pet1)
    person1.dogs.append(pet2)
    person2.dogs.append(pet3)
}

#endif
