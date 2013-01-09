//
//  table.mm
//  TightDB
//

#import <cstring>

#import <tightdb/table.hpp>
#import <tightdb/table_view.hpp>

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
-(id)initWithData:(const char *)data len:(size_t)size
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


#pragma mark - Date
@implementation OCDate
{
    tightdb::Date *_date;
}
-(id)initWithDate:(time_t)d
{
    self = [super init];
    if (self) {
        _date = new tightdb::Date(d);
    }
    return self;
}
-(time_t)getDate
{
    return _date->get_date();
}
-(BOOL)isEqual:(OCDate *)other
{
    return [self getDate] == [other getDate];
}

-(void)dealloc
{
#ifdef TIGHTDB_DEBUG
    NSLog(@"OCDate dealloc");
#endif
    delete _date;
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

+(OCMixed *)mixedWithMixed:(tightdb::Mixed&)other
{
    OCMixed *mixed = [[OCMixed alloc] init];

    mixed.mixed = other;

    return mixed;
}
+(OCMixed *)mixedWithTable:(Table *)table
{
    OCMixed *mixed = [[OCMixed alloc] init];

    mixed.mixed = tightdb::Mixed(tightdb::Mixed::subtable_tag());
    mixed.table = table;
    return mixed;
}

+(OCMixed *)mixedWithBool:(BOOL)value
{
    OCMixed *mixed = [[OCMixed alloc] init];

    mixed.mixed = tightdb::Mixed((bool)value);

    return mixed;
}

+(OCMixed *)mixedWithDate:(OCDate *)date
{
    OCMixed *mixed = [[OCMixed alloc] init];

    mixed.mixed = tightdb::Mixed(tightdb::Date([date getDate]));

    return mixed;
}

+(OCMixed *)mixedWithInt64:(int64_t)value
{
    OCMixed *mixed = [[OCMixed alloc] init];

    mixed.mixed = tightdb::Mixed(value);

    return mixed;
}

+(OCMixed *)mixedWithString:(NSString *)string
{
    OCMixed *mixed = [[OCMixed alloc] init];

    mixed.mixed = tightdb::Mixed((const char *)[string UTF8String]);

    return mixed;
}

+(OCMixed *)mixedWithBinary:(BinaryData *)data
{
    OCMixed *mixed = [[OCMixed alloc] init];

    mixed.mixed = tightdb::Mixed([data getBinary]);

    return mixed;
}

+(OCMixed *)mixedWithBinary:(const char*)value length:(size_t)length
{
    OCMixed *mixed = [[OCMixed alloc] init];

    mixed.mixed = tightdb::Mixed(tightdb::BinaryData(value, length));

    return mixed;
}

-(BOOL)isEqual:(OCMixed *)other
{
    const tightdb::ColumnType type = _mixed.get_type();
    if (type != other->_mixed.get_type()) return NO;
    switch (type) {
        case tightdb::COLUMN_TYPE_BOOL:
            return _mixed.get_bool() == other->_mixed.get_bool();
        case tightdb::COLUMN_TYPE_INT:
            return _mixed.get_int() == other->_mixed.get_int();
        case tightdb::COLUMN_TYPE_STRING:
            return std::strcmp(_mixed.get_string(), other->_mixed.get_string()) == 0;
        case tightdb::COLUMN_TYPE_BINARY:
            return _mixed.get_binary().compare_payload(other->_mixed.get_binary());
        case tightdb::COLUMN_TYPE_DATE:
            return _mixed.get_date() == other->_mixed.get_date();
        case tightdb::COLUMN_TYPE_TABLE:
            return [_table getTable] == [other->_table getTable]; // Compare table contents
            break;
        default:
            TIGHTDB_ASSERT(false);
            break;
    }
    return NO;
}

-(TightdbColumnType)getType
{
    return (TightdbColumnType)_mixed.get_type();
}
-(int64_t)getInt
{
    return _mixed.get_int();
}
-(BOOL)getBool
{
    return _mixed.get_bool();
}

-(OCDate *)getDate
{
    return [[OCDate alloc] initWithDate:_mixed.get_date()];
}

-(NSString *)getString
{
    return [NSString stringWithUTF8String:_mixed.get_string()];
}

-(BinaryData *)getBinary
{
    return [[BinaryData alloc] initWithBinary:_mixed.get_binary()];
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
-(BOOL)addColumn:(TightdbColumnType)type name:(NSString *)name
{
    _spec->add_column((tightdb::ColumnType)type, [name UTF8String]);
    return YES;
}

// FIXME: Detect errors from core library
-(OCSpec *)addColumnTable:(NSString *)name
{
    tightdb::Spec tmp = _spec->add_subtable_column([name UTF8String]);
    return [OCSpec specWithSpec:&tmp isOwned:TRUE];
}

// FIXME: Detect errors from core library
-(OCSpec *)getSpec:(size_t)columnId
{
    tightdb::Spec tmp = _spec->get_subtable_spec(columnId);
    return [OCSpec specWithSpec:&tmp isOwned:TRUE];
}

-(size_t)getColumnCount
{
    return _spec->get_column_count();
}
-(TightdbColumnType)getColumnType:(size_t)ndx
{
    return (TightdbColumnType)_spec->get_column_type(ndx);
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
-(int64_t)get:(size_t)columnId ndx:(size_t)ndx
{
    return _tableView->get_int(columnId, ndx);
}
-(BOOL)getBool:(size_t)columnId ndx:(size_t)ndx
{
    return _tableView->get_bool(columnId, ndx);
}
-(time_t)getDate:(size_t)columnId ndx:(size_t)ndx
{
    return _tableView->get_date(columnId, ndx);
}
-(NSString *)getString:(size_t)columnId ndx:(size_t)ndx
{
    return [NSString stringWithUTF8String:_tableView->get_string(columnId, ndx)];
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
        _table = tightdb::Table::create();
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

-(Table *)getSubtable:(size_t)columnId ndx:(size_t)ndx
{
    const tightdb::ColumnType t = _table->get_column_type(columnId);
    if (t != tightdb::COLUMN_TYPE_TABLE && t != tightdb::COLUMN_TYPE_MIXED) return nil;
    tightdb::TableRef r = _table->get_subtable(columnId, ndx);
    if (!r) return nil;
    Table *table = [[Table alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table)) return nil;
    [table setTable:move(r)];
    [table setParent:self];
    [table setReadOnly:_readOnly];
    return table;
}

// FIXME: Check that the specified class derives from Table.
-(id)getSubtable:(size_t)columnId ndx:(size_t)ndx withClass:(__unsafe_unretained Class)classObj
{
    const tightdb::ColumnType t = _table->get_column_type(columnId);
    if (t != tightdb::COLUMN_TYPE_TABLE && t != tightdb::COLUMN_TYPE_MIXED) return nil;
    tightdb::TableRef r = _table->get_subtable(columnId, ndx);
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
-(TightdbColumnType)getColumnType:(size_t)ndx
{
    return (TightdbColumnType)_table->get_column_type(ndx);
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
-(int64_t)get:(size_t)columnId ndx:(size_t)ndx
{
    return _table->get_int(columnId, ndx);
}
-(void)set:(size_t)columnId ndx:(size_t)ndx value:(int64_t)value
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to set while read only ColumnId: %llu", (unsigned long long)columnId];
    _table->set_int(columnId, ndx, value);
}
-(BOOL)getBool:(size_t)columnId ndx:(size_t)ndx
{
    return _table->get_bool(columnId, ndx);
}
-(void)setBool:(size_t)columnId ndx:(size_t)ndx value:(BOOL)value
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to set while read only ColumnId: %llu", (unsigned long long)columnId];
    _table->set_bool(columnId, ndx, value);
}
-(time_t)getDate:(size_t)columnId ndx:(size_t)ndx
{
    return _table->get_date(columnId, ndx);
}
-(void)setDate:(size_t)columnId ndx:(size_t)ndx value:(time_t)value
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to set while read only ColumnId: %llu", (unsigned long long)columnId];
    _table->set_date(columnId, ndx, value);
}
-(void)insertInt:(size_t)columnId ndx:(size_t)ndx value:(int64_t)value
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)columnId];
    _table->insert_int(columnId, ndx, value);
}
-(void)insertBool:(size_t)columnId ndx:(size_t)ndx value:(BOOL)value
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)columnId];
    _table->insert_bool(columnId, ndx, value);
}
-(void)insertDate:(size_t)columnId ndx:(size_t)ndx value:(time_t)value
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)columnId];
    _table->insert_date(columnId, ndx, value);
}
-(void)insertString:(size_t)columnId ndx:(size_t)ndx value:(NSString *)value
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)columnId];
    _table->insert_string(columnId, ndx, [value UTF8String]);
}
-(void)insertBinary:(size_t)columnId ndx:(size_t)ndx value:(void *)value len:(size_t)len
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)columnId];
    _table->insert_binary(columnId, ndx, (const char*)value, len);
}

-(void)insertDone
{
    _table->insert_done();
}

-(NSString *)getString:(size_t)columnId ndx:(size_t)ndx
{
    return [NSString stringWithUTF8String:_table->get_string(columnId, ndx)];
}

-(void)setString:(size_t)columnId ndx:(size_t)ndx value:(NSString *)value
{
    _table->set_string(columnId, ndx, [value UTF8String]);
}

-(BinaryData *)getBinary:(size_t)columnId ndx:(size_t)ndx
{
    return [[BinaryData alloc] initWithBinary:_table->get_binary(columnId, ndx)];
}

-(void)setBinary:(size_t)columnId ndx:(size_t)ndx value:(void *)value len:(size_t)len
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to set while read only ColumnId: %llu", (unsigned long long)columnId];
    _table->set_binary(columnId, ndx, (const char*)value, len);
}

-(size_t)getTableSize:(size_t)columnId ndx:(size_t)ndx
{
    return _table->get_subtable_size(columnId, ndx);
}

-(void)insertSubtable:(size_t)columnId ndx:(size_t)ndx
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)columnId];
    _table->insert_subtable(columnId, ndx);
}

-(void)_insertSubtableCopy:(size_t)col_ndx row_ndx:(size_t)row_ndx subtable:(Table *)subtable
{
    [self insertSubtable:col_ndx ndx:row_ndx];
    /* FIXME: Perform table copying here, but only if 'subtable' is not 'nil'. */
    (void)subtable;
}

-(void)clearTable:(size_t)columnId ndx:(size_t)ndx
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to clear while read only ColumnId: %llu", (unsigned long long)columnId];
    _table->clear_subtable(columnId, ndx);
}

-(OCMixed *)getMixed:(size_t)columnId ndx:(size_t)ndx
{
    tightdb::Mixed tmp = _table->get_mixed(columnId, ndx);
    OCMixed *mixed = [OCMixed mixedWithMixed:tmp];
    if ([mixed getType] == TIGHTDB_COLUMN_TYPE_TABLE) {
        [mixed setTable:[self getSubtable:columnId ndx:ndx]];
    }
    return mixed;
}

-(TightdbColumnType)getMixedType:(size_t)columnId ndx:(size_t)ndx
{
    return (TightdbColumnType)_table->get_mixed_type(columnId, ndx);
}

-(void)insertMixed:(size_t)columnId ndx:(size_t)ndx value:(OCMixed *)value
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)columnId];
    _table->insert_mixed(columnId, ndx, value.mixed);
    // FIXME: Insert copy of subtable if type is table
}
-(void)setMixed:(size_t)columnId ndx:(size_t)ndx value:(OCMixed *)value
{
    if (_readOnly)
        [NSException raise:@"Table is read only" format:@"Tried to set while read only ColumnId: %llu", (unsigned long long)columnId];
    _table->set_mixed(columnId, ndx, value.mixed);
    // FIXME: Insert copy of subtable if type is table
}

-(size_t)addColumn:(TightdbColumnType)type name:(NSString *)name
{
    return _table->add_column((tightdb::ColumnType)type, [name UTF8String]);
}
-(size_t)findBool:(size_t)columnId value:(BOOL)value
{
    return _table->find_first_bool(columnId, value);
}
-(size_t)findInt:(size_t)columnId value:(int64_t)value
{
    return _table->find_first_int(columnId, value);
}
-(size_t)findString:(size_t)columnId value:(NSString *)value
{
    return _table->find_first_string(columnId, [value UTF8String]);
}
-(size_t)findBinary:(size_t)columnId value:(BinaryData *)value
{
    return _table->find_first_binary(columnId, [value getData], [value getSize]);
}
-(size_t)findDate:(size_t)columnId value:(time_t)value
{
    return _table->find_first_date(columnId, value);
}
-(size_t)findMixed:(size_t)columnId value:(OCMixed *)value
{
    static_cast<void>(columnId);
    static_cast<void>(value);
    [NSException raise:@"NotImplemented" format:@"Not implemented"];
    // FIXME: Implement this!
    // return _table->find_first_mixed(columnId, value);
    return 0;
}

-(TableView *)findAll:(TableView *)view column:(size_t)columnId value:(int64_t)value
{
    *view.tableView = _table->find_all_int(columnId, value);
    return view;
}

-(BOOL)hasIndex:(size_t)columnId
{
    return _table->has_index(columnId);
}
-(void)setIndex:(size_t)columnId
{
    _table->set_index(columnId);
}
-(void)optimize
{
    _table->optimize();
}

-(size_t)countInt:(size_t)columnId target:(int64_t)target
{
    return _table->count_int(columnId, target);
}

-(size_t)countString:(size_t)columnId target:(NSString *)target
{
    return _table->count_string(columnId, [target UTF8String]);
}

-(int64_t)sum:(size_t)columnId
{
    return _table->sum(columnId);
}

-(int64_t)maximum:(size_t)columnId
{
    return _table->maximum(columnId);
}

-(int64_t)minimum:(size_t)columnId
{
    return _table->minimum(columnId);
}

-(double)average:(size_t)columnId
{
    return _table->average(columnId);
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

@implementation OCColumnProxy_Mixed
-(size_t)find:(OCMixed *)value
{
    return [self.table findMixed:self.column value:value];
}
@end

