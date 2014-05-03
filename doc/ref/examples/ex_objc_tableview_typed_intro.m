/* @@Example: ex_objc_tableview_typed_intro @@ */
#import <Realm/Realm.h>
#import "people.h"

/*
 The classes People, PeopleQuery, PeopleView, and PeopleRow are declared
 (interfaces are generated) in people.h as

 REALM_TABLE_DEF_3(People,
                     Name,  String,
                     Age,   Int,
                     Hired, Bool)

 and in people.m you must have

 REALM_TABLE_IMPL_3(People,
                      Name, String,
                      Age,  Int,
                      Hired, Bool)

 in order to generate the implementation of the classes.
*/

void ex_objc_tableview_typed_intro()
{
<<<<<<< HEAD
    [[RLMContext contextWithDefaultPersistence] writeUsingBlock:^(RLMRealm *realm) {
        /* Creates a new table of the type defined above. */
        People *table = [realm createTableWithName:@"Example" asTableClass:People.class];
        
        /* Adds rows to the table. */
        [table addRow:@{@"Name":@"Brian",  @"Age":@10, @"Hired":@NO}];
        [table addRow:@{@"Name":@"Sofie",  @"Age":@40, @"Hired":@YES}];
        [table addRow:@{@"Name":@"Sam",    @"Age":@76, @"Hired":@NO}];
        
        /* Get the result of a query in a table view. */
        PeopleView *view = [[[table where].Age columnIsGreaterThan:20] findAll];
        
        /* Iterate over the result in the table view. */
        for (PeopleRow *row in view) {
            NSLog(@"This person is over the age of 20: %@", row.Name);
        }
    }];
=======
    /* Creates a new table of the type defined above. */
    PeopleTable *table = [[PeopleTable alloc] init];
    
    /* Adds rows to the table. */
    [table addRow:@{@"Name":@"Brian",  @"Age":@10, @"Hired":@NO}];
    [table addRow:@{@"Name":@"Sofie",  @"Age":@40, @"Hired":@YES}];
    [table addRow:@{@"Name":@"Sam",    @"Age":@76, @"Hired":@NO}];
    
    /* Get the result of a query in a view. */
    RLMView *view = [table allWhere:@"Age > 20"];
    
    /* Iterate over the result in the table view. */
    for (RLMRow *row in view) {
        NSLog(@"This person is over the age of 20: %@", row[@"Name"]);
    }
>>>>>>> 0c5befb1d95840f3a70236a56bf1fa62ddce2eb3
}
/* @@EndExample@@ */
