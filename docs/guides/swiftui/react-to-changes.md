# React to Changes - SwiftUI
## Observe an Object
The Swift SDK provides the `@ObservedRealmObject` property wrapper that invalidates a view
when an observed object changes. You can use this property wrapper to
create a view that automatically updates itself when the observed object
changes.

```swift
struct DogDetailView: View {
    @ObservedRealmObject var dog: Dog

    var body: some View {
        VStack {
            Text(dog.name)
                .font(.title2)
            Text("\(dog.name) is a \(dog.breed)")
            AsyncImage(url: dog.profileImageUrl) { image in
                            image.resizable()
                        } placeholder: {
                            ProgressView()
                        }
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
            Text("Favorite toy: \(dog.favoriteToy)")
        }
    }
}

```

## Observe Query Results
The Swift SDK provides the `@ObservedResults`
property wrapper that lets you observe a collection of query results. You
can perform a quick write to an ObservedResults collection, and the view
automatically updates itself when the observed query changes. For example,
you can remove a dog from an observed list of dogs using `onDelete`.

> Note:
> The `@ObservedResults` property wrapper is intended for use in a
SwiftUI View. If you want to observe results in a view model, register
a change listener.
>

```swift
struct DogsView: View {
    @ObservedResults(Dog.self) var dogs

    /// The button to be displayed on the top left.
    var leadingBarButton: AnyView?

    var body: some View {
        NavigationView {
            VStack {
                // The list shows the dogs in the realm.
                // The ``@ObservedResults`` above implicitly opens a realm and retrieves
                // all the Dog objects. We can then pass those objects to views further down the
                // hierarchy.
                List {
                    ForEach(dogs) { dog in
                        DogRow(dog: dog)
                    }.onDelete(perform: $dogs.remove)
                }.listStyle(GroupedListStyle())
                    .navigationBarTitle("Dogs", displayMode: .large)
                    .navigationBarBackButtonHidden(true)
                    .navigationBarItems(
                        leading: self.leadingBarButton,
                        // Edit button on the right to enable rearranging items
                        trailing: EditButton())
            }.padding()
        }
    }
}

```

> Seealso:
> For more information about the query syntax and types of queries that Realm
supports, see: Read and Filter
Data.
>

### Sort Observed Results
The `@ObservedResults`
property wrapper can take a `SortDescriptor` parameter to sort the query results.

```swift
struct SortedDogsView: View {
    @ObservedResults(Dog.self,
                     sortDescriptor: SortDescriptor(keyPath: "name",
                        ascending: true)) var dogs

    var body: some View {
        NavigationView {
            // The list shows the dogs in the realm, sorted by name
            List(dogs) { dog in
                DogRow(dog: dog)
            }
        }
    }
}

```

> Tip:
> You cannot use a computed property as a `SortDescriptor` for `@ObservedResults`.
>

### Observe Sectioned Results
> Version added: 10.29.0

You can observe a results set that is divided into sections by a key
generated from a property on the object. We've added a computed variable
to the model that we don't persist; we just use this to section the results
set.

```swift
var firstLetter: String {
    guard let char = name.first else {
        return ""
    }
    return String(char)
}

```

Then, we can use the `@ObservedSectionedResults` property wrapper to
observe the results set divided into sections based on the computed variable
key.

```swift
@ObservedSectionedResults(Dog.self,
                          sectionKeyPath: \.firstLetter) var dogs

```

You might use these observed sectioned results to populate a List view
divided by sections:

```swift
struct SectionedDogsView: View {
    @ObservedSectionedResults(Dog.self,
                              sectionKeyPath: \.firstLetter) var dogs

    /// The button to be displayed on the top left.
    var leadingBarButton: AnyView?

    var body: some View {
        NavigationView {
            VStack {
                // The list shows the dogs in the realm, split into sections according to the keypath.
                List {
                    ForEach(dogs) { section in
                        Section(header: Text(section.key)) {
                            ForEach(section) { dog in
                                DogRow(dog: dog)
                            }
                        }
                    }
                }
                .listStyle(GroupedListStyle())
                    .navigationBarTitle("Dogs", displayMode: .large)
                    .navigationBarBackButtonHidden(true)
                    .navigationBarItems(
                        leading: self.leadingBarButton,
                        // Edit button on the right to enable rearranging items
                        trailing: EditButton())
            }.padding()
        }
    }
}

```
