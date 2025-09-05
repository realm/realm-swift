# CRUD - Swift SDK
## Write Transactions
Realm uses a highly efficient storage engine
to persist objects. You can **create** objects in a realm,
**update** objects in a realm, and eventually **delete**
objects from a realm. Because these operations modify the
state of the realm, we call them writes.

Realm handles writes in terms of **transactions**. A
transaction is a list of read and write operations that
Realm treats as a single indivisible operation. In other
words, a transaction is *all or nothing*: either all of the
operations in the transaction succeed or none of the
operations in the transaction take effect.

All writes must happen in a transaction.

A realm allows only one open transaction at a time. Realm
blocks other writes on other threads until the open
transaction is complete. Consequently, there is no race
condition when reading values from the realm within a
transaction.

When you are done with your transaction, Realm either
**commits** it or **cancels** it:

- When Realm **commits** a transaction, Realm writes
all changes to disk.
- When Realm **cancels** a write transaction or an operation in
the transaction causes an error, all changes are discarded
(or "rolled back").

### Run a Transaction
The Swift SDK represents each transaction as a callback function
that contains zero or more read and write operations. To run
a transaction, define a transaction callback and pass it to
the realm's `write` method. Within this callback, you are
free to create, read, update, and delete on the realm. If
the code in the callback throws an exception when Realm runs
it, Realm cancels the transaction. Otherwise, Realm commits
the transaction immediately after the callback.

> Important:
> Since transactions block each other, it is best to avoid
opening transactions on both the UI thread and a
background thread. If a background transaction
blocks your UI thread's transaction, your app may appear
unresponsive.
>

> Example:
> The following code shows how to run a transaction with
the realm's write method. If the code in the callback
throws an exception, Realm cancels the transaction.
Otherwise, Realm commits the transaction.
>
> #### Objective-C
>
> ```objectivec
> // Open the default realm.
> RLMRealm *realm = [RLMRealm defaultRealm];
>
> // Open a thread-safe transaction.
> [realm transactionWithBlock:^() {
>     // ... Make changes ...
>     // Realm automatically cancels the transaction in case of exception.
>     // Otherwise, Realm automatically commits the transaction at the
>     // end of the code block.
> }];
>
> ```
>
>
> #### Swift
>
> ```swift
> // Open the default realm.
> let realm = try! Realm()
>
> // Prepare to handle exceptions.
> do {
>     // Open a thread-safe transaction.
>     try realm.write {
>         // Make any writes within this code block.
>         // Realm automatically cancels the transaction
>         // if this code throws an exception. Otherwise,
>         // Realm automatically commits the transaction
>         // after the end of this code block.
>     }
> } catch let error as NSError {
>     // Failed to write to realm.
>     // ... Handle error ...
> }
>
> ```
>
>

## Interface-Driven Writes
Realm always delivers notifications asynchronously, so they
never block the UI thread. However, there are situations when the UI
must reflect changes instantly. If you update the UI directly at the
same time as the write, the eventual notification could double that
update. This could lead to your app crashing due to inconsistent state
between the UI and the backing data store. To avoid this, you can write
without sending a notification to a specific handler. We call this type
of transaction an **interface-driven write**.

> Example:
> Say we decide to manage a table view's data source manually, because
our app design requires an instantaneous response to UI-driven table
updates. As soon as a user adds an item to the table view, we insert
it to our data source, which writes to the realm but also
immediately kicks off the animation. However, when Realm
delivers the change notification for this insertion a little later,
it indicates that an object has been added. But we already updated
the table view for it! Rather than writing complicated code to handle
this case, we can use interface-driven writes to prevent a specific
notification handler from firing for that specific write.
>

Interface-driven writes, also known as silent writes, are especially
useful when using fine-grained collection notifications. While you use
interface-driven writes for the current user's updates and update the UI
immediately, the sync process can use standard notifications to update
the UI.
