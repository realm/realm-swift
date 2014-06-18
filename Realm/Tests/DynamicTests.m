////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMTestCase.h"
#import "RLMTestObjects.h"
#import "RLMSchema.h"

@interface RLMDynamicObject : RLMObject
@property (nonatomic, copy) NSString *column;
@property (nonatomic) NSInteger integer;
@end

@implementation RLMDynamicObject
@end

@interface DynamicTests : RLMTestCase
@end

@interface RLMRealm ()
+ (instancetype)realmWithPath:(NSString *)path
                     readOnly:(BOOL)readonly
                      dynamic:(BOOL)dynamic
                        error:(NSError **)outError;
@end

@implementation DynamicTests

#pragma mark - Tests

- (void)testDynamicRealmExists {
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
    XCTAssertEqual(dynSchema.properties.count, (NSUInteger)2, @"RLMDynamicObject should have 2 properties");
    XCTAssertEqualObjects([dynSchema.properties[0] name], @"column", @"Invalid property name");
    XCTAssertEqual([(RLMProperty *)dynSchema.properties[1] type], RLMPropertyTypeInt, @"Invalid type");
    
    // verify object type
    RLMArray *array = [dyrealm allObjects:@"RLMDynamicObject"];
    XCTAssertEqual(array.count, (NSUInteger)2, @"Array should have 2 elements");
    XCTAssertNotEqual(array.objectClassName, RLMDynamicObject.className,
                      @"Array class should by a dynamic object class");
}

- (void)testDynaimcProperties {
    @autoreleasepool {
        // open realm in autoreleasepool to create tables and then dispose
        RLMRealm *realm = [RLMRealm realmWithPath:RLMTestRealmPath() readOnly:NO error:nil];
        [realm beginWriteTransaction];
        [RLMDynamicObject createInRealm:realm withObject:@[@"column1", @1]];
        [RLMDynamicObject createInRealm:realm withObject:@[@"column2", @2]];
        [realm commitWriteTransaction];
    }
    
    // verify properties
    RLMRealm *dyrealm = [RLMRealm realmWithPath:RLMTestRealmPath() readOnly:YES dynamic:YES error:nil];
    RLMArray *array = [dyrealm allObjects:@"RLMDynamicObject"];
    
    RLMObject *o1 = array[0], *o2 = array[1];
    XCTAssertEqualObjects(o1[@"integer"], @1, @"First object should have column value 1");
    XCTAssertEqualObjects(o2[@"column"], @"column2", @"Second object should have column value column2");
    XCTAssertThrows(o1[@"invalid"], @"Invalid column name should throw");
}

- (void)testDynaimcTypes {
    NSDate *now = [NSDate dateWithTimeIntervalSince1970:100000];
    id obj1 = @[@YES, @1, @1.1f, @1.11, @"string", [NSData dataWithBytes:"a" length:1], now, @YES, @11, @0, NSNull.null];
    
    RLMTestObject *obj = [[RLMTestObject alloc] init];
    obj.column = @"column";
    id obj2 = @[@NO, @2, @2.2f, @2.22, @"string2", [NSData dataWithBytes:"b" length:1], now, @NO, @22, now, obj];
    @autoreleasepool {
        // open realm in autoreleasepool to create tables and then dispose
        RLMRealm *realm = [RLMRealm realmWithPath:RLMTestRealmPath() readOnly:NO error:nil];
        [realm beginWriteTransaction];
        [AllTypesObject createInRealm:realm withObject:obj1];
        [AllTypesObject createInRealm:realm withObject:obj2];
        [realm commitWriteTransaction];
    }
    
    // verify properties
    RLMRealm *dyrealm = [RLMRealm realmWithPath:RLMTestRealmPath() readOnly:NO dynamic:YES error:nil];
    RLMArray *array = [dyrealm allObjects:AllTypesObject.className];
    XCTAssertEqual(array.count, (NSUInteger)2, @"Should have 2 objects");
    
    RLMObjectSchema *schema = dyrealm.schema[AllTypesObject.className];
    for (int i = 0; i < 10; i++) {
        NSString *propName = [schema.properties[i] name];
        XCTAssertEqualObjects(obj1[i], array[0][propName], @"Invalid property value");
        XCTAssertEqualObjects(obj2[i], array[1][propName], @"Invalid property value");
    }
    
    // check sub object type
    XCTAssertEqualObjects([schema.properties[10] objectClassName], @"RLMTestObject",
                          @"Sub-object type in schema should be 'RLMTestObject'");
    
    // check object equality
    XCTAssertNil(array[0][@"objectCol"], @"object should be nil");
    XCTAssertEqualObjects(array[1][@"objectCol"][@"column"], @"column",
                          @"Child object should have string value 'column'");
}

@end


