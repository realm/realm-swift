////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>

@class RLMObject;

/**
 
 RLMArray is the primary container type in Realm.
 Unlike an NSArray, RLMArrays hold a single type, specified by the `objectClassName` property.
 This is referred to in these docs as the “type” of the array.
 
 RLMArrays can be queried with the same predicates as RLMObject and RLMRealm,
 so you can easily chain queries to further filter query results.
 
 RLMArrays fulfill 2 primary purposes:
 
 - Hold the results of a query. Using one of the query methods on RLMRealm or RLMObject will return a typed RLMArray of results.
 - Allow the declaration of one-to-many relationships. See RLMObject class documentation for details.
 
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
 
 Returns NSNotFound if the object is not found in this RLMArray.
 
 @param predicate   The argument can be an NSPredicate, a predicate string, or predicate format string
                    which can accept variable arguments.
 */
- (NSUInteger)indexOfObjectWhere:(id)predicate, ...;

/**
 Get objects matching the given predicate in the RLMArray.
 
 @param predicate   The argument can be an NSPredicate, a predicate string, or predicate format string
                    which can accept variable arguments.
 
 @return            An RLMArray of objects that match the given predicate
 */
- (RLMArray *)objectsWhere:(id)predicate, ...;

/**
 Get an ordered RLMArray of objects matching the given predicate in the RLMArray.
 
 @param predicate   The argument can be an NSPredicate, a predicate string, or predicate format string
                    which can accept variable arguments.
 @param order       This argument determines how the results are sorted. It can be an NSString containing
 t                  he property name, or an NSSortDescriptor with the property name and order.
 
 @return            An RLMArray of objects that match the predicate ordered by the given order.
 */
- (RLMArray *)objectsOrderedBy:(id)order where:(id)predicate, ...;


#pragma mark -


/**---------------------------------------------------------------------------------------
 *  @name Aggregating Property Values
 *  ---------------------------------------------------------------------------------------
 */

/**
 Returns the minimum (lowest) value of the given property 
 
 NSNumber *min = [array minOfProperty:@"age"];
 
 @warning You cannot use this method on RLMObject, RLMArray, and NSData properties.
 
 @param property The property to look for a minimum on. Only properties of type int, float and double are supported.
 
 @return The minimum value for the property amongst objects in an RLMArray.
 */
-(id)minOfProperty:(NSString *)property;

/**
 Returns the maximum (highest) value of the given property of objects in an RLMArray
 
 NSNumber *max = [array maxOfProperty:@"age"];
 
 @warning You cannot use this method on RLMObject, RLMArray, and NSData properties.
 
 @param property The property to look for a maximum on. Only properties of type int, float and double are supported.
 
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
 Returns the average of a givne property for objects in an RLMArray.
 
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

@end

