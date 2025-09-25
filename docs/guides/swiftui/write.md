# Write Data - SwiftUI
## Perform a Quick Write
In addition to performing writes inside a transaction block, the Realm Swift
SDK offers a convenience feature to enable quick writes without explicitly
performing a write transaction.

When you use the `@ObservedRealmObject` or `@ObservedResults` property
wrappers, you can implicitly open a write transaction. Use the `$` operator
to create a two-way binding to the state object. Then, when you make changes
to the bound object or collection, you initiate an implicit write.

The Realm SwiftUI property wrappers work with frozen data to provide thread safety. When you use `$` to
create a two-way binding, the Realm Swift SDK manages thawing the
frozen objects so you can write to them.

### Update an Object's Properties
In this example, we create a two-way binding with one of the state object's
properties. `$dog.favoriteToy` creates a binding to the model Dog
object's `favoriteToy` property

When the app user updates that field in this example, Realm
opens an implicit write transaction and saves the new value to the database.

```swift
struct EditDogDetails: View {
    @ObservedRealmObject var dog: Dog
    
    var body: some View {
        VStack {
            Text(dog.name)
                .font(.title2)
            TextField("Favorite toy", text: $dog.favoriteToy)
        }
    }
}

```

### Add or Remove Objects in an ObservedResults Collection
While a regular Realm Results collection
is immutable, `ObservedResults`
is a mutable collection that allows you to perform writes using a two-way
binding. When you update the bound collection, Realm opens an implicit write
transaction and saves the changes to the collection.

In this example, we remove an element from the results set using
`$dogs.remove` in the `onDelete`. Using the `$dogs` here creates a
two-way binding to a `BoundCollection` that lets us mutate the
`@ObservedResults` `dogs` collection.

We add an item to the results using `$dogs.append` in the
`addDogButton`.

These actions write directly to the `@ObservedResults` collection.

```swift
struct DogsListView: View {
    @ObservedResults(Dog.self) var dogs
    
    var body: some View {
        NavigationView {
            VStack {
                // The list shows the dogs in the realm.
                List {
                    ForEach(dogs) { dog in
                        DogRow(dog: dog)
                        // Because `$dogs` here accesses an ObservedResults
                        // collection, we can remove the specific dog from the collection.
                        // Regular Realm Results are immutable, but you can write directly
                        // to an `@ObservedResults` collection.
                    }.onDelete(perform: $dogs.remove)
                }.listStyle(GroupedListStyle())
                    .navigationBarTitle("Dogs", displayMode: .large)
                    .navigationBarBackButtonHidden(true)
                // Action bar at bottom contains Add button.
                HStack {
                    Spacer()
                    Button(action: {
                        // The bound collection automatically
                        // handles write transactions, so we can
                        // append directly to it. This example assumes
                        // we have some values to populate the Dog object.
                        $dogs.append(Dog(value: ["name":"Bandido"]))
                    }) { Image(systemName: "plus") }
                    .accessibilityIdentifier("addDogButton")
                }.padding()
            }
        }
    }
}

```

> Note:
> The `@ObservedResults` property wrapper is intended for use in a
SwiftUI View. If you want to observe results in a view model, register
a change listener.
>

### Append an Object to a List
When you have a two-way binding with an `@ObservedRealmObject` that has
a list property, you can add new objects to the list.

In this example, the `Person` object has a list property that forms a
to-many relationship with one or more dogs.

```swift
class Person: Object, ObjectKeyIdentifiable {
   @Persisted(primaryKey: true) var _id: ObjectId
   @Persisted var firstName = ""
   @Persisted var lastName = ""
   ...
   @Persisted var dogs: List<Dog>
}
```

When the user presses the `Save` button, this:

- Creates a `Dog` object with the details that the user has entered
- Appends the `Dog` object to the `Person` object's `dogs` list

```swift
struct AddDogToPersonView: View {
    @ObservedRealmObject var person: Person
    @Binding var isInAddDogView: Bool
    @State var name = ""
    @State var breed = ""
    @State var weight = 0
    @State var favoriteToy = ""
    @State var profileImageUrl: URL?

    var body: some View {
        Form {
            TextField("Dog's name", text: $name)
            TextField("Dog's breed", text: $breed)
            TextField("Dog's weight", value: $weight, format: .number)
            TextField("Dog's favorite toy", text: $favoriteToy)
            TextField("Image link", value: $profileImageUrl, format: .url)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
            Section {
                Button(action: {
                    let dog = createDog(name: name, breed: breed, weight: weight, favoriteToy: favoriteToy, profileImageUrl: profileImageUrl)
                    $person.dogs.append(dog)
                    isInAddDogView.toggle()
                }) {
                    Text("Save")
                }
                Button(action: {
                    isInAddDogView.toggle()
                }) {
                    Text("Cancel")
                }
            }
        }
    }
}
```

### Use Create to Copy an Object Into the Realm
There may be times when you create a new object, and set one of its properties
to an object that already exists in the realm. Then, when you go to add the
new object to the realm, you see an error similar to:

```shell
Object is already managed by another Realm. Use create instead to copy it into this Realm.
```

When this occurs, you can use the `.create`
method to initialize the object, and use `modified: .update` to set its
property to the existing object.

> Example:
> Consider a version of the DoggoDB `Dog` model where the `favoriteToy`
property isn't just a `String`, but is an optional `DogToy` object:
>
> ```swift
> class Dog: Object, ObjectKeyIdentifiable {
>    @Persisted(primaryKey: true) var _id: UUID
>    @Persisted var name = ""
>    ...
>    @Persisted var favoriteToy: DogToy?
>    ...
> }
> ```
>
> When your app goes to create a new `Dog` object, perhaps it checks to see
if the `DogToy` already exists in the realm, and then set the `favoriteToy`
property to the existing dog toy.
>
> When you go to append the new `Dog` to the `Person` object, you may
see an error similar to:
>
> ```shell
> Object is already managed by another Realm. Use create instead to copy it into this Realm.
> ```
>
> The `Dog` object remains unmanaged until you append it to the `Person`
object's `dogs` property. When the Realm Swift SDK checks the `Dog`
object to find the realm that is currently managing it, it finds nothing.
>
> When you use the `$` notation to perform a quick write that appends the
`Dog` object to the `Person` object, this write uses the realm it has
access to in the view. This is a realm instance implicitly opened by
the `@ObservedRealmObject` or `@ObservedResults` property wrapper.
The existing `DogToy` object, however, may be managed by a different
realm instance.
>
> To solve this error, use the `.create`
method when you initialize the `Dog` object, and use
`modified: .update` to set its `favoriteToy` value to the existing
object:
>
> ```swift
> // When working with an `@ObservedRealmObject` `Person`, this is a frozen object.
> // Thaw the object and get its realm to perform the write to append the new dog.
> let thawedPersonRealm = frozenPerson.thaw()!.realm!
> try! thawedPersonRealm.write {
>     // Use the .create method with `update: .modified` to copy the
>     // existing object into the realm
>     let dog = thawedPersonRealm.create(Dog.self, value:
>                                         ["name": "Maui",
>                                          "favoriteToy": wubba],
>                                        update: .modified)
>     person.dogs.append(dog)
> }
>
> ```
>

## Perform an Explicit Write
In some cases, you may want or need to explicitly perform a write transaction
instead of using the implicit `$` to perform a quick write. You may want
to do this when:

- You need to look up additional objects to perform a write
- You need to perform a write to objects you don't have access to in the view

If you pass an object you are observing with `@ObservedRealmObject` or
`@ObservedResults` into a function where you perform an explicit write
transaction that modifies the object, you must thaw it first.

```swift
let thawedCompany = company.thaw()!

```

You can access the realm that is managing the object or objects by calling
`.realm` on the object or collection:

```swift
let realm = company.realm!.thaw()

```

Because the SwiftUI property wrappers use frozen objects, you must thaw
the realm before you can write to it.

> Example:
> Consider a version of the DoggoDB app where a `Company` object
has a list of `Employee` objects. Each `Employee` has a list of
`Dog` objects. But for business reasons, you also wanted to have a
list of `Dog` objects available directly on the `Company` object,
without being associated with an `Employee`. The model might look
something like:
>
> ```swift
> class Company: Object, ObjectKeyIdentifiable {
>     @Persisted(primaryKey: true) var _id: ObjectId
>     @Persisted var companyName = ""
>     @Persisted var employees: List<Employee>
>     @Persisted var dogs: List<Dog>
> }
>
> ```
>
> Consider a view where you have access to the `Company` object, but
want to perform an explicit write to add an existing dog to an existing
employee. Your function might look something like:
>
> ```swift
> // The `frozenCompany` here represents an `@ObservedRealmObject var company: Company`
> performAnExplicitWrite(company: frozenCompany, employeeName: "Dachary", dogName: "Maui")
>
> func performAnExplicitWrite(company: Company, employeeName: String, dogName: String) {
>     // Get the realm that is managing the `Company` object you passed in.
>     // Thaw the realm so you can write to it.
>     let realm = company.realm!.thaw()
>     // Thawing the `Company` object that you passed in also thaws the objects in its List properties.
>     // This lets you append the `Dog` to the `Employee` without individually thawing both of them.
>     let thawedCompany = company.thaw()!
>     let thisEmployee = thawedCompany.employees.where { $0.name == employeeName }.first!
>     let thisDog = thawedCompany.dogs.where { $0.name == dogName }.first!
>     try! realm.write {
>         thisEmployee.dogs.append(thisDog)
>     }
> }
>
> ```
>
