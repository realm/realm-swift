import sys
from Cheetah.Template import Template

templateDef = """#slurp
#compiler-settings
commentStartToken = %%
directiveStartToken = %
#end compiler-settings
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
%for $i in range($max_cols)
%set $num_cols = $i + 1


#define TIGHTDB_TABLE_DEF_${num_cols}(TableName%slurp
%for $j in range($num_cols)
, CName${j+1}, CType${j+1}%slurp
%end for
) \\
@interface TableName##_Cursor : CursorBase \\
%for $j in range($num_cols)
TIGHTDB_CURSOR_PROPERTY_DEF(CName${j+1}, CType${j+1}) \\
%end for
@end \\
@class TableName##_Query; \\
@class TableName##_View; \\
%for $j in range($num_cols)
TIGHTDB_QUERY_ACCESSOR_DEF(TableName, CName${j+1}, CType${j+1}) \\
%end for
@interface TableName##_Query : Query \\
%for $j in range($num_cols)
@property(nonatomic, strong) TableName##_QueryAccessor_##CName${j+1} *CName${j+1}; \\
%end for
-(TableName##_Query *)group; \\
-(TableName##_Query *)or; \\
-(TableName##_Query *)endgroup; \\
-(TableName##_Query *)subtable:(size_t)column; \\
-(TableName##_Query *)parent; \\
-(TableName##_View *)findAll; \\
@end \\
@interface TableName : Table \\
%for $j in range($num_cols)
TIGHTDB_COLUMN_PROXY_DEF(CName${j+1}, CType${j+1}) \\
%end for
-(void)add##%slurp
%for $j in range($num_cols)
%if 0 < $j
%echo ' '
%end if
CName${j+1}:(TIGHTDB_ARG_TYPE(CType${j+1}))CName${j+1}%slurp
%end for
; \\
-(void)insertAtIndex:(size_t)ndx%slurp
%for $j in range($num_cols)
 CName${j+1}:(TIGHTDB_ARG_TYPE(CType${j+1}))CName${j+1}%slurp
%end for
; \\
-(TableName##_Query *)where; \\
-(TableName##_Cursor *)add; \\
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \\
-(TableName##_Cursor *)lastObject; \\
@end \\
@interface TableName##_View : TableView \\
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \\
@end

#define TIGHTDB_TABLE_IMPL_${num_cols}(TableName%slurp
%for $j in range($num_cols)
, CName${j+1}, CType${j+1}%slurp
%end for
) \\
@implementation TableName##_Cursor \\
{ \\
%for $j in range($num_cols)
    OCAccessor *_##CName${j+1}; \\
%end for
} \\
-(id)initWithTable:(Table *)table ndx:(size_t)ndx \\
{ \\
    self = [super initWithTable:table ndx:ndx]; \\
    if (self) { \\
%for $j in range($num_cols)
        _##CName${j+1} = [[OCAccessor alloc] initWithCursor:self columnId:${j}]; \\
%end for
    } \\
    return self; \\
} \\
%for $j in range($num_cols)
TIGHTDB_CURSOR_PROPERTY_IMPL(CName${j+1}, CType${j+1}) \\
%end for
@end \\
@implementation TableName##_Query \\
{ \\
    TableName##_Cursor *tmpCursor; \\
} \\
-(long)getFastEnumStart \\
{ \\
    return [self findNext:-1]; \\
} \\
-(long)incrementFastEnum:(long)ndx \\
{ \\
    return [self findNext:ndx]; \\
} \\
-(CursorBase *)getCursor:(long)ndx \\
{ \\
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:ndx]; \\
} \\
%for $j in range($num_cols)
@synthesize CName${j+1} = _CName${j+1}; \\
%end for
-(id)initWithTable:(Table *)table \\
{ \\
    self = [super initWithTable:table]; \\
    if (self) { \\
%for $j in range($num_cols)
        _CName${j+1} = [[TableName##_QueryAccessor_##CName${j+1} alloc] initWithColumn:${j} query:self]; \\
%end for
    } \\
    return self; \\
} \\
-(TableName##_Query *)group \\
{ \\
    [super group]; \\
    return self; \\
} \\
-(TableName##_Query *)or \\
{ \\
    [super or]; \\
    return self; \\
} \\
-(TableName##_Query *)endgroup \\
{ \\
    [super endgroup]; \\
    return self; \\
} \\
-(TableName##_Query *)subtable:(size_t)column \\
{ \\
    [super subtable:column]; \\
    return self; \\
} \\
-(TableName##_Query *)parent \\
{ \\
    [super parent]; \\
    return self; \\
} \\
-(TableName##_View *)findAll \\
{ \\
    return [[TableName##_View alloc] initFromQuery:self]; \\
} \\
@end \\
%for $j in range($num_cols)
TIGHTDB_QUERY_ACCESSOR_IMPL(TableName, CName${j+1}, CType${j+1}) \\
%end for
@implementation TableName \\
{ \\
    TableName##_Cursor *tmpCursor; \\
} \\
%for $j in range($num_cols)
TIGHTDB_COLUMN_PROXY_IMPL(CName${j+1}, CType${j+1}) \\
%end for
\\
-(id)_initRaw \\
{ \\
    self = [super _initRaw]; \\
    if (!self) return nil; \\
%for $j in range($num_cols)
    TIGHTDB_COLUMN_PROXY_INIT(self, ${j}, CName${j+1}, CType${j+1}); \\
%end for
    return self; \\
} \\
-(id)init \\
{ \\
    self = [super init]; \\
    if (!self) return nil; \\
    if (![self _addColumns]) return nil; \\
\\
%for $j in range($num_cols)
    TIGHTDB_COLUMN_PROXY_INIT(self, ${j}, CName${j+1}, CType${j+1}); \\
%end for
    return self; \\
} \\
-(void)add##%slurp
%for $j in range($num_cols)
CName${j+1}:(TIGHTDB_ARG_TYPE(CType${j+1}))CName${j+1} %slurp
%end for
\\
{ \\
    const size_t ndx = [self count]; \\
%for $j in range($num_cols)
    TIGHTDB_COLUMN_INSERT(self, ${j}, ndx, CName${j+1}, CType${j+1}); \\
%end for
    [self insertDone]; \\
} \\
-(void)insertAtIndex:(size_t)ndx %slurp
%for $j in range($num_cols)
CName${j+1}:(TIGHTDB_ARG_TYPE(CType${j+1}))CName${j+1} %slurp
%end for
\\
{ \\
%for $j in range($num_cols)
    TIGHTDB_COLUMN_INSERT(self, ${j}, ndx, CName${j+1}, CType${j+1}); \\
%end for
    [self insertDone]; \\
} \\
-(TableName##_Query *)where \\
{ \\
    return [[TableName##_Query alloc] initWithTable:self]; \\
} \\
-(TableName##_Cursor *)add \\
{ \\
    return [[TableName##_Cursor alloc] initWithTable:self ndx:[self addRow]]; \\
} \\
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx \\
{ \\
    return [[TableName##_Cursor alloc] initWithTable:self ndx:ndx]; \\
} \\
-(TableName##_Cursor *)lastObject \\
{ \\
    return [[TableName##_Cursor alloc] initWithTable:self ndx:[self count]-1]; \\
} \\
-(CursorBase *)getCursor \\
{ \\
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:self ndx:0]; \\
} \\
+(BOOL)_checkType:(OCSpec *)spec \\
{ \\
%for $j in range($num_cols)
    TIGHTDB_CHECK_COLUMN_TYPE(spec, ${j}, CName${j+1}, CType${j+1}) \\
%end for
    return YES; \\
} \\
-(BOOL)_checkType \\
{ \\
    OCSpec *spec = [self getSpec]; \\
    if (!spec) return NO; \\
    if (![TableName _checkType:spec]) return NO; \\
    return YES; \\
} \\
+(BOOL)_addColumns:(OCSpec *)spec \\
{ \\
%for $j in range($num_cols)
    TIGHTDB_ADD_COLUMN(spec, CName${j+1}, CType${j+1}) \\
%end for
    return YES; \\
} \\
-(BOOL)_addColumns \\
{ \\
    OCSpec *spec = [self getSpec]; \\
    if (!spec) return NO; \\
    if (![TableName _addColumns:spec]) return NO; \\
    [self updateFromSpec]; \\
    return YES; \\
} \\
@end \\
@implementation TableName##_View \\
{ \\
    TableName##_Cursor *tmpCursor; \\
} \\
-(CursorBase *)getCursor \\
{ \\
    return tmpCursor = [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:0]]; \\
} \\
-(TableName##_Cursor *)objectAtIndex:(size_t)ndx \\
{ \\
    return [[TableName##_Cursor alloc] initWithTable:[self getTable] ndx:[self getSourceNdx:ndx]]; \\
} \\
@end

#define TIGHTDB_TABLE_${num_cols}(TableName%slurp
%for $j in range($num_cols)
, CType${j+1}, CName${j+1}%slurp
%end for
) \\
TIGHTDB_TABLE_DEF_${num_cols}(TableName%slurp
%for $j in range($num_cols)
, CType${j+1}, CName${j+1}%slurp
%end for
) \\
TIGHTDB_TABLE_IMPL_${num_cols}(TableName%slurp
%for $j in range($num_cols)
, CType${j+1}, CName${j+1}%slurp
%end for
)
%end for
"""

args = sys.argv[1:]
if len(args) != 1:
    sys.stderr.write("Please specify the maximum number of table columns\n")
    sys.exit(1)
max_cols = int(args[0])
t = Template(templateDef, searchList=[{'max_cols': max_cols}])
sys.stdout.write(str(t))
