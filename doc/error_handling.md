Obj-C Error Management Patterns
===============================

1a. Pass-back with optional error paramater
-------------------------------------------
    -(BOOL)doSomething;
    -(BOOL)doSomethingWithError(NSError **);

    -(MyValue *)doSomething;
    -(MyValue *)doSomethingWithError(NSError **);



1b. Pass-back with forced error paramater
-------------------------------------------
    -(BOOL)doSomethingWithError(NSError **);





1c. Pass-back with forced error paramater
-------------------------------------------
    -(BOOL)doSomethingWithError(NSError **);


3. Check-state

2. Delegation (call-back)

