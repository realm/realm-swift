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

#import <Foundation/Foundation.h>
#import <Realm/RLMCollection.h>

@class RLMObject, RLMRealm, RLMResults;

/**
 
 RLMArray is the container type in Realm used to define to-many relationships.

 Unlike an NSArray, RLMArrays hold a single type, specified by the `objectClassName` property.
 This is referred to in these docs as the “type” of the array.
 
 RLMArrays can be queried with the same predicates as RLMObject and RLMResults.

 RLMArrays cannot be created directly. RLMArray properties on RLMObjects are
 lazily created when accessed, or can be obtained by querying a Realm.
 */

@interface RLMArray : NSObject<RLMCollection, NSFastEnumeration>

/**---------------------------------------------------------------------------------------
 *  @name RLMArray Properties
 *  ---------------------------------------------------------------------------------------
 */

/**
 Number of objects in the array.
 */
@property (nonatomic, readonly, assign) NSUInteger count;

/**
 The class name (i.e. type) of the RLMObjects contained in this RLMArray.
 */
@property (nonatomic, readonly, copy) NSString *objectClassName;

/**
 The Realm in which this array is persisted. Returns nil for standalone arrays.
 */
@property (nonatomic, readonly) RLMRealm *realm;

/**
 Indicates if an array can no longer be accessed.
 */
@property (nonatomic, readonly, getter = isInvalidated) BOOL invalidated;

#pragma mark -

/**---------------------------------------------------------------------------------------
 *  @name Accessing Objects from an Array
 * ---------------------------------------------------------------------------------------
 */

/**
 Returns the object at the index specified.
 
 @param index   The index to look up.
 
 @return An RLMObject of the class contained by this RLMArray.
 */
- (id)objectAtIndex:(NSUInteger)index;

/**
 Returns the first object in the array.
 
 Returns `nil` if called on an empty RLMArray.
 
 @return An RLMObject of the class contained by this RLMArray.
 */
- (id)firstObject;

/**
 Returns the last object in the array.

 Returns `nil` if called on an empty RLMArray.

 @return An RLMObject of the class contained by this RLMArray.
 */
- (id)lastObject;


#pragma mark -


/**---------------------------------------------------------------------------------------
 *  @name Adding, Removing, and Replacing Objects in an Array
 *  ---------------------------------------------------------------------------------------
 */

/**
 Adds an object to the end of the array.
 
 @warning This method can only be called during a write transaction.
 
 @param object  An RLMObject of the class contained by this RLMArray.
 */
- (void)addObject:(RLMObject *)object;

/**
 Adds an array of objects at the end of the array.
 
 @warning This method can only be called during a write transaction.
 
 @param objects     An enumerable object such as NSArray or RLMResults which contains objects of the
                    same class as this RLMArray.
 */
- (void)addObjects:(id<NSFastEnumeration>)objects;

/**
 Inserts an object at the given index.
 
 Throws an exception when called with an index greater than the number of objects in this RLMArray.
 
 @warning This method can only be called during a write transaction.
 
 @param anObject  An object (of the same type as returned from the objectClassName selector).
 @param index   The array index at which the object is inserted.
 */
- (void)insertObject:(RLMObject *)anObject atIndex:(NSUInteger)index;

/**
 Removes an object at a given index.
 
 Throws an exception when called with an index greater than the number of objects in this RLMArray.

 @warning This method can only be called during a write transaction.
 
 @param index   The array index identifying the object to be removed.
 */
- (void)removeObjectAtIndex:(NSUInteger)index;

/**
 Removes the last object in an RLMArray.
 
 @warning This method can only be called during a write transaction.
*/
- (void)removeLastObject;

/**
 Removes all objects from an RLMArray.
 
 @warning This method can only be called during a write transaction.
 */
- (void)removeAllObjects;

/**
 Replaces an object at the given index with a new object.

 Throws an exception when called with an index greater than the number of objects in this RLMArray.

 @warning This method can only be called during a write transaction.
 
 @param index       The array index of the object to be replaced.
 @param anObject    An object (of the same type as returned from the objectClassName selector).
 */
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(RLMObject *)anObject;


#pragma mark -


/**---------------------------------------------------------------------------------------
 *  @name Querying an Array
 *  ---------------------------------------------------------------------------------------
 */
/**
 Gets the index of an object.
 
 Returns NSNotFound if the object is not found in this RLMArray.
 
 @param object  An object (of the same type as returned from the objectClassName selector).
 */
- (NSUInteger)indexOfObject:(RLMObject *)object;

/**
 Gets the index of the first object matching the predicate.
 
 @param predicateFormat The predicate format string which can accept variable arguments.
 
 @return    Index of object or NSNotFound if the object is not found in this RLMArray.
 */
- (NSUInteger)indexOfObjectWhere:(NSString *)predicateFormat, ...;

/**
 Gets the index of the first object matching the predicate.
 
 @param predicate   The predicate to filter the objects.
 
 @return    Index of object or NSNotFound if the object is not found in this RLMArray.
 */
- (NSUInteger)indexOfObjectWithPredicate:(NSPredicate *)predicate;

/**
 Get objects matching the given predicate in the RLMArray.
 
 @param predicateFormat The predicate format string which can accept variable arguments.
 
 @return                An RLMResults of objects that match the given predicate
 */
- (RLMResults *)objectsWhere:(NSString *)predicateFormat, ...;

/**
 Get objects matching the given predicate in the RLMArray.
 
 @param predicate   The predicate to filter the objects.
 
 @return            An RLMResults of objects that match the given predicate
 */
- (RLMResults *)objectsWithPredicate:(NSPredicate *)predicate;

/**
 Get a sorted RLMResults from an RLMArray
 
 @param property    The property name to sort by.
 @param ascending   The direction to sort by.
 
 @return    An RLMResults sorted by the specified property.
 */
- (RLMResults *)sortedResultsUsingProperty:(NSString *)property ascending:(BOOL)ascending;

/**
 Get a sorted RLMResults from an RLMArray

 @param properties  An array of `RLMSortDescriptor`s to sort by.

 @return    An RLMResults sorted by the specified properties.
 */
- (RLMResults *)sortedResultsUsingDescriptors:(NSArray *)properties;

#pragma mark -

- (id)objectAtIndexedSubscript:(NSUInteger)index;
- (void)setObject:(id)newValue atIndexedSubscript:(NSUInteger)index;

#pragma mark -

/**---------------------------------------------------------------------------------------
 *  @name Unavailable Methods
 *  ---------------------------------------------------------------------------------------
 */

/**
 -[RLMArray init] is not available because RLMArrays cannot be created directly.
 RLMArray properties on RLMObjects are lazily created when accessed, or can be obtained by querying a Realm.
 */
- (instancetype)init __attribute__((unavailable("RLMArrays cannot be created directly")));

/**
 +[RLMArray new] is not available because RLMArrays cannot be created directly.
 RLMArray properties on RLMObjects are lazily created when accessed, or can be obtained by querying a Realm.
 */
+ (instancetype)new __attribute__((unavailable("RLMArrays cannot be created directly")));

@end

/**
 An RLMSortDescriptor stores a property name and a sort order for use with
 `sortedResultsUsingDescriptors:`. It is similar to NSSortDescriptor, but supports
 only the subset of functionality which can be efficiently run by the query
 engine. RLMSortDescriptor instances are immutable.
 */
@interface RLMSortDescriptor : NSObject

/**
 The name of the property which this sort descriptor orders results by.
 */
@property (nonatomic, readonly) NSString *property;

/**
 Whether this descriptor sorts in ascending or descending order.
 */
@property (nonatomic, readonly) BOOL ascending;

/**
 Returns a new sort descriptor for the given property name and order.
 */
+ (instancetype)sortDescriptorWithProperty:(NSString *)propertyName ascending:(BOOL)ascending;

/**
 Returns a copy of the receiver with the sort order reversed.
 */
- (instancetype)reversedSortDescriptor;

@end

@interface RLMArray (Swift)
// for use only in Swift class definitions
- (instancetype)initWithObjectClassName:(NSString *)objectClassName;
@end
