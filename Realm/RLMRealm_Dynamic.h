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

#import "RLMRealm.h"
#import "RLMObjectSchema.h"

@interface RLMRealm (Dynamic)

// full constructor
+ (instancetype)realmWithPath:(NSString *)path
                     readOnly:(BOOL)readonly
                      dynamic:(BOOL)dynamic
                       schema:(RLMSchema *)customSchema
                        error:(NSError **)outError;

/**---------------------------------------------------------------------------------------
 *  @name Getting Objects from a Realm
 * ---------------------------------------------------------------------------------------
 */
/**
 Get all objects of a given type in this Realm.

 @param className   The name of the RLMObject subclass to retrieve on e.g. `MyClass.className`.

 @return    An RLMArray of all objects in this realm of the given type.

 @see       RLMObject allObjects
 */
- (RLMArray *)allObjects:(NSString *)className;

/**
 Get objects matching the given predicate from the this Realm.

 The preferred way to get objects of a single class is to use the class methods on RLMObject.

 @param className       The type of objects you are looking for (name of the class).
 @param predicateFormat The predicate format string which can accept variable arguments.

 @return    An RLMArray of results matching the given predicate.

 @see       RLMObject objectsWhere:
 */
- (RLMArray *)objects:(NSString *)className where:(NSString *)predicateFormat, ...;

/**
 Get objects matching the given predicate from the this Realm.

 The preferred way to get objects of a single class is to use the class methods on RLMObject.

 @param className   The type of objects you are looking for (name of the class).
 @param predicate   The predicate to filter the objects.

 @return    An RLMArray of results matching the given predicate.

 @see       RLMObject objectsWhere:
 */
- (RLMArray *)objects:(NSString *)className withPredicate:(NSPredicate *)predicate;

@end

@interface RLMObjectSchema (Dynamic)
/**
 Initialize an RLMObjectSchema with classname, objectClass, and an array of properties

 @param objectClassName     The name of the class used to refer to objects of this type.
 @param objectClass         The objective-c class used when creating instances of this type.
 @param properties          An array RLMProperty describing the persisted properties for this type.

 @return    An initialized instance of RLMObjectSchema.
 */
- (instancetype)initWithClassName:(NSString *)objectClassName objectClass:(Class)objectClass properties:(NSArray *)properties;
@end

@interface RLMProperty (Dynamic)
/**
 Initialize an RLMProperty

 @param name            The property name.
 @param type            The property type.
 @param objectClassName The object type used for Object and Array types.
 @param attributes      A bitmask of attributes for this property.

 @return    An initialized instance of RLMProperty.
 */
- (instancetype)initWithName:(NSString *)name
                        type:(RLMPropertyType)type
             objectClassName:(NSString *)objectClassName
                  attributes:(RLMPropertyAttributes)attributes;
@end
