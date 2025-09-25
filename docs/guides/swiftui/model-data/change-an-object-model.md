# Change an Object Model - SwiftUI
## Overview
When you update your object schema, you must increment the schema version
and perform a migration. You might update your object schema between major
version releases of your app.

For information on how to actually perform the migration, see:
Change an Object Model.

This page focuses on how to use migrated data in SwiftUI Views.

## Use Migrated Data with SwiftUI
To perform a migration:

- Update your schema and write a migration block, if required
- Specify a `Realm.Configuration`
that uses this migration logic and/or updated schema version when you
initialize your realm.

From here, you have a few options to pass the configuration object. You can:

- Set the configuration as the default configuration. If you do not explicitly pass the
configuration via environment injection or as a parameter, property
wrappers use the default configuration.
- Use environment injection to provide this configuration to the first view
in your hierarchy that uses Realm
- Explicitly provide the configuration to a Realm property wrapper that takes
a configuration object, such as `@ObservedResults` or `@AsyncOpen`.

> Example:
> For example, you might want to add a property to an existing object. We
could add a `favoriteTreat` property to the `Dog` object in DoggoDB:
>
> ```swift
> @Persisted var favoriteTreat = ""
> ```
>
> After you add your new property to the schema, you must increment the
schema version. Your `Realm.Configuration` might look like this:
>
> ```swift
> let config = Realm.Configuration(schemaVersion: 2)
>
> ```
>
> Declare this configuration somewhere that is accessible to the first view
in the hierarchy that needs it. Declaring this above your `@main` app
entrypoint makes it available everywhere, but you could also put it in
the file where you first open a realm.
>

### Set a Default Configuration
You can set a default configuration in a SwiftUI app the same as any other
Realm Swift app. Set the default realm configuration by assigning a new
Realm.Configuration instance to the `Realm.Configuration.defaultConfiguration`
class property.

```swift
// Open the default realm
let defaultRealm = try! Realm()

// Open the realm with a specific file URL, for example a username
let username = "GordonCole"
var config = Realm.Configuration.defaultConfiguration
config.fileURL!.deleteLastPathComponent()
config.fileURL!.appendPathComponent(username)
config.fileURL!.appendPathExtension("realm")
let realm = try! Realm(configuration: config)

```

### Pass the Configuration Object as an Environment Object
Once you have declared the configuration, you can inject it as an environment
object to the first view in your hierarchy that opens a realm. If you are
using the `@ObservedResults` or `@ObservedRealmObject` property wrappers,
these views implicitly open a realm, so they also need access to this
configuration.

```swift
.environment(\.realmConfiguration, config)
```

You can pass the realm configuration environment object directly
to the `LocalOnlyContentView`:

```swift
.environment(\.realmConfiguration, config)

```

Which opens a realm implicitly with:

```swift
struct LocalOnlyContentView: View {
    // Implicitly use the default realm's objects(Dog.self)
    @ObservedResults(Dog.self) var dogs

    var body: some View {
        if dogs.first != nil {
            // If dogs exist, go to the DogsView
            DogsView()
        } else {
            // If there is no Dog object, add one here.
            AddDogView()
        }
    }
}

```

### Explicitly Pass the Updated Configuration to a Realm SwiftUI Property Wrapper
You can explicitly pass the configuration object to a Realm SwiftUI
property wrapper that takes a configuration object, such as `@ObservedResults`
or `@AutoOpen`. In this case, you might pass it directly to `@ObservedResults`
in our `DogsView`.

```swift
// Use a `config` that you've passed in from above.
@ObservedResults(Dog.self, configuration: config) var dogs
```
