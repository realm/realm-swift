# Swift Concurrency - Swift SDK
Swift's concurrency system provides built-in support for writing asynchronous
and parallel code in a structured way. For a detailed overview of the
Swift concurrency system, refer to the [Swift Programming Language Concurrency
topic](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html).

While the considerations on this page broadly apply to using realm with
Swift concurrency features, Realm Swift SDK version 10.39.0 adds support
for using Realm with Swift Actors. You can use Realm isolated to a single
actor or use Realm across actors.

Realm's actor support simplifies using Realm in a MainActor and background actor
context, and supersedes much of the advice on this page regarding concurrency
considerations. For more information, refer to Use Realm with Actors - Swift SDK.

## Realm Concurrency Caveats
As you implement concurrency features in your app, consider this caveat
about Realm's threading model and Swift concurrency threading behaviors.

### Suspending Execution with Await
Anywhere you use the Swift keyword `await` marks a possible suspension
point in the execution of your code. With Swift 5.7, once your code suspends,
subsequent code might not execute on the same thread. This means that
anywhere you use `await` in your code, the subsequent code could be
executed on a different thread than the code that precedes or follows it.

This is inherently incompatible with Realm's live object paradigm. Live objects, collections, and realm instances are
**thread-confined**: that is, they are only valid on the thread on which
they were created. Practically speaking, this means you cannot pass live
instances to other threads. However, Realm offers several
mechanisms for sharing objects across threads. These mechanisms typically require
your code to do some explicit handling to safely pass data across threads.

You can use some of these mechanisms, such as frozen objects or the ThreadSafeReference, to safely use Realm objects and instances
across threads with the `await` keyword. You can also avoid
threading-related issues by marking any asynchronous Realm code with
`@MainActor` to ensure your apps always execute this code on the main
thread.

As a general rule, keep in mind that using Realm in an `await` context
*without* incorporating threading protection may yield inconsistent behavior.
Sometimes, the code may succeed. In other cases, it may throw an error
related to writing on an incorrect thread.

### Perform Background Writes
A commonly-requested use case for asynchronous code is to perform write
operations in the background without blocking the main thread.

Realm has two APIs that allow for performing asynchronous writes:

- The [writeAsync()](https://www.mongodb.com/docs/realm-sdks/swift/latest/Structs/Realm.html#/s:10RealmSwift0A0V10writeAsync_10onCompletes6UInt32Vyyc_ys5Error_pSgcSgtF)
API allows for performing async writes using Swift completion handlers.
- The [asyncWrite()](https://www.mongodb.com/docs/realm-sdks/swift/latest/Structs/Realm.html#/s:10RealmSwift0A0V10asyncWriteyxxyKXEYaKlF)
API allows for performing async writes using Swift async/await syntax.

Both of these APIs allow you to add, update, or delete objects in the
background without using frozen objects or passing a thread-safe reference.

With the `writeAsync()` API, waiting to obtain the write lock and
committing a transaction occur in the background. The write block itself
runs on the calling thread. This provides thread-safety without requiring
you to manually handle frozen objects or passing references across threads.

However, while the write block itself is executed, this does block new
transactions on the calling thread. This means that a large write using
the `writeAsync()` API could block small, quick writes while it executes.

The `asyncWrite()` API suspends the calling task while waiting for its
turn to write rather than blocking the thread. In addition, the actual
I/O to write data to disk is done by a background worker thread. For small
writes, using this function on the main thread may block the main thread
for less time than manually dispatching the write to a background thread.

For more information, including code examples, refer to: Perform a Background Write.

## Tasks and TaskGroups
Swift concurrency provides APIs to manage [Tasks](https://developer.apple.com/documentation/swift/task)
and [TaskGroups](https://developer.apple.com/documentation/swift/taskgroup). The [Swift concurrency
documentation](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
defines a task as a unit of work that can be run asynchronously as part of
your program. Task allows you to specifically define a unit of asynchronous
work. TaskGroup lets you define a collection of Tasks to execute as a unit
under the parent TaskGroup.

Tasks and TaskGroups provide the ability to yield the thread to other
important work or to cancel a long-running task that could be blocking
other operations. To get these benefits, you might be tempted to use Tasks
and TaskGroups to manage realm writes in the background.

However, the thread-confined constraints described in Suspending
Execution with Await above apply in
the Task context. If your Task contains `await` points, subsequent code
might run or resume on a different thread and violate Realm's thread confinement.

You must annotate functions that you run in a Task context with `@MainActor`
to ensure code that accesses Realm only runs on the main thread. This negates
some of the benefits of using Tasks, and may mean this is not a good design
choice for apps that use Realm unless you are using Tasks solely for
networking activities like managing users.

## Actor Isolation
> Seealso:
> The information in this section is applicable to Realm SDK versions earlier
than 10.39.0. Starting in Realm Swift SDK version 10.39.0 and newer,
the SDK supports using Realm with Swift Actors and related async functionality.
>
> For more information, refer to Use Realm with Actors - Swift SDK.
>

Actor isolation provides the perception of confining Realm access to a
dedicated actor, and therefore seems like a safe way to manage Realm
access in an asynchronous context.

However, using Realm in a non-`@MainActor` async function is currently
not supported.

In Swift 5.6, this would often work by coincidence. Execution after an
`await` would continue on whatever thread the awaited thing ran on.
Using `await Realm()` in an async function would result in the code
following that running on the main thread until your next call to an
actor-isolated function.

Swift 5.7 instead hops threads whenever changing actor isolation contexts.
An unisolated async function always runs on a background thread instead.

If you have code which uses `await Realm()` and works in 5.6, marking
the function as `@MainActor` will make it work with Swift 5.7. It will
function how it did - unintentionally - in 5.6.

## Errors Related to Concurrency Code
Most often, the error you see related to accessing Realm through concurrency
code is `Realm accessed from incorrect thread.` This is due to the
thread-isolation issues described on this page.

To avoid threading-related issues in code that uses Swift concurrency features:

- Upgrade to a version of the Realm Swift SDK that supports actor-isolated realms,
and use this as an alternative to manually managing threading. For more
information, refer to Use Realm with Actors - Swift SDK.
- Do not change execution contexts when accessing a realm. If you open a realm
on the main thread to provide data for your UI, annotate subsequent functions
where you access the realm asynchronously with `@MainActor` to ensure it
always runs on the main thread. Remember that `await` marks a suspension
point that could change to a different thread.
- Apps that do not use actor-isolated realms can use the `writeAsync` API to
perform a background write. This manages realm
access in a thread-safe way without requiring you to write specialized code
to do it yourself. This is a special API that outsources aspects of the
write process - where it is safe to do so - to run in an async context.
Unless you are writing to an actor-isolated realm, you do not use this
method with Swift's `async/await` syntax. Use this method synchronously
in your code. Alternately, you can use the `asyncWrite` API with Swift's
`async/await` syntax when awaiting writes to asynchronous realms.
- If you want to explicitly write concurrency code that is not actor-isolated
where accessing a realm is done in a thread-safe way, you can explicitly
pass instances across threads where
applicable to avoid threading-related crashes. This does require a good
understanding of Realm's threading model, as well as being mindful of
Swift concurrency threading behaviors.

## Sendable, Non-Sendable and Thread-Confined Types
The Realm Swift SDK public API contains types that fall into three broad
categories:

- Sendable
- Not Sendable and not thread confined
- Thread-confined

You can share types that are not Sendable and not thread confined between
threads, but you must synchronize them.

Thread-confined types, unless frozen, are confined to an isolation context.
You cannot pass them between these contexts even with synchronization.
