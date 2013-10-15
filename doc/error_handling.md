Obj-C Error Management Patterns
===============================

1a) Pass-back with optional error paramater
-------------------------------------------
    -(BOOL)doSomething;
    -(BOOL)doSomethingWithError(NSError **);
    -(NSObject *)doSomething;
    -(NSObject *)doSomethingWithError(NSError **);



1b) Pass-back with forced error paramater
-------------------------------------------
    -(BOOL)doSomethingWithError(NSError **);
    -(NSObject *)doSomethingWithError(NSError **);

- When we want to force the client to handle error. For instance:
    
    (TightdbGroup *)groupWithFilename:(NSString *)filename error:(NSError **)error;



1c) Pass-back without error paramater
-------------------------------------------
    -(BOOL)doSomething;
    -(NSObject *)doSomething;



2) Check-state
--------------
	@interface
	-(BOOL)didFail;
	-(NSError *)error;
	@end



3) Delegation (call-back)
-------------------------
    @interface
    @property (nonatomic, assign) id <TightdbErrorDelegate> delegate;
    @end

    @protocol TightdbErrorDelegate <NSObject>
    @optional
    -(BOOL)didFailWithError(NSError *) inTable:(TightdbTable *);
    @end