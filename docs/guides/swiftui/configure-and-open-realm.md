# Configure and Open a Realm - SwiftUI
The Swift SDK provides property wrappers to open a realm in a
SwiftUI-friendly way.

You can:

- Implicitly open a realm
with a `defaultConfiguration` or specify a different configuration.

## Open a Realm with a Configuration
When you use `@ObservedRealmObject`
or `@ObservedResults`, these
property wrappers implicitly open a realm and retrieve the specified
objects or results.

```swift
// Implicitly use the default realm's objects(Dog.self)
@ObservedResults(Dog.self) var dogs

```

> Note:
> The `@ObservedResults` property wrapper is intended for use in a
SwiftUI View. If you want to observe results in a view model, register
a change listener.
>

When you do not specify a configuration, these property wrappers use the
`defaultConfiguration`.
You can set the defaultConfiguration
globally, and property wrappers across the app can use that configuration
when they implicitly open a realm.

You can provide alternative configurations that the property wrappers use
to implicitly open the realm.
To do this, create explicit configurations.
Then, use environment injection to pass the respective configurations
to the views that need them.
Passing a configuration to a view where property wrappers open a realm
uses the passed configuration instead of the `defaultConfiguration`.
