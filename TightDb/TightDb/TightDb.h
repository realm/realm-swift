//
//  TightDb.h
//  TightDB
//

#import "OCTable.h"
#import "OCQuery.h"

#ifdef TIGHT_IMPL
#undef TDB_TABLE_1
#define TDB_TABLE_1(TableName, CType1, CName1) \
@implementation TableName##_##Query \
@synthesize CName1 = _CName1; \
-(id)init \
{ \
    self = [super init]; \
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
    self = [super init]; \
    if (self) { \
        if (block) block(self); \
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
-(void)insert##CName1:(size_t)ndx CName1:(tdbOCType##CType1)CName1 \
{ \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insertDone]; \
} \
-(TableName##_##Query *)getQuery \
{ \
    return [[TableName##_##Query alloc] init]; \
} \
@end

#undef TDB_TABLE_2
#define TDB_TABLE_2(TableName, CType1, CName1, CType2, CName2) \
@implementation TableName##_##Query \
@synthesize CName1 = _CName1; \
@synthesize CName2 = _CName2; \
-(id)init \
{ \
    self = [super init]; \
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
    self = [super init]; \
    if (self) { \
        if (block) block(self); \
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
-(void)insert##CName1:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 \
{ \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insertDone]; \
} \
-(TableName##_##Query *)getQuery \
{ \
    return [[TableName##_##Query alloc] init]; \
} \
@end

#undef TDB_TABLE_3
#define TDB_TABLE_3(TableName, CType1, CName1, CType2, CName2, CType3, CName3) \
@implementation TableName##_##Query \
@synthesize CName1 = _CName1; \
@synthesize CName2 = _CName2; \
@synthesize CName3 = _CName3; \
-(id)init \
{ \
    self = [super init]; \
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
    self = [super init]; \
    if (self) { \
        if (block) block(self); \
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
-(void)insert##CName1:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 \
{ \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insertDone]; \
} \
-(TableName##_##Query *)getQuery \
{ \
    return [[TableName##_##Query alloc] init]; \
} \
@end

#undef TDB_TABLE_4
#define TDB_TABLE_4(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4) \
@implementation TableName##_##Query \
@synthesize CName1 = _CName1; \
@synthesize CName2 = _CName2; \
@synthesize CName3 = _CName3; \
@synthesize CName4 = _CName4; \
-(id)init \
{ \
    self = [super init]; \
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
    self = [super init]; \
    if (self) { \
        if (block) block(self); \
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
-(void)insert##CName1:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 \
{ \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insert##CType3:2 ndx:ndx value:CName3]; \
    [self insert##CType4:3 ndx:ndx value:CName4]; \
    [self insertDone]; \
} \
-(TableName##_##Query *)getQuery \
{ \
    return [[TableName##_##Query alloc] init]; \
} \
@end

#undef TDB_TABLE_5
#define TDB_TABLE_5(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5) \
@implementation TableName##_##Query \
@synthesize CName1 = _CName1; \
@synthesize CName2 = _CName2; \
@synthesize CName3 = _CName3; \
@synthesize CName4 = _CName4; \
@synthesize CName5 = _CName5; \
-(id)init \
{ \
    self = [super init]; \
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
    self = [super init]; \
    if (self) { \
        if (block) block(self); \
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
-(void)insert##CName1:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 \
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
    return [[TableName##_##Query alloc] init]; \
} \
@end

#undef TDB_TABLE_6
#define TDB_TABLE_6(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6) \
@implementation TableName##_##Query \
@synthesize CName1 = _CName1; \
@synthesize CName2 = _CName2; \
@synthesize CName3 = _CName3; \
@synthesize CName4 = _CName4; \
@synthesize CName5 = _CName5; \
@synthesize CName6 = _CName6; \
-(id)init \
{ \
    self = [super init]; \
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
    self = [super init]; \
    if (self) { \
        if (block) block(self); \
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
-(void)insert##CName1:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 \
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
    return [[TableName##_##Query alloc] init]; \
} \
@end

#undef TDB_TABLE_7
#define TDB_TABLE_7(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7) \
@implementation TableName##_##Query \
@synthesize CName1 = _CName1; \
@synthesize CName2 = _CName2; \
@synthesize CName3 = _CName3; \
@synthesize CName4 = _CName4; \
@synthesize CName5 = _CName5; \
@synthesize CName6 = _CName6; \
@synthesize CName7 = _CName7; \
-(id)init \
{ \
    self = [super init]; \
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
    self = [super init]; \
    if (self) { \
        if (block) block(self); \
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
-(void)insert##CName1:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 \
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
    return [[TableName##_##Query alloc] init]; \
} \
@end

#undef TDB_TABLE_8
#define TDB_TABLE_8(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8) \
@implementation TableName##_##Query \
@synthesize CName1 = _CName1; \
@synthesize CName2 = _CName2; \
@synthesize CName3 = _CName3; \
@synthesize CName4 = _CName4; \
@synthesize CName5 = _CName5; \
@synthesize CName6 = _CName6; \
@synthesize CName7 = _CName7; \
@synthesize CName8 = _CName8; \
-(id)init \
{ \
    self = [super init]; \
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
    self = [super init]; \
    if (self) { \
        if (block) block(self); \
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
-(void)insert##CName1:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8 \
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
    return [[TableName##_##Query alloc] init]; \
} \
@end


#else


#undef TDB_TABLE_1
#define TDB_TABLE_1(TableName, CType1, CName1) \
@class TableName##_##Query; \
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
@interface TableName##_##Query : OCQuery \
@property(nonatomic, strong) TableName##QueryAccessor##CType1 *CName1; \
-(TableName##_##Query *)group; \
-(TableName##_##Query *)or; \
-(TableName##_##Query *)endgroup; \
-(TableName##_##Query *)subtable:(size_t)column; \
-(TableName##_##Query *)parent; \
@end \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
-(void)add##CName1:(tdbOCType##CType1)CName1; \
-(void)insert##CName1:(size_t)ndx CName1:(tdbOCType##CType1)CName1; \
-(TableName##_##Query *)getQuery; \
@end

#undef TDB_TABLE_2
#define TDB_TABLE_2(TableName, CType1, CName1, CType2, CName2) \
@class TableName##_##Query; \
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
@interface TableName##_##Query : OCQuery \
@property(nonatomic, strong) TableName##QueryAccessor##CType1 *CName1; \
@property(nonatomic, strong) TableName##QueryAccessor##CType2 *CName2; \
-(TableName##_##Query *)group; \
-(TableName##_##Query *)or; \
-(TableName##_##Query *)endgroup; \
-(TableName##_##Query *)subtable:(size_t)column; \
-(TableName##_##Query *)parent; \
@end \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy##CType2 *CName2; \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2; \
-(void)insert##CName1:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2; \
-(TableName##_##Query *)getQuery; \
@end

#undef TDB_TABLE_3
#define TDB_TABLE_3(TableName, CType1, CName1, CType2, CName2, CType3, CName3) \
@class TableName##_##Query; \
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
@interface TableName##_##Query : OCQuery \
@property(nonatomic, strong) TableName##QueryAccessor##CType1 *CName1; \
@property(nonatomic, strong) TableName##QueryAccessor##CType2 *CName2; \
@property(nonatomic, strong) TableName##QueryAccessor##CType3 *CName3; \
-(TableName##_##Query *)group; \
-(TableName##_##Query *)or; \
-(TableName##_##Query *)endgroup; \
-(TableName##_##Query *)subtable:(size_t)column; \
-(TableName##_##Query *)parent; \
@end \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy##CType3 *CName3; \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3; \
-(void)insert##CName1:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3; \
-(TableName##_##Query *)getQuery; \
@end

#undef TDB_TABLE_4
#define TDB_TABLE_4(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4) \
@class TableName##_##Query; \
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
@interface TableName##_##Query : OCQuery \
@property(nonatomic, strong) TableName##QueryAccessor##CType1 *CName1; \
@property(nonatomic, strong) TableName##QueryAccessor##CType2 *CName2; \
@property(nonatomic, strong) TableName##QueryAccessor##CType3 *CName3; \
@property(nonatomic, strong) TableName##QueryAccessor##CType4 *CName4; \
-(TableName##_##Query *)group; \
-(TableName##_##Query *)or; \
-(TableName##_##Query *)endgroup; \
-(TableName##_##Query *)subtable:(size_t)column; \
-(TableName##_##Query *)parent; \
@end \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy##CType4 *CName4; \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4; \
-(void)insert##CName1:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4; \
-(TableName##_##Query *)getQuery; \
@end

#undef TDB_TABLE_5
#define TDB_TABLE_5(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5) \
@class TableName##_##Query; \
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
@interface TableName##_##Query : OCQuery \
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
@end \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy##CType4 *CName4; \
@property(nonatomic, strong) OCColumnProxy##CType5 *CName5; \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5; \
-(void)insert##CName1:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5; \
-(TableName##_##Query *)getQuery; \
@end

#undef TDB_TABLE_6
#define TDB_TABLE_6(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6) \
@class TableName##_##Query; \
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
@interface TableName##_##Query : OCQuery \
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
@end \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy##CType4 *CName4; \
@property(nonatomic, strong) OCColumnProxy##CType5 *CName5; \
@property(nonatomic, strong) OCColumnProxy##CType6 *CName6; \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6; \
-(void)insert##CName1:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6; \
-(TableName##_##Query *)getQuery; \
@end

#undef TDB_TABLE_7
#define TDB_TABLE_7(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7) \
@class TableName##_##Query; \
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
@interface TableName##_##Query : OCQuery \
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
-(void)insert##CName1:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7; \
-(TableName##_##Query *)getQuery; \
@end

#undef TDB_TABLE_8
#define TDB_TABLE_8(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8) \
@class TableName##_##Query; \
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
@interface TableName##_##Query : OCQuery \
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
-(void)insert##CName1:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4 CName5:(tdbOCType##CType5)CName5 CName6:(tdbOCType##CType6)CName6 CName7:(tdbOCType##CType7)CName7 CName8:(tdbOCType##CType8)CName8; \
-(TableName##_##Query *)getQuery; \
@end


#endif
