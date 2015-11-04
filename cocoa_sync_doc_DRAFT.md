Cocoa sync doc DRAFT
====================

Overview
--------

In general, synchronization is enabled when a server URL is specified. To enable synchronization for the default Realm, you need to set the `syncServerURL` property of the default Realm configuration as follows:

```objc
RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
configuration.syncServerURL = [NSURL URLWithString:@"realm://hydrogen.fr.sync.realm.io/my_app/foo"];
[RLMRealmConfiguration setDefaultConfiguration:configuration];
```

~(KS: Why is the `setDefaultConfiguration:` step needed? Couldn't the configuration object have been "live"?)~

For example, you can do that from `didFinishLaunchingWithOptions:` of your implementation of `UIApplicationDelegate`.

The server URL specifies both the server name (and port), and the server-side Realm with which to synchronize (`/my_app/foo`).

Use `hydrogen.fr.sync.realm.io` as server name to access our shared synchronization server (recently launched).

Setting the server URL is enough to enable synchronization.

You can adjust the amount of information logged by the synchronization process. For example, to get the maximum amount of information, do this:

```objc
[RLMRealm setServerSyncLogLevel:2]; // Log everything
```

The default level is `1` (normal), and `0` means 'nothing'. Note, setting the log level to `2` can have a significant negative impact on the performance of your application.

Before trying this out, you need to build Realm with synchronization support (this is still a manual process). See [Building Realm for iOS] for more on this.

See [How it works] for more information on how synchronization works.

See [Your own server] if you want to run your own server.


How it works
------------



Building Realm for iOS
----------------------

Be sure to have followed the instructions in "Build preperations".

In `realm-sync/`:

    shell> sh build.sh build-cocoa

In `realm-cocoa/`:

    shell> sh build.sh ios-static

After those steps it is possible to build the iOS demo apps, such as Draw and Puzzle available via `examples/ios/objc/RealmExamples.xcodeproj` in `realm-cocoa/`.


Build preperations
------------------

For now you need a local clone of the core, the sync, and the Cocoa GitHub repositories to be able to build Realm with syncronization support.

For now it will be assumed that the directory names of your three local repositories are as follows, and that they exist next to eachother in your file system, as that simplifies the build process:

    Directory       GitHub URL
    ----------------------------------------------------
    realm-core/     git@github.com:realm/realm-core.git
    realm-sync/     git@github.com:realm/realm-sync.git
    realm-cocoa/    git@github.com:realm/realm-cocoa.git

For now it is a manual process to ensure that the branches checked out in each of these repositories are intercompatible. At the present time, there is a branch called `sync-demo-5` in each of them, and they are currently intercompatible, and represent the latest state of development.

    Repository       Recommended branch
    -----------------------------------
    realm-core/      sync-demo-5
    realm-sync/      sync-demo-5
    realm-cocoa/     sync-demo-5


Your own server
---------------

Be sure to have followed the instructions in "Build preperations".

Build the server from`realm-sync/` as follows:

    shell> sh build.sh build

Then run the server like this:

    shell> src/realm/realm-server-noinst /tmp/sync-dir 127.0.0.1

Where `/tmp/sync-dir` is a directory you have created for server-side Realm files.

For more options, see the output from:

    shell> src/realm/realm-server-noinst --help
