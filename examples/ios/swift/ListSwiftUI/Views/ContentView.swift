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
        "Conor", "Seán", "Oisín", "Patrick", "Cian"
    ]
    /// The unique id of this dog
    @objc dynamic var id = ObjectId.generate()
    /// The name of the person
    @objc dynamic var name = peopleNames.randomElement()!
    /// The dogs this person has
    var dogs = RealmSwift.List<Dog>()
}

struct DogList: View {
    @RealmState var dogs: RealmSwift.List<Dog>
    @State var _filter: String = ""
    var filter: String {
        _filter.isEmpty ? "TRUEPREDICATE" : "name BEGINSWITH '\(_filter)'"
    }

    var body: some View {
        List {
            TextField("filter", text: $_filter)
            // Using the `$` will bind the Dog List to the view.
            // Each Dog will be be bound as well, and will be
            // of type `Binding<Dog>`
            ForEach($dogs.filter(filter)) { dog in
                // TODO: Think about how to add a conditional for bound vs unbound types
                // The write transaction for the name property of `Dog`
                // is implicit here, and will occur on every edit.
                TextField("dog name", text: bind(dog, \.name))
            }
            // the remove method on the dogs list
            // will implicitly write and remove the dogs
            // at the offsets from the `onDelete(perform:)` method
            .onDelete(perform: $dogs.filter(filter).remove)
            // the move method on the dogs list
            // will implicitly write and move the dogs
            // to and from the offsets from the `onMove(perform:)` method
//            .onMove(perform: $dogs.filter(filter).move)
        }
    }
}
// MARK: Person View
struct PersonDetailView: View {
    // bind a Person to the View
    @RealmState var person: Person
    @State var filter: String = ""

    var body: some View {
        VStack {
            // The write transaction for the name property of `Person`
            // is implicit here, and will occur on every edit
            TextField("name", text: $person.name)
                .font(Font.largeTitle.bold()).padding()
            DogList(dogs: person.dogs)
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
                ForEach($results) { person in
                    NavigationLink(destination: PersonDetailView(person: person)) {
                        Text(person.name)
                    }
                }
                .onDelete(perform: $results.remove)
                .onAppear {
                    print("appeared")
                }
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
