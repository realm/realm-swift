# Pass Realm Data Between SwiftUI Views
The Realm Swift SDK provides several ways to pass realm data between views:

- Pass Realm objects to a view
- Use environment injection to: Inject a partition value into a viewInject an opened realm into a viewInject a realm configuration into a view

## Pass Realm Objects to a View
When you use the `@ObservedRealmObject` or `@ObservedResults` property
wrapper, you implicitly open a realm and retrieve the specified objects
or results. You can then pass those objects to a view further down the
hierarchy.

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

## Pass Environment Values
[Environment](https://developer.apple.com/documentation/swiftui/environment) injection is a
useful tool in SwiftUI development with Realm.
Realm property wrappers provide different ways for you to
work with environment values when developing your SwiftUI application.

### Inject an Opened Realm
You can inject a realm that you opened in another SwiftUI view into
a view as an environment value. The property wrapper uses this passed-in
realm to populate the view:

```swift
ListView()
   .environment(\.realm, realm)
```

### Inject a Realm Configuration
You can use a realm other than the default realm by passing a different
configuration in an environment object.

```swift
LocalOnlyContentView()
.environment(\.realmConfiguration, Realm.Configuration( /* ... */ ))
```
