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
#import "RLMObjectSchema_Private.h"
#import "RLMObject_Private.hpp"
#import "RLMPredicateUtil.hpp"
#import "RLMProperty_Private.h"
#import "RLMSchema.h"
#import "RLMUtil.hpp"

#import "object_store.hpp"
#import "results.hpp"

#include <realm/query_engine.hpp>
#include <realm/query_expression.hpp>
#include <realm/util/cf_ptr.hpp>

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

// return the property for a validated column name
RLMProperty *RLMValidatedProperty(RLMObjectSchema *desc, NSString *columnName) {
    RLMProperty *prop = desc[columnName];
    RLMPrecondition(prop, @"Invalid property name",
                    @"Property '%@' not found in object of type '%@'", columnName, desc.className);
    return prop;
}

namespace {
BOOL RLMPropertyTypeIsNumeric(RLMPropertyType propertyType) {
    switch (propertyType) {
        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
            return YES;
        default:
            return NO;
    }
}


// Declare an overload set using lambdas or other function objects.
// A minimal version of C++ Library Evolution Working Group proposal P0051R2.
// FIXME: Switch to realm::util::overload once https://github.com/realm/realm-core/pull/2539 is in a core release.

template <typename Fn, typename... Fns>
struct Overloaded : Fn, Overloaded<Fns...> {
    template <typename U, typename... Rest>
    Overloaded(U&& fn, Rest&&... rest) : Fn(std::forward<U>(fn)), Overloaded<Fns...>(std::forward<Rest>(rest)...) { }

    using Fn::operator();
    using Overloaded<Fns...>::operator();
};

template <typename Fn>
struct Overloaded<Fn> : Fn {
    template <typename U>
    Overloaded(U&& fn) : Fn(std::forward<U>(fn)) { }

    using Fn::operator();
};

template <typename... Fns>
Overloaded<Fns...> overload(Fns&&... f)
{
    return Overloaded<Fns...>(std::forward<Fns>(f)...);
}


// FIXME: TrueExpression and FalseExpression should be supported by core in some way

struct TrueExpression : realm::Expression {
    size_t find_first(size_t start, size_t end) const override
    {
        if (start != end)
            return start;

        return realm::not_found;
    }
    void set_base_table(const Table*) override {}
    void verify_column() const override {}
    const Table* get_base_table() const override { return nullptr; }
    std::unique_ptr<Expression> clone(QueryNodeHandoverPatches*) const override
    {
        return std::unique_ptr<Expression>(new TrueExpression(*this));
    }
};

struct FalseExpression : realm::Expression {
    size_t find_first(size_t, size_t) const override { return realm::not_found; }
    void set_base_table(const Table*) override {}
    void verify_column() const override {}
    const Table* get_base_table() const override { return nullptr; }
    std::unique_ptr<Expression> clone(QueryNodeHandoverPatches*) const override
    {
        return std::unique_ptr<Expression>(new FalseExpression(*this));
    }
};


// Equal and ContainsSubstring are used by QueryBuilder::add_string_constraint as the comparator
// for performing diacritic-insensitive comparisons.

bool equal(CFStringCompareFlags options, StringData v1, StringData v2)
{
    if (v1.is_null() || v2.is_null()) {
        return v1.is_null() == v2.is_null();
    }

    auto s1 = util::adoptCF(CFStringCreateWithBytesNoCopy(kCFAllocatorSystemDefault, (const UInt8*)v1.data(), v1.size(),
                                                          kCFStringEncodingUTF8, false, kCFAllocatorNull));
    auto s2 = util::adoptCF(CFStringCreateWithBytesNoCopy(kCFAllocatorSystemDefault, (const UInt8*)v2.data(), v2.size(),
                                                          kCFStringEncodingUTF8, false, kCFAllocatorNull));

    return CFStringCompare(s1.get(), s2.get(), options) == kCFCompareEqualTo;
}

template <CFStringCompareFlags options>
struct Equal {
    using CaseSensitive = Equal<options & ~kCFCompareCaseInsensitive>;
    using CaseInsensitive = Equal<options | kCFCompareCaseInsensitive>;

    bool operator()(StringData v1, StringData v2, bool v1_null, bool v2_null) const
    {
        REALM_ASSERT_DEBUG(v1_null == v1.is_null());
        REALM_ASSERT_DEBUG(v2_null == v2.is_null());

        return equal(options, v1, v2);
    }
};

bool contains_substring(CFStringCompareFlags options, StringData v1, StringData v2)
{
    if (v2.is_null()) {
        // Everything contains NULL
        return true;
    }

    if (v1.is_null()) {
        // NULL contains nothing (except NULL, handled above)
        return false;
    }

    if (v2.size() == 0) {
        // Everything (except NULL, handled above) contains the empty string
        return true;
    }

    auto s1 = util::adoptCF(CFStringCreateWithBytesNoCopy(kCFAllocatorSystemDefault, (const UInt8*)v1.data(), v1.size(),
                                                          kCFStringEncodingUTF8, false, kCFAllocatorNull));
    auto s2 = util::adoptCF(CFStringCreateWithBytesNoCopy(kCFAllocatorSystemDefault, (const UInt8*)v2.data(), v2.size(),
                                                          kCFStringEncodingUTF8, false, kCFAllocatorNull));

    return CFStringFind(s1.get(), s2.get(), options).location != kCFNotFound;
}

template <CFStringCompareFlags options>
struct ContainsSubstring {
    using CaseSensitive = ContainsSubstring<options & ~kCFCompareCaseInsensitive>;
    using CaseInsensitive = ContainsSubstring<options | kCFCompareCaseInsensitive>;

    bool operator()(StringData v1, StringData v2, bool v1_null, bool v2_null) const
    {
        REALM_ASSERT_DEBUG(v1_null == v1.is_null());
        REALM_ASSERT_DEBUG(v2_null == v2.is_null());

        return contains_substring(options, v1, v2);
    }
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
            return @"BETWEEN";
        case NSCustomSelectorPredicateOperatorType:
            return @"custom selector";
    }

    return [NSString stringWithFormat:@"unknown operator %lu", (unsigned long)operatorType];
}

Table& get_table(Group& group, RLMObjectSchema *objectSchema)
{
    return *ObjectStore::table_for_object_type(group, objectSchema.objectName.UTF8String);
}

// A reference to a column within a query. Can be resolved to a Columns<T> for use in query expressions.
class ColumnReference {
public:
    ColumnReference(Query& query, Group& group, RLMSchema *schema, RLMProperty* property, const std::vector<RLMProperty*>& links = {})
    : m_links(links), m_property(property), m_schema(schema), m_group(&group), m_query(&query), m_table(query.get_table().get())
    {
        auto& table = walk_link_chain([](Table&, size_t, RLMPropertyType) { });
        m_index = table.get_column_index(m_property.name.UTF8String);
    }

    template <typename T, typename... SubQuery>
    auto resolve(SubQuery&&... subquery) const
    {
        static_assert(sizeof...(SubQuery) < 2, "resolve() takes at most one subquery");
        set_link_chain_on_table();
        if (type() != RLMPropertyTypeLinkingObjects) {
            return m_table->template column<T>(index(), std::forward<SubQuery>(subquery)...);
        }
        else {
            return resolve_backlink<T>(std::forward<SubQuery>(subquery)...);
        }
    }

    RLMProperty *property() const { return m_property; }
    size_t index() const { return m_index; }
    RLMPropertyType type() const { return property().type; }
    Group& group() const { return *m_group; }

    RLMObjectSchema *link_target_object_schema() const
    {
        switch (type()) {
            case RLMPropertyTypeObject:
            case RLMPropertyTypeArray:
            case RLMPropertyTypeLinkingObjects:
                return m_schema[property().objectClassName];
            default:
                REALM_ASSERT(false);
        }
    }

    bool has_links() const { return m_links.size(); }

    bool has_any_to_many_links() const {
        return std::any_of(begin(m_links), end(m_links), [](RLMProperty *property) {
            return property.type == RLMPropertyTypeArray || property.type == RLMPropertyTypeLinkingObjects;
        });
    }

    ColumnReference last_link_column() const {
        REALM_ASSERT(!m_links.empty());
        return {*m_query, *m_group, m_schema, m_links.back(), {m_links.begin(), m_links.end() - 1}};
    }

    ColumnReference column_ignoring_links(Query& query) const {
        return {query, *m_group, m_schema, m_property};
    }

private:
    template <typename T, typename... SubQuery>
    auto resolve_backlink(SubQuery&&... subquery) const
    {
        // We actually just want `if constexpr (std::is_same<T, Link>::value) { ... }`,
        // so fake it by tag-dispatching on the conditional
        return do_resolve_backlink<T>(std::is_same<T, Link>(), std::forward<SubQuery>(subquery)...);
    }

    template <typename T, typename... SubQuery>
    auto do_resolve_backlink(std::true_type, SubQuery&&... subquery) const
    {
        return with_link_origin(m_property, [&](Table& table, size_t col) {
            return m_table->template column<T>(table, col, std::forward<SubQuery>(subquery)...);
        });
    }

    template <typename T, typename... SubQuery>
    Columns<T> do_resolve_backlink(std::false_type, SubQuery&&...) const
    {
        // This can't actually happen as we only call resolve_backlink() if
        // it's RLMPropertyTypeLinkingObjects
        __builtin_unreachable();
    }

    template<typename Func>
    Table& walk_link_chain(Func&& func) const
    {
        auto table = m_query->get_table().get();
        for (const auto& link : m_links) {
            if (link.type != RLMPropertyTypeLinkingObjects) {
                auto index = table->get_column_index(link.name.UTF8String);
                func(*table, index, link.type);
                table = table->get_link_target(index).get();
            }
            else {
                with_link_origin(link, [&](Table& link_origin_table, size_t link_origin_column) {
                    func(link_origin_table, link_origin_column, link.type);
                    table = &link_origin_table;
                });
            }
        }
        return *table;
    }

    template<typename Func>
    auto with_link_origin(RLMProperty *prop, Func&& func) const
    {
        RLMObjectSchema *link_origin_schema = m_schema[prop.objectClassName];
        Table& link_origin_table = get_table(*m_group, link_origin_schema);
        size_t link_origin_column = link_origin_table.get_column_index(prop.linkOriginPropertyName.UTF8String);
        return func(link_origin_table, link_origin_column);
    }

    void set_link_chain_on_table() const
    {
        walk_link_chain([&](Table& current_table, size_t column, RLMPropertyType type) {
            if (type == RLMPropertyTypeLinkingObjects) {
                m_table->backlink(current_table, column);
            }
            else {
                m_table->link(column);
            }
        });
    }

    std::vector<RLMProperty*> m_links;
    RLMProperty *m_property;
    RLMSchema *m_schema;
    Group *m_group;
    Query *m_query;
    Table *m_table;
    size_t m_index;
};

class CollectionOperation {
public:
    enum Type {
        Count,
        Minimum,
        Maximum,
        Sum,
        Average,
    };

    CollectionOperation(Type type, ColumnReference link_column, util::Optional<ColumnReference> column)
        : m_type(type)
        , m_link_column(std::move(link_column))
        , m_column(std::move(column))
    {
        RLMPrecondition(m_link_column.type() == RLMPropertyTypeArray || m_link_column.type() == RLMPropertyTypeLinkingObjects,
                        @"Invalid predicate", @"Collection operation can only be applied to a property of type RLMArray.");

        switch (m_type) {
            case Count:
                RLMPrecondition(!m_column, @"Invalid predicate", @"Result of @count does not have any properties.");
                break;
            case Minimum:
            case Maximum:
            case Sum:
            case Average:
                RLMPrecondition(m_column && RLMPropertyTypeIsNumeric(m_column->type()), @"Invalid predicate",
                                @"%@ can only be applied to a numeric property.", name_for_type(m_type));
                break;
        }
    }

    CollectionOperation(NSString *operationName, ColumnReference link_column, util::Optional<ColumnReference> column = util::none)
        : CollectionOperation(type_for_name(operationName), std::move(link_column), std::move(column))
    {
    }

    Type type() const { return m_type; }
    const ColumnReference& link_column() const { return m_link_column; }
    const ColumnReference& column() const { return *m_column; }

    void validate_comparison(id value) const {
        switch (m_type) {
            case Count:
            case Average:
                RLMPrecondition([value isKindOfClass:[NSNumber class]], @"Invalid operand",
                                @"%@ can only be compared with a numeric value.", name_for_type(m_type));
                break;
            case Minimum:
            case Maximum:
            case Sum:
                RLMPrecondition(RLMIsObjectValidForProperty(value, m_column->property()), @"Invalid operand",
                                @"%@ on a property of type %@ cannot be compared with '%@'",
                                name_for_type(m_type), RLMTypeToString(m_column->type()), value);
                break;
        }
    }

    void validate_comparison(const ColumnReference& column) const {
        switch (m_type) {
            case Count:
                RLMPrecondition(RLMPropertyTypeIsNumeric(column.type()), @"Invalid operand",
                                @"%@ can only be compared with a numeric value.", name_for_type(m_type));
                break;
            case Average:
            case Minimum:
            case Maximum:
            case Sum:
                RLMPrecondition(RLMPropertyTypeIsNumeric(column.type()), @"Invalid operand",
                                @"%@ on a property of type %@ cannot be compared with property of type '%@'",
                                name_for_type(m_type), RLMTypeToString(m_column->type()), RLMTypeToString(column.type()));
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
    ColumnReference m_link_column;
    util::Optional<ColumnReference> m_column;
};

class QueryBuilder {
public:
    QueryBuilder(Query& query, Group& group, RLMSchema *schema)
    : m_query(query), m_group(group), m_schema(schema) { }

    void apply_predicate(NSPredicate *predicate, RLMObjectSchema *objectSchema);


    void apply_collection_operator_expression(RLMObjectSchema *desc, NSString *keyPath, id value, NSComparisonPredicate *pred);
    void apply_value_expression(RLMObjectSchema *desc, NSString *keyPath, id value, NSComparisonPredicate *pred);
    void apply_column_expression(RLMObjectSchema *desc, NSString *leftKeyPath, NSString *rightKeyPath, NSComparisonPredicate *predicate);
    void apply_subquery_count_expression(RLMObjectSchema *objectSchema, NSExpression *subqueryExpression,
                                         NSPredicateOperatorType operatorType, NSExpression *right);
    void apply_function_subquery_expression(RLMObjectSchema *objectSchema, NSExpression *functionExpression,
                                            NSPredicateOperatorType operatorType, NSExpression *right);
    void apply_function_expression(RLMObjectSchema *objectSchema, NSExpression *functionExpression,
                                   NSPredicateOperatorType operatorType, NSExpression *right);


    template <typename A, typename B>
    void add_numeric_constraint(RLMPropertyType datatype,
                                NSPredicateOperatorType operatorType,
                                A&& lhs, B&& rhs);

    template <typename A, typename B>
    void add_bool_constraint(NSPredicateOperatorType operatorType, A lhs, B rhs);

    template <typename T>
    void add_string_constraint(NSPredicateOperatorType operatorType,
                               NSComparisonPredicateOptions predicateOptions,
                               Columns<String> &&column,
                               T value);

    void add_string_constraint(NSPredicateOperatorType operatorType,
                               NSComparisonPredicateOptions predicateOptions,
                               StringData value,
                               Columns<String>&& column);

    template <typename L, typename R>
    void add_constraint(RLMPropertyType type,
                        NSPredicateOperatorType operatorType,
                        NSComparisonPredicateOptions predicateOptions,
                        L lhs, R rhs);
    template <typename... T>
    void do_add_constraint(RLMPropertyType type, NSPredicateOperatorType operatorType,
                           NSComparisonPredicateOptions predicateOptions, T... values);
    void do_add_constraint(RLMPropertyType, NSPredicateOperatorType, NSComparisonPredicateOptions, id, realm::null);

    void add_between_constraint(const ColumnReference& column, id value);

    template<typename T>
    void add_binary_constraint(NSPredicateOperatorType operatorType, const ColumnReference& column, T value);
    void add_binary_constraint(NSPredicateOperatorType operatorType, const ColumnReference& column, id value);
    void add_binary_constraint(NSPredicateOperatorType operatorType, id value, const ColumnReference& column);
    void add_binary_constraint(NSPredicateOperatorType, const ColumnReference&, const ColumnReference&);

    void add_link_constraint(NSPredicateOperatorType operatorType, const ColumnReference& column, RLMObject *obj);
    void add_link_constraint(NSPredicateOperatorType operatorType, const ColumnReference& column, realm::null);
    template<typename T>
    void add_link_constraint(NSPredicateOperatorType operatorType, T obj, const ColumnReference& column);
    void add_link_constraint(NSPredicateOperatorType, const ColumnReference&, const ColumnReference&);

    template <CollectionOperation::Type Operation, typename... T>
    void add_collection_operation_constraint(RLMPropertyType propertyType, NSPredicateOperatorType operatorType, T... values);
    template <typename... T>
    void add_collection_operation_constraint(NSPredicateOperatorType operatorType,
                                             CollectionOperation collectionOperation, T... values);


    CollectionOperation collection_operation_from_key_path(RLMObjectSchema *desc, NSString *keyPath);
    ColumnReference column_reference_from_key_path(RLMObjectSchema *objectSchema, NSString *keyPath, bool isAggregate);

private:
    Query& m_query;
    Group& m_group;
    RLMSchema *m_schema;
};

// add a clause for numeric constraints based on operator type
template <typename A, typename B>
void QueryBuilder::add_numeric_constraint(RLMPropertyType datatype,
                                          NSPredicateOperatorType operatorType,
                                          A&& lhs, B&& rhs)
{
    switch (operatorType) {
        case NSLessThanPredicateOperatorType:
            m_query.and_query(lhs < rhs);
            break;
        case NSLessThanOrEqualToPredicateOperatorType:
            m_query.and_query(lhs <= rhs);
            break;
        case NSGreaterThanPredicateOperatorType:
            m_query.and_query(lhs > rhs);
            break;
        case NSGreaterThanOrEqualToPredicateOperatorType:
            m_query.and_query(lhs >= rhs);
            break;
        case NSEqualToPredicateOperatorType:
            m_query.and_query(lhs == rhs);
            break;
        case NSNotEqualToPredicateOperatorType:
            m_query.and_query(lhs != rhs);
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                         @"Operator '%@' not supported for type %@", operatorName(operatorType), RLMTypeToString(datatype));
    }
}

template <typename A, typename B>
void QueryBuilder::add_bool_constraint(NSPredicateOperatorType operatorType, A lhs, B rhs) {
    switch (operatorType) {
        case NSEqualToPredicateOperatorType:
            m_query.and_query(lhs == rhs);
            break;
        case NSNotEqualToPredicateOperatorType:
            m_query.and_query(lhs != rhs);
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                         @"Operator '%@' not supported for bool type", operatorName(operatorType));
    }
}

template <typename T>
void QueryBuilder::add_string_constraint(NSPredicateOperatorType operatorType,
                                         NSComparisonPredicateOptions predicateOptions,
                                         Columns<String> &&column,
                                         T value) {
    bool caseSensitive = !(predicateOptions & NSCaseInsensitivePredicateOption);
    bool diacriticSensitive = !(predicateOptions & NSDiacriticInsensitivePredicateOption);

    if (diacriticSensitive) {
        switch (operatorType) {
            case NSBeginsWithPredicateOperatorType:
                m_query.and_query(column.begins_with(value, caseSensitive));
                break;
            case NSEndsWithPredicateOperatorType:
                m_query.and_query(column.ends_with(value, caseSensitive));
                break;
            case NSContainsPredicateOperatorType:
                m_query.and_query(column.contains(value, caseSensitive));
                break;
            case NSEqualToPredicateOperatorType:
                m_query.and_query(column.equal(value, caseSensitive));
                break;
            case NSNotEqualToPredicateOperatorType:
                m_query.and_query(column.not_equal(value, caseSensitive));
                break;
            case NSLikePredicateOperatorType:
                m_query.and_query(column.like(value, caseSensitive));
                break;
            default:
                @throw RLMPredicateException(@"Invalid operator type",
                                             @"Operator '%@' not supported for string type", operatorName(operatorType));
        }
        return;
    }

    auto as_subexpr = overload([](StringData value) { return make_subexpr<ConstantStringValue>(value); },
                               [](const Columns<String>& c) { return c.clone(); });
    auto left = as_subexpr(column);
    auto right = as_subexpr(value);

    auto add_constraint = [&](auto comparator) mutable {
        using Comparator = decltype(comparator);
        using CompareCS = Compare<typename Comparator::CaseSensitive, StringData>;
        using CompareCI = Compare<typename Comparator::CaseInsensitive, StringData>;

        if (caseSensitive) {
            m_query.and_query(make_expression<CompareCS>(std::move(left), std::move(right)));
        }
        else {
            m_query.and_query(make_expression<CompareCI>(std::move(left), std::move(right)));
        }
    };

    switch (operatorType) {
        case NSBeginsWithPredicateOperatorType:
            add_constraint(ContainsSubstring<kCFCompareDiacriticInsensitive | kCFCompareAnchored>{});
            break;
        case NSEndsWithPredicateOperatorType:
            add_constraint(ContainsSubstring<kCFCompareDiacriticInsensitive | kCFCompareAnchored | kCFCompareBackwards>{});
            break;
        case NSContainsPredicateOperatorType:
            add_constraint(ContainsSubstring<kCFCompareDiacriticInsensitive>{});
            break;
        case NSNotEqualToPredicateOperatorType:
            m_query.Not();
            REALM_FALLTHROUGH;
        case NSEqualToPredicateOperatorType:
            add_constraint(Equal<kCFCompareDiacriticInsensitive>{});
            break;
        case NSLikePredicateOperatorType:
            @throw RLMPredicateException(@"Invalid operator type",
                                         @"Operator 'LIKE' not supported with diacritic-insensitive modifier.");
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                         @"Operator '%@' not supported for string type", operatorName(operatorType));
    }
}

void QueryBuilder::add_string_constraint(NSPredicateOperatorType operatorType,
                                         NSComparisonPredicateOptions predicateOptions,
                                         StringData value,
                                         Columns<String>&& column) {
    switch (operatorType) {
        case NSEqualToPredicateOperatorType:
        case NSNotEqualToPredicateOperatorType:
            add_string_constraint(operatorType, predicateOptions, std::move(column), value);
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

void QueryBuilder::add_between_constraint(const ColumnReference& column, id value) {
    if (column.has_any_to_many_links()) {
        auto link_column = column.last_link_column();
        Query subquery = get_table(m_group, link_column.link_target_object_schema()).where();
        QueryBuilder(subquery, m_group, m_schema).add_between_constraint(column.column_ignoring_links(subquery), value);

        m_query.and_query(link_column.resolve<Link>(std::move(subquery)).count() > 0);
        return;
    }

    id from, to;
    validate_and_extract_between_range(value, column.property(), &from, &to);

    RLMPropertyType type = column.type();

    m_query.group();
    add_constraint(type, NSGreaterThanOrEqualToPredicateOperatorType, 0, column, from);
    add_constraint(type, NSLessThanOrEqualToPredicateOperatorType, 0, column, to);
    m_query.end_group();
}

template<typename T>
void QueryBuilder::add_binary_constraint(NSPredicateOperatorType operatorType,
                                         const ColumnReference& column,
                                         T value) {
    RLMPrecondition(!column.has_links(), @"Unsupported operator", @"NSData properties cannot be queried over an object link.");

    size_t index = column.index();
    switch (operatorType) {
        case NSBeginsWithPredicateOperatorType:
            m_query.begins_with(index, value);
            break;
        case NSEndsWithPredicateOperatorType:
            m_query.ends_with(index, value);
            break;
        case NSContainsPredicateOperatorType:
            m_query.contains(index, value);
            break;
        case NSEqualToPredicateOperatorType:
            m_query.equal(index, value);
            break;
        case NSNotEqualToPredicateOperatorType:
            m_query.not_equal(index, value);
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                         @"Operator '%@' not supported for binary type", operatorName(operatorType));
    }
}

void QueryBuilder::add_binary_constraint(NSPredicateOperatorType operatorType, const ColumnReference& column, id value) {
    add_binary_constraint(operatorType, column, RLMBinaryDataForNSData(value));
}

void QueryBuilder::add_binary_constraint(NSPredicateOperatorType operatorType, id value, const ColumnReference& column) {
    switch (operatorType) {
        case NSEqualToPredicateOperatorType:
        case NSNotEqualToPredicateOperatorType:
            add_binary_constraint(operatorType, column, value);
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                         @"Operator '%@' is not supported for binary type with key path on right side of operator",
                                         operatorName(operatorType));
    }
}

void QueryBuilder::add_binary_constraint(NSPredicateOperatorType, const ColumnReference&, const ColumnReference&) {
    @throw RLMPredicateException(@"Invalid predicate", @"Comparisons between two NSData properties are not supported");
}

void QueryBuilder::add_link_constraint(NSPredicateOperatorType operatorType,
                                       const ColumnReference& column, RLMObject *obj) {
    RLMPrecondition(operatorType == NSEqualToPredicateOperatorType || operatorType == NSNotEqualToPredicateOperatorType,
                    @"Invalid operator type", @"Only 'Equal' and 'Not Equal' operators supported for object comparison");

    if (operatorType == NSEqualToPredicateOperatorType) {
        m_query.and_query(column.resolve<Link>() == obj->_row);
    }
    else {
        m_query.and_query(column.resolve<Link>() != obj->_row);
    }
}

void QueryBuilder::add_link_constraint(NSPredicateOperatorType operatorType,
                                       const ColumnReference& column,
                                       realm::null) {
    RLMPrecondition(operatorType == NSEqualToPredicateOperatorType || operatorType == NSNotEqualToPredicateOperatorType,
                    @"Invalid operator type", @"Only 'Equal' and 'Not Equal' operators supported for object comparison");

    if (operatorType == NSEqualToPredicateOperatorType) {
        m_query.and_query(column.resolve<Link>() == null());
    }
    else {
        m_query.and_query(column.resolve<Link>() != null());
    }
}

template<typename T>
void QueryBuilder::add_link_constraint(NSPredicateOperatorType operatorType, T obj, const ColumnReference& column) {
    // Link constraints only support the equal-to and not-equal-to operators. The order of operands
    // is not important for those comparisons so we can delegate to the other implementation.
    add_link_constraint(operatorType, column, obj);
}

void QueryBuilder::add_link_constraint(NSPredicateOperatorType, const ColumnReference&, const ColumnReference&) {
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
        query.and_query(std::unique_ptr<Expression>(new FalseExpression));
    }

    query.end_group();
}

template <typename RequestedType>
RequestedType convert(id value);

template <>
Timestamp convert<Timestamp>(id value) {
    return RLMTimestampForNSDate(value);
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

template <typename>
realm::null value_of_type(realm::null) {
    return realm::null();
}

template <typename RequestedType>
auto value_of_type(id value) {
    return ::convert<RequestedType>(value);
}

template <typename RequestedType>
auto value_of_type(const ColumnReference& column) {
    return column.resolve<RequestedType>();
}


template <typename... T>
void QueryBuilder::do_add_constraint(RLMPropertyType type, NSPredicateOperatorType operatorType,
                                     NSComparisonPredicateOptions predicateOptions, T... values)
{
    static_assert(sizeof...(T) == 2, "do_add_constraint accepts only two values as arguments");

    switch (type) {
        case RLMPropertyTypeBool:
            add_bool_constraint(operatorType, value_of_type<bool>(values)...);
            break;
        case RLMPropertyTypeDate:
            add_numeric_constraint(type, operatorType, value_of_type<realm::Timestamp>(values)...);
            break;
        case RLMPropertyTypeDouble:
            add_numeric_constraint(type, operatorType, value_of_type<Double>(values)...);
            break;
        case RLMPropertyTypeFloat:
            add_numeric_constraint(type, operatorType, value_of_type<Float>(values)...);
            break;
        case RLMPropertyTypeInt:
            add_numeric_constraint(type, operatorType, value_of_type<Int>(values)...);
            break;
        case RLMPropertyTypeString:
            add_string_constraint(operatorType, predicateOptions, value_of_type<String>(values)...);
            break;
        case RLMPropertyTypeData:
            add_binary_constraint(operatorType, values...);
            break;
        case RLMPropertyTypeObject:
        case RLMPropertyTypeArray:
        case RLMPropertyTypeLinkingObjects:
            add_link_constraint(operatorType, values...);
            break;
        default:
            @throw RLMPredicateException(@"Unsupported predicate value type",
                                         @"Object type %@ not supported", RLMTypeToString(type));
    }
}

void QueryBuilder::do_add_constraint(RLMPropertyType, NSPredicateOperatorType, NSComparisonPredicateOptions, id, realm::null)
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
void QueryBuilder::add_constraint(RLMPropertyType type, NSPredicateOperatorType operatorType,
                                  NSComparisonPredicateOptions predicateOptions, L lhs, R rhs)
{
    // The expression operators are only overloaded for realm::null on the rhs
    RLMPrecondition(!is_nsnull(lhs), @"Unsupported operator",
                    @"Nil is only supported on the right side of operators");

    if (is_nsnull(rhs)) {
        do_add_constraint(type, operatorType, predicateOptions, lhs, realm::null());
    }
    else {
        do_add_constraint(type, operatorType, predicateOptions, lhs, rhs);
    }
}

struct KeyPath {
    std::vector<RLMProperty *> links;
    RLMProperty *property;
    bool containsToManyRelationship;
};

KeyPath key_path_from_string(RLMSchema *schema, RLMObjectSchema *objectSchema, NSString *keyPath)
{
    RLMProperty *property;
    std::vector<RLMProperty *> links;

    bool keyPathContainsToManyRelationship = false;

    NSUInteger start = 0, length = keyPath.length, end = NSNotFound;
    do {
        end = [keyPath rangeOfString:@"." options:0 range:{start, length - start}].location;
        NSString *propertyName = [keyPath substringWithRange:{start, end == NSNotFound ? length - start : end - start}];
        property = objectSchema[propertyName];
        RLMPrecondition(property, @"Invalid property name",
                        @"Property '%@' not found in object of type '%@'", propertyName, objectSchema.className);

        if (property.type == RLMPropertyTypeArray || property.type == RLMPropertyTypeLinkingObjects)
            keyPathContainsToManyRelationship = true;

        if (end != NSNotFound) {
            RLMPrecondition(property.type == RLMPropertyTypeObject || property.type == RLMPropertyTypeArray || property.type == RLMPropertyTypeLinkingObjects,
                            @"Invalid value", @"Property '%@' is not a link in object of type '%@'", propertyName, objectSchema.className);

            links.push_back(property);
            REALM_ASSERT(property.objectClassName);
            objectSchema = schema[property.objectClassName];
        }

        start = end + 1;
    } while (end != NSNotFound);

    return {std::move(links), property, keyPathContainsToManyRelationship};
}

ColumnReference QueryBuilder::column_reference_from_key_path(RLMObjectSchema *objectSchema, NSString *keyPathString, bool isAggregate)
{
    auto keyPath = key_path_from_string(m_schema, objectSchema, keyPathString);

    if (isAggregate && !keyPath.containsToManyRelationship) {
        @throw RLMPredicateException(@"Invalid predicate",
                                     @"Aggregate operations can only be used on key paths that include an array property");
    } else if (!isAggregate && keyPath.containsToManyRelationship) {
        @throw RLMPredicateException(@"Invalid predicate",
                                     @"Key paths that include an array property must use aggregate operations");
    }

    return ColumnReference(m_query, m_group, m_schema, keyPath.property, std::move(keyPath.links));
}

void validate_property_value(const ColumnReference& column,
                             __unsafe_unretained id const value,
                             __unsafe_unretained NSString *const err,
                             __unsafe_unretained RLMObjectSchema *const objectSchema,
                             __unsafe_unretained NSString *const keyPath) {
    RLMProperty *prop = column.property();
    if (prop.type == RLMPropertyTypeArray || prop.type == RLMPropertyTypeLinkingObjects) {
        RLMPrecondition([RLMObjectBaseObjectSchema(RLMDynamicCast<RLMObjectBase>(value)).className isEqualToString:prop.objectClassName],
                        @"Invalid value", err, prop.objectClassName, keyPath, objectSchema.className, value);
    }
    else {
        RLMPrecondition(RLMIsObjectValidForProperty(value, prop),
                        @"Invalid value", err, RLMTypeToString(prop.type), keyPath, objectSchema.className, value);
    }
    if (RLMObjectBase *obj = RLMDynamicCast<RLMObjectBase>(value)) {
        RLMPrecondition(!obj->_row.is_attached() || &column.group() == &obj->_realm.group,
                        @"Invalid value origin", @"Object must be from the Realm being queried");
    }
}

template <typename RequestedType, CollectionOperation::Type OperationType>
struct ValueOfTypeWithCollectionOperationHelper;

template <>
struct ValueOfTypeWithCollectionOperationHelper<Int, CollectionOperation::Count> {
    static auto convert(const CollectionOperation& operation)
    {
        assert(operation.type() == CollectionOperation::Count);
        return operation.link_column().resolve<Link>().count();
    }
};

#define VALUE_OF_TYPE_WITH_COLLECTION_OPERATOR_HELPER(OperationType, function) \
template <typename T> \
struct ValueOfTypeWithCollectionOperationHelper<T, OperationType> { \
    static auto convert(const CollectionOperation& operation) \
    { \
        REALM_ASSERT(operation.type() == OperationType); \
        auto targetColumn = operation.link_column().resolve<Link>().template column<T>(operation.column().index()); \
        return targetColumn.function(); \
    } \
} \

VALUE_OF_TYPE_WITH_COLLECTION_OPERATOR_HELPER(CollectionOperation::Minimum, min);
VALUE_OF_TYPE_WITH_COLLECTION_OPERATOR_HELPER(CollectionOperation::Maximum, max);
VALUE_OF_TYPE_WITH_COLLECTION_OPERATOR_HELPER(CollectionOperation::Sum, sum);
VALUE_OF_TYPE_WITH_COLLECTION_OPERATOR_HELPER(CollectionOperation::Average, average);
#undef VALUE_OF_TYPE_WITH_COLLECTION_OPERATOR_HELPER

template <typename Requested, CollectionOperation::Type OperationType, typename T>
auto value_of_type_with_collection_operation(T&& value) {
    return value_of_type<Requested>(std::forward<T>(value));
}

template <typename Requested, CollectionOperation::Type OperationType>
auto value_of_type_with_collection_operation(CollectionOperation operation) {
    using helper = ValueOfTypeWithCollectionOperationHelper<Requested, OperationType>;
    return helper::convert(operation);
}

template <CollectionOperation::Type Operation, typename... T>
void QueryBuilder::add_collection_operation_constraint(RLMPropertyType propertyType, NSPredicateOperatorType operatorType, T... values)
{
    switch (propertyType) {
        case RLMPropertyTypeInt:
            add_numeric_constraint(propertyType, operatorType, value_of_type_with_collection_operation<Int, Operation>(values)...);
            break;
        case RLMPropertyTypeFloat:
            add_numeric_constraint(propertyType, operatorType, value_of_type_with_collection_operation<Float, Operation>(values)...);
            break;
        case RLMPropertyTypeDouble:
            add_numeric_constraint(propertyType, operatorType, value_of_type_with_collection_operation<Double, Operation>(values)...);
            break;
        default:
            REALM_ASSERT(false && "Only numeric property types should hit this path.");
    }
}

template <typename... T>
void QueryBuilder::add_collection_operation_constraint(NSPredicateOperatorType operatorType,
                                                  CollectionOperation collectionOperation, T... values)
{
    static_assert(sizeof...(T) == 2, "add_collection_operation_constraint accepts only two values as arguments");

    switch (collectionOperation.type()) {
        case CollectionOperation::Count:
            add_numeric_constraint(RLMPropertyTypeInt, operatorType,
                                   value_of_type_with_collection_operation<Int, CollectionOperation::Count>(values)...);
            break;
        case CollectionOperation::Minimum:
            add_collection_operation_constraint<CollectionOperation::Minimum>(collectionOperation.column().type(), operatorType, values...);
            break;
        case CollectionOperation::Maximum:
            add_collection_operation_constraint<CollectionOperation::Maximum>(collectionOperation.column().type(), operatorType, values...);
            break;
        case CollectionOperation::Sum:
            add_collection_operation_constraint<CollectionOperation::Sum>(collectionOperation.column().type(), operatorType, values...);
            break;
        case CollectionOperation::Average:
            add_collection_operation_constraint<CollectionOperation::Average>(collectionOperation.column().type(), operatorType, values...);
            break;
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

    if (at.location == 0 || [keyPath characterAtIndex:at.location - 1] != '.') {
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

CollectionOperation QueryBuilder::collection_operation_from_key_path(RLMObjectSchema *desc, NSString *keyPath) {
    NSString *leadingKeyPath;
    NSString *trailingKey;
    NSString *collectionOperationName = get_collection_operation_name_from_key_path(keyPath, &leadingKeyPath, &trailingKey);

    ColumnReference linkColumn = column_reference_from_key_path(desc, leadingKeyPath, true);
    util::Optional<ColumnReference> column;
    if (trailingKey) {
        RLMPrecondition([trailingKey rangeOfString:@"."].location == NSNotFound, @"Invalid key path",
                        @"Right side of collection operator may only have a single level key");
        NSString *fullKeyPath = [leadingKeyPath stringByAppendingFormat:@".%@", trailingKey];
        column = column_reference_from_key_path(desc, fullKeyPath, true);
    }

    return {collectionOperationName, std::move(linkColumn), std::move(column)};
}

void QueryBuilder::apply_collection_operator_expression(RLMObjectSchema *desc,
                                                        NSString *keyPath, id value,
                                                        NSComparisonPredicate *pred) {
    CollectionOperation operation = collection_operation_from_key_path(desc, keyPath);
    operation.validate_comparison(value);

    if (pred.leftExpression.expressionType == NSKeyPathExpressionType) {
        add_collection_operation_constraint(pred.predicateOperatorType, operation, operation, value);
    } else {
        add_collection_operation_constraint(pred.predicateOperatorType, operation, value, operation);
    }
}

void QueryBuilder::apply_value_expression(RLMObjectSchema *desc,
                                          NSString *keyPath, id value,
                                          NSComparisonPredicate *pred)
{
    if (key_path_contains_collection_operator(keyPath)) {
        apply_collection_operator_expression(desc, keyPath, value, pred);
        return;
    }

    bool isAny = pred.comparisonPredicateModifier == NSAnyPredicateModifier;
    ColumnReference column = column_reference_from_key_path(desc, keyPath, isAny);

    // check to see if this is a between query
    if (pred.predicateOperatorType == NSBetweenPredicateOperatorType) {
        add_between_constraint(std::move(column), value);
        return;
    }

    // turn "key.path IN collection" into ored together ==. "collection IN key.path" is handled elsewhere.
    if (pred.predicateOperatorType == NSInPredicateOperatorType) {
        process_or_group(m_query, value, [&](id item) {
            id normalized = value_from_constant_expression_or_value(item);
            validate_property_value(column, normalized,
                                    @"Expected object of type %@ in IN clause for property '%@' on object of type '%@', but received: %@", desc, keyPath);
            add_constraint(column.type(), NSEqualToPredicateOperatorType, pred.options, column, normalized);
        });
        return;
    }

    validate_property_value(column, value, @"Expected object of type %@ for property '%@' on object of type '%@', but received: %@", desc, keyPath);
    if (pred.leftExpression.expressionType == NSKeyPathExpressionType) {
        add_constraint(column.type(), pred.predicateOperatorType, pred.options, std::move(column), value);
    } else {
        add_constraint(column.type(), pred.predicateOperatorType, pred.options, value, std::move(column));
    }
}

void QueryBuilder::apply_column_expression(RLMObjectSchema *desc,
                                           NSString *leftKeyPath, NSString *rightKeyPath,
                                           NSComparisonPredicate *predicate)
{
    bool left_key_path_contains_collection_operator = key_path_contains_collection_operator(leftKeyPath);
    bool right_key_path_contains_collection_operator = key_path_contains_collection_operator(rightKeyPath);
    if (left_key_path_contains_collection_operator && right_key_path_contains_collection_operator) {
        @throw RLMPredicateException(@"Unsupported predicate", @"Key paths including aggregate operations cannot be compared with other aggregate operations.");
    }

    if (left_key_path_contains_collection_operator) {
        CollectionOperation left = collection_operation_from_key_path(desc, leftKeyPath);
        ColumnReference right = column_reference_from_key_path(desc, rightKeyPath, false);
        left.validate_comparison(right);
        add_collection_operation_constraint(predicate.predicateOperatorType, left, left, std::move(right));
        return;
    }
    if (right_key_path_contains_collection_operator) {
        ColumnReference left = column_reference_from_key_path(desc, leftKeyPath, false);
        CollectionOperation right = collection_operation_from_key_path(desc, rightKeyPath);
        right.validate_comparison(left);
        add_collection_operation_constraint(predicate.predicateOperatorType, right, std::move(left), right);
        return;
    }

    bool isAny = false;
    ColumnReference left = column_reference_from_key_path(desc, leftKeyPath, isAny);
    ColumnReference right = column_reference_from_key_path(desc, rightKeyPath, isAny);

    // NOTE: It's assumed that column type must match and no automatic type conversion is supported.
    RLMPrecondition(left.type() == right.type(),
                    RLMPropertiesComparisonTypeMismatchException,
                    RLMPropertiesComparisonTypeMismatchReason,
                    RLMTypeToString(left.type()),
                    RLMTypeToString(right.type()));

    // TODO: Should we handle special case where left row is the same as right row (tautology)
    add_constraint(left.type(), predicate.predicateOperatorType, predicate.options,
                   std::move(left), std::move(right));
}

// Identify expressions of the form [SELF valueForKeyPath:]
bool is_self_value_for_key_path_function_expression(NSExpression *expression)
{
    if (expression.expressionType != NSFunctionExpressionType)
        return false;

    if (expression.operand.expressionType != NSEvaluatedObjectExpressionType)
        return false;

    return [expression.function isEqualToString:@"valueForKeyPath:"];
}

// -[NSPredicate predicateWithSubtitutionVariables:] results in function expressions of the form [SELF valueForKeyPath:]
// that apply_predicate cannot handle. Replace such expressions with equivalent NSKeyPathExpressionType expressions.
NSExpression *simplify_self_value_for_key_path_function_expression(NSExpression *expression) {
    if (is_self_value_for_key_path_function_expression(expression)) {
        if (NSString *keyPath = [expression.arguments.firstObject keyPath]) {
            return [NSExpression expressionForKeyPath:keyPath];
        }
    }
    return expression;
}

void QueryBuilder::apply_subquery_count_expression(RLMObjectSchema *objectSchema,
                                                   NSExpression *subqueryExpression, NSPredicateOperatorType operatorType, NSExpression *right) {
    if (right.expressionType != NSConstantValueExpressionType || ![right.constantValue isKindOfClass:[NSNumber class]]) {
        @throw RLMPredicateException(@"Invalid predicate expression", @"SUBQUERY(…).@count is only supported when compared with a constant number.");
    }
    int64_t value = [right.constantValue integerValue];

    ColumnReference collectionColumn = column_reference_from_key_path(objectSchema, [subqueryExpression.collection keyPath], true);
    RLMObjectSchema *collectionMemberObjectSchema = m_schema[collectionColumn.property().objectClassName];

    // Eliminate references to the iteration variable in the subquery.
    NSPredicate *subqueryPredicate = [subqueryExpression.predicate predicateWithSubstitutionVariables:@{ subqueryExpression.variable : [NSExpression expressionForEvaluatedObject] }];
    subqueryPredicate = transformPredicate(subqueryPredicate, simplify_self_value_for_key_path_function_expression);

    Query subquery = RLMPredicateToQuery(subqueryPredicate, collectionMemberObjectSchema, m_schema, m_group);
    add_numeric_constraint(RLMPropertyTypeInt, operatorType,
                           collectionColumn.resolve<LinkList>(std::move(subquery)).count(), value);
}

void QueryBuilder::apply_function_subquery_expression(RLMObjectSchema *objectSchema, NSExpression *functionExpression,
                                                      NSPredicateOperatorType operatorType, NSExpression *right) {
    if (![functionExpression.function isEqualToString:@"valueForKeyPath:"] || functionExpression.arguments.count != 1) {
        @throw RLMPredicateException(@"Invalid predicate", @"The '%@' function is not supported on the result of a SUBQUERY.", functionExpression.function);
    }

    NSExpression *keyPathExpression = functionExpression.arguments.firstObject;
    if ([keyPathExpression.keyPath isEqualToString:@"@count"]) {
        apply_subquery_count_expression(objectSchema, functionExpression.operand,  operatorType, right);
    } else {
        @throw RLMPredicateException(@"Invalid predicate", @"SUBQUERY is only supported when immediately followed by .@count that is compared with a constant number.");
    }
}

void QueryBuilder::apply_function_expression(RLMObjectSchema *objectSchema, NSExpression *functionExpression,
                                             NSPredicateOperatorType operatorType, NSExpression *right) {
    if (functionExpression.operand.expressionType == NSSubqueryExpressionType) {
        apply_function_subquery_expression(objectSchema, functionExpression, operatorType, right);
    } else {
        @throw RLMPredicateException(@"Invalid predicate", @"The '%@' function is not supported.", functionExpression.function);
    }
}


void QueryBuilder::apply_predicate(NSPredicate *predicate, RLMObjectSchema *objectSchema)
{
    // Compound predicates.
    if ([predicate isMemberOfClass:[NSCompoundPredicate class]]) {
        NSCompoundPredicate *comp = (NSCompoundPredicate *)predicate;

        switch ([comp compoundPredicateType]) {
            case NSAndPredicateType:
                if (comp.subpredicates.count) {
                    // Add all of the subpredicates.
                    m_query.group();
                    for (NSPredicate *subp in comp.subpredicates) {
                        apply_predicate(subp, objectSchema);
                    }
                    m_query.end_group();
                } else {
                    // NSCompoundPredicate's documentation states that an AND predicate with no subpredicates evaluates to TRUE.
                    m_query.and_query(std::unique_ptr<Expression>(new TrueExpression));
                }
                break;

            case NSOrPredicateType: {
                // Add all of the subpredicates with ors inbetween.
                process_or_group(m_query, comp.subpredicates, [&](__unsafe_unretained NSPredicate *const subp) {
                    apply_predicate(subp, objectSchema);
                });
                break;
            }

            case NSNotPredicateType:
                // Add the negated subpredicate
                m_query.Not();
                apply_predicate(comp.subpredicates.firstObject, objectSchema);
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
            // Inserting an array via %@ gives NSConstantValueExpressionType, but including it directly gives NSAggregateExpressionType
            if (exp1Type == NSKeyPathExpressionType && (exp2Type == NSAggregateExpressionType || exp2Type == NSConstantValueExpressionType)) {
                // "key.path IN %@", "key.path IN {…}", "key.path BETWEEN %@", or "key.path BETWEEN {…}".
                exp2Type = NSConstantValueExpressionType;
            }
            else if (compp.predicateOperatorType == NSInPredicateOperatorType && exp1Type == NSConstantValueExpressionType && exp2Type == NSKeyPathExpressionType) {
                // "%@ IN key.path" is equivalent to "ANY key.path IN %@". Rewrite the former into the latter.
                compp = [NSComparisonPredicate predicateWithLeftExpression:compp.rightExpression rightExpression:compp.leftExpression
                                                                  modifier:NSAnyPredicateModifier type:NSEqualToPredicateOperatorType options:0];
                exp1Type = NSKeyPathExpressionType;
                exp2Type = NSConstantValueExpressionType;
            }
            else {
                if (compp.predicateOperatorType == NSBetweenPredicateOperatorType) {
                    @throw RLMPredicateException(@"Invalid predicate",
                                                 @"Predicate with BETWEEN operator must compare a KeyPath with an aggregate with two values");
                }
                else if (compp.predicateOperatorType == NSInPredicateOperatorType) {
                    @throw RLMPredicateException(@"Invalid predicate",
                                                 @"Predicate with IN operator must compare a KeyPath with an aggregate");
                }
            }
        }

        if (exp1Type == NSKeyPathExpressionType && exp2Type == NSKeyPathExpressionType) {
            // both expression are KeyPaths
            apply_column_expression(objectSchema, compp.leftExpression.keyPath, compp.rightExpression.keyPath, compp);
        }
        else if (exp1Type == NSKeyPathExpressionType && exp2Type == NSConstantValueExpressionType) {
            // comparing keypath to value
            apply_value_expression(objectSchema, compp.leftExpression.keyPath, compp.rightExpression.constantValue, compp);
        }
        else if (exp1Type == NSConstantValueExpressionType && exp2Type == NSKeyPathExpressionType) {
            // comparing value to keypath
            apply_value_expression(objectSchema, compp.rightExpression.keyPath, compp.leftExpression.constantValue, compp);
        }
        else if (exp1Type == NSFunctionExpressionType) {
            apply_function_expression(objectSchema, compp.leftExpression, compp.predicateOperatorType, compp.rightExpression);
        }
        else if (exp1Type == NSSubqueryExpressionType) {
            // The subquery expressions that we support are handled by the NSFunctionExpressionType case above.
            @throw RLMPredicateException(@"Invalid predicate expression", @"SUBQUERY is only supported when immediately followed by .@count.");
        }
        else {
            @throw RLMPredicateException(@"Invalid predicate expressions",
                                         @"Predicate expressions must compare a keypath and another keypath or a constant value");
        }
    }
    else if ([predicate isEqual:[NSPredicate predicateWithValue:YES]]) {
        m_query.and_query(std::unique_ptr<Expression>(new TrueExpression));
    } else if ([predicate isEqual:[NSPredicate predicateWithValue:NO]]) {
        m_query.and_query(std::unique_ptr<Expression>(new FalseExpression));
    }
    else {
        // invalid predicate type
        @throw RLMPredicateException(@"Invalid predicate",
                                     @"Only support compound, comparison, and constant predicates");
    }
}

std::vector<size_t> RLMValidatedColumnIndicesForSort(RLMClassInfo& classInfo, NSString *keyPathString)
{
    RLMPrecondition([keyPathString rangeOfString:@"@"].location == NSNotFound, @"Invalid key path for sort",
                    @"Cannot sort on '%@': sorting on key paths that include collection operators is not supported.",
                    keyPathString);
    auto keyPath = key_path_from_string(classInfo.realm.schema, classInfo.rlmObjectSchema, keyPathString);

    RLMPrecondition(!keyPath.containsToManyRelationship, @"Invalid key path for sort",
                    @"Cannot sort on '%@': sorting on key paths that include a to-many relationship is not supported.",
                    keyPathString);

    switch (keyPath.property.type) {
        case RLMPropertyTypeBool:
        case RLMPropertyTypeDate:
        case RLMPropertyTypeDouble:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeInt:
        case RLMPropertyTypeString:
            break;

        default:
            @throw RLMPredicateException(@"Invalid sort property type",
                                         @"Cannot sort on key path '%@' on object of type '%s': sorting is only supported on bool, date, double, float, integer, and string properties, but property is of type %@.",
                                         keyPathString, classInfo.rlmObjectSchema.className, RLMTypeToString(keyPath.property.type));
    }

    std::vector<size_t> columnIndices;
    columnIndices.reserve(keyPath.links.size() + 1);

    auto currentClassInfo = &classInfo;
    for (RLMProperty *link : keyPath.links) {
        auto tableColumn = currentClassInfo->tableColumn(link);
        currentClassInfo = &currentClassInfo->linkTargetType(link.index);
        columnIndices.push_back(tableColumn);
    }
    columnIndices.push_back(currentClassInfo->tableColumn(keyPath.property));

    return columnIndices;
}

} // namespace

realm::Query RLMPredicateToQuery(NSPredicate *predicate, RLMObjectSchema *objectSchema,
                                 RLMSchema *schema, Group &group)
{
    auto query = get_table(group, objectSchema).where();

    // passing a nil predicate is a no-op
    if (!predicate) {
        return query;
    }

    @autoreleasepool {
        QueryBuilder(query, group, schema).apply_predicate(predicate, objectSchema);
    }

    // Test the constructed query in core
    std::string validateMessage = query.validate();
    RLMPrecondition(validateMessage.empty(), @"Invalid query", @"%.*s",
                    (int)validateMessage.size(), validateMessage.c_str());
    return query;
}

realm::SortDescriptor RLMSortDescriptorFromDescriptors(RLMClassInfo& classInfo, NSArray<RLMSortDescriptor *> *descriptors) {
    std::vector<std::vector<size_t>> columnIndices;
    std::vector<bool> ascending;
    columnIndices.reserve(descriptors.count);
    ascending.reserve(descriptors.count);

    for (RLMSortDescriptor *descriptor in descriptors) {
        columnIndices.push_back(RLMValidatedColumnIndicesForSort(classInfo, descriptor.keyPath));
        ascending.push_back(descriptor.ascending);
    }

    return {*classInfo.table(), std::move(columnIndices), std::move(ascending)};
}
