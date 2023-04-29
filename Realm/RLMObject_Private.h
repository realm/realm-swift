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

#import <Realm/RLMRealm.h>

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

@class RLMProperty, RLMArray, RLMSchema;
typedef NS_ENUM(int32_t, RLMPropertyType);

FOUNDATION_EXTERN void RLMInitializeWithValue(RLMObjectBase *, id, RLMSchema *);

typedef void (^RLMObjectNotificationCallback)(RLMObjectBase *_Nullable object,
                                              NSArray<NSString *> *_Nullable propertyNames,
                                              NSArray *_Nullable oldValues,
                                              NSArray *_Nullable newValues,
                                              NSError *_Nullable error);

// RLMObject accessor and read/write realm
@interface RLMObjectBase () {
@public
    RLMRealm *_realm;
    __unsafe_unretained RLMObjectSchema *_objectSchema;
}

// shared schema for this class
+ (nullable RLMObjectSchema *)sharedSchema;

+ (nullable NSArray<RLMProperty *> *)_getProperties;
+ (bool)_realmIgnoreClass;

// This enables to override the propertiesMapping in Swift, it is not to be used in Objective-C API.
+ (NSDictionary<NSString *, NSString *> *)propertiesMapping;
@end

@interface RLMDynamicObject : RLMObject

@end

// Calls valueForKey: and re-raises NSUndefinedKeyExceptions
FOUNDATION_EXTERN id _Nullable RLMValidatedValueForProperty(id object, NSString *key, NSString *className);

// Compare two RLObjectBases
FOUNDATION_EXTERN BOOL RLMObjectBaseAreEqual(RLMObjectBase * _Nullable o1, RLMObjectBase * _Nullable o2);

FOUNDATION_EXTERN RLMNotificationToken *RLMObjectBaseAddNotificationBlock(RLMObjectBase *obj,
                                                                          NSArray<NSString *> *_Nullable keyPaths,
                                                                          dispatch_queue_t _Nullable queue,
                                                                          RLMObjectNotificationCallback block);

RLMNotificationToken *RLMObjectAddNotificationBlock(RLMObjectBase *obj,
                                                    RLMObjectChangeBlock block,
                                                    NSArray<NSString *> *_Nullable keyPaths,
                                                    dispatch_queue_t _Nullable queue);

// Returns whether the class is a descendent of RLMObjectBase
FOUNDATION_EXTERN BOOL RLMIsObjectOrSubclass(Class klass);

// Returns whether the class is an indirect descendant of RLMObjectBase
FOUNDATION_EXTERN BOOL RLMIsObjectSubclass(Class klass);

FOUNDATION_EXTERN const NSUInteger RLMDescriptionMaxDepth;

FOUNDATION_EXTERN id RLMObjectFreeze(RLMObjectBase *obj) NS_RETURNS_RETAINED;

FOUNDATION_EXTERN id RLMObjectThaw(RLMObjectBase *obj);

// Gets an object identifier suitable for use with Combine. This value may
// change when an unmanaged object is added to the Realm.
FOUNDATION_EXTERN uint64_t RLMObjectBaseGetCombineId(RLMObjectBase *);

// An accessor object which is used to interact with Swift properties from obj-c
@interface RLMManagedPropertyAccessor : NSObject
// Perform any initialization required for KVO on a *unmanaged* object
+ (void)observe:(RLMProperty *)property on:(RLMObjectBase *)parent;
// Initialize the given property on a *managed* object which previous was unmanaged
+ (void)promote:(RLMProperty *)property on:(RLMObjectBase *)parent;
// Initialize the given property on a newly created *managed* object
+ (void)initialize:(RLMProperty *)property on:(RLMObjectBase *)parent;
// Read the value of the property, on either kind of object
+ (id)get:(RLMProperty *)property on:(RLMObjectBase *)parent;
// Set the property to the given value, on either kind of object
+ (void)set:(RLMProperty *)property on:(RLMObjectBase *)parent to:(id)value;
@end

@interface RLMObjectNotificationToken : RLMNotificationToken
- (void)observe:(RLMObjectBase *)obj
       keyPaths:(nullable NSArray<NSString *> *)keyPaths
          block:(RLMObjectNotificationCallback)block;
- (void)registrationComplete:(void (^)(void))completion;
@end

RLM_HEADER_AUDIT_END(nullability, sendability)
