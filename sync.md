Cocoa sync doc DRAFT
====================

Realm Sync allows you to transparently share Realms between multiple devices. This makes it easy for users to move seamlessly between devices, do realtime collaboration with other users and always have live backup of all their data. 

**Key features:**
* Realtime collaboration: Multiple users can interact with the same data simultaneously.
* Full access to the entire Realm on the device. No latency on your own operations.
* Works even when devices go offline. Changes will transparently be merged when reconnected.

Overview
--------

In general, synchronization is enabled when a server URL is specified. To enable synchronization for the default Realm, you need to set the `syncServerURL` and `syncIdentity` properties of your RLMRealmConfiguration as follows:

```objc
RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
configuration.syncServerURL = [NSURL URLWithString:@"realm://hydrogen.fr.sync.realm.io/my_app/foo"];
configuration.syncIdentity = @"..."; // 40-byte string
[[RLMRealm alloc] initWithConfiguration:configuration error:nil];
```

In the future the `syncIdentity` will change from a string to be a persisted cryptographic token.

You can set up sync from `didFinishLaunchingWithOptions:` in your implementation of `UIApplicationDelegate`.

The server URL specifies both the server name (and port), and the server-side Realm with which to synchronize (`/my_app/foo`). Different user identities will see completely independent Realms even if they ask for the same path. Sharing across user identities is currently not possible.

Use `hydrogen.fr.sync.realm.io` as server name to access our shared synchronization server (recently launched).

Setting the server URL is enough to enable synchronization. If the server URL is set but not the user identity token, you will see an error message in the log.

You can adjust the amount of information logged by the synchronization process. For example, to get the maximum amount of information, do this:

```objc
[RLMRealm setGlobalSynchronizationLoggingLevel:RLMSyncLogLevelVerbose];
```

The default level is `RLMSyncLogLevelNormal`. Note, setting the log level to `RLMSyncLogLevelVerbose` can have a significant negative impact on the performance of your application.

Before trying this out, you need to build Realm with synchronization support (this is still a manual process). See [Building Realm for iOS](#building-realm-for-ios) for more on this.

See [How it works](#how-it-works) for more information on how synchronization works.

See [Your own server](#your-own-server) if you want to run your own server.


How it works
------------

Realm Sync is based on a set of merge rules which ensure that all clients will eventually see the same state. Clients are allowed to make any modification they please at any point in time (except destructive schema changes, for now). In a formal sense, Realm Sync is an AP solution under the CAP theorem. Clients are generally unaware of each other, except the server, and it is up to the app to identify different users if it so pleases.

When two clients make modifications to the Realm in a way that causes a conflict, Realm Sync automatically resolves the conflict in a way that emulates the behavior that would have been observed if all the operations had been performed locally. The order of operations used in this emulation is defined by the timestamp of each commit in the transaction log. Timestamps are [Lamport timestamps](https://en.wikipedia.org/wiki/Lamport_timestamps) to ensure a somewhat intuitive behavior of the merge algorithm.

Objects in Realm have no inherent order, so insertion/object creation can always be merged in a way that behaves naturally. However, for ordered data structures (such as lists), the order of operations on the data structure matters. For instance, if the app developer inserts elements to a list in an sort order that the app defines, this order might be broken when receiving updates from the server, because the merge algorithm doesn't know about the order that the user is trying to enforce. Similarly, if the app developer updates a field of an object based on some condition derived from other data in the Realm, this invariant might be broken during sync if another peer came to a different conclusion and made a different update, because the merge algorithm does not know about this logic.

If, however, operations on the Realm always reflect end-user intentions (i.e. a user-defined list order, or a field of an object that is updated directly by the user), things "naturally" merge correctly.

NOTE: In the (near) future we will start providing ways to make this behavior much more customizable, potentially by letting the app developer express their intention to the sync merge algorithm in various ways. Some of the planned features are: Set, Dictionary, Counter, Bounded Counter.

NOTE: Sync is currently only able to function in AP mode, which means that global locks are not available. This has the implication that features that depend on all clients participating on sync agreeing on a particular state are not possible to implement (for instance, a bank transfer app that needs to answer the question "do I have enough money for this transaction?" will not work properly). Each device is considered an equal source of truth in the app's decision-making, and it is currently not possible to work in a different mode. Luckily, this interacts very well with our existing APIs, in the sense that apps using Realm require zero modifications to the app code to work with sync (no calls into Realm will suddently start blocking, etc.).


Building Realm for iOS
----------------------

Be sure to have followed the instructions in [Build preperations](#build-preperations).

In `realm-sync/`:

    shell> sh build.sh build-cocoa

In `realm-cocoa/`:

    shell> sh build.sh ios-static

After this last step, you can find `Realm.framework` in `realm-cocoa/build/ios`. Install the framework into your Xcode project or one of the iOS demo apps, such as Draw and Puzzle available via `examples/ios/objc/RealmExamples.xcodeproj` in `realm-cocoa/`.


Build preperations
------------------

For now you need a local clone of the core, the sync, and the Cocoa GitHub repositories to be able to build Realm with syncronization support.

For now it will be assumed that the directory names of your three local repositories are as follows, and that they exist next to eachother in your file system, as that simplifies the build process:

    Directory       GitHub URL
    ----------------------------------------------------
    realm-core/     git@github.com:realm/realm-core.git
    realm-sync/     git@github.com:realm/realm-sync.git
    realm-cocoa/    git@github.com:realm/realm-cocoa-private.git (make sure to adjust the cloned folder to just realm-cocoa)

For now it is a manual process to ensure that the branches checked out in each of these repositories are intercompatible. At the present time, there is a branch called `sync-demo-5` in each of them, and they are currently intercompatible, and represent the latest state of development.

    Repository       Recommended branch
    -----------------------------------
    realm-core/      sync-demo-5
    realm-sync/      sync-demo-5
    realm-cocoa/     sync-demo-5


Your own server
---------------

Be sure to have followed the instructions in [Build preperations](#build-preperations).

Build the server from`realm-sync/` as follows:

    shell> sh build.sh build

Then run the server like this:

    shell> src/realm/realm-server-noinst /tmp/sync-dir 127.0.0.1

Where `/tmp/sync-dir` is a directory you have created for server-side Realm files.

For more options, see the output from:

    shell> src/realm/realm-server-noinst --help
