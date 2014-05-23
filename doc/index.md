<img alt="Realm Logo" src="docs/realm.png"/>

Realm is a fast embedded database that integrates transparently into Objective-C. It provides the full benefits of a database, but with a much lower memory footprint and higher performance than native data structures.


## Defining a Data Model

Realm data models are defined using traditional `NSObject` classes with `@properties`. Just subclass `RLMObject` to create your Realm data model objects. You can add your `RLMObject` objects to an `RLMRealm` object.

	@interface DemoObject : RLMObject

	@property (nonatomic, copy)   NSString *title;
	@property (nonatomic, strong) NSDate   *date;

	@end

	@implementation DemoObject
	// none needed
	@end

	// Generate a matching RLMTable class called “DemoTable” for DemoObject
	RLM_DEFINE_TABLE_TYPE_FOR_OBJECT_TYPE(DemoTable, RLMDemoObject)
	// This will provide automatic casting when accessing objects in tables of that class
	// as well as other syntaxic conveniences

See the [RLMObject Protocol](Protocols/RLMObject.html) for more details.


## Reading and Writing Objects

The `RLMRealm` class is responsible for reading and writing data. You can initialize an `RLMRealm` instance that persists to the default file (`<Application_Home>/Documents/default.realm`):

	RLMRealm *realm = [RLMRealm defaultRealm];

or which persists to a file at a provided path:

	RLMRealm *realm = [RLMRealm realmWithPath:filePath];

You can write data in Realm using write transactions. You begin and end a write transaction as follows:

    // Get the default Realm
    RLMRealm *realm = [RLMRealm defaultRealm];

    // Begin a transaction
    [realm beginWriteTransaction];

    // Add a new object
    DemoObject *obj = [DemoObject createInRealm:realm withObject:@{@"title" : @"my title", @"date" : [NSDate date]}];

    // Commit the transaction
    [realm commitWriteTransaction];

See `RLMRealm` and `RLMObject` for more details.

## Querying

You can simply apply `NSPredicates` to an `RLMRealm` to return an `RLMArray` containing a filtered view of your objects.

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"date < %@ && title contains %@", [NSDate date], @"00"];
    RLMArray objects = [realm objects:DemoObject.class where:predicate];

    for (RLMDemoObject *object in objects) {
        NSLog(@"title: %@\ndate: %@", object.title, object.date);
    }

See `RLMRealm` and `RLMObject` for more details on possible queries.


## Notifications

The auto-updating Realm will send out notifications every time the underlying Realm is updated. These notifications can be observed by registering a block:

    // Observe Realm Notifications
    [realm addNotification:^(NSString *note, RLMRealm * realm) {
        [myViewController updateUI];
    }];

## Background Operations

Realm can be very efficient when writing large amounts of data by batching together multiple writes within a single transaction. Transactions can also be performed in the background using Grand Central Dispatch to avoid blocking the main thread. RLMRealm objects are not thread safe and cannot be shared across threads, so you must get an RLMRealm instance in each thread/dispatch_queue in which you want to read or write. Here's an example of inserting a million objects in a background queue:

    dispatch_async(queue, ^{
        // Get realm and table instances for this thread
        RLMRealm *realm = [RLMRealm defaultRealm];
        for (NSInteger idx1 = 0; idx1 < 1000; idx1++) {
            // Break up the writing blocks into smaller portions by starting a new transaction
            [realm beginWriteTransaction];
            for (NSInteger idx2 = 0; idx2 < 1000; idx2++) {
                // Add row via dictionary. Order is ignored.
                [DemoObject createInRealm:realm withObject:@{@"title": [self randomString], @"date": [self randomDate]}];
            }

            // Commit the write transaction to make this data available to other threads
            [realm commitWriteTransaction];
	}
    });


See `RLMRealm` for more details.


## Next Steps

You can download a full end-to-end sample [here](http://realm.io/downloads/sample.zip).

Happy hacking! You can always talk to a live human developer at [support@realm.io](mailto:support@realm.io)
