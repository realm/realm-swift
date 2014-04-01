/* @@Example: ex_objc_tableview_dynamic_intro @@ */
#import <Tightdb/Tightdb.h>

void ex_objc_tableview_dynamic_intro()
{
    /* Creates a new table dynamically. */
    TDBTable *table = [[TDBTable alloc] init];
    
    /* Add some columns dynamically */
    NSUInteger const NAME = [table addColumnWithName:@"Name" type:TDBStringType];
    NSUInteger const AGE  = [table addColumnWithName:@"Age" type:TDBIntType];
    NSUInteger const HIRED= [table addColumnWithName:@"Hired" type:TDBBoolType];
    
    /* Add people (rows). */
    [table addRow:@[@"Joe", @23, @YES]];
    [table addRow:@[@"Simon", @32, @YES]];
    [table addRow:@[@"Steve",@12, @NO]];
    [table addRow:@[@"Nick", @59, @YES]];
    
    /* Set up a query to search for employees. */
    TDBQuery *q =  [[[[table where]
                        intIsGreaterThanOrEqualTo:30 inColumnWithIndex:AGE]
                        intIsLessThanOrEqualTo:60 inColumnWithIndex:AGE ]
                        boolIsEqualTo:YES inColumnWithIndex:HIRED];
    
    /* Create a (table)view with the rows matching the query */
    TDBView *view = [q findAllRows];
    
    /* Iterate over the matching rows */
    for (TDBRow *row in view) {
        NSLog(@"With fast enumerator. Name: %@",row[NAME]);
    }
    
    /* Take a row at index one in the view. */
    /* Note: the index of this row is different in the underlaying table. */
    
    TDBRow *row = [view rowAtIndex:1];
    if (row != nil)
        NSLog(@"With fixed index. Name: %@",row[NAME]);
    
    /* Try to get a row with an out-of-bounds index. */
    TDBRow *row2 = [view rowAtIndex:view.rowCount];
    if (row2 != nil)
        NSLog(@"Should not get here!");
}
/* @@EndExample@@ */
