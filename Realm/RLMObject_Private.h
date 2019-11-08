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

#import <Realm/RLMObjectBase_Dynamic.h>

NS_ASSUME_NONNULL_BEGIN

@class RLMProperty, RLMArray;
typedef NS_ENUM(int32_t, RLMPropertyType);

FOUNDATION_EXTERN void RLMInitializeWithValue(RLMObjectBase *, id, RLMSchema *);

// RLMObject accessor and read/write realm
@interface RLMObjectBase () {
@public
    RLMRealm *_realm;
    __unsafe_unretained RLMObjectSchema *_objectSchema;
}

// shared schema for this class
+ (nullable RLMObjectSchema *)sharedSchema;

+ (nullable NSArray<RLMProperty *> *)_getPropertiesWithInstance:(id)obj;
+ (bool)_realmIgnoreClass;

@end

@interface RLMDynamicObject : RLMObject

@end

// Calls valueForKey: and re-raises NSUndefinedKeyExceptions
FOUNDATION_EXTERN id _Nullable RLMValidatedValueForProperty(id object, NSString *key, NSString *className);

// Compare two RLObjectBases
FOUNDATION_EXTERN BOOL RLMObjectBaseAreEqual(RLMObjectBase * _Nullable o1, RLMObjectBase * _Nullable o2);

typedef void (^RLMObjectNotificationCallback)(NSArray<NSString *> *_Nullable propertyNames,
                                              NSArray *_Nullable oldValues,
                                              NSArray *_Nullable newValues,
                                              NSError *_Nullable error);
FOUNDATION_EXTERN RLMNotificationToken *RLMObjectAddNotificationBlock(RLMObjectBase *obj, RLMObjectNotificationCallback block);

// Returns whether the class is a descendent of RLMObjectBase
FOUNDATION_EXTERN BOOL RLMIsObjectOrSubclass(Class klass);

// Returns whether the class is an indirect descendant of RLMObjectBase
FOUNDATION_EXTERN BOOL RLMIsObjectSubclass(Class klass);

FOUNDATION_EXTERN const NSUInteger RLMDescriptionMaxDepth;

@interface RLMManagedPropertyAccessor : NSObject
+ (void)initializeObject:(void *)object parent:(RLMObjectBase *)parent property:(RLMProperty *)property;
+ (id)get:(void *)pointer;
@end

NS_ASSUME_NONNULL_END
