//////////////////////////////////////////////////////////////////////////////
////
//// Copyright 2021 Realm Inc.
////
//// Licensed under the Apache License, Version 2.0 (the "License");
//// you may not use this file except in compliance with the License.
//// You may obtain a copy of the License at
////
//// http://www.apache.org/licenses/LICENSE-2.0
////
//// Unless required by applicable law or agreed to in writing, software
//// distributed under the License is distributed on an "AS IS" BASIS,
//// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//// See the License for the specific language governing permissions and
//// limitations under the License.
////
//////////////////////////////////////////////////////////////////////////////
//
//import Foundation
//import RealmSwift
//
//// MARK: - Schema
//
//let schemaVersion = RealmVersion.v3
//
//// Changes from previous version:
//// rename the `Dog` object to `Pet`
//// add a `kind` property to `Pet`
//// change the `dogs` property on `Person`:
//// - rename to `pets`
//// - change type to `List<Pet>`
//
//// Renaming tables is not supported yet: https://github.com/realm/realm-cocoa/issues/2491
//// The recommended way is to create a new type instead and migrate the old type.
//// Here we create `Pet` and migrate its data from `Dog` so simulate renaming the table.
//@available(*, deprecated, renamed: "Pet")
//class Dog: Object {
//    @objc dynamic var name = ""
//}
//
//class Pet: Object {
//    @objc dynamic var name = ""
//    @objc dynamic var kind = ""
//}
//
//class Person: Object {
//    @objc dynamic var fullName = ""
//    @objc dynamic var age = 0
//    let pets = List<Pet>()
//}
//
//// MARK: - Migration
//
//// Migration block to migrate from *any* previous version to this version.
//let migrationBlock: MigrationBlock = { migration, oldSchemaVersion in
//    if oldSchemaVersion < 1 {
//        migration.enumerateObjects(ofType: Person.className()) { oldObject, newObject in
//            // combine name fields into a single field
//            let firstName = oldObject!["firstName"] as! String
//            let lastName = oldObject!["lastName"] as! String
//            newObject!["fullName"] = "\(firstName) \(lastName)"
//        }
//    }
//    if oldSchemaVersion < 2 {
//        migration.enumerateObjects(ofType: Person.className()) { _, newObject in
//            // Add a pet to a specific person
//            if newObject!["fullName"] as! String == "John Smith" {
//                let johnsDog = migration.create(Dog.className(), value: ["Jimbo"])
//                let dogs = newObject!["dogs"] as! List<MigrationObject>
//                dogs.append(johnsDog)
//            }
//        }
//    }
//}
//
//// MARK: - Example data
//
//// Example data for this schema version.
//let exampleData: (Realm) -> Void = { realm in
//    let person1 = Person(value: ["John Doe", 42])
//    let person2 = Person(value: ["Jane Doe", 43])
//    let person3 = Person(value: ["John Smith", 44])
//    let pet1 = Dog(value: ["Marley"])
//    let pet2 = Dog(value: ["Lassie"])
//    let pet3 = Dog(value: ["Toto"])
//    let pet4 = Dog(value: ["Slinkey"])
//    realm.add([person1, person2, person3])
//    person1.dogs.append(pet1)
//    person1.dogs.append(pet2)
//    person2.dogs.append(pet3)
//    person2.dogs.append(pet4)
//}
