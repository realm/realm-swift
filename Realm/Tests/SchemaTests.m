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
    NSUInteger identifiedTypesCount = 0;
    for (NSString *expectedType in expectedTypes) {
        NSUInteger occurrenceCount = 0;
        
        for (RLMObjectSchema *objectSchema in objectSchemas) {
            if ([objectSchema.className isEqualToString:expectedType]) {
                occurrenceCount++;
            }
        }
        
        XCTAssertEqual(occurrenceCount, (NSUInteger)1, @"Expecting single occurrence of object schema for type %@ found %lu", expectedType, occurrenceCount);
        
        if (occurrenceCount > 0) {
            identifiedTypesCount++;
        }
    }

    // Test 3: Do the object schema array have unexpected schemas?
    XCTAssertEqual(identifiedTypesCount, expectedTypes.count, @"Unexpected object schemas in database. Found %lu out of %lu expected", identifiedTypesCount, expectedTypes.count);
    
    // Test 4: Test querying object schemas using schemaForClassName: for expected types
    for (NSString *expectedType in expectedTypes) {
        XCTAssertNotNil([schema schemaForClassName:expectedType], @"Expecting to find object schema for type %@ in realm using query, found none", expectedType);
    }

    // Test 5: Test querying object schemas using schemaForClassName: for unexpected types
    XCTAssertNil([schema schemaForClassName:unexpectedType], @"Expecting not to find object schema for type %@ in realm using query, did find", unexpectedType);
    
    // Test 6: Test querying object schemas using subscription for unexpected types
    for (NSString *expectedType in expectedTypes) {
        XCTAssertNotNil(schema[expectedType], @"Expecting to find object schema for type %@ in realm using subscription, found none", expectedType);
    }
    
    // Test 7: Test querying object schemas using subscription for unexpected types
    XCTAssertNil(schema[unexpectedType], @"Expecting not to find object schema for type %@ in realm using subscription, did find", unexpectedType);
}

@end
