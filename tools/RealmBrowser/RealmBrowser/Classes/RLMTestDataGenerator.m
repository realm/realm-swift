//
//  RLMTestDataGenerator.m
//  Realm
//
//  Created by Gustaf Kugelberg on 26/08/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "RLMTestDataGenerator.h"
#import <Realm/Realm.h>

const NSUInteger kMaxItemsInTestArray = 12;

@interface RLMTestDataGenerator ()

@property (nonatomic) NSArray *classNames;
@property (nonatomic) NSDictionary *existingObjects;

@end


@implementation RLMTestDataGenerator

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

-(RLMObject *)randomObjectOfClass:(Class)class inRealm:(RLMRealm *)realm
{
    return [self randomObjectOfClass:class inRealm:realm tryToReuse:NO];
}

-(RLMObject *)randomObjectOfClass:(Class)class inRealm:(RLMRealm *)realm tryToReuse:(BOOL)reuse
{
    NSMutableArray *existingObjectsOfRequiredClass = self.existingObjects[class.className];
    NSUInteger existingCount = existingObjectsOfRequiredClass.count;
    
    if (reuse && existingCount > 0) {
        NSUInteger index = arc4random_uniform((u_int32_t)existingCount);
        
        return existingObjectsOfRequiredClass[index];
    }
    
    RLMObjectSchema *objectSchema = [realm.schema schemaForClassName:class.className];
    
    NSMutableArray *propertyValues = [NSMutableArray array];
    
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
                propertyValue = @"<Any>";
                break;
                
            case RLMPropertyTypeObject:
                propertyValue = [self randomObjectOfClass:NSClassFromString(property.objectClassName) inRealm:realm tryToReuse:YES];
                break;
        }
        
        [propertyValues addObject:propertyValue];
    }
    
    RLMObject *newObject = [class createInRealm:realm withObject:propertyValues];
    [existingObjectsOfRequiredClass addObject:newObject];
    
    return newObject;
}

-(BOOL)randomBool
{
    return arc4random() % 2 == 0;
}

-(NSInteger)randomInteger
{
    return arc4random_uniform(9999999);
}

-(float)randomFloat
{
    return arc4random_uniform(9999999)/(1.0f + arc4random_uniform(9999));
}

-(double)randomDouble
{
    return arc4random_uniform(9999999)/(1.0 + arc4random_uniform(9999));
}

-(NSDate *)randomDate
{
    return [[NSDate date] dateByAddingTimeInterval:-(double)arc4random_uniform(999999999)];
}

-(NSString *)randomString
{
    NSArray *names = @[@"John", @"Jane", @"Tom", @"Dick", @"Harry", @"Jack", @"Jill"];
    NSString *name = names[arc4random_uniform((u_int32_t)names.count)];
    
    NSArray *surnames = @[@"Purple", @"Red", @"Brown", @"Pink", @"Black", @"Orange"];
    NSString *surname = surnames[arc4random_uniform((u_int32_t)surnames.count)];
    
    return [NSString stringWithFormat:@"%@ %@", name, surname];
}

-(NSString *)randomData
{
    return @"<Data>";
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

