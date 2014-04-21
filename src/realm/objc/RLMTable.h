/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2014] TightDB Inc
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of TightDB Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to TightDB Incorporated
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from TightDB Incorporated.
 *
 **************************************************************************/

#import <Foundation/Foundation.h>

#import "RLMViewProtocol.h"

@class RLMView;
@class RLMQuery;
@class RLMDescriptor;
@class RLMRow;


@interface RLMTable : NSObject <RLMView,NSFastEnumeration>

@property (nonatomic, readonly) NSUInteger rowCount;
@property (nonatomic, readonly) NSUInteger columnCount;
@property (nonatomic, readonly) RLMDescriptor *descriptor;

// Initializers for standalone tables
-(instancetype)init;
-(instancetype)initWithColumns:(NSArray *)columns;

// Working with columns
-(NSUInteger)addColumnWithName:(NSString *)name type:(RLMType)type;
-(void)renameColumnWithIndex:(NSUInteger)colIndex to:(NSString *)newName;
-(void)removeColumnWithIndex:(NSUInteger)colIndex;

-(NSString *)nameOfColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)indexOfColumnWithName:(NSString *)name;
-(RLMType)columnTypeOfColumnWithIndex:(NSUInteger)colIndex;

// Getting individual rows
-(RLMRow *)rowAtIndex:(NSUInteger)rowIndex;
-(RLMRow *)firstRow;
-(RLMRow *)lastRow;

// Getting and setting individual rows with object subscripting
-(id)objectAtIndexedSubscript:(NSUInteger)rowIndex;
-(void)setObject:(id)newValue atIndexedSubscript:(NSUInteger)rowIndex;

// Add a row at the end of the table.
// If data is nil, an empty row with default values is added.
-(void)addRow:(NSObject *)data;

// Inserting rows at specific positions
-(void)insertRow:(NSObject *)anObject atIndex:(NSUInteger)rowIndex;

// Removing rows
-(void)removeAllRows;
-(void)removeRowAtIndex:(NSUInteger)rowIndex;
-(void)removeLastRow;

// Queries
-(RLMQuery *)where;
// Only supported on string columns with an index
-(RLMView *)distinctValuesInColumnWithIndex:(NSUInteger)colIndex;

// Predicate queries
-(RLMRow *)find:(id)condition;
-(RLMView *)where:(id)condition;
-(RLMView *)where:(id)condition orderBy:(id)order;

// Indexing
-(void)createIndexInColumnWithIndex:(NSUInteger)colIndex;
-(BOOL)isIndexCreatedInColumnWithIndex:(NSUInteger)colIndex;

// Optimizing
-(BOOL)optimize;

// Table type and schema
-(BOOL)isEqual:(id)otherTableClass;
-(id)castToTypedTableClass:(Class)typedTableClass;
// FIXME: implement method below and reenable and document it
// -(BOOL)hasSameDescriptorAs:(Class)otherTableClass;

-(RLMType)mixedTypeForColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;

@end
