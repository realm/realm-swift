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
-(BOOL)addColumnWithName:(NSString*)name andType:(TightdbType)type
{
    return [self addColumnWithName:name andType:type error:nil];
}

-(BOOL)addColumnWithName:(NSString*)name andType:(TightdbType)type error:(NSError* __autoreleasing*)error
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

-(TightdbDescriptor*)subdescriptorForColumnWithIndex:(NSUInteger)col_ndx
{
    return [self subdescriptorForColumnWithIndex:col_ndx error:nil];
}

-(TightdbDescriptor*)subdescriptorForColumnWithIndex:(NSUInteger)col_ndx error:(NSError* __autoreleasing*)error
{
    TIGHTDB_EXCEPTION_ERRHANDLER(
        tightdb::DescriptorRef subdesc = m_desc->get_subdescriptor(col_ndx);
        return [TightdbDescriptor descWithDesc:subdesc.get() readOnly:m_read_only error:error];,
        nil);
}

-(NSUInteger)columnCount
{
    return m_desc->get_column_count();
}
-(TightdbType)columnTypeOfColumn:(NSUInteger)colIndex
{
    return (TightdbType)m_desc->get_column_type(colIndex);
}
-(NSString*)columnNameOfColumn:(NSUInteger)colIndex
{
    return to_objc_string(m_desc->get_column_name(colIndex));
}
-(NSUInteger)indexOfColumnWithName:(NSString *)name
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
        m_table = [query originTable];
        m_read_only = [m_table isReadOnly];
    }
    return self;
}

-(TightdbTable*)originTable // Synthesize property
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

-(TightdbCursor*)rowAtIndex:(NSUInteger)ndx
{
    // The cursor constructor checks the index is in bounds. However, getSourceIndex should
    // not be called with illegal index.

    if (ndx >= self.rowCount)
        return nil;

    return [[TightdbCursor alloc] initWithTable:m_table ndx:[self rowIndexInOriginTableForRowAtIndex:ndx]];
}

-(NSUInteger)rowCount
{
    return m_view->size();
}

-(NSUInteger)columnCount
{
    return m_view->get_column_count();
}

-(TightdbType)columnTypeOfColumn:(NSUInteger)colNdx
{
    TIGHTDB_EXCEPTION_HANDLER_COLUMN_INDEX_VALID(colNdx);
    return TightdbType(m_view->get_column_type(colNdx));
}
-(void)sortUsingColumnWithIndex:(NSUInteger)colIndex
{
    [self sortUsingColumnWithIndex:colIndex inOrder:tightdb_ascending];
}
-(void)sortUsingColumnWithIndex:(NSUInteger)colIndex  inOrder: (TightdbSortOrder)order
{
    TightdbType columnType = [self columnTypeOfColumn:colIndex];
    
    if(columnType != tightdb_Int && columnType != tightdb_Bool && columnType != tightdb_Date) {
        NSException* exception = [NSException exceptionWithName:@"tightdb:sort_on_column_with_type_not_supported"
                                                         reason:@"Sort is currently only supported on Integer, Boolean and Date columns."
                                                       userInfo:[NSMutableDictionary dictionary]];
        [exception raise];
    }
    
    try {
        m_view->sort(colIndex, order == 0);
    } catch(std::exception& ex) {
        NSException* exception = [NSException exceptionWithName:@"tightdb:core_exception"
                                                         reason:[NSString stringWithUTF8String:ex.what()]
                                                       userInfo:[NSMutableDictionary dictionary]];
        [exception raise];
    }
}

-(BOOL)boolInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return m_view->get_bool(colIndex, rowIndex);
}
-(time_t)dateInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return m_view->get_datetime(colIndex, rowIndex).get_datetime();
}
-(double)doubleInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return m_view->get_double(colIndex, rowIndex);
}
-(float)floatInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return m_view->get_float(colIndex, rowIndex);
}
-(int64_t)intInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return m_view->get_int(colIndex, rowIndex);
}
-(TightdbMixed *)mixedInColumnWithIndex:(NSUInteger)colNdx atRowIndex:(NSUInteger)rowIndex
{
    tightdb::Mixed mixed = m_view->get_mixed(colNdx, rowIndex);
    if (mixed.get_type() != tightdb::type_Table)
        return [TightdbMixed mixedWithNativeMixed:mixed];
    
    tightdb::TableRef table = m_view->get_subtable(colNdx, rowIndex);
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

-(NSString*)stringInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return to_objc_string(m_view->get_string(colIndex, rowIndex));
}


-(void) removeRowAtIndex:(NSUInteger)ndx
{
    m_view->remove(ndx);
}
-(void)removeAllRows
{
    if (m_read_only) {
        NSException* exception = [NSException exceptionWithName:@"tightdb:table_view_is_read_only"
                                                         reason:@"You tried to modify an immutable tableview"
                                                       userInfo:[NSMutableDictionary dictionary]];
        [exception raise];
    }
    
    m_view->clear();
}
-(NSUInteger)rowIndexInOriginTableForRowAtIndex:(NSUInteger)rowIndex
{
    return m_view->get_source_ndx(rowIndex);
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
    if (state->state < self.rowCount) {
        [((TightdbCursor*)*stackbuf) TDBSetNdx:[self rowIndexInOriginTableForRowAtIndex:state->state]];
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
    if (state->state < self.rowCount) {
        [((TightdbCursor*)*stackbuf) TDBSetNdx:state->state];
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
-(BOOL)hasSameDescriptorAs:(__unsafe_unretained Class)class_obj
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

-(NSUInteger)columnCount
{
    return m_table->get_column_count();
}
-(NSString*)columnNameOfColumn:(NSUInteger)ndx
{
    return to_objc_string(m_table->get_column_name(ndx));
}
-(NSUInteger)indexOfColumnWithName:(NSString *)name
{
    return m_table->get_column_index(ObjcStringAccessor(name));
}
-(TightdbType)columnTypeOfColumn:(NSUInteger)ndx
{
    return TightdbType(m_table->get_column_type(ndx));
}
-(TightdbDescriptor*)descriptor
{
    return [self descriptorWithError:nil];
}
-(TightdbDescriptor*)descriptorWithError:(NSError* __autoreleasing*)error
{
    tightdb::DescriptorRef desc = m_table->get_descriptor();
    BOOL read_only = m_read_only || m_table->has_shared_type();
    return [TightdbDescriptor descWithDesc:desc.get() readOnly:read_only error:error];
}

-(NSUInteger)rowCount //Synthesize property
{
    return m_table->size();
}

-(TightdbCursor*)addEmptyRow
{
    return [[TightdbCursor alloc] initWithTable:self ndx:[self TDBAddEmptyRow]];
}

-(TightdbCursor*)insertEmptyRowAtIndex:(NSUInteger)ndx
{
    [self TDBInsertRow:ndx];
    return [[TightdbCursor alloc] initWithTable:self ndx:ndx];
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


-(NSUInteger)TDBAddEmptyRow
{
    return [self TDBAddEmptyRows:1];
}

-(NSUInteger)TDBAddEmptyRows:(NSUInteger)num_rows
{
    // TODO: Use a macro or a function for error handling

    if(m_read_only) {
        NSException* exception = [NSException exceptionWithName:@"tightdb:table_is_read_only"
                                                         reason:@"You tried to modify a table in read only mode"
                                                       userInfo:[NSMutableDictionary dictionary]];
        [exception raise];
    }

    NSUInteger index;
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


-(TightdbCursor*)rowAtIndex:(NSUInteger)ndx
{
    // initWithTable checks for illegal index.

    return [[TightdbCursor alloc] initWithTable:self ndx:ndx];
}

-(TightdbCursor*)lastRow //FIXME must return nil, of table is empty. Consider property
{
    return [[TightdbCursor alloc] initWithTable:self ndx:self.rowCount-1];
}

-(TightdbCursor*)firstRow //FIXME must return nil, of table is empty. Consider property
{
    return [[TightdbCursor alloc] initWithTable:self ndx:0];
}

-(TightdbCursor*)insertRowAtIndex:(NSUInteger)ndx
{
    [self insertEmptyRowAtIndex:ndx];
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



-(BOOL)removeAllRows
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


-(BOOL)boolInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return m_table->get_bool(colIndex, rowIndex);
}

-(int64_t)intInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return m_table->get_int(colIndex, rowIndex);
}

-(float)floatInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return m_table->get_float(colIndex, rowIndex);
}

-(double)doubleInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return m_table->get_double(colIndex, rowIndex);
}

-(NSString*)stringInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return to_objc_string(m_table->get_string(colIndex, rowIndex));
}

-(TightdbBinary*)binaryInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return [[TightdbBinary alloc] initWithBinary:m_table->get_binary(colIndex, rowIndex)];
}

-(time_t)dateInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return m_table->get_datetime(colIndex, rowIndex).get_datetime();
}

-(TightdbTable*)tableInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    tightdb::DataType type = m_table->get_column_type(colIndex);
    if (type != tightdb::type_Table)
        return nil;
    tightdb::TableRef table = m_table->get_subtable(colIndex, rowIndex);
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
-(id)tableInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex asTableClass:(__unsafe_unretained Class)tableClass
{
    tightdb::DataType type = m_table->get_column_type(colIndex);
    if (type != tightdb::type_Table)
        return nil;
    tightdb::TableRef table = m_table->get_subtable(colIndex, rowIndex);
    if (!table)
        return nil;
    TightdbTable* table_2 = [[tableClass alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table))
        return nil;
    [table_2 setNativeTable:table.get()];
    [table_2 setParent:self];
    [table_2 setReadOnly:m_read_only];
    if (![table_2 _checkType])
        return nil;
    return table_2;
}

-(TightdbMixed*)mixedInColumnWithIndex:(NSUInteger)colNdx atRowIndex:(NSUInteger)rowIndex
{
    tightdb::Mixed mixed = m_table->get_mixed(colNdx, rowIndex);
    if (mixed.get_type() != tightdb::type_Table)
        return [TightdbMixed mixedWithNativeMixed:mixed];

    tightdb::TableRef table = m_table->get_subtable(colNdx, rowIndex);
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


-(void) setBool:(BOOL)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
{
    TIGHTDB_EXCEPTION_HANDLER_SETTERS(
        m_table->set_bool(col_ndx, row_ndx, value);,
        tightdb_Bool);
}

-(void)setInt:(int64_t)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
{
    TIGHTDB_EXCEPTION_HANDLER_SETTERS(
        m_table->set_int(col_ndx, row_ndx, value);,
        tightdb_Int);
}

-(void)setFloat:(float)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
{
    TIGHTDB_EXCEPTION_HANDLER_SETTERS(
        m_table->set_float(col_ndx, row_ndx, value);,
        tightdb_Float);
}

-(void)setDouble:(double)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
{
    TIGHTDB_EXCEPTION_HANDLER_SETTERS(
        m_table->set_double(col_ndx, row_ndx, value);,
        tightdb_Double);
}

-(void)setString:(NSString*)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
{
    TIGHTDB_EXCEPTION_HANDLER_SETTERS(
        m_table->set_string(col_ndx, row_ndx, ObjcStringAccessor(value));,
        tightdb_String);
}

-(void)setBinary:(TightdbBinary*)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
{
    TIGHTDB_EXCEPTION_HANDLER_SETTERS(
        m_table->set_binary(col_ndx, row_ndx, [value getNativeBinary]);,
        tightdb_Binary);
}

-(void)setDate:(time_t)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
{
    TIGHTDB_EXCEPTION_HANDLER_SETTERS(
        m_table->set_datetime(col_ndx, row_ndx, value);,
        tightdb_Date);
}

-(void)setTable:(TightdbTable*)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
{
    // TODO: Use core method for checking the equality of two table specs. Even in the typed interface
    // the user might add columns (_checkType for typed and spec against spec for dynamic).

    TIGHTDB_EXCEPTION_HANDLER_SETTERS(
        m_table->set_subtable(col_ndx, row_ndx, &[value getNativeTable]);,
        tightdb_Table);
}

-(void)setMixed:(TightdbMixed*)value inColumnWithIndex:(NSUInteger)col_ndx atRowIndex:(NSUInteger)row_ndx
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


-(BOOL)TDBInsertBool:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(BOOL)value
{
    return [self TDBInsertBool:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)TDBInsertBool:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(BOOL)value error:(NSError* __autoreleasing*)error
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

-(BOOL)TDBInsertInt:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(int64_t)value
{
    return [self TDBInsertInt:col_ndx ndx:ndx value:value error:nil];
}


-(BOOL)TDBInsertInt:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(int64_t)value error:(NSError* __autoreleasing*)error
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

-(BOOL)TDBInsertFloat:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(float)value
{
    return [self TDBInsertFloat:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)TDBInsertFloat:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(float)value error:(NSError* __autoreleasing*)error
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

-(BOOL)TDBInsertDouble:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(double)value
{
    return [self TDBInsertDouble:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)TDBInsertDouble:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(double)value error:(NSError* __autoreleasing*)error
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

-(BOOL)TDBInsertString:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(NSString*)value
{
    return [self TDBInsertString:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)TDBInsertString:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(NSString*)value error:(NSError* __autoreleasing*)error
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

-(BOOL)TDBInsertBinary:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(TightdbBinary*)value
{
    return [self TDBInsertBinary:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)TDBInsertBinary:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(TightdbBinary*)value error:(NSError* __autoreleasing*)error
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

-(BOOL)TDBInsertBinary:(NSUInteger)col_ndx ndx:(NSUInteger)ndx data:(const char*)data size:(size_t)size
{
    return [self TDBInsertBinary:col_ndx ndx:ndx data:data size:size error:nil];
}

-(BOOL)TDBInsertBinary:(NSUInteger)col_ndx ndx:(NSUInteger)ndx data:(const char*)data size:(size_t)size error:(NSError* __autoreleasing*)error
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

-(BOOL)TDBInsertDate:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(time_t)value
{
    return [self TDBInsertDate:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)TDBInsertDate:(NSUInteger)col_ndx ndx:(NSUInteger)ndx value:(time_t)value error:(NSError* __autoreleasing*)error
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

-(BOOL)TDBInsertDone
{
    return [self TDBInsertDoneWithError:nil];
}

-(BOOL)TDBInsertDoneWithError:(NSError* __autoreleasing*)error
{
    // FIXME: This method should probably not take an error argument.
    TIGHTDB_EXCEPTION_ERRHANDLER(m_table->insert_done();, NO);
    return YES;
}




-(BOOL)TDBInsertSubtable:(NSUInteger)col_ndx ndx:(NSUInteger)row_ndx
{
    return [self TDBInsertSubtable:col_ndx ndx:row_ndx error:nil];
}

-(BOOL)TDBInsertSubtable:(NSUInteger)col_ndx ndx:(NSUInteger)row_ndx error:(NSError* __autoreleasing*)error
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

-(BOOL)TDBInsertSubtableCopy:(NSUInteger)col_ndx row:(NSUInteger)row_ndx subtable:(TightdbTable*)subtable
{
    return [self TDBInsertSubtableCopy:col_ndx row:row_ndx subtable:subtable error:nil];
}


-(BOOL)TDBInsertSubtableCopy:(NSUInteger)col_ndx row:(NSUInteger)row_ndx subtable:(TightdbTable*)subtable error:(NSError* __autoreleasing*)error
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




-(TightdbType)mixedTypeForColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return TightdbType(m_table->get_mixed_type(colIndex, rowIndex));
}

-(BOOL)TDBInsertMixed:(NSUInteger)col_ndx ndx:(NSUInteger)row_ndx value:(TightdbMixed*)value
{
    return [self TDBInsertMixed:col_ndx ndx:row_ndx value:value error:nil];
}

-(BOOL)TDBInsertMixed:(NSUInteger)col_ndx ndx:(NSUInteger)row_ndx value:(TightdbMixed*)value error:(NSError* __autoreleasing*)error
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


-(NSUInteger)addColumnWithName:(NSString*)name andType:(TightdbType)type
{
    return [self addColumnWithType:type andName:name error:nil];
}

-(NSUInteger)addColumnWithType:(TightdbType)type andName:(NSString*)name error:(NSError* __autoreleasing*)error
{
    TIGHTDB_EXCEPTION_ERRHANDLER(
        return m_table->add_column(tightdb::DataType(type), ObjcStringAccessor(name));,
        0);
}

-(void)removeColumnWithIndex:(NSUInteger)columnIndex
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

-(NSUInteger)findRowIndexWithBool:(BOOL)aBool inColumnWithIndex:(NSUInteger)colIndex
{
    return m_table->find_first_bool(colIndex, aBool);
}
-(NSUInteger)findRowIndexWithInt:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex
{
    return m_table->find_first_int(colIndex, anInt);
}
-(NSUInteger)findRowIndexWithFloat:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex
{
    return m_table->find_first_float(colIndex, aFloat);
}
-(NSUInteger)findRowIndexWithDouble:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex
{
    return m_table->find_first_double(colIndex, aDouble);
}
-(NSUInteger)findRowIndexWithString:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex
{
    return m_table->find_first_string(colIndex, ObjcStringAccessor(aString));
}
-(NSUInteger)findRowIndexWithBinary:(TightdbBinary *)aBinary inColumnWithIndex:(NSUInteger)colIndex
{
    return m_table->find_first_binary(colIndex, [aBinary getNativeBinary]);
}
-(NSUInteger)findRowIndexWithDate:(time_t)aDate inColumnWithIndex:(NSUInteger)colIndex
{
    return m_table->find_first_datetime(colIndex, aDate);
}
-(NSUInteger)findRowIndexWithMixed:(TightdbMixed *)aMixed inColumnWithIndex:(NSUInteger)colIndex
{
    static_cast<void>(colIndex);
    static_cast<void>(aMixed);
    [NSException raise:@"NotImplemented" format:@"Not implemented"];
    // FIXME: Implement this!
//    return _table->find_first_mixed(col_ndx, [value getNativeMixed]);
    return 0;
}

-(TightdbView*)findAllRowsWithBool:(BOOL)aBool inColumnWithIndex:(NSUInteger)colIndex
{
    tightdb::TableView view = m_table->find_all_bool(colIndex, aBool);
    return [TightdbView viewWithTable:self andNativeView:view];
}
-(TightdbView*)findAllRowsWithInt:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex
{
    tightdb::TableView view = m_table->find_all_int(colIndex, anInt);
    return [TightdbView viewWithTable:self andNativeView:view];
}
-(TightdbView*)findAllRowsWithFloat:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex
{
    tightdb::TableView view = m_table->find_all_float(colIndex, aFloat);
    return [TightdbView viewWithTable:self andNativeView:view];
}
-(TightdbView*)findAllRowsWithDouble:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex
{
    tightdb::TableView view = m_table->find_all_double(colIndex, aDouble);
    return [TightdbView viewWithTable:self andNativeView:view];
}
-(TightdbView*)findAllRowsWithString:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex
{
    tightdb::TableView view = m_table->find_all_string(colIndex, ObjcStringAccessor(aString));
    return [TightdbView viewWithTable:self andNativeView:view];
}
-(TightdbView*)findAllRowsWithBinary:(TightdbBinary *)aBinary inColumnWithIndex:(NSUInteger)colIndex
{
    tightdb::TableView view = m_table->find_all_binary(colIndex, [aBinary getNativeBinary]);
    return [TightdbView viewWithTable:self andNativeView:view];
}
-(TightdbView*)findAllRowsWithDate:(time_t)aDate inColumnWithIndex:(NSUInteger)colIndex
{
    tightdb::TableView view = m_table->find_all_datetime(colIndex, aDate);
    return [TightdbView viewWithTable:self andNativeView:view];
}
-(TightdbView*)findAllRowsWithMixed:(TightdbMixed *)aMixed inColumnWithIndex:(NSUInteger)colIndex
{
    static_cast<void>(colIndex);
    static_cast<void>(aMixed);
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

#ifdef TIGHTDB_DEBUG
-(void)verify
{
    m_table->Verify();
}
#endif
@end


@implementation TightdbColumnProxy
@synthesize table = _table, column = _column;
-(id)initWithTable:(TightdbTable*)table column:(NSUInteger)column
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
-(NSUInteger)find:(BOOL)value
{
    return [self.table findRowIndexWithBool:value inColumnWithIndex:self.column ];
}
@end

@implementation TightdbColumnProxy_Int
-(NSUInteger)find:(int64_t)value
{
    return [self.table findRowIndexWithInt:value inColumnWithIndex:self.column ];
}
-(int64_t)minimum
{
    return [self.table minIntInColumnWithIndex:self.column ];
}
-(int64_t)maximum
{
    return [self.table maxIntInColumnWithIndex:self.column ];
}
-(int64_t)sum
{
    return [self.table sumIntColumnWithIndex:self.column ];
}
-(double)average
{
    return [self.table avgIntColumnWithIndex:self.column ];
}
@end

@implementation TightdbColumnProxy_Float
-(NSUInteger)find:(float)value
{
    return [self.table findRowIndexWithFloat:value inColumnWithIndex:self.column];
}
-(float)minimum
{
    return [self.table minFloatInColumnWithIndex:self.column];
}
-(float)maximum
{
    return [self.table maxFloatInColumnWithIndex:self.column];
}
-(double)sum
{
    return [self.table sumFloatColumnWithIndex:self.column];
}
-(double)average
{
    return [self.table avgFloatColumnWithIndex:self.column];
}
@end

@implementation TightdbColumnProxy_Double
-(NSUInteger)find:(double)value
{
    return [self.table findRowIndexWithDouble:value inColumnWithIndex:self.column];
}
-(double)minimum
{
    return [self.table minDoubleInColumnWithIndex:self.column];
}
-(double)maximum
{
    return [self.table maxDoubleInColumnWithIndex:self.column];
}
-(double)sum
{
    return [self.table sumDoubleColumnWithIndex:self.column];
}
-(double)average
{
    return [self.table avgDoubleColumnWithIndex:self.column];
}
@end

@implementation TightdbColumnProxy_String
-(NSUInteger)find:(NSString*)value
{
    return [self.table findRowIndexWithString:value inColumnWithIndex:self.column];
}
@end

@implementation TightdbColumnProxy_Binary
-(NSUInteger)find:(TightdbBinary*)value
{
    return [self.table findRowIndexWithBinary:value inColumnWithIndex:self.column];
}
@end

@implementation TightdbColumnProxy_Date
-(NSUInteger)find:(time_t)value
{
    return [self.table findRowIndexWithDate:value inColumnWithIndex:self.column];
}
@end

@implementation TightdbColumnProxy_Subtable
@end

@implementation TightdbColumnProxy_Mixed
-(NSUInteger)find:(TightdbMixed*)value
{
    return [self.table findRowIndexWithMixed:value inColumnWithIndex:self.column];
}
@end

