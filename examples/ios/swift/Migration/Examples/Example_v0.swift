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

#if SCHEMA_VERSION_0

import Foundation
import RealmSwift

// MARK: - Schema

let schemaVersion = 0

class Person: Object {
    @Persisted var firstName = ""
    @Persisted var lastName = ""
    @Persisted var age = 0
    convenience init(firstName: String, lastName: String, age: Int) {
        self.init()
        self.firstName = firstName
        self.lastName = lastName
        self.age = age
    }
}

// MARK: - Migration

// Migration block to migrate from *any* previous version to this version.
let migrationBlock: MigrationBlock = { _, _ in }

// This block checks if the migration led to the expected result.
// All older versions should have been migrated to the below stated `exampleData`.
let migrationCheck: (Realm) -> Void = { realm in
    let persons = realm.objects(Person.self)
    assert(persons.count == 3)
    assert(persons[0].firstName == "John")
    assert(persons[0].lastName == "Doe")
    assert(persons[0].age == 42)
    assert(persons[1].firstName == "Jane")
    assert(persons[1].lastName == "Doe")
    assert(persons[1].age == 43)
    assert(persons[2].firstName == "John")
    assert(persons[2].lastName == "Smith")
    assert(persons[2].age == 44)
}

// MARK: - Example data

// Example data for this schema version.
let exampleData: (Realm) -> Void = { realm in
    let person1 = Person(firstName: "John", lastName: "Doe", age: 42)
    let person2 = Person(firstName: "Jane", lastName: "Doe", age: 43)
    let person3 = Person(firstName: "John", lastName: "Smith", age: 44)
    realm.add([person1, person2, person3])
}

#endif
