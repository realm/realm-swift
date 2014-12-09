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

#import "RLMTestDataGenerator.h"
#import <Realm/Realm.h>

const NSUInteger kMaxItemsInTestArray = 12;

@interface RLMTestDataGenerator ()

@property (nonatomic) NSArray *classNames;
@property (nonatomic) NSDictionary *existingObjects;

@end


@implementation RLMTestDataGenerator

// Creates a test realm at [url], filled with [objectCount] random objects of classes in [classNames]
+(BOOL)createRealmAtUrl:(NSURL *)url withClassesNamed:(NSArray *)classNames objectCount:(NSUInteger)objectCount
{
    NSError *error;
    RLMRealm *realm = [RLMRealm realmWithPath:url.path readOnly:NO error:&error];
    
    if (error) {
        return NO;
    }
    
    RLMTestDataGenerator *generator = [[RLMTestDataGenerator alloc] initWithClassesNamed:classNames];
    [generator populateRealm:realm withObjectCount:objectCount];
    
    return YES;
}

// Initializes the testDataGenerator and saves the desired [classNames]
-(instancetype)initWithClassesNamed:(NSArray *)classNames
{
    self = [super init];
    if (self) {
        self.classNames = classNames;
        
        NSMutableDictionary *existingObjects = [NSMutableDictionary dictionary];
        for (NSString *className in classNames) {
            existingObjects[className] = [NSMutableArray array];
        }
        
        self.existingObjects = existingObjects;
    }
    
    return self;
}

// Fills the supplied [realm] with [objectCount] objects of types in self.classNames
-(void)populateRealm:(RLMRealm *)realm withObjectCount:(NSUInteger)objectCount
{
    [realm beginWriteTransaction];
    
    for (NSString *className in self.classNames) {
        Class class = NSClassFromString(className);
        
        for (NSUInteger index = 0; index < objectCount; index++) {
            [self randomObjectOfClass:class inRealm:realm];
        }
    }
    
    [realm commitWriteTransaction];
}

// Creates a new random object of [class] and puts in realm
-(RLMObject *)randomObjectOfClass:(Class)class inRealm:(RLMRealm *)realm
{
    return [self randomObjectOfClass:class inRealm:realm tryToReuse:NO];
}

// Creates a random object of [class] and puts in realm, possibly through [reuse] of existing objects of same class
-(RLMObject *)randomObjectOfClass:(Class)class inRealm:(RLMRealm *)realm tryToReuse:(BOOL)reuse
{
    NSMutableArray *existingObjectsOfRequiredClass = self.existingObjects[class.className];
    NSUInteger existingCount = existingObjectsOfRequiredClass.count;
    
    // If reuse is desired and there is something to reuse, return existing object
    if (reuse && existingCount > 0) {
        NSUInteger index = arc4random_uniform((u_int32_t)existingCount);
        
        return existingObjectsOfRequiredClass[index];
    }
    
    RLMObjectSchema *objectSchema = [realm.schema schemaForClassName:class.className];
    
    // Make array to keep property values
    NSMutableArray *propertyValues = [NSMutableArray array];
    
    // Go through properties and fill with random values
    for (RLMProperty *property in objectSchema.properties) {
        id propertyValue;
        
        switch (property.type) {
            case RLMPropertyTypeBool:
                propertyValue = @([self randomBool]);
                break;
                
            case RLMPropertyTypeInt:
                propertyValue = @([self randomInteger]);
                break;
                
            case RLMPropertyTypeFloat:
                propertyValue = @([self randomFloat]);
                break;
                
            case RLMPropertyTypeDouble:
                propertyValue = @([self randomDouble]);
                break;
                
            case RLMPropertyTypeDate:
                propertyValue = [self randomDate];
                break;
                
            case RLMPropertyTypeString:
                propertyValue = [self randomString];
                break;
                
            case RLMPropertyTypeArray:
                propertyValue = [self randomArrayWithObjectsOfClass:NSClassFromString(property.objectClassName) inRealm:realm];
                break;
                
            case RLMPropertyTypeData:
                propertyValue = [self randomData];
                break;
                
            case RLMPropertyTypeAny:
                propertyValue = [self randomAny];
                break;
                
            case RLMPropertyTypeObject:
                propertyValue = [self randomObjectOfClass:NSClassFromString(property.objectClassName) inRealm:realm tryToReuse:YES];
                break;
        }
        
        [propertyValues addObject:propertyValue];
    }
    
    // Create an object from [propertyValues] and put in [realm]
    RLMObject *newObject = [class createInRealm:realm withObject:propertyValues];
    
    // Add object to store of existing objects
    [existingObjectsOfRequiredClass addObject:newObject];
    
    return newObject;
}

-(BOOL)randomBool
{
    return arc4random() % 2 == 0;
}

-(NSInteger)randomInteger
{
    NSUInteger type = arc4random_uniform(20);
    
    switch (type) {
        case 0:
            return INTMAX_MIN;
        case 1:
            return INTMAX_MAX;
        case 2:
            return 0;
        default:
            return arc4random_uniform(9999999);
    }
}

-(float)randomFloat
{
    NSUInteger type = arc4random_uniform(20);
    
    switch (type) {
        case 0:
            return FLT_MIN;
        case 1:
            return FLT_MAX;
        case 2:
            return 0;
        default:
            return arc4random_uniform(9999999)/9999.0f;
    }
}

-(double)randomDouble
{
    NSUInteger type = arc4random_uniform(20);
    
    switch (type) {
        case 0:
            return DBL_MIN;
        case 1:
            return DBL_MAX;
        case 2:
            return 0;
        default:
            return arc4random_uniform(9999999)/9999.0;
    }
}

-(NSDate *)randomDate
{
    return [[NSDate date] dateByAddingTimeInterval:-(double)arc4random_uniform(999999999)];
}

-(NSString *)randomString
{
    NSString *result = [[NSUUID UUID] UUIDString];

    if (arc4random_uniform(100) == 0) {
       result = [result stringByPaddingToLength:10000 withString: @" bla" startingAtIndex:0];
    }
    
    return result;
}

-(NSData *)randomData
{
    return [[self randomString] dataUsingEncoding:NSUTF8StringEncoding];
}

-(id)randomAny
{
    switch (arc4random() % 3) {
        case 0:
            return [self randomString];
        case 1:
            return [self randomData];
        default:
            return [self randomDate];
    }
}

-(NSArray *)randomArrayWithObjectsOfClass:(Class)testClass inRealm:(RLMRealm *)realm
{
    NSUInteger itemCount = arc4random_uniform(kMaxItemsInTestArray + 1);
    
    NSMutableArray *testArray = [NSMutableArray array];
    
    for (NSUInteger i = 0; i < itemCount; i++) {
        RLMObject *object = [self randomObjectOfClass:testClass inRealm:realm tryToReuse:YES];
        [testArray addObject:object];
    }

    return testArray;
}



@end