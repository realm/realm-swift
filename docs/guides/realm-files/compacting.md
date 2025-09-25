# Reduce Realm File Size - Swift SDK
## Overview
The size of a realm file is always larger than the total
size of the objects stored within it. This architecture enables some of
realm's great performance, concurrency, and safety benefits.

Realm writes new data within unused space tracked inside a
file. In some situations, unused space may comprise a significant
portion of a realm file. Realm's default behavior is to automatically
compact a realm file to prevent it from growing too large.
You can use manual compaction strategies when
automatic compaction is not sufficient for your use case
or you're using a version of the SDK that doesn't have automatic
compaction.

## Realm File Size
Generally, a realm file takes less space on disk than a
comparable SQLite database. These factors can affect
file size:

- Pinning transactions
- Threading
- Dispatch Queues

When you consider reducing the file size through compacting, there are a
couple of things to keep in mind:

- Compacting can be a resource-intensive operation
- Compacting can block the UI thread

Because of these factors, you probably don't want to compact a realm every
time you open it, but instead want to consider when to compact a
realm. This varies based on your application's
platform and usage patterns. When deciding when to compact, consider iOS
file size limitations.

### Avoid Pinning Transactions
Realm ties read transaction lifetimes to the memory lifetime
of realm instances. Avoid "pinning" old Realm transactions.
Use auto-refreshing realms, and wrap the use of Realm APIs
from background threads in explicit autorelease pools.

### Threading
Realm updates the version of your data that it accesses at
the start of a run loop iteration. While this gives you a consistent
view of your data, it has file size implications.

Imagine this scenario:

- **Thread A**: Read some data from a realm, and then block the thread on a
long-running operation.
- **Thread B**: Write data on another thread.
- **Thread A**: The version on the read thread isn't updated. Realm has
to hold intermediate versions of the data, growing in file size with
every write.

To avoid this issue, call `invalidate()`
on the realm. This tells the realm that you no longer need the
objects you've read so far. This frees realm from tracking
intermediate versions of those objects. The next time you access it,
realm will have the latest version of the objects.

You can also use these two methods to compact your Realm:

- Set `shouldCompactOnLaunch`
in the configuration
- Use `writeCopy(toFile:encryptionKey:)`

> Seealso:
> Advanced Guides: Threading
>

### Dispatch Queues
When accessing Realm using [Grand Central Dispatch](https://developer.apple.com/documentation/dispatch), you may see similar file growth. A dispatch
queue's autorelease pool may not drain immediately upon executing your
code. Realm cannot reuse intermediate versions of the data until the
dispatch pool deallocates the realm object. Use an explicit
autorelease pool when accessing realm from a dispatch queue.

## Automatic Compaction
> Version added: 10.35.0

The SDK automatically compacts Realm files in the background by continuously reallocating data
within the file and removing unused file space. Automatic compaction is sufficient for minimizing the Realm file size
for most applications.

Automatic compaction begins when the size of unused space in the file is more than twice the size of user
data in the file. Automatic compaction only takes place when
the file is not being accessed.

## Manual Compaction
Manual compaction can be used for applications that
require stricter management of file size or that use an older version
of the SDK that does not support automatic compaction.

Realm manual compaction works by:

1. Reading the entire contents of the realm file
2. Writing the contents to a new file at a different location
3. Replacing the original file

If the file contains a lot of data, this can be an expensive operation.

Use `shouldCompactOnLaunch()`
(Swift) or `shouldCompactOnLaunch`
(Objective-C) on a realm's configuration object to compact a realm.
Specify conditions to execute this method, such as:

- The size of the file on disk
- How much free space the file contains

For more information about the conditions to execute in the method, see:
Tips for Using Manual Compaction.

> Important:
> Compacting cannot occur while a realm is being accessed,
regardless of any configuration settings.
>

#### Objective-C

```objectivec
RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
config.shouldCompactOnLaunch = ^BOOL(NSUInteger totalBytes, NSUInteger usedBytes) {
    // totalBytes refers to the size of the file on disk in bytes (data + free space)
    // usedBytes refers to the number of bytes used by data in the file

    // Compact if the file is over 100MB in size and less than 50% 'used'
    NSUInteger oneHundredMB = 100 * 1024 * 1024;
    return (totalBytes > oneHundredMB) && ((double)usedBytes / totalBytes) < 0.5;
};

NSError *error = nil;
// Realm is compacted on the first open if the configuration block conditions were met.
RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:&error];
if (error) {
    // handle error compacting or opening Realm
}

```

#### Swift

```swift
let config = Realm.Configuration(shouldCompactOnLaunch: { totalBytes, usedBytes in
    // totalBytes refers to the size of the file on disk in bytes (data + free space)
    // usedBytes refers to the number of bytes used by data in the file

    // Compact if the file is over 100MB in size and less than 50% 'used'
    let oneHundredMB = 100 * 1024 * 1024
    return (totalBytes > oneHundredMB) && (Double(usedBytes) / Double(totalBytes)) < 0.5
})
do {
    // Realm is compacted on the first open if the configuration block conditions were met.
    let realm = try Realm(configuration: config)
} catch {
    // handle error compacting or opening Realm
}

```

### Compact a Realm Asynchronously
When you use the Swift async/await syntax to open a realm asynchronously,
you can compact a realm in the background.

```swift
func testAsyncCompact() async {
    let config = Realm.Configuration(shouldCompactOnLaunch: { totalBytes, usedBytes in
        // totalBytes refers to the size of the file on disk in bytes (data + free space)
        // usedBytes refers to the number of bytes used by data in the file

        // Compact if the file is over 100MB in size and less than 50% 'used'
        let oneHundredMB = 100 * 1024 * 1024
        return (totalBytes > oneHundredMB) && (Double(usedBytes) / Double(totalBytes)) < 0.5
    })

    do {
        // Realm is compacted asynchronously on the first open if the
        // configuration block conditions were met.
        let realm = try await Realm(configuration: config)
    } catch {
        // handle error compacting or opening Realm
    }
}

```

Starting with Realm Swift SDK Versions 10.15.0 and 10.16.0, many of the
Realm APIs support the Swift async/await syntax. Projects must
meet these requirements:

|Swift SDK Version|Swift Version Requirement|Supported OS|
| --- | --- | --- |
|10.25.0|Swift 5.6|iOS 13.x|
|10.15.0 or 10.16.0|Swift 5.5|iOS 15.x|

If your app accesses Realm in an `async/await` context, mark the code
with `@MainActor` to avoid threading-related crashes.

### Make a Compacted Copy
You can save a compacted (and optionally encrypted) copy of a realm to another file location
with the `Realm.writeCopy(toFile:encryptionKey:)`
method. The destination file cannot already exist.

> Important:
> Avoid calling this method within a write transaction. If called within a write transaction, this
method copies the absolute latest data. This includes any
**uncommitted** changes you made in the transaction before this
method call.
>

### Tips for Using Manual Compaction
Compacting a realm can be an expensive operation that can block
the UI thread. Your application should not compact every time you open
a realm. Instead, try to optimize compacting so your application does
it just often enough to prevent the file size from growing too large.
If your application runs in a resource-constrained environment,
you may want to compact when you reach a certain file size or when the
file size negatively impacts performance.

These recommendations can help you optimize manual compaction for your
application:

- Set the max file size to a multiple of your average realm state
size. If your average realm state size is 10MB, you might set the max
file size to 20MB or 40MB, depending on expected usage and device
constraints.
- As a starting point, compact realms when more than 50% of the realm file
size is no longer in use. Divide the currently used bytes by the total
file size to determine the percentage of space that is currently used.
Then, check for that to be less than 50%. This means that greater than
50% of your realm file size is unused space, and it is a good time to
compact. After experimentation, you may find a different percentage
works best for your application.

These calculations might look like this in your `shouldCompactOnLaunch`
callback:

```swift
// Set a maxFileSize equal to 20MB in bytes
let maxFileSize = 20 * 1024 * 1024
// Check for the realm file size to be greater than the max file size,
// and the amount of bytes currently used to be less than 50% of the
// total realm file size
return (realmFileSizeInBytes > maxFileSize) && (Double(usedBytes) / Double(realmFileSizeInBytes)) < 0.5
```

Experiment with conditions to find the right balance of how often to
compact realm files in your application.

#### Consider iOS File Size Limitations
A large realm file can impact the performance and reliability of
your app. Any single realm file cannot be larger than the amount
of memory your application would be allowed to map in iOS. This limit
depends on the device and on how fragmented the memory space is at
that point in time.

If you need to store more data, map it over multiple realm files.

## Summary
- Realm's architecture enables threading-related benefits,
but can result in file size growth.
- Automatic compaction manages file size growth when the file is not being accessed.
- Manual compaction strategies like `shouldCompactOnLaunch()` can be used when automatic compaction does not meet application needs.
- Compacting cannot occur if another process is accessing the realm.
- You can compact a realm in the background when you use async/await syntax.
