# Bundle a Realm File - Swift SDK

Realm supports **bundling** realm files. When you bundle
a realm file, you include a database and all of its data in your
application download.

This allows users to start applications for the first time with a set of
initial data.

## Overview
To create and bundle a realm file with your application:

1. Create a realm file that
contains the data you'd like to bundle.
2. Bundle the realm file in your
production application.
3. In your production application,
open the realm from the bundled asset file.

## Create a Realm File for Bundling
1. Build a temporary realm app that shares the data model of your
application.
2. Open a realm and add the data you wish to bundle.
3. Use the `writeCopy(configuration:)`
method to copy the realm to a new file:

> Tip:
> If your app accesses Realm in an `async/await` context, mark the code
with `@MainActor` to avoid threading-related crashes.
>

`writeCopy(configuration: )`
automatically compacts your realm to the smallest possible size before
copying.

## Bundle a Realm File in Your Production Application
Now that you have a copy of the realm that contains the initial data,
bundle it with your production application. At a broad level, this entails:

1. Create a new project with the exact same data models as your production
app. Open a realm and add the data you wish to bundle. Since realm
files are cross-platform, you can do this in a macOS app.
2. Drag the compacted copy of your realm file to your production app's Xcode
Project Navigator.
3. Go to your app target's Build Phases tab in Xcode. Add the
realm file to the Copy Bundle Resources build phase.
4. At this point, your app can access the bundled realm file. Find its path
with [Bundle.main.path(forResource:ofType)](https://developer.apple.com/documentation/foundation/bundle/1410989-path).

You can open the realm at the bundle path directly if the
`readOnly` property is set to `true` on the
`Realm.Configuration`. If
you want to modify the bundled realm, first copy the bundled file to
your app's Documents folder with setting `seedFilePath` with the URL of the bundled Realm on your Configuration.

> Tip:
> See the [migration sample app](https://github.com/realm/realm-swift/tree/master/examples/ios/swift/Migration) for a
complete working app that uses a bundled local realm.
>

## Open a Realm from a Bundled Realm File
Now that you have a copy of the realm included with your production
application, you need to add code to use it. Use the `seedFilePath`
method when configuring your realm to open the realm
from the bundled file:

> Tip:
> If your app accesses Realm in an `async/await` context, mark the code
with `@MainActor` to avoid threading-related crashes.
>

```swift
try await openBundledSyncedRealm()

// Opening a realm and accessing it must be done from the same thread.
// Marking this function as `@MainActor` avoids threading-related issues.
@MainActor
func openBundledRealm() async throws {

    // Find the path of the seed.realm file in your project
    let realmURL = Bundle.main.url(forResource: "seed", withExtension: ".realm")
    print("The bundled realm URL is: \(realmURL)")

    // When you use the `seedFilePath` parameter, this copies the
    // realm at the specified path for use with the user's config
    newUserConfig.seedFilePath = realmURL

    // Open the realm, downloading any changes before opening it.
    // This starts with the existing data in the bundled realm, but checks
    // for any updates to the data before opening it in your application.
    let realm = try await Realm(configuration: newUserConfig, downloadBeforeOpen: .always)
    print("Successfully opened the bundled realm")

    // Read and write to the bundled realm as normal
    let todos = realm.objects(Todo.self)

    // There should be one todo whose owner is Daenerys because that's
    // what was in the bundled realm.
    var daenerysTodos = todos.where { $0.owner == "Daenerys" }
    XCTAssertEqual(daenerysTodos.count, 1)
    print("The bundled realm has \(daenerysTodos.count) todos whose owner is Daenerys")

    // Write as usual to the realm, and see the object count increment
    let todo = Todo(value: ["name": "Banish Ser Jorah", "owner": "Daenerys", "status": "In Progress"])
    try realm.write {
        realm.add(todo)
    }
    print("Successfully added a todo to the realm")

    daenerysTodos = todos.where { $0.owner == "Daenerys" }
    XCTAssertEqual(daenerysTodos.count, 2)
}

```
