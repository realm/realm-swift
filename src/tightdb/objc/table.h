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

#include <tightdb/objc/type.h>

@class TDBTable;
@class TDBView;
@class TDBQuery;
@class TDBRow;


@interface TDBBinary: NSObject
-(id)initWithData:(const char *)data size:(size_t)size;
-(const char *)getData;
-(size_t)getSize;

/**
 * Compare the referenced binary data for equality.
 */
-(BOOL)isEqual:(TDBBinary *)bin;
@end


@interface TDBMixed: NSObject
+(TDBMixed *)mixedWithBool:(BOOL)value;
+(TDBMixed *)mixedWithInt64:(int64_t)value;
+(TDBMixed *)mixedWithFloat:(float)value;
+(TDBMixed *)mixedWithDouble:(double)value;
+(TDBMixed *)mixedWithString:(NSString *)value;
+(TDBMixed *)mixedWithBinary:(TDBBinary *)value;
+(TDBMixed *)mixedWithBinary:(const char *)data size:(size_t)size;
+(TDBMixed *)mixedWithDate:(time_t)value;
+(TDBMixed *)mixedWithTable:(TDBTable *)value;
-(BOOL)isEqual:(TDBMixed *)other;
-(TDBType)getType;
-(BOOL)getBool;
-(int64_t)getInt;
-(float)getFloat;
-(double)getDouble;
-(NSString *)getString;
-(TDBBinary *)getBinary;
-(time_t)getDate;
-(TDBTable *)getTable;
@end


@interface TDBDescriptor: NSObject

@property (nonatomic, readonly) NSUInteger columnCount;

/**
 * Returns NO on memory allocation error.
 */
-(BOOL)addColumnWithName:(NSString *)name andType:(TDBType)type;
-(BOOL)addColumnWithName:(NSString *)name andType:(TDBType)type error:(NSError *__autoreleasing *)error;
/**
 * Returns nil on memory allocation error.
 */
-(TDBDescriptor *)addColumnTable:(NSString *)name;
-(TDBDescriptor *)addColumnTable:(NSString *)name error:(NSError *__autoreleasing *)error;
-(TDBDescriptor *)subdescriptorForColumnWithIndex:(NSUInteger)colIndex;
-(TDBDescriptor *)subdescriptorForColumnWithIndex:(NSUInteger)colIndex error:(NSError *__autoreleasing *)error;

-(TDBType)columnTypeOfColumn:(NSUInteger)colIndex;
-(NSString *)columnNameOfColumn:(NSUInteger)colIndex;
-(NSUInteger)indexOfColumnWithName:(NSString *)name;
@end


@interface TDBTable: NSObject <NSFastEnumeration>

@property (nonatomic, readonly) NSUInteger columnCount;
@property (nonatomic, readonly) TDBDescriptor *descriptor;
@property (nonatomic, readonly) NSUInteger rowCount;


-(BOOL)isEqual:(TDBTable *)other;

-(BOOL)isReadOnly;


/**
 * This method will return NO if it encounters a memory allocation
 * error (out of memory).
 *
 * The specified table class must be one that is declared by using
 * one of the table macros TIGHTDB_TABLE_*.
 */
-(BOOL)hasSameDescriptorAs:(Class)otherTableClass;

/**
 * If the type of this table is not compatible with the specified
 * table class, then this method returns nil. It also returns nil if
 * it encounters a memory allocation error (out of memory).
 *
 * The specified table class must be one that is declared by using
 * one of the table macros TIGHTDB_TABLE_*.
 */
-(id)castClass:(Class)obj;

/* Column meta info */
-(NSUInteger)addColumnWithName:(NSString *)name andType:(TDBType)type;
-(void)removeColumnWithIndex:(NSUInteger)colIndex;
-(NSString *)columnNameOfColumn:(NSUInteger)colIndex;
-(NSUInteger)indexOfColumnWithName:(NSString *)name;
-(TDBType)columnTypeOfColumn:(NSUInteger)colIndex;


-(TDBRow *)addEmptyRow;

/* Only curser based add should be public. This is just a temporaray way to hide the methods. */
/* TODO: Move to class extension. */
-(NSUInteger)TDBAddEmptyRow;
-(NSUInteger)TDBAddEmptyRows:(NSUInteger)numberOfRows;

-(BOOL)removeAllRows;
-(BOOL)removeRowAtIndex:(NSUInteger)rowIndex;
-(BOOL)removeLastRow;

-(TDBRow *)objectAtIndexedSubscript:(NSUInteger)rowIndex; /* object subscripting */
-(TDBRow *)rowAtIndex:(NSUInteger)rowIndex;
-(TDBRow *)lastRow;
-(TDBRow *)firstRow;
-(void)setObject:(id)newValue atIndexedSubscript:(NSUInteger)rowIndex;

-(TDBRow *)insertEmptyRowAtIndex:(NSUInteger)rowIndex;

-(BOOL)appendRow:(NSObject *)data;
-(BOOL)insertRow:(id)anObject atRowIndex:(NSUInteger)rowIndex;

-(BOOL)boolInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(int64_t)intInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(float)floatInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(double)doubleInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(time_t)dateInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(NSString *)stringInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(TDBBinary *)binaryInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(TDBTable *)tableInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(id)tableInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex asTableClass:(Class)tableClass;
-(TDBMixed *)mixedInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;

-(void)setInt:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(void)setBool:(BOOL)aBool inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)setFloat:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)setDouble:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)setDate:(time_t)aDate inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
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
-(BOOL)TDBInsertDate:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(time_t)value;
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
-(NSUInteger)findRowIndexWithBinary:(TDBBinary *)aBinary inColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)findRowIndexWithDate:(time_t)aDate inColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)findRowIndexWithMixed:(TDBMixed *)aMixed inColumnWithIndex:(NSUInteger)colIndex;

-(TDBView *)findAllRowsWithBool:(BOOL)aBool inColumnWithIndex:(NSUInteger)colIndex;
-(TDBView *)findAllRowsWithInt:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(TDBView *)findAllRowsWithFloat:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(TDBView *)findAllRowsWithDouble:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;
-(TDBView *)findAllRowsWithString:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex;
-(TDBView *)findAllRowsWithBinary:(TDBBinary *)aBinary inColumnWithIndex:(NSUInteger)colIndex;
-(TDBView *)findAllRowsWithDate:(time_t)aDate inColumnWithIndex:(NSUInteger)colIndex;
-(TDBView *)findAllRowsWithMixed:(TDBMixed *)aMixed inColumnWithIndex:(NSUInteger)colIndex;


-(TDBQuery *)where;
-(TDBQuery *)whereWithError:(NSError *__autoreleasing *)error;

/* Indexing */
-(void)createIndexInColumnWithIndex:(NSUInteger)colIndex;
-(BOOL)isIndexCreatedInColumnWithIndex:(NSUInteger)colIndex;

/* Optimizing */
-(BOOL)optimize;
-(BOOL)optimizeWithError:(NSError *__autoreleasing *)error;

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

#ifdef TIGHTDB_DEBUG
-(void)verify;
#endif

/* Private */
-(id)_initRaw;
-(BOOL)TDBInsertSubtableCopy:(NSUInteger)colIndex row:(NSUInteger)rowNdx subtable:(TDBTable *)subtable;
-(BOOL)TDBInsertSubtableCopy:(NSUInteger)colIndex row:(NSUInteger)rowIndex subtable:(TDBTable *)subtable error:(NSError *__autoreleasing *)error;
@end


@interface TDBView: NSObject <NSFastEnumeration>


@property (nonatomic, readonly) NSUInteger rowCount;
@property (nonatomic, readonly) NSUInteger columnCount;
@property (nonatomic, readonly) TDBTable *originTable;

-(TDBRow *)rowAtIndex:(NSUInteger)rowIndex;
-(TDBRow *)lastRow;
-(TDBRow *)firstRow;

-(TDBType)columnTypeOfColumn:(NSUInteger)colIndex;

-(void) sortUsingColumnWithIndex: (NSUInteger)colIndex;
-(void) sortUsingColumnWithIndex: (NSUInteger)colIndex inOrder: (TDBSortOrder)order;


-(BOOL)boolInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(int64_t)intInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(float)floatInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(double)doubleInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(time_t)dateInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(NSString *)stringInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
//-(TDBBinary *)binaryInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
//-(TDBTable *)tableInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
//-(id)tableInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex asTableClass:(Class)tableClass;
-(TDBMixed *)mixedInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;


-(void)removeRowAtIndex:(NSUInteger)rowIndex;
-(void)removeAllRows;

-(NSUInteger)rowIndexInOriginTableForRowAtIndex:(NSUInteger)rowIndex;


/* Private */
-(id)_initWithQuery:(TDBQuery *)query;
@end


@interface TDBColumnProxy: NSObject
@property(nonatomic, weak) TDBTable *table;
@property(nonatomic) size_t column;
-(id)initWithTable:(TDBTable *)table column:(NSUInteger)column;
-(void)clear;
@end

@interface TDBColumnProxy_Bool: TDBColumnProxy
-(NSUInteger)find:(BOOL)value;
@end

@interface TDBColumnProxy_Int: TDBColumnProxy
-(NSUInteger)find:(int64_t)value;
-(int64_t)minimum;
-(int64_t)maximum;
-(int64_t)sum;
-(double)average;
@end

@interface TDBColumnProxy_Float: TDBColumnProxy
-(NSUInteger)find:(float)value;
-(float)minimum;
-(float)maximum;
-(double)sum;
-(double)average;
@end

@interface TDBColumnProxy_Double: TDBColumnProxy
-(NSUInteger)find:(double)value;
-(double)minimum;
-(double)maximum;
-(double)sum;
-(double)average;
@end

@interface TDBColumnProxy_String: TDBColumnProxy
-(NSUInteger)find:(NSString *)value;
@end

@interface TDBColumnProxy_Binary: TDBColumnProxy
-(NSUInteger)find:(TDBBinary *)value;
@end

@interface TDBColumnProxy_Date: TDBColumnProxy
-(NSUInteger)find:(time_t)value;
@end

@interface TDBColumnProxy_Subtable: TDBColumnProxy
@end

@interface TDBColumnProxy_Mixed: TDBColumnProxy
-(NSUInteger)find:(TDBMixed *)value;
@end
