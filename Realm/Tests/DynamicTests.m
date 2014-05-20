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
#import "RLMSchema.h"
#import "XCTestCase+AsyncTesting.h"

@interface RLMDynamicObject : RLMObject
@property (nonatomic, copy) NSString *column;
@property (nonatomic) NSInteger integer;

@end

@implementation RLMDynamicObject
@end

@interface RLMDynamicTests : RLMTestCase
@end

@interface RLMRealm ()
+ (instancetype)realmWithPath:(NSString *)path
                     readOnly:(BOOL)readonly
                      dynamic:(BOOL)dynamic
                        error:(NSError **)outError;
@end

@implementation RLMDynamicTests

#pragma mark - Tests

- (void)testDynaimcRealmExists {
    @autoreleasepool {
        // open realm in autoreleasepool to create tables and then dispose
        RLMRealm *realm = [RLMRealm realmWithPath:RLMTestRealmPath() readOnly:NO error:nil];
        [realm beginWriteTransaction];
        [RLMDynamicObject createInRealm:realm withObject:@[@"column1", @1]];
        [RLMDynamicObject createInRealm:realm withObject:@[@"column2", @2]];
        [realm commitWriteTransaction];
    }
    
    RLMRealm *dyrealm = [RLMRealm realmWithPath:RLMTestRealmPath() readOnly:YES dynamic:YES error:nil];
    XCTAssertNotNil(dyrealm, @"realm should not be nil");
    XCTAssertEqual([dyrealm class], [RLMRealm class], @"realm should be of class RLMDynamicRealm");
    
    // verify schema
    RLMObjectSchema *dynSchema = dyrealm.schema[@"RLMDynamicObject"];
    XCTAssertNotNil(dynSchema, @"Should be able to get object schema dynamically");
    XCTAssertEqual(dynSchema.properties.count, 2, @"RLMDynamicObject should have 2 properties");
    XCTAssertEqualObjects([dynSchema.properties[0] name], @"column", @"Invalid property name");
    XCTAssertEqual([(RLMProperty *)dynSchema.properties[1] type], RLMPropertyTypeInt, @"Invalid type");
    
    // verify object type
    RLMArray *array = [dyrealm allObjects:@"RLMDynamicObject"];
    XCTAssertEqual(array.count, 2, @"Array should have 2 elements");
    XCTAssertNotEqual(array.objectClass, RLMDynamicObject.class,
                      @"Array class should by a dynamic object class");
}

@end
