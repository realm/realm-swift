<img alt="Realm Logo" src="docs/realm.png"/>

Realm is a fast embedded database that integrates transparently into Objective-C. It provides the full benefits of a database, but with a much lower memory footprint and higher performance than native data structures.


## Defining a Data Model

Realm data models fully embrace Objective-C and are defined using traditional `NSObject` classes with `@properties`. Just subclass RLMRow to create your Realm data model objects:

	@interface RLMDemoObject : RLMRow

	@property (nonatomic, copy)   NSString *title;
	@property (nonatomic, strong) NSDate   *date;

	@end

	@implementation RLMDemoObject
	// none needed
	@end

See the [RLMObject Protocol](Protocols/RLMObject.html) for more details.


## [RLMContext](Classes/RLMContext.html)

The RLMContext class is responsible for all write transactions:

	[[RLMContext contextWithDefaultPersistence] writeUsingBlock:^(RLMRealm *realm) {
	    RLMTable *table = [realm tableWithName:kTableName objectClass:[RLMDemoObject class]];
	    // Add row via array. Order matters.
	    [table addRow:@[[self randomString], [self randomDate]]];
	}];

… and read transactions:

    [[RLMContext contextWithDefaultPersistence] readUsingBlock:^(RLMRealm *realm) {
        RLMTable *table = [realm tableWithName:@"DemoTable" objectClass:[RLMDemoObject class]];
        for (RLMDemoObject *object in table) {
            NSLog(@"title: %@\ndate: %@", object.title, object.date);
        }
    }];

An RLMContext provides a realm on which to perform operations. These transactions are run on the current thread. As the previous example demonstrates, RLMTable supports fast enumeration.

See RLMContext for more details.


## RLMRealm

The RLMRealm class is the main way to interact with a realm. It's how tables are created and extracted. When creating a read-only realm on the main thread, the context becomes optional and transactions are then performed implicitly at run loop intervals. This greatly simplifies usage when reading to display information in the UI, for example.

	RLMRealm *realm = [RLMRealm realmWithDefaultPersistenceAndInitBlock:^(RLMRealm *realm) {
        // Create table if it doesn't exist
        if (realm.isEmpty) {
            [realm createTableWithName:@"DemoTable" objectClass:[RLMDemoObject class]];
        }
    }];
    
    RLMTable *table = [realm tableWithName:@"DemoTable" objectClass:[RLMDemoObject class]];

See the RLMRealm for more details.


## Listening to Changes

Though Realm is extremely fast, it isn't instantaneous. Realm sends notifications to broadcast when a write transaction has completed. These notifications can be observed through the `NSNotificationCenter`:

	// Observe Realm Notifications
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(realmContextDidChange)
	                                             name:RLMContextDidChangeNotification
	                                           object:nil];
## Background Operations

Inserting large amounts of data into your application has never been easier. Realm is designed to work with the tools you already know like Grand Central Dispatch and `NSOperationQueue`. Here's an example importing a million objects while keeping an app responsive and still allowing high-priority writes on the main thread:

	dispatch_async(queue, ^{
	    RLMContext *ctx = [RLMContext contextWithDefaultPersistence];
	    for (NSInteger idx1 = 0; idx1 < 1000; idx1++) {
	        // Break up the writing blocks into smaller portions
	        [ctx writeUsingBlock:^(RLMRealm *realm) {
	            RLMTable *table = [realm tableWithName:@"DemoTable" objectClass:[RLMDemoObject class]];
	            for (NSInteger idx2 = 0; idx2 < 1000; idx2++) {
	                // Add row via dictionary. Order is ignored.
	                [table addRow:@{@"title": [self randomString], @"date": [self randomDate]}];
	            }
	        }];
	    }
	});


## Querying

With support for `NSPredicate` and blazing fast performance, Realm's querying interface really shines.

	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"date < %@ && title contains %@", [NSDate date], @"00"];
	RLMView *view = [self.table where:predicate];
	for (RLMDemoObject *object in view) {
	    NSLog(@"title: %@\ndate: %@", object.title, object.date);
	}

See RLMTable for more details.


## Next Steps

You can download a full end-to-end sample [here](http://realm.io/downloads/sample.zip).

Happy hacking! You can always talk to a live human developer at [support@realm.io](mailto:support@realm.io)