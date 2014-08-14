////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMQueryUtil.hpp"
#import "RLMUtil.hpp"
#import "RLMProperty_Private.h"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObject_Private.h"

#include <tightdb.hpp>
using namespace tightdb;

NSString * const RLMPropertiesComparisonTypeMismatchException = @"RLMPropertiesComparisonTypeMismatchException";
NSString * const RLMUnsupportedTypesFoundInPropertyComparisonException = @"RLMUnsupportedTypesFoundInPropertyComparisonException";

NSString * const RLMPropertiesComparisonTypeMismatchReason = @"Property type mismatch between %@ and %@";
NSString * const RLMUnsupportedTypesFoundInPropertyComparisonReason = @"Comparison between %@ and %@";

// small helper to create the many exceptions thrown when parsing predicates
static NSException *RLMPredicateException(NSString *name, NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *reason = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    return [NSException exceptionWithName:name reason:reason userInfo:nil];
}

// return the column index for a validated column name
NSUInteger RLMValidatedColumnIndex(RLMObjectSchema *desc, NSString *columnName) {
    RLMProperty *prop = desc[columnName];
    if (!prop) {
        @throw RLMPredicateException(@"Invalid column name",
                                     @"Column name %@ not found in table", columnName);
    }
    return prop.column;
}

namespace {

//// apply an expression between two columns to a query
//void update_query_with_column_expression(RLMTable *table, tightdb::Query & query,
//                                         NSString *col1, NSString *col2, NSPredicateOperatorType operatorType) {
//    
//    // only support equality for now
//    if (operatorType != NSEqualToPredicateOperatorType) {
//        @throw RLM_predicate_exception(@"Invalid predicate comparison type",
//                                       @"only support equality comparison type");
//    }
//    
//    // validate column names
//    NSUInteger index1 = RLMValidatedColumnIndex(table, col1);
//    NSUInteger index2 = RLMValidatedColumnIndex(table, col2);
//    
//    // make sure they are the same type
//    tightdb::DataType type1 = table->m_table->get_column_type(index1);
//    tightdb::DataType type2 = table->m_table->get_column_type(index2);
//    
//    if (type1 == type2) {
//        @throw RLM_predicate_exception(@"Invalid predicate expression",
//                                       @"Columns must be the same type");
//    }
//    
//    // not suppoting for now - if we changed names for column comparisons so that we could
//    // use templated function for all numeric types this would be much easier
//    @throw RLM_predicate_exception(@"Unsupported predicate",
//                                   @"Not suppoting column comparison for now");
//}

// add a clause for numeric constraints based on operator type
template <typename T>
void add_numeric_constraint_to_query(tightdb::Query & query,
                                     RLMPropertyType datatype,
                                     NSPredicateOperatorType operatorType,
                                     NSUInteger index,
                                     T value) {
    switch (operatorType) {
        case NSLessThanPredicateOperatorType:
            query.less(index, value);
            break;
        case NSLessThanOrEqualToPredicateOperatorType:
            query.less_equal(index, value);
            break;
        case NSGreaterThanPredicateOperatorType:
            query.greater(index, value);
            break;
        case NSGreaterThanOrEqualToPredicateOperatorType:
            query.greater_equal(index, value);
            break;
        case NSEqualToPredicateOperatorType:
            query.equal(index, value);
            break;
        case NSNotEqualToPredicateOperatorType:
            query.not_equal(index, value);
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                         @"Operator type %lu not supported for type %@", (unsigned long)operatorType, RLMTypeToString(datatype));
    }
}

template <typename T>
void add_numeric_constraint_to_link_query(tightdb::Query& query,
                                          RLMPropertyType datatype,
                                          NSPredicateOperatorType operatorType,
                                          NSUInteger firstIndex,
                                          NSUInteger secondIndex,
                                          T value)
{
    tightdb::TableRef table = query.get_table();

    switch (operatorType) {
        case NSLessThanPredicateOperatorType:
            query.and_query(table->link(firstIndex).column<T>(secondIndex) < value);
            break;
        case NSLessThanOrEqualToPredicateOperatorType:
            query.and_query(table->link(firstIndex).column<T>(secondIndex) <= value);
            break;
        case NSGreaterThanPredicateOperatorType:
            query.and_query(table->link(firstIndex).column<T>(secondIndex) > value);
            break;
        case NSGreaterThanOrEqualToPredicateOperatorType:
            query.and_query(table->link(firstIndex).column<T>(secondIndex) >= value);
            break;
        case NSEqualToPredicateOperatorType:
            query.and_query(table->link(firstIndex).column<T>(secondIndex) == value);
            break;
        case NSNotEqualToPredicateOperatorType:
            query.and_query(table->link(firstIndex).column<T>(secondIndex) != value);
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                         @"Operator type %lu not supported for type %@", (unsigned long)operatorType, RLMTypeToString(datatype));
    }
}


void add_bool_constraint_to_query(tightdb::Query & query,
                                  NSPredicateOperatorType operatorType,
                                  NSUInteger index,
                                  bool value) {
    switch (operatorType) {
        case NSEqualToPredicateOperatorType:
            query.equal(index, value);
            break;
        case NSNotEqualToPredicateOperatorType:
            query.not_equal(index, value);
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                         @"Operator type %lu not supported for bool type", (unsigned long)operatorType);
    }
}

void add_bool_constraint_to_link_query(tightdb::Query& query,
                                       NSPredicateOperatorType operatorType,
                                       NSUInteger firstIndex,
                                       NSUInteger secondIndex,
                                       bool value) {

    tightdb::TableRef table = query.get_table();
    switch (operatorType) {
        case NSEqualToPredicateOperatorType:
            query.and_query(table->link(firstIndex).column<Bool>(secondIndex) == value);
            break;
        case NSNotEqualToPredicateOperatorType:
            query.and_query(table->link(firstIndex).column<Bool>(secondIndex) == value);
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                         @"Operator type %lu not supported for bool type", (unsigned long)operatorType);
    }
}

void add_string_constraint_to_query(tightdb::Query & query,
                                    NSPredicateOperatorType operatorType,
                                    NSComparisonPredicateOptions predicateOptions,
                                    NSUInteger index,
                                    NSString *value) {
    bool caseSensitive = !(predicateOptions & NSCaseInsensitivePredicateOption);
    bool diacriticInsensitive = (predicateOptions & NSDiacriticInsensitivePredicateOption);
    
    if (diacriticInsensitive) {
        @throw RLMPredicateException(@"Invalid predicate option",
                                     @"NSDiacriticInsensitivePredicateOption not supported for string type");
    }
    
    tightdb::StringData sd = RLMStringDataWithNSString(value);
    switch (operatorType) {
        case NSBeginsWithPredicateOperatorType:
            query.begins_with(index, sd, caseSensitive);
            break;
        case NSEndsWithPredicateOperatorType:
            query.ends_with(index, sd, caseSensitive);
            break;
        case NSContainsPredicateOperatorType:
            query.contains(index, sd, caseSensitive);
            break;
        case NSEqualToPredicateOperatorType:
            query.equal(index, sd, caseSensitive);
            break;
        case NSNotEqualToPredicateOperatorType:
            query.not_equal(index, sd, caseSensitive);
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                         @"Operator type %lu not supported for string type", (unsigned long)operatorType);
    }
}

// FIXME: beginsWith, endsWith, contains missing
// FIXME: not case sensitive
void add_string_constraint_to_link_query(tightdb::Query& query,
                                         NSPredicateOperatorType operatorType,
                                         NSComparisonPredicateOptions predicateOptions,
                                         NSUInteger firstIndex,
                                         NSUInteger secondIndex,
                                         NSString *value) {
    bool diacriticInsensitive = (predicateOptions & NSDiacriticInsensitivePredicateOption);
    if (diacriticInsensitive) {
        @throw RLMPredicateException(@"Invalid predicate option",
                                     @"NSDiacriticInsensitivePredicateOption not supported for string type");
    }

    tightdb::TableRef table = query.get_table();
    tightdb::StringData sd = RLMStringDataWithNSString(value);
    switch (operatorType) {
        case NSBeginsWithPredicateOperatorType:
            @throw RLMPredicateException(@"Invalid type", @"Predicate 'BEGINSWITH' is not supported");
            break;
        case NSEndsWithPredicateOperatorType:
            @throw RLMPredicateException(@"Invalid type", @"Predicate 'ENDSWITH' is not supported");
            break;
        case NSContainsPredicateOperatorType:
            @throw RLMPredicateException(@"Invalid type", @"Predicate 'CONTAINS' is not supported");
            break;
        case NSEqualToPredicateOperatorType:
            query.and_query(table->link(firstIndex).column<String>(secondIndex) == sd);
            break;
        case NSNotEqualToPredicateOperatorType:
            query.and_query(table->link(firstIndex).column<String>(secondIndex) != sd);
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                         @"Operator type %lu not supported for string type", (unsigned long)operatorType);
    }
}

void add_datetime_constraint_to_query(tightdb::Query & query,
                                      NSPredicateOperatorType operatorType,
                                      NSUInteger index,
                                      double value) {
    switch (operatorType) {
        case NSLessThanPredicateOperatorType:
            query.less_datetime(index, value);
            break;
        case NSLessThanOrEqualToPredicateOperatorType:
            query.less_equal_datetime(index, value);
            break;
        case NSGreaterThanPredicateOperatorType:
            query.greater_datetime(index, value);
            break;
        case NSGreaterThanOrEqualToPredicateOperatorType:
            query.greater_equal_datetime(index, value);
            break;
        case NSEqualToPredicateOperatorType:
            query.equal_datetime(index, value);
            break;
        case NSNotEqualToPredicateOperatorType:
            query.not_equal_datetime(index, value);
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                         @"Operator type %lu not supported for type NSDate", (unsigned long)operatorType);
    }
}

void add_datetime_constraint_to_link_query(tightdb::Query& query,
                                           NSPredicateOperatorType operatorType,
                                           NSUInteger firstIndex,
                                           NSUInteger secondIndex,
                                           double value)
{
    tightdb::TableRef table = query.get_table();
    switch (operatorType) {
        case NSLessThanPredicateOperatorType:
            query.and_query(table->link(firstIndex).column<Int>(secondIndex) < value);
            break;
        case NSLessThanOrEqualToPredicateOperatorType:
            query.and_query(table->link(firstIndex).column<Int>(secondIndex) <= value);
            break;
        case NSGreaterThanPredicateOperatorType:
            query.and_query(table->link(firstIndex).column<Int>(secondIndex) > value);
            break;
        case NSGreaterThanOrEqualToPredicateOperatorType:
            query.and_query(table->link(firstIndex).column<Int>(secondIndex) >= value);
            break;
        case NSEqualToPredicateOperatorType:
            query.and_query(table->link(firstIndex).column<Int>(secondIndex) == value);
            break;
        case NSNotEqualToPredicateOperatorType:
            query.and_query(table->link(firstIndex).column<Int>(secondIndex) != value);
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                         @"Operator type %lu not supported for type NSDate", (unsigned long)operatorType);
    }
}

id value_from_constant_expression_or_value(id value) {
    if (NSExpression *exp = RLMDynamicCast<NSExpression>(value)) {
        if (exp.expressionType != NSConstantValueExpressionType) {
            @throw RLMPredicateException(@"Invalid value", @"Expressions within predicate aggregates must be constant values");
        }
        return exp.constantValue;
    }
    return value;
}

void validate_and_extract_between_range(id value, RLMProperty *prop, id *from, id *to) {
    NSArray *array = RLMDynamicCast<NSArray>(value);
    if (!array) {
        @throw RLMPredicateException(@"Invalid value", @"object must be of type NSArray for BETWEEN operations");
    }
    if (array.count != 2) {
        @throw RLMPredicateException(@"Invalid value", @"NSArray object must contain exactly two objects for BETWEEN operations");
    }

    *from = value_from_constant_expression_or_value(array.firstObject);
    *to = value_from_constant_expression_or_value(array.lastObject);
    if (!RLMIsObjectValidForProperty(*from, prop) || !RLMIsObjectValidForProperty(*to, prop)) {
        @throw RLMPredicateException(@"Invalid value",
                                     @"NSArray objects must be of type %@ for BETWEEN operations", RLMTypeToString(prop.type));
    }
}

void add_between_constraint_to_query(tightdb::Query & query,
                                     RLMObjectSchema *desc,
                                     NSString *columnName,
                                     id value) {
    RLMProperty *prop = desc[columnName];
    id from, to;
    validate_and_extract_between_range(value, prop, &from, &to);

    NSUInteger index = RLMValidatedColumnIndex(desc, columnName);

    // add to query
    switch (prop.type) {
        case type_DateTime:
            query.between_datetime(index,
                                   [from timeIntervalSince1970],
                                   [to timeIntervalSince1970]);
            break;
        case type_Double:
            query.between(index, [from doubleValue], [to doubleValue]);
            break;
        case type_Float:
            query.between(index, [from floatValue], [to floatValue]);
            break;
        case type_Int:
            query.between(index, [from longLongValue], [to longLongValue]);
            break;
        default:
            @throw RLMPredicateException(@"Unsupported predicate value type",
                                         @"Object type %@ not supported for BETWEEN operations", RLMTypeToString(prop.type));
    }
}

void add_binary_constraint_to_query(tightdb::Query & query,
                                    NSPredicateOperatorType operatorType,
                                    NSUInteger index,
                                    NSData *value) {
    tightdb::BinaryData binData = RLMBinaryDataForNSData(value);
    switch (operatorType) {
        case NSBeginsWithPredicateOperatorType:
            query.begins_with(index, binData);
            break;
        case NSEndsWithPredicateOperatorType:
            query.ends_with(index, binData);
            break;
        case NSContainsPredicateOperatorType:
            query.contains(index, binData);
            break;
        case NSEqualToPredicateOperatorType:
            query.equal(index, binData);
            break;
        case NSNotEqualToPredicateOperatorType:
            query.not_equal(index, binData);
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                         @"Operator type %lu not supported for binary type", (unsigned long)operatorType);
    }
}
    
void add_link_constraint_to_query(tightdb::Query & query,
                                 NSPredicateOperatorType operatorType,
                                 NSUInteger column,
                                 RLMObject *obj) {
    if (operatorType != NSEqualToPredicateOperatorType) {
        @throw RLMPredicateException(@"Invalid operator type", @"Only 'Equal' operator supported for object comparison");
    }
    if (obj) {
        query.links_to(column, obj->_row.get_index());
    }
    else {
        query.and_query(query.get_table()->column<Link>(column).is_null());
    }
}
 
void update_link_query_with_value_expression(RLMSchema *schema,
                                             RLMObjectSchema *desc,
                                             tightdb::Query &query,
                                             NSArray *paths,
                                             id value,
                                             NSPredicateOperatorType operatorType,
                                             NSComparisonPredicateOptions predicateOptions)
{
    // FIXME: when core support multiple levels of link queries
    //        loop through the elements of arr to build up link query
    if (paths.count != 2) {
        @throw RLMPredicateException(@"Invalid predicate", @"Only KeyPaths one level deep are currently supported");
    }
    
    // get the first index and property
    NSUInteger idx1 = RLMValidatedColumnIndex(desc, paths[0]);
    RLMProperty *firstProp = desc[paths[0]];

    // make sure we have a valid property type
    if (firstProp.type != RLMPropertyTypeObject && firstProp.type != RLMPropertyTypeArray) {
        @throw RLMPredicateException(@"Invalid value", @"column name '%@' is not a link", paths[0]);
    }

    // get the next level index and property
    NSUInteger idx2 = RLMValidatedColumnIndex(schema[firstProp.objectClassName], paths[1]);
    RLMProperty *secondProp = schema[firstProp.objectClassName][paths[1]];

    if (operatorType == NSBetweenPredicateOperatorType) {
        id from, to;
        validate_and_extract_between_range(value, secondProp, &from, &to);
        query.group();
        update_link_query_with_value_expression(schema, desc, query, paths, from, NSGreaterThanOrEqualToPredicateOperatorType, 0);
        update_link_query_with_value_expression(schema, desc, query, paths, to, NSLessThanOrEqualToPredicateOperatorType, 0);
        query.end_group();
        return;
    }

    // validate value
    if (!RLMIsObjectValidForProperty(value, secondProp)) {
        @throw RLMPredicateException(@"Invalid value",
                                     @"object for property '%@' must be of type '%@'",
                                     secondProp.name, RLMTypeToString(secondProp.type));
    }

    // finally cast to native types and add query clause
    RLMPropertyType type = secondProp.type;
    switch (type) {
        case type_Bool:
            add_bool_constraint_to_link_query(query, operatorType, idx1, idx2, bool([value boolValue]));
            break;
        case type_DateTime:
            add_datetime_constraint_to_link_query(query, operatorType, idx1, idx2, double([value timeIntervalSince1970]));
            break;
        case type_Double:
            add_numeric_constraint_to_link_query(query, type, operatorType, idx1, idx2, Double([value doubleValue]));
            break;
        case type_Float:
            add_numeric_constraint_to_link_query(query, type, operatorType, idx1, idx2, Float([value floatValue]));
            break;
        case type_Int:
            add_numeric_constraint_to_link_query(query, type, operatorType, idx1, idx2, Int([value longLongValue]));
            break;
        case type_String:
            add_string_constraint_to_link_query(query, operatorType, predicateOptions, idx1, idx2, value);
            break;
        case type_Binary:
            @throw RLMPredicateException(@"Unsupported operator", @"Binary data is not supported.");
        case type_Link:
            add_link_constraint_to_query(query, operatorType, idx1, value);
            break;
        default:
            @throw RLMPredicateException(@"Unsupported predicate value type",
                                         @"Object type %@ not supported", RLMTypeToString(type));
    }
}

void add_constraint_to_query(tightdb::Query &query,
                             NSPredicateOperatorType operatorType,
                             RLMPropertyType type,
                             NSComparisonPredicateOptions options,
                             NSUInteger index,
                             id value) {
    switch (type) {
        case type_Bool:
            add_bool_constraint_to_query(query, operatorType, index, bool([value boolValue]));
            break;
        case type_DateTime:
            add_datetime_constraint_to_query(query, operatorType, index, [value timeIntervalSince1970]);
            break;
        case type_Double:
            add_numeric_constraint_to_query(query, type, operatorType, index, [value doubleValue]);
            break;
        case type_Float:
            add_numeric_constraint_to_query(query, type, operatorType, index, [value floatValue]);
            break;
        case type_Int:
            add_numeric_constraint_to_query(query, type, operatorType, index, [value longLongValue]);
            break;
        case type_String:
            add_string_constraint_to_query(query, operatorType, options, index, value);
            break;
        case type_Binary:
            add_binary_constraint_to_query(query, operatorType, index, value);
            break;
        case type_Link:
            add_link_constraint_to_query(query, operatorType, index, value);
            break;
        default:
            @throw RLMPredicateException(@"Unsupported predicate value type",
                                         @"Object type %@ not supported", RLMTypeToString(type));
    }
}

void update_query_with_value_expression(RLMSchema *schema,
                                        RLMObjectSchema *desc,
                                        tightdb::Query &query,
                                        NSString *keyPath,
                                        id value,
                                        NSComparisonPredicate *pred)
{
    // split keypath
    NSArray *paths = [keyPath componentsSeparatedByString:@"."];
    RLMProperty *prop = desc[paths[0]];

    // make sure we are not comparing on RLMArray
    if (prop.type == RLMPropertyTypeArray) {
        @throw RLMPredicateException(@"Invalid predicate",
                                     @"RLMArray predicates must contain the ANY modifier");
    }

    // check to see if this is a link query
    if (paths.count > 1) {
        update_link_query_with_value_expression(schema, desc, query, paths, value, pred.predicateOperatorType, pred.options);
        return;
    }
    
    // check to see if this is a between query
    if (pred.predicateOperatorType == NSBetweenPredicateOperatorType) {
        add_between_constraint_to_query(query, desc, keyPath, value);
        return;
    }
    
    // get prop and index
    NSUInteger index = RLMValidatedColumnIndex(desc, keyPath);

    // turn IN into ored together ==
    if (pred.predicateOperatorType == NSInPredicateOperatorType) {
        query.group();

        bool first = true;
        for (id item in value) {
            id normalized = value_from_constant_expression_or_value(item);
            if (!RLMIsObjectValidForProperty(normalized, prop)) {
                @throw RLMPredicateException(@"Invalid value", @"object in IN clause must be of type %@", RLMTypeToString(prop.type));
            }

            if (!first) {
                query.Or();
            }
            first = false;
            add_constraint_to_query(query, NSEqualToPredicateOperatorType, prop.type, pred.options, index, normalized);
        }
        query.end_group();
        return;
    }

    // validate value
    if (!RLMIsObjectValidForProperty(value, prop)) {
        @throw RLMPredicateException(@"Invalid value", @"object must be of type %@", RLMTypeToString(prop.type));
    }
    
    // finally cast to native types and add query clause
    add_constraint_to_query(query, pred.predicateOperatorType, prop.type, pred.options, index, value);
}

template<typename T>
Query column_expression(NSComparisonPredicateOptions operatorType,
                                            NSUInteger leftColumn,
                                            NSUInteger rightColumn,
                                            Table *table) {
    switch (operatorType) {
        case NSEqualToPredicateOperatorType:
            return table->column<T>(leftColumn) == table->column<T>(rightColumn);
        case NSNotEqualToPredicateOperatorType:
            return table->column<T>(leftColumn) != table->column<T>(rightColumn);
        case NSLessThanPredicateOperatorType:
            return table->column<T>(leftColumn) < table->column<T>(rightColumn);
        case NSGreaterThanPredicateOperatorType:
            return table->column<T>(leftColumn) > table->column<T>(rightColumn);
        case NSLessThanOrEqualToPredicateOperatorType:
            return table->column<T>(leftColumn) <= table->column<T>(rightColumn);
        case NSGreaterThanOrEqualToPredicateOperatorType:
            return table->column<T>(leftColumn) >= table->column<T>(rightColumn);
        default:
            @throw RLMPredicateException(@"Unsupported operator", @"Only ==, !=, <, <=, >, and >= are supported comparison operators");
    }
}
    
void update_query_with_column_expression(RLMObjectSchema *scheme, Query &query, NSString *leftColumnName, NSString *rightColumnName, NSComparisonPredicateOptions predicateOptions)
{
    // Validate object types
    NSUInteger leftIndex = RLMValidatedColumnIndex(scheme, leftColumnName);
    RLMPropertyType leftType = [scheme[leftColumnName] type];
    
    NSUInteger rightIndex = RLMValidatedColumnIndex(scheme, rightColumnName);
    RLMPropertyType rightType = [scheme[rightColumnName] type];

    if (leftType == RLMPropertyTypeArray || rightType == RLMPropertyTypeArray) {
        @throw RLMPredicateException(@"Invalid predicate",
                                     @"RLMArray predicates must contain the ANY modifier");
    }

    // TODO: Should we handle special case where left row is the same as right row (tautology)
    // NOTE: It's assumed that column type must match and no automatic type conversion is supported.
    if (leftType == rightType) {
        switch (leftType) {
            case type_Bool:
                query.and_query(column_expression<Bool>(predicateOptions, leftIndex, rightIndex, &(*query.get_table())));
                break;
            case type_Int:
                query.and_query(column_expression<Int>(predicateOptions, leftIndex, rightIndex, &(*query.get_table())));
                break;
            case type_Float:
                query.and_query(column_expression<Float>(predicateOptions, leftIndex, rightIndex, &(*query.get_table())));
                break;
            case type_Double:
                query.and_query(column_expression<Double>(predicateOptions, leftIndex, rightIndex, &(*query.get_table())));
                break;
            case type_DateTime:
                // FIXME: int64_t should be DateTime but that doesn't work on 32 bit
                // FIXME: as time_t(32bit) != time_t(64bit)
                query.and_query(column_expression<int64_t>(predicateOptions, leftIndex, rightIndex, &(*query.get_table())));
                break;
            default:
                @throw RLMPredicateException(RLMUnsupportedTypesFoundInPropertyComparisonException,
                                             RLMUnsupportedTypesFoundInPropertyComparisonReason,
                                             RLMTypeToString(leftType),
                                             RLMTypeToString(rightType));
        }
    }
    else {
        @throw RLMPredicateException(RLMPropertiesComparisonTypeMismatchException,
                                     RLMPropertiesComparisonTypeMismatchReason,
                                     RLMTypeToString(leftType),
                                     RLMTypeToString(rightType));
    }
}
    
void update_query_with_predicate(NSPredicate *predicate, RLMSchema *schema,
                                 RLMObjectSchema *objectSchema, tightdb::Query & query)
{
    // Compound predicates.
    if ([predicate isMemberOfClass:[NSCompoundPredicate class]]) {
        NSCompoundPredicate *comp = (NSCompoundPredicate *)predicate;
        
        switch ([comp compoundPredicateType]) {
            case NSAndPredicateType:
                // Add all of the subpredicates.
                query.group();
                for (NSPredicate *subp in comp.subpredicates) {
                    update_query_with_predicate(subp, schema, objectSchema, query);
                }
                query.end_group();
                break;
                
            case NSOrPredicateType: {
                // Add all of the subpredicates with ors inbetween.
                query.group();

                bool first = true;
                for (NSPredicate *subp in comp.subpredicates) {
                    if (!first) {
                        query.Or();
                    }
                    first = false;
                    update_query_with_predicate(subp, schema, objectSchema, query);
                }
                query.end_group();
                break;
            }
                
            case NSNotPredicateType:
                // Add the negated subpredicate
                query.Not();
                update_query_with_predicate(comp.subpredicates.firstObject, schema, objectSchema, query);
                break;
                
            default:
                @throw RLMPredicateException(@"Invalid compound predicate type",
                                             @"Only support AND, OR and NOT predicate types");
        }
    }
    else if ([predicate isMemberOfClass:[NSComparisonPredicate class]]) {
        NSComparisonPredicate *compp = (NSComparisonPredicate *)predicate;
        
        // check modifier
        if (compp.comparisonPredicateModifier == NSAllPredicateModifier) {
            // no support for ALL queries
            @throw RLMPredicateException(@"Invalid predicate",
                                         @"ALL modifier not supported");
        }

        NSExpressionType exp1Type = compp.leftExpression.expressionType;
        NSExpressionType exp2Type = compp.rightExpression.expressionType;

        if (compp.comparisonPredicateModifier == NSAnyPredicateModifier) {
            // for ANY queries
            if (exp1Type != NSKeyPathExpressionType || exp2Type != NSConstantValueExpressionType) {
                @throw RLMPredicateException(@"Invalid predicate",
                                             @"Predicate with ANY modifier must compare a KeyPath with RLMArray with a value");
            }

            // split keypath
            NSArray *paths = [compp.leftExpression.keyPath componentsSeparatedByString:@"."];

            // first component of keypath must be RLMArray
            RLMProperty *arrayProp = objectSchema[paths[0]];
            if (arrayProp.type != RLMPropertyTypeArray) {
                @throw RLMPredicateException(@"Invalid predicate",
                                             @"Predicate with ANY modifier must compare a KeyPath with RLMArray with a value");
            }

            if (paths.count == 1) {
                // querying on object identity
                NSUInteger idx = RLMValidatedColumnIndex(objectSchema, arrayProp.name);
                add_link_constraint_to_query(query, compp.predicateOperatorType, idx, compp.rightExpression.constantValue);
            }
            else if (paths.count > 1) {
                // querying on object properties
                update_link_query_with_value_expression(schema, objectSchema, query, paths, compp.rightExpression.constantValue, compp.predicateOperatorType, compp.options);
            }
            return;
        }

        if (compp.predicateOperatorType == NSBetweenPredicateOperatorType || compp.predicateOperatorType == NSInPredicateOperatorType) {
            // Inserting an array via %@ gives NSConstantValueExpressionType, but
            // including it directly gives NSAggregateExpressionType
            if (exp1Type != NSKeyPathExpressionType || (exp2Type != NSAggregateExpressionType && exp2Type != NSConstantValueExpressionType)) {
                @throw RLMPredicateException(@"Invalid predicate",
                                             @"Predicate with %s operator must compare a KeyPath with an aggregate with two values",
                                             compp.predicateOperatorType == NSBetweenPredicateOperatorType ? "BETWEEN" : "IN");
            }
            update_query_with_value_expression(schema, objectSchema, query, compp.leftExpression.keyPath,
                                               compp.rightExpression.constantValue, compp);
            return;
        }

        if (exp1Type == NSKeyPathExpressionType && exp2Type == NSKeyPathExpressionType) {
            // both expression are KeyPaths
            update_query_with_column_expression(objectSchema, query, compp.leftExpression.keyPath, compp.rightExpression.keyPath,
                                                compp.predicateOperatorType);
        }
        else if (exp1Type == NSKeyPathExpressionType && exp2Type == NSConstantValueExpressionType) {
            // comparing keypath to value
            update_query_with_value_expression(schema, objectSchema, query, compp.leftExpression.keyPath,
                                               compp.rightExpression.constantValue, compp);
        }
        else if (exp1Type == NSConstantValueExpressionType && exp2Type == NSKeyPathExpressionType) {
            // comparing value to keypath
            update_query_with_value_expression(schema, objectSchema, query, compp.rightExpression.keyPath,
                                               compp.leftExpression.constantValue, compp);
        }
        else {
            @throw RLMPredicateException(@"Invalid predicate expressions",
                                         @"Predicate expressions must compare a keypath and another keypath or a constant value");
        }
    }
    else {
        // invalid predicate type
        @throw RLMPredicateException(@"Invalid predicate",
                                     @"Only support compound and comparison predicates");
    }
}

} // namespace

void RLMUpdateQueryWithPredicate(tightdb::Query *query, id predicate, RLMSchema *schema,
                                 RLMObjectSchema *objectSchema)
{
    // parse and apply predicate tree
    if (!predicate) {
        return;
    }

    if ([predicate isKindOfClass:[NSString class]]) {
        predicate = [NSPredicate predicateWithFormat:predicate];
    }

    if (![predicate isKindOfClass:[NSPredicate class]]) {
        @throw RLMPredicateException(@"Invalid argument",
                                     @"Condition should be predicate as string or NSPredicate object");
    }

    update_query_with_predicate(predicate, schema, objectSchema, *query);

    // Test the constructed query in core
    std::string validateMessage = query->validate();
    if (!validateMessage.empty()) {
        @throw RLMPredicateException(@"Invalid query", @"%s", validateMessage.c_str());
    }
}

void RLMUpdateViewWithOrder(tightdb::TableView &view, RLMObjectSchema *schema, NSString *property, BOOL ascending)
{
    if (!property || property.length == 0) {
        return;
    }
    
    // validate
    RLMProperty *prop = schema[property];
    if (!prop) {
        @throw RLMPredicateException(@"Invalid sort column",
                                     @"Column named '%@' not found.", property);
    }
    
    switch (prop.type) {
        case RLMPropertyTypeBool:
        case RLMPropertyTypeDate:
        case RLMPropertyTypeDouble:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeInt:
        case RLMPropertyTypeString:
            view.sort(prop.column, ascending);
            break;
            
        default:
            @throw RLMPredicateException(@"Invalid sort column type",
                                         @"Sorting is only supported on Bool, Date, Double, Float, Integer and String columns.");
    }
}
