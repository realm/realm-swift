Obj-C Error Management Patterns
===============================

1a) Pass-back with optional error paramater
-------------------------------------------
    -(BOOL)doSomething;
    -(BOOL)doSomethingWithError(NSError **);
    -(NSObject *)doSomething;
    -(NSObject *)doSomethingWithError(NSError **);

GOOD FOR: Follows the conventional error handling pattern in Obj-C.
BAD FOR: All methods which can fail (most) must be duplicated.
BAD FOR: Not compatible with assignment such as..

	cursor.Name = @"Jack";   // can't check the return value

1b) Pass-back with forced error paramater
-------------------------------------------
    -(BOOL)doSomethingWithError(NSError **);
    -(NSObject *)doSomethingWithError(NSError **);

GOOD FOR: When we want to force the client to handle errors.
    
    (TightdbGroup *)groupWithFilename:(NSString *)filename error:(NSError **)error;
    -(BOOL)write:(NSString *)filePath error:(NSError *__autoreleasing *)error;

1c) Pass-back without error paramater
-------------------------------------------
    -(BOOL)doSomething;
    -(NSObject *)doSomething;

GOOD FOR: When additional error information is not needed.

	(example missing)

2) Check-state
--------------
Table keep internal error state. Clients can ask for status ad-hoc.

	@interface
	-(BOOL)didFail;
	-(NSError *)error;
	@end

GOOD FOR: Avoids duplicate methods.
GOOD FOR: Supports assignments in typed API (see "=" example above).
GOOD FOR: Groups could refuse to persist tables that have failed.

BAD FOR: Delayed feedback. May be difficult to recover (if needed).
BAD FOR: Requires more proactive client code.
BAD FOR: This is custom made, may have implications we can't see now.


3) Delegation (call-back)
-------------------------
    @interface
    @property (nonatomic, assign) id <TightdbErrorDelegate> delegate;
    @end

    @protocol TightdbErrorDelegate <NSObject>
    @optional
    -(BOOL)didFailWithError(NSError *) inTable:(TightdbTable *);
    @end


next steps.....
---------------

- fill in more examples
- decide what to use and when (could be a combination of several options)
