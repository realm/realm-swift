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

#pragma mark AllTypesObject

@implementation AllTypesObject
@end

@implementation ArrayOfAllTypesObject
@end

@implementation LinkToAllTypesObject
@end

#pragma mark - Real Life Objects
#pragma mark -

@implementation EmployeeObject
@end

@implementation CompanyObject
@end

@implementation DogObject
@end

@implementation DogArrayObject
@end

@implementation OwnerObject
@end

#pragma mark - Specific Use Objects
#pragma mark -

@implementation MixedObject
@end

@implementation CustomAccessorsObject
@end

@implementation BaseClassStringObject
@end

@implementation CircleObject
@end

@implementation CircleArrayObject
@end

@implementation ArrayPropertyObject
@end

@implementation DynamicObject
@end

@implementation AggregateObject
@end

@implementation PrimaryStringObject
+ (NSString *)primaryKey {
    return @"stringCol";
}
@end

@interface ReadOnlyPropertyObject ()
@property (readwrite) int readOnlyPropertyMadeReadWriteInClassExtension;
@end

@implementation ReadOnlyPropertyObject
- (NSNumber *)readOnlyUnsupportedProperty {
    return nil;
}
@end
