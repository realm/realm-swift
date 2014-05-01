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

#define REALM_VA_NARGS_IMPL(_1, _2, _3, _4, _5, N, ...) N
#define REALM_VA_NARGS(...) REALM_VA_NARGS_IMPL(__VA_ARGS__, 5, 4, 3, 2, 1)

#define REALM_IS_SUBTABLE(col_type) REALM_IS_SUBTABLE_2(REALM_IS_SUBTABLE_##col_type)
#define REALM_IS_SUBTABLE_2(...)    REALM_IS_SUBTABLE_3(REALM_VA_NARGS(__VA_ARGS__))
#define REALM_IS_SUBTABLE_3(count)  REALM_IS_SUBTABLE_4(count)
#define REALM_IS_SUBTABLE_4(count)  REALM_IS_SUBTABLE_5_##count
#define REALM_IS_SUBTABLE_5_1       Y
#define REALM_IS_SUBTABLE_5_2       N
#define REALM_IS_SUBTABLE_Int       x,x
#define REALM_IS_SUBTABLE_Bool      x,x
#define REALM_IS_SUBTABLE_Float     x,x
#define REALM_IS_SUBTABLE_Double    x,x
#define REALM_IS_SUBTABLE_String    x,x
#define REALM_IS_SUBTABLE_Binary    x,x
#define REALM_IS_SUBTABLE_Date      x,x
#define REALM_IS_SUBTABLE_Mixed     x,x

#define REALM_TYPE_Bool      BOOL
#define REALM_TYPE_Int       int64_t
#define REALM_TYPE_Float     float
#define REALM_TYPE_Double    double
#define REALM_TYPE_String    NSString*
#define REALM_TYPE_Binary    NSData *
#define REALM_TYPE_Date      NSDate *
#define REALM_TYPE_Mixed     id

#define REALM_TYPE_ID_Bool   RLMTypeBool
#define REALM_TYPE_ID_Int    RLMTypeInt
#define REALM_TYPE_ID_Float  RLMTypeFloat
#define REALM_TYPE_ID_Double RLMTypeDouble
#define REALM_TYPE_ID_String RLMTypeString
#define REALM_TYPE_ID_Binary RLMTypeBinary
#define REALM_TYPE_ID_Date   RLMTypeDate
#define REALM_TYPE_ID_Mixed  RLMTypeMixed



/* REALM_ARG_TYPE */

#define REALM_ARG_TYPE(type)                 REALM_ARG_TYPE_2(REALM_IS_SUBTABLE(type), type)
#define REALM_ARG_TYPE_2(is_subtable, type)  REALM_ARG_TYPE_3(is_subtable, type)
#define REALM_ARG_TYPE_3(is_subtable, type)  REALM_ARG_TYPE_4_##is_subtable(type)
#define REALM_ARG_TYPE_4_Y(type)             type*
#define REALM_ARG_TYPE_4_N(type)             REALM_TYPE_##type



/* REALM_COLUMN_PROXY */

#define REALM_COLUMN_PROXY_DEF(name, type)                 REALM_COLUMN_PROXY_DEF_2(REALM_IS_SUBTABLE(type), name, type)
#define REALM_COLUMN_PROXY_DEF_2(is_subtable, name, type)  REALM_COLUMN_PROXY_DEF_3(is_subtable, name, type)
#define REALM_COLUMN_PROXY_DEF_3(is_subtable, name, type)  REALM_COLUMN_PROXY_DEF_4_##is_subtable(name, type)
#define REALM_COLUMN_PROXY_DEF_4_Y(name, type)             @property(nonatomic, strong) RLMColumnProxySubtable* name;
#define REALM_COLUMN_PROXY_DEF_4_N(name, type)             @property(nonatomic, strong) RLMColumnProxy##type* name;

#define REALM_COLUMN_PROXY_IMPL(name, type)                @synthesize name = _##name;

#define REALM_COLUMN_PROXY_INIT(table, col, name, type)                REALM_COLUMN_PROXY_INIT_2(REALM_IS_SUBTABLE(type), table, col, name, type)
#define REALM_COLUMN_PROXY_INIT_2(is_subtable, table, col, name, type) REALM_COLUMN_PROXY_INIT_3(is_subtable, table, col, name, type)
#define REALM_COLUMN_PROXY_INIT_3(is_subtable, table, col, name, type) REALM_COLUMN_PROXY_INIT_4_##is_subtable(table, col, name, type)
#define REALM_COLUMN_PROXY_INIT_4_Y(table, col, name, type)            _##name = [[RLMColumnProxySubtable alloc] initWithTable:table column:col]
#define REALM_COLUMN_PROXY_INIT_4_N(table, col, name, type)            _##name = [[RLMColumnProxy##type alloc] initWithTable:table column:col]



/* REALM_ADD_COLUMN */

#define REALM_ADD_COLUMN(desc, name, type)                REALM_ADD_COLUMN_2(REALM_IS_SUBTABLE(type), desc, name, type)
#define REALM_ADD_COLUMN_2(is_subtable, desc, name, type) REALM_ADD_COLUMN_3(is_subtable, desc, name, type)
#define REALM_ADD_COLUMN_3(is_subtable, desc, name, type) REALM_ADD_COLUMN_4_##is_subtable(desc, name, type)
#define REALM_ADD_COLUMN_4_Y(desc, _name, type) \
{ \
    NSString* name = [NSString stringWithUTF8String:#_name]; \
    if (!name) \
        return NO; \
    RLMDescriptor* subdesc = [desc addColumnTable:name]; \
    if (!subdesc) \
        return NO; \
    if (![type _addColumns:subdesc]) \
        return NO; \
}
#define REALM_ADD_COLUMN_4_N(desc, _name, _type) \
{ \
    NSString* name = [NSString stringWithUTF8String:#_name]; \
    if (!name) \
        return NO; \
    if ([desc addColumnWithName:name type:REALM_TYPE_ID_##_type] == NSNotFound) \
        return NO; \
}



/* REALM_CHECK_COLUMN_TYPE */

#define REALM_CHECK_COLUMN_TYPE(desc, col, name, type)                REALM_CHECK_COLUMN_TYPE_2(REALM_IS_SUBTABLE(type), desc, col, name, type)
#define REALM_CHECK_COLUMN_TYPE_2(is_subtable, desc, col, name, type) REALM_CHECK_COLUMN_TYPE_3(is_subtable, desc, col, name, type)
#define REALM_CHECK_COLUMN_TYPE_3(is_subtable, desc, col, name, type) REALM_CHECK_COLUMN_TYPE_4_##is_subtable(desc, col, name, type)
#define REALM_CHECK_COLUMN_TYPE_4_Y(desc, col, name, type)      \
{ \
    if ([desc columnTypeOfColumnWithIndex:col] != RLMTypeTable) \
        return NO; \
    if (![[desc nameOfColumnWithIndex:col] isEqualToString:@#name]) \
        return NO; \
    RLMDescriptor* subdesc = [desc subdescriptorForColumnWithIndex:col]; \
    if (!subdesc) \
        return NO; \
    if (![type _checkType:subdesc]) \
        return NO; \
}
#define REALM_CHECK_COLUMN_TYPE_4_N(desc, col, name, type) \
{ \
    if ([desc columnTypeOfColumnWithIndex:col] != REALM_TYPE_ID_##type) \
        return NO; \
    if (![[desc nameOfColumnWithIndex:col] isEqualToString:@#name]) \
        return NO; \
}



/* REALM_COLUMN_INSERT */

#define REALM_COLUMN_INSERT(table, col, row, value, type)                REALM_COLUMN_INSERT_2(REALM_IS_SUBTABLE(type), table, col, row, value, type)
#define REALM_COLUMN_INSERT_2(is_subtable, table, col, row, value, type) REALM_COLUMN_INSERT_3(is_subtable, table, col, row, value, type)
#define REALM_COLUMN_INSERT_3(is_subtable, table, col, row, value, type) REALM_COLUMN_INSERT_4_##is_subtable(table, col, row, value, type)
#define REALM_COLUMN_INSERT_4_Y(table, col, _row, value, type)           [table RLM_insertSubtableCopy:col row:_row subtable:value]
#define REALM_COLUMN_INSERT_4_N(table, col, row, _value, type)           [table RLM_insert##type:col ndx:row value:_value]



/* REALM_ROW_PROPERTY */

#define REALM_ROW_PROPERTY_DEF(name, type)                 REALM_ROW_PROPERTY_DEF_2(REALM_IS_SUBTABLE(type), name, type)
#define REALM_ROW_PROPERTY_DEF_2(is_subtable, name, type)  REALM_ROW_PROPERTY_DEF_3(is_subtable, name, type)
#define REALM_ROW_PROPERTY_DEF_3(is_subtable, name, type)  REALM_ROW_PROPERTY_DEF_4_##is_subtable(name, type)
#define REALM_ROW_PROPERTY_DEF_4_Y(name, type)             REALM_ROW_PROPERTY_DEF_SUBTABLE(name, type)
#define REALM_ROW_PROPERTY_DEF_4_N(name, type)             REALM_ROW_PROPERTY_DEF_SIMPLE(name, type)

#define REALM_ROW_PROPERTY_IMPL(name, type)                REALM_ROW_PROPERTY_IMPL_2(REALM_IS_SUBTABLE(type), name, type)
#define REALM_ROW_PROPERTY_IMPL_2(is_subtable, name, type) REALM_ROW_PROPERTY_IMPL_3(is_subtable, name, type)
#define REALM_ROW_PROPERTY_IMPL_3(is_subtable, name, type) REALM_ROW_PROPERTY_IMPL_4_##is_subtable(name, type)
#define REALM_ROW_PROPERTY_IMPL_4_Y(name, type)            REALM_ROW_PROPERTY_IMPL_SUBTABLE(name, type)
#define REALM_ROW_PROPERTY_IMPL_4_N(name, type)            REALM_ROW_PROPERTY_IMPL_SIMPLE(name, type)


#define REALM_ROW_PROPERTY_DEF_SIMPLE(name, type) \
@property (nonatomic, setter = RLM_set##name: , getter = RLM_##name) REALM_TYPE_##type name; \
-(REALM_TYPE_##type)RLM_##name; \
-(void)RLM_set##name:(REALM_TYPE_##type)value;

#define REALM_ROW_PROPERTY_IMPL_SIMPLE(name, type) \
-(REALM_TYPE_##type)RLM_##name \
{ \
    return [_##name get##type]; \
} \
-(void)RLM_set##name:(REALM_TYPE_##type)value \
{ \
    [_##name set##type:value]; \
}

#define REALM_ROW_PROPERTY_DEF_SUBTABLE(name, type) \
@property type* name; \
-(type*)name; \

#define REALM_ROW_PROPERTY_IMPL_SUBTABLE(name, type) \
-(type*)name \
{ \
    return [_##name getSubtable:[type class]]; \
} \
-(void)set##name:(type*)subtable \
{ \
    [_##name setSubtable:subtable]; \
} \

/* REALM_QUERY_ACCESSOR */

#define REALM_QUERY_ACCESSOR_DEF(table, col_name, col_type)                 REALM_QUERY_ACCESSOR_DEF_2(REALM_IS_SUBTABLE(col_type), table, col_name, col_type)
#define REALM_QUERY_ACCESSOR_DEF_2(is_subtable, table, col_name, col_type)  REALM_QUERY_ACCESSOR_DEF_3(is_subtable, table, col_name, col_type)
#define REALM_QUERY_ACCESSOR_DEF_3(is_subtable, table, col_name, col_type)  REALM_QUERY_ACCESSOR_DEF_4_##is_subtable(table, col_name, col_type)
#define REALM_QUERY_ACCESSOR_DEF_4_Y(table, col_name, col_type)             REALM_QUERY_ACCESSOR_DEF_SUBTABLE(table, col_name, col_type)
#define REALM_QUERY_ACCESSOR_DEF_4_N(table, col_name, col_type)             REALM_QUERY_ACCESSOR_DEF_##col_type(table, col_name)

#define REALM_QUERY_ACCESSOR_IMPL(table, col_name, col_type)                REALM_QUERY_ACCESSOR_IMPL_2(REALM_IS_SUBTABLE(col_type), table, col_name, col_type)
#define REALM_QUERY_ACCESSOR_IMPL_2(is_subtable, table, col_name, col_type) REALM_QUERY_ACCESSOR_IMPL_3(is_subtable, table, col_name, col_type)
#define REALM_QUERY_ACCESSOR_IMPL_3(is_subtable, table, col_name, col_type) REALM_QUERY_ACCESSOR_IMPL_4_##is_subtable(table, col_name, col_type)
#define REALM_QUERY_ACCESSOR_IMPL_4_Y(table, col_name, col_type)            REALM_QUERY_ACCESSOR_IMPL_SUBTABLE(table, col_name, col_type)
#define REALM_QUERY_ACCESSOR_IMPL_4_N(table, col_name, col_type)            REALM_QUERY_ACCESSOR_IMPL_##col_type(table, col_name)


/* Boolean */

#define REALM_QUERY_ACCESSOR_DEF_Bool(table, col_name) \
@interface table##QueryAccessor##col_name : RLMQueryAccessorBool \
-(table##Query*)columnIsEqualTo:(BOOL)value; \
@end

#define REALM_QUERY_ACCESSOR_IMPL_Bool(table, col_name) \
@implementation table##QueryAccessor##col_name \
-(table##Query*)columnIsEqualTo:(BOOL)value \
{ \
    return (table##Query*)[super columnIsEqualTo:value]; \
} \
@end


/* Integer */

#define REALM_QUERY_ACCESSOR_DEF_Int(table, col_name) \
@interface table##QueryAccessor##col_name : RLMQueryAccessorInt \
-(table##Query*)columnIsEqualTo:(int64_t)value; \
-(table##Query*)columnIsNotEqualTo:(int64_t)value; \
-(table##Query*)columnIsGreaterThan:(int64_t)value; \
-(table##Query*)columnIsGreaterThanOrEqualTo:(int64_t)value; \
-(table##Query*)columnIsLessThan:(int64_t)value; \
-(table##Query*)columnIsLessThanOrEqualTo:(int64_t)value; \
-(table##Query*)columnIsBetween:(int64_t)from :(int64_t)to; \
@end

#define REALM_QUERY_ACCESSOR_IMPL_Int(table, col_name) \
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
-(table##Query*)columnIsBetween:(int64_t)from :(int64_t)to \
{ \
    return (table##Query*)[super columnIsBetween:from :to]; \
} \
@end


/* Float */

#define REALM_QUERY_ACCESSOR_DEF_Float(table, col_name) \
@interface table##QueryAccessor##col_name : RLMQueryAccessorFloat \
-(table##Query*)columnIsEqualTo:(float)value; \
-(table##Query*)columnIsNotEqualTo:(float)value; \
-(table##Query*)columnIsGreaterThan:(float)value; \
-(table##Query*)columnIsGreaterThanOrEqualTo:(float)value; \
-(table##Query*)columnIsLessThan:(float)value; \
-(table##Query*)columnIsLessThanOrEqualTo:(float)value; \
-(table##Query*)columnIsBetween:(float)from :(float)to; \
@end

#define REALM_QUERY_ACCESSOR_IMPL_Float(table, col_name) \
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
-(table##Query*)columnIsBetween:(float)from :(float)to \
{ \
    return (table##Query*)[super columnIsBetween:from :to]; \
} \
@end


/* Double */

#define REALM_QUERY_ACCESSOR_DEF_Double(table, col_name) \
@interface table##QueryAccessor##col_name : RLMQueryAccessorDouble \
-(table##Query*)columnIsEqualTo:(double)value; \
-(table##Query*)columnIsNotEqualTo:(double)value; \
-(table##Query*)columnIsGreaterThan:(double)value; \
-(table##Query*)columnIsGreaterThanOrEqualTo:(double)value; \
-(table##Query*)columnIsLessThan:(double)value; \
-(table##Query*)columnIsLessThanOrEqualTo:(double)value; \
-(table##Query*)columnIsBetween:(double)from :(double)to; \
@end

#define REALM_QUERY_ACCESSOR_IMPL_Double(table, col_name) \
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
-(table##Query*)columnIsBetween:(double)from :(double)to \
{ \
    return (table##Query*)[super columnIsBetween:from :to]; \
} \
@end


/* String */

#define REALM_QUERY_ACCESSOR_DEF_String(table, col_name) \
@interface table##QueryAccessor##col_name : RLMQueryAccessorString \
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

#define REALM_QUERY_ACCESSOR_IMPL_String(table, col_name) \
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

#define REALM_QUERY_ACCESSOR_DEF_Binary(table, col_name) \
@interface table##QueryAccessor##col_name : RLMQueryAccessorBinary \
-(table##Query*)columnIsEqualTo:(NSData*)value; \
-(table##Query*)columnIsNotEqualTo:(NSData*)value; \
-(table##Query*)columnBeginsWith:(NSData*)value; \
-(table##Query*)columnEndsWith:(NSData*)value; \
-(table##Query*)columnContains:(NSData*)value; \
@end

#define REALM_QUERY_ACCESSOR_IMPL_Binary(table, col_name) \
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

#define REALM_QUERY_ACCESSOR_DEF_Date(table, col_name) \
@interface table##QueryAccessor##col_name : RLMQueryAccessorDate \
-(table##Query*)columnIsEqualTo:(NSDate *)value; \
-(table##Query*)columnIsNotEqualTo:(NSDate *)value; \
-(table##Query*)columnIsGreaterThan:(NSDate *)value; \
-(table##Query*)columnIsGreaterThanOrEqualTo:(NSDate *)value; \
-(table##Query*)columnIsLessThan:(NSDate *)value; \
-(table##Query*)columnIsLessThanOrEqualTo:(NSDate *)value; \
-(table##Query*)columnIsBetween:(NSDate *)from :(NSDate *)to; \
@end

#define REALM_QUERY_ACCESSOR_IMPL_Date(table, col_name) \
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
-(table##Query*)columnIsBetween:(NSDate *)from :(NSDate *)to \
{ \
    return (table##Query*)[super columnIsBetween:from :to]; \
} \
@end


/* Subtable */

#define REALM_QUERY_ACCESSOR_DEF_SUBTABLE(table, col_name, col_type) \
@interface table##QueryAccessor##col_name : RLMQueryAccessorSubtable \
@end

#define REALM_QUERY_ACCESSOR_IMPL_SUBTABLE(table, col_name, col_type) \
@implementation table##QueryAccessor##col_name \
@end


/* Mixed */

#define REALM_QUERY_ACCESSOR_DEF_Mixed(table, col_name) \
@interface table##QueryAccessor##col_name : RLMQueryAccessorMixed \
@end

#define REALM_QUERY_ACCESSOR_IMPL_Mixed(table, col_name) \
@implementation table##QueryAccessor##col_name \
@end
