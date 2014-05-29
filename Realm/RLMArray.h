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
 
 RLMArrays contains RLMObjects of a single type.
 
 They are used to hold the results of a query, or to hold multiple RLMObjects of the same type
 on an RLMObject property (e.g. an RLMObject of class Person can have a property “dogs” that contains
 an RLMArray of several RLMObjects of class Dog.)

 
 **If your first property on the RLMObject class contained by the RLMArray is an NSString, you can also use keyed subscripting**:
 
     myArray[@"foo"] // will return the first object whose first property is equal to “foo”
     myArray[@"foo"] = someObject;
 
 RLMArrays provide the same query interface as an RLMRealm, so you can easily chain queries
 and do refinements on top of query results. This chaining is very efficient and will have
 minimal impact on overall query performance.
 */

@interface RLMArray : NSObject<NSFastEnumeration>

/**---------------------------------------------------------------------------------------
 *  @name Initializing & Accessing an Array
 *  ---------------------------------------------------------------------------------------
 */

/** 
 Initialize an RLMArray.
 
 @param objectClassName     The class name of object this RLMArray will hold.

 @return                    An initialized RLMArray instance.
*/
- (instancetype)initWithObjectClassName:(NSString *)objectClassName;

/**
 Number of objects in the RLMArray.
 */
@property (nonatomic, readonly) NSUInteger count;

/**
 The object class of objects in the RLMArray.
 */
@property (nonatomic, readonly) Class objectClass;

#pragma mark -

/**---------------------------------------------------------------------------------------
 *  @name Reading Objects from an Array
 * ---------------------------------------------------------------------------------------
 */

/**
 Returns the object at the index specified.
 
 @param index   The index to look up.
 
 @return An object.
 */
- (id)objectAtIndex:(NSUInteger)index;

/**
 Returns the first object.
 
 Returns nil if called on an empty RLMArray.
 
 @return An object (of the same type as returned from the objectClass selector).
 */
- (id)firstObject;

/**
 Returns the last object.

 Returns nil if called on an empty RLMArray.

 @return An object (of the same type as returned from the objectClass selector).
 */
- (id)lastObject;


#pragma mark -


/**---------------------------------------------------------------------------------------
 *  @name Adding, Removing, and Replacing Objects on an Array
 *  ---------------------------------------------------------------------------------------
 */

/**
 Adds an object to the end of the RLMArray.
 
 @warning This method can only be called during a write transaction.
 
 @param object  An object (of the same type as returned from the objectClass selector).
 */
- (void)addObject:(RLMObject *)object;

/**
 Adds an array of object to the bottom of the RLMTable.
 
 @warning This method can only be called during a write transaction.
 
 @param objects     An NSArray or RLMArray of objects. The contained objects must be of the type returned
                    from the objectClass selector.
 */
- (void)addObjectsFromArray:(id)objects;

/**
 Inserts an object at the given index.
 
 Throws an exception when called with an index greater than the number of objects in this RLMArray.
 
 @warning This method can only be called during a write transaction.
 
 @param anObject  An object (of the same type as returned from the objectClass selector).
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
 @param anObject    An object (of the same type as returned from the objectClass selector).
 */
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;


#pragma mark -


/**---------------------------------------------------------------------------------------
 *  @name Querying an Array for Objects
 *  ---------------------------------------------------------------------------------------
 */
/**
 Gets the index of an object.
 
 Returns NSNotFound if the object is not found in this RLMArray.
 
 @param object  An object (of the same type as returned from the objectClass selector).
 */
- (NSUInteger)indexOfObject:(RLMObject *)object;

/**
 Gets the index of the first object matching the predicate.
 
 Returns NSNotFound if the object is not found in this RLMArray.
 
 @param predicate   The argument can be an NSPredicate, a predicte string, or predicate format string
                    which can accept variable arguments.
 */
- (NSUInteger)indexOfObjectWhere:(id)predicate, ...;

/**
 Get objects matching the given predicate in the RLMArray.
 
 @param predicate   The argument can be an NSPredicate, a predicte string, or predicate format string
                    which can accept variable arguments.
 
 @return            An RLMArray of objects that match the given predicate
 */
- (RLMArray *)objectsWhere:(id)predicate, ...;

/**
 Get an ordered RLMArray of objects matching the given predicate in the RLMArray.
 
 @param predicate   The argument can be an NSPredicate, a predicte string, or predicate format string
                    which can accept variable arguments.
 @param order       This argument determines how the results are sorted. It can be an NSString containing
 t                  he property name, or an NSSortDescriptor with the property name and order.
 
 @return            An RLMArray of objects that match the predicate ordered by the given order.
 */
- (RLMArray *)objectsOrderedBy:(id)order where:(id)predicate, ...;


#pragma mark -


/**---------------------------------------------------------------------------------------
 *  @name Querying for Aggregate Results on an Array
 *  ---------------------------------------------------------------------------------------
 */

/**
 Returns the minimum (lowest) value of the given property 
 
 NSNumber *min = [array minOfProperty:@"age"];
 
 @warning You can only use this method on properties with the following types: int, float & double.
 @bug Properties of type NSDate or NSString are not supported (yet).
 @bug Properties of type RLMArray are not supported (yet). *i.e.* you cannot search on subproperties.
 
 @param property The property to look for a minimum on. Only properties of type int, float and double are supported.
 
 @return The minimum value for the property amongst objects in an RLMArray.
 */
-(id)minOfProperty:(NSString *)property;

/**
 Returns the maximum (highest) value of the given property of objects in an RLMArray
 
 NSNumber *max = [array maxOfProperty:@"age"];
 
 @warning You can only use this method on properties with the following types: int, float & double.
 @bug Properties of type NSString are not supported (yet).
 @bug Properties of type RLMArray are not supported (yet). *i.e.* you cannot search on subproperties.
 
 @param property The property to look for a maximum on. Only properties of type int, float and double are supported.
 
 @return The maximum value for the property amongst objects in an RLMArray
 */
-(id)maxOfProperty:(NSString *)property;

/**
 Returns the sum of the given property for objects in an RLMArray.
 
 NSNumber *sum = [array sumOfProperty:@"age"];
 
 @warning You can only use this method on properties with the following types: int, float & double.
 @bug Properties of type NSDate or NSString are not supported (yet).
 @bug Properties of type RLMArray are not supported (yet). *i.e.* you cannot search on subproperties.
 
 @param property The property to calculate sum on. Only properties of type int, float and double are supported.
 
 @return The sum of the given property over all objects in an RLMArray.
 */
-(NSNumber *)sumOfProperty:(NSString *)property;

/**
 Returns the average of a givne property for objects in an RLMArray.
 
 NSNumber *average = [table averageOfProperty:@"age"];
 
 @warning You can only use this method on properties with the following types: int, float & double.
 @bug Properties of type NSDate or NSString are not supported (yet).
 @bug Properties of type RLMArray are not supported (yet). *i.e.* you cannot search on subproperties.
 
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
 Returns a JSON string of an RLMArray and all of its objects.
 
 @return    JSON string representation of this RLMArray.
 */
- (NSString *)JSONString;


#pragma mark -


- (id)objectAtIndexedSubscript:(NSUInteger)index;
- (void)setObject:(id)newValue atIndexedSubscript:(NSUInteger)index;

@end

