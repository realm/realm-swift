# Delete a Realm File - Swift SDK
In some cases, you may want to completely delete a realm file from disk.

Realm avoids copying data into memory except when absolutely required.
As a result, all objects managed by a realm have references to the file
on disk. Before you can safely delete the file, you must ensure the
deallocation of these objects:

- All objects read from or added to the realm
- All List and Results objects
- All ThreadSafeReference objects
- The realm itself

> Warning:
> If you delete a realm file or any of its auxiliary files while one or
more instances of the realm are open, you might corrupt the realm or
disrupt sync.
>

## Delete a Realm File to Avoid Migration
If you iterate rapidly as you develop your app, you may want to delete a
realm file instead of migrating it when you make schema changes. The Realm
configuration provides a `deleteRealmIfMigrationNeeded`
parameter to help with this case.

When you set this property to `true`, the SDK deletes the realm file when
a migration would be required. Then, you can create objects that match the
new schema instead of writing migration blocks for development or test data.

```swift
do {
    // Delete the realm if a migration would be required, instead of migrating it.
    // While it's useful during development, do not leave this set to `true` in a production app!
    let configuration = Realm.Configuration(deleteRealmIfMigrationNeeded: true)
    let realm = try Realm(configuration: configuration)
} catch {
    print("Error opening realm: \(error.localizedDescription)")
}

```

## Delete a Realm File
In practice, there are two safe times to delete the realm file:

1. On application startup before ever opening the realm.
2. After only having opened the realm within an explicit `autorelease` pool, which ensures deallocation of all of objects within it.

