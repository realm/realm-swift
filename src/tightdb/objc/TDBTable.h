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

#import "TDBViewProtocol.h"

@class TDBView;
@class TDBQuery;
@class TDBDescriptor;
@class TDBRow;

/****************	  TDBTable		****************/

@interface TDBTable: NSObject <TDBView,NSFastEnumeration>

@property (nonatomic, readonly) NSUInteger rowCount;
@property (nonatomic, readonly) NSUInteger columnCount;
@property (nonatomic, readonly) TDBDescriptor *descriptor;

// Initializers for standalone tables
-(instancetype)init;
-(instancetype)initWithColumns:(NSArray *)columns;

// Working with columns
-(NSUInteger)addColumnWithName:(NSString *)name type:(TDBType)type;
-(void)renameColumnWithIndex:(NSUInteger)colIndex to:(NSString *)newName;
-(void)removeColumnWithIndex:(NSUInteger)colIndex;

-(NSString *)nameOfColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)indexOfColumnWithName:(NSString *)name;
-(TDBType)columnTypeOfColumnWithIndex:(NSUInteger)colIndex;

// Getting and setting individual rows (uses object subscripting)
-(TDBRow *)rowAtIndex:(NSUInteger)rowIndex;
-(TDBRow *)lastRow;
-(TDBRow *)firstRow;
-(void)setObject:(id)newValue atIndexedSubscript:(NSUInteger)rowIndex;
-(TDBRow *)objectAtIndexedSubscript:(NSUInteger)rowIndex;

/**
 * Adds a row at the end of the table.
 * If data is nil, an empty row with default values is added.
 */
-(void)addRow:(NSObject *)data;

// Inserting rows at specific positions
-(void)insertRow:(NSObject *)anObject atIndex:(NSUInteger)rowIndex;

// Removing rows
-(BOOL)removeAllRows;
-(BOOL)removeRowAtIndex:(NSUInteger)rowIndex;
-(BOOL)removeLastRow;

// Queries
-(TDBQuery *)where;
// Only supported on string columns with an index
-(TDBView *)distinctValuesInColumnWithIndex:(NSUInteger)colIndex;

// Indexing
-(void)createIndexInColumnWithIndex:(NSUInteger)colIndex;
-(BOOL)isIndexCreatedInColumnWithIndex:(NSUInteger)colIndex;

// Optimizing
-(BOOL)optimize;

// Table type and schema
-(BOOL)isEqual:(id)other;
-(BOOL)hasSameDescriptorAs:(Class)otherTableClass;
-(id)castClass:(Class)obj;

-(TDBType)mixedTypeForColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;

@end
