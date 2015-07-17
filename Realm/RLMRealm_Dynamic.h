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

/**
 This method is useful only in specialized circumstances, for example, when opening Realm files
 retrieved externally that contain a different schema than defined in your application.
 If you are simply building an app on Realm you should consider using:
 [defaultRealm]([RLMRealm defaultRealm]) or [realmWithPath:]([RLMRealm realmWithPath:])
 
 Obtains an `RLMRealm` instance with persistence to a specific file path with
 options.
 
 @warning This method is useful only in specialized circumstances.

 @param path         Path to the file you want the data saved in.
 @param key          64-byte key to use to encrypt the data.
 @param readonly     `BOOL` indicating if this Realm is read-only (must use for read-only files)
 @param inMemory     `BOOL` indicating if this Realm is in-memory
 @param dynamic      `BOOL` indicating if this Realm is dynamic
 @param customSchema `RLMSchema` object representing the schema for the Realm
 @param outError     If an error occurs, upon return contains an `NSError` object
                     that describes the problem. If you are not interested in
                     possible errors, pass in NULL.

 @return An `RLMRealm` instance.
 
 @see RLMRealm defaultRealm
 @see RLMRealm realmWithPath:
 @see RLMRealm realmWithPath:readOnly:error:
 @see RLMRealm realmWithPath:encryptionKey:readOnly:error:
 */
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
 This method is useful only in specialized circumstances, for example, when building components
 that integrate with Realm. If you are simply building an app on Realm, it is
 recommended to use the class methods on `RLMObject`.
 
 Get all objects of a given type in this Realm.
 
 The preferred way to get objects of a single class is to use the class methods on RLMObject.
 
 @warning This method is useful only in specialized circumstances.

 @param className   The name of the RLMObject subclass to retrieve on e.g. `MyClass.className`.

 @return    An RLMResults of all objects in this realm of the given type.

 @see       RLMObject allObjects
 */
- (RLMResults *)allObjects:(NSString *)className;

/**
 This method is useful only in specialized circumstances, for example, when building components
 that integrate with Realm. If you are simply building an app on Realm, it is
 recommended to use the class methods on `RLMObject`.
 
 Get objects matching the given predicate from the this Realm.

 The preferred way to get objects of a single class is to use the class methods on RLMObject.
 
 @warning This method is useful only in specialized circumstances.

 @param className       The type of objects you are looking for (name of the class).
 @param predicateFormat The predicate format string which can accept variable arguments.

 @return    An RLMResults of results matching the given predicate.

 @see       RLMObject objectsWhere:
 */
- (RLMResults *)objects:(NSString *)className where:(NSString *)predicateFormat, ...;

/**
 This method is useful only in specialized circumstances, for example, when building components
 that integrate with Realm. If you are simply building an app on Realm, it is
 recommended to use the class methods on `RLMObject`.
 
 Get objects matching the given predicate from the this Realm.

 The preferred way to get objects of a single class is to use the class methods on RLMObject.
 
 @warning This method is useful only in specialized circumstances.

 @param className   The type of objects you are looking for (name of the class).
 @param predicate   The predicate to filter the objects.

 @return    An RLMResults of results matching the given predicate.

 @see       RLMObject objectsWhere:
 */
- (RLMResults *)objects:(NSString *)className withPredicate:(NSPredicate *)predicate;

/**
 This method is useful only in specialized circumstances, for example, when building components
 that integrate with Realm. If you are simply building an app on Realm, it is
 recommended to use [RLMObject createInDefaultRealmWithValue:].
 
 Create an RLMObject of type `className` in the Realm with a given object.
 
 @warning This method is useful only in specialized circumstances.

 @param value   The value used to populate the object. This can be any key/value coding compliant
                object, or a JSON object such as those returned from the methods in NSJSONSerialization, or
                an NSArray with one object for each persisted property. An exception will be
                thrown if any required properties are not present and no default is set.

                When passing in an NSArray, all properties must be present, valid and in the same order as 
                the properties defined in the model.
 
 @return    An RLMObject of type `className`
 */
-(RLMObject *)createObject:(NSString *)className withValue:(id)value;

@end

@interface RLMObjectSchema (Dynamic)
/**
 This method is useful only in specialized circumstances, for example, when accessing objects
 in a Realm produced externally. If you are simply building an app on Realm, it is not recommened 
 to use this method as an [RLMObjectSchema](RLMObjectSchema) is generated automatically for every [RLMObject](RLMObject) subclass.
 
 Initialize an RLMObjectSchema with classname, objectClass, and an array of properties
 
 @warning This method is useful only in specialized circumstances.

 @param objectClassName     The name of the class used to refer to objects of this type.
 @param objectClass         The objective-c class used when creating instances of this type.
 @param properties          An array RLMProperty describing the persisted properties for this type.

 @return    An initialized instance of RLMObjectSchema.
 */
- (instancetype)initWithClassName:(NSString *)objectClassName objectClass:(Class)objectClass properties:(NSArray *)properties;
@end

@interface RLMProperty (Dynamic)
/**
 This method is useful only in specialized circumstances, for example, in conjunction with 
 [RLMObjectSchema initWithClassName:objectClass:properties:]. If you are simply building an 
 app on Realm, it is not recommened to use this method.
 
 Initialize an RLMProperty
 
 @warning This method is useful only in specialized circumstances.

 @param name            The property name.
 @param type            The property type.
 @param objectClassName The object type used for Object and Array types.

 @return    An initialized instance of RLMProperty.
 */
- (instancetype)initWithName:(NSString *)name
                        type:(RLMPropertyType)type
             objectClassName:(NSString *)objectClassName
                     indexed:(BOOL)indexed
                    optional:(BOOL)optional;
@end
