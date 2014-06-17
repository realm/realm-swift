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

#import <Foundation/Foundation.h>
#import "RLMObject.h"

#pragma mark - RLMTestObject

@interface RLMTestObject : RLMObject

@property (nonatomic, copy) NSString *column;

@end

RLM_ARRAY_TYPE(RLMTestObject)

#pragma mark - AllTypesObject

@interface AllTypesObject : RLMObject
@property BOOL           boolCol;
@property int            intCol;
@property float          floatCol;
@property double         doubleCol;
@property NSString      *stringCol;
@property NSData        *binaryCol;
@property NSDate        *dateCol;
@property bool           cBoolCol;
@property long           longCol;
@property id             mixedCol;
@property RLMTestObject *objectCol;
//@property AgeTable      *tableCol;
@end

#pragma mark - AggregateObject

@interface AggregateObject : RLMObject

@property int intCol;
@property float floatCol;
@property double doubleCol;
@property BOOL boolCol;
@property NSDate *dateCol;

@end

#pragma mark - PersonObject

@interface PersonObject : RLMObject

@property NSString *name;
@property int age;
@property BOOL hired;

@end

RLM_ARRAY_TYPE(PersonObject)  //Defines an RLMArray<PersonObject> type

#pragma mark - Company

@interface Company : RLMObject

@property RLMArray<PersonObject> *employees;

@end

#pragma mark - ArrayPropertyObject

@interface ArrayPropertyObject : RLMObject

@property NSString *name;
@property RLMArray<RLMTestObject> *array;

@end

#pragma mark - RLMDynamicObject

@interface RLMDynamicObject : RLMObject

@property (nonatomic, copy) NSString *column;
@property (nonatomic) NSInteger integer;

@end

#pragma mark - EnumPerson

@interface EnumPerson : RLMObject

@property NSString * Name;
@property int Age;
@property bool Hired;

@end

#pragma mark - DogObject

@interface DogObject : RLMObject

@property NSString *dogName;

@end

#pragma mark - OwnerObject

@interface OwnerObject : RLMObject

@property NSString *name;
@property DogObject *dog;

@end

#pragma mark - CircleObject

@interface CircleObject : RLMObject

@property NSString *data;
@property CircleObject *next;

@end

#pragma mark - MixedObject

@interface MixedObject : RLMObject

@property (nonatomic, assign) BOOL hired;
@property (nonatomic, strong) id other;
@property (nonatomic, assign) NSInteger age;

@end

#pragma mark - CustomAccessors

@interface CustomAccessors : RLMObject

@property (getter = getThatName) NSString * name;
@property (setter = setTheInt:) int age;

@end

#pragma mark - InvalidSubclassObject

@interface InvalidSubclassObject : RLMTestObject

@property NSString *invalid;

@end

#pragma mark - BaseClassTestObject

@interface BaseClassTestObject : RLMObject

@property NSInteger intCol;

@end

@interface BaseClassTestObject ()

@property (nonatomic, copy) NSString *stringCol;

@end

#pragma mark - SimpleObject

@interface SimpleObject : RLMObject

@property NSString *name;
@property int age;
@property BOOL hired;

@end

#pragma mark - AgeObject

@interface AgeObject : RLMObject

@property int age;

@end

#pragma mark - KeyedObject

@interface KeyedObject : RLMObject

@property NSString * name;
@property int objID;

@end

#pragma mark - DefaultObject

@interface DefaultObject : RLMObject

@property int intCol;
@property float floatCol;
@property double doubleCol;
@property BOOL boolCol;
@property NSDate *dateCol;
@property NSString *stringCol;
@property NSData *binaryCol;
@property id mixedCol;

@end

#pragma mark - NoDefaultObject

@interface NoDefaultObject : RLMObject

@property NSString *stringCol;
@property int intCol;

@end

#pragma mark - IgnoredURLObject

@interface IgnoredURLObject : RLMObject

@property NSString *name;
@property NSURL *url;

@end

#pragma mark - IndexedObject

@interface IndexedObject : RLMObject

@property NSString *name;
@property NSInteger age;

@end

#pragma mark - NonRealmPersonObject

@interface NonRealmPersonObject : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;

@end

#pragma mark - PersonQueryObject

@interface PersonQueryObject : RLMObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;

@end

#pragma mark - AllPropertyTypesObject

@interface AllPropertyTypesObject : RLMObject

@property (nonatomic, assign) BOOL boolCol;
@property (nonatomic, copy) NSDate *dateCol;
@property (nonatomic, assign) double doubleCol;
@property (nonatomic, assign) float floatCol;
@property (nonatomic, assign) NSInteger intCol;
@property (nonatomic, copy) NSString *stringCol;
@property (nonatomic, copy) id mixedCol;

@end

#pragma mark - TestQueryObject

@interface TestQueryObject : RLMObject

@property (nonatomic, assign) NSInteger int1;
@property (nonatomic, assign) NSInteger int2;
@property (nonatomic, assign) float float1;
@property (nonatomic, assign) float float2;
@property (nonatomic, assign) double double1;
@property (nonatomic, assign) double double2;
@property (nonatomic, copy) NSString *recordTag;

@end

#pragma mark - SimpleMisuseObject

@interface SimpleMisuseObject : RLMObject

@property (nonatomic, copy) NSString *stringCol;
@property (nonatomic, assign) NSInteger intCol;

@end
