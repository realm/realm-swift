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

@implementation RLMTestDataGenerator

+(BOOL)createRealmAtUrl:(NSURL *)url withClassesNamed:(NSArray *)testClassNames elementCount:(NSUInteger)objectCount
{
    NSError *error;
    RLMRealm *realm = [RLMRealm realmWithPath:url.path readOnly:NO error:&error];
    
    if (error) {
        return NO;
    }
    
    [realm beginWriteTransaction];
    
    for (NSString *testClassName in testClassNames) {
        Class testClass = NSClassFromString(testClassName);

        for (NSUInteger index = 0; index < objectCount; index++) {
            [self randomObjectOfClass:testClass inRealm:realm];
        }
    }
    
    [realm commitWriteTransaction];
    
    return YES;
}

+(RLMObject *)randomObjectOfClass:(Class)testClass inRealm:(RLMRealm *)realm
{
    RLMObjectSchema *objectSchema = [realm.schema schemaForClassName:[testClass className]];

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
                propertyValue = @[];
                break;
                
            case RLMPropertyTypeData:
                propertyValue = [self randomData];
                break;
                
            case RLMPropertyTypeAny:
                propertyValue = @"<Any>";
                break;
                
            case RLMPropertyTypeObject:
                propertyValue = [self randomObjectOfClass:NSClassFromString(property.objectClassName) inRealm:realm];
                break;
        }
        
        [propertyValues addObject:propertyValue];
    }
    
    return [testClass createInRealm:realm withObject:propertyValues];
}

+(BOOL)randomBool
{
    return arc4random() % 2 == 0;
}

+(NSInteger)randomInteger
{
    return arc4random_uniform(9999999);
}

+(float)randomFloat
{
    return arc4random_uniform(9999999)/(1.0f + arc4random_uniform(9999));
}

+(double)randomDouble
{
    return arc4random_uniform(9999999)/(1.0 + arc4random_uniform(9999));
}

+(NSDate *)randomDate
{
    return [[NSDate date] dateByAddingTimeInterval:-(double)arc4random_uniform(999999999)];
}

+(NSString *)randomString
{
    NSArray *names = @[@"John", @"Jane", @"Tom", @"Dick", @"Harry", @"Jack", @"Jill"];
    NSString *name = names[arc4random_uniform((u_int32_t)names.count)];
    
    NSArray *surnames = @[@"Purple", @"Red", @"Brown", @"Pink", @"Black", @"Orange"];
    NSString *surname = surnames[arc4random_uniform((u_int32_t)surnames.count)];
    
    return [NSString stringWithFormat:@"%@ %@", name, surname];
}

+(NSString *)randomData
{
    return @"<Data>";
}

+(NSArray *)randomArrayOfClass:(Class)testClass inRealm:(RLMRealm *)realm
{
    NSUInteger itemCount = arc4random_uniform(kMaxItemsInTestArray);
    
    NSMutableArray *testArray = [NSMutableArray array];
    
    for (NSUInteger i = 0; i < itemCount; i++) {
        RLMObject *object = [self randomObjectOfClass:testClass inRealm:realm];
        [testArray addObject:object];
    }

    return testArray;
}

@end

