# Realm Objective-C Interface

Realm is a fast embedded database that integrates transparently into Objective-C. It provides the full benefits of a database, but with a much lower memory footprint and higher performance than native data structures.

Building an iOS app with Realm couldn't be simpler. This article will cover the core concepts.

## Main Classes

`RLMRealm`, `RLMTable` and `RLMTransactionManager` are the main classes you'll encounter while working with Realm.

## Defining a Data Model

Realm data models fully embrace Objective-C and are defined using traditional `NSObject` classes with `@properties`. Just subclass `RLMRow` to create your Realm data model objects:

```objc
@interface RLMDemoObject : RLMRow

@property (nonatomic, copy)   NSString *title;
@property (nonatomic, strong) NSDate   *date;

@end
```

See [Building a Data Model](#) for more advanced usage examples.

## RLMRealm

The `RLMRealm` class is the main way to interact with a realm. It's how tables are created and extracted:

```objc
self.realm = [RLMRealm realmWithDefaultPersistenceAndInitBlock:^(RLMRealm *realm) {
    // Create table if it doesn't exist
    if (realm.isEmpty) {
        [realm createTableWithName:kTableName objectClass:[RLMDemoObject class]];
    }
}];

self.table = [self.realm tableWithName:kTableName objectClass:[RLMDemoObject class]];
```

Realms are read-only and can only be created on the main thread, unless created through a transaction manager.

See the `RLMRealm` [documentation](#) for more details.

## Transaction Manager

The `RLMTransactionManager` class is responsible for all *write* transactions:

```objc
[[RLMContext contextWithDefaultPersistence] writeUsingBlock:^(RLMRealm *realm) {
    RLMTable *table = [realm tableWithName:kTableName objectClass:[RLMDemoObject class]];
    // Add row via array. Order matters.
    [table addRow:@[[self randomString], [self randomDate]]];
}];
```

as well as all *read* transactions performed outside the main thread:

```objc
dispatch_async(queue, ^{
    [[RLMContext contextWithDefaultPersistence] readUsingBlock:^(RLMRealm *realm) {
        RLMTable *table = [realm tableWithName:kTableName objectClass:[RLMDemoObject class]];
        for (RLMDemoObject *object in table) {
            NSLog(@"object: %@", object);
        }
    }];
});
```

These transactions are run on the current thread. As the previous example demonstrates, `RLMTable`s support fast enumeration.

See the `RLMTransactionManager` [documentation](#) for more details.

## Listening to Changes

Though Realm is extremely fast, it isn't instantaneous. Realm sends notifications to broadcast when a write transaction has completed. These notifications can be observed through the `NSNotificationCenter`:

```objc
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(realmContextDidChange)
                                             name:RLMContextDidChangeNotification
                                           object:nil];
```

## Background Operations

Inserting large amounts of data into your application has never been easier. Realm is designed to work with the tools you already know like Grand Central Dispatch and `NSOperationQueue`s. Here's an example importing a million objects while keeping an app responsive and still allowing high-priority writes on the main thread:

```objc
dispatch_async(queue, ^{
    RLMContext *ctx = [RLMContext contextWithDefaultPersistence];
    for (NSInteger idx1 = 0; idx1 < 1000; idx1++) {
        // Break up the writing blocks into smaller portions
        [ctx writeUsingBlock:^(RLMRealm *realm) {
            RLMTable *table = [realm tableWithName:@"table2" objectClass:[RLMDemoObject class]];
            for (NSInteger idx2 = 0; idx2 < 1000; idx2++) {
                // Add row via dictionary. Order is ignored.
                [table addRow:@{@"title": [self randomString], @"date": [self randomDate]}];
            }
        }];
    }
});
```

## Querying

With support for `NSPredicate`s and blazing fast queries, Realm's querying interface really shines.

```objc
NSPredicate *predicate = [NSPredicate predicateWithFormat:@"date < %@ && title contains %@", [NSDate date], @"00"];
RLMView *view = [self.table where:predicate];
for (RLMDemoObject *object in view) {
    NSLog(@"title: %@\ndate: %@", object.title, object.date);
}
```

See the `RLMTable` [documentation](#) for more information on what's possible with tables in Realm.

## Next Steps

This document just scratches the surface of what's possible with Realm. Here are some resources available for more information:

* [Realm Objective-C Documentation](#)
* [Realm Objective-C Tutorials](#)
* [Realm on GitHub](#)
* [Realm on StackOverflow](#)
* [support@realm.io](mailto:support@realm.io)
