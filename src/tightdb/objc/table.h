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

/// Compare the referenced binary data for equality.
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


@interface TightdbSpec: NSObject
/// Returns NO on memory allocation error.
-(BOOL)addColumnWithType:(TightdbType)type andName:(NSString *)name;
-(BOOL)addColumnWithType:(TightdbType)type andName:(NSString *)name error:(NSError *__autoreleasing *)error;
/// Returns nil on memory allocation error.
-(TightdbSpec *)addColumnTable:(NSString *)name;
-(TightdbSpec *)addColumnTable:(NSString *)name error:(NSError *__autoreleasing *)error;
-(TightdbSpec *)getSubspec:(size_t)colNdx;
-(TightdbSpec *)getSubspec:(size_t)colNdx error:(NSError *__autoreleasing *)error;
-(size_t)getColumnCount;
-(TightdbType)getColumnType:(size_t)colNdx;
-(NSString *)getColumnName:(size_t)colNdx;
-(size_t)getColumnIndex:(NSString *)name;
@end


@interface TightdbTable: NSObject <NSFastEnumeration>




-(BOOL)updateFromSpec;
-(BOOL)updateFromSpecWithError:(NSError *__autoreleasing *)error;
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len;

-(BOOL)isEqual:(TightdbTable *)other;

-(BOOL)isReadOnly;



/// This method will return NO if it encounters a memory allocation
/// error (out of memory).
///
/// The specified table class must be one that is declared by using
/// one of the table macros TIGHTDB_TABLE_*.
-(BOOL)isClass:(Class)obj;

/// If the type of this table is not compatible with the specified
/// table class, then this method returns nil. It also returns nil if
/// it encounters a memory allocation error (out of memory).
///
/// The specified table class must be one that is declared by using
/// one of the table macros TIGHTDB_TABLE_*.
-(id)castClass:(Class)obj;

//Column meta info
-(size_t)getColumnCount;
-(NSString *)getColumnName:(size_t)ndx;
-(size_t)getColumnIndex:(NSString *)name;
-(TightdbType)getColumnType:(size_t)ndx;
-(TightdbSpec *)getSpec;
-(TightdbSpec *)getSpecWithError:(NSError *__autoreleasing *)error;
-(BOOL)isEmpty;
-(size_t)count;
-(TightdbCursor *)addRow;

// Only curser based add should be public. This is just a temporaray way to hide the methods.
// TODO: Move to class extension.
-(size_t)_addRow;
-(size_t)_addRows:(size_t)rowCount;

-(BOOL)clear;
-(BOOL)clearWithError:(NSError *__autoreleasing *)error;
-(BOOL)removeRowAtIndex:(size_t)ndx;
-(BOOL)removeRowAtIndex:(size_t)ndx error:(NSError *__autoreleasing *)error;
-(BOOL)removeLastRow;
-(BOOL)removeLastRowWithError:(NSError *__autoreleasing *)error;

-(TightdbCursor *)cursorAtIndex:(size_t)ndx;
-(TightdbCursor *)cursorAtLastIndex;

-(TightdbCursor *)insertRowAtIndex:(size_t)ndx;

-(BOOL)insertRow:(size_t)ndx;
-(BOOL)insertRow:(size_t)ndx error:(NSError *__autoreleasing *)error;

-(void)setInt:(int64_t)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx;
-(void)setBool:(BOOL)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx;
-(void)setFloat:(float)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx;
-(void)setDouble:(double)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx;
-(void)setDate:(time_t)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx;
-(void)setString:(NSString *)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx;
-(void)setBinary:(TightdbBinary *)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx;
-(void)setMixed:(TightdbMixed *)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx;
-(void)setTable:(TightdbTable *)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx;

-(BOOL)getBoolInColumn:(size_t)colNdx atRow:(size_t)ndx;
-(int64_t)getIntInColumn:(size_t)colNdx atRow:(size_t)ndx;
-(float)getFloatInColumn:(size_t)colNdx atRow:(size_t)ndx;
-(double)getDoubleInColumn:(size_t)colNdx atRow:(size_t)ndx;
-(time_t)getDateInColumn:(size_t)colNdx atRow:(size_t)ndx;
-(NSString *)getStringInColumn:(size_t)colNdx atRow:(size_t)ndx;
-(TightdbBinary *)getBinaryInColumn:(size_t)colNdx atRow:(size_t)ndx;
-(TightdbMixed *)getMixedInColumn:(size_t)colNdx atRow:(size_t)ndx;

//@{
/// If the specified column is neither a subtable column, nor a mixed
/// column, then these methods return nil. They also return nil for a
/// mixed column, if the mixed value at the specified row is not a
/// subtable. The second method also returns nil if the type of the
/// subtable is not compatible with the specified table
/// class. Finally, these methods return nil if they encounter a
/// memory allocation error (out of memory).
///
/// The specified table class must be one that is declared by using
/// one of the table macros TIGHTDB_TABLE_*.
-(TightdbTable *)getTableInColumn:(size_t)colNdx atRow:(size_t)ndx;

// This method is only used in the typed interface. 
-(id)getTableInColumn:(size_t)colNdx atRow:(size_t)ndx withClass:(Class)obj;
//@}

// NOTE: Low-level insert functions. Always insert in all columns at once
// and call InsertDone after to avoid table getting un-balanced.

// FIXME: Remove this option from binding. Use insertRowAtIndex and a cursor.

-(BOOL)insertBool:(size_t)colNdx ndx:(size_t)ndx value:(BOOL)value;
-(BOOL)insertBool:(size_t)colNdx ndx:(size_t)ndx value:(BOOL)value error:(NSError *__autoreleasing *)error;
-(BOOL)insertInt:(size_t)colNdx ndx:(size_t)ndx value:(int64_t)value;
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
-(BOOL)insertDate:(size_t)colNdx ndx:(size_t)ndx value:(time_t)value error:(NSError *__autoreleasing *)error;
-(BOOL)insertDone;
-(BOOL)insertDoneWithError:(NSError *__autoreleasing *)error;




// Binary


//-(BOOL)setBinary:(size_t)colNdx ndx:(size_t)ndx data:(const char *)data size:(size_t)size;
//-(BOOL)setBinary:(size_t)colNdx ndx:(size_t)ndx data:(const char *)data size:(size_t)size error:(NSError *__autoreleasing *)error;

// Subtables
-(size_t)getTableSize:(size_t)colNdx ndx:(size_t)ndx;
-(BOOL)insertSubtable:(size_t)colNdx ndx:(size_t)ndx;
-(BOOL)insertSubtable:(size_t)colNdx ndx:(size_t)ndx error:(NSError *__autoreleasing *)error;
-(BOOL)clearSubtable:(size_t)colNdx ndx:(size_t)ndx;
-(BOOL)clearSubtable:(size_t)colNdx ndx:(size_t)ndx error:(NSError *__autoreleasing *)error;
//-(BOOL)setSubtable:(size_t)col_ndx ndx:(size_t)ndx withTable:(TightdbTable *)subtable;

// Mixed

-(TightdbType)getMixedType:(size_t)colNdx ndx:(size_t)ndx;
-(BOOL)insertMixed:(size_t)colNdx ndx:(size_t)ndx value:(TightdbMixed *)value;
-(BOOL)insertMixed:(size_t)colNdx ndx:(size_t)ndx value:(TightdbMixed *)value error:(NSError *__autoreleasing *)error;

-(size_t)addColumnWithType:(TightdbType)type andName:(NSString *)name;
-(size_t)addColumnWithType:(TightdbType)type andName:(NSString *)name error:(NSError *__autoreleasing *)error;

// Searching
-(size_t)findBool:(size_t)colNdx value:(BOOL)value;
-(size_t)findInt:(size_t)colNdx value:(int64_t)value;
-(size_t)findFloat:(size_t)colNdx value:(float)value;
-(size_t)findDouble:(size_t)colNdx value:(double)value;
-(size_t)findString:(size_t)colNdx value:(NSString *)value;
-(size_t)findBinary:(size_t)colNdx value:(TightdbBinary *)value;
-(size_t)findDate:(size_t)colNdx value:(time_t)value;
-(size_t)findMixed:(size_t)colNdx value:(TightdbMixed *)value;
-(TightdbQuery *)where;
-(TightdbQuery *)whereWithError:(NSError *__autoreleasing *)error;

// FIXME: Why does this one take a TableView as argument?
-(TightdbView *)findAll:(TightdbView *)view column:(size_t)colNdx value:(int64_t)value;
// FIXME: Implement findAll for the rest of the column types.

// Indexing
-(BOOL)hasIndex:(size_t)colNdx;
-(void)setIndex:(size_t)colNdx;

// Optimizing
-(BOOL)optimize;
-(BOOL)optimizeWithError:(NSError *__autoreleasing *)error;

// Conversion
// FIXME: Do we want to conversion methods? Maybe use NSData.

// Aggregate functions
-(size_t)countWithIntColumn:(size_t)colNdx andValue:(int64_t)target;
-(size_t)countWithFloatColumn:(size_t)colNdx andValue:(float)target;
-(size_t)countWithDoubleColumn:(size_t)colNdx andValue:(double)target;
-(size_t)countWithStringColumn:(size_t)colNdx andValue:(NSString *)target;
-(int64_t)sumWithIntColumn:(size_t)colNdx;
-(double)sumWithFloatColumn:(size_t)colNdx;
-(double)sumWithDoubleColumn:(size_t)colNdx;
-(int64_t)maximumWithIntColumn:(size_t)colNdx;
-(float)maximumWithFloatColumn:(size_t)colNdx;
-(double)maximumWithDoubleColumn:(size_t)colNdx;
-(int64_t)minimumWithIntColumn:(size_t)colNdx;
-(float)minimumWithFloatColumn:(size_t)colNdx;
-(double)minimumWithDoubleColumn:(size_t)colNdx;
-(double)averageWithIntColumn:(size_t)colNdx;
-(double)averageWithFloatColumn:(size_t)colNdx;
-(double)averageWithDoubleColumn:(size_t)colNDx;

#ifdef TIGHTDB_DEBUG
-(void)verify;
#endif

// Private
-(id)_initRaw;
-(BOOL)_insertSubtableCopy:(size_t)colNdx row:(size_t)rowNdx subtable:(TightdbTable *)subtable;
-(BOOL)_insertSubtableCopy:(size_t)colNdx row:(size_t)rowNdx subtable:(TightdbTable *)subtable error:(NSError *__autoreleasing *)error;
@end


@interface TightdbView: NSObject <NSFastEnumeration>
-(id)initFromQuery:(TightdbQuery *)query;
+(TightdbView *)tableViewWithTable:(TightdbTable *)table;

-(TightdbCursor *)cursorAtIndex:(size_t)ndx;

-(size_t)count;
-(BOOL)isEmpty;
-(int64_t)get:(size_t)colNdx ndx:(size_t)ndx;
-(BOOL)getBool:(size_t)colNdx ndx:(size_t)ndx;
-(time_t)getDate:(size_t)colNdx ndx:(size_t)ndx;
-(NSString *)getString:(size_t)colNdx ndx:(size_t)ndx;
-(void)removeRowAtIndex:(size_t)ndx;
-(void)clear;
-(TightdbTable *)getTable;
-(size_t)getSourceIndex:(size_t)ndx;
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len;
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
-(TightdbView *)findAll:(int64_t)value;
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
