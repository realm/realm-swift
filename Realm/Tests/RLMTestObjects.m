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

#import "RLMTestObjects.h"

#pragma mark - RLMTestObject

@implementation RLMTestObject
@end

#pragma mark - AllTypesObject

@implementation AllTypesObject
@end

#pragma mark - AggregateObject

@implementation AggregateObject
@end

#pragma mark - PersonObject

@implementation PersonObject
@end

#pragma mark - Company

@implementation Company
@end

#pragma mark - ArrayPropertyObject

@implementation ArrayPropertyObject
@end

#pragma mark - RLMDynamicObject

@implementation RLMDynamicObject
@end

#pragma mark - EnumPerson

@implementation EnumPerson
@end

#pragma mark - DogObject

@implementation DogObject
@end

#pragma mark - OwnerObject

@implementation OwnerObject
@end

#pragma mark - CircleObject

@implementation CircleObject
@end

#pragma mark - MixedObject

@implementation MixedObject
@end

#pragma mark - CustomAccessors

@implementation CustomAccessors
@end

#pragma mark - InvalidSubclassObject

@implementation InvalidSubclassObject
@end

#pragma mark - BaseClassTestObject

@implementation BaseClassTestObject
@end

#pragma mark - SimpleObject

@implementation SimpleObject
@end

#pragma mark - AgeObject

@implementation AgeObject
@end

#pragma mark - KeyedObject

@implementation KeyedObject
@end

#pragma mark - DefaultObject

@implementation DefaultObject

+ (NSDictionary *)defaultPropertyValues
{
    NSString *binaryString = @"binary";
    NSData *binaryData = [binaryString dataUsingEncoding:NSUTF8StringEncoding];
    
    return @{@"intCol" : @12,
             @"floatCol" : @88.9f,
             @"doubleCol" : @1002.892,
             @"boolCol" : @YES,
             @"dateCol" : [NSDate dateWithTimeIntervalSince1970:999999],
             @"stringCol" : @"potato",
             @"binaryCol" : binaryData,
             @"mixedCol" : @"foo"};
}

@end

#pragma mark - NoDefaultObject

@implementation NoDefaultObject
@end

#pragma mark - IgnoredURLObject

@implementation IgnoredURLObject

+ (NSArray *)ignoredProperties
{
    return @[@"url"];
}

@end

#pragma mark - IndexedObject

@implementation IndexedObject

+ (RLMPropertyAttributes)attributesForProperty:(NSString *)propertyName
{
    RLMPropertyAttributes superAttributes = [super attributesForProperty:propertyName];
    if ([propertyName isEqualToString:@"name"]) {
        superAttributes |= RLMPropertyAttributeIndexed;
    }
    return superAttributes;
}

@end

#pragma mark - NonRealmPersonObject

@implementation NonRealmPersonObject
@end

#pragma mark - PersonQueryObject

@implementation PersonQueryObject
@end

#pragma mark - AllPropertyTypesObject

@implementation AllPropertyTypesObject
@end

#pragma mark - TestQueryObject

@implementation TestQueryObject
@end

#pragma mark - SimpleMisuseObject

@implementation SimpleMisuseObject

+ (NSDictionary *)defaultPropertyValues
{
    return @{@"stringCol" : @""};
}

@end
