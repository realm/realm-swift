//
//  tutorial.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import "RLMTestCase.h"

#import <realm/objc/Realm.h>
#import <realm/objc/RLMPrivateTableMacrosFast.h>

@interface RLMPerson2 : RLMRow

@property (nonatomic, copy)   NSString *name;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, assign) BOOL      hired;

@end

@implementation RLMPerson2
@end

RLM_TABLE_TYPE_FOR_OBJECT_TYPE(RLMPersonTable2, RLMPerson2);

@interface MACTestTutorial: RLMTestCase

@end

@implementation MACTestTutorial

- (void)testTutorial {
    //------------------------------------------------------
    NSLog(@"--- Creating tables ---");
    //------------------------------------------------------

    RLMRealm *manager = [self realmWithTestPath];
    
    [manager writeUsingBlock:^(RLMRealm *realm) {
        // Create new table in realm
        RLMPersonTable2 *table = [RLMPersonTable2 tableInRealm:realm named:@"table"];
        
        // Add some rows
        [table addRow:@[@"John", @20, @YES]];
        [table addRow:@[@"Mary", @21, @NO]];
        [table addRow:@[@"Lars", @21, @YES]];
        [table addRow:@[@"Phil", @43, @NO]];
        [table addRow:@[@"Anni", @54, @YES]];
        
        [table insertRow:@[@"Frank", @34, @YES] atIndex:2];
        
        // Getting the size of the table
        NSLog(@"PeopleTable Size: %lu - is %@.    [6 - not empty]", [table rowCount],
              table.rowCount == 0 ? @"empty" : @"not empty");

        //------------------------------------------------------
        NSLog(@"--- Working with individual rows ---");
        //------------------------------------------------------
        
        // Getting values
        NSString * name = table[5].name;   // => 'Anni'
        // Using a row
        RLMPerson2 *myRow = table[5];
        int64_t age = myRow.age;                           // => 54
        BOOL hired  = myRow.hired;                         // => true
        NSLog(@"%@ is %lld years old.", name, age);
        if (hired) NSLog(@"is hired.");

        // Setting values  (note: setter access will be made obsolete, use dot notation)
        table[5].age = 43;  // Getting younger
        
        // or with dot-syntax:
        myRow.age += 1;                                    // Happy birthday!
        NSLog(@"%@ age is now %ld.   [44]", myRow.name, (long)myRow.age);
        
        // Get last row
        NSString *lastname = table.lastRow.name;       // => "Anni"
        NSLog(@"Last name is %@.   [Anni]", lastname);
        
        // Change a row - not implemented yet
        // [people setAtIndex:4 Name:"Eric" Age:50 Hired:YES];
        
        // Delete row
        [table removeRowAtIndex:2];
    }];

    RLMPersonTable2 *people = [RLMPersonTable2 tableInRealm:self.realmPersistedAtTestPath named:@"table"];
    
    NSLog(@"%lu rows after remove.  [5]", [people rowCount]);  // 5
    XCTAssertEqual([people rowCount], (NSUInteger)5,@"rows should be 5");

    // Iterating over rows:
    for (NSUInteger i = 0; i < [people rowCount]; ++i) {
        RLMPerson2 *row = people[i];
        NSLog(@"(Rows) %@ is %ld years old.", row.name, (long)row.age);
    }

    //------------------------------------------------------
    NSLog(@"--- Simple Searching ---");
    //------------------------------------------------------
    
    XCTAssertNil([people firstWhere:@"name == 'Philip'"], @"Philip should not be there");
    XCTAssertNotNil([people firstWhere:@"name == 'Mary'"], @"Mary should have been there");
    XCTAssertEqual([people countWhere:@"age == 21"], (NSUInteger)2, @"There should be two rows in the view");

    //------------------------------------------------------
    NSLog(@"--- Queries ---");
    //------------------------------------------------------

    // Create query (current employees between 20 and 30 years old)
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"age between %@", @[@20, @30]];
    RLMView *view = [people allWhere:predicate];
    
    XCTAssertEqual(view.rowCount, (NSUInteger)3, @"Expected 3 rows in view");
    XCTAssertEqualWithAccuracy([[people averageOfProperty:@"age" where:predicate] doubleValue], (double)20.66, 0.01, @"Expected 21.6666 average");
    
    // iterate over the view
    for (NSUInteger i = 0; i < [view rowCount]; ++i) {
        NSLog(@"%zu: %@ is %@ years old", i,
            view[i][@"name"],
            view[i][@"age"]);
    }

    [manager writeUsingBlock:^(RLMRealm *realm) {
        RLMPersonTable2 *table = [RLMPersonTable2 tableInRealm:realm named:@"table"];
        [table addRow:@[@"Anni", @54, @YES]];
        
        XCTAssertEqual([table rowCount], (NSUInteger)6, @"PeopleTable should have 6 rows");
        
        for (NSUInteger i = 0; i < [table rowCount]; i++) {
            RLMPerson2 *row = table[i];
            NSLog(@"%zu: %@", i, row[@"name"]);
        }
    }];
}

@end
