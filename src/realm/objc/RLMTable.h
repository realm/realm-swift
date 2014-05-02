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

#import "RLMViewProtocol.h"

@class RLMView;
@class RLMQuery;
@class RLMDescriptor;
@class RLMRow;

/**
 
 RLMTables contain your objects (RLMRow subclasses).
 
 You can use indexed subscripting to access your data:
    
    myTable[2] // will return the object stored in the second row in the RLMable.
    myTable[2] = someObject;
 
 **If your first property on your RLMRow subclass is a _string_**, you can also use keyed subscripting:
 
    myTable[@"foo"] // will return the first object whose first property is equal to “foo”
    myTable[@"foo"] = someObject;
 
 To query, you can use NSPredicates and an optional NSSortDescriptor
 
    [[RLMTransactionManager managerForDefaultRealm] readUsingBlock:^(RLMRealm *realm) {
        RLMTable *table = [realm tableWithName:@"Dogs" objectClass:[RLMDogObject class]];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"age = %@", @3];
        RLMRow *r = [table find:predicate];     // returns only the first object that matches
        r[@"age"] …                             // outputs the value for the “age” property
 
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"age = %@", @1];
        RLMView *v = [table where:predicate];   // returns a view containing all matches
        v[0]@"age"] …
 
        NSSortDescriptor * boolSort = [NSSortDescriptor sortDescriptorWithKey:@"hired" ascending:YES];
        RLMView *v = [table where:predicate orderBy:boolSort] // returns a sorted view containing all matches
        v[0]@"age"] …
    }];

 
 @warning All Table access should be done from within an RLMRealm / RLMTransactionManager. You will receive 
 an error if trying to access an RLMTable directly.
 */

@interface RLMTable : NSObject <RLMView,NSFastEnumeration>


@property (nonatomic, readonly) RLMDescriptor *descriptor;

// Standalone tables
-(instancetype)init;
-(instancetype)initWithObjectClass:(Class)objectClass;
-(instancetype)initWithColumns:(NSArray *)columns;

// Working with columns
-(NSUInteger)addColumnWithName:(NSString *)name type:(RLMType)type;
-(void)renameColumnWithIndex:(NSUInteger)colIndex to:(NSString *)newName;
-(void)removeColumnWithIndex:(NSUInteger)colIndex;

// Column manipulation
-(NSString *)nameOfColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)indexOfColumnWithName:(NSString *)name;
-(RLMType)columnTypeOfColumnWithIndex:(NSUInteger)colIndex;

/**---------------------------------------------------------------------------------------
 *  @name Writing & Updating Objects in a Table
 *  ---------------------------------------------------------------------------------------
 */
/**
 Adds an object to the bottom of the RLMTable.
 
 If data is nil, an empty row with the default values is added.
 
 @warning This method can only be called from inside a write transaction.
 
 @param data An object (of the same type as the RLMRow subclass used on this RLMTable).
 */
-(void)addRow:(NSObject *)data;

/**
 Adds an object at the specified position in the RLMTable
 
 @warning All rows after rowIndex will be offset by one position!
 @warning This method can only be called from inside a write transaction.
 
 @param anObject An object (of the same type as the RLMRow subclass used on this RLMTable).
 @param rowIndex The position you want this object inserted at.
 
 @see updateRow:atIndex:
 */
-(void)insertRow:(NSObject *)anObject atIndex:(NSUInteger)rowIndex;

/**
 Updates (replaces) the object at the specified position in the RLMTable
 
 @warning This method can only be called from inside a write transaction.
 
 @param anObject An object (of the same type as the RLMRow subclass used on this RLMTable).
 @param rowIndex The position you want this object inserted at.
 
 @see insertRow:atIndex:
 */
-(void)updateRow:(NSObject *)anObject atIndex:(NSUInteger)rowIndex;

/**
 Deletes the object at the position specified.
 
 @warning This method can only be called from inside a write transaction.
 
 @param rowIndex The position of the object you want to delete.
 */
-(void)removeRowAtIndex:(NSUInteger)rowIndex;

/**
 Deletes the object at the bottom of the RLMTable.
 
 @warning This method can only be called from inside a write transaction.
 */
-(void)removeLastRow;

/**
 Removes all objects from the RLMTable.
 
 @warning This method can only be called from inside a write transaction.
 */
-(void)removeAllRows;


/**---------------------------------------------------------------------------------------
 *  @name Reading Objects from a Table
 *  ---------------------------------------------------------------------------------------
 */
/**
 Number of objects in this RLMTable.
 */
@property (nonatomic, readonly) NSUInteger rowCount;
@property (nonatomic, readonly) NSUInteger columnCount;
/**
 Returns the object at the index specified.
 
 @param rowIndex The index to look up.
 
 @return An object (of the same type as the RLMRow subclass used on this RLMTable).
 */
-(id)rowAtIndex:(NSUInteger)rowIndex;
/**
 Returns the object at the top of the RLMTable.
 
 @return An object (of the same type as the RLMRow subclass used on this RLMTable).
 */
-(id)firstRow;
/**
 Returns the object at the bottom of the RLMTable.
 
 @return An object (of the same type as the RLMRow subclass used on this RLMTable).
 */
-(id)lastRow;

// internal method for keyed+indexed subscripting
-(id)objectAtIndexedSubscript:(NSUInteger)rowIndex;
-(void)setObject:(id)newValue atIndexedSubscript:(NSUInteger)rowIndex;
-(id)objectForKeyedSubscript:(NSString *)key;
-(void)setObject:(id)newValue forKeyedSubscript:(NSString *)key;

// Only supported on string columns with an index
-(RLMView *)distinctValuesInColumnWithIndex:(NSUInteger)colIndex;

/**---------------------------------------------------------------------------------------
 *  @name Querying a Table
 *  ---------------------------------------------------------------------------------------
 */
/**
 Returns the **first** object matching the [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html)
 
    RLMRow *r = [table firstWhere:@"name == \"name10\""];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"age = %@", @3];
    r = [table firstWhere:predicate];
 
 @param predicate An [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html). You can also use the predicate format string directly instead of the NSPredicate.
 
 @return The **first** object matching the Predicate. It will be of the same type as the RLMRow subclass used on this RLMTable
 @see allWhere:
 */
-(id)firstWhere:(id)predicate;
/**
 Returns **all** objects matching the [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html).
 
    RLMView *v = [table where:@"name == \"name10\""];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"age = %@", @3];
    v = [table where:predicate];
 
 @param predicate An [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html). You can also use the predicate format string directly instead of the NSPredicate.
 
 @return A reference to an RLMView containing **all** objects matching the Predicate. Objects contained will be of the same type as the RLMRow subclass used on this RLMTable
 @see firstWhere:
 @see allWhere:orderBy:
 */
-(RLMView *)allWhere:(id)predicate;
/**
 Returns **all** objects matching the [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html), in the order specified by the [NSSortDescriptor](https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/classes/NSSortDescriptor_Class/Reference/Reference.html).
 
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"age = %@", @3];
    NSSortDescriptor * reverseSort = [NSSortDescriptor sortDescriptorWithKey:@"age" ascending:NO];
    v = [table where:predicate oderBy:reverseSort];
 
    v = [table where:predicate orderBy:@"age"];
 
 @param predicate An [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html). You can also use the NSString instead of the NSPredicate.
 @param order     An [NSSortDescriptor](https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/classes/NSSortDescriptor_Class/Reference/Reference.html). You can also use the descriptor format string directly instead of the NSSortDescriptor.
 
 @return A reference to an RLMView containing **all** objects matching the Predicate, sorted according to the Sort Descriptor. Objects contained will be of the same type as the RLMRow subclass used on this RLMTable
 
 @see allWhere:
 */
-(RLMView *)allWhere:(id)predicate orderBy:(id)order;


/**---------------------------------------------------------------------------------------
 *  @name Aggregate Querying on a Table
 *  ---------------------------------------------------------------------------------------
 */
/**
 Returns the number of objects matching an [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html)
 
    NSUInteger count = [table countWhere:@"name == \"name10\""];
 
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"age = %@", @3];
    count = [table countWhere:predicate];
 
 @param predicate An [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html). You can also use the predicate format string directly instead of the NSPredicate.
 
 @return The number of objects matching the Predicate.
 */
-(NSUInteger)countWhere:(id)predicate;
/**
 Returns the minimum (lowest) value of a property for objects matching an [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html) in a column.
 
    NSNumber *min = [table minInColumn:@"age" where:@"name == \"name10\""];
 
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"age = %@", @3];
    min = [table minInColumn:@"age" where:predicate];
 
 @warning You can only use this method on properties with the following types: int, float & double.
 @bug Properties of type NSDate or NSString are not supported (yet).
 @bug Properties of type RLMTable are not supported (yet). *i.e.* you cannot search on subproperties.
 
 @param property The property to look for a minimum on. Only properties of type int, float and double are supported.
 @param predicate An [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html). You can also use the predicate format string directly instead of the NSPredicate.
 
 @return The minimum value for the property amongst objects matching the Predicate.
 */
-(id)minInColumn:(NSString *)columnName where:(id)predicate;
/**
 Returns the maximum (highest) value of a property for objects matching an [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html).
 
    NSNumber *max = [table maxInColumn:@"age" where:@"name == \"name10\""];
 
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"age = %@", @3];
    max = [table maxInColumn:@"age" where:predicate];
 
 @warning You can only use this method on properties with the following types: int, float & double.
 @bug Properties of type NSString are not supported (yet).
 @bug Properties of type RLMTable are not supported (yet). *i.e.* you cannot search on subproperties.
 
 @param property The property to look for a maximum on. Only properties of type int, float and double are supported.
 @param predicate An [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html). You can also use the predicate format string directly instead of the NSPredicate.
 
 @return The maximum value for the property amongst objects matching the Predicate.
 */
-(id)maxInColumn:(NSString *)columnName where:(id)predicate;
/**
 Returns the sum of a property for objects matching an [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html).
 
    NSNumber *sum = [table sumOfColumn:@"age" where:@"name == \"name10\""];
 
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"age = %@", @3];
    sum = [table sumOfColumn:@"age" where:predicate];
 
 
 @warning You can only use this method on properties with the following types: int, float & double.
 @bug Properties of type NSDate or NSString are not supported (yet).
 @bug Properties of type RLMTable are not supported (yet). *i.e.* you cannot search on subproperties.
 
 @param columnName An NSString specifying the column's name. Only properties of type int, float and double are supported.
 @param predicate An [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html). You can also use the predicate format string directly instead of the NSPredicate.
 
 @return The sum for the property amongst objects matching the Predicate.
 */
-(NSNumber *)sumOfColumn:(NSString *)columnName where:(id)predicate;
/**
 Returns the average of a property for objects matching an [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html).
 
    NSNumber *average = [table averageOfColumn:@"age" where:@"name == \"name10\""];
 
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"age = %@", @3];
    average = [table averageOfColumn:@"age" where:predicate];
 
 @warning You can only use this method on properties with the following types: int, float & double.
 @bug Properties of type NSDate or NSString are not supported (yet).
 @bug Properties of type RLMTable are not supported (yet). *i.e.* you cannot search on subproperties.
 
 @param columnName An NSString specifying the column's name. Only properties of type int, float and double are supported.
 @param predicate An [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html). You can also use the predicate format string directly instead of the NSPredicate.
 
 @return The average for the property amongst objects matching the Predicate.
 */
-(NSNumber *)averageOfColumn:(NSString *)columnName where:(id)predicate;

// Indices
-(void)createIndexInColumnWithIndex:(NSUInteger)colIndex;
-(BOOL)isIndexCreatedInColumnWithIndex:(NSUInteger)colIndex;

// Table type and schema
-(BOOL)isEqual:(id)otherTableClass;
-(id)castToTypedTableClass:(Class)typedTableClass;
// FIXME: implement method below and reenable and document it
// -(BOOL)hasSameDescriptorAs:(Class)otherTableClass;

-(RLMType)mixedTypeForColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;

@end

