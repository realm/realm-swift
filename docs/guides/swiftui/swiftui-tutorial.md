# Realm with SwiftUI QuickStart
## Prerequisites
- Have Xcode 12.4 or later (minimum Swift version 5.3.1).
- Create a new Xcode project using the SwiftUI "App" template with a minimum iOS target of 15.0.
- Install the Swift SDK. This SwiftUI app requires a minimum
SDK version of 10.19.0.

## Overview
> Seealso:
> This page provides a small working app to get you up and running with
Realm and SwiftUI quickly. If you'd like to see additional examples,
including more explanation about Realm's SwiftUI features, see:
SwiftUI.
>

This page contains all of the code for a working Realm and SwiftUI app.
The app starts on the `ItemsView`, where you can edit a list of items:

- Press the `Add` button on the bottom right of the screen to add
randomly-generated items.
- Press the `Edit` button on the top right to modify the list order,
which the app persists in the realm.
- You can also swipe to delete items.

When you have items in the list, you can press one of the items to
navigate to the `ItemDetailsView`. This is where you can modify the
item name or mark it as a favorite:

- Press the text field in the center of the screen and type a new name.
When you press Return, the item name should update across the app.
- You can also toggle its favorite status by pressing the heart toggle in the
top right.

### Get Started
We assume you have created an Xcode project with the SwiftUI "App"
template. Open the main Swift file and delete all of the code inside,
including any `@main` `App` classes that Xcode generated for you. At
the top of the file, import the Realm and SwiftUI frameworks:

```swift
import RealmSwift
import SwiftUI

```

> Tip:
> Just want to dive right in with the complete code? Jump to
Complete Code below.
>

### Define Models
A common Realm data modeling use case is to have "things" and
"containers of things". This app defines two related Realm object models: item
and itemGroup.

An item has two user-facing properties:

- A randomly generated-name, which the user can edit.
- An `isFavorite` boolean property, which shows whether the user "favorited"
the item.

An itemGroup contains items. You can extend the itemGroup to have a name and an
association with a specific user, but that's out of scope of this guide.

Paste the following code into your main Swift file to define the models:

```swift
/// Random adjectives for more interesting demo item names
let randomAdjectives = [
    "fluffy", "classy", "bumpy", "bizarre", "wiggly", "quick", "sudden",
    "acoustic", "smiling", "dispensable", "foreign", "shaky", "purple", "keen",
    "aberrant", "disastrous", "vague", "squealing", "ad hoc", "sweet"
]

/// Random noun for more interesting demo item names
let randomNouns = [
    "floor", "monitor", "hair tie", "puddle", "hair brush", "bread",
    "cinder block", "glass", "ring", "twister", "coasters", "fridge",
    "toe ring", "bracelet", "cabinet", "nail file", "plate", "lace",
    "cork", "mouse pad"
]

/// An individual item. Part of an `ItemGroup`.
final class Item: Object, ObjectKeyIdentifiable {
    /// The unique ID of the Item. `primaryKey: true` declares the
    /// _id member as the primary key to the realm.
    @Persisted(primaryKey: true) var _id: ObjectId

    /// The name of the Item, By default, a random name is generated.
    @Persisted var name = "\(randomAdjectives.randomElement()!) \(randomNouns.randomElement()!)"

    /// A flag indicating whether the user "favorited" the item.
    @Persisted var isFavorite = false

    /// Users can enter a description, which is an empty string by default
    @Persisted var itemDescription = ""

    /// The backlink to the `ItemGroup` this item is a part of.
    @Persisted(originProperty: "items") var group: LinkingObjects<ItemGroup>
}

/// Represents a collection of items.
final class ItemGroup: Object, ObjectKeyIdentifiable {
    /// The unique ID of the ItemGroup. `primaryKey: true` declares the
    /// _id member as the primary key to the realm.
    @Persisted(primaryKey: true) var _id: ObjectId

    /// The collection of Items in this group.
    @Persisted var items = RealmSwift.List<Item>()
}

```

### Views and Observed Objects
The entrypoint of the app is the `ContentView` class that derives from
`SwiftUI.App`. For now, this always displays the
`LocalOnlyContentView`.

```swift
@main
struct ContentView: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            LocalOnlyContentView()
        }
    }
}

```

> Tip:
> You can use a realm other than the default realm by passing
an environment object from higher in the View hierarchy:
>
> ```swift
> LocalOnlyContentView()
>   .environment(\.realmConfiguration, Realm.Configuration( /* ... */ ))
> ```
>

The LocalOnlyContentView has an `@ObservedResults` itemGroups. This implicitly uses the default
realm to load all itemGroups when the view appears.

This app only expects there to ever be one itemGroup. If there is an itemGroup
in the realm, the LocalOnlyContentView renders an `ItemsView` for
that itemGroup.

If there is no itemGroup already in the realm, then the
LocalOnlyContentView displays a ProgressView while it adds one. Because
the view observes the itemGroups thanks to the `@ObservedResults` property
wrapper, the view immediately refreshes upon adding that first itemGroup and
displays the ItemsView.

```swift
/// The main content view
struct LocalOnlyContentView: View {
    @State var searchFilter: String = ""
    // Implicitly use the default realm's objects(ItemGroup.self)
    @ObservedResults(ItemGroup.self) var itemGroups

    var body: some View {
        if let itemGroup = itemGroups.first {
            // Pass the ItemGroup objects to a view further
            // down the hierarchy
            ItemsView(itemGroup: itemGroup)
        } else {
            // For this small app, we only want one itemGroup in the realm.
            // You can expand this app to support multiple itemGroups.
            // For now, if there is no itemGroup, add one here.
            ProgressView().onAppear {
                $itemGroups.append(ItemGroup())
            }
        }
    }
}

```

> Tip:
> Starting in SDK version 10.12.0, you can use an optional key path parameter
with `@ObservedResults` to filter change notifications to only those
occurring on the provided key path or key paths. For example:
>
> ```
> @ObservedResults(MyObject.self, keyPaths: ["myList.property"])
> ```
>

The ItemsView receives the itemGroup from the parent view and stores it in
an `@ObservedRealmObject`
property. This allows the ItemsView to "know" when the object has
changed regardless of where that change happened.

The ItemsView iterates over the itemGroup's items and passes each item to an
`ItemRow` for rendering as a list.

To define what happens when a user deletes or moves a row, we pass the
`remove` and `move` methods of the Realm
`List` as the handlers of the respective
remove and move events of the SwiftUI List. Thanks to the
`@ObservedRealmObject` property wrapper, we can use these methods
without explicitly opening a write transaction. The property wrapper
automatically opens a write transaction as needed.

```swift
/// The screen containing a list of items in an ItemGroup. Implements functionality for adding, rearranging,
/// and deleting items in the ItemGroup.
struct ItemsView: View {
    @ObservedRealmObject var itemGroup: ItemGroup

    /// The button to be displayed on the top left.
    var leadingBarButton: AnyView?

    var body: some View {
        NavigationView {
            VStack {
                // The list shows the items in the realm.
                List {
                    ForEach(itemGroup.items) { item in
                        ItemRow(item: item)
                    }.onDelete(perform: $itemGroup.items.remove)
                    .onMove(perform: $itemGroup.items.move)
                }
                .listStyle(GroupedListStyle())
                    .navigationBarTitle("Items", displayMode: .large)
                    .navigationBarBackButtonHidden(true)
                    .navigationBarItems(
                        leading: self.leadingBarButton,
                        // Edit button on the right to enable rearranging items
                        trailing: EditButton())
                // Action bar at bottom contains Add button.
                HStack {
                    Spacer()
                    Button(action: {
                        // The bound collection automatically
                        // handles write transactions, so we can
                        // append directly to it.
                        $itemGroup.items.append(Item())
                    }) { Image(systemName: "plus") }
                }.padding()
            }
        }
    }
}

```

Finally, the `ItemRow` and `ItemDetailsView` classes use the
`@ObservedRealmObject` property wrapper with the item passed in from
above. These classes demonstrate a few more examples of how to use the
property wrapper to display and update properties.

```swift
/// Represents an Item in a list.
struct ItemRow: View {
    @ObservedRealmObject var item: Item

    var body: some View {
        // You can click an item in the list to navigate to an edit details screen.
        NavigationLink(destination: ItemDetailsView(item: item)) {
            Text(item.name)
            if item.isFavorite {
                // If the user "favorited" the item, display a heart icon
                Image(systemName: "heart.fill")
            }
        }
    }
}

/// Represents a screen where you can edit the item's name.
struct ItemDetailsView: View {
    @ObservedRealmObject var item: Item

    var body: some View {
        VStack(alignment: .leading) {
            Text("Enter a new name:")
            // Accept a new name
            TextField("New name", text: $item.name)
                .navigationBarTitle(item.name)
                .navigationBarItems(trailing: Toggle(isOn: $item.isFavorite) {
                    Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                })
        }.padding()
    }
}

```

> Tip:
> `@ObservedRealmObject` is a frozen object. If you want to modify
the properties of an `@ObservedRealmObject`
directly in a write transaction, you must `.thaw()` it first.
>

At this point, you have everything you need to work with
Realm and SwiftUI. Test it out and see if everything is
working as expected.

## Complete Code
If you would like to copy and paste or examine the complete code, see below.

```swift
import RealmSwift
import SwiftUI

// MARK: Models

/// Random adjectives for more interesting demo item names
let randomAdjectives = [
    "fluffy", "classy", "bumpy", "bizarre", "wiggly", "quick", "sudden",
    "acoustic", "smiling", "dispensable", "foreign", "shaky", "purple", "keen",
    "aberrant", "disastrous", "vague", "squealing", "ad hoc", "sweet"
]

/// Random noun for more interesting demo item names
let randomNouns = [
    "floor", "monitor", "hair tie", "puddle", "hair brush", "bread",
    "cinder block", "glass", "ring", "twister", "coasters", "fridge",
    "toe ring", "bracelet", "cabinet", "nail file", "plate", "lace",
    "cork", "mouse pad"
]

/// An individual item. Part of an `ItemGroup`.
final class Item: Object, ObjectKeyIdentifiable {
    /// The unique ID of the Item. `primaryKey: true` declares the
    /// _id member as the primary key to the realm.
    @Persisted(primaryKey: true) var _id: ObjectId

    /// The name of the Item, By default, a random name is generated.
    @Persisted var name = "\(randomAdjectives.randomElement()!) \(randomNouns.randomElement()!)"

    /// A flag indicating whether the user "favorited" the item.
    @Persisted var isFavorite = false

    /// Users can enter a description, which is an empty string by default
    @Persisted var itemDescription = ""

    /// The backlink to the `ItemGroup` this item is a part of.
    @Persisted(originProperty: "items") var group: LinkingObjects<ItemGroup>

}

/// Represents a collection of items.
final class ItemGroup: Object, ObjectKeyIdentifiable {
    /// The unique ID of the ItemGroup. `primaryKey: true` declares the
    /// _id member as the primary key to the realm.
    @Persisted(primaryKey: true) var _id: ObjectId

    /// The collection of Items in this group.
    @Persisted var items = RealmSwift.List<Item>()

}

extension Item {
    static let item1 = Item(value: ["name": "fluffy coasters", "isFavorite": false, "ownerId": "previewRealm"])
    static let item2 = Item(value: ["name": "sudden cinder block", "isFavorite": true, "ownerId": "previewRealm"])
    static let item3 = Item(value: ["name": "classy mouse pad", "isFavorite": false, "ownerId": "previewRealm"])
}

extension ItemGroup {
    static let itemGroup = ItemGroup(value: ["ownerId": "previewRealm"])

    static var previewRealm: Realm {
        var realm: Realm
        let identifier = "previewRealm"
        let config = Realm.Configuration(inMemoryIdentifier: identifier)
        do {
            realm = try Realm(configuration: config)
            // Check to see whether the in-memory realm already contains an ItemGroup.
            // If it does, we'll just return the existing realm.
            // If it doesn't, we'll add an ItemGroup and append the Items.
            let realmObjects = realm.objects(ItemGroup.self)
            if realmObjects.count == 1 {
                return realm
            } else {
                try realm.write {
                    realm.add(itemGroup)
                    itemGroup.items.append(objectsIn: [Item.item1, Item.item2, Item.item3])
                }
                return realm
            }
        } catch let error {
            fatalError("Can't bootstrap item data: \(error.localizedDescription)")
        }
    }
}

// MARK: Views

// MARK: Main Views
/// The main screen that determines whether to present the SyncContentView or the LocalOnlyContentView.
/// For now, it always displays the LocalOnlyContentView.
@main
struct ContentView: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            LocalOnlyContentView()
        }
    }
}

/// The main content view
struct LocalOnlyContentView: View {
    @State var searchFilter: String = ""
    // Implicitly use the default realm's objects(ItemGroup.self)
    @ObservedResults(ItemGroup.self) var itemGroups

    var body: some View {
        if let itemGroup = itemGroups.first {
            // Pass the ItemGroup objects to a view further
            // down the hierarchy
            ItemsView(itemGroup: itemGroup)
        } else {
            // For this small app, we only want one itemGroup in the realm.
            // You can expand this app to support multiple itemGroups.
            // For now, if there is no itemGroup, add one here.
            ProgressView().onAppear {
                $itemGroups.append(ItemGroup())
            }
        }
    }
}

// MARK: Item Views
/// The screen containing a list of items in an ItemGroup. Implements functionality for adding, rearranging,
/// and deleting items in the ItemGroup.
struct ItemsView: View {
    @ObservedRealmObject var itemGroup: ItemGroup

    /// The button to be displayed on the top left.
    var leadingBarButton: AnyView?

    var body: some View {
        NavigationView {
            VStack {
                // The list shows the items in the realm.
                List {
                    ForEach(itemGroup.items) { item in
                        ItemRow(item: item)
                    }.onDelete(perform: $itemGroup.items.remove)
                    .onMove(perform: $itemGroup.items.move)
                }
                .listStyle(GroupedListStyle())
                    .navigationBarTitle("Items", displayMode: .large)
                    .navigationBarBackButtonHidden(true)
                    .navigationBarItems(
                        leading: self.leadingBarButton,
                        // Edit button on the right to enable rearranging items
                        trailing: EditButton())
                // Action bar at bottom contains Add button.
                HStack {
                    Spacer()
                    Button(action: {
                        // The bound collection automatically
                        // handles write transactions, so we can
                        // append directly to it.
                        $itemGroup.items.append(Item())
                    }) { Image(systemName: "plus") }
                }.padding()
            }
        }
    }
}

struct ItemsView_Previews: PreviewProvider {
    static var previews: some View {
        let realm = ItemGroup.previewRealm
        let itemGroup = realm.objects(ItemGroup.self)
        ItemsView(itemGroup: itemGroup.first!)
    }
}

/// Represents an Item in a list.
struct ItemRow: View {
    @ObservedRealmObject var item: Item

    var body: some View {
        // You can click an item in the list to navigate to an edit details screen.
        NavigationLink(destination: ItemDetailsView(item: item)) {
            Text(item.name)
            if item.isFavorite {
                // If the user "favorited" the item, display a heart icon
                Image(systemName: "heart.fill")
            }
        }
    }
}

/// Represents a screen where you can edit the item's name.
struct ItemDetailsView: View {
    @ObservedRealmObject var item: Item

    var body: some View {
        VStack(alignment: .leading) {
            Text("Enter a new name:")
            // Accept a new name
            TextField("New name", text: $item.name)
                .navigationBarTitle(item.name)
                .navigationBarItems(trailing: Toggle(isOn: $item.isFavorite) {
                    Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                })
        }.padding()
    }
}

struct ItemDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ItemDetailsView(item: Item.item2)
        }
    }
}

```
