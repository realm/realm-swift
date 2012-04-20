//
//  Table.mm
//  TightDB
//

#include "TightDb/Table.h"
#include "TightDb/alloc.h"
#import "Table.h"
#import "TablePriv.h"

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
    return _date->GetDate();
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
+(OCMixed *)mixedWithType:(ColumnType)type
{
    OCMixed *mixed = [[OCMixed alloc] init];
    
    mixed.mixed = new tightdb::Mixed(type);
    
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

+(OCMixed *)mixedWithBinary:(BinaryData)data
{
    OCMixed *mixed = [[OCMixed alloc] init];
    
    mixed.mixed = new tightdb::Mixed(data);
    
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
    return _mixed->GetType();
}
-(int64_t)getInt
{
    return _mixed->GetInt();
}
-(BOOL)getBool
{
    return _mixed->GetBool();
}

-(OCDate *)getDate
{
    return [[OCDate alloc] initWithDate:_mixed->GetDate()];
}

-(NSString *)getString
{
    return [NSString stringWithUTF8String:_mixed->GetString()];
}

-(BinaryData)getBinary
{
    return _mixed->GetBinary();
}
@end

#pragma mark - Spec

@interface OCSpec()
@property (nonatomic) tightdb::Spec *spec;
+(OCSpec *)specWithAllocator:(tightdb::Allocator&)allocator ref:(size_t)ref parent:(tightdb::ArrayParent*)parent pndx:(size_t)pndx;
+(OCSpec *)specWithSpec:(tightdb::Spec*)other;
@end
@implementation OCSpec
@synthesize spec = _spec;


// Dummy method - not used. allocators can probably not be overwritten with OC
+(OCSpec *)specWithAllocator:(tightdb::Allocator &)allocator ref:(size_t)ref parent:(tightdb::ArrayParent *)parent pndx:(size_t)pndx
{
    OCSpec *spec = [[OCSpec alloc] init];
//  TODO???  spec.spec = new Spec(allocator, ref, parent, pndx);
    return spec;
}
+(OCSpec *)specWithSpec:(tightdb::Spec *)other
{
    OCSpec *spec = [[OCSpec alloc] init];
    spec.spec = new tightdb::Spec(*other);
    return spec;    
}

-(void)addColumn:(ColumnType)type name:(NSString *)name
{
    _spec->AddColumn(type, [name UTF8String]);
}
-(OCSpec *)addColumnTable:(NSString *)name
{
    tightdb::Spec tmp = _spec->AddColumnTable([name UTF8String]);
    return [OCSpec specWithSpec:&tmp];
}
-(OCSpec *)getSpec:(size_t)columndId
{
    tightdb::Spec tmp = _spec->GetSpec(columndId);
    return [OCSpec specWithSpec:&tmp];
}
-(size_t)getColumnCount
{
    return _spec->GetColumnCount();
}
-(ColumnType)getColumnType:(size_t)ndx
{
    return _spec->GetColumnType(ndx);
}
-(NSString *)getColumnName:(size_t)ndx
{
    return [NSString stringWithUTF8String:_spec->GetColumnName(ndx)];
}
-(size_t)getColumnIndex:(NSString *)name
{
    return _spec->GetColumnIndex([name UTF8String]);
}
-(size_t)getRef
{
    return _spec->GetRef();
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
    delete _spec;
}


@end


#pragma mark - TableView

@interface TableView()
@property (nonatomic) tightdb::TableView *tableView;
@end
@implementation TableView
@synthesize tableView = _tableView;


+(TableView *)tableViewWithTable:(Table *)table
{
    TableView *tableView = [[TableView alloc] init];
    tableView.tableView = new tightdb::TableView(*[table getTable]);
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
    delete _tableView;
}

-(size_t)count
{
    return _tableView->GetSize();
}
-(BOOL)isEmpty
{
    return _tableView->IsEmpty();
}
-(int64_t)get:(size_t)columnId ndx:(size_t)ndx
{
    return _tableView->Get(columnId, ndx);
}
-(BOOL)getBool:(size_t)columnId ndx:(size_t)ndx
{
    return _tableView->GetBool(columnId, ndx);
}
-(time_t)getDate:(size_t)columnId ndx:(size_t)ndx
{
    return _tableView->GetDate(columnId, ndx);
}
-(NSString *)getString:(size_t)columnId ndx:(size_t)ndx
{
    return [NSString stringWithUTF8String:_tableView->GetString(columnId, ndx)];
}
-(void)delete:(size_t)ndx
{
    _tableView->Delete(ndx);
}
-(void)clear
{
    _tableView->Clear();
}
@end


#pragma mark - Table

@implementation Table
{
//    NSMutableArray *_tables; // Temp solution to refrain from deleting group before tables.
    id _parent;
}
@synthesize table = _table;
@synthesize tablePtr = _tablePtr;

-(id)initWithBlock:(TopLevelTableInitBlock)block
{
    self = [super init];
    if (self) {    
        if (block) block(self);
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

-(id)init
{
    self = [super init];
    if (self) {
        _tablePtr = new tightdb::TopLevelTable();
        _table = _tablePtr->GetTableRef(); 
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
    // NOTE: Because of ARC, we maintain an array of "owned" tables, so we can remove tableref before deleting parent tables.
/*    if (!_tables)
        _tables = [NSMutableArray arrayWithCapacity:5];
    [_tables addObject:[[Table alloc] initWithTableRef:_table->GetTable(columnId, ndx)]];
    return [_tables lastObject];*/
    Table *table = [[Table alloc] initWithTableRef:_table->GetTable(columnId, ndx)];
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
    return _table->GetColumnCount();
}
-(NSString *)getColumnName:(size_t)ndx
{
    return [NSString stringWithUTF8String:_table->GetColumnName(ndx)];
}
-(size_t)getColumnIndex:(NSString *)name
{
    return _table->GetColumnIndex([name UTF8String]);
}
-(ColumnType)getColumnType:(size_t)ndx
{
    return _table->GetColumnType(ndx);
}
-(OCSpec *)getSpec
{
    tightdb::Spec tmp = _table->GetSpec();
    return [OCSpec specWithSpec:&tmp];
}
-(BOOL)isEmpty
{
    return _table->IsEmpty();
}
-(size_t)count
{
    return _table->GetSize();
}
-(size_t)addRow
{
    return _table->AddRow();
}
-(void)clear
{
    _table->Clear();
}
-(void)deleteRow:(size_t)ndx
{
    _table->DeleteRow(ndx);
}
-(void)popBack
{
    _table->PopBack();
}
-(int64_t)get:(size_t)columnId ndx:(size_t)ndx
{
    return _table->Get(columnId, ndx);
}
-(void)set:(size_t)columnId ndx:(size_t)ndx value:(int64_t)value
{
    _table->Set(columnId, ndx, value);
}
-(BOOL)getBool:(size_t)columndId ndx:(size_t)ndx
{
    return _table->GetBool(columndId, ndx);
}
-(void)setBool:(size_t)columndId ndx:(size_t)ndx value:(BOOL)value
{
    _table->SetBool(columndId, ndx, value);
}
-(time_t)getDate:(size_t)columndId ndx:(size_t)ndx
{
    return _table->GetDate(columndId, ndx);
}
-(void)setDate:(size_t)columndId ndx:(size_t)ndx value:(time_t)value
{
    _table->SetDate(columndId, ndx, value);
}
-(void)insertInt:(size_t)columndId ndx:(size_t)ndx value:(int64_t)value
{
    _table->InsertInt(columndId, ndx, value);
}
-(void)insertBool:(size_t)columndId ndx:(size_t)ndx value:(BOOL)value
{
    _table->InsertBool(columndId, ndx, value);
}
-(void)insertDate:(size_t)columndId ndx:(size_t)ndx value:(time_t)value
{
    _table->InsertDate(columndId, ndx, value);
}
-(void)insertString:(size_t)columndId ndx:(size_t)ndx value:(NSString *)value
{
    _table->InsertString(columndId, ndx, [value UTF8String]);
}
-(void)insertBinary:(size_t)columndId ndx:(size_t)ndx value:(void *)value len:(size_t)len
{
    _table->InsertBinary(columndId, ndx, value, len);
}
-(void)insertDone
{
    _table->InsertDone();
}

-(NSString *)getString:(size_t)columndId ndx:(size_t)ndx
{
    return [NSString stringWithUTF8String:_table->GetString(columndId, ndx)];
}
-(void)setString:(size_t)columndId ndx:(size_t)ndx value:(NSString *)value
{
    _table->SetString(columndId, ndx, [value UTF8String]);
}

-(BinaryData)getBinary:(size_t)columndId ndx:(size_t)ndx
{
    return _table->GetBinary(columndId, ndx);
}
-(void)setBinary:(size_t)columndId ndx:(size_t)ndx value:(void *)value len:(size_t)len
{
    _table->SetBinary(columndId, ndx, value, len);
}

-(size_t)getTableSize:(size_t)columnId ndx:(size_t)ndx
{
    return _table->GetTableSize(columnId, ndx);
}
-(void)insertTable:(size_t)columnId ndx:(size_t)ndx
{
    _table->InsertTable(columnId, ndx);
}
-(void)clearTable:(size_t)columnId ndx:(size_t)ndx
{
    _table->ClearTable(columnId, ndx);
}
-(OCMixed *)getMixed:(size_t)columnId ndx:(size_t)ndx
{
    tightdb::Mixed tmp = _table->GetMixed(columnId, ndx);
    return [OCMixed mixedWithMixed:tmp];
}
-(ColumnType)getMixedType:(size_t)columnId ndx:(size_t)ndx
{
    return _table->GetMixedType(columnId, ndx);
}
-(void)insertMixed:(size_t)columnId ndx:(size_t)ndx value:(OCMixed *)value
{
    _table->InsertMixed(columnId, ndx, value);
}
-(void)setMixed:(size_t)columnId ndx:(size_t)ndx value:(OCMixed *)value
{
    _table->SetMixed(columnId, ndx, value);
}

-(size_t)registerColumn:(ColumnType)type name:(NSString *)name
{
    return _table->RegisterColumn(type, [name UTF8String]);
}
-(size_t)find:(size_t)columnId value:(int64_t)value
{
    return _table->Find(columnId, value);
}
-(size_t)findBool:(size_t)columnId value:(BOOL)value
{
    return _table->FindBool(columnId, value);
}
-(size_t)findString:(size_t)columnId value:(NSString *)value
{
    return _table->FindString(columnId, [value UTF8String]);
}
-(size_t)findDate:(size_t)columnId value:(time_t)value
{
    return _table->FindDate(columnId, value);
}

-(TableView *)findAll:(TableView *)view column:(size_t)columnId value:(int64_t)value
{
    _table->FindAll(*view.tableView, columnId, value);
    return view;
}

-(BOOL)hasIndex:(size_t)columnId
{
    return _table->HasIndex(columnId);
}
-(void)setIndex:(size_t)columnId
{
    _table->SetIndex(columnId);
}
-(void)optimize
{
    _table->Optimize();
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

-(void)updateFromSpec:(size_t)ref_specSet
{
    static_cast<tightdb::TopLevelTable *>(&*self.table)->UpdateFromSpec(ref_specSet);
}

-(size_t)getRef
{
    return static_cast<tightdb::TopLevelTable *>(&*self.table)->GetRef();
}

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