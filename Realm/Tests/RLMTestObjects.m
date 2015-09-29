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

#pragma mark - Abstract Objects
#pragma mark -

#pragma mark OneTypeObjects

@implementation StringObject
@end

@implementation IntObject
@end

@implementation AllIntSizesObject
@end

@implementation FloatObject
@end

@implementation DoubleObject
@end

@implementation BoolObject
@end

@implementation DateObject
@end

@implementation BinaryObject
@end

@implementation UTF8Object
@end

@implementation IndexedStringObject
+ (NSArray *)indexedProperties
{
    return @[@"stringCol"];
}
@end

@implementation LinkStringObject
@end

@implementation LinkIndexedStringObject
@end

@implementation RequiredPropertiesObject
+ (NSArray *)requiredProperties {
    return @[@"stringCol", @"binaryCol"];
}
@end

#pragma mark AllTypesObject

@implementation AllTypesObject
@end

@implementation ArrayOfAllTypesObject
@end

@implementation LinkToAllTypesObject
@end

#pragma mark - Real Life Objects
#pragma mark -

#pragma mark EmployeeObject

@implementation EmployeeObject
@end

#pragma mark CompanyObject

@implementation CompanyObject
@end

#pragma mark DogObject

@implementation DogObject
@end

#pragma mark OwnerObject

@implementation OwnerObject
@end

#pragma mark - Specific Use Objects
#pragma mark -

#pragma mark MixedObject

@implementation MixedObject
@end

#pragma mark CustomAccessorsObject

@implementation CustomAccessorsObject
@end

#pragma mark BaseClassStringObject

@implementation BaseClassStringObject
@end

#pragma mark CircleObject

@implementation CircleObject
@end

#pragma mark CircleArrayObject

@implementation CircleArrayObject
@end

#pragma mark ArrayPropertyObject

@implementation ArrayPropertyObject
@end

#pragma mark DynamicObject

@implementation DynamicObject
@end

#pragma mark AggregateObject

@implementation AggregateObject
@end

#pragma mark PrimaryStringObject

@implementation PrimaryStringObject
+ (NSString *)primaryKey {
    return @"stringCol";
}
@end

#pragma mark ReadOnlyPropertyObject

@interface ReadOnlyPropertyObject ()
@property (readwrite) int readOnlyPropertyMadeReadWriteInClassExtension;
@end

@implementation ReadOnlyPropertyObject
- (NSNumber *)readOnlyUnsupportedProperty {
    return nil;
}
@end

#pragma mark IntegerArrayPropertyObject

@implementation IntegerArrayPropertyObject
@end

#pragma mark FakeObject

@implementation FakeObject
+ (NSArray *)ignoredProperties { return nil; }
+ (NSArray *)indexedProperties { return nil; }
+ (NSString *)primaryKey { return nil; }
+ (NSArray *)requiredProperties { return nil; }
@end
