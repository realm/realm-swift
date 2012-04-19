//
//  TightDb.h
//  TightDB
//

#import "OCTable.h"
#import "OCQuery.h"

#ifdef TIGHT_IMPL
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
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 \
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

#undef TDB_TABLE_4
#define TDB_TABLE_4(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4) \
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
@end 


#else


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
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2; \
-(TableName##_##Query *)getQuery; \
@end 

#undef TDB_TABLE_4
#define TDB_TABLE_4(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4) \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy##CType4 *CName4; \
-(void)add##CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4; \
-(void)insertAtIndex:(size_t)ndx CName1:(tdbOCType##CType1)CName1 CName2:(tdbOCType##CType2)CName2 CName3:(tdbOCType##CType3)CName3 CName4:(tdbOCType##CType4)CName4; \
@end 


#endif

