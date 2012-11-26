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

#include <tightdb/objc/column_type.h>

#define tdbOCTypeInt int64_t
#define tdbOCTypeBool BOOL
#define tdbOCTypeString NSString*
#define tdbOCTypeMixed OCMixed*

#define COLTYPEInt COLUMN_TYPE_INT
#define COLTYPEBool COLUMN_TYPE_BOOL
#define COLTYPEString COLUMN_TYPE_STRING
#define COLTYPEDate COLUMN_TYPE_DATE
#define COLTYPEMixed COLUMN_TYPE_MIXED

@class Table;
@class TableView;

@interface BinaryData : NSObject
-(id)initWithData:(char *)ptr len:(size_t)len;
@end

@interface OCMemRef : NSObject
-(id)initWithPointer:(void *)p ref:(size_t)r;
-(void *)getPointer;
-(size_t)getRef;
@end

@interface OCDate : NSObject
-(id)initWithDate:(time_t)d;
-(time_t)getDate;
-(BOOL)isEqual:(OCDate *)other;
@end

@interface OCMixed : NSObject
+(OCMixed *)mixedWithTable:(Table *)table;
+(OCMixed *)mixedWithBool:(BOOL)value;
+(OCMixed *)mixedWithDate:(OCDate *)date;
+(OCMixed *)mixedWithInt64:(int64_t)value;
+(OCMixed *)mixedWithString:(NSString *)string;
+(OCMixed *)mixedWithBinary:(BinaryData *)data;
+(OCMixed *)mixedWithData:(const char*)value length:(size_t)length;
-(BOOL)isEqual:(OCMixed *)other;
-(ColumnType)getType;
-(int64_t)getInt;
-(BOOL)getBool;
-(OCDate *)getDate;
-(NSString *)getString;
-(BinaryData *)getBinary;
-(Table *)getTable;
@end


@interface OCSpec : NSObject
/// Returns NO on memory allocation error.
-(BOOL)addColumn:(ColumnType)type name:(NSString *)name;
/// Returns nil on memory allocation error.
-(OCSpec *)addColumnTable:(NSString *)name;
-(OCSpec *)getSpec:(size_t)columnId;
-(size_t)getColumnCount;
-(ColumnType)getColumnType:(size_t)ndx;
-(NSString *)getColumnName:(size_t)ndx;
-(size_t)getColumnIndex:(NSString *)name;
-(size_t)write:(id)obj pos:(size_t)pos;
@end


@interface Table : NSObject
-(void)updateFromSpec;
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len;

// TODO - TableRef methods ?????????

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
-(Table *)getSubtable:(size_t)columnId ndx:(size_t)ndx;
-(id)getSubtable:(size_t)columnId ndx:(size_t)ndx withClass:(Class)obj;
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
-(ColumnType)getColumnType:(size_t)ndx;
-(OCSpec *)getSpec;
-(BOOL)isEmpty;
-(size_t)count;
-(size_t)addRow;
-(void)clear;
-(void)deleteRow:(size_t)ndx;
-(void)popBack;

// Adaptive ints.
-(int64_t)get:(size_t)columnId ndx:(size_t)ndx;
-(void)set:(size_t)columnId ndx:(size_t)ndx value:(int64_t)value;
-(BOOL)getBool:(size_t)columnId ndx:(size_t)ndx;
-(void)setBool:(size_t)columnId ndx:(size_t)ndx value:(BOOL)value;
-(time_t)getDate:(size_t)columnId ndx:(size_t)ndx;
-(void)setDate:(size_t)columnId ndx:(size_t)ndx value:(time_t)value;

// NOTE: Low-level insert functions. Always insert in all columns at once
// and call InsertDone after to avoid table getting un-balanced.
-(void)insertInt:(size_t)columnId ndx:(size_t)ndx value:(int64_t)value;
-(void)insertBool:(size_t)columnId ndx:(size_t)ndx value:(BOOL)value;
-(void)insertDate:(size_t)columnId ndx:(size_t)ndx value:(time_t)value;
-(void)insertString:(size_t)columnId ndx:(size_t)ndx value:(NSString *)value;
-(void)insertBinary:(size_t)columnId ndx:(size_t)ndx value:(void *)value len:(size_t)len;
-(void)insertDone;

// Strings
-(NSString *)getString:(size_t)columnId ndx:(size_t)ndx;
-(void)setString:(size_t)columnId ndx:(size_t)ndx value:(NSString *)value;

// Binary
-(BinaryData *)getBinary:(size_t)columnId ndx:(size_t)ndx;
-(void)setBinary:(size_t)columnId ndx:(size_t)ndx value:(void *)value len:(size_t)len;

// Subtables
-(size_t)getTableSize:(size_t)columnId ndx:(size_t)ndx;
-(void)insertSubtable:(size_t)columnId ndx:(size_t)ndx;
-(void)clearTable:(size_t)columnId ndx:(size_t)ndx;

// Mixed
-(OCMixed *)getMixed:(size_t)columnId ndx:(size_t)ndx;
-(ColumnType)getMixedType:(size_t)columnId ndx:(size_t)ndx;
-(void)insertMixed:(size_t)columnId ndx:(size_t)ndx value:(OCMixed *)value;
-(void)setMixed:(size_t)columnId ndx:(size_t)ndx value:(OCMixed *)value;

-(size_t)addColumn:(ColumnType)type name:(NSString *)name;

// TODO - Column stuff...

// Searching
-(size_t)find:(size_t)columnId value:(int64_t)value;
-(size_t)findBool:(size_t)columnId value:(BOOL)value;
-(size_t)findString:(size_t)columnId value:(NSString *)value;
-(size_t)findDate:(size_t)columnId value:(time_t)value;

// TODO - Table view stuff
-(TableView *)findAll:(TableView *)view column:(size_t)columnId value:(int64_t)value;

// Indexing
-(BOOL)hasIndex:(size_t)columnId;
-(void)setIndex:(size_t)columnId;

// Optimizing
-(void)optimize;

// Conversion
// TODO ????? - Maybe NSData ???

// Aggregate functions
-(size_t)countInt:(size_t)columnId target:(int64_t)target;
-(size_t)countString:(size_t)columnId target:(NSString *)target;
-(int64_t)sum:(size_t)columnId;
-(int64_t)maximum:(size_t)columnId;
-(int64_t)minimum:(size_t)columnId;
-(double)average:(size_t)columnId;

#ifdef TIGHTDB_DEBUG
-(void)verify;
#endif

-(id)_initRaw;
-(void)_insertSubtableCopy:(size_t)col_ndx row_ndx:(size_t)row_ndx subtable:(Table *)subtable;
@end


@class Query;
@interface TableView : NSObject
-(id)initFromQuery:(Query *)query;
+(TableView *)tableViewWithTable:(Table *)table;

-(size_t)count;
-(BOOL)isEmpty;
-(int64_t)get:(size_t)columnId ndx:(size_t)ndx;
-(BOOL)getBool:(size_t)columnId ndx:(size_t)ndx;
-(time_t)getDate:(size_t)columnId ndx:(size_t)ndx;
-(NSString *)getString:(size_t)columnId ndx:(size_t)ndx;
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

@interface OCColumnProxyInt : OCColumnProxy
-(size_t)find:(int64_t)value;
-(size_t)findPos:(int64_t)value;
-(TableView *)findAll:(int64_t)value;
@end
@interface OCColumnProxyBool : OCColumnProxy
-(size_t)find:(BOOL)value;
@end
@interface OCColumnProxyDate : OCColumnProxy
-(size_t)find:(time_t) value;
@end
@interface OCColumnProxyString : OCColumnProxy
-(size_t)find:(NSString*)value;
@end
@interface OCColumnProxyMixed : OCColumnProxy
-(size_t)find:(OCMixed*)value;
@end
