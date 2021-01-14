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
    @objc dynamic var name = dogNames.randomElement()!

    public static func ==(lhs: Dog, rhs: Dog) -> Bool {
        return lhs.isSameObject(as: rhs)
    }

    let handlers = LinkingObjects(fromType: Person.self, property: "dogs")
}

// MARK: Person Model
public class Person: Object, ObjectKeyIdentifiable {
    private static let peopleNames = [
        "Aoife", "Caoimhe", "Saoirse", "Ciara", "Niamh",
        "Conor", "Seán", "Oisín", "Patrick", "Cian",
        "Isabella", "Mateo", "Emilia", "Savannah", "Isla",
        "Elena", "Maya", "Santiago", "Gabriella", "Leonardo"
    ]
    /// The name of the person
    @objc dynamic var name = peopleNames.randomElement()!
    /// The dogs this person has
    var dogs = RealmSwift.List<Dog>()
}

struct DogList: View {
    @RealmState var dogs: RealmSwift.List<Dog>

    var body: some View {
        List {
            ForEach(dogs) { dog in
                TextField("dog name", text: bind(dog, \.name))
            }
            .onDelete(perform: $dogs.remove)
            .onMove(perform: $dogs.move)
        }
    }
}
// MARK: Person View
struct PersonDetailView: View {
    // bind a Person to the View
    @RealmState var person: Person

    var body: some View {
        VStack {
            TextField("name", text: $person.name)
                .font(Font.largeTitle.bold()).padding()
                .accessibility(identifier: "personName")
            DogList(dogs: person.dogs)
        }
        .navigationBarItems(trailing: Button("Add Dog") {
            $person.dogs.append(Dog())
        })
    }
}

struct PersonView: View {
    @RealmState(Person.self) var results
    @Environment(\.realm) var realm

    var body: some View {
        return NavigationView {
            VStack {
                Text(realm.configuration.fileURL!.absoluteString).accessibility(identifier: "realmPath")
                List {
                    ForEach(results) { person in
                        NavigationLink(destination: PersonDetailView(person: person)) {
                            Text(person.name)
                        }
                    }
                    .onDelete(perform: $results.remove)
                    .onMove(perform: $results.move)
                }
                .navigationBarTitle("People", displayMode: .large)
                .navigationBarItems(trailing: Button("Add") {
                    $results.append(Person())
                })
            }
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
