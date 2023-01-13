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

#import <Realm/RLMConstants.h>

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

@class RLMProperty;

/**
 This class represents Realm model object schemas.

 When using Realm, `RLMObjectSchema` instances allow performing migrations and
 introspecting the database's schema.

 Object schemas map to tables in the core database.
 */
RLM_SWIFT_SENDABLE RLM_FINAL // not actually immutable, but the public API kinda is
@interface RLMObjectSchema : NSObject<NSCopying>

#pragma mark - Properties

/**
 An array of `RLMProperty` instances representing the managed properties of a class described by the schema.

 @see `RLMProperty`
 */
@property (nonatomic, readonly, copy) NSArray<RLMProperty *> *properties;

/**
 The name of the class the schema describes.
 */
@property (nonatomic, readonly) NSString *className;

/**
 The property which serves as the primary key for the class the schema describes, if any.
 */
@property (nonatomic, readonly, nullable) RLMProperty *primaryKeyProperty;

/**
 Whether this object type is embedded.
 */
@property (nonatomic, readonly) BOOL isEmbedded;

/**
 Whether this object is asymmetric.
 */
@property (nonatomic, readonly) BOOL isAsymmetric;

#pragma mark - Methods

/**
 Retrieves an `RLMProperty` object by the property name.

 @param propertyName The property's name.

 @return An `RLMProperty` object, or `nil` if there is no property with the given name.
 */
- (nullable RLMProperty *)objectForKeyedSubscript:(NSString *)propertyName;

/**
 Returns whether two `RLMObjectSchema` instances are equal.
 */
- (BOOL)isEqualToObjectSchema:(RLMObjectSchema *)objectSchema;

@end

RLM_HEADER_AUDIT_END(nullability, sendability)
