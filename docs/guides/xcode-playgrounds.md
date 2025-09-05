# Use Realm in Xcode Playgrounds
## Prerequisites
You can only use Swift packages within Xcode projects that have at least one
scheme and target. To use Realm in Xcode Playgrounds, you must first have
an Xcode project where you have Installed the Swift SDK.

## Create a Playground

Within a project, go to File > New > Playground. Select the type of
Playground you want. For this example, we've used a Blank iOS
Playground.

Name and save the playground in the root of your
project. Be sure to add it to the project.

You should see your new Playground in your Project navigator.

## Import Realm
Add the following import statement to use Realm in the playground:

```swift
import RealmSwift

```

## Experiment with Realm
Experiment with Realm. For this example, we'll:

- Define a new Realm object type
- Create a new object of that type and write it to realm
- Query objects of the type, and filter them

```swift
class Drink: Object {
    @Persisted var name = ""
    @Persisted var rating = 0
    @Persisted var source = ""
    @Persisted var drinkType = ""
}

let drink = Drink(value: ["name": "Los Cabellos", "rating": 10, "source": "AeroPress", "drinkType": "Coffee"])

let realm = try! Realm(configuration: config)

try! realm.write {
    realm.add(drink)
}

let drinks = realm.objects(Drink.self)

let coffeeDrinks = drinks.where {
    $0.drinkType == "Coffee"
}

print(coffeeDrinks.first?.name)
```

## Managing the Realm File in Your Playground
When you work with a default realm
in a Playground, you might run into a situation where you need to delete the
realm. For example, if you are experimenting with an object type and add
properties to the object, you may get an error that you must migrate the
realm.

You can specify `Realm.configuration` details to open the file at a specific
path, and delete the realm if it exists at the path.

```swift
var config = Realm.Configuration()

config.fileURL!.deleteLastPathComponent()
config.fileURL!.appendPathComponent("playgroundRealm")
config.fileURL!.appendPathExtension("realm")

if Realm.fileExists(for: config) {
    try Realm.deleteFiles(for: config)
    print("Successfully deleted existing realm at path: \(config.fileURL!)")
} else {
    print("No file currently exists at path")
}
```

Alternately, you can open the realm in-memory only, or use the
`deleteRealmIfMigrationNeeded`
method to automatically delete a realm when migration is needed.
