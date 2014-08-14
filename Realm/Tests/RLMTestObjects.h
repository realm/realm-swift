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

#import "RLMObject.h"
#import "RLMRealm.h"

#pragma mark - Abstract Objects
#pragma mark -

#pragma mark SingleTypeObjects

@interface StringObject : RLMObject

@property NSString *stringCol;

@end

@interface IntObject : RLMObject

@property int intCol;

@end

@interface FloatObject : RLMObject

@property float floatCol;

@end

@interface DoubleObject : RLMObject

@property double doubleCol;

@end

@interface BoolObject : RLMObject

@property BOOL boolCol;

@end

@interface DateObject : RLMObject

@property NSDate *dateCol;

@end

@interface BinaryObject : RLMObject

@property NSData *binaryCol;

@end

@interface UTF8Object : RLMObject
@property NSString *柱колоéнǢкƱаم;
@end

RLM_ARRAY_TYPE(StringObject)
RLM_ARRAY_TYPE(IntObject)

#pragma mark AllTypesObject

@interface AllTypesObject : RLMObject

@property BOOL          boolCol;
@property int           intCol;
@property float         floatCol;
@property double        doubleCol;
@property NSString     *stringCol;
@property NSData       *binaryCol;
@property NSDate       *dateCol;
@property bool          cBoolCol;
@property int64_t     longCol;
@property id            mixedCol;
@property StringObject *objectCol;

@end

RLM_ARRAY_TYPE(AllTypesObject)

@interface LinkToAllTypesObject : RLMObject
@property AllTypesObject *allTypesCol;
@end

@interface ArrayOfAllTypesObject : RLMObject
@property RLMArray<AllTypesObject> *array;
@end

#pragma mark - Real Life Objects
#pragma mark -

#pragma mark EmployeeObject

@interface EmployeeObject : RLMObject

@property NSString *name;
@property int age;
@property BOOL hired;

@end

RLM_ARRAY_TYPE(EmployeeObject)

#pragma mark CompanyObject

@interface CompanyObject : RLMObject

@property NSString *name;
@property RLMArray<EmployeeObject> *employees;

@end

#pragma mark DogObject

@interface DogObject : RLMObject
@property NSString *dogName;
@property int age;
@end

#pragma mark OwnerObject

@interface OwnerObject : RLMObject

@property NSString *name;
@property DogObject *dog;

@end

#pragma mark - Specific Use Objects
#pragma mark -

#pragma mark MixedObject

@interface MixedObject : RLMObject

@property BOOL hired;
@property id other;
@property NSInteger age;

@end

#pragma mark CustomAccessorsObject

@interface CustomAccessorsObject : RLMObject

@property (getter = getThatName) NSString *name;
@property (setter = setTheInt:)  int age;

@end

#pragma mark BaseClassStringObject

@interface BaseClassStringObject : RLMObject

@property NSInteger intCol;

@end

@interface BaseClassStringObject ()

@property NSString *stringCol;

@end

#pragma mark CircleObject

@interface CircleObject : RLMObject

@property NSString *data;
@property CircleObject *next;

@end

#pragma mark ArrayPropertyObject

@interface ArrayPropertyObject : RLMObject

@property NSString *name;
@property RLMArray<StringObject> *array;
@property RLMArray<IntObject> *intArray;

@end

#pragma mark - Class Extension

@interface RLMRealm ()

+ (instancetype)realmWithPath:(NSString *)path
                     readOnly:(BOOL)readonly
                      dynamic:(BOOL)dynamic
                        error:(NSError **)outError;

@end

#pragma mark DynamicObject

@interface DynamicObject : RLMObject

@property NSString *stringCol;
@property NSInteger intCol;

@end

#pragma mark AggregateObject

@interface AggregateObject : RLMObject

@property int     intCol;
@property float   floatCol;
@property double  doubleCol;
@property BOOL    boolCol;
@property NSDate *dateCol;

@end
