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

#import "RLMArray_Private.hpp"
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
    const Table* get_table() const override { return nullptr; }
};

struct FalseExpression : realm::Expression {
    size_t find_first(size_t, size_t) const override { return realm::not_found; }
    void set_table() override {}
    const Table* get_table() const override { return nullptr; }
};

NSString *operatorName(NSPredicateOperatorType operatorType)
{
    switch (operatorType) {
        case NSLessThanPredicateOperatorType:
            return @"<";
        case NSLessThanOrEqualToPredicateOperatorType:
            return @"<=";
        case NSGreaterThanPredicateOperatorType:
            return @">";
        case NSGreaterThanOrEqualToPredicateOperatorType:
            return @">=";
        case NSEqualToPredicateOperatorType:
            return @"==";
        case NSNotEqualToPredicateOperatorType:
            return @"!=";
        case NSMatchesPredicateOperatorType:
            return @"MATCHES";
        case NSLikePredicateOperatorType:
            return @"LIKE";
        case NSBeginsWithPredicateOperatorType:
            return @"BEGINSWITH";
        case NSEndsWithPredicateOperatorType:
            return @"ENDSWITH";
        case NSInPredicateOperatorType:
            return @"IN";
        case NSContainsPredicateOperatorType:
            return @"CONTAINS";
        case NSBetweenPredicateOperatorType:
            return @"BETWEENS";
        case NSCustomSelectorPredicateOperatorType:
            return @"custom selector";
    }

    return [NSString stringWithFormat:@"unknown operator %lu", (unsigned long)operatorType];
}

class CollectionOperation {
public:
    enum Type {
        Count,
        Minimum,
        Maximum,
        Sum,
        Average,
    };

    CollectionOperation(Type type, RLMProperty *linkProperty, RLMProperty *property)
        : m_type(type)
        , m_link_property(linkProperty)
        , m_property(property)
    {
        RLMPrecondition(m_link_property.type == RLMPropertyTypeArray, @"Invalid predicate", @"Collection operation can only be applied to a property of type RLMArray.");

        switch (m_type) {
            case Count:
                RLMPrecondition(!m_property, @"Invalid predicate", @"Result of @count does not have any properties.");
                break;
            case Minimum:
            case Maximum:
            case Sum:
            case Average:
                RLMPrecondition(m_property && RLMPropertyTypeIsNumeric(m_property.type), @"Invalid predicate", @"%@ can only be applied to a numeric property.", name_for_type(m_type));
                break;
        }
    }

    CollectionOperation(NSString *operationName, RLMProperty *linkProperty, RLMProperty *property = nil)
        : CollectionOperation(type_for_name(operationName), linkProperty, property)
    {
    }

    Type type() const { return m_type; }
    NSUInteger linkColumnIndex() const { return m_link_property.column; }
    NSUInteger columnIndex() const { return m_property.column; }
    RLMPropertyType columnType() const { return m_property.type; }

    void validate_value(id value) const {
        switch (m_type) {
            case Count:
            case Average:
                RLMPrecondition([value isKindOfClass:[NSNumber class]], @"Invalid operand", @"%@ can only be compared with a numeric value.", name_for_type(m_type));
                break;
            case Minimum:
            case Maximum:
            case Sum:
                RLMPrecondition(RLMIsObjectValidForProperty(value, m_property), @"Invalid operand", @"%@ on a property of type %@ cannot be compared with '%@'",
                                name_for_type(m_type), RLMTypeToString(m_property.type), value);
                break;
        }
    }

private:
    static Type type_for_name(NSString *name) {
        if ([name isEqualToString:@"@count"]) {
            return Count;
        }
        if ([name isEqualToString:@"@min"]) {
            return Minimum;
        }
        if ([name isEqualToString:@"@max"]) {
            return Maximum;
        }
        if ([name isEqualToString:@"@sum"]) {
            return Sum;
        }
        if ([name isEqualToString:@"@avg"]) {
            return Average;
        }
        @throw RLMPredicateException(@"Invalid predicate", @"Unsupported collection operation '%@'", name);
    }

    static NSString *name_for_type(Type type) {
        switch (type) {
            case Count: return @"@count";
            case Minimum: return @"@min";
            case Maximum: return @"@max";
            case Sum: return @"@sum";
            case Average: return @"@avg";
        }
    }

    Type m_type;
    RLMProperty *m_link_property;
    RLMProperty *m_property;
};

// add a clause for numeric constraints based on operator type
template <typename A, typename B>
void add_numeric_constraint_to_query(realm::Query& query,
                                     RLMPropertyType datatype,
                                     NSPredicateOperatorType operatorType,
                                     A&& lhs,
                                     B&& rhs)
{
    switch (operatorType) {
        case NSLessThanPredicateOperatorType:
            query.and_query(lhs < rhs);
            break;
        case NSLessThanOrEqualToPredicateOperatorType:
            query.and_query(lhs <= rhs);
            break;
        case NSGreaterThanPredicateOperatorType:
            query.and_query(lhs > rhs);
            break;
        case NSGreaterThanOrEqualToPredicateOperatorType:
            query.and_query(lhs >= rhs);
            break;
        case NSEqualToPredicateOperatorType:
            query.and_query(lhs == rhs);
            break;
        case NSNotEqualToPredicateOperatorType:
            query.and_query(lhs != rhs);
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                         @"Operator '%@' not supported for type %@", operatorName(operatorType), RLMTypeToString(datatype));
    }
}

template <typename A, typename B>
void add_bool_constraint_to_query(realm::Query &query, NSPredicateOperatorType operatorType, A lhs, B rhs) {
    switch (operatorType) {
        case NSEqualToPredicateOperatorType:
            query.and_query(lhs == rhs);
            break;
        case NSNotEqualToPredicateOperatorType:
            query.and_query(lhs != rhs);
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                         @"Operator '%@' not supported for bool type", operatorName(operatorType));
    }
}

template <typename T>
void add_string_constraint_to_query(realm::Query &query,
                                    NSPredicateOperatorType operatorType,
                                    NSComparisonPredicateOptions predicateOptions,
                                    Columns<String> &&column,
                                    T value) {
    bool caseSensitive = !(predicateOptions & NSCaseInsensitivePredicateOption);
    bool diacriticInsensitive = (predicateOptions & NSDiacriticInsensitivePredicateOption);
    RLMPrecondition(!diacriticInsensitive, @"Invalid predicate option",
                    @"NSDiacriticInsensitivePredicateOption not supported for string type");

    switch (operatorType) {
        case NSBeginsWithPredicateOperatorType:
            query.and_query(column.begins_with(value, caseSensitive));
            break;
        case NSEndsWithPredicateOperatorType:
            query.and_query(column.ends_with(value, caseSensitive));
            break;
        case NSContainsPredicateOperatorType:
            query.and_query(column.contains(value, caseSensitive));
            break;
        case NSEqualToPredicateOperatorType:
            query.and_query(column.equal(value, caseSensitive));
            break;
        case NSNotEqualToPredicateOperatorType:
            query.and_query(column.not_equal(value, caseSensitive));
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                         @"Operator '%@' not supported for string type", operatorName(operatorType));
    }
}

void add_string_constraint_to_query(realm::Query& query,
                                    NSPredicateOperatorType operatorType,
                                    NSComparisonPredicateOptions predicateOptions,
                                    StringData value,
                                    Columns<String>&& column) {
    switch (operatorType) {
        case NSEqualToPredicateOperatorType:
        case NSNotEqualToPredicateOperatorType:
            add_string_constraint_to_query(query, operatorType, predicateOptions, std::move(column), value);
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                         @"Operator '%@' is not supported for string type with key path on right side of operator",
                                         operatorName(operatorType));
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

template <typename L, typename R>
void add_constraint_to_query(realm::Query &query, RLMPropertyType type,
                             NSPredicateOperatorType operatorType,
                             NSComparisonPredicateOptions predicateOptions,
                             const std::vector<NSUInteger>& linkColumns, L lhs, R rhs);

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

template<typename T>
void add_binary_constraint_to_query(realm::Query & query,
                                    NSPredicateOperatorType operatorType,
                                    NSUInteger index,
                                    T value) {
    switch (operatorType) {
        case NSBeginsWithPredicateOperatorType:
            query.begins_with(index, value);
            break;
        case NSEndsWithPredicateOperatorType:
            query.ends_with(index, value);
            break;
        case NSContainsPredicateOperatorType:
            query.contains(index, value);
            break;
        case NSEqualToPredicateOperatorType:
            query.equal(index, value);
            break;
        case NSNotEqualToPredicateOperatorType:
            query.not_equal(index, value);
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                         @"Operator '%@' not supported for binary type", operatorName(operatorType));
    }
}

void add_binary_constraint_to_query(realm::Query& query, NSPredicateOperatorType operatorType, NSUInteger index, id value) {
    add_binary_constraint_to_query(query, operatorType, index, RLMBinaryDataForNSData(value));
}

void add_binary_constraint_to_query(realm::Query& query, NSPredicateOperatorType operatorType, id value, NSUInteger index) {
    switch (operatorType) {
        case NSEqualToPredicateOperatorType:
        case NSNotEqualToPredicateOperatorType:
            add_binary_constraint_to_query(query, operatorType, index, value);
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                         @"Operator '%@' is not supported for binary type with key path on right side of operator",
                                         operatorName(operatorType));
    }
}

void add_binary_constraint_to_query(realm::Query&, NSPredicateOperatorType, NSUInteger, NSUInteger) {
    @throw RLMPredicateException(@"Invalid predicate", @"Comparisons between two NSData properties are not supported");
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

    query.links_to(column, obj->_row.get_index());
}

void add_link_constraint_to_query(realm::Query & query,
                                 NSPredicateOperatorType operatorType,
                                 NSUInteger column,
                                 realm::null) {
    RLMPrecondition(operatorType == NSEqualToPredicateOperatorType || operatorType == NSNotEqualToPredicateOperatorType,
                    @"Invalid operator type", @"Only 'Equal' and 'Not Equal' operators supported for object comparison");
    if (operatorType == NSNotEqualToPredicateOperatorType) {
        query.Not();
    }

    query.and_query(query.get_table()->column<Link>(column).is_null());
}

template<typename T>
void add_link_constraint_to_query(realm::Query& query, NSPredicateOperatorType operatorType, T obj, NSUInteger column) {
    // Link constraints only support the equal-to and not-equal-to operators. The order of operands
    // is not important for those comparisons so we can delegate to the other implementation.
    add_link_constraint_to_query(query, operatorType, column, obj);
}

void add_link_constraint_to_query(realm::Query&, NSPredicateOperatorType, NSUInteger, NSUInteger) {
    // This is not actually reachable as this case is caught earlier, but this
    // overload is needed for the code to compile
    @throw RLMPredicateException(@"Invalid predicate", @"Comparisons between two RLMArray properties are not supported");
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
        query.and_query(new FalseExpression);
    }

    query.end_group();
}

template <typename RequestedType, typename TableGetter>
struct ColumnOfTypeHelper {
    static realm::Columns<RequestedType> convert(TableGetter&& table, NSUInteger idx) {
        return table()->template column<RequestedType>(idx);
    }
};

template <typename RequestedType>
RequestedType convert(id value);

template <>
DateTime convert<DateTime>(id value) {
    return [value timeIntervalSince1970];
}

template <>
bool convert<bool>(id value) {
    return [value boolValue];
}

template <>
Double convert<Double>(id value) {
    return [value doubleValue];
}

template <>
Float convert<Float>(id value) {
    return [value floatValue];
}

template <>
Int convert<Int>(id value) {
    return [value longLongValue];
}

template <>
String convert<String>(id value) {
    return RLMStringDataWithNSString(value);
}

template <typename RequestedType, typename TableGetter>
struct ValueOfTypeHelper {
    static realm::null convert(TableGetter&&, realm::null) { return realm::null(); }
    static auto convert(TableGetter&&, id value) { return ::convert<RequestedType>(value); }
};

template <typename RequestedType, typename Value, typename TableGetter>
auto value_of_type_for_query(TableGetter&& tables, Value&& value)
{
    const bool isColumnIndex = std::is_same<NSUInteger, typename std::remove_reference<Value>::type>::value;
    using helper = std::conditional_t<isColumnIndex,
                                     ColumnOfTypeHelper<RequestedType, TableGetter>,
                                     ValueOfTypeHelper<RequestedType, TableGetter>>;
    return helper::convert(std::forward<TableGetter>(tables), std::forward<Value>(value));
}

template <typename... T>
void do_add_constraint_to_query(realm::Query &query, RLMPropertyType type,
                                NSPredicateOperatorType operatorType,
                                NSComparisonPredicateOptions predicateOptions,
                                const std::vector<NSUInteger>& linkColumns, T... values)
{
    static_assert(sizeof...(T) == 2, "do_add_constraint_to_query accepts only two values as arguments");

    auto table = [&] {
        realm::TableRef& tbl = query.get_table();
        for (NSUInteger col : linkColumns) {
            tbl->link(col); // mutates m_link_chain on table
        }
        return tbl.get();
    };

    switch (type) {
        case type_Bool:
            add_bool_constraint_to_query(query, operatorType, value_of_type_for_query<bool>(table, values)...);
            break;
        case type_DateTime:
            add_numeric_constraint_to_query(query, type, operatorType, value_of_type_for_query<realm::DateTime>(table, values)...);
            break;
        case type_Double:
            add_numeric_constraint_to_query(query, type, operatorType, value_of_type_for_query<Double>(table, values)...);
            break;
        case type_Float:
            add_numeric_constraint_to_query(query, type, operatorType, value_of_type_for_query<Float>(table, values)...);
            break;
        case type_Int:
            add_numeric_constraint_to_query(query, type, operatorType, value_of_type_for_query<Int>(table, values)...);
            break;
        case type_String:
            add_string_constraint_to_query(query, operatorType, predicateOptions, value_of_type_for_query<String>(table, values)...);
            break;
        case type_Binary:
            if (linkColumns.empty()) {
                add_binary_constraint_to_query(query, operatorType, values...);
                break;
            }
            else {
                @throw RLMPredicateException(@"Unsupported operator", @"NSData properties cannot be queried over an object link.");
            }
        case type_Link:
        case type_LinkList:
            if (linkColumns.empty()) {
                add_link_constraint_to_query(query, operatorType, values...);
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

void do_add_constraint_to_query(realm::Query&, RLMPropertyType, NSPredicateOperatorType,
                                NSComparisonPredicateOptions, const std::vector<NSUInteger>&,
                                id, realm::null)
{
    // This is not actually reachable as this case is caught earlier, but this
    // overload is needed for the code to compile
    @throw RLMPredicateException(@"Invalid predicate expressions",
                                 @"Predicate expressions must compare a keypath and another keypath or a constant value");
}

bool is_nsnull(id value) {
    return !value || value == NSNull.null;
}

template<typename T>
bool is_nsnull(T) {
    return false;
}

template <typename L, typename R>
void add_constraint_to_query(realm::Query &query, RLMPropertyType type,
                             NSPredicateOperatorType operatorType,
                             NSComparisonPredicateOptions predicateOptions,
                             const std::vector<NSUInteger>& linkColumns, L lhs, R rhs)
{
    // The expression operators are only overloaded for realm::null on the rhs
    RLMPrecondition(!is_nsnull(lhs), @"Unsupported operator",
                    @"Nil is only supported on the right side of operators");

    if (is_nsnull(rhs)) {
        do_add_constraint_to_query(query, type, operatorType, predicateOptions, linkColumns, lhs, realm::null());
    }
    else {
        do_add_constraint_to_query(query, type, operatorType, predicateOptions, linkColumns, lhs, rhs);
    }
}

RLMProperty *get_property_from_key_path(RLMSchema *schema, RLMObjectSchema *desc,
                                        NSString *keyPath, std::vector<NSUInteger> &indexes, bool isAggregate)
{
    RLMProperty *prop = nil;

    NSString *prevPath = nil;
    NSUInteger start = 0, length = keyPath.length, end = NSNotFound;
    do {
        end = [keyPath rangeOfString:@"." options:0 range:{start, length - start}].location;
        NSString *path = [keyPath substringWithRange:{start, end == NSNotFound ? length - start : end - start}];
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

            if (isAggregate) {
                RLMPrecondition(prop.type == RLMPropertyTypeArray,
                                @"Invalid predicate",
                                @"Aggregate operations can only be used on RLMArray properties");
            }
            else {
                RLMPrecondition(prop.type != RLMPropertyTypeArray,
                                @"Invalid predicate",
                                @"RLMArray predicates must use aggregate operations");
            }
        }

        if (prop.objectClassName) {
            desc = schema[prop.objectClassName];
        }
        prevPath = path;
        start = end + 1;
    } while (end != NSNotFound);

    return prop;
}

void validate_property_value(__unsafe_unretained RLMProperty *const prop,
                             __unsafe_unretained id const value,
                             __unsafe_unretained NSString *const err,
                             __unsafe_unretained RLMObjectSchema *const objectSchema,
                             __unsafe_unretained NSString *const keyPath) {
    if (prop.type == RLMPropertyTypeArray) {
        RLMPrecondition([RLMObjectBaseObjectSchema(RLMDynamicCast<RLMObjectBase>(value)).className isEqualToString:prop.objectClassName],
                        @"Invalid value", err, prop.objectClassName, keyPath, objectSchema.className, value);
    }
    else {
        RLMPrecondition(RLMIsObjectValidForProperty(value, prop),
                        @"Invalid value", err, RLMTypeToString(prop.type), keyPath, objectSchema.className, value);
    }
}

template <typename RequestedType, CollectionOperation::Type OperationType, typename TableGetter>
struct ValueOfTypeWithCollectionOperationHelper;

template <typename RequestedType, typename TableGetter>
struct ValueOfTypeWithCollectionOperationPassThrough {
    template <typename T>
    static auto convert(TableGetter&& table, T&& value)
    {
        return value_of_type_for_query<RequestedType>(std::forward<TableGetter>(table), std::forward<T>(value));
    }
};

template <typename TableGetter>
struct ValueOfTypeWithCollectionOperationHelper<Int, CollectionOperation::Count, TableGetter> : ValueOfTypeWithCollectionOperationPassThrough<Int, TableGetter> {
    using ValueOfTypeWithCollectionOperationPassThrough<Int, TableGetter>::convert;

    static auto convert(TableGetter&& table, CollectionOperation operation)
    {
        assert(operation.type() == CollectionOperation::Count);
        return table()->template column<Link>(operation.linkColumnIndex()).count();
    }
};

#define VALUE_OF_TYPE_WITH_COLLECTION_OPERATOR_HELPER(OperationType, function) \
template <typename T, typename TableGetter> \
struct ValueOfTypeWithCollectionOperationHelper<T, OperationType, TableGetter> : ValueOfTypeWithCollectionOperationPassThrough<T, TableGetter> { \
    using ValueOfTypeWithCollectionOperationPassThrough<T, TableGetter>::convert; \
\
    static auto convert(TableGetter&& table, CollectionOperation operation) \
    { \
        REALM_ASSERT(operation.type() == OperationType); \
        auto targetColumn = table()->template column<Link>(operation.linkColumnIndex()).template column<T>(operation.columnIndex()); \
        return targetColumn.function(); \
    } \
} \

VALUE_OF_TYPE_WITH_COLLECTION_OPERATOR_HELPER(CollectionOperation::Minimum, min);
VALUE_OF_TYPE_WITH_COLLECTION_OPERATOR_HELPER(CollectionOperation::Maximum, max);
VALUE_OF_TYPE_WITH_COLLECTION_OPERATOR_HELPER(CollectionOperation::Sum, sum);
VALUE_OF_TYPE_WITH_COLLECTION_OPERATOR_HELPER(CollectionOperation::Average, average);
#undef VALUE_OF_TYPE_WITH_COLLECTION_OPERATOR_HELPER

template <typename Requested, CollectionOperation::Type OperationType, typename TableGetter, typename T>
auto value_of_type_for_query_with_collection_operation(TableGetter&& table, T&& value) {
    using helper = ValueOfTypeWithCollectionOperationHelper<Requested, OperationType, TableGetter>;
    return helper::convert(std::forward<TableGetter>(table), std::forward<T>(value));
}

template <CollectionOperation::Type Operation, typename TableGetter, typename... T>
void add_collection_operation_constraint_to_query(realm::Query& query, RLMPropertyType propertyType, NSPredicateOperatorType operatorType, TableGetter&& table, T... values)
{
    switch (propertyType) {
        case RLMPropertyTypeInt:
            add_numeric_constraint_to_query(query, propertyType, operatorType, value_of_type_for_query_with_collection_operation<Int, Operation>(table, values)...);
            break;
        case RLMPropertyTypeFloat:
            add_numeric_constraint_to_query(query, propertyType, operatorType, value_of_type_for_query_with_collection_operation<Float, Operation>(table, values)...);
            break;
        case RLMPropertyTypeDouble:
            add_numeric_constraint_to_query(query, propertyType, operatorType, value_of_type_for_query_with_collection_operation<Double, Operation>(table, values)...);
            break;
        default:
            REALM_ASSERT(false && "Only numeric property types should hit this path.");
    }
}

template <typename... T>
void add_collection_operation_constraint_to_query(realm::Query& query, NSPredicateOperatorType operatorType,
                                                  CollectionOperation collectionOperation, const std::vector<NSUInteger> linkColumns, T... values)
{
    static_assert(sizeof...(T) == 2, "add_collection_operation_constraint_to_query accepts only two values as arguments");

    auto table = [&] {
        realm::TableRef& tbl = query.get_table();
        for (NSUInteger col : linkColumns) {
            tbl->link(col); // mutates m_link_chain on table
        }
        return tbl.get();
    };

    switch (collectionOperation.type()) {
        case CollectionOperation::Count: {
            add_numeric_constraint_to_query(query, RLMPropertyTypeInt, operatorType, value_of_type_for_query_with_collection_operation<Int, CollectionOperation::Count>(table, values)...);
            break;
        }
        case CollectionOperation::Minimum: {
            add_collection_operation_constraint_to_query<CollectionOperation::Minimum>(query, collectionOperation.columnType(), operatorType, table, values...);
            break;
        }
        case CollectionOperation::Maximum: {
            add_collection_operation_constraint_to_query<CollectionOperation::Maximum>(query, collectionOperation.columnType(), operatorType, table, values...);
            break;
        }
        case CollectionOperation::Sum: {
            add_collection_operation_constraint_to_query<CollectionOperation::Sum>(query, collectionOperation.columnType(), operatorType, table, values...);
            break;
        }
        case CollectionOperation::Average: {
            add_collection_operation_constraint_to_query<CollectionOperation::Average>(query, collectionOperation.columnType(), operatorType, table, values...);
            break;
        }
    }
}

bool key_path_contains_collection_operator(NSString *keyPath) {
    return [keyPath rangeOfString:@"@"].location != NSNotFound;
}

NSString *get_collection_operation_name_from_key_path(NSString *keyPath, NSString **leadingKeyPath, NSString **trailingKey) {
    NSRange at  = [keyPath rangeOfString:@"@"];
    if (at.location == NSNotFound || at.location >= keyPath.length - 1) {
        @throw RLMPredicateException(@"Invalid key path", @"'%@' is not a valid key path'", keyPath);
    }

    if ([keyPath characterAtIndex:at.location - 1] != '.') {
        @throw RLMPredicateException(@"Invalid key path", @"'%@' is not a valid key path'", keyPath);
    }

    NSRange trailingKeyRange = [keyPath rangeOfString:@"." options:0 range:{at.location, keyPath.length - at.location} locale:nil];

    *leadingKeyPath = [keyPath substringToIndex:at.location - 1];
    if (trailingKeyRange.location == NSNotFound) {
        *trailingKey = nil;
        return [keyPath substringFromIndex:at.location];
    } else {
        *trailingKey = [keyPath substringFromIndex:trailingKeyRange.location + 1];
        return [keyPath substringWithRange:{at.location, trailingKeyRange.location - at.location}];
    }
}

void update_query_with_collection_operator_expression(RLMSchema *schema,
                                                      RLMObjectSchema *desc,
                                                      realm::Query &query,
                                                      NSString *keyPath,
                                                      id value,
                                                      NSComparisonPredicate *pred) {
    NSString *leadingKeyPath;
    NSString *trailingKey;
    NSString *collectionOperationName = get_collection_operation_name_from_key_path(keyPath, &leadingKeyPath, &trailingKey);

    std::vector<NSUInteger> indexes;
    RLMProperty *linkProperty = get_property_from_key_path(schema, desc, leadingKeyPath, indexes, true);
    RLMProperty *property;
    if (trailingKey) {
        RLMPrecondition([trailingKey rangeOfString:@"."].location == NSNotFound, @"Invalid key path", @"Right side of collection operator may only have a single level key");
        NSString *fullKeyPath = [leadingKeyPath stringByAppendingFormat:@".%@", trailingKey];
        std::vector<NSUInteger> ignoredIndexes;
        property = get_property_from_key_path(schema, desc, fullKeyPath, ignoredIndexes, true);
    }

    CollectionOperation operation(collectionOperationName, linkProperty, property);
    operation.validate_value(value);

    if (pred.leftExpression.expressionType == NSKeyPathExpressionType) {
        add_collection_operation_constraint_to_query(query, pred.predicateOperatorType, operation, indexes, operation, value);
    } else {
        add_collection_operation_constraint_to_query(query, pred.predicateOperatorType, operation, indexes, value, operation);
    }
}

void update_query_with_value_expression(RLMSchema *schema,
                                        RLMObjectSchema *desc,
                                        realm::Query &query,
                                        NSString *keyPath,
                                        id value,
                                        NSComparisonPredicate *pred)
{
    if (key_path_contains_collection_operator(keyPath)) {
        update_query_with_collection_operator_expression(schema, desc, query, keyPath, value, pred);
        return;
    }

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
    if (pred.leftExpression.expressionType == NSKeyPathExpressionType) {
        add_constraint_to_query(query, prop.type, pred.predicateOperatorType,
                                pred.options, indexes, index, value);
    } else {
        add_constraint_to_query(query, prop.type, pred.predicateOperatorType,
                                pred.options, indexes, value, index);
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
    add_constraint_to_query(query, leftType, predicate.predicateOperatorType, predicate.options, {}, leftIndex, rightIndex);
}

void update_query_with_predicate(NSPredicate *predicate, RLMSchema *schema,
                                 RLMObjectSchema *objectSchema, realm::Query &query)
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
                    query.and_query(new TrueExpression);
                }
                break;

            case NSOrPredicateType: {
                // Add all of the subpredicates with ors inbetween.
                process_or_group(query, comp.subpredicates, [&](__unsafe_unretained NSPredicate *const subp) {
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
        query.and_query(new TrueExpression);
    } else if ([predicate isEqual:[NSPredicate predicateWithValue:NO]]) {
        query.and_query(new FalseExpression);
    }
    else {
        // invalid predicate type
        @throw RLMPredicateException(@"Invalid predicate",
                                     @"Only support compound, comparison, and constant predicates");
    }
}

RLMProperty *RLMValidatedPropertyForSort(RLMObjectSchema *schema, NSString *propName) {
    // validate
    RLMPrecondition([propName rangeOfString:@"."].location == NSNotFound, @"Invalid sort property", @"Cannot sort on '%@': sorting on key paths is not supported.", propName);
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

RLMSortOrder RLMSortOrderFromDescriptors(RLMObjectSchema *objectSchema, NSArray *descriptors) {
    RLMSortOrder sort;
    sort.columnIndices.reserve(descriptors.count);
    sort.ascending.reserve(descriptors.count);

    for (RLMSortDescriptor *descriptor in descriptors) {
        sort.columnIndices.push_back(RLMValidatedPropertyForSort(objectSchema, descriptor.property).column);
        sort.ascending.push_back(descriptor.ascending);
    }

    return sort;
}
