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

#import "RLMAccessor.h"
#import "RLMObjectSchema_Private.hpp"
#import "RLMProperty_Private.h"
#import "RLMRealm_Dynamic.h"
#import "RLMSchema_Private.h"
#import "RLMSchema_Private.h"

#import <algorithm>
#import <objc/runtime.h>

@interface SchemaTestClassBase : RLMObject
@property IntObject *baseCol;
@end
@implementation SchemaTestClassBase
@end

@interface SchemaTestClassFirstChild : SchemaTestClassBase
@property IntObject *firstChildCol;
@end
@implementation SchemaTestClassFirstChild
@end

@interface SchemaTestClassSecondChild : SchemaTestClassBase
@property IntObject *secondChildCol;
@end
@implementation SchemaTestClassSecondChild
@end

RLM_ARRAY_TYPE(SchemaTestClassBase)
RLM_ARRAY_TYPE(SchemaTestClassFirstChild)
RLM_ARRAY_TYPE(SchemaTestClassSecondChild)

@interface SchemaTestClassLink : RLMObject
@property SchemaTestClassBase *base;
@property SchemaTestClassFirstChild *child;
@property SchemaTestClassSecondChild *secondChild;

@property RLMArray<SchemaTestClassBase> *baseArray;
@property RLMArray<SchemaTestClassFirstChild> *childArray;
@property RLMArray<SchemaTestClassSecondChild> *secondChildArray;
@end
@implementation SchemaTestClassLink
@end

@interface SchemaTestClassWithSingleDuplicatePropertyBase : FakeObject
@property NSString *string;
@end

@implementation SchemaTestClassWithSingleDuplicatePropertyBase
@end

@interface SchemaTestClassWithSingleDuplicateProperty : SchemaTestClassWithSingleDuplicatePropertyBase
@property NSString *string;
@end

@implementation SchemaTestClassWithSingleDuplicateProperty
@dynamic string;
@end

@interface SchemaTestClassWithMultipleDuplicatePropertiesBase : FakeObject
@property NSString *string;
@property int integer;
@end

@implementation SchemaTestClassWithMultipleDuplicatePropertiesBase
@end

@interface SchemaTestClassWithMultipleDuplicateProperties : SchemaTestClassWithMultipleDuplicatePropertiesBase
@property NSString *string;
@property int integer;
@end

@implementation SchemaTestClassWithMultipleDuplicateProperties
@dynamic string;
@dynamic integer;
@end

@interface UnindexableProperty : FakeObject
@property double unindexable;
@end
@implementation UnindexableProperty
+ (NSArray *)indexedProperties {
    return @[@"unindexable"];
}
@end


@interface InvalidPrimaryKeyType : FakeObject
@property double primaryKey;
@end
@implementation InvalidPrimaryKeyType
+ (NSString *)primaryKey {
    return @"primaryKey";
}
@end

@interface RequiredLinkProperty : FakeObject
@property BoolObject *object;
@end
@implementation RequiredLinkProperty
+ (NSArray *)requiredProperties {
    return @[@"object"];
}
@end

@interface SchemaTests : RLMTestCase
@end

@implementation SchemaTests

- (void)testNoSchemaForUnpersistedObjectClasses {
    RLMSchema *schema = [RLMSchema sharedSchema];
    XCTAssertNil([schema schemaForClassName:@"RLMObject"]);
    XCTAssertNil([schema schemaForClassName:@"RLMObjectBase"]);
    XCTAssertNil([schema schemaForClassName:@"RLMDynamicObject"]);
}

- (void)testInheritanceInitialization
{
    Class testClasses[] = {
        [SchemaTestClassBase class],
        [SchemaTestClassFirstChild class],
        [SchemaTestClassSecondChild class],
        [SchemaTestClassLink class],
        [IntObject class]
    };

    auto pred = ^(Class lft, Class rgt) {
        return (uintptr_t)lft < (uintptr_t)rgt;
    };

    auto checkSchema = ^(RLMSchema *schema, NSString *className, NSDictionary *properties) {
        RLMObjectSchema *objectSchema = schema[className];
        XCTAssertEqualObjects(className, objectSchema.className);
        XCTAssertEqualObjects(className, [objectSchema.standaloneClass className]);
        XCTAssertEqualObjects(className, [objectSchema.accessorClass className]);

        XCTAssertEqual(objectSchema.properties.count, properties.count);
        for (NSString *propName in properties) {
            XCTAssertEqualObjects(properties[propName], [objectSchema[propName] objectClassName]);
        }
    };

    // Test each permutation of loading orders and verify that all properties
    // are initialized correctly
    std::sort(testClasses, std::end(testClasses), pred);
    do @autoreleasepool {
        // Clean up any existing overridden things
        for (Class cls : testClasses) {
            // Ensure that the className method isn't used during schema init
            // as it may not be overriden yet
            NSString *className = NSStringFromClass(cls);
            Class metaClass = objc_getMetaClass(className.UTF8String);
            IMP imp = imp_implementationWithBlock(^{ return nil; });
            class_replaceMethod(metaClass, @selector(className), imp, "@:");
        }

        NSMutableArray *objectSchemas = [NSMutableArray arrayWithCapacity:4U];
        for (Class cls : testClasses) {
            [objectSchemas addObject:[RLMObjectSchema schemaForObjectClass:cls]];
        }

        RLMSchema *schema = [[RLMSchema alloc] init];
        schema.objectSchema = objectSchemas;

        for (RLMObjectSchema *objectSchema in objectSchemas) {
            objectSchema.accessorClass = RLMAccessorClassForObjectClass(objectSchema.objectClass, objectSchema, @"RLMAccessor_");
            objectSchema.standaloneClass = RLMStandaloneAccessorClassForObjectClass(objectSchema.objectClass, objectSchema);
        }

        // Verify that each class has the correct properties and className
        // for generated subclasses
        checkSchema(schema, @"SchemaTestClassBase", @{@"baseCol": @"IntObject"});
        checkSchema(schema, @"SchemaTestClassFirstChild", @{@"baseCol": @"IntObject",
                                                            @"firstChildCol": @"IntObject"});
        checkSchema(schema, @"SchemaTestClassSecondChild", @{@"baseCol": @"IntObject",
                                                            @"secondChildCol": @"IntObject"});
        checkSchema(schema, @"SchemaTestClassLink", @{@"base": @"SchemaTestClassBase",
                                                      @"baseArray": @"SchemaTestClassBase",
                                                      @"child": @"SchemaTestClassFirstChild",
                                                      @"childArray": @"SchemaTestClassFirstChild",
                                                      @"secondChild": @"SchemaTestClassSecondChild",
                                                      @"secondChildArray": @"SchemaTestClassSecondChild"});

        for (Class cls : testClasses) {
            NSString *className = NSStringFromClass(cls);

            // Restore the className method
            Class metaClass = objc_getMetaClass(className.UTF8String);
            IMP imp = imp_implementationWithBlock(^{ return className; });
            class_replaceMethod(metaClass, @selector(className), imp, "@:");
        }

        // Test creating objects of each class
        [self deleteFiles];
        RLMRealm *realm = [self realmWithTestPathAndSchema:schema];
        [realm beginWriteTransaction];
        [realm createObject:@"SchemaTestClassBase" withValue:@{@"baseCol": @[@0]}];
        [realm createObject:@"SchemaTestClassFirstChild" withValue:@{@"baseCol": @[@0], @"firstChildCol": @[@0]}];
        [realm createObject:@"SchemaTestClassSecondChild" withValue:@{@"baseCol": @[@0], @"secondChildCol": @[@0]}];
        [realm commitWriteTransaction];
    } while (std::next_permutation(testClasses, std::end(testClasses), pred));
}

- (void)testObjectSchema
{
    // Setting up some test data

    // Due to the automatic initialization of a new realm with all visible classes inheriting from
    // RLMObject, it's difficult to define test cases that verify the absolute correctness of a
    // realm's current type catalogue unless its expected configuration is known at compile time
    // (requires that the set of expected types is always up-to-date). Instead, only a partial
    // verification is performed, which only requires the availability of a well-defined subset of
    // types and ignores any other types that may be included in the realm's type catalogue.
    // If a more fine-grained control with the realm's type inclusion mechanism is introduced later
    // on, these tests should be altered to verify all types.
    
    NSArray *expectedTypes = @[@"AllTypesObject",
                               @"StringObject",
                               @"IntObject"];
    
    NSString *unexpectedType = @"__$ThisTypeShouldNotOccur$__";
    
    // Getting the test realm
    NSMutableArray *objectSchema = [NSMutableArray array];
    for (NSString *className in expectedTypes) {
        [objectSchema addObject:[RLMObjectSchema schemaForObjectClass:NSClassFromString(className)]];
    }

    RLMSchema *schema = [[RLMSchema alloc] init];
    schema.objectSchema = objectSchema;

    // create realm with schema
    [self realmWithTestPathAndSchema:schema];

    // get dynamic realm and extract schema
    RLMRealm *realm = [self realmWithTestPathAndSchema:nil];
    schema = realm.schema;

    // Test 1: Does the objectSchema return the right number of object schemas?
    NSArray *objectSchemas = schema.objectSchema;
    
    XCTAssertTrue(objectSchemas.count >= expectedTypes.count, @"Expecting %lu object schemas in database found %lu", (unsigned long)expectedTypes.count, (unsigned long)objectSchemas.count);
    
    // Test 2: Does the object schema array contain the expected schemas?
    NSUInteger identifiedTypesCount = 0;
    for (NSString *expectedType in expectedTypes) {
        NSUInteger occurrenceCount = 0;
        
        for (RLMObjectSchema *objectSchema in objectSchemas) {
            NSLog(@"Scheme %@", objectSchema.className);
            if ([objectSchema.className isEqualToString:expectedType]) {
                occurrenceCount++;
            }
        }
        
        XCTAssertEqual(occurrenceCount, (NSUInteger)1, @"Expecting single occurrence of object schema for type %@ found %lu", expectedType, (unsigned long)occurrenceCount);
        
        if (occurrenceCount > 0) {
            identifiedTypesCount++;
        }
    }

    // Test 3: Does the object schema array contains at least the expected classes
    XCTAssertTrue(identifiedTypesCount >= expectedTypes.count, @"Unexpected object schemas in database. Found %lu out of %lu expected", (unsigned long)identifiedTypesCount, (unsigned long)expectedTypes.count);
    
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
    XCTAssertThrows(schema[unexpectedType], @"Expecting asking schema for type %@ in realm using subscription to throw", unexpectedType);

    // Test 8: RLMObject should not appear in the shared object schema
    XCTAssertThrows(RLMSchema.sharedSchema[@"RLMObject"]);
}

- (void)testDescription {
    NSArray *expectedTypes = @[@"AllTypesObject",
                               @"StringObject",
                               @"IntObject"];

    NSMutableArray *objectSchema = [NSMutableArray array];
    for (NSString *className in expectedTypes) {
        [objectSchema addObject:[RLMObjectSchema schemaForObjectClass:NSClassFromString(className)]];
    }

    RLMSchema *schema = [[RLMSchema alloc] init];
    schema.objectSchema = objectSchema;

    XCTAssertEqualObjects(schema.description, @"Schema {\n"
                                              @"\tAllTypesObject {\n"
                                              @"\t\tboolCol {\n"
                                              @"\t\t\ttype = bool;\n"
                                              @"\t\t\tobjectClassName = (null);\n"
                                              @"\t\t\tindexed = NO;\n"
                                              @"\t\t\tisPrimary = NO;\n"
                                              @"\t\t\toptional = NO;\n"
                                              @"\t\t}\n"
                                              @"\t\tintCol {\n"
                                              @"\t\t\ttype = int;\n"
                                              @"\t\t\tobjectClassName = (null);\n"
                                              @"\t\t\tindexed = NO;\n"
                                              @"\t\t\tisPrimary = NO;\n"
                                              @"\t\t\toptional = NO;\n"
                                              @"\t\t}\n"
                                              @"\t\tfloatCol {\n"
                                              @"\t\t\ttype = float;\n"
                                              @"\t\t\tobjectClassName = (null);\n"
                                              @"\t\t\tindexed = NO;\n"
                                              @"\t\t\tisPrimary = NO;\n"
                                              @"\t\t\toptional = NO;\n"
                                              @"\t\t}\n"
                                              @"\t\tdoubleCol {\n"
                                              @"\t\t\ttype = double;\n"
                                              @"\t\t\tobjectClassName = (null);\n"
                                              @"\t\t\tindexed = NO;\n"
                                              @"\t\t\tisPrimary = NO;\n"
                                              @"\t\t\toptional = NO;\n"
                                              @"\t\t}\n"
                                              @"\t\tstringCol {\n"
                                              @"\t\t\ttype = string;\n"
                                              @"\t\t\tobjectClassName = (null);\n"
                                              @"\t\t\tindexed = NO;\n"
                                              @"\t\t\tisPrimary = NO;\n"
                                              @"\t\t\toptional = YES;\n"
                                              @"\t\t}\n"
                                              @"\t\tbinaryCol {\n"
                                              @"\t\t\ttype = data;\n"
                                              @"\t\t\tobjectClassName = (null);\n"
                                              @"\t\t\tindexed = NO;\n"
                                              @"\t\t\tisPrimary = NO;\n"
                                              @"\t\t\toptional = YES;\n"
                                              @"\t\t}\n"
                                              @"\t\tdateCol {\n"
                                              @"\t\t\ttype = date;\n"
                                              @"\t\t\tobjectClassName = (null);\n"
                                              @"\t\t\tindexed = NO;\n"
                                              @"\t\t\tisPrimary = NO;\n"
                                              @"\t\t\toptional = NO;\n"
                                              @"\t\t}\n"
                                              @"\t\tcBoolCol {\n"
                                              @"\t\t\ttype = bool;\n"
                                              @"\t\t\tobjectClassName = (null);\n"
                                              @"\t\t\tindexed = NO;\n"
                                              @"\t\t\tisPrimary = NO;\n"
                                              @"\t\t\toptional = NO;\n"
                                              @"\t\t}\n"
                                              @"\t\tlongCol {\n"
                                              @"\t\t\ttype = int;\n"
                                              @"\t\t\tobjectClassName = (null);\n"
                                              @"\t\t\tindexed = NO;\n"
                                              @"\t\t\tisPrimary = NO;\n"
                                              @"\t\t\toptional = NO;\n"
                                              @"\t\t}\n"
                                              @"\t\tmixedCol {\n"
                                              @"\t\t\ttype = any;\n"
                                              @"\t\t\tobjectClassName = (null);\n"
                                              @"\t\t\tindexed = NO;\n"
                                              @"\t\t\tisPrimary = NO;\n"
                                              @"\t\t\toptional = NO;\n"
                                              @"\t\t}\n"
                                              @"\t\tobjectCol {\n"
                                              @"\t\t\ttype = object;\n"
                                              @"\t\t\tobjectClassName = StringObject;\n"
                                              @"\t\t\tindexed = NO;\n"
                                              @"\t\t\tisPrimary = NO;\n"
                                              @"\t\t\toptional = YES;\n"
                                              @"\t\t}\n"
                                              @"\t}\n"
                                              @"\tStringObject {\n"
                                              @"\t\tstringCol {\n"
                                              @"\t\t\ttype = string;\n"
                                              @"\t\t\tobjectClassName = (null);\n"
                                              @"\t\t\tindexed = NO;\n"
                                              @"\t\t\tisPrimary = NO;\n"
                                              @"\t\t\toptional = YES;\n"
                                              @"\t\t}\n"
                                              @"\t}\n"
                                              @"\tIntObject {\n"
                                              @"\t\tintCol {\n"
                                              @"\t\t\ttype = int;\n"
                                              @"\t\t\tobjectClassName = (null);\n"
                                              @"\t\t\tindexed = NO;\n"
                                              @"\t\t\tisPrimary = NO;\n"
                                              @"\t\t\toptional = NO;\n"
                                              @"\t\t}\n"
                                              @"\t}\n"
                                              @"}");
}

- (void)testClassWithDuplicateProperties
{
    RLMAssertThrowsWithReasonMatching([RLMObjectSchema schemaForObjectClass:SchemaTestClassWithSingleDuplicateProperty.class], @"'string' .* multiple times .* 'SchemaTestClassWithSingleDuplicateProperty'");
    RLMAssertThrowsWithReasonMatching([RLMObjectSchema schemaForObjectClass:SchemaTestClassWithMultipleDuplicateProperties.class], @"'SchemaTestClassWithMultipleDuplicateProperties' .* declared multiple times");
}

- (void)testClassWithInvalidPrimaryKey {
    XCTAssertThrows([RLMObjectSchema schemaForObjectClass:InvalidPrimaryKeyType.class]);
}

- (void)testClassWithUnindexableProperty {
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:UnindexableProperty.class];
    RLMSchema *schema = [[RLMSchema alloc] init];
    schema.objectSchema = @[objectSchema];
    RLMAssertThrowsWithReasonMatching([self realmWithTestPathAndSchema:schema],
                                      @".*Can't index property.*double.*");
}

- (void)testClassWithRequiredNullableProperties {
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:RequiredPropertiesObject.class];
    XCTAssertFalse([objectSchema[@"stringCol"] optional]);
    XCTAssertFalse([objectSchema[@"binaryCol"] optional]);
}

- (void)testClassWithRequiredLinkProperty {
    RLMAssertThrowsWithReasonMatching([RLMObjectSchema schemaForObjectClass:RequiredLinkProperty.class], @"cannot be made required.*'object'");
}

@end
