//
//  Table.mm
//  TightDB
//

#import <tightdb/table.hpp>
#import <tightdb/table_view.hpp>
//#import "TightDb/alloc.hpp"
#import "Table.h"
#import "TablePriv.h"
#import "Query.h"
#import "QueryPriv.h"
#import "Cursor.h"

#pragma mark BinaryData

@implementation BinaryData
{
    tightdb::BinaryData _data;
}
-(id)initWithData:(char *)ptr len:(size_t)len
{
    self = [super init];
    if (self) {
        _data.pointer = ptr;
        _data.len = len;
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
-(tightdb::BinaryData)getBinary
{
    return _data;
}
@end

#pragma mark - Allocater
@implementation OCMemRef
{
    tightdb::MemRef *_memref;
}
-(id)initWithPointer:(void *)p ref:(size_t)r
{
    self = [super init];
    if (self) {
        _memref = new tightdb::MemRef(p,r);
    }
    return self;
}
-(id)init
{
    self = [super init];
    if (self) {
        _memref = new tightdb::MemRef();
    }
    return self;    
}
-(void *)getPointer
{
    return _memref->pointer;
}
-(size_t)getRef
{
    return _memref->ref;
}
-(void)dealloc
{
    delete _memref;
}
@end

@implementation OCAllocator
{
    tightdb::Allocator *_allocator;
}
-(id)init
{
    self = [super init];
    if (self) {
        _allocator = new tightdb::Allocator();
    }
    return self;
}
-(OCMemRef *)alloc:(size_t)size
{
    tightdb::MemRef ref = _allocator->Alloc(size);
    return [[OCMemRef alloc] initWithPointer:ref.pointer ref:ref.ref];
}
-(OCMemRef *)reAlloc:(size_t)r pointer:(void *)p size:(size_t)size
{
    tightdb::MemRef ref = _allocator->ReAlloc(r, p, size);
    return [[OCMemRef alloc] initWithPointer:ref.pointer ref:ref.ref];    
}
-(void)free:(size_t)ref pointer:(void *)p
{
    _allocator->Free(ref, p);
}
-(void*)translate:(size_t)ref
{
    return _allocator->Translate(ref);
}
-(BOOL)isReadOnly:(size_t)ref
{
    return NO;
}
-(void)dealloc
{
    delete _allocator;
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
-(void)dealloc
{
#ifdef DEBUG
    NSLog(@"OCDate dealloc");
#endif
    delete _date;
}
@end

#pragma mark - Mixed
@interface OCMixed()
@property (nonatomic) tightdb::Mixed *mixed;
+(OCMixed *)mixedWithMixed:(tightdb::Mixed&)other;
@end
@implementation OCMixed
@synthesize mixed = _mixed;

+(OCMixed *)mixedWithMixed:(tightdb::Mixed&)other
{
    OCMixed *mixed = [[OCMixed alloc] init];
    
    mixed.mixed = new tightdb::Mixed(other);
    
    return mixed;    
}
+(OCMixed *)mixedWithTable
{
    OCMixed *mixed = [[OCMixed alloc] init];
    
    mixed.mixed = new tightdb::Mixed(tightdb::Mixed::subtable_tag());
    
    return mixed;
}

+(OCMixed *)mixedWithBool:(BOOL)value
{
    OCMixed *mixed = [[OCMixed alloc] init];
    
    mixed.mixed = new tightdb::Mixed((bool)value);
    
    return mixed;    
}

+(OCMixed *)mixedWithDate:(OCDate *)date
{
    OCMixed *mixed = [[OCMixed alloc] init];
    
    mixed.mixed = new tightdb::Mixed(new tightdb::Date([date getDate]));
    
    return mixed;        
}

+(OCMixed *)mixedWithInt64:(int64_t)value
{
    OCMixed *mixed = [[OCMixed alloc] init];
    
    mixed.mixed = new tightdb::Mixed(value);
    
    return mixed;            
}

+(OCMixed *)mixedWithString:(NSString *)string
{
    OCMixed *mixed = [[OCMixed alloc] init];
    
    mixed.mixed = new tightdb::Mixed([string UTF8String]);
    
    return mixed;            
}

+(OCMixed *)mixedWithBinary:(BinaryData *)data
{
    OCMixed *mixed = [[OCMixed alloc] init];
    
    mixed.mixed = new tightdb::Mixed([data getBinary]);
    
    return mixed;            
}

+(OCMixed *)mixedWithData:(const char*)value length:(size_t)length
{
    OCMixed *mixed = [[OCMixed alloc] init];
    
    mixed.mixed = new tightdb::Mixed(value, length);
    
    return mixed;            
}

-(ColumnType)getType
{
    return (ColumnType)_mixed->get_type();
}
-(int64_t)getInt
{
    return _mixed->get_int();
}
-(BOOL)getBool
{
    return _mixed->get_bool();
}

-(OCDate *)getDate
{
    return [[OCDate alloc] initWithDate:_mixed->get_date()];
}

-(NSString *)getString
{
    return [NSString stringWithUTF8String:_mixed->get_string()];
}

-(BinaryData *)getBinary
{
    return [[BinaryData alloc] initWithBinary:_mixed->get_binary()];    
}
@end

#pragma mark - Spec

@interface OCSpec()
@property (nonatomic) tightdb::Spec *spec;
@property (nonatomic) BOOL isOwned;
+(OCSpec *)specWithAllocator:(tightdb::Allocator&)allocator ref:(size_t)ref parent:(tightdb::ArrayParent*)parent pndx:(size_t)pndx;
+(OCSpec *)specWithSpec:(tightdb::Spec*)other isOwned:(BOOL)isOwned;
@end
@implementation OCSpec
@synthesize spec = _spec;
@synthesize isOwned = _isOwned;


// Dummy method - not used. allocators can probably not be overwritten with OC
+(OCSpec *)specWithAllocator:(tightdb::Allocator &)allocator ref:(size_t)ref parent:(tightdb::ArrayParent *)parent pndx:(size_t)pndx
{
    OCSpec *spec = [[OCSpec alloc] init];
//  TODO???  spec.spec = new Spec(allocator, ref, parent, pndx);
    return spec;
}
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

-(void)addColumn:(ColumnType)type name:(NSString *)name
{
    _spec->add_column((tightdb::ColumnType)type, [name UTF8String]);
}
-(OCSpec *)addColumnTable:(NSString *)name
{
    tightdb::Spec tmp = _spec->add_subtable_column([name UTF8String]);
    return [OCSpec specWithSpec:&tmp isOwned:TRUE];
}
-(OCSpec *)getSpec:(size_t)columndId
{
    tightdb::Spec tmp = _spec->get_subtable_spec(columndId);
    return [OCSpec specWithSpec:&tmp isOwned:TRUE];
}
-(size_t)getColumnCount
{
    return _spec->get_column_count();
}
-(ColumnType)getColumnType:(size_t)ndx
{
    return (ColumnType)_spec->get_column_type(ndx);
}
-(NSString *)getColumnName:(size_t)ndx
{
    return [NSString stringWithUTF8String:_spec->get_column_name(ndx)];
}
-(size_t)getColumnIndex:(NSString *)name
{
    return _spec->get_column_index([name UTF8String]);
}
-(size_t)write:(id)obj pos:(size_t)pos
{
    // Possibly not possible.....TODO.
    return 0;
}
-(void)dealloc
{
#ifdef DEBUG
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
        self.tableView = new tightdb::TableView([query getTableView]); // TODO: Copy constructor is called here. (Move did not work).
    }
    return self;    
}

-(Table *)getTable
{
    return _table;
}

+(TableView *)tableViewWithTable:(Table *)table
{
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
#ifdef DEBUG
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
    return nil; // Has to be overridden in TightDb.h
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len
{
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
}
@synthesize table = _table;
@synthesize tablePtr = _tablePtr;

-(id)initWithBlock:(TopLevelTableInitBlock)block
{
    self = [super init];
    if (self) {   
        __weak Table *weakSelf = self;
        if (block) block(weakSelf);
    }
    return self;
}
-(id)initWithTableRef:(tightdb::TableRef)ref
{
    self = [super init];
    if (self) {
        _tablePtr = 0;
        _table = ref;
    }
    return self;
}

-(void)initRefs
{
    // Dummy - Must be overridden in TightDB.h
}
-(id)init
{
    self = [super init];
    if (self) {
        _tablePtr = new tightdb::Table();
        _table = _tablePtr->get_table_ref(); 
    }
    return self;
}

-(tightdb::Table *)getTable
{
    return &*_table;
}

-(void)setParent:(id)parent
{
    _parent = parent;
}

-(Table *)getTable:(size_t)columnId ndx:(size_t)ndx
{
    Table *table = [[Table alloc] initWithTableRef:_table->get_subtable(columnId, ndx)];
    [table setParent:self];
    return table;
}

-(OCTopLevelTable *)getTopLevelTable:(size_t)columnId ndx:(size_t)ndx
{
    OCTopLevelTable *table = [[OCTopLevelTable alloc] initWithTableRef:_table->get_subtable(columnId, ndx)];
    [table setParent:self];
    return table;
}


-(void)dealloc
{
#ifdef DEBUG
    NSLog(@"Table dealloc");
#endif
    // NOTE: Because of ARC we remove tableref from sub tables when this is deleted.
/*    for(Table *table in _tables) {
        NSLog(@"Delete...");
        table.table = TableRef();
    }*/
    _table = tightdb::TableRef();
    if (_tablePtr)
        delete _tablePtr;
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
-(ColumnType)getColumnType:(size_t)ndx
{
    return (ColumnType)_table->get_column_type(ndx);
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
    return _table->add_empty_row();
}
-(void)clear
{
    _table->clear();
}
-(void)deleteRow:(size_t)ndx
{
    _table->remove(ndx);
}
-(void)popBack
{
    _table->remove_last();
}
-(int64_t)get:(size_t)columnId ndx:(size_t)ndx
{
    return _table->get_int(columnId, ndx);
}
-(void)set:(size_t)columnId ndx:(size_t)ndx value:(int64_t)value
{
    _table->set_int(columnId, ndx, value);
}
-(BOOL)getBool:(size_t)columndId ndx:(size_t)ndx
{
    return _table->get_bool(columndId, ndx);
}
-(void)setBool:(size_t)columndId ndx:(size_t)ndx value:(BOOL)value
{
    _table->set_bool(columndId, ndx, value);
}
-(time_t)getDate:(size_t)columndId ndx:(size_t)ndx
{
    return _table->get_date(columndId, ndx);
}
-(void)setDate:(size_t)columndId ndx:(size_t)ndx value:(time_t)value
{
    _table->set_date(columndId, ndx, value);
}
-(void)insertInt:(size_t)columndId ndx:(size_t)ndx value:(int64_t)value
{
    _table->insert_int(columndId, ndx, value);
}
-(void)insertBool:(size_t)columndId ndx:(size_t)ndx value:(BOOL)value
{
    _table->insert_bool(columndId, ndx, value);
}
-(void)insertDate:(size_t)columndId ndx:(size_t)ndx value:(time_t)value
{
    _table->insert_date(columndId, ndx, value);
}
-(void)insertString:(size_t)columndId ndx:(size_t)ndx value:(NSString *)value
{
    _table->insert_string(columndId, ndx, [value UTF8String]);
}
-(void)insertBinary:(size_t)columndId ndx:(size_t)ndx value:(void *)value len:(size_t)len
{
    _table->insert_binary(columndId, ndx, (const char*)value, len);
}
-(void)insertDone
{
    _table->insert_done();
}

-(NSString *)getString:(size_t)columndId ndx:(size_t)ndx
{
    return [NSString stringWithUTF8String:_table->get_string(columndId, ndx)];
}
-(void)setString:(size_t)columndId ndx:(size_t)ndx value:(NSString *)value
{
    _table->set_string(columndId, ndx, [value UTF8String]);
}

-(BinaryData *)getBinary:(size_t)columndId ndx:(size_t)ndx
{
    return [[BinaryData alloc] initWithBinary:_table->get_binary(columndId, ndx)];
}
-(void)setBinary:(size_t)columndId ndx:(size_t)ndx value:(void *)value len:(size_t)len
{
    _table->set_binary(columndId, ndx, (const char*)value, len);
}

-(size_t)getTableSize:(size_t)columnId ndx:(size_t)ndx
{
    return _table->get_subtable_size(columnId, ndx);
}
-(void)insertTable:(size_t)columnId ndx:(size_t)ndx
{
    _table->insert_subtable(columnId, ndx);
}
-(void)clearTable:(size_t)columnId ndx:(size_t)ndx
{
    _table->clear_subtable(columnId, ndx);
}
-(OCMixed *)getMixed:(size_t)columnId ndx:(size_t)ndx
{
    tightdb::Mixed tmp = _table->get_mixed(columnId, ndx);
    return [OCMixed mixedWithMixed:tmp];
}
-(ColumnType)getMixedType:(size_t)columnId ndx:(size_t)ndx
{
    return (ColumnType)_table->get_mixed_type(columnId, ndx);
}
-(void)insertMixed:(size_t)columnId ndx:(size_t)ndx value:(OCMixed *)value
{
    _table->insert_mixed(columnId, ndx, value);
}
-(void)setMixed:(size_t)columnId ndx:(size_t)ndx value:(OCMixed *)value
{
    _table->set_mixed(columnId, ndx, value);
}

-(size_t)registerColumn:(ColumnType)type name:(NSString *)name
{
    return _table->add_column((tightdb::ColumnType)type, [name UTF8String]);
}
-(size_t)find:(size_t)columnId value:(int64_t)value
{
    return _table->find_first_int(columnId, value);
}
-(size_t)findBool:(size_t)columnId value:(BOOL)value
{
    return _table->find_first_bool(columnId, value);
}
-(size_t)findString:(size_t)columnId value:(NSString *)value
{
    return _table->find_first_string(columnId, [value UTF8String]);
}
-(size_t)findDate:(size_t)columnId value:(time_t)value
{
    return _table->find_first_date(columnId, value);
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
#ifdef _DEBUG
-(void)verify
{
    _table->Verify();
}
#endif
@end

// TODO - Dummy version of initWithBlock missing ...
@implementation OCTopLevelTable

-(id)initWithBlock:(TopLevelTableInitBlock)block
{
    // Dummy method - Will be overridden - sjhould just call super.
    return [super initWithBlock:block];
}
-(id)initWithTableRef:(tightdb::TableRef)ref
{
    self = [super initWithTableRef:ref];
    return self;
}
-(void)updateFromSpec
{
    static_cast<tightdb::Table *>(&*self.table)->update_from_spec();
}


-(CursorBase *)getCursor
{
    return nil; // Has to be overridden in TightDb.h
}
-(void)clearCursor
{
    // Dummy - must be overridden in TightDb.h
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len
{
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


#ifdef DEBUG
-(void)dealloc
{
    NSLog(@"OCTopLevelTable dealloc");
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

@implementation OCColumnProxyInt

-(size_t)find:(int64_t)value
{
    return [self.table find:self.column value:value];
}

-(size_t)findPos:(int64_t)value
{
    return 0; // TODO - [[self.table getColumn:self.column] findPos:value];
}

-(TableView *)findAll:(int64_t)value
{
    TableView *view = [TableView tableViewWithTable:self.table];
    return [self.table findAll:view column:self.column value:value];
}
@end


@implementation OCColumnProxyBool

-(size_t)find:(BOOL)value
{
    return [self.table findBool:self.column value:value];    
}

@end

@implementation OCColumnProxyDate

-(size_t)find:(time_t)value
{
    return [self.table findDate:self.column value:value];
}

@end

@implementation OCColumnProxyString

-(size_t)find:(NSString *)value
{
    return [self.table findString:self.column value:value];
}

@end
