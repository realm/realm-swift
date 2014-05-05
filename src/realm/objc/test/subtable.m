//
//  subtable.m
//  TightDB
//
//  Test save/load on disk of a realm with one table
//

#import "RLMTestCase.h"

#import <realm/objc/Realm.h>

@interface SubObject : RLMRow
@property NSString * Name;
@property int Age;
@end

@implementation SubObject
@end

RLM_TABLE_TYPE_FOR_OBJECT_TYPE(SubTable, SubObject)

@interface MainObject : RLMRow
@property NSString * First;
@property SubTable * Sub;
@property int Second;
@end

@implementation MainObject
@end

RLM_TABLE_TYPE_FOR_OBJECT_TYPE(MainTable, MainObject)


// main and subtable definitions derived from nsobject
@interface SubProxied : RLMRow
@property NSString * Name;
@property long LongAge;
@end

@implementation SubProxied
@end

@interface MainProxied : RLMRow
@property NSString * First;
@property RLMTable * Sub;
@property int Second;

-(NSString *)forwardGetFirst;

@end

@implementation MainProxied
+(Class)subtableObjectClassForProperty:(NSString *)columnName {
    if ([columnName isEqualToString:@"Sub"]) return SubProxied.class;
    return nil;
}

-(NSString *)forwardGetFirst {
    return self.First;
}

@end

@interface UnspecifiedSubObject : RLMRow
@property RLMTable * Sub;
@end

@implementation UnspecifiedSubObject
@end


@interface MACTestSubtable: RLMTestCase
@end

@implementation MACTestSubtable

- (void)testSubtable
{    
    [[self realmWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        /* Create new table in group */
        MainTable *people = [MainTable tableInRealm:realm named:@"employees"];
        
        /* FIXME: Add support for specifying a subtable to the 'add'
         method. The subtable must then be copied into the parent
         table. */
        [people addRow:@[@"first", @[], @8]];
        
        MainObject *cursor = people[0];
        SubTable *subtable = cursor.Sub;
        [subtable addRow:@[@"name", @999]];
        
        XCTAssertEqual(subtable[0].Age, (int)999, @"Age should be 999");
        
        // test setter
        
        // test setter
        cursor.Second = 10;
        XCTAssertEqual(people[0].Second, (int)10, @"Second should be 10");
	}];
}

- (void)testSubtableSimple {
    [[self realmWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        /* Create new table in group */
        RLMTable *people = [realm createTableWithName:@"employees" objectClass:MainProxied.class];
        
        /* FIXME: Add support for specifying a subtable to the 'add'
         method. The subtable must then be copied into the parent
         table. */
        [people addRow:@[@"first", @[], @8]];
        
        // test getter
        XCTAssertEqual([people[0] Second], (int)8, @"Second should be 8");
        
        // test forward invocation
        XCTAssertTrue([@"first" isEqualToString:[people[0] forwardGetFirst]], @"First should be first");
        
        MainProxied *cursor = people[0];
        RLMTable *subtable = cursor.Sub;
        [subtable addRow:@[@"name", @999]];
        
        XCTAssertEqual([subtable[0] LongAge], (long)999, @"Age should be 999");
	}];
}

- (void)testBadSubtable {
    
    [[self realmWithTestPath] writeUsingBlock:^(RLMRealm *realm) {    
        XCTAssertThrows([realm createTableWithName:@"badTable" objectClass:UnspecifiedSubObject.class], @"Shoud throw exception");
	}];
}

- (void) testDescriptor
{
    [[self realmWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        
    RLMTable *t = [realm createTableWithName:@"table"];
    RLMDescriptor *d = t.descriptor;
    RLMDescriptor *subDesc = [d addColumnTable:@"subtable"];
    
    XCTAssertEqual(t.columnCount, (NSUInteger)1, @"One column added");
    XCTAssertEqual(subDesc.columnCount, (NSUInteger)0, @"0 columns in subtable");
    
    NSUInteger subTablColIndex = [subDesc addColumnWithName:@"subCol" type:RLMTypeBool];
    XCTAssertEqual(subDesc.columnCount, (NSUInteger)1, @"Col count on subtable should be 1");
    XCTAssertEqual(subTablColIndex, (NSUInteger)0, @"col index of column should be 0");
    }];
}

@end
