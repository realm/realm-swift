//
//  tightdb.h
//  TightDB
//

#import <tightdb/objc/table.h>
#import <tightdb/objc/query.h>
#import <tightdb/objc/cursor.h>

#undef TIGHTDB_TABLE_IMPL_1
#define TIGHTDB_TABLE_IMPL_1(TableName, CType1, CName1) \
@implementation TableName##_##Cursor \
    { \
        OCAccessor *_##CName1; \
    } \
    -(id)initWithTable:(Table *)table ndx:(size_t)ndx; \
    { \
    self = [super initWithTable:table ndx:ndx]; \
    if (self) { \
    _##CName1 = [[OCAccessor alloc] initWithCursor:self columnId:0]; \
    } \
    return self; \
    } \
    -(tdbOCType##CType1)CName1 \
    { \
        return [_##CName1 get##CType1]; \
    } \
    -(void)set##CName1:(tdbOCType##CType1)value \
    { \
    [_##CName1 set##CType1:value]; \
    } \
@end \
@implementation TableName##_##Query \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
    -(long)getFastEnumStart \
    { \
       return [self findNext:-1]; \
    } \
    -(long)incrementFastEnum:(long)ndx \
    { \
        return [self findNext:ndx]; \
    } \
    -(CursorBase *)getCursor:(long)ndx \
    { \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
    } \
@synthesize CName1 = _CName1; \
-(id)initWithTable:(Table *)table \
{ \
    self = [super initWithTable:table]; \
    if (self) { \
        _CName1 = [[TableName##QueryAccessor##CType1 alloc] initWithColumn:0 query:self]; \
    } \
    return self; \
} \
-(TableName##_##Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_##Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_##Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_##Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_##Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_##View *)findAll \
    { \
        return [[TableName##_##View alloc] initFromQuery:self]; \
    } \
@end \
@implementation TableName##QueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
-(TableName##_##Query *)notEqual:(size_t)value \
{ \
    return (TableName##_##Query *)[super notEqual:value]; \
} \
-(TableName##_##Query *)greater:(int64_t)value \
{ \
    return (TableName##_##Query *)[super greater:value]; \
} \
-(TableName##_##Query *)less:(int64_t)value \
{ \
    return (TableName##_##Query *)[super less:value]; \
} \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to \
{ \
    return (TableName##_##Query *)[super between:from to:to]; \
} \
@end \
@implementation TableName##QueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
@end \
@implementation TableName##QueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super equal:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super notEqual:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super beginsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super endsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super contains:value caseSensitive:caseSensitive]; \
} \
@end \
@implementation TableName \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
@synthesize CName1 = _##CName1; \
\
-(id)initWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        if ([self getColumnCount] == 0) { \
            [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        } \
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
    } \
    return self; \
} \
-(id)initCreateWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
    } \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
    } \
    return self; \
} \
-(void)add##CName1:(tdbOCType##CType1)CName1 \
{ \
    const size_t ndx = [self count]; \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 \
{ \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insertDone]; \
} \
-(TableName##_##Query *)getQuery \
{ \
    return [[TableName##_##Query alloc] initWithTable:self]; \
} \
-(TableName##_##Cursor *)add \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self addRow]]; \
} \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:ndx]; \
} \
-(TableName##_##Cursor *)lastObject \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self count]-1]; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:self ndx:0]; \
} \
@end \
@implementation TableName##_##View \
    { \
        TableName##_##Cursor *tmpCursor; \
    } \
    -(CursorBase *)getCursor \
    { \
        return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
    } \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
    { \
    return [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
    } \
@end

#undef TIGHTDB_TABLE_IMPL_2
#define TIGHTDB_TABLE_IMPL_2(TableName, CType1, CName1, CType2, CName2) \
@implementation TableName##_##Cursor \
    { \
        OCAccessor *_##CName1; \
        OCAccessor *_##CName2; \
    } \
    -(id)initWithTable:(Table *)table ndx:(size_t)ndx; \
    { \
    self = [super initWithTable:table ndx:ndx]; \
    if (self) { \
    _##CName1 = [[OCAccessor alloc] initWithCursor:self columnId:0]; \
    _##CName2 = [[OCAccessor alloc] initWithCursor:self columnId:1]; \
    } \
    return self; \
    } \
    -(tdbOCType##CType1)CName1 \
    { \
        return [_##CName1 get##CType1]; \
    } \
    -(void)set##CName1:(tdbOCType##CType1)value \
    { \
    [_##CName1 set##CType1:value]; \
    } \
    -(tdbOCType##CType2)CName2 \
    { \
        return [_##CName2 get##CType2]; \
    } \
    -(void)set##CName2:(tdbOCType##CType2)value \
    { \
    [_##CName2 set##CType2:value]; \
    } \
@end \
@implementation TableName##_##Query \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
    -(long)getFastEnumStart \
    { \
       return [self findNext:-1]; \
    } \
    -(long)incrementFastEnum:(long)ndx \
    { \
        return [self findNext:ndx]; \
    } \
    -(CursorBase *)getCursor:(long)ndx \
    { \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
    } \
@synthesize CName1 = _CName1; \
@synthesize CName2 = _CName2; \
-(id)initWithTable:(Table *)table \
{ \
    self = [super initWithTable:table]; \
    if (self) { \
        _CName1 = [[TableName##QueryAccessor##CType1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##QueryAccessor##CType2 alloc] initWithColumn:1 query:self]; \
    } \
    return self; \
} \
-(TableName##_##Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_##Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_##Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_##Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_##Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_##View *)findAll \
    { \
        return [[TableName##_##View alloc] initFromQuery:self]; \
    } \
@end \
@implementation TableName##QueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
-(TableName##_##Query *)notEqual:(size_t)value \
{ \
    return (TableName##_##Query *)[super notEqual:value]; \
} \
-(TableName##_##Query *)greater:(int64_t)value \
{ \
    return (TableName##_##Query *)[super greater:value]; \
} \
-(TableName##_##Query *)less:(int64_t)value \
{ \
    return (TableName##_##Query *)[super less:value]; \
} \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to \
{ \
    return (TableName##_##Query *)[super between:from to:to]; \
} \
@end \
@implementation TableName##QueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
@end \
@implementation TableName##QueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super equal:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super notEqual:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super beginsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super endsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super contains:value caseSensitive:caseSensitive]; \
} \
@end \
@implementation TableName \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
@synthesize CName1 = _##CName1; \
@synthesize CName2 = _##CName2; \
\
-(id)initWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        if ([self getColumnCount] == 0) { \
            [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
            [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        } \
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
    } \
    return self; \
} \
-(id)initCreateWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
    } \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
    } \
    return self; \
} \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 \
{ \
    const size_t ndx = [self count]; \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 \
{ \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insertDone]; \
} \
-(TableName##_##Query *)getQuery \
{ \
    return [[TableName##_##Query alloc] initWithTable:self]; \
} \
-(TableName##_##Cursor *)add \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self addRow]]; \
} \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:ndx]; \
} \
-(TableName##_##Cursor *)lastObject \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self count]-1]; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:self ndx:0]; \
} \
@end \
@implementation TableName##_##View \
    { \
        TableName##_##Cursor *tmpCursor; \
    } \
    -(CursorBase *)getCursor \
    { \
        return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
    } \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
    { \
    return [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
    } \
@end

#undef TIGHTDB_TABLE_IMPL_3
#define TIGHTDB_TABLE_IMPL_3(TableName, CType1, CName1, CType2, CName2, CType3, CName3) \
@implementation TableName##_##Cursor \
    { \
        OCAccessor *_##CName1; \
        OCAccessor *_##CName2; \
        OCAccessor *_##CName3; \
    } \
    -(id)initWithTable:(Table *)table ndx:(size_t)ndx; \
    { \
    self = [super initWithTable:table ndx:ndx]; \
    if (self) { \
    _##CName1 = [[OCAccessor alloc] initWithCursor:self columnId:0]; \
    _##CName2 = [[OCAccessor alloc] initWithCursor:self columnId:1]; \
    _##CName3 = [[OCAccessor alloc] initWithCursor:self columnId:2]; \
    } \
    return self; \
    } \
    -(tdbOCType##CType1)CName1 \
    { \
        return [_##CName1 get##CType1]; \
    } \
    -(void)set##CName1:(tdbOCType##CType1)value \
    { \
    [_##CName1 set##CType1:value]; \
    } \
    -(tdbOCType##CType2)CName2 \
    { \
        return [_##CName2 get##CType2]; \
    } \
    -(void)set##CName2:(tdbOCType##CType2)value \
    { \
    [_##CName2 set##CType2:value]; \
    } \
    -(tdbOCType##CType3)CName3 \
    { \
        return [_##CName3 get##CType3]; \
    } \
    -(void)set##CName3:(tdbOCType##CType3)value \
    { \
    [_##CName3 set##CType3:value]; \
    } \
@end \
@implementation TableName##_##Query \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
    -(long)getFastEnumStart \
    { \
       return [self findNext:-1]; \
    } \
    -(long)incrementFastEnum:(long)ndx \
    { \
        return [self findNext:ndx]; \
    } \
    -(CursorBase *)getCursor:(long)ndx \
    { \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
    } \
@synthesize CName1 = _CName1; \
@synthesize CName2 = _CName2; \
@synthesize CName3 = _CName3; \
-(id)initWithTable:(Table *)table \
{ \
    self = [super initWithTable:table]; \
    if (self) { \
        _CName1 = [[TableName##QueryAccessor##CType1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##QueryAccessor##CType2 alloc] initWithColumn:1 query:self]; \
        _CName3 = [[TableName##QueryAccessor##CType3 alloc] initWithColumn:2 query:self]; \
    } \
    return self; \
} \
-(TableName##_##Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_##Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_##Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_##Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_##Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_##View *)findAll \
    { \
        return [[TableName##_##View alloc] initFromQuery:self]; \
    } \
@end \
@implementation TableName##QueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
-(TableName##_##Query *)notEqual:(size_t)value \
{ \
    return (TableName##_##Query *)[super notEqual:value]; \
} \
-(TableName##_##Query *)greater:(int64_t)value \
{ \
    return (TableName##_##Query *)[super greater:value]; \
} \
-(TableName##_##Query *)less:(int64_t)value \
{ \
    return (TableName##_##Query *)[super less:value]; \
} \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to \
{ \
    return (TableName##_##Query *)[super between:from to:to]; \
} \
@end \
@implementation TableName##QueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
@end \
@implementation TableName##QueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super equal:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super notEqual:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super beginsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super endsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super contains:value caseSensitive:caseSensitive]; \
} \
@end \
@implementation TableName \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
@synthesize CName1 = _##CName1; \
@synthesize CName2 = _##CName2; \
@synthesize CName3 = _##CName3; \
\
-(id)initWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        if ([self getColumnCount] == 0) { \
            [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
            [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
            [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
        } \
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
    } \
    return self; \
} \
-(id)initCreateWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
    } \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
    } \
    return self; \
} \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 \
{ \
    const size_t ndx = [self count]; \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 \
{ \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insertDone]; \
} \
-(TableName##_##Query *)getQuery \
{ \
    return [[TableName##_##Query alloc] initWithTable:self]; \
} \
-(TableName##_##Cursor *)add \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self addRow]]; \
} \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:ndx]; \
} \
-(TableName##_##Cursor *)lastObject \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self count]-1]; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:self ndx:0]; \
} \
@end \
@implementation TableName##_##View \
    { \
        TableName##_##Cursor *tmpCursor; \
    } \
    -(CursorBase *)getCursor \
    { \
        return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
    } \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
    { \
    return [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
    } \
@end

#undef TIGHTDB_TABLE_IMPL_4
#define TIGHTDB_TABLE_IMPL_4(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4) \
@implementation TableName##_##Cursor \
    { \
        OCAccessor *_##CName1; \
        OCAccessor *_##CName2; \
        OCAccessor *_##CName3; \
        OCAccessor *_##CName4; \
    } \
    -(id)initWithTable:(Table *)table ndx:(size_t)ndx; \
    { \
    self = [super initWithTable:table ndx:ndx]; \
    if (self) { \
    _##CName1 = [[OCAccessor alloc] initWithCursor:self columnId:0]; \
    _##CName2 = [[OCAccessor alloc] initWithCursor:self columnId:1]; \
    _##CName3 = [[OCAccessor alloc] initWithCursor:self columnId:2]; \
    _##CName4 = [[OCAccessor alloc] initWithCursor:self columnId:3]; \
    } \
    return self; \
    } \
    -(tdbOCType##CType1)CName1 \
    { \
        return [_##CName1 get##CType1]; \
    } \
    -(void)set##CName1:(tdbOCType##CType1)value \
    { \
    [_##CName1 set##CType1:value]; \
    } \
    -(tdbOCType##CType2)CName2 \
    { \
        return [_##CName2 get##CType2]; \
    } \
    -(void)set##CName2:(tdbOCType##CType2)value \
    { \
    [_##CName2 set##CType2:value]; \
    } \
    -(tdbOCType##CType3)CName3 \
    { \
        return [_##CName3 get##CType3]; \
    } \
    -(void)set##CName3:(tdbOCType##CType3)value \
    { \
    [_##CName3 set##CType3:value]; \
    } \
    -(tdbOCType##CType4)CName4 \
    { \
        return [_##CName4 get##CType4]; \
    } \
    -(void)set##CName4:(tdbOCType##CType4)value \
    { \
    [_##CName4 set##CType4:value]; \
    } \
@end \
@implementation TableName##_##Query \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
    -(long)getFastEnumStart \
    { \
       return [self findNext:-1]; \
    } \
    -(long)incrementFastEnum:(long)ndx \
    { \
        return [self findNext:ndx]; \
    } \
    -(CursorBase *)getCursor:(long)ndx \
    { \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
    } \
@synthesize CName1 = _CName1; \
@synthesize CName2 = _CName2; \
@synthesize CName3 = _CName3; \
@synthesize CName4 = _CName4; \
-(id)initWithTable:(Table *)table \
{ \
    self = [super initWithTable:table]; \
    if (self) { \
        _CName1 = [[TableName##QueryAccessor##CType1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##QueryAccessor##CType2 alloc] initWithColumn:1 query:self]; \
        _CName3 = [[TableName##QueryAccessor##CType3 alloc] initWithColumn:2 query:self]; \
        _CName4 = [[TableName##QueryAccessor##CType4 alloc] initWithColumn:3 query:self]; \
    } \
    return self; \
} \
-(TableName##_##Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_##Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_##Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_##Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_##Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_##View *)findAll \
    { \
        return [[TableName##_##View alloc] initFromQuery:self]; \
    } \
@end \
@implementation TableName##QueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
-(TableName##_##Query *)notEqual:(size_t)value \
{ \
    return (TableName##_##Query *)[super notEqual:value]; \
} \
-(TableName##_##Query *)greater:(int64_t)value \
{ \
    return (TableName##_##Query *)[super greater:value]; \
} \
-(TableName##_##Query *)less:(int64_t)value \
{ \
    return (TableName##_##Query *)[super less:value]; \
} \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to \
{ \
    return (TableName##_##Query *)[super between:from to:to]; \
} \
@end \
@implementation TableName##QueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
@end \
@implementation TableName##QueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super equal:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super notEqual:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super beginsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super endsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super contains:value caseSensitive:caseSensitive]; \
} \
@end \
@implementation TableName \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
@synthesize CName1 = _##CName1; \
@synthesize CName2 = _##CName2; \
@synthesize CName3 = _##CName3; \
@synthesize CName4 = _##CName4; \
\
-(id)initWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        if ([self getColumnCount] == 0) { \
            [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
            [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
            [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
            [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
        } \
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
    } \
    return self; \
} \
-(id)initCreateWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
        [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
    } \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
        [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
    } \
    return self; \
} \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 \
{ \
    const size_t ndx = [self count]; \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insert##CType4:3 ndx:ndx value:CName4]; \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 \
{ \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insert##CType4:3 ndx:ndx value:CName4]; \
    [self insertDone]; \
} \
-(TableName##_##Query *)getQuery \
{ \
    return [[TableName##_##Query alloc] initWithTable:self]; \
} \
-(TableName##_##Cursor *)add \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self addRow]]; \
} \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:ndx]; \
} \
-(TableName##_##Cursor *)lastObject \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self count]-1]; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:self ndx:0]; \
} \
@end \
@implementation TableName##_##View \
    { \
        TableName##_##Cursor *tmpCursor; \
    } \
    -(CursorBase *)getCursor \
    { \
        return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
    } \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
    { \
    return [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
    } \
@end

#undef TIGHTDB_TABLE_IMPL_5
#define TIGHTDB_TABLE_IMPL_5(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5) \
@implementation TableName##_##Cursor \
    { \
        OCAccessor *_##CName1; \
        OCAccessor *_##CName2; \
        OCAccessor *_##CName3; \
        OCAccessor *_##CName4; \
        OCAccessor *_##CName5; \
    } \
    -(id)initWithTable:(Table *)table ndx:(size_t)ndx; \
    { \
    self = [super initWithTable:table ndx:ndx]; \
    if (self) { \
    _##CName1 = [[OCAccessor alloc] initWithCursor:self columnId:0]; \
    _##CName2 = [[OCAccessor alloc] initWithCursor:self columnId:1]; \
    _##CName3 = [[OCAccessor alloc] initWithCursor:self columnId:2]; \
    _##CName4 = [[OCAccessor alloc] initWithCursor:self columnId:3]; \
    _##CName5 = [[OCAccessor alloc] initWithCursor:self columnId:4]; \
    } \
    return self; \
    } \
    -(tdbOCType##CType1)CName1 \
    { \
        return [_##CName1 get##CType1]; \
    } \
    -(void)set##CName1:(tdbOCType##CType1)value \
    { \
    [_##CName1 set##CType1:value]; \
    } \
    -(tdbOCType##CType2)CName2 \
    { \
        return [_##CName2 get##CType2]; \
    } \
    -(void)set##CName2:(tdbOCType##CType2)value \
    { \
    [_##CName2 set##CType2:value]; \
    } \
    -(tdbOCType##CType3)CName3 \
    { \
        return [_##CName3 get##CType3]; \
    } \
    -(void)set##CName3:(tdbOCType##CType3)value \
    { \
    [_##CName3 set##CType3:value]; \
    } \
    -(tdbOCType##CType4)CName4 \
    { \
        return [_##CName4 get##CType4]; \
    } \
    -(void)set##CName4:(tdbOCType##CType4)value \
    { \
    [_##CName4 set##CType4:value]; \
    } \
    -(tdbOCType##CType5)CName5 \
    { \
        return [_##CName5 get##CType5]; \
    } \
    -(void)set##CName5:(tdbOCType##CType5)value \
    { \
    [_##CName5 set##CType5:value]; \
    } \
@end \
@implementation TableName##_##Query \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
    -(long)getFastEnumStart \
    { \
       return [self findNext:-1]; \
    } \
    -(long)incrementFastEnum:(long)ndx \
    { \
        return [self findNext:ndx]; \
    } \
    -(CursorBase *)getCursor:(long)ndx \
    { \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
    } \
@synthesize CName1 = _CName1; \
@synthesize CName2 = _CName2; \
@synthesize CName3 = _CName3; \
@synthesize CName4 = _CName4; \
@synthesize CName5 = _CName5; \
-(id)initWithTable:(Table *)table \
{ \
    self = [super initWithTable:table]; \
    if (self) { \
        _CName1 = [[TableName##QueryAccessor##CType1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##QueryAccessor##CType2 alloc] initWithColumn:1 query:self]; \
        _CName3 = [[TableName##QueryAccessor##CType3 alloc] initWithColumn:2 query:self]; \
        _CName4 = [[TableName##QueryAccessor##CType4 alloc] initWithColumn:3 query:self]; \
        _CName5 = [[TableName##QueryAccessor##CType5 alloc] initWithColumn:4 query:self]; \
    } \
    return self; \
} \
-(TableName##_##Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_##Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_##Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_##Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_##Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_##View *)findAll \
    { \
        return [[TableName##_##View alloc] initFromQuery:self]; \
    } \
@end \
@implementation TableName##QueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
-(TableName##_##Query *)notEqual:(size_t)value \
{ \
    return (TableName##_##Query *)[super notEqual:value]; \
} \
-(TableName##_##Query *)greater:(int64_t)value \
{ \
    return (TableName##_##Query *)[super greater:value]; \
} \
-(TableName##_##Query *)less:(int64_t)value \
{ \
    return (TableName##_##Query *)[super less:value]; \
} \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to \
{ \
    return (TableName##_##Query *)[super between:from to:to]; \
} \
@end \
@implementation TableName##QueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
@end \
@implementation TableName##QueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super equal:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super notEqual:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super beginsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super endsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super contains:value caseSensitive:caseSensitive]; \
} \
@end \
@implementation TableName \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
@synthesize CName1 = _##CName1; \
@synthesize CName2 = _##CName2; \
@synthesize CName3 = _##CName3; \
@synthesize CName4 = _##CName4; \
@synthesize CName5 = _##CName5; \
\
-(id)initWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        if ([self getColumnCount] == 0) { \
            [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
            [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
            [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
            [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
            [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
        } \
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
    } \
    return self; \
} \
-(id)initCreateWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
        [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
        [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
    } \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
        [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
        [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
    } \
    return self; \
} \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 \
{ \
    const size_t ndx = [self count]; \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insert##CType4:3 ndx:ndx value:CName4]; \
    [self insert##CType5:4 ndx:ndx value:CName5]; \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 \
{ \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insert##CType4:3 ndx:ndx value:CName4]; \
    [self insert##CType5:4 ndx:ndx value:CName5]; \
    [self insertDone]; \
} \
-(TableName##_##Query *)getQuery \
{ \
    return [[TableName##_##Query alloc] initWithTable:self]; \
} \
-(TableName##_##Cursor *)add \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self addRow]]; \
} \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:ndx]; \
} \
-(TableName##_##Cursor *)lastObject \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self count]-1]; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:self ndx:0]; \
} \
@end \
@implementation TableName##_##View \
    { \
        TableName##_##Cursor *tmpCursor; \
    } \
    -(CursorBase *)getCursor \
    { \
        return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
    } \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
    { \
    return [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
    } \
@end

#undef TIGHTDB_TABLE_IMPL_6
#define TIGHTDB_TABLE_IMPL_6(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6) \
@implementation TableName##_##Cursor \
    { \
        OCAccessor *_##CName1; \
        OCAccessor *_##CName2; \
        OCAccessor *_##CName3; \
        OCAccessor *_##CName4; \
        OCAccessor *_##CName5; \
        OCAccessor *_##CName6; \
    } \
    -(id)initWithTable:(Table *)table ndx:(size_t)ndx; \
    { \
    self = [super initWithTable:table ndx:ndx]; \
    if (self) { \
    _##CName1 = [[OCAccessor alloc] initWithCursor:self columnId:0]; \
    _##CName2 = [[OCAccessor alloc] initWithCursor:self columnId:1]; \
    _##CName3 = [[OCAccessor alloc] initWithCursor:self columnId:2]; \
    _##CName4 = [[OCAccessor alloc] initWithCursor:self columnId:3]; \
    _##CName5 = [[OCAccessor alloc] initWithCursor:self columnId:4]; \
    _##CName6 = [[OCAccessor alloc] initWithCursor:self columnId:5]; \
    } \
    return self; \
    } \
    -(tdbOCType##CType1)CName1 \
    { \
        return [_##CName1 get##CType1]; \
    } \
    -(void)set##CName1:(tdbOCType##CType1)value \
    { \
    [_##CName1 set##CType1:value]; \
    } \
    -(tdbOCType##CType2)CName2 \
    { \
        return [_##CName2 get##CType2]; \
    } \
    -(void)set##CName2:(tdbOCType##CType2)value \
    { \
    [_##CName2 set##CType2:value]; \
    } \
    -(tdbOCType##CType3)CName3 \
    { \
        return [_##CName3 get##CType3]; \
    } \
    -(void)set##CName3:(tdbOCType##CType3)value \
    { \
    [_##CName3 set##CType3:value]; \
    } \
    -(tdbOCType##CType4)CName4 \
    { \
        return [_##CName4 get##CType4]; \
    } \
    -(void)set##CName4:(tdbOCType##CType4)value \
    { \
    [_##CName4 set##CType4:value]; \
    } \
    -(tdbOCType##CType5)CName5 \
    { \
        return [_##CName5 get##CType5]; \
    } \
    -(void)set##CName5:(tdbOCType##CType5)value \
    { \
    [_##CName5 set##CType5:value]; \
    } \
    -(tdbOCType##CType6)CName6 \
    { \
        return [_##CName6 get##CType6]; \
    } \
    -(void)set##CName6:(tdbOCType##CType6)value \
    { \
    [_##CName6 set##CType6:value]; \
    } \
@end \
@implementation TableName##_##Query \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
    -(long)getFastEnumStart \
    { \
       return [self findNext:-1]; \
    } \
    -(long)incrementFastEnum:(long)ndx \
    { \
        return [self findNext:ndx]; \
    } \
    -(CursorBase *)getCursor:(long)ndx \
    { \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
    } \
@synthesize CName1 = _CName1; \
@synthesize CName2 = _CName2; \
@synthesize CName3 = _CName3; \
@synthesize CName4 = _CName4; \
@synthesize CName5 = _CName5; \
@synthesize CName6 = _CName6; \
-(id)initWithTable:(Table *)table \
{ \
    self = [super initWithTable:table]; \
    if (self) { \
        _CName1 = [[TableName##QueryAccessor##CType1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##QueryAccessor##CType2 alloc] initWithColumn:1 query:self]; \
        _CName3 = [[TableName##QueryAccessor##CType3 alloc] initWithColumn:2 query:self]; \
        _CName4 = [[TableName##QueryAccessor##CType4 alloc] initWithColumn:3 query:self]; \
        _CName5 = [[TableName##QueryAccessor##CType5 alloc] initWithColumn:4 query:self]; \
        _CName6 = [[TableName##QueryAccessor##CType6 alloc] initWithColumn:5 query:self]; \
    } \
    return self; \
} \
-(TableName##_##Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_##Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_##Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_##Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_##Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_##View *)findAll \
    { \
        return [[TableName##_##View alloc] initFromQuery:self]; \
    } \
@end \
@implementation TableName##QueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
-(TableName##_##Query *)notEqual:(size_t)value \
{ \
    return (TableName##_##Query *)[super notEqual:value]; \
} \
-(TableName##_##Query *)greater:(int64_t)value \
{ \
    return (TableName##_##Query *)[super greater:value]; \
} \
-(TableName##_##Query *)less:(int64_t)value \
{ \
    return (TableName##_##Query *)[super less:value]; \
} \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to \
{ \
    return (TableName##_##Query *)[super between:from to:to]; \
} \
@end \
@implementation TableName##QueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
@end \
@implementation TableName##QueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super equal:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super notEqual:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super beginsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super endsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super contains:value caseSensitive:caseSensitive]; \
} \
@end \
@implementation TableName \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
@synthesize CName1 = _##CName1; \
@synthesize CName2 = _##CName2; \
@synthesize CName3 = _##CName3; \
@synthesize CName4 = _##CName4; \
@synthesize CName5 = _##CName5; \
@synthesize CName6 = _##CName6; \
\
-(id)initWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        if ([self getColumnCount] == 0) { \
            [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
            [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
            [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
            [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
            [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
            [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
        } \
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
    } \
    return self; \
} \
-(id)initCreateWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
        [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
        [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
        [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
    } \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
        [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
        [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
        [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
    } \
    return self; \
} \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 \
{ \
    const size_t ndx = [self count]; \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insert##CType4:3 ndx:ndx value:CName4]; \
    [self insert##CType5:4 ndx:ndx value:CName5]; \
    [self insert##CType6:5 ndx:ndx value:CName6]; \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 \
{ \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insert##CType4:3 ndx:ndx value:CName4]; \
    [self insert##CType5:4 ndx:ndx value:CName5]; \
    [self insert##CType6:5 ndx:ndx value:CName6]; \
    [self insertDone]; \
} \
-(TableName##_##Query *)getQuery \
{ \
    return [[TableName##_##Query alloc] initWithTable:self]; \
} \
-(TableName##_##Cursor *)add \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self addRow]]; \
} \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:ndx]; \
} \
-(TableName##_##Cursor *)lastObject \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self count]-1]; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:self ndx:0]; \
} \
@end \
@implementation TableName##_##View \
    { \
        TableName##_##Cursor *tmpCursor; \
    } \
    -(CursorBase *)getCursor \
    { \
        return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
    } \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
    { \
    return [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
    } \
@end

#undef TIGHTDB_TABLE_IMPL_7
#define TIGHTDB_TABLE_IMPL_7(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7) \
@implementation TableName##_##Cursor \
    { \
        OCAccessor *_##CName1; \
        OCAccessor *_##CName2; \
        OCAccessor *_##CName3; \
        OCAccessor *_##CName4; \
        OCAccessor *_##CName5; \
        OCAccessor *_##CName6; \
        OCAccessor *_##CName7; \
    } \
    -(id)initWithTable:(Table *)table ndx:(size_t)ndx; \
    { \
    self = [super initWithTable:table ndx:ndx]; \
    if (self) { \
    _##CName1 = [[OCAccessor alloc] initWithCursor:self columnId:0]; \
    _##CName2 = [[OCAccessor alloc] initWithCursor:self columnId:1]; \
    _##CName3 = [[OCAccessor alloc] initWithCursor:self columnId:2]; \
    _##CName4 = [[OCAccessor alloc] initWithCursor:self columnId:3]; \
    _##CName5 = [[OCAccessor alloc] initWithCursor:self columnId:4]; \
    _##CName6 = [[OCAccessor alloc] initWithCursor:self columnId:5]; \
    _##CName7 = [[OCAccessor alloc] initWithCursor:self columnId:6]; \
    } \
    return self; \
    } \
    -(tdbOCType##CType1)CName1 \
    { \
        return [_##CName1 get##CType1]; \
    } \
    -(void)set##CName1:(tdbOCType##CType1)value \
    { \
    [_##CName1 set##CType1:value]; \
    } \
    -(tdbOCType##CType2)CName2 \
    { \
        return [_##CName2 get##CType2]; \
    } \
    -(void)set##CName2:(tdbOCType##CType2)value \
    { \
    [_##CName2 set##CType2:value]; \
    } \
    -(tdbOCType##CType3)CName3 \
    { \
        return [_##CName3 get##CType3]; \
    } \
    -(void)set##CName3:(tdbOCType##CType3)value \
    { \
    [_##CName3 set##CType3:value]; \
    } \
    -(tdbOCType##CType4)CName4 \
    { \
        return [_##CName4 get##CType4]; \
    } \
    -(void)set##CName4:(tdbOCType##CType4)value \
    { \
    [_##CName4 set##CType4:value]; \
    } \
    -(tdbOCType##CType5)CName5 \
    { \
        return [_##CName5 get##CType5]; \
    } \
    -(void)set##CName5:(tdbOCType##CType5)value \
    { \
    [_##CName5 set##CType5:value]; \
    } \
    -(tdbOCType##CType6)CName6 \
    { \
        return [_##CName6 get##CType6]; \
    } \
    -(void)set##CName6:(tdbOCType##CType6)value \
    { \
    [_##CName6 set##CType6:value]; \
    } \
    -(tdbOCType##CType7)CName7 \
    { \
        return [_##CName7 get##CType7]; \
    } \
    -(void)set##CName7:(tdbOCType##CType7)value \
    { \
    [_##CName7 set##CType7:value]; \
    } \
@end \
@implementation TableName##_##Query \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
    -(long)getFastEnumStart \
    { \
       return [self findNext:-1]; \
    } \
    -(long)incrementFastEnum:(long)ndx \
    { \
        return [self findNext:ndx]; \
    } \
    -(CursorBase *)getCursor:(long)ndx \
    { \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
    } \
@synthesize CName1 = _CName1; \
@synthesize CName2 = _CName2; \
@synthesize CName3 = _CName3; \
@synthesize CName4 = _CName4; \
@synthesize CName5 = _CName5; \
@synthesize CName6 = _CName6; \
@synthesize CName7 = _CName7; \
-(id)initWithTable:(Table *)table \
{ \
    self = [super initWithTable:table]; \
    if (self) { \
        _CName1 = [[TableName##QueryAccessor##CType1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##QueryAccessor##CType2 alloc] initWithColumn:1 query:self]; \
        _CName3 = [[TableName##QueryAccessor##CType3 alloc] initWithColumn:2 query:self]; \
        _CName4 = [[TableName##QueryAccessor##CType4 alloc] initWithColumn:3 query:self]; \
        _CName5 = [[TableName##QueryAccessor##CType5 alloc] initWithColumn:4 query:self]; \
        _CName6 = [[TableName##QueryAccessor##CType6 alloc] initWithColumn:5 query:self]; \
        _CName7 = [[TableName##QueryAccessor##CType7 alloc] initWithColumn:6 query:self]; \
    } \
    return self; \
} \
-(TableName##_##Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_##Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_##Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_##Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_##Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_##View *)findAll \
    { \
        return [[TableName##_##View alloc] initFromQuery:self]; \
    } \
@end \
@implementation TableName##QueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
-(TableName##_##Query *)notEqual:(size_t)value \
{ \
    return (TableName##_##Query *)[super notEqual:value]; \
} \
-(TableName##_##Query *)greater:(int64_t)value \
{ \
    return (TableName##_##Query *)[super greater:value]; \
} \
-(TableName##_##Query *)less:(int64_t)value \
{ \
    return (TableName##_##Query *)[super less:value]; \
} \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to \
{ \
    return (TableName##_##Query *)[super between:from to:to]; \
} \
@end \
@implementation TableName##QueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
@end \
@implementation TableName##QueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super equal:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super notEqual:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super beginsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super endsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super contains:value caseSensitive:caseSensitive]; \
} \
@end \
@implementation TableName \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
@synthesize CName1 = _##CName1; \
@synthesize CName2 = _##CName2; \
@synthesize CName3 = _##CName3; \
@synthesize CName4 = _##CName4; \
@synthesize CName5 = _##CName5; \
@synthesize CName6 = _##CName6; \
@synthesize CName7 = _##CName7; \
\
-(id)initWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        if ([self getColumnCount] == 0) { \
            [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
            [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
            [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
            [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
            [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
            [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
            [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
        } \
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
    } \
    return self; \
} \
-(id)initCreateWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
        [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
        [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
        [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
        [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
    } \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
        [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
        [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
        [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
        [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
    } \
    return self; \
} \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 \
{ \
    const size_t ndx = [self count]; \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insert##CType4:3 ndx:ndx value:CName4]; \
    [self insert##CType5:4 ndx:ndx value:CName5]; \
    [self insert##CType6:5 ndx:ndx value:CName6]; \
    [self insert##CType7:6 ndx:ndx value:CName7]; \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 \
{ \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insert##CType4:3 ndx:ndx value:CName4]; \
    [self insert##CType5:4 ndx:ndx value:CName5]; \
    [self insert##CType6:5 ndx:ndx value:CName6]; \
    [self insert##CType7:6 ndx:ndx value:CName7]; \
    [self insertDone]; \
} \
-(TableName##_##Query *)getQuery \
{ \
    return [[TableName##_##Query alloc] initWithTable:self]; \
} \
-(TableName##_##Cursor *)add \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self addRow]]; \
} \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:ndx]; \
} \
-(TableName##_##Cursor *)lastObject \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self count]-1]; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:self ndx:0]; \
} \
@end \
@implementation TableName##_##View \
    { \
        TableName##_##Cursor *tmpCursor; \
    } \
    -(CursorBase *)getCursor \
    { \
        return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
    } \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
    { \
    return [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
    } \
@end

#undef TIGHTDB_TABLE_IMPL_8
#define TIGHTDB_TABLE_IMPL_8(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8) \
@implementation TableName##_##Cursor \
    { \
        OCAccessor *_##CName1; \
        OCAccessor *_##CName2; \
        OCAccessor *_##CName3; \
        OCAccessor *_##CName4; \
        OCAccessor *_##CName5; \
        OCAccessor *_##CName6; \
        OCAccessor *_##CName7; \
        OCAccessor *_##CName8; \
    } \
    -(id)initWithTable:(Table *)table ndx:(size_t)ndx; \
    { \
    self = [super initWithTable:table ndx:ndx]; \
    if (self) { \
    _##CName1 = [[OCAccessor alloc] initWithCursor:self columnId:0]; \
    _##CName2 = [[OCAccessor alloc] initWithCursor:self columnId:1]; \
    _##CName3 = [[OCAccessor alloc] initWithCursor:self columnId:2]; \
    _##CName4 = [[OCAccessor alloc] initWithCursor:self columnId:3]; \
    _##CName5 = [[OCAccessor alloc] initWithCursor:self columnId:4]; \
    _##CName6 = [[OCAccessor alloc] initWithCursor:self columnId:5]; \
    _##CName7 = [[OCAccessor alloc] initWithCursor:self columnId:6]; \
    _##CName8 = [[OCAccessor alloc] initWithCursor:self columnId:7]; \
    } \
    return self; \
    } \
    -(tdbOCType##CType1)CName1 \
    { \
        return [_##CName1 get##CType1]; \
    } \
    -(void)set##CName1:(tdbOCType##CType1)value \
    { \
    [_##CName1 set##CType1:value]; \
    } \
    -(tdbOCType##CType2)CName2 \
    { \
        return [_##CName2 get##CType2]; \
    } \
    -(void)set##CName2:(tdbOCType##CType2)value \
    { \
    [_##CName2 set##CType2:value]; \
    } \
    -(tdbOCType##CType3)CName3 \
    { \
        return [_##CName3 get##CType3]; \
    } \
    -(void)set##CName3:(tdbOCType##CType3)value \
    { \
    [_##CName3 set##CType3:value]; \
    } \
    -(tdbOCType##CType4)CName4 \
    { \
        return [_##CName4 get##CType4]; \
    } \
    -(void)set##CName4:(tdbOCType##CType4)value \
    { \
    [_##CName4 set##CType4:value]; \
    } \
    -(tdbOCType##CType5)CName5 \
    { \
        return [_##CName5 get##CType5]; \
    } \
    -(void)set##CName5:(tdbOCType##CType5)value \
    { \
    [_##CName5 set##CType5:value]; \
    } \
    -(tdbOCType##CType6)CName6 \
    { \
        return [_##CName6 get##CType6]; \
    } \
    -(void)set##CName6:(tdbOCType##CType6)value \
    { \
    [_##CName6 set##CType6:value]; \
    } \
    -(tdbOCType##CType7)CName7 \
    { \
        return [_##CName7 get##CType7]; \
    } \
    -(void)set##CName7:(tdbOCType##CType7)value \
    { \
    [_##CName7 set##CType7:value]; \
    } \
    -(tdbOCType##CType8)CName8 \
    { \
        return [_##CName8 get##CType8]; \
    } \
    -(void)set##CName8:(tdbOCType##CType8)value \
    { \
    [_##CName8 set##CType8:value]; \
    } \
@end \
@implementation TableName##_##Query \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
    -(long)getFastEnumStart \
    { \
       return [self findNext:-1]; \
    } \
    -(long)incrementFastEnum:(long)ndx \
    { \
        return [self findNext:ndx]; \
    } \
    -(CursorBase *)getCursor:(long)ndx \
    { \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
    } \
@synthesize CName1 = _CName1; \
@synthesize CName2 = _CName2; \
@synthesize CName3 = _CName3; \
@synthesize CName4 = _CName4; \
@synthesize CName5 = _CName5; \
@synthesize CName6 = _CName6; \
@synthesize CName7 = _CName7; \
@synthesize CName8 = _CName8; \
-(id)initWithTable:(Table *)table \
{ \
    self = [super initWithTable:table]; \
    if (self) { \
        _CName1 = [[TableName##QueryAccessor##CType1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##QueryAccessor##CType2 alloc] initWithColumn:1 query:self]; \
        _CName3 = [[TableName##QueryAccessor##CType3 alloc] initWithColumn:2 query:self]; \
        _CName4 = [[TableName##QueryAccessor##CType4 alloc] initWithColumn:3 query:self]; \
        _CName5 = [[TableName##QueryAccessor##CType5 alloc] initWithColumn:4 query:self]; \
        _CName6 = [[TableName##QueryAccessor##CType6 alloc] initWithColumn:5 query:self]; \
        _CName7 = [[TableName##QueryAccessor##CType7 alloc] initWithColumn:6 query:self]; \
        _CName8 = [[TableName##QueryAccessor##CType8 alloc] initWithColumn:7 query:self]; \
    } \
    return self; \
} \
-(TableName##_##Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_##Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_##Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_##Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_##Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_##View *)findAll \
    { \
        return [[TableName##_##View alloc] initFromQuery:self]; \
    } \
@end \
@implementation TableName##QueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
-(TableName##_##Query *)notEqual:(size_t)value \
{ \
    return (TableName##_##Query *)[super notEqual:value]; \
} \
-(TableName##_##Query *)greater:(int64_t)value \
{ \
    return (TableName##_##Query *)[super greater:value]; \
} \
-(TableName##_##Query *)less:(int64_t)value \
{ \
    return (TableName##_##Query *)[super less:value]; \
} \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to \
{ \
    return (TableName##_##Query *)[super between:from to:to]; \
} \
@end \
@implementation TableName##QueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
@end \
@implementation TableName##QueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super equal:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super notEqual:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super beginsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super endsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super contains:value caseSensitive:caseSensitive]; \
} \
@end \
@implementation TableName \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
@synthesize CName1 = _##CName1; \
@synthesize CName2 = _##CName2; \
@synthesize CName3 = _##CName3; \
@synthesize CName4 = _##CName4; \
@synthesize CName5 = _##CName5; \
@synthesize CName6 = _##CName6; \
@synthesize CName7 = _##CName7; \
@synthesize CName8 = _##CName8; \
\
-(id)initWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        if ([self getColumnCount] == 0) { \
            [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
            [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
            [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
            [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
            [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
            [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
            [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
            [self registerColumn:COLTYPE##CType8 name:[NSString stringWithUTF8String:#CName8]]; \
        } \
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
        _##CName8 = [[OCColumnProxy##CType8 alloc] initWithTable:self column:7]; \
    } \
    return self; \
} \
-(id)initCreateWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
        [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
        [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
        [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
        [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
        [self registerColumn:COLTYPE##CType8 name:[NSString stringWithUTF8String:#CName8]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
        _##CName8 = [[OCColumnProxy##CType8 alloc] initWithTable:self column:7]; \
    } \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
        [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
        [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
        [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
        [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
        [self registerColumn:COLTYPE##CType8 name:[NSString stringWithUTF8String:#CName8]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
        _##CName8 = [[OCColumnProxy##CType8 alloc] initWithTable:self column:7]; \
    } \
    return self; \
} \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 \
{ \
    const size_t ndx = [self count]; \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insert##CType4:3 ndx:ndx value:CName4]; \
    [self insert##CType5:4 ndx:ndx value:CName5]; \
    [self insert##CType6:5 ndx:ndx value:CName6]; \
    [self insert##CType7:6 ndx:ndx value:CName7]; \
    [self insert##CType8:7 ndx:ndx value:CName8]; \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 \
{ \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insert##CType4:3 ndx:ndx value:CName4]; \
    [self insert##CType5:4 ndx:ndx value:CName5]; \
    [self insert##CType6:5 ndx:ndx value:CName6]; \
    [self insert##CType7:6 ndx:ndx value:CName7]; \
    [self insert##CType8:7 ndx:ndx value:CName8]; \
    [self insertDone]; \
} \
-(TableName##_##Query *)getQuery \
{ \
    return [[TableName##_##Query alloc] initWithTable:self]; \
} \
-(TableName##_##Cursor *)add \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self addRow]]; \
} \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:ndx]; \
} \
-(TableName##_##Cursor *)lastObject \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self count]-1]; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:self ndx:0]; \
} \
@end \
@implementation TableName##_##View \
    { \
        TableName##_##Cursor *tmpCursor; \
    } \
    -(CursorBase *)getCursor \
    { \
        return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
    } \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
    { \
    return [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
    } \
@end

#undef TIGHTDB_TABLE_IMPL_9
#define TIGHTDB_TABLE_IMPL_9(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9) \
@implementation TableName##_##Cursor \
    { \
        OCAccessor *_##CName1; \
        OCAccessor *_##CName2; \
        OCAccessor *_##CName3; \
        OCAccessor *_##CName4; \
        OCAccessor *_##CName5; \
        OCAccessor *_##CName6; \
        OCAccessor *_##CName7; \
        OCAccessor *_##CName8; \
        OCAccessor *_##CName9; \
    } \
    -(id)initWithTable:(Table *)table ndx:(size_t)ndx; \
    { \
    self = [super initWithTable:table ndx:ndx]; \
    if (self) { \
    _##CName1 = [[OCAccessor alloc] initWithCursor:self columnId:0]; \
    _##CName2 = [[OCAccessor alloc] initWithCursor:self columnId:1]; \
    _##CName3 = [[OCAccessor alloc] initWithCursor:self columnId:2]; \
    _##CName4 = [[OCAccessor alloc] initWithCursor:self columnId:3]; \
    _##CName5 = [[OCAccessor alloc] initWithCursor:self columnId:4]; \
    _##CName6 = [[OCAccessor alloc] initWithCursor:self columnId:5]; \
    _##CName7 = [[OCAccessor alloc] initWithCursor:self columnId:6]; \
    _##CName8 = [[OCAccessor alloc] initWithCursor:self columnId:7]; \
    _##CName9 = [[OCAccessor alloc] initWithCursor:self columnId:8]; \
    } \
    return self; \
    } \
    -(tdbOCType##CType1)CName1 \
    { \
        return [_##CName1 get##CType1]; \
    } \
    -(void)set##CName1:(tdbOCType##CType1)value \
    { \
    [_##CName1 set##CType1:value]; \
    } \
    -(tdbOCType##CType2)CName2 \
    { \
        return [_##CName2 get##CType2]; \
    } \
    -(void)set##CName2:(tdbOCType##CType2)value \
    { \
    [_##CName2 set##CType2:value]; \
    } \
    -(tdbOCType##CType3)CName3 \
    { \
        return [_##CName3 get##CType3]; \
    } \
    -(void)set##CName3:(tdbOCType##CType3)value \
    { \
    [_##CName3 set##CType3:value]; \
    } \
    -(tdbOCType##CType4)CName4 \
    { \
        return [_##CName4 get##CType4]; \
    } \
    -(void)set##CName4:(tdbOCType##CType4)value \
    { \
    [_##CName4 set##CType4:value]; \
    } \
    -(tdbOCType##CType5)CName5 \
    { \
        return [_##CName5 get##CType5]; \
    } \
    -(void)set##CName5:(tdbOCType##CType5)value \
    { \
    [_##CName5 set##CType5:value]; \
    } \
    -(tdbOCType##CType6)CName6 \
    { \
        return [_##CName6 get##CType6]; \
    } \
    -(void)set##CName6:(tdbOCType##CType6)value \
    { \
    [_##CName6 set##CType6:value]; \
    } \
    -(tdbOCType##CType7)CName7 \
    { \
        return [_##CName7 get##CType7]; \
    } \
    -(void)set##CName7:(tdbOCType##CType7)value \
    { \
    [_##CName7 set##CType7:value]; \
    } \
    -(tdbOCType##CType8)CName8 \
    { \
        return [_##CName8 get##CType8]; \
    } \
    -(void)set##CName8:(tdbOCType##CType8)value \
    { \
    [_##CName8 set##CType8:value]; \
    } \
    -(tdbOCType##CType9)CName9 \
    { \
        return [_##CName9 get##CType9]; \
    } \
    -(void)set##CName9:(tdbOCType##CType9)value \
    { \
    [_##CName9 set##CType9:value]; \
    } \
@end \
@implementation TableName##_##Query \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
    -(long)getFastEnumStart \
    { \
       return [self findNext:-1]; \
    } \
    -(long)incrementFastEnum:(long)ndx \
    { \
        return [self findNext:ndx]; \
    } \
    -(CursorBase *)getCursor:(long)ndx \
    { \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
    } \
@synthesize CName1 = _CName1; \
@synthesize CName2 = _CName2; \
@synthesize CName3 = _CName3; \
@synthesize CName4 = _CName4; \
@synthesize CName5 = _CName5; \
@synthesize CName6 = _CName6; \
@synthesize CName7 = _CName7; \
@synthesize CName8 = _CName8; \
@synthesize CName9 = _CName9; \
-(id)initWithTable:(Table *)table \
{ \
    self = [super initWithTable:table]; \
    if (self) { \
        _CName1 = [[TableName##QueryAccessor##CType1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##QueryAccessor##CType2 alloc] initWithColumn:1 query:self]; \
        _CName3 = [[TableName##QueryAccessor##CType3 alloc] initWithColumn:2 query:self]; \
        _CName4 = [[TableName##QueryAccessor##CType4 alloc] initWithColumn:3 query:self]; \
        _CName5 = [[TableName##QueryAccessor##CType5 alloc] initWithColumn:4 query:self]; \
        _CName6 = [[TableName##QueryAccessor##CType6 alloc] initWithColumn:5 query:self]; \
        _CName7 = [[TableName##QueryAccessor##CType7 alloc] initWithColumn:6 query:self]; \
        _CName8 = [[TableName##QueryAccessor##CType8 alloc] initWithColumn:7 query:self]; \
        _CName9 = [[TableName##QueryAccessor##CType9 alloc] initWithColumn:8 query:self]; \
    } \
    return self; \
} \
-(TableName##_##Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_##Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_##Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_##Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_##Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_##View *)findAll \
    { \
        return [[TableName##_##View alloc] initFromQuery:self]; \
    } \
@end \
@implementation TableName##QueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
-(TableName##_##Query *)notEqual:(size_t)value \
{ \
    return (TableName##_##Query *)[super notEqual:value]; \
} \
-(TableName##_##Query *)greater:(int64_t)value \
{ \
    return (TableName##_##Query *)[super greater:value]; \
} \
-(TableName##_##Query *)less:(int64_t)value \
{ \
    return (TableName##_##Query *)[super less:value]; \
} \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to \
{ \
    return (TableName##_##Query *)[super between:from to:to]; \
} \
@end \
@implementation TableName##QueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
@end \
@implementation TableName##QueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super equal:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super notEqual:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super beginsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super endsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super contains:value caseSensitive:caseSensitive]; \
} \
@end \
@implementation TableName \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
@synthesize CName1 = _##CName1; \
@synthesize CName2 = _##CName2; \
@synthesize CName3 = _##CName3; \
@synthesize CName4 = _##CName4; \
@synthesize CName5 = _##CName5; \
@synthesize CName6 = _##CName6; \
@synthesize CName7 = _##CName7; \
@synthesize CName8 = _##CName8; \
@synthesize CName9 = _##CName9; \
\
-(id)initWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        if ([self getColumnCount] == 0) { \
            [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
            [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
            [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
            [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
            [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
            [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
            [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
            [self registerColumn:COLTYPE##CType8 name:[NSString stringWithUTF8String:#CName8]]; \
            [self registerColumn:COLTYPE##CType9 name:[NSString stringWithUTF8String:#CName9]]; \
        } \
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
        _##CName8 = [[OCColumnProxy##CType8 alloc] initWithTable:self column:7]; \
        _##CName9 = [[OCColumnProxy##CType9 alloc] initWithTable:self column:8]; \
    } \
    return self; \
} \
-(id)initCreateWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
        [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
        [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
        [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
        [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
        [self registerColumn:COLTYPE##CType8 name:[NSString stringWithUTF8String:#CName8]]; \
        [self registerColumn:COLTYPE##CType9 name:[NSString stringWithUTF8String:#CName9]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
        _##CName8 = [[OCColumnProxy##CType8 alloc] initWithTable:self column:7]; \
        _##CName9 = [[OCColumnProxy##CType9 alloc] initWithTable:self column:8]; \
    } \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
        [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
        [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
        [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
        [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
        [self registerColumn:COLTYPE##CType8 name:[NSString stringWithUTF8String:#CName8]]; \
        [self registerColumn:COLTYPE##CType9 name:[NSString stringWithUTF8String:#CName9]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
        _##CName8 = [[OCColumnProxy##CType8 alloc] initWithTable:self column:7]; \
        _##CName9 = [[OCColumnProxy##CType9 alloc] initWithTable:self column:8]; \
    } \
    return self; \
} \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9 \
{ \
    const size_t ndx = [self count]; \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insert##CType4:3 ndx:ndx value:CName4]; \
    [self insert##CType5:4 ndx:ndx value:CName5]; \
    [self insert##CType6:5 ndx:ndx value:CName6]; \
    [self insert##CType7:6 ndx:ndx value:CName7]; \
    [self insert##CType8:7 ndx:ndx value:CName8]; \
    [self insert##CType9:8 ndx:ndx value:CName9]; \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9 \
{ \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insert##CType4:3 ndx:ndx value:CName4]; \
    [self insert##CType5:4 ndx:ndx value:CName5]; \
    [self insert##CType6:5 ndx:ndx value:CName6]; \
    [self insert##CType7:6 ndx:ndx value:CName7]; \
    [self insert##CType8:7 ndx:ndx value:CName8]; \
    [self insert##CType9:8 ndx:ndx value:CName9]; \
    [self insertDone]; \
} \
-(TableName##_##Query *)getQuery \
{ \
    return [[TableName##_##Query alloc] initWithTable:self]; \
} \
-(TableName##_##Cursor *)add \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self addRow]]; \
} \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:ndx]; \
} \
-(TableName##_##Cursor *)lastObject \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self count]-1]; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:self ndx:0]; \
} \
@end \
@implementation TableName##_##View \
    { \
        TableName##_##Cursor *tmpCursor; \
    } \
    -(CursorBase *)getCursor \
    { \
        return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
    } \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
    { \
    return [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
    } \
@end

#undef TIGHTDB_TABLE_IMPL_10
#define TIGHTDB_TABLE_IMPL_10(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10) \
@implementation TableName##_##Cursor \
    { \
        OCAccessor *_##CName1; \
        OCAccessor *_##CName2; \
        OCAccessor *_##CName3; \
        OCAccessor *_##CName4; \
        OCAccessor *_##CName5; \
        OCAccessor *_##CName6; \
        OCAccessor *_##CName7; \
        OCAccessor *_##CName8; \
        OCAccessor *_##CName9; \
        OCAccessor *_##CName10; \
    } \
    -(id)initWithTable:(Table *)table ndx:(size_t)ndx; \
    { \
    self = [super initWithTable:table ndx:ndx]; \
    if (self) { \
    _##CName1 = [[OCAccessor alloc] initWithCursor:self columnId:0]; \
    _##CName2 = [[OCAccessor alloc] initWithCursor:self columnId:1]; \
    _##CName3 = [[OCAccessor alloc] initWithCursor:self columnId:2]; \
    _##CName4 = [[OCAccessor alloc] initWithCursor:self columnId:3]; \
    _##CName5 = [[OCAccessor alloc] initWithCursor:self columnId:4]; \
    _##CName6 = [[OCAccessor alloc] initWithCursor:self columnId:5]; \
    _##CName7 = [[OCAccessor alloc] initWithCursor:self columnId:6]; \
    _##CName8 = [[OCAccessor alloc] initWithCursor:self columnId:7]; \
    _##CName9 = [[OCAccessor alloc] initWithCursor:self columnId:8]; \
    _##CName10 = [[OCAccessor alloc] initWithCursor:self columnId:9]; \
    } \
    return self; \
    } \
    -(tdbOCType##CType1)CName1 \
    { \
        return [_##CName1 get##CType1]; \
    } \
    -(void)set##CName1:(tdbOCType##CType1)value \
    { \
    [_##CName1 set##CType1:value]; \
    } \
    -(tdbOCType##CType2)CName2 \
    { \
        return [_##CName2 get##CType2]; \
    } \
    -(void)set##CName2:(tdbOCType##CType2)value \
    { \
    [_##CName2 set##CType2:value]; \
    } \
    -(tdbOCType##CType3)CName3 \
    { \
        return [_##CName3 get##CType3]; \
    } \
    -(void)set##CName3:(tdbOCType##CType3)value \
    { \
    [_##CName3 set##CType3:value]; \
    } \
    -(tdbOCType##CType4)CName4 \
    { \
        return [_##CName4 get##CType4]; \
    } \
    -(void)set##CName4:(tdbOCType##CType4)value \
    { \
    [_##CName4 set##CType4:value]; \
    } \
    -(tdbOCType##CType5)CName5 \
    { \
        return [_##CName5 get##CType5]; \
    } \
    -(void)set##CName5:(tdbOCType##CType5)value \
    { \
    [_##CName5 set##CType5:value]; \
    } \
    -(tdbOCType##CType6)CName6 \
    { \
        return [_##CName6 get##CType6]; \
    } \
    -(void)set##CName6:(tdbOCType##CType6)value \
    { \
    [_##CName6 set##CType6:value]; \
    } \
    -(tdbOCType##CType7)CName7 \
    { \
        return [_##CName7 get##CType7]; \
    } \
    -(void)set##CName7:(tdbOCType##CType7)value \
    { \
    [_##CName7 set##CType7:value]; \
    } \
    -(tdbOCType##CType8)CName8 \
    { \
        return [_##CName8 get##CType8]; \
    } \
    -(void)set##CName8:(tdbOCType##CType8)value \
    { \
    [_##CName8 set##CType8:value]; \
    } \
    -(tdbOCType##CType9)CName9 \
    { \
        return [_##CName9 get##CType9]; \
    } \
    -(void)set##CName9:(tdbOCType##CType9)value \
    { \
    [_##CName9 set##CType9:value]; \
    } \
    -(tdbOCType##CType10)CName10 \
    { \
        return [_##CName10 get##CType10]; \
    } \
    -(void)set##CName10:(tdbOCType##CType10)value \
    { \
    [_##CName10 set##CType10:value]; \
    } \
@end \
@implementation TableName##_##Query \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
    -(long)getFastEnumStart \
    { \
       return [self findNext:-1]; \
    } \
    -(long)incrementFastEnum:(long)ndx \
    { \
        return [self findNext:ndx]; \
    } \
    -(CursorBase *)getCursor:(long)ndx \
    { \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
    } \
@synthesize CName1 = _CName1; \
@synthesize CName2 = _CName2; \
@synthesize CName3 = _CName3; \
@synthesize CName4 = _CName4; \
@synthesize CName5 = _CName5; \
@synthesize CName6 = _CName6; \
@synthesize CName7 = _CName7; \
@synthesize CName8 = _CName8; \
@synthesize CName9 = _CName9; \
@synthesize CName10 = _CName10; \
-(id)initWithTable:(Table *)table \
{ \
    self = [super initWithTable:table]; \
    if (self) { \
        _CName1 = [[TableName##QueryAccessor##CType1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##QueryAccessor##CType2 alloc] initWithColumn:1 query:self]; \
        _CName3 = [[TableName##QueryAccessor##CType3 alloc] initWithColumn:2 query:self]; \
        _CName4 = [[TableName##QueryAccessor##CType4 alloc] initWithColumn:3 query:self]; \
        _CName5 = [[TableName##QueryAccessor##CType5 alloc] initWithColumn:4 query:self]; \
        _CName6 = [[TableName##QueryAccessor##CType6 alloc] initWithColumn:5 query:self]; \
        _CName7 = [[TableName##QueryAccessor##CType7 alloc] initWithColumn:6 query:self]; \
        _CName8 = [[TableName##QueryAccessor##CType8 alloc] initWithColumn:7 query:self]; \
        _CName9 = [[TableName##QueryAccessor##CType9 alloc] initWithColumn:8 query:self]; \
        _CName10 = [[TableName##QueryAccessor##CType10 alloc] initWithColumn:9 query:self]; \
    } \
    return self; \
} \
-(TableName##_##Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_##Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_##Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_##Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_##Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_##View *)findAll \
    { \
        return [[TableName##_##View alloc] initFromQuery:self]; \
    } \
@end \
@implementation TableName##QueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
-(TableName##_##Query *)notEqual:(size_t)value \
{ \
    return (TableName##_##Query *)[super notEqual:value]; \
} \
-(TableName##_##Query *)greater:(int64_t)value \
{ \
    return (TableName##_##Query *)[super greater:value]; \
} \
-(TableName##_##Query *)less:(int64_t)value \
{ \
    return (TableName##_##Query *)[super less:value]; \
} \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to \
{ \
    return (TableName##_##Query *)[super between:from to:to]; \
} \
@end \
@implementation TableName##QueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
@end \
@implementation TableName##QueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super equal:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super notEqual:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super beginsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super endsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super contains:value caseSensitive:caseSensitive]; \
} \
@end \
@implementation TableName \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
@synthesize CName1 = _##CName1; \
@synthesize CName2 = _##CName2; \
@synthesize CName3 = _##CName3; \
@synthesize CName4 = _##CName4; \
@synthesize CName5 = _##CName5; \
@synthesize CName6 = _##CName6; \
@synthesize CName7 = _##CName7; \
@synthesize CName8 = _##CName8; \
@synthesize CName9 = _##CName9; \
@synthesize CName10 = _##CName10; \
\
-(id)initWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        if ([self getColumnCount] == 0) { \
            [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
            [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
            [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
            [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
            [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
            [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
            [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
            [self registerColumn:COLTYPE##CType8 name:[NSString stringWithUTF8String:#CName8]]; \
            [self registerColumn:COLTYPE##CType9 name:[NSString stringWithUTF8String:#CName9]]; \
            [self registerColumn:COLTYPE##CType10 name:[NSString stringWithUTF8String:#CName10]]; \
        } \
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
        _##CName8 = [[OCColumnProxy##CType8 alloc] initWithTable:self column:7]; \
        _##CName9 = [[OCColumnProxy##CType9 alloc] initWithTable:self column:8]; \
        _##CName10 = [[OCColumnProxy##CType10 alloc] initWithTable:self column:9]; \
    } \
    return self; \
} \
-(id)initCreateWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
        [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
        [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
        [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
        [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
        [self registerColumn:COLTYPE##CType8 name:[NSString stringWithUTF8String:#CName8]]; \
        [self registerColumn:COLTYPE##CType9 name:[NSString stringWithUTF8String:#CName9]]; \
        [self registerColumn:COLTYPE##CType10 name:[NSString stringWithUTF8String:#CName10]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
        _##CName8 = [[OCColumnProxy##CType8 alloc] initWithTable:self column:7]; \
        _##CName9 = [[OCColumnProxy##CType9 alloc] initWithTable:self column:8]; \
        _##CName10 = [[OCColumnProxy##CType10 alloc] initWithTable:self column:9]; \
    } \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
        [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
        [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
        [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
        [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
        [self registerColumn:COLTYPE##CType8 name:[NSString stringWithUTF8String:#CName8]]; \
        [self registerColumn:COLTYPE##CType9 name:[NSString stringWithUTF8String:#CName9]]; \
        [self registerColumn:COLTYPE##CType10 name:[NSString stringWithUTF8String:#CName10]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
        _##CName8 = [[OCColumnProxy##CType8 alloc] initWithTable:self column:7]; \
        _##CName9 = [[OCColumnProxy##CType9 alloc] initWithTable:self column:8]; \
        _##CName10 = [[OCColumnProxy##CType10 alloc] initWithTable:self column:9]; \
    } \
    return self; \
} \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9 CName10:(tdbOCType##CType10)CName10 \
{ \
    const size_t ndx = [self count]; \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insert##CType4:3 ndx:ndx value:CName4]; \
    [self insert##CType5:4 ndx:ndx value:CName5]; \
    [self insert##CType6:5 ndx:ndx value:CName6]; \
    [self insert##CType7:6 ndx:ndx value:CName7]; \
    [self insert##CType8:7 ndx:ndx value:CName8]; \
    [self insert##CType9:8 ndx:ndx value:CName9]; \
    [self insert##CType10:9 ndx:ndx value:CName10]; \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9 CName10:(tdbOCType##CType10)CName10 \
{ \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insert##CType4:3 ndx:ndx value:CName4]; \
    [self insert##CType5:4 ndx:ndx value:CName5]; \
    [self insert##CType6:5 ndx:ndx value:CName6]; \
    [self insert##CType7:6 ndx:ndx value:CName7]; \
    [self insert##CType8:7 ndx:ndx value:CName8]; \
    [self insert##CType9:8 ndx:ndx value:CName9]; \
    [self insert##CType10:9 ndx:ndx value:CName10]; \
    [self insertDone]; \
} \
-(TableName##_##Query *)getQuery \
{ \
    return [[TableName##_##Query alloc] initWithTable:self]; \
} \
-(TableName##_##Cursor *)add \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self addRow]]; \
} \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:ndx]; \
} \
-(TableName##_##Cursor *)lastObject \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self count]-1]; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:self ndx:0]; \
} \
@end \
@implementation TableName##_##View \
    { \
        TableName##_##Cursor *tmpCursor; \
    } \
    -(CursorBase *)getCursor \
    { \
        return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
    } \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
    { \
    return [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
    } \
@end

#undef TIGHTDB_TABLE_IMPL_11
#define TIGHTDB_TABLE_IMPL_11(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10, CType11, CName11) \
@implementation TableName##_##Cursor \
    { \
        OCAccessor *_##CName1; \
        OCAccessor *_##CName2; \
        OCAccessor *_##CName3; \
        OCAccessor *_##CName4; \
        OCAccessor *_##CName5; \
        OCAccessor *_##CName6; \
        OCAccessor *_##CName7; \
        OCAccessor *_##CName8; \
        OCAccessor *_##CName9; \
        OCAccessor *_##CName10; \
        OCAccessor *_##CName11; \
    } \
    -(id)initWithTable:(Table *)table ndx:(size_t)ndx; \
    { \
    self = [super initWithTable:table ndx:ndx]; \
    if (self) { \
    _##CName1 = [[OCAccessor alloc] initWithCursor:self columnId:0]; \
    _##CName2 = [[OCAccessor alloc] initWithCursor:self columnId:1]; \
    _##CName3 = [[OCAccessor alloc] initWithCursor:self columnId:2]; \
    _##CName4 = [[OCAccessor alloc] initWithCursor:self columnId:3]; \
    _##CName5 = [[OCAccessor alloc] initWithCursor:self columnId:4]; \
    _##CName6 = [[OCAccessor alloc] initWithCursor:self columnId:5]; \
    _##CName7 = [[OCAccessor alloc] initWithCursor:self columnId:6]; \
    _##CName8 = [[OCAccessor alloc] initWithCursor:self columnId:7]; \
    _##CName9 = [[OCAccessor alloc] initWithCursor:self columnId:8]; \
    _##CName10 = [[OCAccessor alloc] initWithCursor:self columnId:9]; \
    _##CName11 = [[OCAccessor alloc] initWithCursor:self columnId:10]; \
    } \
    return self; \
    } \
    -(tdbOCType##CType1)CName1 \
    { \
        return [_##CName1 get##CType1]; \
    } \
    -(void)set##CName1:(tdbOCType##CType1)value \
    { \
    [_##CName1 set##CType1:value]; \
    } \
    -(tdbOCType##CType2)CName2 \
    { \
        return [_##CName2 get##CType2]; \
    } \
    -(void)set##CName2:(tdbOCType##CType2)value \
    { \
    [_##CName2 set##CType2:value]; \
    } \
    -(tdbOCType##CType3)CName3 \
    { \
        return [_##CName3 get##CType3]; \
    } \
    -(void)set##CName3:(tdbOCType##CType3)value \
    { \
    [_##CName3 set##CType3:value]; \
    } \
    -(tdbOCType##CType4)CName4 \
    { \
        return [_##CName4 get##CType4]; \
    } \
    -(void)set##CName4:(tdbOCType##CType4)value \
    { \
    [_##CName4 set##CType4:value]; \
    } \
    -(tdbOCType##CType5)CName5 \
    { \
        return [_##CName5 get##CType5]; \
    } \
    -(void)set##CName5:(tdbOCType##CType5)value \
    { \
    [_##CName5 set##CType5:value]; \
    } \
    -(tdbOCType##CType6)CName6 \
    { \
        return [_##CName6 get##CType6]; \
    } \
    -(void)set##CName6:(tdbOCType##CType6)value \
    { \
    [_##CName6 set##CType6:value]; \
    } \
    -(tdbOCType##CType7)CName7 \
    { \
        return [_##CName7 get##CType7]; \
    } \
    -(void)set##CName7:(tdbOCType##CType7)value \
    { \
    [_##CName7 set##CType7:value]; \
    } \
    -(tdbOCType##CType8)CName8 \
    { \
        return [_##CName8 get##CType8]; \
    } \
    -(void)set##CName8:(tdbOCType##CType8)value \
    { \
    [_##CName8 set##CType8:value]; \
    } \
    -(tdbOCType##CType9)CName9 \
    { \
        return [_##CName9 get##CType9]; \
    } \
    -(void)set##CName9:(tdbOCType##CType9)value \
    { \
    [_##CName9 set##CType9:value]; \
    } \
    -(tdbOCType##CType10)CName10 \
    { \
        return [_##CName10 get##CType10]; \
    } \
    -(void)set##CName10:(tdbOCType##CType10)value \
    { \
    [_##CName10 set##CType10:value]; \
    } \
    -(tdbOCType##CType11)CName11 \
    { \
        return [_##CName11 get##CType11]; \
    } \
    -(void)set##CName11:(tdbOCType##CType11)value \
    { \
    [_##CName11 set##CType11:value]; \
    } \
@end \
@implementation TableName##_##Query \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
    -(long)getFastEnumStart \
    { \
       return [self findNext:-1]; \
    } \
    -(long)incrementFastEnum:(long)ndx \
    { \
        return [self findNext:ndx]; \
    } \
    -(CursorBase *)getCursor:(long)ndx \
    { \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
    } \
@synthesize CName1 = _CName1; \
@synthesize CName2 = _CName2; \
@synthesize CName3 = _CName3; \
@synthesize CName4 = _CName4; \
@synthesize CName5 = _CName5; \
@synthesize CName6 = _CName6; \
@synthesize CName7 = _CName7; \
@synthesize CName8 = _CName8; \
@synthesize CName9 = _CName9; \
@synthesize CName10 = _CName10; \
@synthesize CName11 = _CName11; \
-(id)initWithTable:(Table *)table \
{ \
    self = [super initWithTable:table]; \
    if (self) { \
        _CName1 = [[TableName##QueryAccessor##CType1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##QueryAccessor##CType2 alloc] initWithColumn:1 query:self]; \
        _CName3 = [[TableName##QueryAccessor##CType3 alloc] initWithColumn:2 query:self]; \
        _CName4 = [[TableName##QueryAccessor##CType4 alloc] initWithColumn:3 query:self]; \
        _CName5 = [[TableName##QueryAccessor##CType5 alloc] initWithColumn:4 query:self]; \
        _CName6 = [[TableName##QueryAccessor##CType6 alloc] initWithColumn:5 query:self]; \
        _CName7 = [[TableName##QueryAccessor##CType7 alloc] initWithColumn:6 query:self]; \
        _CName8 = [[TableName##QueryAccessor##CType8 alloc] initWithColumn:7 query:self]; \
        _CName9 = [[TableName##QueryAccessor##CType9 alloc] initWithColumn:8 query:self]; \
        _CName10 = [[TableName##QueryAccessor##CType10 alloc] initWithColumn:9 query:self]; \
        _CName11 = [[TableName##QueryAccessor##CType11 alloc] initWithColumn:10 query:self]; \
    } \
    return self; \
} \
-(TableName##_##Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_##Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_##Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_##Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_##Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_##View *)findAll \
    { \
        return [[TableName##_##View alloc] initFromQuery:self]; \
    } \
@end \
@implementation TableName##QueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
-(TableName##_##Query *)notEqual:(size_t)value \
{ \
    return (TableName##_##Query *)[super notEqual:value]; \
} \
-(TableName##_##Query *)greater:(int64_t)value \
{ \
    return (TableName##_##Query *)[super greater:value]; \
} \
-(TableName##_##Query *)less:(int64_t)value \
{ \
    return (TableName##_##Query *)[super less:value]; \
} \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to \
{ \
    return (TableName##_##Query *)[super between:from to:to]; \
} \
@end \
@implementation TableName##QueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
@end \
@implementation TableName##QueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super equal:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super notEqual:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super beginsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super endsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super contains:value caseSensitive:caseSensitive]; \
} \
@end \
@implementation TableName \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
@synthesize CName1 = _##CName1; \
@synthesize CName2 = _##CName2; \
@synthesize CName3 = _##CName3; \
@synthesize CName4 = _##CName4; \
@synthesize CName5 = _##CName5; \
@synthesize CName6 = _##CName6; \
@synthesize CName7 = _##CName7; \
@synthesize CName8 = _##CName8; \
@synthesize CName9 = _##CName9; \
@synthesize CName10 = _##CName10; \
@synthesize CName11 = _##CName11; \
\
-(id)initWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        if ([self getColumnCount] == 0) { \
            [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
            [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
            [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
            [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
            [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
            [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
            [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
            [self registerColumn:COLTYPE##CType8 name:[NSString stringWithUTF8String:#CName8]]; \
            [self registerColumn:COLTYPE##CType9 name:[NSString stringWithUTF8String:#CName9]]; \
            [self registerColumn:COLTYPE##CType10 name:[NSString stringWithUTF8String:#CName10]]; \
            [self registerColumn:COLTYPE##CType11 name:[NSString stringWithUTF8String:#CName11]]; \
        } \
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
        _##CName8 = [[OCColumnProxy##CType8 alloc] initWithTable:self column:7]; \
        _##CName9 = [[OCColumnProxy##CType9 alloc] initWithTable:self column:8]; \
        _##CName10 = [[OCColumnProxy##CType10 alloc] initWithTable:self column:9]; \
        _##CName11 = [[OCColumnProxy##CType11 alloc] initWithTable:self column:10]; \
    } \
    return self; \
} \
-(id)initCreateWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
        [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
        [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
        [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
        [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
        [self registerColumn:COLTYPE##CType8 name:[NSString stringWithUTF8String:#CName8]]; \
        [self registerColumn:COLTYPE##CType9 name:[NSString stringWithUTF8String:#CName9]]; \
        [self registerColumn:COLTYPE##CType10 name:[NSString stringWithUTF8String:#CName10]]; \
        [self registerColumn:COLTYPE##CType11 name:[NSString stringWithUTF8String:#CName11]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
        _##CName8 = [[OCColumnProxy##CType8 alloc] initWithTable:self column:7]; \
        _##CName9 = [[OCColumnProxy##CType9 alloc] initWithTable:self column:8]; \
        _##CName10 = [[OCColumnProxy##CType10 alloc] initWithTable:self column:9]; \
        _##CName11 = [[OCColumnProxy##CType11 alloc] initWithTable:self column:10]; \
    } \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
        [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
        [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
        [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
        [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
        [self registerColumn:COLTYPE##CType8 name:[NSString stringWithUTF8String:#CName8]]; \
        [self registerColumn:COLTYPE##CType9 name:[NSString stringWithUTF8String:#CName9]]; \
        [self registerColumn:COLTYPE##CType10 name:[NSString stringWithUTF8String:#CName10]]; \
        [self registerColumn:COLTYPE##CType11 name:[NSString stringWithUTF8String:#CName11]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
        _##CName8 = [[OCColumnProxy##CType8 alloc] initWithTable:self column:7]; \
        _##CName9 = [[OCColumnProxy##CType9 alloc] initWithTable:self column:8]; \
        _##CName10 = [[OCColumnProxy##CType10 alloc] initWithTable:self column:9]; \
        _##CName11 = [[OCColumnProxy##CType11 alloc] initWithTable:self column:10]; \
    } \
    return self; \
} \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9 CName10:(tdbOCType##CType10)CName10 CName11:(tdbOCType##CType11)CName11 \
{ \
    const size_t ndx = [self count]; \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insert##CType4:3 ndx:ndx value:CName4]; \
    [self insert##CType5:4 ndx:ndx value:CName5]; \
    [self insert##CType6:5 ndx:ndx value:CName6]; \
    [self insert##CType7:6 ndx:ndx value:CName7]; \
    [self insert##CType8:7 ndx:ndx value:CName8]; \
    [self insert##CType9:8 ndx:ndx value:CName9]; \
    [self insert##CType10:9 ndx:ndx value:CName10]; \
    [self insert##CType11:10 ndx:ndx value:CName11]; \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9 CName10:(tdbOCType##CType10)CName10 CName11:(tdbOCType##CType11)CName11 \
{ \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insert##CType4:3 ndx:ndx value:CName4]; \
    [self insert##CType5:4 ndx:ndx value:CName5]; \
    [self insert##CType6:5 ndx:ndx value:CName6]; \
    [self insert##CType7:6 ndx:ndx value:CName7]; \
    [self insert##CType8:7 ndx:ndx value:CName8]; \
    [self insert##CType9:8 ndx:ndx value:CName9]; \
    [self insert##CType10:9 ndx:ndx value:CName10]; \
    [self insert##CType11:10 ndx:ndx value:CName11]; \
    [self insertDone]; \
} \
-(TableName##_##Query *)getQuery \
{ \
    return [[TableName##_##Query alloc] initWithTable:self]; \
} \
-(TableName##_##Cursor *)add \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self addRow]]; \
} \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:ndx]; \
} \
-(TableName##_##Cursor *)lastObject \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self count]-1]; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:self ndx:0]; \
} \
@end \
@implementation TableName##_##View \
    { \
        TableName##_##Cursor *tmpCursor; \
    } \
    -(CursorBase *)getCursor \
    { \
        return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
    } \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
    { \
    return [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
    } \
@end

#undef TIGHTDB_TABLE_IMPL_12
#define TIGHTDB_TABLE_IMPL_12(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10, CType11, CName11, CType12, CName12) \
@implementation TableName##_##Cursor \
    { \
        OCAccessor *_##CName1; \
        OCAccessor *_##CName2; \
        OCAccessor *_##CName3; \
        OCAccessor *_##CName4; \
        OCAccessor *_##CName5; \
        OCAccessor *_##CName6; \
        OCAccessor *_##CName7; \
        OCAccessor *_##CName8; \
        OCAccessor *_##CName9; \
        OCAccessor *_##CName10; \
        OCAccessor *_##CName11; \
        OCAccessor *_##CName12; \
    } \
    -(id)initWithTable:(Table *)table ndx:(size_t)ndx; \
    { \
    self = [super initWithTable:table ndx:ndx]; \
    if (self) { \
    _##CName1 = [[OCAccessor alloc] initWithCursor:self columnId:0]; \
    _##CName2 = [[OCAccessor alloc] initWithCursor:self columnId:1]; \
    _##CName3 = [[OCAccessor alloc] initWithCursor:self columnId:2]; \
    _##CName4 = [[OCAccessor alloc] initWithCursor:self columnId:3]; \
    _##CName5 = [[OCAccessor alloc] initWithCursor:self columnId:4]; \
    _##CName6 = [[OCAccessor alloc] initWithCursor:self columnId:5]; \
    _##CName7 = [[OCAccessor alloc] initWithCursor:self columnId:6]; \
    _##CName8 = [[OCAccessor alloc] initWithCursor:self columnId:7]; \
    _##CName9 = [[OCAccessor alloc] initWithCursor:self columnId:8]; \
    _##CName10 = [[OCAccessor alloc] initWithCursor:self columnId:9]; \
    _##CName11 = [[OCAccessor alloc] initWithCursor:self columnId:10]; \
    _##CName12 = [[OCAccessor alloc] initWithCursor:self columnId:11]; \
    } \
    return self; \
    } \
    -(tdbOCType##CType1)CName1 \
    { \
        return [_##CName1 get##CType1]; \
    } \
    -(void)set##CName1:(tdbOCType##CType1)value \
    { \
    [_##CName1 set##CType1:value]; \
    } \
    -(tdbOCType##CType2)CName2 \
    { \
        return [_##CName2 get##CType2]; \
    } \
    -(void)set##CName2:(tdbOCType##CType2)value \
    { \
    [_##CName2 set##CType2:value]; \
    } \
    -(tdbOCType##CType3)CName3 \
    { \
        return [_##CName3 get##CType3]; \
    } \
    -(void)set##CName3:(tdbOCType##CType3)value \
    { \
    [_##CName3 set##CType3:value]; \
    } \
    -(tdbOCType##CType4)CName4 \
    { \
        return [_##CName4 get##CType4]; \
    } \
    -(void)set##CName4:(tdbOCType##CType4)value \
    { \
    [_##CName4 set##CType4:value]; \
    } \
    -(tdbOCType##CType5)CName5 \
    { \
        return [_##CName5 get##CType5]; \
    } \
    -(void)set##CName5:(tdbOCType##CType5)value \
    { \
    [_##CName5 set##CType5:value]; \
    } \
    -(tdbOCType##CType6)CName6 \
    { \
        return [_##CName6 get##CType6]; \
    } \
    -(void)set##CName6:(tdbOCType##CType6)value \
    { \
    [_##CName6 set##CType6:value]; \
    } \
    -(tdbOCType##CType7)CName7 \
    { \
        return [_##CName7 get##CType7]; \
    } \
    -(void)set##CName7:(tdbOCType##CType7)value \
    { \
    [_##CName7 set##CType7:value]; \
    } \
    -(tdbOCType##CType8)CName8 \
    { \
        return [_##CName8 get##CType8]; \
    } \
    -(void)set##CName8:(tdbOCType##CType8)value \
    { \
    [_##CName8 set##CType8:value]; \
    } \
    -(tdbOCType##CType9)CName9 \
    { \
        return [_##CName9 get##CType9]; \
    } \
    -(void)set##CName9:(tdbOCType##CType9)value \
    { \
    [_##CName9 set##CType9:value]; \
    } \
    -(tdbOCType##CType10)CName10 \
    { \
        return [_##CName10 get##CType10]; \
    } \
    -(void)set##CName10:(tdbOCType##CType10)value \
    { \
    [_##CName10 set##CType10:value]; \
    } \
    -(tdbOCType##CType11)CName11 \
    { \
        return [_##CName11 get##CType11]; \
    } \
    -(void)set##CName11:(tdbOCType##CType11)value \
    { \
    [_##CName11 set##CType11:value]; \
    } \
    -(tdbOCType##CType12)CName12 \
    { \
        return [_##CName12 get##CType12]; \
    } \
    -(void)set##CName12:(tdbOCType##CType12)value \
    { \
    [_##CName12 set##CType12:value]; \
    } \
@end \
@implementation TableName##_##Query \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
    -(long)getFastEnumStart \
    { \
       return [self findNext:-1]; \
    } \
    -(long)incrementFastEnum:(long)ndx \
    { \
        return [self findNext:ndx]; \
    } \
    -(CursorBase *)getCursor:(long)ndx \
    { \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
    } \
@synthesize CName1 = _CName1; \
@synthesize CName2 = _CName2; \
@synthesize CName3 = _CName3; \
@synthesize CName4 = _CName4; \
@synthesize CName5 = _CName5; \
@synthesize CName6 = _CName6; \
@synthesize CName7 = _CName7; \
@synthesize CName8 = _CName8; \
@synthesize CName9 = _CName9; \
@synthesize CName10 = _CName10; \
@synthesize CName11 = _CName11; \
@synthesize CName12 = _CName12; \
-(id)initWithTable:(Table *)table \
{ \
    self = [super initWithTable:table]; \
    if (self) { \
        _CName1 = [[TableName##QueryAccessor##CType1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##QueryAccessor##CType2 alloc] initWithColumn:1 query:self]; \
        _CName3 = [[TableName##QueryAccessor##CType3 alloc] initWithColumn:2 query:self]; \
        _CName4 = [[TableName##QueryAccessor##CType4 alloc] initWithColumn:3 query:self]; \
        _CName5 = [[TableName##QueryAccessor##CType5 alloc] initWithColumn:4 query:self]; \
        _CName6 = [[TableName##QueryAccessor##CType6 alloc] initWithColumn:5 query:self]; \
        _CName7 = [[TableName##QueryAccessor##CType7 alloc] initWithColumn:6 query:self]; \
        _CName8 = [[TableName##QueryAccessor##CType8 alloc] initWithColumn:7 query:self]; \
        _CName9 = [[TableName##QueryAccessor##CType9 alloc] initWithColumn:8 query:self]; \
        _CName10 = [[TableName##QueryAccessor##CType10 alloc] initWithColumn:9 query:self]; \
        _CName11 = [[TableName##QueryAccessor##CType11 alloc] initWithColumn:10 query:self]; \
        _CName12 = [[TableName##QueryAccessor##CType12 alloc] initWithColumn:11 query:self]; \
    } \
    return self; \
} \
-(TableName##_##Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_##Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_##Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_##Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_##Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_##View *)findAll \
    { \
        return [[TableName##_##View alloc] initFromQuery:self]; \
    } \
@end \
@implementation TableName##QueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
-(TableName##_##Query *)notEqual:(size_t)value \
{ \
    return (TableName##_##Query *)[super notEqual:value]; \
} \
-(TableName##_##Query *)greater:(int64_t)value \
{ \
    return (TableName##_##Query *)[super greater:value]; \
} \
-(TableName##_##Query *)less:(int64_t)value \
{ \
    return (TableName##_##Query *)[super less:value]; \
} \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to \
{ \
    return (TableName##_##Query *)[super between:from to:to]; \
} \
@end \
@implementation TableName##QueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
@end \
@implementation TableName##QueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super equal:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super notEqual:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super beginsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super endsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super contains:value caseSensitive:caseSensitive]; \
} \
@end \
@implementation TableName \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
@synthesize CName1 = _##CName1; \
@synthesize CName2 = _##CName2; \
@synthesize CName3 = _##CName3; \
@synthesize CName4 = _##CName4; \
@synthesize CName5 = _##CName5; \
@synthesize CName6 = _##CName6; \
@synthesize CName7 = _##CName7; \
@synthesize CName8 = _##CName8; \
@synthesize CName9 = _##CName9; \
@synthesize CName10 = _##CName10; \
@synthesize CName11 = _##CName11; \
@synthesize CName12 = _##CName12; \
\
-(id)initWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        if ([self getColumnCount] == 0) { \
            [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
            [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
            [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
            [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
            [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
            [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
            [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
            [self registerColumn:COLTYPE##CType8 name:[NSString stringWithUTF8String:#CName8]]; \
            [self registerColumn:COLTYPE##CType9 name:[NSString stringWithUTF8String:#CName9]]; \
            [self registerColumn:COLTYPE##CType10 name:[NSString stringWithUTF8String:#CName10]]; \
            [self registerColumn:COLTYPE##CType11 name:[NSString stringWithUTF8String:#CName11]]; \
            [self registerColumn:COLTYPE##CType12 name:[NSString stringWithUTF8String:#CName12]]; \
        } \
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
        _##CName8 = [[OCColumnProxy##CType8 alloc] initWithTable:self column:7]; \
        _##CName9 = [[OCColumnProxy##CType9 alloc] initWithTable:self column:8]; \
        _##CName10 = [[OCColumnProxy##CType10 alloc] initWithTable:self column:9]; \
        _##CName11 = [[OCColumnProxy##CType11 alloc] initWithTable:self column:10]; \
        _##CName12 = [[OCColumnProxy##CType12 alloc] initWithTable:self column:11]; \
    } \
    return self; \
} \
-(id)initCreateWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
        [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
        [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
        [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
        [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
        [self registerColumn:COLTYPE##CType8 name:[NSString stringWithUTF8String:#CName8]]; \
        [self registerColumn:COLTYPE##CType9 name:[NSString stringWithUTF8String:#CName9]]; \
        [self registerColumn:COLTYPE##CType10 name:[NSString stringWithUTF8String:#CName10]]; \
        [self registerColumn:COLTYPE##CType11 name:[NSString stringWithUTF8String:#CName11]]; \
        [self registerColumn:COLTYPE##CType12 name:[NSString stringWithUTF8String:#CName12]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
        _##CName8 = [[OCColumnProxy##CType8 alloc] initWithTable:self column:7]; \
        _##CName9 = [[OCColumnProxy##CType9 alloc] initWithTable:self column:8]; \
        _##CName10 = [[OCColumnProxy##CType10 alloc] initWithTable:self column:9]; \
        _##CName11 = [[OCColumnProxy##CType11 alloc] initWithTable:self column:10]; \
        _##CName12 = [[OCColumnProxy##CType12 alloc] initWithTable:self column:11]; \
    } \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
        [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
        [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
        [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
        [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
        [self registerColumn:COLTYPE##CType8 name:[NSString stringWithUTF8String:#CName8]]; \
        [self registerColumn:COLTYPE##CType9 name:[NSString stringWithUTF8String:#CName9]]; \
        [self registerColumn:COLTYPE##CType10 name:[NSString stringWithUTF8String:#CName10]]; \
        [self registerColumn:COLTYPE##CType11 name:[NSString stringWithUTF8String:#CName11]]; \
        [self registerColumn:COLTYPE##CType12 name:[NSString stringWithUTF8String:#CName12]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
        _##CName8 = [[OCColumnProxy##CType8 alloc] initWithTable:self column:7]; \
        _##CName9 = [[OCColumnProxy##CType9 alloc] initWithTable:self column:8]; \
        _##CName10 = [[OCColumnProxy##CType10 alloc] initWithTable:self column:9]; \
        _##CName11 = [[OCColumnProxy##CType11 alloc] initWithTable:self column:10]; \
        _##CName12 = [[OCColumnProxy##CType12 alloc] initWithTable:self column:11]; \
    } \
    return self; \
} \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9 CName10:(tdbOCType##CType10)CName10 CName11:(tdbOCType##CType11)CName11 CName12:(tdbOCType##CType12)CName12 \
{ \
    const size_t ndx = [self count]; \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insert##CType4:3 ndx:ndx value:CName4]; \
    [self insert##CType5:4 ndx:ndx value:CName5]; \
    [self insert##CType6:5 ndx:ndx value:CName6]; \
    [self insert##CType7:6 ndx:ndx value:CName7]; \
    [self insert##CType8:7 ndx:ndx value:CName8]; \
    [self insert##CType9:8 ndx:ndx value:CName9]; \
    [self insert##CType10:9 ndx:ndx value:CName10]; \
    [self insert##CType11:10 ndx:ndx value:CName11]; \
    [self insert##CType12:11 ndx:ndx value:CName12]; \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9 CName10:(tdbOCType##CType10)CName10 CName11:(tdbOCType##CType11)CName11 CName12:(tdbOCType##CType12)CName12 \
{ \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insert##CType4:3 ndx:ndx value:CName4]; \
    [self insert##CType5:4 ndx:ndx value:CName5]; \
    [self insert##CType6:5 ndx:ndx value:CName6]; \
    [self insert##CType7:6 ndx:ndx value:CName7]; \
    [self insert##CType8:7 ndx:ndx value:CName8]; \
    [self insert##CType9:8 ndx:ndx value:CName9]; \
    [self insert##CType10:9 ndx:ndx value:CName10]; \
    [self insert##CType11:10 ndx:ndx value:CName11]; \
    [self insert##CType12:11 ndx:ndx value:CName12]; \
    [self insertDone]; \
} \
-(TableName##_##Query *)getQuery \
{ \
    return [[TableName##_##Query alloc] initWithTable:self]; \
} \
-(TableName##_##Cursor *)add \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self addRow]]; \
} \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:ndx]; \
} \
-(TableName##_##Cursor *)lastObject \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self count]-1]; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:self ndx:0]; \
} \
@end \
@implementation TableName##_##View \
    { \
        TableName##_##Cursor *tmpCursor; \
    } \
    -(CursorBase *)getCursor \
    { \
        return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
    } \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
    { \
    return [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
    } \
@end

#undef TIGHTDB_TABLE_IMPL_13
#define TIGHTDB_TABLE_IMPL_13(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10, CType11, CName11, CType12, CName12, CType13, CName13) \
@implementation TableName##_##Cursor \
    { \
        OCAccessor *_##CName1; \
        OCAccessor *_##CName2; \
        OCAccessor *_##CName3; \
        OCAccessor *_##CName4; \
        OCAccessor *_##CName5; \
        OCAccessor *_##CName6; \
        OCAccessor *_##CName7; \
        OCAccessor *_##CName8; \
        OCAccessor *_##CName9; \
        OCAccessor *_##CName10; \
        OCAccessor *_##CName11; \
        OCAccessor *_##CName12; \
        OCAccessor *_##CName13; \
    } \
    -(id)initWithTable:(Table *)table ndx:(size_t)ndx; \
    { \
    self = [super initWithTable:table ndx:ndx]; \
    if (self) { \
    _##CName1 = [[OCAccessor alloc] initWithCursor:self columnId:0]; \
    _##CName2 = [[OCAccessor alloc] initWithCursor:self columnId:1]; \
    _##CName3 = [[OCAccessor alloc] initWithCursor:self columnId:2]; \
    _##CName4 = [[OCAccessor alloc] initWithCursor:self columnId:3]; \
    _##CName5 = [[OCAccessor alloc] initWithCursor:self columnId:4]; \
    _##CName6 = [[OCAccessor alloc] initWithCursor:self columnId:5]; \
    _##CName7 = [[OCAccessor alloc] initWithCursor:self columnId:6]; \
    _##CName8 = [[OCAccessor alloc] initWithCursor:self columnId:7]; \
    _##CName9 = [[OCAccessor alloc] initWithCursor:self columnId:8]; \
    _##CName10 = [[OCAccessor alloc] initWithCursor:self columnId:9]; \
    _##CName11 = [[OCAccessor alloc] initWithCursor:self columnId:10]; \
    _##CName12 = [[OCAccessor alloc] initWithCursor:self columnId:11]; \
    _##CName13 = [[OCAccessor alloc] initWithCursor:self columnId:12]; \
    } \
    return self; \
    } \
    -(tdbOCType##CType1)CName1 \
    { \
        return [_##CName1 get##CType1]; \
    } \
    -(void)set##CName1:(tdbOCType##CType1)value \
    { \
    [_##CName1 set##CType1:value]; \
    } \
    -(tdbOCType##CType2)CName2 \
    { \
        return [_##CName2 get##CType2]; \
    } \
    -(void)set##CName2:(tdbOCType##CType2)value \
    { \
    [_##CName2 set##CType2:value]; \
    } \
    -(tdbOCType##CType3)CName3 \
    { \
        return [_##CName3 get##CType3]; \
    } \
    -(void)set##CName3:(tdbOCType##CType3)value \
    { \
    [_##CName3 set##CType3:value]; \
    } \
    -(tdbOCType##CType4)CName4 \
    { \
        return [_##CName4 get##CType4]; \
    } \
    -(void)set##CName4:(tdbOCType##CType4)value \
    { \
    [_##CName4 set##CType4:value]; \
    } \
    -(tdbOCType##CType5)CName5 \
    { \
        return [_##CName5 get##CType5]; \
    } \
    -(void)set##CName5:(tdbOCType##CType5)value \
    { \
    [_##CName5 set##CType5:value]; \
    } \
    -(tdbOCType##CType6)CName6 \
    { \
        return [_##CName6 get##CType6]; \
    } \
    -(void)set##CName6:(tdbOCType##CType6)value \
    { \
    [_##CName6 set##CType6:value]; \
    } \
    -(tdbOCType##CType7)CName7 \
    { \
        return [_##CName7 get##CType7]; \
    } \
    -(void)set##CName7:(tdbOCType##CType7)value \
    { \
    [_##CName7 set##CType7:value]; \
    } \
    -(tdbOCType##CType8)CName8 \
    { \
        return [_##CName8 get##CType8]; \
    } \
    -(void)set##CName8:(tdbOCType##CType8)value \
    { \
    [_##CName8 set##CType8:value]; \
    } \
    -(tdbOCType##CType9)CName9 \
    { \
        return [_##CName9 get##CType9]; \
    } \
    -(void)set##CName9:(tdbOCType##CType9)value \
    { \
    [_##CName9 set##CType9:value]; \
    } \
    -(tdbOCType##CType10)CName10 \
    { \
        return [_##CName10 get##CType10]; \
    } \
    -(void)set##CName10:(tdbOCType##CType10)value \
    { \
    [_##CName10 set##CType10:value]; \
    } \
    -(tdbOCType##CType11)CName11 \
    { \
        return [_##CName11 get##CType11]; \
    } \
    -(void)set##CName11:(tdbOCType##CType11)value \
    { \
    [_##CName11 set##CType11:value]; \
    } \
    -(tdbOCType##CType12)CName12 \
    { \
        return [_##CName12 get##CType12]; \
    } \
    -(void)set##CName12:(tdbOCType##CType12)value \
    { \
    [_##CName12 set##CType12:value]; \
    } \
    -(tdbOCType##CType13)CName13 \
    { \
        return [_##CName13 get##CType13]; \
    } \
    -(void)set##CName13:(tdbOCType##CType13)value \
    { \
    [_##CName13 set##CType13:value]; \
    } \
@end \
@implementation TableName##_##Query \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
    -(long)getFastEnumStart \
    { \
       return [self findNext:-1]; \
    } \
    -(long)incrementFastEnum:(long)ndx \
    { \
        return [self findNext:ndx]; \
    } \
    -(CursorBase *)getCursor:(long)ndx \
    { \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
    } \
@synthesize CName1 = _CName1; \
@synthesize CName2 = _CName2; \
@synthesize CName3 = _CName3; \
@synthesize CName4 = _CName4; \
@synthesize CName5 = _CName5; \
@synthesize CName6 = _CName6; \
@synthesize CName7 = _CName7; \
@synthesize CName8 = _CName8; \
@synthesize CName9 = _CName9; \
@synthesize CName10 = _CName10; \
@synthesize CName11 = _CName11; \
@synthesize CName12 = _CName12; \
@synthesize CName13 = _CName13; \
-(id)initWithTable:(Table *)table \
{ \
    self = [super initWithTable:table]; \
    if (self) { \
        _CName1 = [[TableName##QueryAccessor##CType1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##QueryAccessor##CType2 alloc] initWithColumn:1 query:self]; \
        _CName3 = [[TableName##QueryAccessor##CType3 alloc] initWithColumn:2 query:self]; \
        _CName4 = [[TableName##QueryAccessor##CType4 alloc] initWithColumn:3 query:self]; \
        _CName5 = [[TableName##QueryAccessor##CType5 alloc] initWithColumn:4 query:self]; \
        _CName6 = [[TableName##QueryAccessor##CType6 alloc] initWithColumn:5 query:self]; \
        _CName7 = [[TableName##QueryAccessor##CType7 alloc] initWithColumn:6 query:self]; \
        _CName8 = [[TableName##QueryAccessor##CType8 alloc] initWithColumn:7 query:self]; \
        _CName9 = [[TableName##QueryAccessor##CType9 alloc] initWithColumn:8 query:self]; \
        _CName10 = [[TableName##QueryAccessor##CType10 alloc] initWithColumn:9 query:self]; \
        _CName11 = [[TableName##QueryAccessor##CType11 alloc] initWithColumn:10 query:self]; \
        _CName12 = [[TableName##QueryAccessor##CType12 alloc] initWithColumn:11 query:self]; \
        _CName13 = [[TableName##QueryAccessor##CType13 alloc] initWithColumn:12 query:self]; \
    } \
    return self; \
} \
-(TableName##_##Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_##Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_##Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_##Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_##Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_##View *)findAll \
    { \
        return [[TableName##_##View alloc] initFromQuery:self]; \
    } \
@end \
@implementation TableName##QueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
-(TableName##_##Query *)notEqual:(size_t)value \
{ \
    return (TableName##_##Query *)[super notEqual:value]; \
} \
-(TableName##_##Query *)greater:(int64_t)value \
{ \
    return (TableName##_##Query *)[super greater:value]; \
} \
-(TableName##_##Query *)less:(int64_t)value \
{ \
    return (TableName##_##Query *)[super less:value]; \
} \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to \
{ \
    return (TableName##_##Query *)[super between:from to:to]; \
} \
@end \
@implementation TableName##QueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
@end \
@implementation TableName##QueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super equal:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super notEqual:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super beginsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super endsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super contains:value caseSensitive:caseSensitive]; \
} \
@end \
@implementation TableName \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
@synthesize CName1 = _##CName1; \
@synthesize CName2 = _##CName2; \
@synthesize CName3 = _##CName3; \
@synthesize CName4 = _##CName4; \
@synthesize CName5 = _##CName5; \
@synthesize CName6 = _##CName6; \
@synthesize CName7 = _##CName7; \
@synthesize CName8 = _##CName8; \
@synthesize CName9 = _##CName9; \
@synthesize CName10 = _##CName10; \
@synthesize CName11 = _##CName11; \
@synthesize CName12 = _##CName12; \
@synthesize CName13 = _##CName13; \
\
-(id)initWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        if ([self getColumnCount] == 0) { \
            [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
            [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
            [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
            [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
            [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
            [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
            [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
            [self registerColumn:COLTYPE##CType8 name:[NSString stringWithUTF8String:#CName8]]; \
            [self registerColumn:COLTYPE##CType9 name:[NSString stringWithUTF8String:#CName9]]; \
            [self registerColumn:COLTYPE##CType10 name:[NSString stringWithUTF8String:#CName10]]; \
            [self registerColumn:COLTYPE##CType11 name:[NSString stringWithUTF8String:#CName11]]; \
            [self registerColumn:COLTYPE##CType12 name:[NSString stringWithUTF8String:#CName12]]; \
            [self registerColumn:COLTYPE##CType13 name:[NSString stringWithUTF8String:#CName13]]; \
        } \
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
        _##CName8 = [[OCColumnProxy##CType8 alloc] initWithTable:self column:7]; \
        _##CName9 = [[OCColumnProxy##CType9 alloc] initWithTable:self column:8]; \
        _##CName10 = [[OCColumnProxy##CType10 alloc] initWithTable:self column:9]; \
        _##CName11 = [[OCColumnProxy##CType11 alloc] initWithTable:self column:10]; \
        _##CName12 = [[OCColumnProxy##CType12 alloc] initWithTable:self column:11]; \
        _##CName13 = [[OCColumnProxy##CType13 alloc] initWithTable:self column:12]; \
    } \
    return self; \
} \
-(id)initCreateWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
        [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
        [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
        [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
        [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
        [self registerColumn:COLTYPE##CType8 name:[NSString stringWithUTF8String:#CName8]]; \
        [self registerColumn:COLTYPE##CType9 name:[NSString stringWithUTF8String:#CName9]]; \
        [self registerColumn:COLTYPE##CType10 name:[NSString stringWithUTF8String:#CName10]]; \
        [self registerColumn:COLTYPE##CType11 name:[NSString stringWithUTF8String:#CName11]]; \
        [self registerColumn:COLTYPE##CType12 name:[NSString stringWithUTF8String:#CName12]]; \
        [self registerColumn:COLTYPE##CType13 name:[NSString stringWithUTF8String:#CName13]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
        _##CName8 = [[OCColumnProxy##CType8 alloc] initWithTable:self column:7]; \
        _##CName9 = [[OCColumnProxy##CType9 alloc] initWithTable:self column:8]; \
        _##CName10 = [[OCColumnProxy##CType10 alloc] initWithTable:self column:9]; \
        _##CName11 = [[OCColumnProxy##CType11 alloc] initWithTable:self column:10]; \
        _##CName12 = [[OCColumnProxy##CType12 alloc] initWithTable:self column:11]; \
        _##CName13 = [[OCColumnProxy##CType13 alloc] initWithTable:self column:12]; \
    } \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
        [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
        [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
        [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
        [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
        [self registerColumn:COLTYPE##CType8 name:[NSString stringWithUTF8String:#CName8]]; \
        [self registerColumn:COLTYPE##CType9 name:[NSString stringWithUTF8String:#CName9]]; \
        [self registerColumn:COLTYPE##CType10 name:[NSString stringWithUTF8String:#CName10]]; \
        [self registerColumn:COLTYPE##CType11 name:[NSString stringWithUTF8String:#CName11]]; \
        [self registerColumn:COLTYPE##CType12 name:[NSString stringWithUTF8String:#CName12]]; \
        [self registerColumn:COLTYPE##CType13 name:[NSString stringWithUTF8String:#CName13]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
        _##CName8 = [[OCColumnProxy##CType8 alloc] initWithTable:self column:7]; \
        _##CName9 = [[OCColumnProxy##CType9 alloc] initWithTable:self column:8]; \
        _##CName10 = [[OCColumnProxy##CType10 alloc] initWithTable:self column:9]; \
        _##CName11 = [[OCColumnProxy##CType11 alloc] initWithTable:self column:10]; \
        _##CName12 = [[OCColumnProxy##CType12 alloc] initWithTable:self column:11]; \
        _##CName13 = [[OCColumnProxy##CType13 alloc] initWithTable:self column:12]; \
    } \
    return self; \
} \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9 CName10:(tdbOCType##CType10)CName10 CName11:(tdbOCType##CType11)CName11 CName12:(tdbOCType##CType12)CName12 CName13:(tdbOCType##CType13)CName13 \
{ \
    const size_t ndx = [self count]; \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insert##CType4:3 ndx:ndx value:CName4]; \
    [self insert##CType5:4 ndx:ndx value:CName5]; \
    [self insert##CType6:5 ndx:ndx value:CName6]; \
    [self insert##CType7:6 ndx:ndx value:CName7]; \
    [self insert##CType8:7 ndx:ndx value:CName8]; \
    [self insert##CType9:8 ndx:ndx value:CName9]; \
    [self insert##CType10:9 ndx:ndx value:CName10]; \
    [self insert##CType11:10 ndx:ndx value:CName11]; \
    [self insert##CType12:11 ndx:ndx value:CName12]; \
    [self insert##CType13:12 ndx:ndx value:CName13]; \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9 CName10:(tdbOCType##CType10)CName10 CName11:(tdbOCType##CType11)CName11 CName12:(tdbOCType##CType12)CName12 CName13:(tdbOCType##CType13)CName13 \
{ \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insert##CType4:3 ndx:ndx value:CName4]; \
    [self insert##CType5:4 ndx:ndx value:CName5]; \
    [self insert##CType6:5 ndx:ndx value:CName6]; \
    [self insert##CType7:6 ndx:ndx value:CName7]; \
    [self insert##CType8:7 ndx:ndx value:CName8]; \
    [self insert##CType9:8 ndx:ndx value:CName9]; \
    [self insert##CType10:9 ndx:ndx value:CName10]; \
    [self insert##CType11:10 ndx:ndx value:CName11]; \
    [self insert##CType12:11 ndx:ndx value:CName12]; \
    [self insert##CType13:12 ndx:ndx value:CName13]; \
    [self insertDone]; \
} \
-(TableName##_##Query *)getQuery \
{ \
    return [[TableName##_##Query alloc] initWithTable:self]; \
} \
-(TableName##_##Cursor *)add \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self addRow]]; \
} \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:ndx]; \
} \
-(TableName##_##Cursor *)lastObject \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self count]-1]; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:self ndx:0]; \
} \
@end \
@implementation TableName##_##View \
    { \
        TableName##_##Cursor *tmpCursor; \
    } \
    -(CursorBase *)getCursor \
    { \
        return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
    } \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
    { \
    return [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
    } \
@end

#undef TIGHTDB_TABLE_IMPL_14
#define TIGHTDB_TABLE_IMPL_14(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10, CType11, CName11, CType12, CName12, CType13, CName13, CType14, CName14) \
@implementation TableName##_##Cursor \
    { \
        OCAccessor *_##CName1; \
        OCAccessor *_##CName2; \
        OCAccessor *_##CName3; \
        OCAccessor *_##CName4; \
        OCAccessor *_##CName5; \
        OCAccessor *_##CName6; \
        OCAccessor *_##CName7; \
        OCAccessor *_##CName8; \
        OCAccessor *_##CName9; \
        OCAccessor *_##CName10; \
        OCAccessor *_##CName11; \
        OCAccessor *_##CName12; \
        OCAccessor *_##CName13; \
        OCAccessor *_##CName14; \
    } \
    -(id)initWithTable:(Table *)table ndx:(size_t)ndx; \
    { \
    self = [super initWithTable:table ndx:ndx]; \
    if (self) { \
    _##CName1 = [[OCAccessor alloc] initWithCursor:self columnId:0]; \
    _##CName2 = [[OCAccessor alloc] initWithCursor:self columnId:1]; \
    _##CName3 = [[OCAccessor alloc] initWithCursor:self columnId:2]; \
    _##CName4 = [[OCAccessor alloc] initWithCursor:self columnId:3]; \
    _##CName5 = [[OCAccessor alloc] initWithCursor:self columnId:4]; \
    _##CName6 = [[OCAccessor alloc] initWithCursor:self columnId:5]; \
    _##CName7 = [[OCAccessor alloc] initWithCursor:self columnId:6]; \
    _##CName8 = [[OCAccessor alloc] initWithCursor:self columnId:7]; \
    _##CName9 = [[OCAccessor alloc] initWithCursor:self columnId:8]; \
    _##CName10 = [[OCAccessor alloc] initWithCursor:self columnId:9]; \
    _##CName11 = [[OCAccessor alloc] initWithCursor:self columnId:10]; \
    _##CName12 = [[OCAccessor alloc] initWithCursor:self columnId:11]; \
    _##CName13 = [[OCAccessor alloc] initWithCursor:self columnId:12]; \
    _##CName14 = [[OCAccessor alloc] initWithCursor:self columnId:13]; \
    } \
    return self; \
    } \
    -(tdbOCType##CType1)CName1 \
    { \
        return [_##CName1 get##CType1]; \
    } \
    -(void)set##CName1:(tdbOCType##CType1)value \
    { \
    [_##CName1 set##CType1:value]; \
    } \
    -(tdbOCType##CType2)CName2 \
    { \
        return [_##CName2 get##CType2]; \
    } \
    -(void)set##CName2:(tdbOCType##CType2)value \
    { \
    [_##CName2 set##CType2:value]; \
    } \
    -(tdbOCType##CType3)CName3 \
    { \
        return [_##CName3 get##CType3]; \
    } \
    -(void)set##CName3:(tdbOCType##CType3)value \
    { \
    [_##CName3 set##CType3:value]; \
    } \
    -(tdbOCType##CType4)CName4 \
    { \
        return [_##CName4 get##CType4]; \
    } \
    -(void)set##CName4:(tdbOCType##CType4)value \
    { \
    [_##CName4 set##CType4:value]; \
    } \
    -(tdbOCType##CType5)CName5 \
    { \
        return [_##CName5 get##CType5]; \
    } \
    -(void)set##CName5:(tdbOCType##CType5)value \
    { \
    [_##CName5 set##CType5:value]; \
    } \
    -(tdbOCType##CType6)CName6 \
    { \
        return [_##CName6 get##CType6]; \
    } \
    -(void)set##CName6:(tdbOCType##CType6)value \
    { \
    [_##CName6 set##CType6:value]; \
    } \
    -(tdbOCType##CType7)CName7 \
    { \
        return [_##CName7 get##CType7]; \
    } \
    -(void)set##CName7:(tdbOCType##CType7)value \
    { \
    [_##CName7 set##CType7:value]; \
    } \
    -(tdbOCType##CType8)CName8 \
    { \
        return [_##CName8 get##CType8]; \
    } \
    -(void)set##CName8:(tdbOCType##CType8)value \
    { \
    [_##CName8 set##CType8:value]; \
    } \
    -(tdbOCType##CType9)CName9 \
    { \
        return [_##CName9 get##CType9]; \
    } \
    -(void)set##CName9:(tdbOCType##CType9)value \
    { \
    [_##CName9 set##CType9:value]; \
    } \
    -(tdbOCType##CType10)CName10 \
    { \
        return [_##CName10 get##CType10]; \
    } \
    -(void)set##CName10:(tdbOCType##CType10)value \
    { \
    [_##CName10 set##CType10:value]; \
    } \
    -(tdbOCType##CType11)CName11 \
    { \
        return [_##CName11 get##CType11]; \
    } \
    -(void)set##CName11:(tdbOCType##CType11)value \
    { \
    [_##CName11 set##CType11:value]; \
    } \
    -(tdbOCType##CType12)CName12 \
    { \
        return [_##CName12 get##CType12]; \
    } \
    -(void)set##CName12:(tdbOCType##CType12)value \
    { \
    [_##CName12 set##CType12:value]; \
    } \
    -(tdbOCType##CType13)CName13 \
    { \
        return [_##CName13 get##CType13]; \
    } \
    -(void)set##CName13:(tdbOCType##CType13)value \
    { \
    [_##CName13 set##CType13:value]; \
    } \
    -(tdbOCType##CType14)CName14 \
    { \
        return [_##CName14 get##CType14]; \
    } \
    -(void)set##CName14:(tdbOCType##CType14)value \
    { \
    [_##CName14 set##CType14:value]; \
    } \
@end \
@implementation TableName##_##Query \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
    -(long)getFastEnumStart \
    { \
       return [self findNext:-1]; \
    } \
    -(long)incrementFastEnum:(long)ndx \
    { \
        return [self findNext:ndx]; \
    } \
    -(CursorBase *)getCursor:(long)ndx \
    { \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
    } \
@synthesize CName1 = _CName1; \
@synthesize CName2 = _CName2; \
@synthesize CName3 = _CName3; \
@synthesize CName4 = _CName4; \
@synthesize CName5 = _CName5; \
@synthesize CName6 = _CName6; \
@synthesize CName7 = _CName7; \
@synthesize CName8 = _CName8; \
@synthesize CName9 = _CName9; \
@synthesize CName10 = _CName10; \
@synthesize CName11 = _CName11; \
@synthesize CName12 = _CName12; \
@synthesize CName13 = _CName13; \
@synthesize CName14 = _CName14; \
-(id)initWithTable:(Table *)table \
{ \
    self = [super initWithTable:table]; \
    if (self) { \
        _CName1 = [[TableName##QueryAccessor##CType1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##QueryAccessor##CType2 alloc] initWithColumn:1 query:self]; \
        _CName3 = [[TableName##QueryAccessor##CType3 alloc] initWithColumn:2 query:self]; \
        _CName4 = [[TableName##QueryAccessor##CType4 alloc] initWithColumn:3 query:self]; \
        _CName5 = [[TableName##QueryAccessor##CType5 alloc] initWithColumn:4 query:self]; \
        _CName6 = [[TableName##QueryAccessor##CType6 alloc] initWithColumn:5 query:self]; \
        _CName7 = [[TableName##QueryAccessor##CType7 alloc] initWithColumn:6 query:self]; \
        _CName8 = [[TableName##QueryAccessor##CType8 alloc] initWithColumn:7 query:self]; \
        _CName9 = [[TableName##QueryAccessor##CType9 alloc] initWithColumn:8 query:self]; \
        _CName10 = [[TableName##QueryAccessor##CType10 alloc] initWithColumn:9 query:self]; \
        _CName11 = [[TableName##QueryAccessor##CType11 alloc] initWithColumn:10 query:self]; \
        _CName12 = [[TableName##QueryAccessor##CType12 alloc] initWithColumn:11 query:self]; \
        _CName13 = [[TableName##QueryAccessor##CType13 alloc] initWithColumn:12 query:self]; \
        _CName14 = [[TableName##QueryAccessor##CType14 alloc] initWithColumn:13 query:self]; \
    } \
    return self; \
} \
-(TableName##_##Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_##Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_##Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_##Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_##Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_##View *)findAll \
    { \
        return [[TableName##_##View alloc] initFromQuery:self]; \
    } \
@end \
@implementation TableName##QueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
-(TableName##_##Query *)notEqual:(size_t)value \
{ \
    return (TableName##_##Query *)[super notEqual:value]; \
} \
-(TableName##_##Query *)greater:(int64_t)value \
{ \
    return (TableName##_##Query *)[super greater:value]; \
} \
-(TableName##_##Query *)less:(int64_t)value \
{ \
    return (TableName##_##Query *)[super less:value]; \
} \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to \
{ \
    return (TableName##_##Query *)[super between:from to:to]; \
} \
@end \
@implementation TableName##QueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
@end \
@implementation TableName##QueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super equal:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super notEqual:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super beginsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super endsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super contains:value caseSensitive:caseSensitive]; \
} \
@end \
@implementation TableName \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
@synthesize CName1 = _##CName1; \
@synthesize CName2 = _##CName2; \
@synthesize CName3 = _##CName3; \
@synthesize CName4 = _##CName4; \
@synthesize CName5 = _##CName5; \
@synthesize CName6 = _##CName6; \
@synthesize CName7 = _##CName7; \
@synthesize CName8 = _##CName8; \
@synthesize CName9 = _##CName9; \
@synthesize CName10 = _##CName10; \
@synthesize CName11 = _##CName11; \
@synthesize CName12 = _##CName12; \
@synthesize CName13 = _##CName13; \
@synthesize CName14 = _##CName14; \
\
-(id)initWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        if ([self getColumnCount] == 0) { \
            [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
            [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
            [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
            [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
            [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
            [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
            [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
            [self registerColumn:COLTYPE##CType8 name:[NSString stringWithUTF8String:#CName8]]; \
            [self registerColumn:COLTYPE##CType9 name:[NSString stringWithUTF8String:#CName9]]; \
            [self registerColumn:COLTYPE##CType10 name:[NSString stringWithUTF8String:#CName10]]; \
            [self registerColumn:COLTYPE##CType11 name:[NSString stringWithUTF8String:#CName11]]; \
            [self registerColumn:COLTYPE##CType12 name:[NSString stringWithUTF8String:#CName12]]; \
            [self registerColumn:COLTYPE##CType13 name:[NSString stringWithUTF8String:#CName13]]; \
            [self registerColumn:COLTYPE##CType14 name:[NSString stringWithUTF8String:#CName14]]; \
        } \
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
        _##CName8 = [[OCColumnProxy##CType8 alloc] initWithTable:self column:7]; \
        _##CName9 = [[OCColumnProxy##CType9 alloc] initWithTable:self column:8]; \
        _##CName10 = [[OCColumnProxy##CType10 alloc] initWithTable:self column:9]; \
        _##CName11 = [[OCColumnProxy##CType11 alloc] initWithTable:self column:10]; \
        _##CName12 = [[OCColumnProxy##CType12 alloc] initWithTable:self column:11]; \
        _##CName13 = [[OCColumnProxy##CType13 alloc] initWithTable:self column:12]; \
        _##CName14 = [[OCColumnProxy##CType14 alloc] initWithTable:self column:13]; \
    } \
    return self; \
} \
-(id)initCreateWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
        [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
        [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
        [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
        [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
        [self registerColumn:COLTYPE##CType8 name:[NSString stringWithUTF8String:#CName8]]; \
        [self registerColumn:COLTYPE##CType9 name:[NSString stringWithUTF8String:#CName9]]; \
        [self registerColumn:COLTYPE##CType10 name:[NSString stringWithUTF8String:#CName10]]; \
        [self registerColumn:COLTYPE##CType11 name:[NSString stringWithUTF8String:#CName11]]; \
        [self registerColumn:COLTYPE##CType12 name:[NSString stringWithUTF8String:#CName12]]; \
        [self registerColumn:COLTYPE##CType13 name:[NSString stringWithUTF8String:#CName13]]; \
        [self registerColumn:COLTYPE##CType14 name:[NSString stringWithUTF8String:#CName14]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
        _##CName8 = [[OCColumnProxy##CType8 alloc] initWithTable:self column:7]; \
        _##CName9 = [[OCColumnProxy##CType9 alloc] initWithTable:self column:8]; \
        _##CName10 = [[OCColumnProxy##CType10 alloc] initWithTable:self column:9]; \
        _##CName11 = [[OCColumnProxy##CType11 alloc] initWithTable:self column:10]; \
        _##CName12 = [[OCColumnProxy##CType12 alloc] initWithTable:self column:11]; \
        _##CName13 = [[OCColumnProxy##CType13 alloc] initWithTable:self column:12]; \
        _##CName14 = [[OCColumnProxy##CType14 alloc] initWithTable:self column:13]; \
    } \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
        [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
        [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
        [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
        [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
        [self registerColumn:COLTYPE##CType8 name:[NSString stringWithUTF8String:#CName8]]; \
        [self registerColumn:COLTYPE##CType9 name:[NSString stringWithUTF8String:#CName9]]; \
        [self registerColumn:COLTYPE##CType10 name:[NSString stringWithUTF8String:#CName10]]; \
        [self registerColumn:COLTYPE##CType11 name:[NSString stringWithUTF8String:#CName11]]; \
        [self registerColumn:COLTYPE##CType12 name:[NSString stringWithUTF8String:#CName12]]; \
        [self registerColumn:COLTYPE##CType13 name:[NSString stringWithUTF8String:#CName13]]; \
        [self registerColumn:COLTYPE##CType14 name:[NSString stringWithUTF8String:#CName14]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
        _##CName8 = [[OCColumnProxy##CType8 alloc] initWithTable:self column:7]; \
        _##CName9 = [[OCColumnProxy##CType9 alloc] initWithTable:self column:8]; \
        _##CName10 = [[OCColumnProxy##CType10 alloc] initWithTable:self column:9]; \
        _##CName11 = [[OCColumnProxy##CType11 alloc] initWithTable:self column:10]; \
        _##CName12 = [[OCColumnProxy##CType12 alloc] initWithTable:self column:11]; \
        _##CName13 = [[OCColumnProxy##CType13 alloc] initWithTable:self column:12]; \
        _##CName14 = [[OCColumnProxy##CType14 alloc] initWithTable:self column:13]; \
    } \
    return self; \
} \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9 CName10:(tdbOCType##CType10)CName10 CName11:(tdbOCType##CType11)CName11 CName12:(tdbOCType##CType12)CName12 CName13:(tdbOCType##CType13)CName13 CName14:(tdbOCType##CType14)CName14 \
{ \
    const size_t ndx = [self count]; \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insert##CType4:3 ndx:ndx value:CName4]; \
    [self insert##CType5:4 ndx:ndx value:CName5]; \
    [self insert##CType6:5 ndx:ndx value:CName6]; \
    [self insert##CType7:6 ndx:ndx value:CName7]; \
    [self insert##CType8:7 ndx:ndx value:CName8]; \
    [self insert##CType9:8 ndx:ndx value:CName9]; \
    [self insert##CType10:9 ndx:ndx value:CName10]; \
    [self insert##CType11:10 ndx:ndx value:CName11]; \
    [self insert##CType12:11 ndx:ndx value:CName12]; \
    [self insert##CType13:12 ndx:ndx value:CName13]; \
    [self insert##CType14:13 ndx:ndx value:CName14]; \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9 CName10:(tdbOCType##CType10)CName10 CName11:(tdbOCType##CType11)CName11 CName12:(tdbOCType##CType12)CName12 CName13:(tdbOCType##CType13)CName13 CName14:(tdbOCType##CType14)CName14 \
{ \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insert##CType4:3 ndx:ndx value:CName4]; \
    [self insert##CType5:4 ndx:ndx value:CName5]; \
    [self insert##CType6:5 ndx:ndx value:CName6]; \
    [self insert##CType7:6 ndx:ndx value:CName7]; \
    [self insert##CType8:7 ndx:ndx value:CName8]; \
    [self insert##CType9:8 ndx:ndx value:CName9]; \
    [self insert##CType10:9 ndx:ndx value:CName10]; \
    [self insert##CType11:10 ndx:ndx value:CName11]; \
    [self insert##CType12:11 ndx:ndx value:CName12]; \
    [self insert##CType13:12 ndx:ndx value:CName13]; \
    [self insert##CType14:13 ndx:ndx value:CName14]; \
    [self insertDone]; \
} \
-(TableName##_##Query *)getQuery \
{ \
    return [[TableName##_##Query alloc] initWithTable:self]; \
} \
-(TableName##_##Cursor *)add \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self addRow]]; \
} \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:ndx]; \
} \
-(TableName##_##Cursor *)lastObject \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self count]-1]; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:self ndx:0]; \
} \
@end \
@implementation TableName##_##View \
    { \
        TableName##_##Cursor *tmpCursor; \
    } \
    -(CursorBase *)getCursor \
    { \
        return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
    } \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
    { \
    return [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
    } \
@end

#undef TIGHTDB_TABLE_IMPL_15
#define TIGHTDB_TABLE_IMPL_15(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10, CType11, CName11, CType12, CName12, CType13, CName13, CType14, CName14, CType15, CName15) \
@implementation TableName##_##Cursor \
    { \
        OCAccessor *_##CName1; \
        OCAccessor *_##CName2; \
        OCAccessor *_##CName3; \
        OCAccessor *_##CName4; \
        OCAccessor *_##CName5; \
        OCAccessor *_##CName6; \
        OCAccessor *_##CName7; \
        OCAccessor *_##CName8; \
        OCAccessor *_##CName9; \
        OCAccessor *_##CName10; \
        OCAccessor *_##CName11; \
        OCAccessor *_##CName12; \
        OCAccessor *_##CName13; \
        OCAccessor *_##CName14; \
        OCAccessor *_##CName15; \
    } \
    -(id)initWithTable:(Table *)table ndx:(size_t)ndx; \
    { \
    self = [super initWithTable:table ndx:ndx]; \
    if (self) { \
    _##CName1 = [[OCAccessor alloc] initWithCursor:self columnId:0]; \
    _##CName2 = [[OCAccessor alloc] initWithCursor:self columnId:1]; \
    _##CName3 = [[OCAccessor alloc] initWithCursor:self columnId:2]; \
    _##CName4 = [[OCAccessor alloc] initWithCursor:self columnId:3]; \
    _##CName5 = [[OCAccessor alloc] initWithCursor:self columnId:4]; \
    _##CName6 = [[OCAccessor alloc] initWithCursor:self columnId:5]; \
    _##CName7 = [[OCAccessor alloc] initWithCursor:self columnId:6]; \
    _##CName8 = [[OCAccessor alloc] initWithCursor:self columnId:7]; \
    _##CName9 = [[OCAccessor alloc] initWithCursor:self columnId:8]; \
    _##CName10 = [[OCAccessor alloc] initWithCursor:self columnId:9]; \
    _##CName11 = [[OCAccessor alloc] initWithCursor:self columnId:10]; \
    _##CName12 = [[OCAccessor alloc] initWithCursor:self columnId:11]; \
    _##CName13 = [[OCAccessor alloc] initWithCursor:self columnId:12]; \
    _##CName14 = [[OCAccessor alloc] initWithCursor:self columnId:13]; \
    _##CName15 = [[OCAccessor alloc] initWithCursor:self columnId:14]; \
    } \
    return self; \
    } \
    -(tdbOCType##CType1)CName1 \
    { \
        return [_##CName1 get##CType1]; \
    } \
    -(void)set##CName1:(tdbOCType##CType1)value \
    { \
    [_##CName1 set##CType1:value]; \
    } \
    -(tdbOCType##CType2)CName2 \
    { \
        return [_##CName2 get##CType2]; \
    } \
    -(void)set##CName2:(tdbOCType##CType2)value \
    { \
    [_##CName2 set##CType2:value]; \
    } \
    -(tdbOCType##CType3)CName3 \
    { \
        return [_##CName3 get##CType3]; \
    } \
    -(void)set##CName3:(tdbOCType##CType3)value \
    { \
    [_##CName3 set##CType3:value]; \
    } \
    -(tdbOCType##CType4)CName4 \
    { \
        return [_##CName4 get##CType4]; \
    } \
    -(void)set##CName4:(tdbOCType##CType4)value \
    { \
    [_##CName4 set##CType4:value]; \
    } \
    -(tdbOCType##CType5)CName5 \
    { \
        return [_##CName5 get##CType5]; \
    } \
    -(void)set##CName5:(tdbOCType##CType5)value \
    { \
    [_##CName5 set##CType5:value]; \
    } \
    -(tdbOCType##CType6)CName6 \
    { \
        return [_##CName6 get##CType6]; \
    } \
    -(void)set##CName6:(tdbOCType##CType6)value \
    { \
    [_##CName6 set##CType6:value]; \
    } \
    -(tdbOCType##CType7)CName7 \
    { \
        return [_##CName7 get##CType7]; \
    } \
    -(void)set##CName7:(tdbOCType##CType7)value \
    { \
    [_##CName7 set##CType7:value]; \
    } \
    -(tdbOCType##CType8)CName8 \
    { \
        return [_##CName8 get##CType8]; \
    } \
    -(void)set##CName8:(tdbOCType##CType8)value \
    { \
    [_##CName8 set##CType8:value]; \
    } \
    -(tdbOCType##CType9)CName9 \
    { \
        return [_##CName9 get##CType9]; \
    } \
    -(void)set##CName9:(tdbOCType##CType9)value \
    { \
    [_##CName9 set##CType9:value]; \
    } \
    -(tdbOCType##CType10)CName10 \
    { \
        return [_##CName10 get##CType10]; \
    } \
    -(void)set##CName10:(tdbOCType##CType10)value \
    { \
    [_##CName10 set##CType10:value]; \
    } \
    -(tdbOCType##CType11)CName11 \
    { \
        return [_##CName11 get##CType11]; \
    } \
    -(void)set##CName11:(tdbOCType##CType11)value \
    { \
    [_##CName11 set##CType11:value]; \
    } \
    -(tdbOCType##CType12)CName12 \
    { \
        return [_##CName12 get##CType12]; \
    } \
    -(void)set##CName12:(tdbOCType##CType12)value \
    { \
    [_##CName12 set##CType12:value]; \
    } \
    -(tdbOCType##CType13)CName13 \
    { \
        return [_##CName13 get##CType13]; \
    } \
    -(void)set##CName13:(tdbOCType##CType13)value \
    { \
    [_##CName13 set##CType13:value]; \
    } \
    -(tdbOCType##CType14)CName14 \
    { \
        return [_##CName14 get##CType14]; \
    } \
    -(void)set##CName14:(tdbOCType##CType14)value \
    { \
    [_##CName14 set##CType14:value]; \
    } \
    -(tdbOCType##CType15)CName15 \
    { \
        return [_##CName15 get##CType15]; \
    } \
    -(void)set##CName15:(tdbOCType##CType15)value \
    { \
    [_##CName15 set##CType15:value]; \
    } \
@end \
@implementation TableName##_##Query \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
    -(long)getFastEnumStart \
    { \
       return [self findNext:-1]; \
    } \
    -(long)incrementFastEnum:(long)ndx \
    { \
        return [self findNext:ndx]; \
    } \
    -(CursorBase *)getCursor:(long)ndx \
    { \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
    } \
@synthesize CName1 = _CName1; \
@synthesize CName2 = _CName2; \
@synthesize CName3 = _CName3; \
@synthesize CName4 = _CName4; \
@synthesize CName5 = _CName5; \
@synthesize CName6 = _CName6; \
@synthesize CName7 = _CName7; \
@synthesize CName8 = _CName8; \
@synthesize CName9 = _CName9; \
@synthesize CName10 = _CName10; \
@synthesize CName11 = _CName11; \
@synthesize CName12 = _CName12; \
@synthesize CName13 = _CName13; \
@synthesize CName14 = _CName14; \
@synthesize CName15 = _CName15; \
-(id)initWithTable:(Table *)table \
{ \
    self = [super initWithTable:table]; \
    if (self) { \
        _CName1 = [[TableName##QueryAccessor##CType1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##QueryAccessor##CType2 alloc] initWithColumn:1 query:self]; \
        _CName3 = [[TableName##QueryAccessor##CType3 alloc] initWithColumn:2 query:self]; \
        _CName4 = [[TableName##QueryAccessor##CType4 alloc] initWithColumn:3 query:self]; \
        _CName5 = [[TableName##QueryAccessor##CType5 alloc] initWithColumn:4 query:self]; \
        _CName6 = [[TableName##QueryAccessor##CType6 alloc] initWithColumn:5 query:self]; \
        _CName7 = [[TableName##QueryAccessor##CType7 alloc] initWithColumn:6 query:self]; \
        _CName8 = [[TableName##QueryAccessor##CType8 alloc] initWithColumn:7 query:self]; \
        _CName9 = [[TableName##QueryAccessor##CType9 alloc] initWithColumn:8 query:self]; \
        _CName10 = [[TableName##QueryAccessor##CType10 alloc] initWithColumn:9 query:self]; \
        _CName11 = [[TableName##QueryAccessor##CType11 alloc] initWithColumn:10 query:self]; \
        _CName12 = [[TableName##QueryAccessor##CType12 alloc] initWithColumn:11 query:self]; \
        _CName13 = [[TableName##QueryAccessor##CType13 alloc] initWithColumn:12 query:self]; \
        _CName14 = [[TableName##QueryAccessor##CType14 alloc] initWithColumn:13 query:self]; \
        _CName15 = [[TableName##QueryAccessor##CType15 alloc] initWithColumn:14 query:self]; \
    } \
    return self; \
} \
-(TableName##_##Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_##Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_##Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_##Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_##Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_##View *)findAll \
    { \
        return [[TableName##_##View alloc] initFromQuery:self]; \
    } \
@end \
@implementation TableName##QueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
-(TableName##_##Query *)notEqual:(size_t)value \
{ \
    return (TableName##_##Query *)[super notEqual:value]; \
} \
-(TableName##_##Query *)greater:(int64_t)value \
{ \
    return (TableName##_##Query *)[super greater:value]; \
} \
-(TableName##_##Query *)less:(int64_t)value \
{ \
    return (TableName##_##Query *)[super less:value]; \
} \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to \
{ \
    return (TableName##_##Query *)[super between:from to:to]; \
} \
@end \
@implementation TableName##QueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value \
{ \
    return (TableName##_##Query *)[super equal:value]; \
} \
@end \
@implementation TableName##QueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super equal:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super notEqual:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super beginsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super endsWith:value caseSensitive:caseSensitive]; \
} \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (TableName##_##Query *)[super contains:value caseSensitive:caseSensitive]; \
} \
@end \
@implementation TableName \
    { \
    TableName##_##Cursor *tmpCursor; \
    } \
@synthesize CName1 = _##CName1; \
@synthesize CName2 = _##CName2; \
@synthesize CName3 = _##CName3; \
@synthesize CName4 = _##CName4; \
@synthesize CName5 = _##CName5; \
@synthesize CName6 = _##CName6; \
@synthesize CName7 = _##CName7; \
@synthesize CName8 = _##CName8; \
@synthesize CName9 = _##CName9; \
@synthesize CName10 = _##CName10; \
@synthesize CName11 = _##CName11; \
@synthesize CName12 = _##CName12; \
@synthesize CName13 = _##CName13; \
@synthesize CName14 = _##CName14; \
@synthesize CName15 = _##CName15; \
\
-(id)initWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        if ([self getColumnCount] == 0) { \
            [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
            [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
            [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
            [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
            [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
            [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
            [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
            [self registerColumn:COLTYPE##CType8 name:[NSString stringWithUTF8String:#CName8]]; \
            [self registerColumn:COLTYPE##CType9 name:[NSString stringWithUTF8String:#CName9]]; \
            [self registerColumn:COLTYPE##CType10 name:[NSString stringWithUTF8String:#CName10]]; \
            [self registerColumn:COLTYPE##CType11 name:[NSString stringWithUTF8String:#CName11]]; \
            [self registerColumn:COLTYPE##CType12 name:[NSString stringWithUTF8String:#CName12]]; \
            [self registerColumn:COLTYPE##CType13 name:[NSString stringWithUTF8String:#CName13]]; \
            [self registerColumn:COLTYPE##CType14 name:[NSString stringWithUTF8String:#CName14]]; \
            [self registerColumn:COLTYPE##CType15 name:[NSString stringWithUTF8String:#CName15]]; \
        } \
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
        _##CName8 = [[OCColumnProxy##CType8 alloc] initWithTable:self column:7]; \
        _##CName9 = [[OCColumnProxy##CType9 alloc] initWithTable:self column:8]; \
        _##CName10 = [[OCColumnProxy##CType10 alloc] initWithTable:self column:9]; \
        _##CName11 = [[OCColumnProxy##CType11 alloc] initWithTable:self column:10]; \
        _##CName12 = [[OCColumnProxy##CType12 alloc] initWithTable:self column:11]; \
        _##CName13 = [[OCColumnProxy##CType13 alloc] initWithTable:self column:12]; \
        _##CName14 = [[OCColumnProxy##CType14 alloc] initWithTable:self column:13]; \
        _##CName15 = [[OCColumnProxy##CType15 alloc] initWithTable:self column:14]; \
    } \
    return self; \
} \
-(id)initCreateWithBlock:(TopLevelTableInitBlock)block \
{ \
    self = [super initWithBlock:block]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
        [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
        [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
        [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
        [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
        [self registerColumn:COLTYPE##CType8 name:[NSString stringWithUTF8String:#CName8]]; \
        [self registerColumn:COLTYPE##CType9 name:[NSString stringWithUTF8String:#CName9]]; \
        [self registerColumn:COLTYPE##CType10 name:[NSString stringWithUTF8String:#CName10]]; \
        [self registerColumn:COLTYPE##CType11 name:[NSString stringWithUTF8String:#CName11]]; \
        [self registerColumn:COLTYPE##CType12 name:[NSString stringWithUTF8String:#CName12]]; \
        [self registerColumn:COLTYPE##CType13 name:[NSString stringWithUTF8String:#CName13]]; \
        [self registerColumn:COLTYPE##CType14 name:[NSString stringWithUTF8String:#CName14]]; \
        [self registerColumn:COLTYPE##CType15 name:[NSString stringWithUTF8String:#CName15]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
        _##CName8 = [[OCColumnProxy##CType8 alloc] initWithTable:self column:7]; \
        _##CName9 = [[OCColumnProxy##CType9 alloc] initWithTable:self column:8]; \
        _##CName10 = [[OCColumnProxy##CType10 alloc] initWithTable:self column:9]; \
        _##CName11 = [[OCColumnProxy##CType11 alloc] initWithTable:self column:10]; \
        _##CName12 = [[OCColumnProxy##CType12 alloc] initWithTable:self column:11]; \
        _##CName13 = [[OCColumnProxy##CType13 alloc] initWithTable:self column:12]; \
        _##CName14 = [[OCColumnProxy##CType14 alloc] initWithTable:self column:13]; \
        _##CName15 = [[OCColumnProxy##CType15 alloc] initWithTable:self column:14]; \
    } \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (self) { \
        [self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
        [self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
        [self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
        [self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
        [self registerColumn:COLTYPE##CType5 name:[NSString stringWithUTF8String:#CName5]]; \
        [self registerColumn:COLTYPE##CType6 name:[NSString stringWithUTF8String:#CName6]]; \
        [self registerColumn:COLTYPE##CType7 name:[NSString stringWithUTF8String:#CName7]]; \
        [self registerColumn:COLTYPE##CType8 name:[NSString stringWithUTF8String:#CName8]]; \
        [self registerColumn:COLTYPE##CType9 name:[NSString stringWithUTF8String:#CName9]]; \
        [self registerColumn:COLTYPE##CType10 name:[NSString stringWithUTF8String:#CName10]]; \
        [self registerColumn:COLTYPE##CType11 name:[NSString stringWithUTF8String:#CName11]]; \
        [self registerColumn:COLTYPE##CType12 name:[NSString stringWithUTF8String:#CName12]]; \
        [self registerColumn:COLTYPE##CType13 name:[NSString stringWithUTF8String:#CName13]]; \
        [self registerColumn:COLTYPE##CType14 name:[NSString stringWithUTF8String:#CName14]]; \
        [self registerColumn:COLTYPE##CType15 name:[NSString stringWithUTF8String:#CName15]]; \
\
        _##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
        _##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
        _##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
        _##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
        _##CName5 = [[OCColumnProxy##CType5 alloc] initWithTable:self column:4]; \
        _##CName6 = [[OCColumnProxy##CType6 alloc] initWithTable:self column:5]; \
        _##CName7 = [[OCColumnProxy##CType7 alloc] initWithTable:self column:6]; \
        _##CName8 = [[OCColumnProxy##CType8 alloc] initWithTable:self column:7]; \
        _##CName9 = [[OCColumnProxy##CType9 alloc] initWithTable:self column:8]; \
        _##CName10 = [[OCColumnProxy##CType10 alloc] initWithTable:self column:9]; \
        _##CName11 = [[OCColumnProxy##CType11 alloc] initWithTable:self column:10]; \
        _##CName12 = [[OCColumnProxy##CType12 alloc] initWithTable:self column:11]; \
        _##CName13 = [[OCColumnProxy##CType13 alloc] initWithTable:self column:12]; \
        _##CName14 = [[OCColumnProxy##CType14 alloc] initWithTable:self column:13]; \
        _##CName15 = [[OCColumnProxy##CType15 alloc] initWithTable:self column:14]; \
    } \
    return self; \
} \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9 CName10:(tdbOCType##CType10)CName10 CName11:(tdbOCType##CType11)CName11 CName12:(tdbOCType##CType12)CName12 CName13:(tdbOCType##CType13)CName13 CName14:(tdbOCType##CType14)CName14 CName15:(tdbOCType##CType15)CName15 \
{ \
    const size_t ndx = [self count]; \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insert##CType4:3 ndx:ndx value:CName4]; \
    [self insert##CType5:4 ndx:ndx value:CName5]; \
    [self insert##CType6:5 ndx:ndx value:CName6]; \
    [self insert##CType7:6 ndx:ndx value:CName7]; \
    [self insert##CType8:7 ndx:ndx value:CName8]; \
    [self insert##CType9:8 ndx:ndx value:CName9]; \
    [self insert##CType10:9 ndx:ndx value:CName10]; \
    [self insert##CType11:10 ndx:ndx value:CName11]; \
    [self insert##CType12:11 ndx:ndx value:CName12]; \
    [self insert##CType13:12 ndx:ndx value:CName13]; \
    [self insert##CType14:13 ndx:ndx value:CName14]; \
    [self insert##CType15:14 ndx:ndx value:CName15]; \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9 CName10:(tdbOCType##CType10)CName10 CName11:(tdbOCType##CType11)CName11 CName12:(tdbOCType##CType12)CName12 CName13:(tdbOCType##CType13)CName13 CName14:(tdbOCType##CType14)CName14 CName15:(tdbOCType##CType15)CName15 \
{ \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insert##CType4:3 ndx:ndx value:CName4]; \
    [self insert##CType5:4 ndx:ndx value:CName5]; \
    [self insert##CType6:5 ndx:ndx value:CName6]; \
    [self insert##CType7:6 ndx:ndx value:CName7]; \
    [self insert##CType8:7 ndx:ndx value:CName8]; \
    [self insert##CType9:8 ndx:ndx value:CName9]; \
    [self insert##CType10:9 ndx:ndx value:CName10]; \
    [self insert##CType11:10 ndx:ndx value:CName11]; \
    [self insert##CType12:11 ndx:ndx value:CName12]; \
    [self insert##CType13:12 ndx:ndx value:CName13]; \
    [self insert##CType14:13 ndx:ndx value:CName14]; \
    [self insert##CType15:14 ndx:ndx value:CName15]; \
    [self insertDone]; \
} \
-(TableName##_##Query *)getQuery \
{ \
    return [[TableName##_##Query alloc] initWithTable:self]; \
} \
-(TableName##_##Cursor *)add \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self addRow]]; \
} \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:ndx]; \
} \
-(TableName##_##Cursor *)lastObject \
{ \
    return [[TableName##_##Cursor alloc] initWithTable:self ndx:[self count]-1]; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:self ndx:0]; \
} \
@end \
@implementation TableName##_##View \
    { \
        TableName##_##Cursor *tmpCursor; \
    } \
    -(CursorBase *)getCursor \
    { \
        return tmpCursor = [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
    } \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx \
    { \
    return [[TableName##_##Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
    } \
@end


#undef TIGHTDB_TABLE_DEF_1
#define TIGHTDB_TABLE_DEF_1(TableName, CType1, CName1) \
@interface TableName##_##Cursor : CursorBase \
    @property tdbOCType##CType1 CName1; \
    -(tdbOCType##CType1)CName1; \
    -(void)set##CName1:(tdbOCType##CType1)value; \
@end \
@class TableName##_##Query; \
@class TableName##_##View; \
@interface TableName##QueryAccessorInt : OCXQueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value; \
-(TableName##_##Query *)notEqual:(size_t)value; \
-(TableName##_##Query *)greater:(int64_t)value; \
-(TableName##_##Query *)less:(int64_t)value; \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to; \
@end \
@interface TableName##QueryAccessorBool : OCXQueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value; \
@end \
@interface TableName##QueryAccessorString : OCXQueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
@end \
@interface TableName##_##Query : Query \
@property(nonatomic, strong) TableName##QueryAccessor##CType1 *CName1; \
-(TableName##_##Query *)group; \
-(TableName##_##Query *)or; \
-(TableName##_##Query *)endgroup; \
-(TableName##_##Query *)subtable:(size_t)column; \
-(TableName##_##Query *)parent; \
-(TableName##_##View *)findAll; \
@end \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
-(void)add##CName1:(tdbOCType##CType1)CName1; \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1; \
-(TableName##_##Query *)getQuery; \
-(TableName##_##Cursor *)add; \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_##Cursor *)lastObject; \
@end \
@interface TableName##_##View : TableView \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
@end

#undef TIGHTDB_TABLE_1
#define TIGHTDB_TABLE_1(TableName    , CType1, CName1    ) \
TIGHTDB_TABLE_DEF_1(TableName    ,CType1, CName1    ) \
TIGHTDB_TABLE_IMPL_1(TableName    ,CType1, CName1    )


#undef TIGHTDB_TABLE_DEF_2
#define TIGHTDB_TABLE_DEF_2(TableName, CType1, CName1, CType2, CName2) \
@interface TableName##_##Cursor : CursorBase \
    @property tdbOCType##CType1 CName1; \
    @property tdbOCType##CType2 CName2; \
    -(tdbOCType##CType1)CName1; \
    -(void)set##CName1:(tdbOCType##CType1)value; \
    -(tdbOCType##CType2)CName2; \
    -(void)set##CName2:(tdbOCType##CType2)value; \
@end \
@class TableName##_##Query; \
@class TableName##_##View; \
@interface TableName##QueryAccessorInt : OCXQueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value; \
-(TableName##_##Query *)notEqual:(size_t)value; \
-(TableName##_##Query *)greater:(int64_t)value; \
-(TableName##_##Query *)less:(int64_t)value; \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to; \
@end \
@interface TableName##QueryAccessorBool : OCXQueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value; \
@end \
@interface TableName##QueryAccessorString : OCXQueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
@end \
@interface TableName##_##Query : Query \
@property(nonatomic, strong) TableName##QueryAccessor##CType1 *CName1; \
@property(nonatomic, strong) TableName##QueryAccessor##CType2 *CName2; \
-(TableName##_##Query *)group; \
-(TableName##_##Query *)or; \
-(TableName##_##Query *)endgroup; \
-(TableName##_##Query *)subtable:(size_t)column; \
-(TableName##_##Query *)parent; \
-(TableName##_##View *)findAll; \
@end \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy##CType2 *CName2; \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2; \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2; \
-(TableName##_##Query *)getQuery; \
-(TableName##_##Cursor *)add; \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_##Cursor *)lastObject; \
@end \
@interface TableName##_##View : TableView \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
@end

#undef TIGHTDB_TABLE_2
#define TIGHTDB_TABLE_2(TableName    , CType1, CName1    , CType2, CName2    ) \
TIGHTDB_TABLE_DEF_2(TableName    ,CType1, CName1    ,CType2, CName2    ) \
TIGHTDB_TABLE_IMPL_2(TableName    ,CType1, CName1    ,CType2, CName2    )


#undef TIGHTDB_TABLE_DEF_3
#define TIGHTDB_TABLE_DEF_3(TableName, CType1, CName1, CType2, CName2, CType3, CName3) \
@interface TableName##_##Cursor : CursorBase \
    @property tdbOCType##CType1 CName1; \
    @property tdbOCType##CType2 CName2; \
    @property tdbOCType##CType3 CName3; \
    -(tdbOCType##CType1)CName1; \
    -(void)set##CName1:(tdbOCType##CType1)value; \
    -(tdbOCType##CType2)CName2; \
    -(void)set##CName2:(tdbOCType##CType2)value; \
    -(tdbOCType##CType3)CName3; \
    -(void)set##CName3:(tdbOCType##CType3)value; \
@end \
@class TableName##_##Query; \
@class TableName##_##View; \
@interface TableName##QueryAccessorInt : OCXQueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value; \
-(TableName##_##Query *)notEqual:(size_t)value; \
-(TableName##_##Query *)greater:(int64_t)value; \
-(TableName##_##Query *)less:(int64_t)value; \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to; \
@end \
@interface TableName##QueryAccessorBool : OCXQueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value; \
@end \
@interface TableName##QueryAccessorString : OCXQueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
@end \
@interface TableName##_##Query : Query \
@property(nonatomic, strong) TableName##QueryAccessor##CType1 *CName1; \
@property(nonatomic, strong) TableName##QueryAccessor##CType2 *CName2; \
@property(nonatomic, strong) TableName##QueryAccessor##CType3 *CName3; \
-(TableName##_##Query *)group; \
-(TableName##_##Query *)or; \
-(TableName##_##Query *)endgroup; \
-(TableName##_##Query *)subtable:(size_t)column; \
-(TableName##_##Query *)parent; \
-(TableName##_##View *)findAll; \
@end \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy##CType3 *CName3; \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3; \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3; \
-(TableName##_##Query *)getQuery; \
-(TableName##_##Cursor *)add; \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_##Cursor *)lastObject; \
@end \
@interface TableName##_##View : TableView \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
@end

#undef TIGHTDB_TABLE_3
#define TIGHTDB_TABLE_3(TableName    , CType1, CName1    , CType2, CName2    , CType3, CName3    ) \
TIGHTDB_TABLE_DEF_3(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ) \
TIGHTDB_TABLE_IMPL_3(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    )


#undef TIGHTDB_TABLE_DEF_4
#define TIGHTDB_TABLE_DEF_4(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4) \
@interface TableName##_##Cursor : CursorBase \
    @property tdbOCType##CType1 CName1; \
    @property tdbOCType##CType2 CName2; \
    @property tdbOCType##CType3 CName3; \
    @property tdbOCType##CType4 CName4; \
    -(tdbOCType##CType1)CName1; \
    -(void)set##CName1:(tdbOCType##CType1)value; \
    -(tdbOCType##CType2)CName2; \
    -(void)set##CName2:(tdbOCType##CType2)value; \
    -(tdbOCType##CType3)CName3; \
    -(void)set##CName3:(tdbOCType##CType3)value; \
    -(tdbOCType##CType4)CName4; \
    -(void)set##CName4:(tdbOCType##CType4)value; \
@end \
@class TableName##_##Query; \
@class TableName##_##View; \
@interface TableName##QueryAccessorInt : OCXQueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value; \
-(TableName##_##Query *)notEqual:(size_t)value; \
-(TableName##_##Query *)greater:(int64_t)value; \
-(TableName##_##Query *)less:(int64_t)value; \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to; \
@end \
@interface TableName##QueryAccessorBool : OCXQueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value; \
@end \
@interface TableName##QueryAccessorString : OCXQueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
@end \
@interface TableName##_##Query : Query \
@property(nonatomic, strong) TableName##QueryAccessor##CType1 *CName1; \
@property(nonatomic, strong) TableName##QueryAccessor##CType2 *CName2; \
@property(nonatomic, strong) TableName##QueryAccessor##CType3 *CName3; \
@property(nonatomic, strong) TableName##QueryAccessor##CType4 *CName4; \
-(TableName##_##Query *)group; \
-(TableName##_##Query *)or; \
-(TableName##_##Query *)endgroup; \
-(TableName##_##Query *)subtable:(size_t)column; \
-(TableName##_##Query *)parent; \
-(TableName##_##View *)findAll; \
@end \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy##CType4 *CName4; \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4; \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4; \
-(TableName##_##Query *)getQuery; \
-(TableName##_##Cursor *)add; \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_##Cursor *)lastObject; \
@end \
@interface TableName##_##View : TableView \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
@end

#undef TIGHTDB_TABLE_4
#define TIGHTDB_TABLE_4(TableName    , CType1, CName1    , CType2, CName2    , CType3, CName3    , CType4, CName4    ) \
TIGHTDB_TABLE_DEF_4(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ) \
TIGHTDB_TABLE_IMPL_4(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    )


#undef TIGHTDB_TABLE_DEF_5
#define TIGHTDB_TABLE_DEF_5(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5) \
@interface TableName##_##Cursor : CursorBase \
    @property tdbOCType##CType1 CName1; \
    @property tdbOCType##CType2 CName2; \
    @property tdbOCType##CType3 CName3; \
    @property tdbOCType##CType4 CName4; \
    @property tdbOCType##CType5 CName5; \
    -(tdbOCType##CType1)CName1; \
    -(void)set##CName1:(tdbOCType##CType1)value; \
    -(tdbOCType##CType2)CName2; \
    -(void)set##CName2:(tdbOCType##CType2)value; \
    -(tdbOCType##CType3)CName3; \
    -(void)set##CName3:(tdbOCType##CType3)value; \
    -(tdbOCType##CType4)CName4; \
    -(void)set##CName4:(tdbOCType##CType4)value; \
    -(tdbOCType##CType5)CName5; \
    -(void)set##CName5:(tdbOCType##CType5)value; \
@end \
@class TableName##_##Query; \
@class TableName##_##View; \
@interface TableName##QueryAccessorInt : OCXQueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value; \
-(TableName##_##Query *)notEqual:(size_t)value; \
-(TableName##_##Query *)greater:(int64_t)value; \
-(TableName##_##Query *)less:(int64_t)value; \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to; \
@end \
@interface TableName##QueryAccessorBool : OCXQueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value; \
@end \
@interface TableName##QueryAccessorString : OCXQueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
@end \
@interface TableName##_##Query : Query \
@property(nonatomic, strong) TableName##QueryAccessor##CType1 *CName1; \
@property(nonatomic, strong) TableName##QueryAccessor##CType2 *CName2; \
@property(nonatomic, strong) TableName##QueryAccessor##CType3 *CName3; \
@property(nonatomic, strong) TableName##QueryAccessor##CType4 *CName4; \
@property(nonatomic, strong) TableName##QueryAccessor##CType5 *CName5; \
-(TableName##_##Query *)group; \
-(TableName##_##Query *)or; \
-(TableName##_##Query *)endgroup; \
-(TableName##_##Query *)subtable:(size_t)column; \
-(TableName##_##Query *)parent; \
-(TableName##_##View *)findAll; \
@end \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy##CType4 *CName4; \
@property(nonatomic, strong) OCColumnProxy##CType5 *CName5; \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5; \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5; \
-(TableName##_##Query *)getQuery; \
-(TableName##_##Cursor *)add; \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_##Cursor *)lastObject; \
@end \
@interface TableName##_##View : TableView \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
@end

#undef TIGHTDB_TABLE_5
#define TIGHTDB_TABLE_5(TableName    , CType1, CName1    , CType2, CName2    , CType3, CName3    , CType4, CName4    , CType5, CName5    ) \
TIGHTDB_TABLE_DEF_5(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ) \
TIGHTDB_TABLE_IMPL_5(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    )


#undef TIGHTDB_TABLE_DEF_6
#define TIGHTDB_TABLE_DEF_6(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6) \
@interface TableName##_##Cursor : CursorBase \
    @property tdbOCType##CType1 CName1; \
    @property tdbOCType##CType2 CName2; \
    @property tdbOCType##CType3 CName3; \
    @property tdbOCType##CType4 CName4; \
    @property tdbOCType##CType5 CName5; \
    @property tdbOCType##CType6 CName6; \
    -(tdbOCType##CType1)CName1; \
    -(void)set##CName1:(tdbOCType##CType1)value; \
    -(tdbOCType##CType2)CName2; \
    -(void)set##CName2:(tdbOCType##CType2)value; \
    -(tdbOCType##CType3)CName3; \
    -(void)set##CName3:(tdbOCType##CType3)value; \
    -(tdbOCType##CType4)CName4; \
    -(void)set##CName4:(tdbOCType##CType4)value; \
    -(tdbOCType##CType5)CName5; \
    -(void)set##CName5:(tdbOCType##CType5)value; \
    -(tdbOCType##CType6)CName6; \
    -(void)set##CName6:(tdbOCType##CType6)value; \
@end \
@class TableName##_##Query; \
@class TableName##_##View; \
@interface TableName##QueryAccessorInt : OCXQueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value; \
-(TableName##_##Query *)notEqual:(size_t)value; \
-(TableName##_##Query *)greater:(int64_t)value; \
-(TableName##_##Query *)less:(int64_t)value; \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to; \
@end \
@interface TableName##QueryAccessorBool : OCXQueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value; \
@end \
@interface TableName##QueryAccessorString : OCXQueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
@end \
@interface TableName##_##Query : Query \
@property(nonatomic, strong) TableName##QueryAccessor##CType1 *CName1; \
@property(nonatomic, strong) TableName##QueryAccessor##CType2 *CName2; \
@property(nonatomic, strong) TableName##QueryAccessor##CType3 *CName3; \
@property(nonatomic, strong) TableName##QueryAccessor##CType4 *CName4; \
@property(nonatomic, strong) TableName##QueryAccessor##CType5 *CName5; \
@property(nonatomic, strong) TableName##QueryAccessor##CType6 *CName6; \
-(TableName##_##Query *)group; \
-(TableName##_##Query *)or; \
-(TableName##_##Query *)endgroup; \
-(TableName##_##Query *)subtable:(size_t)column; \
-(TableName##_##Query *)parent; \
-(TableName##_##View *)findAll; \
@end \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy##CType4 *CName4; \
@property(nonatomic, strong) OCColumnProxy##CType5 *CName5; \
@property(nonatomic, strong) OCColumnProxy##CType6 *CName6; \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6; \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6; \
-(TableName##_##Query *)getQuery; \
-(TableName##_##Cursor *)add; \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_##Cursor *)lastObject; \
@end \
@interface TableName##_##View : TableView \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
@end

#undef TIGHTDB_TABLE_6
#define TIGHTDB_TABLE_6(TableName    , CType1, CName1    , CType2, CName2    , CType3, CName3    , CType4, CName4    , CType5, CName5    , CType6, CName6    ) \
TIGHTDB_TABLE_DEF_6(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ,CType6, CName6    ) \
TIGHTDB_TABLE_IMPL_6(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ,CType6, CName6    )


#undef TIGHTDB_TABLE_DEF_7
#define TIGHTDB_TABLE_DEF_7(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7) \
@interface TableName##_##Cursor : CursorBase \
    @property tdbOCType##CType1 CName1; \
    @property tdbOCType##CType2 CName2; \
    @property tdbOCType##CType3 CName3; \
    @property tdbOCType##CType4 CName4; \
    @property tdbOCType##CType5 CName5; \
    @property tdbOCType##CType6 CName6; \
    @property tdbOCType##CType7 CName7; \
    -(tdbOCType##CType1)CName1; \
    -(void)set##CName1:(tdbOCType##CType1)value; \
    -(tdbOCType##CType2)CName2; \
    -(void)set##CName2:(tdbOCType##CType2)value; \
    -(tdbOCType##CType3)CName3; \
    -(void)set##CName3:(tdbOCType##CType3)value; \
    -(tdbOCType##CType4)CName4; \
    -(void)set##CName4:(tdbOCType##CType4)value; \
    -(tdbOCType##CType5)CName5; \
    -(void)set##CName5:(tdbOCType##CType5)value; \
    -(tdbOCType##CType6)CName6; \
    -(void)set##CName6:(tdbOCType##CType6)value; \
    -(tdbOCType##CType7)CName7; \
    -(void)set##CName7:(tdbOCType##CType7)value; \
@end \
@class TableName##_##Query; \
@class TableName##_##View; \
@interface TableName##QueryAccessorInt : OCXQueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value; \
-(TableName##_##Query *)notEqual:(size_t)value; \
-(TableName##_##Query *)greater:(int64_t)value; \
-(TableName##_##Query *)less:(int64_t)value; \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to; \
@end \
@interface TableName##QueryAccessorBool : OCXQueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value; \
@end \
@interface TableName##QueryAccessorString : OCXQueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
@end \
@interface TableName##_##Query : Query \
@property(nonatomic, strong) TableName##QueryAccessor##CType1 *CName1; \
@property(nonatomic, strong) TableName##QueryAccessor##CType2 *CName2; \
@property(nonatomic, strong) TableName##QueryAccessor##CType3 *CName3; \
@property(nonatomic, strong) TableName##QueryAccessor##CType4 *CName4; \
@property(nonatomic, strong) TableName##QueryAccessor##CType5 *CName5; \
@property(nonatomic, strong) TableName##QueryAccessor##CType6 *CName6; \
@property(nonatomic, strong) TableName##QueryAccessor##CType7 *CName7; \
-(TableName##_##Query *)group; \
-(TableName##_##Query *)or; \
-(TableName##_##Query *)endgroup; \
-(TableName##_##Query *)subtable:(size_t)column; \
-(TableName##_##Query *)parent; \
-(TableName##_##View *)findAll; \
@end \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy##CType4 *CName4; \
@property(nonatomic, strong) OCColumnProxy##CType5 *CName5; \
@property(nonatomic, strong) OCColumnProxy##CType6 *CName6; \
@property(nonatomic, strong) OCColumnProxy##CType7 *CName7; \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7; \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7; \
-(TableName##_##Query *)getQuery; \
-(TableName##_##Cursor *)add; \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_##Cursor *)lastObject; \
@end \
@interface TableName##_##View : TableView \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
@end

#undef TIGHTDB_TABLE_7
#define TIGHTDB_TABLE_7(TableName    , CType1, CName1    , CType2, CName2    , CType3, CName3    , CType4, CName4    , CType5, CName5    , CType6, CName6    , CType7, CName7    ) \
TIGHTDB_TABLE_DEF_7(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ,CType6, CName6    ,CType7, CName7    ) \
TIGHTDB_TABLE_IMPL_7(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ,CType6, CName6    ,CType7, CName7    )


#undef TIGHTDB_TABLE_DEF_8
#define TIGHTDB_TABLE_DEF_8(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8) \
@interface TableName##_##Cursor : CursorBase \
    @property tdbOCType##CType1 CName1; \
    @property tdbOCType##CType2 CName2; \
    @property tdbOCType##CType3 CName3; \
    @property tdbOCType##CType4 CName4; \
    @property tdbOCType##CType5 CName5; \
    @property tdbOCType##CType6 CName6; \
    @property tdbOCType##CType7 CName7; \
    @property tdbOCType##CType8 CName8; \
    -(tdbOCType##CType1)CName1; \
    -(void)set##CName1:(tdbOCType##CType1)value; \
    -(tdbOCType##CType2)CName2; \
    -(void)set##CName2:(tdbOCType##CType2)value; \
    -(tdbOCType##CType3)CName3; \
    -(void)set##CName3:(tdbOCType##CType3)value; \
    -(tdbOCType##CType4)CName4; \
    -(void)set##CName4:(tdbOCType##CType4)value; \
    -(tdbOCType##CType5)CName5; \
    -(void)set##CName5:(tdbOCType##CType5)value; \
    -(tdbOCType##CType6)CName6; \
    -(void)set##CName6:(tdbOCType##CType6)value; \
    -(tdbOCType##CType7)CName7; \
    -(void)set##CName7:(tdbOCType##CType7)value; \
    -(tdbOCType##CType8)CName8; \
    -(void)set##CName8:(tdbOCType##CType8)value; \
@end \
@class TableName##_##Query; \
@class TableName##_##View; \
@interface TableName##QueryAccessorInt : OCXQueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value; \
-(TableName##_##Query *)notEqual:(size_t)value; \
-(TableName##_##Query *)greater:(int64_t)value; \
-(TableName##_##Query *)less:(int64_t)value; \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to; \
@end \
@interface TableName##QueryAccessorBool : OCXQueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value; \
@end \
@interface TableName##QueryAccessorString : OCXQueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
@end \
@interface TableName##_##Query : Query \
@property(nonatomic, strong) TableName##QueryAccessor##CType1 *CName1; \
@property(nonatomic, strong) TableName##QueryAccessor##CType2 *CName2; \
@property(nonatomic, strong) TableName##QueryAccessor##CType3 *CName3; \
@property(nonatomic, strong) TableName##QueryAccessor##CType4 *CName4; \
@property(nonatomic, strong) TableName##QueryAccessor##CType5 *CName5; \
@property(nonatomic, strong) TableName##QueryAccessor##CType6 *CName6; \
@property(nonatomic, strong) TableName##QueryAccessor##CType7 *CName7; \
@property(nonatomic, strong) TableName##QueryAccessor##CType8 *CName8; \
-(TableName##_##Query *)group; \
-(TableName##_##Query *)or; \
-(TableName##_##Query *)endgroup; \
-(TableName##_##Query *)subtable:(size_t)column; \
-(TableName##_##Query *)parent; \
-(TableName##_##View *)findAll; \
@end \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy##CType4 *CName4; \
@property(nonatomic, strong) OCColumnProxy##CType5 *CName5; \
@property(nonatomic, strong) OCColumnProxy##CType6 *CName6; \
@property(nonatomic, strong) OCColumnProxy##CType7 *CName7; \
@property(nonatomic, strong) OCColumnProxy##CType8 *CName8; \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8; \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8; \
-(TableName##_##Query *)getQuery; \
-(TableName##_##Cursor *)add; \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_##Cursor *)lastObject; \
@end \
@interface TableName##_##View : TableView \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
@end

#undef TIGHTDB_TABLE_8
#define TIGHTDB_TABLE_8(TableName    , CType1, CName1    , CType2, CName2    , CType3, CName3    , CType4, CName4    , CType5, CName5    , CType6, CName6    , CType7, CName7    , CType8, CName8    ) \
TIGHTDB_TABLE_DEF_8(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ,CType6, CName6    ,CType7, CName7    ,CType8, CName8    ) \
TIGHTDB_TABLE_IMPL_8(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ,CType6, CName6    ,CType7, CName7    ,CType8, CName8    )


#undef TIGHTDB_TABLE_DEF_9
#define TIGHTDB_TABLE_DEF_9(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9) \
@interface TableName##_##Cursor : CursorBase \
    @property tdbOCType##CType1 CName1; \
    @property tdbOCType##CType2 CName2; \
    @property tdbOCType##CType3 CName3; \
    @property tdbOCType##CType4 CName4; \
    @property tdbOCType##CType5 CName5; \
    @property tdbOCType##CType6 CName6; \
    @property tdbOCType##CType7 CName7; \
    @property tdbOCType##CType8 CName8; \
    @property tdbOCType##CType9 CName9; \
    -(tdbOCType##CType1)CName1; \
    -(void)set##CName1:(tdbOCType##CType1)value; \
    -(tdbOCType##CType2)CName2; \
    -(void)set##CName2:(tdbOCType##CType2)value; \
    -(tdbOCType##CType3)CName3; \
    -(void)set##CName3:(tdbOCType##CType3)value; \
    -(tdbOCType##CType4)CName4; \
    -(void)set##CName4:(tdbOCType##CType4)value; \
    -(tdbOCType##CType5)CName5; \
    -(void)set##CName5:(tdbOCType##CType5)value; \
    -(tdbOCType##CType6)CName6; \
    -(void)set##CName6:(tdbOCType##CType6)value; \
    -(tdbOCType##CType7)CName7; \
    -(void)set##CName7:(tdbOCType##CType7)value; \
    -(tdbOCType##CType8)CName8; \
    -(void)set##CName8:(tdbOCType##CType8)value; \
    -(tdbOCType##CType9)CName9; \
    -(void)set##CName9:(tdbOCType##CType9)value; \
@end \
@class TableName##_##Query; \
@class TableName##_##View; \
@interface TableName##QueryAccessorInt : OCXQueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value; \
-(TableName##_##Query *)notEqual:(size_t)value; \
-(TableName##_##Query *)greater:(int64_t)value; \
-(TableName##_##Query *)less:(int64_t)value; \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to; \
@end \
@interface TableName##QueryAccessorBool : OCXQueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value; \
@end \
@interface TableName##QueryAccessorString : OCXQueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
@end \
@interface TableName##_##Query : Query \
@property(nonatomic, strong) TableName##QueryAccessor##CType1 *CName1; \
@property(nonatomic, strong) TableName##QueryAccessor##CType2 *CName2; \
@property(nonatomic, strong) TableName##QueryAccessor##CType3 *CName3; \
@property(nonatomic, strong) TableName##QueryAccessor##CType4 *CName4; \
@property(nonatomic, strong) TableName##QueryAccessor##CType5 *CName5; \
@property(nonatomic, strong) TableName##QueryAccessor##CType6 *CName6; \
@property(nonatomic, strong) TableName##QueryAccessor##CType7 *CName7; \
@property(nonatomic, strong) TableName##QueryAccessor##CType8 *CName8; \
@property(nonatomic, strong) TableName##QueryAccessor##CType9 *CName9; \
-(TableName##_##Query *)group; \
-(TableName##_##Query *)or; \
-(TableName##_##Query *)endgroup; \
-(TableName##_##Query *)subtable:(size_t)column; \
-(TableName##_##Query *)parent; \
-(TableName##_##View *)findAll; \
@end \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy##CType4 *CName4; \
@property(nonatomic, strong) OCColumnProxy##CType5 *CName5; \
@property(nonatomic, strong) OCColumnProxy##CType6 *CName6; \
@property(nonatomic, strong) OCColumnProxy##CType7 *CName7; \
@property(nonatomic, strong) OCColumnProxy##CType8 *CName8; \
@property(nonatomic, strong) OCColumnProxy##CType9 *CName9; \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9; \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9; \
-(TableName##_##Query *)getQuery; \
-(TableName##_##Cursor *)add; \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_##Cursor *)lastObject; \
@end \
@interface TableName##_##View : TableView \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
@end

#undef TIGHTDB_TABLE_9
#define TIGHTDB_TABLE_9(TableName    , CType1, CName1    , CType2, CName2    , CType3, CName3    , CType4, CName4    , CType5, CName5    , CType6, CName6    , CType7, CName7    , CType8, CName8    , CType9, CName9    ) \
TIGHTDB_TABLE_DEF_9(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ,CType6, CName6    ,CType7, CName7    ,CType8, CName8    ,CType9, CName9    ) \
TIGHTDB_TABLE_IMPL_9(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ,CType6, CName6    ,CType7, CName7    ,CType8, CName8    ,CType9, CName9    )


#undef TIGHTDB_TABLE_DEF_10
#define TIGHTDB_TABLE_DEF_10(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10) \
@interface TableName##_##Cursor : CursorBase \
    @property tdbOCType##CType1 CName1; \
    @property tdbOCType##CType2 CName2; \
    @property tdbOCType##CType3 CName3; \
    @property tdbOCType##CType4 CName4; \
    @property tdbOCType##CType5 CName5; \
    @property tdbOCType##CType6 CName6; \
    @property tdbOCType##CType7 CName7; \
    @property tdbOCType##CType8 CName8; \
    @property tdbOCType##CType9 CName9; \
    @property tdbOCType##CType10 CName10; \
    -(tdbOCType##CType1)CName1; \
    -(void)set##CName1:(tdbOCType##CType1)value; \
    -(tdbOCType##CType2)CName2; \
    -(void)set##CName2:(tdbOCType##CType2)value; \
    -(tdbOCType##CType3)CName3; \
    -(void)set##CName3:(tdbOCType##CType3)value; \
    -(tdbOCType##CType4)CName4; \
    -(void)set##CName4:(tdbOCType##CType4)value; \
    -(tdbOCType##CType5)CName5; \
    -(void)set##CName5:(tdbOCType##CType5)value; \
    -(tdbOCType##CType6)CName6; \
    -(void)set##CName6:(tdbOCType##CType6)value; \
    -(tdbOCType##CType7)CName7; \
    -(void)set##CName7:(tdbOCType##CType7)value; \
    -(tdbOCType##CType8)CName8; \
    -(void)set##CName8:(tdbOCType##CType8)value; \
    -(tdbOCType##CType9)CName9; \
    -(void)set##CName9:(tdbOCType##CType9)value; \
    -(tdbOCType##CType10)CName10; \
    -(void)set##CName10:(tdbOCType##CType10)value; \
@end \
@class TableName##_##Query; \
@class TableName##_##View; \
@interface TableName##QueryAccessorInt : OCXQueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value; \
-(TableName##_##Query *)notEqual:(size_t)value; \
-(TableName##_##Query *)greater:(int64_t)value; \
-(TableName##_##Query *)less:(int64_t)value; \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to; \
@end \
@interface TableName##QueryAccessorBool : OCXQueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value; \
@end \
@interface TableName##QueryAccessorString : OCXQueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
@end \
@interface TableName##_##Query : Query \
@property(nonatomic, strong) TableName##QueryAccessor##CType1 *CName1; \
@property(nonatomic, strong) TableName##QueryAccessor##CType2 *CName2; \
@property(nonatomic, strong) TableName##QueryAccessor##CType3 *CName3; \
@property(nonatomic, strong) TableName##QueryAccessor##CType4 *CName4; \
@property(nonatomic, strong) TableName##QueryAccessor##CType5 *CName5; \
@property(nonatomic, strong) TableName##QueryAccessor##CType6 *CName6; \
@property(nonatomic, strong) TableName##QueryAccessor##CType7 *CName7; \
@property(nonatomic, strong) TableName##QueryAccessor##CType8 *CName8; \
@property(nonatomic, strong) TableName##QueryAccessor##CType9 *CName9; \
@property(nonatomic, strong) TableName##QueryAccessor##CType10 *CName10; \
-(TableName##_##Query *)group; \
-(TableName##_##Query *)or; \
-(TableName##_##Query *)endgroup; \
-(TableName##_##Query *)subtable:(size_t)column; \
-(TableName##_##Query *)parent; \
-(TableName##_##View *)findAll; \
@end \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy##CType4 *CName4; \
@property(nonatomic, strong) OCColumnProxy##CType5 *CName5; \
@property(nonatomic, strong) OCColumnProxy##CType6 *CName6; \
@property(nonatomic, strong) OCColumnProxy##CType7 *CName7; \
@property(nonatomic, strong) OCColumnProxy##CType8 *CName8; \
@property(nonatomic, strong) OCColumnProxy##CType9 *CName9; \
@property(nonatomic, strong) OCColumnProxy##CType10 *CName10; \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9 CName10:(tdbOCType##CType10)CName10; \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9 CName10:(tdbOCType##CType10)CName10; \
-(TableName##_##Query *)getQuery; \
-(TableName##_##Cursor *)add; \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_##Cursor *)lastObject; \
@end \
@interface TableName##_##View : TableView \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
@end

#undef TIGHTDB_TABLE_10
#define TIGHTDB_TABLE_10(TableName    , CType1, CName1    , CType2, CName2    , CType3, CName3    , CType4, CName4    , CType5, CName5    , CType6, CName6    , CType7, CName7    , CType8, CName8    , CType9, CName9    , CType10, CName10    ) \
TIGHTDB_TABLE_DEF_10(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ,CType6, CName6    ,CType7, CName7    ,CType8, CName8    ,CType9, CName9    ,CType10, CName10    ) \
TIGHTDB_TABLE_IMPL_10(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ,CType6, CName6    ,CType7, CName7    ,CType8, CName8    ,CType9, CName9    ,CType10, CName10    )


#undef TIGHTDB_TABLE_DEF_11
#define TIGHTDB_TABLE_DEF_11(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10, CType11, CName11) \
@interface TableName##_##Cursor : CursorBase \
    @property tdbOCType##CType1 CName1; \
    @property tdbOCType##CType2 CName2; \
    @property tdbOCType##CType3 CName3; \
    @property tdbOCType##CType4 CName4; \
    @property tdbOCType##CType5 CName5; \
    @property tdbOCType##CType6 CName6; \
    @property tdbOCType##CType7 CName7; \
    @property tdbOCType##CType8 CName8; \
    @property tdbOCType##CType9 CName9; \
    @property tdbOCType##CType10 CName10; \
    @property tdbOCType##CType11 CName11; \
    -(tdbOCType##CType1)CName1; \
    -(void)set##CName1:(tdbOCType##CType1)value; \
    -(tdbOCType##CType2)CName2; \
    -(void)set##CName2:(tdbOCType##CType2)value; \
    -(tdbOCType##CType3)CName3; \
    -(void)set##CName3:(tdbOCType##CType3)value; \
    -(tdbOCType##CType4)CName4; \
    -(void)set##CName4:(tdbOCType##CType4)value; \
    -(tdbOCType##CType5)CName5; \
    -(void)set##CName5:(tdbOCType##CType5)value; \
    -(tdbOCType##CType6)CName6; \
    -(void)set##CName6:(tdbOCType##CType6)value; \
    -(tdbOCType##CType7)CName7; \
    -(void)set##CName7:(tdbOCType##CType7)value; \
    -(tdbOCType##CType8)CName8; \
    -(void)set##CName8:(tdbOCType##CType8)value; \
    -(tdbOCType##CType9)CName9; \
    -(void)set##CName9:(tdbOCType##CType9)value; \
    -(tdbOCType##CType10)CName10; \
    -(void)set##CName10:(tdbOCType##CType10)value; \
    -(tdbOCType##CType11)CName11; \
    -(void)set##CName11:(tdbOCType##CType11)value; \
@end \
@class TableName##_##Query; \
@class TableName##_##View; \
@interface TableName##QueryAccessorInt : OCXQueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value; \
-(TableName##_##Query *)notEqual:(size_t)value; \
-(TableName##_##Query *)greater:(int64_t)value; \
-(TableName##_##Query *)less:(int64_t)value; \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to; \
@end \
@interface TableName##QueryAccessorBool : OCXQueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value; \
@end \
@interface TableName##QueryAccessorString : OCXQueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
@end \
@interface TableName##_##Query : Query \
@property(nonatomic, strong) TableName##QueryAccessor##CType1 *CName1; \
@property(nonatomic, strong) TableName##QueryAccessor##CType2 *CName2; \
@property(nonatomic, strong) TableName##QueryAccessor##CType3 *CName3; \
@property(nonatomic, strong) TableName##QueryAccessor##CType4 *CName4; \
@property(nonatomic, strong) TableName##QueryAccessor##CType5 *CName5; \
@property(nonatomic, strong) TableName##QueryAccessor##CType6 *CName6; \
@property(nonatomic, strong) TableName##QueryAccessor##CType7 *CName7; \
@property(nonatomic, strong) TableName##QueryAccessor##CType8 *CName8; \
@property(nonatomic, strong) TableName##QueryAccessor##CType9 *CName9; \
@property(nonatomic, strong) TableName##QueryAccessor##CType10 *CName10; \
@property(nonatomic, strong) TableName##QueryAccessor##CType11 *CName11; \
-(TableName##_##Query *)group; \
-(TableName##_##Query *)or; \
-(TableName##_##Query *)endgroup; \
-(TableName##_##Query *)subtable:(size_t)column; \
-(TableName##_##Query *)parent; \
-(TableName##_##View *)findAll; \
@end \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy##CType4 *CName4; \
@property(nonatomic, strong) OCColumnProxy##CType5 *CName5; \
@property(nonatomic, strong) OCColumnProxy##CType6 *CName6; \
@property(nonatomic, strong) OCColumnProxy##CType7 *CName7; \
@property(nonatomic, strong) OCColumnProxy##CType8 *CName8; \
@property(nonatomic, strong) OCColumnProxy##CType9 *CName9; \
@property(nonatomic, strong) OCColumnProxy##CType10 *CName10; \
@property(nonatomic, strong) OCColumnProxy##CType11 *CName11; \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9 CName10:(tdbOCType##CType10)CName10 CName11:(tdbOCType##CType11)CName11; \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9 CName10:(tdbOCType##CType10)CName10 CName11:(tdbOCType##CType11)CName11; \
-(TableName##_##Query *)getQuery; \
-(TableName##_##Cursor *)add; \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_##Cursor *)lastObject; \
@end \
@interface TableName##_##View : TableView \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
@end

#undef TIGHTDB_TABLE_11
#define TIGHTDB_TABLE_11(TableName    , CType1, CName1    , CType2, CName2    , CType3, CName3    , CType4, CName4    , CType5, CName5    , CType6, CName6    , CType7, CName7    , CType8, CName8    , CType9, CName9    , CType10, CName10    , CType11, CName11    ) \
TIGHTDB_TABLE_DEF_11(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ,CType6, CName6    ,CType7, CName7    ,CType8, CName8    ,CType9, CName9    ,CType10, CName10    ,CType11, CName11    ) \
TIGHTDB_TABLE_IMPL_11(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ,CType6, CName6    ,CType7, CName7    ,CType8, CName8    ,CType9, CName9    ,CType10, CName10    ,CType11, CName11    )


#undef TIGHTDB_TABLE_DEF_12
#define TIGHTDB_TABLE_DEF_12(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10, CType11, CName11, CType12, CName12) \
@interface TableName##_##Cursor : CursorBase \
    @property tdbOCType##CType1 CName1; \
    @property tdbOCType##CType2 CName2; \
    @property tdbOCType##CType3 CName3; \
    @property tdbOCType##CType4 CName4; \
    @property tdbOCType##CType5 CName5; \
    @property tdbOCType##CType6 CName6; \
    @property tdbOCType##CType7 CName7; \
    @property tdbOCType##CType8 CName8; \
    @property tdbOCType##CType9 CName9; \
    @property tdbOCType##CType10 CName10; \
    @property tdbOCType##CType11 CName11; \
    @property tdbOCType##CType12 CName12; \
    -(tdbOCType##CType1)CName1; \
    -(void)set##CName1:(tdbOCType##CType1)value; \
    -(tdbOCType##CType2)CName2; \
    -(void)set##CName2:(tdbOCType##CType2)value; \
    -(tdbOCType##CType3)CName3; \
    -(void)set##CName3:(tdbOCType##CType3)value; \
    -(tdbOCType##CType4)CName4; \
    -(void)set##CName4:(tdbOCType##CType4)value; \
    -(tdbOCType##CType5)CName5; \
    -(void)set##CName5:(tdbOCType##CType5)value; \
    -(tdbOCType##CType6)CName6; \
    -(void)set##CName6:(tdbOCType##CType6)value; \
    -(tdbOCType##CType7)CName7; \
    -(void)set##CName7:(tdbOCType##CType7)value; \
    -(tdbOCType##CType8)CName8; \
    -(void)set##CName8:(tdbOCType##CType8)value; \
    -(tdbOCType##CType9)CName9; \
    -(void)set##CName9:(tdbOCType##CType9)value; \
    -(tdbOCType##CType10)CName10; \
    -(void)set##CName10:(tdbOCType##CType10)value; \
    -(tdbOCType##CType11)CName11; \
    -(void)set##CName11:(tdbOCType##CType11)value; \
    -(tdbOCType##CType12)CName12; \
    -(void)set##CName12:(tdbOCType##CType12)value; \
@end \
@class TableName##_##Query; \
@class TableName##_##View; \
@interface TableName##QueryAccessorInt : OCXQueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value; \
-(TableName##_##Query *)notEqual:(size_t)value; \
-(TableName##_##Query *)greater:(int64_t)value; \
-(TableName##_##Query *)less:(int64_t)value; \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to; \
@end \
@interface TableName##QueryAccessorBool : OCXQueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value; \
@end \
@interface TableName##QueryAccessorString : OCXQueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
@end \
@interface TableName##_##Query : Query \
@property(nonatomic, strong) TableName##QueryAccessor##CType1 *CName1; \
@property(nonatomic, strong) TableName##QueryAccessor##CType2 *CName2; \
@property(nonatomic, strong) TableName##QueryAccessor##CType3 *CName3; \
@property(nonatomic, strong) TableName##QueryAccessor##CType4 *CName4; \
@property(nonatomic, strong) TableName##QueryAccessor##CType5 *CName5; \
@property(nonatomic, strong) TableName##QueryAccessor##CType6 *CName6; \
@property(nonatomic, strong) TableName##QueryAccessor##CType7 *CName7; \
@property(nonatomic, strong) TableName##QueryAccessor##CType8 *CName8; \
@property(nonatomic, strong) TableName##QueryAccessor##CType9 *CName9; \
@property(nonatomic, strong) TableName##QueryAccessor##CType10 *CName10; \
@property(nonatomic, strong) TableName##QueryAccessor##CType11 *CName11; \
@property(nonatomic, strong) TableName##QueryAccessor##CType12 *CName12; \
-(TableName##_##Query *)group; \
-(TableName##_##Query *)or; \
-(TableName##_##Query *)endgroup; \
-(TableName##_##Query *)subtable:(size_t)column; \
-(TableName##_##Query *)parent; \
-(TableName##_##View *)findAll; \
@end \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy##CType4 *CName4; \
@property(nonatomic, strong) OCColumnProxy##CType5 *CName5; \
@property(nonatomic, strong) OCColumnProxy##CType6 *CName6; \
@property(nonatomic, strong) OCColumnProxy##CType7 *CName7; \
@property(nonatomic, strong) OCColumnProxy##CType8 *CName8; \
@property(nonatomic, strong) OCColumnProxy##CType9 *CName9; \
@property(nonatomic, strong) OCColumnProxy##CType10 *CName10; \
@property(nonatomic, strong) OCColumnProxy##CType11 *CName11; \
@property(nonatomic, strong) OCColumnProxy##CType12 *CName12; \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9 CName10:(tdbOCType##CType10)CName10 CName11:(tdbOCType##CType11)CName11 CName12:(tdbOCType##CType12)CName12; \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9 CName10:(tdbOCType##CType10)CName10 CName11:(tdbOCType##CType11)CName11 CName12:(tdbOCType##CType12)CName12; \
-(TableName##_##Query *)getQuery; \
-(TableName##_##Cursor *)add; \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_##Cursor *)lastObject; \
@end \
@interface TableName##_##View : TableView \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
@end

#undef TIGHTDB_TABLE_12
#define TIGHTDB_TABLE_12(TableName    , CType1, CName1    , CType2, CName2    , CType3, CName3    , CType4, CName4    , CType5, CName5    , CType6, CName6    , CType7, CName7    , CType8, CName8    , CType9, CName9    , CType10, CName10    , CType11, CName11    , CType12, CName12    ) \
TIGHTDB_TABLE_DEF_12(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ,CType6, CName6    ,CType7, CName7    ,CType8, CName8    ,CType9, CName9    ,CType10, CName10    ,CType11, CName11    ,CType12, CName12    ) \
TIGHTDB_TABLE_IMPL_12(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ,CType6, CName6    ,CType7, CName7    ,CType8, CName8    ,CType9, CName9    ,CType10, CName10    ,CType11, CName11    ,CType12, CName12    )


#undef TIGHTDB_TABLE_DEF_13
#define TIGHTDB_TABLE_DEF_13(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10, CType11, CName11, CType12, CName12, CType13, CName13) \
@interface TableName##_##Cursor : CursorBase \
    @property tdbOCType##CType1 CName1; \
    @property tdbOCType##CType2 CName2; \
    @property tdbOCType##CType3 CName3; \
    @property tdbOCType##CType4 CName4; \
    @property tdbOCType##CType5 CName5; \
    @property tdbOCType##CType6 CName6; \
    @property tdbOCType##CType7 CName7; \
    @property tdbOCType##CType8 CName8; \
    @property tdbOCType##CType9 CName9; \
    @property tdbOCType##CType10 CName10; \
    @property tdbOCType##CType11 CName11; \
    @property tdbOCType##CType12 CName12; \
    @property tdbOCType##CType13 CName13; \
    -(tdbOCType##CType1)CName1; \
    -(void)set##CName1:(tdbOCType##CType1)value; \
    -(tdbOCType##CType2)CName2; \
    -(void)set##CName2:(tdbOCType##CType2)value; \
    -(tdbOCType##CType3)CName3; \
    -(void)set##CName3:(tdbOCType##CType3)value; \
    -(tdbOCType##CType4)CName4; \
    -(void)set##CName4:(tdbOCType##CType4)value; \
    -(tdbOCType##CType5)CName5; \
    -(void)set##CName5:(tdbOCType##CType5)value; \
    -(tdbOCType##CType6)CName6; \
    -(void)set##CName6:(tdbOCType##CType6)value; \
    -(tdbOCType##CType7)CName7; \
    -(void)set##CName7:(tdbOCType##CType7)value; \
    -(tdbOCType##CType8)CName8; \
    -(void)set##CName8:(tdbOCType##CType8)value; \
    -(tdbOCType##CType9)CName9; \
    -(void)set##CName9:(tdbOCType##CType9)value; \
    -(tdbOCType##CType10)CName10; \
    -(void)set##CName10:(tdbOCType##CType10)value; \
    -(tdbOCType##CType11)CName11; \
    -(void)set##CName11:(tdbOCType##CType11)value; \
    -(tdbOCType##CType12)CName12; \
    -(void)set##CName12:(tdbOCType##CType12)value; \
    -(tdbOCType##CType13)CName13; \
    -(void)set##CName13:(tdbOCType##CType13)value; \
@end \
@class TableName##_##Query; \
@class TableName##_##View; \
@interface TableName##QueryAccessorInt : OCXQueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value; \
-(TableName##_##Query *)notEqual:(size_t)value; \
-(TableName##_##Query *)greater:(int64_t)value; \
-(TableName##_##Query *)less:(int64_t)value; \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to; \
@end \
@interface TableName##QueryAccessorBool : OCXQueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value; \
@end \
@interface TableName##QueryAccessorString : OCXQueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
@end \
@interface TableName##_##Query : Query \
@property(nonatomic, strong) TableName##QueryAccessor##CType1 *CName1; \
@property(nonatomic, strong) TableName##QueryAccessor##CType2 *CName2; \
@property(nonatomic, strong) TableName##QueryAccessor##CType3 *CName3; \
@property(nonatomic, strong) TableName##QueryAccessor##CType4 *CName4; \
@property(nonatomic, strong) TableName##QueryAccessor##CType5 *CName5; \
@property(nonatomic, strong) TableName##QueryAccessor##CType6 *CName6; \
@property(nonatomic, strong) TableName##QueryAccessor##CType7 *CName7; \
@property(nonatomic, strong) TableName##QueryAccessor##CType8 *CName8; \
@property(nonatomic, strong) TableName##QueryAccessor##CType9 *CName9; \
@property(nonatomic, strong) TableName##QueryAccessor##CType10 *CName10; \
@property(nonatomic, strong) TableName##QueryAccessor##CType11 *CName11; \
@property(nonatomic, strong) TableName##QueryAccessor##CType12 *CName12; \
@property(nonatomic, strong) TableName##QueryAccessor##CType13 *CName13; \
-(TableName##_##Query *)group; \
-(TableName##_##Query *)or; \
-(TableName##_##Query *)endgroup; \
-(TableName##_##Query *)subtable:(size_t)column; \
-(TableName##_##Query *)parent; \
-(TableName##_##View *)findAll; \
@end \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy##CType4 *CName4; \
@property(nonatomic, strong) OCColumnProxy##CType5 *CName5; \
@property(nonatomic, strong) OCColumnProxy##CType6 *CName6; \
@property(nonatomic, strong) OCColumnProxy##CType7 *CName7; \
@property(nonatomic, strong) OCColumnProxy##CType8 *CName8; \
@property(nonatomic, strong) OCColumnProxy##CType9 *CName9; \
@property(nonatomic, strong) OCColumnProxy##CType10 *CName10; \
@property(nonatomic, strong) OCColumnProxy##CType11 *CName11; \
@property(nonatomic, strong) OCColumnProxy##CType12 *CName12; \
@property(nonatomic, strong) OCColumnProxy##CType13 *CName13; \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9 CName10:(tdbOCType##CType10)CName10 CName11:(tdbOCType##CType11)CName11 CName12:(tdbOCType##CType12)CName12 CName13:(tdbOCType##CType13)CName13; \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9 CName10:(tdbOCType##CType10)CName10 CName11:(tdbOCType##CType11)CName11 CName12:(tdbOCType##CType12)CName12 CName13:(tdbOCType##CType13)CName13; \
-(TableName##_##Query *)getQuery; \
-(TableName##_##Cursor *)add; \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_##Cursor *)lastObject; \
@end \
@interface TableName##_##View : TableView \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
@end

#undef TIGHTDB_TABLE_13
#define TIGHTDB_TABLE_13(TableName    , CType1, CName1    , CType2, CName2    , CType3, CName3    , CType4, CName4    , CType5, CName5    , CType6, CName6    , CType7, CName7    , CType8, CName8    , CType9, CName9    , CType10, CName10    , CType11, CName11    , CType12, CName12    , CType13, CName13    ) \
TIGHTDB_TABLE_DEF_13(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ,CType6, CName6    ,CType7, CName7    ,CType8, CName8    ,CType9, CName9    ,CType10, CName10    ,CType11, CName11    ,CType12, CName12    ,CType13, CName13    ) \
TIGHTDB_TABLE_IMPL_13(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ,CType6, CName6    ,CType7, CName7    ,CType8, CName8    ,CType9, CName9    ,CType10, CName10    ,CType11, CName11    ,CType12, CName12    ,CType13, CName13    )


#undef TIGHTDB_TABLE_DEF_14
#define TIGHTDB_TABLE_DEF_14(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10, CType11, CName11, CType12, CName12, CType13, CName13, CType14, CName14) \
@interface TableName##_##Cursor : CursorBase \
    @property tdbOCType##CType1 CName1; \
    @property tdbOCType##CType2 CName2; \
    @property tdbOCType##CType3 CName3; \
    @property tdbOCType##CType4 CName4; \
    @property tdbOCType##CType5 CName5; \
    @property tdbOCType##CType6 CName6; \
    @property tdbOCType##CType7 CName7; \
    @property tdbOCType##CType8 CName8; \
    @property tdbOCType##CType9 CName9; \
    @property tdbOCType##CType10 CName10; \
    @property tdbOCType##CType11 CName11; \
    @property tdbOCType##CType12 CName12; \
    @property tdbOCType##CType13 CName13; \
    @property tdbOCType##CType14 CName14; \
    -(tdbOCType##CType1)CName1; \
    -(void)set##CName1:(tdbOCType##CType1)value; \
    -(tdbOCType##CType2)CName2; \
    -(void)set##CName2:(tdbOCType##CType2)value; \
    -(tdbOCType##CType3)CName3; \
    -(void)set##CName3:(tdbOCType##CType3)value; \
    -(tdbOCType##CType4)CName4; \
    -(void)set##CName4:(tdbOCType##CType4)value; \
    -(tdbOCType##CType5)CName5; \
    -(void)set##CName5:(tdbOCType##CType5)value; \
    -(tdbOCType##CType6)CName6; \
    -(void)set##CName6:(tdbOCType##CType6)value; \
    -(tdbOCType##CType7)CName7; \
    -(void)set##CName7:(tdbOCType##CType7)value; \
    -(tdbOCType##CType8)CName8; \
    -(void)set##CName8:(tdbOCType##CType8)value; \
    -(tdbOCType##CType9)CName9; \
    -(void)set##CName9:(tdbOCType##CType9)value; \
    -(tdbOCType##CType10)CName10; \
    -(void)set##CName10:(tdbOCType##CType10)value; \
    -(tdbOCType##CType11)CName11; \
    -(void)set##CName11:(tdbOCType##CType11)value; \
    -(tdbOCType##CType12)CName12; \
    -(void)set##CName12:(tdbOCType##CType12)value; \
    -(tdbOCType##CType13)CName13; \
    -(void)set##CName13:(tdbOCType##CType13)value; \
    -(tdbOCType##CType14)CName14; \
    -(void)set##CName14:(tdbOCType##CType14)value; \
@end \
@class TableName##_##Query; \
@class TableName##_##View; \
@interface TableName##QueryAccessorInt : OCXQueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value; \
-(TableName##_##Query *)notEqual:(size_t)value; \
-(TableName##_##Query *)greater:(int64_t)value; \
-(TableName##_##Query *)less:(int64_t)value; \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to; \
@end \
@interface TableName##QueryAccessorBool : OCXQueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value; \
@end \
@interface TableName##QueryAccessorString : OCXQueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
@end \
@interface TableName##_##Query : Query \
@property(nonatomic, strong) TableName##QueryAccessor##CType1 *CName1; \
@property(nonatomic, strong) TableName##QueryAccessor##CType2 *CName2; \
@property(nonatomic, strong) TableName##QueryAccessor##CType3 *CName3; \
@property(nonatomic, strong) TableName##QueryAccessor##CType4 *CName4; \
@property(nonatomic, strong) TableName##QueryAccessor##CType5 *CName5; \
@property(nonatomic, strong) TableName##QueryAccessor##CType6 *CName6; \
@property(nonatomic, strong) TableName##QueryAccessor##CType7 *CName7; \
@property(nonatomic, strong) TableName##QueryAccessor##CType8 *CName8; \
@property(nonatomic, strong) TableName##QueryAccessor##CType9 *CName9; \
@property(nonatomic, strong) TableName##QueryAccessor##CType10 *CName10; \
@property(nonatomic, strong) TableName##QueryAccessor##CType11 *CName11; \
@property(nonatomic, strong) TableName##QueryAccessor##CType12 *CName12; \
@property(nonatomic, strong) TableName##QueryAccessor##CType13 *CName13; \
@property(nonatomic, strong) TableName##QueryAccessor##CType14 *CName14; \
-(TableName##_##Query *)group; \
-(TableName##_##Query *)or; \
-(TableName##_##Query *)endgroup; \
-(TableName##_##Query *)subtable:(size_t)column; \
-(TableName##_##Query *)parent; \
-(TableName##_##View *)findAll; \
@end \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy##CType4 *CName4; \
@property(nonatomic, strong) OCColumnProxy##CType5 *CName5; \
@property(nonatomic, strong) OCColumnProxy##CType6 *CName6; \
@property(nonatomic, strong) OCColumnProxy##CType7 *CName7; \
@property(nonatomic, strong) OCColumnProxy##CType8 *CName8; \
@property(nonatomic, strong) OCColumnProxy##CType9 *CName9; \
@property(nonatomic, strong) OCColumnProxy##CType10 *CName10; \
@property(nonatomic, strong) OCColumnProxy##CType11 *CName11; \
@property(nonatomic, strong) OCColumnProxy##CType12 *CName12; \
@property(nonatomic, strong) OCColumnProxy##CType13 *CName13; \
@property(nonatomic, strong) OCColumnProxy##CType14 *CName14; \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9 CName10:(tdbOCType##CType10)CName10 CName11:(tdbOCType##CType11)CName11 CName12:(tdbOCType##CType12)CName12 CName13:(tdbOCType##CType13)CName13 CName14:(tdbOCType##CType14)CName14; \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9 CName10:(tdbOCType##CType10)CName10 CName11:(tdbOCType##CType11)CName11 CName12:(tdbOCType##CType12)CName12 CName13:(tdbOCType##CType13)CName13 CName14:(tdbOCType##CType14)CName14; \
-(TableName##_##Query *)getQuery; \
-(TableName##_##Cursor *)add; \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_##Cursor *)lastObject; \
@end \
@interface TableName##_##View : TableView \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
@end

#undef TIGHTDB_TABLE_14
#define TIGHTDB_TABLE_14(TableName    , CType1, CName1    , CType2, CName2    , CType3, CName3    , CType4, CName4    , CType5, CName5    , CType6, CName6    , CType7, CName7    , CType8, CName8    , CType9, CName9    , CType10, CName10    , CType11, CName11    , CType12, CName12    , CType13, CName13    , CType14, CName14    ) \
TIGHTDB_TABLE_DEF_14(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ,CType6, CName6    ,CType7, CName7    ,CType8, CName8    ,CType9, CName9    ,CType10, CName10    ,CType11, CName11    ,CType12, CName12    ,CType13, CName13    ,CType14, CName14    ) \
TIGHTDB_TABLE_IMPL_14(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ,CType6, CName6    ,CType7, CName7    ,CType8, CName8    ,CType9, CName9    ,CType10, CName10    ,CType11, CName11    ,CType12, CName12    ,CType13, CName13    ,CType14, CName14    )


#undef TIGHTDB_TABLE_DEF_15
#define TIGHTDB_TABLE_DEF_15(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10, CType11, CName11, CType12, CName12, CType13, CName13, CType14, CName14, CType15, CName15) \
@interface TableName##_##Cursor : CursorBase \
    @property tdbOCType##CType1 CName1; \
    @property tdbOCType##CType2 CName2; \
    @property tdbOCType##CType3 CName3; \
    @property tdbOCType##CType4 CName4; \
    @property tdbOCType##CType5 CName5; \
    @property tdbOCType##CType6 CName6; \
    @property tdbOCType##CType7 CName7; \
    @property tdbOCType##CType8 CName8; \
    @property tdbOCType##CType9 CName9; \
    @property tdbOCType##CType10 CName10; \
    @property tdbOCType##CType11 CName11; \
    @property tdbOCType##CType12 CName12; \
    @property tdbOCType##CType13 CName13; \
    @property tdbOCType##CType14 CName14; \
    @property tdbOCType##CType15 CName15; \
    -(tdbOCType##CType1)CName1; \
    -(void)set##CName1:(tdbOCType##CType1)value; \
    -(tdbOCType##CType2)CName2; \
    -(void)set##CName2:(tdbOCType##CType2)value; \
    -(tdbOCType##CType3)CName3; \
    -(void)set##CName3:(tdbOCType##CType3)value; \
    -(tdbOCType##CType4)CName4; \
    -(void)set##CName4:(tdbOCType##CType4)value; \
    -(tdbOCType##CType5)CName5; \
    -(void)set##CName5:(tdbOCType##CType5)value; \
    -(tdbOCType##CType6)CName6; \
    -(void)set##CName6:(tdbOCType##CType6)value; \
    -(tdbOCType##CType7)CName7; \
    -(void)set##CName7:(tdbOCType##CType7)value; \
    -(tdbOCType##CType8)CName8; \
    -(void)set##CName8:(tdbOCType##CType8)value; \
    -(tdbOCType##CType9)CName9; \
    -(void)set##CName9:(tdbOCType##CType9)value; \
    -(tdbOCType##CType10)CName10; \
    -(void)set##CName10:(tdbOCType##CType10)value; \
    -(tdbOCType##CType11)CName11; \
    -(void)set##CName11:(tdbOCType##CType11)value; \
    -(tdbOCType##CType12)CName12; \
    -(void)set##CName12:(tdbOCType##CType12)value; \
    -(tdbOCType##CType13)CName13; \
    -(void)set##CName13:(tdbOCType##CType13)value; \
    -(tdbOCType##CType14)CName14; \
    -(void)set##CName14:(tdbOCType##CType14)value; \
    -(tdbOCType##CType15)CName15; \
    -(void)set##CName15:(tdbOCType##CType15)value; \
@end \
@class TableName##_##Query; \
@class TableName##_##View; \
@interface TableName##QueryAccessorInt : OCXQueryAccessorInt \
-(TableName##_##Query *)equal:(size_t)value; \
-(TableName##_##Query *)notEqual:(size_t)value; \
-(TableName##_##Query *)greater:(int64_t)value; \
-(TableName##_##Query *)less:(int64_t)value; \
-(TableName##_##Query *)between:(int64_t)from to:(int64_t)to; \
@end \
@interface TableName##QueryAccessorBool : OCXQueryAccessorBool \
-(TableName##_##Query *)equal:(BOOL)value; \
@end \
@interface TableName##QueryAccessorString : OCXQueryAccessorString \
-(TableName##_##Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(TableName##_##Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
@end \
@interface TableName##_##Query : Query \
@property(nonatomic, strong) TableName##QueryAccessor##CType1 *CName1; \
@property(nonatomic, strong) TableName##QueryAccessor##CType2 *CName2; \
@property(nonatomic, strong) TableName##QueryAccessor##CType3 *CName3; \
@property(nonatomic, strong) TableName##QueryAccessor##CType4 *CName4; \
@property(nonatomic, strong) TableName##QueryAccessor##CType5 *CName5; \
@property(nonatomic, strong) TableName##QueryAccessor##CType6 *CName6; \
@property(nonatomic, strong) TableName##QueryAccessor##CType7 *CName7; \
@property(nonatomic, strong) TableName##QueryAccessor##CType8 *CName8; \
@property(nonatomic, strong) TableName##QueryAccessor##CType9 *CName9; \
@property(nonatomic, strong) TableName##QueryAccessor##CType10 *CName10; \
@property(nonatomic, strong) TableName##QueryAccessor##CType11 *CName11; \
@property(nonatomic, strong) TableName##QueryAccessor##CType12 *CName12; \
@property(nonatomic, strong) TableName##QueryAccessor##CType13 *CName13; \
@property(nonatomic, strong) TableName##QueryAccessor##CType14 *CName14; \
@property(nonatomic, strong) TableName##QueryAccessor##CType15 *CName15; \
-(TableName##_##Query *)group; \
-(TableName##_##Query *)or; \
-(TableName##_##Query *)endgroup; \
-(TableName##_##Query *)subtable:(size_t)column; \
-(TableName##_##Query *)parent; \
-(TableName##_##View *)findAll; \
@end \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy##CType4 *CName4; \
@property(nonatomic, strong) OCColumnProxy##CType5 *CName5; \
@property(nonatomic, strong) OCColumnProxy##CType6 *CName6; \
@property(nonatomic, strong) OCColumnProxy##CType7 *CName7; \
@property(nonatomic, strong) OCColumnProxy##CType8 *CName8; \
@property(nonatomic, strong) OCColumnProxy##CType9 *CName9; \
@property(nonatomic, strong) OCColumnProxy##CType10 *CName10; \
@property(nonatomic, strong) OCColumnProxy##CType11 *CName11; \
@property(nonatomic, strong) OCColumnProxy##CType12 *CName12; \
@property(nonatomic, strong) OCColumnProxy##CType13 *CName13; \
@property(nonatomic, strong) OCColumnProxy##CType14 *CName14; \
@property(nonatomic, strong) OCColumnProxy##CType15 *CName15; \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9 CName10:(tdbOCType##CType10)CName10 CName11:(tdbOCType##CType11)CName11 CName12:(tdbOCType##CType12)CName12 CName13:(tdbOCType##CType13)CName13 CName14:(tdbOCType##CType14)CName14 CName15:(tdbOCType##CType15)CName15; \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 CName9:(tdbOCType##CType9)CName9 CName10:(tdbOCType##CType10)CName10 CName11:(tdbOCType##CType11)CName11 CName12:(tdbOCType##CType12)CName12 CName13:(tdbOCType##CType13)CName13 CName14:(tdbOCType##CType14)CName14 CName15:(tdbOCType##CType15)CName15; \
-(TableName##_##Query *)getQuery; \
-(TableName##_##Cursor *)add; \
-(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_##Cursor *)lastObject; \
@end \
@interface TableName##_##View : TableView \
    -(TableName##_##Cursor *)objectAtIndex:(size_t)ndx; \
@end

#undef TIGHTDB_TABLE_15
#define TIGHTDB_TABLE_15(TableName    , CType1, CName1    , CType2, CName2    , CType3, CName3    , CType4, CName4    , CType5, CName5    , CType6, CName6    , CType7, CName7    , CType8, CName8    , CType9, CName9    , CType10, CName10    , CType11, CName11    , CType12, CName12    , CType13, CName13    , CType14, CName14    , CType15, CName15    ) \
TIGHTDB_TABLE_DEF_15(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ,CType6, CName6    ,CType7, CName7    ,CType8, CName8    ,CType9, CName9    ,CType10, CName10    ,CType11, CName11    ,CType12, CName12    ,CType13, CName13    ,CType14, CName14    ,CType15, CName15    ) \
TIGHTDB_TABLE_IMPL_15(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ,CType6, CName6    ,CType7, CName7    ,CType8, CName8    ,CType9, CName9    ,CType10, CName10    ,CType11, CName11    ,CType12, CName12    ,CType13, CName13    ,CType14, CName14    ,CType15, CName15    )



