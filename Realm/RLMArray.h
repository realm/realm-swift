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
 
 RLMArray is the primary container type used in Realm for working with sets of RLMObjects. Primarily,
 RLMArray is used to add sets to a RLMRealm or return sets from an RLMRealm in response to a query. 
 
 ### RLMArray vs. NSArray
 Unlike an NSArray, RLMArrays hold a single type, specified by the `objectClassName` property.
 This is referred to in these docs as the “type” of the array.
 
 ### Chaining queries
 RLMArrays can be queried with the same predicates as RLMObject and RLMRealm,
 so you can easily chain queries to further filter query results.
 
 ### Using indexed subscripting

 Realm supports indexed subscripting to access & set RLMObjects in an RLMArray.

 For example, to put an RLMObject into an RLMArray, the syntax would look like this:

    myRLMArray[index] = myRLMObject;

 The syntax to retrieve the RLMObject stored at an index would look like this:
 
    RLMObject * myRLMObject = myRLMArray[index];
 */

@interface RLMArray : NSObject<NSFastEnumeration>

/**---------------------------------------------------------------------------------------
 *  @name Initializing & Accessing an Array
 *  ---------------------------------------------------------------------------------------
 */

/** 
 Initializes a typed RLMArray.

 The type of an array is equal to the RLMObject subclass type of the RLMObject instances it holds.
 
 @param  objectClassName  The name of the RLMObject subclass this RLMArray will hold.

 @warning                 RLMArrays are typed. You must specify an RLMObject subclass name 
                          during initialization and can only add objects of this type to the RLMArray.

 @return                  An initialized RLMArray instance.
*/
- (instancetype)initWithObjectClassName:(NSString *)objectClassName;

/**
 The number of RLMObject instances in the RLMArray.
 */
@property (nonatomic, readonly) NSUInteger count;

/**
 The name (i.e. type) of the RLMObject subclass in this RLMArray.
 */
@property (nonatomic, readonly) NSString *objectClassName;

#pragma mark -

/**---------------------------------------------------------------------------------------
 *  @name Accessing Objects from an RLMArray
 * ---------------------------------------------------------------------------------------
 */

/**
 Returns the RLMObject at the specified RLMArray index.
 
 @param  index  The index of the RLMObject to retrieve.
 
 @return        The RLMObject stored at the specified index.
 */
- (id)objectAtIndex:(NSUInteger)index;

/**
 Returns the first RLMObject in the RLMArray.
 
 Returns `nil` if called on an empty RLMArray.
 
 @return  The first RLMObject in the RLMArray.
 */
- (id)firstObject;

/**
 Returns the last RLMObject in the RLMArray.

 Returns `nil` if called on an empty RLMArray.

 @return  The last RLMObject in the RLMArray.
 */
- (id)lastObject;


#pragma mark -


/**---------------------------------------------------------------------------------------
 *  @name Adding, Removing, and Replacing Objects in an RLMArray
 *  ---------------------------------------------------------------------------------------
 */

/**
 Adds an RLMObject to the end of the RLMArray.
 
 @warning        This method can only be called during a write transaction.
 
 @param  object  The RLMObject to add to the end of the RLMArray.
 */
- (void)addObject:(RLMObject *)object;

/**
 Adds an NSArray or RLMArray of RLMObjects to the end of the RLMArray.
 
 @warning         This method can only be called during a write transaction.
 
 @param  objects  An NSArray or RLMArray of objects to add to the end of the RLMArray.
 */
- (void)addObjectsFromArray:(id)objects;

/**
 Inserts an RLMObject into the RLMArray at the specified index.
 
 @param  anObject  An object (of the same type as returned from the objectClassName selector).
 @param  index     The array index to insert the RLMObject at.
 
 @warning          This method can only be called during a write transaction.
 
 @exception        Thrown if the specified index is greater than the number of RLMObjects in the RLMArray.

 */
- (void)insertObject:(RLMObject *)anObject atIndex:(NSUInteger)index;

/**
 Removes the RLMObject stored at the specified index from the RLMArray.
 
 @param  index  The RLMArray index of the RLMObject to be removed.
 
 @exception     Thrown if the specified index is greater than the number of RLMObjects in the RLMArray.

 @warning       This method can only be called during a write transaction.
 */
- (void)removeObjectAtIndex:(NSUInteger)index;

/**
 Removes the last RLMObject from the RLMArray.
 
 @warning  This method can only be called during a write transaction.
*/
- (void)removeLastObject;

/**
 Empties an RLMArray.
 
 @warning  This method can only be called during a write transaction.
 */
- (void)removeAllObjects;

/**
 Replaces an RLMObject at the specified index in the RLMArray with another RLMObject.

 @param  index     The index of the RLMObject to be replaced.
 @param  anObject  The RLMObject to add.

 @exception        Thrown when called with an index greater than the number of RLMObjects 
                   in the RLMArray.

 @warning          This method can only be called during a write transaction.
 */
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;

/**
 Retrieves the RLMObject stored at the specified index in the RLMArray.
 
 @param  index  The index of the RLMObject to be retrieved.
 
 @return        The RLMObject stored at the specified index.
 */
- (id)objectAtIndexedSubscript:(NSUInteger)index;

/**
 Replaces the RLMObject stored at the specified index in the RLMArray with a different RLMObject.
 
 @param  newValue  The RLMObject to store at the specified index.
 @param  index     The index of the RLMObject to be replaced.
 */
- (void)setObject:(id)newValue atIndexedSubscript:(NSUInteger)index;


#pragma mark -


/**---------------------------------------------------------------------------------------
 *  @name Querying an RLMArray
 *  ---------------------------------------------------------------------------------------
 */
/**
 Retrieves the index of an RLMObject in the RLMArray.
 
 @param  object  The RLMObject whose index should be retrieved.
 
 @return         The index of the specified RLMObject. If not found, an NSNotFound instance is returned.
 */
- (NSUInteger)indexOfObject:(RLMObject *)object;

/**
 Retrieves the index of the first RLMObject that matches the specified predicate.
 
 @param  predicate  An NSPredicate, a predicate string, or predicate format string that can accept 
                    variable arguments.
 
 @return            The index of the first matching RLMObject. If not found, an NSNotFound instance is returned.
 */
- (NSUInteger)indexOfObjectWhere:(id)predicate, ...;

/**
 Retrieves an RLMArray of all RLMObjects from the RLMArray that match the specified predicate.
 
 @param  predicate  An NSPredicate, a predicate string, or predicate format string that can accept 
                    variable arguments.
 
 @return            An RLMArray of all the RLMObjects that matched the given predicate.
 */
- (RLMArray *)objectsWhere:(id)predicate, ...;

/**
 Retrieves an ordered RLMArray of all RLMObjects that match the specified predicate from the RLMArray.
 
 @param  predicate  An NSPredicate, a predicate string, or predicate format string that can accept 
                    variable arguments.
 @param  order      An NSString containing the property name, or an NSSortDescriptor with the property 
                    name and order, that the results should be sorted by.
 
 @return            An ordered RLMArray of all the RLMObjects that matched the specified predicate.
 */
- (RLMArray *)objectsOrderedBy:(id)order where:(id)predicate, ...;


#pragma mark -


/**---------------------------------------------------------------------------------------
 *  @name Aggregating Property Values
 *  ---------------------------------------------------------------------------------------
 */

/**
 Finds the minimum (lowest) value of the specified RLMObject property present in the RLMArray.
 
 @param  property  The property to look for a minimum on. Only RLMObject properties of type `int`, 
                   `float` and `double` are supported.
 
 @warning          Properties with values of type RLMObject, RLMArray, and NSData are not supported.
 
 @return           The minimum value of the specified property.
 */
-(id)minOfProperty:(NSString *)property;

/**
 Finds the maximum (highest) value of the specified RLMObject property present in the RLMArray.
 
 @param  property  The property to look for a maximum on. Only properties of type `int`, `float` and `double` are supported.
 
 @warning          Properties with values of type RLMObject, RLMArray, and NSData are not supported.

 @return           The maximum value for the specified property.
 */
-(id)maxOfProperty:(NSString *)property;

/**
 Calculates the sum of all values for the specified RLMObject property in the RLMArray.
 
 @param  property  The property to calculate the sum on. Only properties of type `int`, `float` and `double` are supported.
 
 @warning          Properties with values of type RLMObject, RLMArray, and NSData are not supported.

 @return           The sum of all values of the specified property over all objects in the RLMArray.
 */
-(NSNumber *)sumOfProperty:(NSString *)property;

/**
 Calculates the average of all values for the specified RLMObject property in the RLMArray.
  
 @param  property  The property to calculate the average on. Only properties of type `int`, `float` and `double` are supported.
 
 @warning          Properties with values of type RLMObject, RLMArray, and NSData are not supported.

 @return           The average of all values of the specified property over all objects in the RLMArray. This will be 
                   of type `double` for both `float` and `double` properties.
 */
-(NSNumber *)averageOfProperty:(NSString *)property;


#pragma mark -


/**---------------------------------------------------------------------------------------
 *  @name Serializing an Array to JSON
 *  ---------------------------------------------------------------------------------------
 */
/**
 Returns the RLMArray and the RLMObjects it contains formatted as a JSON string.
 
 @return  A JSON string representation of this RLMArray and all its RLMObjects.
 */
- (NSString *)JSONString;

@end

