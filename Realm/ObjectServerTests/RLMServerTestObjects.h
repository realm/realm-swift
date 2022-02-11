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

#import "RLMTestObjects.h"

@interface Dog : RLMObject

@property RLMObjectId *_id;
@property NSString *breed;
@property NSString *name;
@property NSString *partition;
- (instancetype)initWithPrimaryKey:(RLMObjectId *)primaryKey breed:(NSString *)breed name:(NSString *)name;
@end

@interface Person : RLMObject
@property RLMObjectId *_id;
@property NSInteger age;
@property NSString *firstName;
@property NSString *lastName;
@property NSString *partition;

- (instancetype)initWithPrimaryKey:(RLMObjectId *)primaryKey age:(NSInteger)strCol firstName:(NSString *)intCol lastName:(NSString *)intCol;
+ (instancetype)john;
+ (instancetype)paul;
+ (instancetype)ringo;
+ (instancetype)george;
+ (instancetype)stuart;
@end

@interface HugeSyncObject : RLMObject
@property RLMObjectId *_id;
@property NSData *dataProp;
+ (instancetype)hugeSyncObject;
@end

@interface UUIDPrimaryKeyObject : RLMObject
@property NSUUID *_id;
@property NSString *strCol;
@property NSInteger intCol;
- (instancetype)initWithPrimaryKey:(NSUUID *)primaryKey strCol:(NSString *)strCol intCol:(NSInteger)intCol;
@end

@interface StringPrimaryKeyObject : RLMObject
@property NSString *_id;
@property NSString *strCol;
@property NSInteger intCol;
- (instancetype)initWithPrimaryKey:(NSString *)primaryKey strCol:(NSString *)strCol intCol:(NSInteger)intCol;
@end

@interface IntPrimaryKeyObject : RLMObject
@property NSInteger _id;
@property NSString *strCol;
@property NSInteger intCol;
- (instancetype)initWithPrimaryKey:(NSInteger)primaryKey strCol:(NSString *)strCol intCol:(NSInteger)intCol;
@end

@interface AllTypesSyncObject : RLMObject
@property RLMObjectId *_id;
@property BOOL boolCol;
@property bool cBoolCol;
@property int intCol;
@property double doubleCol;
@property NSString *stringCol;
@property NSData *binaryCol;
@property NSDate *dateCol;
@property int64_t longCol;
@property RLMDecimal128 *decimalCol;
@property NSUUID *uuidCol;
@property id<RLMValue> anyCol;
@property Person *objectCol;
+ (NSDictionary *)values:(int)i;
@end

RLM_COLLECTION_TYPE(Person);
@interface RLMArraySyncObject : RLMObject
@property RLMObjectId *_id;
@property RLMArray<RLMInt> *intArray;
@property RLMArray<RLMBool> *boolArray;
@property RLMArray<RLMString> *stringArray;
@property RLMArray<RLMData> *dataArray;
@property RLMArray<RLMDouble> *doubleArray;
@property RLMArray<RLMObjectId> *objectIdArray;
@property RLMArray<RLMDecimal128> *decimalArray;
@property RLMArray<RLMUUID> *uuidArray;
@property RLMArray<RLMValue> *anyArray;
@property RLM_GENERIC_ARRAY(Person) *objectArray;
@end

@interface RLMSetSyncObject : RLMObject
@property RLMObjectId *_id;
@property RLMSet<RLMInt> *intSet;
@property RLMSet<RLMBool> *boolSet;
@property RLMSet<RLMString> *stringSet;
@property RLMSet<RLMData> *dataSet;
@property RLMSet<RLMDouble> *doubleSet;
@property RLMSet<RLMObjectId> *objectIdSet;
@property RLMSet<RLMDecimal128> *decimalSet;
@property RLMSet<RLMUUID> *uuidSet;
@property RLMSet<RLMValue> *anySet;
@property RLM_GENERIC_SET(Person) *objectSet;

@property RLMSet<RLMInt> *otherIntSet;
@property RLMSet<RLMBool> *otherBoolSet;
@property RLMSet<RLMString> *otherStringSet;
@property RLMSet<RLMData> *otherDataSet;
@property RLMSet<RLMDouble> *otherDoubleSet;
@property RLMSet<RLMObjectId> *otherObjectIdSet;
@property RLMSet<RLMDecimal128> *otherDecimalSet;
@property RLMSet<RLMUUID> *otherUuidSet;
@property RLMSet<RLMValue> *otherAnySet;
@property RLM_GENERIC_SET(Person) *otherObjectSet;
@end

@interface RLMDictionarySyncObject : RLMObject
@property RLMObjectId *_id;
@property RLMDictionary<NSString *, NSNumber *><RLMString, RLMInt> *intDictionary;
@property RLMDictionary<NSString *, NSNumber *><RLMString, RLMBool> *boolDictionary;
@property RLMDictionary<NSString *, NSString *><RLMString, RLMString> *stringDictionary;
@property RLMDictionary<NSString *, NSData *><RLMString, RLMData> *dataDictionary;
@property RLMDictionary<NSString *, NSNumber *><RLMString, RLMDouble> *doubleDictionary;
@property RLMDictionary<NSString *, RLMObjectId *><RLMString, RLMObjectId> *objectIdDictionary;
@property RLMDictionary<NSString *, RLMDecimal128 *><RLMString, RLMDecimal128> *decimalDictionary;
@property RLMDictionary<NSString *, NSUUID *><RLMString, RLMUUID> *uuidDictionary;
@property RLMDictionary<NSString *, NSObject *><RLMString, RLMValue> *anyDictionary;
@property RLMDictionary<NSString *, Person *><RLMString, Person> *objectDictionary;

@end
