# Configure & Open a Realm - Swift SDK
When you open a realm, you can pass a `Realm.Configuration` that specifies additional details
about how to configure the realm file. This includes things like:

- Pass a fileURL or in-memory identifier to customize how the realm is stored on device
- Specify the realm use only a subset of your app's classes
- Whether and when to compact a realm to reduce its file size
- Pass an encryption key to encrypt a realm
- Provide a schema version or migration block when making schema changes

## Open a Realm
You can open a local realm with several different configuration
options:

- No configuration - i.e. default configuration
- Specify a file URL for the realm
- Open the realm only in memory, without saving a file to the file system

### Open a Default Realm or Realm at a File URL
#### Objective-C

You can open the default realm with [+[RLMRealm
defaultRealm]].

You can also pass a `RLMRealmConfiguration` object to
`+[RLMRealm realmWithConfiguration:error:]`
to open a realm at a specific file URL or in memory.

You can set the default realm configuration by passing a
RLMRealmConfiguration instance to
`+[RLMRealmConfiguration setDefaultConfiguration:]`.

```objectivec
// Open the default realm
RLMRealm *defaultRealm = [RLMRealm defaultRealm];

// Open the realm with a specific file URL, for example a username
NSString *username = @"GordonCole";
RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
configuration.fileURL = [[[configuration.fileURL URLByDeletingLastPathComponent]
                         URLByAppendingPathComponent:username]
                         URLByAppendingPathExtension:@"realm"];
NSError *error = nil;
RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration
                                             error:&error];

```

#### Swift

You can open a realm with the `Realm()` initializer.
If you omit the `Realm.Configuration` parameter, you will open the
default realm.

You can set the default realm configuration by assigning a new
Realm.Configuration instance to the
`Realm.Configuration.defaultConfiguration`
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

### Open an In-Memory Realm

You can open a realm entirely in memory, which will not create a
`.realm` file or its associated auxiliary files. Instead the SDK stores objects in memory while the
realm is open and discards them immediately when all instances are
closed.

#### Objective-C

Set the `inMemoryIdentifier`
property of the realm configuration.

```objectivec
// Open the realm with a specific in-memory identifier.
NSString *identifier = @"MyRealm";
RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
configuration.inMemoryIdentifier = identifier;
// Open the realm
RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:nil];

```

#### Swift

Set the `inMemoryIdentifier`
property of the realm configuration.

```swift
// Open the realm with a specific in-memory identifier.
let identifier = "MyRealm"
let config = Realm.Configuration(
    inMemoryIdentifier: identifier)
// Open the realm
let realm = try! Realm(configuration: config)

```

> Important:
> When all *in-memory* realm instances with a particular identifier
go out of scope, Realm deletes **all data** in that
realm. To avoid this, hold onto a strong reference to any
in-memory realms during your app's lifetime.
>

### Open a Realm with Swift Concurrency Features
You can use Swift's async/await syntax to open a MainActor-isolated realm,
or specify an actor when opening a realm asynchronously:

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

Or you can define a custom realm actor to manage all of your realm operations:

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

For more information about working with actor-isolated realms, refer to
Use Realm with Actors - Swift SDK.

## Close a Realm
There is no need to manually close a realm in Swift or Objective-C.
When a realm goes out of scope and is removed from memory due to
[ARC](https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html),
the realm is closed.

## Handle Errors When Accessing a Realm
#### Objective-C

To handle errors when accessing a realm, provide an
`NSError` pointer to the `error` parameter:

```objectivec
NSError *error = nil;
RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:&error];
if (!realm) {
    // Handle error
    return;
}
// Use realm

```

#### Swift

To handle errors when accessing a realm, use Swift's built-in
error handling mechanism:

```swift
do {
    let realm = try Realm()
    // Use realm
} catch let error as NSError {
    // Handle error
}

```

## Provide a Subset of Classes to a Realm
> Tip:
> Some applications, such as watchOS apps and iOS app extensions, have
tight constraints on their memory footprints. To optimize your data
model for low-memory environments, open the realm with a subset
of classes.
>

#### Objective-C

By default, the Swift SDK automatically adds all
`RLMObject`- and
`RLMEmbeddedObject`-derived
classes in your executable to the realm schema. You can control
which objects get added by setting the `objectClasses`
property of the `RLMRealmConfiguration` object.

```objectivec
RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];

// Given a RLMObject subclass called `Task`
// Limit the realm to only the Task object. All other
// Object- and EmbeddedObject-derived classes are not added.
config.objectClasses = @[[Task class]];

NSError *error = nil;
RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:&error];

if (error != nil) {
    // Something went wrong
} else {
    // Use realm
}

```

#### Swift

By default, the Swift SDK automatically adds all
`Object`- and
`EmbeddedObject`-derived
classes in your executable to the realm schema. You can control
which objects get added by setting the `objectTypes`
property of the `Realm.Configuration` object.

```swift
var config = Realm.Configuration.defaultConfiguration

// Given: `class Dog: Object`
// Limit the realm to only the Dog object. All other
// Object- and EmbeddedObject-derived classes are not added.
config.objectTypes = [Dog.self]

let realm = try! Realm(configuration: config)

```

## Initialize Properties Using Realm APIs
You might define properties whose values are initialized using
Realm APIs. For example:

```swift
class SomeSwiftType {
    let persons = try! Realm().objects(Person.self)
    // ...
}
```

If this initialization code runs before you set up your Realm
configurations, you might get unexpected behavior. For example, if you
set a migration block for the default realm
configuration in `applicationDidFinishLaunching()`, but you create an
instance of `SomeSwiftType` before
`applicationDidFinishLaunching()`, you might be accessing your
realm before it has been correctly configured.

To avoid such issues, consider doing one of the following:

- Defer instantiation of any type that eagerly initializes properties using Realm APIs until after your app has completed setting up its realm configurations.
- Define your properties using Swift's `lazy` keyword. This allows you to safely instantiate such types at any time during your application's lifecycle, as long as you do not attempt to access your `lazy` properties until after your app has set up its realm configurations.
- Only initialize your properties using Realm APIs that explicitly take in user-defined configurations. You can be sure that the configuration values you are using have been set up properly before they are used to open realms.

## Use Realm When the Device Is Locked
By default, iOS 8 and above encrypts app files using
`NSFileProtection` whenever the device is locked. If your app attempts
to access a realm while the device is locked, you might see the
following error:

```text
open() failed: Operation not permitted
```

To handle this, downgrade the file protection of the folder containing
the Realm files.

> Tip:
> If you reduce iOS file encryption, consider using Realm's
built-in encryption to secure your data
instead.
>

This example shows how to apply a less strict protection level to the
parent directory of the default realm.

```swift
let realm = try! Realm()

// Get the realm file's parent directory
let folderPath = realm.configuration.fileURL!.deletingLastPathComponent().path

// Disable file protection for this directory after the user has unlocked the device once
try! FileManager.default.setAttributes([FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                                       ofItemAtPath: folderPath)

```

Realm may create and delete auxiliary files at any time.
Instead of downgrading file protection on the files, apply it to the
parent folder. This way, the file protection applies to all relevant
files regardless of creation time.
