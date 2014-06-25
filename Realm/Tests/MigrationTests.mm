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

extern "C" {
    #import "RLMTestCase.h"
    #import "RLMMigration.h"
    #import "RLMSchema_Private.h"
}
#import "RLMObjectSchema_Private.hpp"

@interface MigrationObject : RLMObject
@property int intCol;
@property NSString *stringCol;
@end

@implementation MigrationObject
@end

@interface MigrationTests : RLMTestCase
@end

@implementation MigrationTests

- (RLMRealm *)realmWithSingleObject:(RLMObjectSchema *)objectSchema {
    RLMSchema *schema = [[RLMSchema alloc] init];
    schema.objectSchema = @[objectSchema];
    return [self dynamicRealmWithTestPathAndSchema:schema];
}

- (void)testAddingProperty {
    // create schema to migrate from with single string column
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationObject.class];
    objectSchema.properties = @[objectSchema.properties[0]];
    
    // create realm with old schema and populate
    RLMRealm *realm = [self realmWithSingleObject:objectSchema];
    [realm beginWriteTransaction];
    
    // FIXME - add objects
    
    [realm commitWriteTransaction];

    // open realm with new schema before migration
    objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationObject.class];
    XCTAssertThrows([self realmWithSingleObject:objectSchema], @"Migration should be required");
    
    // apply migration
    [RLMRealm applyMigrationBlock:^NSUInteger(RLMMigration *migration, NSUInteger oldSchemaVersion) {
        XCTAssertEqual(oldSchemaVersion, 0U, @"Initial schema version should be 0");
        [migration enumerateObjectsWithClass:MigrationObject.class
                                       block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertThrows(oldObject[@"stringCol"], @"stringCol should not exist on old object");
            NSNumber *intObj;
            XCTAssertNoThrow(intObj = oldObject[@"intCol"], @"Should be able to access intCol on oldObject");
            NSString *stringObj = [NSString stringWithFormat:@"%@", intObj];
            XCTAssertNoThrow(newObject[@"stringCol"] = stringObj, @"Should be able to set stringCol");
        }];
        return 1;
    } atPath:RLMTestRealmPath() error:nil];
}

@end

