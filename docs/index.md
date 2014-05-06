<img alt="Realm Logo" src="docs/realm.png"/>

Realm is a fast embedded database that integrates transparently into Objective-C. It provides the full benefits of a database, but with a much lower memory footprint and higher performance than native data structures.


## Defining a Data Model

Realm data models are defined using traditional `NSObject` classes with `@properties`. Just subclass RLMRow to create your Realm data model objects. You can then organize your RLMRow objects in RLMTables.

	@interface DemoObject : RLMRow

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

Please note that RLMRow objects can only be created when using `addRow:` on an RLMTable and cannot be instantiated on their own.

See the [RLMObject Protocol](Protocols/RLMObject.html) for more details.


## Reading and Writing Objects

The RLMRealm class is responsible for reading and writing data. You can initialize an RLMRealm instance that persists to the default file (`<Application_Home>/Documents/default.realm`):

	RLMRealm *realm = [RLMRealm defaultRealm];

or which persists to a file at a provided path:

	RLMRealm *realm = [RLMRealm realmWithPath:filePath];

An RLMRealm instance contains RLMTable(s), which in turn contain your objects (RLMRow subclasses). Tables and objects within can be read as follows: 

	RLMRealm *realm = [RLMRealm defaultRealm];
	DemoTable *table = [DemoTable tableInRealm:realm named:@"mytable"];
	DemoObject *object = [DemoObject table.firstRow];
	NSLog(object.title);

You can write data in Realm using write transactions. You begin and end a write transaction as follows:
	        
    // Get the default Realm and get or create a new table
    RLMRealm *realm = [RLMRealm defaultRealm];
    DemoTable *table = [DemoTable tableInRealm:realm named:@"mytable"];

    // Begin a transaction
    [realm beginWriteTransaction];
    
    // Add a new row
    [table addRow:@{@"title" : @"my title",
                    @"date"  : [NSDate date]}];

    // Commit the transaction
    [realm commitWriteTransaction];

See RLMRealm and RLMTable for more details.

## Querying

You can simply apply NSPredicates to an RLMTable to return an RLMView containing a filtered view of your objects.

	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"date < %@ && title contains %@",
															  [NSDate date], @"00"];
	RLMView *view = [self.table where:predicate];
	for (RLMDemoObject *object in view) {
	    NSLog(@"title: %@\ndate: %@", object.title, object.date);
	}

See RLMTable for more details on possible queries.


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
	    RLMTable *table = [realm tableWithName:@"DemoTable" objectClass:[RLMDemoObject class]];
	    for (NSInteger idx1 = 0; idx1 < 1000; idx1++) {
            // Break up the writing blocks into smaller portions by starting a new transaction
            [realm beginWriteTransaction];
            for (NSInteger idx2 = 0; idx2 < 1000; idx2++) {
                // Add row via dictionary. Order is ignored.
                [table addRow:@{@"title": [self randomString], @"date": [self randomDate]}];
            }

            // Commit the write transaction to make this data available to other threads
            [realm commitWriteTransaction];
	    }
	});


See RLMTable for more details.


## Next Steps

You can download a full end-to-end sample [here](http://realm.io/downloads/sample.zip).

Happy hacking! You can always talk to a live human developer at [support@realm.io](mailto:support@realm.io)
