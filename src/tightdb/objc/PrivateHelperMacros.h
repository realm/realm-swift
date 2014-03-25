/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2014] TightDB Inc
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
#define TIGHTDB_TYPE_Binary    NSData *
#define TIGHTDB_TYPE_Date      NSDate *
#define TIGHTDB_TYPE_Mixed     id

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
#define TIGHTDB_COLUMN_PROXY_DEF_4_Y(name, type)             @property(nonatomic, strong) TDBColumnProxySubtable* name;
#define TIGHTDB_COLUMN_PROXY_DEF_4_N(name, type)             @property(nonatomic, strong) TDBColumnProxy##type* name;

#define TIGHTDB_COLUMN_PROXY_IMPL(name, type)                @synthesize name = _##name;

#define TIGHTDB_COLUMN_PROXY_INIT(table, col, name, type)                TIGHTDB_COLUMN_PROXY_INIT_2(TIGHTDB_IS_SUBTABLE(type), table, col, name, type)
#define TIGHTDB_COLUMN_PROXY_INIT_2(is_subtable, table, col, name, type) TIGHTDB_COLUMN_PROXY_INIT_3(is_subtable, table, col, name, type)
#define TIGHTDB_COLUMN_PROXY_INIT_3(is_subtable, table, col, name, type) TIGHTDB_COLUMN_PROXY_INIT_4_##is_subtable(table, col, name, type)
#define TIGHTDB_COLUMN_PROXY_INIT_4_Y(table, col, name, type)            _##name = [[TDBColumnProxySubtable alloc] initWithTable:table column:col]
#define TIGHTDB_COLUMN_PROXY_INIT_4_N(table, col, name, type)            _##name = [[TDBColumnProxy##type alloc] initWithTable:table column:col]



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
#define TIGHTDB_COLUMN_INSERT_4_Y(table, col, _row, value, type)           [table TDB_insertSubtableCopy:col row:_row subtable:value]
#define TIGHTDB_COLUMN_INSERT_4_N(table, col, row, _value, type)           [table TDB_insert##type:col ndx:row value:_value]



/* TIGHTDB_ROW_PROPERTY */

#define TIGHTDB_ROW_PROPERTY_DEF(name, type)                 TIGHTDB_ROW_PROPERTY_DEF_2(TIGHTDB_IS_SUBTABLE(type), name, type)
#define TIGHTDB_ROW_PROPERTY_DEF_2(is_subtable, name, type)  TIGHTDB_ROW_PROPERTY_DEF_3(is_subtable, name, type)
#define TIGHTDB_ROW_PROPERTY_DEF_3(is_subtable, name, type)  TIGHTDB_ROW_PROPERTY_DEF_4_##is_subtable(name, type)
#define TIGHTDB_ROW_PROPERTY_DEF_4_Y(name, type)             TIGHTDB_ROW_PROPERTY_DEF_SUBTABLE(name, type)
#define TIGHTDB_ROW_PROPERTY_DEF_4_N(name, type)             TIGHTDB_ROW_PROPERTY_DEF_SIMPLE(name, type)

#define TIGHTDB_ROW_PROPERTY_IMPL(name, type)                TIGHTDB_ROW_PROPERTY_IMPL_2(TIGHTDB_IS_SUBTABLE(type), name, type)
#define TIGHTDB_ROW_PROPERTY_IMPL_2(is_subtable, name, type) TIGHTDB_ROW_PROPERTY_IMPL_3(is_subtable, name, type)
#define TIGHTDB_ROW_PROPERTY_IMPL_3(is_subtable, name, type) TIGHTDB_ROW_PROPERTY_IMPL_4_##is_subtable(name, type)
#define TIGHTDB_ROW_PROPERTY_IMPL_4_Y(name, type)            TIGHTDB_ROW_PROPERTY_IMPL_SUBTABLE(name, type)
#define TIGHTDB_ROW_PROPERTY_IMPL_4_N(name, type)            TIGHTDB_ROW_PROPERTY_IMPL_SIMPLE(name, type)


#define TIGHTDB_ROW_PROPERTY_DEF_SIMPLE(name, type) \
@property TIGHTDB_TYPE_##type name; \
-(TIGHTDB_TYPE_##type)name; \
-(void)set##name:(TIGHTDB_TYPE_##type)value;

#define TIGHTDB_ROW_PROPERTY_IMPL_SIMPLE(name, type) \
-(TIGHTDB_TYPE_##type)name \
{ \
    return [_##name get##type]; \
} \
-(void)set##name:(TIGHTDB_TYPE_##type)value \
{ \
    [_##name set##type:value]; \
}

#define TIGHTDB_ROW_PROPERTY_DEF_SUBTABLE(name, type) \
@property type* name; \
-(type*)name; \

#define TIGHTDB_ROW_PROPERTY_IMPL_SUBTABLE(name, type) \
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
@interface table##QueryAccessor##col_name : TDBQueryAccessorBool \
-(table##Query*)columnIsEqualTo:(BOOL)value; \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_Bool(table, col_name) \
@implementation table##QueryAccessor##col_name \
-(table##Query*)columnIsEqualTo:(BOOL)value \
{ \
    return (table##Query*)[super columnIsEqualTo:value]; \
} \
@end


/* Integer */

#define TIGHTDB_QUERY_ACCESSOR_DEF_Int(table, col_name) \
@interface table##QueryAccessor##col_name : TDBQueryAccessorInt \
-(table##Query*)columnIsEqualTo:(int64_t)value; \
-(table##Query*)columnIsNotEqualTo:(int64_t)value; \
-(table##Query*)columnIsGreaterThan:(int64_t)value; \
-(table##Query*)columnIsGreaterThanOrEqualTo:(int64_t)value; \
-(table##Query*)columnIsLessThan:(int64_t)value; \
-(table##Query*)columnIsLessThanOrEqualTo:(int64_t)value; \
-(table##Query*)columnIsBetween:(int64_t)from and_:(int64_t)to; \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_Int(table, col_name) \
@implementation table##QueryAccessor##col_name \
-(table##Query*)columnIsEqualTo:(int64_t)value \
{ \
    return (table##Query*)[super columnIsEqualTo:value]; \
} \
-(table##Query*)columnIsNotEqualTo:(int64_t)value \
{ \
    return (table##Query*)[super columnIsNotEqualTo:value]; \
} \
-(table##Query*)columnIsGreaterThan:(int64_t)value \
{ \
    return (table##Query*)[super columnIsGreaterThan:value]; \
} \
-(table##Query*)columnIsGreaterThanOrEqualTo:(int64_t)value \
{ \
    return (table##Query*)[super columnIsGreaterThanOrEqualTo:value]; \
} \
-(table##Query*)columnIsLessThan:(int64_t)value \
{ \
    return (table##Query*)[super columnIsLessThan:value]; \
} \
-(table##Query*)columnIsLessThanOrEqualTo:(int64_t)value \
{ \
    return (table##Query*)[super columnIsLessThanOrEqualTo:value]; \
} \
-(table##Query*)columnIsBetween:(int64_t)from and_:(int64_t)to \
{ \
    return (table##Query*)[super columnIsBetween:from and_:to]; \
} \
@end


/* Float */

#define TIGHTDB_QUERY_ACCESSOR_DEF_Float(table, col_name) \
@interface table##QueryAccessor##col_name : TDBQueryAccessorFloat \
-(table##Query*)columnIsEqualTo:(float)value; \
-(table##Query*)columnIsNotEqualTo:(float)value; \
-(table##Query*)columnIsGreaterThan:(float)value; \
-(table##Query*)columnIsGreaterThanOrEqualTo:(float)value; \
-(table##Query*)columnIsLessThan:(float)value; \
-(table##Query*)columnIsLessThanOrEqualTo:(float)value; \
-(table##Query*)columnIsBetween:(float)from and_:(float)to; \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_Float(table, col_name) \
@implementation table##QueryAccessor##col_name \
-(table##Query*)columnIsEqualTo:(float)value \
{ \
    return (table##Query*)[super columnIsEqualTo:value]; \
} \
-(table##Query*)columnIsNotEqualTo:(float)value \
{ \
    return (table##Query*)[super columnIsNotEqualTo:value]; \
} \
-(table##Query*)columnIsGreaterThan:(float)value \
{ \
    return (table##Query*)[super columnIsGreaterThan:value]; \
} \
-(table##Query*)columnIsGreaterThanOrEqualTo:(float)value \
{ \
    return (table##Query*)[super columnIsGreaterThanOrEqualTo:value]; \
} \
-(table##Query*)columnIsLessThan:(float)value \
{ \
    return (table##Query*)[super columnIsLessThan:value]; \
} \
-(table##Query*)columnIsLessThanOrEqualTo:(float)value \
{ \
    return (table##Query*)[super columnIsLessThanOrEqualTo:value]; \
} \
-(table##Query*)columnIsBetween:(float)from and_:(float)to \
{ \
    return (table##Query*)[super columnIsBetween:from and_:to]; \
} \
@end


/* Double */

#define TIGHTDB_QUERY_ACCESSOR_DEF_Double(table, col_name) \
@interface table##QueryAccessor##col_name : TDBQueryAccessorDouble \
-(table##Query*)columnIsEqualTo:(double)value; \
-(table##Query*)columnIsNotEqualTo:(double)value; \
-(table##Query*)columnIsGreaterThan:(double)value; \
-(table##Query*)columnIsGreaterThanOrEqualTo:(double)value; \
-(table##Query*)columnIsLessThan:(double)value; \
-(table##Query*)columnIsLessThanOrEqualTo:(double)value; \
-(table##Query*)columnIsBetween:(double)from and_:(double)to; \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_Double(table, col_name) \
@implementation table##QueryAccessor##col_name \
-(table##Query*)columnIsEqualTo:(double)value \
{ \
    return (table##Query*)[super columnIsEqualTo:value]; \
} \
-(table##Query*)columnIsNotEqualTo:(double)value \
{ \
    return (table##Query*)[super columnIsNotEqualTo:value]; \
} \
-(table##Query*)columnIsGreaterThan:(double)value \
{ \
    return (table##Query*)[super columnIsGreaterThan:value]; \
} \
-(table##Query*)columnIsGreaterThanOrEqualTo:(double)value \
{ \
    return (table##Query*)[super columnIsGreaterThanOrEqualTo:value]; \
} \
-(table##Query*)columnIsLessThan:(double)value \
{ \
    return (table##Query*)[super columnIsLessThan:value]; \
} \
-(table##Query*)columnIsLessThanOrEqualTo:(double)value \
{ \
    return (table##Query*)[super columnIsLessThanOrEqualTo:value]; \
} \
-(table##Query*)columnIsBetween:(double)from and_:(double)to \
{ \
    return (table##Query*)[super columnIsBetween:from and_:to]; \
} \
@end


/* String */

#define TIGHTDB_QUERY_ACCESSOR_DEF_String(table, col_name) \
@interface table##QueryAccessor##col_name : TDBQueryAccessorString \
-(table##Query*)columnIsEqualTo:(NSString*)value; \
-(table##Query*)columnIsEqualTo:(NSString*)value caseSensitive:(BOOL)caseSensitive; \
-(table##Query*)columnIsNotEqualTo:(NSString*)value; \
-(table##Query*)columnIsNotEqualTo:(NSString*)value caseSensitive:(BOOL)caseSensitive; \
-(table##Query*)columnBeginsWith:(NSString*)value; \
-(table##Query*)columnBeginsWith:(NSString*)value caseSensitive:(BOOL)caseSensitive; \
-(table##Query*)columnEndsWith:(NSString*)value; \
-(table##Query*)columnEndsWith:(NSString*)value caseSensitive:(BOOL)caseSensitive; \
-(table##Query*)columnContains:(NSString*)value; \
-(table##Query*)columnContains:(NSString*)value caseSensitive:(BOOL)caseSensitive; \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_String(table, col_name) \
@implementation table##QueryAccessor##col_name \
-(table##Query*)columnIsEqualTo:(NSString*)value \
{ \
    return (table##Query*)[super columnIsEqualTo:value]; \
} \
-(table##Query*)columnIsEqualTo:(NSString*)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (table##Query*)[super columnIsEqualTo:value caseSensitive:caseSensitive]; \
} \
-(table##Query*)columnIsNotEqualTo:(NSString*)value \
{ \
    return (table##Query*)[super columnIsNotEqualTo:value]; \
} \
-(table##Query*)columnIsNotEqualTo:(NSString*)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (table##Query*)[super columnIsNotEqualTo:value caseSensitive:caseSensitive]; \
} \
-(table##Query*)columnBeginsWith:(NSString*)value \
{ \
    return (table##Query*)[super columnBeginsWith:value]; \
} \
-(table##Query*)columnBeginsWith:(NSString*)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (table##Query*)[super columnBeginsWith:value caseSensitive:caseSensitive]; \
} \
-(table##Query*)columnEndsWith:(NSString*)value \
{ \
    return (table##Query*)[super columnEndsWith:value]; \
} \
-(table##Query*)columnEndsWith:(NSString*)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (table##Query*)[super columnEndsWith:value caseSensitive:caseSensitive]; \
} \
-(table##Query*)columnContains:(NSString*)value \
{ \
    return (table##Query*)[super columnContains:value]; \
} \
-(table##Query*)columnContains:(NSString*)value caseSensitive:(BOOL)caseSensitive \
{ \
    return (table##Query*)[super columnContains:value caseSensitive:caseSensitive]; \
} \
@end


/* Binary */

#define TIGHTDB_QUERY_ACCESSOR_DEF_Binary(table, col_name) \
@interface table##QueryAccessor##col_name : TDBQueryAccessorBinary \
-(table##Query*)columnIsEqualTo:(NSData*)value; \
-(table##Query*)columnIsNotEqualTo:(NSData*)value; \
-(table##Query*)columnBeginsWith:(NSData*)value; \
-(table##Query*)columnEndsWith:(NSData*)value; \
-(table##Query*)columnContains:(NSData*)value; \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_Binary(table, col_name) \
@implementation table##QueryAccessor##col_name \
-(table##Query*)columnIsEqualTo:(NSData*)value \
{ \
    return (table##Query*)[super columnIsEqualTo:value]; \
} \
-(table##Query*)columnIsNotEqualTo:(NSData*)value \
{ \
    return (table##Query*)[super columnIsNotEqualTo:value]; \
} \
-(table##Query*)columnBeginsWith:(NSData*)value \
{ \
    return (table##Query*)[super columnBeginsWith:value]; \
} \
-(table##Query*)columnEndsWith:(NSData*)value \
{ \
    return (table##Query*)[super columnEndsWith:value]; \
} \
-(table##Query*)columnContains:(NSData*)value \
{ \
    return (table##Query*)[super columnContains:value]; \
} \
@end


/* Date */

#define TIGHTDB_QUERY_ACCESSOR_DEF_Date(table, col_name) \
@interface table##QueryAccessor##col_name : TDBQueryAccessorDate \
-(table##Query*)columnIsEqualTo:(NSDate *)value; \
-(table##Query*)columnIsNotEqualTo:(NSDate *)value; \
-(table##Query*)columnIsGreaterThan:(NSDate *)value; \
-(table##Query*)columnIsGreaterThanOrEqualTo:(NSDate *)value; \
-(table##Query*)columnIsLessThan:(NSDate *)value; \
-(table##Query*)columnIsLessThanOrEqualTo:(NSDate *)value; \
-(table##Query*)columnIsBetween:(NSDate *)from and_:(NSDate *)to; \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_Date(table, col_name) \
@implementation table##QueryAccessor##col_name \
-(table##Query*)columnIsEqualTo:(NSDate *)value \
{ \
    return (table##Query*)[super columnIsEqualTo:value]; \
} \
-(table##Query*)columnIsNotEqualTo:(NSDate *)value \
{ \
    return (table##Query*)[super columnIsNotEqualTo:value]; \
} \
-(table##Query*)columnIsGreaterThan:(NSDate *)value \
{ \
    return (table##Query*)[super columnIsGreaterThan:value]; \
} \
-(table##Query*)columnIsGreaterThanOrEqualTo:(NSDate *)value \
{ \
    return (table##Query*)[super columnIsGreaterThanOrEqualTo:value]; \
} \
-(table##Query*)columnIsLessThan:(NSDate *)value \
{ \
    return (table##Query*)[super columnIsLessThan:value]; \
} \
-(table##Query*)columnIsLessThanOrEqualTo:(NSDate *)value \
{ \
    return (table##Query*)[super columnIsLessThanOrEqualTo:value]; \
} \
-(table##Query*)columnIsBetween:(NSDate *)from and_:(NSDate *)to \
{ \
    return (table##Query*)[super columnIsBetween:from and_:to]; \
} \
@end


/* Subtable */

#define TIGHTDB_QUERY_ACCESSOR_DEF_SUBTABLE(table, col_name, col_type) \
@interface table##QueryAccessor##col_name : TDBQueryAccessorSubtable \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_SUBTABLE(table, col_name, col_type) \
@implementation table##QueryAccessor##col_name \
@end


/* Mixed */

#define TIGHTDB_QUERY_ACCESSOR_DEF_Mixed(table, col_name) \
@interface table##QueryAccessor##col_name : TDBQueryAccessorMixed \
@end

#define TIGHTDB_QUERY_ACCESSOR_IMPL_Mixed(table, col_name) \
@implementation table##QueryAccessor##col_name \
@end
