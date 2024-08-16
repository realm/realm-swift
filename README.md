<picture>
    <source srcset="./media/logo-dark.svg" media="(prefers-color-scheme: dark)" alt="realm by MongoDB">
    <img src="./media/logo.svg" alt="realm by MongoDB">
</picture>

# About Realm Database

Realm is a mobile database that runs directly inside phones, tablets or wearables.
This repository holds the source code for the iOS, macOS, tvOS & watchOS versions of Realm Swift & Realm Objective-C.

## Why Use Realm

* **Intuitive to Developers:** Realm’s object-oriented data model is simple to learn, doesn’t need an ORM, and lets you write less code.
* **Built for Mobile:** Realm is fully-featured, lightweight, and efficiently uses memory, disk space, and battery life.
* **Designed for Offline Use:** Realm’s local database persists data on-disk, so apps work as well offline as they do online.
* **[MongoDB Atlas Device Sync](https://www.mongodb.com/docs/atlas/app-services/sync/)**: Makes it simple to keep data in sync across users, devices, and your backend in real-time. Get started for free with [a template application](https://github.com/mongodb/template-app-swiftui-todo) and [create the cloud backend](http://mongodb.com/realm/register?utm_medium=github_atlas_CTA&utm_source=realm_swift_github).

## Object-Oriented: Streamline Your Code

Realm was built for mobile developers, with simplicity in mind. The idiomatic, object-oriented data model can save you thousands of lines of code.

```swift
// Define your models like regular Swift classes
class Dog: Object {
    @Persisted var name: String
    @Persisted var age: Int
}
class Person: Object {
    @Persisted(primaryKey: true) var _id: String
    @Persisted var name: String
    @Persisted var age: Int
    // Create relationships by pointing an Object field to another Class
    @Persisted var dogs: List<Dog>
}
// Use them like regular Swift objects
let dog = Dog()
dog.name = "Rex"
dog.age = 1
print("name of dog: \(dog.name)")

// Get the default Realm
let realm = try! Realm()
// Persist your data easily with a write transaction
try! realm.write {
    realm.add(dog)
}
```
## Live Objects: Build Reactive Apps
Realm’s live objects mean data updated anywhere is automatically updated everywhere.
```swift
// Open the default realm.
let realm = try! Realm()

var token: NotificationToken?

let dog = Dog()
dog.name = "Max"

// Create a dog in the realm.
try! realm.write {
    realm.add(dog)
}

//  Set up the listener & observe object notifications.
token = dog.observe { change in
    switch change {
    case .change(let properties):
        for property in properties {
            print("Property '\(property.name)' changed to '\(property.newValue!)'");
        }
    case .error(let error):
        print("An error occurred: (error)")
    case .deleted:
        print("The object was deleted.")
    }
}

// Update the dog's name to see the effect.
try! realm.write {
    dog.name = "Wolfie"
}
```
### SwiftUI
Realm integrates directly with SwiftUI, updating your views so you don't have to.
```swift
struct ContactsView: View {
    @ObservedResults(Person.self) var persons

    var body: some View {
        List {
            ForEach(persons) { person in
                Text(person.name)
            }
            .onMove(perform: $persons.move)
            .onDelete(perform: $persons.remove)
        }.navigationBarItems(trailing:
            Button("Add") {
                $persons.append(Person())
            }
        )
    }
}
```

## Fully Encrypted
Data can be encrypted in-flight and at-rest, keeping even the most sensitive data secure.
```swift
// Generate a random encryption key
var key = Data(count: 64)
_ = key.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) in
    guard let baseAddress = pointer.baseAddress else {
        fatalError("Failed to obtain base address")
    }
    SecRandomCopyBytes(kSecRandomDefault, 64, baseAddress)
}

// Add the encryption key to the config and open the realm
let config = Realm.Configuration(encryptionKey: key)
let realm = try Realm(configuration: config)

// Use the Realm as normal
let dogs = realm.objects(Dog.self).filter("name contains 'Fido'")
```

## Getting Started

We support installing Realm via Swift Package Manager, CocoaPods, Carthage, or by importing a dynamic XCFramework.

For more information, see the detailed instructions in our [docs](https://www.mongodb.com/docs/atlas/device-sdks/sdk/swift/install/).

Interested in getting started for free with [a template application](https://github.com/mongodb/template-app-swiftui-todo) that includes a cloud backend and Sync? [Create a MongoDB Atlas Account](http://mongodb.com/realm/register?utm_medium=github_atlas_CTA&utm_source=realm_swift_github).

## Documentation

The documentation can be found at [mongodb.com/docs/atlas/device-sdks/sdk/swift/](https://www.mongodb.com/docs/atlas/device-sdks/sdk/swift/).
The API reference is located at [mongodb.com/docs/realm-sdks/swift/latest/](https://www.mongodb.com/docs/realm-sdks/swift/latest/)

## Getting Help

- **Need help with your code?**: Look for previous questions with the[`realm` tag](https://stackoverflow.com/questions/tagged/realm?sort=newest) on Stack Overflow or [ask a new question](https://stackoverflow.com/questions/ask?tags=realm). For general discussion that might be considered too broad for Stack Overflow, use the [Community Forum](https://developer.mongodb.com/community/forums/tags/c/realm-sdks/58/swift/).
- **Have a bug to report?** [Open a GitHub issue](https://github.com/realm/realm-swift/issues/new). If possible, include the version of Realm, a full log, the Realm file, and a project that shows the issue.
- **Have a feature request?** [Open a GitHub issue](https://github.com/realm/realm-swift/issues/new). Tell us what the feature should do and why you want the feature.

## Building Realm

In case you don't want to use the precompiled version, you can build Realm yourself from source.

Prerequisites:

* Building Realm requires Xcode 14.1 or newer.
* Building Realm documentation requires [jazzy](https://github.com/realm/jazzy)

Once you have all the necessary prerequisites, building Realm just takes a single command: `sh build.sh build`.
You'll need an internet connection the first time you build Realm to download the core binary.
This will produce Realm.xcframework and RealmSwift.xcframework in `build/Release/`.

Run `sh build.sh help` to see all the actions you can perform (build ios/osx, generate docs, test, etc.).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for more details!

## Code of Conduct

This project adheres to the [MongoDB Code of Conduct](https://www.mongodb.com/community-code-of-conduct).
By participating, you are expected to uphold this code. Please report
unacceptable behavior to [community-conduct@mongodb.com](mailto:community-conduct@mongodb.com).

## License

Realm Objective-C & Realm Swift are published under the Apache 2.0 license.
Realm Core is also published under the Apache 2.0 license and is available
[here](https://github.com/realm/realm-core).

## Feedback

**_If you use Realm and are happy with it, please consider sending out a tweet mentioning [@realm](https://twitter.com/realm) to share your thoughts!_**

**_And if you don't like it, please let us know what you would like improved, so we can fix it!_**

<img style="width: 0px; height: 0px;" src="https://3eaz4mshcd.execute-api.us-east-1.amazonaws.com/prod?s=https://github.com/realm/realm-swift#README.md">
