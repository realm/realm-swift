# Quick Start - Swift SDK
This Quick Start demonstrates how to use Realm with the Realm Swift SDK.
Before you begin, ensure you have installed the Swift SDK.

> Seealso:
> If your app uses SwiftUI, check out the [SwiftUI Quick Start](swiftui-tutorial.md).
>

## Import Realm
Near the top of any Swift file that uses Realm, add the following import
statement:

```swift
import RealmSwift

```

## Define Your Object Model
For a local realm, you can define your object model directly in code.

```swift
class Todo: Object {
   @Persisted(primaryKey: true) var _id: ObjectId
   @Persisted var name: String = ""
   @Persisted var status: String = ""
   @Persisted var ownerId: String

   convenience init(name: String, ownerId: String) {
       self.init()
       self.name = name
       self.ownerId = ownerId
   }
}

```

## Open a Realm
In a local realm, the simplest option to open a realm
is to use the default realm with no configuration parameter:

```swift
// Open the default realm
let realm = try! Realm()

```

You can also specify a `Realm.Configuration`
parameter to open a realm at a specific file URL, in-memory, or with a
subset of classes.

For more information, see: Configure and Open a Realm.

## Create, Read, Update, and Delete Objects
Once you have opened a realm, you can modify it and its objects
in a write transaction block.

To create a new Todo object, instantiate the Todo class and add it to the realm in a write block:

```swift
let todo = Todo(name: "Do laundry", ownerId: user.id)
try! realm.write {
    realm.add(todo)
}

```

You can retrieve a live collection of all todos in the realm:

```swift
// Get all todos in the realm
let todos = realm.objects(Todo.self)

```

You can also filter that collection using where:

```swift
let todosInProgress = todos.where {
    $0.status == "InProgress"
}
print("A list of all todos in progress: \(todosInProgress)")

```

To modify a todo, update its properties in a write transaction block:

```swift
// All modifications to a realm must happen in a write block.
let todoToUpdate = todos[0]
try! realm.write {
    todoToUpdate.status = "InProgress"
}

```

Finally, you can delete a todo:

```swift
// All modifications to a realm must happen in a write block.
let todoToDelete = todos[0]
try! realm.write {
    // Delete the Todo.
    realm.delete(todoToDelete)
}

```

## Watch for Changes
You can watch a realm, collection, or object for changes with the `observe` method.

```swift
// Retain notificationToken as long as you want to observe
let notificationToken = todos.observe { (changes) in
    switch changes {
    case .initial: break
        // Results are now populated and can be accessed without blocking the UI
    case .update(_, let deletions, let insertions, let modifications):
        // Query results have changed.
        print("Deleted indices: ", deletions)
        print("Inserted indices: ", insertions)
        print("Modified modifications: ", modifications)
    case .error(let error):
        // An error occurred while opening the Realm file on the background worker thread
        fatalError("\(error)")
    }
}

```

Be sure to retain the notification token returned by `observe` as
long as you want to continue observing. When you are done observing,
invalidate the token to free the resources:

```swift
// Invalidate notification tokens when done observing
notificationToken.invalidate()

```
