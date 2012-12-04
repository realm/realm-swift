/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2012] TightDB Inc
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of TightDB Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to TightDB Incorporated
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from TightDB Incorporated.
 *
 **************************************************************************/

#import <tightdb/objc/table.h>
#import <tightdb/objc/query.h>
#import <tightdb/objc/cursor.h>
#import <tightdb/objc/helper_macros.h>


#define TIGHTDB_TABLE_DEF_1(TableName, CName1, CType1) \
@interface TableName##_Cursor : CursorBase \
TIGHTDB_CURSOR_PROPERTY_DEF(CName1, CType1) \
@end \
@class TableName##_Query; \
@class TableName##_View; \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName1, CType1) \
@interface TableName##_Query : Query \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName1 *CName1; \
-(TableName##_Query *)group; \
-(TableName##_Query *)or; \
-(TableName##_Query *)endgroup; \
-(TableName##_Query *)subtable:(size_t)column; \
-(TableName##_Query *)parent; \
-(TableName##_View *)findAll; \
@end \
@interface OCColumnProxy_##TableName : OCColumnProxy \
-(size_t)find:(NSString*)value; \
@end \
@interface TableName : Table \
@property(nonatomic, strong) OCColumnProxy_##CType1 *CName1; \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1; \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1; \
-(TableName##_Query *)getQuery; \
-(TableName##_Cursor *)add; \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_Cursor *)lastObject; \
@end \
typedef TableName* TIGHTDB_TYPE_##TableName; \
@interface TableName##_View : TableView \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
@end

#define TIGHTDB_TABLE_IMPL_1(TableName, CName1, CType1) \
@implementation TableName##_Cursor \
{ \
    OCAccessor *_##CName1; \
} \
-(id)initWithTable:(Table *)table ndx:(size_t)ndx \
{ \
    self = [super initWithTable:table ndx:ndx]; \
    if (self) { \
        _##CName1 = [[OCAccessor alloc] initWithCursor:self columnId:0]; \
    } \
    return self; \
} \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName1, CType1) \
@end \
@implementation TableName##_Query \
{ \
    TableName##_Cursor *tmpCursor; \
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
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
} \
@synthesize CName1 = _CName1; \
-(id)initWithTable:(Table *)table \
{ \
    self = [super initWithTable:table]; \
    if (self) { \
        _CName1 = [[TableName##_QueryAccessor_##CName1 alloc] initWithColumn:0 query:self]; \
    } \
    return self; \
} \
-(TableName##_Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_View *)findAll \
{ \
    return [[TableName##_View alloc] initFromQuery:self]; \
} \
@end \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName1, CType1) \
@implementation OCColumnProxy_##TableName \
-(size_t)find:(NSString *)value \
{ \
    return [self.table findString:self.column value:value]; \
} \
@end \
@implementation TableName \
{ \
    TableName##_Cursor *tmpCursor; \
} \
@synthesize CName1 = _##CName1; \
\
-(id)_initRaw \
{ \
    self = [super _initRaw]; \
    if (!self) return nil; \
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (!self) return nil; \
    if (![self _addColumns]) return nil; \
\
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    return self; \
} \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 \
{ \
    const size_t ndx = [self count]; \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 \
{ \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    [self insertDone]; \
} \
-(TableName##_Query *)getQuery \
{ \
    return [[TableName##_Query alloc] initWithTable:self]; \
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
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:self ndx:0]; \
} \
+(BOOL)_checkType:(OCSpec *)spec \
{ \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 0, CName1, CType1) \
    return YES; \
} \
-(BOOL)_checkType \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _checkType:spec]) return NO; \
    return YES; \
} \
+(BOOL)_addColumns:(OCSpec *)spec \
{ \
    TIGHTDB_ADD_COLUMN(spec, CName1, CType1) \
    return YES; \
} \
-(BOOL)_addColumns \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _addColumns:spec]) return NO; \
    [self updateFromSpec]; \
    return YES; \
} \
@end \
@implementation TableName##_View \
{ \
    TableName##_Cursor *tmpCursor; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
} \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
} \
@end

#define TIGHTDB_TABLE_1(TableName, CType1, CName1) \
TIGHTDB_TABLE_DEF_1(TableName, CType1, CName1) \
TIGHTDB_TABLE_IMPL_1(TableName, CType1, CName1)


#define TIGHTDB_TABLE_DEF_2(TableName, CName1, CType1, CName2, CType2) \
@interface TableName##_Cursor : CursorBase \
TIGHTDB_CURSOR_PROPERTY_DEF(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName2, CType2) \
@end \
@class TableName##_Query; \
@class TableName##_View; \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName2, CType2) \
@interface TableName##_Query : Query \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName1 *CName1; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName2 *CName2; \
-(TableName##_Query *)group; \
-(TableName##_Query *)or; \
-(TableName##_Query *)endgroup; \
-(TableName##_Query *)subtable:(size_t)column; \
-(TableName##_Query *)parent; \
-(TableName##_View *)findAll; \
@end \
@interface OCColumnProxy_##TableName : OCColumnProxy \
-(size_t)find:(NSString*)value; \
@end \
@interface TableName : Table \
@property(nonatomic, strong) OCColumnProxy_##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy_##CType2 *CName2; \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2; \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2; \
-(TableName##_Query *)getQuery; \
-(TableName##_Cursor *)add; \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_Cursor *)lastObject; \
@end \
typedef TableName* TIGHTDB_TYPE_##TableName; \
@interface TableName##_View : TableView \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
@end

#define TIGHTDB_TABLE_IMPL_2(TableName, CName1, CType1, CName2, CType2) \
@implementation TableName##_Cursor \
{ \
    OCAccessor *_##CName1; \
    OCAccessor *_##CName2; \
} \
-(id)initWithTable:(Table *)table ndx:(size_t)ndx \
{ \
    self = [super initWithTable:table ndx:ndx]; \
    if (self) { \
        _##CName1 = [[OCAccessor alloc] initWithCursor:self columnId:0]; \
        _##CName2 = [[OCAccessor alloc] initWithCursor:self columnId:1]; \
    } \
    return self; \
} \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName2, CType2) \
@end \
@implementation TableName##_Query \
{ \
    TableName##_Cursor *tmpCursor; \
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
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
} \
@synthesize CName1 = _CName1; \
@synthesize CName2 = _CName2; \
-(id)initWithTable:(Table *)table \
{ \
    self = [super initWithTable:table]; \
    if (self) { \
        _CName1 = [[TableName##_QueryAccessor_##CName1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##_QueryAccessor_##CName2 alloc] initWithColumn:1 query:self]; \
    } \
    return self; \
} \
-(TableName##_Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_View *)findAll \
{ \
    return [[TableName##_View alloc] initFromQuery:self]; \
} \
@end \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName2, CType2) \
@implementation OCColumnProxy_##TableName \
-(size_t)find:(NSString *)value \
{ \
    return [self.table findString:self.column value:value]; \
} \
@end \
@implementation TableName \
{ \
    TableName##_Cursor *tmpCursor; \
} \
@synthesize CName1 = _##CName1; \
@synthesize CName2 = _##CName2; \
\
-(id)_initRaw \
{ \
    self = [super _initRaw]; \
    if (!self) return nil; \
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (!self) return nil; \
    if (![self _addColumns]) return nil; \
\
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    return self; \
} \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 \
{ \
    const size_t ndx = [self count]; \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 \
{ \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    [self insertDone]; \
} \
-(TableName##_Query *)getQuery \
{ \
    return [[TableName##_Query alloc] initWithTable:self]; \
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
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:self ndx:0]; \
} \
+(BOOL)_checkType:(OCSpec *)spec \
{ \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 0, CName1, CType1) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 1, CName2, CType2) \
    return YES; \
} \
-(BOOL)_checkType \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _checkType:spec]) return NO; \
    return YES; \
} \
+(BOOL)_addColumns:(OCSpec *)spec \
{ \
    TIGHTDB_ADD_COLUMN(spec, CName1, CType1) \
    TIGHTDB_ADD_COLUMN(spec, CName2, CType2) \
    return YES; \
} \
-(BOOL)_addColumns \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _addColumns:spec]) return NO; \
    [self updateFromSpec]; \
    return YES; \
} \
@end \
@implementation TableName##_View \
{ \
    TableName##_Cursor *tmpCursor; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
} \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
} \
@end

#define TIGHTDB_TABLE_2(TableName, CType1, CName1, CType2, CName2) \
TIGHTDB_TABLE_DEF_2(TableName, CType1, CName1, CType2, CName2) \
TIGHTDB_TABLE_IMPL_2(TableName, CType1, CName1, CType2, CName2)


#define TIGHTDB_TABLE_DEF_3(TableName, CName1, CType1, CName2, CType2, CName3, CType3) \
@interface TableName##_Cursor : CursorBase \
TIGHTDB_CURSOR_PROPERTY_DEF(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName2, CType2) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName3, CType3) \
@end \
@class TableName##_Query; \
@class TableName##_View; \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName2, CType2) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName3, CType3) \
@interface TableName##_Query : Query \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName1 *CName1; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName2 *CName2; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName3 *CName3; \
-(TableName##_Query *)group; \
-(TableName##_Query *)or; \
-(TableName##_Query *)endgroup; \
-(TableName##_Query *)subtable:(size_t)column; \
-(TableName##_Query *)parent; \
-(TableName##_View *)findAll; \
@end \
@interface OCColumnProxy_##TableName : OCColumnProxy \
-(size_t)find:(NSString*)value; \
@end \
@interface TableName : Table \
@property(nonatomic, strong) OCColumnProxy_##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy_##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy_##CType3 *CName3; \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3; \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3; \
-(TableName##_Query *)getQuery; \
-(TableName##_Cursor *)add; \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_Cursor *)lastObject; \
@end \
typedef TableName* TIGHTDB_TYPE_##TableName; \
@interface TableName##_View : TableView \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
@end

#define TIGHTDB_TABLE_IMPL_3(TableName, CName1, CType1, CName2, CType2, CName3, CType3) \
@implementation TableName##_Cursor \
{ \
    OCAccessor *_##CName1; \
    OCAccessor *_##CName2; \
    OCAccessor *_##CName3; \
} \
-(id)initWithTable:(Table *)table ndx:(size_t)ndx \
{ \
    self = [super initWithTable:table ndx:ndx]; \
    if (self) { \
        _##CName1 = [[OCAccessor alloc] initWithCursor:self columnId:0]; \
        _##CName2 = [[OCAccessor alloc] initWithCursor:self columnId:1]; \
        _##CName3 = [[OCAccessor alloc] initWithCursor:self columnId:2]; \
    } \
    return self; \
} \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName2, CType2) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName3, CType3) \
@end \
@implementation TableName##_Query \
{ \
    TableName##_Cursor *tmpCursor; \
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
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
} \
@synthesize CName1 = _CName1; \
@synthesize CName2 = _CName2; \
@synthesize CName3 = _CName3; \
-(id)initWithTable:(Table *)table \
{ \
    self = [super initWithTable:table]; \
    if (self) { \
        _CName1 = [[TableName##_QueryAccessor_##CName1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##_QueryAccessor_##CName2 alloc] initWithColumn:1 query:self]; \
        _CName3 = [[TableName##_QueryAccessor_##CName3 alloc] initWithColumn:2 query:self]; \
    } \
    return self; \
} \
-(TableName##_Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_View *)findAll \
{ \
    return [[TableName##_View alloc] initFromQuery:self]; \
} \
@end \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName2, CType2) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName3, CType3) \
@implementation OCColumnProxy_##TableName \
-(size_t)find:(NSString *)value \
{ \
    return [self.table findString:self.column value:value]; \
} \
@end \
@implementation TableName \
{ \
    TableName##_Cursor *tmpCursor; \
} \
@synthesize CName1 = _##CName1; \
@synthesize CName2 = _##CName2; \
@synthesize CName3 = _##CName3; \
\
-(id)_initRaw \
{ \
    self = [super _initRaw]; \
    if (!self) return nil; \
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    _##CName3 = [[OCColumnProxy_##CType3 alloc] initWithTable:self column:2]; \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (!self) return nil; \
    if (![self _addColumns]) return nil; \
\
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    _##CName3 = [[OCColumnProxy_##CType3 alloc] initWithTable:self column:2]; \
    return self; \
} \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 \
{ \
    const size_t ndx = [self count]; \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    TIGHTDB_COLUMN_INSERT(self, 2, ndx, CName3, CType3); \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 \
{ \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    TIGHTDB_COLUMN_INSERT(self, 2, ndx, CName3, CType3); \
    [self insertDone]; \
} \
-(TableName##_Query *)getQuery \
{ \
    return [[TableName##_Query alloc] initWithTable:self]; \
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
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:self ndx:0]; \
} \
+(BOOL)_checkType:(OCSpec *)spec \
{ \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 0, CName1, CType1) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 1, CName2, CType2) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 2, CName3, CType3) \
    return YES; \
} \
-(BOOL)_checkType \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _checkType:spec]) return NO; \
    return YES; \
} \
+(BOOL)_addColumns:(OCSpec *)spec \
{ \
    TIGHTDB_ADD_COLUMN(spec, CName1, CType1) \
    TIGHTDB_ADD_COLUMN(spec, CName2, CType2) \
    TIGHTDB_ADD_COLUMN(spec, CName3, CType3) \
    return YES; \
} \
-(BOOL)_addColumns \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _addColumns:spec]) return NO; \
    [self updateFromSpec]; \
    return YES; \
} \
@end \
@implementation TableName##_View \
{ \
    TableName##_Cursor *tmpCursor; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
} \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
} \
@end

#define TIGHTDB_TABLE_3(TableName, CType1, CName1, CType2, CName2, CType3, CName3) \
TIGHTDB_TABLE_DEF_3(TableName, CType1, CName1, CType2, CName2, CType3, CName3) \
TIGHTDB_TABLE_IMPL_3(TableName, CType1, CName1, CType2, CName2, CType3, CName3)


#define TIGHTDB_TABLE_DEF_4(TableName, CName1, CType1, CName2, CType2, CName3, CType3, CName4, CType4) \
@interface TableName##_Cursor : CursorBase \
TIGHTDB_CURSOR_PROPERTY_DEF(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName2, CType2) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName3, CType3) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName4, CType4) \
@end \
@class TableName##_Query; \
@class TableName##_View; \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName2, CType2) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName3, CType3) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName4, CType4) \
@interface TableName##_Query : Query \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName1 *CName1; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName2 *CName2; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName3 *CName3; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName4 *CName4; \
-(TableName##_Query *)group; \
-(TableName##_Query *)or; \
-(TableName##_Query *)endgroup; \
-(TableName##_Query *)subtable:(size_t)column; \
-(TableName##_Query *)parent; \
-(TableName##_View *)findAll; \
@end \
@interface OCColumnProxy_##TableName : OCColumnProxy \
-(size_t)find:(NSString*)value; \
@end \
@interface TableName : Table \
@property(nonatomic, strong) OCColumnProxy_##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy_##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy_##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy_##CType4 *CName4; \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4; \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4; \
-(TableName##_Query *)getQuery; \
-(TableName##_Cursor *)add; \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_Cursor *)lastObject; \
@end \
typedef TableName* TIGHTDB_TYPE_##TableName; \
@interface TableName##_View : TableView \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
@end

#define TIGHTDB_TABLE_IMPL_4(TableName, CName1, CType1, CName2, CType2, CName3, CType3, CName4, CType4) \
@implementation TableName##_Cursor \
{ \
    OCAccessor *_##CName1; \
    OCAccessor *_##CName2; \
    OCAccessor *_##CName3; \
    OCAccessor *_##CName4; \
} \
-(id)initWithTable:(Table *)table ndx:(size_t)ndx \
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
TIGHTDB_CURSOR_PROPERTY_IMPL(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName2, CType2) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName3, CType3) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName4, CType4) \
@end \
@implementation TableName##_Query \
{ \
    TableName##_Cursor *tmpCursor; \
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
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
} \
@synthesize CName1 = _CName1; \
@synthesize CName2 = _CName2; \
@synthesize CName3 = _CName3; \
@synthesize CName4 = _CName4; \
-(id)initWithTable:(Table *)table \
{ \
    self = [super initWithTable:table]; \
    if (self) { \
        _CName1 = [[TableName##_QueryAccessor_##CName1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##_QueryAccessor_##CName2 alloc] initWithColumn:1 query:self]; \
        _CName3 = [[TableName##_QueryAccessor_##CName3 alloc] initWithColumn:2 query:self]; \
        _CName4 = [[TableName##_QueryAccessor_##CName4 alloc] initWithColumn:3 query:self]; \
    } \
    return self; \
} \
-(TableName##_Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_View *)findAll \
{ \
    return [[TableName##_View alloc] initFromQuery:self]; \
} \
@end \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName2, CType2) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName3, CType3) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName4, CType4) \
@implementation OCColumnProxy_##TableName \
-(size_t)find:(NSString *)value \
{ \
    return [self.table findString:self.column value:value]; \
} \
@end \
@implementation TableName \
{ \
    TableName##_Cursor *tmpCursor; \
} \
@synthesize CName1 = _##CName1; \
@synthesize CName2 = _##CName2; \
@synthesize CName3 = _##CName3; \
@synthesize CName4 = _##CName4; \
\
-(id)_initRaw \
{ \
    self = [super _initRaw]; \
    if (!self) return nil; \
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    _##CName3 = [[OCColumnProxy_##CType3 alloc] initWithTable:self column:2]; \
    _##CName4 = [[OCColumnProxy_##CType4 alloc] initWithTable:self column:3]; \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (!self) return nil; \
    if (![self _addColumns]) return nil; \
\
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    _##CName3 = [[OCColumnProxy_##CType3 alloc] initWithTable:self column:2]; \
    _##CName4 = [[OCColumnProxy_##CType4 alloc] initWithTable:self column:3]; \
    return self; \
} \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 \
{ \
    const size_t ndx = [self count]; \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    TIGHTDB_COLUMN_INSERT(self, 2, ndx, CName3, CType3); \
    TIGHTDB_COLUMN_INSERT(self, 3, ndx, CName4, CType4); \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 \
{ \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    TIGHTDB_COLUMN_INSERT(self, 2, ndx, CName3, CType3); \
    TIGHTDB_COLUMN_INSERT(self, 3, ndx, CName4, CType4); \
    [self insertDone]; \
} \
-(TableName##_Query *)getQuery \
{ \
    return [[TableName##_Query alloc] initWithTable:self]; \
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
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:self ndx:0]; \
} \
+(BOOL)_checkType:(OCSpec *)spec \
{ \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 0, CName1, CType1) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 1, CName2, CType2) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 2, CName3, CType3) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 3, CName4, CType4) \
    return YES; \
} \
-(BOOL)_checkType \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _checkType:spec]) return NO; \
    return YES; \
} \
+(BOOL)_addColumns:(OCSpec *)spec \
{ \
    TIGHTDB_ADD_COLUMN(spec, CName1, CType1) \
    TIGHTDB_ADD_COLUMN(spec, CName2, CType2) \
    TIGHTDB_ADD_COLUMN(spec, CName3, CType3) \
    TIGHTDB_ADD_COLUMN(spec, CName4, CType4) \
    return YES; \
} \
-(BOOL)_addColumns \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _addColumns:spec]) return NO; \
    [self updateFromSpec]; \
    return YES; \
} \
@end \
@implementation TableName##_View \
{ \
    TableName##_Cursor *tmpCursor; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
} \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
} \
@end

#define TIGHTDB_TABLE_4(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4) \
TIGHTDB_TABLE_DEF_4(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4) \
TIGHTDB_TABLE_IMPL_4(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4)


#define TIGHTDB_TABLE_DEF_5(TableName, CName1, CType1, CName2, CType2, CName3, CType3, CName4, CType4, CName5, CType5) \
@interface TableName##_Cursor : CursorBase \
TIGHTDB_CURSOR_PROPERTY_DEF(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName2, CType2) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName3, CType3) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName4, CType4) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName5, CType5) \
@end \
@class TableName##_Query; \
@class TableName##_View; \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName2, CType2) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName3, CType3) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName4, CType4) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName5, CType5) \
@interface TableName##_Query : Query \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName1 *CName1; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName2 *CName2; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName3 *CName3; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName4 *CName4; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName5 *CName5; \
-(TableName##_Query *)group; \
-(TableName##_Query *)or; \
-(TableName##_Query *)endgroup; \
-(TableName##_Query *)subtable:(size_t)column; \
-(TableName##_Query *)parent; \
-(TableName##_View *)findAll; \
@end \
@interface OCColumnProxy_##TableName : OCColumnProxy \
-(size_t)find:(NSString*)value; \
@end \
@interface TableName : Table \
@property(nonatomic, strong) OCColumnProxy_##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy_##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy_##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy_##CType4 *CName4; \
@property(nonatomic, strong) OCColumnProxy_##CType5 *CName5; \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5; \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5; \
-(TableName##_Query *)getQuery; \
-(TableName##_Cursor *)add; \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_Cursor *)lastObject; \
@end \
typedef TableName* TIGHTDB_TYPE_##TableName; \
@interface TableName##_View : TableView \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
@end

#define TIGHTDB_TABLE_IMPL_5(TableName, CName1, CType1, CName2, CType2, CName3, CType3, CName4, CType4, CName5, CType5) \
@implementation TableName##_Cursor \
{ \
    OCAccessor *_##CName1; \
    OCAccessor *_##CName2; \
    OCAccessor *_##CName3; \
    OCAccessor *_##CName4; \
    OCAccessor *_##CName5; \
} \
-(id)initWithTable:(Table *)table ndx:(size_t)ndx \
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
TIGHTDB_CURSOR_PROPERTY_IMPL(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName2, CType2) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName3, CType3) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName4, CType4) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName5, CType5) \
@end \
@implementation TableName##_Query \
{ \
    TableName##_Cursor *tmpCursor; \
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
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
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
        _CName1 = [[TableName##_QueryAccessor_##CName1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##_QueryAccessor_##CName2 alloc] initWithColumn:1 query:self]; \
        _CName3 = [[TableName##_QueryAccessor_##CName3 alloc] initWithColumn:2 query:self]; \
        _CName4 = [[TableName##_QueryAccessor_##CName4 alloc] initWithColumn:3 query:self]; \
        _CName5 = [[TableName##_QueryAccessor_##CName5 alloc] initWithColumn:4 query:self]; \
    } \
    return self; \
} \
-(TableName##_Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_View *)findAll \
{ \
    return [[TableName##_View alloc] initFromQuery:self]; \
} \
@end \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName2, CType2) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName3, CType3) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName4, CType4) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName5, CType5) \
@implementation OCColumnProxy_##TableName \
-(size_t)find:(NSString *)value \
{ \
    return [self.table findString:self.column value:value]; \
} \
@end \
@implementation TableName \
{ \
    TableName##_Cursor *tmpCursor; \
} \
@synthesize CName1 = _##CName1; \
@synthesize CName2 = _##CName2; \
@synthesize CName3 = _##CName3; \
@synthesize CName4 = _##CName4; \
@synthesize CName5 = _##CName5; \
\
-(id)_initRaw \
{ \
    self = [super _initRaw]; \
    if (!self) return nil; \
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    _##CName3 = [[OCColumnProxy_##CType3 alloc] initWithTable:self column:2]; \
    _##CName4 = [[OCColumnProxy_##CType4 alloc] initWithTable:self column:3]; \
    _##CName5 = [[OCColumnProxy_##CType5 alloc] initWithTable:self column:4]; \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (!self) return nil; \
    if (![self _addColumns]) return nil; \
\
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    _##CName3 = [[OCColumnProxy_##CType3 alloc] initWithTable:self column:2]; \
    _##CName4 = [[OCColumnProxy_##CType4 alloc] initWithTable:self column:3]; \
    _##CName5 = [[OCColumnProxy_##CType5 alloc] initWithTable:self column:4]; \
    return self; \
} \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 \
{ \
    const size_t ndx = [self count]; \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    TIGHTDB_COLUMN_INSERT(self, 2, ndx, CName3, CType3); \
    TIGHTDB_COLUMN_INSERT(self, 3, ndx, CName4, CType4); \
    TIGHTDB_COLUMN_INSERT(self, 4, ndx, CName5, CType5); \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 \
{ \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    TIGHTDB_COLUMN_INSERT(self, 2, ndx, CName3, CType3); \
    TIGHTDB_COLUMN_INSERT(self, 3, ndx, CName4, CType4); \
    TIGHTDB_COLUMN_INSERT(self, 4, ndx, CName5, CType5); \
    [self insertDone]; \
} \
-(TableName##_Query *)getQuery \
{ \
    return [[TableName##_Query alloc] initWithTable:self]; \
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
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:self ndx:0]; \
} \
+(BOOL)_checkType:(OCSpec *)spec \
{ \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 0, CName1, CType1) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 1, CName2, CType2) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 2, CName3, CType3) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 3, CName4, CType4) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 4, CName5, CType5) \
    return YES; \
} \
-(BOOL)_checkType \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _checkType:spec]) return NO; \
    return YES; \
} \
+(BOOL)_addColumns:(OCSpec *)spec \
{ \
    TIGHTDB_ADD_COLUMN(spec, CName1, CType1) \
    TIGHTDB_ADD_COLUMN(spec, CName2, CType2) \
    TIGHTDB_ADD_COLUMN(spec, CName3, CType3) \
    TIGHTDB_ADD_COLUMN(spec, CName4, CType4) \
    TIGHTDB_ADD_COLUMN(spec, CName5, CType5) \
    return YES; \
} \
-(BOOL)_addColumns \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _addColumns:spec]) return NO; \
    [self updateFromSpec]; \
    return YES; \
} \
@end \
@implementation TableName##_View \
{ \
    TableName##_Cursor *tmpCursor; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
} \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
} \
@end

#define TIGHTDB_TABLE_5(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5) \
TIGHTDB_TABLE_DEF_5(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5) \
TIGHTDB_TABLE_IMPL_5(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5)


#define TIGHTDB_TABLE_DEF_6(TableName, CName1, CType1, CName2, CType2, CName3, CType3, CName4, CType4, CName5, CType5, CName6, CType6) \
@interface TableName##_Cursor : CursorBase \
TIGHTDB_CURSOR_PROPERTY_DEF(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName2, CType2) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName3, CType3) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName4, CType4) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName5, CType5) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName6, CType6) \
@end \
@class TableName##_Query; \
@class TableName##_View; \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName2, CType2) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName3, CType3) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName4, CType4) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName5, CType5) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName6, CType6) \
@interface TableName##_Query : Query \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName1 *CName1; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName2 *CName2; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName3 *CName3; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName4 *CName4; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName5 *CName5; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName6 *CName6; \
-(TableName##_Query *)group; \
-(TableName##_Query *)or; \
-(TableName##_Query *)endgroup; \
-(TableName##_Query *)subtable:(size_t)column; \
-(TableName##_Query *)parent; \
-(TableName##_View *)findAll; \
@end \
@interface OCColumnProxy_##TableName : OCColumnProxy \
-(size_t)find:(NSString*)value; \
@end \
@interface TableName : Table \
@property(nonatomic, strong) OCColumnProxy_##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy_##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy_##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy_##CType4 *CName4; \
@property(nonatomic, strong) OCColumnProxy_##CType5 *CName5; \
@property(nonatomic, strong) OCColumnProxy_##CType6 *CName6; \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6; \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6; \
-(TableName##_Query *)getQuery; \
-(TableName##_Cursor *)add; \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_Cursor *)lastObject; \
@end \
typedef TableName* TIGHTDB_TYPE_##TableName; \
@interface TableName##_View : TableView \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
@end

#define TIGHTDB_TABLE_IMPL_6(TableName, CName1, CType1, CName2, CType2, CName3, CType3, CName4, CType4, CName5, CType5, CName6, CType6) \
@implementation TableName##_Cursor \
{ \
    OCAccessor *_##CName1; \
    OCAccessor *_##CName2; \
    OCAccessor *_##CName3; \
    OCAccessor *_##CName4; \
    OCAccessor *_##CName5; \
    OCAccessor *_##CName6; \
} \
-(id)initWithTable:(Table *)table ndx:(size_t)ndx \
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
TIGHTDB_CURSOR_PROPERTY_IMPL(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName2, CType2) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName3, CType3) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName4, CType4) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName5, CType5) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName6, CType6) \
@end \
@implementation TableName##_Query \
{ \
    TableName##_Cursor *tmpCursor; \
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
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
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
        _CName1 = [[TableName##_QueryAccessor_##CName1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##_QueryAccessor_##CName2 alloc] initWithColumn:1 query:self]; \
        _CName3 = [[TableName##_QueryAccessor_##CName3 alloc] initWithColumn:2 query:self]; \
        _CName4 = [[TableName##_QueryAccessor_##CName4 alloc] initWithColumn:3 query:self]; \
        _CName5 = [[TableName##_QueryAccessor_##CName5 alloc] initWithColumn:4 query:self]; \
        _CName6 = [[TableName##_QueryAccessor_##CName6 alloc] initWithColumn:5 query:self]; \
    } \
    return self; \
} \
-(TableName##_Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_View *)findAll \
{ \
    return [[TableName##_View alloc] initFromQuery:self]; \
} \
@end \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName2, CType2) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName3, CType3) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName4, CType4) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName5, CType5) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName6, CType6) \
@implementation OCColumnProxy_##TableName \
-(size_t)find:(NSString *)value \
{ \
    return [self.table findString:self.column value:value]; \
} \
@end \
@implementation TableName \
{ \
    TableName##_Cursor *tmpCursor; \
} \
@synthesize CName1 = _##CName1; \
@synthesize CName2 = _##CName2; \
@synthesize CName3 = _##CName3; \
@synthesize CName4 = _##CName4; \
@synthesize CName5 = _##CName5; \
@synthesize CName6 = _##CName6; \
\
-(id)_initRaw \
{ \
    self = [super _initRaw]; \
    if (!self) return nil; \
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    _##CName3 = [[OCColumnProxy_##CType3 alloc] initWithTable:self column:2]; \
    _##CName4 = [[OCColumnProxy_##CType4 alloc] initWithTable:self column:3]; \
    _##CName5 = [[OCColumnProxy_##CType5 alloc] initWithTable:self column:4]; \
    _##CName6 = [[OCColumnProxy_##CType6 alloc] initWithTable:self column:5]; \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (!self) return nil; \
    if (![self _addColumns]) return nil; \
\
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    _##CName3 = [[OCColumnProxy_##CType3 alloc] initWithTable:self column:2]; \
    _##CName4 = [[OCColumnProxy_##CType4 alloc] initWithTable:self column:3]; \
    _##CName5 = [[OCColumnProxy_##CType5 alloc] initWithTable:self column:4]; \
    _##CName6 = [[OCColumnProxy_##CType6 alloc] initWithTable:self column:5]; \
    return self; \
} \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 \
{ \
    const size_t ndx = [self count]; \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    TIGHTDB_COLUMN_INSERT(self, 2, ndx, CName3, CType3); \
    TIGHTDB_COLUMN_INSERT(self, 3, ndx, CName4, CType4); \
    TIGHTDB_COLUMN_INSERT(self, 4, ndx, CName5, CType5); \
    TIGHTDB_COLUMN_INSERT(self, 5, ndx, CName6, CType6); \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 \
{ \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    TIGHTDB_COLUMN_INSERT(self, 2, ndx, CName3, CType3); \
    TIGHTDB_COLUMN_INSERT(self, 3, ndx, CName4, CType4); \
    TIGHTDB_COLUMN_INSERT(self, 4, ndx, CName5, CType5); \
    TIGHTDB_COLUMN_INSERT(self, 5, ndx, CName6, CType6); \
    [self insertDone]; \
} \
-(TableName##_Query *)getQuery \
{ \
    return [[TableName##_Query alloc] initWithTable:self]; \
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
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:self ndx:0]; \
} \
+(BOOL)_checkType:(OCSpec *)spec \
{ \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 0, CName1, CType1) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 1, CName2, CType2) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 2, CName3, CType3) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 3, CName4, CType4) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 4, CName5, CType5) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 5, CName6, CType6) \
    return YES; \
} \
-(BOOL)_checkType \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _checkType:spec]) return NO; \
    return YES; \
} \
+(BOOL)_addColumns:(OCSpec *)spec \
{ \
    TIGHTDB_ADD_COLUMN(spec, CName1, CType1) \
    TIGHTDB_ADD_COLUMN(spec, CName2, CType2) \
    TIGHTDB_ADD_COLUMN(spec, CName3, CType3) \
    TIGHTDB_ADD_COLUMN(spec, CName4, CType4) \
    TIGHTDB_ADD_COLUMN(spec, CName5, CType5) \
    TIGHTDB_ADD_COLUMN(spec, CName6, CType6) \
    return YES; \
} \
-(BOOL)_addColumns \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _addColumns:spec]) return NO; \
    [self updateFromSpec]; \
    return YES; \
} \
@end \
@implementation TableName##_View \
{ \
    TableName##_Cursor *tmpCursor; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
} \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
} \
@end

#define TIGHTDB_TABLE_6(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6) \
TIGHTDB_TABLE_DEF_6(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6) \
TIGHTDB_TABLE_IMPL_6(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6)


#define TIGHTDB_TABLE_DEF_7(TableName, CName1, CType1, CName2, CType2, CName3, CType3, CName4, CType4, CName5, CType5, CName6, CType6, CName7, CType7) \
@interface TableName##_Cursor : CursorBase \
TIGHTDB_CURSOR_PROPERTY_DEF(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName2, CType2) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName3, CType3) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName4, CType4) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName5, CType5) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName6, CType6) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName7, CType7) \
@end \
@class TableName##_Query; \
@class TableName##_View; \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName2, CType2) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName3, CType3) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName4, CType4) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName5, CType5) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName6, CType6) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName7, CType7) \
@interface TableName##_Query : Query \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName1 *CName1; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName2 *CName2; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName3 *CName3; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName4 *CName4; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName5 *CName5; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName6 *CName6; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName7 *CName7; \
-(TableName##_Query *)group; \
-(TableName##_Query *)or; \
-(TableName##_Query *)endgroup; \
-(TableName##_Query *)subtable:(size_t)column; \
-(TableName##_Query *)parent; \
-(TableName##_View *)findAll; \
@end \
@interface OCColumnProxy_##TableName : OCColumnProxy \
-(size_t)find:(NSString*)value; \
@end \
@interface TableName : Table \
@property(nonatomic, strong) OCColumnProxy_##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy_##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy_##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy_##CType4 *CName4; \
@property(nonatomic, strong) OCColumnProxy_##CType5 *CName5; \
@property(nonatomic, strong) OCColumnProxy_##CType6 *CName6; \
@property(nonatomic, strong) OCColumnProxy_##CType7 *CName7; \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7; \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7; \
-(TableName##_Query *)getQuery; \
-(TableName##_Cursor *)add; \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_Cursor *)lastObject; \
@end \
typedef TableName* TIGHTDB_TYPE_##TableName; \
@interface TableName##_View : TableView \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
@end

#define TIGHTDB_TABLE_IMPL_7(TableName, CName1, CType1, CName2, CType2, CName3, CType3, CName4, CType4, CName5, CType5, CName6, CType6, CName7, CType7) \
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
-(id)initWithTable:(Table *)table ndx:(size_t)ndx \
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
TIGHTDB_CURSOR_PROPERTY_IMPL(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName2, CType2) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName3, CType3) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName4, CType4) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName5, CType5) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName6, CType6) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName7, CType7) \
@end \
@implementation TableName##_Query \
{ \
    TableName##_Cursor *tmpCursor; \
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
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
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
        _CName1 = [[TableName##_QueryAccessor_##CName1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##_QueryAccessor_##CName2 alloc] initWithColumn:1 query:self]; \
        _CName3 = [[TableName##_QueryAccessor_##CName3 alloc] initWithColumn:2 query:self]; \
        _CName4 = [[TableName##_QueryAccessor_##CName4 alloc] initWithColumn:3 query:self]; \
        _CName5 = [[TableName##_QueryAccessor_##CName5 alloc] initWithColumn:4 query:self]; \
        _CName6 = [[TableName##_QueryAccessor_##CName6 alloc] initWithColumn:5 query:self]; \
        _CName7 = [[TableName##_QueryAccessor_##CName7 alloc] initWithColumn:6 query:self]; \
    } \
    return self; \
} \
-(TableName##_Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_View *)findAll \
{ \
    return [[TableName##_View alloc] initFromQuery:self]; \
} \
@end \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName2, CType2) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName3, CType3) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName4, CType4) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName5, CType5) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName6, CType6) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName7, CType7) \
@implementation OCColumnProxy_##TableName \
-(size_t)find:(NSString *)value \
{ \
    return [self.table findString:self.column value:value]; \
} \
@end \
@implementation TableName \
{ \
    TableName##_Cursor *tmpCursor; \
} \
@synthesize CName1 = _##CName1; \
@synthesize CName2 = _##CName2; \
@synthesize CName3 = _##CName3; \
@synthesize CName4 = _##CName4; \
@synthesize CName5 = _##CName5; \
@synthesize CName6 = _##CName6; \
@synthesize CName7 = _##CName7; \
\
-(id)_initRaw \
{ \
    self = [super _initRaw]; \
    if (!self) return nil; \
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    _##CName3 = [[OCColumnProxy_##CType3 alloc] initWithTable:self column:2]; \
    _##CName4 = [[OCColumnProxy_##CType4 alloc] initWithTable:self column:3]; \
    _##CName5 = [[OCColumnProxy_##CType5 alloc] initWithTable:self column:4]; \
    _##CName6 = [[OCColumnProxy_##CType6 alloc] initWithTable:self column:5]; \
    _##CName7 = [[OCColumnProxy_##CType7 alloc] initWithTable:self column:6]; \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (!self) return nil; \
    if (![self _addColumns]) return nil; \
\
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    _##CName3 = [[OCColumnProxy_##CType3 alloc] initWithTable:self column:2]; \
    _##CName4 = [[OCColumnProxy_##CType4 alloc] initWithTable:self column:3]; \
    _##CName5 = [[OCColumnProxy_##CType5 alloc] initWithTable:self column:4]; \
    _##CName6 = [[OCColumnProxy_##CType6 alloc] initWithTable:self column:5]; \
    _##CName7 = [[OCColumnProxy_##CType7 alloc] initWithTable:self column:6]; \
    return self; \
} \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 \
{ \
    const size_t ndx = [self count]; \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    TIGHTDB_COLUMN_INSERT(self, 2, ndx, CName3, CType3); \
    TIGHTDB_COLUMN_INSERT(self, 3, ndx, CName4, CType4); \
    TIGHTDB_COLUMN_INSERT(self, 4, ndx, CName5, CType5); \
    TIGHTDB_COLUMN_INSERT(self, 5, ndx, CName6, CType6); \
    TIGHTDB_COLUMN_INSERT(self, 6, ndx, CName7, CType7); \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 \
{ \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    TIGHTDB_COLUMN_INSERT(self, 2, ndx, CName3, CType3); \
    TIGHTDB_COLUMN_INSERT(self, 3, ndx, CName4, CType4); \
    TIGHTDB_COLUMN_INSERT(self, 4, ndx, CName5, CType5); \
    TIGHTDB_COLUMN_INSERT(self, 5, ndx, CName6, CType6); \
    TIGHTDB_COLUMN_INSERT(self, 6, ndx, CName7, CType7); \
    [self insertDone]; \
} \
-(TableName##_Query *)getQuery \
{ \
    return [[TableName##_Query alloc] initWithTable:self]; \
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
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:self ndx:0]; \
} \
+(BOOL)_checkType:(OCSpec *)spec \
{ \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 0, CName1, CType1) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 1, CName2, CType2) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 2, CName3, CType3) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 3, CName4, CType4) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 4, CName5, CType5) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 5, CName6, CType6) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 6, CName7, CType7) \
    return YES; \
} \
-(BOOL)_checkType \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _checkType:spec]) return NO; \
    return YES; \
} \
+(BOOL)_addColumns:(OCSpec *)spec \
{ \
    TIGHTDB_ADD_COLUMN(spec, CName1, CType1) \
    TIGHTDB_ADD_COLUMN(spec, CName2, CType2) \
    TIGHTDB_ADD_COLUMN(spec, CName3, CType3) \
    TIGHTDB_ADD_COLUMN(spec, CName4, CType4) \
    TIGHTDB_ADD_COLUMN(spec, CName5, CType5) \
    TIGHTDB_ADD_COLUMN(spec, CName6, CType6) \
    TIGHTDB_ADD_COLUMN(spec, CName7, CType7) \
    return YES; \
} \
-(BOOL)_addColumns \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _addColumns:spec]) return NO; \
    [self updateFromSpec]; \
    return YES; \
} \
@end \
@implementation TableName##_View \
{ \
    TableName##_Cursor *tmpCursor; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
} \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
} \
@end

#define TIGHTDB_TABLE_7(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7) \
TIGHTDB_TABLE_DEF_7(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7) \
TIGHTDB_TABLE_IMPL_7(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7)


#define TIGHTDB_TABLE_DEF_8(TableName, CName1, CType1, CName2, CType2, CName3, CType3, CName4, CType4, CName5, CType5, CName6, CType6, CName7, CType7, CName8, CType8) \
@interface TableName##_Cursor : CursorBase \
TIGHTDB_CURSOR_PROPERTY_DEF(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName2, CType2) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName3, CType3) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName4, CType4) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName5, CType5) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName6, CType6) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName7, CType7) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName8, CType8) \
@end \
@class TableName##_Query; \
@class TableName##_View; \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName2, CType2) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName3, CType3) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName4, CType4) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName5, CType5) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName6, CType6) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName7, CType7) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName8, CType8) \
@interface TableName##_Query : Query \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName1 *CName1; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName2 *CName2; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName3 *CName3; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName4 *CName4; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName5 *CName5; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName6 *CName6; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName7 *CName7; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName8 *CName8; \
-(TableName##_Query *)group; \
-(TableName##_Query *)or; \
-(TableName##_Query *)endgroup; \
-(TableName##_Query *)subtable:(size_t)column; \
-(TableName##_Query *)parent; \
-(TableName##_View *)findAll; \
@end \
@interface OCColumnProxy_##TableName : OCColumnProxy \
-(size_t)find:(NSString*)value; \
@end \
@interface TableName : Table \
@property(nonatomic, strong) OCColumnProxy_##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy_##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy_##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy_##CType4 *CName4; \
@property(nonatomic, strong) OCColumnProxy_##CType5 *CName5; \
@property(nonatomic, strong) OCColumnProxy_##CType6 *CName6; \
@property(nonatomic, strong) OCColumnProxy_##CType7 *CName7; \
@property(nonatomic, strong) OCColumnProxy_##CType8 *CName8; \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8; \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8; \
-(TableName##_Query *)getQuery; \
-(TableName##_Cursor *)add; \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_Cursor *)lastObject; \
@end \
typedef TableName* TIGHTDB_TYPE_##TableName; \
@interface TableName##_View : TableView \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
@end

#define TIGHTDB_TABLE_IMPL_8(TableName, CName1, CType1, CName2, CType2, CName3, CType3, CName4, CType4, CName5, CType5, CName6, CType6, CName7, CType7, CName8, CType8) \
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
-(id)initWithTable:(Table *)table ndx:(size_t)ndx \
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
TIGHTDB_CURSOR_PROPERTY_IMPL(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName2, CType2) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName3, CType3) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName4, CType4) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName5, CType5) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName6, CType6) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName7, CType7) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName8, CType8) \
@end \
@implementation TableName##_Query \
{ \
    TableName##_Cursor *tmpCursor; \
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
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
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
        _CName1 = [[TableName##_QueryAccessor_##CName1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##_QueryAccessor_##CName2 alloc] initWithColumn:1 query:self]; \
        _CName3 = [[TableName##_QueryAccessor_##CName3 alloc] initWithColumn:2 query:self]; \
        _CName4 = [[TableName##_QueryAccessor_##CName4 alloc] initWithColumn:3 query:self]; \
        _CName5 = [[TableName##_QueryAccessor_##CName5 alloc] initWithColumn:4 query:self]; \
        _CName6 = [[TableName##_QueryAccessor_##CName6 alloc] initWithColumn:5 query:self]; \
        _CName7 = [[TableName##_QueryAccessor_##CName7 alloc] initWithColumn:6 query:self]; \
        _CName8 = [[TableName##_QueryAccessor_##CName8 alloc] initWithColumn:7 query:self]; \
    } \
    return self; \
} \
-(TableName##_Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_View *)findAll \
{ \
    return [[TableName##_View alloc] initFromQuery:self]; \
} \
@end \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName2, CType2) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName3, CType3) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName4, CType4) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName5, CType5) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName6, CType6) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName7, CType7) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName8, CType8) \
@implementation OCColumnProxy_##TableName \
-(size_t)find:(NSString *)value \
{ \
    return [self.table findString:self.column value:value]; \
} \
@end \
@implementation TableName \
{ \
    TableName##_Cursor *tmpCursor; \
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
-(id)_initRaw \
{ \
    self = [super _initRaw]; \
    if (!self) return nil; \
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    _##CName3 = [[OCColumnProxy_##CType3 alloc] initWithTable:self column:2]; \
    _##CName4 = [[OCColumnProxy_##CType4 alloc] initWithTable:self column:3]; \
    _##CName5 = [[OCColumnProxy_##CType5 alloc] initWithTable:self column:4]; \
    _##CName6 = [[OCColumnProxy_##CType6 alloc] initWithTable:self column:5]; \
    _##CName7 = [[OCColumnProxy_##CType7 alloc] initWithTable:self column:6]; \
    _##CName8 = [[OCColumnProxy_##CType8 alloc] initWithTable:self column:7]; \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (!self) return nil; \
    if (![self _addColumns]) return nil; \
\
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    _##CName3 = [[OCColumnProxy_##CType3 alloc] initWithTable:self column:2]; \
    _##CName4 = [[OCColumnProxy_##CType4 alloc] initWithTable:self column:3]; \
    _##CName5 = [[OCColumnProxy_##CType5 alloc] initWithTable:self column:4]; \
    _##CName6 = [[OCColumnProxy_##CType6 alloc] initWithTable:self column:5]; \
    _##CName7 = [[OCColumnProxy_##CType7 alloc] initWithTable:self column:6]; \
    _##CName8 = [[OCColumnProxy_##CType8 alloc] initWithTable:self column:7]; \
    return self; \
} \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 \
{ \
    const size_t ndx = [self count]; \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    TIGHTDB_COLUMN_INSERT(self, 2, ndx, CName3, CType3); \
    TIGHTDB_COLUMN_INSERT(self, 3, ndx, CName4, CType4); \
    TIGHTDB_COLUMN_INSERT(self, 4, ndx, CName5, CType5); \
    TIGHTDB_COLUMN_INSERT(self, 5, ndx, CName6, CType6); \
    TIGHTDB_COLUMN_INSERT(self, 6, ndx, CName7, CType7); \
    TIGHTDB_COLUMN_INSERT(self, 7, ndx, CName8, CType8); \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 \
{ \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    TIGHTDB_COLUMN_INSERT(self, 2, ndx, CName3, CType3); \
    TIGHTDB_COLUMN_INSERT(self, 3, ndx, CName4, CType4); \
    TIGHTDB_COLUMN_INSERT(self, 4, ndx, CName5, CType5); \
    TIGHTDB_COLUMN_INSERT(self, 5, ndx, CName6, CType6); \
    TIGHTDB_COLUMN_INSERT(self, 6, ndx, CName7, CType7); \
    TIGHTDB_COLUMN_INSERT(self, 7, ndx, CName8, CType8); \
    [self insertDone]; \
} \
-(TableName##_Query *)getQuery \
{ \
    return [[TableName##_Query alloc] initWithTable:self]; \
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
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:self ndx:0]; \
} \
+(BOOL)_checkType:(OCSpec *)spec \
{ \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 0, CName1, CType1) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 1, CName2, CType2) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 2, CName3, CType3) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 3, CName4, CType4) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 4, CName5, CType5) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 5, CName6, CType6) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 6, CName7, CType7) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 7, CName8, CType8) \
    return YES; \
} \
-(BOOL)_checkType \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _checkType:spec]) return NO; \
    return YES; \
} \
+(BOOL)_addColumns:(OCSpec *)spec \
{ \
    TIGHTDB_ADD_COLUMN(spec, CName1, CType1) \
    TIGHTDB_ADD_COLUMN(spec, CName2, CType2) \
    TIGHTDB_ADD_COLUMN(spec, CName3, CType3) \
    TIGHTDB_ADD_COLUMN(spec, CName4, CType4) \
    TIGHTDB_ADD_COLUMN(spec, CName5, CType5) \
    TIGHTDB_ADD_COLUMN(spec, CName6, CType6) \
    TIGHTDB_ADD_COLUMN(spec, CName7, CType7) \
    TIGHTDB_ADD_COLUMN(spec, CName8, CType8) \
    return YES; \
} \
-(BOOL)_addColumns \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _addColumns:spec]) return NO; \
    [self updateFromSpec]; \
    return YES; \
} \
@end \
@implementation TableName##_View \
{ \
    TableName##_Cursor *tmpCursor; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
} \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
} \
@end

#define TIGHTDB_TABLE_8(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8) \
TIGHTDB_TABLE_DEF_8(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8) \
TIGHTDB_TABLE_IMPL_8(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8)


#define TIGHTDB_TABLE_DEF_9(TableName, CName1, CType1, CName2, CType2, CName3, CType3, CName4, CType4, CName5, CType5, CName6, CType6, CName7, CType7, CName8, CType8, CName9, CType9) \
@interface TableName##_Cursor : CursorBase \
TIGHTDB_CURSOR_PROPERTY_DEF(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName2, CType2) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName3, CType3) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName4, CType4) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName5, CType5) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName6, CType6) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName7, CType7) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName8, CType8) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName9, CType9) \
@end \
@class TableName##_Query; \
@class TableName##_View; \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName2, CType2) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName3, CType3) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName4, CType4) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName5, CType5) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName6, CType6) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName7, CType7) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName8, CType8) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName9, CType9) \
@interface TableName##_Query : Query \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName1 *CName1; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName2 *CName2; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName3 *CName3; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName4 *CName4; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName5 *CName5; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName6 *CName6; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName7 *CName7; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName8 *CName8; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName9 *CName9; \
-(TableName##_Query *)group; \
-(TableName##_Query *)or; \
-(TableName##_Query *)endgroup; \
-(TableName##_Query *)subtable:(size_t)column; \
-(TableName##_Query *)parent; \
-(TableName##_View *)findAll; \
@end \
@interface OCColumnProxy_##TableName : OCColumnProxy \
-(size_t)find:(NSString*)value; \
@end \
@interface TableName : Table \
@property(nonatomic, strong) OCColumnProxy_##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy_##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy_##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy_##CType4 *CName4; \
@property(nonatomic, strong) OCColumnProxy_##CType5 *CName5; \
@property(nonatomic, strong) OCColumnProxy_##CType6 *CName6; \
@property(nonatomic, strong) OCColumnProxy_##CType7 *CName7; \
@property(nonatomic, strong) OCColumnProxy_##CType8 *CName8; \
@property(nonatomic, strong) OCColumnProxy_##CType9 *CName9; \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9; \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9; \
-(TableName##_Query *)getQuery; \
-(TableName##_Cursor *)add; \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_Cursor *)lastObject; \
@end \
typedef TableName* TIGHTDB_TYPE_##TableName; \
@interface TableName##_View : TableView \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
@end

#define TIGHTDB_TABLE_IMPL_9(TableName, CName1, CType1, CName2, CType2, CName3, CType3, CName4, CType4, CName5, CType5, CName6, CType6, CName7, CType7, CName8, CType8, CName9, CType9) \
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
    OCAccessor *_##CName9; \
} \
-(id)initWithTable:(Table *)table ndx:(size_t)ndx \
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
TIGHTDB_CURSOR_PROPERTY_IMPL(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName2, CType2) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName3, CType3) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName4, CType4) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName5, CType5) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName6, CType6) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName7, CType7) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName8, CType8) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName9, CType9) \
@end \
@implementation TableName##_Query \
{ \
    TableName##_Cursor *tmpCursor; \
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
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
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
        _CName1 = [[TableName##_QueryAccessor_##CName1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##_QueryAccessor_##CName2 alloc] initWithColumn:1 query:self]; \
        _CName3 = [[TableName##_QueryAccessor_##CName3 alloc] initWithColumn:2 query:self]; \
        _CName4 = [[TableName##_QueryAccessor_##CName4 alloc] initWithColumn:3 query:self]; \
        _CName5 = [[TableName##_QueryAccessor_##CName5 alloc] initWithColumn:4 query:self]; \
        _CName6 = [[TableName##_QueryAccessor_##CName6 alloc] initWithColumn:5 query:self]; \
        _CName7 = [[TableName##_QueryAccessor_##CName7 alloc] initWithColumn:6 query:self]; \
        _CName8 = [[TableName##_QueryAccessor_##CName8 alloc] initWithColumn:7 query:self]; \
        _CName9 = [[TableName##_QueryAccessor_##CName9 alloc] initWithColumn:8 query:self]; \
    } \
    return self; \
} \
-(TableName##_Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_View *)findAll \
{ \
    return [[TableName##_View alloc] initFromQuery:self]; \
} \
@end \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName2, CType2) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName3, CType3) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName4, CType4) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName5, CType5) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName6, CType6) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName7, CType7) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName8, CType8) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName9, CType9) \
@implementation OCColumnProxy_##TableName \
-(size_t)find:(NSString *)value \
{ \
    return [self.table findString:self.column value:value]; \
} \
@end \
@implementation TableName \
{ \
    TableName##_Cursor *tmpCursor; \
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
-(id)_initRaw \
{ \
    self = [super _initRaw]; \
    if (!self) return nil; \
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    _##CName3 = [[OCColumnProxy_##CType3 alloc] initWithTable:self column:2]; \
    _##CName4 = [[OCColumnProxy_##CType4 alloc] initWithTable:self column:3]; \
    _##CName5 = [[OCColumnProxy_##CType5 alloc] initWithTable:self column:4]; \
    _##CName6 = [[OCColumnProxy_##CType6 alloc] initWithTable:self column:5]; \
    _##CName7 = [[OCColumnProxy_##CType7 alloc] initWithTable:self column:6]; \
    _##CName8 = [[OCColumnProxy_##CType8 alloc] initWithTable:self column:7]; \
    _##CName9 = [[OCColumnProxy_##CType9 alloc] initWithTable:self column:8]; \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (!self) return nil; \
    if (![self _addColumns]) return nil; \
\
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    _##CName3 = [[OCColumnProxy_##CType3 alloc] initWithTable:self column:2]; \
    _##CName4 = [[OCColumnProxy_##CType4 alloc] initWithTable:self column:3]; \
    _##CName5 = [[OCColumnProxy_##CType5 alloc] initWithTable:self column:4]; \
    _##CName6 = [[OCColumnProxy_##CType6 alloc] initWithTable:self column:5]; \
    _##CName7 = [[OCColumnProxy_##CType7 alloc] initWithTable:self column:6]; \
    _##CName8 = [[OCColumnProxy_##CType8 alloc] initWithTable:self column:7]; \
    _##CName9 = [[OCColumnProxy_##CType9 alloc] initWithTable:self column:8]; \
    return self; \
} \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9 \
{ \
    const size_t ndx = [self count]; \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    TIGHTDB_COLUMN_INSERT(self, 2, ndx, CName3, CType3); \
    TIGHTDB_COLUMN_INSERT(self, 3, ndx, CName4, CType4); \
    TIGHTDB_COLUMN_INSERT(self, 4, ndx, CName5, CType5); \
    TIGHTDB_COLUMN_INSERT(self, 5, ndx, CName6, CType6); \
    TIGHTDB_COLUMN_INSERT(self, 6, ndx, CName7, CType7); \
    TIGHTDB_COLUMN_INSERT(self, 7, ndx, CName8, CType8); \
    TIGHTDB_COLUMN_INSERT(self, 8, ndx, CName9, CType9); \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9 \
{ \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    TIGHTDB_COLUMN_INSERT(self, 2, ndx, CName3, CType3); \
    TIGHTDB_COLUMN_INSERT(self, 3, ndx, CName4, CType4); \
    TIGHTDB_COLUMN_INSERT(self, 4, ndx, CName5, CType5); \
    TIGHTDB_COLUMN_INSERT(self, 5, ndx, CName6, CType6); \
    TIGHTDB_COLUMN_INSERT(self, 6, ndx, CName7, CType7); \
    TIGHTDB_COLUMN_INSERT(self, 7, ndx, CName8, CType8); \
    TIGHTDB_COLUMN_INSERT(self, 8, ndx, CName9, CType9); \
    [self insertDone]; \
} \
-(TableName##_Query *)getQuery \
{ \
    return [[TableName##_Query alloc] initWithTable:self]; \
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
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:self ndx:0]; \
} \
+(BOOL)_checkType:(OCSpec *)spec \
{ \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 0, CName1, CType1) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 1, CName2, CType2) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 2, CName3, CType3) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 3, CName4, CType4) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 4, CName5, CType5) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 5, CName6, CType6) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 6, CName7, CType7) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 7, CName8, CType8) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 8, CName9, CType9) \
    return YES; \
} \
-(BOOL)_checkType \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _checkType:spec]) return NO; \
    return YES; \
} \
+(BOOL)_addColumns:(OCSpec *)spec \
{ \
    TIGHTDB_ADD_COLUMN(spec, CName1, CType1) \
    TIGHTDB_ADD_COLUMN(spec, CName2, CType2) \
    TIGHTDB_ADD_COLUMN(spec, CName3, CType3) \
    TIGHTDB_ADD_COLUMN(spec, CName4, CType4) \
    TIGHTDB_ADD_COLUMN(spec, CName5, CType5) \
    TIGHTDB_ADD_COLUMN(spec, CName6, CType6) \
    TIGHTDB_ADD_COLUMN(spec, CName7, CType7) \
    TIGHTDB_ADD_COLUMN(spec, CName8, CType8) \
    TIGHTDB_ADD_COLUMN(spec, CName9, CType9) \
    return YES; \
} \
-(BOOL)_addColumns \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _addColumns:spec]) return NO; \
    [self updateFromSpec]; \
    return YES; \
} \
@end \
@implementation TableName##_View \
{ \
    TableName##_Cursor *tmpCursor; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
} \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
} \
@end

#define TIGHTDB_TABLE_9(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9) \
TIGHTDB_TABLE_DEF_9(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9) \
TIGHTDB_TABLE_IMPL_9(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9)


#define TIGHTDB_TABLE_DEF_10(TableName, CName1, CType1, CName2, CType2, CName3, CType3, CName4, CType4, CName5, CType5, CName6, CType6, CName7, CType7, CName8, CType8, CName9, CType9, CName10, CType10) \
@interface TableName##_Cursor : CursorBase \
TIGHTDB_CURSOR_PROPERTY_DEF(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName2, CType2) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName3, CType3) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName4, CType4) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName5, CType5) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName6, CType6) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName7, CType7) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName8, CType8) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName9, CType9) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName10, CType10) \
@end \
@class TableName##_Query; \
@class TableName##_View; \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName2, CType2) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName3, CType3) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName4, CType4) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName5, CType5) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName6, CType6) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName7, CType7) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName8, CType8) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName9, CType9) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName10, CType10) \
@interface TableName##_Query : Query \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName1 *CName1; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName2 *CName2; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName3 *CName3; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName4 *CName4; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName5 *CName5; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName6 *CName6; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName7 *CName7; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName8 *CName8; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName9 *CName9; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName10 *CName10; \
-(TableName##_Query *)group; \
-(TableName##_Query *)or; \
-(TableName##_Query *)endgroup; \
-(TableName##_Query *)subtable:(size_t)column; \
-(TableName##_Query *)parent; \
-(TableName##_View *)findAll; \
@end \
@interface OCColumnProxy_##TableName : OCColumnProxy \
-(size_t)find:(NSString*)value; \
@end \
@interface TableName : Table \
@property(nonatomic, strong) OCColumnProxy_##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy_##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy_##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy_##CType4 *CName4; \
@property(nonatomic, strong) OCColumnProxy_##CType5 *CName5; \
@property(nonatomic, strong) OCColumnProxy_##CType6 *CName6; \
@property(nonatomic, strong) OCColumnProxy_##CType7 *CName7; \
@property(nonatomic, strong) OCColumnProxy_##CType8 *CName8; \
@property(nonatomic, strong) OCColumnProxy_##CType9 *CName9; \
@property(nonatomic, strong) OCColumnProxy_##CType10 *CName10; \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9 CName10:(TIGHTDB_TYPE_##CType10)CName10; \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9 CName10:(TIGHTDB_TYPE_##CType10)CName10; \
-(TableName##_Query *)getQuery; \
-(TableName##_Cursor *)add; \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_Cursor *)lastObject; \
@end \
typedef TableName* TIGHTDB_TYPE_##TableName; \
@interface TableName##_View : TableView \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
@end

#define TIGHTDB_TABLE_IMPL_10(TableName, CName1, CType1, CName2, CType2, CName3, CType3, CName4, CType4, CName5, CType5, CName6, CType6, CName7, CType7, CName8, CType8, CName9, CType9, CName10, CType10) \
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
    OCAccessor *_##CName9; \
    OCAccessor *_##CName10; \
} \
-(id)initWithTable:(Table *)table ndx:(size_t)ndx \
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
TIGHTDB_CURSOR_PROPERTY_IMPL(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName2, CType2) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName3, CType3) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName4, CType4) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName5, CType5) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName6, CType6) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName7, CType7) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName8, CType8) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName9, CType9) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName10, CType10) \
@end \
@implementation TableName##_Query \
{ \
    TableName##_Cursor *tmpCursor; \
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
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
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
        _CName1 = [[TableName##_QueryAccessor_##CName1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##_QueryAccessor_##CName2 alloc] initWithColumn:1 query:self]; \
        _CName3 = [[TableName##_QueryAccessor_##CName3 alloc] initWithColumn:2 query:self]; \
        _CName4 = [[TableName##_QueryAccessor_##CName4 alloc] initWithColumn:3 query:self]; \
        _CName5 = [[TableName##_QueryAccessor_##CName5 alloc] initWithColumn:4 query:self]; \
        _CName6 = [[TableName##_QueryAccessor_##CName6 alloc] initWithColumn:5 query:self]; \
        _CName7 = [[TableName##_QueryAccessor_##CName7 alloc] initWithColumn:6 query:self]; \
        _CName8 = [[TableName##_QueryAccessor_##CName8 alloc] initWithColumn:7 query:self]; \
        _CName9 = [[TableName##_QueryAccessor_##CName9 alloc] initWithColumn:8 query:self]; \
        _CName10 = [[TableName##_QueryAccessor_##CName10 alloc] initWithColumn:9 query:self]; \
    } \
    return self; \
} \
-(TableName##_Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_View *)findAll \
{ \
    return [[TableName##_View alloc] initFromQuery:self]; \
} \
@end \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName2, CType2) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName3, CType3) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName4, CType4) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName5, CType5) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName6, CType6) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName7, CType7) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName8, CType8) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName9, CType9) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName10, CType10) \
@implementation OCColumnProxy_##TableName \
-(size_t)find:(NSString *)value \
{ \
    return [self.table findString:self.column value:value]; \
} \
@end \
@implementation TableName \
{ \
    TableName##_Cursor *tmpCursor; \
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
-(id)_initRaw \
{ \
    self = [super _initRaw]; \
    if (!self) return nil; \
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    _##CName3 = [[OCColumnProxy_##CType3 alloc] initWithTable:self column:2]; \
    _##CName4 = [[OCColumnProxy_##CType4 alloc] initWithTable:self column:3]; \
    _##CName5 = [[OCColumnProxy_##CType5 alloc] initWithTable:self column:4]; \
    _##CName6 = [[OCColumnProxy_##CType6 alloc] initWithTable:self column:5]; \
    _##CName7 = [[OCColumnProxy_##CType7 alloc] initWithTable:self column:6]; \
    _##CName8 = [[OCColumnProxy_##CType8 alloc] initWithTable:self column:7]; \
    _##CName9 = [[OCColumnProxy_##CType9 alloc] initWithTable:self column:8]; \
    _##CName10 = [[OCColumnProxy_##CType10 alloc] initWithTable:self column:9]; \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (!self) return nil; \
    if (![self _addColumns]) return nil; \
\
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    _##CName3 = [[OCColumnProxy_##CType3 alloc] initWithTable:self column:2]; \
    _##CName4 = [[OCColumnProxy_##CType4 alloc] initWithTable:self column:3]; \
    _##CName5 = [[OCColumnProxy_##CType5 alloc] initWithTable:self column:4]; \
    _##CName6 = [[OCColumnProxy_##CType6 alloc] initWithTable:self column:5]; \
    _##CName7 = [[OCColumnProxy_##CType7 alloc] initWithTable:self column:6]; \
    _##CName8 = [[OCColumnProxy_##CType8 alloc] initWithTable:self column:7]; \
    _##CName9 = [[OCColumnProxy_##CType9 alloc] initWithTable:self column:8]; \
    _##CName10 = [[OCColumnProxy_##CType10 alloc] initWithTable:self column:9]; \
    return self; \
} \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9 CName10:(TIGHTDB_TYPE_##CType10)CName10 \
{ \
    const size_t ndx = [self count]; \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    TIGHTDB_COLUMN_INSERT(self, 2, ndx, CName3, CType3); \
    TIGHTDB_COLUMN_INSERT(self, 3, ndx, CName4, CType4); \
    TIGHTDB_COLUMN_INSERT(self, 4, ndx, CName5, CType5); \
    TIGHTDB_COLUMN_INSERT(self, 5, ndx, CName6, CType6); \
    TIGHTDB_COLUMN_INSERT(self, 6, ndx, CName7, CType7); \
    TIGHTDB_COLUMN_INSERT(self, 7, ndx, CName8, CType8); \
    TIGHTDB_COLUMN_INSERT(self, 8, ndx, CName9, CType9); \
    TIGHTDB_COLUMN_INSERT(self, 9, ndx, CName10, CType10); \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9 CName10:(TIGHTDB_TYPE_##CType10)CName10 \
{ \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    TIGHTDB_COLUMN_INSERT(self, 2, ndx, CName3, CType3); \
    TIGHTDB_COLUMN_INSERT(self, 3, ndx, CName4, CType4); \
    TIGHTDB_COLUMN_INSERT(self, 4, ndx, CName5, CType5); \
    TIGHTDB_COLUMN_INSERT(self, 5, ndx, CName6, CType6); \
    TIGHTDB_COLUMN_INSERT(self, 6, ndx, CName7, CType7); \
    TIGHTDB_COLUMN_INSERT(self, 7, ndx, CName8, CType8); \
    TIGHTDB_COLUMN_INSERT(self, 8, ndx, CName9, CType9); \
    TIGHTDB_COLUMN_INSERT(self, 9, ndx, CName10, CType10); \
    [self insertDone]; \
} \
-(TableName##_Query *)getQuery \
{ \
    return [[TableName##_Query alloc] initWithTable:self]; \
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
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:self ndx:0]; \
} \
+(BOOL)_checkType:(OCSpec *)spec \
{ \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 0, CName1, CType1) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 1, CName2, CType2) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 2, CName3, CType3) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 3, CName4, CType4) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 4, CName5, CType5) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 5, CName6, CType6) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 6, CName7, CType7) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 7, CName8, CType8) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 8, CName9, CType9) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 9, CName10, CType10) \
    return YES; \
} \
-(BOOL)_checkType \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _checkType:spec]) return NO; \
    return YES; \
} \
+(BOOL)_addColumns:(OCSpec *)spec \
{ \
    TIGHTDB_ADD_COLUMN(spec, CName1, CType1) \
    TIGHTDB_ADD_COLUMN(spec, CName2, CType2) \
    TIGHTDB_ADD_COLUMN(spec, CName3, CType3) \
    TIGHTDB_ADD_COLUMN(spec, CName4, CType4) \
    TIGHTDB_ADD_COLUMN(spec, CName5, CType5) \
    TIGHTDB_ADD_COLUMN(spec, CName6, CType6) \
    TIGHTDB_ADD_COLUMN(spec, CName7, CType7) \
    TIGHTDB_ADD_COLUMN(spec, CName8, CType8) \
    TIGHTDB_ADD_COLUMN(spec, CName9, CType9) \
    TIGHTDB_ADD_COLUMN(spec, CName10, CType10) \
    return YES; \
} \
-(BOOL)_addColumns \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _addColumns:spec]) return NO; \
    [self updateFromSpec]; \
    return YES; \
} \
@end \
@implementation TableName##_View \
{ \
    TableName##_Cursor *tmpCursor; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
} \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
} \
@end

#define TIGHTDB_TABLE_10(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10) \
TIGHTDB_TABLE_DEF_10(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10) \
TIGHTDB_TABLE_IMPL_10(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10)


#define TIGHTDB_TABLE_DEF_11(TableName, CName1, CType1, CName2, CType2, CName3, CType3, CName4, CType4, CName5, CType5, CName6, CType6, CName7, CType7, CName8, CType8, CName9, CType9, CName10, CType10, CName11, CType11) \
@interface TableName##_Cursor : CursorBase \
TIGHTDB_CURSOR_PROPERTY_DEF(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName2, CType2) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName3, CType3) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName4, CType4) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName5, CType5) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName6, CType6) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName7, CType7) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName8, CType8) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName9, CType9) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName10, CType10) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName11, CType11) \
@end \
@class TableName##_Query; \
@class TableName##_View; \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName2, CType2) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName3, CType3) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName4, CType4) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName5, CType5) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName6, CType6) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName7, CType7) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName8, CType8) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName9, CType9) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName10, CType10) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName11, CType11) \
@interface TableName##_Query : Query \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName1 *CName1; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName2 *CName2; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName3 *CName3; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName4 *CName4; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName5 *CName5; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName6 *CName6; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName7 *CName7; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName8 *CName8; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName9 *CName9; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName10 *CName10; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName11 *CName11; \
-(TableName##_Query *)group; \
-(TableName##_Query *)or; \
-(TableName##_Query *)endgroup; \
-(TableName##_Query *)subtable:(size_t)column; \
-(TableName##_Query *)parent; \
-(TableName##_View *)findAll; \
@end \
@interface OCColumnProxy_##TableName : OCColumnProxy \
-(size_t)find:(NSString*)value; \
@end \
@interface TableName : Table \
@property(nonatomic, strong) OCColumnProxy_##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy_##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy_##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy_##CType4 *CName4; \
@property(nonatomic, strong) OCColumnProxy_##CType5 *CName5; \
@property(nonatomic, strong) OCColumnProxy_##CType6 *CName6; \
@property(nonatomic, strong) OCColumnProxy_##CType7 *CName7; \
@property(nonatomic, strong) OCColumnProxy_##CType8 *CName8; \
@property(nonatomic, strong) OCColumnProxy_##CType9 *CName9; \
@property(nonatomic, strong) OCColumnProxy_##CType10 *CName10; \
@property(nonatomic, strong) OCColumnProxy_##CType11 *CName11; \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9 CName10:(TIGHTDB_TYPE_##CType10)CName10 CName11:(TIGHTDB_TYPE_##CType11)CName11; \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9 CName10:(TIGHTDB_TYPE_##CType10)CName10 CName11:(TIGHTDB_TYPE_##CType11)CName11; \
-(TableName##_Query *)getQuery; \
-(TableName##_Cursor *)add; \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_Cursor *)lastObject; \
@end \
typedef TableName* TIGHTDB_TYPE_##TableName; \
@interface TableName##_View : TableView \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
@end

#define TIGHTDB_TABLE_IMPL_11(TableName, CName1, CType1, CName2, CType2, CName3, CType3, CName4, CType4, CName5, CType5, CName6, CType6, CName7, CType7, CName8, CType8, CName9, CType9, CName10, CType10, CName11, CType11) \
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
    OCAccessor *_##CName9; \
    OCAccessor *_##CName10; \
    OCAccessor *_##CName11; \
} \
-(id)initWithTable:(Table *)table ndx:(size_t)ndx \
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
TIGHTDB_CURSOR_PROPERTY_IMPL(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName2, CType2) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName3, CType3) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName4, CType4) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName5, CType5) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName6, CType6) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName7, CType7) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName8, CType8) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName9, CType9) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName10, CType10) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName11, CType11) \
@end \
@implementation TableName##_Query \
{ \
    TableName##_Cursor *tmpCursor; \
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
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
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
        _CName1 = [[TableName##_QueryAccessor_##CName1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##_QueryAccessor_##CName2 alloc] initWithColumn:1 query:self]; \
        _CName3 = [[TableName##_QueryAccessor_##CName3 alloc] initWithColumn:2 query:self]; \
        _CName4 = [[TableName##_QueryAccessor_##CName4 alloc] initWithColumn:3 query:self]; \
        _CName5 = [[TableName##_QueryAccessor_##CName5 alloc] initWithColumn:4 query:self]; \
        _CName6 = [[TableName##_QueryAccessor_##CName6 alloc] initWithColumn:5 query:self]; \
        _CName7 = [[TableName##_QueryAccessor_##CName7 alloc] initWithColumn:6 query:self]; \
        _CName8 = [[TableName##_QueryAccessor_##CName8 alloc] initWithColumn:7 query:self]; \
        _CName9 = [[TableName##_QueryAccessor_##CName9 alloc] initWithColumn:8 query:self]; \
        _CName10 = [[TableName##_QueryAccessor_##CName10 alloc] initWithColumn:9 query:self]; \
        _CName11 = [[TableName##_QueryAccessor_##CName11 alloc] initWithColumn:10 query:self]; \
    } \
    return self; \
} \
-(TableName##_Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_View *)findAll \
{ \
    return [[TableName##_View alloc] initFromQuery:self]; \
} \
@end \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName2, CType2) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName3, CType3) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName4, CType4) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName5, CType5) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName6, CType6) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName7, CType7) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName8, CType8) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName9, CType9) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName10, CType10) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName11, CType11) \
@implementation OCColumnProxy_##TableName \
-(size_t)find:(NSString *)value \
{ \
    return [self.table findString:self.column value:value]; \
} \
@end \
@implementation TableName \
{ \
    TableName##_Cursor *tmpCursor; \
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
-(id)_initRaw \
{ \
    self = [super _initRaw]; \
    if (!self) return nil; \
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    _##CName3 = [[OCColumnProxy_##CType3 alloc] initWithTable:self column:2]; \
    _##CName4 = [[OCColumnProxy_##CType4 alloc] initWithTable:self column:3]; \
    _##CName5 = [[OCColumnProxy_##CType5 alloc] initWithTable:self column:4]; \
    _##CName6 = [[OCColumnProxy_##CType6 alloc] initWithTable:self column:5]; \
    _##CName7 = [[OCColumnProxy_##CType7 alloc] initWithTable:self column:6]; \
    _##CName8 = [[OCColumnProxy_##CType8 alloc] initWithTable:self column:7]; \
    _##CName9 = [[OCColumnProxy_##CType9 alloc] initWithTable:self column:8]; \
    _##CName10 = [[OCColumnProxy_##CType10 alloc] initWithTable:self column:9]; \
    _##CName11 = [[OCColumnProxy_##CType11 alloc] initWithTable:self column:10]; \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (!self) return nil; \
    if (![self _addColumns]) return nil; \
\
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    _##CName3 = [[OCColumnProxy_##CType3 alloc] initWithTable:self column:2]; \
    _##CName4 = [[OCColumnProxy_##CType4 alloc] initWithTable:self column:3]; \
    _##CName5 = [[OCColumnProxy_##CType5 alloc] initWithTable:self column:4]; \
    _##CName6 = [[OCColumnProxy_##CType6 alloc] initWithTable:self column:5]; \
    _##CName7 = [[OCColumnProxy_##CType7 alloc] initWithTable:self column:6]; \
    _##CName8 = [[OCColumnProxy_##CType8 alloc] initWithTable:self column:7]; \
    _##CName9 = [[OCColumnProxy_##CType9 alloc] initWithTable:self column:8]; \
    _##CName10 = [[OCColumnProxy_##CType10 alloc] initWithTable:self column:9]; \
    _##CName11 = [[OCColumnProxy_##CType11 alloc] initWithTable:self column:10]; \
    return self; \
} \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9 CName10:(TIGHTDB_TYPE_##CType10)CName10 CName11:(TIGHTDB_TYPE_##CType11)CName11 \
{ \
    const size_t ndx = [self count]; \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    TIGHTDB_COLUMN_INSERT(self, 2, ndx, CName3, CType3); \
    TIGHTDB_COLUMN_INSERT(self, 3, ndx, CName4, CType4); \
    TIGHTDB_COLUMN_INSERT(self, 4, ndx, CName5, CType5); \
    TIGHTDB_COLUMN_INSERT(self, 5, ndx, CName6, CType6); \
    TIGHTDB_COLUMN_INSERT(self, 6, ndx, CName7, CType7); \
    TIGHTDB_COLUMN_INSERT(self, 7, ndx, CName8, CType8); \
    TIGHTDB_COLUMN_INSERT(self, 8, ndx, CName9, CType9); \
    TIGHTDB_COLUMN_INSERT(self, 9, ndx, CName10, CType10); \
    TIGHTDB_COLUMN_INSERT(self, 10, ndx, CName11, CType11); \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9 CName10:(TIGHTDB_TYPE_##CType10)CName10 CName11:(TIGHTDB_TYPE_##CType11)CName11 \
{ \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    TIGHTDB_COLUMN_INSERT(self, 2, ndx, CName3, CType3); \
    TIGHTDB_COLUMN_INSERT(self, 3, ndx, CName4, CType4); \
    TIGHTDB_COLUMN_INSERT(self, 4, ndx, CName5, CType5); \
    TIGHTDB_COLUMN_INSERT(self, 5, ndx, CName6, CType6); \
    TIGHTDB_COLUMN_INSERT(self, 6, ndx, CName7, CType7); \
    TIGHTDB_COLUMN_INSERT(self, 7, ndx, CName8, CType8); \
    TIGHTDB_COLUMN_INSERT(self, 8, ndx, CName9, CType9); \
    TIGHTDB_COLUMN_INSERT(self, 9, ndx, CName10, CType10); \
    TIGHTDB_COLUMN_INSERT(self, 10, ndx, CName11, CType11); \
    [self insertDone]; \
} \
-(TableName##_Query *)getQuery \
{ \
    return [[TableName##_Query alloc] initWithTable:self]; \
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
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:self ndx:0]; \
} \
+(BOOL)_checkType:(OCSpec *)spec \
{ \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 0, CName1, CType1) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 1, CName2, CType2) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 2, CName3, CType3) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 3, CName4, CType4) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 4, CName5, CType5) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 5, CName6, CType6) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 6, CName7, CType7) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 7, CName8, CType8) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 8, CName9, CType9) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 9, CName10, CType10) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 10, CName11, CType11) \
    return YES; \
} \
-(BOOL)_checkType \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _checkType:spec]) return NO; \
    return YES; \
} \
+(BOOL)_addColumns:(OCSpec *)spec \
{ \
    TIGHTDB_ADD_COLUMN(spec, CName1, CType1) \
    TIGHTDB_ADD_COLUMN(spec, CName2, CType2) \
    TIGHTDB_ADD_COLUMN(spec, CName3, CType3) \
    TIGHTDB_ADD_COLUMN(spec, CName4, CType4) \
    TIGHTDB_ADD_COLUMN(spec, CName5, CType5) \
    TIGHTDB_ADD_COLUMN(spec, CName6, CType6) \
    TIGHTDB_ADD_COLUMN(spec, CName7, CType7) \
    TIGHTDB_ADD_COLUMN(spec, CName8, CType8) \
    TIGHTDB_ADD_COLUMN(spec, CName9, CType9) \
    TIGHTDB_ADD_COLUMN(spec, CName10, CType10) \
    TIGHTDB_ADD_COLUMN(spec, CName11, CType11) \
    return YES; \
} \
-(BOOL)_addColumns \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _addColumns:spec]) return NO; \
    [self updateFromSpec]; \
    return YES; \
} \
@end \
@implementation TableName##_View \
{ \
    TableName##_Cursor *tmpCursor; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
} \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
} \
@end

#define TIGHTDB_TABLE_11(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10, CType11, CName11) \
TIGHTDB_TABLE_DEF_11(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10, CType11, CName11) \
TIGHTDB_TABLE_IMPL_11(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10, CType11, CName11)


#define TIGHTDB_TABLE_DEF_12(TableName, CName1, CType1, CName2, CType2, CName3, CType3, CName4, CType4, CName5, CType5, CName6, CType6, CName7, CType7, CName8, CType8, CName9, CType9, CName10, CType10, CName11, CType11, CName12, CType12) \
@interface TableName##_Cursor : CursorBase \
TIGHTDB_CURSOR_PROPERTY_DEF(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName2, CType2) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName3, CType3) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName4, CType4) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName5, CType5) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName6, CType6) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName7, CType7) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName8, CType8) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName9, CType9) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName10, CType10) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName11, CType11) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName12, CType12) \
@end \
@class TableName##_Query; \
@class TableName##_View; \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName2, CType2) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName3, CType3) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName4, CType4) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName5, CType5) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName6, CType6) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName7, CType7) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName8, CType8) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName9, CType9) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName10, CType10) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName11, CType11) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName12, CType12) \
@interface TableName##_Query : Query \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName1 *CName1; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName2 *CName2; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName3 *CName3; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName4 *CName4; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName5 *CName5; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName6 *CName6; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName7 *CName7; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName8 *CName8; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName9 *CName9; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName10 *CName10; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName11 *CName11; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName12 *CName12; \
-(TableName##_Query *)group; \
-(TableName##_Query *)or; \
-(TableName##_Query *)endgroup; \
-(TableName##_Query *)subtable:(size_t)column; \
-(TableName##_Query *)parent; \
-(TableName##_View *)findAll; \
@end \
@interface OCColumnProxy_##TableName : OCColumnProxy \
-(size_t)find:(NSString*)value; \
@end \
@interface TableName : Table \
@property(nonatomic, strong) OCColumnProxy_##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy_##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy_##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy_##CType4 *CName4; \
@property(nonatomic, strong) OCColumnProxy_##CType5 *CName5; \
@property(nonatomic, strong) OCColumnProxy_##CType6 *CName6; \
@property(nonatomic, strong) OCColumnProxy_##CType7 *CName7; \
@property(nonatomic, strong) OCColumnProxy_##CType8 *CName8; \
@property(nonatomic, strong) OCColumnProxy_##CType9 *CName9; \
@property(nonatomic, strong) OCColumnProxy_##CType10 *CName10; \
@property(nonatomic, strong) OCColumnProxy_##CType11 *CName11; \
@property(nonatomic, strong) OCColumnProxy_##CType12 *CName12; \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9 CName10:(TIGHTDB_TYPE_##CType10)CName10 CName11:(TIGHTDB_TYPE_##CType11)CName11 CName12:(TIGHTDB_TYPE_##CType12)CName12; \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9 CName10:(TIGHTDB_TYPE_##CType10)CName10 CName11:(TIGHTDB_TYPE_##CType11)CName11 CName12:(TIGHTDB_TYPE_##CType12)CName12; \
-(TableName##_Query *)getQuery; \
-(TableName##_Cursor *)add; \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_Cursor *)lastObject; \
@end \
typedef TableName* TIGHTDB_TYPE_##TableName; \
@interface TableName##_View : TableView \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
@end

#define TIGHTDB_TABLE_IMPL_12(TableName, CName1, CType1, CName2, CType2, CName3, CType3, CName4, CType4, CName5, CType5, CName6, CType6, CName7, CType7, CName8, CType8, CName9, CType9, CName10, CType10, CName11, CType11, CName12, CType12) \
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
    OCAccessor *_##CName9; \
    OCAccessor *_##CName10; \
    OCAccessor *_##CName11; \
    OCAccessor *_##CName12; \
} \
-(id)initWithTable:(Table *)table ndx:(size_t)ndx \
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
TIGHTDB_CURSOR_PROPERTY_IMPL(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName2, CType2) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName3, CType3) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName4, CType4) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName5, CType5) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName6, CType6) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName7, CType7) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName8, CType8) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName9, CType9) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName10, CType10) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName11, CType11) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName12, CType12) \
@end \
@implementation TableName##_Query \
{ \
    TableName##_Cursor *tmpCursor; \
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
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
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
        _CName1 = [[TableName##_QueryAccessor_##CName1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##_QueryAccessor_##CName2 alloc] initWithColumn:1 query:self]; \
        _CName3 = [[TableName##_QueryAccessor_##CName3 alloc] initWithColumn:2 query:self]; \
        _CName4 = [[TableName##_QueryAccessor_##CName4 alloc] initWithColumn:3 query:self]; \
        _CName5 = [[TableName##_QueryAccessor_##CName5 alloc] initWithColumn:4 query:self]; \
        _CName6 = [[TableName##_QueryAccessor_##CName6 alloc] initWithColumn:5 query:self]; \
        _CName7 = [[TableName##_QueryAccessor_##CName7 alloc] initWithColumn:6 query:self]; \
        _CName8 = [[TableName##_QueryAccessor_##CName8 alloc] initWithColumn:7 query:self]; \
        _CName9 = [[TableName##_QueryAccessor_##CName9 alloc] initWithColumn:8 query:self]; \
        _CName10 = [[TableName##_QueryAccessor_##CName10 alloc] initWithColumn:9 query:self]; \
        _CName11 = [[TableName##_QueryAccessor_##CName11 alloc] initWithColumn:10 query:self]; \
        _CName12 = [[TableName##_QueryAccessor_##CName12 alloc] initWithColumn:11 query:self]; \
    } \
    return self; \
} \
-(TableName##_Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_View *)findAll \
{ \
    return [[TableName##_View alloc] initFromQuery:self]; \
} \
@end \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName2, CType2) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName3, CType3) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName4, CType4) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName5, CType5) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName6, CType6) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName7, CType7) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName8, CType8) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName9, CType9) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName10, CType10) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName11, CType11) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName12, CType12) \
@implementation OCColumnProxy_##TableName \
-(size_t)find:(NSString *)value \
{ \
    return [self.table findString:self.column value:value]; \
} \
@end \
@implementation TableName \
{ \
    TableName##_Cursor *tmpCursor; \
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
-(id)_initRaw \
{ \
    self = [super _initRaw]; \
    if (!self) return nil; \
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    _##CName3 = [[OCColumnProxy_##CType3 alloc] initWithTable:self column:2]; \
    _##CName4 = [[OCColumnProxy_##CType4 alloc] initWithTable:self column:3]; \
    _##CName5 = [[OCColumnProxy_##CType5 alloc] initWithTable:self column:4]; \
    _##CName6 = [[OCColumnProxy_##CType6 alloc] initWithTable:self column:5]; \
    _##CName7 = [[OCColumnProxy_##CType7 alloc] initWithTable:self column:6]; \
    _##CName8 = [[OCColumnProxy_##CType8 alloc] initWithTable:self column:7]; \
    _##CName9 = [[OCColumnProxy_##CType9 alloc] initWithTable:self column:8]; \
    _##CName10 = [[OCColumnProxy_##CType10 alloc] initWithTable:self column:9]; \
    _##CName11 = [[OCColumnProxy_##CType11 alloc] initWithTable:self column:10]; \
    _##CName12 = [[OCColumnProxy_##CType12 alloc] initWithTable:self column:11]; \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (!self) return nil; \
    if (![self _addColumns]) return nil; \
\
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    _##CName3 = [[OCColumnProxy_##CType3 alloc] initWithTable:self column:2]; \
    _##CName4 = [[OCColumnProxy_##CType4 alloc] initWithTable:self column:3]; \
    _##CName5 = [[OCColumnProxy_##CType5 alloc] initWithTable:self column:4]; \
    _##CName6 = [[OCColumnProxy_##CType6 alloc] initWithTable:self column:5]; \
    _##CName7 = [[OCColumnProxy_##CType7 alloc] initWithTable:self column:6]; \
    _##CName8 = [[OCColumnProxy_##CType8 alloc] initWithTable:self column:7]; \
    _##CName9 = [[OCColumnProxy_##CType9 alloc] initWithTable:self column:8]; \
    _##CName10 = [[OCColumnProxy_##CType10 alloc] initWithTable:self column:9]; \
    _##CName11 = [[OCColumnProxy_##CType11 alloc] initWithTable:self column:10]; \
    _##CName12 = [[OCColumnProxy_##CType12 alloc] initWithTable:self column:11]; \
    return self; \
} \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9 CName10:(TIGHTDB_TYPE_##CType10)CName10 CName11:(TIGHTDB_TYPE_##CType11)CName11 CName12:(TIGHTDB_TYPE_##CType12)CName12 \
{ \
    const size_t ndx = [self count]; \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    TIGHTDB_COLUMN_INSERT(self, 2, ndx, CName3, CType3); \
    TIGHTDB_COLUMN_INSERT(self, 3, ndx, CName4, CType4); \
    TIGHTDB_COLUMN_INSERT(self, 4, ndx, CName5, CType5); \
    TIGHTDB_COLUMN_INSERT(self, 5, ndx, CName6, CType6); \
    TIGHTDB_COLUMN_INSERT(self, 6, ndx, CName7, CType7); \
    TIGHTDB_COLUMN_INSERT(self, 7, ndx, CName8, CType8); \
    TIGHTDB_COLUMN_INSERT(self, 8, ndx, CName9, CType9); \
    TIGHTDB_COLUMN_INSERT(self, 9, ndx, CName10, CType10); \
    TIGHTDB_COLUMN_INSERT(self, 10, ndx, CName11, CType11); \
    TIGHTDB_COLUMN_INSERT(self, 11, ndx, CName12, CType12); \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9 CName10:(TIGHTDB_TYPE_##CType10)CName10 CName11:(TIGHTDB_TYPE_##CType11)CName11 CName12:(TIGHTDB_TYPE_##CType12)CName12 \
{ \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    TIGHTDB_COLUMN_INSERT(self, 2, ndx, CName3, CType3); \
    TIGHTDB_COLUMN_INSERT(self, 3, ndx, CName4, CType4); \
    TIGHTDB_COLUMN_INSERT(self, 4, ndx, CName5, CType5); \
    TIGHTDB_COLUMN_INSERT(self, 5, ndx, CName6, CType6); \
    TIGHTDB_COLUMN_INSERT(self, 6, ndx, CName7, CType7); \
    TIGHTDB_COLUMN_INSERT(self, 7, ndx, CName8, CType8); \
    TIGHTDB_COLUMN_INSERT(self, 8, ndx, CName9, CType9); \
    TIGHTDB_COLUMN_INSERT(self, 9, ndx, CName10, CType10); \
    TIGHTDB_COLUMN_INSERT(self, 10, ndx, CName11, CType11); \
    TIGHTDB_COLUMN_INSERT(self, 11, ndx, CName12, CType12); \
    [self insertDone]; \
} \
-(TableName##_Query *)getQuery \
{ \
    return [[TableName##_Query alloc] initWithTable:self]; \
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
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:self ndx:0]; \
} \
+(BOOL)_checkType:(OCSpec *)spec \
{ \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 0, CName1, CType1) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 1, CName2, CType2) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 2, CName3, CType3) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 3, CName4, CType4) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 4, CName5, CType5) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 5, CName6, CType6) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 6, CName7, CType7) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 7, CName8, CType8) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 8, CName9, CType9) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 9, CName10, CType10) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 10, CName11, CType11) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 11, CName12, CType12) \
    return YES; \
} \
-(BOOL)_checkType \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _checkType:spec]) return NO; \
    return YES; \
} \
+(BOOL)_addColumns:(OCSpec *)spec \
{ \
    TIGHTDB_ADD_COLUMN(spec, CName1, CType1) \
    TIGHTDB_ADD_COLUMN(spec, CName2, CType2) \
    TIGHTDB_ADD_COLUMN(spec, CName3, CType3) \
    TIGHTDB_ADD_COLUMN(spec, CName4, CType4) \
    TIGHTDB_ADD_COLUMN(spec, CName5, CType5) \
    TIGHTDB_ADD_COLUMN(spec, CName6, CType6) \
    TIGHTDB_ADD_COLUMN(spec, CName7, CType7) \
    TIGHTDB_ADD_COLUMN(spec, CName8, CType8) \
    TIGHTDB_ADD_COLUMN(spec, CName9, CType9) \
    TIGHTDB_ADD_COLUMN(spec, CName10, CType10) \
    TIGHTDB_ADD_COLUMN(spec, CName11, CType11) \
    TIGHTDB_ADD_COLUMN(spec, CName12, CType12) \
    return YES; \
} \
-(BOOL)_addColumns \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _addColumns:spec]) return NO; \
    [self updateFromSpec]; \
    return YES; \
} \
@end \
@implementation TableName##_View \
{ \
    TableName##_Cursor *tmpCursor; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
} \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
} \
@end

#define TIGHTDB_TABLE_12(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10, CType11, CName11, CType12, CName12) \
TIGHTDB_TABLE_DEF_12(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10, CType11, CName11, CType12, CName12) \
TIGHTDB_TABLE_IMPL_12(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10, CType11, CName11, CType12, CName12)


#define TIGHTDB_TABLE_DEF_13(TableName, CName1, CType1, CName2, CType2, CName3, CType3, CName4, CType4, CName5, CType5, CName6, CType6, CName7, CType7, CName8, CType8, CName9, CType9, CName10, CType10, CName11, CType11, CName12, CType12, CName13, CType13) \
@interface TableName##_Cursor : CursorBase \
TIGHTDB_CURSOR_PROPERTY_DEF(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName2, CType2) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName3, CType3) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName4, CType4) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName5, CType5) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName6, CType6) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName7, CType7) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName8, CType8) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName9, CType9) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName10, CType10) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName11, CType11) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName12, CType12) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName13, CType13) \
@end \
@class TableName##_Query; \
@class TableName##_View; \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName2, CType2) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName3, CType3) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName4, CType4) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName5, CType5) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName6, CType6) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName7, CType7) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName8, CType8) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName9, CType9) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName10, CType10) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName11, CType11) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName12, CType12) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName13, CType13) \
@interface TableName##_Query : Query \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName1 *CName1; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName2 *CName2; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName3 *CName3; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName4 *CName4; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName5 *CName5; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName6 *CName6; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName7 *CName7; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName8 *CName8; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName9 *CName9; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName10 *CName10; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName11 *CName11; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName12 *CName12; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName13 *CName13; \
-(TableName##_Query *)group; \
-(TableName##_Query *)or; \
-(TableName##_Query *)endgroup; \
-(TableName##_Query *)subtable:(size_t)column; \
-(TableName##_Query *)parent; \
-(TableName##_View *)findAll; \
@end \
@interface OCColumnProxy_##TableName : OCColumnProxy \
-(size_t)find:(NSString*)value; \
@end \
@interface TableName : Table \
@property(nonatomic, strong) OCColumnProxy_##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy_##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy_##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy_##CType4 *CName4; \
@property(nonatomic, strong) OCColumnProxy_##CType5 *CName5; \
@property(nonatomic, strong) OCColumnProxy_##CType6 *CName6; \
@property(nonatomic, strong) OCColumnProxy_##CType7 *CName7; \
@property(nonatomic, strong) OCColumnProxy_##CType8 *CName8; \
@property(nonatomic, strong) OCColumnProxy_##CType9 *CName9; \
@property(nonatomic, strong) OCColumnProxy_##CType10 *CName10; \
@property(nonatomic, strong) OCColumnProxy_##CType11 *CName11; \
@property(nonatomic, strong) OCColumnProxy_##CType12 *CName12; \
@property(nonatomic, strong) OCColumnProxy_##CType13 *CName13; \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9 CName10:(TIGHTDB_TYPE_##CType10)CName10 CName11:(TIGHTDB_TYPE_##CType11)CName11 CName12:(TIGHTDB_TYPE_##CType12)CName12 CName13:(TIGHTDB_TYPE_##CType13)CName13; \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9 CName10:(TIGHTDB_TYPE_##CType10)CName10 CName11:(TIGHTDB_TYPE_##CType11)CName11 CName12:(TIGHTDB_TYPE_##CType12)CName12 CName13:(TIGHTDB_TYPE_##CType13)CName13; \
-(TableName##_Query *)getQuery; \
-(TableName##_Cursor *)add; \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_Cursor *)lastObject; \
@end \
typedef TableName* TIGHTDB_TYPE_##TableName; \
@interface TableName##_View : TableView \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
@end

#define TIGHTDB_TABLE_IMPL_13(TableName, CName1, CType1, CName2, CType2, CName3, CType3, CName4, CType4, CName5, CType5, CName6, CType6, CName7, CType7, CName8, CType8, CName9, CType9, CName10, CType10, CName11, CType11, CName12, CType12, CName13, CType13) \
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
    OCAccessor *_##CName9; \
    OCAccessor *_##CName10; \
    OCAccessor *_##CName11; \
    OCAccessor *_##CName12; \
    OCAccessor *_##CName13; \
} \
-(id)initWithTable:(Table *)table ndx:(size_t)ndx \
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
TIGHTDB_CURSOR_PROPERTY_IMPL(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName2, CType2) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName3, CType3) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName4, CType4) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName5, CType5) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName6, CType6) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName7, CType7) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName8, CType8) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName9, CType9) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName10, CType10) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName11, CType11) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName12, CType12) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName13, CType13) \
@end \
@implementation TableName##_Query \
{ \
    TableName##_Cursor *tmpCursor; \
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
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
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
        _CName1 = [[TableName##_QueryAccessor_##CName1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##_QueryAccessor_##CName2 alloc] initWithColumn:1 query:self]; \
        _CName3 = [[TableName##_QueryAccessor_##CName3 alloc] initWithColumn:2 query:self]; \
        _CName4 = [[TableName##_QueryAccessor_##CName4 alloc] initWithColumn:3 query:self]; \
        _CName5 = [[TableName##_QueryAccessor_##CName5 alloc] initWithColumn:4 query:self]; \
        _CName6 = [[TableName##_QueryAccessor_##CName6 alloc] initWithColumn:5 query:self]; \
        _CName7 = [[TableName##_QueryAccessor_##CName7 alloc] initWithColumn:6 query:self]; \
        _CName8 = [[TableName##_QueryAccessor_##CName8 alloc] initWithColumn:7 query:self]; \
        _CName9 = [[TableName##_QueryAccessor_##CName9 alloc] initWithColumn:8 query:self]; \
        _CName10 = [[TableName##_QueryAccessor_##CName10 alloc] initWithColumn:9 query:self]; \
        _CName11 = [[TableName##_QueryAccessor_##CName11 alloc] initWithColumn:10 query:self]; \
        _CName12 = [[TableName##_QueryAccessor_##CName12 alloc] initWithColumn:11 query:self]; \
        _CName13 = [[TableName##_QueryAccessor_##CName13 alloc] initWithColumn:12 query:self]; \
    } \
    return self; \
} \
-(TableName##_Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_View *)findAll \
{ \
    return [[TableName##_View alloc] initFromQuery:self]; \
} \
@end \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName2, CType2) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName3, CType3) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName4, CType4) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName5, CType5) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName6, CType6) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName7, CType7) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName8, CType8) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName9, CType9) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName10, CType10) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName11, CType11) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName12, CType12) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName13, CType13) \
@implementation OCColumnProxy_##TableName \
-(size_t)find:(NSString *)value \
{ \
    return [self.table findString:self.column value:value]; \
} \
@end \
@implementation TableName \
{ \
    TableName##_Cursor *tmpCursor; \
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
-(id)_initRaw \
{ \
    self = [super _initRaw]; \
    if (!self) return nil; \
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    _##CName3 = [[OCColumnProxy_##CType3 alloc] initWithTable:self column:2]; \
    _##CName4 = [[OCColumnProxy_##CType4 alloc] initWithTable:self column:3]; \
    _##CName5 = [[OCColumnProxy_##CType5 alloc] initWithTable:self column:4]; \
    _##CName6 = [[OCColumnProxy_##CType6 alloc] initWithTable:self column:5]; \
    _##CName7 = [[OCColumnProxy_##CType7 alloc] initWithTable:self column:6]; \
    _##CName8 = [[OCColumnProxy_##CType8 alloc] initWithTable:self column:7]; \
    _##CName9 = [[OCColumnProxy_##CType9 alloc] initWithTable:self column:8]; \
    _##CName10 = [[OCColumnProxy_##CType10 alloc] initWithTable:self column:9]; \
    _##CName11 = [[OCColumnProxy_##CType11 alloc] initWithTable:self column:10]; \
    _##CName12 = [[OCColumnProxy_##CType12 alloc] initWithTable:self column:11]; \
    _##CName13 = [[OCColumnProxy_##CType13 alloc] initWithTable:self column:12]; \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (!self) return nil; \
    if (![self _addColumns]) return nil; \
\
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    _##CName3 = [[OCColumnProxy_##CType3 alloc] initWithTable:self column:2]; \
    _##CName4 = [[OCColumnProxy_##CType4 alloc] initWithTable:self column:3]; \
    _##CName5 = [[OCColumnProxy_##CType5 alloc] initWithTable:self column:4]; \
    _##CName6 = [[OCColumnProxy_##CType6 alloc] initWithTable:self column:5]; \
    _##CName7 = [[OCColumnProxy_##CType7 alloc] initWithTable:self column:6]; \
    _##CName8 = [[OCColumnProxy_##CType8 alloc] initWithTable:self column:7]; \
    _##CName9 = [[OCColumnProxy_##CType9 alloc] initWithTable:self column:8]; \
    _##CName10 = [[OCColumnProxy_##CType10 alloc] initWithTable:self column:9]; \
    _##CName11 = [[OCColumnProxy_##CType11 alloc] initWithTable:self column:10]; \
    _##CName12 = [[OCColumnProxy_##CType12 alloc] initWithTable:self column:11]; \
    _##CName13 = [[OCColumnProxy_##CType13 alloc] initWithTable:self column:12]; \
    return self; \
} \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9 CName10:(TIGHTDB_TYPE_##CType10)CName10 CName11:(TIGHTDB_TYPE_##CType11)CName11 CName12:(TIGHTDB_TYPE_##CType12)CName12 CName13:(TIGHTDB_TYPE_##CType13)CName13 \
{ \
    const size_t ndx = [self count]; \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    TIGHTDB_COLUMN_INSERT(self, 2, ndx, CName3, CType3); \
    TIGHTDB_COLUMN_INSERT(self, 3, ndx, CName4, CType4); \
    TIGHTDB_COLUMN_INSERT(self, 4, ndx, CName5, CType5); \
    TIGHTDB_COLUMN_INSERT(self, 5, ndx, CName6, CType6); \
    TIGHTDB_COLUMN_INSERT(self, 6, ndx, CName7, CType7); \
    TIGHTDB_COLUMN_INSERT(self, 7, ndx, CName8, CType8); \
    TIGHTDB_COLUMN_INSERT(self, 8, ndx, CName9, CType9); \
    TIGHTDB_COLUMN_INSERT(self, 9, ndx, CName10, CType10); \
    TIGHTDB_COLUMN_INSERT(self, 10, ndx, CName11, CType11); \
    TIGHTDB_COLUMN_INSERT(self, 11, ndx, CName12, CType12); \
    TIGHTDB_COLUMN_INSERT(self, 12, ndx, CName13, CType13); \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9 CName10:(TIGHTDB_TYPE_##CType10)CName10 CName11:(TIGHTDB_TYPE_##CType11)CName11 CName12:(TIGHTDB_TYPE_##CType12)CName12 CName13:(TIGHTDB_TYPE_##CType13)CName13 \
{ \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    TIGHTDB_COLUMN_INSERT(self, 2, ndx, CName3, CType3); \
    TIGHTDB_COLUMN_INSERT(self, 3, ndx, CName4, CType4); \
    TIGHTDB_COLUMN_INSERT(self, 4, ndx, CName5, CType5); \
    TIGHTDB_COLUMN_INSERT(self, 5, ndx, CName6, CType6); \
    TIGHTDB_COLUMN_INSERT(self, 6, ndx, CName7, CType7); \
    TIGHTDB_COLUMN_INSERT(self, 7, ndx, CName8, CType8); \
    TIGHTDB_COLUMN_INSERT(self, 8, ndx, CName9, CType9); \
    TIGHTDB_COLUMN_INSERT(self, 9, ndx, CName10, CType10); \
    TIGHTDB_COLUMN_INSERT(self, 10, ndx, CName11, CType11); \
    TIGHTDB_COLUMN_INSERT(self, 11, ndx, CName12, CType12); \
    TIGHTDB_COLUMN_INSERT(self, 12, ndx, CName13, CType13); \
    [self insertDone]; \
} \
-(TableName##_Query *)getQuery \
{ \
    return [[TableName##_Query alloc] initWithTable:self]; \
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
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:self ndx:0]; \
} \
+(BOOL)_checkType:(OCSpec *)spec \
{ \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 0, CName1, CType1) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 1, CName2, CType2) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 2, CName3, CType3) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 3, CName4, CType4) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 4, CName5, CType5) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 5, CName6, CType6) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 6, CName7, CType7) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 7, CName8, CType8) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 8, CName9, CType9) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 9, CName10, CType10) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 10, CName11, CType11) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 11, CName12, CType12) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 12, CName13, CType13) \
    return YES; \
} \
-(BOOL)_checkType \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _checkType:spec]) return NO; \
    return YES; \
} \
+(BOOL)_addColumns:(OCSpec *)spec \
{ \
    TIGHTDB_ADD_COLUMN(spec, CName1, CType1) \
    TIGHTDB_ADD_COLUMN(spec, CName2, CType2) \
    TIGHTDB_ADD_COLUMN(spec, CName3, CType3) \
    TIGHTDB_ADD_COLUMN(spec, CName4, CType4) \
    TIGHTDB_ADD_COLUMN(spec, CName5, CType5) \
    TIGHTDB_ADD_COLUMN(spec, CName6, CType6) \
    TIGHTDB_ADD_COLUMN(spec, CName7, CType7) \
    TIGHTDB_ADD_COLUMN(spec, CName8, CType8) \
    TIGHTDB_ADD_COLUMN(spec, CName9, CType9) \
    TIGHTDB_ADD_COLUMN(spec, CName10, CType10) \
    TIGHTDB_ADD_COLUMN(spec, CName11, CType11) \
    TIGHTDB_ADD_COLUMN(spec, CName12, CType12) \
    TIGHTDB_ADD_COLUMN(spec, CName13, CType13) \
    return YES; \
} \
-(BOOL)_addColumns \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _addColumns:spec]) return NO; \
    [self updateFromSpec]; \
    return YES; \
} \
@end \
@implementation TableName##_View \
{ \
    TableName##_Cursor *tmpCursor; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
} \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
} \
@end

#define TIGHTDB_TABLE_13(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10, CType11, CName11, CType12, CName12, CType13, CName13) \
TIGHTDB_TABLE_DEF_13(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10, CType11, CName11, CType12, CName12, CType13, CName13) \
TIGHTDB_TABLE_IMPL_13(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10, CType11, CName11, CType12, CName12, CType13, CName13)


#define TIGHTDB_TABLE_DEF_14(TableName, CName1, CType1, CName2, CType2, CName3, CType3, CName4, CType4, CName5, CType5, CName6, CType6, CName7, CType7, CName8, CType8, CName9, CType9, CName10, CType10, CName11, CType11, CName12, CType12, CName13, CType13, CName14, CType14) \
@interface TableName##_Cursor : CursorBase \
TIGHTDB_CURSOR_PROPERTY_DEF(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName2, CType2) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName3, CType3) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName4, CType4) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName5, CType5) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName6, CType6) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName7, CType7) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName8, CType8) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName9, CType9) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName10, CType10) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName11, CType11) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName12, CType12) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName13, CType13) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName14, CType14) \
@end \
@class TableName##_Query; \
@class TableName##_View; \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName2, CType2) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName3, CType3) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName4, CType4) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName5, CType5) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName6, CType6) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName7, CType7) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName8, CType8) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName9, CType9) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName10, CType10) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName11, CType11) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName12, CType12) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName13, CType13) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName14, CType14) \
@interface TableName##_Query : Query \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName1 *CName1; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName2 *CName2; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName3 *CName3; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName4 *CName4; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName5 *CName5; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName6 *CName6; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName7 *CName7; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName8 *CName8; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName9 *CName9; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName10 *CName10; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName11 *CName11; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName12 *CName12; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName13 *CName13; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName14 *CName14; \
-(TableName##_Query *)group; \
-(TableName##_Query *)or; \
-(TableName##_Query *)endgroup; \
-(TableName##_Query *)subtable:(size_t)column; \
-(TableName##_Query *)parent; \
-(TableName##_View *)findAll; \
@end \
@interface OCColumnProxy_##TableName : OCColumnProxy \
-(size_t)find:(NSString*)value; \
@end \
@interface TableName : Table \
@property(nonatomic, strong) OCColumnProxy_##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy_##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy_##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy_##CType4 *CName4; \
@property(nonatomic, strong) OCColumnProxy_##CType5 *CName5; \
@property(nonatomic, strong) OCColumnProxy_##CType6 *CName6; \
@property(nonatomic, strong) OCColumnProxy_##CType7 *CName7; \
@property(nonatomic, strong) OCColumnProxy_##CType8 *CName8; \
@property(nonatomic, strong) OCColumnProxy_##CType9 *CName9; \
@property(nonatomic, strong) OCColumnProxy_##CType10 *CName10; \
@property(nonatomic, strong) OCColumnProxy_##CType11 *CName11; \
@property(nonatomic, strong) OCColumnProxy_##CType12 *CName12; \
@property(nonatomic, strong) OCColumnProxy_##CType13 *CName13; \
@property(nonatomic, strong) OCColumnProxy_##CType14 *CName14; \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9 CName10:(TIGHTDB_TYPE_##CType10)CName10 CName11:(TIGHTDB_TYPE_##CType11)CName11 CName12:(TIGHTDB_TYPE_##CType12)CName12 CName13:(TIGHTDB_TYPE_##CType13)CName13 CName14:(TIGHTDB_TYPE_##CType14)CName14; \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9 CName10:(TIGHTDB_TYPE_##CType10)CName10 CName11:(TIGHTDB_TYPE_##CType11)CName11 CName12:(TIGHTDB_TYPE_##CType12)CName12 CName13:(TIGHTDB_TYPE_##CType13)CName13 CName14:(TIGHTDB_TYPE_##CType14)CName14; \
-(TableName##_Query *)getQuery; \
-(TableName##_Cursor *)add; \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_Cursor *)lastObject; \
@end \
typedef TableName* TIGHTDB_TYPE_##TableName; \
@interface TableName##_View : TableView \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
@end

#define TIGHTDB_TABLE_IMPL_14(TableName, CName1, CType1, CName2, CType2, CName3, CType3, CName4, CType4, CName5, CType5, CName6, CType6, CName7, CType7, CName8, CType8, CName9, CType9, CName10, CType10, CName11, CType11, CName12, CType12, CName13, CType13, CName14, CType14) \
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
    OCAccessor *_##CName9; \
    OCAccessor *_##CName10; \
    OCAccessor *_##CName11; \
    OCAccessor *_##CName12; \
    OCAccessor *_##CName13; \
    OCAccessor *_##CName14; \
} \
-(id)initWithTable:(Table *)table ndx:(size_t)ndx \
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
TIGHTDB_CURSOR_PROPERTY_IMPL(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName2, CType2) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName3, CType3) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName4, CType4) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName5, CType5) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName6, CType6) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName7, CType7) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName8, CType8) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName9, CType9) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName10, CType10) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName11, CType11) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName12, CType12) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName13, CType13) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName14, CType14) \
@end \
@implementation TableName##_Query \
{ \
    TableName##_Cursor *tmpCursor; \
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
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
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
        _CName1 = [[TableName##_QueryAccessor_##CName1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##_QueryAccessor_##CName2 alloc] initWithColumn:1 query:self]; \
        _CName3 = [[TableName##_QueryAccessor_##CName3 alloc] initWithColumn:2 query:self]; \
        _CName4 = [[TableName##_QueryAccessor_##CName4 alloc] initWithColumn:3 query:self]; \
        _CName5 = [[TableName##_QueryAccessor_##CName5 alloc] initWithColumn:4 query:self]; \
        _CName6 = [[TableName##_QueryAccessor_##CName6 alloc] initWithColumn:5 query:self]; \
        _CName7 = [[TableName##_QueryAccessor_##CName7 alloc] initWithColumn:6 query:self]; \
        _CName8 = [[TableName##_QueryAccessor_##CName8 alloc] initWithColumn:7 query:self]; \
        _CName9 = [[TableName##_QueryAccessor_##CName9 alloc] initWithColumn:8 query:self]; \
        _CName10 = [[TableName##_QueryAccessor_##CName10 alloc] initWithColumn:9 query:self]; \
        _CName11 = [[TableName##_QueryAccessor_##CName11 alloc] initWithColumn:10 query:self]; \
        _CName12 = [[TableName##_QueryAccessor_##CName12 alloc] initWithColumn:11 query:self]; \
        _CName13 = [[TableName##_QueryAccessor_##CName13 alloc] initWithColumn:12 query:self]; \
        _CName14 = [[TableName##_QueryAccessor_##CName14 alloc] initWithColumn:13 query:self]; \
    } \
    return self; \
} \
-(TableName##_Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_View *)findAll \
{ \
    return [[TableName##_View alloc] initFromQuery:self]; \
} \
@end \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName2, CType2) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName3, CType3) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName4, CType4) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName5, CType5) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName6, CType6) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName7, CType7) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName8, CType8) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName9, CType9) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName10, CType10) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName11, CType11) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName12, CType12) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName13, CType13) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName14, CType14) \
@implementation OCColumnProxy_##TableName \
-(size_t)find:(NSString *)value \
{ \
    return [self.table findString:self.column value:value]; \
} \
@end \
@implementation TableName \
{ \
    TableName##_Cursor *tmpCursor; \
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
-(id)_initRaw \
{ \
    self = [super _initRaw]; \
    if (!self) return nil; \
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    _##CName3 = [[OCColumnProxy_##CType3 alloc] initWithTable:self column:2]; \
    _##CName4 = [[OCColumnProxy_##CType4 alloc] initWithTable:self column:3]; \
    _##CName5 = [[OCColumnProxy_##CType5 alloc] initWithTable:self column:4]; \
    _##CName6 = [[OCColumnProxy_##CType6 alloc] initWithTable:self column:5]; \
    _##CName7 = [[OCColumnProxy_##CType7 alloc] initWithTable:self column:6]; \
    _##CName8 = [[OCColumnProxy_##CType8 alloc] initWithTable:self column:7]; \
    _##CName9 = [[OCColumnProxy_##CType9 alloc] initWithTable:self column:8]; \
    _##CName10 = [[OCColumnProxy_##CType10 alloc] initWithTable:self column:9]; \
    _##CName11 = [[OCColumnProxy_##CType11 alloc] initWithTable:self column:10]; \
    _##CName12 = [[OCColumnProxy_##CType12 alloc] initWithTable:self column:11]; \
    _##CName13 = [[OCColumnProxy_##CType13 alloc] initWithTable:self column:12]; \
    _##CName14 = [[OCColumnProxy_##CType14 alloc] initWithTable:self column:13]; \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (!self) return nil; \
    if (![self _addColumns]) return nil; \
\
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    _##CName3 = [[OCColumnProxy_##CType3 alloc] initWithTable:self column:2]; \
    _##CName4 = [[OCColumnProxy_##CType4 alloc] initWithTable:self column:3]; \
    _##CName5 = [[OCColumnProxy_##CType5 alloc] initWithTable:self column:4]; \
    _##CName6 = [[OCColumnProxy_##CType6 alloc] initWithTable:self column:5]; \
    _##CName7 = [[OCColumnProxy_##CType7 alloc] initWithTable:self column:6]; \
    _##CName8 = [[OCColumnProxy_##CType8 alloc] initWithTable:self column:7]; \
    _##CName9 = [[OCColumnProxy_##CType9 alloc] initWithTable:self column:8]; \
    _##CName10 = [[OCColumnProxy_##CType10 alloc] initWithTable:self column:9]; \
    _##CName11 = [[OCColumnProxy_##CType11 alloc] initWithTable:self column:10]; \
    _##CName12 = [[OCColumnProxy_##CType12 alloc] initWithTable:self column:11]; \
    _##CName13 = [[OCColumnProxy_##CType13 alloc] initWithTable:self column:12]; \
    _##CName14 = [[OCColumnProxy_##CType14 alloc] initWithTable:self column:13]; \
    return self; \
} \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9 CName10:(TIGHTDB_TYPE_##CType10)CName10 CName11:(TIGHTDB_TYPE_##CType11)CName11 CName12:(TIGHTDB_TYPE_##CType12)CName12 CName13:(TIGHTDB_TYPE_##CType13)CName13 CName14:(TIGHTDB_TYPE_##CType14)CName14 \
{ \
    const size_t ndx = [self count]; \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    TIGHTDB_COLUMN_INSERT(self, 2, ndx, CName3, CType3); \
    TIGHTDB_COLUMN_INSERT(self, 3, ndx, CName4, CType4); \
    TIGHTDB_COLUMN_INSERT(self, 4, ndx, CName5, CType5); \
    TIGHTDB_COLUMN_INSERT(self, 5, ndx, CName6, CType6); \
    TIGHTDB_COLUMN_INSERT(self, 6, ndx, CName7, CType7); \
    TIGHTDB_COLUMN_INSERT(self, 7, ndx, CName8, CType8); \
    TIGHTDB_COLUMN_INSERT(self, 8, ndx, CName9, CType9); \
    TIGHTDB_COLUMN_INSERT(self, 9, ndx, CName10, CType10); \
    TIGHTDB_COLUMN_INSERT(self, 10, ndx, CName11, CType11); \
    TIGHTDB_COLUMN_INSERT(self, 11, ndx, CName12, CType12); \
    TIGHTDB_COLUMN_INSERT(self, 12, ndx, CName13, CType13); \
    TIGHTDB_COLUMN_INSERT(self, 13, ndx, CName14, CType14); \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9 CName10:(TIGHTDB_TYPE_##CType10)CName10 CName11:(TIGHTDB_TYPE_##CType11)CName11 CName12:(TIGHTDB_TYPE_##CType12)CName12 CName13:(TIGHTDB_TYPE_##CType13)CName13 CName14:(TIGHTDB_TYPE_##CType14)CName14 \
{ \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    TIGHTDB_COLUMN_INSERT(self, 2, ndx, CName3, CType3); \
    TIGHTDB_COLUMN_INSERT(self, 3, ndx, CName4, CType4); \
    TIGHTDB_COLUMN_INSERT(self, 4, ndx, CName5, CType5); \
    TIGHTDB_COLUMN_INSERT(self, 5, ndx, CName6, CType6); \
    TIGHTDB_COLUMN_INSERT(self, 6, ndx, CName7, CType7); \
    TIGHTDB_COLUMN_INSERT(self, 7, ndx, CName8, CType8); \
    TIGHTDB_COLUMN_INSERT(self, 8, ndx, CName9, CType9); \
    TIGHTDB_COLUMN_INSERT(self, 9, ndx, CName10, CType10); \
    TIGHTDB_COLUMN_INSERT(self, 10, ndx, CName11, CType11); \
    TIGHTDB_COLUMN_INSERT(self, 11, ndx, CName12, CType12); \
    TIGHTDB_COLUMN_INSERT(self, 12, ndx, CName13, CType13); \
    TIGHTDB_COLUMN_INSERT(self, 13, ndx, CName14, CType14); \
    [self insertDone]; \
} \
-(TableName##_Query *)getQuery \
{ \
    return [[TableName##_Query alloc] initWithTable:self]; \
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
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:self ndx:0]; \
} \
+(BOOL)_checkType:(OCSpec *)spec \
{ \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 0, CName1, CType1) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 1, CName2, CType2) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 2, CName3, CType3) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 3, CName4, CType4) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 4, CName5, CType5) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 5, CName6, CType6) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 6, CName7, CType7) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 7, CName8, CType8) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 8, CName9, CType9) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 9, CName10, CType10) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 10, CName11, CType11) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 11, CName12, CType12) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 12, CName13, CType13) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 13, CName14, CType14) \
    return YES; \
} \
-(BOOL)_checkType \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _checkType:spec]) return NO; \
    return YES; \
} \
+(BOOL)_addColumns:(OCSpec *)spec \
{ \
    TIGHTDB_ADD_COLUMN(spec, CName1, CType1) \
    TIGHTDB_ADD_COLUMN(spec, CName2, CType2) \
    TIGHTDB_ADD_COLUMN(spec, CName3, CType3) \
    TIGHTDB_ADD_COLUMN(spec, CName4, CType4) \
    TIGHTDB_ADD_COLUMN(spec, CName5, CType5) \
    TIGHTDB_ADD_COLUMN(spec, CName6, CType6) \
    TIGHTDB_ADD_COLUMN(spec, CName7, CType7) \
    TIGHTDB_ADD_COLUMN(spec, CName8, CType8) \
    TIGHTDB_ADD_COLUMN(spec, CName9, CType9) \
    TIGHTDB_ADD_COLUMN(spec, CName10, CType10) \
    TIGHTDB_ADD_COLUMN(spec, CName11, CType11) \
    TIGHTDB_ADD_COLUMN(spec, CName12, CType12) \
    TIGHTDB_ADD_COLUMN(spec, CName13, CType13) \
    TIGHTDB_ADD_COLUMN(spec, CName14, CType14) \
    return YES; \
} \
-(BOOL)_addColumns \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _addColumns:spec]) return NO; \
    [self updateFromSpec]; \
    return YES; \
} \
@end \
@implementation TableName##_View \
{ \
    TableName##_Cursor *tmpCursor; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
} \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
} \
@end

#define TIGHTDB_TABLE_14(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10, CType11, CName11, CType12, CName12, CType13, CName13, CType14, CName14) \
TIGHTDB_TABLE_DEF_14(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10, CType11, CName11, CType12, CName12, CType13, CName13, CType14, CName14) \
TIGHTDB_TABLE_IMPL_14(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10, CType11, CName11, CType12, CName12, CType13, CName13, CType14, CName14)


#define TIGHTDB_TABLE_DEF_15(TableName, CName1, CType1, CName2, CType2, CName3, CType3, CName4, CType4, CName5, CType5, CName6, CType6, CName7, CType7, CName8, CType8, CName9, CType9, CName10, CType10, CName11, CType11, CName12, CType12, CName13, CType13, CName14, CType14, CName15, CType15) \
@interface TableName##_Cursor : CursorBase \
TIGHTDB_CURSOR_PROPERTY_DEF(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName2, CType2) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName3, CType3) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName4, CType4) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName5, CType5) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName6, CType6) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName7, CType7) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName8, CType8) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName9, CType9) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName10, CType10) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName11, CType11) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName12, CType12) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName13, CType13) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName14, CType14) \
TIGHTDB_CURSOR_PROPERTY_DEF(CName15, CType15) \
@end \
@class TableName##_Query; \
@class TableName##_View; \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName2, CType2) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName3, CType3) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName4, CType4) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName5, CType5) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName6, CType6) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName7, CType7) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName8, CType8) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName9, CType9) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName10, CType10) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName11, CType11) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName12, CType12) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName13, CType13) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName14, CType14) \
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName15, CType15) \
@interface TableName##_Query : Query \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName1 *CName1; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName2 *CName2; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName3 *CName3; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName4 *CName4; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName5 *CName5; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName6 *CName6; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName7 *CName7; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName8 *CName8; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName9 *CName9; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName10 *CName10; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName11 *CName11; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName12 *CName12; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName13 *CName13; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName14 *CName14; \
@property(nonatomic, strong) TableName##_QueryAccessor_##CName15 *CName15; \
-(TableName##_Query *)group; \
-(TableName##_Query *)or; \
-(TableName##_Query *)endgroup; \
-(TableName##_Query *)subtable:(size_t)column; \
-(TableName##_Query *)parent; \
-(TableName##_View *)findAll; \
@end \
@interface OCColumnProxy_##TableName : OCColumnProxy \
-(size_t)find:(NSString*)value; \
@end \
@interface TableName : Table \
@property(nonatomic, strong) OCColumnProxy_##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy_##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy_##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy_##CType4 *CName4; \
@property(nonatomic, strong) OCColumnProxy_##CType5 *CName5; \
@property(nonatomic, strong) OCColumnProxy_##CType6 *CName6; \
@property(nonatomic, strong) OCColumnProxy_##CType7 *CName7; \
@property(nonatomic, strong) OCColumnProxy_##CType8 *CName8; \
@property(nonatomic, strong) OCColumnProxy_##CType9 *CName9; \
@property(nonatomic, strong) OCColumnProxy_##CType10 *CName10; \
@property(nonatomic, strong) OCColumnProxy_##CType11 *CName11; \
@property(nonatomic, strong) OCColumnProxy_##CType12 *CName12; \
@property(nonatomic, strong) OCColumnProxy_##CType13 *CName13; \
@property(nonatomic, strong) OCColumnProxy_##CType14 *CName14; \
@property(nonatomic, strong) OCColumnProxy_##CType15 *CName15; \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9 CName10:(TIGHTDB_TYPE_##CType10)CName10 CName11:(TIGHTDB_TYPE_##CType11)CName11 CName12:(TIGHTDB_TYPE_##CType12)CName12 CName13:(TIGHTDB_TYPE_##CType13)CName13 CName14:(TIGHTDB_TYPE_##CType14)CName14 CName15:(TIGHTDB_TYPE_##CType15)CName15; \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9 CName10:(TIGHTDB_TYPE_##CType10)CName10 CName11:(TIGHTDB_TYPE_##CType11)CName11 CName12:(TIGHTDB_TYPE_##CType12)CName12 CName13:(TIGHTDB_TYPE_##CType13)CName13 CName14:(TIGHTDB_TYPE_##CType14)CName14 CName15:(TIGHTDB_TYPE_##CType15)CName15; \
-(TableName##_Query *)getQuery; \
-(TableName##_Cursor *)add; \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
-(TableName##_Cursor *)lastObject; \
@end \
typedef TableName* TIGHTDB_TYPE_##TableName; \
@interface TableName##_View : TableView \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \
@end

#define TIGHTDB_TABLE_IMPL_15(TableName, CName1, CType1, CName2, CType2, CName3, CType3, CName4, CType4, CName5, CType5, CName6, CType6, CName7, CType7, CName8, CType8, CName9, CType9, CName10, CType10, CName11, CType11, CName12, CType12, CName13, CType13, CName14, CType14, CName15, CType15) \
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
    OCAccessor *_##CName9; \
    OCAccessor *_##CName10; \
    OCAccessor *_##CName11; \
    OCAccessor *_##CName12; \
    OCAccessor *_##CName13; \
    OCAccessor *_##CName14; \
    OCAccessor *_##CName15; \
} \
-(id)initWithTable:(Table *)table ndx:(size_t)ndx \
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
TIGHTDB_CURSOR_PROPERTY_IMPL(CName1, CType1) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName2, CType2) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName3, CType3) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName4, CType4) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName5, CType5) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName6, CType6) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName7, CType7) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName8, CType8) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName9, CType9) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName10, CType10) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName11, CType11) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName12, CType12) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName13, CType13) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName14, CType14) \
TIGHTDB_CURSOR_PROPERTY_IMPL(CName15, CType15) \
@end \
@implementation TableName##_Query \
{ \
    TableName##_Cursor *tmpCursor; \
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
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \
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
        _CName1 = [[TableName##_QueryAccessor_##CName1 alloc] initWithColumn:0 query:self]; \
        _CName2 = [[TableName##_QueryAccessor_##CName2 alloc] initWithColumn:1 query:self]; \
        _CName3 = [[TableName##_QueryAccessor_##CName3 alloc] initWithColumn:2 query:self]; \
        _CName4 = [[TableName##_QueryAccessor_##CName4 alloc] initWithColumn:3 query:self]; \
        _CName5 = [[TableName##_QueryAccessor_##CName5 alloc] initWithColumn:4 query:self]; \
        _CName6 = [[TableName##_QueryAccessor_##CName6 alloc] initWithColumn:5 query:self]; \
        _CName7 = [[TableName##_QueryAccessor_##CName7 alloc] initWithColumn:6 query:self]; \
        _CName8 = [[TableName##_QueryAccessor_##CName8 alloc] initWithColumn:7 query:self]; \
        _CName9 = [[TableName##_QueryAccessor_##CName9 alloc] initWithColumn:8 query:self]; \
        _CName10 = [[TableName##_QueryAccessor_##CName10 alloc] initWithColumn:9 query:self]; \
        _CName11 = [[TableName##_QueryAccessor_##CName11 alloc] initWithColumn:10 query:self]; \
        _CName12 = [[TableName##_QueryAccessor_##CName12 alloc] initWithColumn:11 query:self]; \
        _CName13 = [[TableName##_QueryAccessor_##CName13 alloc] initWithColumn:12 query:self]; \
        _CName14 = [[TableName##_QueryAccessor_##CName14 alloc] initWithColumn:13 query:self]; \
        _CName15 = [[TableName##_QueryAccessor_##CName15 alloc] initWithColumn:14 query:self]; \
    } \
    return self; \
} \
-(TableName##_Query *)group \
{ \
    [super group]; \
    return self; \
} \
-(TableName##_Query *)or \
{ \
    [super or]; \
    return self; \
} \
-(TableName##_Query *)endgroup \
{ \
    [super endgroup]; \
    return self; \
} \
-(TableName##_Query *)subtable:(size_t)column \
{ \
    [super subtable:column]; \
    return self; \
} \
-(TableName##_Query *)parent \
{ \
    [super parent]; \
    return self; \
} \
-(TableName##_View *)findAll \
{ \
    return [[TableName##_View alloc] initFromQuery:self]; \
} \
@end \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName1, CType1) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName2, CType2) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName3, CType3) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName4, CType4) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName5, CType5) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName6, CType6) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName7, CType7) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName8, CType8) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName9, CType9) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName10, CType10) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName11, CType11) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName12, CType12) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName13, CType13) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName14, CType14) \
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName15, CType15) \
@implementation OCColumnProxy_##TableName \
-(size_t)find:(NSString *)value \
{ \
    return [self.table findString:self.column value:value]; \
} \
@end \
@implementation TableName \
{ \
    TableName##_Cursor *tmpCursor; \
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
-(id)_initRaw \
{ \
    self = [super _initRaw]; \
    if (!self) return nil; \
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    _##CName3 = [[OCColumnProxy_##CType3 alloc] initWithTable:self column:2]; \
    _##CName4 = [[OCColumnProxy_##CType4 alloc] initWithTable:self column:3]; \
    _##CName5 = [[OCColumnProxy_##CType5 alloc] initWithTable:self column:4]; \
    _##CName6 = [[OCColumnProxy_##CType6 alloc] initWithTable:self column:5]; \
    _##CName7 = [[OCColumnProxy_##CType7 alloc] initWithTable:self column:6]; \
    _##CName8 = [[OCColumnProxy_##CType8 alloc] initWithTable:self column:7]; \
    _##CName9 = [[OCColumnProxy_##CType9 alloc] initWithTable:self column:8]; \
    _##CName10 = [[OCColumnProxy_##CType10 alloc] initWithTable:self column:9]; \
    _##CName11 = [[OCColumnProxy_##CType11 alloc] initWithTable:self column:10]; \
    _##CName12 = [[OCColumnProxy_##CType12 alloc] initWithTable:self column:11]; \
    _##CName13 = [[OCColumnProxy_##CType13 alloc] initWithTable:self column:12]; \
    _##CName14 = [[OCColumnProxy_##CType14 alloc] initWithTable:self column:13]; \
    _##CName15 = [[OCColumnProxy_##CType15 alloc] initWithTable:self column:14]; \
    return self; \
} \
-(id)init \
{ \
    self = [super init]; \
    if (!self) return nil; \
    if (![self _addColumns]) return nil; \
\
    _##CName1 = [[OCColumnProxy_##CType1 alloc] initWithTable:self column:0]; \
    _##CName2 = [[OCColumnProxy_##CType2 alloc] initWithTable:self column:1]; \
    _##CName3 = [[OCColumnProxy_##CType3 alloc] initWithTable:self column:2]; \
    _##CName4 = [[OCColumnProxy_##CType4 alloc] initWithTable:self column:3]; \
    _##CName5 = [[OCColumnProxy_##CType5 alloc] initWithTable:self column:4]; \
    _##CName6 = [[OCColumnProxy_##CType6 alloc] initWithTable:self column:5]; \
    _##CName7 = [[OCColumnProxy_##CType7 alloc] initWithTable:self column:6]; \
    _##CName8 = [[OCColumnProxy_##CType8 alloc] initWithTable:self column:7]; \
    _##CName9 = [[OCColumnProxy_##CType9 alloc] initWithTable:self column:8]; \
    _##CName10 = [[OCColumnProxy_##CType10 alloc] initWithTable:self column:9]; \
    _##CName11 = [[OCColumnProxy_##CType11 alloc] initWithTable:self column:10]; \
    _##CName12 = [[OCColumnProxy_##CType12 alloc] initWithTable:self column:11]; \
    _##CName13 = [[OCColumnProxy_##CType13 alloc] initWithTable:self column:12]; \
    _##CName14 = [[OCColumnProxy_##CType14 alloc] initWithTable:self column:13]; \
    _##CName15 = [[OCColumnProxy_##CType15 alloc] initWithTable:self column:14]; \
    return self; \
} \
-(void)add##CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9 CName10:(TIGHTDB_TYPE_##CType10)CName10 CName11:(TIGHTDB_TYPE_##CType11)CName11 CName12:(TIGHTDB_TYPE_##CType12)CName12 CName13:(TIGHTDB_TYPE_##CType13)CName13 CName14:(TIGHTDB_TYPE_##CType14)CName14 CName15:(TIGHTDB_TYPE_##CType15)CName15 \
{ \
    const size_t ndx = [self count]; \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    TIGHTDB_COLUMN_INSERT(self, 2, ndx, CName3, CType3); \
    TIGHTDB_COLUMN_INSERT(self, 3, ndx, CName4, CType4); \
    TIGHTDB_COLUMN_INSERT(self, 4, ndx, CName5, CType5); \
    TIGHTDB_COLUMN_INSERT(self, 5, ndx, CName6, CType6); \
    TIGHTDB_COLUMN_INSERT(self, 6, ndx, CName7, CType7); \
    TIGHTDB_COLUMN_INSERT(self, 7, ndx, CName8, CType8); \
    TIGHTDB_COLUMN_INSERT(self, 8, ndx, CName9, CType9); \
    TIGHTDB_COLUMN_INSERT(self, 9, ndx, CName10, CType10); \
    TIGHTDB_COLUMN_INSERT(self, 10, ndx, CName11, CType11); \
    TIGHTDB_COLUMN_INSERT(self, 11, ndx, CName12, CType12); \
    TIGHTDB_COLUMN_INSERT(self, 12, ndx, CName13, CType13); \
    TIGHTDB_COLUMN_INSERT(self, 13, ndx, CName14, CType14); \
    TIGHTDB_COLUMN_INSERT(self, 14, ndx, CName15, CType15); \
    [self insertDone]; \
} \
-(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_TYPE_##CType1)CName1 CName2:(TIGHTDB_TYPE_##CType2)CName2 CName3:(TIGHTDB_TYPE_##CType3)CName3 CName4:(TIGHTDB_TYPE_##CType4)CName4 CName5:(TIGHTDB_TYPE_##CType5)CName5 CName6:(TIGHTDB_TYPE_##CType6)CName6 CName7:(TIGHTDB_TYPE_##CType7)CName7 CName8:(TIGHTDB_TYPE_##CType8)CName8 CName9:(TIGHTDB_TYPE_##CType9)CName9 CName10:(TIGHTDB_TYPE_##CType10)CName10 CName11:(TIGHTDB_TYPE_##CType11)CName11 CName12:(TIGHTDB_TYPE_##CType12)CName12 CName13:(TIGHTDB_TYPE_##CType13)CName13 CName14:(TIGHTDB_TYPE_##CType14)CName14 CName15:(TIGHTDB_TYPE_##CType15)CName15 \
{ \
    TIGHTDB_COLUMN_INSERT(self, 0, ndx, CName1, CType1); \
    TIGHTDB_COLUMN_INSERT(self, 1, ndx, CName2, CType2); \
    TIGHTDB_COLUMN_INSERT(self, 2, ndx, CName3, CType3); \
    TIGHTDB_COLUMN_INSERT(self, 3, ndx, CName4, CType4); \
    TIGHTDB_COLUMN_INSERT(self, 4, ndx, CName5, CType5); \
    TIGHTDB_COLUMN_INSERT(self, 5, ndx, CName6, CType6); \
    TIGHTDB_COLUMN_INSERT(self, 6, ndx, CName7, CType7); \
    TIGHTDB_COLUMN_INSERT(self, 7, ndx, CName8, CType8); \
    TIGHTDB_COLUMN_INSERT(self, 8, ndx, CName9, CType9); \
    TIGHTDB_COLUMN_INSERT(self, 9, ndx, CName10, CType10); \
    TIGHTDB_COLUMN_INSERT(self, 10, ndx, CName11, CType11); \
    TIGHTDB_COLUMN_INSERT(self, 11, ndx, CName12, CType12); \
    TIGHTDB_COLUMN_INSERT(self, 12, ndx, CName13, CType13); \
    TIGHTDB_COLUMN_INSERT(self, 13, ndx, CName14, CType14); \
    TIGHTDB_COLUMN_INSERT(self, 14, ndx, CName15, CType15); \
    [self insertDone]; \
} \
-(TableName##_Query *)getQuery \
{ \
    return [[TableName##_Query alloc] initWithTable:self]; \
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
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:self ndx:0]; \
} \
+(BOOL)_checkType:(OCSpec *)spec \
{ \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 0, CName1, CType1) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 1, CName2, CType2) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 2, CName3, CType3) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 3, CName4, CType4) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 4, CName5, CType5) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 5, CName6, CType6) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 6, CName7, CType7) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 7, CName8, CType8) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 8, CName9, CType9) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 9, CName10, CType10) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 10, CName11, CType11) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 11, CName12, CType12) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 12, CName13, CType13) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 13, CName14, CType14) \
    TIGHTDB_CHECK_COLUMN_TYPE(spec, 14, CName15, CType15) \
    return YES; \
} \
-(BOOL)_checkType \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _checkType:spec]) return NO; \
    return YES; \
} \
+(BOOL)_addColumns:(OCSpec *)spec \
{ \
    TIGHTDB_ADD_COLUMN(spec, CName1, CType1) \
    TIGHTDB_ADD_COLUMN(spec, CName2, CType2) \
    TIGHTDB_ADD_COLUMN(spec, CName3, CType3) \
    TIGHTDB_ADD_COLUMN(spec, CName4, CType4) \
    TIGHTDB_ADD_COLUMN(spec, CName5, CType5) \
    TIGHTDB_ADD_COLUMN(spec, CName6, CType6) \
    TIGHTDB_ADD_COLUMN(spec, CName7, CType7) \
    TIGHTDB_ADD_COLUMN(spec, CName8, CType8) \
    TIGHTDB_ADD_COLUMN(spec, CName9, CType9) \
    TIGHTDB_ADD_COLUMN(spec, CName10, CType10) \
    TIGHTDB_ADD_COLUMN(spec, CName11, CType11) \
    TIGHTDB_ADD_COLUMN(spec, CName12, CType12) \
    TIGHTDB_ADD_COLUMN(spec, CName13, CType13) \
    TIGHTDB_ADD_COLUMN(spec, CName14, CType14) \
    TIGHTDB_ADD_COLUMN(spec, CName15, CType15) \
    return YES; \
} \
-(BOOL)_addColumns \
{ \
    OCSpec *spec = [self getSpec]; \
    if (!spec) return NO; \
    if (![TableName _addColumns:spec]) return NO; \
    [self updateFromSpec]; \
    return YES; \
} \
@end \
@implementation TableName##_View \
{ \
    TableName##_Cursor *tmpCursor; \
} \
-(CursorBase *)getCursor \
{ \
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \
} \
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx \
{ \
    return [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \
} \
@end

#define TIGHTDB_TABLE_15(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10, CType11, CName11, CType12, CName12, CType13, CName13, CType14, CName14, CType15, CName15) \
TIGHTDB_TABLE_DEF_15(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10, CType11, CName11, CType12, CName12, CType13, CName13, CType14, CName14, CType15, CName15) \
TIGHTDB_TABLE_IMPL_15(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8, CType9, CName9, CType10, CName10, CType11, CName11, CType12, CName12, CType13, CName13, CType14, CName14, CType15, CName15)
