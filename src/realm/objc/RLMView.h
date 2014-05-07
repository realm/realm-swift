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

#import "RLMType.h"
#import "RLMTable.h"

/**
 [allWhere: queries](RLMTable.html#//api/name/allWhere:) on an RLMTable return RLMView objects.
 They work as virtual tables containing just the matched rows. You can interact with an RLMView just like a regular RLMtable.
 
  You can use indexed subscripting to access your data:
    
    myView[2] // will return the second match in your query
    myView[2] = someObject; // will update the second match of your query (and be reflected in the underlying table)
 
 It is possible to create two or more RLMViews for the same RLMTable.
 
 @warning Note that top-level keyed subscripting (`myView[@"foo"]`) does _not_ work on RLMView; it only works on RLMTable.  
 You can still use object-level keyed subscripting (`myObject[@"title"]`) on objects from a view.
 
 @warning An RLMView is implicitely linked to an RLMTable. All changes to the view will propagate to the original (or source) table.
 This includes operations like updating values and deleting rows.
 **This is NOT true in the other direction**:
 Any change that adds or removes rows in the original table will _not_ be automatically updated in an active RLMView.
 
 */

@interface RLMView : NSObject <RLMView, NSFastEnumeration>

/**---------------------------------------------------------------------------------------
 *  @name Accessing Objects inside a View
 *  ---------------------------------------------------------------------------------------
 */
/**
 The number of rows in the view (e.g. the number of results to your query)
 */
@property (nonatomic, readonly) NSUInteger rowCount;
/**
 A pointer to the RLMTable backing this RLMView
 */
@property (nonatomic, readonly) RLMTable *originTable;
@property (nonatomic, readonly) NSUInteger columnCount;

-(RLMRow *)objectAtIndexedSubscript:(NSUInteger)rowIndex;
/**
 Returns the object at the index specified.
 
 @param rowIndex The index to look up.
 
 @return An object (of the same type as the RLMRow subclass used on the underlying RLMTable).
 */
-(RLMRow *)rowAtIndex:(NSUInteger)rowIndex;
/**
 Returns the object at the top of the RLMView.
 
 @return An object (of the same type as the RLMRow subclass used on the underlying RLMTable).
 */
-(RLMRow *)lastRow;
/**
 Returns the object at the bottom of the RLMView.
 
 @return An object (of the same type as the RLMRow subclass used on the underlying RLMTable).
 */
-(RLMRow *)firstRow;

-(RLMType)columnTypeOfColumnWithIndex:(NSUInteger)colIndex;

-(void) sortUsingColumnWithIndex: (NSUInteger)colIndex;
-(void) sortUsingColumnWithIndex: (NSUInteger)colIndex inOrder: (RLMSortOrder)order;

/**
 Deletes the object at the position specified.
 
 @warning This will be reflected in the underlying RLMTable!
 
 @param rowIndex <#rowIndex description#>
 */
-(void)removeRowAtIndex:(NSUInteger)rowIndex;
/**
 Deletes all objects from the RLMView.
 
 @warning This will be reflected in the underlying RLMTable!
 */
-(void)removeAllRows;

-(NSUInteger)rowIndexInOriginTableForRowAtIndex:(NSUInteger)rowIndex;

/**---------------------------------------------------------------------------------------
 *  @name JSON Serialization
 *  ---------------------------------------------------------------------------------------
 */

/** Construct a JSON representation of all the data selected by the view.
 
 @return String JSON representation of the view's data.
 */
- (NSString *)toJSONString;

@end
