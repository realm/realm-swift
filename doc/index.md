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


## Writing & Reading Objects

The RLMTransactionManager class is responsible for read & write transactions. You can initialize one persisting to the default file (`<Application_Home>/Documents/default.realm`) like this:

	RLMTransactionManager *manager = [RLMTransactionManager managerForDefaultRealm];

You can use the transaction manager to extract a Realm which is a representation of all the data stored in the file. An RLMRealm contains RLMTable(s), which in turn contain your objects (RLMRow subclasses).

This example accesses the Realm in write mode via a Context and adds a DemoObject via its properties:

	[manager writeUsingBlock:^(RLMRealm *realm) {
			// Now we can create a table, reusing the class defined
			// by the macro in the previous sample
	        DemoTable *table = [DemoTable tableInRealm:realm named:@"mytable"];

	        // Add a new row
	        [table addRow:@{@"title": @"my title",
	                         @"date": [NSDate date]}];
	 }];

You can use a Transaction Manager to perform (lock-free) read transactions as well.  
This example accesses the Realm in read-only mode via a Transaction Manager, opens a table consisting of DemoObjects and uses fast enumeration to iterate through all objects in the table and output them.

    [manager readUsingBlock:^(RLMRealm *realm) {
        DemoTable *table = [DemoTable tableInRealm:realm named:@"mytable"];
        for (RLMDemoObject *object in table) {
            NSLog(@"title: %@\ndate: %@", object.title, object.date);
        }
    }];

See RLMTransactionManager, RLMRealm and RLMTable for more details.

## Querying

You can simply apply NSPredicates to an RLMTable to return an RLMView containing a filtered view of your objects.

	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"date < %@ && title contains %@",
															  [NSDate date], @"00"];
	RLMView *view = [self.table where:predicate];
	for (RLMDemoObject *object in view) {
	    NSLog(@"title: %@\ndate: %@", object.title, object.date);
	}

See RLMTable for more details on possible queries.



## Transactionless Reads (main thread only!)

For ease of development when accessing values on the main thread (for example for UI purposes), we allow reads to be performed without an RLMContext or transaction block, but **only when the call is made from the main thread**.

	// No RLMTransactionManager needed!
	RLMRealm *realm = [RLMRealm realmWithDefaultPersistence];
	DemoTable *table = [DemoTable tableInRealm:realm named:@"mytable"];
	DemoObject *object = [DemoObject table.firstRow];
	NSLog(object.title);

Again, this only works on the main thread, and only for reads. You will still need to wrap your calls in an RLMContext with `writeUsingBlock:`
to perform writes on the main thread.

## Notifications

The auto-updating Realm will send out notifications every time the underlying Realm is updated. These notifications can be observed through `NSNotificationCenter`:

	// Observe Realm Notifications
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(realmDidChange)
	                                             name:RLMDidChangeNotification
	                                           object:nil];

## Background Operations

Realm can be very efficient when writing large amounts of data by batching together multiple writes within a single transaction. Transactions can also be performed in the background using Grand Central Dispatch to avoid blocking the main thread.  
Here's an example of inserting a million objects in a background queue:

	dispatch_async(queue, ^{
	    RLMTransactionManager *manager = [RLMTransactionManager managerForDefaultRealm];
	    for (NSInteger idx1 = 0; idx1 < 1000; idx1++) {
	        // Break up the writing blocks into smaller portions
	        [manager writeUsingBlock:^(RLMRealm *realm) {
	            RLMTable *table = [realm tableWithName:@"DemoTable" objectClass:[RLMDemoObject class]];
	            for (NSInteger idx2 = 0; idx2 < 1000; idx2++) {
	                // Add row via dictionary. Order is ignored.
	                [table addRow:@{@"title": [self randomString], @"date": [self randomDate]}];
	            }
	        }];
	    }
	});


See RLMTable for more details.


## Next Steps

You can download a full end-to-end sample [here](http://realm.io/downloads/sample.zip).

Happy hacking! You can always talk to a live human developer at [support@realm.io](mailto:support@realm.io)
