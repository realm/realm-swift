//
//  subtable.m
//  TightDB
//
//  Test save/load on disk of a group with one table
//

#import <XCTest/XCTest.h>

#import <realm/objc/Realm.h>
#import <realm/objc/group.h>

@interface SubObject : RLMRow
@property NSString * Name;
@property int Age;
@end

@implementation SubObject
@end

DEFINE_TABLE_TYPE(SubObject)

@interface MainObject : RLMRow
@property NSString * First;
@property RLMTable<SubObject> * Sub;
@property int Second;
@end

@implementation MainObject
@end

DEFINE_TABLE_TYPE(MainObject)


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


@interface MACTestSubtable: XCTestCase
@end
@implementation MACTestSubtable

- (void)setUp
{
    [super setUp];

    // _group = [Group group];
    // NSLog(@"Group: %@", _group);
    // XCTAssertNotNil(_group, @"Group is nil");
}

- (void)tearDown
{
    // Tear-down code here.

    //  [super tearDown];
    //  _group = nil;
}

- (void)testSubtable
{
    RLMTransaction *group = [RLMTransaction group];
    
    /* Create new table in group */
    RLMTable<MainObject> *people = [group createTableWithName:@"employees" objectClass:MainObject.class];
    
    /* FIXME: Add support for specifying a subtable to the 'add'
     method. The subtable must then be copied into the parent
     table. */
    [people addRow:@[@"first", @[], @8]];
    
    MainObject *cursor = people[0];
    RLMTable<SubObject> *subtable = cursor.Sub;
    [subtable addRow:@[@"name", @999]];
    
    XCTAssertEqual([subtable[0] Age], (int)999, @"Age should be 999");
    
    // test setter
    
    // test setter
    cursor.Second = 10;
    XCTAssertEqual([people[0] Second], (int)10, @"Second should be 10");
}

- (void)testSubtableSimple {
    RLMTransaction *group = [RLMTransaction group];
    
    /* Create new table in group */
    RLMTable *people = [group createTableWithName:@"employees" objectClass:MainProxied.class];
    
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
}

- (void)testBadSubtable {
    
    RLMTransaction *group = [RLMTransaction group];
    
    XCTAssertThrows([group createTableWithName:@"badTable" objectClass:UnspecifiedSubObject.class], @"Shoud throw exception");
}

@end


