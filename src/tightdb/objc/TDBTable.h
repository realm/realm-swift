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

@class TDBBinary;
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
-(NSString *)nameOfColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)indexOfColumnWithName:(NSString *)name;
-(TDBType)columnTypeOfColumn:(NSUInteger)colIndex;

// Getting and setting individual rows (uses object subscripting)
-(TDBRow *)objectAtIndexedSubscript:(NSUInteger)rowIndex;
-(TDBRow *)rowAtIndex:(NSUInteger)rowIndex;
-(TDBRow *)lastRow;
-(TDBRow *)firstRow;
-(void)setObject:(id)newValue atIndexedSubscript:(NSUInteger)rowIndex;

// Adding rows to end of table
-(TDBRow *)addEmptyRow;
-(BOOL)addRow:(NSObject *)data;

// Inserting rows at specific positions
-(TDBRow *)insertEmptyRowAtIndex:(NSUInteger)rowIndex;
-(BOOL)insertRow:(id)anObject atIndex:(NSUInteger)rowIndex;

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

-(BOOL)boolInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(int64_t)intInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(float)floatInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(double)doubleInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(NSDate *)dateInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(NSString *)stringInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(TDBBinary *)binaryInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(TDBTable *)tableInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(id)tableInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex asTableClass:(Class)tableClass;
-(TDBMixed *)mixedInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;

-(void)setInt:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(void)setBool:(BOOL)aBool inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)setFloat:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)setDouble:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)setDate:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)setString:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)setBinary:(TDBBinary *)aBinary inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)setTable:(TDBTable *)aTable inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)setMixed:(TDBMixed *)aMixed inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;



-(BOOL)TDBInsertBool:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(BOOL)value;
-(BOOL)TDBInsertInt:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(int64_t)value;
-(BOOL)TDBInsertFloat:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(float)value;
-(BOOL)TDBInsertDouble:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(double)value;
-(BOOL)TDBInsertString:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(NSString *)value;
-(BOOL)TDBInsertBinary:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(TDBBinary *)value;
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






-(TDBView *)findAllRowsWithBool:(BOOL)aBool inColumnWithIndex:(NSUInteger)colIndex;
-(TDBView *)findAllRowsWithInt:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(TDBView *)findAllRowsWithFloat:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(TDBView *)findAllRowsWithDouble:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;
-(TDBView *)findAllRowsWithString:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex;
-(TDBView *)findAllRowsWithBinary:(TDBBinary *)aBinary inColumnWithIndex:(NSUInteger)colIndex;
-(TDBView *)findAllRowsWithDate:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex;
-(TDBView *)findAllRowsWithMixed:(TDBMixed *)aMixed inColumnWithIndex:(NSUInteger)colIndex;





/* Private */
-(id)_initRaw;
-(BOOL)TDBInsertSubtableCopy:(NSUInteger)colIndex row:(NSUInteger)rowNdx subtable:(TDBTable *)subtable;
-(BOOL)TDBInsertSubtableCopy:(NSUInteger)colIndex row:(NSUInteger)rowIndex subtable:(TDBTable *)subtable error:(NSError *__autoreleasing *)error;
@end
