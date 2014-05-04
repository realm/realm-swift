////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>

#include <tightdb/lang_bind_helper.hpp>

#import "RLMView_noinst.h"
#import "RLMQuery_noinst.h"
#import "RLMDescriptor_noinst.h"
#import "RLMProxy.h"
#import "RLMObjectDescriptor.h"
#import "NSData+RLMGetBinaryData.h"
#import "RLMRealm_noinst.h"
#import "RLMPrivate.h"
#import "RLMPrivate.hpp"
#import "util_noinst.hpp"
#import "query_util.h"

@implementation RLMTable
{
    tightdb::TableRef m_table;
    id m_parent;
    BOOL m_read_only;
    RLMRow * m_tmp_row;
}

@dynamic baseTable;

-(instancetype)initWithObjectClass:(Class)objectClass
{
    self = [super init];
    if (self) {
        m_read_only = NO;
        m_table = tightdb::Table::create(); // FIXME: May throw
        [self setObjectClass:objectClass];
    }
    return self;
}


-(instancetype)init
{
    self = [super init];
    if (self) {
        m_read_only = NO;
        m_table = tightdb::Table::create(); // FIXME: May throw
        _objectClass = RLMRow.class;
        _proxyObjectClass = RLMRow.class;
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
    _objectClass = RLMRow.class;
    _proxyObjectClass = RLMRow.class;
    
    if (!set_columns(m_table, columns)) {
        m_table.reset();

        // Parsing the schema failed
        //TODO: More detailed error msg in exception
        @throw [NSException exceptionWithName:@"realm:invalid_columns"
                                                         reason:@"The supplied list of columns was invalid"
                                                       userInfo:nil];
    }

    return self;
}

-(id)_initRaw
{
    self = [super init];
    _objectClass = RLMRow.class;
    _proxyObjectClass = RLMRow.class;
    return self;
}


-(void)setObjectClass:(Class)objectClass {
    _objectClass = objectClass;
    _proxyObjectClass = [RLMProxy proxyClassForObjectClass:objectClass];
    RLMObjectDescriptor * descriptor = [RLMObjectDescriptor descriptorForObjectClass:objectClass];
    [RLMTable updateDescriptor:self.descriptor toSupportObjectDescriptor:descriptor];
}

-(BOOL)_checkType
{
    return YES;
    // Dummy - must be overridden in tightdb.h - Check if spec matches the macro definitions
}

-(RLMRow *)getRow
{
    return m_tmp_row = [[_proxyObjectClass alloc] initWithTable:self ndx:0];
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
        RLMRow * tmp = [self getRow];
        *stackbuf = tmp;
    }
    if (state->state < self.rowCount) {
        [((RLMRow *) *stackbuf) RLM_setNdx:state->state];
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

-(void)setBaseTable:(tightdb::Table *)baseTable {
    [self setNativeTable:baseTable];
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
    if ([other isKindOfClass:[RLMTable class]])
        return *m_table == *(((RLMTable *)other)->m_table);
    return NO;
}

//
// This method will return NO if it encounters a memory allocation
// error (out of memory).
//
// The specified table class must be one that is declared by using
// one of the table macros REALM_TABLE_*.
//
// FIXME: Check that the specified class derives from RLMTable.
-(BOOL)hasSameDescriptorAs:(__unsafe_unretained Class)tableClass
{
    RLMTable * table = [[tableClass alloc] _initRaw];
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
// one of the table macros REALM_TABLE_*.
//
// FIXME: Check that the specified class derives from RLMTable.
-(id)castToTypedTableClass:(__unsafe_unretained Class)typedTableClass
{
    RLMTable * table = [[typedTableClass alloc] _initRaw];
    if (TIGHTDB_LIKELY(table)) {
        [table setNativeTable:m_table.get()];
        [table setParent:m_parent];
        [table setReadOnly:m_read_only];
        if (![table _checkType])
            return nil;
    }
    return table;
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

-(RLMType)columnTypeOfColumnWithIndex:(NSUInteger)ndx
{
    return RLMType(m_table->get_column_type(ndx));
}

-(RLMDescriptor*)descriptor
{
    return [self descriptorWithError:nil];
}

-(RLMDescriptor*)descriptorWithError:(NSError* __autoreleasing*)error
{
    tightdb::DescriptorRef desc = m_table->get_descriptor();
    BOOL read_only = m_read_only || m_table->has_shared_type();
    return [RLMDescriptor descWithDesc:desc.get() readOnly:read_only error:error];
}

-(NSUInteger)rowCount // Implementing property accessor
{
    return m_table->size();
}

-(RLMRow *)insertEmptyRowAtIndex:(NSUInteger)ndx
{
    [self RLMInsertRow:ndx];
    return [[_proxyObjectClass alloc] initWithTable:self ndx:ndx];
}

-(BOOL)RLMInsertRow:(NSUInteger)ndx
{
    return [self RLMInsertRow:ndx error:nil];
}

-(BOOL)RLMInsertRow:(NSUInteger)ndx error:(NSError* __autoreleasing*)error
{
    if (m_read_only) {
        if (error)
            *error = make_realm_error(RLMErrorFailRdOnly, @"Tried to insert row while read-only.");
        return NO;
    }
    
    REALM_EXCEPTION_ERRHANDLER(m_table->insert_empty_row(ndx);, 0);
    return YES;
}


-(NSUInteger)RLM_addEmptyRow
{
    return [self RLM_addEmptyRows:1];
}

-(NSUInteger)RLM_addEmptyRows:(NSUInteger)num_rows
{
    // TODO: Use a macro or a function for error handling

    if(m_read_only) {
        @throw [NSException exceptionWithName:@"realm:table_is_read_only"
                                       reason:@"You tried to modify a table in read only mode"
                                     userInfo:nil];
    }

    NSUInteger index;
    try {
        index = m_table->add_empty_row(num_rows);
    }
    catch(std::exception& ex) {
        @throw [NSException exceptionWithName:@"realm:core_exception"
                                       reason:[NSString stringWithUTF8String:ex.what()]
                                     userInfo:nil];
    }

    return index;
}

-(RLMRow *)objectAtIndexedSubscript:(NSUInteger)rowIndex
{
    if (rowIndex >= self.rowCount) {
        @throw [NSException exceptionWithName:@"realm:index_out_of_bounds"
                                       reason:[NSString stringWithFormat:@"Index %lu beyond bounds [0 .. %lu]", (unsigned long)rowIndex, (unsigned long)self.rowCount-1]
                                     userInfo:nil];
    }
    
    return [[_proxyObjectClass alloc] initWithTable:self ndx:rowIndex];
}

-(void)setObject:(id)newValue atIndexedSubscript:(NSUInteger)rowIndex
{
    [self updateRow:newValue atIndex:rowIndex]; //Exceptions handled here. This should also call setRow:atIndex: when util.mm methods refactored.
}

-(RLMRow *)objectForKeyedSubscript:(NSString *)key
{
    // Currently only supporting first column lookup for RLMTypeString. Will add support for different
    // columns when we have Mantle-like syntax
    if ([self columnCount] < 1) {
        @throw [NSException exceptionWithName:@"realm:column_not_defined"
                                       reason:@"This table has no columns"
                                     userInfo:nil];
    }
    else if ([self columnTypeOfColumnWithIndex:0] != RLMTypeString) {
        @throw [NSException exceptionWithName:@"realm:column_not_type_string"
                                       reason:@"Column at index 0 must be of RLMTypeString"
                                     userInfo:nil];
    }
    
    size_t ndx = [self RLM_lookup:key];
    
    return ndx != (NSUInteger)NSNotFound ? [self rowAtIndex:ndx] : nil;
}

-(void)setObject:(id)newValue forKeyedSubscript:(NSString *)key
{
    RLMRow* row = self[key]; // Exceptions handled here
    
    if (row) {
        [self updateRow:newValue atIndex:[row RLM_index]]; // This should call setRow:atIndex: when util.mm methods refactored
    }
//    else { // Commenting this out. Currently only support keyed subscripts for updating. Uncomment this when util.mm implements set and update methods.
//        [self addRow:newValue];
//    }
}

- (size_t)RLM_lookup:(NSString *)key
{
    return m_table->lookup([key UTF8String]);
}

-(id)rowAtIndex:(NSUInteger)ndx
{
    // initWithTable checks for illegal index.

    return [[_proxyObjectClass alloc] initWithTable:self ndx:ndx];
}

-(id)firstRow
{
    if (self.rowCount == 0) {
        return nil;
    }
    return [[_proxyObjectClass alloc] initWithTable:self ndx:0];
}

-(id)lastRow
{
    if (self.rowCount == 0) {
        return nil;
    }
    return [[_proxyObjectClass alloc] initWithTable:self ndx:self.rowCount-1];
}

-(id)insertRowAtIndex:(NSUInteger)ndx
{
    [self insertEmptyRowAtIndex:ndx];
    return [[_proxyObjectClass alloc] initWithTable:self ndx:ndx];
}

-(void)addRow:(NSObject*)data
{
    if(m_read_only) {
        @throw [NSException exceptionWithName:@"realm:table_is_read_only"
                                       reason:@"You tried to modify a table in read only mode"
                                     userInfo:[NSMutableDictionary dictionary]];
    }
    
    if (!data) {
        [self RLM_addEmptyRow];
        return;
    }
    tightdb::Table& table = *m_table;
    [self insertRow:data atIndex:table.size()];
}

/* Moved to private header */
-(RLMRow *)addEmptyRow
{
    return [[_proxyObjectClass alloc] initWithTable:self ndx:[self RLM_addEmptyRow]];
}


-(void)insertRow:(NSObject *)anObject atIndex:(NSUInteger)rowIndex
{
    if (!anObject) {
        [self RLMInsertRow:rowIndex];
        return;
    }
    
    tightdb::Table& table = *m_table;
    tightdb::ConstDescriptorRef desc = table.get_descriptor();
    
    if ([anObject isKindOfClass:[NSArray class]]) {
        verify_row(*desc, (NSArray *)anObject);
        insert_row(size_t(rowIndex), table, (NSArray *)anObject);
        return;
    }
    
    if ([anObject isKindOfClass:[NSDictionary class]]) {
        verify_row_with_labels(*desc, (NSDictionary *)anObject);
        insert_row_with_labels(size_t(rowIndex), table, (NSDictionary *)anObject);
        return;
    }
    
    if ([anObject isKindOfClass:[NSObject class]]) {
        verify_row_from_object(*desc, (NSObject *)anObject);
        insert_row_from_object(size_t(rowIndex), table, (NSObject *)anObject);
        return;
    }

    @throw [NSException exceptionWithName:@"realm:column_not_implemented"
                                   reason:@"You should either use nil, NSObject, NSDictionary, or NSArray"
                                 userInfo:nil];
}

- (void)updateRow:(NSObject *)anObject atIndex:(NSUInteger)rowIndex
{
    if (rowIndex >= self.rowCount) {
        @throw [NSException exceptionWithName:@"realm:index_out_of_bounds"
                                       reason:[NSString stringWithFormat:@"Index %lu beyond bounds [0 .. %lu]", (unsigned long)rowIndex, (unsigned long)self.rowCount-1]
                                     userInfo:nil];
    }
    
    if (!anObject) {
        return;
    }
    
    tightdb::Table& table = *m_table;
    tightdb::ConstDescriptorRef desc = table.get_descriptor();
    
    // These should call update_row. Will re-implement set_row() when setRow:atIndex is implemented.
    if ([anObject isKindOfClass:[NSArray class]]) {
        verify_row(*desc, (NSArray *)anObject);
        set_row(size_t(rowIndex), table, (NSArray*)anObject);
        return;
    }
    
    if ([anObject isKindOfClass:[NSDictionary class]]) {
        verify_row_with_labels(*desc, (NSDictionary *)anObject);
        set_row_with_labels(size_t(rowIndex), table, (NSDictionary*)anObject);
        return;
    }
    
    if ([anObject isKindOfClass:[NSObject class]]) {
        verify_row_from_object(*desc, (NSObject *)anObject);
        set_row_from_object(size_t(rowIndex), table, (NSObject *)anObject);
        return;
    }
    
    @throw [NSException exceptionWithName:@"realm:column_not_implemented"
                                   reason:@"You should either use nil, NSObject, NSDictionary, or NSArray"
                                 userInfo:nil];
}


-(void)removeAllRows
{
    if (m_read_only) {
        @throw [NSException exceptionWithName:@"realm:table_is_read_only"
                                       reason:@"You tried to modify an immutable table."
                                     userInfo:nil];
    }
    
    m_table->clear();
}

-(void)removeRowAtIndex:(NSUInteger)ndx
{
    if (m_read_only) {
        @throw [NSException exceptionWithName:@"realm:table_is_read_only"
                                       reason:@"You tried to modify an immutable table."
                                     userInfo:nil];
    }
    m_table->remove(ndx);
}

-(void)removeLastRow
{
    if (m_read_only) {
        @throw [NSException exceptionWithName:@"realm:table_is_read_only"
                                       reason:@"You tried to modify an immutable table."
                                     userInfo:nil];
    }
    m_table->remove_last();
}


-(BOOL)RLM_boolInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return m_table->get_bool(colIndex, rowIndex);
}

-(int64_t)RLM_intInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return m_table->get_int(colIndex, rowIndex);
}

-(float)RLM_floatInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return m_table->get_float(colIndex, rowIndex);
}

-(double)RLM_doubleInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return m_table->get_double(colIndex, rowIndex);
}

-(NSString*)RLM_stringInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return to_objc_string(m_table->get_string(colIndex, rowIndex));
}

-(NSData*)RLM_binaryInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    tightdb::BinaryData bd = m_table->get_binary(colIndex, rowIndex);
    return [[NSData alloc] initWithBytes:static_cast<const void *>(bd.data()) length:bd.size()];
}

-(NSDate *)RLM_dateInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return [NSDate dateWithTimeIntervalSince1970: m_table->get_datetime(colIndex, rowIndex).get_datetime()];
}

-(RLMTable *)RLM_tableInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    tightdb::DataType type = m_table->get_column_type(colIndex);
    if (type != tightdb::type_Table)
        return nil;
    tightdb::TableRef table = m_table->get_subtable(colIndex, rowIndex);
    if (!table)
        return nil;
    RLMTable * tableObj = [[RLMTable alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!tableObj))
        return nil;
    [tableObj setNativeTable:table.get()];
    [tableObj setParent:self];
    [tableObj setReadOnly:m_read_only];
    return tableObj;
}

// FIXME: Check that the specified class derives from RLMTable.
-(id)RLM_tableInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex asTableClass:(Class)tableClass
{
    tightdb::DataType type = m_table->get_column_type(colIndex);
    if (type != tightdb::type_Table)
        return nil;
    tightdb::TableRef table = m_table->get_subtable(colIndex, rowIndex);
    TIGHTDB_ASSERT(table);
    RLMTable * tableObj = [[tableClass alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!tableObj))
        return nil;
    [tableObj setNativeTable:table.get()];
    [tableObj setParent:self];
    [tableObj setReadOnly:m_read_only];
    if (![tableObj _checkType])
        return nil;
    return tableObj;
}

-(id)RLM_mixedInColumnWithIndex:(NSUInteger)colNdx atRowIndex:(NSUInteger)rowIndex
{
    tightdb::Mixed mixed = m_table->get_mixed(colNdx, rowIndex);
    if (mixed.get_type() != tightdb::type_Table)
        return to_objc_object(mixed);

    tightdb::TableRef table = m_table->get_subtable(colNdx, rowIndex);
    TIGHTDB_ASSERT(table);
    RLMTable * tableObj = [[RLMTable alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!tableObj))
        return nil;
    [tableObj setNativeTable:table.get()];
    [tableObj setParent:self];
    [tableObj setReadOnly:m_read_only];
    if (![tableObj _checkType])
        return nil;

    return tableObj;
}


-(void)RLM_setBool:(BOOL)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
{
    REALM_EXCEPTION_HANDLER_SETTERS(
        m_table->set_bool(col_ndx, row_ndx, value);,
    RLMTypeBool);
}

-(void)RLM_setInt:(int64_t)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
{
    REALM_EXCEPTION_HANDLER_SETTERS(
        m_table->set_int(col_ndx, row_ndx, value);,
        RLMTypeInt);
}

-(void)RLM_setFloat:(float)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
{
    REALM_EXCEPTION_HANDLER_SETTERS(
        m_table->set_float(col_ndx, row_ndx, value);,
        RLMTypeFloat);
}

-(void)RLM_setDouble:(double)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
{
    REALM_EXCEPTION_HANDLER_SETTERS(
        m_table->set_double(col_ndx, row_ndx, value);,
        RLMTypeDouble);
}

-(void)RLM_setString:(NSString *)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
{
    REALM_EXCEPTION_HANDLER_SETTERS(
        m_table->set_string(col_ndx, row_ndx, ObjcStringAccessor(value));,
        RLMTypeString);
}

-(void)RLM_setBinary:(NSData *)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
{
    REALM_EXCEPTION_HANDLER_SETTERS(
        m_table->set_binary(col_ndx, row_ndx, ((NSData *)value).rlmBinaryData);,
        RLMTypeBinary);
}

-(void)RLM_setDate:(NSDate *)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
{
    REALM_EXCEPTION_HANDLER_SETTERS(
       m_table->set_datetime(col_ndx, row_ndx, tightdb::DateTime((time_t)[value timeIntervalSince1970]));,
       RLMTypeDate);
}

-(void)RLM_setTable:(RLMTable *)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
{
    // TODO: Use core method for checking the equality of two table specs. Even in the typed interface
    // the user might add columns (_checkType for typed and spec against spec for dynamic).

    REALM_EXCEPTION_HANDLER_SETTERS(
        m_table->set_subtable(col_ndx, row_ndx, &[value getNativeTable]);,
        RLMTypeTable);
}

-(void)RLM_setMixed:(id)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
{
    tightdb::Mixed mixed;
    to_mixed(value, mixed);
    RLMTable * subtable = mixed.get_type() == tightdb::type_Table ? (RLMTable *)value : nil;
    REALM_EXCEPTION_HANDLER_SETTERS(
        if (subtable) {
            tightdb::LangBindHelper::set_mixed_subtable(*m_table, col_ndx, row_ndx,
                                                        [subtable getNativeTable]);
        }
        else {
            m_table->set_mixed(col_ndx, row_ndx, mixed);
        },
        RLMTypeMixed);
}


-(BOOL)RLM_insertBool:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(BOOL)value
{
    return [self RLM_insertBool:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)RLM_insertBool:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(BOOL)value error:(NSError* __autoreleasing*)error
{
    // FIXME: Read-only errors should probably be handled by throwing
    // an exception. That is what is done in other places in this
    // binding, and it also seems like the right thing to do. This
    // method should also not take an error argument.
    if (m_read_only) {
        if (error)
            *error = make_realm_error(RLMErrorFailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    REALM_EXCEPTION_ERRHANDLER(m_table->insert_bool(col_ndx, ndx, value);, NO);
    return YES;
}

-(BOOL)RLM_insertInt:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(int64_t)value
{
    return [self RLM_insertInt:col_ndx ndx:ndx value:value error:nil];
}


-(BOOL)RLM_insertInt:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(int64_t)value error:(NSError* __autoreleasing*)error
{
    // FIXME: Read-only errors should probably be handled by throwing
    // an exception. That is what is done in other places in this
    // binding, and it also seems like the right thing to do. This
    // method should also not take an error argument.
    if (m_read_only) {
        if (error)
            *error = make_realm_error(RLMErrorFailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    REALM_EXCEPTION_ERRHANDLER(m_table->insert_int(col_ndx, ndx, value);, NO);
    return YES;
}

-(BOOL)RLM_insertFloat:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(float)value
{
    return [self RLM_insertFloat:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)RLM_insertFloat:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(float)value error:(NSError* __autoreleasing*)error
{
    // FIXME: Read-only errors should probably be handled by throwing
    // an exception. That is what is done in other places in this
    // binding, and it also seems like the right thing to do. This
    // method should also not take an error argument.
    if (m_read_only) {
        if (error)
            *error = make_realm_error(RLMErrorFailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    REALM_EXCEPTION_ERRHANDLER(m_table->insert_float(col_ndx, ndx, value);, NO);
    return YES;
}

-(BOOL)RLM_insertDouble:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(double)value
{
    return [self RLM_insertDouble:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)RLM_insertDouble:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(double)value error:(NSError* __autoreleasing*)error
{
    // FIXME: Read-only errors should probably be handled by throwing
    // an exception. That is what is done in other places in this
    // binding, and it also seems like the right thing to do. This
    // method should also not take an error argument.
    if (m_read_only) {
        if (error)
            *error = make_realm_error(RLMErrorFailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    REALM_EXCEPTION_ERRHANDLER(m_table->insert_double(col_ndx, ndx, value);, NO);
    return YES;
}

-(BOOL)RLM_insertString:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(NSString*)value
{
    return [self RLM_insertString:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)RLM_insertString:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(NSString*)value error:(NSError* __autoreleasing*)error
{
    // FIXME: Read-only errors should probably be handled by throwing
    // an exception. That is what is done in other places in this
    // binding, and it also seems like the right thing to do. This
    // method should also not take an error argument.
    if (m_read_only) {
        if (error)
            *error = make_realm_error(RLMErrorFailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    REALM_EXCEPTION_ERRHANDLER(
        m_table->insert_string(col_ndx, ndx, ObjcStringAccessor(value));,
        NO);
    return YES;
}

-(BOOL)RLM_insertBinary:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(NSData*)value
{
    return [self RLM_insertBinary:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)RLM_insertBinary:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(NSData*)value error:(NSError* __autoreleasing*)error
{
    // FIXME: Read-only errors should probably be handled by throwing
    // an exception. That is what is done in other places in this
    // binding, and it also seems like the right thing to do. This
    // method should also not take an error argument.
    if (m_read_only) {
        if (error)
            *error = make_realm_error(RLMErrorFailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    const void *data = [(NSData *)value bytes];
    tightdb::BinaryData bd(static_cast<const char *>(data), [(NSData *)value length]);
    REALM_EXCEPTION_ERRHANDLER(
        m_table->insert_binary(col_ndx, ndx, bd);,
        NO);
    return YES;
}

-(BOOL)RLM_insertBinary:(NSUInteger)col_ndx ndx:(NSUInteger)ndx data:(const char *)data size:(size_t)size
{
    return [self RLM_insertBinary:col_ndx ndx:ndx data:data size:size error:nil];
}

-(BOOL)RLM_insertBinary:(NSUInteger)col_ndx ndx:(NSUInteger)ndx data:(const char*)data size:(size_t)size error:(NSError* __autoreleasing*)error
{
    // FIXME: Read-only errors should probably be handled by throwing
    // an exception. That is what is done in other places in this
    // binding, and it also seems like the right thing to do. This
    // method should also not take an error argument.
    if (m_read_only) {
        if (error)
            *error = make_realm_error(RLMErrorFailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    REALM_EXCEPTION_ERRHANDLER(
        m_table->insert_binary(col_ndx, ndx, tightdb::BinaryData(data, size));,
        NO);
    return YES;
}

-(BOOL)RLM_insertDate:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(NSDate *)value
{
    return [self RLM_insertDate:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)RLM_insertDate:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(NSDate *)value error:(NSError* __autoreleasing*)error
{
    // FIXME: Read-only errors should probably be handled by throwing
    // an exception. That is what is done in other places in this
    // binding, and it also seems like the right thing to do. This
    // method should also not take an error argument.
    if (m_read_only) {
        if (error)
            *error = make_realm_error(RLMErrorFailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    REALM_EXCEPTION_ERRHANDLER(m_table->insert_datetime(col_ndx, ndx, [value timeIntervalSince1970]);, NO);
    return YES;
}

-(BOOL)RLM_insertDone
{
    return [self RLM_insertDoneWithError:nil];
}

-(BOOL)RLM_insertDoneWithError:(NSError* __autoreleasing*)error
{
    // FIXME: This method should probably not take an error argument.
    REALM_EXCEPTION_ERRHANDLER(m_table->insert_done();, NO);
    return YES;
}




-(BOOL)RLM_insertSubtable:(NSUInteger)col_ndx ndx:(NSUInteger)row_ndx
{
    return [self RLM_insertSubtable:col_ndx ndx:row_ndx error:nil];
}

-(BOOL)RLM_insertSubtable:(NSUInteger)col_ndx ndx:(NSUInteger)row_ndx error:(NSError* __autoreleasing*)error
{
    // FIXME: Read-only errors should probably be handled by throwing
    // an exception. That is what is done in other places in this
    // binding, and it also seems like the right thing to do. This
    // method should also not take an error argument.
    if (m_read_only) {
        if (error)
            *error = make_realm_error(RLMErrorFailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    REALM_EXCEPTION_ERRHANDLER(m_table->insert_subtable(col_ndx, row_ndx);, NO);
    return YES;
}

-(BOOL)RLM_insertSubtableCopy:(NSUInteger)col_ndx row:(NSUInteger)row_ndx subtable:(RLMTable *)subtable
{
    return [self RLM_insertSubtableCopy:col_ndx row:row_ndx subtable:subtable error:nil];
}


-(BOOL)RLM_insertSubtableCopy:(NSUInteger)col_ndx row:(NSUInteger)row_ndx subtable:(RLMTable *)subtable error:(NSError* __autoreleasing*)error
{
    // FIXME: Read-only errors should probably be handled by throwing
    // an exception. That is what is done in other places in this
    // binding, and it also seems like the right thing to do. This
    // method should also not take an error argument.
    if (m_read_only) {
        if (error)
            *error = make_realm_error(RLMErrorFailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    REALM_EXCEPTION_ERRHANDLER(
        tightdb::LangBindHelper::insert_subtable(*m_table, col_ndx, row_ndx, [subtable getNativeTable]);,
        NO);
    return YES;
}




-(RLMType)mixedTypeForColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return RLMType(m_table->get_mixed_type(colIndex, rowIndex));
}

-(BOOL)RLM_insertMixed:(NSUInteger)col_ndx ndx:(NSUInteger)row_ndx value:(id)value
{
    return [self RLM_insertMixed:col_ndx ndx:row_ndx value:value error:nil];
}

-(BOOL)RLM_insertMixed:(NSUInteger)col_ndx ndx:(NSUInteger)row_ndx value:(id)value error:(NSError* __autoreleasing*)error
{
    if (m_read_only) {
        if (error)
            *error = make_realm_error(RLMErrorFailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    tightdb::Mixed mixed;
    RLMTable * subtable;
    if ([value isKindOfClass:[RLMTable class]]) {
        subtable = (RLMTable *)value;
    }
    else {
        to_mixed(value, mixed);
    }
    REALM_EXCEPTION_ERRHANDLER(
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


-(NSUInteger)addColumnWithName:(NSString*)name type:(RLMType)type
{
    return [self addColumnWithType:type andName:name error:nil];
}

-(NSUInteger)addColumnWithType:(RLMType)type andName:(NSString*)name error:(NSError* __autoreleasing*)error
{
    REALM_EXCEPTION_ERRHANDLER(
        return m_table->add_column(tightdb::DataType(type), ObjcStringAccessor(name));,
        0);
}

-(void)renameColumnWithIndex:(NSUInteger)colIndex to:(NSString *)newName
{
    REALM_EXCEPTION_HANDLER_COLUMN_INDEX_VALID(colIndex);
    m_table->rename_column(colIndex, ObjcStringAccessor(newName));
}


-(void)removeColumnWithIndex:(NSUInteger)columnIndex
{
    REALM_EXCEPTION_HANDLER_COLUMN_INDEX_VALID(columnIndex);
    
    try {
        m_table->remove_column(columnIndex);
    }
    catch(std::exception& ex) {
        @throw[NSException exceptionWithName:@"realm:core_exception"
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

-(RLMView*)findAllRowsWithBool:(BOOL)aBool inColumnWithIndex:(NSUInteger)colIndex
{
    tightdb::TableView view = m_table->find_all_bool(colIndex, aBool);
    return [RLMView viewWithTable:self nativeView:view];
}
-(RLMView*)findAllRowsWithInt:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex
{
    tightdb::TableView view = m_table->find_all_int(colIndex, anInt);
    return [RLMView viewWithTable:self nativeView:view];
}
-(RLMView*)findAllRowsWithFloat:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex
{
    tightdb::TableView view = m_table->find_all_float(colIndex, aFloat);
    return [RLMView viewWithTable:self nativeView:view];
}
-(RLMView*)findAllRowsWithDouble:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex
{
    tightdb::TableView view = m_table->find_all_double(colIndex, aDouble);
    return [RLMView viewWithTable:self nativeView:view];
}
-(RLMView*)findAllRowsWithString:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex
{
    tightdb::TableView view = m_table->find_all_string(colIndex, ObjcStringAccessor(aString));
    return [RLMView viewWithTable:self nativeView:view];
}
-(RLMView*)findAllRowsWithBinary:(NSData *)aBinary inColumnWithIndex:(NSUInteger)colIndex
{
    tightdb::TableView view = m_table->find_all_binary(colIndex, aBinary.rlmBinaryData);
    return [RLMView viewWithTable:self nativeView:view];
}
-(RLMView*)findAllRowsWithDate:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex
{
    tightdb::TableView view = m_table->find_all_datetime(colIndex, [aDate timeIntervalSince1970]);
    return [RLMView viewWithTable:self nativeView:view];
}
-(RLMView*)findAllRowsWithMixed:(id)aMixed inColumnWithIndex:(NSUInteger)colIndex
{
    static_cast<void>(colIndex);
    static_cast<void>(aMixed);
    [NSException raise:@"NotImplemented" format:@"Not implemented"];
    // FIXME: Implement this!
//    tightdb::TableView view = m_table->find_all_mixed(col_ndx, [value getNativeMixed]);
//    return [RLMView viewWithTable:self nativeView:view];
    return 0;
}

-(RLMQuery*)where
{
    return [self whereWithError:nil];
}

-(RLMQuery*)whereWithError:(NSError* __autoreleasing*)error
{
    return [[RLMQuery alloc] initWithTable:self error:error];
}

-(RLMView *)distinctValuesInColumnWithIndex:(NSUInteger)colIndex
{
    if (!([self columnTypeOfColumnWithIndex:colIndex] == RLMTypeString)) {
        @throw [NSException exceptionWithName:@"realm:column_type_not_supported"
                                       reason:@"Distinct currently only supported on columns of type RLMTypeString"
                                     userInfo:nil];
    }
    if (![self isIndexCreatedInColumnWithIndex:colIndex]) {
        @throw [NSException exceptionWithName:@"realm:column_not_indexed"
                                       reason:@"An index must be created on the column to get distinct values"
                                     userInfo:nil];
    }
    
    tightdb::TableView distinctView = m_table->get_distinct_view(colIndex);
    return [RLMView viewWithTable:self nativeView:distinctView];
}

-(id)firstWhere:(id)predicate
{
    tightdb::Query query = queryFromPredicate(self, predicate);

    size_t row_ndx = query.find();
    
    if (row_ndx == tightdb::not_found)
        return nil;
    
    return [[_proxyObjectClass alloc] initWithTable:self ndx:row_ndx];
}

-(RLMView *)allWhere:(id)predicate
{
    tightdb::Query query = queryFromPredicate(self, predicate);

    // create view
    tightdb::TableView view = query.find_all();
    
    // create objc view and return
    return [RLMView viewWithTable:self nativeView:view objectClass:_proxyObjectClass];
}

-(RLMView *)allWhere:(id)predicate orderBy:(id)order
{
    tightdb::Query query = queryFromPredicate(self, predicate);

    // create view
    tightdb::TableView view = query.find_all();
    
    // apply order
    if (order) {
        NSString *columnName;
        BOOL ascending = YES;
        
        if ([order isKindOfClass:[NSString class]]) {
            columnName = order;
        }
        else if ([order isKindOfClass:[NSSortDescriptor class]]) {
            columnName = ((NSSortDescriptor*)order).key;
            ascending = ((NSSortDescriptor*)order).ascending;
        }
        else {
            @throw predicate_exception(@"Invalid order type",
                                       @"Order must be column name or NSSortDescriptor");
        }
        
        NSUInteger index = validated_column_index(self, columnName);
        RLMType columnType = [self columnTypeOfColumnWithIndex:index];
        
        if (columnType != RLMTypeInt && columnType != RLMTypeBool && columnType != RLMTypeDate) {
            @throw predicate_exception(@"Invalid sort column type",
                                       @"Sort only supported on Integer, Date and Boolean columns.");
        }
        
        view.sort(index, ascending);
    }
    
    // create objc view and return
    return [RLMView viewWithTable:self nativeView:view objectClass:_proxyObjectClass];
}

-(NSUInteger)countWhere:(id)predicate
{
    tightdb::Query query = queryFromPredicate(self, predicate);
    
    size_t count = query.count();
    
    return count;
}

-(NSNumber *)sumOfColumn:(NSString *)columnName where:(id)predicate
{
    tightdb::Query query = queryFromPredicate(self, predicate);
    
    NSUInteger index = [self indexOfColumnWithName:columnName];
    
    if (index == NSNotFound) {
        @throw [NSException exceptionWithName:@"realm:invalid_column_name"
                                       reason:[NSString stringWithFormat:@"Column with name %@ not found on table", columnName]
                                     userInfo:nil];
    }
    
    NSNumber *sum;
    RLMType columnType = [self columnTypeOfColumnWithIndex:index];
    if (columnType == RLMTypeInt) {
        sum = [NSNumber numberWithInteger:query.sum_int(index)];
    }
    else if (columnType == RLMTypeDouble) {
        sum = [NSNumber numberWithDouble:query.sum_double(index)];
    }
    else if (columnType == RLMTypeFloat) {
        sum = [NSNumber numberWithDouble:query.sum_float(index)];
    }
    else {
        @throw [NSException exceptionWithName:@"realm:operation_not_supprted"
                                       reason:@"Sum only supported on int, float and double columns."
                                     userInfo:nil];
    }
    
    return sum;
}

-(NSNumber *)averageOfColumn:(NSString *)columnName where:(id)predicate
{
    tightdb::Query query = queryFromPredicate(self, predicate);
    
    NSUInteger index = [self indexOfColumnWithName:columnName];
    
    if (index == NSNotFound) {
        @throw [NSException exceptionWithName:@"realm:invalid_column_name"
                                       reason:[NSString stringWithFormat:@"Column with name %@ not found on table", columnName]
                                     userInfo:nil];
    }
    
    NSNumber *average;
    RLMType columnType = [self columnTypeOfColumnWithIndex:index];
    if (columnType == RLMTypeInt) {
        average = [NSNumber numberWithDouble:query.average_int(index)];
    }
    else if (columnType == RLMTypeDouble) {
        average = [NSNumber numberWithDouble:query.average_double(index)];
    }
    else if (columnType == RLMTypeFloat) {
        average = [NSNumber numberWithDouble:query.average_float(index)];
    }
    else {
        @throw [NSException exceptionWithName:@"realm:operation_not_supprted"
                                       reason:@"Average only supported on int, float and double columns."
                                     userInfo:nil];
    }
    
    return average;
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
    REALM_EXCEPTION_ERRHANDLER(m_table->optimize();, NO);
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


+ (void)updateDescriptor:(RLMDescriptor *)desc toSupportObjectDescriptor:(RLMObjectDescriptor *)descriptor {
    for (RLMProperty *prop in descriptor.properties) {
        NSUInteger index = [desc indexOfColumnWithName:prop.name];
        if (index == NSNotFound) {
            // create the column
            [desc addColumnWithName:prop.name type:prop.type];
            if (prop.type == RLMTypeTable) {
                // set subtable schema
                RLMDescriptor * subDesc = [desc subdescriptorForColumnWithIndex:desc.columnCount-1];
                RLMObjectDescriptor * objectDescriptor = [RLMObjectDescriptor descriptorForObjectClass:prop.subtableObjectClass];
                [RLMTable updateDescriptor:subDesc toSupportObjectDescriptor:objectDescriptor];
            }
        }
        else if ([desc columnTypeOfColumnWithIndex:index] != prop.type) {
            NSString *reason = [NSString stringWithFormat:@"Column with name '%@' exists on table with different type", prop.name];
            @throw [NSException exceptionWithName:@"TDBException"
                                           reason:reason
                                         userInfo:nil];
        }
    }
}


// returns YES if you can currently insert objects of type Class
-(BOOL)canInsertObjectOfClass:(Class)objectClass {
    RLMObjectDescriptor * descriptor = [RLMObjectDescriptor descriptorForObjectClass:objectClass];
    for (RLMProperty * prop in descriptor.properties) {
        NSUInteger index = [self indexOfColumnWithName:prop.name];
        if (index == NSNotFound || [self columnTypeOfColumnWithIndex:index] != prop.type) {
            NSLog(@"Schema not compatible with table columns");
            return NO;
        }
    }
    return YES;
}

// returns YES if it's possible to update the table to support objects of type Class
-(BOOL)canUpdateToSupportObjectClass:(Class)objectClass {
    RLMObjectDescriptor *descriptor = [RLMObjectDescriptor descriptorForObjectClass:objectClass];
    for (RLMProperty *prop in descriptor.properties) {
        NSUInteger index = [self indexOfColumnWithName:prop.name];
        if (index != NSNotFound && [self columnTypeOfColumnWithIndex:index] != prop.type) {
            return NO;
        }
    }
    return YES;
}


@end
