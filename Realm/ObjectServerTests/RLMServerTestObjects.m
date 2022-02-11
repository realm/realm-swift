////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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

#import <Realm/Realm.h>
#import "RLMServerTestObjects.h"

#pragma mark Dog

@implementation Dog

+ (NSString *)primaryKey {
    return @"_id";
}

+ (NSArray *)requiredProperties {
    return @[@"name"];
}

+ (NSDictionary *)defaultPropertyValues {
    return @{@"_id": [RLMObjectId objectId]};
}

- (instancetype)initWithPrimaryKey:(RLMObjectId *)primaryKey breed:(NSString *)breed name:(NSString *)name {
    self = [super init];
    if (self) {
        self._id = primaryKey;
        self.breed = breed;
        self.name = name;
    }
    return self;
}

@end

#pragma mark Person

@implementation Person

+ (NSDictionary *)defaultPropertyValues {
    return @{@"_id": [RLMObjectId objectId]};
}

+ (NSString *)primaryKey {
    return @"_id";
}

+ (NSArray *)requiredProperties {
    return @[@"firstName", @"lastName", @"age"];
}

- (instancetype)initWithPrimaryKey:(RLMObjectId *)primaryKey age:(NSInteger)age firstName:(NSString *)firstName lastName:(NSString *)lastName {
    self = [super init];
    if (self) {
        self._id = primaryKey;
        self.age = age;
        self.firstName = firstName;
        self.lastName = lastName;
    }
    return self;
}

+ (instancetype)john {
    Person *john = [[Person alloc] init];
    john._id = [RLMObjectId objectId];
    john.age = 30;
    john.firstName = @"John";
    john.lastName = @"Lennon";
    return john;
}

+ (instancetype)paul {
    Person *paul = [[Person alloc] init];
    paul._id = [RLMObjectId objectId];
    paul.age = 30;
    paul.firstName = @"Paul";
    paul.lastName = @"McCartney";
    return paul;
}

+ (instancetype)ringo {
    Person *ringo = [[Person alloc] init];
    ringo._id = [RLMObjectId objectId];
    ringo.age = 30;
    ringo.firstName = @"Ringo";
    ringo.lastName = @"Starr";
    return ringo;
}

+ (instancetype)george {
    Person *george = [[Person alloc] init];
    george._id = [RLMObjectId objectId];
    george.age = 30;
    george.firstName = @"George";
    george.lastName = @"Harrison";
    return george;
}

+ (instancetype)stuart {
    Person *stuart = [[Person alloc] init];
    stuart._id = [RLMObjectId objectId];
    stuart.age = 30;
    stuart.firstName = @"Stuart";
    stuart.lastName = @"Sutcliffe";
    return stuart;
}

@end

#pragma mark HugeSyncObject

@implementation HugeSyncObject

+ (NSDictionary *)defaultPropertyValues {
    return @{@"_id": [RLMObjectId objectId]};
}

+ (NSString *)primaryKey {
    return @"_id";
}

+ (instancetype)hugeSyncObject {
    const NSInteger fakeDataSize = 1000000;
    HugeSyncObject *object = [[self alloc] init];
    char fakeData[fakeDataSize];
    memset(fakeData, 16, sizeof(fakeData));
    object.dataProp = [NSData dataWithBytes:fakeData length:sizeof(fakeData)];
    return object;
}

@end

#pragma mark AllTypeSyncObject

@implementation AllTypesSyncObject

+ (NSDictionary *)defaultPropertyValues {
    return @{@"_id": [RLMObjectId objectId]};
}

+ (NSString *)primaryKey {
    return @"_id";
}

+ (NSArray *)requiredProperties {
    return @[@"boolCol", @"cBoolcol",
             @"intCol", @"doubleCol",
             @"stringCol", @"binaryCol",
             @"dateCol", @"longCol",
             @"decimalCol", @"uuidCol", @"objectIdCol"];
}

+ (NSDictionary *)values:(int)i {
    NSString *str = [NSString stringWithFormat:@"%d", i];
    return @{
             @"boolCol": @(i % 2),
             @"cBoolCol": @(i % 2),
             @"intCol": @(i),
             @"doubleCol": @(1.11 * i),
             @"stringCol": [NSString stringWithFormat:@"%d", i],
             @"binaryCol": [str dataUsingEncoding:NSUTF8StringEncoding],
             @"dateCol": [NSDate dateWithTimeIntervalSince1970:i],
             @"longCol": @((long long)i * INT_MAX + 1),
             @"decimalCol": [[RLMDecimal128 alloc] initWithNumber:@(i)],
             @"uuidCol": i < 4 ? @[[[NSUUID alloc] initWithUUIDString:@"85d4fbee-6ec6-47df-bfa1-615931903d7e"],
                                   [[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"],
                                   [[NSUUID alloc] initWithUUIDString:@"137DECC8-B300-4954-A233-F89909F4FD89"],
                                   [[NSUUID alloc] initWithUUIDString:@"b84e8912-a7c2-41cd-8385-86d200d7b31e"]][i] :
                 [[NSUUID alloc] initWithUUIDString:@"b9d325b0-3058-4838-8473-8f1aaae410db"],
             @"anyCol": @(i+1),
             };
}

@end

#pragma mark RLMArraySyncObject

@implementation RLMArraySyncObject

+ (NSDictionary *)defaultPropertyValues {
    return @{@"_id": [RLMObjectId objectId]};
}

+ (NSString *)primaryKey {
    return @"_id";
}

+ (NSArray *)requiredProperties {
    return @[@"intArray", @"boolArray",
             @"stringArray", @"dataArray",
             @"doubleArray", @"objectIdArray",
             @"decimalArray", @"uuidArray", @"anyArray"];
}

@end

#pragma mark RLMSetSyncObject

@implementation RLMSetSyncObject

+ (NSDictionary *)defaultPropertyValues {
    return @{@"_id": [RLMObjectId objectId]};
}

+ (NSString *)primaryKey {
    return @"_id";
}

+ (NSArray *)requiredProperties {
    return @[@"intSet", @"boolSet",
             @"stringSet", @"dataSet",
             @"doubleSet", @"objectIdSet",
             @"decimalSet", @"uuidSet", @"anySet",
             @"otherIntSet", @"otherBoolSet",
             @"otherStringSet", @"otherDataSet",
             @"otherDoubleSet", @"otherObjectIdSet",
             @"otherDecimalSet", @"otherUuidSet", @"otherAnySet"];
}

@end

#pragma mark RLMDictionarySyncObject

@implementation RLMDictionarySyncObject

+ (NSDictionary *)defaultPropertyValues {
    return @{@"_id": [RLMObjectId objectId]};
}

+ (NSString *)primaryKey {
    return @"_id";
}

+ (NSArray *)requiredProperties {
    return @[@"intDictionary", @"boolDictionary", @"stringDictionary",
             @"dataDictionary", @"doubleDictionary", @"objectIdDictionary",
             @"decimalDictionary", @"uuidDictionary", @"anyDictionary"];
}

@end

#pragma mark UUIDPrimaryKeyObject

@implementation UUIDPrimaryKeyObject

+ (NSString *)primaryKey {
    return @"_id";
}

+ (NSArray *)requiredProperties {
    return @[@"strCol", @"intCol"];
}

+ (NSDictionary *)defaultPropertyValues {
    return @{@"_id": [[NSUUID alloc] initWithUUIDString:@"85d4fbee-6ec6-47df-bfa1-615931903d7e"]};
}

- (instancetype)initWithPrimaryKey:(NSUUID *)primaryKey strCol:(NSString *)strCol intCol:(NSInteger)intCol {
    self = [super init];
    if (self) {
        self._id = primaryKey;
        self.strCol = strCol;
        self.intCol = intCol;
    }
    return self;
}

@end

#pragma mark StringPrimaryKeyObject

@implementation StringPrimaryKeyObject

+ (NSString *)primaryKey {
    return @"_id";
}

+ (NSArray *)requiredProperties {
    return @[@"strCol", @"intCol"];
}

+ (NSDictionary *)defaultPropertyValues {
    return @{@"_id": @"1234567890ab1234567890ab"};
}

- (instancetype)initWithPrimaryKey:(NSString *)primaryKey strCol:(NSString *)strCol intCol:(NSInteger)intCol {
    self = [super init];
    if (self) {
        self._id = primaryKey;
        self.strCol = strCol;
        self.intCol = intCol;
    }
    return self;
}

@end

#pragma mark IntPrimaryKeyObject

@implementation IntPrimaryKeyObject

+ (NSString *)primaryKey {
    return @"_id";
}

+ (NSArray *)requiredProperties {
    return @[@"_id", @"strCol", @"intCol"];
}

+ (NSDictionary *)defaultPropertyValues {
    return @{@"_id": @1234567890};
}

- (instancetype)initWithPrimaryKey:(NSInteger)primaryKey strCol:(NSString *)strCol intCol:(NSInteger)intCol {
    self = [super init];
    if (self) {
        self._id = primaryKey;
        self.strCol = strCol;
        self.intCol = intCol;
    }
    return self;
}

@end
