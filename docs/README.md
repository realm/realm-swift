# Realm SDK for Swift
Use the Realm SDK for Swift to develop iOS, macOS, watchOS and tvOS
apps in Swift and Objective-C.

## Get Started with the Swift SDK

These docs contain minimal-explanation code examples of how to work
with the Swift SDK.

To get started with SwiftUI, see: [SwiftUI Quick Start](swiftui-tutorial.md)

### Install the Swift SDK
Use Swift Package Manager, CocoaPods, or Carthage to
Install the SDK for iOS, macOS, tvOS, and watchOS in your project.

Import `RealmSwift` in your project files to get started.

### Define an Object Schema
Use Swift to idiomatically define an object schema.

### Open a Database
The SDK's database - Realm - stores objects in files on your
device. Or you can open an in-memory database which does not
create a file.

Configure and open a database to specify the options for your database file.

### Read and Write Data
- Create, read, update, and delete objects from the device database.
- Filter data using the SDK's type-safe .where syntax, or construct an NSPredicate.

### React to Changes
Live objects mean that your data is always up-to-date.
You can register a notification handler
to watch for changes and perform some logic, such as updating
your UI. Or in SwiftUI, use the Swift property wrappers
to update Views when data changes.

## Realm SwiftUI

The Swift SDK offers property wrappers and convenience
features designed to make it easier to work with SwiftUI.
For example View code that demonstrates common SwiftUI
patterns, check out the SwiftUI documentation.

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

## Generating API Reference Docs

You can generate the API docs locally by running `sh build.sh docs` from the root of this repository.
This requires installation of [jazzy](https://github.com/realm/jazzy/).
You will find the output in `docs/swift_output/` and `docs/objc_output/`.
