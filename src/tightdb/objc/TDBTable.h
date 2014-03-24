/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2012] TightDB Inc
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

#include <tightdb/objc/TDBType.h>

@class TDBView;
@class TDBQuery;
@class TDBDescriptor;
@class TDBRow;
@class TDBMixed;

/****************	  TDBTable		****************/

@interface TDBTable: NSObject <NSFastEnumeration>

@property (nonatomic, readonly) NSUInteger rowCount;
@property (nonatomic, readonly) NSUInteger columnCount;
@property (nonatomic, readonly) TDBDescriptor *descriptor;

// Initializers for standalone tables
-(instancetype)init;

// Working with columns
-(NSUInteger)addColumnWithName:(NSString *)name andType:(TDBType)type;
-(void)removeColumnWithIndex:(NSUInteger)colIndex;
-(NSString *)columnNameOfColumn:(NSUInteger)colIndex;
-(NSUInteger)indexOfColumnWithName:(NSString *)name;
-(TDBType)columnTypeOfColumn:(NSUInteger)colIndex;

// Getting and setting individual rows (uses object subscripting)
-(TDBRow *)objectAtIndexedSubscript:(NSUInteger)rowIndex;
-(TDBRow *)rowAtIndex:(NSUInteger)rowIndex;
-(TDBRow *)lastRow;
-(TDBRow *)firstRow;
-(void)setObject:(id)newValue atIndexedSubscript:(NSUInteger)rowIndex;

// Appending rows to end of table
-(TDBRow *)addEmptyRow;
-(BOOL)appendRow:(NSObject *)data;

// Inserting rows at specific positions
-(TDBRow *)insertEmptyRowAtIndex:(NSUInteger)rowIndex;
-(BOOL)insertRow:(id)anObject atRowIndex:(NSUInteger)rowIndex;

// Removing rows
-(BOOL)removeAllRows;
-(BOOL)removeRowAtIndex:(NSUInteger)rowIndex;
-(BOOL)removeLastRow;

// Queries
-(TDBQuery *)where;

// Indexing
-(void)createIndexInColumnWithIndex:(NSUInteger)colIndex;
-(BOOL)isIndexCreatedInColumnWithIndex:(NSUInteger)colIndex;

// Optimizing
-(BOOL)optimize;

// Table type and schema
-(BOOL)isReadOnly;
-(BOOL)isEqual:(TDBTable *)other;
-(BOOL)hasSameDescriptorAs:(Class)otherTableClass;
-(id)castClass:(Class)obj;


/* -\/- EVERYTHING BELOW HERE SHOULD BE REMOVED / HIDDEN AWAY -\/- */

/* Only curser based add should be public. This is just a temporaray way to hide the methods. */
/* TODO: Move to class extension. */
-(NSUInteger)TDBAddEmptyRow;
-(NSUInteger)TDBAddEmptyRows:(NSUInteger)numberOfRows;

-(BOOL)TDBboolInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(int64_t)TDBintInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(float)TDBfloatInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(double)TDBdoubleInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(NSDate *)TDBdateInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(NSString *)TDBstringInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(NSData *)TDBbinaryInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(TDBTable *)TDBtableInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(id)TDBtableInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex asTableClass:(Class)tableClass;
-(TDBMixed *)TDBmixedInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;

-(void)TDBsetInt:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(void)TDBsetBool:(BOOL)aBool inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)TDBsetFloat:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)TDBsetDouble:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)TDBsetDate:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)TDBsetString:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)TDBsetBinary:(NSData *)aBinary inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)TDBsetTable:(TDBTable *)aTable inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)TDBsetMixed:(TDBMixed *)aMixed inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;



-(BOOL)TDBInsertBool:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(BOOL)value;
-(BOOL)TDBInsertInt:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(int64_t)value;
-(BOOL)TDBInsertFloat:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(float)value;
-(BOOL)TDBInsertDouble:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(double)value;
-(BOOL)TDBInsertString:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(NSString *)value;
-(BOOL)TDBInsertBinary:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(NSData *)value;
-(BOOL)TDBInsertBinary:(NSUInteger)colIndex ndx:(NSUInteger)ndx data:(const char *)data size:(size_t)size;
-(BOOL)TDBInsertDate:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(NSDate *)value;
-(BOOL)TDBInsertDone;


/* Subtables */

-(BOOL)TDBInsertSubtable:(NSUInteger)colIndex ndx:(NSUInteger)ndx;
-(BOOL)TDBInsertSubtable:(NSUInteger)colIndex ndx:(NSUInteger)ndx error:(NSError *__autoreleasing *)error;


/* Mixed */

-(TDBType)mixedTypeForColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(BOOL)TDBInsertMixed:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(TDBMixed *)value;
-(BOOL)TDBInsertMixed:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(TDBMixed *)value error:(NSError *__autoreleasing *)error;




-(NSUInteger)findRowIndexWithBool:(BOOL)aBool inColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)findRowIndexWithInt:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)findRowIndexWithFloat:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)findRowIndexWithDouble:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)findRowIndexWithString:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)findRowIndexWithBinary:(NSData *)aBinary inColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)findRowIndexWithDate:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)findRowIndexWithMixed:(TDBMixed *)aMixed inColumnWithIndex:(NSUInteger)colIndex;

-(TDBView *)findAllRowsWithBool:(BOOL)aBool inColumnWithIndex:(NSUInteger)colIndex;
-(TDBView *)findAllRowsWithInt:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(TDBView *)findAllRowsWithFloat:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(TDBView *)findAllRowsWithDouble:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;
-(TDBView *)findAllRowsWithString:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex;
-(TDBView *)findAllRowsWithBinary:(NSData *)aBinary inColumnWithIndex:(NSUInteger)colIndex;
-(TDBView *)findAllRowsWithDate:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex;
-(TDBView *)findAllRowsWithMixed:(TDBMixed *)aMixed inColumnWithIndex:(NSUInteger)colIndex;




/* Conversion */
/* FIXME: Do we want to conversion methods? Maybe use NSData. */

/* Aggregate functions */
/* FIXME: Consider adding:
 countRowsWithValue: @"foo"
 countRowsWithValue: @300 */
-(NSUInteger)countRowsWithInt:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)countRowsWithFloat:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)countRowsWithDouble:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)countRowsWithString:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex;
-(int64_t)sumIntColumnWithIndex:(NSUInteger)colIndex;
-(double)sumFloatColumnWithIndex:(NSUInteger)colIndex;
-(double)sumDoubleColumnWithIndex:(NSUInteger)colIndex;
-(int64_t)maxIntInColumnWithIndex:(NSUInteger)colIndex;
-(float)maxFloatInColumnWithIndex:(NSUInteger)colIndex;
-(double)maxDoubleInColumnWithIndex:(NSUInteger)colIndex;
-(int64_t)minIntInColumnWithIndex:(NSUInteger)colIndex;
-(float)minFloatInColumnWithIndex:(NSUInteger)colIndex;
-(double)minDoubleInColumnWithIndex:(NSUInteger)colIndex;
-(double)avgIntColumnWithIndex:(NSUInteger)colIndex;
-(double)avgFloatColumnWithIndex:(NSUInteger)colIndex;
-(double)avgDoubleColumnWithIndex:(NSUInteger)colIndex;


/* Private */
-(id)_initRaw;
-(BOOL)TDBInsertSubtableCopy:(NSUInteger)colIndex row:(NSUInteger)rowNdx subtable:(TDBTable *)subtable;
-(BOOL)TDBInsertSubtableCopy:(NSUInteger)colIndex row:(NSUInteger)rowIndex subtable:(TDBTable *)subtable error:(NSError *__autoreleasing *)error;
@end
