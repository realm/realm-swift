Objective-C Typed API: Capitalizaiton in signature names
========================================================

This document describes issues and solutions related signature naming in the typed Objective-C interface. The overall challenge is that classes are defined with macros, which cannot modify case (capitalization) in the column names the user supplies in the table definition. 

Background
----------
- For consistency across languages, column names are recommended to be all lower case. However column names are in general required to be case sensitive.
- For manipulating rows in table, the user can get a curser via the table, or use specific methods in table, which accesses several columns at once. The curser contains properties for accessing columns.
- When building queries, the user can refer to columns using assessors in a query.
- The typed interface uses macros to generate the getters and setters in which the columns names are referred to. This provides strong typing and increased usability.

Examples #1 (adding a row and setting multiple values with a single setter):
----------------------------------------------------------------------------

    Table: Name, String
           Age,  Int
        
    [table addName:@”Bob” Age:10];

    Table: name, String
           age,  Int

    [table addname:@”Bob” age:10];

Problem #1: The latter signature should in Objective-C notation have been “addName…..” with capital “N”. However, this is impossible to implement with macros.

Decision #1: Due to above problem, we decided to avoid prefixes before column names. It apparently has the direct consequence that we cannot create methods, which sets multiple values at once and where the first parameter is a column (how should the signature be named?).

Decision #2:  Based on decision #1 we decided to only use (overridden) property getters/setters for accessing and only set one property at the time. 


Examples #2 (using property getters/setters):
---------------------------------------------

    Table: name, String
           age,  Int
    
    Curser *c = [table add];    // adds a row and returns the curser for it
    [c setAge]                  // synthesized setter
    [c setage]                  // custom setter
         
Problem #2: At the time of writing we generate a custom setter setage, which accesses the database. On top of that setAge is automatically synthesized and does not access the database – only the property named age (not wanted).

Problem #3: We can disable the synthesised setter, but we cannot create a custom setter with capital A in the name.

Decision #3: Only allow dot notation. Example code below. The getter and setter methods have names, which are so weird that they will never be called directly – only via the property. 

    @property (getter = _private_age, setter = _private_setage:) NSString *age;

    -(NSString*)_private_age { 
        return @"Getting a value from the database";
    }

    -(void)_private_setage:(NSString *)age {
        NSLog(@"Setting a value in the database");
    }

    int main()
    {
        @autoreleasepool {
            Person *p = [[Person alloc]init];
            p.age = @"14";
            NSLog(@"The value of age: %@", p.age);
        }
    }

