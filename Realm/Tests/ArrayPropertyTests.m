////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////


#import "RLMTestCase.h"
#import "RLMTestObjects.h"

@interface ArrayPropertyObject : RLMObject
@property NSString *name;
@property RLMArray<RLMTestObject> *array;
@end

@implementation ArrayPropertyObject
@end


@interface ArrayPropertyTests : RLMTestCase
@end

@implementation ArrayPropertyTests


-(void)testPopulateEmptyArray {
    RLMRealm *realm = [self realmWithTestPath];
    
    [realm beginWriteTransaction];
    ArrayPropertyObject *array = [ArrayPropertyObject createInRealm:realm withObject:@[@"arrayObject", @[]]];
    XCTAssertNotNil(array.array, @"Should be able to get an empty array");
    XCTAssertEqual(array.array.count, 0, @"Should start with no array elements");

    RLMTestObject *obj = [[RLMTestObject alloc] init];
    obj.column = @"a";
    [array.array addObject:obj];
    [array.array addObject:[RLMTestObject createInRealm:realm withObject:@[@"b"]]];
    [array.array addObject:obj];
    [realm commitWriteTransaction];
    
    XCTAssertEqual(array.array.count, 3, @"Should have two elements in array");
    XCTAssertEqualObjects([array.array[0] column], @"a", @"First element should have property valud 'a'");
    XCTAssertEqualObjects([array.array[1] column], @"b", @"Second element should have property valud 'b'");
    XCTAssertEqualObjects([array.array[2] column], @"a", @"Third element should have property valud 'a'");

    // FIXME - link array accessor
    // XCTAssertThrows([array.array addObject:obj], @"Adding array object outside a transaction should throw");
}

-(void)testInsertArray {
    RLMRealm *realm = [self realmWithTestPath];
    
    RLMArray *array = [[RLMArray alloc] initWithObjectClassName:RLMTestObject.className];
    
    [realm beginWriteTransaction];
    [ArrayPropertyObject createInRealm:realm withObject:@[@"arrayObject", array]];
    [realm commitWriteTransaction];
}

@end

