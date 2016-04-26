# Realm Sync Beta for Cocoa

Realm Sync allows you to transparently share Realms between multiple devices. This makes it easy for users to transition seamlessly between devices, do realtime collaboration with other users and always have live backup of all their data.

**Key features:**
* Realtime collaboration: Multiple users can interact with the same data simultaneously.
* Full access to the entire Realm on the device. No latency on your own operations.
* Works even when offline. Changes will be transparently merged when reconnected.

**Limitations:**
* You can only synchronize entire Realms. Sync of subsets (individual objects) is not supported yet.
* Primary keys do not work as intended with sync yet. Two objects with the same primary key created on different devices, will be treated as seperate objects versus the expected behavior of merging the objects together when each device syncs with the other.
* You cannot enable sync on a Realm that already contains data, such as in the case of wanting to test Realm Sync on an existing app that uses Realm. Instead, you should create a new seperate synced Realm (at a different file path) and copy the data into it from the existing Realm.
* Only additive schema changes are currently supported via sync (you are still required to perform a client-side migration for the existing client data). However, if you remove a property from the model in a synced Realm, the server will silently reject the connection at the same `syncServerURL` end point from which the previous schema had connected to. You will need to point this Realm with the new schema to a different `syncServerURL` which will mean losing the transaction history.
* During development you might need to "reset" sync, possibly due to a non-additive schema change or simply because you want to remove the history. The client API doesn't currently offer any ability to reset the server state, so the suggested work around is to change the `syncServerURL` to a new end point without any existing history.


## Installation

### Objective-C

1. Go to your Xcode project's "General" settings. Drag `Realm.framework` from
   the `framwework/ios/` or `framwework/osx/` directory to the "Embedded Binaries"
   section. Make sure **Copy items if needed** is selected and click **Finish**.
2. In your unit test target's "Build Settings", add the parent path to
   `Realm.framework` in the "Framework Search Paths" section.
3. If using Realm in an iOS project, create a new "Run Script Phase" in your
   app's target's "Build Phases" and paste the following snippet in the script
   text field: `bash "${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/Realm.framework/strip-frameworks.sh"`
   This step is required to work around an
   [App Store submission bug](http://www.openradar.me/radar?id=6409498411401216)
   when archiving universal binaries.

## Usage

In general, synchronization is enabled when a server URL is specified. To enable synchronization for the default Realm, you need to set the `syncServerURL` and `syncIdentity` properties of your RLMRealmConfiguration as follows:

**Objective-C**
```objc
RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
configuration.syncServerURL = [NSURL URLWithString:@"realm://127.0.0.1:7800/my_app"];
configuration.syncIdentity = @"..."; // identity file in base64
configuration.syncSignature = @"..." // sha256 signed string
[RLMRealmConfiguration setDefaultConfiguration:configuration];

...
// Default Realm now opens with sync
RLMRealm *realm = [RLMRealm defaultRealm];
```

You can use the following syncIdentity and syncSignature. They will work with the current public key the server uses.

```objc
configuration.syncIdentity = @"ewogICAgImlkZW50aXR5IjogImRlZmF1bHRJZGVudGl0eSIsCiAgICAiYWNjZXNzIjogWyJkb3dubG9hZCIsICJ1cGxvYWQiXSwKICAgICJhcHBfaWQiOiAiY29tLlJlYWxtLkFwcCIsCiAgICAiZXhwaXJlcyI6IG51bGwsCiAgICAidGltZXN0YW1wIjogMTQ1NjE1NTQzNgp9Cg==";
configuration.syncSignature = @"oLlAo7l5P41rcnfcOGDkFpFfEClj1FnbPwQlpS6KYUknreqQi5N8l4KnsSumI/X7rlK7C1pvDujYzX8OzXGeTbvQcJz8x0X/xGJzXAOClDOLIccwC1zjpdryeL0l4aA1ec57YmvjJ9kZ+wxwyrk0z2zDusEUGLQlUF0VxqIVaD7ijpNjI66EFEacko+i2C5z3tc3AtFyLsP5hftL9SEPHTIkETy4ZPyf+QL5bUu8M/3C1WOiiNaU+CTgP6WsgSSw3ropVciYV5WEdfckW0KTFWO7n+3OuvShJ7fyaY5+UDuYnDb0dWXyqAeJcYyFUN7x2PCWFKGgliV7iLX2mb4neQ==";
```

You can set up sync from `didFinishLaunchingWithOptions:` in your implementation of `UIApplicationDelegate`.

The server URL specifies both the server name (and port), and the server-side Realm with which to synchronize (`/my_app`). Different user identities will see completely independent Realms even if they ask for the same path. Sharing across user identities is currently not possible.

Use `fr.demo.realmusercontent.com` as server name to access our shared synchronization server.

Setting the server URL is enough to enable synchronization. If the server URL is set but not the user identity token, you will see an error message in the log.

You can adjust the amount of information logged by the synchronization process. For example, to get the maximum amount of information, do this:

```objc
[RLMRealm setGlobalSynchronizationLoggingLevel:RLMSyncLogLevelVerbose];
```

The default level is `RLMSyncLogLevelNormal`. Note, setting the log level to `RLMSyncLogLevelVerbose` can have a significant negative impact on the performance of your application.

Once sync is enabled on a Realm file, any changes written to that Realm file will be automatically propagated to Realm files on other devices, that were created with the same `syncIdentity` and `syncServerURL`. These changes are performed asynchronously, with the updated values becoming visible in the Realm file on the new device as if it had performed a write transaction itself on a local background queue.

If sync activity should cause the UI to update, [Realm Notifications](https://realm.io/docs/objc/latest/#notifications) can be used to be notified of changes.


## Best Practices

* Realm objects and queries are auto-updating, so you should make use of Realm's notification capabilities to update the UI in response to both local and remotely synced changes (which will be integrated in the background). We currently offer KVO and a global notification whenever a Realm updates, and we are actively working on fine-grained notifications to give you more control.
* To enable basic data sharing with the current implementation you can create a "public" synced Realm by using a hardcoded `syncIdentity` that all devices would have access to. To share data among groups of users, the "public" sync Realm could be used to share `syncIdentity` strings that correspond to groups of individual users. This is an area we plan to improve going forward.