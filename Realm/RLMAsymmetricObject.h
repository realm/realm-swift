////////////////////////////////////////////////////////////////////////////
//
// Copyright 2022 Realm Inc.
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

#import <Realm/RLMObjectBase.h>

NS_ASSUME_NONNULL_BEGIN

@class RLMObjectSchema, RLMPropertyDescriptor;
/**
 `RLMAsymmetricObject` is a base class used to define asymmetric Realm objects.

 Asymmetric objects can only be created using the `createInRealm:`
 function, and cannot be added, removed or queried.
 When created, asymmetric objects will be synced unidirectionally to the MongoDB
 database and cannot be accessed locally.

 Incoming links from any asymmetric table are not allowed, meaning embedding
 an asymmetric object within an `RLMObject` will throw an error.

 The property types supported on `RLMAsymmetricObject` are the same as for `RLMObject`,
 except for that asymmetric objects can only link to embedded objects, so `RLMObject`
 and `RLMArray<RLMObject>` properties are not supported (`RLMEmbeddedObject` and
 `RLMArray<RLEmbeddedObject>` *are*).
 */
@interface RLMAsymmetricObject : RLMObjectBase

#pragma mark - Creating & Initializing Objects

/**
 Creates an unmanaged instance of a Realm object.
 */
- (instancetype)init NS_DESIGNATED_INITIALIZER;

/**
 Creates an unmanaged instance of a Realm object.

 Pass in an `NSArray` or `NSDictionary` instance to set the values of the object's properties.
 */
- (instancetype)initWithValue:(id)value;

/**
 Returns the class name for a Realm object subclass.

 @warning Do not override. Realm relies on this method returning the exact class
          name.

 @return  The class name for the model class.
 */
+ (NSString *)className;

/**
 Creates an Asymmetric object, which will be synced unidirectionally and
 cannot be queried locally, only objects which inherits from `RLMAsymmetricObject`
 can be created using this method.

 Objects created using this method will not be added to the Realm.

 @warning This method may only be called during a write transaction.

 @param realm    The Realm to be used to create the asymmetric object..
 @param value    The value used to populate the object.

 @return  This will return `nil`.
 */
+ (instancetype)createInRealm:(RLMRealm *)realm withValue:(id)value __attribute__((warn_unused_result));

#pragma mark - Properties

/**
 The object schema which lists the managed properties for the object.
 */
@property (nonatomic, readonly) RLMObjectSchema *objectSchema;

#pragma mark - Dynamic Accessors

/// :nodoc:
- (nullable id)objectForKeyedSubscript:(NSString *)key;

/// :nodoc:
- (void)setObject:(nullable id)obj forKeyedSubscript:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
