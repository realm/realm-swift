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
#define TIGHTDB_TYPE_String    NSString*
#define TIGHTDB_TYPE_Binary    TDBBinary*
#define TIGHTDB_TYPE_Date      time_t
#define TIGHTDB_TYPE_Mixed     TDBMixed*

#define TIGHTDB_TYPE_ID_Bool   TDBBoolType
#define TIGHTDB_TYPE_ID_Int    TDBIntType
#define TIGHTDB_TYPE_ID_Float  TDBFloatType
#define TIGHTDB_TYPE_ID_Double TDBDoubleType
#define TIGHTDB_TYPE_ID_String TDBStringType
#define TIGHTDB_TYPE_ID_Binary TDBBinaryType
#define TIGHTDB_TYPE_ID_Date   TDBDateType
#define TIGHTDB_TYPE_ID_Mixed  TDBMixedType



/* TIGHTDB_ARG_TYPE */

#define TIGHTDB_ARG_TYPE(type)                 TIGHTDB_ARG_TYPE_2(TIGHTDB_IS_SUBTABLE(type), type)
#define TIGHTDB_ARG_TYPE_2(is_subtable, type)  TIGHTDB_ARG_TYPE_3(is_subtable, type)
#define TIGHTDB_ARG_TYPE_3(is_subtable, type)  TIGHTDB_ARG_TYPE_4_##is_subtable(type)
#define TIGHTDB_ARG_TYPE_4_Y(type)             type*
#define TIGHTDB_ARG_TYPE_4_N(type)             TIGHTDB_TYPE_##type



/* TIGHTDB_COLUMN_PROXY */

#define TIGHTDB_COLUMN_PROXY_DEF(name, type)                 TIGHTDB_COLUMN_PROXY_DEF_2(TIGHTDB_IS_SUBTABLE(type), name, type)
#define TIGHTDB_COLUMN_PROXY_DEF_2(is_subtable, name, type)  TIGHTDB_COLUMN_PROXY_DEF_3(is_subtable, name, type)
#define TIGHTDB_COLUMN_PROXY_DEF_3(is_subtable, name, type)  TIGHTDB_COLUMN_PROXY_DEF_4_##is_subtable(name, type)
#define TIGHTDB_COLUMN_PROXY_DEF_4_Y(name, type)             @property(nonatomic, strong) TDBColumnProxy_Subtable* name;
#define TIGHTDB_COLUMN_PROXY_DEF_4_N(name, type)             @property(nonatomic, strong) TDBColumnProxy_##type* name;

#define TIGHTDB_COLUMN_PROXY_IMPL(name, type)                @synthesize name = _##name;

#define TIGHTDB_COLUMN_PROXY_INIT(table, col, name, type)                TIGHTDB_COLUMN_PROXY_INIT_2(TIGHTDB_IS_SUBTABLE(type), table, col, name, type)
#define TIGHTDB_COLUMN_PROXY_INIT_2(is_subtable, table, col, name, type) TIGHTDB_COLUMN_PROXY_INIT_3(is_subtable, table, col, name, type)
#define TIGHTDB_COLUMN_PROXY_INIT_3(is_subtable, table, col, name, type) TIGHTDB_COLUMN_PROXY_INIT_4_##is_subtable(table, col, name, type)
#define TIGHTDB_COLUMN_PROXY_INIT_4_Y(table, col, name, type)            _##name = [[TDBColumnProxy_Subtable alloc] initWithTable:table column:col]
#define TIGHTDB_COLUMN_PROXY_INIT_4_N(table, col, name, type)            _##name = [[TDBColumnProxy_##type alloc] initWithTable:table column:col]



/* TIGHTDB_ADD_COLUMN */

#define TIGHTDB_ADD_COLUMN(desc, name, type)                TIGHTDB_ADD_COLUMN_2(TIGHTDB_IS_SUBTABLE(type), desc, name, type)
#define TIGHTDB_ADD_COLUMN_2(is_subtable, desc, name, type) TIGHTDB_ADD_COLUMN_3(is_subtable, desc, name, type)
#define TIGHTDB_ADD_COLUMN_3(is_subtable, desc, name, type) TIGHTDB_ADD_COLUMN_4_##is_subtable(desc, name, type)
#define TIGHTDB_ADD_COLUMN_4_Y(desc, _name, type) \
{ \
    NSString* name = [NSString stringWithUTF8String:#_name]; \
    if (!name) \
        return NO; \
    TDBDescriptor* subdesc = [desc addColumnTable:name]; \
    if (!subdesc) \
        return NO; \
    if (![type _addColumns:subdesc]) \
        return NO; \
}
#define TIGHTDB_ADD_COLUMN_4_N(desc, _name, type) \
{ \
    NSString* name = [NSString stringWithUTF8String:#_name]; \
    if (!name) \
        return NO; \
    if (![desc addColumnWithName:name andType:TIGHTDB_TYPE_ID_##type]) \
        return NO; \
}



/* TIGHTDB_CHECK_COLUMN_TYPE */

#define TIGHTDB_CHECK_COLUMN_TYPE(desc, col, name, type)                TIGHTDB_CHECK_COLUMN_TYPE_2(TIGHTDB_IS_SUBTABLE(type), desc, col, name, type)
#define TIGHTDB_CHECK_COLUMN_TYPE_2(is_subtable, desc, col, name, type) TIGHTDB_CHECK_COLUMN_TYPE_3(is_subtable, desc, col, name, type)
#define TIGHTDB_CHECK_COLUMN_TYPE_3(is_subtable, desc, col, name, type) TIGHTDB_CHECK_COLUMN_TYPE_4_##is_subtable(desc, col, name, type)
#define TIGHTDB_CHECK_COLUMN_TYPE_4_Y(desc, col, name, type)      \
{ \
    if ([desc columnTypeOfColumn:col] != TDBTableType) \
        return NO; \
    if (![[desc columnNameOfColumn:col] isEqualToString:@#name]) \
        return NO; \
    TDBDescriptor* subdesc = [desc subdescriptorForColumnWithIndex:col]; \
    if (!subdesc) \
        return NO; \
    if (![type _checkType:subdesc]) \
        return NO; \
}
#define TIGHTDB_CHECK_COLUMN_TYPE_4_N(desc, col, name, type) \
{ \
    if ([desc columnTypeOfColumn:col] != TIGHTDB_TYPE_ID_##type) \
        return NO; \
    if (![[desc columnNameOfColumn:col] isEqualToString:@#name]) \
        return NO; \
}



/* TIGHTDB_COLUMN_INSERT */

#define TIGHTDB_COLUMN_INSERT(table, col, row, value, type)                TIGHTDB_COLUMN_INSERT_2(TIGHTDB_IS_SUBTABLE(type), table, col, row, value, type)
#define TIGHTDB_COLUMN_INSERT_2(is_subtable, table, col, row, value, type) TIGHTDB_COLUMN_INSERT_3(is_subtable, table, col, row, value, type)
#define TIGHTDB_COLUMN_INSERT_3(is_subtable, table, col, row, value, type) TIGHTDB_COLUMN_INSERT_4_##is_subtable(table, col, row, value, type)
#define TIGHTDB_COLUMN_INSERT_4_Y(table, col, _row, value, type)           [table TDBInsertSubtableCopy:col row:_row subtable:value]
#define TIGHTDB_COLUMN_INSERT_4_N(table, col, row, _value, type)           [table TDBInsert##type:col ndx:row value:_value]



/* TIGHTDB_CURSOR_PROPERTY */

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
-(void)set##name:(TIGHTDB_TYPE_##type)value;

#define TIGHTDB_CURSOR_PROPERTY_IMPL_SIMPLE(name, type) \
-(TIGHTDB_TYPE_##type)name \
{ \
    return [_##name get##type]; \
} \
-(void)set##name:(TIGHTDB_TYPE_##type)value \
{ \
    [_##name set##type:value]; \
}

#define TIGHTDB_CURSOR_PROPERTY_DEF_SUBTABLE(name, type) \
@property type* name; \
-(type*)name; \

#define TIGHTDB_CURSOR_PROPERTY_IMPL_SUBTABLE(name, type) \
-(type*)name \
{ \
    return [_##name getSubtable:[type class]]; \
} \
-(void)set##name:(type*)subtable \
{ \
    [_##name setSubtable:subtable]; \
} \

/* TIGHTDB_QUERY_ACCESSOR */

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


/* Boolean */

#define TIGHTDB_QUERY_ACCESSOR_DEF_Bool(table, col_name) \
@interface table##_QueryAccessor_##col_name : TDBQueryAccessorBool \
-(table##_Query*)columnIsEqualTo:(BOOL)value; \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_Bool(table, col_name) \
@implementation table##_QueryAccessor_##col_name \
-(table##_Query*)columnIsEqualTo:(BOOL)value \
{ \
    return (table##_Query*)[super columnIsEqualTo:value]; \
} \
@end


/* Integer */

#define TIGHTDB_QUERY_ACCESSOR_DEF_Int(table, col_name) \
@interface table##_QueryAccessor_##col_name : TDBQueryAccessorInt \
-(table##_Query*)columnIsEqualTo:(int64_t)value; \
-(table##_Query*)columnIsNotEqualTo:(int64_t)value; \
-(table##_Query*)columnIsGreaterThan:(int64_t)value; \
-(table##_Query*)columnIsGreaterThanOrEqualTo:(int64_t)value; \
-(table##_Query*)columnIsLessThan:(int64_t)value; \
-(table##_Query*)columnIsLessThanOrEqualTo:(int64_t)value; \
-(table##_Query*)columnIsBetween:(int64_t)from and_:(int64_t)to; \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_Int(table, col_name) \
@implementation table##_QueryAccessor_##col_name \
-(table##_Query*)columnIsEqualTo:(int64_t)value \
{ \
    return (table##_Query*)[super columnIsEqualTo:value]; \
} \
-(table##_Query*)columnIsNotEqualTo:(int64_t)value \
{ \
    return (table##_Query*)[super columnIsNotEqualTo:value]; \
} \
-(table##_Query*)columnIsGreaterThan:(int64_t)value \
{ \
    return (table##_Query*)[super columnIsGreaterThan:value]; \
} \
-(table##_Query*)columnIsGreaterThanOrEqualTo:(int64_t)value \
{ \
    return (table##_Query*)[super columnIsGreaterThanOrEqualTo:value]; \
} \
-(table##_Query*)columnIsLessThan:(int64_t)value \
{ \
    return (table##_Query*)[super columnIsLessThan:value]; \
} \
-(table##_Query*)columnIsLessThanOrEqualTo:(int64_t)value \
{ \
    return (table##_Query*)[super columnIsLessThanOrEqualTo:value]; \
} \
-(table##_Query*)columnIsBetween:(int64_t)from and_:(int64_t)to \
{ \
    return (table##_Query*)[super columnIsBetween:from and_:to]; \
} \
@end


/* Float */

#define TIGHTDB_QUERY_ACCESSOR_DEF_Float(table, col_name) \
@interface table##_QueryAccessor_##col_name : TDBQueryAccessorFloat \
-(table##_Query*)columnIsEqualTo:(float)value; \
-(table##_Query*)columnIsNotEqualTo:(float)value; \
-(table##_Query*)columnIsGreaterThan:(float)value; \
-(table##_Query*)columnIsGreaterThanOrEqualTo:(float)value; \
-(table##_Query*)columnIsLessThan:(float)value; \
-(table##_Query*)columnIsLessThanOrEqualTo:(float)value; \
-(table##_Query*)columnIsBetween:(float)from and_:(float)to; \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_Float(table, col_name) \
@implementation table##_QueryAccessor_##col_name \
-(table##_Query*)columnIsEqualTo:(float)value \
{ \
    return (table##_Query*)[super columnIsEqualTo:value]; \
} \
-(table##_Query*)columnIsNotEqualTo:(float)value \
{ \
    return (table##_Query*)[super columnIsNotEqualTo:value]; \
} \
-(table##_Query*)columnIsGreaterThan:(float)value \
{ \
    return (table##_Query*)[super columnIsGreaterThan:value]; \
} \
-(table##_Query*)columnIsGreaterThanOrEqualTo:(float)value \
{ \
    return (table##_Query*)[super columnIsGreaterThanOrEqualTo:value]; \
} \
-(table##_Query*)columnIsLessThan:(float)value \
{ \
    return (table##_Query*)[super columnIsLessThan:value]; \
} \
-(table##_Query*)columnIsLessThanOrEqualTo:(float)value \
{ \
    return (table##_Query*)[super columnIsLessThanOrEqualTo:value]; \
} \
-(table##_Query*)columnIsBetween:(float)from and_:(float)to \
{ \
    return (table##_Query*)[super columnIsBetween:from and_:to]; \
} \
@end


/* Double */

#define TIGHTDB_QUERY_ACCESSOR_DEF_Double(table, col_name) \
@interface table##_QueryAccessor_##col_name : TDBQueryAccessorDouble \
-(table##_Query*)columnIsEqualTo:(double)value; \
-(table##_Query*)columnIsNotEqualTo:(double)value; \
-(table##_Query*)columnIsGreaterThan:(double)value; \
-(table##_Query*)columnIsGreaterThanOrEqualTo:(double)value; \
-(table##_Query*)columnIsLessThan:(double)value; \
-(table##_Query*)columnIsLessThanOrEqualTo:(double)value; \
-(table##_Query*)columnIsBetween:(double)from and_:(double)to; \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_Double(table, col_name) \
@implementation table##_QueryAccessor_##col_name \
-(table##_Query*)columnIsEqualTo:(double)value \
{ \
    return (table##_Query*)[super columnIsEqualTo:value]; \
} \
-(table##_Query*)columnIsNotEqualTo:(double)value \
{ \
    return (table##_Query*)[super columnIsNotEqualTo:value]; \
} \
-(table##_Query*)columnIsGreaterThan:(double)value \
{ \
    return (table##_Query*)[super columnIsGreaterThan:value]; \
} \
-(table##_Query*)columnIsGreaterThanOrEqualTo:(double)value \
{ \
    return (table##_Query*)[super columnIsGreaterThanOrEqualTo:value]; \
} \
-(table##_Query*)columnIsLessThan:(double)value \
{ \
    return (table##_Query*)[super columnIsLessThan:value]; \
} \
-(table##_Query*)columnIsLessThanOrEqualTo:(double)value \
{ \
    return (table##_Query*)[super columnIsLessThanOrEqualTo:value]; \
} \
-(table##_Query*)columnIsBetween:(double)from and_:(double)to \
{ \
    return (table##_Query*)[super columnIsBetween:from and_:to]; \
} \
@end


/* String */

#define TIGHTDB_QUERY_ACCESSOR_DEF_String(table, col_name) \
@interface table##_QueryAccessor_##col_name : TDBQueryAccessorString \
-(table##_Query*)columnIsEqualTo:(NSString*)value; \
-(table##_Query*)columnIsEqualTo:(NSString*)value caseSensitive:(BOOL)caseSensitive; \
-(table##_Query*)columnIsNotEqualTo:(NSString*)value; \
-(table##_Query*)columnIsNotEqualTo:(NSString*)value caseSensitive:(BOOL)caseSensitive; \
-(table##_Query*)columnBeginsWith:(NSString*)value; \
-(table##_Query*)columnBeginsWith:(NSString*)value caseSensitive:(BOOL)caseSensitive; \
-(table##_Query*)columnEndsWith:(NSString*)value; \
-(table##_Query*)columnEndsWith:(NSString*)value caseSensitive:(BOOL)caseSensitive; \
-(table##_Query*)columnContains:(NSString*)value; \
-(table##_Query*)columnContains:(NSString*)value caseSensitive:(BOOL)caseSensitive; \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_String(table, col_name) \
@implementation table##_QueryAccessor_##col_name \
-(table##_Query*)columnIsEqualTo:(NSString*)value \
{ \
    return (table##_Query*)[super columnIsEqualTo:value]; \
} \
-(table##_Query*)columnIsEqualTo:(NSString*)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (table##_Query*)[super columnIsEqualTo:value caseSensitive:caseSensitive]; \
} \
-(table##_Query*)columnIsNotEqualTo:(NSString*)value \
{ \
    return (table##_Query*)[super columnIsNotEqualTo:value]; \
} \
-(table##_Query*)columnIsNotEqualTo:(NSString*)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (table##_Query*)[super columnIsNotEqualTo:value caseSensitive:caseSensitive]; \
} \
-(table##_Query*)columnBeginsWith:(NSString*)value \
{ \
    return (table##_Query*)[super columnBeginsWith:value]; \
} \
-(table##_Query*)columnBeginsWith:(NSString*)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (table##_Query*)[super columnBeginsWith:value caseSensitive:caseSensitive]; \
} \
-(table##_Query*)columnEndsWith:(NSString*)value \
{ \
    return (table##_Query*)[super columnEndsWith:value]; \
} \
-(table##_Query*)columnEndsWith:(NSString*)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (table##_Query*)[super columnEndsWith:value caseSensitive:caseSensitive]; \
} \
-(table##_Query*)columnContains:(NSString*)value \
{ \
    return (table##_Query*)[super columnContains:value]; \
} \
-(table##_Query*)columnContains:(NSString*)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (table##_Query*)[super columnContains:value caseSensitive:caseSensitive]; \
} \
@end


/* Binary */

#define TIGHTDB_QUERY_ACCESSOR_DEF_Binary(table, col_name) \
@interface table##_QueryAccessor_##col_name : TDBQueryAccessorBinary \
-(table##_Query*)columnIsEqualTo:(TDBBinary*)value; \
-(table##_Query*)columnIsNotEqualTo:(TDBBinary*)value; \
-(table##_Query*)columnBeginsWith:(TDBBinary*)value; \
-(table##_Query*)columnEndsWith:(TDBBinary*)value; \
-(table##_Query*)columnContains:(TDBBinary*)value; \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_Binary(table, col_name) \
@implementation table##_QueryAccessor_##col_name \
-(table##_Query*)columnIsEqualTo:(TDBBinary*)value \
{ \
    return (table##_Query*)[super columnIsEqualTo:value]; \
} \
-(table##_Query*)columnIsNotEqualTo:(TDBBinary*)value \
{ \
    return (table##_Query*)[super columnIsNotEqualTo:value]; \
} \
-(table##_Query*)columnBeginsWith:(TDBBinary*)value \
{ \
    return (table##_Query*)[super columnBeginsWith:value]; \
} \
-(table##_Query*)columnEndsWith:(TDBBinary*)value \
{ \
    return (table##_Query*)[super columnEndsWith:value]; \
} \
-(table##_Query*)columnContains:(TDBBinary*)value \
{ \
    return (table##_Query*)[super columnContains:value]; \
} \
@end


/* Date */

#define TIGHTDB_QUERY_ACCESSOR_DEF_Date(table, col_name) \
@interface table##_QueryAccessor_##col_name : TDBQueryAccessorDate \
-(table##_Query*)columnIsEqualTo:(time_t)value; \
-(table##_Query*)columnIsNotEqualTo:(time_t)value; \
-(table##_Query*)columnIsGreaterThan:(time_t)value; \
-(table##_Query*)columnIsGreaterThanOrEqualTo:(time_t)value; \
-(table##_Query*)columnIsLessThan:(time_t)value; \
-(table##_Query*)columnIsLessThanOrEqualTo:(time_t)value; \
-(table##_Query*)columnIsBetween:(time_t)from and_:(time_t)to; \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_Date(table, col_name) \
@implementation table##_QueryAccessor_##col_name \
-(table##_Query*)columnIsEqualTo:(time_t)value \
{ \
    return (table##_Query*)[super columnIsEqualTo:value]; \
} \
-(table##_Query*)columnIsNotEqualTo:(time_t)value \
{ \
    return (table##_Query*)[super columnIsNotEqualTo:value]; \
} \
-(table##_Query*)columnIsGreaterThan:(time_t)value \
{ \
    return (table##_Query*)[super columnIsGreaterThan:value]; \
} \
-(table##_Query*)columnIsGreaterThanOrEqualTo:(time_t)value \
{ \
    return (table##_Query*)[super columnIsGreaterThanOrEqualTo:value]; \
} \
-(table##_Query*)columnIsLessThan:(time_t)value \
{ \
    return (table##_Query*)[super columnIsLessThan:value]; \
} \
-(table##_Query*)columnIsLessThanOrEqualTo:(time_t)value \
{ \
    return (table##_Query*)[super columnIsLessThanOrEqualTo:value]; \
} \
-(table##_Query*)columnIsBetween:(time_t)from and_:(time_t)to \
{ \
    return (table##_Query*)[super columnIsBetween:from and_:to]; \
} \
@end


/* Subtable */

#define TIGHTDB_QUERY_ACCESSOR_DEF_SUBTABLE(table, col_name, col_type) \
@interface table##_QueryAccessor_##col_name : TDBQueryAccessorSubtable \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_SUBTABLE(table, col_name, col_type) \
@implementation table##_QueryAccessor_##col_name \
@end


/* Mixed */

#define TIGHTDB_QUERY_ACCESSOR_DEF_Mixed(table, col_name) \
@interface table##_QueryAccessor_##col_name : TDBQueryAccessorMixed \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_Mixed(table, col_name) \
@implementation table##_QueryAccessor_##col_name \
@end
