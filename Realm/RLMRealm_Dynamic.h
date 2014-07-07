//
//  RLMRealm_Dynamic.h
//  Realm
//
//  Created by Ari Lazier on 7/7/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "RLMRealm.h"

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

 @see       RLMObject objectsWithPredicateFormat:
 */
- (RLMArray *)objects:(NSString *)className withPredicateFormat:(NSString *)predicateFormat, ...;

/**
 Get objects matching the given predicate from the this Realm.

 The preferred way to get objects of a single class is to use the class methods on RLMObject.

 @param className   The type of objects you are looking for (name of the class).
 @param predicate   The predicate to filter the objects.

 @return    An RLMArray of results matching the given predicate.

 @see       RLMObject objectsWithPredicateFormat:
 */
- (RLMArray *)objects:(NSString *)className withPredicate:(NSPredicate *)predicate;

@end

