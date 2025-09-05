# React to Changes - Swift SDK
All Realm objects are **live objects**, which means they
automatically update whenever they're modified. Realm emits a
notification event whenever any property changes. You can register a
notification handler to listen for these notification events, and update
your UI with the latest data.

This page shows how to manually register notification listeners in Swift.
Realm SDK for Swift offers SwiftUI property wrappers to make it easy to
automatically update the UI when data changes. For more about how to use
the SwiftUI property wrappers to react to changes, refer to
Observe an Object.

## Register a Realm Change Listener
You can register a notification handler on an entire realm. Realm calls the notification
handler whenever any write transaction involving that Realm is
committed. The handler receives no information about the change.

#### Objective-C

```objectivec
RLMRealm *realm = [RLMRealm defaultRealm];

// Observe realm notifications. Keep a strong reference to the notification token
// or the observation will stop.
RLMNotificationToken *token = [realm addNotificationBlock:^(RLMNotification  _Nonnull notification, RLMRealm * _Nonnull realm) {
    // `notification` is an enum specifying what kind of notification was emitted.
    // ... update UI ...
}];

// ...

// Later, explicitly stop observing.
[token invalidate];

```

#### Swift

```swift
let realm = try! Realm()

// Observe realm notifications. Keep a strong reference to the notification token
// or the observation will stop.
let token = realm.observe { notification, realm in
    // `notification` is an enum specifying what kind of notification was emitted
    viewController.updateUI()
}

// ...

// Later, explicitly stop observing.
token.invalidate()

```

## Register a Collection Change Listener
You can register a notification handler on a collection within a
realm.

Realm notifies your handler:

- After first retrieving the collection.
- Whenever a write transaction adds, changes, or removes objects in the collection.

Notifications describe the changes since the prior notification with
three lists of indices: the indices of the objects that were deleted,
inserted, and modified.

> Important:
> In collection notification handlers, always apply changes
in the following order: deletions, insertions, then
modifications. Handling insertions before deletions may
result in unexpected behavior.
>

Collection notifications provide a `change` parameter that reports which
objects are deleted, added, or modified during the write transaction. This
`RealmCollectionChange`
resolves to an array of index paths that you can pass to a `UITableView`'s
batch update methods.

> Important:
> This example of a collection change listener does not support
high-frequency updates. Under an intense workload, this collection
change listener may cause the app to throw an exception.
>

#### Objective-C

```objectivec
@interface CollectionNotificationExampleViewController : UITableViewController
@end

@implementation CollectionNotificationExampleViewController {
    RLMNotificationToken *_notificationToken;
}
- (void)viewDidLoad {
    [super viewDidLoad];

    // Observe RLMResults Notifications
    __weak typeof(self) weakSelf = self;
    _notificationToken = [[Dog objectsWhere:@"age > 5"]
      addNotificationBlock:^(RLMResults<Dog *> *results, RLMCollectionChange *changes, NSError *error) {

        if (error) {
            NSLog(@"Failed to open realm on background worker: %@", error);
            return;
        }

        UITableView *tableView = weakSelf.tableView;
        // Initial run of the query will pass nil for the change information
        if (!changes) {
            [tableView reloadData];
            return;
        }

        // Query results have changed, so apply them to the UITableView
        [tableView performBatchUpdates:^{
            // Always apply updates in the following order: deletions, insertions, then modifications.
            // Handling insertions before deletions may result in unexpected behavior.
            [tableView deleteRowsAtIndexPaths:[changes deletionsInSection:0]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            [tableView insertRowsAtIndexPaths:[changes insertionsInSection:0]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            [tableView reloadRowsAtIndexPaths:[changes modificationsInSection:0]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
        } completion:^(BOOL finished) {
            // ...
        }];
    }];
}
@end

```

#### Swift

```swift
class CollectionNotificationExampleViewController: UITableViewController {
    var notificationToken: NotificationToken?

    override func viewDidLoad() {
        super.viewDidLoad()
        let realm = try! Realm()
        let results = realm.objects(Dog.self)

        // Observe collection notifications. Keep a strong
        // reference to the notification token or the
        // observation will stop.
        notificationToken = results.observe { [weak self] (changes: RealmCollectionChange) in
            guard let tableView = self?.tableView else { return }
            switch changes {
            case .initial:
                // Results are now populated and can be accessed without blocking the UI
                tableView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                // Query results have changed, so apply them to the UITableView
                tableView.performBatchUpdates({
                    // Always apply updates in the following order: deletions, insertions, then modifications.
                    // Handling insertions before deletions may result in unexpected behavior.
                    tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}),
                                         with: .automatic)
                    tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
                                         with: .automatic)
                    tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
                                         with: .automatic)
                }, completion: { finished in
                    // ...
                })
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(error)")
            }
        }
    }
}

```

## Register an Object Change Listener
You can register a notification handler on a specific object
within a realm. Realm notifies your handler:

- When the object is deleted.
- When any of the object's properties change.

The handler receives information about what fields changed
and whether the object was deleted.

#### Objective-C

```objectivec
@interface Dog : RLMObject
@property NSString *name;
@property int age;
@end

@implementation Dog
@end

RLMNotificationToken *objectNotificationToken = nil;

void objectNotificationExample() {
    Dog *dog = [[Dog alloc] init];
    dog.name = @"Max";
    dog.age = 3;
    
    // Open the default realm
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm transactionWithBlock:^{
        [realm addObject:dog];
    }];

    // Observe object notifications. Keep a strong reference to the notification token
    // or the observation will stop. Invalidate the token when done observing.
    objectNotificationToken = [dog addNotificationBlock:^(BOOL deleted, NSArray<RLMPropertyChange *> * _Nullable changes, NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"An error occurred: %@", [error localizedDescription]);
            return;
        }
        if (deleted) {
            NSLog(@"The object was deleted.");
            return;
        }
        NSLog(@"Property %@ changed to '%@'",
              changes[0].name,
              changes[0].value);
    }];

    // Now update to trigger the notification
    [realm transactionWithBlock:^{
        dog.name = @"Wolfie";
    }];

}

```

#### Swift

```swift
// Define the dog class.
class Dog: Object {
    @Persisted var name = ""
}

var objectNotificationToken: NotificationToken?

func objectNotificationExample() {
    let dog = Dog()
    dog.name = "Max"

    // Open the default realm.
    let realm = try! Realm()
    try! realm.write {
        realm.add(dog)
    }
    // Observe object notifications. Keep a strong reference to the notification token
    // or the observation will stop. Invalidate the token when done observing.
    objectNotificationToken = dog.observe { change in
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
    }

    // Now update to trigger the notification
    try! realm.write {
        dog.name = "Wolfie"
    }
}

```

## Register a Key Path Change Listener
> Version added: 10.12.0

In addition to registering a notification handler on an `object`
or `collection`, you can pass an optional string `keyPaths` parameter to specify the key path or
key paths to watch.

> Example:
> ```swift
> // Define the dog class.
> class Dog: Object {
>     @Persisted var name = ""
>     @Persisted var favoriteToy = ""
>     @Persisted var age: Int?
> }
>
> var objectNotificationToken: NotificationToken?
>
> func objectNotificationExample() {
>     let dog = Dog()
>     dog.name = "Max"
>     dog.favoriteToy = "Ball"
>     dog.age = 2
>
>     // Open the default realm.
>     let realm = try! Realm()
>     try! realm.write {
>         realm.add(dog)
>     }
>     // Observe notifications on some of the object's key paths. Keep a strong
>     // reference to the notification token or the observation will stop.
>     // Invalidate the token when done observing.
>     objectNotificationToken = dog.observe(keyPaths: ["favoriteToy", "age"], { change in
>         switch change {
>         case .change(let object, let properties):
>             for property in properties {
>                 print("Property '\(property.name)' of object \(object) changed to '\(property.newValue!)'")
>             }
>         case .error(let error):
>             print("An error occurred: \(error)")
>         case .deleted:
>             print("The object was deleted.")
>         }
>     })
>
>     // Now update to trigger the notification
>     try! realm.write {
>         dog.favoriteToy = "Frisbee"
>     }
>     // When you specify one or more key paths, changes to other properties
>     // do not trigger notifications. In this example, changing the "name"
>     // property does not trigger a notification.
>     try! realm.write {
>         dog.name = "Maxamillion"
>     }
> }
> ```
>

> Version added: 10.14.0

You can `observe`
a partially type-erased [PartialKeyPath](https://developer.apple.com/documentation/swift/partialkeypath)
on `Objects` or `RealmCollections`.

```swift
objectNotificationToken = dog.observe(keyPaths: [\Dog.favoriteToy, \Dog.age], { change in
```

When you specify `keyPaths`, *only* changes to those
`keyPaths` trigger notification blocks. Any other changes do not trigger
notification blocks.

> Example:
> Consider a `Dog` object where one of its properties is a list of
`siblings`:
>
> ```swift
> class Dog: Object {
>     @Persisted var name = ""
>     @Persisted var siblings: List<Dog>
>     @Persisted var age: Int?
> }
> ```
>
> If you pass `siblings` as a `keyPath` to observe, any insertion,
deletion, or modification to the `siblings` list would trigger a
notification. However, a change to `someSibling.name` would not trigger
a notification, unless you explicitly observed `["siblings.name"]`.
>

> Note:
> Multiple notification tokens on the same object which filter for
separate key paths *do not* filter exclusively. If one key path
change is satisfied for one notification token, then all notification
token blocks for that object will execute.
>

### Realm Collections
When you observe key paths on the various collection types, expect these
behaviors:

- `LinkingObjects`:
Observing a property of the LinkingObject triggers a notification for a
change to that property, but does not trigger notifications for changes to
its other properties. Insertions or deletions to the list or the object
that the list is on trigger a notification.
- `Lists`:
Observing a property of the list's object will triggers a notification for
a change to that property, but does not trigger notifications for changes
to its other properties. Insertions or deletions to the list or the object
that the list is on trigger a notification.
- `Map`:
Observing a property of the map's object triggers a notification for a change
to that property, but does not trigger notifications for changes to its other
properties. Insertions or deletions to the Map or the object that the map is
on trigger a notification. The `change` parameter reports, in the form of
keys within the map, which key-value pairs are added, removed, or modified
during each write transaction.
- `MutableSet`:
Observing a property of a MutableSet's object triggers a notification
for a change to that property, but does not trigger notifications for changes
to its other properties. Insertions or deletions to the MutableSet or the
object that the MutableSet is on trigger a notification.
- `Results`:
Observing a property of the Result triggers a notification for a change to
that property, but does not trigger notifications for changes to its other
properties. Insertions or deletions to the Result trigger a notification.

## Write Silently
You can write to a realm *without* sending a notification to a
specific observer by passing the observer's notification token in an
array to `realm.write(withoutNotifying:_)`:

#### Objective-C

```objectivec
RLMRealm *realm = [RLMRealm defaultRealm];

// Observe realm notifications
RLMNotificationToken *token = [realm addNotificationBlock:^(RLMNotification  _Nonnull notification, RLMRealm * _Nonnull realm) {
    // ... handle update
}];

// Later, pass the token in an array to the realm's `-transactionWithoutNotifying:block:` method.
// Realm will _not_ notify the handler after this write.
[realm transactionWithoutNotifying:@[token] block:^{
   // ... write to realm
}];

// Finally
[token invalidate];

```

#### Swift

```swift
let realm = try! Realm()

// Observe realm notifications
let token = realm.observe { notification, realm in
    // ... handle update
}

// Later, pass the token in an array to the realm.write(withoutNotifying:)
// method to write without sending a notification to that observer.
try! realm.write(withoutNotifying: [token]) {
    // ... write to realm
}

// Finally
token.invalidate()

```

## Stop Watching for Changes
Observation stops when the token returned by an `observe` call becomes
invalid. You can explicitly invalidate a token by calling its
`invalidate()` method.

> Important:
> Notifications stop if the token is in a local variable that goes out
of scope.
>

#### Objective-C

```objectivec
RLMRealm *realm = [RLMRealm defaultRealm];

// Observe and obtain token
RLMNotificationToken *token = [realm addNotificationBlock:^(RLMNotification  _Nonnull notification, RLMRealm * _Nonnull realm) {
    /* ... */
}];

// Stop observing
[token invalidate];

```

#### Swift

```swift
let realm = try! Realm()

// Observe and obtain token
let token = realm.observe { notification, realm in /* ... */ }

// Stop observing
token.invalidate()

```

## Key-value Observation
### Key-value Observation Compliance
Realm objects are [key-value observing (KVO)
compliant](https://developer.apple.com/documentation/swift/cocoa_design_patterns/using_key-value_observing_in_swift)
for most properties:

- Almost all managed (non-ignored) properties on `Object` subclasses
- The `invalidated` property on `Object` and `List`

You cannot observe `LinkingObjects` properties via Key-value observation.

> Important:
> You cannot add an object to a realm (with `realm.add(obj)` or similar
methods) while it has any registered observers.
>

### Managed vs. Unmanaged KVO Considerations
Observing the properties of unmanaged instances of `Object` subclasses
works like any other dynamic property.

Observing the properties of managed objects works differently. With
realm-managed objects, the value of a property may change when:

- You assign to it
- The realm is refreshed, either manually with `realm.refresh()` or
automatically on a runloop thread
- You begin a write transaction after changes on another thread

Realm applies changes made in the write transaction(s) on other threads
at once. Observers see Key-value observation notifications at once.
Intermediate steps do not trigger KVO notifications.

> Example:
> Say your app performs a write transaction that increments a property
from 1 to 10. On the main thread, you get a single notification of a
change directly from 1 to 10. You won't get notifications for every
incremental change between 1 and 10.
>

Avoid modifying managed Realm objects from within
`observeValueForKeyPath(_:ofObject:change:context:)`. Property values
can change when not in a write transaction, or as part of beginning a
write transaction.

### Observing Realm Lists
Observing changes made to Realm `List` properties is simpler than
`NSMutableArray` properties:

- You don't have to mark `List` properties as dynamic to observe them.
- You can call modification methods on `List` directly. Anyone observing
the property that stores it gets a notification.

You don't need to use `mutableArrayValueForKey(_:)`, although realm
does support this for code compatibility.

> Seealso:
> Examples of using Realm with [ReactiveCocoa from Objective-C](https://github.com/realm/realm-swift/tree/master/examples/ios/objc/TableView),
and [ReactKit from Swift](https://github.com/realm/realm-swift/tree/v2.3.0/examples/ios/swift-2.2/ReactKit).
>

## React to Changes on a Different Actor
You can observe notifications on a different actor. Calling
`await object.observe(on: Actor)` or
`await collection.observe(on: Actor)` registers a block to be called each
time the object or collection changes.

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

For more information about change notifications on another actor,
refer to Observe Notifications on a Different Actor.

## React to Changes to a Class Projection
Like other realm objects, you can react to changes
to a class projection. When you register a class projection change listener,
you see notifications for changes made through the class projection object
directly. You also see notifications for changes to the underlying object's
properties that project through the class projection object.

Properties on the underlying object that are not `@Projected` in the
class projection do not generate notifications.

This notification block fires for changes in:

- `Person.firstName` property of the class projection's underlying
`Person` object, but not changes to `Person.lastName` or
`Person.friends`.
- `PersonProjection.firstName` property, but not another class projection
that uses the same underlying object's property.

```swift
let realm = try! Realm()
let projectedPerson = realm.objects(PersonProjection.self).first(where: { $0.firstName == "Jason" })!
let token = projectedPerson.observe(keyPaths: ["firstName"], { change in
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

// Now update to trigger the notification
try! realm.write {
    projectedPerson.firstName = "David"
}

```

## Notification Delivery
Notification delivery can vary depending on:

- Whether or not the notification occurs within a write transaction
- The relative threads of the write and the observation

When your application relies on the timing of notification delivery, such
as when you use notifications to update a `UITableView`, it's important
to understand the specific behaviors for your application code's context.

### Perform Writes Only on a Different Thread than the Observing Thread
Reading an observed collection or object from inside a change notification
always accurately tells you what has changed in the collection passed to
the callback since the last time the callback was invoked.

Reading collections or objects outside of change notifications always gives
you the exact same values you saw in the most recent change notification
for that object.

Reading objects other than the observed one *inside* a change notification
may see a different value prior to the notification for that change being
delivered. Realm `refresh` brings the entire realm from 'old version' to
'latest version' in one operation. However, there might have been multiple
change notifications fired between 'old version' and 'latest version'. Inside
a callback, you may see changes that have pending notifications.

Writes on different threads eventually become visible on the observing
thread. Explicitly calling `refresh()` blocks until the writes made on
other threads are visible and the appropriate notifications have been sent.
If you call `refresh()` within a notification callback, it's a no-op.

### Perform Writes on the Observing Thread, Outside of Notifications
At the start of the write transaction all behaviors above apply to this
context. Additionally, you can expect to always see the latest version of
the data.

Inside a write transaction, the only changes you see are those you've made
so far within the write transaction.

Between committing a write transaction and the next set of change
notifications being sent, you can see the changes you made in the write
transaction, but no other changes. Writes made on different threads do
not become visible until you receive the next set of notifications.
Performing another write on the same thread sends notifications for the
previous write first.

### Perform Writes Inside of Notifications
When you perform writes within notifications, you see many of the same
behaviors above, with a few exceptions.

Callbacks invoked before the one that performed a write behave normally.
While Realm invokes change callbacks in a stable order, this is not strictly
the order in which you added the observations.

If beginning the write refreshes the realm, which can happen if another
thread is making writes, this triggers recursive notifications. These
nested notifications report the changes made since the last call to the
callback. For callbacks before the one making the write, this means the
inner notification reports only the changes made after the ones already
reported in the outer notification. If the callback making the write tries
to write again in the inner notification, Realm throws an exception.
The callbacks after the one making the write get a single notification for
both sets of changes.

After the callback completes the write and returns, Realm does not invoke
any of the subsequent callbacks as they no longer have any changes to report.
Realm provides a notification later for the write as if the write had happened
outside of a notification.

If beginning the write doesn't refresh the realm, the write happens as
usual. However, Realm invokes the subsequent callbacks in an inconsistent
state. They continue to report the original change information, but the
observed object/collection now includes the changes from the write made
in the previous callback.

If you try to perform manual checks and write handling to get more fine-grained
notifications from within a write transaction, you can get notifications
nested more than two levels deep. An example of a manual write handling is
checking `realm.isInWriteTransaction`, and if so making changes, calling
`realm.commitWrite()` and then `realm.beginWrite()`. The nested
notifications and potential for error make this manual manipulation
error-prone and difficult to debug.

You can use the writeAsync API to sidestep complexity
if you don't need fine-grained change information from inside your write block.
Observing an async write similar to this provides notifications even if the
notification happens to be delivered inside a write transaction:

```swift
let token = dog.observe(keyPaths: [\Dog.age]) { change in
   guard case let .change(dog, _) = change else { return }
   dog.realm!.writeAsync {
      dog.isPuppy = dog.age < 2
   }
}
```

However, because the write is async the realm may have changed between the
notification and when the write happens. In this case, the change information
passed to the notification may no longer be applicable.

### Updating a UITableView Based on Notifications
If you only update a `UITableView` via notifications, in the time between
a write transaction and the next notification arriving, the TableView's
state is out of sync with the data. The TableView could have a pending update
scheduled, which can appear to cause delayed or inconsistent updates.

You can address these behaviors in a few ways.

The following examples use this very basic `UITableViewController`.

```swift
class TableViewController: UITableViewController {
    let realm = try! Realm()
    let results = try! Realm().objects(DemoObject.self).sorted(byKeyPath: "date")
    var notificationToken: NotificationToken!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        notificationToken = results.observe { (changes: RealmCollectionChange) in
            switch changes {
            case .initial:
                self.tableView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                // Always apply updates in the following order: deletions, insertions, then modifications.
                // Handling insertions before deletions may result in unexpected behavior.
                self.tableView.beginUpdates()
                self.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                self.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                self.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                self.tableView.endUpdates()
            case .error(let err):
                fatalError("\(err)")
            }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let object = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = object.title
        return cell
    }

    func delete(at index: Int) throws {
        try realm.write {
            realm.delete(results[index])
        }
    }
}

```

#### Update the UITableView Directly Without a Notification
Updating the `UITableView` directly without waiting for a notification
provides the most responsive UI. This code updates the TableView immediately
instead of requiring hops between threads, which add a small amount of
lag to each update. The downside is that it requires frequent manual
updates to the view.

```swift
func delete(at index: Int) throws {
    try realm.write(withoutNotifying: [notificationToken]) {
        realm.delete(results[index])
    }
    tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
}

```

#### Force a Refresh After a Write
Forcing a `refresh()` after a write provides the notifications from the
write immediately rather than on a future run of the run loop. There's no
window for the TableView to read out-of-sync values.

The downside is that this means things we recommend doing in the background,
such as writing, rerunning the query and re-sorting the results, happen
on the main thread. When these operations are computationally expensive,
this can cause delays on the main thread.

```swift
func delete(at index: Int) throws {
    try realm.write {
        realm.delete(results[index])
    }
    realm.refresh()
}

```

#### Perform the Write on a Background Thread
Performing a write on a background thread blocks the main thread for the
least amount of time. However, the code to perform a write on the background
requires more familiarity with Realm's threading model and Swift DispatchQueue
usage. Since the write doesn't happen on the main thread, the main thread
never sees the write before the notifications arrive.

```swift
func delete(at index: Int) throws {
    func delete(at index: Int) throws {
        @ThreadSafe var object = results[index]
        DispatchQueue.global().async {
            guard let object = object else { return }
            let realm = object.realm!
            try! realm.write {
                if !object.isInvalidated {
                    realm.delete(object)
                }
            }
        }
    }
}

```

## Change Notification Limits
Changes in nested documents deeper than four levels down do not trigger
change notifications.

If you have a data structure where you need to listen for changes five
levels down or deeper, workarounds include:

- Refactor the schema to reduce nesting.
- Add something like "push-to-refresh" to enable users to manually refresh data.

In the Swift SDK, you can also use
key path filtering to work
around this limitation. This feature is not available in the other SDKs.
