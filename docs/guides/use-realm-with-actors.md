# Use Realm with Actors - Swift SDK
Starting with Realm Swift SDK version 10.39.0, Realm supports built-in
functionality for using Realm with Swift Actors. Realm's actor support
provides an alternative to managing threads or dispatch queues to perform
asynchronous work. You can use Realm with actors in a few different ways:

- Work with realm *only* on a specific actor with an actor-isolated realm
- Use Realm across actors based on the needs of your application

You might want to use an actor-isolated realm if you want to restrict all
realm access to a single actor. This negates the need to pass data across
the actor boundary, and can simplify data race debugging.

You might want to use realms across actors in cases where you want to
perform different types of work on different actors. For example, you might
want to read objects on the MainActor but use a background actor for large
writes.

For general information about Swift actors, refer to [Apple's Actor
documentation](https://developer.apple.com/documentation/swift/actor).

## Prerequisites
To use Realm in a Swift actor, your project must:

- Use Realm Swift SDK version 10.39.0 or later
- Use Swift 5.8/Xcode 14.3

In addition, we strongly recommend enabling these settings in your project:

- `SWIFT_STRICT_CONCURRENCY=complete`: enables strict concurrency checking
- `OTHER_SWIFT_FLAGS=-Xfrontend-enable-actor-data-race-checks`: enables
runtime actor data-race detection

## About the Examples on This Page
The examples on this page use the following model:

```swift
class Todo: Object {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var name: String
    @Persisted var owner: String
    @Persisted var status: String
}

```

## Open an Actor-Isolated Realm
You can use the Swift async/await syntax to await opening a realm.

Initializing a realm with `try await Realm()` opens a MainActor-isolated
realm. Alternately, you can explicitly specify an actor when opening a
realm with the `await` syntax.

```swift
@MainActor
func mainThreadFunction() async throws {
    // These are identical: the async init produces a
    // MainActor-isolated Realm if no actor is supplied
    let realm1 = try await Realm()
    let realm2 = try await Realm(actor: MainActor.shared)

    try await useTheRealm(realm: realm1)
}

```

You can specify a default configuration or customize your configuration when
opening an actor-isolated realm:

```swift
@MainActor
func mainThreadFunction() async throws {
    let username = "Galadriel"

    // Customize the default realm config
    var config = Realm.Configuration.defaultConfiguration
    config.fileURL!.deleteLastPathComponent()
    config.fileURL!.appendPathComponent(username)
    config.fileURL!.appendPathExtension("realm")

    // Open an actor-isolated realm with a specific configuration
    let realm = try await Realm(configuration: config, actor: MainActor.shared)

    try await useTheRealm(realm: realm)
}

```

For more general information about configuring a realm, refer to
Configure & Open a Realm.

## Define a Custom Realm Actor
You can define a specific actor to manage Realm in asynchronous contexts.
You can use this actor to manage realm access and perform write operations.

```swift
actor RealmActor {
    // An implicitly-unwrapped optional is used here to let us pass `self` to
    // `Realm(actor:)` within `init`
    var realm: Realm!
    init() async throws {
        realm = try await Realm(actor: self)
    }

    var count: Int {
        realm.objects(Todo.self).count
    }

    func createTodo(name: String, owner: String, status: String) async throws {
        try await realm.asyncWrite {
            realm.create(Todo.self, value: [
                "_id": ObjectId.generate(),
                "name": name,
                "owner": owner,
                "status": status
            ])
        }
    }

    func getTodoOwner(forTodoNamed name: String) -> String {
        let todo = realm.objects(Todo.self).where {
            $0.name == name
        }.first!
        return todo.owner
    }

    struct TodoStruct {
        var id: ObjectId
        var name, owner, status: String
    }

    func getTodoAsStruct(forTodoNamed name: String) -> TodoStruct {
        let todo = realm.objects(Todo.self).where {
            $0.name == name
        }.first!
        return TodoStruct(id: todo._id, name: todo.name, owner: todo.owner, status: todo.status)
    }

    func updateTodo(_id: ObjectId, name: String, owner: String, status: String) async throws {
        try await realm.asyncWrite {
            realm.create(Todo.self, value: [
                "_id": _id,
                "name": name,
                "owner": owner,
                "status": status
            ], update: .modified)
        }
    }

    func deleteTodo(id: ObjectId) async throws {
        try await realm.asyncWrite {
            let todoToDelete = realm.object(ofType: Todo.self, forPrimaryKey: id)
            realm.delete(todoToDelete!)
        }
    }

    func close() {
        realm = nil
    }

}

```

An actor-isolated realm may be used with either local or global actors.

```swift
// A simple example of a custom global actor
@globalActor actor BackgroundActor: GlobalActor {
    static var shared = BackgroundActor()
}

@BackgroundActor
func backgroundThreadFunction() async throws {
    // Explicitly specifying the actor is required for anything that is not MainActor
    let realm = try await Realm(actor: BackgroundActor.shared)
    try await realm.asyncWrite {
        _ = realm.create(Todo.self, value: [
            "name": "Pledge fealty and service to Gondor",
            "owner": "Pippin",
            "status": "In Progress"
        ])
    }
    // Thread-confined Realms would sometimes throw an exception here, as we
    // may end up on a different thread after an `await`
    let todoCount = realm.objects(Todo.self).count
    print("The number of Realm objects is: \(todoCount)")
}

@MainActor
func mainThreadFunction() async throws {
    try await backgroundThreadFunction()
}

```

### Use a Realm Actor Synchronously in an Isolated Function
When a function is confined to a specific actor, you can use the actor-isolated
realm synchronously.

```swift
func createObject(in actor: isolated RealmActor) async throws {
    // Because this function is isolated to this actor, you can use
    // realm synchronously in this context without async/await keywords
    try actor.realm.write {
        actor.realm.create(Todo.self, value: [
            "name": "Keep it secret",
            "owner": "Frodo",
            "status": "In Progress"
        ])
    }
    let taskCount = actor.count
    print("The actor currently has \(taskCount) tasks")
}

let actor = try await RealmActor()

try await createObject(in: actor)

```

### Use a Realm Actor in Async Functions
When a function isn't confined to a specific actor, you can use your Realm actor
with Swift's async/await syntax.

```swift
func createObject() async throws {
    // Because this function is not isolated to this actor,
    // you must await operations completed on the actor
    try await actor.createTodo(name: "Take the ring to Mount Doom", owner: "Frodo", status: "In Progress")
    let taskCount = await actor.count
    print("The actor currently has \(taskCount) tasks")
}

let actor = try await RealmActor()

try await createObject()

```

## Write to an Actor-Isolated Realm
Actor-isolated realms can use Swift async/await syntax for asynchronous
writes. Using `try await realm.asyncWrite { ... }` suspends the current task,
acquires the write lock without blocking the current thread, and then invokes
the block. Realm writes the data to disk on a background thread and resumes
the task when that completes.

This function from the example `RealmActor` defined above shows how you might
write to an actor-isolated realm:

```swift
func createTodo(name: String, owner: String, status: String) async throws {
    try await realm.asyncWrite {
        realm.create(Todo.self, value: [
            "_id": ObjectId.generate(),
            "name": name,
            "owner": owner,
            "status": status
        ])
    }
}

```

And you might perform this write using Swift's async syntax:

```swift
func createObject() async throws {
    // Because this function is not isolated to this actor,
    // you must await operations completed on the actor
    try await actor.createTodo(name: "Take the ring to Mount Doom", owner: "Frodo", status: "In Progress")
    let taskCount = await actor.count
    print("The actor currently has \(taskCount) tasks")
}

let actor = try await RealmActor()

try await createObject()

```

This does not block the calling thread while waiting to write. It does
not perform I/O on the calling thread. For small writes, this is safe to
use from `@MainActor` functions without blocking the UI. Writes that
negatively impact your app's performance due to complexity and/or platform
resource constraints may still benefit from being done on a background thread.

Asynchronous writes are only supported for actor-isolated Realms or in
`@MainActor` functions.

## Pass Realm Data Across the Actor Boundary
Realm objects are not [Sendable](https://developer.apple.com/documentation/swift/sendable),
and cannot cross the actor boundary directly. To pass Realm data across
the actor boundary, you have two options:

- Pass a `ThreadSafeReference` to or from the actor
- Pass other types that *are* Sendable, such as passing values directly
or by creating structs to pass across actor boundaries

### Pass a ThreadSafeReference
You can create a `ThreadSafeReference` on an
actor where you have access to the object. In this case, we create a
`ThreadSafeReference` on the `MainActor`. Then, pass the `ThreadSafeReference` to the destination actor.

```swift
// We can pass a thread-safe reference to an object to update it on a different actor.
let todo = todoCollection.where {
    $0.name == "Arrive safely in Bree"
}.first!
let threadSafeReferenceToTodo = ThreadSafeReference(to: todo)
try await backgroundActor.deleteTodo(tsrToTodo: threadSafeReferenceToTodo)

```

On the destination actor, you must `resolve()` the reference within a
write transaction before you can use it. This retrieves a version of the
object local to that actor.

```swift
actor BackgroundActor {
    public func deleteTodo(tsrToTodo tsr: ThreadSafeReference<Todo>) throws {
        let realm = try! Realm()
        try realm.write {
            // Resolve the thread safe reference on the Actor where you want to use it.
            // Then, do something with the object.
            let todoOnActor = realm.resolve(tsr)
            realm.delete(todoOnActor!)
        }
    }
}

```

> Important:
> You must resolve a `ThreadSafeReference` exactly once. Otherwise,
the source realm remains pinned until the reference gets
deallocated. For this reason, `ThreadSafeReference` should be
short-lived.
>
> If you may need to share the same realm object across actors more than
once, you may prefer to share the primary key
and query for it on
the actor where you want to use it. Refer to the "Pass a Primary Key
and Query for the Object on Another Actor" section on this page for an example.
>

### Pass a Sendable Type
While Realm objects are not Sendable, you can work around this by passing
Sendable types across actor boundaries. You can use a few strategies to
pass Sendable types and work with data across actor boundaries:

- Pass Sendable Realm types or primitive values instead of complete Realm objects
- Pass an object's primary key and query for the object on another actor
- Create a Sendable representation of your Realm object, such as a struct

#### Pass Sendable Realm Types and Primitive Values
If you only need a piece of information from the Realm object, such as a
`String` or `Int`, you can pass the value directly across actors instead
of passing the Realm object. For a full list of which Realm types are Sendable,
refer to Sendable, Non-Sendable and Thread-Confined Types.

```swift
@MainActor
func mainThreadFunction() async throws {
    // Create an object in an actor-isolated realm.
    // Pass primitive data to the actor instead of
    // creating the object here and passing the object.
    let actor = try await RealmActor()
    try await actor.createTodo(name: "Prepare fireworks for birthday party", owner: "Gandalf", status: "In Progress")

    // Later, get information off the actor-confined realm
    let todoOwner = await actor.getTodoOwner(forTodoNamed: "Prepare fireworks for birthday party")
}

```

#### Pass a Primary Key and Query for the Object on Another Actor
If you want to use a Realm object on another actor, you can share the
primary key and
query for it on the actor
where you want to use it.

```swift
// Execute code on a specific actor - in this case, the @MainActor
@MainActor
func mainThreadFunction() async throws {
    // Create an object off the main actor
    func createObject(in actor: isolated BackgroundActor) async throws -> ObjectId {
        let realm = try await Realm(actor: actor)
        let newTodo = try await realm.asyncWrite {
            return realm.create(Todo.self, value: [
                "name": "Pledge fealty and service to Gondor",
                "owner": "Pippin",
                "status": "In Progress"
            ])
        }

        // Share the todo's primary key so we can easily query for it on another actor
        return newTodo._id
    }

    // Initialize an actor where you want to perform background work
    let actor = BackgroundActor()
    let newTodoId = try await createObject(in: actor)
    let realm = try await Realm()
    let todoOnMainActor = realm.object(ofType: Todo.self, forPrimaryKey: newTodoId)
}

```

#### Create a Sendable Representation of Your Object
If you need to work with more than a simple value, but don't want the
overhead of passing around `ThreadSafeReferences` or querying objects on
different actors, you can create a struct or other Sendable representation
of your data to pass across the actor boundary.

For example, your actor might have a function that creates a struct
representation of the Realm object.

```swift
struct TodoStruct {
    var id: ObjectId
    var name, owner, status: String
}

func getTodoAsStruct(forTodoNamed name: String) -> TodoStruct {
    let todo = realm.objects(Todo.self).where {
        $0.name == name
    }.first!
    return TodoStruct(id: todo._id, name: todo.name, owner: todo.owner, status: todo.status)
}

```

Then, you can call a function to get the data as a struct on another actor.

```swift
@MainActor
func mainThreadFunction() async throws {
    // Create an object in an actor-isolated realm.
    let actor = try await RealmActor()
    try await actor.createTodo(name: "Leave the ring on the mantle", owner: "Bilbo", status: "In Progress")

    // Get information as a struct or other Sendable type.
    let todoAsStruct = await actor.getTodoAsStruct(forTodoNamed: "Leave the ring on the mantle")
}

```

## Observe Notifications on a Different Actor
You can observe notifications on an actor-isolated realm using Swift's
async/await syntax.

Calling `await object.observe(on: Actor)` or
`await collection.observe(on: Actor)` registers a block to be called
each time the object or collection changes.

The SDK asynchronously calls the block on the given actor's executor.

For write transactions performed on different threads or in different
processes, the SDK calls the block when the realm is (auto)refreshed
to a version including the changes. For local writes, the SDK calls the block
at some point in the future after the write transaction is committed.

Like other Realm notifications, you can
only observe objects or collections managed by a realm. You must retain the
returned token for as long as you want to watch for updates.

If you need to manually advance the state of an observed realm on the main
thread or on another actor, call `await realm.asyncRefresh()`.
This updates the realm and outstanding objects managed by the Realm to point to
the most recent data and deliver any applicable notifications.

### Observation Limitations
You *cannot* call the `.observe()` method:

- During a write transaction
- When the containing realm is read-only
- On an actor-confined realm from outside the actor

### Register a Collection Change Listener
The SDK calls a collection notification block after each write transaction which:

- Deletes an object from the collection.
- Inserts an object into the collection.
- Modifies any of the managed properties of an object in the collection. This
includes self-assignments that set a property to its existing value.

> Important:
> In collection notification handlers, always apply changes
in the following order: deletions, insertions, then
modifications. Handling insertions before deletions may
result in unexpected behavior.
>

These notifications provide information about the actor on which the change
occurred. Like non-actor-isolated collection notifications, they also provide
a `change` parameter that reports which objects are deleted, added, or
modified during the write transaction. This `RealmCollectionChange`
resolves to an array of index paths that you can pass to a `UITableView`'s
batch update methods.

```swift
// Create a simple actor
actor BackgroundActor {
    public func deleteTodo(tsrToTodo tsr: ThreadSafeReference<Todo>) throws {
        let realm = try! Realm()
        try realm.write {
            // Resolve the thread safe reference on the Actor where you want to use it.
            // Then, do something with the object.
            let todoOnActor = realm.resolve(tsr)
            realm.delete(todoOnActor!)
        }
    }
}

// Execute some code on a different actor - in this case, the MainActor
@MainActor
func mainThreadFunction() async throws {
    let backgroundActor = BackgroundActor()
    let realm = try! await Realm()

    // Create a todo item so there is something to observe
    try await realm.asyncWrite {
        realm.create(Todo.self, value: [
            "_id": ObjectId.generate(),
            "name": "Arrive safely in Bree",
            "owner": "Merry",
            "status": "In Progress"
        ])
    }

    // Get the collection of todos on the current actor
    let todoCollection = realm.objects(Todo.self)

    // Register a notification token, providing the actor where you want to observe changes.
    // This is only required if you want to observe on a different actor.
    let token = await todoCollection.observe(on: backgroundActor, { actor, changes in
        print("A change occurred on actor: \(actor)")
        switch changes {
        case .initial:
            print("The initial value of the changed object was: \(changes)")
        case .update(_, let deletions, let insertions, let modifications):
            if !deletions.isEmpty {
                print("An object was deleted: \(changes)")
            } else if !insertions.isEmpty {
                print("An object was inserted: \(changes)")
            } else if !modifications.isEmpty {
                print("An object was modified: \(changes)")
            }
        case .error(let error):
            print("An error occurred: \(error.localizedDescription)")
        }
    })

    // Update an object to trigger the notification.
    // This example triggers a notification that the object is deleted.
    // We can pass a thread-safe reference to an object to update it on a different actor.
    let todo = todoCollection.where {
        $0.name == "Arrive safely in Bree"
    }.first!
    let threadSafeReferenceToTodo = ThreadSafeReference(to: todo)
    try await backgroundActor.deleteTodo(tsrToTodo: threadSafeReferenceToTodo)

    // Invalidate the token when done observing
    token.invalidate()
}

```

### Register an Object Change Listener
The SDK calls an object notification block after each write transaction which:

- Deletes the object.
- Modifies any of the managed properties of the object. This includes
self-assignments that set a property to its existing value.

The block is passed a copy of the object isolated to the requested actor,
along with information about what changed. This object can be safely used
on that actor.

By default, only direct changes to the object's properties produce notifications.
Changes to linked objects do not produce notifications. If a non-nil, non-empty
keypath array is passed in, only changes to the properties identified by those
keypaths produce change notifications. The keypaths may traverse link
properties to receive information about changes to linked objects.

```swift
// Execute some code on a specific actor - in this case, the MainActor
@MainActor
func mainThreadFunction() async throws {
    // Initialize an instance of another actor
    // where you want to do background work
    let backgroundActor = BackgroundActor()

    // Create a todo item so there is something to observe
    let realm = try! await Realm()
    let scourTheShire = try await realm.asyncWrite {
        return realm.create(Todo.self, value: [
            "_id": ObjectId.generate(),
            "name": "Scour the Shire",
            "owner": "Merry",
            "status": "In Progress"
        ])
    }

    // Register a notification token, providing the actor
    let token = await scourTheShire.observe(on: backgroundActor, { actor, change in
        print("A change occurred on actor: \(actor)")
        switch change {
        case .change(let object, let properties):
            for property in properties {
                print("Property '\(property.name)' of object \(object) changed to '\(property.newValue!)'")
            }
        case .error(let error):
            print("An error occurred: \(error)")
        case .deleted:
            print("The object was deleted.")
        }
    })

    // Update the object to trigger the notification.
    // This triggers a notification that the object's `status` property has been changed.
    try await realm.asyncWrite {
        scourTheShire.status = "Complete"
    }

    // Invalidate the token when done observing
    token.invalidate()
}

```
