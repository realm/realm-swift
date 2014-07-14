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
