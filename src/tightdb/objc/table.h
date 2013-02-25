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

#include <tightdb/objc/data_type.h>

@class Table;
@class TableView;

@interface BinaryData : NSObject
-(id)initWithData:(const char *)data size:(size_t)size;
-(const char *)getData;
-(size_t)getSize;

/// Compare the referenced binary data for equality.
-(BOOL)isEqual:(BinaryData *)bin;
@end

@interface OCMixed : NSObject
+(OCMixed *)mixedWithBool:(BOOL)value;
+(OCMixed *)mixedWithInt64:(int64_t)value;
+(OCMixed *)mixedWithFloat:(float)value;
+(OCMixed *)mixedWithDouble:(double)value;
+(OCMixed *)mixedWithString:(NSString *)value;
+(OCMixed *)mixedWithBinary:(BinaryData *)value;
+(OCMixed *)mixedWithBinary:(const char *)data size:(size_t)size;
+(OCMixed *)mixedWithDate:(time_t)value;
+(OCMixed *)mixedWithTable:(Table *)value;
-(BOOL)isEqual:(OCMixed *)other;
-(TightdbDataType)getType;
-(BOOL)getBool;
-(int64_t)getInt;
-(float)getFloat;
-(double)getDouble;
-(NSString *)getString;
-(BinaryData *)getBinary;
-(time_t)getDate;
-(Table *)getTable;
@end


@interface OCSpec : NSObject
/// Returns NO on memory allocation error.
-(BOOL)addColumn:(TightdbDataType)type name:(NSString *)name;
/// Returns nil on memory allocation error.
-(OCSpec *)addColumnTable:(NSString *)name;
-(OCSpec *)getSubspec:(size_t)colNdx;
-(size_t)getColumnCount;
-(TightdbDataType)getColumnType:(size_t)colNdx;
-(NSString *)getColumnName:(size_t)colNdx;
-(size_t)getColumnIndex:(NSString *)name;
@end


@interface Table : NSObject
-(void)updateFromSpec;
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len;

-(BOOL)isEqual:(Table *)other;

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
-(Table *)getSubtable:(size_t)colNdx ndx:(size_t)ndx;
-(id)getSubtable:(size_t)colNdx ndx:(size_t)ndx withClass:(Class)obj;
//@}

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
-(TightdbDataType)getColumnType:(size_t)ndx;
-(OCSpec *)getSpec;
-(BOOL)isEmpty;
-(size_t)count;
-(size_t)addRow;
-(void)clear;
-(void)deleteRow:(size_t)ndx;
-(void)popBack;

// Adaptive ints.
-(int64_t)get:(size_t)colNdx ndx:(size_t)ndx;
-(void)set:(size_t)colNdx ndx:(size_t)ndx value:(int64_t)value;
-(BOOL)getBool:(size_t)colNdx ndx:(size_t)ndx;
-(void)setBool:(size_t)colNdx ndx:(size_t)ndx value:(BOOL)value;
-(float)getFloat:(size_t)colNdx ndx:(size_t)ndx;
-(void)setFloat:(size_t)colNdx ndx:(size_t)ndx value:(float)value;
-(double)getDouble:(size_t)colNdx ndx:(size_t)ndx;
-(void)setDouble:(size_t)colNdx ndx:(size_t)ndx value:(double)value;
-(time_t)getDate:(size_t)colNdx ndx:(size_t)ndx;
-(void)setDate:(size_t)colNdx ndx:(size_t)ndx value:(time_t)value;

// NOTE: Low-level insert functions. Always insert in all columns at once
// and call InsertDone after to avoid table getting un-balanced.
-(void)insertBool:(size_t)colNdx ndx:(size_t)ndx value:(BOOL)value;
-(void)insertInt:(size_t)colNdx ndx:(size_t)ndx value:(int64_t)value;
-(void)insertFloat:(size_t)colNdx ndx:(size_t)ndx value:(float)value;
-(void)insertDouble:(size_t)colNdx ndx:(size_t)ndx value:(double)value;
-(void)insertString:(size_t)colNdx ndx:(size_t)ndx value:(NSString *)value;
-(void)insertBinary:(size_t)colNdx ndx:(size_t)ndx value:(BinaryData *)value;
-(void)insertBinary:(size_t)colNdx ndx:(size_t)ndx data:(const char *)data size:(size_t)size;
-(void)insertDate:(size_t)colNdx ndx:(size_t)ndx value:(time_t)value;
-(void)insertDone;

// Strings
-(NSString *)getString:(size_t)colNdx ndx:(size_t)ndx;
-(void)setString:(size_t)colNdx ndx:(size_t)ndx value:(NSString *)value;

// Binary
-(BinaryData *)getBinary:(size_t)colNdx ndx:(size_t)ndx;
-(void)setBinary:(size_t)colNdx ndx:(size_t)ndx value:(BinaryData *)value;
-(void)setBinary:(size_t)colNdx ndx:(size_t)ndx data:(const char *)data size:(size_t)size;

// Subtables
-(size_t)getTableSize:(size_t)colNdx ndx:(size_t)ndx;
-(void)insertSubtable:(size_t)colNdx ndx:(size_t)ndx;
-(void)clearSubtable:(size_t)colNdx ndx:(size_t)ndx;

// Mixed
-(OCMixed *)getMixed:(size_t)colNdx ndx:(size_t)ndx;
-(TightdbDataType)getMixedType:(size_t)colNdx ndx:(size_t)ndx;
-(void)insertMixed:(size_t)colNdx ndx:(size_t)ndx value:(OCMixed *)value;
-(void)setMixed:(size_t)colNdx ndx:(size_t)ndx value:(OCMixed *)value;

-(size_t)addColumn:(TightdbDataType)type name:(NSString *)name;

// Searching
-(size_t)findBool:(size_t)colNdx value:(BOOL)value;
-(size_t)findInt:(size_t)colNdx value:(int64_t)value;
-(size_t)findFloat:(size_t)colNdx value:(float)value;
-(size_t)findDouble:(size_t)colNdx value:(double)value;
-(size_t)findString:(size_t)colNdx value:(NSString *)value;
-(size_t)findBinary:(size_t)colNdx value:(BinaryData *)value;
-(size_t)findDate:(size_t)colNdx value:(time_t)value;
-(size_t)findMixed:(size_t)colNdx value:(OCMixed *)value;

// FIXME: Why does this one take a TableView as argument?
-(TableView *)findAll:(TableView *)view column:(size_t)colNdx value:(int64_t)value;
// FIXME: Implement findAll for the rest of the column types.

// Indexing
-(BOOL)hasIndex:(size_t)colNdx;
-(void)setIndex:(size_t)colNdx;

// Optimizing
-(void)optimize;

// Conversion
// FIXME: Do we want to conversion methods? Maybe use NSData.

// Aggregate functions
-(size_t)countInt:(size_t)colNdx target:(int64_t)target;
-(size_t)countFloat:(size_t)colNdx target:(float)target;
-(size_t)countDouble:(size_t)colNdx target:(double)target;
-(size_t)countString:(size_t)colNdx target:(NSString *)target;
-(int64_t)sumInt:(size_t)colNdx;
-(double)sumFloat:(size_t)colNdx;
-(double)sumDouble:(size_t)colNdx;
-(int64_t)maxInt:(size_t)colNdx;
-(float)maxFloat:(size_t)colNdx;
-(double)maxDouble:(size_t)colNdx;
-(int64_t)minInt:(size_t)colNdx;
-(float)minFloat:(size_t)colNdx;
-(double)minDouble:(size_t)colNdx;
-(double)avgInt:(size_t)colNdx;
-(double)avgFloat:(size_t)colNdx;
-(double)avgDouble:(size_t)colNDx;

#ifdef TIGHTDB_DEBUG
-(void)verify;
#endif

// Private
-(id)_initRaw;
-(void)_insertSubtableCopy:(size_t)colNdx row:(size_t)rowNdx subtable:(Table *)subtable;
@end


@class Query;
@interface TableView : NSObject
-(id)initFromQuery:(Query *)query;
+(TableView *)tableViewWithTable:(Table *)table;

-(size_t)count;
-(BOOL)isEmpty;
-(int64_t)get:(size_t)colNdx ndx:(size_t)ndx;
-(BOOL)getBool:(size_t)colNdx ndx:(size_t)ndx;
-(time_t)getDate:(size_t)colNdx ndx:(size_t)ndx;
-(NSString *)getString:(size_t)colNdx ndx:(size_t)ndx;
// Deleting
-(void)delete:(size_t)ndx;
-(void)clear;
-(Table *)getTable;
-(size_t)getSourceNdx:(size_t)ndx;
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len;
@end


@interface OCColumnProxy : NSObject
@property(nonatomic, weak) Table *table;
@property(nonatomic) size_t column;
-(id)initWithTable:(Table *)table column:(size_t)column;
-(void)clear;
@end

@interface OCColumnProxy_Bool : OCColumnProxy
-(size_t)find:(BOOL)value;
@end

@interface OCColumnProxy_Int : OCColumnProxy
-(size_t)find:(int64_t)value;
-(TableView *)findAll:(int64_t)value;
-(int64_t)min;
-(int64_t)max;
-(int64_t)sum;
-(double)avg;
@end

@interface OCColumnProxy_Float : OCColumnProxy
-(size_t)find:(float)value;
-(float)min;
-(float)max;
-(double)sum;
-(double)avg;
@end

@interface OCColumnProxy_Double : OCColumnProxy
-(size_t)find:(double)value;
-(double)min;
-(double)max;
-(double)sum;
-(double)avg;
@end

@interface OCColumnProxy_String : OCColumnProxy
-(size_t)find:(NSString *)value;
@end

@interface OCColumnProxy_Binary : OCColumnProxy
-(size_t)find:(BinaryData *)value;
@end

@interface OCColumnProxy_Date : OCColumnProxy
-(size_t)find:(time_t) value;
@end
@interface OCColumnProxy_Subtable : OCColumnProxy
@end

@interface OCColumnProxy_Mixed : OCColumnProxy
-(size_t)find:(OCMixed *)value;
@end
