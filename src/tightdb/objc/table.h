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
-(TightdbDescriptor *)getSubdescriptor:(NSUInteger)colNdx;
-(TightdbDescriptor *)getSubdescriptor:(NSUInteger)colNdx error:(NSError *__autoreleasing *)error;
-(NSUInteger)getColumnCount;
-(TightdbType)getColumnType:(NSUInteger)colNdx;
-(NSString *)getColumnName:(NSUInteger)colNdx;
-(NSUInteger)getColumnIndex:(NSString *)name;
@end


@interface TightdbTable: NSObject <NSFastEnumeration>
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len;

-(BOOL)isEqual:(TightdbTable *)other;

-(BOOL)isReadOnly;


/**
 * This method will return NO if it encounters a memory allocation
 * error (out of memory).
 *
 * The specified table class must be one that is declared by using
 * one of the table macros TIGHTDB_TABLE_*.
 */
-(BOOL)isClass:(Class)obj;

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
-(NSUInteger)getColumnCount;
-(NSString *)getColumnName:(NSUInteger)ndx;
-(NSUInteger)getColumnIndex:(NSString *)name;
-(TightdbType)getColumnType:(NSUInteger)ndx;
-(TightdbDescriptor *)getDescriptor;
-(TightdbDescriptor *)getDescriptorWithError:(NSError *__autoreleasing *)error;
-(BOOL)isEmpty;
-(NSUInteger)count;
-(TightdbCursor *)addEmptyRow;

/* Only curser based add should be public. This is just a temporaray way to hide the methods. */
/* TODO: Move to class extension. */
-(NSUInteger)_addEmptyRow;
-(NSUInteger)_addEmptyRows:(NSUInteger)rowCount;

-(BOOL)clear;
-(BOOL)removeRowAtIndex:(NSUInteger)ndx;
-(BOOL)removeRowAtIndex:(NSUInteger)ndx error:(NSError *__autoreleasing *)error;
-(BOOL)removeLastRow;
-(BOOL)removeLastRowWithError:(NSError *__autoreleasing *)error;

-(TightdbCursor *)objectAtIndexedSubscript:(NSUInteger)ndx; /* object subscripting */
-(TightdbCursor *)cursorAtIndex:(NSUInteger)ndx;
-(TightdbCursor *)cursorAtLastIndex;

-(TightdbCursor *)insertRowAtIndex:(NSUInteger)ndx;

-(BOOL)appendRow:(NSArray *)data;

-(BOOL)insertRow:(NSUInteger)ndx;
-(BOOL)insertRow:(NSUInteger)ndx error:(NSError *__autoreleasing *)error;

-(BOOL)getBoolInColumn:(NSUInteger)colNdx atRow:(NSUInteger)ndx;
-(int64_t)getIntInColumn:(NSUInteger)colNdx atRow:(NSUInteger)ndx;
-(float)getFloatInColumn:(NSUInteger)colNdx atRow:(NSUInteger)ndx;
-(double)getDoubleInColumn:(NSUInteger)colNdx atRow:(NSUInteger)ndx;
-(time_t)getDateInColumn:(NSUInteger)colNdx atRow:(NSUInteger)ndx;
-(NSString *)getStringInColumn:(NSUInteger)colNdx atRow:(NSUInteger)ndx;
-(TightdbBinary *)getBinaryInColumn:(NSUInteger)colNdx atRow:(NSUInteger)ndx;
-(TightdbTable *)getTableInColumn:(NSUInteger)colNdx atRow:(NSUInteger)ndx;
-(id)getTableInColumn:(NSUInteger)colNdx atRow:(NSUInteger)ndx withClass:(Class)obj;
-(TightdbMixed *)getMixedInColumn:(NSUInteger)colNdx atRow:(NSUInteger)ndx;

-(void)setInt:(int64_t)value inColumn:(NSUInteger)col_ndx atRow:(NSUInteger)row_ndx;
-(void)setBool:(BOOL)value inColumn:(NSUInteger)col_ndx atRow:(NSUInteger)row_ndx;
-(void)setFloat:(float)value inColumn:(NSUInteger)col_ndx atRow:(NSUInteger)row_ndx;
-(void)setDouble:(double)value inColumn:(NSUInteger)col_ndx atRow:(NSUInteger)row_ndx;
-(void)setDate:(time_t)value inColumn:(NSUInteger)col_ndx atRow:(NSUInteger)row_ndx;
-(void)setString:(NSString *)value inColumn:(NSUInteger)col_ndx atRow:(NSUInteger)row_ndx;
-(void)setBinary:(TightdbBinary *)value inColumn:(NSUInteger)col_ndx atRow:(NSUInteger)row_ndx;
-(void)setTable:(TightdbTable *)value inColumn:(NSUInteger)col_ndx atRow:(NSUInteger)row_ndx;
-(void)setMixed:(TightdbMixed *)value inColumn:(NSUInteger)col_ndx atRow:(NSUInteger)row_ndx;


/* FIXME: It has been decided that the insert methods must not be a
 * part of the public Obj-C API. All row insertion must happen by
 * inserting a complete rows. This must occur either by calling
 * `addEmptyRow` and then setting each column value afterwards, or possibly
 * by calling a method that takes all column values as arguments at
 * once. */
-(BOOL)insertBool:(NSUInteger)colNdx ndx:(NSUInteger)ndx value:(BOOL)value;
-(BOOL)insertBool:(NSUInteger)colNdx ndx:(NSUInteger)ndx value:(BOOL)value error:(NSError *__autoreleasing *)error;
-(BOOL)insertInt:(NSUInteger)colNdx ndx:(NSUInteger)ndx value:(int64_t)value;
-(BOOL)insertInt:(NSUInteger)colNdx ndx:(NSUInteger)ndx value:(int64_t)value error:(NSError *__autoreleasing *)error;
-(BOOL)insertFloat:(NSUInteger)colNdx ndx:(NSUInteger)ndx value:(float)value;
-(BOOL)insertFloat:(NSUInteger)colNdx ndx:(NSUInteger)ndx value:(float)value error:(NSError *__autoreleasing *)error;
-(BOOL)insertDouble:(NSUInteger)colNdx ndx:(NSUInteger)ndx value:(double)value;
-(BOOL)insertDouble:(NSUInteger)colNdx ndx:(NSUInteger)ndx value:(double)value error:(NSError *__autoreleasing *)error;
-(BOOL)insertString:(NSUInteger)colNdx ndx:(NSUInteger)ndx value:(NSString *)value;
-(BOOL)insertString:(NSUInteger)colNdx ndx:(NSUInteger)ndx value:(NSString *)value error:(NSError *__autoreleasing *)error;
-(BOOL)insertBinary:(NSUInteger)colNdx ndx:(NSUInteger)ndx value:(TightdbBinary *)value;
-(BOOL)insertBinary:(NSUInteger)colNdx ndx:(NSUInteger)ndx value:(TightdbBinary *)value error:(NSError *__autoreleasing *)error;
-(BOOL)insertBinary:(NSUInteger)colNdx ndx:(NSUInteger)ndx data:(const char *)data size:(size_t)size;
-(BOOL)insertBinary:(NSUInteger)colNdx ndx:(NSUInteger)ndx data:(const char *)data size:(size_t)size error:(NSError *__autoreleasing *)error;
-(BOOL)insertDate:(NSUInteger)colNdx ndx:(NSUInteger)ndx value:(time_t)value;
-(BOOL)insertDate:(NSUInteger)colNdx ndx:(NSUInteger)ndx value:(time_t)value error:(NSError *__autoreleasing *)error;
-(BOOL)insertDone;
-(BOOL)insertDoneWithError:(NSError *__autoreleasing *)error;


/* Subtables */
-(NSUInteger)getTableSize:(NSUInteger)colNdx ndx:(NSUInteger)ndx;
-(BOOL)insertSubtable:(NSUInteger)colNdx ndx:(NSUInteger)ndx;
-(BOOL)insertSubtable:(NSUInteger)colNdx ndx:(NSUInteger)ndx error:(NSError *__autoreleasing *)error;
-(BOOL)clearSubtable:(NSUInteger)colNdx ndx:(NSUInteger)ndx;
-(BOOL)clearSubtable:(NSUInteger)colNdx ndx:(NSUInteger)ndx error:(NSError *__autoreleasing *)error;

/* Mixed */

-(TightdbType)getMixedType:(NSUInteger)colNdx ndx:(NSUInteger)ndx;
-(BOOL)insertMixed:(NSUInteger)colNdx ndx:(NSUInteger)ndx value:(TightdbMixed *)value;
-(BOOL)insertMixed:(NSUInteger)colNdx ndx:(NSUInteger)ndx value:(TightdbMixed *)value error:(NSError *__autoreleasing *)error;

-(NSUInteger)addColumnWithType:(TightdbType)type andName:(NSString *)name;
-(NSUInteger)addColumnWithType:(TightdbType)type andName:(NSString *)name error:(NSError *__autoreleasing *)error;

-(void)removeColumnWithIndex:(NSUInteger)columnIndex;

/* Searching */
/* FIXME: Should be findBool:(BOOL)value inColumn:(size_t)colNdx; */
-(NSUInteger)findBool:(NSUInteger)colNdx value:(BOOL)value;
-(NSUInteger)findInt:(NSUInteger)colNdx value:(int64_t)value;
-(NSUInteger)findFloat:(NSUInteger)colNdx value:(float)value;
-(NSUInteger)findDouble:(NSUInteger)colNdx value:(double)value;
-(NSUInteger)findString:(NSUInteger)colNdx value:(NSString *)value;
-(NSUInteger)findBinary:(NSUInteger)colNdx value:(TightdbBinary *)value;
-(NSUInteger)findDate:(NSUInteger)colNdx value:(time_t)value;
-(NSUInteger)findMixed:(NSUInteger)colNdx value:(TightdbMixed *)value;

/* FIXME: The naming scheme used here is superior to the one used in
   most of the other methods in this class. As time allows, this
   scheme must be migrated to all those other methods. */
-(TightdbView *)findAllBool:(BOOL)value              inColumn:(NSUInteger)colNdx;
-(TightdbView *)findAllInt:(int64_t)value            inColumn:(NSUInteger)colNdx;
-(TightdbView *)findAllFloat:(float)value            inColumn:(NSUInteger)colNdx;
-(TightdbView *)findAllDouble:(double)value          inColumn:(NSUInteger)colNdx;
-(TightdbView *)findAllString:(NSString *)value      inColumn:(NSUInteger)colNdx;
-(TightdbView *)findAllBinary:(TightdbBinary *)value inColumn:(NSUInteger)colNdx;
-(TightdbView *)findAllDate:(time_t)value            inColumn:(NSUInteger)colNdx;
-(TightdbView *)findAllMixed:(TightdbMixed *)value   inColumn:(NSUInteger)colNdx;

-(TightdbQuery *)where;
-(TightdbQuery *)whereWithError:(NSError *__autoreleasing *)error;

/* Indexing */
-(BOOL)hasIndex:(NSUInteger)colNdx;
-(void)setIndex:(NSUInteger)colNdx;

/* Optimizing */
-(BOOL)optimize;
-(BOOL)optimizeWithError:(NSError *__autoreleasing *)error;

/* Conversion */
/* FIXME: Do we want to conversion methods? Maybe use NSData. */

/* Aggregate functions */
/* FIXME: Should be countInt:(int64_t)value inColumn:(size_t)colNdx; */
-(NSUInteger)countWithIntColumn:(NSUInteger)colNdx andValue:(int64_t)target;
-(NSUInteger)countWithFloatColumn:(NSUInteger)colNdx andValue:(float)target;
-(NSUInteger)countWithDoubleColumn:(NSUInteger)colNdx andValue:(double)target;
-(NSUInteger)countWithStringColumn:(NSUInteger)colNdx andValue:(NSString *)target;
-(int64_t)sumWithIntColumn:(NSUInteger)colNdx;
-(double)sumWithFloatColumn:(NSUInteger)colNdx;
-(double)sumWithDoubleColumn:(NSUInteger)colNdx;
-(int64_t)maximumWithIntColumn:(NSUInteger)colNdx;
-(float)maximumWithFloatColumn:(NSUInteger)colNdx;
-(double)maximumWithDoubleColumn:(NSUInteger)colNdx;
-(int64_t)minimumWithIntColumn:(NSUInteger)colNdx;
-(float)minimumWithFloatColumn:(NSUInteger)colNdx;
-(double)minimumWithDoubleColumn:(NSUInteger)colNdx;
-(double)averageWithIntColumn:(NSUInteger)colNdx;
-(double)averageWithFloatColumn:(NSUInteger)colNdx;
-(double)averageWithDoubleColumn:(NSUInteger)colNDx;

#ifdef TIGHTDB_DEBUG
-(void)verify;
#endif

/* Private */
-(id)_initRaw;
-(BOOL)_insertSubtableCopy:(NSUInteger)colNdx row:(NSUInteger)rowNdx subtable:(TightdbTable *)subtable;
-(BOOL)_insertSubtableCopy:(NSUInteger)colNdx row:(NSUInteger)rowNdx subtable:(TightdbTable *)subtable error:(NSError *__autoreleasing *)error;
@end


@interface TightdbView: NSObject <NSFastEnumeration>
-(TightdbCursor *)cursorAtIndex:(NSUInteger)ndx;

-(NSUInteger)count;
-(BOOL)isEmpty;
-(TightdbType)getColumnType:(NSUInteger)colNdx;
-(NSUInteger)getColumnCount;
-(void) sortColumnWithIndex: (NSUInteger)columnIndex;
-(void) sortColumnWithIndex: (NSUInteger)columnIndex inOrder: (TightdbSortOrder)order;
-(int64_t)get:(NSUInteger)colNdx ndx:(NSUInteger)ndx;
-(BOOL)getBool:(NSUInteger)colNdx ndx:(NSUInteger)ndx;
-(time_t)getDate:(NSUInteger)colNdx ndx:(NSUInteger)ndx;
-(NSString *)getString:(NSUInteger)colNdx ndx:(NSUInteger)ndx;
-(void)removeRowAtIndex:(NSUInteger)ndx;
-(void)clear;
-(TightdbTable *)getTable;
-(NSUInteger)getSourceIndex:(NSUInteger)ndx;
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len;

/* Private */
-(id)_initWithQuery:(TightdbQuery *)query;
@end


@interface TightdbColumnProxy: NSObject
@property(nonatomic, weak) TightdbTable *table;
@property(nonatomic) size_t column;
-(id)initWithTable:(TightdbTable *)table column:(NSUInteger)column;
-(void)clear;
@end

@interface TightdbColumnProxy_Bool: TightdbColumnProxy
-(NSUInteger)find:(BOOL)value;
@end

@interface TightdbColumnProxy_Int: TightdbColumnProxy
-(NSUInteger)find:(int64_t)value;
-(int64_t)minimum;
-(int64_t)maximum;
-(int64_t)sum;
-(double)average;
@end

@interface TightdbColumnProxy_Float: TightdbColumnProxy
-(NSUInteger)find:(float)value;
-(float)minimum;
-(float)maximum;
-(double)sum;
-(double)average;
@end

@interface TightdbColumnProxy_Double: TightdbColumnProxy
-(NSUInteger)find:(double)value;
-(double)minimum;
-(double)maximum;
-(double)sum;
-(double)average;
@end

@interface TightdbColumnProxy_String: TightdbColumnProxy
-(NSUInteger)find:(NSString *)value;
@end

@interface TightdbColumnProxy_Binary: TightdbColumnProxy
-(NSUInteger)find:(TightdbBinary *)value;
@end

@interface TightdbColumnProxy_Date: TightdbColumnProxy
-(NSUInteger)find:(time_t)value;
@end

@interface TightdbColumnProxy_Subtable: TightdbColumnProxy
@end

@interface TightdbColumnProxy_Mixed: TightdbColumnProxy
-(NSUInteger)find:(TightdbMixed *)value;
@end
