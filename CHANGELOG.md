0.92.2 Release notes (2015-05-08)
=============================================================

### API breaking changes

* None.

### Enhancements

* Exceptions raised when incorrect object types are used with predicates now contain more detailed information.
* Added `-[RLMMigration deleteDataForClassName:]` and `Migration.deleteData(_:)` 
  to enable cleaning up after removing object subclasses

### Bugfixes

* Prevent debugging of an application using an encrypted Realm to work around
  frequent LLDB hangs. Until the underlying issue is addressed you may set
  REALM_DISABLE_ENCRYPTION=YES in your application's environment variables to
  have requests to open an encrypted Realm treated as a request for an
  unencrypted Realm.
* Linked objects are properly updated in `createOrUpdateInRealm:withValue:`.
* List properties on Objects are now properly initialized during fast enumeration.

0.92.1 Release notes (2015-05-06)
=============================================================

### API breaking changes

* None.

### Enhancements

* `-[RLMRealm inWriteTransaction]` is now public.
* Realm Swift is now available on CoocaPods.

### Bugfixes

* Force code re-signing after stripping architectures in `strip-frameworks.sh`.

0.92.0 Release notes (2015-05-05)
=============================================================

### API breaking changes

* Migration blocks are no longer called when a Realm file is first created.
* The following APIs have been deprecated in favor of newer method names:

| Deprecated API                                         | New API                                               |
|:-------------------------------------------------------|:------------------------------------------------------|
| `-[RLMMigration createObject:withObject:]`             | `-[RLMMigration createObject:withValue:]`             |
| `-[RLMObject initWithObject:]`                         | `-[RLMObject initWithValue:]`                         |
| `+[RLMObject createInDefaultRealmWithObject:]`         | `+[RLMObject createInDefaultRealmWithValue:]`         |
| `+[RLMObject createInRealm:withObject:]`               | `+[RLMObject createInRealm:withValue:]`               |
| `+[RLMObject createOrUpdateInDefaultRealmWithObject:]` | `+[RLMObject createOrUpdateInDefaultRealmWithValue:]` |
| `+[RLMObject createOrUpdateInRealm:withObject:]`       | `+[RLMObject createOrUpdateInRealm:withValue:]`       |

### Enhancements

* `Int8` properties defined in Swift are now treated as integers, rather than
  booleans.
* NSPredicates created using `+predicateWithValue:` are now supported.

### Bugfixes

* Compound AND predicates with no subpredicates now correctly match all objects.

0.91.5 Release notes (2015-04-28)
=============================================================

### Bugfixes

* Fix issues with removing search indexes and re-enable it.

0.91.4 Release notes (2015-04-27)
=============================================================

### Bugfixes

* Temporarily disable removing indexes from existing columns due to bugs.

0.91.3 Release notes (2015-04-17)
=============================================================

### Bugfixes

* Fix `Extra argument 'objectClassName' in call` errors when building via
  CocoaPods.

0.91.2 Release notes (2015-04-16)
=============================================================

* Migration blocks are no longer called when a Realm file is first created.

### Enhancements

* `RLMCollection` supports collection KVC operations.
* Sorting `RLMResults` is 2-5x faster (typically closer to 2x).
* Refreshing `RLMRealm` after a write transaction which inserts or modifies
  strings or `NSData` is committed on another thread is significantly faster.
* Indexes are now added and removed from existing properties when a Realm file
  is opened, rather than only when properties are first added.

### Bugfixes

* `+[RLMSchema dynamicSchemaForRealm:]` now respects search indexes.
* `+[RLMProperty isEqualToProperty:]` now checks for equal `indexed` properties.

0.91.1 Release notes (2015-03-12)
=============================================================

### Enhancements

* The browser will automatically refresh when the Realm has been modified
  from another process.
* Allow using Realm in an embedded framework by setting
  `APPLICATION_EXTENSION_API_ONLY` to YES.

### Bugfixes

* Fix a crash in CFRunLoopSourceInvalidate.

0.91.0 Release notes (2015-03-10)
=============================================================

### API breaking changes

* `attributesForProperty:` has been removed from `RLMObject`. You now specify indexed
  properties by implementing the `indexedProperties` method.
* An exception will be thrown when calling `setEncryptionKey:forRealmsAtPath:`,
  `setSchemaVersion:forRealmAtPath:withMigrationBlock:`, and `migrateRealmAtPath:`
  when a Realm at the given path is already open.
* Object and array properties of type `RLMObject` will no longer be allowed.

### Enhancements

* Add support for sharing Realm files between processes.
* The browser will no longer show objects that have no persisted properties.
* `RLMSchema`, `RLMObjectSchema`, and `RLMProperty` now have more useful descriptions.
* Opening an encrypted Realm while a debugger is attached to the process no
  longer throws an exception.
* `RLMArray` now exposes an `isInvalidated` property to indicate if it can no
  longer be accessed.

### Bugfixes

* An exception will now be thrown when calling `-beginWriteTransaction` from within a notification
  triggered by calling `-beginWriteTransaction` elsewhere.
* When calling `delete:` we now verify that the object being deleted is persisted in the target Realm.
* Fix crash when calling `createOrUpdate:inRealm` with nested linked objects.
* Use the key from `+[RLMRealm setEncryptionKey:forRealmsAtPath:]` in
  `-writeCopyToPath:error:` and `+migrateRealmAtPath:`.
* Comparing an RLMObject to a non-RLMObject using `-[RLMObject isEqual:]` or
  `-isEqualToObject:` now returns NO instead of crashing.
* Improved error message when an `RLMObject` subclass is defined nested within
  another Swift declaration.
* Fix crash when the process is terminated by the OS on iOS while encrypted realms are open.
* Fix crash after large commits to encrypted realms.

0.90.6 Release notes (2015-02-20)
=============================================================

### Enhancements

* Improve compatiblity of encrypted Realms with third-party crash reporters.

### Bugfixes

* Fix incorrect results when using aggregate functions on sorted RLMResults.
* Fix data corruption when using writeCopyToPath:encryptionKey:.
* Maybe fix some assertion failures.

0.90.5 Release notes (2015-02-04)
=============================================================

### Bugfixes

* Fix for crashes when encryption is enabled on 64-bit iOS devices.

0.90.4 Release notes (2015-01-29)
=============================================================

### Bugfixes

* Fix bug that resulted in columns being dropped and recreated during migrations.

0.90.3 Release notes (2015-01-27)
=============================================================

### Enhancements

* Calling `createInDefaultRealmWithObject:`, `createInRealm:withObject:`,
  `createOrUpdateInDefaultRealmWithObject:` or `createOrUpdateInRealm:withObject:`
  is a no-op if the argument is an RLMObject of the same type as the receiver
  and is already backed by the target realm.

### Bugfixes

* Fix incorrect column type assertions when the first Realm file opened is a
  read-only file that is missing tables.
* Throw an exception when adding an invalidated or deleted object as a link.
* Throw an exception when calling `createOrUpdateInRealm:withObject:` when the
  receiver has no primary key defined.

0.90.1 Release notes (2015-01-22)
=============================================================

### Bugfixes

* Fix for RLMObject being treated as a model object class and showing up in the browser.
* Fix compilation from the podspec.
* Fix for crash when calling `objectsWhere:` with grouping in the query on `allObjects`.

0.90.0 Release notes (2015-01-21)
=============================================================

### API breaking changes

* Rename `-[RLMRealm encryptedRealmWithPath:key:readOnly:error:]` to
  `-[RLMRealm realmWithPath:encryptionKey:readOnly:error:]`.
* `-[RLMRealm setSchemaVersion:withMigrationBlock]` is no longer global and must be called
  for each individual Realm path used. You can now call `-[RLMRealm setDefaultRealmSchemaVersion:withMigrationBlock]`
  for the default Realm and `-[RLMRealm setSchemaVersion:forRealmAtPath:withMigrationBlock:]` for all others;

### Enhancements

* Add `-[RLMRealm writeCopyToPath:encryptionKey:error:]`.
* Add support for comparing string columns to other string columns in queries.

### Bugfixes

* Roll back changes made when an exception is thrown during a migration.
* Throw an exception if the number of items in a RLMResults or RLMArray changes
  while it's being fast-enumerated.
* Also encrypt the temporary files used when encryption is enabled for a Realm.
* Fixed crash in JSONImport example on OS X with non-en_US locale.
* Fixed infinite loop when opening a Realm file in the Browser at the same time
  as it is open in a 32-bit simulator.
* Fixed a crash when adding primary keys to older realm files with no primary
  keys on any objects.
* Fixed a crash when removing a primary key in a migration.
* Fixed a crash when multiple write transactions with no changes followed by a
  write transaction with changes were committed without the main thread
  RLMRealm getting a chance to refresh.
* Fixed incomplete results when querying for non-null relationships.
* Improve the error message when a Realm file is opened in multiple processes
  at once.

0.89.2 Release notes (2015-01-02)
=============================================================

### API breaking changes

* None.

### Enhancements

* None.

### Bugfixes

* Fix an assertion failure when invalidating a Realm which is in a write
  transaction, has already been invalidated, or has never been used.
* Fix an assertion failure when sorting an empty RLMArray property.
* Fix a bug resulting in the browser never becoming visible on 10.9.
* Write UTF-8 when generating class files from a realm file in the Browser.

0.89.1 Release notes (2014-12-22)
=============================================================

### API breaking changes

* None.

### Enhancements

* Improve the error message when a Realm can't be opened due to lacking write
  permissions.

### Bugfixes

* Fix an assertion failure when inserting rows after calling `deleteAllObjects`
  on a Realm.
* Separate dynamic frameworks are now built for the simulator and devices to
  work around App Store submission errors due to the simulator version not
  being automatically stripped from dynamic libraries.

0.89.0 Release notes (2014-12-18)
=============================================================

### API breaking changes

* None.

### Enhancements

* Add support for encrypting Realm files on disk.
* Support using KVC-compliant objects without getters or with custom getter
  names to initialize RLMObjects with `createObjectInRealm` and friends.

### Bugfixes

* Merge native Swift default property values with defaultPropertyValues().
* Don't leave the database schema partially updated when opening a realm fails
  due to a migration being needed.
* Fixed issue where objects with custom getter names couldn't be used to
  initialize other objects.
* Fix a major performance regression on queries on string properties.
* Fix a memory leak when circularly linked objects are added to a Realm.

0.88.0 Release notes (2014-12-02)
=============================================================

### API breaking changes

* Deallocating an RLMRealm instance in a write transaction lacking an explicit
  commit/cancel will now be automatically cancelled instead of committed.
* `-[RLMObject isDeletedFromRealm]` has been renamed to `-[RLMObject isInvalidated]`.

### Enhancements

* Add `-[RLMRealm writeCopyToPath:]` to write a compacted copy of the Realm
  another file.
* Add support for case insensitive, BEGINSWITH, ENDSWITH and CONTAINS string
  queries on array properties.
* Make fast enumeration of `RLMArray` and `RLMResults` ~30% faster and
  `objectAtIndex:` ~55% faster.
* Added a lldb visualizer script for displaying the contents of persisted
  RLMObjects when debugging.
* Added method `-setDefaultRealmPath:` to change the default Realm path.
* Add `-[RLMRealm invalidate]` to release data locked by the current thread.

### Bugfixes

* Fix for crash when running many simultaneous write transactions on background threads.
* Fix for crashes caused by opening Realms at multiple paths simultaneously which have had
  properties re-ordered during migration.
* Don't run the query twice when `firstObject` or `lastObject` are called on an
  `RLMResults` which has not had its results accessed already.
* Fix for bug where schema version is 0 for new Realm created at the latest version.
* Fix for error message where no migration block is specified when required.

0.87.4 Release notes (2014-11-07)
=============================================================

### API breaking changes

* None.

### Enhancements

* None.

### Bugfixes

* Fix browser location in release zip.

0.87.3 Release notes (2014-11-06)
=============================================================

### API breaking changes

* None.

### Enhancements

* Added method `-linkingObjectsOfClass:forProperty:` to RLMObject to expose inverse
  relationships/backlinks.

### Bugfixes

* Fix for crash due to missing search index when migrating an object with a string primary key
  in a database created using an older versions (0.86.3 and earlier).
* Throw an exception when passing an array containing a
  non-RLMObject to -[RLMRealm addObjects:].
* Fix for crash when deleting an object from multiple threads.

0.87.0 Release notes (2014-10-21)
=============================================================

### API breaking changes

* RLMArray has been split into two classes, `RLMArray` and `RLMResults`. RLMArray is
  used for object properties as in previous releases. Moving forward all methods used to
  enumerate, query, and sort objects return an instance of a new class `RLMResults`. This
  change was made to support diverging apis and the future addition of change notifications
  for queries.
* The api for migrations has changed. You now call `setSchemaVersion:withMigrationBlock:` to
  register a global migration block and associated version. This block is applied to Realms as
  needed when opened for Realms at a previous version. The block can be applied manually if
  desired by calling `migrateRealmAtPath:`.
* `arraySortedByProperty:ascending:` was renamed to `sortedResultsUsingProperty:ascending`
* `addObjectsFromArray:` on both `RLMRealm` and `RLMArray` has been renamed to `addObjects:`
  and now accepts any container class which implements `NSFastEnumeration`
* Building with Swift support now requires Xcode 6.1

### Enhancements

* Add support for sorting `RLMArray`s by multiple columns with `sortedResultsUsingDescriptors:`
* Added method `deleteAllObjects` on `RLMRealm` to clear a Realm.
* Added method `createObject:withObject:` on `RLMMigration` which allows object creation during migrations.
* Added method `deleteObject:` on `RLMMigration` which allows object deletion during migrations.
* Updating to core library version 0.85.0.
* Implement `objectsWhere:` and `objectsWithPredicate:` for array properties.
* Add `cancelWriteTransaction` to revert all changes made in a write transaction and end the transaction.
* Make creating `RLMRealm` instances on background threads when an instance
  exists on another thread take a fifth of the time.
* Support for partial updates when calling `createOrUpdateWithObject:` and `addOrUpdateObject:`
* Re-enable Swift support on OS X

### Bugfixes

* Fix exceptions when trying to set `RLMObject` properties after rearranging
  the properties in a `RLMObject` subclass.
* Fix crash on IN query with several thousand items.
* Fix crash when querying indexed `NSString` properties.
* Fixed an issue which prevented in-memory Realms from being used accross multiple threads.
* Preserve the sort order when querying a sorted `RLMResults`.
* Fixed an issue with migrations where if a Realm file is deleted after a Realm is initialized,
  the newly created Realm can be initialized with an incorrect schema version.
* Fix crash in `RLMSuperSet` when assigning to a `RLMArray` property on a standalone object.
* Add an error message when the protocol for an `RLMArray` property is not a
  valid object type.
* Add an error message when an `RLMObject` subclass is defined nested within
  another Swift class.

0.86.3 Release notes (2014-10-09)
=============================================================

### Enhancements

* Add support for != in queries on object relationships.

### Bugfixes

* Re-adding an object to its Realm no longer throws an exception and is now a no-op
  (as it was previously).
* Fix another bug which would sometimes result in subclassing RLMObject
  subclasses not working.

0.86.2 Release notes (2014-10-06)
=============================================================

### Bugfixes

* Fixed issues with packaging "Realm Browser.app" for release.

0.86.1 Release notes (2014-10-03)
=============================================================

### Bugfixes

* Fix a bug which would sometimes result in subclassing RLMObject subclasses
  not working.

0.86.0 Release notes (2014-10-03)
=============================================================

### API breaking changes

* Xcode 6 is now supported from the main Xcode project `Realm.xcodeproj`.
  Xcode 5 is no longer supported.

### Enhancements

* Support subclassing RLMObject models. Although you can now persist subclasses,
  polymorphic behavior is not supported (i.e. setting a property to an
  instance of its subclass).
* Add support for sorting RLMArray properties.
* Speed up inserting objects with `addObject:` by ~20%.
* `readonly` properties are automatically ignored rather than having to be
  added to `ignoredProperties`.
* Updating to core library version 0.83.1.
* Return "[deleted object]" rather than throwing an exception when
  `-description` is called on a deleted RLMObject.
* Significantly improve performance of very large queries.
* Allow passing any enumerable to IN clauses rather than just NSArray.
* Add `objectForPrimaryKey:` and `objectInRealm:forPrimaryKey:` convenience
  methods to fetch an object by primary key.

### Bugfixes

* Fix error about not being able to persist property 'hash' with incompatible
  type when building for devices with Xcode 6.
* Fix spurious notifications of new versions of Realm.
* Fix for updating nested objects where some types do not have primary keys.
* Fix for inserting objects from JSON with NSNull values when default values
  should be used.
* Trying to add a persisted RLMObject to a different Realm now throws an
  exception rather than creating an uninitialized object.
* Fix validation errors when using IN on array properties.
* Fix errors when an IN clause has zero items.
* Fix for chained queries ignoring all but the last query's conditions.

0.85.0 Release notes (2014-09-15)
=============================================================

### API breaking changes

* Notifications for a refresh being needed (when autorefresh is off) now send
  the notification type RLMRealmRefreshRequiredNotification rather than
  RLMRealmDidChangeNotification.

### Enhancements

* Updating to core library version 0.83.0.
* Support for primary key properties (for int and string columns). Declaring a property
  to be the primary key ensures uniqueness for that property for all objects of a given type.
  At the moment indexes on primary keys are not yet supported but this will be added in a future
  release.
* Added methods to update or insert (upsert) for objects with primary keys defined.
* `[RLMObject initWithObject:]` and `[RLMObject createInRealmWithObject:]` now support
  any object type with kvc properties.
* The Swift support has been reworked to work around Swift not being supported
  in Frameworks on iOS 7.
* Improve performance when getting the count of items matching a query but not
  reading any of the objects in the results.
* Add a return value to `-[RLMRealm refresh]` that indicates whether or not
  there was anything to refresh.
* Add the class name to the error message when an RLMObject is missing a value
  for a property without a default.
* Add support for opening Realms in read-only mode.
* Add an automatic check for updates when using Realm in a simulator (the
  checker code is not compiled into device builds). This can be disabled by
  setting the REALM_DISABLE_UPDATE_CHECKER environment variable to any value.
* Add support for Int16 and Int64 properties in Swift classes.

### Bugfixes

* Realm change notifications when beginning a write transaction are now sent
  after updating rather than before, to match refresh.
* `-isEqual:` now uses the default `NSObject` implementation unless a primary key
  is specified for an RLMObject. When a primary key is specified, `-isEqual:` calls
  `-isEqualToObject:` and a corresponding implementation for `-hash` is also implemented.

0.84.0 Release notes (2014-08-28)
=============================================================

### API breaking changes

* The timer used to trigger notifications has been removed. Notifications are now
  only triggered by commits made in other threads, and can not currently be triggered
  by changes made by other processes. Interprocess notifications will be re-added in
  a future commit with an improved design.

### Enhancements

* Updating to core library version 0.82.2.
* Add property `deletedFromRealm` to RLMObject to indicate objects which have been deleted.
* Add support for the IN operator in predicates.
* Add support for the BETWEEN operator in link queries.
* Add support for multi-level link queries in predicates (e.g. `foo.bar.baz = 5`).
* Switch to building the SDK from source when using CocoaPods and add a
  Realm.Headers subspec for use in targets that should not link a copy of Realm
  (such as test targets).
* Allow unregistering from change notifications in the change notification
  handler block.
* Significant performance improvements when holding onto large numbers of RLMObjects.
* Realm-Xcode6.xcodeproj now only builds using Xcode6-Beta6.
* Improved performance during RLMArray iteration, especially when mutating
  contained objects.

### Bugfixes

* Fix crashes and assorted bugs when sorting or querying a RLMArray returned
  from a query.
* Notifications are no longer sent when initializing new RLMRealm instances on background
  threads.
* Handle object cycles in -[RLMObject description] and -[RLMArray description].
* Lowered the deployment target for the Xcode 6 projects and Swift examples to
  iOS 7.0, as they didn't actually require 8.0.
* Support setting model properties starting with the letter 'z'
* Fixed crashes that could result from switching between Debug and Relase
  builds of Realm.

0.83.0 Release notes (2014-08-13)
=============================================================

### API breaking changes

* Realm-Xcode6.xcodeproj now only builds using Xcode6-Beta5.
* Properties to be persisted in Swift classes must be explicitly declared as `dynamic`.
* Subclasses of RLMObject subclasses now throw an exception on startup, rather
  than when added to a Realm.

### Enhancements

* Add support for querying for nil object properties.
* Improve error message when specifying invalid literals when creating or
  initializing RLMObjects.
* Throw an exception when an RLMObject is used from the incorrect thread rather
  than crashing in confusing ways.
* Speed up RLMRealm instantiation and array property iteration.
* Allow array and objection relation properties to be missing or null when
  creating a RLMObject from a NSDictionary.

### Bugfixes

* Fixed a memory leak when querying for objects.
* Fixed initializing array properties on standalone Swift RLMObject subclasses.
* Fix for queries on 64bit integers.

0.82.0 Release notes (2014-08-05)
=============================================================

### API breaking changes

* Realm-Xcode6.xcodeproj now only builds using Xcode6-Beta4.

### Enhancements

* Updating to core library version 0.80.5.
* Now support disabling the `autorefresh` property on RLMRealm instances.
* Building Realm-Xcode6 for iOS now builds a universal framework for Simulator & Device.
* Using NSNumber properties (unsupported) now throws a more informative exception.
* Added `[RLMRealm defaultRealmPath]`
* Proper implementation for [RLMArray indexOfObjectWhere:]
* The default Realm path on OS X is now ~/Library/Application Support/[bundle
  identifier]/default.realm rather than ~/Documents
* We now check that the correct framework (ios or osx) is used at compile time.

### Bugfixes

* Fixed rapid growth of the realm file size.
* Fixed a bug which could cause a crash during RLMArray destruction after a query.
* Fixed bug related to querying on float properties: `floatProperty = 1.7` now works.
* Fixed potential bug related to the handling of array properties (RLMArray).
* Fixed bug where array properties accessed the wrong property.
* Fixed bug that prevented objects with custom getters to be added to a Realm.
* Fixed a bug where initializing a standalone object with an array literal would
  trigger an exception.
* Clarified exception messages when using unsupported NSPredicate operators.
* Clarified exception messages when using unsupported property types on RLMObject subclasses.
* Fixed a memory leak when breaking out of a for-in loop on RLMArray.
* Fixed a memory leak when removing objects from a RLMArray property.
* Fixed a memory leak when querying for objects.


0.81.0 Release notes (2014-07-22)
=============================================================

### API breaking changes

* None.

### Enhancements

* Updating to core library version 0.80.3.
* Added support for basic querying of RLMObject and RLMArray properties (one-to-one and one-to-many relationships).
  e.g. `[Person objectsWhere:@"dog.name == 'Alfonso'"]` or `[Person objectsWhere:@"ANY dogs.name == 'Alfonso'"]`
  Supports all normal operators for numeric and date types. Does not support NSData properties or `BEGINSWITH`, `ENDSWITH`, `CONTAINS`
  and other options for string properties.
* Added support for querying for object equality in RLMObject and RLMArray properties (one-to-one and one-to-many relationships).
  e.g. `[Person objectsWhere:@"dog == %@", myDog]` `[Person objectsWhere:@"ANY dogs == %@", myDog]` `[Person objectsWhere:@"ANY friends.dog == %@", dog]`
  Only supports comparing objects for equality (i.e. ==)
* Added a helper method to RLMRealm to perform a block inside a transaction.
* OSX framework now supported in CocoaPods.

### Bugfixes

* Fixed Unicode support in property names and string contents (Chinese, Russian, etc.). Closing #612 and #604.
* Fixed bugs related to migration when properties are removed.
* Fixed keyed subscripting for standalone RLMObjects.
* Fixed bug related to double clicking on a .realm file to launch the Realm Browser (thanks to Dean Moore).


0.80.0 Release notes (2014-07-15)
=============================================================

### API breaking changes

* Rename migration methods to -migrateDefaultRealmWithBlock: and -migrateRealmAtPath:withBlock:
* Moved Realm specific query methods from RLMRealm to class methods on RLMObject (-allObjects: to +allObjectsInRealm: ect.)

### Enhancements

* Added +createInDefaultRealmWithObject: method to RLMObject.
* Added support for array and object literals when calling -createWithObject: and -initWithObject: variants.
* Added method -deleteObjects: to batch delete objects from a Realm
* Support for defining RLMObject models entirely in Swift (experimental, see known issues).
* RLMArrays in Swift support Sequence-style enumeration (for obj in array).
* Implemented -indexOfObject: for RLMArray

### Known Issues for Swift-defined models

* Properties other than String, NSData and NSDate require a default value in the model. This can be an empty (but typed) array for array properties.
* The previous caveat also implies that not all models defined in Objective-C can be used for object properties. Only Objective-C models with only implicit (i.e. primitives) or explicit default values can be used. However, any Objective-C model object can be used in a Swift array property.
* Array property accessors don't work until its parent object has been added to a realm.
* Realm-Bridging-Header.h is temporarily exposed as a public header. This is temporary and will be private again once rdar://17633863 is fixed.
* Does not leverage Swift generics and still uses RLM-prefix everywhere. This is coming in #549.


0.22.0 Release notes
=============================================================

### API breaking changes

* Rename schemaForObject: to schemaForClassName: on RLMSchema
* Removed -objects:where: and -objects:orderedBy:where: from RLMRealm
* Removed -indexOfObjectWhere:, -objectsWhere: and -objectsOrderedBy:where: from RLMArray
* Removed +objectsWhere: and +objectsOrderedBy:where: from RLMObject

### Enhancements

* New Xcode 6 project for experimental swift support.
* New Realm Editor app for reading and editing Realm db files.
* Added support for migrations.
* Added support for RLMArray properties on objects.
* Added support for creating in-memory default Realm.
* Added -objectsWithClassName:predicateFormat: and -objectsWithClassName:predicate: to RLMRealm
* Added -indexOfObjectWithPredicateFormat:, -indexOfObjectWithPredicate:, -objectsWithPredicateFormat:, -objectsWithPredi
* Added +objectsWithPredicateFormat: and +objectsWithPredicate: to RLMObject
* Now allows predicates comparing two object properties of the same type.


0.20.0 Release notes (2014-05-28)
=============================================================

Completely rewritten to be much more object oriented.

### API breaking changes

* Everything

### Enhancements

* None.

### Bugfixes

* None.


0.11.0 Release notes (not released)
=============================================================

The Objective-C API has been updated and your code will break!

### API breaking changes

* `RLMTable` objects can only be created with an `RLMRealm` object.
* Renamed `RLMContext` to `RLMTransactionManager`
* Renamed `RLMContextDidChangeNotification` to `RLMRealmDidChangeNotification`
* Renamed `contextWithDefaultPersistence` to `managerForDefaultRealm`
* Renamed `contextPersistedAtPath:` to `managerForRealmWithPath:`
* Renamed `realmWithDefaultPersistence` to `defaultRealm`
* Renamed `realmWithDefaultPersistenceAndInitBlock` to `defaultRealmWithInitBlock`
* Renamed `find:` to `firstWhere:`
* Renamed `where:` to `allWhere:`
* Renamed `where:orderBy:` to `allWhere:orderBy:`

### Enhancements

* Added `countWhere:` on `RLMTable`
* Added `sumOfColumn:where:` on `RLMTable`
* Added `averageOfColumn:where:` on `RLMTable`
* Added `minOfProperty:where:` on `RLMTable`
* Added `maxOfProperty:where:` on `RLMTable`
* Added `toJSONString` on `RLMRealm`, `RLMTable` and `RLMView`
* Added support for `NOT` operator in predicates
* Added support for default values
* Added validation support in `createInRealm:withObject:`

### Bugfixes

* None.


0.10.0 Release notes (2014-04-23)
=============================================================

TightDB is now Realm! The Objective-C API has been updated
and your code will break!

### API breaking changes

* All references to TightDB have been changed to Realm.
* All prefixes changed from `TDB` to `RLM`.
* `TDBTransaction` and `TDBSmartContext` have merged into `RLMRealm`.
* Write transactions now take an optional rollback parameter (rather than needing to return a boolean).
* `addColumnWithName:` and variant methods now return the index of the newly created column if successful, `NSNotFound` otherwise.

### Enhancements

* `createTableWithName:columns:` has been added to `RLMRealm`.
* Added keyed subscripting for RLMTable's first column if column is of type RLMPropertyTypeString.
* `setRow:atIndex:` has been added to `RLMTable`.
* `RLMRealm` constructors now have variants that take an writable initialization block
* New object interface - tables created/retrieved using `tableWithName:objectClass:` return custom objects

### Bugfixes

* None.


0.6.0 Release notes (2014-04-11)
=============================================================

### API breaking changes

* `contextWithPersistenceToFile:error:` renamed to `contextPersistedAtPath:error:` in `TDBContext`
* `readWithBlock:` renamed to `readUsingBlock:` in `TDBContext`
* `writeWithBlock:error:` renamed to `writeUsingBlock:error:` in `TDBContext`
* `readTable:withBlock:` renamed to `readTable:usingBlock:` in `TDBContext`
* `writeTable:withBlock:error:` renamed to `writeTable:usingBlock:error:` in `TDBContext`
* `findFirstRow` renamed to `indexOfFirstMatchingRow` on `TDBQuery`.
* `findFirstRowFromIndex:` renamed to `indexOfFirstMatchingRowFromIndex:` on `TDBQuery`.
* Return `NSNotFound` instead of -1 when appropriate.
* Renamed `castClass` to `castToTytpedTableClass` on `TDBTable`.
* `removeAllRows`, `removeRowAtIndex`, `removeLastRow`, `addRow` and `insertRow` methods
  on table now return void instead of BOOL.

### Enhancements
* A `TDBTable` can now be queried using `where:` and `where:orderBy:` taking
  `NSPredicate` and `NSSortDescriptor` as arguments.
* Added `find:` method on `TDBTable` to find first row matching predicate.
* `contextWithDefaultPersistence` class method added to `TDBContext`. Will create a context persisted
  to a file in app/documents folder.
* `renameColumnWithIndex:to:` has been added to `TDBTable`.
* `distinctValuesInColumnWithIndex` has been added to `TDBTable`.
* `dateIsBetween::`, `doubleIsBetween::`, `floatIsBetween::` and `intIsBetween::`
  have been added to `TDBQuery`.
* Column names in Typed Tables can begin with non-capital letters too. The generated `addX`
  selector can look odd. For example, a table with one column with name `age`,
  appending a new row will look like `[table addage:7]`.
* Mixed typed values are better validated when rows are added, inserted,
  or modified as object literals.
* `addRow`, `insertRow`, and row updates can be done using objects
   derived from `NSObject`.
* `where` has been added to `TDBView`and `TDBViewProtocol`.
* Adding support for "smart" contexts (`TDBSmartContext`).

### Bugfixes

* Modifications of a `TDBView` and `TDBQuery` now throw an exception in a readtransaction.


0.5.0 Release notes (2014-04-02)
=============================================================

The Objective-C API has been updated and your code will break!
Of notable changes a fast interface has been added.
This interface includes specific methods to get and set values into Tightdb.
To use these methods import `<Tightdb/TightdbFast.h>`.

### API breaking changes

* `getTableWithName:` renamed to `tableWithName:` in `TDBTransaction`.
* `addColumnWithName:andType:` renamed to `addColumnWithName:type:` in `TDBTable`.
* `columnTypeOfColumn:` renamed to `columnTypeOfColumnWithIndex` in `TDBTable`.
* `columnNameOfColumn:` renamed to `nameOfColumnWithIndex:` in `TDBTable`.
* `addColumnWithName:andType:` renamed to `addColumnWithName:type:` in `TDBDescriptor`.
* Fast getters and setters moved from `TDBRow.h` to `TDBRowFast.h`.

### Enhancements

* Added `minDateInColumnWithIndex` and `maxDateInColumnWithIndex` to `TDBQuery`.
* Transactions can now be started directly on named tables.
* You can create dynamic tables with initial schema.
* `TDBTable` and `TDBView` now have a shared protocol so they can easier be used interchangeably.

### Bugfixes

* Fixed bug in 64 bit iOS when inserting BOOL as NSNumber.


0.4.0 Release notes (2014-03-26)
=============================================================

### API breaking changes

* Typed interface Cursor has now been renamed to Row.
* TDBGroup has been renamed to TDBTransaction.
* Header files are renamed so names match class names.
* Underscore (_) removed from generated typed table classes.
* TDBBinary has been removed; use NSData instead.
* Underscope (_) removed from generated typed table classes.
* Constructor for TDBContext has been renamed to contextWithPersistenceToFile:
* Table findFirstRow and min/max/sum/avg operations has been hidden.
* Table.appendRow has been renamed to addRow.
* getOrCreateTable on Transaction has been removed.
* set*:inColumnWithIndex:atRowIndex: methods have been prefixed with TDB
* *:inColumnWithIndex:atRowIndex: methods have been prefixed with TDB
* addEmptyRow on table has been removed. Use [table addRow:nil] instead.
* TDBMixed removed. Use id and NSObject instead.
* insertEmptyRow has been removed from table. Use insertRow:nil atIndex:index instead.

#### Enhancements

* Added firstRow, lastRow selectors on view.
* firstRow and lastRow on table now return nil if table is empty.
* getTableWithName selector added on group.
* getting and creating table methods on group no longer take error argument.
* [TDBQuery parent] and [TDBQuery subtable:] selectors now return self.
* createTable method added on Transaction. Throws exception if table with same name already exists.
* Experimental support for pinning transactions on Context.
* TDBView now has support for object subscripting.

### Bugfixes

* None.


0.3.0 Release notes (2014-03-14)
=============================================================

The Objective-C API has been updated and your code will break!

### API breaking changes

* Most selectors have been renamed in the binding!
* Prepend TDB-prefix on all classes and types.

### Enhancements

* Return types and parameters changed from size_t to NSUInteger.
* Adding setObject to TightdbTable (t[2] = @[@1, @"Hello"] is possible).
* Adding insertRow to TightdbTable.
* Extending appendRow to accept NSDictionary.

### Bugfixes

* None.


0.2.0 Release notes (2014-03-07)
=============================================================

The Objective-C API has been updated and your code will break!

### API breaking changes

* addRow renamed to addEmptyRow

### Enhancements

* Adding a simple class for version numbering.
* Adding get-version and set-version targets to build.sh.
* tableview now supports sort on column with column type bool, date and int
* tableview has method for checking the column type of a specified column
* tableview has method for getting the number of columns
* Adding methods getVersion, getCoreVersion and isAtLeast.
* Adding appendRow to TightdbTable.
* Adding object subscripting.
* Adding method removeColumn on table.

### Bugfixes

* None.



*Template follows:*

x.x.x Release notes (yyyy-MM-dd)
=============================================================

?? summary

### API breaking changes

* None.

### Enhancements

* None.

### Bugfixes

* None.
