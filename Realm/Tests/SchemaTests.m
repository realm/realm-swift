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

#import <XCTest/XCTest.h>
#import "RLMTestCase.h"

@interface SchemaTests : RLMTestCase

@end

@implementation SchemaTests

- (void)testObjectSchema
{
    // Setting up some test data
    
    NSArray *expectedTypes = @[@"Company",
                               @"AgeObject",
                               @"KeyedObject",
                               @"AggregateObject",
                               @"AllTypesObject",
                               @"RLMTestObject",
                               @"SimpleObject",
                               @"PersonObject",
                               @"SimpleMisuseObject",
                               @"OwnerObject",
                               @"RLMDynamicObject",
                               @"EnumPerson",
                               @"CircleObject",
                               @"MixedObject",
                               @"DogObject",
                               @"IndexedObject",
                               @"TestQueryObject",
                               @"ArrayPropertyObject",
                               @"BaseClassTestObject",
                               @"CustomAccessors",
                               @"NoDefaultObject",
                               @"PersonQueryObject",
                               @"AllPropertyTypesObject",
                               @"IgnoredURLObject",
                               @"DefaultObject"];
    
    NSString *unexpectedType = @"__$ThisTypeShouldNotOccur$__";
    
    // Getting the test realm
    RLMRealm *realm = [self realmWithTestPath];
    RLMSchema *schema = realm.schema;
    
    // Test 1: Do objectSchema returns the right number of object schemas?
    NSArray *objectSchemas = schema.objectSchema;
    
    XCTAssertEqual(objectSchemas.count, expectedTypes.count, @"Expecting %lu object schemas in database", (unsigned long)expectedTypes.count);
    
    // Test 2: Does the object schema array contained the expected schemas?
    for (NSString *expectedType in expectedTypes) {
        [self performIndexAccessTestOnObjectSchemas:objectSchemas
                                     withSchemaName:expectedType
                                      expectedCount:1];
    }

    [self performIndexAccessTestOnObjectSchemas:objectSchemas
                                 withSchemaName:unexpectedType
                                  expectedCount:0];
    
    // Test 3: Test querying object schemas using schemaForClassName:
    for (NSString *expectedType in expectedTypes) {
        [self performQueryAccessTestOnRealmSchema:schema
                                   withSchemaName:expectedType
                                         expected:YES];
    }

    [self performQueryAccessTestOnRealmSchema:schema
                               withSchemaName:unexpectedType
                                     expected:NO];
    
    // Test 4: Test querying object schemas using subscription
    for (NSString *expectedType in expectedTypes) {
        [self performSubscriptionAccessTestOnRealmSchema:schema
                                          withSchemaName:expectedType
                                                expected:YES];
    }
    [self performSubscriptionAccessTestOnRealmSchema:schema
                                      withSchemaName:unexpectedType
                                            expected:NO];
}

- (void)performIndexAccessTestOnObjectSchemas:(NSArray *)objectSchemas withSchemaName:(NSString *)className expectedCount:(NSUInteger)expectedCount
{
    NSUInteger occurrenceCount = 0;
    
    for (RLMObjectSchema *objectSchema in objectSchemas) {
        if ([objectSchema.className isEqualToString:className]) {
            occurrenceCount++;
        }
    }
    
    XCTAssertEqual(occurrenceCount, expectedCount, @"Expecting %lu occurrence of object schema for type %@ found %lu", expectedCount, className, (unsigned long)occurrenceCount);
}

- (void)performQueryAccessTestOnRealmSchema:(RLMSchema *)realmSchema withSchemaName:(NSString *)className expected:(BOOL)expected
{
    BOOL found = [realmSchema schemaForClassName:className] != nil;
    
    if (expected) {
        XCTAssertTrue(found, @"Expecting to find type %@ in realm using query, found none", className);
    }
    else {
        XCTAssertFalse(found, @"Expecting not to find type %@ in realm using query, found one", className);
    }
}

- (void)performSubscriptionAccessTestOnRealmSchema:(RLMSchema *)realmSchema withSchemaName:(NSString *)className expected:(BOOL)expected
{
    BOOL found = realmSchema[className] != nil;
    
    if (expected) {
        XCTAssertTrue(found, @"Expecting to find type %@ in realm using subscription, found none", className);
    }
    else {
        XCTAssertFalse(found, @"Expecting not to find type %@ in realm using subscription, found one", className);
    }
    
}

@end
