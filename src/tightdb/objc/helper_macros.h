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
#define TIGHTDB_IS_SUBTABLE_Date      x,x
#define TIGHTDB_IS_SUBTABLE_String    x,x
#define TIGHTDB_IS_SUBTABLE_Binary    x,x
#define TIGHTDB_IS_SUBTABLE_Mixed     x,x



// TIGHTDB_ADD_COLUMN

#define TIGHTDB_ADD_COLUMN(spec, name, type)                TIGHTDB_ADD_COLUMN_2(TIGHTDB_IS_SUBTABLE(type), spec, name, type)
#define TIGHTDB_ADD_COLUMN_2(is_subtable, spec, name, type) TIGHTDB_ADD_COLUMN_3(is_subtable, spec, name, type)
#define TIGHTDB_ADD_COLUMN_3(is_subtable, spec, name, type) TIGHTDB_ADD_COLUMN_4_##is_subtable(spec, name, type)
#define TIGHTDB_ADD_COLUMN_4_Y(spec, _name, type) \
{ \
    NSString *name = [NSString stringWithUTF8String:#_name]; \
    if (!name) return NO; \
    OCSpec *subspec = [spec addColumnTable:name]; \
    if (!subspec) return NO; \
    if (![type _addColumns:subspec]) return NO; \
}
#define TIGHTDB_ADD_COLUMN_4_N(spec, _name, type) \
{ \
    NSString *name = [NSString stringWithUTF8String:#_name]; \
    if (!name) return NO; \
    if (![spec addColumn:COLTYPE##type name:name]) return NO; \
}



// TIGHTDB_COLUMN_INSERT

#define TIGHTDB_COLUMN_INSERT(table, col, row, value, type)                TIGHTDB_COLUMN_INSERT_2(TIGHTDB_IS_SUBTABLE(type), table, col, row, value, type)
#define TIGHTDB_COLUMN_INSERT_2(is_subtable, table, col, row, value, type) TIGHTDB_COLUMN_INSERT_3(is_subtable, table, col, row, value, type)
#define TIGHTDB_COLUMN_INSERT_3(is_subtable, table, col, row, value, type) TIGHTDB_COLUMN_INSERT_4_##is_subtable(table, col, row, value, type)
#define TIGHTDB_COLUMN_INSERT_4_Y(table, col, row, _value, type)           [table _insertSubtableCopy:col row_ndx:row subtable:_value]
#define TIGHTDB_COLUMN_INSERT_4_N(table, col, row, _value, type)           [table insert##type:col ndx:row value:_value]



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
@property tdbOCType##type name; \
-(tdbOCType##type)name; \
-(void)set##name:(tdbOCType##type)value;

#define TIGHTDB_CURSOR_PROPERTY_IMPL_SIMPLE(name, type) \
-(tdbOCType##type)name \
{ \
    return [_##name get##type]; \
} \
-(void)set##name:(tdbOCType##type)value \
{ \
    [_##name set##type:value]; \
}


#define TIGHTDB_CURSOR_PROPERTY_DEF_SUBTABLE(name, type) \
@property id name; \
-(id)name; \
-(void)set##name:(id)value;

/* FIXME: Must implement setter as a table copying operation. */
#define TIGHTDB_CURSOR_PROPERTY_IMPL_SUBTABLE(name, type) \
-(id)name \
{ \
    return [_##name getSubtable:[type class]]; \
} \
-(void)set##name:(id)value \
{ \
    (void)value; \
}



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

// Integer

#define TIGHTDB_QUERY_ACCESSOR_DEF_Int(table, col_name) \
@interface table##_QueryAccessor_##col_name : OCXQueryAccessorInt \
-(table##_Query *)equal:(size_t)value; \
-(table##_Query *)notEqual:(size_t)value; \
-(table##_Query *)greater:(int64_t)value; \
-(table##_Query *)less:(int64_t)value; \
-(table##_Query *)between:(int64_t)from to:(int64_t)to; \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_Int(table, col_name) \
@implementation table##_QueryAccessor_##col_name \
-(table##_Query *)equal:(size_t)value \
{ \
    return (table##_Query *)[super equal:value]; \
} \
-(table##_Query *)notEqual:(size_t)value \
{ \
    return (table##_Query *)[super notEqual:value]; \
} \
-(table##_Query *)greater:(int64_t)value \
{ \
    return (table##_Query *)[super greater:value]; \
} \
-(table##_Query *)less:(int64_t)value \
{ \
    return (table##_Query *)[super less:value]; \
} \
-(table##_Query *)between:(int64_t)from to:(int64_t)to \
{ \
    return (table##_Query *)[super between:from to:to]; \
} \
@end

// Boolean

#define TIGHTDB_QUERY_ACCESSOR_DEF_Bool(table, col_name) \
@interface table##_QueryAccessor_##col_name : OCXQueryAccessorBool \
-(table##_Query *)equal:(BOOL)value; \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_Bool(table, col_name) \
@implementation table##_QueryAccessor_##col_name \
-(table##_Query *)equal:(BOOL)value \
{ \
    return (table##_Query *)[super equal:value]; \
} \
@end

// Date

#define TIGHTDB_QUERY_ACCESSOR_DEF_Date(table, col_name) \
@interface table##_QueryAccessor_##col_name : OCXQueryAccessorDate \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_Date(table, col_name) \
@implementation table##_QueryAccessor_##col_name \
@end

// String

#define TIGHTDB_QUERY_ACCESSOR_DEF_String(table, col_name) \
@interface table##_QueryAccessor_##col_name : OCXQueryAccessorString \
-(table##_Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(table##_Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(table##_Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(table##_Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
-(table##_Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive; \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_String(table, col_name) \
@implementation table##_QueryAccessor_##col_name \
-(table##_Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (table##_Query *)[super equal:value caseSensitive:caseSensitive]; \
} \
-(table##_Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (table##_Query *)[super notEqual:value caseSensitive:caseSensitive]; \
} \
-(table##_Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (table##_Query *)[super beginsWith:value caseSensitive:caseSensitive]; \
} \
-(table##_Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (table##_Query *)[super endsWith:value caseSensitive:caseSensitive]; \
} \
-(table##_Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (table##_Query *)[super contains:value caseSensitive:caseSensitive]; \
} \
@end

// Subtable

#define TIGHTDB_QUERY_ACCESSOR_DEF_SUBTABLE(table, col_name, col_type) \
@interface table##_QueryAccessor_##col_name : OCXQueryAccessorSubtable \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_SUBTABLE(table, col_name, col_type) \
@implementation table##_QueryAccessor_##col_name \
@end

// Mixed

#define TIGHTDB_QUERY_ACCESSOR_DEF_Mixed(table, col_name) \
@interface table##_QueryAccessor_##col_name : OCXQueryAccessorMixed \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_Mixed(table, col_name) \
@implementation table##_QueryAccessor_##col_name \
@end
