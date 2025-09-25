# Filter Data - SwiftUI
## Observe in SwiftUI Views
The `@ObservedResults` property wrapper used in the examples on this page
is intended for use in a SwiftUI View. If you want to observe results
in a view model instead, register a change listener.

## Search a Realm Collection
> Version added: 10.19.0

The Realm Swift SDK allows you to extend [.searchable](https://developer.apple.com/documentation/swiftui/view/searchable(text:placement:prompt:)-18a8f).
When you use `ObservedResults`
to query a realm, you can specify collection and keypath in the result set
to mark it as searchable.

The collection is the bound collection represented by your ObservedResults
query. In this example, it is the `dogs` variable that represents the
collection of all Dog objects in the realm.

The keypath is the object property that you want to search. In this
example, we search the dogs collection by dog name. The Realm Swift
`.searchable` implementation only supports keypaths with `String` types.

```swift
struct SearchableDogsView: View {
    @ObservedResults(Dog.self) var dogs
    @State private var searchFilter = ""
    
    var body: some View {
        NavigationView {
            // The list shows the dogs in the realm.
            List {
                ForEach(dogs) { dog in
                    DogRow(dog: dog)
                }
            }
            .searchable(text: $searchFilter,
                        collection: $dogs,
                        keyPath: \.name) {
                ForEach(dogs) { dogsFiltered in
                    Text(dogsFiltered.name).searchCompletion(dogsFiltered.name)
                }
            }
        }
    }
}

```

## Filter or Query a Realm with ObservedResults
The `@ObservedResults` property wrapper
opens a realm and returns all objects of the specified type. However, you
can filter or query `@ObservedResults` to use only a subset of the objects
in your view.

> Seealso:
> For more information about the query syntax and types of queries that Realm
supports, see: Read and Filter Data.
>

### Filter with an NSPredicate
To filter `@ObservedResults` using the NSPredicate Query API, pass an [NSPredicate](https://developer.apple.com/documentation/foundation/nspredicate) as an argument to `filter`:

```swift
struct FilterDogsViewNSPredicate: View {
    @ObservedResults(Dog.self, filter: NSPredicate(format: "weight > 40")) var dogs
    
    var body: some View {
        NavigationView {
            // The list shows the dogs in the realm.
            List {
                ForEach(dogs) { dog in
                    DogRow(dog: dog)
                }
            }
        }
    }
}

```

### Query with the Realm Type-Safe Query API
> Version added: 10.24.0
> Use *where* to perform type-safe queries on ObservedResults.
>

To use `@ObservedResults` with the Realm Type-Safe Query API, pass a query in a closure as an argument to
`where`:

```swift
struct FilterDogsViewTypeSafeQuery: View {
    @ObservedResults(Dog.self, where: ( { $0.weight > 40 } )) var dogs
    
    var body: some View {
        NavigationView {
            // The list shows the dogs in the realm.
            List {
                ForEach(dogs) { dog in
                    DogRow(dog: dog)
                }
            }
        }
    }
}

```

## Section Filtered Results
> Version added: 10.29.0

The `@ObservedSectionedResults`
property wrapper opens a realm and returns all objects of the specified type,
divided into sections by the specified key path. Similar to
`@ObservedResults` above, you can filter or query `@ObservedSectionedResults`
to use only a subset of the objects in your view:

```swift
@ObservedSectionedResults(Dog.self,
                          sectionKeyPath: \.firstLetter,
                          where: ( { $0.weight > 40 } )) var dogs

```
