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
}

// MARK: Person Model
class Person: Object, ObjectKeyIdentifiable {
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
    @ObservedRealmObject var dogs: RealmSwift.List<Dog>
    @State var selection: Dog?

    var body: some View {
        VStack {
            HStack {
                Button("Add Dog") {
                    $dogs.append(Dog())
                }.accessibility(identifier: "addDog")
                Button("Delete Dog", action: {
                    guard let selection = selection,
                          let index = dogs.index(of: selection) else { return }
                    $dogs.remove(at: index)
                }).accessibility(identifier: "deleteDog")
            }
            List(selection: $selection) {
                ForEach(dogs) { (dog: Dog) in
                    TextField("dog name", text: dog.bind(keyPath: \.name))
                        .tag(dog)
                        .accessibility(identifier: dog.name)
                }
                .onMove(perform: $dogs.move)
            }.accessibility(identifier: "dog table")
        }
    }
}
// MARK: Person View
struct PersonDetailView: View {
    // bind a Person to the View
    @RealmState var person: Person

    var body: some View {
        VStack {
            HStack {
                TextField("name", text: person.bind(keyPath: \.name))
                    .font(Font.largeTitle.bold()).padding()
                    .accessibility(identifier: "personName")
            }
            DogList(dogs: person.dogs)
        }
    }
}

struct PersonRowView: View {
    @RealmState var person: Person

    var body: some View {
        Text(person.name)
    }
}

struct PersonView: View {
    // test optional type
    @RealmState(Person.self) var results
    @Environment(\.realm) var realm
    @State var selection: Person?

    var body: some View {
        NavigationView {
            List(selection: $selection) {
                ForEach(results) { person in
                    NavigationLink(destination: PersonDetailView(person: person)) {
                        PersonRowView(person: person)
                    }.tag(person).onAppear { print(person.isFrozen) }
                }
            }.navigationTitle("People")
            .frame(minWidth: 300)
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        $results.append(Person())
                    }, label: {
                        Image(systemName: "person.fill.badge.plus")
                    })
                    .accessibility(identifier: "addPerson")
                }
                ToolbarItem {
                    Button(action: {
                        if let selection = selection, let index = results.firstIndex(where: {$0.id == selection.id}) {
                            $results.remove(at: index)
//                            self.selection = results.first
                        }
                    }, label: {
                        Image(systemName: selection != nil ? "minus.circle.fill" : "minus.circle")
                    }).disabled(selection == nil)
                    .accessibility(identifier: "deletePerson")
                }
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        PersonView(/*results: try! Realm().objects(Person.self)*/)
    }
}

@main
struct App: SwiftUI.App {
    var view: some View {
        ContentView()
    }

    var body: some Scene {
        if let realmPath = ProcessInfo.processInfo.environment["REALM_PATH"] {
            Realm.Configuration.defaultConfiguration =
                Realm.Configuration(fileURL: URL(string: realmPath)!)
        }
        return WindowGroup {
            view
        }
    }
}
