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

@class TightdbTable;
@class TightdbView;
@class TightdbQuery;
@class TightdbCursor;


@interface TightdbBinary: NSObject
-(id)initWithData:(const char *)data size:(size_t)size;
-(const char *)getData;
-(size_t)getSize;

/**
 * Compare the referenced binary data for equality.
 */
-(BOOL)isEqual:(TightdbBinary *)bin;
@end


@interface TightdbMixed: NSObject
+(TightdbMixed *)mixedWithBool:(BOOL)value;
+(TightdbMixed *)mixedWithInt64:(int64_t)value;
+(TightdbMixed *)mixedWithFloat:(float)value;
+(TightdbMixed *)mixedWithDouble:(double)value;
+(TightdbMixed *)mixedWithString:(NSString *)value;
+(TightdbMixed *)mixedWithBinary:(TightdbBinary *)value;
+(TightdbMixed *)mixedWithBinary:(const char *)data size:(size_t)size;
+(TightdbMixed *)mixedWithDate:(time_t)value;
+(TightdbMixed *)mixedWithTable:(TightdbTable *)value;
-(BOOL)isEqual:(TightdbMixed *)other;
-(TightdbType)getType;
-(BOOL)getBool;
-(int64_t)getInt;
-(float)getFloat;
-(double)getDouble;
-(NSString *)getString;
-(TightdbBinary *)getBinary;
-(time_t)getDate;
-(TightdbTable *)getTable;
@end


@interface TightdbDescriptor: NSObject
/**
 * Returns NO on memory allocation error.
 */
-(BOOL)addColumnWithType:(TightdbType)type andName:(NSString *)name;
-(BOOL)addColumnWithType:(TightdbType)type andName:(NSString *)name error:(NSError *__autoreleasing *)error;
/**
 * Returns nil on memory allocation error.
 */
-(TightdbDescriptor *)addColumnTable:(NSString *)name;
-(TightdbDescriptor *)addColumnTable:(NSString *)name error:(NSError *__autoreleasing *)error;
-(TightdbDescriptor *)getSubdescriptor:(size_t)colNdx;
-(TightdbDescriptor *)getSubdescriptor:(size_t)colNdx error:(NSError *__autoreleasing *)error;
-(size_t)getColumnCount;
-(TightdbType)getColumnType:(size_t)colNdx;
-(NSString *)getColumnName:(size_t)colNdx;
-(size_t)getColumnIndex:(NSString *)name;
@end


@interface TightdbTable: NSObject <NSFastEnumeration>
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len;

-(BOOL)isEqual:(TightdbTable *)other; //isEqualToTable

-(BOOL)isReadOnly;


/**
 * This method will return NO if it encounters a memory allocation
 * error (out of memory).
 *
 * The specified table class must be one that is declared by using
 * one of the table macros TIGHTDB_TABLE_*.
 */
-(BOOL)isClass:(Class)obj; //Hm, not very clear. Maybe isOfType

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
-(size_t)getColumnCount; // columnCount
-(NSString *)getColumnName:(size_t)ndx; // nameOfColumn: column
-(size_t)getColumnIndex:(NSString *)name; // indexOfColumnWithName: name
-(TightdbType)getColumnType:(size_t)ndx; //typeOfColumn: column
-(TightdbDescriptor *)getDescriptor; // descripter
-(TightdbDescriptor *)getDescriptorWithError:(NSError *__autoreleasing *)error; //does it even need to be here?
-(BOOL)isEmpty;
-(size_t)count; //rowCount
-(TightdbCursor *)addEmptyRow;

/* Only curser based add should be public. This is just a temporaray way to hide the methods. */
/* TODO: Move to class extension. */
-(size_t)_addEmptyRow;
-(size_t)_addEmptyRows:(size_t)rowCount;

-(BOOL)clear; //clearRows
-(BOOL)clearWithError:(NSError *__autoreleasing *)error; //Hm, should throw exception
-(BOOL)removeRowAtIndex:(size_t)ndx; // removeRow: row
-(BOOL)removeRowAtIndex:(size_t)ndx error:(NSError *__autoreleasing *)error; //Hm, should throw exception
-(BOOL)removeLastRow;
-(BOOL)removeLastRowWithError:(NSError *__autoreleasing *)error; //Hm, should throw exception

-(TightdbCursor *)cursorAtIndex:(size_t)ndx; //:index
-(TightdbCursor *)cursorAtLastIndex;

-(TightdbCursor *)insertRowAtIndex:(size_t)ndx; //:index

-(BOOL)insertRow:(size_t)ndx; //:index
-(BOOL)insertRow:(size_t)ndx error:(NSError *__autoreleasing *)error; //Hm, should throw exception

-(BOOL)getBoolInColumn:(size_t)colNdx atRow:(size_t)ndx; // boolValueInColumn: column andRow: row
-(int64_t)getIntInColumn:(size_t)colNdx atRow:(size_t)ndx; //intValueInColumn: column andRow: row
-(float)getFloatInColumn:(size_t)colNdx atRow:(size_t)ndx; // same as above......
-(double)getDoubleInColumn:(size_t)colNdx atRow:(size_t)ndx;
-(time_t)getDateInColumn:(size_t)colNdx atRow:(size_t)ndx;
-(NSString *)getStringInColumn:(size_t)colNdx atRow:(size_t)ndx;
-(TightdbBinary *)getBinaryInColumn:(size_t)colNdx atRow:(size_t)ndx;
-(TightdbTable *)getTableInColumn:(size_t)colNdx atRow:(size_t)ndx;
-(id)getTableInColumn:(size_t)colNdx atRow:(size_t)ndx withClass:(Class)obj;
-(TightdbMixed *)getMixedInColumn:(size_t)colNdx atRow:(size_t)ndx; // same same

-(void)setInt:(int64_t)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx; // setIntValue: anInt inColumn: column andRow: row
-(void)setBool:(BOOL)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx; // same all the way down
-(void)setFloat:(float)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx;
-(void)setDouble:(double)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx;
-(void)setDate:(time_t)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx;
-(void)setString:(NSString *)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx;
-(void)setBinary:(TightdbBinary *)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx;
-(void)setTable:(TightdbTable *)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx;
-(void)setMixed:(TightdbMixed *)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx; // same same


/* FIXME: It has been decided that the insert methods must not be a
 * part of the public Obj-C API. All row insertion must happen by
 * inserting a complete rows. This must occur either by calling
 * `addEmptyRow` and then setting each column value afterwards, or possibly
 * by calling a method that takes all column values as arguments at
 * once. */
-(BOOL)insertBool:(size_t)colNdx ndx:(size_t)ndx value:(BOOL)value; // insertBoolValue: aBool inColumn: column andRow: row
-(BOOL)insertBool:(size_t)colNdx ndx:(size_t)ndx value:(BOOL)value error:(NSError *__autoreleasing *)error; //Hm, should throw exception
-(BOOL)insertInt:(size_t)colNdx ndx:(size_t)ndx value:(int64_t)value; // same same
-(BOOL)insertInt:(size_t)colNdx ndx:(size_t)ndx value:(int64_t)value error:(NSError *__autoreleasing *)error;
-(BOOL)insertFloat:(size_t)colNdx ndx:(size_t)ndx value:(float)value;
-(BOOL)insertFloat:(size_t)colNdx ndx:(size_t)ndx value:(float)value error:(NSError *__autoreleasing *)error;
-(BOOL)insertDouble:(size_t)colNdx ndx:(size_t)ndx value:(double)value;
-(BOOL)insertDouble:(size_t)colNdx ndx:(size_t)ndx value:(double)value error:(NSError *__autoreleasing *)error;
-(BOOL)insertString:(size_t)colNdx ndx:(size_t)ndx value:(NSString *)value;
-(BOOL)insertString:(size_t)colNdx ndx:(size_t)ndx value:(NSString *)value error:(NSError *__autoreleasing *)error;
-(BOOL)insertBinary:(size_t)colNdx ndx:(size_t)ndx value:(TightdbBinary *)value;
-(BOOL)insertBinary:(size_t)colNdx ndx:(size_t)ndx value:(TightdbBinary *)value error:(NSError *__autoreleasing *)error;
-(BOOL)insertBinary:(size_t)colNdx ndx:(size_t)ndx data:(const char *)data size:(size_t)size;
-(BOOL)insertBinary:(size_t)colNdx ndx:(size_t)ndx data:(const char *)data size:(size_t)size error:(NSError *__autoreleasing *)error;
-(BOOL)insertDate:(size_t)colNdx ndx:(size_t)ndx value:(time_t)value;
-(BOOL)insertDate:(size_t)colNdx ndx:(size_t)ndx value:(time_t)value error:(NSError *__autoreleasing *)error; // same same
-(BOOL)insertDone;
-(BOOL)insertDoneWithError:(NSError *__autoreleasing *)error;


/* Subtables */
-(size_t)getTableSize:(size_t)colNdx ndx:(size_t)ndx;
-(BOOL)insertSubtable:(size_t)colNdx ndx:(size_t)ndx;
-(BOOL)insertSubtable:(size_t)colNdx ndx:(size_t)ndx error:(NSError *__autoreleasing *)error;
-(BOOL)clearSubtable:(size_t)colNdx ndx:(size_t)ndx;
-(BOOL)clearSubtable:(size_t)colNdx ndx:(size_t)ndx error:(NSError *__autoreleasing *)error;

/* Mixed */

-(TightdbType)getMixedType:(size_t)colNdx ndx:(size_t)ndx;
-(BOOL)insertMixed:(size_t)colNdx ndx:(size_t)ndx value:(TightdbMixed *)value;
-(BOOL)insertMixed:(size_t)colNdx ndx:(size_t)ndx value:(TightdbMixed *)value error:(NSError *__autoreleasing *)error;

-(size_t)addColumnWithType:(TightdbType)type andName:(NSString *)name;
-(size_t)addColumnWithType:(TightdbType)type andName:(NSString *)name error:(NSError *__autoreleasing *)error;

/* Searching */
/* FIXME: Should be findBool:(BOOL)value inColumn:(size_t)colNdx; */
-(size_t)findBool:(size_t)colNdx value:(BOOL)value; // findfirstBoolValue: aBool inColumn: column
-(size_t)findInt:(size_t)colNdx value:(int64_t)value; // same same
-(size_t)findFloat:(size_t)colNdx value:(float)value;
-(size_t)findDouble:(size_t)colNdx value:(double)value;
-(size_t)findString:(size_t)colNdx value:(NSString *)value;
-(size_t)findBinary:(size_t)colNdx value:(TightdbBinary *)value;
-(size_t)findDate:(size_t)colNdx value:(time_t)value;
-(size_t)findMixed:(size_t)colNdx value:(TightdbMixed *)value;

/* FIXME: The naming scheme used here is superior to the one used in
   most of the other methods in this class. As time allows, this
   scheme must be migrated to all those other methods. */
-(TightdbView *)findAllBool:(BOOL)value              inColumn:(size_t)colNdx; // findAllRowsWithBoolValue: aBool inColumn: column
-(TightdbView *)findAllInt:(int64_t)value            inColumn:(size_t)colNdx; // same same
-(TightdbView *)findAllFloat:(float)value            inColumn:(size_t)colNdx;
-(TightdbView *)findAllDouble:(double)value          inColumn:(size_t)colNdx;
-(TightdbView *)findAllString:(NSString *)value      inColumn:(size_t)colNdx;
-(TightdbView *)findAllBinary:(TightdbBinary *)value inColumn:(size_t)colNdx;
-(TightdbView *)findAllDate:(time_t)value            inColumn:(size_t)colNdx;
-(TightdbView *)findAllMixed:(TightdbMixed *)value   inColumn:(size_t)colNdx;

-(TightdbQuery *)where;
-(TightdbQuery *)whereWithError:(NSError *__autoreleasing *)error;

/* Indexing */
-(BOOL)hasIndex:(size_t)colNdx; // isIndexSetInColumn: column // columHasIndex: column
-(void)setIndex:(size_t)colNdx; // setIndexInColumn: column

/* Optimizing */
-(BOOL)optimize;
-(BOOL)optimizeWithError:(NSError *__autoreleasing *)error;

/* Conversion */
/* FIXME: Do we want to conversion methods? Maybe use NSData. */

/* Aggregate functions */
/* FIXME: Should be countInt:(int64_t)value inColumn:(size_t)colNdx; */
-(size_t)countWithIntColumn:(size_t)colNdx andValue:(int64_t)target; // countRowsWithIntValue: antInt inColumn: column
-(size_t)countWithFloatColumn:(size_t)colNdx andValue:(float)target; // same same
-(size_t)countWithDoubleColumn:(size_t)colNdx andValue:(double)target;
-(size_t)countWithStringColumn:(size_t)colNdx andValue:(NSString *)target;
-(int64_t)sumWithIntColumn:(size_t)colNdx; // sumColumn: column containingIntValues // calcSumOnIntColumn : column
-(double)sumWithFloatColumn:(size_t)colNdx; // sumColumn: column containingFloatValues
-(double)sumWithDoubleColumn:(size_t)colNdx;
-(int64_t)maximumWithIntColumn:(size_t)colNdx; //maximumValueInColumn: column containingIntValues // calcMaximumOnIntColumn: column
-(float)maximumWithFloatColumn:(size_t)colNdx;
-(double)maximumWithDoubleColumn:(size_t)colNdx;
-(int64_t)minimumWithIntColumn:(size_t)colNdx;
-(float)minimumWithFloatColumn:(size_t)colNdx;
-(double)minimumWithDoubleColumn:(size_t)colNdx;
-(double)averageWithIntColumn:(size_t)colNdx; // averageColumn: column containingIntValues
-(double)averageWithFloatColumn:(size_t)colNdx;
-(double)averageWithDoubleColumn:(size_t)colNDx;

#ifdef TIGHTDB_DEBUG
-(void)verify;
#endif

/* Private */
-(id)_initRaw;
-(BOOL)_insertSubtableCopy:(size_t)colNdx row:(size_t)rowNdx subtable:(TightdbTable *)subtable;
-(BOOL)_insertSubtableCopy:(size_t)colNdx row:(size_t)rowNdx subtable:(TightdbTable *)subtable error:(NSError *__autoreleasing *)error;
@end


@interface TightdbView: NSObject <NSFastEnumeration>
-(TightdbCursor *)cursorAtIndex:(size_t)ndx;

-(size_t)count; // countRows
-(BOOL)isEmpty;
-(int64_t)get:(size_t)colNdx ndx:(size_t)ndx; // intValueInColumn: column andRow: row
-(BOOL)getBool:(size_t)colNdx ndx:(size_t)ndx; // same
-(time_t)getDate:(size_t)colNdx ndx:(size_t)ndx;
-(NSString *)getString:(size_t)colNdx ndx:(size_t)ndx;
-(void)removeRowAtIndex:(size_t)ndx; // removeRow: row
-(void)clear; // clearRows
-(TightdbTable *)getTable; // sourceTable
-(size_t)getSourceIndex:(size_t)ndx; // rowIndexInSourceTableForRow: row
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len;

/* Private */
-(id)_initWithQuery:(TightdbQuery *)query;
@end


@interface TightdbColumnProxy: NSObject
@property(nonatomic, weak) TightdbTable *table;
@property(nonatomic) size_t column;
-(id)initWithTable:(TightdbTable *)table column:(size_t)column;
-(void)clear;
@end

@interface TightdbColumnProxy_Bool: TightdbColumnProxy
-(size_t)find:(BOOL)value;
@end

@interface TightdbColumnProxy_Int: TightdbColumnProxy
-(size_t)find:(int64_t)value;
-(int64_t)minimum;
-(int64_t)maximum;
-(int64_t)sum;
-(double)average;
@end

@interface TightdbColumnProxy_Float: TightdbColumnProxy
-(size_t)find:(float)value;
-(float)minimum;
-(float)maximum;
-(double)sum;
-(double)average;
@end

@interface TightdbColumnProxy_Double: TightdbColumnProxy
-(size_t)find:(double)value;
-(double)minimum;
-(double)maximum;
-(double)sum;
-(double)average;
@end

@interface TightdbColumnProxy_String: TightdbColumnProxy
-(size_t)find:(NSString *)value;
@end

@interface TightdbColumnProxy_Binary: TightdbColumnProxy
-(size_t)find:(TightdbBinary *)value;
@end

@interface TightdbColumnProxy_Date: TightdbColumnProxy
-(size_t)find:(time_t)value;
@end

@interface TightdbColumnProxy_Subtable: TightdbColumnProxy
@end

@interface TightdbColumnProxy_Mixed: TightdbColumnProxy
-(size_t)find:(TightdbMixed *)value;
@end
