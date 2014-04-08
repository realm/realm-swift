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

#include <tightdb/util/unique_ptr.hpp>
#include <tightdb/table.hpp>
#include <tightdb/descriptor.hpp>
#include <tightdb/table_view.hpp>
#include <tightdb/lang_bind_helper.hpp>

#include "util_noinst.hpp"

#import <tightdb/objc/TDBTable.h>
#import <tightdb/objc/TDBTable_noinst.h>
#import <tightdb/objc/TDBView.h>
#import <tightdb/objc/TDBView_noinst.h>
#import <tightdb/objc/TDBQuery.h>
#import <tightdb/objc/TDBQuery_noinst.h>
#import <tightdb/objc/TDBRow.h>
#import <tightdb/objc/TDBDescriptor.h>
#import <tightdb/objc/TDBDescriptor_noinst.h>
#import <tightdb/objc/TDBColumnProxy.h>
#import <tightdb/objc/NSData+TDBGetBinaryData.h>
#import <tightdb/objc/PrivateTDB.h>


#include <tightdb/objc/util_noinst.hpp>

using namespace std;

@implementation TDBTable
{
    tightdb::TableRef m_table;
    id m_parent;
    BOOL m_read_only;
    TDBRow* m_tmp_row;
}



-(instancetype)init
{
    self = [super init];
    if (self) {
        m_read_only = NO;
        m_table = tightdb::Table::create(); // FIXME: May throw
    }
    return self;
}

-(instancetype)initWithColumns:(NSArray *)columns
{
    self = [super init];
    if (!self)
        return nil;

    m_read_only = NO;
    m_table = tightdb::Table::create(); // FIXME: May throw

    if (!set_columns(m_table, columns)) {
        m_table.reset();

        // Parsing the schema failed
        //TODO: More detailed error msg in exception
        NSException* exception = [NSException exceptionWithName:@"tightdb:invalid_columns"
                                                         reason:@"The supplied list of columns was invalid"
                                                       userInfo:[NSMutableDictionary dictionary]];
        [exception raise];
    }

    return self;
}

-(id)_initRaw
{
    self = [super init];
    return self;
}

-(BOOL)_checkType
{
    return YES;
    // Dummy - must be overridden in tightdb.h - Check if spec matches the macro definitions
}

-(TDBRow*)getRow
{
    return m_tmp_row = [[TDBRow alloc] initWithTable:self ndx:0];
}
-(void)clearRow
{
    // Dummy - must be overridden in tightdb.h

    // TODO: This method was never overridden in tightdh.h. Presumably above comment is made by Thomas.
    //       Clarify if we need the method.
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState*)state objects:(id __unsafe_unretained*)stackbuf count:(NSUInteger)len
{
    static_cast<void>(len);
    if(state->state == 0) {
        const unsigned long* ptr = static_cast<const unsigned long*>(objc_unretainedPointer(self));
        state->mutationsPtr = const_cast<unsigned long*>(ptr); // FIXME: This casting away of constness seems dangerous. Is it?
        TDBRow* tmp = [self getRow];
        *stackbuf = tmp;
    }
    if (state->state < self.rowCount) {
        [((TDBRow*)*stackbuf) TDB_setNdx:state->state];
        state->itemsPtr = stackbuf;
        state->state++;
    }
    else {
        *stackbuf = nil;
        state->itemsPtr = nil;
        state->mutationsPtr = nil;
        [self clearRow];
        return 0;
    }
    return 1;
}

-(tightdb::Table&)getNativeTable
{
    return *m_table;
}

-(void)setNativeTable:(tightdb::Table*)table
{
    m_table.reset(table);
}

-(void)setParent:(id)parent
{
    m_parent = parent;
}

-(void)setReadOnly:(BOOL)read_only
{
    m_read_only = read_only;
}

-(BOOL)isReadOnly
{
    return m_read_only;
}

-(BOOL)isEqual:(id)other
{
    if ([other isKindOfClass:[TDBTable class]])
        return *m_table == *(((TDBTable *)other)->m_table);
    return NO;
}

//
// This method will return NO if it encounters a memory allocation
// error (out of memory).
//
// The specified table class must be one that is declared by using
// one of the table macros TIGHTDB_TABLE_*.
//
// FIXME: Check that the specified class derives from TDBTable.
-(BOOL)hasSameDescriptorAs:(__unsafe_unretained Class)class_obj
{
    TDBTable* table = [[class_obj alloc] _initRaw];
    if (TIGHTDB_LIKELY(table)) {
        [table setNativeTable:m_table.get()];
        [table setParent:m_parent];
        [table setReadOnly:m_read_only];
        if ([table _checkType])
            return YES;
    }
    return NO;
}

//
// If the type of this table is not compatible with the specified
// table class, then this method returns nil. It also returns nil if
// it encounters a memory allocation error (out of memory).
//
// The specified table class must be one that is declared by using
// one of the table macros TIGHTDB_TABLE_*.
//
// FIXME: Check that the specified class derives from TDBTable.
-(id)castClass:(__unsafe_unretained Class)class_obj
{
    TDBTable* table = [[class_obj alloc] _initRaw];
    if (TIGHTDB_LIKELY(table)) {
        [table setNativeTable:m_table.get()];
        [table setParent:m_parent];
        [table setReadOnly:m_read_only];
        if (![table _checkType])
            return nil;
    }
    return table;
}

-(void)dealloc
{
#ifdef TIGHTDB_DEBUG
    NSLog(@"TDBTable dealloc");
#endif
    m_parent = nil; // FIXME: Does this really make a difference?
}

-(NSUInteger)columnCount
{
    return m_table->get_column_count();
}
-(NSString*)nameOfColumnWithIndex:(NSUInteger)ndx
{
    return to_objc_string(m_table->get_column_name(ndx));
}
-(NSUInteger)indexOfColumnWithName:(NSString *)name
{
    return was_not_found(m_table->get_column_index(ObjcStringAccessor(name)));
}
-(TDBType)columnTypeOfColumnWithIndex:(NSUInteger)ndx
{
    return TDBType(m_table->get_column_type(ndx));
}
-(TDBDescriptor*)descriptor
{
    return [self descriptorWithError:nil];
}
-(TDBDescriptor*)descriptorWithError:(NSError* __autoreleasing*)error
{
    tightdb::DescriptorRef desc = m_table->get_descriptor();
    BOOL read_only = m_read_only || m_table->has_shared_type();
    return [TDBDescriptor descWithDesc:desc.get() readOnly:read_only error:error];
}

-(NSUInteger)rowCount // Implementing property accessor
{
    return m_table->size();
}

-(TDBRow*)insertEmptyRowAtIndex:(NSUInteger)ndx
{
    [self TDBInsertRow:ndx];
    return [[TDBRow alloc] initWithTable:self ndx:ndx];
}

-(BOOL)TDBInsertRow:(NSUInteger)ndx
{
    return [self TDBInsertRow:ndx error:nil];
}

-(BOOL)TDBInsertRow:(NSUInteger)ndx error:(NSError* __autoreleasing*)error
{
    if (m_read_only) {
        if (error)
            *error = make_tightdb_error(tdb_err_FailRdOnly, @"Tried to insert row while read-only.");
        return NO;
    }
    
    TIGHTDB_EXCEPTION_ERRHANDLER(m_table->insert_empty_row(ndx);, 0);
    return YES;
}


-(NSUInteger)TDB_addEmptyRow
{
    return [self TDB_addEmptyRows:1];
}

-(NSUInteger)TDB_addEmptyRows:(NSUInteger)num_rows
{
    // TODO: Use a macro or a function for error handling

    if(m_read_only) {
        @throw [NSException exceptionWithName:@"tightdb:table_is_read_only"
                                       reason:@"You tried to modify a table in read only mode"
                                     userInfo:nil];
    }

    NSUInteger index;
    try {
        index = m_table->add_empty_row(num_rows);
    }
    catch(std::exception& ex) {
        @throw [NSException exceptionWithName:@"tightdb:core_exception"
                                       reason:[NSString stringWithUTF8String:ex.what()]
                                     userInfo:nil];
    }

    return index;
}

-(TDBRow *)objectAtIndexedSubscript:(NSUInteger)ndx
{
    return [[TDBRow alloc] initWithTable:self ndx:ndx];
}

-(void)setObject:(id)newValue atIndexedSubscript:(NSUInteger)rowIndex
{
    tightdb::Table& table = *m_table;
    tightdb::ConstDescriptorRef desc = table.get_descriptor();

    if (table.size() < (size_t)rowIndex) {
        // FIXME: raise exception - out of bound
        return ;
    }

    if ([newValue isKindOfClass:[NSArray class]]) {
        verify_row(*desc, (NSArray *)newValue);
        set_row(size_t(rowIndex), table, (NSArray *)newValue);
        return ;
    }
    
    if ([newValue isKindOfClass:[NSDictionary class]]) {
        verify_row_with_labels(*desc, (NSDictionary *)newValue);
        set_row_with_labels(size_t(rowIndex), table, (NSDictionary *)newValue);
        return ;
    }

    if ([newValue isKindOfClass:[NSObject class]]) {
        verify_row_from_object(*desc, (NSObject *)newValue);
        set_row_from_object(rowIndex, table, (NSObject *)newValue);
        return ;
    }

    @throw [NSException exceptionWithName:@"tightdb:column_not_implemented"
                                   reason:@"You should either use nil, NSObject, NSDictionary, or NSArray"
                                 userInfo:nil];
}


-(TDBRow*)rowAtIndex:(NSUInteger)ndx
{
    // initWithTable checks for illegal index.

    return [[TDBRow alloc] initWithTable:self ndx:ndx];
}

-(TDBRow*)firstRow
{
    if (self.rowCount == 0) {
        return nil;
    }
    return [[TDBRow alloc] initWithTable:self ndx:0];
}

-(TDBRow*)lastRow
{
    if (self.rowCount == 0) {
        return nil;
    }
    return [[TDBRow alloc] initWithTable:self ndx:self.rowCount-1];
}

-(TDBRow*)insertRowAtIndex:(NSUInteger)ndx
{
    [self insertEmptyRowAtIndex:ndx];
    return [[TDBRow alloc] initWithTable:self ndx:ndx];
}

-(void)addRow:(NSObject*)data
{
    if (!data) {
        [self TDB_addEmptyRow];
        return ;
    }
    tightdb::Table& table = *m_table;
    [self insertRow:data atIndex:table.size()];
}

/* Moved to private header */
-(TDBRow*)addEmptyRow
{
    return [[TDBRow alloc] initWithTable:self ndx:[self TDB_addEmptyRow]];
}


-(void)insertRow:(NSObject *)anObject atIndex:(NSUInteger)rowIndex
{
    if (!anObject) {
        [self TDBInsertRow:rowIndex];
        return ;
    }
    
    tightdb::Table& table = *m_table;
    tightdb::ConstDescriptorRef desc = table.get_descriptor();
    
    if ([anObject isKindOfClass:[NSArray class]]) {
        verify_row(*desc, (NSArray *)anObject);
        insert_row(size_t(rowIndex), table, (NSArray *)anObject);
        return ;
    }
    
    if ([anObject isKindOfClass:[NSDictionary class]]) {
        verify_row_with_labels(*desc, (NSDictionary *)anObject);
        insert_row_with_labels(size_t(rowIndex), table, (NSDictionary *)anObject);
        return ;
    }
    
    if ([anObject isKindOfClass:[NSObject class]]) {
        verify_row_from_object(*desc, (NSObject *)anObject);
        insert_row_from_object(size_t(rowIndex), table, (NSObject *)anObject);
        return ;
    }

    @throw [NSException exceptionWithName:@"tightdb:column_not_implemented"
                                   reason:@"You should either use nil, NSObject, NSDictionary, or NSArray"
                                 userInfo:nil];
}


-(BOOL)removeAllRows
{
    if (m_read_only) {
        NSException* exception = [NSException exceptionWithName:@"tightdb:table_view_is_read_only"
                                                         reason:@"You tried to modify an immutable table."
                                                       userInfo:nil];
        [exception raise];
        return NO;
    }
    
    m_table->clear();
    return YES;
}

-(BOOL)removeRowAtIndex:(NSUInteger)ndx
{
    return [self removeRowAtIndex:ndx error:nil];
}

-(BOOL)removeRowAtIndex:(NSUInteger)ndx error:(NSError* __autoreleasing*)error
{
    if (m_read_only) {
        if (error)
            *error = make_tightdb_error(tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to remove row while read only ndx: %llu", (unsigned long long)ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(m_table->remove(ndx);, NO);
    return YES;
}

-(BOOL)removeLastRow
{
    return [self removeLastRowWithError:nil];
}

-(BOOL)removeLastRowWithError:(NSError* __autoreleasing*)error
{
    if (m_read_only) {
        if (error)
            *error = make_tightdb_error(tdb_err_FailRdOnly, @"Tried to remove last while read-only.");
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(m_table->remove_last();, NO);
    return YES;
}


-(BOOL)TDB_boolInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return m_table->get_bool(colIndex, rowIndex);
}

-(int64_t)TDB_intInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return m_table->get_int(colIndex, rowIndex);
}

-(float)TDB_floatInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return m_table->get_float(colIndex, rowIndex);
}

-(double)TDB_doubleInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return m_table->get_double(colIndex, rowIndex);
}

-(NSString*)TDB_stringInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return to_objc_string(m_table->get_string(colIndex, rowIndex));
}

-(NSData*)TDB_binaryInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    tightdb::BinaryData bd = m_table->get_binary(colIndex, rowIndex);
    return [[NSData alloc] initWithBytes:static_cast<const void *>(bd.data()) length:bd.size()];
}

-(NSDate *)TDB_dateInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return [NSDate dateWithTimeIntervalSince1970: m_table->get_datetime(colIndex, rowIndex).get_datetime()];
}

-(TDBTable*)TDB_tableInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    tightdb::DataType type = m_table->get_column_type(colIndex);
    if (type != tightdb::type_Table)
        return nil;
    tightdb::TableRef table = m_table->get_subtable(colIndex, rowIndex);
    if (!table)
        return nil;
    TDBTable* table_2 = [[TDBTable alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table_2))
        return nil;
    [table_2 setNativeTable:table.get()];
    [table_2 setParent:self];
    [table_2 setReadOnly:m_read_only];
    return table_2;
}

// FIXME: Check that the specified class derives from TDBTable.
-(id)TDB_tableInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex asTableClass:(__unsafe_unretained Class)tableClass
{
    tightdb::DataType type = m_table->get_column_type(colIndex);
    if (type != tightdb::type_Table)
        return nil;
    tightdb::TableRef table = m_table->get_subtable(colIndex, rowIndex);
    TIGHTDB_ASSERT(table);
    TDBTable* table_2 = [[tableClass alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table))
        return nil;
    [table_2 setNativeTable:table.get()];
    [table_2 setParent:self];
    [table_2 setReadOnly:m_read_only];
    if (![table_2 _checkType])
        return nil;
    return table_2;
}

-(id)TDB_mixedInColumnWithIndex:(NSUInteger)colNdx atRowIndex:(NSUInteger)rowIndex
{
    tightdb::Mixed mixed = m_table->get_mixed(colNdx, rowIndex);
    if (mixed.get_type() != tightdb::type_Table)
        return to_objc_object(mixed);

    tightdb::TableRef table = m_table->get_subtable(colNdx, rowIndex);
    TIGHTDB_ASSERT(table);
    TDBTable* table_2 = [[TDBTable alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table_2))
        return nil;
    [table_2 setNativeTable:table.get()];
    [table_2 setParent:self];
    [table_2 setReadOnly:m_read_only];
    if (![table_2 _checkType])
        return nil;

    return table_2;
}


-(void)TDB_setBool:(BOOL)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
{
    TIGHTDB_EXCEPTION_HANDLER_SETTERS(
        m_table->set_bool(col_ndx, row_ndx, value);,
        TDBBoolType);
}

-(void)TDB_setInt:(int64_t)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
{
    TIGHTDB_EXCEPTION_HANDLER_SETTERS(
        m_table->set_int(col_ndx, row_ndx, value);,
        TDBIntType);
}

-(void)TDB_setFloat:(float)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
{
    TIGHTDB_EXCEPTION_HANDLER_SETTERS(
        m_table->set_float(col_ndx, row_ndx, value);,
        TDBFloatType);
}

-(void)TDB_setDouble:(double)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
{
    TIGHTDB_EXCEPTION_HANDLER_SETTERS(
        m_table->set_double(col_ndx, row_ndx, value);,
        TDBDoubleType);
}

-(void)TDB_setString:(NSString*)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
{
    TIGHTDB_EXCEPTION_HANDLER_SETTERS(
        m_table->set_string(col_ndx, row_ndx, ObjcStringAccessor(value));,
        TDBStringType);
}

-(void)TDB_setBinary:(NSData*)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
{
    TIGHTDB_EXCEPTION_HANDLER_SETTERS(
        m_table->set_binary(col_ndx, row_ndx, ((NSData *)value).tdbBinaryData);,
        TDBBinaryType);
}

-(void)TDB_setDate:(NSDate *)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
{
    TIGHTDB_EXCEPTION_HANDLER_SETTERS(
       m_table->set_datetime(col_ndx, row_ndx, tightdb::DateTime((time_t)[value timeIntervalSince1970]));,
       TDBDateType);
}

-(void)TDB_setTable:(TDBTable*)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
{
    // TODO: Use core method for checking the equality of two table specs. Even in the typed interface
    // the user might add columns (_checkType for typed and spec against spec for dynamic).

    TIGHTDB_EXCEPTION_HANDLER_SETTERS(
        m_table->set_subtable(col_ndx, row_ndx, &[value getNativeTable]);,
        TDBTableType);
}

-(void)TDB_setMixed:(id)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
{
    tightdb::Mixed mixed;
    to_mixed(value, mixed);
    TDBTable* subtable = mixed.get_type() == tightdb::type_Table ? (TDBTable *)value : nil;
    TIGHTDB_EXCEPTION_HANDLER_SETTERS(
        if (subtable) {
            tightdb::LangBindHelper::set_mixed_subtable(*m_table, col_ndx, row_ndx,
                                                        [subtable getNativeTable]);
        }
        else {
            m_table->set_mixed(col_ndx, row_ndx, mixed);
        },
        TDBMixedType);
}


-(BOOL)TDB_insertBool:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(BOOL)value
{
    return [self TDB_insertBool:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)TDB_insertBool:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(BOOL)value error:(NSError* __autoreleasing*)error
{
    // FIXME: Read-only errors should probably be handled by throwing
    // an exception. That is what is done in other places in this
    // binding, and it also seems like the right thing to do. This
    // method should also not take an error argument.
    if (m_read_only) {
        if (error)
            *error = make_tightdb_error(tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(m_table->insert_bool(col_ndx, ndx, value);, NO);
    return YES;
}

-(BOOL)TDB_insertInt:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(int64_t)value
{
    return [self TDB_insertInt:col_ndx ndx:ndx value:value error:nil];
}


-(BOOL)TDB_insertInt:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(int64_t)value error:(NSError* __autoreleasing*)error
{
    // FIXME: Read-only errors should probably be handled by throwing
    // an exception. That is what is done in other places in this
    // binding, and it also seems like the right thing to do. This
    // method should also not take an error argument.
    if (m_read_only) {
        if (error)
            *error = make_tightdb_error(tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(m_table->insert_int(col_ndx, ndx, value);, NO);
    return YES;
}

-(BOOL)TDB_insertFloat:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(float)value
{
    return [self TDB_insertFloat:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)TDB_insertFloat:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(float)value error:(NSError* __autoreleasing*)error
{
    // FIXME: Read-only errors should probably be handled by throwing
    // an exception. That is what is done in other places in this
    // binding, and it also seems like the right thing to do. This
    // method should also not take an error argument.
    if (m_read_only) {
        if (error)
            *error = make_tightdb_error(tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(m_table->insert_float(col_ndx, ndx, value);, NO);
    return YES;
}

-(BOOL)TDB_insertDouble:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(double)value
{
    return [self TDB_insertDouble:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)TDB_insertDouble:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(double)value error:(NSError* __autoreleasing*)error
{
    // FIXME: Read-only errors should probably be handled by throwing
    // an exception. That is what is done in other places in this
    // binding, and it also seems like the right thing to do. This
    // method should also not take an error argument.
    if (m_read_only) {
        if (error)
            *error = make_tightdb_error(tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(m_table->insert_double(col_ndx, ndx, value);, NO);
    return YES;
}

-(BOOL)TDB_insertString:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(NSString*)value
{
    return [self TDB_insertString:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)TDB_insertString:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(NSString*)value error:(NSError* __autoreleasing*)error
{
    // FIXME: Read-only errors should probably be handled by throwing
    // an exception. That is what is done in other places in this
    // binding, and it also seems like the right thing to do. This
    // method should also not take an error argument.
    if (m_read_only) {
        if (error)
            *error = make_tightdb_error(tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
        m_table->insert_string(col_ndx, ndx, ObjcStringAccessor(value));,
        NO);
    return YES;
}

-(BOOL)TDB_insertBinary:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(NSData*)value
{
    return [self TDB_insertBinary:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)TDB_insertBinary:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(NSData*)value error:(NSError* __autoreleasing*)error
{
    // FIXME: Read-only errors should probably be handled by throwing
    // an exception. That is what is done in other places in this
    // binding, and it also seems like the right thing to do. This
    // method should also not take an error argument.
    if (m_read_only) {
        if (error)
            *error = make_tightdb_error(tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    const void *data = [(NSData *)value bytes];
    tightdb::BinaryData bd(static_cast<const char *>(data), [(NSData *)value length]);
    TIGHTDB_EXCEPTION_ERRHANDLER(
        m_table->insert_binary(col_ndx, ndx, bd);,
        NO);
    return YES;
}

-(BOOL)TDB_insertBinary:(NSUInteger)col_ndx ndx:(NSUInteger)ndx data:(const char*)data size:(size_t)size
{
    return [self TDB_insertBinary:col_ndx ndx:ndx data:data size:size error:nil];
}

-(BOOL)TDB_insertBinary:(NSUInteger)col_ndx ndx:(NSUInteger)ndx data:(const char*)data size:(size_t)size error:(NSError* __autoreleasing*)error
{
    // FIXME: Read-only errors should probably be handled by throwing
    // an exception. That is what is done in other places in this
    // binding, and it also seems like the right thing to do. This
    // method should also not take an error argument.
    if (m_read_only) {
        if (error)
            *error = make_tightdb_error(tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
        m_table->insert_binary(col_ndx, ndx, tightdb::BinaryData(data, size));,
        NO);
    return YES;
}

-(BOOL)TDB_insertDate:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(NSDate *)value
{
    return [self TDB_insertDate:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)TDB_insertDate:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(NSDate *)value error:(NSError* __autoreleasing*)error
{
    // FIXME: Read-only errors should probably be handled by throwing
    // an exception. That is what is done in other places in this
    // binding, and it also seems like the right thing to do. This
    // method should also not take an error argument.
    if (m_read_only) {
        if (error)
            *error = make_tightdb_error(tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(m_table->insert_datetime(col_ndx, ndx, [value timeIntervalSince1970]);, NO);
    return YES;
}

-(BOOL)TDB_insertDone
{
    return [self TDB_insertDoneWithError:nil];
}

-(BOOL)TDB_insertDoneWithError:(NSError* __autoreleasing*)error
{
    // FIXME: This method should probably not take an error argument.
    TIGHTDB_EXCEPTION_ERRHANDLER(m_table->insert_done();, NO);
    return YES;
}




-(BOOL)TDB_insertSubtable:(NSUInteger)col_ndx ndx:(NSUInteger)row_ndx
{
    return [self TDB_insertSubtable:col_ndx ndx:row_ndx error:nil];
}

-(BOOL)TDB_insertSubtable:(NSUInteger)col_ndx ndx:(NSUInteger)row_ndx error:(NSError* __autoreleasing*)error
{
    // FIXME: Read-only errors should probably be handled by throwing
    // an exception. That is what is done in other places in this
    // binding, and it also seems like the right thing to do. This
    // method should also not take an error argument.
    if (m_read_only) {
        if (error)
            *error = make_tightdb_error(tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(m_table->insert_subtable(col_ndx, row_ndx);, NO);
    return YES;
}

-(BOOL)TDB_insertSubtableCopy:(NSUInteger)col_ndx row:(NSUInteger)row_ndx subtable:(TDBTable*)subtable
{
    return [self TDB_insertSubtableCopy:col_ndx row:row_ndx subtable:subtable error:nil];
}


-(BOOL)TDB_insertSubtableCopy:(NSUInteger)col_ndx row:(NSUInteger)row_ndx subtable:(TDBTable*)subtable error:(NSError* __autoreleasing*)error
{
    // FIXME: Read-only errors should probably be handled by throwing
    // an exception. That is what is done in other places in this
    // binding, and it also seems like the right thing to do. This
    // method should also not take an error argument.
    if (m_read_only) {
        if (error)
            *error = make_tightdb_error(tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
        tightdb::LangBindHelper::insert_subtable(*m_table, col_ndx, row_ndx, [subtable getNativeTable]);,
        NO);
    return YES;
}




-(TDBType)mixedTypeForColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return TDBType(m_table->get_mixed_type(colIndex, rowIndex));
}

-(BOOL)TDB_insertMixed:(NSUInteger)col_ndx ndx:(NSUInteger)row_ndx value:(id)value
{
    return [self TDB_insertMixed:col_ndx ndx:row_ndx value:value error:nil];
}

-(BOOL)TDB_insertMixed:(NSUInteger)col_ndx ndx:(NSUInteger)row_ndx value:(id)value error:(NSError* __autoreleasing*)error
{
    if (m_read_only) {
        if (error)
            *error = make_tightdb_error(tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    tightdb::Mixed mixed;
    TDBTable* subtable;
    if ([value isKindOfClass:[TDBTable class]]) {
        subtable = (TDBTable *)value;
    }
    else {
        to_mixed(value, mixed);
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
        if (subtable) {
            tightdb::LangBindHelper::insert_mixed_subtable(*m_table, col_ndx, row_ndx,
                                                           [subtable getNativeTable]);
        }
        else {
            m_table->insert_mixed(col_ndx, row_ndx, mixed);
        },
        NO);
    return YES;
}


-(NSUInteger)addColumnWithName:(NSString*)name type:(TDBType)type
{
    return [self addColumnWithType:type andName:name error:nil];
}

-(NSUInteger)addColumnWithType:(TDBType)type andName:(NSString*)name error:(NSError* __autoreleasing*)error
{
    TIGHTDB_EXCEPTION_ERRHANDLER(
        return m_table->add_column(tightdb::DataType(type), ObjcStringAccessor(name));,
        0);
}

-(void)renameColumnWithIndex:(NSUInteger)colIndex to:(NSString *)newName
{
    TIGHTDB_EXCEPTION_HANDLER_COLUMN_INDEX_VALID(colIndex);
    m_table->rename_column(colIndex, ObjcStringAccessor(newName));
}


-(void)removeColumnWithIndex:(NSUInteger)columnIndex
{
    TIGHTDB_EXCEPTION_HANDLER_COLUMN_INDEX_VALID(columnIndex);
    
    try {
        m_table->remove_column(columnIndex);
    }
    catch(std::exception& ex) {
        @throw[NSException exceptionWithName:@"tightdb:core_exception"
                                      reason:[NSString stringWithUTF8String:ex.what()]
                                    userInfo:nil];
    }
}

-(NSUInteger)findRowIndexWithBool:(BOOL)aBool inColumnWithIndex:(NSUInteger)colIndex
{
    return was_not_found(m_table->find_first_bool(colIndex, aBool));
}
-(NSUInteger)findRowIndexWithInt:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex
{
    return was_not_found(m_table->find_first_int(colIndex, anInt));
}
-(NSUInteger)findRowIndexWithFloat:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex
{
    return was_not_found(m_table->find_first_float(colIndex, aFloat));
}
-(NSUInteger)findRowIndexWithDouble:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex
{
    return was_not_found(m_table->find_first_double(colIndex, aDouble));
}
-(NSUInteger)findRowIndexWithString:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex
{
    return was_not_found(m_table->find_first_string(colIndex, ObjcStringAccessor(aString)));
}
-(NSUInteger)findRowIndexWithBinary:(NSData *)aBinary inColumnWithIndex:(NSUInteger)colIndex
{
    const void *data = [(NSData *)aBinary bytes];
    tightdb::BinaryData bd(static_cast<const char *>(data), [(NSData *)aBinary length]);
    return was_not_found(m_table->find_first_binary(colIndex, bd));
}
-(NSUInteger)findRowIndexWithDate:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex
{
    return was_not_found(m_table->find_first_datetime(colIndex, [aDate timeIntervalSince1970]));
}
-(NSUInteger)findRowIndexWithMixed:(id)aMixed inColumnWithIndex:(NSUInteger)colIndex
{
    static_cast<void>(colIndex);
    static_cast<void>(aMixed);
    [NSException raise:@"NotImplemented" format:@"Not implemented"];
    // FIXME: Implement this!
//    return _table->find_first_mixed(col_ndx, [value getNativeMixed]);
    return 0;
}

-(TDBView*)findAllRowsWithBool:(BOOL)aBool inColumnWithIndex:(NSUInteger)colIndex
{
    tightdb::TableView view = m_table->find_all_bool(colIndex, aBool);
    return [TDBView viewWithTable:self andNativeView:view];
}
-(TDBView*)findAllRowsWithInt:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex
{
    tightdb::TableView view = m_table->find_all_int(colIndex, anInt);
    return [TDBView viewWithTable:self andNativeView:view];
}
-(TDBView*)findAllRowsWithFloat:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex
{
    tightdb::TableView view = m_table->find_all_float(colIndex, aFloat);
    return [TDBView viewWithTable:self andNativeView:view];
}
-(TDBView*)findAllRowsWithDouble:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex
{
    tightdb::TableView view = m_table->find_all_double(colIndex, aDouble);
    return [TDBView viewWithTable:self andNativeView:view];
}
-(TDBView*)findAllRowsWithString:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex
{
    tightdb::TableView view = m_table->find_all_string(colIndex, ObjcStringAccessor(aString));
    return [TDBView viewWithTable:self andNativeView:view];
}
-(TDBView*)findAllRowsWithBinary:(NSData *)aBinary inColumnWithIndex:(NSUInteger)colIndex
{
    tightdb::TableView view = m_table->find_all_binary(colIndex, aBinary.tdbBinaryData);
    return [TDBView viewWithTable:self andNativeView:view];
}
-(TDBView*)findAllRowsWithDate:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex
{
    tightdb::TableView view = m_table->find_all_datetime(colIndex, [aDate timeIntervalSince1970]);
    return [TDBView viewWithTable:self andNativeView:view];
}
-(TDBView*)findAllRowsWithMixed:(id)aMixed inColumnWithIndex:(NSUInteger)colIndex
{
    static_cast<void>(colIndex);
    static_cast<void>(aMixed);
    [NSException raise:@"NotImplemented" format:@"Not implemented"];
    // FIXME: Implement this!
//    tightdb::TableView view = m_table->find_all_mixed(col_ndx, [value getNativeMixed]);
//    return [TDBView viewWithTable:self andNativeView:view];
    return 0;
}

-(TDBQuery*)where
{
    return [self whereWithError:nil];
}

-(TDBQuery*)whereWithError:(NSError* __autoreleasing*)error
{
    return [[TDBQuery alloc] initWithTable:self error:error];
}

-(TDBView *)distinctValuesInColumnWithIndex:(NSUInteger)colIndex
{
    if (!([self columnTypeOfColumnWithIndex:colIndex] == TDBStringType)) {
        @throw [NSException exceptionWithName:@"tightdb:column_type_not_supported"
                                       reason:@"Distinct currently only supported on columns of type TDBStringType"
                                     userInfo:nil];
    }
    if (![self isIndexCreatedInColumnWithIndex:colIndex]) {
        @throw [NSException exceptionWithName:@"tightdb:column_not_indexed"
                                       reason:@"An index must be created on the column to get distinct values"
                                     userInfo:nil];
    }
    
    tightdb::TableView distinctView = m_table->get_distinct_view(colIndex);
    return [TDBView viewWithTable:self andNativeView:distinctView];
}

-(BOOL)isIndexCreatedInColumnWithIndex:(NSUInteger)colIndex
{
    return m_table->has_index(colIndex);
}

-(void)createIndexInColumnWithIndex:(NSUInteger)colIndex
{
    m_table->set_index(colIndex);
}

-(BOOL)optimize
{
    return [self optimizeWithError:nil];
}

-(BOOL)optimizeWithError:(NSError* __autoreleasing*)error
{
    TIGHTDB_EXCEPTION_ERRHANDLER(m_table->optimize();, NO);
    return YES;
}

-(NSUInteger)countRowsWithInt:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex
{
    return m_table->count_int(colIndex, anInt);
}
-(NSUInteger)countRowsWithFloat:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex
{
    return m_table->count_float(colIndex, aFloat);
}
-(NSUInteger)countRowsWithDouble:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex
{
    return m_table->count_double(colIndex, aDouble);
}
-(NSUInteger)countRowsWithString:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex
{
    return m_table->count_string(colIndex, ObjcStringAccessor(aString));
}

-(int64_t)sumIntColumnWithIndex:(NSUInteger)colIndex
{
    return m_table->sum_int(colIndex);
}
-(double)sumFloatColumnWithIndex:(NSUInteger)colIndex
{
    return m_table->sum_float(colIndex);
}
-(double)sumDoubleColumnWithIndex:(NSUInteger)colIndex
{
    return m_table->sum_double(colIndex);
}

-(int64_t)maxIntInColumnWithIndex:(NSUInteger)colIndex
{
    return m_table->maximum_int(colIndex);
}
-(float)maxFloatInColumnWithIndex:(NSUInteger)colIndex
{
    return m_table->maximum_float(colIndex);
}
-(double)maxDoubleInColumnWithIndex:(NSUInteger)colIndex
{
    return m_table->maximum_double(colIndex);
}

-(int64_t)minIntInColumnWithIndex:(NSUInteger)colIndex
{
    return m_table->minimum_int(colIndex);
}
-(float)minFloatInColumnWithIndex:(NSUInteger)colIndex
{
    return m_table->minimum_float(colIndex);
}
-(double)minDoubleInColumnWithIndex:(NSUInteger)colIndex
{
    return m_table->minimum_double(colIndex);
}

-(double)avgIntColumnWithIndex:(NSUInteger)colIndex
{
    return m_table->average_int(colIndex);
}
-(double)avgFloatColumnWithIndex:(NSUInteger)colIndex
{
    return m_table->average_float(colIndex);
}
-(double)avgDoubleColumnWithIndex:(NSUInteger)colIndex
{
    return m_table->average_double(colIndex);
}

-(BOOL)_addColumns
{
    return YES; // Must be overridden in typed table classes.
}

@end


