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

#define TIGHTDB_VA_NARGS_IMPL(_1, _2, _3, _4, _5, N, ...) N
#define TIGHTDB_VA_NARGS(...) TIGHTDB_VA_NARGS_IMPL(__VA_ARGS__, 5, 4, 3, 2, 1)

#define TIGHTDB_IS_SUBTABLE(col_type) TIGHTDB_IS_SUBTABLE_2(TIGHTDB_IS_SUBTABLE_##col_type)
#define TIGHTDB_IS_SUBTABLE_2(...)    TIGHTDB_IS_SUBTABLE_3(TIGHTDB_VA_NARGS(__VA_ARGS__))
#define TIGHTDB_IS_SUBTABLE_3(count)  TIGHTDB_IS_SUBTABLE_4(count)
#define TIGHTDB_IS_SUBTABLE_4(count)  TIGHTDB_IS_SUBTABLE_5_##count
#define TIGHTDB_IS_SUBTABLE_5_1       Y
#define TIGHTDB_IS_SUBTABLE_5_2       N
#define TIGHTDB_IS_SUBTABLE_Int       x,x
#define TIGHTDB_IS_SUBTABLE_Bool      x,x
#define TIGHTDB_IS_SUBTABLE_Float     x,x
#define TIGHTDB_IS_SUBTABLE_Double    x,x
#define TIGHTDB_IS_SUBTABLE_String    x,x
#define TIGHTDB_IS_SUBTABLE_Binary    x,x
#define TIGHTDB_IS_SUBTABLE_Date      x,x
#define TIGHTDB_IS_SUBTABLE_Mixed     x,x

#define TIGHTDB_TYPE_Bool      BOOL
#define TIGHTDB_TYPE_Int       int64_t
#define TIGHTDB_TYPE_Float     float
#define TIGHTDB_TYPE_Double    double
#define TIGHTDB_TYPE_String    NSString *
#define TIGHTDB_TYPE_Binary    TightdbBinary *
#define TIGHTDB_TYPE_Date      time_t
#define TIGHTDB_TYPE_Mixed     TightdbMixed *

#define TIGHTDB_TYPE_ID_Bool   tightdb_Bool
#define TIGHTDB_TYPE_ID_Int    tightdb_Int
#define TIGHTDB_TYPE_ID_Float  tightdb_Float
#define TIGHTDB_TYPE_ID_Double tightdb_Double
#define TIGHTDB_TYPE_ID_String tightdb_String
#define TIGHTDB_TYPE_ID_Binary tightdb_Binary
#define TIGHTDB_TYPE_ID_Date   tightdb_Date
#define TIGHTDB_TYPE_ID_Mixed  tightdb_Mixed



// TIGHTDB_ARG_TYPE

#define TIGHTDB_ARG_TYPE(type)                 TIGHTDB_ARG_TYPE_2(TIGHTDB_IS_SUBTABLE(type), type)
#define TIGHTDB_ARG_TYPE_2(is_subtable, type)  TIGHTDB_ARG_TYPE_3(is_subtable, type)
#define TIGHTDB_ARG_TYPE_3(is_subtable, type)  TIGHTDB_ARG_TYPE_4_##is_subtable(type)
#define TIGHTDB_ARG_TYPE_4_Y(type)             type *
#define TIGHTDB_ARG_TYPE_4_N(type)             TIGHTDB_TYPE_##type



// TIGHTDB_COLUMN_PROXY

#define TIGHTDB_COLUMN_PROXY_DEF(name, type)                 TIGHTDB_COLUMN_PROXY_DEF_2(TIGHTDB_IS_SUBTABLE(type), name, type)
#define TIGHTDB_COLUMN_PROXY_DEF_2(is_subtable, name, type)  TIGHTDB_COLUMN_PROXY_DEF_3(is_subtable, name, type)
#define TIGHTDB_COLUMN_PROXY_DEF_3(is_subtable, name, type)  TIGHTDB_COLUMN_PROXY_DEF_4_##is_subtable(name, type)
#define TIGHTDB_COLUMN_PROXY_DEF_4_Y(name, type)             @property(nonatomic, strong) TightdbColumnProxy_Subtable *name;
#define TIGHTDB_COLUMN_PROXY_DEF_4_N(name, type)             @property(nonatomic, strong) TightdbColumnProxy_##type *name;

#define TIGHTDB_COLUMN_PROXY_IMPL(name, type)                @synthesize name = _##name;

#define TIGHTDB_COLUMN_PROXY_INIT(table, col, name, type)                TIGHTDB_COLUMN_PROXY_INIT_2(TIGHTDB_IS_SUBTABLE(type), table, col, name, type)
#define TIGHTDB_COLUMN_PROXY_INIT_2(is_subtable, table, col, name, type) TIGHTDB_COLUMN_PROXY_INIT_3(is_subtable, table, col, name, type)
#define TIGHTDB_COLUMN_PROXY_INIT_3(is_subtable, table, col, name, type) TIGHTDB_COLUMN_PROXY_INIT_4_##is_subtable(table, col, name, type)
#define TIGHTDB_COLUMN_PROXY_INIT_4_Y(table, col, name, type)            _##name = [[TightdbColumnProxy_Subtable alloc] initWithTable:table column:col]
#define TIGHTDB_COLUMN_PROXY_INIT_4_N(table, col, name, type)            _##name = [[TightdbColumnProxy_##type alloc] initWithTable:table column:col]



// TIGHTDB_ADD_COLUMN

#define TIGHTDB_ADD_COLUMN(spec, name, type)                TIGHTDB_ADD_COLUMN_2(TIGHTDB_IS_SUBTABLE(type), spec, name, type)
#define TIGHTDB_ADD_COLUMN_2(is_subtable, spec, name, type) TIGHTDB_ADD_COLUMN_3(is_subtable, spec, name, type)
#define TIGHTDB_ADD_COLUMN_3(is_subtable, spec, name, type) TIGHTDB_ADD_COLUMN_4_##is_subtable(spec, name, type)
#define TIGHTDB_ADD_COLUMN_4_Y(spec, _name, type) \
{ \
    NSString *name = [NSString stringWithUTF8String:#_name]; \
    if (!name) return NO; \
    TightdbSpec *subspec = [spec addColumnTable:name]; \
    if (!subspec) return NO; \
    if (![type _addColumns:subspec]) return NO; \
}
#define TIGHTDB_ADD_COLUMN_4_N(spec, _name, type) \
{ \
    NSString *name = [NSString stringWithUTF8String:#_name]; \
    if (!name) return NO; \
    if (![spec addColumn:TIGHTDB_TYPE_ID_##type name:name]) return NO; \
}



// TIGHTDB_CHECK_COLUMN_TYPE

#define TIGHTDB_CHECK_COLUMN_TYPE(spec, col, name, type)                TIGHTDB_CHECK_COLUMN_TYPE_2(TIGHTDB_IS_SUBTABLE(type), spec, col, name, type)
#define TIGHTDB_CHECK_COLUMN_TYPE_2(is_subtable, spec, col, name, type) TIGHTDB_CHECK_COLUMN_TYPE_3(is_subtable, spec, col, name, type)
#define TIGHTDB_CHECK_COLUMN_TYPE_3(is_subtable, spec, col, name, type) TIGHTDB_CHECK_COLUMN_TYPE_4_##is_subtable(spec, col, name, type)
#define TIGHTDB_CHECK_COLUMN_TYPE_4_Y(spec, col, name, type)      \
{ \
    if ([spec getColumnType:col] != tightdb_Table) return NO; \
    if (![[spec getColumnName:col] isEqualToString:@#name]) return NO; \
    TightdbSpec *subspec = [spec getSubspec:col]; \
    if (!subspec) return NO; \
    if (![type _checkType:subspec]) return NO; \
}
#define TIGHTDB_CHECK_COLUMN_TYPE_4_N(spec, col, name, type) \
{ \
    if ([spec getColumnType:col] != TIGHTDB_TYPE_ID_##type) return NO; \
    if (![[spec getColumnName:col] isEqualToString:@#name]) return NO; \
}



// TIGHTDB_COLUMN_INSERT

#define TIGHTDB_COLUMN_INSERT(table, col, row, value, type)                TIGHTDB_COLUMN_INSERT_2(TIGHTDB_IS_SUBTABLE(type), table, col, row, value, type)
#define TIGHTDB_COLUMN_INSERT_2(is_subtable, table, col, row, value, type) TIGHTDB_COLUMN_INSERT_3(is_subtable, table, col, row, value, type)
#define TIGHTDB_COLUMN_INSERT_3(is_subtable, table, col, row, value, type) TIGHTDB_COLUMN_INSERT_4_##is_subtable(table, col, row, value, type)
#define TIGHTDB_COLUMN_INSERT_4_Y(table, col, _row, value, type)           [table _insertSubtableCopy:col row:_row subtable:value]
#define TIGHTDB_COLUMN_INSERT_4_N(table, col, row, _value, type)           [table insert##type:col ndx:row value:_value]

// TIGHTDB_COLUMN_INSERT_ERROR

#define TIGHTDB_COLUMN_INSERT_ERROR(table, col, row, value, type, error)                TIGHTDB_COLUMN_INSERT_ERROR_2(TIGHTDB_IS_SUBTABLE(type), table, col, row, value, type, error)
#define TIGHTDB_COLUMN_INSERT_ERROR_2(is_subtable, table, col, row, value, type, error) TIGHTDB_COLUMN_INSERT_ERROR_3(is_subtable, table, col, row, value, type, error)
#define TIGHTDB_COLUMN_INSERT_ERROR_3(is_subtable, table, col, row, value, type, error) TIGHTDB_COLUMN_INSERT_ERROR_4_##is_subtable(table, col, row, value, type, error)
#define TIGHTDB_COLUMN_INSERT_ERROR_4_Y(table, col, _row, value, type, error)           [table _insertSubtableCopy:col row:_row subtable:value error:error]
#define TIGHTDB_COLUMN_INSERT_ERROR_4_N(table, col, row, _value, type, error)           [table insert##type:col ndx:row value:_value error:error]



// TIGHTDB_CURSOR_PROPERTY

#define TIGHTDB_CURSOR_PROPERTY_DEF(name, type)                 TIGHTDB_CURSOR_PROPERTY_DEF_2(TIGHTDB_IS_SUBTABLE(type), name, type)
#define TIGHTDB_CURSOR_PROPERTY_DEF_2(is_subtable, name, type)  TIGHTDB_CURSOR_PROPERTY_DEF_3(is_subtable, name, type)
#define TIGHTDB_CURSOR_PROPERTY_DEF_3(is_subtable, name, type)  TIGHTDB_CURSOR_PROPERTY_DEF_4_##is_subtable(name, type)
#define TIGHTDB_CURSOR_PROPERTY_DEF_4_Y(name, type)             TIGHTDB_CURSOR_PROPERTY_DEF_SUBTABLE(name, type)
#define TIGHTDB_CURSOR_PROPERTY_DEF_4_N(name, type)             TIGHTDB_CURSOR_PROPERTY_DEF_SIMPLE(name, type)

#define TIGHTDB_CURSOR_PROPERTY_IMPL(name, type)                TIGHTDB_CURSOR_PROPERTY_IMPL_2(TIGHTDB_IS_SUBTABLE(type), name, type)
#define TIGHTDB_CURSOR_PROPERTY_IMPL_2(is_subtable, name, type) TIGHTDB_CURSOR_PROPERTY_IMPL_3(is_subtable, name, type)
#define TIGHTDB_CURSOR_PROPERTY_IMPL_3(is_subtable, name, type) TIGHTDB_CURSOR_PROPERTY_IMPL_4_##is_subtable(name, type)
#define TIGHTDB_CURSOR_PROPERTY_IMPL_4_Y(name, type)            TIGHTDB_CURSOR_PROPERTY_IMPL_SUBTABLE(name, type)
#define TIGHTDB_CURSOR_PROPERTY_IMPL_4_N(name, type)            TIGHTDB_CURSOR_PROPERTY_IMPL_SIMPLE(name, type)


#define TIGHTDB_CURSOR_PROPERTY_DEF_SIMPLE(name, type) \
@property TIGHTDB_TYPE_##type name; \
-(TIGHTDB_TYPE_##type)name; \
-(void)set##name:(TIGHTDB_TYPE_##type)value; \
-(BOOL)set##name:(TIGHTDB_TYPE_##type)value error:(NSError *__autoreleasing *)error;

#define TIGHTDB_CURSOR_PROPERTY_IMPL_SIMPLE(name, type) \
-(TIGHTDB_TYPE_##type)name \
{ \
    return [_##name get##type]; \
} \
-(void)set##name:(TIGHTDB_TYPE_##type)value \
{ \
    [_##name set##type:value]; \
} \
-(BOOL)set##name:(TIGHTDB_TYPE_##type)value error:(NSError *__autoreleasing *)error \
{ \
    return [_##name set##type:value error:error]; \
}


#define TIGHTDB_CURSOR_PROPERTY_DEF_SUBTABLE(name, type) \
@property (readonly) type *name; \
-(type *)name; \

#define TIGHTDB_CURSOR_PROPERTY_IMPL_SUBTABLE(name, type) \
-(type *)name \
{ \
    return [_##name getSubtable:[type class]]; \
} \



// TIGHTDB_QUERY_ACCESSOR

#define TIGHTDB_QUERY_ACCESSOR_DEF(table, col_name, col_type)                 TIGHTDB_QUERY_ACCESSOR_DEF_2(TIGHTDB_IS_SUBTABLE(col_type), table, col_name, col_type)
#define TIGHTDB_QUERY_ACCESSOR_DEF_2(is_subtable, table, col_name, col_type)  TIGHTDB_QUERY_ACCESSOR_DEF_3(is_subtable, table, col_name, col_type)
#define TIGHTDB_QUERY_ACCESSOR_DEF_3(is_subtable, table, col_name, col_type)  TIGHTDB_QUERY_ACCESSOR_DEF_4_##is_subtable(table, col_name, col_type)
#define TIGHTDB_QUERY_ACCESSOR_DEF_4_Y(table, col_name, col_type)             TIGHTDB_QUERY_ACCESSOR_DEF_SUBTABLE(table, col_name, col_type)
#define TIGHTDB_QUERY_ACCESSOR_DEF_4_N(table, col_name, col_type)             TIGHTDB_QUERY_ACCESSOR_DEF_##col_type(table, col_name)

#define TIGHTDB_QUERY_ACCESSOR_IMPL(table, col_name, col_type)                TIGHTDB_QUERY_ACCESSOR_IMPL_2(TIGHTDB_IS_SUBTABLE(col_type), table, col_name, col_type)
#define TIGHTDB_QUERY_ACCESSOR_IMPL_2(is_subtable, table, col_name, col_type) TIGHTDB_QUERY_ACCESSOR_IMPL_3(is_subtable, table, col_name, col_type)
#define TIGHTDB_QUERY_ACCESSOR_IMPL_3(is_subtable, table, col_name, col_type) TIGHTDB_QUERY_ACCESSOR_IMPL_4_##is_subtable(table, col_name, col_type)
#define TIGHTDB_QUERY_ACCESSOR_IMPL_4_Y(table, col_name, col_type)            TIGHTDB_QUERY_ACCESSOR_IMPL_SUBTABLE(table, col_name, col_type)
#define TIGHTDB_QUERY_ACCESSOR_IMPL_4_N(table, col_name, col_type)            TIGHTDB_QUERY_ACCESSOR_IMPL_##col_type(table, col_name)


// Boolean

#define TIGHTDB_QUERY_ACCESSOR_DEF_Bool(table, col_name) \
@interface table##_QueryAccessor_##col_name : TightdbQueryAccessorBool \
-(table##_Query *)equal:(BOOL)value; \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_Bool(table, col_name) \
@implementation table##_QueryAccessor_##col_name \
-(table##_Query *)equal:(BOOL)value \
{ \
    return (table##_Query *)[super equal:value]; \
} \
@end


// Integer

#define TIGHTDB_QUERY_ACCESSOR_DEF_Int(table, col_name) \
@interface table##_QueryAccessor_##col_name : TightdbQueryAccessorInt \
-(table##_Query *)equal:(int64_t)value; \
-(table##_Query *)notEqual:(int64_t)value; \
-(table##_Query *)greater:(int64_t)value; \
-(table##_Query *)greaterEqual:(int64_t)value; \
-(table##_Query *)less:(int64_t)value; \
-(table##_Query *)lessEqual:(int64_t)value; \
-(table##_Query *)between:(int64_t)from to:(int64_t)to; \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_Int(table, col_name) \
@implementation table##_QueryAccessor_##col_name \
-(table##_Query *)equal:(int64_t)value \
{ \
    return (table##_Query *)[super equal:value]; \
} \
-(table##_Query *)notEqual:(int64_t)value \
{ \
    return (table##_Query *)[super notEqual:value]; \
} \
-(table##_Query *)greater:(int64_t)value \
{ \
    return (table##_Query *)[super greater:value]; \
} \
-(table##_Query *)greaterEqual:(int64_t)value \
{ \
    return (table##_Query *)[super greaterEqual:value]; \
} \
-(table##_Query *)less:(int64_t)value \
{ \
    return (table##_Query *)[super less:value]; \
} \
-(table##_Query *)lessEqual:(int64_t)value \
{ \
    return (table##_Query *)[super lessEqual:value]; \
} \
-(table##_Query *)between:(int64_t)from to:(int64_t)to \
{ \
    return (table##_Query *)[super between:from to:to]; \
} \
@end


// Float

#define TIGHTDB_QUERY_ACCESSOR_DEF_Float(table, col_name) \
@interface table##_QueryAccessor_##col_name : TightdbQueryAccessorFloat \
-(table##_Query *)equal:(float)value; \
-(table##_Query *)notEqual:(float)value; \
-(table##_Query *)greater:(float)value; \
-(table##_Query *)greaterEqual:(float)value; \
-(table##_Query *)less:(float)value; \
-(table##_Query *)lessEqual:(float)value; \
-(table##_Query *)between:(float)from to:(float)to; \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_Float(table, col_name) \
@implementation table##_QueryAccessor_##col_name \
-(table##_Query *)equal:(float)value \
{ \
    return (table##_Query *)[super equal:value]; \
} \
-(table##_Query *)notEqual:(float)value \
{ \
    return (table##_Query *)[super notEqual:value]; \
} \
-(table##_Query *)greater:(float)value \
{ \
    return (table##_Query *)[super greater:value]; \
} \
-(table##_Query *)greaterEqual:(float)value \
{ \
    return (table##_Query *)[super greaterEqual:value]; \
} \
-(table##_Query *)less:(float)value \
{ \
    return (table##_Query *)[super less:value]; \
} \
-(table##_Query *)lessEqual:(float)value \
{ \
    return (table##_Query *)[super lessEqual:value]; \
} \
-(table##_Query *)between:(float)from to:(float)to \
{ \
    return (table##_Query *)[super between:from to:to]; \
} \
@end


// Double

#define TIGHTDB_QUERY_ACCESSOR_DEF_Double(table, col_name) \
@interface table##_QueryAccessor_##col_name : TightdbQueryAccessorDouble \
-(table##_Query *)equal:(double)value; \
-(table##_Query *)notEqual:(double)value; \
-(table##_Query *)greater:(double)value; \
-(table##_Query *)greaterEqual:(double)value; \
-(table##_Query *)less:(double)value; \
-(table##_Query *)lessEqual:(double)value; \
-(table##_Query *)between:(double)from to:(double)to; \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_Double(table, col_name) \
@implementation table##_QueryAccessor_##col_name \
-(table##_Query *)equal:(double)value \
{ \
    return (table##_Query *)[super equal:value]; \
} \
-(table##_Query *)notEqual:(double)value \
{ \
    return (table##_Query *)[super notEqual:value]; \
} \
-(table##_Query *)greater:(double)value \
{ \
    return (table##_Query *)[super greater:value]; \
} \
-(table##_Query *)greaterEqual:(double)value \
{ \
    return (table##_Query *)[super greaterEqual:value]; \
} \
-(table##_Query *)less:(double)value \
{ \
    return (table##_Query *)[super less:value]; \
} \
-(table##_Query *)lessEqual:(double)value \
{ \
    return (table##_Query *)[super lessEqual:value]; \
} \
-(table##_Query *)between:(double)from to:(double)to \
{ \
    return (table##_Query *)[super between:from to:to]; \
} \
@end


// String

#define TIGHTDB_QUERY_ACCESSOR_DEF_String(table, col_name) \
@interface table##_QueryAccessor_##col_name : TightdbQueryAccessorString \
-(table##_Query *)equal:(NSString *)value; \
-(table##_Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(table##_Query *)notEqual:(NSString *)value; \
-(table##_Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(table##_Query *)beginsWith:(NSString *)value; \
-(table##_Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(table##_Query *)endsWith:(NSString *)value; \
-(table##_Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(table##_Query *)contains:(NSString *)value; \
-(table##_Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_String(table, col_name) \
@implementation table##_QueryAccessor_##col_name \
-(table##_Query *)equal:(NSString *)value \
{ \
    return (table##_Query *)[super equal:value]; \
} \
-(table##_Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (table##_Query *)[super equal:value caseSensitive:caseSensitive]; \
} \
-(table##_Query *)notEqual:(NSString *)value \
{ \
    return (table##_Query *)[super notEqual:value]; \
} \
-(table##_Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (table##_Query *)[super notEqual:value caseSensitive:caseSensitive]; \
} \
-(table##_Query *)beginsWith:(NSString *)value \
{ \
    return (table##_Query *)[super beginsWith:value]; \
} \
-(table##_Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (table##_Query *)[super beginsWith:value caseSensitive:caseSensitive]; \
} \
-(table##_Query *)endsWith:(NSString *)value \
{ \
    return (table##_Query *)[super endsWith:value]; \
} \
-(table##_Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (table##_Query *)[super endsWith:value caseSensitive:caseSensitive]; \
} \
-(table##_Query *)contains:(NSString *)value \
{ \
    return (table##_Query *)[super contains:value]; \
} \
-(table##_Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (table##_Query *)[super contains:value caseSensitive:caseSensitive]; \
} \
@end


// Binary

#define TIGHTDB_QUERY_ACCESSOR_DEF_Binary(table, col_name) \
@interface table##_QueryAccessor_##col_name : TightdbQueryAccessorBinary \
-(table##_Query *)equal:(TightdbBinary *)value; \
-(table##_Query *)notEqual:(TightdbBinary *)value; \
-(table##_Query *)beginsWith:(TightdbBinary *)value; \
-(table##_Query *)endsWith:(TightdbBinary *)value; \
-(table##_Query *)contains:(TightdbBinary *)value; \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_Binary(table, col_name) \
@implementation table##_QueryAccessor_##col_name \
-(table##_Query *)equal:(TightdbBinary *)value \
{ \
    return (table##_Query *)[super equal:value]; \
} \
-(table##_Query *)notEqual:(TightdbBinary *)value \
{ \
    return (table##_Query *)[super notEqual:value]; \
} \
-(table##_Query *)beginsWith:(TightdbBinary *)value \
{ \
    return (table##_Query *)[super beginsWith:value]; \
} \
-(table##_Query *)endsWith:(TightdbBinary *)value \
{ \
    return (table##_Query *)[super endsWith:value]; \
} \
-(table##_Query *)contains:(TightdbBinary *)value \
{ \
    return (table##_Query *)[super contains:value]; \
} \
@end


// Date

#define TIGHTDB_QUERY_ACCESSOR_DEF_Date(table, col_name) \
@interface table##_QueryAccessor_##col_name : TightdbQueryAccessorDate \
-(table##_Query *)equal:(time_t)value; \
-(table##_Query *)notEqual:(time_t)value; \
-(table##_Query *)greater:(time_t)value; \
-(table##_Query *)greaterEqual:(time_t)value; \
-(table##_Query *)less:(time_t)value; \
-(table##_Query *)lessEqual:(time_t)value; \
-(table##_Query *)between:(time_t)from to:(time_t)to; \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_Date(table, col_name) \
@implementation table##_QueryAccessor_##col_name \
-(table##_Query *)equal:(time_t)value \
{ \
    return (table##_Query *)[super equal:value]; \
} \
-(table##_Query *)notEqual:(time_t)value \
{ \
    return (table##_Query *)[super notEqual:value]; \
} \
-(table##_Query *)greater:(time_t)value \
{ \
    return (table##_Query *)[super greater:value]; \
} \
-(table##_Query *)greaterEqual:(time_t)value \
{ \
    return (table##_Query *)[super greaterEqual:value]; \
} \
-(table##_Query *)less:(time_t)value \
{ \
    return (table##_Query *)[super less:value]; \
} \
-(table##_Query *)lessEqual:(time_t)value \
{ \
    return (table##_Query *)[super lessEqual:value]; \
} \
-(table##_Query *)between:(time_t)from to:(time_t)to \
{ \
    return (table##_Query *)[super between:from to:to]; \
} \
@end


// Subtable

#define TIGHTDB_QUERY_ACCESSOR_DEF_SUBTABLE(table, col_name, col_type) \
@interface table##_QueryAccessor_##col_name : TightdbQueryAccessorSubtable \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_SUBTABLE(table, col_name, col_type) \
@implementation table##_QueryAccessor_##col_name \
@end


// Mixed

#define TIGHTDB_QUERY_ACCESSOR_DEF_Mixed(table, col_name) \
@interface table##_QueryAccessor_##col_name : TightdbQueryAccessorMixed \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_Mixed(table, col_name) \
@implementation table##_QueryAccessor_##col_name \
@end
