//
//  SchemaTests.m
//  Realm
//
//  Created by Jesper Zuschlag on 17/06/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

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
    
    // Test 1: Do objectSchema returns the right number of object schema?
    NSArray *objectSchemas = schema.objectSchema;
    
    XCTAssert(objectSchemas.count == 25, @"Expecting 25 object schemas in database");
    
    // Test 2: Does the object schema array contained the expected shema?
    for(NSString *expectedType in expectedTypes) {
        [self performIndexAccessTestOnObjectSchemas:objectSchemas
                                     withSchemaName:expectedType
                                      expectedCount:1];
    }

    [self performIndexAccessTestOnObjectSchemas:objectSchemas
                                 withSchemaName:unexpectedType
                                  expectedCount:0];
    
    // Test 3: Test querying object schema using schemaForClassName:
    for(NSString *expectedType in expectedTypes) {
        [self performQueryAccessTestOnRealmSchemas:schema
                                    withSchemaName:expectedType
                                          expected:YES];
    }

    [self performQueryAccessTestOnRealmSchemas:schema
                                withSchemaName:unexpectedType
                                      expected:NO];
    
    // Test 4: Test querying object schema using subscription
    for(NSString *expectedType in expectedTypes) {
        [self performSubscriptionAccessTestOnRealmSchemas:schema
                                           withSchemaName:expectedType
                                                 expected:YES];
    }
    [self performSubscriptionAccessTestOnRealmSchemas:schema
                                       withSchemaName:unexpectedType
                                             expected:NO];
    
    NSLog(@"Object schemas %@", objectSchemas);
}

- (void)performIndexAccessTestOnObjectSchemas:(NSArray *)objectSchemas withSchemaName:(NSString *)className expectedCount:(NSUInteger)expectedCount
{
    NSUInteger occurrenceCount = 0;
    
    for(RLMObjectSchema *objectSchema in objectSchemas) {
        if([objectSchema.className isEqualToString:className]) {
            occurrenceCount++;
        }
    }
    
    XCTAssert(occurrenceCount == expectedCount, @"Expecting %lu occurrence of object schema for type %@ found %lu", expectedCount, className, (unsigned long)occurrenceCount);
}

- (void)performQueryAccessTestOnRealmSchemas:(RLMSchema *)realmSchema withSchemaName:(NSString *)className expected:(BOOL)expected
{
    BOOL found = [realmSchema schemaForClassName:className] != nil;
    
    if(expected) {
        XCTAssert(found, @"Expecting to find type %@ in realm using query, found none", className);
    }
    else {
        XCTAssert(!found, @"Expecting not to find type %@ in realm using query, found one", className);
    }
}

- (void)performSubscriptionAccessTestOnRealmSchemas:(RLMSchema *)realmSchema withSchemaName:(NSString *)className expected:(BOOL)expected
{
    BOOL found = realmSchema[className] != nil;
    
    if(expected) {
        XCTAssert(found, @"Expecting to find type %@ in realm using subscription, found none", className);
    }
    else {
        XCTAssert(!found, @"Expecting not to find type %@ in realm using subscription, found one", className);
    }
    
}

@end
