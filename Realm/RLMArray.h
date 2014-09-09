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

@class RLMObject, RLMRealm;

/**
 
 RLMArray is the primary container type in Realm.
 Unlike an NSArray, RLMArrays hold a single type, specified by the `objectClassName` property.
 This is referred to in these docs as the “type” of the array.
 
 RLMArrays can be queried with the same predicates as RLMObject and RLMRealm,
 so you can easily chain queries to further filter query results.
 
 RLMArrays fulfill 2 primary purposes:
 
 - Hold the results of a query. Using one of the query methods on RLMRealm or RLMObject will return a typed RLMArray of results.
 - Allow the declaration of one-to-many relationships. See RLMObject class documentation for details.
 
 RLMArrays cannot be created directly. RLMArray properties on RLMObjects are
 lazily created when accessed, or can be obtained by querying a Realm.
 */

@interface RLMArray : NSObject<NSFastEnumeration>

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
 Indicates if the RLMArray is readOnly. 
 YES for RLMArray instances returned from predicate queries and object enumeration.
 */
@property (nonatomic, readonly, getter = isReadOnly) BOOL readOnly;

/**
 The Realm in which this array is persisted. Returns nil for standalone arrays.
 */
@property (nonatomic, readonly) RLMRealm *realm;

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
 
 @param objects     An NSArray or RLMArray of objects of the class contained by this RLMArray.
 */
- (void)addObjectsFromArray:(id)objects;

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
 
 @return                An RLMArray of objects that match the given predicate
 */
- (RLMArray *)objectsWhere:(NSString *)predicateFormat, ...;

/**
 Get objects matching the given predicate in the RLMArray.
 
 @param predicate   The predicate to filter the objects.
 
 @return            An RLMArray of objects that match the given predicate
 */
- (RLMArray *)objectsWithPredicate:(NSPredicate *)predicate;

/**
 Get a sorted RLMArray from an existing RLMArray
 
 @param property    The property name to sort by.
 @param ascending   The direction to sort by.
 
 @return    An RLMArray sorted by the specified property.
 */
- (RLMArray *)arraySortedByProperty:(NSString *)property ascending:(BOOL)ascending;

#pragma mark -


/**---------------------------------------------------------------------------------------
 *  @name Aggregating Property Values
 *  ---------------------------------------------------------------------------------------
 */

/**
 Returns the minimum (lowest) value of the given property

 NSNumber *min = [array minOfProperty:@"age"];

 @warning You cannot use this method on RLMObject, RLMArray, and NSData properties.

 @param property The property to look for a minimum on. Only properties of type int, float, double and NSDate are supported.

 @return The minimum value for the property amongst objects in an RLMArray.
 */
-(id)minOfProperty:(NSString *)property;

/**
 Returns the maximum (highest) value of the given property of objects in an RLMArray

 NSNumber *max = [array maxOfProperty:@"age"];

 @warning You cannot use this method on RLMObject, RLMArray, and NSData properties.

 @param property The property to look for a maximum on. Only properties of type int, float, double and NSDate are supported.

 @return The maximum value for the property amongst objects in an RLMArray
 */
-(id)maxOfProperty:(NSString *)property;

/**
 Returns the sum of the given property for objects in an RLMArray.
 
 NSNumber *sum = [array sumOfProperty:@"age"];
 
 @warning You cannot use this method on RLMObject, RLMArray, and NSData properties.
 
 @param property The property to calculate sum on. Only properties of type int, float and double are supported.
 
 @return The sum of the given property over all objects in an RLMArray.
 */
-(NSNumber *)sumOfProperty:(NSString *)property;

/**
 Returns the average of a given property for objects in an RLMArray.
 
 NSNumber *average = [table averageOfProperty:@"age"];
 
 @warning You cannot use this method on RLMObject, RLMArray, and NSData properties.
 
 @param property The property to calculate average on. Only properties of type int, float and double are supported.
 
 @return    The average for the given property amongst objects in an RLMArray. This will be of type double for both
            float and double properties.
 */
-(NSNumber *)averageOfProperty:(NSString *)property;


#pragma mark -


/**---------------------------------------------------------------------------------------
 *  @name Serializing an Array to JSON
 *  ---------------------------------------------------------------------------------------
 */
/**
 Returns the RLMArray and the RLMObjects it contains as a JSON string.
 
 @return    JSON string representation of this RLMArray.
 */
- (NSString *)JSONString;


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

