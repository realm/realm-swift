import RealmSwift
import SwiftUI

// MARK: Dog Model
class Dog: Object, Identifiable {
    private static let dogNames = [
        "Bella", "Charlie", "Luna", "Lucy", "Max",
        "Bailey", "Cooper", "Daisy", "Sadie", "Molly"
    ]

    /// The unique id of this dog
    @objc dynamic var id = ObjectId.generate()
    /// The name of this dog
    @objc dynamic var name = dogNames.randomElement()!

    public static func ==(lhs: Dog, rhs: Dog) -> Bool {
        return lhs.isSameObject(as: rhs)
    }
}

// MARK: Person Model
class Person: Object, Identifiable {
    private static let peopleNames = [
        "Aoife", "Caoimhe", "Saoirse", "Ciara", "Niamh",
        "Conor", "Seán", "Oisín", "Patrick", "Cian"
    ]

    /// The name of the person
    @objc dynamic var name = peopleNames.randomElement()!
    /// The dogs this person has
    var dogs = RealmSwift.List<Dog>()
}

// MARK: Person View
struct PersonView: View {
    // bind a Person to the View
    @RealmBind var person: Person

    var body: some View {
        VStack {
            // The write transaction for the name property of `Person`
            // is implicit here, and will occur on every edit
            TextField("name", text: $person.name)
                .font(Font.largeTitle.bold()).padding()
            List {
                // Using the `$` will bind the Dog List to the view.
                // Each Dog will be be bound as well, and will be
                // of type `Binding<Dog>`
                ForEach($person.dogs, id: \.id) { dog in
                    // The write transaction for the name property of `Dog`
                    // is implicit here, and will occur on every edit.
                    TextField("dog name", text: dog.name)
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

// MARK: Results View
struct ResultsView: View {
    @Environment(\.realm) var realm: Realm
    @RealmBind(Person.self) var results

    var body: some View {
        NavigationView {
            List {
                ForEach(results) { person in
                    NavigationLink(destination: PersonView(person: person)) {
                        Text(person.name)
                    }
                }
            }
            .navigationBarTitle("People", displayMode: .large)
            .navigationBarItems(trailing: Button("Add") {
                try! realm.write { realm.add(Person()) }
            })
        }
    }
}

@main
struct ContentView: SwiftUI.App {
    var realm = try! Realm()

    var view: some View {
        ResultsView().environment(\.realm, realm)
    }

    var body: some Scene {
        WindowGroup {
            view
        }
    }
}
