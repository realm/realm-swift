//
//  table.mm
//  TightDB
//

#import <cstring>

#import <tightdb/table.hpp>
#import <tightdb/table_view.hpp>
#import <tightdb/lang_bind_helper.hpp>

#import <tightdb/objc/table.h>
#import <tightdb/objc/table_priv.h>
#import <tightdb/objc/query.h>
#import <tightdb/objc/query_priv.h>
#import <tightdb/objc/cursor.h>

#pragma mark BinaryData

@implementation BinaryData
{
    tightdb::BinaryData _data;
}
-(id)initWithData:(const char *)data size:(size_t)size
{
    self = [super init];
    if (self) {
        _data.pointer = data;
        _data.len = size;
    }
    return self;
}
-(id)initWithBinary:(tightdb::BinaryData)data
{
    self = [super init];
    if (self) {
        _data = data;
    }
    return self;
}
-(const char *)getData
{
    return _data.pointer;
}
-(size_t)getSize
{
    return _data.len;
}
-(BOOL)isEqual:(BinaryData *)bin
{
    return _data.compare_payload(bin->_data);
}
-(tightdb::BinaryData)getBinary
{
    return _data;
}
@end


#pragma mark - Mixed
@interface OCMixed()
@property (nonatomic) tightdb::Mixed mixed;
@property (nonatomic, strong) Table *table;
+(OCMixed *)mixedWithMixed:(tightdb::Mixed&)other;
@end
@implementation OCMixed
@synthesize mixed = _mixed;
@synthesize table = _table;

+(OCMixed *)mixedWithBool:(BOOL)value
{
    OCMixed *mixed = [[OCMixed alloc] init];
    mixed.mixed = tightdb::Mixed((bool)value);
    return mixed;
}

+(OCMixed *)mixedWithInt64:(int64_t)value
{
    OCMixed *mixed = [[OCMixed alloc] init];
    mixed.mixed = tightdb::Mixed(value);
    return mixed;
}

+(OCMixed *)mixedWithFloat:(float)value
{
    OCMixed *mixed = [[OCMixed alloc] init];
    mixed.mixed = tightdb::Mixed(value);
    return mixed;
}

+(OCMixed *)mixedWithDouble:(double)value
{
    OCMixed *mixed = [[OCMixed alloc] init];
    mixed.mixed = tightdb::Mixed(value);
    return mixed;
}

+(OCMixed *)mixedWithString:(NSString *)value
{
    OCMixed *mixed = [[OCMixed alloc] init];
    mixed.mixed = tightdb::Mixed((const char *)[value UTF8String]);
    return mixed;
}

+(OCMixed *)mixedWithBinary:(BinaryData *)value
{
    OCMixed *mixed = [[OCMixed alloc] init];
    mixed.mixed = tightdb::Mixed([value getBinary]);
    return mixed;
}

+(OCMixed *)mixedWithBinary:(const char *)data size:(size_t)size
{
    OCMixed *mixed = [[OCMixed alloc] init];
    mixed.mixed = tightdb::Mixed(tightdb::BinaryData(data, size));
    return mixed;
}

+(OCMixed *)mixedWithDate:(time_t)value
{
    OCMixed *mixed = [[OCMixed alloc] init];
    mixed.mixed = tightdb::Mixed(tightdb::Date(value));
    return mixed;
}

+(OCMixed *)mixedWithTable:(Table *)value
{
    OCMixed *mixed = [[OCMixed alloc] init];
    mixed.mixed = tightdb::Mixed(tightdb::Mixed::subtable_tag());
    mixed.table = value;
    return mixed;
}

+(OCMixed *)mixedWithMixed:(tightdb::Mixed&)value
{
    OCMixed *mixed = [[OCMixed alloc] init];
    mixed.mixed = value;
    return mixed;
}

-(BOOL)isEqual:(OCMixed *)other
{
    const tightdb::DataType type = _mixed.get_type();
    if (type != other->_mixed.get_type()) return NO;
    switch (type) {
        case tightdb::type_Bool:
            return _mixed.get_bool() == other->_mixed.get_bool();
        case tightdb::type_Int:
            return _mixed.get_int() == other->_mixed.get_int();
        case tightdb::type_Float:
            return _mixed.get_float() == other->_mixed.get_float();
        case tightdb::type_Double:
            return _mixed.get_double() == other->_mixed.get_double();
        case tightdb::type_String:
            return std::strcmp(_mixed.get_string(), other->_mixed.get_string()) == 0;
        case tightdb::type_Binary:
            return _mixed.get_binary().compare_payload(other->_mixed.get_binary());
        case tightdb::type_Date:
            return _mixed.get_date() == other->_mixed.get_date();
        case tightdb::type_Table:
            return [_table getTable] == [other->_table getTable]; // Compare table contents
        case tightdb::type_Mixed:
            TIGHTDB_ASSERT(false);
            break;
    }
    return NO;
}

-(TightdbDataType)getType
{
    return (TightdbDataType)_mixed.get_type();
}

-(BOOL)getBool
{
    return _mixed.get_bool();
}

-(int64_t)getInt
{
    return _mixed.get_int();
}

-(float)getFloat
{
    return _mixed.get_float();
}

-(double)getDouble
{
    return _mixed.get_double();
}

-(NSString *)getString
{
    return [NSString stringWithUTF8String:_mixed.get_string()];
}

-(BinaryData *)getBinary
{
    return [[BinaryData alloc] initWithBinary:_mixed.get_binary()];
}

-(time_t)getDate
{
    return _mixed.get_date();
}

-(Table *)getTable
{
    return _table;
}
@end

#pragma mark - Spec

@interface OCSpec()
@property (nonatomic) tightdb::Spec *spec;
@property (nonatomic) BOOL isOwned;
+(OCSpec *)specWithSpec:(tightdb::Spec*)other isOwned:(BOOL)isOwned;
@end
@implementation OCSpec
@synthesize spec = _spec;
@synthesize isOwned = _isOwned;


+(OCSpec *)specWithSpec:(tightdb::Spec *)other isOwned:(BOOL)isOwned
{
    OCSpec *spec = [[OCSpec alloc] init];
    if (isOwned) {
        spec.spec = new tightdb::Spec(*other);
        spec.isOwned = TRUE;
    }
    else {
        spec.spec = other;
        spec.isOwned = FALSE;
    }
    return spec;
}

// FIXME: Provide a version of this method that takes a 'const char *'. This will simplify _addColumns of MyTable.
// FIXME: Detect errors from core library
-(BOOL)addColumn:(TightdbDataType)type name:(NSString *)name
{
    _spec->add_column((tightdb::DataType)type, [name UTF8String]);
    return YES;
}

// FIXME: Detect errors from core library
-(OCSpec *)addColumnTable:(NSString *)name
{
    tightdb::Spec tmp = _spec->add_subtable_column([name UTF8String]);
    return [OCSpec specWithSpec:&tmp isOwned:TRUE];
}

// FIXME: Detect errors from core library
-(OCSpec *)getSubspec:(size_t)col_ndx
{
    tightdb::Spec tmp = _spec->get_subtable_spec(col_ndx);
    return [OCSpec specWithSpec:&tmp isOwned:TRUE];
}

-(size_t)getColumnCount
{
    return _spec->get_column_count();
}
-(TightdbDataType)getColumnType:(size_t)ndx
{
    return (TightdbDataType)_spec->get_column_type(ndx);
}
-(NSString *)getColumnName:(size_t)ndx
{
    return [NSString stringWithUTF8String:_spec->get_column_name(ndx)];
}
-(size_t)getColumnIndex:(NSString *)name
{
    return _spec->get_column_index([name UTF8String]);
}
-(void)dealloc
{
#ifdef TIGHTDB_DEBUG
    NSLog(@"OCSpec dealloc");
#endif
    if (_isOwned) delete _spec;
}


@end


#pragma mark - TableView

@interface TableView()
@property (nonatomic) tightdb::TableView *tableView;
@end
@implementation TableView
{
    Table *_table;
}
@synthesize tableView = _tableView;


-(id)initFromQuery:(Query *)query
{
    self = [super init];
    if (self) {
        _table = [query getTable];
        self.tableView = new tightdb::TableView([query getTableView]);
    }
    return self;
}

-(Table *)getTable
{
    return _table;
}

+(TableView *)tableViewWithTable:(Table *)table
{
    (void)table;
    TableView *tableView = [[TableView alloc] init];
    tableView.tableView = new tightdb::TableView(); // not longer needs table at construction
    return tableView;
}

+(TableView *)tableViewWithTableView:(tightdb::TableView)table
{
    TableView *tableView = [[TableView alloc] init];
    tableView.tableView = new tightdb::TableView(table);
    return tableView;
}

-(void)dealloc
{
#ifdef TIGHTDB_DEBUG
    NSLog(@"TableView dealloc");
#endif
    _table = nil;
    delete _tableView;
}

-(size_t)count
{
    return _tableView->size();
}
-(BOOL)isEmpty
{
    return _tableView->is_empty();
}
-(int64_t)get:(size_t)col_ndx ndx:(size_t)ndx
{
    return _tableView->get_int(col_ndx, ndx);
}
-(BOOL)getBool:(size_t)col_ndx ndx:(size_t)ndx
{
    return _tableView->get_bool(col_ndx, ndx);
}
-(time_t)getDate:(size_t)col_ndx ndx:(size_t)ndx
{
    return _tableView->get_date(col_ndx, ndx);
}
-(NSString *)getString:(size_t)col_ndx ndx:(size_t)ndx
{
    return [NSString stringWithUTF8String:_tableView->get_string(col_ndx, ndx)];
}
-(void)delete:(size_t)ndx
{
    _tableView->remove(ndx);
}
-(void)clear
{
    _tableView->clear();
}
-(size_t)getSourceNdx:(size_t)ndx
{
    return _tableView->get_source_ndx(ndx);
}

-(CursorBase *)getCursor
{
    return nil; // Has to be overridden in tightdb.h
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len
{
    (void)len;
    if(state->state == 0)
    {
        state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self);
        CursorBase *tmp = [self getCursor];
        *stackbuf = tmp;
    }
    if (state->state < [self count]) {
        [((CursorBase *)*stackbuf) setNdx:[self getSourceNdx:state->state]];
        state->itemsPtr = stackbuf;
        state->state++;
    } else {
        *stackbuf = nil;
        state->itemsPtr = nil;
        state->mutationsPtr = nil;
        return 0;
    }
    return 1;
}

@end


#pragma mark - Table

@implementation Table
{
    id _parent;
    BOOL _readOnly;
}
@synthesize table = _table;

-(id)init
{
    self = [super init];
    if (self) {
        _readOnly = NO;
        _table = tightdb::Table::create(); // FIXME: May throw
    }
    return self;
}

-(id)_initRaw
{
    self = [super init];
    return self;
}

-(void)updateFromSpec
{
    static_cast<tightdb::Table *>(&*self.table)->update_from_spec();
}

-(BOOL)_checkType
{
    return YES;
    // Dummy - must be overridden in tightdb.h - Check if spec matches the macro definitions
}

-(CursorBase *)getCursor
{
    return nil; // Has to be overridden in tightdb.h
}
-(void)clearCursor
{
    // Dummy - must be overridden in tightdb.h
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len
{
    (void)len;
    if(state->state == 0)
    {
        state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self);
        CursorBase *tmp = [self getCursor];
        *stackbuf = tmp;
    }
    if (state->state < [self count]) {
        [((CursorBase *)*stackbuf) setNdx:state->state];
        state->itemsPtr = stackbuf;
        state->state++;
    } else {
        *stackbuf = nil;
        state->itemsPtr = nil;
        state->mutationsPtr = nil;
        [self clearCursor];
        return 0;
    }
    return 1;
}

-(tightdb::Table &)getTable
{
    return *_table;
}

-(void)setParent:(id)parent
{
    _parent = parent;
}

-(void)setReadOnly:(BOOL)readOnly
{
    _readOnly = readOnly;
}

-(BOOL)isEqual:(Table *)other
{
    return *_table == *other->_table;
}

-(Table *)getSubtable:(size_t)col_ndx ndx:(size_t)ndx
{
    const tightdb::DataType t = _table->get_column_type(col_ndx);
    if (t != tightdb::type_Table && t != tightdb::type_Mixed) return nil;
    tightdb::TableRef r = _table->get_subtable(col_ndx, ndx);
    if (!r) return nil;
    Table *table = [[Table alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table)) return nil;
    [table setTable:move(r)];
    [table setParent:self];
    [table setReadOnly:_readOnly];
    return table;
}

// FIXME: Check that the specified class derives from Table.
-(id)getSubtable:(size_t)col_ndx ndx:(size_t)ndx withClass:(__unsafe_unretained Class)classObj
{
    const tightdb::DataType t = _table->get_column_type(col_ndx);
    if (t != tightdb::type_Table && t != tightdb::type_Mixed) return nil;
    tightdb::TableRef r = _table->get_subtable(col_ndx, ndx);
    if (!r) return nil;
    Table *table = [[classObj alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table)) return nil;
    [table setTable:move(r)];
    [table setParent:self];
    [table setReadOnly:_readOnly];
    if (![table _checkType]) return nil;
    return table;
}

// FIXME: Check that the specified class derives from Table.
-(BOOL)isClass:(__unsafe_unretained Class)classObj
{
    Table *table = [[classObj alloc] _initRaw];
    if (TIGHTDB_LIKELY(table)) {
        [table setTable:_table];
        [table setParent:_parent];
        [table setReadOnly:_readOnly];
        if ([table _checkType]) return YES;
    }
    return NO;
}

// FIXME: Check that the specified class derives from Table.
-(id)castClass:(__unsafe_unretained Class)classObj
{
    Table *table = [[classObj alloc] _initRaw];
    if (TIGHTDB_LIKELY(table)) {
        [table setTable:_table];
        [table setParent:_parent];
        [table setReadOnly:_readOnly];
        if (![table _checkType]) return nil;
    }
    return table;
}

-(void)dealloc
{
#ifdef TIGHTDB_DEBUG
    NSLog(@"Table dealloc");
#endif
    _parent = nil;
}

-(size_t)getColumnCount
{
    return _table->get_column_count();
}
-(NSString *)getColumnName:(size_t)ndx
{
    return [NSString stringWithUTF8String:_table->get_column_name(ndx)];
}
-(size_t)getColumnIndex:(NSString *)name
{
    return _table->get_column_index([name UTF8String]);
}
-(TightdbDataType)getColumnType:(size_t)ndx
{
    return (TightdbDataType)_table->get_column_type(ndx);
}
-(OCSpec *)getSpec
{
    tightdb::Spec& spec = _table->get_spec();
    return [OCSpec specWithSpec:&spec isOwned:FALSE];
}
-(BOOL)isEmpty
{
    return _table->is_empty();
}
-(size_t)count
{
    return _table->size();
}
-(size_t)addRow
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to add row while read only"];
    return _table->add_empty_row();
}
-(void)clear
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to clear while read only"];
    _table->clear();
}
-(void)deleteRow:(size_t)ndx
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to delete row while read only ndx: %llu", (unsigned long long)ndx];
    _table->remove(ndx);
}
-(void)popBack
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to pop back while read only"];
    _table->remove_last();
}
-(int64_t)get:(size_t)col_ndx ndx:(size_t)ndx
{
    return _table->get_int(col_ndx, ndx);
}
-(void)set:(size_t)col_ndx ndx:(size_t)ndx value:(int64_t)value
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to set while read only ColumnId: %llu", (unsigned long long)col_ndx];
    _table->set_int(col_ndx, ndx, value);
}
-(BOOL)getBool:(size_t)col_ndx ndx:(size_t)ndx
{
    return _table->get_bool(col_ndx, ndx);
}
-(void)setBool:(size_t)col_ndx ndx:(size_t)ndx value:(BOOL)value
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to set while read only ColumnId: %llu", (unsigned long long)col_ndx];
    _table->set_bool(col_ndx, ndx, value);
}
-(float)getFloat:(size_t)col_ndx ndx:(size_t)ndx
{
    return _table->get_float(col_ndx, ndx);
}
-(void)setFloat:(size_t)col_ndx ndx:(size_t)ndx value:(float)value
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to set while read only ColumnId: %llu", (unsigned long long)col_ndx];
    _table->set_float(col_ndx, ndx, value);
}
-(double)getDouble:(size_t)col_ndx ndx:(size_t)ndx
{
    return _table->get_double(col_ndx, ndx);
}
-(void)setDouble:(size_t)col_ndx ndx:(size_t)ndx value:(double)value
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to set while read only ColumnId: %llu", (unsigned long long)col_ndx];
    _table->set_double(col_ndx, ndx, value);
}
-(time_t)getDate:(size_t)col_ndx ndx:(size_t)ndx
{
    return _table->get_date(col_ndx, ndx);
}
-(void)setDate:(size_t)col_ndx ndx:(size_t)ndx value:(time_t)value
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to set while read only ColumnId: %llu", (unsigned long long)col_ndx];
    _table->set_date(col_ndx, ndx, value);
}
-(void)insertBool:(size_t)col_ndx ndx:(size_t)ndx value:(BOOL)value
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx];
    _table->insert_bool(col_ndx, ndx, value);
}
-(void)insertInt:(size_t)col_ndx ndx:(size_t)ndx value:(int64_t)value
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx];
    _table->insert_int(col_ndx, ndx, value);
}
-(void)insertFloat:(size_t)col_ndx ndx:(size_t)ndx value:(float)value
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx];
    _table->insert_float(col_ndx, ndx, value);
}
-(void)insertDouble:(size_t)col_ndx ndx:(size_t)ndx value:(double)value
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx];
    _table->insert_double(col_ndx, ndx, value);
}
-(void)insertString:(size_t)col_ndx ndx:(size_t)ndx value:(NSString *)value
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx];
    _table->insert_string(col_ndx, ndx, [value UTF8String]);
}
-(void)insertBinary:(size_t)col_ndx ndx:(size_t)ndx value:(BinaryData *)value
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx];
    _table->insert_binary(col_ndx, ndx, [value getData], [value getSize]);
}
-(void)insertBinary:(size_t)col_ndx ndx:(size_t)ndx data:(const char *)data size:(size_t)size
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx];
    _table->insert_binary(col_ndx, ndx, data, size);
}
-(void)insertDate:(size_t)col_ndx ndx:(size_t)ndx value:(time_t)value
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx];
    _table->insert_date(col_ndx, ndx, value);
}

-(void)insertDone
{
    _table->insert_done();
}

-(NSString *)getString:(size_t)col_ndx ndx:(size_t)ndx
{
    return [NSString stringWithUTF8String:_table->get_string(col_ndx, ndx)];
}

-(void)setString:(size_t)col_ndx ndx:(size_t)ndx value:(NSString *)value
{
    _table->set_string(col_ndx, ndx, [value UTF8String]);
}

-(BinaryData *)getBinary:(size_t)col_ndx ndx:(size_t)ndx
{
    return [[BinaryData alloc] initWithBinary:_table->get_binary(col_ndx, ndx)];
}

-(void)setBinary:(size_t)col_ndx ndx:(size_t)ndx value:(BinaryData *)value
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to set while read only ColumnId: %llu", (unsigned long long)col_ndx];
    _table->set_binary(col_ndx, ndx, [value getData], [value getSize]);
}

-(void)setBinary:(size_t)col_ndx ndx:(size_t)ndx data:(const char *)data size:(size_t)size
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to set while read only ColumnId: %llu", (unsigned long long)col_ndx];
    _table->set_binary(col_ndx, ndx, data, size);
}

-(size_t)getTableSize:(size_t)col_ndx ndx:(size_t)row_ndx
{
    return _table->get_subtable_size(col_ndx, row_ndx);
}

-(void)insertSubtable:(size_t)col_ndx ndx:(size_t)row_ndx
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx];
    _table->insert_subtable(col_ndx, row_ndx);
}

-(void)_insertSubtableCopy:(size_t)col_ndx row:(size_t)row_ndx subtable:(Table *)subtable
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx];
    tightdb::LangBindHelper::insert_subtable(*_table, col_ndx, row_ndx, [subtable getTable]);
}

-(void)clearSubtable:(size_t)col_ndx ndx:(size_t)row_ndx
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to clear while read only ColumnId: %llu", (unsigned long long)col_ndx];
    _table->clear_subtable(col_ndx, row_ndx);
}

-(OCMixed *)getMixed:(size_t)col_ndx ndx:(size_t)row_ndx
{
    tightdb::Mixed tmp = _table->get_mixed(col_ndx, row_ndx);
    OCMixed *mixed = [OCMixed mixedWithMixed:tmp];
    if ([mixed getType] == tightdb_Table) {
        [mixed setTable:[self getSubtable:col_ndx ndx:row_ndx]];
    }
    return mixed;
}

-(TightdbDataType)getMixedType:(size_t)col_ndx ndx:(size_t)row_ndx
{
    return (TightdbDataType)_table->get_mixed_type(col_ndx, row_ndx);
}

-(void)insertMixed:(size_t)col_ndx ndx:(size_t)row_ndx value:(OCMixed *)value
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx];
    if (value.mixed.get_type() == tightdb::type_Table && value.table) {
        tightdb::LangBindHelper::insert_mixed_subtable(*_table, col_ndx, row_ndx,
                                                       [value.table getTable]);
    }
    else {
        _table->insert_mixed(col_ndx, row_ndx, value.mixed);
    }
}
-(void)setMixed:(size_t)col_ndx ndx:(size_t)row_ndx value:(OCMixed *)value
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to set while read only ColumnId: %llu", (unsigned long long)col_ndx];
    if (value.mixed.get_type() == tightdb::type_Table && value.table) {
        tightdb::LangBindHelper::set_mixed_subtable(*_table, col_ndx, row_ndx,
                                                    [value.table getTable]);
    }
    else {
        _table->set_mixed(col_ndx, row_ndx, value.mixed);
    }
}

-(size_t)addColumn:(TightdbDataType)type name:(NSString *)name
{
    return _table->add_column((tightdb::DataType)type, [name UTF8String]);
}
-(size_t)findBool:(size_t)col_ndx value:(BOOL)value
{
    return _table->find_first_bool(col_ndx, value);
}
-(size_t)findInt:(size_t)col_ndx value:(int64_t)value
{
    return _table->find_first_int(col_ndx, value);
}
-(size_t)findFloat:(size_t)col_ndx value:(float)value
{
    return _table->find_first_float(col_ndx, value);
}
-(size_t)findDouble:(size_t)col_ndx value:(double)value
{
    return _table->find_first_double(col_ndx, value);
}
-(size_t)findString:(size_t)col_ndx value:(NSString *)value
{
    return _table->find_first_string(col_ndx, [value UTF8String]);
}
-(size_t)findBinary:(size_t)col_ndx value:(BinaryData *)value
{
    return _table->find_first_binary(col_ndx, [value getData], [value getSize]);
}
-(size_t)findDate:(size_t)col_ndx value:(time_t)value
{
    return _table->find_first_date(col_ndx, value);
}
-(size_t)findMixed:(size_t)col_ndx value:(OCMixed *)value
{
    static_cast<void>(col_ndx);
    static_cast<void>(value);
    [NSException raise:@"NotImplemented" format:@"Not implemented"];
    // FIXME: Implement this!
    // return _table->find_first_mixed(col_ndx, value);
    return 0;
}

-(TableView *)findAll:(TableView *)view column:(size_t)col_ndx value:(int64_t)value
{
    *view.tableView = _table->find_all_int(col_ndx, value);
    return view;
}

-(BOOL)hasIndex:(size_t)col_ndx
{
    return _table->has_index(col_ndx);
}
-(void)setIndex:(size_t)col_ndx
{
    _table->set_index(col_ndx);
}
-(void)optimize
{
    _table->optimize();
}

-(size_t)countInt:(size_t)col_ndx target:(int64_t)target
{
    return _table->count_int(col_ndx, target);
}
-(size_t)countFloat:(size_t)col_ndx target:(float)target
{
    return _table->count_float(col_ndx, target);
}
-(size_t)countDouble:(size_t)col_ndx target:(double)target
{
    return _table->count_double(col_ndx, target);
}
-(size_t)countString:(size_t)col_ndx target:(NSString *)target
{
    return _table->count_string(col_ndx, [target UTF8String]);
}

-(int64_t)sumInt:(size_t)col_ndx
{
    return _table->sum(col_ndx);
}
-(double)sumFloat:(size_t)col_ndx
{
    return _table->sum_float(col_ndx);
}
-(double)sumDouble:(size_t)col_ndx
{
    return _table->sum_double(col_ndx);
}

-(int64_t)maxInt:(size_t)col_ndx
{
    return _table->maximum(col_ndx);
}
-(float)maxFloat:(size_t)col_ndx
{
    return _table->maximum_float(col_ndx);
}
-(double)maxDouble:(size_t)col_ndx
{
    return _table->maximum_double(col_ndx);
}

-(int64_t)minInt:(size_t)col_ndx
{
    return _table->minimum(col_ndx);
}
-(float)minFloat:(size_t)col_ndx
{
    return _table->minimum_float(col_ndx);
}
-(double)minDouble:(size_t)col_ndx
{
    return _table->minimum_double(col_ndx);
}

-(double)avgInt:(size_t)col_ndx
{
    return _table->average(col_ndx);
}
-(double)avgFloat:(size_t)col_ndx
{
    return _table->average_float(col_ndx);
}
-(double)avgDouble:(size_t)col_ndx
{
    return _table->average_double(col_ndx);
}

-(BOOL)_addColumns
{
    return YES; // Must be overridden in typed table classes.
}

#ifdef TIGHTDB_DEBUG
-(void)verify
{
    _table->Verify();
}
#endif
@end



#pragma mark - OCColumnProxy

@implementation OCColumnProxy
@synthesize table = _table, column = _column;
-(id)initWithTable:(Table *)table column:(size_t)column
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

@implementation OCColumnProxy_Bool
-(size_t)find:(BOOL)value
{
    return [self.table findBool:self.column value:value];
}
@end

@implementation OCColumnProxy_Int
-(size_t)find:(int64_t)value
{
    return [self.table findInt:self.column value:value];
}
-(TableView *)findAll:(int64_t)value
{
    TableView *view = [TableView tableViewWithTable:self.table];
    return [self.table findAll:view column:self.column value:value];
}
-(int64_t)min
{
    return [self.table minInt:self.column];
}
-(int64_t)max
{
    return [self.table maxInt:self.column];
}
-(int64_t)sum
{
    return [self.table sumInt:self.column];
}
-(double)avg
{
    return [self.table avgInt:self.column];
}
@end

@implementation OCColumnProxy_Float
-(size_t)find:(float)value
{
    return [self.table findFloat:self.column value:value];
}
-(float)min
{
    return [self.table minFloat:self.column];
}
-(float)max
{
    return [self.table maxFloat:self.column];
}
-(double)sum
{
    return [self.table sumFloat:self.column];
}
-(double)avg
{
    return [self.table avgFloat:self.column];
}
@end

@implementation OCColumnProxy_Double
-(size_t)find:(double)value
{
    return [self.table findDouble:self.column value:value];
}
-(double)min
{
    return [self.table minDouble:self.column];
}
-(double)max
{
    return [self.table maxDouble:self.column];
}
-(double)sum
{
    return [self.table sumDouble:self.column];
}
-(double)avg
{
    return [self.table avgDouble:self.column];
}
@end

@implementation OCColumnProxy_String
-(size_t)find:(NSString *)value
{
    return [self.table findString:self.column value:value];
}
@end

@implementation OCColumnProxy_Binary
-(size_t)find:(BinaryData *)value
{
    return [self.table findBinary:self.column value:value];
}
@end

@implementation OCColumnProxy_Date
-(size_t)find:(time_t)value
{
    return [self.table findDate:self.column value:value];
}
@end

@implementation OCColumnProxy_Subtable
@end

@implementation OCColumnProxy_Mixed
-(size_t)find:(OCMixed *)value
{
    return [self.table findMixed:self.column value:value];
}
@end

