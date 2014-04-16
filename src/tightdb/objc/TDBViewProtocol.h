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

#include "TDBType.h"

@class RLMRow;
@class RLMQuery;


@protocol TDBView

@property (nonatomic, readonly) NSUInteger rowCount;
@property (nonatomic, readonly) NSUInteger columnCount;

// Getting and setting individual rows
-(RLMRow *)objectAtIndexedSubscript:(NSUInteger)rowIndex;
-(RLMRow *)rowAtIndex:(NSUInteger)rowIndex;
-(RLMRow *)lastRow;
-(RLMRow *)firstRow;

// Working with columns
-(TDBType)columnTypeOfColumnWithIndex:(NSUInteger)colIndex;

// Removing rows
-(void)removeRowAtIndex:(NSUInteger)rowIndex;
-(void)removeAllRows;

-(RLMQuery *)where;

@end
