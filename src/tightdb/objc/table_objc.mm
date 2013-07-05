//
//  table.mm
//  TightDB
//

#include <tightdb/table.hpp>
#include <tightdb/table_view.hpp>
#include <tightdb/lang_bind_helper.hpp>

#import <tightdb/objc/table.h>
#import <tightdb/objc/table_priv.h>
#import <tightdb/objc/query.h>
#import <tightdb/objc/query_priv.h>
#import <tightdb/objc/cursor.h>

#include <tightdb/objc/util.hpp>

using namespace std;


#ifdef TIGHTDB_DEBUG
_Atomic(int) TightdbBinaryAllocateCount = 0;
#endif

@implementation TightdbBinary
{
    tightdb::BinaryData _data;
}
-(id)initWithData:(const char *)data size:(size_t)size
{
    self = [super init];
    if (self) {
        _data = tightdb::BinaryData(data, size);
#ifdef TIGHTDB_DEBUG
        ++TightdbBinaryAllocateCount;
#endif
    }
    return self;
}
-(id)initWithBinary:(tightdb::BinaryData)data
{
    self = [super init];
    if (self) {
        _data = data;
#ifdef TIGHTDB_DEBUG
        ++TightdbBinaryAllocateCount;
#endif
    }
    return self;
}
-(const char *)getData
{
    return _data.data();
}
-(size_t)getSize
{
    return _data.size();
}
-(BOOL)isEqual:(TightdbBinary *)bin
{
    return _data == bin->_data;
}
-(tightdb::BinaryData)getBinary
{
    return _data;
}
-(void)dealloc
{
#ifdef TIGHTDB_DEBUG
    --TightdbBinaryAllocateCount;
#endif
}
@end

#ifdef TIGHTDB_DEBUG
_Atomic(int) TightdbMixedAllocateCount = 0;
#endif

@interface TightdbMixed()
@property (nonatomic) tightdb::Mixed mixed;
@property (nonatomic, strong) TightdbTable *table;
+(TightdbMixed *)mixedWithMixed:(tightdb::Mixed&)other;
@end
@implementation TightdbMixed
@synthesize mixed = _mixed;
@synthesize table = _table;

-(id)init
{
    self = [super init];
    if (self) {
#ifdef TIGHTDB_DEBUG
        ++TightdbMixedAllocateCount;
#endif
    }
    return self;
}
-(void)dealloc
{
#ifdef TIGHTDB_DEBUG
    --TightdbMixedAllocateCount;
#endif
}

+(TightdbMixed *)mixedWithBool:(BOOL)value
{
    TightdbMixed *mixed = [[TightdbMixed alloc] init];
    mixed.mixed = tightdb::Mixed((bool)value);
    return mixed;
}

+(TightdbMixed *)mixedWithInt64:(int64_t)value
{
    TightdbMixed *mixed = [[TightdbMixed alloc] init];
    mixed.mixed = tightdb::Mixed(value);
    return mixed;
}

+(TightdbMixed *)mixedWithFloat:(float)value
{
    TightdbMixed *mixed = [[TightdbMixed alloc] init];
    mixed.mixed = tightdb::Mixed(value);
    return mixed;
}

+(TightdbMixed *)mixedWithDouble:(double)value
{
    TightdbMixed *mixed = [[TightdbMixed alloc] init];
    mixed.mixed = tightdb::Mixed(value);
    return mixed;
}

+(TightdbMixed *)mixedWithString:(NSString *)value
{
    TightdbMixed *mixed = [[TightdbMixed alloc] init];
    mixed.mixed = tightdb::Mixed(ObjcStringAccessor(value));
    return mixed;
}

+(TightdbMixed *)mixedWithBinary:(TightdbBinary *)value
{
    TightdbMixed *mixed = [[TightdbMixed alloc] init];
    mixed.mixed = tightdb::Mixed([value getBinary]);
    return mixed;
}

+(TightdbMixed *)mixedWithBinary:(const char *)data size:(size_t)size
{
    TightdbMixed *mixed = [[TightdbMixed alloc] init];
    mixed.mixed = tightdb::Mixed(tightdb::BinaryData(data, size));
    return mixed;
}

+(TightdbMixed *)mixedWithDate:(time_t)value
{
    TightdbMixed *mixed = [[TightdbMixed alloc] init];
    mixed.mixed = tightdb::Mixed(tightdb::Date(value));
    return mixed;
}

+(TightdbMixed *)mixedWithTable:(TightdbTable *)value
{
    TightdbMixed *mixed = [[TightdbMixed alloc] init];
    mixed.mixed = tightdb::Mixed(tightdb::Mixed::subtable_tag());
    mixed.table = value;
    return mixed;
}

+(TightdbMixed *)mixedWithMixed:(tightdb::Mixed&)value
{
    TightdbMixed *mixed = [[TightdbMixed alloc] init];
    mixed.mixed = value;
    return mixed;
}

-(BOOL)isEqual:(TightdbMixed *)other
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
            return _mixed.get_string() == other->_mixed.get_string();
        case tightdb::type_Binary:
            return _mixed.get_binary() == other->_mixed.get_binary();
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

-(TightdbType)getType
{
    return (TightdbType)_mixed.get_type();
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
    return to_objc_string(_mixed.get_string());
}

-(TightdbBinary *)getBinary
{
    return [[TightdbBinary alloc] initWithBinary:_mixed.get_binary()];
}

-(time_t)getDate
{
    return _mixed.get_date().get_date();
}

-(TightdbTable *)getTable
{
    return _table;
}
@end

#ifdef TIGHTDB_DEBUG
_Atomic(int) TightdbSpecAllocateCount = 0;
#endif

@interface TightdbSpec()
@property (nonatomic) tightdb::Spec *spec;
@property (nonatomic) BOOL isOwned;
+(TightdbSpec *)specWithSpec:(tightdb::Spec*)spec readOnly:(BOOL)readOnly isOwned:(BOOL)isOwned error:(NSError *__autoreleasing *)error;
@end

@implementation TightdbSpec
{
    BOOL _readOnly;
}
@synthesize spec = _spec;
@synthesize isOwned = _isOwned;


+(TightdbSpec *)specWithSpec:(tightdb::Spec *)spec readOnly:(BOOL)readOnly isOwned:(BOOL)isOwned error:(NSError *__autoreleasing *)error
{
    TightdbSpec *spec2 = [[TightdbSpec alloc] init];
    spec2->_readOnly = readOnly;
    if (isOwned) {
        TIGHTDB_EXCEPTION_ERRHANDLER(
                                     spec2.spec    = new tightdb::Spec(*spec);
                                     , @"com.tightdb.spec", return nil);
        spec2.isOwned = TRUE;
    }
    else {
        spec2.spec     = spec;
        spec2.isOwned  = FALSE;
    }
#ifdef TIGHTDB_DEBUG
    ++TightdbSpecAllocateCount;
#endif
    return spec2;
}

// FIXME: Provide a version of this method that takes a 'const char *'. This will simplify _addColumns of MyTable.
// FIXME: Detect errors from core library
-(BOOL)addColumn:(TightdbType)type name:(NSString *)name
{
    return [self addColumn:type name:name error:nil];
}

-(BOOL)addColumn:(TightdbType)type name:(NSString *)name error:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.spec", tdb_err_FailRdOnly, @"Tried to add column while read only");
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 _spec->add_column(tightdb::DataType(type), ObjcStringAccessor(name));
                                 , @"com.tightdb.spec", return NO);
    return YES;
}

-(TightdbSpec *)addColumnTable:(NSString *)name
{
    return [self addColumnTable:name error:nil];
}

-(TightdbSpec *)addColumnTable:(NSString *)name error:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.spec", tdb_err_FailRdOnly, @"Tried to add column while read only");
        return nil;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 tightdb::Spec tmp = _spec->add_subtable_column(ObjcStringAccessor(name));
                                 return [TightdbSpec specWithSpec:&tmp readOnly:FALSE isOwned:TRUE error:error];
                                 , @"com.tightdb.spec", return nil);
}

-(TightdbSpec *)getSubspec:(size_t)col_ndx
{
    return [self getSubspec:col_ndx error:nil];
}

-(TightdbSpec *)getSubspec:(size_t)col_ndx error:(NSError *__autoreleasing *)error
{
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 tightdb::Spec subspec = _spec->get_subtable_spec(col_ndx);
                                 return [TightdbSpec specWithSpec:&subspec readOnly:_readOnly isOwned:TRUE error:error];
                                 , @"com.tightdb.spec", return nil);
}

-(size_t)getColumnCount
{
    return _spec->get_column_count();
}
-(TightdbType)getColumnType:(size_t)ndx
{
    return (TightdbType)_spec->get_column_type(ndx);
}
-(NSString *)getColumnName:(size_t)ndx
{
    return to_objc_string(_spec->get_column_name(ndx));
}
-(size_t)getColumnIndex:(NSString *)name
{
    return _spec->get_column_index(ObjcStringAccessor(name));
}
-(void)dealloc
{
#ifdef TIGHTDB_DEBUG
    NSLog(@"TightdbSpec dealloc");
    --TightdbSpecAllocateCount;
#endif
    if (_isOwned) delete _spec;
}


@end


#ifdef TIGHTDB_DEBUG
_Atomic(int) TightdbViewAllocateCount = 0;
#endif

@interface TightdbView()
@property (nonatomic) tightdb::TableView *tableView;
@end
@implementation TightdbView
{
    __weak TightdbTable *_table;
}
@synthesize tableView = _tableView;


-(id)initFromQuery:(TightdbQuery *)query
{
    self = [super init];
    if (self) {
        _table = [query getTable];
        self.tableView = new tightdb::TableView([query getTableView]);
#ifdef TIGHTDB_DEBUG
        ++TightdbViewAllocateCount;
#endif
    }
    return self;
}

-(TightdbTable *)getTable
{
    return _table;
}

+(TightdbView *)tableViewWithTable:(TightdbTable *)table
{
    (void)table;
    TightdbView *tableView = [[TightdbView alloc] init];
    tableView.tableView = new tightdb::TableView(); // not longer needs table at construction
#ifdef TIGHTDB_DEBUG
    if (tableView)
        ++TightdbViewAllocateCount;
#endif
    return tableView;
}

+(TightdbView *)tableViewWithTableView:(tightdb::TableView)table
{
    TightdbView *tableView = [[TightdbView alloc] init];
    tableView.tableView = new tightdb::TableView(table);
#ifdef TIGHTDB_DEBUG
    if (tableView)
        ++TightdbViewAllocateCount;
#endif
    return tableView;
}

-(void)dealloc
{
#ifdef TIGHTDB_DEBUG
    NSLog(@"TightdbView dealloc");
    --TightdbViewAllocateCount;
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
    return _tableView->get_date(col_ndx, ndx).get_date();
}
-(NSString *)getString:(size_t)col_ndx ndx:(size_t)ndx
{
    return to_objc_string(_tableView->get_string(col_ndx, ndx));
}
-(void)remove:(size_t)ndx
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

-(TightdbCursor *)getCursor
{
    return nil; // Has to be overridden in tightdb.h
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len
{
    (void)len;
    if(state->state == 0) {
        state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self);
        TightdbCursor *tmp = [self getCursor];
        *stackbuf = tmp;
    }
    if (state->state < [self count]) {
        [((TightdbCursor *)*stackbuf) setNdx:[self getSourceNdx:state->state]];
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


#ifdef TIGHTDB_DEBUG
_Atomic(int) TightdbTableAllocateCount = 0;
#endif

@implementation TightdbTable
{
    id _parent;
    BOOL _readOnly;
}
@synthesize table = _table;

-(id)init
{
    return [self initWithError:nil];
}

-(id)initWithError:(NSError *__autoreleasing *)error
{
    self = [super init];
    if (self) {
        _readOnly = NO;
        TIGHTDB_EXCEPTION_ERRHANDLER(
                                     _table = tightdb::Table::create();
                                     , @"com.tightdb.table", return nil);
#ifdef TIGHTDB_DEBUG
        ++TightdbTableAllocateCount;
        NSLog(@"TightdbTable init");
#endif
    }
    return self;
}

-(id)_initRaw
{
    self = [super init];
#ifdef TIGHTDB_DEBUG
    if (self) {
        ++TightdbTableAllocateCount;
    }
#endif
    return self;
}

-(BOOL)updateFromSpec
{
    return [self updateFromSpecWithError:nil];
}
-(BOOL)updateFromSpecWithError:(NSError *__autoreleasing *)error
{
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 static_cast<tightdb::Table *>(&*self.table)->update_from_spec();
                                 , @"com.tightdb.table", return NO);
    return YES;
}

-(BOOL)_checkType
{
    return YES;
    // Dummy - must be overridden in tightdb.h - Check if spec matches the macro definitions
}

-(TightdbCursor *)getCursor
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
    if(state->state == 0) {
        state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self);
        TightdbCursor *tmp = [self getCursor];
        *stackbuf = tmp;
    }
    if (state->state < [self count]) {
        [((TightdbCursor *)*stackbuf) setNdx:state->state];
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

-(BOOL)isEqual:(TightdbTable *)other
{
    return *_table == *other->_table;
}

-(TightdbTable *)getSubtable:(size_t)col_ndx ndx:(size_t)ndx
{
    return [self getSubtable:col_ndx ndx:ndx error:nil];
}
-(TightdbTable *)getSubtable:(size_t)col_ndx ndx:(size_t)ndx error:(NSError *__autoreleasing *)error
{
    TIGHTDB_TABLEBOUNDS_ERRHANDLER(col_ndx, ndx, error, return nil);
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 const tightdb::DataType t = _table->get_column_type(col_ndx);
                                 if (t != tightdb::type_Table && t != tightdb::type_Mixed) return nil;
                                 tightdb::TableRef r = _table->get_subtable(col_ndx, ndx);
                                 if (!r) return nil;
                                 TightdbTable *table = [[TightdbTable alloc] _initRaw];
                                 if (TIGHTDB_UNLIKELY(!table)) return nil;
                                 [table setTable:move(r)];
                                 [table setParent:self];
                                 [table setReadOnly:_readOnly];
                                 return table;
                                 , @"com.tightdb.table", return nil);
}

// FIXME: Check that the specified class derives from TightdbTable.
-(id)getSubtable:(size_t)col_ndx ndx:(size_t)ndx withClass:(__unsafe_unretained Class)classObj
{
    const tightdb::DataType t = _table->get_column_type(col_ndx);
    if (t != tightdb::type_Table && t != tightdb::type_Mixed) return nil;
    tightdb::TableRef r = _table->get_subtable(col_ndx, ndx);
    if (!r) return nil;
    TightdbTable *table = [[classObj alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table)) return nil;
    [table setTable:move(r)];
    [table setParent:self];
    [table setReadOnly:_readOnly];
    if (![table _checkType]) return nil;
    return table;
}

// FIXME: Check that the specified class derives from TightdbTable.
-(BOOL)isClass:(__unsafe_unretained Class)classObj
{
    TightdbTable *table = [[classObj alloc] _initRaw];
    if (TIGHTDB_LIKELY(table)) {
        [table setTable:_table];
        [table setParent:_parent];
        [table setReadOnly:_readOnly];
        if ([table _checkType]) return YES;
    }
    return NO;
}

// FIXME: Check that the specified class derives from TightdbTable.
-(id)castClass:(__unsafe_unretained Class)classObj
{
    TightdbTable *table = [[classObj alloc] _initRaw];
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
    NSLog(@"TightdbTable dealloc");
    --TightdbTableAllocateCount;
#endif
    _parent = nil;
}

-(size_t)getColumnCount
{
    return _table->get_column_count();
}
-(NSString *)getColumnName:(size_t)ndx
{
    return to_objc_string(_table->get_column_name(ndx));
}
-(size_t)getColumnIndex:(NSString *)name
{
    return _table->get_column_index(ObjcStringAccessor(name));
}
-(TightdbType)getColumnType:(size_t)ndx
{
    return (TightdbType)_table->get_column_type(ndx);
}

-(TightdbSpec *)getSpec
{
    return [self getSpecWithError:nil];
}
-(TightdbSpec *)getSpecWithError:(NSError *__autoreleasing *)error
{
    tightdb::Spec& spec = tightdb::LangBindHelper::get_spec(*_table);
    BOOL readOnly = _readOnly || _table->has_shared_spec();
    return [TightdbSpec specWithSpec:&spec readOnly:readOnly isOwned:FALSE error:error];
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
    return [self addRowWithError:nil];
}
-(size_t)addRowWithError:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_FailRdOnly, @"Tried to add row while readonly.");
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 return _table->add_empty_row();
                                 , @"com.tightdb.table", return 0);
}

-(size_t)addRows:(size_t)rowCount
{
    return [self addRows:rowCount error:nil];
}

-(size_t)addRows:(size_t)rowCount error:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_FailRdOnly, @"Tried to add row while readonly.");
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 return _table->add_empty_row(rowCount);
                                 , @"com.tightdb.table", return 0);
}

-(BOOL)clear
{
    return [self clearWithError:nil];
}
-(BOOL)clearWithError:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_FailRdOnly, @"Tried to clear while readonly.");
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 _table->clear();
                                 , @"com.tightdb.table", return NO);
    return YES;
}

-(BOOL)remove:(size_t)ndx
{
    return [self remove:ndx error:nil];
}

-(BOOL)remove:(size_t)ndx error:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to remove row while read only ndx: %llu", (unsigned long long)ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 _table->remove(ndx);
                                 , @"com.tightdb.table", return NO);
    return YES;
}

-(BOOL)removeLast
{
    return [self removeLastWithError:nil];
}

-(BOOL)removeLastWithError:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_FailRdOnly, @"Tried to remove last while readonly.");
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 _table->remove_last();
                                 , @"com.tightdb.table", return NO);
    return YES;
}
-(NSNumber *)get:(size_t)col_ndx ndx:(size_t)ndx
{
    return [self get:col_ndx ndx:ndx error:nil];
}
-(NSNumber *)get:(size_t)col_ndx ndx:(size_t)ndx error:(NSError *__autoreleasing *)error
{
    TIGHTDB_TABLEBOUNDS_ERRHANDLER(col_ndx, ndx, error, return nil);
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 return [NSNumber numberWithLongLong:_table->get_int(col_ndx, ndx)];
                                 , @"com.tightdb.table", return nil);
}

-(BOOL)set:(size_t)col_ndx ndx:(size_t)ndx value:(int64_t)value
{
    return [self set:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)set:(size_t)col_ndx ndx:(size_t)ndx value:(int64_t)value error:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to set while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 _table->set_int(col_ndx, ndx, value);
                                 , @"com.tightdb.table", return NO);
    return YES;
}

-(NSNumber *)getBool:(size_t)col_ndx ndx:(size_t)ndx
{
    return [self getBool:col_ndx ndx:ndx error:nil];
}
-(NSNumber *)getBool:(size_t)col_ndx ndx:(size_t)ndx error:(NSError *__autoreleasing *)error
{
    TIGHTDB_TABLEBOUNDS_ERRHANDLER(col_ndx, ndx, error, return nil);
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 return [NSNumber numberWithBool:_table->get_bool(col_ndx, ndx)];
                                 , @"com.tightdb.table", return nil);
}

-(BOOL)setBool:(size_t)col_ndx ndx:(size_t)ndx value:(BOOL)value
{
    return [self setBool:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)setBool:(size_t)col_ndx ndx:(size_t)ndx value:(BOOL)value error:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to set while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 _table->set_bool(col_ndx, ndx, value);
                                 , @"com.tightdb.table", return NO);
    return YES;
}

-(NSNumber *)getFloat:(size_t)col_ndx ndx:(size_t)ndx
{
    return [self getFloat:col_ndx ndx:ndx error:nil];
}
-(NSNumber *)getFloat:(size_t)col_ndx ndx:(size_t)ndx error:(NSError *__autoreleasing *)error
{
    TIGHTDB_TABLEBOUNDS_ERRHANDLER(col_ndx, ndx, error, return nil);
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 return [NSNumber numberWithFloat:_table->get_float(col_ndx, ndx)];
                                 , @"com.tightdb.table", return nil);
}

-(BOOL)setFloat:(size_t)col_ndx ndx:(size_t)ndx value:(float)value
{
    return [self setFloat:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)setFloat:(size_t)col_ndx ndx:(size_t)ndx value:(float)value error:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to set while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 _table->set_float(col_ndx, ndx, value);
                                 , @"com.tightdb.table", return NO);
    return YES;
}

-(NSNumber *)getDouble:(size_t)col_ndx ndx:(size_t)ndx
{
    return [self getDouble:col_ndx ndx:ndx error:nil];
}
-(NSNumber *)getDouble:(size_t)col_ndx ndx:(size_t)ndx error:(NSError *__autoreleasing *)error
{
    TIGHTDB_TABLEBOUNDS_ERRHANDLER(col_ndx, ndx, error, return nil);
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 return [NSNumber numberWithDouble:_table->get_double(col_ndx, ndx)];
                                 , @"com.tightdb.table", return nil);
}

-(BOOL)setDouble:(size_t)col_ndx ndx:(size_t)ndx value:(double)value
{
    return [self setDouble:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)setDouble:(size_t)col_ndx ndx:(size_t)ndx value:(double)value error:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to set while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 _table->set_double(col_ndx, ndx, value);
                                 , @"com.tightdb.table", return NO);
    return YES;
}

-(NSNumber *)getDate:(size_t)col_ndx ndx:(size_t)ndx
{
    return [self getDate:col_ndx ndx:ndx error:nil];
}
-(NSNumber *)getDate:(size_t)col_ndx ndx:(size_t)ndx error:(NSError *__autoreleasing *)error
{
    TIGHTDB_TABLEBOUNDS_ERRHANDLER(col_ndx, ndx, error, return nil);
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 return [NSNumber numberWithLong:_table->get_date(col_ndx, ndx).get_date()];
                                 , @"com.tightdb.table", return nil);
}

-(BOOL)setDate:(size_t)col_ndx ndx:(size_t)ndx value:(time_t)value
{
    return [self setDate:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)setDate:(size_t)col_ndx ndx:(size_t)ndx value:(time_t)value error:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to set while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 _table->set_date(col_ndx, ndx, value);
                                 , @"com.tightdb.table", return NO);
    return YES;
}



-(NSArray *)getRowAtIndex:(size_t)ndx
{
    return [self getRowAtIndex:ndx error:nil];
}

-(NSArray *)getRowAtIndex:(size_t)ndx error:(NSError *__autoreleasing *)error
{
    size_t count = [self getColumnCount];
    NSMutableArray *row = [NSMutableArray arrayWithCapacity:count];
    for (size_t i = 0; i < count; ++i) {
        TightdbType type = [self getColumnType:i];
        id value;
        switch (type) {
            case tightdb_Int:
                value = [self get:i ndx:ndx error:error];
                break;
            case tightdb_Float:
                value = [self getFloat:i ndx:ndx error:error];
                break;
            case tightdb_Double:
                value = [self getDouble:i ndx:ndx error:error];
                break;
            case tightdb_String:
                value = [self getString:i ndx:ndx error:error];
                break;
            case tightdb_Bool:
                value = [self getBool:i ndx:ndx error:error];
                break;
            case tightdb_Binary:
                value = [self getBinary:i ndx:ndx error:error];
                break;
            case tightdb_Date:
                value = [self getDate:i ndx:ndx error:error];
                break;
            case tightdb_Mixed:
                value = [self getMixed:i ndx:ndx error:error];
                break;
            case tightdb_Table:
                value = [self getSubtable:i ndx:ndx error:error];
                break;
                
        }
        if (!value)
            return nil;
        [row addObject:value];
    }
    return row;
}

-(BOOL)insertBool:(size_t)col_ndx ndx:(size_t)ndx value:(BOOL)value
{
    return [self insertBool:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)insertBool:(size_t)col_ndx ndx:(size_t)ndx value:(BOOL)value error:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 _table->insert_bool(col_ndx, ndx, value);
                                 , @"com.tightdb.table", return NO);
    return YES;
}

-(BOOL)insertInt:(size_t)col_ndx ndx:(size_t)ndx value:(int64_t)value
{
    return [self insertInt:col_ndx ndx:ndx value:value error:nil];
}


-(BOOL)insertInt:(size_t)col_ndx ndx:(size_t)ndx value:(int64_t)value error:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 _table->insert_int(col_ndx, ndx, value);
                                 , @"com.tightdb.table", return NO);
    return YES;
}

-(BOOL)insertFloat:(size_t)col_ndx ndx:(size_t)ndx value:(float)value
{
    return [self insertFloat:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)insertFloat:(size_t)col_ndx ndx:(size_t)ndx value:(float)value error:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 _table->insert_float(col_ndx, ndx, value);
                                 , @"com.tightdb.table", return NO);
    return YES;
}

-(BOOL)insertDouble:(size_t)col_ndx ndx:(size_t)ndx value:(double)value
{
    return [self insertDouble:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)insertDouble:(size_t)col_ndx ndx:(size_t)ndx value:(double)value error:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 _table->insert_double(col_ndx, ndx, value);
                                 , @"com.tightdb.table", return NO);
    return YES;
}

-(BOOL)insertString:(size_t)col_ndx ndx:(size_t)ndx value:(NSString *)value
{
    return [self insertString:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)insertString:(size_t)col_ndx ndx:(size_t)ndx value:(NSString *)value error:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 _table->insert_string(col_ndx, ndx, ObjcStringAccessor(value));
                                 , @"com.tightdb.table", return NO);
    return YES;
}

-(BOOL)insertBinary:(size_t)col_ndx ndx:(size_t)ndx value:(TightdbBinary *)value
{
    return [self insertBinary:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)insertBinary:(size_t)col_ndx ndx:(size_t)ndx value:(TightdbBinary *)value error:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 _table->insert_binary(col_ndx, ndx, [value getBinary]);
                                 , @"com.tightdb.table", return NO);
    return YES;
}

-(BOOL)insertBinary:(size_t)col_ndx ndx:(size_t)ndx data:(const char *)data size:(size_t)size
{
    return [self insertBinary:col_ndx ndx:ndx data:data size:size error:nil];
}

-(BOOL)insertBinary:(size_t)col_ndx ndx:(size_t)ndx data:(const char *)data size:(size_t)size error:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 _table->insert_binary(col_ndx, ndx, tightdb::BinaryData(data, size));
                                 , @"com.tightdb.table", return NO);
    return YES;
}

-(BOOL)insertDate:(size_t)col_ndx ndx:(size_t)ndx value:(time_t)value
{
    return [self insertDate:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)insertDate:(size_t)col_ndx ndx:(size_t)ndx value:(time_t)value error:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 _table->insert_date(col_ndx, ndx, value);
                                 , @"com.tightdb.table", return NO);
    return YES;
}

-(BOOL)insertRowAtIndex:(size_t)ndx, ...
{
    va_list args;
    va_start(args, ndx);
    BOOL result = [self insertRowAtIndex:ndx error:nil, args];
    va_end(args);
    return result;
}

-(BOOL)insertRowAtIndex:(size_t)ndx error:(NSError *__autoreleasing *)error, ...
{
    if (ndx>[self count]) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_Bounds, [NSString stringWithFormat:@"Insert index: %zd greater than number of rows: %zd", ndx, [self count]]);
        return NO;
    }
    va_list args;
    va_start(args, error);
    size_t count = [self getColumnCount];
    for (size_t i = 0; i < count; ++i) {
        BOOL result = NO;
        TightdbType type = [self getColumnType:i];
        switch (type) {
            case tightdb_Int:
            {
                int64_t value = va_arg(args, int64_t);
                result = [self insertInt:i ndx:ndx value:value error:error];
                break;
            }
            case tightdb_Float:
            {
                float value = va_arg(args, double);
                result = [self insertFloat:i ndx:ndx value:value error:error];
                break;
            }
            case tightdb_Double:
            {
                double value = va_arg(args, double);
                result = [self insertDouble:i ndx:ndx value:value error:error];
                break;
            }
            case tightdb_String:
            {
                NSString *value = va_arg(args, NSString *);
                result = [self insertString:i ndx:ndx value:value error:error];
                break;
            }
            case tightdb_Bool:
            {
                BOOL value = va_arg(args, int);
                result = [self insertBool:i ndx:ndx value:value error:error];
                break;
            }
            case tightdb_Binary:
            {
                TightdbBinary *value = va_arg(args, TightdbBinary *);
                result = [self insertBinary:i ndx:ndx value:value error:error];
                break;
            }
            case tightdb_Date:
            {
                time_t value = va_arg(args, time_t);
                result = [self insertDate:i ndx:ndx value:value error:error];
                break;
            }
            case tightdb_Mixed:
            {
                TightdbMixed *value = va_arg(args, TightdbMixed *);
                result = [self insertMixed:i ndx:ndx value:value error:error];
                break;
            }
            case tightdb_Table:
            {
                if (error)
                    *error = make_tightdb_error(@"com.tightdb.table", tdb_err_Bounds, @"Subtable not supported in insert row");
                return NO;
            }
        }
        if (!result)
            return NO;
    }
    
    return [self insertDoneWithError:error];
}

-(BOOL)insertDone
{
    return [self insertDoneWithError:nil];
}

-(BOOL)insertDoneWithError:(NSError *__autoreleasing *)error
{
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 _table->insert_done();
                                 , @"com.tightdb.table", return NO);
    return YES;
}

-(NSString *)getString:(size_t)col_ndx ndx:(size_t)ndx
{
    return [self getString:col_ndx ndx:ndx error:nil];
}
-(NSString *)getString:(size_t)col_ndx ndx:(size_t)ndx error:(NSError *__autoreleasing *)error
{
    TIGHTDB_TABLEBOUNDS_ERRHANDLER(col_ndx, ndx, error, return nil);
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 return to_objc_string(_table->get_string(col_ndx, ndx));
                                 , @"com.tightdb.table", return nil);
}

-(BOOL)setString:(size_t)col_ndx ndx:(size_t)ndx value:(NSString *)value
{
    return [self setString:col_ndx ndx:ndx value:value error:nil];
}
-(BOOL)setString:(size_t)col_ndx ndx:(size_t)ndx value:(NSString *)value error:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to set while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 _table->set_string(col_ndx, ndx, ObjcStringAccessor(value));
                                 , @"com.tightdb.table", return NO);
    return YES;
}


-(TightdbBinary *)getBinary:(size_t)col_ndx ndx:(size_t)ndx
{
    return [self getBinary:col_ndx ndx:ndx error:nil];
}
-(TightdbBinary *)getBinary:(size_t)col_ndx ndx:(size_t)ndx error:(NSError *__autoreleasing *)error
{
    TIGHTDB_TABLEBOUNDS_ERRHANDLER(col_ndx, ndx, error, return nil);
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 return [[TightdbBinary alloc] initWithBinary:_table->get_binary(col_ndx, ndx)];
                                 , @"com.tightdb.table", return nil);
}

-(BOOL)setBinary:(size_t)col_ndx ndx:(size_t)ndx value:(TightdbBinary *)value
{
    return [self setBinary:col_ndx ndx:ndx value:value error:nil];
}

-(BOOL)setBinary:(size_t)col_ndx ndx:(size_t)ndx value:(TightdbBinary *)value error:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to set while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 _table->set_binary(col_ndx, ndx, [value getBinary]);
                                 , @"com.tightdb.table", return NO);
    return YES;
}

-(BOOL)setBinary:(size_t)col_ndx ndx:(size_t)ndx data:(const char *)data size:(size_t)size
{
    return [self setBinary:col_ndx ndx:ndx data:data size:size error:nil];
}

-(BOOL)setBinary:(size_t)col_ndx ndx:(size_t)ndx data:(const char *)data size:(size_t)size error:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to set while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 _table->set_binary(col_ndx, ndx, tightdb::BinaryData(data, size));
                                 , @"com.tightdb.table", return NO);
    return YES;
}

-(size_t)getTableSize:(size_t)col_ndx ndx:(size_t)row_ndx
{
    return _table->get_subtable_size(col_ndx, row_ndx);
}

-(BOOL)insertSubtable:(size_t)col_ndx ndx:(size_t)row_ndx
{
    return [self insertSubtable:col_ndx ndx:row_ndx error:nil];
}

-(BOOL)insertSubtable:(size_t)col_ndx ndx:(size_t)row_ndx error:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 _table->insert_subtable(col_ndx, row_ndx);
                                 , @"com.tightdb.table", return NO);
    return YES;
}

-(BOOL)_insertSubtableCopy:(size_t)col_ndx row:(size_t)row_ndx subtable:(TightdbTable *)subtable
{
    return [self _insertSubtableCopy:col_ndx row:row_ndx subtable:subtable error:nil];
}


-(BOOL)_insertSubtableCopy:(size_t)col_ndx row:(size_t)row_ndx subtable:(TightdbTable *)subtable error:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 tightdb::LangBindHelper::insert_subtable(*_table, col_ndx, row_ndx, [subtable getTable]);
                                 , @"com.tightdb.table", return NO);
    return YES;
}

-(BOOL)clearSubtable:(size_t)col_ndx ndx:(size_t)row_ndx
{
    return [self clearSubtable:col_ndx ndx:row_ndx error:nil];
}
-(BOOL)clearSubtable:(size_t)col_ndx ndx:(size_t)row_ndx error:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to clear while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 _table->clear_subtable(col_ndx, row_ndx);
                                 , @"com.tightdb.table", return NO);
    return YES;
}

-(TightdbMixed *)getMixed:(size_t)col_ndx ndx:(size_t)ndx
{
    return [self getMixed:col_ndx ndx:ndx error:nil];
}
-(TightdbMixed *)getMixed:(size_t)col_ndx ndx:(size_t)ndx error:(NSError *__autoreleasing *)error
{
    TIGHTDB_TABLEBOUNDS_ERRHANDLER(col_ndx, ndx, error, return nil);
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 tightdb::Mixed tmp = _table->get_mixed(col_ndx, ndx);
                                 TightdbMixed *mixed = [TightdbMixed mixedWithMixed:tmp];
                                 if ([mixed getType] == tightdb_Table) {
                                     [mixed setTable:[self getSubtable:col_ndx ndx:ndx error:error]];
                                 }
                                 return mixed;
                                 , @"com.tightdb.table", return nil);
}

-(TightdbType)getMixedType:(size_t)col_ndx ndx:(size_t)row_ndx
{
    return (TightdbType)_table->get_mixed_type(col_ndx, row_ndx);
}

-(BOOL)insertMixed:(size_t)col_ndx ndx:(size_t)row_ndx value:(TightdbMixed *)value
{
    return [self insertMixed:col_ndx ndx:row_ndx value:value error:nil];
}

-(BOOL)insertMixed:(size_t)col_ndx ndx:(size_t)row_ndx value:(TightdbMixed *)value error:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to insert while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 if (value.mixed.get_type() == tightdb::type_Table && value.table) {
                                     tightdb::LangBindHelper::insert_mixed_subtable(*_table, col_ndx, row_ndx,
                                                                                    [value.table getTable]);
                                 }
                                 else {
                                     _table->insert_mixed(col_ndx, row_ndx, value.mixed);
                                 }
                                 , @"com.tightdb.table", return NO);
    return YES;
}

-(BOOL)setMixed:(size_t)col_ndx ndx:(size_t)row_ndx value:(TightdbMixed *)value
{
    return [self setMixed:col_ndx ndx:row_ndx value:value error:nil];
}

-(BOOL)setMixed:(size_t)col_ndx ndx:(size_t)row_ndx value:(TightdbMixed *)value error:(NSError *__autoreleasing *)error
{
    if (_readOnly) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.table", tdb_err_FailRdOnly, [NSString stringWithFormat:@"Tried to set while read only ColumnId: %llu", (unsigned long long)col_ndx]);
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 if (value.mixed.get_type() == tightdb::type_Table && value.table) {
                                     tightdb::LangBindHelper::set_mixed_subtable(*_table, col_ndx, row_ndx,
                                                                                 [value.table getTable]);
                                 }
                                 else {
                                     _table->set_mixed(col_ndx, row_ndx, value.mixed);
                                 }
                                 , @"com.tightdb.table", return NO);
    return YES;
}

-(size_t)addColumn:(TightdbType)type name:(NSString *)name
{
    return [self addColumn:type name:name error:nil];
}

-(size_t)addColumn:(TightdbType)type name:(NSString *)name error:(NSError *__autoreleasing *)error
{
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 return _table->add_column(tightdb::DataType(type), ObjcStringAccessor(name));
                                 , @"com.tightdb.table", return 0);
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
    return _table->find_first_string(col_ndx, ObjcStringAccessor(value));
}
-(size_t)findBinary:(size_t)col_ndx value:(TightdbBinary *)value
{
    return _table->find_first_binary(col_ndx, [value getBinary]);
}
-(size_t)findDate:(size_t)col_ndx value:(time_t)value
{
    return _table->find_first_date(col_ndx, value);
}
-(size_t)findMixed:(size_t)col_ndx value:(TightdbMixed *)value
{
    static_cast<void>(col_ndx);
    static_cast<void>(value);
    [NSException raise:@"NotImplemented" format:@"Not implemented"];
    // FIXME: Implement this!
    // return _table->find_first_mixed(col_ndx, value);
    return 0;
}

-(TightdbView *)findAll:(TightdbView *)view column:(size_t)col_ndx value:(int64_t)value
{
    *view.tableView = _table->find_all_int(col_ndx, value);
    return view;
}

-(TightdbQuery *)where
{
    return [self whereWithError:nil];
}

-(TightdbQuery *)whereWithError:(NSError *__autoreleasing *)error
{
    return [[TightdbQuery alloc] initWithTable:self error:error];
}
-(BOOL)hasIndex:(size_t)col_ndx
{
    return _table->has_index(col_ndx);
}
-(void)setIndex:(size_t)col_ndx
{
    _table->set_index(col_ndx);
}

-(BOOL)optimize
{
    return [self optimizeWithError:nil];
}

-(BOOL)optimizeWithError:(NSError *__autoreleasing *)error
{
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 _table->optimize();
                                 , @"com.tightdb.table", return NO);
    return YES;
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
    return _table->count_string(col_ndx, ObjcStringAccessor(target));
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


#ifdef TIGHTDB_DEBUG
_Atomic(int) TightdbColumnProxyAllocateCount = 0;
#endif

@implementation TightdbColumnProxy
@synthesize table = _table, column = _column;
-(id)initWithTable:(TightdbTable *)table column:(size_t)column
{
    self = [super init];
    if (self) {
        _table = table;
        _column = column;
#ifdef TIGHTDB_DEBUG
        ++TightdbColumnProxyAllocateCount;
#endif
    }
    return self;
}
-(void)clear
{
    _table = nil;
}

-(void)dealloc
{
#ifdef TIGHTDB_DEBUG
    NSLog(@"TightdbColumnProxy dealloc");
    --TightdbColumnProxyAllocateCount;
#endif
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
-(TightdbView *)findAll:(int64_t)value
{
    TightdbView *view = [TightdbView tableViewWithTable:self.table];
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

@implementation TightdbColumnProxy_Float
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

@implementation TightdbColumnProxy_Double
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

@implementation TightdbColumnProxy_String
-(size_t)find:(NSString *)value
{
    return [self.table findString:self.column value:value];
}
@end

@implementation TightdbColumnProxy_Binary
-(size_t)find:(TightdbBinary *)value
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
-(size_t)find:(TightdbMixed *)value
{
    return [self.table findMixed:self.column value:value];
}
@end

