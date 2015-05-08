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

#import "RLMArray.h"
#import "RLMObject_Private.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMProperty_Private.h"
#import "RLMSchema_Private.h"
#import "RLMUtil.hpp"

#include <realm.hpp>
using namespace realm;

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

// check a precondition and throw an exception if it is not met
// this should be used iff the condition being false indicates a bug in the caller
// of the function checking its preconditions
static void RLMPrecondition(bool condition, NSString *name, NSString *format, ...) {
    if (__builtin_expect(condition, 1)) {
        return;
    }

    va_list args;
    va_start(args, format);
    NSString *reason = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    @throw [NSException exceptionWithName:name reason:reason userInfo:nil];
}

// return the column index for a validated column name
NSUInteger RLMValidatedColumnIndex(RLMObjectSchema *desc, NSString *columnName) {
    RLMProperty *prop = desc[columnName];
    RLMPrecondition(prop, @"Invalid property name",
                    @"Property '%@' not found in object of type '%@'", columnName, desc.className);
    return prop.column;
}

namespace {

// FIXME: TrueExpression and FalseExpression should be supported by core in some way

struct TrueExpression : realm::Expression {
    size_t find_first(size_t start, size_t end) const override
    {
        if (start != end)
            return start;

        return realm::not_found;
    }
    void set_table() override {}
    const Table* get_table() override { return nullptr; }
};

struct FalseExpression : realm::Expression {
    size_t find_first(size_t, size_t) const override { return realm::not_found; }
    void set_table() override {}
    const Table* get_table() override { return nullptr; }
};

// add a clause for numeric constraints based on operator type
template <typename T>
void add_numeric_constraint_to_query(realm::Query& query,
                                     RLMPropertyType datatype,
                                     NSPredicateOperatorType operatorType,
                                     Columns<T> &&column,
                                     T value)
{
    switch (operatorType) {
        case NSLessThanPredicateOperatorType:
            query.and_query(column < value);
            break;
        case NSLessThanOrEqualToPredicateOperatorType:
            query.and_query(column <= value);
            break;
        case NSGreaterThanPredicateOperatorType:
            query.and_query(column > value);
            break;
        case NSGreaterThanOrEqualToPredicateOperatorType:
            query.and_query(column >= value);
            break;
        case NSEqualToPredicateOperatorType:
            query.and_query(column == value);
            break;
        case NSNotEqualToPredicateOperatorType:
            query.and_query(column != value);
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                         @"Operator type %lu not supported for type %@", (unsigned long)operatorType, RLMTypeToString(datatype));
    }
}

void add_bool_constraint_to_query(realm::Query &query,
                                       NSPredicateOperatorType operatorType,
                                       Columns<Bool> &&column,
                                       bool value) {

    switch (operatorType) {
        case NSEqualToPredicateOperatorType:
            query.and_query(column == value);
            break;
        case NSNotEqualToPredicateOperatorType:
            query.and_query(column != value);
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                         @"Operator type %lu not supported for bool type", (unsigned long)operatorType);
    }
}

void add_string_constraint_to_query(realm::Query &query,
                                    NSPredicateOperatorType operatorType,
                                    NSComparisonPredicateOptions predicateOptions,
                                    Columns<String> &&column,
                                    NSString *value) {
    bool caseSensitive = !(predicateOptions & NSCaseInsensitivePredicateOption);
    bool diacriticInsensitive = (predicateOptions & NSDiacriticInsensitivePredicateOption);
    RLMPrecondition(!diacriticInsensitive, @"Invalid predicate option",
                    @"NSDiacriticInsensitivePredicateOption not supported for string type");

    realm::StringData sd = RLMStringDataWithNSString(value);
    switch (operatorType) {
        case NSBeginsWithPredicateOperatorType:
            query.and_query(column.begins_with(sd, caseSensitive));
            break;
        case NSEndsWithPredicateOperatorType:
            query.and_query(column.ends_with(sd, caseSensitive));
            break;
        case NSContainsPredicateOperatorType:
            query.and_query(column.contains(sd, caseSensitive));
            break;
        case NSEqualToPredicateOperatorType:
            query.and_query(column.equal(sd, caseSensitive));
            break;
        case NSNotEqualToPredicateOperatorType:
            query.and_query(column.not_equal(sd, caseSensitive));
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                         @"Operator type %lu not supported for string type", (unsigned long)operatorType);
    }
}

id value_from_constant_expression_or_value(id value) {
    if (NSExpression *exp = RLMDynamicCast<NSExpression>(value)) {
        RLMPrecondition(exp.expressionType == NSConstantValueExpressionType,
                        @"Invalid value",
                        @"Expressions within predicate aggregates must be constant values");
        return exp.constantValue;
    }
    return value;
}

void validate_and_extract_between_range(id value, RLMProperty *prop, id *from, id *to) {
    NSArray *array = RLMDynamicCast<NSArray>(value);
    RLMPrecondition(array, @"Invalid value", @"object must be of type NSArray for BETWEEN operations");
    RLMPrecondition(array.count == 2, @"Invalid value", @"NSArray object must contain exactly two objects for BETWEEN operations");

    *from = value_from_constant_expression_or_value(array.firstObject);
    *to = value_from_constant_expression_or_value(array.lastObject);
    RLMPrecondition(RLMIsObjectValidForProperty(*from, prop) && RLMIsObjectValidForProperty(*to, prop),
                    @"Invalid value",
                    @"NSArray objects must be of type %@ for BETWEEN operations", RLMTypeToString(prop.type));
}

void add_constraint_to_query(realm::Query &query, RLMPropertyType type,
                             NSPredicateOperatorType operatorType,
                             NSComparisonPredicateOptions predicateOptions,
                             std::vector<NSUInteger> linkColumns, NSUInteger idx, id value);

void add_between_constraint_to_query(realm::Query &query, std::vector<NSUInteger> const& indexes, RLMProperty *prop, id value) {
    id from, to;
    validate_and_extract_between_range(value, prop, &from, &to);

    NSUInteger index = prop.column;

    if (!indexes.empty()) {
        query.group();
        add_constraint_to_query(query, prop.type, NSGreaterThanOrEqualToPredicateOperatorType, 0, indexes, index, from);
        add_constraint_to_query(query, prop.type, NSLessThanOrEqualToPredicateOperatorType, 0, indexes, index, to);
        query.end_group();
        return;
    }

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

void add_binary_constraint_to_query(realm::Query & query,
                                    NSPredicateOperatorType operatorType,
                                    NSUInteger index,
                                    NSData *value) {
    realm::BinaryData binData = RLMBinaryDataForNSData(value);
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

void add_link_constraint_to_query(realm::Query & query,
                                 NSPredicateOperatorType operatorType,
                                 NSUInteger column,
                                 RLMObject *obj) {
    RLMPrecondition(operatorType == NSEqualToPredicateOperatorType || operatorType == NSNotEqualToPredicateOperatorType,
                    @"Invalid operator type", @"Only 'Equal' and 'Not Equal' operators supported for object comparison");
    if (operatorType == NSNotEqualToPredicateOperatorType) {
        query.Not();
    }

    if (obj) {
        query.links_to(column, obj->_row.get_index());
    }
    else {
        query.and_query(query.get_table()->column<Link>(column).is_null());
    }
}

// iterate over an array of subpredicates, using @func to build a query from each
// one and ORing them together
template<typename Func>
void process_or_group(Query &query, id array, Func&& func) {
    RLMPrecondition([array conformsToProtocol:@protocol(NSFastEnumeration)],
                    @"Invalid value", @"IN clause requires an array of items");

    query.group();

    bool first = true;
    for (id item in array) {
        if (!first) {
            query.Or();
        }
        first = false;

        func(item);
    }

    if (first) {
        // Queries can't be empty, so if there's zero things in the OR group
        // validation will fail. Work around this by adding an expression which
        // will never find any rows in a table.
        query.expression(new FalseExpression);
    }

    query.end_group();
}

void add_constraint_to_query(realm::Query &query, RLMPropertyType type,
                             NSPredicateOperatorType operatorType,
                             NSComparisonPredicateOptions predicateOptions,
                             std::vector<NSUInteger> linkColumns, NSUInteger idx, id value)
{
    realm::Table *(^table)() = ^{
        realm::TableRef& tbl = query.get_table();
        for (NSUInteger col : linkColumns) {
            tbl->link(col); // mutates m_link_chain on table
        }
        return tbl.get();
    };

    switch (type) {
        case type_Bool:
            add_bool_constraint_to_query(query, operatorType, table()->column<bool>(idx), bool([value boolValue]));
            break;
        case type_DateTime:
            add_numeric_constraint_to_query(query, type, operatorType, table()->column<Int>(idx), Int([value timeIntervalSince1970]));
            break;
        case type_Double:
            add_numeric_constraint_to_query(query, type, operatorType, table()->column<Double>(idx), [value doubleValue]);
            break;
        case type_Float:
            add_numeric_constraint_to_query(query, type, operatorType, table()->column<Float>(idx), [value floatValue]);
            break;
        case type_Int:
            add_numeric_constraint_to_query(query, type, operatorType, table()->column<Int>(idx), [value longLongValue]);
            break;
        case type_String:
            add_string_constraint_to_query(query, operatorType, predicateOptions, table()->column<String>(idx), value);
            break;
        case type_Binary:
            if (linkColumns.empty()) {
                add_binary_constraint_to_query(query, operatorType, idx, value);
                break;
            }
            else {
                @throw RLMPredicateException(@"Unsupported operator", @"Binary data is not supported.");
            }
        case type_Link:
        case type_LinkList:
            if (linkColumns.empty()) {
                add_link_constraint_to_query(query, operatorType, idx, value);
            }
            else {
                @throw RLMPredicateException(@"Unsupported operator", @"Multi-level object equality link queries are not supported.");
            }
            break;
        default:
            @throw RLMPredicateException(@"Unsupported predicate value type",
                                         @"Object type %@ not supported", RLMTypeToString(type));
    }
}

RLMProperty *get_property_from_key_path(RLMSchema *schema, RLMObjectSchema *desc,
                                        NSString *keyPath, std::vector<NSUInteger> &indexes, bool isAny)
{
    RLMProperty *prop = nil;
    NSArray *paths = [keyPath componentsSeparatedByString:@"."];
    indexes.reserve(paths.count - 1);

    NSString *prevPath = nil;
    for (NSString *path in paths) {
        if (prop) {
            RLMPrecondition(prop.type == RLMPropertyTypeObject || prop.type == RLMPropertyTypeArray,
                            @"Invalid value", @"Property '%@' is not a link in object of type '%@'", prevPath, desc.className);
            indexes.push_back(prop.column);
            prop = desc[path];
            RLMPrecondition(prop, @"Invalid property name",
                            @"Property '%@' not found in object of type '%@'", path, desc.className);
        }
        else {
            prop = desc[path];
            RLMPrecondition(prop, @"Invalid property name",
                            @"Property '%@' not found in object of type '%@'", path, desc.className);

            if (isAny) {
                RLMPrecondition(prop.type == RLMPropertyTypeArray,
                                @"Invalid predicate",
                                @"ANY modifier can only be used for RLMArray properties");
            }
            else {
                RLMPrecondition(prop.type != RLMPropertyTypeArray,
                                @"Invalid predicate",
                                @"RLMArray predicates must contain the ANY modifier");
            }
        }

        if (prop.objectClassName) {
            desc = schema[prop.objectClassName];
        }
        prevPath = path;
    }

    return prop;
}

void validate_property_value(RLMProperty *prop, id value, NSString *err, RLMObjectSchema *objectSchema, NSString *keyPath) {
    if (prop.type == RLMPropertyTypeArray) {
        RLMPrecondition([RLMDynamicCast<RLMObject>(value).objectSchema.className isEqualToString:prop.objectClassName],
                        @"Invalid value", err, prop.objectClassName, keyPath, objectSchema.className, value);
    }
    else {
        RLMPrecondition(RLMIsObjectValidForProperty(value, prop),
                        @"Invalid value", err, RLMTypeToString(prop.type), keyPath, objectSchema.className, value);
    }
}

void update_query_with_value_expression(RLMSchema *schema,
                                        RLMObjectSchema *desc,
                                        realm::Query &query,
                                        NSString *keyPath,
                                        id value,
                                        NSComparisonPredicate *pred)
{
    bool isAny = pred.comparisonPredicateModifier == NSAnyPredicateModifier;
    std::vector<NSUInteger> indexes;
    RLMProperty *prop = get_property_from_key_path(schema, desc, keyPath, indexes, isAny);

    NSUInteger index = prop.column;

    // check to see if this is a between query
    if (pred.predicateOperatorType == NSBetweenPredicateOperatorType) {
        add_between_constraint_to_query(query, indexes, prop, value);
        return;
    }

    // turn IN into ored together ==
    if (pred.predicateOperatorType == NSInPredicateOperatorType) {
        process_or_group(query, value, [&](id item) {
            id normalized = value_from_constant_expression_or_value(item);
            validate_property_value(prop, normalized, @"Expected object of type %@ in IN clause for property '%@' on object of type '%@', but received: %@", desc, keyPath);
            add_constraint_to_query(query, prop.type, NSEqualToPredicateOperatorType,
                                    pred.options, indexes, index, normalized);
        });
        return;
    }

    validate_property_value(prop, value, @"Expected object of type %@ for property '%@' on object of type '%@', but received: %@", desc, keyPath);
    add_constraint_to_query(query, prop.type, pred.predicateOperatorType,
                            pred.options, indexes, index, value);
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

void update_query_with_column_expression(RLMObjectSchema *scheme, Query &query,
                                         NSString *leftColumnName, NSString *rightColumnName,
                                         NSComparisonPredicate *predicate)
{
    // Validate object types
    NSUInteger leftIndex = RLMValidatedColumnIndex(scheme, leftColumnName);
    RLMPropertyType leftType = [scheme[leftColumnName] type];
    RLMPrecondition(leftType != RLMPropertyTypeArray, @"Invalid predicate",
                    @"RLMArray predicates must contain the ANY modifier");

    NSUInteger rightIndex = RLMValidatedColumnIndex(scheme, rightColumnName);
    RLMPropertyType rightType = [scheme[rightColumnName] type];
    RLMPrecondition(rightType != RLMPropertyTypeArray, @"Invalid predicate",
                    @"RLMArray predicates must contain the ANY modifier");

    // NOTE: It's assumed that column type must match and no automatic type conversion is supported.
    RLMPrecondition(leftType == rightType,
                    RLMPropertiesComparisonTypeMismatchException,
                    RLMPropertiesComparisonTypeMismatchReason,
                    RLMTypeToString(leftType),
                    RLMTypeToString(rightType));

    // TODO: Should we handle special case where left row is the same as right row (tautology)
    Table *table = query.get_table().get();
    NSPredicateOperatorType type = predicate.predicateOperatorType;
    switch (leftType) {
        case type_Bool:
            query.and_query(column_expression<Bool>(type, leftIndex, rightIndex, table));
            break;
        case type_Int:
            query.and_query(column_expression<Int>(type, leftIndex, rightIndex, table));
            break;
        case type_Float:
            query.and_query(column_expression<Float>(type, leftIndex, rightIndex, table));
            break;
        case type_Double:
            query.and_query(column_expression<Double>(type, leftIndex, rightIndex, table));
            break;
        case type_DateTime:
            // FIXME: int64_t should be DateTime but that doesn't work on 32 bit
            // FIXME: as time_t(32bit) != time_t(64bit)
            query.and_query(column_expression<int64_t>(type, leftIndex, rightIndex, table));
            break;
        case type_String: {
            bool caseSensitive = (predicate.options & NSCaseInsensitivePredicateOption) == 0;
            switch (type) {
                case NSBeginsWithPredicateOperatorType:
                    query.and_query(table->column<String>(leftIndex).begins_with(table->column<String>(rightIndex), caseSensitive));
                    break;
                case NSEndsWithPredicateOperatorType:
                    query.and_query(table->column<String>(leftIndex).ends_with(table->column<String>(rightIndex), caseSensitive));
                    break;
                case NSContainsPredicateOperatorType:
                    query.and_query(table->column<String>(leftIndex).contains(table->column<String>(rightIndex), caseSensitive));
                    break;
                case NSEqualToPredicateOperatorType:
                    query.and_query(table->column<String>(leftIndex).equal(table->column<String>(rightIndex), caseSensitive));
                    break;
                case NSNotEqualToPredicateOperatorType:
                    query.and_query(table->column<String>(leftIndex).not_equal(table->column<String>(rightIndex), caseSensitive));
                    break;
                default:
                    @throw RLMPredicateException(@"Invalid operator type",
                                                 @"Operator type %lu not supported for string type", (unsigned long)type);
            }
            break;
        }
        default:
            @throw RLMPredicateException(RLMUnsupportedTypesFoundInPropertyComparisonException,
                                         RLMUnsupportedTypesFoundInPropertyComparisonReason,
                                         RLMTypeToString(leftType),
                                         RLMTypeToString(rightType));
    }
}

void update_query_with_predicate(NSPredicate *predicate, RLMSchema *schema,
                                 RLMObjectSchema *objectSchema, realm::Query & query)
{
    // Compound predicates.
    if ([predicate isMemberOfClass:[NSCompoundPredicate class]]) {
        NSCompoundPredicate *comp = (NSCompoundPredicate *)predicate;

        switch ([comp compoundPredicateType]) {
            case NSAndPredicateType:
                if (comp.subpredicates.count) {
                    // Add all of the subpredicates.
                    query.group();
                    for (NSPredicate *subp in comp.subpredicates) {
                        update_query_with_predicate(subp, schema, objectSchema, query);
                    }
                    query.end_group();
                } else {
                    // NSCompoundPredicate's documentation states that an AND predicate with no subpredicates evaluates to TRUE.
                    query.expression(new TrueExpression);
                }
                break;

            case NSOrPredicateType: {
                // Add all of the subpredicates with ors inbetween.
                process_or_group(query, comp.subpredicates, [&](NSPredicate *subp) {
                    update_query_with_predicate(subp, schema, objectSchema, query);
                });
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
        RLMPrecondition(compp.comparisonPredicateModifier != NSAllPredicateModifier,
                        @"Invalid predicate", @"ALL modifier not supported");

        NSExpressionType exp1Type = compp.leftExpression.expressionType;
        NSExpressionType exp2Type = compp.rightExpression.expressionType;

        if (compp.comparisonPredicateModifier == NSAnyPredicateModifier) {
            // for ANY queries
            RLMPrecondition(exp1Type == NSKeyPathExpressionType && exp2Type == NSConstantValueExpressionType,
                            @"Invalid predicate",
                            @"Predicate with ANY modifier must compare a KeyPath with RLMArray with a value");
        }

        if (compp.predicateOperatorType == NSBetweenPredicateOperatorType || compp.predicateOperatorType == NSInPredicateOperatorType) {
            // Inserting an array via %@ gives NSConstantValueExpressionType, but
            // including it directly gives NSAggregateExpressionType
            if (exp1Type != NSKeyPathExpressionType || (exp2Type != NSAggregateExpressionType && exp2Type != NSConstantValueExpressionType)) {
                @throw RLMPredicateException(@"Invalid predicate",
                                             @"Predicate with %s operator must compare a KeyPath with an aggregate with two values",
                                             compp.predicateOperatorType == NSBetweenPredicateOperatorType ? "BETWEEN" : "IN");
            }
            exp2Type = NSConstantValueExpressionType;
        }

        if (exp1Type == NSKeyPathExpressionType && exp2Type == NSKeyPathExpressionType) {
            // both expression are KeyPaths
            update_query_with_column_expression(objectSchema, query, compp.leftExpression.keyPath,
                                                compp.rightExpression.keyPath, compp);
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
    else if ([predicate isEqual:[NSPredicate predicateWithValue:YES]]) {
        query.expression(new TrueExpression);
    } else if ([predicate isEqual:[NSPredicate predicateWithValue:NO]]) {
        query.expression(new FalseExpression);
    }
    else {
        // invalid predicate type
        @throw RLMPredicateException(@"Invalid predicate",
                                     @"Only support compound, comparison, and constant predicates");
    }
}

RLMProperty *RLMValidatedPropertyForSort(RLMObjectSchema *schema, NSString *propName) {
    // validate
    RLMPrecondition(![propName containsString:@"."], @"Invalid sort property", @"Cannot sort on '%@': sorting on key paths is not supported.", propName);
    RLMProperty *prop = schema[propName];
    RLMPrecondition(prop, @"Invalid sort property", @"Cannot sort on property '%@' on object of type '%@': property not found.", propName, schema.className);

    switch (prop.type) {
        case RLMPropertyTypeBool:
        case RLMPropertyTypeDate:
        case RLMPropertyTypeDouble:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeInt:
        case RLMPropertyTypeString:
            break;

        default:
            @throw RLMPredicateException(@"Invalid sort property type",
                                         @"Cannot sort on property '%@' on object of type '%@': sorting is only supported on bool, date, double, float, integer, and string properties, but property is of type %@.", propName, schema.className, RLMTypeToString(prop.type));
    }
    return prop;
}

} // namespace

void RLMUpdateQueryWithPredicate(realm::Query *query, NSPredicate *predicate, RLMSchema *schema,
                                 RLMObjectSchema *objectSchema)
{
    // passing a nil predicate is a no-op
    if (!predicate) {
        return;
    }

    RLMPrecondition([predicate isKindOfClass:NSPredicate.class], @"Invalid argument",
                    @"predicate must be an NSPredicate object");

    update_query_with_predicate(predicate, schema, objectSchema, *query);

    // Test the constructed query in core
    std::string validateMessage = query->validate();
    RLMPrecondition(validateMessage.empty(), @"Invalid query", @"%.*s",
                    (int)validateMessage.size(), validateMessage.c_str());
}

void RLMGetColumnIndices(RLMObjectSchema *schema, NSArray *properties,
                         std::vector<size_t> &columns, std::vector<bool> &order) {
    columns.reserve(properties.count);
    order.reserve(properties.count);

    for (RLMSortDescriptor *descriptor in properties) {
        columns.push_back(RLMValidatedPropertyForSort(schema, descriptor.property).column);
        order.push_back(descriptor.ascending);
    }
}

void RLMUpdateViewWithOrder(realm::TableView &view, RLMObjectSchema *schema, NSArray *properties)
{
    std::vector<size_t> columns;
    std::vector<bool> order;
    RLMGetColumnIndices(schema, properties, columns, order);
    view.sort(move(columns), move(order));
}
