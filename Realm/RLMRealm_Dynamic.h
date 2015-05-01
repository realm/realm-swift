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

#import <Realm/RLMRealm.h>

#import <Realm/RLMObjectSchema.h>
#import <Realm/RLMProperty.h>

@class RLMResults;

@interface RLMRealm (Dynamic)

// full constructor
+ (instancetype)realmWithPath:(NSString *)path
                          key:(NSData *)key
                     readOnly:(BOOL)readonly
                     inMemory:(BOOL)inMemory
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

 @return    An RLMResults of all objects in this realm of the given type.

 @see       RLMObject allObjects
 */
- (RLMResults *)allObjects:(NSString *)className;

/**
 Get objects matching the given predicate from the this Realm.

 The preferred way to get objects of a single class is to use the class methods on RLMObject.

 @param className       The type of objects you are looking for (name of the class).
 @param predicateFormat The predicate format string which can accept variable arguments.

 @return    An RLMResults of results matching the given predicate.

 @see       RLMObject objectsWhere:
 */
- (RLMResults *)objects:(NSString *)className where:(NSString *)predicateFormat, ...;

/**
 Get objects matching the given predicate from the this Realm.

 The preferred way to get objects of a single class is to use the class methods on RLMObject.

 @param className   The type of objects you are looking for (name of the class).
 @param predicate   The predicate to filter the objects.

 @return    An RLMResults of results matching the given predicate.

 @see       RLMObject objectsWhere:
 */
- (RLMResults *)objects:(NSString *)className withPredicate:(NSPredicate *)predicate;

/**
 Create an RLMObject of type `className` in the Realm with a given object.

 @param value   The value used to populate the object. This can be any key/value coding compliant
                object, or a JSON object such as those returned from the methods in NSJSONSerialization, or
                an NSArray with one object for each persisted property. An exception will be
                thrown if any required properties are not present and no default is set.

 When passing in an NSArray, all properties must be present, valid and in the same order as the properties defined in the model.
 */
-(RLMObject *)createObject:(NSString *)className withValue:(id)value;

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
                     indexed:(BOOL)indexed;
@end
