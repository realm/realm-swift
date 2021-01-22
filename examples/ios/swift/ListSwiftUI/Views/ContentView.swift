////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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

import RealmSwift
import SwiftUI

// MARK: Dog Model
class Dog: EmbeddedObject, ObjectKeyIdentifiable {
    private static let dogNames =
        ["Bella","Lucy","Daisy","Molly","Lola","Sophie","Sadie","Maggie","Chloe","Bailey",
         "Roxy","Zoey","Lily","Luna","Coco","Stella","Gracie","Abby","Penny","Zoe",
         "Angel","Belle","Layla","Missy","Cali","Honey","Millie","Harley",
         "Marley","Holly","Kona","Shelby","Jasmine","Ella","Charlie","Minnie",
         "Loki","Moose","George","Samson","Coco","Benny","Thor","Rufus","Prince",
         "Kobe","Chase","Oreo","Frankie","Mac","Benji","Bubba","Champ","Brady",
         "Elvis","Copper","Cash","Archie","Walter"]

    /// The unique id of this dog
    @objc dynamic var id = ObjectId.generate()
    /// The name of this dog
    @objc dynamic var name = dogNames.randomElement()!

    public static func ==(lhs: Dog, rhs: Dog) -> Bool {
        return lhs.isSameObject(as: rhs)
    }

    let handlers = LinkingObjects(fromType: Person.self, property: "dogs")
}

// MARK: Person Model
class Person: Object, ObjectKeyIdentifiable {
    private static let peopleNames = [
        "Aoife", "Caoimhe", "Saoirse", "Ciara", "Niamh",
        "Conor", "Seán", "Oisín", "Patrick", "Cian",
        "Isabella", "Mateo", "Emilia", "Savannah", "Isla",
        "Elena", "Maya", "Santiago", "Gabriella", "Leonardo"
    ]
    /// The unique id of this dog
    @objc dynamic var id = ObjectId.generate()
    /// The name of the person
    @objc dynamic var name = peopleNames.randomElement()!
    /// The dogs this person has
    var dogs = RealmSwift.List<Dog>()
}

struct DogList: View {
    @ObservedRealmObject var dogs: RealmSwift.List<Dog>

    var body: some View {
        List {
            // Bind the dogs to the view
            ForEach(dogs) { dog in
                // bind the dog name to the TextField for easy modifications
                TextField("dog name", text: dog.bind(keyPath: \.name))
            }
            // the remove method on the dogs list
            // will implicitly write and remove the dogs
            // at the offsets from the `onDelete(perform:)` method
            .onDelete(perform: $dogs.remove)
            // the move method on the dogs list
            // will implicitly write and move the dogs
            // to and from the offsets from the `onMove(perform:)` method
            .onMove(perform: $dogs.move)
        }
    }
}
// MARK: Person View
struct PersonDetailView: View {
    // bind a Person to the View
    @RealmState var person: Person

    var body: some View {
        return VStack {
            // The write transaction for the name property of `Person`
            // is implicit here, and will occur on every edit
            TextField("name", text: $person.name)
                .font(Font.largeTitle.bold()).padding()
            List {
                // Bind the dog list to the view
                ForEach(person.dogs) { dog in
                    // bind the dog name to view for easy modifying
                    TextField("dog name", text: dog.bind(keyPath: \.name))
                }
                // the remove method on the dogs list
                // will implicitly write and remove the dogs
                // at the offsets from the `onDelete(perform:)` method
                .onDelete(perform: $person.dogs.remove)
                // the move method on the dogs list
                // will implicitly write and move the dogs
                // to and from the offsets from the `onMove(perform:)` method
                .onMove(perform: $person.dogs.move)
            }
        }
        .navigationBarItems(trailing: Button("Add Dog") {
            // appending a dog to the dogs List implicitly
            // writes to the Realm, since it has been bound
            // to the view
            $person.dogs.append(Dog())
        })
    }
}

struct PersonView: View {
    @RealmState(Person.self) var results

    var body: some View {
        return NavigationView {
            List {
                ForEach(results) { person in
                    NavigationLink(destination: PersonDetailView(person: person)) {
                        Text(person.name)
                    }
                }
                .onDelete(perform: $results.remove)
            }
            .navigationBarTitle("People", displayMode: .large)
            .navigationBarItems(trailing: Button("Add") {
                $results.append(Person())
            })
        }
    }
}

@main
struct ContentView: SwiftUI.App {
    var view: some View {
        PersonView()
    }

    var body: some Scene {
        WindowGroup {
            view
        }
    }
}
