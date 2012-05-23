//
//  TightDb.h
//  TightDB
//

#import "Table.h"
#import "Query.h"
#import "Cursor.h"

#undef TDB_TABLE_IMPL_1
#define TDB_TABLE_IMPL_1(TableName, CType1, CName1) \
@implementation TableName##_Cursor \
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
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len \
    { \
    if(state->state == 0) \
    { \
    state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self); \
    state->extra[0] = (long)[self findNext:-1]; \
    state->state = 1; \
    state->itemsPtr = stackbuf; \
    *stackbuf = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:state->extra[0]]; \
    } \
    int ndx = state->extra[0]; \
    if(ndx==-1) { \
        return 0; \
    } \
    [((TableName##_Cursor *)*stackbuf) setNdx:ndx]; \
    NSLog(@"Cursor: %@ - ndx: %i", *stackbuf, ndx); \
    state->extra[0] = [self findNext:ndx]; \
    return 1; \
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
-(TableName##_Cursor *)add \
{ \
    return [[TableName##_Cursor alloc] initWithTable:self ndx:[self addRow]]; \
} \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_Cursor alloc] initWithTable:self ndx:ndx]; \
} \
-(TableName##_Cursor *)lastObject \
{ \
    return [[TableName##_Cursor alloc] initWithTable:self ndx:[self count]-1]; \
} \
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len \
    { \
    if(state->state == 0) \
    { \
    state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self); \
    state->extra[0] = (long)0; \
    state->state = 1; \
    state->itemsPtr = stackbuf; \
    *stackbuf = [[TableName##_Cursor alloc] initWithTable:self ndx:0]; \
    } \
    int ndx = state->extra[0]; \
    if(ndx>=[self count]) \
        return 0; \
    [((TableName##_Cursor *)*stackbuf) setNdx:ndx]; \
    NSLog(@"Cursor: %@ - ndx: %i", *stackbuf, ndx); \
    if(ndx<[self count]) \
        state->extra[0] = ndx+1; \
    return 1; \
    } \
@end \
@implementation TableName##_##View \
    - (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len \
    { \
    if(state->state == 0) \
    { \
    state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self); \
    state->extra[0] = (long)0; \
    state->state = 1; \
    state->itemsPtr = stackbuf; \
    *stackbuf = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
    } \
    int ndx = state->extra[0]; \
    if(ndx>=[self count]) \
    return 0; \
    [((TableName##_Cursor *)*stackbuf) setNdx:[self getSourceNdx:ndx]]; \
    NSLog(@"Cursor: %@ - ndx: %i", *stackbuf, ndx); \
    if(ndx<[self count]) \
    state->extra[0] = ndx+1; \
    return 1; \
    } \
@end

#undef TDB_TABLE_IMPL_2
#define TDB_TABLE_IMPL_2(TableName, CType1, CName1, CType2, CName2) \
@implementation TableName##_Cursor \
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
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len \
    { \
    if(state->state == 0) \
    { \
    state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self); \
    state->extra[0] = (long)[self findNext:-1]; \
    state->state = 1; \
    state->itemsPtr = stackbuf; \
    *stackbuf = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:state->extra[0]]; \
    } \
    int ndx = state->extra[0]; \
    if(ndx==-1) { \
        return 0; \
    } \
    [((TableName##_Cursor *)*stackbuf) setNdx:ndx]; \
    NSLog(@"Cursor: %@ - ndx: %i", *stackbuf, ndx); \
    state->extra[0] = [self findNext:ndx]; \
    return 1; \
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
-(TableName##_Cursor *)add \
{ \
    return [[TableName##_Cursor alloc] initWithTable:self ndx:[self addRow]]; \
} \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_Cursor alloc] initWithTable:self ndx:ndx]; \
} \
-(TableName##_Cursor *)lastObject \
{ \
    return [[TableName##_Cursor alloc] initWithTable:self ndx:[self count]-1]; \
} \
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len \
    { \
    if(state->state == 0) \
    { \
    state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self); \
    state->extra[0] = (long)0; \
    state->state = 1; \
    state->itemsPtr = stackbuf; \
    *stackbuf = [[TableName##_Cursor alloc] initWithTable:self ndx:0]; \
    } \
    int ndx = state->extra[0]; \
    if(ndx>=[self count]) \
        return 0; \
    [((TableName##_Cursor *)*stackbuf) setNdx:ndx]; \
    NSLog(@"Cursor: %@ - ndx: %i", *stackbuf, ndx); \
    if(ndx<[self count]) \
        state->extra[0] = ndx+1; \
    return 1; \
    } \
@end \
@implementation TableName##_##View \
    - (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len \
    { \
    if(state->state == 0) \
    { \
    state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self); \
    state->extra[0] = (long)0; \
    state->state = 1; \
    state->itemsPtr = stackbuf; \
    *stackbuf = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
    } \
    int ndx = state->extra[0]; \
    if(ndx>=[self count]) \
    return 0; \
    [((TableName##_Cursor *)*stackbuf) setNdx:[self getSourceNdx:ndx]]; \
    NSLog(@"Cursor: %@ - ndx: %i", *stackbuf, ndx); \
    if(ndx<[self count]) \
    state->extra[0] = ndx+1; \
    return 1; \
    } \
@end

#undef TDB_TABLE_IMPL_3
#define TDB_TABLE_IMPL_3(TableName, CType1, CName1, CType2, CName2, CType3, CName3) \
@implementation TableName##_Cursor \
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
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len \
    { \
    if(state->state == 0) \
    { \
    state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self); \
    state->extra[0] = (long)[self findNext:-1]; \
    state->state = 1; \
    state->itemsPtr = stackbuf; \
    *stackbuf = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:state->extra[0]]; \
    } \
    int ndx = state->extra[0]; \
    if(ndx==-1) { \
        return 0; \
    } \
    [((TableName##_Cursor *)*stackbuf) setNdx:ndx]; \
    NSLog(@"Cursor: %@ - ndx: %i", *stackbuf, ndx); \
    state->extra[0] = [self findNext:ndx]; \
    return 1; \
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
-(TableName##_Cursor *)add \
{ \
    return [[TableName##_Cursor alloc] initWithTable:self ndx:[self addRow]]; \
} \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_Cursor alloc] initWithTable:self ndx:ndx]; \
} \
-(TableName##_Cursor *)lastObject \
{ \
    return [[TableName##_Cursor alloc] initWithTable:self ndx:[self count]-1]; \
} \
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len \
    { \
    if(state->state == 0) \
    { \
    state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self); \
    state->extra[0] = (long)0; \
    state->state = 1; \
    state->itemsPtr = stackbuf; \
    *stackbuf = [[TableName##_Cursor alloc] initWithTable:self ndx:0]; \
    } \
    int ndx = state->extra[0]; \
    if(ndx>=[self count]) \
        return 0; \
    [((TableName##_Cursor *)*stackbuf) setNdx:ndx]; \
    NSLog(@"Cursor: %@ - ndx: %i", *stackbuf, ndx); \
    if(ndx<[self count]) \
        state->extra[0] = ndx+1; \
    return 1; \
    } \
@end \
@implementation TableName##_##View \
    - (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len \
    { \
    if(state->state == 0) \
    { \
    state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self); \
    state->extra[0] = (long)0; \
    state->state = 1; \
    state->itemsPtr = stackbuf; \
    *stackbuf = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
    } \
    int ndx = state->extra[0]; \
    if(ndx>=[self count]) \
    return 0; \
    [((TableName##_Cursor *)*stackbuf) setNdx:[self getSourceNdx:ndx]]; \
    NSLog(@"Cursor: %@ - ndx: %i", *stackbuf, ndx); \
    if(ndx<[self count]) \
    state->extra[0] = ndx+1; \
    return 1; \
    } \
@end

#undef TDB_TABLE_IMPL_4
#define TDB_TABLE_IMPL_4(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4) \
@implementation TableName##_Cursor \
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
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len \
    { \
    if(state->state == 0) \
    { \
    state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self); \
    state->extra[0] = (long)[self findNext:-1]; \
    state->state = 1; \
    state->itemsPtr = stackbuf; \
    *stackbuf = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:state->extra[0]]; \
    } \
    int ndx = state->extra[0]; \
    if(ndx==-1) { \
        return 0; \
    } \
    [((TableName##_Cursor *)*stackbuf) setNdx:ndx]; \
    NSLog(@"Cursor: %@ - ndx: %i", *stackbuf, ndx); \
    state->extra[0] = [self findNext:ndx]; \
    return 1; \
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
-(TableName##_Cursor *)add \
{ \
    return [[TableName##_Cursor alloc] initWithTable:self ndx:[self addRow]]; \
} \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_Cursor alloc] initWithTable:self ndx:ndx]; \
} \
-(TableName##_Cursor *)lastObject \
{ \
    return [[TableName##_Cursor alloc] initWithTable:self ndx:[self count]-1]; \
} \
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len \
    { \
    if(state->state == 0) \
    { \
    state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self); \
    state->extra[0] = (long)0; \
    state->state = 1; \
    state->itemsPtr = stackbuf; \
    *stackbuf = [[TableName##_Cursor alloc] initWithTable:self ndx:0]; \
    } \
    int ndx = state->extra[0]; \
    if(ndx>=[self count]) \
        return 0; \
    [((TableName##_Cursor *)*stackbuf) setNdx:ndx]; \
    NSLog(@"Cursor: %@ - ndx: %i", *stackbuf, ndx); \
    if(ndx<[self count]) \
        state->extra[0] = ndx+1; \
    return 1; \
    } \
@end \
@implementation TableName##_##View \
    - (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len \
    { \
    if(state->state == 0) \
    { \
    state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self); \
    state->extra[0] = (long)0; \
    state->state = 1; \
    state->itemsPtr = stackbuf; \
    *stackbuf = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
    } \
    int ndx = state->extra[0]; \
    if(ndx>=[self count]) \
    return 0; \
    [((TableName##_Cursor *)*stackbuf) setNdx:[self getSourceNdx:ndx]]; \
    NSLog(@"Cursor: %@ - ndx: %i", *stackbuf, ndx); \
    if(ndx<[self count]) \
    state->extra[0] = ndx+1; \
    return 1; \
    } \
@end

#undef TDB_TABLE_IMPL_5
#define TDB_TABLE_IMPL_5(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5) \
@implementation TableName##_Cursor \
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
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len \
    { \
    if(state->state == 0) \
    { \
    state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self); \
    state->extra[0] = (long)[self findNext:-1]; \
    state->state = 1; \
    state->itemsPtr = stackbuf; \
    *stackbuf = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:state->extra[0]]; \
    } \
    int ndx = state->extra[0]; \
    if(ndx==-1) { \
        return 0; \
    } \
    [((TableName##_Cursor *)*stackbuf) setNdx:ndx]; \
    NSLog(@"Cursor: %@ - ndx: %i", *stackbuf, ndx); \
    state->extra[0] = [self findNext:ndx]; \
    return 1; \
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
-(TableName##_Cursor *)add \
{ \
    return [[TableName##_Cursor alloc] initWithTable:self ndx:[self addRow]]; \
} \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_Cursor alloc] initWithTable:self ndx:ndx]; \
} \
-(TableName##_Cursor *)lastObject \
{ \
    return [[TableName##_Cursor alloc] initWithTable:self ndx:[self count]-1]; \
} \
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len \
    { \
    if(state->state == 0) \
    { \
    state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self); \
    state->extra[0] = (long)0; \
    state->state = 1; \
    state->itemsPtr = stackbuf; \
    *stackbuf = [[TableName##_Cursor alloc] initWithTable:self ndx:0]; \
    } \
    int ndx = state->extra[0]; \
    if(ndx>=[self count]) \
        return 0; \
    [((TableName##_Cursor *)*stackbuf) setNdx:ndx]; \
    NSLog(@"Cursor: %@ - ndx: %i", *stackbuf, ndx); \
    if(ndx<[self count]) \
        state->extra[0] = ndx+1; \
    return 1; \
    } \
@end \
@implementation TableName##_##View \
    - (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len \
    { \
    if(state->state == 0) \
    { \
    state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self); \
    state->extra[0] = (long)0; \
    state->state = 1; \
    state->itemsPtr = stackbuf; \
    *stackbuf = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
    } \
    int ndx = state->extra[0]; \
    if(ndx>=[self count]) \
    return 0; \
    [((TableName##_Cursor *)*stackbuf) setNdx:[self getSourceNdx:ndx]]; \
    NSLog(@"Cursor: %@ - ndx: %i", *stackbuf, ndx); \
    if(ndx<[self count]) \
    state->extra[0] = ndx+1; \
    return 1; \
    } \
@end

#undef TDB_TABLE_IMPL_6
#define TDB_TABLE_IMPL_6(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6) \
@implementation TableName##_Cursor \
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
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len \
    { \
    if(state->state == 0) \
    { \
    state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self); \
    state->extra[0] = (long)[self findNext:-1]; \
    state->state = 1; \
    state->itemsPtr = stackbuf; \
    *stackbuf = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:state->extra[0]]; \
    } \
    int ndx = state->extra[0]; \
    if(ndx==-1) { \
        return 0; \
    } \
    [((TableName##_Cursor *)*stackbuf) setNdx:ndx]; \
    NSLog(@"Cursor: %@ - ndx: %i", *stackbuf, ndx); \
    state->extra[0] = [self findNext:ndx]; \
    return 1; \
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
-(TableName##_Cursor *)add \
{ \
    return [[TableName##_Cursor alloc] initWithTable:self ndx:[self addRow]]; \
} \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_Cursor alloc] initWithTable:self ndx:ndx]; \
} \
-(TableName##_Cursor *)lastObject \
{ \
    return [[TableName##_Cursor alloc] initWithTable:self ndx:[self count]-1]; \
} \
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len \
    { \
    if(state->state == 0) \
    { \
    state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self); \
    state->extra[0] = (long)0; \
    state->state = 1; \
    state->itemsPtr = stackbuf; \
    *stackbuf = [[TableName##_Cursor alloc] initWithTable:self ndx:0]; \
    } \
    int ndx = state->extra[0]; \
    if(ndx>=[self count]) \
        return 0; \
    [((TableName##_Cursor *)*stackbuf) setNdx:ndx]; \
    NSLog(@"Cursor: %@ - ndx: %i", *stackbuf, ndx); \
    if(ndx<[self count]) \
        state->extra[0] = ndx+1; \
    return 1; \
    } \
@end \
@implementation TableName##_##View \
    - (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len \
    { \
    if(state->state == 0) \
    { \
    state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self); \
    state->extra[0] = (long)0; \
    state->state = 1; \
    state->itemsPtr = stackbuf; \
    *stackbuf = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
    } \
    int ndx = state->extra[0]; \
    if(ndx>=[self count]) \
    return 0; \
    [((TableName##_Cursor *)*stackbuf) setNdx:[self getSourceNdx:ndx]]; \
    NSLog(@"Cursor: %@ - ndx: %i", *stackbuf, ndx); \
    if(ndx<[self count]) \
    state->extra[0] = ndx+1; \
    return 1; \
    } \
@end

#undef TDB_TABLE_IMPL_7
#define TDB_TABLE_IMPL_7(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7) \
@implementation TableName##_Cursor \
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
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len \
    { \
    if(state->state == 0) \
    { \
    state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self); \
    state->extra[0] = (long)[self findNext:-1]; \
    state->state = 1; \
    state->itemsPtr = stackbuf; \
    *stackbuf = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:state->extra[0]]; \
    } \
    int ndx = state->extra[0]; \
    if(ndx==-1) { \
        return 0; \
    } \
    [((TableName##_Cursor *)*stackbuf) setNdx:ndx]; \
    NSLog(@"Cursor: %@ - ndx: %i", *stackbuf, ndx); \
    state->extra[0] = [self findNext:ndx]; \
    return 1; \
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
-(TableName##_Cursor *)add \
{ \
    return [[TableName##_Cursor alloc] initWithTable:self ndx:[self addRow]]; \
} \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_Cursor alloc] initWithTable:self ndx:ndx]; \
} \
-(TableName##_Cursor *)lastObject \
{ \
    return [[TableName##_Cursor alloc] initWithTable:self ndx:[self count]-1]; \
} \
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len \
    { \
    if(state->state == 0) \
    { \
    state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self); \
    state->extra[0] = (long)0; \
    state->state = 1; \
    state->itemsPtr = stackbuf; \
    *stackbuf = [[TableName##_Cursor alloc] initWithTable:self ndx:0]; \
    } \
    int ndx = state->extra[0]; \
    if(ndx>=[self count]) \
        return 0; \
    [((TableName##_Cursor *)*stackbuf) setNdx:ndx]; \
    NSLog(@"Cursor: %@ - ndx: %i", *stackbuf, ndx); \
    if(ndx<[self count]) \
        state->extra[0] = ndx+1; \
    return 1; \
    } \
@end \
@implementation TableName##_##View \
    - (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len \
    { \
    if(state->state == 0) \
    { \
    state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self); \
    state->extra[0] = (long)0; \
    state->state = 1; \
    state->itemsPtr = stackbuf; \
    *stackbuf = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
    } \
    int ndx = state->extra[0]; \
    if(ndx>=[self count]) \
    return 0; \
    [((TableName##_Cursor *)*stackbuf) setNdx:[self getSourceNdx:ndx]]; \
    NSLog(@"Cursor: %@ - ndx: %i", *stackbuf, ndx); \
    if(ndx<[self count]) \
    state->extra[0] = ndx+1; \
    return 1; \
    } \
@end

#undef TDB_TABLE_IMPL_8
#define TDB_TABLE_IMPL_8(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8) \
@implementation TableName##_Cursor \
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
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len \
    { \
    if(state->state == 0) \
    { \
    state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self); \
    state->extra[0] = (long)[self findNext:-1]; \
    state->state = 1; \
    state->itemsPtr = stackbuf; \
    *stackbuf = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:state->extra[0]]; \
    } \
    int ndx = state->extra[0]; \
    if(ndx==-1) { \
        return 0; \
    } \
    [((TableName##_Cursor *)*stackbuf) setNdx:ndx]; \
    NSLog(@"Cursor: %@ - ndx: %i", *stackbuf, ndx); \
    state->extra[0] = [self findNext:ndx]; \
    return 1; \
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
-(TableName##_Cursor *)add \
{ \
    return [[TableName##_Cursor alloc] initWithTable:self ndx:[self addRow]]; \
} \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_Cursor alloc] initWithTable:self ndx:ndx]; \
} \
-(TableName##_Cursor *)lastObject \
{ \
    return [[TableName##_Cursor alloc] initWithTable:self ndx:[self count]-1]; \
} \
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len \
    { \
    if(state->state == 0) \
    { \
    state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self); \
    state->extra[0] = (long)0; \
    state->state = 1; \
    state->itemsPtr = stackbuf; \
    *stackbuf = [[TableName##_Cursor alloc] initWithTable:self ndx:0]; \
    } \
    int ndx = state->extra[0]; \
    if(ndx>=[self count]) \
        return 0; \
    [((TableName##_Cursor *)*stackbuf) setNdx:ndx]; \
    NSLog(@"Cursor: %@ - ndx: %i", *stackbuf, ndx); \
    if(ndx<[self count]) \
        state->extra[0] = ndx+1; \
    return 1; \
    } \
@end \
@implementation TableName##_##View \
    - (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len \
    { \
    if(state->state == 0) \
    { \
    state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self); \
    state->extra[0] = (long)0; \
    state->state = 1; \
    state->itemsPtr = stackbuf; \
    *stackbuf = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
    } \
    int ndx = state->extra[0]; \
    if(ndx>=[self count]) \
    return 0; \
    [((TableName##_Cursor *)*stackbuf) setNdx:[self getSourceNdx:ndx]]; \
    NSLog(@"Cursor: %@ - ndx: %i", *stackbuf, ndx); \
    if(ndx<[self count]) \
    state->extra[0] = ndx+1; \
    return 1; \
    } \
@end


#undef TDB_TABLE_DEF_1
#define TDB_TABLE_DEF_1(TableName, CType1, CName1) \
@interface TableName##_Cursor : CursorBase \
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
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len; \
@end \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
-(void)add##CName1:(tdbOCType##CType1)CName1; \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1; \
-(TableName##_##Query *)getQuery; \
-(TableName##_Cursor *)add; \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_Cursor *)lastObject; \
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len; \
@end \
@interface TableName##_##View : TableView \
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len; \
@end

#undef TDB_TABLE_1
#define TDB_TABLE_1(TableName    , CType1, CName1    ) \
TDB_TABLE_DEF_1(TableName    ,CType1, CName1    ) \
TDB_TABLE_IMPL_1(TableName    ,CType1, CName1    )
    

#undef TDB_TABLE_DEF_2
#define TDB_TABLE_DEF_2(TableName, CType1, CName1, CType2, CName2) \
@interface TableName##_Cursor : CursorBase \
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
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len; \
@end \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy##CType2 *CName2; \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2; \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2; \
-(TableName##_##Query *)getQuery; \
-(TableName##_Cursor *)add; \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_Cursor *)lastObject; \
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len; \
@end \
@interface TableName##_##View : TableView \
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len; \
@end

#undef TDB_TABLE_2
#define TDB_TABLE_2(TableName    , CType1, CName1    , CType2, CName2    ) \
TDB_TABLE_DEF_2(TableName    ,CType1, CName1    ,CType2, CName2    ) \
TDB_TABLE_IMPL_2(TableName    ,CType1, CName1    ,CType2, CName2    )
    

#undef TDB_TABLE_DEF_3
#define TDB_TABLE_DEF_3(TableName, CType1, CName1, CType2, CName2, CType3, CName3) \
@interface TableName##_Cursor : CursorBase \
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
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len; \
@end \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy##CType3 *CName3; \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3; \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3; \
-(TableName##_##Query *)getQuery; \
-(TableName##_Cursor *)add; \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_Cursor *)lastObject; \
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len; \
@end \
@interface TableName##_##View : TableView \
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len; \
@end

#undef TDB_TABLE_3
#define TDB_TABLE_3(TableName    , CType1, CName1    , CType2, CName2    , CType3, CName3    ) \
TDB_TABLE_DEF_3(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ) \
TDB_TABLE_IMPL_3(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    )
    

#undef TDB_TABLE_DEF_4
#define TDB_TABLE_DEF_4(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4) \
@interface TableName##_Cursor : CursorBase \
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
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len; \
@end \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy##CType4 *CName4; \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4; \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4; \
-(TableName##_##Query *)getQuery; \
-(TableName##_Cursor *)add; \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_Cursor *)lastObject; \
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len; \
@end \
@interface TableName##_##View : TableView \
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len; \
@end

#undef TDB_TABLE_4
#define TDB_TABLE_4(TableName    , CType1, CName1    , CType2, CName2    , CType3, CName3    , CType4, CName4    ) \
TDB_TABLE_DEF_4(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ) \
TDB_TABLE_IMPL_4(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    )
    

#undef TDB_TABLE_DEF_5
#define TDB_TABLE_DEF_5(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5) \
@interface TableName##_Cursor : CursorBase \
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
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len; \
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
-(TableName##_Cursor *)add; \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_Cursor *)lastObject; \
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len; \
@end \
@interface TableName##_##View : TableView \
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len; \
@end

#undef TDB_TABLE_5
#define TDB_TABLE_5(TableName    , CType1, CName1    , CType2, CName2    , CType3, CName3    , CType4, CName4    , CType5, CName5    ) \
TDB_TABLE_DEF_5(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ) \
TDB_TABLE_IMPL_5(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    )
    

#undef TDB_TABLE_DEF_6
#define TDB_TABLE_DEF_6(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6) \
@interface TableName##_Cursor : CursorBase \
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
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len; \
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
-(TableName##_Cursor *)add; \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_Cursor *)lastObject; \
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len; \
@end \
@interface TableName##_##View : TableView \
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len; \
@end

#undef TDB_TABLE_6
#define TDB_TABLE_6(TableName    , CType1, CName1    , CType2, CName2    , CType3, CName3    , CType4, CName4    , CType5, CName5    , CType6, CName6    ) \
TDB_TABLE_DEF_6(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ,CType6, CName6    ) \
TDB_TABLE_IMPL_6(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ,CType6, CName6    )
    

#undef TDB_TABLE_DEF_7
#define TDB_TABLE_DEF_7(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7) \
@interface TableName##_Cursor : CursorBase \
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
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len; \
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
-(TableName##_Cursor *)add; \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_Cursor *)lastObject; \
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len; \
@end \
@interface TableName##_##View : TableView \
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len; \
@end

#undef TDB_TABLE_7
#define TDB_TABLE_7(TableName    , CType1, CName1    , CType2, CName2    , CType3, CName3    , CType4, CName4    , CType5, CName5    , CType6, CName6    , CType7, CName7    ) \
TDB_TABLE_DEF_7(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ,CType6, CName6    ,CType7, CName7    ) \
TDB_TABLE_IMPL_7(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ,CType6, CName6    ,CType7, CName7    )
    

#undef TDB_TABLE_DEF_8
#define TDB_TABLE_DEF_8(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8) \
@interface TableName##_Cursor : CursorBase \
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
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len; \
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
-(TableName##_Cursor *)add; \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_Cursor *)lastObject; \
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len; \
@end \
@interface TableName##_##View : TableView \
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len; \
@end

#undef TDB_TABLE_8
#define TDB_TABLE_8(TableName    , CType1, CName1    , CType2, CName2    , CType3, CName3    , CType4, CName4    , CType5, CName5    , CType6, CName6    , CType7, CName7    , CType8, CName8    ) \
TDB_TABLE_DEF_8(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ,CType6, CName6    ,CType7, CName7    ,CType8, CName8    ) \
TDB_TABLE_IMPL_8(TableName    ,CType1, CName1    ,CType2, CName2    ,CType3, CName3    ,CType4, CName4    ,CType5, CName5    ,CType6, CName6    ,CType7, CName7    ,CType8, CName8    )
    


