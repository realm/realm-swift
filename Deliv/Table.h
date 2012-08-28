//
//  Table.h
//  TightDB
//

#import <Foundation/Foundation.h>
#include "ColumnType.h"

#define tdbOCTypeInt int64_t
#define tdbOCTypeBool BOOL
#define tdbOCTypeString NSString*
#define tdbOCTypeMixed OCMixed*

#define COLTYPEInt COLUMN_TYPE_INT
#define COLTYPEBool COLUMN_TYPE_BOOL
#define COLTYPEString COLUMN_TYPE_STRING
#define COLTYPEDate COLUMN_TYPE_DATE

@interface BinaryData : NSObject
-(id)initWithData:(char *)ptr len:(size_t)len;
@end
@class Table;
@class OCTopLevelTable;
typedef void(^TopLevelTableInitBlock)(Table *table);

@interface OCMemRef : NSObject
-(id)initWithPointer:(void *)p ref:(size_t)r;
-(void *)getPointer;
-(size_t)getRef;
@end

@interface OCAllocator : NSObject
-(OCMemRef *)alloc:(size_t)size;
-(OCMemRef *)reAlloc:(size_t)ref pointer:(void *)p size:(size_t)size;
-(void)free:(size_t)ref pointer:(void *)p;
-(void*)translate:(size_t)ref;
-(BOOL)isReadOnly:(size_t)ref;
@end

@interface OCDate : NSObject
-(id)initWithDate:(time_t)d;
-(time_t)getDate;
@end

@interface OCMixed : NSObject
+(OCMixed *)mixedWithTable;
+(OCMixed *)mixedWithBool:(BOOL)value;
+(OCMixed *)mixedWithDate:(OCDate *)date;
+(OCMixed *)mixedWithInt64:(int64_t)value;
+(OCMixed *)mixedWithString:(NSString *)string;
+(OCMixed *)mixedWithBinary:(BinaryData *)data;
+(OCMixed *)mixedWithData:(const char*)value length:(size_t)length;
-(ColumnType)getType;
-(int64_t)getInt;
-(BOOL)getBool;
-(OCDate *)getDate;
-(NSString *)getString;
-(BinaryData *)getBinary;
@end


@interface OCSpec : NSObject
-(void)addColumn:(ColumnType)type name:(NSString *)name;
-(OCSpec *)addColumnTable:(NSString *)name;
-(OCSpec *)getSpec:(size_t)columndId;
-(size_t)getColumnCount;
-(ColumnType)getColumnType:(size_t)ndx;
-(NSString *)getColumnName:(size_t)ndx;
-(size_t)getColumnIndex:(NSString *)name;
-(size_t)write:(id)obj pos:(size_t)pos;
@end

@class TableView;

@interface Table : NSObject
// TODO - TableRef methods ?????????
-(Table *)getTable:(size_t)columnId ndx:(size_t)ndx;
-(OCTopLevelTable *)getTopLevelTable:(size_t)columnId ndx:(size_t)ndx;
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
-(BOOL)getBool:(size_t)columndId ndx:(size_t)ndx;
-(void)setBool:(size_t)columndId ndx:(size_t)ndx value:(BOOL)value;
-(time_t)getDate:(size_t)columndId ndx:(size_t)ndx;
-(void)setDate:(size_t)columndId ndx:(size_t)ndx value:(time_t)value;

// NOTE: Low-level insert functions. Always insert in all columns at once
// and call InsertDone after to avoid table getting un-balanced.
-(void)insertInt:(size_t)columndId ndx:(size_t)ndx value:(int64_t)value;
-(void)insertBool:(size_t)columndId ndx:(size_t)ndx value:(BOOL)value;
-(void)insertDate:(size_t)columndId ndx:(size_t)ndx value:(time_t)value;
-(void)insertString:(size_t)columndId ndx:(size_t)ndx value:(NSString *)value;
-(void)insertBinary:(size_t)columndId ndx:(size_t)ndx value:(void *)value len:(size_t)len;
-(void)insertDone;

// Strings
-(NSString *)getString:(size_t)columndId ndx:(size_t)ndx;
-(void)setString:(size_t)columndId ndx:(size_t)ndx value:(NSString *)value;

// Binary
-(BinaryData *)getBinary:(size_t)columndId ndx:(size_t)ndx;
-(void)setBinary:(size_t)columndId ndx:(size_t)ndx value:(void *)value len:(size_t)len;

// Subtables
-(size_t)getTableSize:(size_t)columnId ndx:(size_t)ndx;
-(void)insertTable:(size_t)columnId ndx:(size_t)ndx;
-(void)clearTable:(size_t)columnId ndx:(size_t)ndx;

// Mixed
-(OCMixed *)getMixed:(size_t)columnId ndx:(size_t)ndx;
-(ColumnType)getMixedType:(size_t)columnId ndx:(size_t)ndx;
-(void)insertMixed:(size_t)columnId ndx:(size_t)ndx value:(OCMixed *)value;
-(void)setMixed:(size_t)columnId ndx:(size_t)ndx value:(OCMixed *)value;

-(size_t)registerColumn:(ColumnType)type name:(NSString *)name;

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

#ifdef _DEBUG
-(void)verify;
#endif
@end


@interface OCTopLevelTable : Table
// refs ??? TODO
-(id)initWithBlock:(TopLevelTableInitBlock)block;
-(void)updateFromSpec;
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len;
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






