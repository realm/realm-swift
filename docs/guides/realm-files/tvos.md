# Build for tvOS
## Overview
This page details considerations when using Realm on tvOS.

> Seealso:
> Install the SDK for iOS, macOS, tvOS, and watchOS
>

## Avoid Storing Important User Data
Avoid storing important user data in a realm on tvOS. Instead, it's
best to treat Realm as a rebuildable cache.

> Note:
> The reason for this has to do with where Realm writes its
Realm files. On other Apple platforms,
Realm writes its Realm files to the "Documents"
directory. Because tvOS restricts writes to that directory, the
default Realm file location on tvOS is instead `NSCachesDirectory`.
tvOS can purge files in that directory at any time, so reliable
long-term persistence is not possible.
>

You can also use Realm as an initial data source by
bundling prebuilt Realm files in your app.
Note that the [App Store guidelines](https://developer.apple.com/tvos/submit/) limit your
app size to 4GB.

> Tip:
> Browse our [tvOS examples](https://github.com/realm/realm-swift/tree/master/examples/tvos) for sample tvOS apps
that demonstrate how to use Realm as an offline cache.
>

## Share Realm Files with TV Services Extensions
To share a Realm file between a tvOS app and a
TV services extension such as [Top Shelf](https://developer.apple.com/design/human-interface-guidelines/tvos/overview/top-shelf/), use the
`Library/Caches/` directory in the shared container for the
application group:

```swift
let fileUrl = FileManager.default
    .containerURL(forSecurityApplicationGroupIdentifier: "group.com.mongodb.realm.examples.extension")!
    .appendingPathComponent("Library/Caches/default.realm")

```
