//
//  table.mm
//  TightDB
//

#import <Foundation/Foundation.h>

#include <tightdb/util/unique_ptr.hpp>
#include <tightdb/table.hpp>
#include <tightdb/descriptor.hpp>
#include <tightdb/table_view.hpp>
#include <tightdb/lang_bind_helper.hpp>

#import <tightdb/objc/table.h>
#import <tightdb/objc/table_priv.h>
#import <tightdb/objc/query.h>
#import <tightdb/objc/query_priv.h>
#import <tightdb/objc/cursor.h>
#import <tightdb/objc/support.h>

#include <tightdb/objc/util.hpp>

using namespace std;

@implementation TightdbBinary
{
    tightdb::BinaryData m_data;
}
-(id)initWithData:(const char*)data size:(size_t)size
{
    self = [super init];
    if (self) {
        m_data = tightdb::BinaryData(data, size);
    }
    return self;
}
-(id)initWithBinary:(tightdb::BinaryData)data
{
    self = [super init];
    if (self) {
        m_data = data;
    }
    return self;
}
-(const char*)getData
{
    return m_data.data();
}
-(size_t)getSize
{
    return m_data.size();
}
-(BOOL)isEqual:(TightdbBinary*)bin
{
    return m_data == bin->m_data;
}
-(tightdb::BinaryData&)getNativeBinary
{
    return m_data;
}
@end


@interface TightdbMixed()
+(TightdbMixed*)mixedWithNativeMixed:(const tightdb::Mixed&)other;
-(tightdb::Mixed&)getNativeMixed;
@end
@implementation TightdbMixed
{
    tightdb::Mixed m_mixed;
    TightdbTable* m_table;
}

+(TightdbMixed*)mixedWithBool:(BOOL)value
{
    TightdbMixed* mixed = [[TightdbMixed alloc] init];
    mixed->m_mixed = tightdb::Mixed(bool(value));
    mixed->m_table = nil;
    return mixed;
}

+(TightdbMixed*)mixedWithInt64:(int64_t)value
{
    TightdbMixed* mixed = [[TightdbMixed alloc] init];
    mixed->m_mixed = tightdb::Mixed(value);
    mixed->m_table = nil;
    return mixed;
}

+(TightdbMixed*)mixedWithFloat:(float)value
{
    TightdbMixed* mixed = [[TightdbMixed alloc] init];
    mixed->m_mixed = tightdb::Mixed(value);
    mixed->m_table = nil;
    return mixed;
}

+(TightdbMixed*)mixedWithDouble:(double)value
{
    TightdbMixed* mixed = [[TightdbMixed alloc] init];
    mixed->m_mixed = tightdb::Mixed(value);
    mixed->m_table = nil;
    return mixed;
}

+(TightdbMixed*)mixedWithString:(NSString*)value
{
    TightdbMixed* mixed = [[TightdbMixed alloc] init];
    mixed->m_mixed = tightdb::Mixed(ObjcStringAccessor(value));
    mixed->m_table = nil;
    return mixed;
}

+(TightdbMixed*)mixedWithBinary:(TightdbBinary*)value
{
    TightdbMixed* mixed = [[TightdbMixed alloc] init];
    mixed->m_mixed = tightdb::Mixed([value getNativeBinary]);
    mixed->m_table = nil;
    return mixed;
}

+(TightdbMixed*)mixedWithBinary:(const char*)data size:(size_t)size
{
    TightdbMixed* mixed = [[TightdbMixed alloc] init];
    mixed->m_mixed = tightdb::Mixed(tightdb::BinaryData(data, size));
    mixed->m_table = nil;
    return mixed;
}

+(TightdbMixed*)mixedWithDate:(time_t)value
{
    TightdbMixed* mixed = [[TightdbMixed alloc] init];
    mixed->m_mixed = tightdb::Mixed(tightdb::DateTime(value));
    mixed->m_table = nil;
    return mixed;
}

+(TightdbMixed*)mixedWithTable:(TightdbTable*)value
{
    TightdbMixed* mixed = [[TightdbMixed alloc] init];
    mixed->m_mixed = tightdb::Mixed(tightdb::Mixed::subtable_tag());
    mixed->m_table = value;
    return mixed;
}

+(TightdbMixed*)mixedWithNativeMixed:(const tightdb::Mixed&)value
{
    TightdbMixed* mixed = [[TightdbMixed alloc] init];
    mixed->m_mixed = value;
    mixed->m_table = nil;
    return mixed;
}

-(tightdb::Mixed&)getNativeMixed
{
    return m_mixed;
}

-(BOOL)isEqual:(TightdbMixed*)other
{
    tightdb::DataType type = m_mixed.get_type();
    if (type != other->m_mixed.get_type())
        return NO;
    switch (type) {
        case tightdb::type_Bool:
            return m_mixed.get_bool() == other->m_mixed.get_bool();
        case tightdb::type_Int:
            return m_mixed.get_int() == other->m_mixed.get_int();
        case tightdb::type_Float:
            return m_mixed.get_float() == other->m_mixed.get_float();
        case tightdb::type_Double:
            return m_mixed.get_double() == other->m_mixed.get_double();
        case tightdb::type_String:
            return m_mixed.get_string() == other->m_mixed.get_string();
        case tightdb::type_Binary:
            return m_mixed.get_binary() == other->m_mixed.get_binary();
        case tightdb::type_DateTime:
            return m_mixed.get_datetime() == other->m_mixed.get_datetime();
        case tightdb::type_Table:
            return [m_table getNativeTable] == [other->m_table getNativeTable]; // Compare table contents
        case tightdb::type_Mixed:
            TIGHTDB_ASSERT(false);
            break;
    }
    return NO;
}

-(TightdbType)getType
{
    return TightdbType(m_mixed.get_type());
}

-(BOOL)getBool
{
    return m_mixed.get_bool();
}

-(int64_t)getInt
{
    return m_mixed.get_int();
}

-(float)getFloat
{
    return m_mixed.get_float();
}

-(double)getDouble
{
    return m_mixed.get_double();
}

-(NSString*)getString
{
    return to_objc_string(m_mixed.get_string());
}

-(TightdbBinary*)getBinary
{
    return [[TightdbBinary alloc] initWithBinary:m_mixed.get_binary()];
}

-(time_t)getDate
{
    return m_mixed.get_datetime().get_datetime();
}

-(TightdbTable*)getTable
{
    return m_table;
}
@end


@interface TightdbDescriptor()
+(TightdbDescriptor*)descWithDesc:(tightdb::Descriptor*)desc readOnly:(BOOL)read_only error:(NSError* __autoreleasing*)error;
@end

@implementation TightdbDescriptor
{
    tightdb::DescriptorRef m_desc;
    BOOL m_read_only;
}


+(TightdbDescriptor*)descWithDesc:(tightdb::Descriptor*)desc readOnly:(BOOL)read_only error:(NSError* __autoreleasing*)error
{
    static_cast<void>(error);
    TightdbDescriptor* desc_2 = [[TightdbDescriptor alloc] init];
    desc_2->m_desc.reset(desc);
    desc_2->m_read_only = read_only;
    return desc_2;
}

// FIXME: Provide a version of this method that takes a 'const char*'. This will simplify _addColumns of MyTable.
// FIXME: Detect errors from core library
-(BOOL)addColumnWithType:(TightdbType)type andName:(NSString*)name
{
    return [self addColumnWithType:type andName:name error:nil];
}

-(BOOL)addColumnWithType:(TightdbType)type andName:(NSString*)name error:(NSError* __autoreleasing*)error
{
    if (m_read_only) {
        if (error)
            *error = make_tightdb_error(tdb_err_FailRdOnly, @"Tried to add column while read only");
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
        m_desc->add_column(tightdb::DataType(type), ObjcStringAccessor(name));,
        NO);
    return YES;
}




-(TightdbDescriptor*)addColumnTable:(NSString*)name
{
    return [self addColumnTable:name error:nil];
}

-(TightdbDescriptor*)addColumnTable:(NSString*)name error:(NSError* __autoreleasing*)error
{
    if (m_read_only) {
        if (error)
            *error = make_tightdb_error(tdb_err_FailRdOnly, @"Tried to add column while read only");
        return nil;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
        tightdb::DescriptorRef subdesc;
        m_desc->add_column(tightdb::type_Table, ObjcStringAccessor(name), &subdesc);
        return [TightdbDescriptor descWithDesc:subdesc.get() readOnly:FALSE error:error];,
        nil);
}

-(TightdbDescriptor*)getSubdescriptor:(size_t)col_ndx
{
    return [self getSubdescriptor:col_ndx error:nil];
}

-(TightdbDescriptor*)getSubdescriptor:(size_t)col_ndx error:(NSError* __autoreleasing*)error
{
    TIGHTDB_EXCEPTION_ERRHANDLER(
        tightdb::DescriptorRef subdesc = m_desc->get_subdescriptor(col_ndx);
        return [TightdbDescriptor descWithDesc:subdesc.get() readOnly:m_read_only error:error];,
        nil);
}

-(size_t)getColumnCount
{
    return m_desc->get_column_count();
}
-(TightdbType)getColumnType:(size_t)ndx
{
    return (TightdbType)m_desc->get_column_type(ndx);
}
-(NSString*)getColumnName:(size_t)ndx
{
    return to_objc_string(m_desc->get_column_name(ndx));
}
-(size_t)getColumnIndex:(NSString*)name
{
    return m_desc->get_column_index(ObjcStringAccessor(name));
}
-(void)dealloc
{
#ifdef TIGHTDB_DEBUG
    NSLog(@"TightdbDescriptor dealloc");
#endif
}


@end


@implementation TightdbView
{
    tightdb::util::UniquePtr<tightdb::TableView> m_view;
    TightdbTable* m_table;
    TightdbCursor* m_tmp_cursor;
    BOOL m_read_only;
}

+(TightdbView*)viewWithTable:(TightdbTable*)table andNativeView:(const tightdb::TableView&)view
{
    TightdbView* view_2 = [[TightdbView alloc] init];
    if (!view_2)
        return nil;
    view_2->m_view.reset(new tightdb::TableView(view)); // FIXME: Exception handling needed here
    view_2->m_table = table;
    view_2->m_read_only = [table isReadOnly];

    return view_2;
}

-(id)_initWithQuery:(TightdbQuery*)query
{
    self = [super init];
    if (self) {
        tightdb::Query& query_2 = [query getNativeQuery];
        m_view.reset(new tightdb::TableView(query_2.find_all())); // FIXME: Exception handling needed here
        m_table = [query getTable];
        m_read_only = [m_table isReadOnly];
    }
    return self;
}

-(TightdbTable*)getTable
{
    return m_table;
}

-(void)dealloc
{
#ifdef TIGHTDB_DEBUG
    NSLog(@"TightdbView dealloc");
#endif
    m_table = nil; // FIXME: What is the point of doing this?
}

-(TightdbCursor*)cursorAtIndex:(size_t)ndx
{
    // The cursor constructor checks the index is in bounds. However, getSourceIndex should
    // not be called with illegal index.

    if (ndx >= [self count])
        return nil;

    return [[TightdbCursor alloc] initWithTable:m_table ndx:[self getSourceIndex:ndx]];
}

-(size_t)count
{
    return m_view->size();
}
-(BOOL)isEmpty
{
    return m_view->is_empty();
}
-(int64_t)get:(size_t)col_ndx ndx:(size_t)ndx
{
    return m_view->get_int(col_ndx, ndx);
}
-(BOOL)getBool:(size_t)col_ndx ndx:(size_t)ndx
{
    return m_view->get_bool(col_ndx, ndx);
}
-(time_t)getDate:(size_t)col_ndx ndx:(size_t)ndx
{
    return m_view->get_datetime(col_ndx, ndx).get_datetime();
}
-(NSString*)getString:(size_t)col_ndx ndx:(size_t)ndx
{
    return to_objc_string(m_view->get_string(col_ndx, ndx));
}
-(void)removeRowAtIndex:(size_t)ndx
{
    m_view->remove(ndx);
}
-(void)clear
{
    if (m_read_only) {
        NSException* exception = [NSException exceptionWithName:@"tightdb:table_view_is_read_only"
                                                         reason:@"You tried to modify an immutable tableview"
                                                       userInfo:[NSMutableDictionary dictionary]];
        [exception raise];
    }
    
    m_view->clear();
}
-(size_t)getSourceIndex:(size_t)ndx
{
    return m_view->get_source_ndx(ndx);
}

-(TightdbCursor*)getCursor
{
    return m_tmp_cursor = [[TightdbCursor alloc] initWithTable: m_table
                                                           ndx: m_view->get_source_ndx(0)];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState*)state objects:(id __unsafe_unretained*)stackbuf count:(NSUInteger)len
{
    static_cast<void>(len);
    if(state->state == 0) {
        const unsigned long* ptr = static_cast<const unsigned long*>(objc_unretainedPointer(self));
        state->mutationsPtr = const_cast<unsigned long*>(ptr); // FIXME: This casting away of constness seems dangerous. Is it?
        TightdbCursor* tmp = [self getCursor];
        *stackbuf = tmp;
    }
    if (state->state < [self count]) {
        [((TightdbCursor*)*stackbuf) setNdx:[self getSourceIndex:state->state]];
        state->itemsPtr = stackbuf;
        state->state++;
    }
    else {
        *stackbuf = nil;
        state->itemsPtr = nil;
        state->mutationsPtr = nil;
        return 0;
    }
    return 1;
}

@end


@implementation TightdbTable
{
    tightdb::TableRef m_table;
    id m_parent;
    BOOL m_read_only;
    TightdbCursor* m_tmp_cursor;
}



-(id)init
{
    self = [super init];
    if (self) {
        m_read_only = NO;
        m_table = tightdb::Table::create(); // FIXME: May throw
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

-(TightdbCursor*)getCursor
{
    return m_tmp_cursor = [[TightdbCursor alloc] initWithTable:self ndx:0];
}
-(void)clearCursor
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
        TightdbCursor* tmp = [self getCursor];
        *stackbuf = tmp;
    }
    if (state->state < [self count]) {
        [((TightdbCursor*)*stackbuf) setNdx:state->state];
        state->itemsPtr = stackbuf;
        state->state++;
    }
    else {
        *stackbuf = nil;
        state->itemsPtr = nil;
        state->mutationsPtr = nil;
        [self clearCursor];
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

-(BOOL)isEqual:(TightdbTable*)other
{
    return *m_table == *other->m_table;
}

// FIXME: Check that the specified class derives from TightdbTable.
-(BOOL)isClass:(__unsafe_unretained Class)class_obj
{
    TightdbTable* table = [[class_obj alloc] _initRaw];
    if (TIGHTDB_LIKELY(table)) {
        [table setNativeTable:m_table.get()];
        [table setParent:m_parent];
        [table setReadOnly:m_read_only];
        if ([table _checkType])
            return YES;
    }
    return NO;
}

// FIXME: Check that the specified class derives from TightdbTable.
-(id)castClass:(__unsafe_unretained Class)class_obj
{
    TightdbTable* table = [[class_obj alloc] _initRaw];
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
    NSLog(@"TightdbTable dealloc");
#endif
    m_parent = nil; // FIXME: Does this really make a difference?
}

-(size_t)getColumnCount
{
    return m_table->get_column_count();
}
-(NSString*)getColumnName:(size_t)ndx
{
    return to_objc_string(m_table->get_column_name(ndx));
}
-(size_t)getColumnIndex:(NSString*)name
{
    return m_table->get_column_index(ObjcStringAccessor(name));
}
-(TightdbType)getColumnType:(size_t)ndx
{
    return TightdbType(m_table->get_column_type(ndx));
}
-(TightdbDescriptor*)getDescriptor
{
    return [self getDescriptorWithError:nil];
}
-(TightdbDescriptor*)getDescriptorWithError:(NSError* __autoreleasing*)error
{
    tightdb::DescriptorRef desc = m_table->get_descriptor();
    BOOL read_only = m_read_only || m_table->has_shared_type();
    return [TightdbDescriptor descWithDesc:desc.get() readOnly:read_only error:error];
}
-(BOOL)isEmpty
{
    return m_table->is_empty();
}
-(size_t)count
{
    return m_table->size();
}

-(TightdbCursor*)addEmptyRow
{
    return [[TightdbCursor alloc] initWithTable:self ndx:[self _addEmptyRow]];
}


-(size_t)_addEmptyRow
{
    return [self _addEmptyRows:1];
}

-(size_t)_addEmptyRows:(size_t)num_rows
{
    // TODO: Use a macro or a function for error handling

    if(m_read_only) {
        NSException* exception = [NSException exceptionWithName:@"tightdb:table_is_read_only"
                                                         reason:@"You tried to modify a table in read only mode"
                                                       userInfo:[NSMutableDictionary dictionary]];
        [exception raise];
    }

    size_t index;
    try {
        index = m_table->add_empty_row(num_rows);
    }
    catch(std::exception& ex) {
        NSException *exception = [NSException exceptionWithName:@"tightdb:core_exception"
                                                         reason:[NSString stringWithUTF8String:ex.what()]
                                                       userInfo:[NSMutableDictionary dictionary]];
        [exception raise];
    }

    return index;
}

-(TightdbCursor *)objectAtIndexedSubscript:(NSUInteger)ndx
{
    return [[TightdbCursor alloc] initWithTable:self ndx:ndx];
}


-(TightdbCursor*)cursorAtIndex:(size_t)ndx
{
    // initWithTable checks for illegal index.

    return [[TightdbCursor alloc] initWithTable:self ndx:ndx];
}

-(TightdbCursor*)cursorAtLastIndex
{
    return [[TightdbCursor alloc] initWithTable:self ndx:[self count]-1];
}

-(TightdbCursor*)insertRowAtIndex:(size_t)ndx
{
    [self insertRow:ndx];
    return [[TightdbCursor alloc] initWithTable:self ndx:ndx];
}

-(BOOL)appendRow:(NSArray*)data
{
    tightdb::Table& table = *m_table;
    tightdb::ConstDescriptorRef desc = table.get_descriptor();
    if (!verify_row(*desc, data)) {
        return NO;
    }

    /* append row */
    return insert_row(table.size(), table, data);
}

-(BOOL)insertRow:(size_t)ndx
{
    return [self insertRow:ndx error:nil];
}

-(BOOL)insertRow:(size_t)ndx error:(NSError* __autoreleasing*)error
{
    if (m_read_only) {
        if (error)
            *error = make_tightdb_error(tdb_err_FailRdOnly, @"Tried to insert row while read-only.");
        return NO;
    }

    TIGHTDB_EXCEPTION_ERRHANDLER(m_table->insert_empty_row(ndx);, 0);
    return YES;
}

-(BOOL)clear
{
    if (m_read_only) {
        NSException* exception = [NSException exceptionWithName:@"tightdb:table_view_is_read_only"
                                                         reason:@"You tried to modify an immutable tableview"
                                                       userInfo:[NSMutableDictionary dictionary]];
        [exception raise];
        return NO;
    }
    
    m_table->clear();
    return YES;
}

-(BOOL)removeRowAtIndex:(size_t)ndx
{
    return [self removeRowAtIndex:ndx error:nil];
}

-(BOOL)removeRowAtIndex:(size_t)ndx error:(NSError* __autoreleasing*)error
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


-(BOOL)getBoolInColumn:(size_t)col_ndx atRow:(size_t)row_ndx
{
    return m_table->get_bool(col_ndx, row_ndx);
}

-(int64_t)getIntInColumn:(size_t)col_ndx atRow:(size_t)row_ndx
{
    return m_table->get_int(col_ndx, row_ndx);
}

-(float)getFloatInColumn:(size_t)col_ndx atRow:(size_t)row_ndx
{
    return m_table->get_float(col_ndx, row_ndx);
}

-(double)getDoubleInColumn:(size_t)col_ndx atRow:(size_t)row_ndx
{
    return m_table->get_double(col_ndx, row_ndx);
}

-(NSString*)getStringInColumn:(size_t)col_ndx atRow:(size_t)row_ndx
{
    return to_objc_string(m_table->get_string(col_ndx, row_ndx));
}

-(TightdbBinary*)getBinaryInColumn:(size_t)col_ndx atRow:(size_t)row_ndx
{
    return [[TightdbBinary alloc] initWithBinary:m_table->get_binary(col_ndx, row_ndx)];
}

-(time_t)getDateInColumn:(size_t)col_ndx atRow:(size_t)row_ndx
{
    return m_table->get_datetime(col_ndx, row_ndx).get_datetime();
}

-(TightdbTable*)getTableInColumn:(size_t)col_ndx atRow:(size_t)row_ndx
{
    tightdb::DataType type = m_table->get_column_type(col_ndx);
    if (type != tightdb::type_Table)
        return nil;
    tightdb::TableRef table = m_table->get_subtable(col_ndx, row_ndx);
    if (!table)
        return nil;
    TightdbTable* table_2 = [[TightdbTable alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table_2))
        return nil;
    [table_2 setNativeTable:table.get()];
    [table_2 setParent:self];
    [table_2 setReadOnly:m_read_only];
    return table_2;
}

// FIXME: Check that the specified class derives from TightdbTable.
-(id)getTableInColumn:(size_t)col_ndx atRow:(size_t)row_ndx withClass:(__unsafe_unretained Class)class_obj
{
    tightdb::DataType type = m_table->get_column_type(col_ndx);
    if (type != tightdb::type_Table)
        return nil;
    tightdb::TableRef table = m_table->get_subtable(col_ndx, row_ndx);
    if (!table)
        return nil;
    TightdbTable* table_2 = [[class_obj alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table))
        return nil;
    [table_2 setNativeTable:table.get()];
    [table_2 setParent:self];
    [table_2 setReadOnly:m_read_only];
    if (![table_2 _checkType])
        return nil;
    return table_2;
}

-(TightdbMixed*)getMixedInColumn:(size_t)col_ndx atRow:(size_t)row_ndx
{
    tightdb::Mixed mixed = m_table->get_mixed(col_ndx, row_ndx);
    if (mixed.get_type() != tightdb::type_Table)
        return [TightdbMixed mixedWithNativeMixed:mixed];

    tightdb::TableRef table = m_table->get_subtable(col_ndx, row_ndx);
    if (!table)
        return nil;
    TightdbTable* table_2 = [[TightdbTable alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table_2))
        return nil;
    [table_2 setNativeTable:table.get()];
    [table_2 setParent:self];
    [table_2 setReadOnly:m_read_only];
    if (![table_2 _checkType])
        return nil;

    return [TightdbMixed mixedWithTable:table_2];
}


-(void)setBool:(BOOL)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx
{
    TIGHTDB_EXCEPTION_HANDLER_SETTERS(
        m_table->set_bool(col_ndx, row_ndx, value);,
        tightdb_Bool);
}

-(void)setInt:(int64_t)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx
{
    TIGHTDB_EXCEPTION_HANDLER_SETTERS(
        m_table->set_int(col_ndx, row_ndx, value);,
        tightdb_Int);
}

-(void)setFloat:(float)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx
{
    TIGHTDB_EXCEPTION_HANDLER_SETTERS(
        m_table->set_float(col_ndx, row_ndx, value);,
        tightdb_Float);
}

-(void)setDouble:(double)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx
{
    TIGHTDB_EXCEPTION_HANDLER_SETTERS(
        m_table->set_double(col_ndx, row_ndx, value);,
        tightdb_Double);
}

-(void)setString:(NSString*)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx
{
    TIGHTDB_EXCEPTION_HANDLER_SETTERS(
        m_table->set_string(col_ndx, row_ndx, ObjcStringAccessor(value));,
        tightdb_String);
}

-(void)setBinary:(TightdbBinary*)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx
{
    TIGHTDB_EXCEPTION_HANDLER_SETTERS(
        m_table->set_binary(col_ndx, row_ndx, [value getNativeBinary]);,
        tightdb_Binary);
}

-(void)setDate:(time_t)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx
{
    TIGHTDB_EXCEPTION_HANDLER_SETTERS(
        m_table->set_datetime(col_ndx, row_ndx, value);,
        tightdb_Date);
}

-(void)setTable:(TightdbTable*)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx
{
    // TODO: Use core method for checking the equality of two table specs. Even in the typed interface
    // the user might add columns (_checkType for typed and spec against spec for dynamic).

    TIGHTDB_EXCEPTION_HANDLER_SETTERS(
        m_table->set_subtable(col_ndx, row_ndx, &[value getNativeTable]);,
        tightdb_Table);
}

-(void)setMixed:(TightdbMixed*)value inColumn:(size_t)col_ndx atRow:(size_t)row_ndx
{
    const tightdb::Mixed& mixed = [value getNativeMixed];
    TightdbTable* subtable = mixed.get_type() == tightdb::type_Table ? [value getTable] : nil;
    TIGHTDB_EXCEPTION_HANDLER_SETTERS(
        if (subtable) {
            tightdb::LangBindHelper::set_mixed_subtable(*m_table, col_ndx, row_ndx,
                                                        [subtable getNativeTable]);
        }
        else {
            m_table->set_mixed(col_ndx, row_ndx, mixed);
        },
        tightdb_Mixed);
}


-(BOOL)insertBool:(size_t)col_ndx ndx:(size_t)ndx value:(BOOL)value
{
    return [self insertBool:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)insertBool:(size_t)col_ndx ndx:(size_t)ndx value:(BOOL)value error:(NSError* __autoreleasing*)error
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

-(BOOL)insertInt:(size_t)col_ndx ndx:(size_t)ndx value:(int64_t)value
{
    return [self insertInt:col_ndx ndx:ndx value:value error:nil];
}


-(BOOL)insertInt:(size_t)col_ndx ndx:(size_t)ndx value:(int64_t)value error:(NSError* __autoreleasing*)error
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

-(BOOL)insertFloat:(size_t)col_ndx ndx:(size_t)ndx value:(float)value
{
    return [self insertFloat:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)insertFloat:(size_t)col_ndx ndx:(size_t)ndx value:(float)value error:(NSError* __autoreleasing*)error
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

-(BOOL)insertDouble:(size_t)col_ndx ndx:(size_t)ndx value:(double)value
{
    return [self insertDouble:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)insertDouble:(size_t)col_ndx ndx:(size_t)ndx value:(double)value error:(NSError* __autoreleasing*)error
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

-(BOOL)insertString:(size_t)col_ndx ndx:(size_t)ndx value:(NSString*)value
{
    return [self insertString:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)insertString:(size_t)col_ndx ndx:(size_t)ndx value:(NSString*)value error:(NSError* __autoreleasing*)error
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

-(BOOL)insertBinary:(size_t)col_ndx ndx:(size_t)ndx value:(TightdbBinary*)value
{
    return [self insertBinary:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)insertBinary:(size_t)col_ndx ndx:(size_t)ndx value:(TightdbBinary*)value error:(NSError* __autoreleasing*)error
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
        m_table->insert_binary(col_ndx, ndx, [value getNativeBinary]);,
        NO);
    return YES;
}

-(BOOL)insertBinary:(size_t)col_ndx ndx:(size_t)ndx data:(const char*)data size:(size_t)size
{
    return [self insertBinary:col_ndx ndx:ndx data:data size:size error:nil];
}

-(BOOL)insertBinary:(size_t)col_ndx ndx:(size_t)ndx data:(const char*)data size:(size_t)size error:(NSError* __autoreleasing*)error
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

-(BOOL)insertDate:(size_t)col_ndx ndx:(size_t)ndx value:(time_t)value
{
    return [self insertDate:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)insertDate:(size_t)col_ndx ndx:(size_t)ndx value:(time_t)value error:(NSError* __autoreleasing*)error
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
    TIGHTDB_EXCEPTION_ERRHANDLER(m_table->insert_datetime(col_ndx, ndx, value);, NO);
    return YES;
}

-(BOOL)insertDone
{
    return [self insertDoneWithError:nil];
}

-(BOOL)insertDoneWithError:(NSError* __autoreleasing*)error
{
    // FIXME: This method should probably not take an error argument.
    TIGHTDB_EXCEPTION_ERRHANDLER(m_table->insert_done();, NO);
    return YES;
}


-(size_t)getTableSize:(size_t)col_ndx ndx:(size_t)row_ndx
{
    return m_table->get_subtable_size(col_ndx, row_ndx);
}

-(BOOL)insertSubtable:(size_t)col_ndx ndx:(size_t)row_ndx
{
    return [self insertSubtable:col_ndx ndx:row_ndx error:nil];
}

-(BOOL)insertSubtable:(size_t)col_ndx ndx:(size_t)row_ndx error:(NSError* __autoreleasing*)error
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

-(BOOL)_insertSubtableCopy:(size_t)col_ndx row:(size_t)row_ndx subtable:(TightdbTable*)subtable
{
    return [self _insertSubtableCopy:col_ndx row:row_ndx subtable:subtable error:nil];
}


-(BOOL)_insertSubtableCopy:(size_t)col_ndx row:(size_t)row_ndx subtable:(TightdbTable*)subtable error:(NSError* __autoreleasing*)error
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

-(BOOL)clearSubtable:(size_t)col_ndx ndx:(size_t)row_ndx
{
    return [self clearSubtable:col_ndx ndx:row_ndx error:nil];
}
-(BOOL)clearSubtable:(size_t)col_ndx ndx:(size_t)row_ndx error:(NSError* __autoreleasing*)error
{
    // FIXME: Read-only errors should probably be handled by throwing
    // an exception. That is what is done in other places in this
    // binding, and it also seems like the right thing to do. This
    // method should also not take an error argument.
    if (m_read_only) {
        if (error)
            *error = make_tightdb_error(tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to clear while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(m_table->clear_subtable(col_ndx, row_ndx);, NO);
    return YES;
}


-(TightdbType)getMixedType:(size_t)col_ndx ndx:(size_t)row_ndx
{
    return TightdbType(m_table->get_mixed_type(col_ndx, row_ndx));
}

-(BOOL)insertMixed:(size_t)col_ndx ndx:(size_t)row_ndx value:(TightdbMixed*)value
{
    return [self insertMixed:col_ndx ndx:row_ndx value:value error:nil];
}

-(BOOL)insertMixed:(size_t)col_ndx ndx:(size_t)row_ndx value:(TightdbMixed*)value error:(NSError* __autoreleasing*)error
{
    if (m_read_only) {
        if (error)
            *error = make_tightdb_error(tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    const tightdb::Mixed& mixed = [value getNativeMixed];
    TightdbTable* subtable = mixed.get_type() == tightdb::type_Table ? [value getTable] : nil;
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


-(size_t)addColumnWithType:(TightdbType)type andName:(NSString*)name
{
    return [self addColumnWithType:type andName:name error:nil];
}

-(size_t)addColumnWithType:(TightdbType)type andName:(NSString*)name error:(NSError* __autoreleasing*)error
{
    TIGHTDB_EXCEPTION_ERRHANDLER(
        return m_table->add_column(tightdb::DataType(type), ObjcStringAccessor(name));,
        0);
}

-(void)removeColumnWithIndex:(size_t)columnIndex
{
    TIGHTDB_EXCEPTION_HANDLER_COLUMN_INDEX_VALID(columnIndex);
    
    try {
        m_table->remove_column(columnIndex);
    }
    catch(std::exception& ex) {
        NSException* exception = [NSException exceptionWithName:@"tightdb:core_exception"
                                                         reason:[NSString stringWithUTF8String:ex.what()]
                                                       userInfo:[NSMutableDictionary dictionary]];
        [exception raise];
    }
}

-(size_t)findBool:(size_t)col_ndx value:(BOOL)value
{
    return m_table->find_first_bool(col_ndx, value);
}
-(size_t)findInt:(size_t)col_ndx value:(int64_t)value
{
    return m_table->find_first_int(col_ndx, value);
}
-(size_t)findFloat:(size_t)col_ndx value:(float)value
{
    return m_table->find_first_float(col_ndx, value);
}
-(size_t)findDouble:(size_t)col_ndx value:(double)value
{
    return m_table->find_first_double(col_ndx, value);
}
-(size_t)findString:(size_t)col_ndx value:(NSString*)value
{
    return m_table->find_first_string(col_ndx, ObjcStringAccessor(value));
}
-(size_t)findBinary:(size_t)col_ndx value:(TightdbBinary*)value
{
    return m_table->find_first_binary(col_ndx, [value getNativeBinary]);
}
-(size_t)findDate:(size_t)col_ndx value:(time_t)value
{
    return m_table->find_first_datetime(col_ndx, value);
}
-(size_t)findMixed:(size_t)col_ndx value:(TightdbMixed*)value
{
    static_cast<void>(col_ndx);
    static_cast<void>(value);
    [NSException raise:@"NotImplemented" format:@"Not implemented"];
    // FIXME: Implement this!
//    return _table->find_first_mixed(col_ndx, [value getNativeMixed]);
    return 0;
}

-(TightdbView*)findAllBool:(BOOL)value inColumn:(size_t)col_ndx
{
    tightdb::TableView view = m_table->find_all_bool(col_ndx, value);
    return [TightdbView viewWithTable:self andNativeView:view];
}
-(TightdbView*)findAllInt:(int64_t)value inColumn:(size_t)col_ndx
{
    tightdb::TableView view = m_table->find_all_int(col_ndx, value);
    return [TightdbView viewWithTable:self andNativeView:view];
}
-(TightdbView*)findAllFloat:(float)value inColumn:(size_t)col_ndx
{
    tightdb::TableView view = m_table->find_all_float(col_ndx, value);
    return [TightdbView viewWithTable:self andNativeView:view];
}
-(TightdbView*)findAllDouble:(double)value inColumn:(size_t)col_ndx
{
    tightdb::TableView view = m_table->find_all_double(col_ndx, value);
    return [TightdbView viewWithTable:self andNativeView:view];
}
-(TightdbView*)findAllString:(NSString*)value inColumn:(size_t)col_ndx
{
    tightdb::TableView view = m_table->find_all_string(col_ndx, ObjcStringAccessor(value));
    return [TightdbView viewWithTable:self andNativeView:view];
}
-(TightdbView*)findAllBinary:(TightdbBinary*)value inColumn:(size_t)col_ndx
{
    tightdb::TableView view = m_table->find_all_binary(col_ndx, [value getNativeBinary]);
    return [TightdbView viewWithTable:self andNativeView:view];
}
-(TightdbView*)findAllDate:(time_t)value inColumn:(size_t)col_ndx
{
    tightdb::TableView view = m_table->find_all_datetime(col_ndx, value);
    return [TightdbView viewWithTable:self andNativeView:view];
}
-(TightdbView*)findAllMixed:(TightdbMixed*)value inColumn:(size_t)col_ndx
{
    static_cast<void>(col_ndx);
    static_cast<void>(value);
    [NSException raise:@"NotImplemented" format:@"Not implemented"];
    // FIXME: Implement this!
//    tightdb::TableView view = m_table->find_all_mixed(col_ndx, [value getNativeMixed]);
//    return [TightdbView viewWithTable:self andNativeView:view];
    return 0;
}

-(TightdbQuery*)where
{
    return [self whereWithError:nil];
}

-(TightdbQuery*)whereWithError:(NSError* __autoreleasing*)error
{
    return [[TightdbQuery alloc] initWithTable:self error:error];
}

-(BOOL)hasIndex:(size_t)col_ndx
{
    return m_table->has_index(col_ndx);
}

-(void)setIndex:(size_t)col_ndx
{
    m_table->set_index(col_ndx);
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

-(size_t)countWithIntColumn:(size_t)col_ndx andValue:(int64_t)target
{
    return m_table->count_int(col_ndx, target);
}
-(size_t)countWithFloatColumn:(size_t)col_ndx andValue:(float)target
{
    return m_table->count_float(col_ndx, target);
}
-(size_t)countWithDoubleColumn:(size_t)col_ndx andValue:(double)target
{
    return m_table->count_double(col_ndx, target);
}
-(size_t)countWithStringColumn:(size_t)col_ndx andValue:(NSString*)target
{
    return m_table->count_string(col_ndx, ObjcStringAccessor(target));
}

-(int64_t)sumWithIntColumn:(size_t)col_ndx
{
    return m_table->sum_int(col_ndx);
}
-(double)sumWithFloatColumn:(size_t)col_ndx
{
    return m_table->sum_float(col_ndx);
}
-(double)sumWithDoubleColumn:(size_t)col_ndx
{
    return m_table->sum_double(col_ndx);
}

-(int64_t)maximumWithIntColumn:(size_t)col_ndx
{
    return m_table->maximum_int(col_ndx);
}
-(float)maximumWithFloatColumn:(size_t)col_ndx
{
    return m_table->maximum_float(col_ndx);
}
-(double)maximumWithDoubleColumn:(size_t)col_ndx
{
    return m_table->maximum_double(col_ndx);
}

-(int64_t)minimumWithIntColumn:(size_t)col_ndx
{
    return m_table->minimum_int(col_ndx);
}
-(float)minimumWithFloatColumn:(size_t)col_ndx
{
    return m_table->minimum_float(col_ndx);
}
-(double)minimumWithDoubleColumn:(size_t)col_ndx
{
    return m_table->minimum_double(col_ndx);
}

-(double)averageWithIntColumn:(size_t)col_ndx
{
    return m_table->average_int(col_ndx);
}
-(double)averageWithFloatColumn:(size_t)col_ndx
{
    return m_table->average_float(col_ndx);
}
-(double)averageWithDoubleColumn:(size_t)col_ndx
{
    return m_table->average_double(col_ndx);
}

-(BOOL)_addColumns
{
    return YES; // Must be overridden in typed table classes.
}

#ifdef TIGHTDB_DEBUG
-(void)verify
{
    m_table->Verify();
}
#endif
@end


@implementation TightdbColumnProxy
@synthesize table = _table, column = _column;
-(id)initWithTable:(TightdbTable*)table column:(size_t)column
{
    self = [super init];
    if (self) {
        _table = table;
        _column = column;
    }
    return self;
}
-(void)clear
{
    _table = nil;
}
@end

@implementation TightdbColumnProxy_Bool
-(size_t)find:(BOOL)value
{
    return [self.table findBool:self.column value:value];
}
@end

@implementation TightdbColumnProxy_Int
-(size_t)find:(int64_t)value
{
    return [self.table findInt:self.column value:value];
}
-(int64_t)minimum
{
    return [self.table minimumWithIntColumn:self.column];
}
-(int64_t)maximum
{
    return [self.table maximumWithIntColumn:self.column];
}
-(int64_t)sum
{
    return [self.table sumWithIntColumn:self.column];
}
-(double)average
{
    return [self.table averageWithIntColumn:self.column];
}
@end

@implementation TightdbColumnProxy_Float
-(size_t)find:(float)value
{
    return [self.table findFloat:self.column value:value];
}
-(float)minimum
{
    return [self.table minimumWithFloatColumn:self.column];
}
-(float)maximum
{
    return [self.table maximumWithFloatColumn:self.column];
}
-(double)sum
{
    return [self.table sumWithFloatColumn:self.column];
}
-(double)average
{
    return [self.table averageWithFloatColumn:self.column];
}
@end

@implementation TightdbColumnProxy_Double
-(size_t)find:(double)value
{
    return [self.table findDouble:self.column value:value];
}
-(double)minimum
{
    return [self.table minimumWithDoubleColumn:self.column];
}
-(double)maximum
{
    return [self.table maximumWithDoubleColumn:self.column];
}
-(double)sum
{
    return [self.table sumWithDoubleColumn:self.column];
}
-(double)average
{
    return [self.table averageWithDoubleColumn:self.column];
}
@end

@implementation TightdbColumnProxy_String
-(size_t)find:(NSString*)value
{
    return [self.table findString:self.column value:value];
}
@end

@implementation TightdbColumnProxy_Binary
-(size_t)find:(TightdbBinary*)value
{
    return [self.table findBinary:self.column value:value];
}
@end

@implementation TightdbColumnProxy_Date
-(size_t)find:(time_t)value
{
    return [self.table findDate:self.column value:value];
}
@end

@implementation TightdbColumnProxy_Subtable
@end

@implementation TightdbColumnProxy_Mixed
-(size_t)find:(TightdbMixed*)value
{
    return [self.table findMixed:self.column value:value];
}
@end

