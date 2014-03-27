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

#import "TDBTable.h"

#include <tightdb/objc/TDBType.h>

@interface TDBView: NSObject <TDBView, NSFastEnumeration>

@property (nonatomic, readonly) NSUInteger rowCount;
@property (nonatomic, readonly) NSUInteger columnCount;
@property (nonatomic, readonly) TDBTable *originTable;

-(TDBRow *)objectAtIndexedSubscript:(NSUInteger)rowIndex;
-(TDBRow *)rowAtIndex:(NSUInteger)rowIndex;
-(TDBRow *)lastRow;
-(TDBRow *)firstRow;

-(TDBType)columnTypeOfColumn:(NSUInteger)colIndex;

-(void) sortUsingColumnWithIndex: (NSUInteger)colIndex;
-(void) sortUsingColumnWithIndex: (NSUInteger)colIndex inOrder: (TDBSortOrder)order;

-(void)removeRowAtIndex:(NSUInteger)rowIndex;
-(void)removeAllRows;

-(NSUInteger)rowIndexInOriginTableForRowAtIndex:(NSUInteger)rowIndex;

@end
