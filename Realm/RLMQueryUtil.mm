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

#import "RLMAccessor.hpp"
#import "RLMGeospatial_Private.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObject_Private.hpp"
#import "RLMPredicateUtil.hpp"
#import "RLMProperty_Private.h"
#import "RLMSchema.h"
#import "RLMUtil.hpp"

#import <realm/geospatial.hpp>
#import <realm/object-store/object_store.hpp>
#import <realm/object-store/results.hpp>
#import <realm/path.hpp>
#import <realm/query_engine.hpp>
#import <realm/query_expression.hpp>
#import <realm/util/cf_ptr.hpp>
#import <realm/util/overload.hpp>

using namespace realm;

namespace {
NSString * const RLMPropertiesComparisonTypeMismatchException = @"RLMPropertiesComparisonTypeMismatchException";
NSString * const RLMPropertiesComparisonTypeMismatchReason = @"Property type mismatch between %@ and %@";

// small helper to create the many exceptions thrown when parsing predicates
[[gnu::cold]] [[noreturn]]
void throwException(NSString *name, NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *reason = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    @throw [NSException exceptionWithName:name reason:reason userInfo:nil];
}

// check a precondition and throw an exception if it is not met
// this should be used iff the condition being false indicates a bug in the caller
// of the function checking its preconditions
void RLMPrecondition(bool condition, NSString *name, NSString *format, ...) {
    if (__builtin_expect(condition, 1)) {
        return;
    }

    va_list args;
    va_start(args, format);
    NSString *reason = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    @throw [NSException exceptionWithName:name reason:reason userInfo:nil];
}

BOOL propertyTypeIsNumeric(RLMPropertyType propertyType) {
    switch (propertyType) {
        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
        case RLMPropertyTypeDecimal128:
        case RLMPropertyTypeDate:
        case RLMPropertyTypeAny:
            return YES;
        default:
            return NO;
    }
}

bool propertyTypeIsLink(RLMPropertyType type) {
    return type == RLMPropertyTypeObject || type == RLMPropertyTypeLinkingObjects;
}

bool isObjectValidForProperty(id value, RLMProperty *prop) {
    if (prop.collection) {
        if (propertyTypeIsLink(prop.type)) {
            RLMObjectBase *obj = RLMDynamicCast<RLMObjectBase>(value);
            if (!obj) {
                obj = RLMDynamicCast<RLMObjectBase>(RLMBridgeSwiftValue(value));
            }
            if (!obj) {
                return false;
            }
            return [RLMObjectBaseObjectSchema(obj).className isEqualToString:prop.objectClassName];
        }
        return RLMValidateValue(value, prop.type, prop.optional, false, nil);
    }
    return RLMIsObjectValidForProperty(value, prop);
}


// Equal and ContainsSubstring are used by QueryBuilder::add_string_constraint as the comparator
// for performing diacritic-insensitive comparisons.

StringData get_string(Mixed const& m) {
    if (m.is_null())
        return StringData();
    if (m.get_type() == type_String)
        return m.get_string();
    auto b = m.get_binary();
    return StringData(b.data(), b.size());
}

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

    bool operator()(Mixed v1, Mixed v2) const
    {
        return equal(options, get_string(v1), get_string(v2));
    }

    static const char* description() { return options & kCFCompareCaseInsensitive ? "==[cd]" : "==[d]"; }
};

template <CFStringCompareFlags options>
struct NotEqual {
    using CaseSensitive = NotEqual<options & ~kCFCompareCaseInsensitive>;
    using CaseInsensitive = NotEqual<options | kCFCompareCaseInsensitive>;

    bool operator()(Mixed v1, Mixed v2) const
    {
        return !equal(options, get_string(v1), get_string(v2));
    }

    static const char* description() { return options & kCFCompareCaseInsensitive ? "!=[cd]" : "!=[d]"; }
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

    bool operator()(Mixed v1, Mixed v2) const
    {
        return contains_substring(options, get_string(v1), get_string(v2));
    }

    static const char* description() { return options & kCFCompareCaseInsensitive ? "CONTAINS[cd]" : "CONTAINS[d]"; }
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

[[gnu::cold]] [[noreturn]]
void unsupportedOperator(RLMPropertyType datatype, NSPredicateOperatorType operatorType) {
    throwException(@"Invalid operator type",
                   @"Operator '%@' not supported for type '%@'",
                   operatorName(operatorType), RLMTypeToString(datatype));
}

bool isNSNull(id value) {
    return !value || value == NSNull.null;
}

template<typename T>
bool isNSNull(T) {
    return false;
}

Table& get_table(Group& group, RLMObjectSchema *objectSchema)
{
    return *ObjectStore::table_for_object_type(group, objectSchema.objectStoreName);
}

// A reference to a column within a query. Can be resolved to a Columns<T> for use in query expressions.
class ColumnReference {
public:
    ColumnReference(Query& query, Group& group, RLMSchema *schema, RLMProperty* property, std::vector<RLMProperty*>&& links = {})
    : m_links(std::move(links)), m_property(property), m_schema(schema), m_group(&group), m_query(&query), m_link_chain(query.get_table())
    {
        for (const auto& link : m_links) {
            if (link.type != RLMPropertyTypeLinkingObjects) {
                m_link_chain.link(link.columnName.UTF8String);
            }
            else {
                auto [link_origin_table, link_origin_column] = link_origin(link);
                m_link_chain.backlink(link_origin_table, link_origin_column);
            }
        }
        m_col = m_link_chain.get_current_table()->get_column_key(m_property.columnName.UTF8String);
    }

    ColumnReference(Query& query, Group& group, RLMSchema *schema)
    : m_schema(schema), m_group(&group), m_query(&query)
    {
    }

    template <typename T, typename... SubQuery>
    auto resolve(SubQuery&&... subquery) const
    {
        static_assert(sizeof...(SubQuery) < 2, "resolve() takes at most one subquery");

        // LinkChain::column() mutates it, so we need to make a copy
        auto lc = m_link_chain;
        if (type() != RLMPropertyTypeLinkingObjects) {
            return lc.column<T>(column(), std::forward<SubQuery>(subquery)...);
        }

        if constexpr (std::is_same_v<T, Link>) {
            auto [table, col] = link_origin(m_property);
            return lc.column<T>(table, col, std::forward<SubQuery>(subquery)...);
        }

        REALM_TERMINATE("LinkingObjects property did not have column type Link");
    }

    RLMProperty *property() const { return m_property; }
    ColKey column() const { return m_col; }
    RLMPropertyType type() const { return property().type; }

    RLMObjectSchema *link_target_object_schema() const
    {
        REALM_ASSERT(is_link());
        return m_schema[property().objectClassName];
    }

    bool is_link() const noexcept {
        return propertyTypeIsLink(type());
    }

    bool has_any_to_many_links() const {
        return std::any_of(begin(m_links), end(m_links),
                           [](RLMProperty *property) { return property.collection; });
    }

    ColumnReference last_link_column() const {
        REALM_ASSERT(!m_links.empty());
        return {*m_query, *m_group, m_schema, m_links.back(), {m_links.begin(), m_links.end() - 1}};
    }

    ColumnReference column_ignoring_links(Query& query) const {
        return {query, *m_group, m_schema, m_property};
    }

    ColumnReference append(RLMProperty *prop) const {
        auto links = m_links;
        if (m_property) {
            links.push_back(m_property);
        }
        return ColumnReference(*m_query, *m_group, m_schema, prop, std::move(links));
    }

    void validate_comparison(id value) const {
        RLMPrecondition(isObjectValidForProperty(value, m_property),
                        @"Invalid value", @"Cannot compare value '%@' of type '%@' to property '%@' of type '%@'",
                        value, [value class], m_property.name, m_property.objectClassName ?: RLMTypeToString(m_property.type));
        if (RLMObjectBase *obj = RLMDynamicCast<RLMObjectBase>(value)) {
            RLMPrecondition(!obj->_row.is_valid() || m_group == &obj->_realm.group,
                            @"Invalid value origin", @"Object must be from the Realm being queried");
        }
    }

private:
    std::pair<Table&, ColKey> link_origin(RLMProperty *prop) const
    {
        RLMObjectSchema *link_origin_schema = m_schema[prop.objectClassName];
        Table& link_origin_table = get_table(*m_group, link_origin_schema);
        NSString *column_name = link_origin_schema[prop.linkOriginPropertyName].columnName;
        auto link_origin_column = link_origin_table.get_column_key(column_name.UTF8String);
        return {link_origin_table, link_origin_column};
    }

    std::vector<RLMProperty*> m_links;
    RLMProperty *m_property;
    RLMSchema *m_schema;
    Group *m_group;
    Query *m_query;
    LinkChain m_link_chain;
    ColKey m_col;
};

class CollectionOperation {
public:
    enum Type {
        None,
        Count,
        Minimum,
        Maximum,
        Sum,
        Average,
        // Dictionary specific.
        AllKeys
    };

    CollectionOperation(Type type, ColumnReference&& link_column, ColumnReference&& column)
        : m_type(type)
        , m_link_column(std::move(link_column))
        , m_column(std::move(column))
    {
        REALM_ASSERT(m_type != None);
    }

    Type type() const { return m_type; }
    const ColumnReference& link_column() const { return m_link_column; }
    const ColumnReference& column() const { return m_column; }

    void validate_comparison(id value) const {
        bool valid = true;
        switch (m_type) {
            case Count:
                RLMPrecondition([value isKindOfClass:[NSNumber class]], @"Invalid operand",
                                @"%@ can only be compared with a numeric value.", name_for_type(m_type));
                return;
            case Average:
            case Minimum:
            case Maximum:
                // Null on min/max/average matches arrays with no non-null values, including on non-nullable types
                valid = isNSNull(value) || isObjectValidForProperty(value, m_column.property());
                break;
            case Sum:
                // Sums are never null
                valid = !isNSNull(value) && isObjectValidForProperty(value, m_column.property());
                break;
            case AllKeys:
                RLMPrecondition(isNSNull(value) || [value isKindOfClass:[NSString class]], @"Invalid operand",
                                @"@allKeys can only be compared with a string value.");
                return;
            case None: break;
        }
        RLMPrecondition(valid, @"Invalid operand",
                        @"%@ on a property of type %@ cannot be compared with '%@'",
                        name_for_type(m_type), RLMTypeToString(m_column.type()), value);
    }

    void validate_comparison(const ColumnReference& column) const {
        switch (m_type) {
            case Count:
                RLMPrecondition(propertyTypeIsNumeric(column.type()), @"Invalid operand",
                                @"%@ can only be compared with a numeric value.", name_for_type(m_type));
                break;
            case Average: case Minimum: case Maximum: case Sum:
                RLMPrecondition(propertyTypeIsNumeric(column.type()), @"Invalid operand",
                                @"%@ on a property of type %@ cannot be compared with property of type '%@'",
                                name_for_type(m_type), RLMTypeToString(m_column.type()), RLMTypeToString(column.type()));
                break;
            case AllKeys:
                RLMPrecondition(column.type() == RLMPropertyTypeString, @"Invalid operand",
                                @"@allKeys can only be compared with a string value.");
                break;
            case None: break;
        }
    }

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
        if ([name isEqualToString:@"@allKeys"]) {
            return AllKeys;
        }
        return None;
    }

private:
    static NSString *name_for_type(Type type) {
        switch (type) {
            case Count: return @"@count";
            case Minimum: return @"@min";
            case Maximum: return @"@max";
            case Sum: return @"@sum";
            case Average: return @"@avg";
            case AllKeys: return @"@allKeys";
            case None: REALM_UNREACHABLE();
        }
    }

    Type m_type;
    ColumnReference m_link_column;
    ColumnReference m_column;
};

struct KeyPath;

class QueryBuilder {
public:
    QueryBuilder(Query& query, Group& group, RLMSchema *schema)
    : m_query(query), m_group(group), m_schema(schema) { }

    void apply_predicate(NSPredicate *predicate, RLMObjectSchema *objectSchema);

    void apply_collection_operator_expression(KeyPath&& kp, id value, NSComparisonPredicate *pred);
    void apply_value_expression(KeyPath&& kp, id value, NSComparisonPredicate *pred);
    void apply_column_expression(KeyPath&& left, KeyPath&& right, NSComparisonPredicate *predicate);
    void apply_function_expression(RLMObjectSchema *objectSchema, NSExpression *functionExpression,
                                   NSPredicateOperatorType operatorType, NSExpression *right);
    void apply_map_expression(RLMObjectSchema *objectSchema, NSExpression *functionExpression,
                              NSComparisonPredicateOptions options, NSPredicateOperatorType operatorType,
                              NSExpression *right);

    template <typename A, typename B>
    void add_numeric_constraint(RLMPropertyType datatype,
                                NSPredicateOperatorType operatorType,
                                A&& lhs, B&& rhs);

    template <typename A, typename B>
    void add_bool_constraint(RLMPropertyType, NSPredicateOperatorType operatorType, A&& lhs, B&& rhs);

    template <typename C, typename T>
    void add_mixed_constraint(NSPredicateOperatorType operatorType,
                              NSComparisonPredicateOptions predicateOptions,
                              Columns<C>&& column, T value);

    template <typename C>
    void add_mixed_constraint(NSPredicateOperatorType operatorType,
                              NSComparisonPredicateOptions predicateOptions,
                              Columns<C>&& column, const ColumnReference& c);

    template <typename C>
    void do_add_mixed_constraint(NSPredicateOperatorType operatorType,
                                 NSComparisonPredicateOptions predicateOptions,
                                 Columns<C>&& column, Mixed&& value);

    template<typename T>
    void add_substring_constraint(const T& value, Query condition);
    template<typename T>
    void add_substring_constraint(const Columns<T>& value, Query condition);

    template <typename C, typename T>
    void add_string_constraint(NSPredicateOperatorType operatorType,
                               NSComparisonPredicateOptions predicateOptions,
                               C&& column, T&& value);

    template <typename C, typename T>
    void add_diacritic_sensitive_string_constraint(NSPredicateOperatorType operatorType,
                                                   NSComparisonPredicateOptions predicateOptions,
                                                   C&& column, T&& value);
    template <typename C, typename T>
    void do_add_diacritic_sensitive_string_constraint(NSPredicateOperatorType operatorType,
                                                      NSComparisonPredicateOptions predicateOptions,
                                                      C&& column, T&& value);

    template <typename R>
    void add_constraint(NSPredicateOperatorType operatorType,
                        NSComparisonPredicateOptions predicateOptions,
                        ColumnReference const& column, R const& rhs);
    template <template<typename> typename W, typename T>
    void do_add_constraint(RLMPropertyType type, NSPredicateOperatorType operatorType,
                           NSComparisonPredicateOptions predicateOptions, ColumnReference const& column, T&& value);

    void add_between_constraint(const ColumnReference& column, id value);

    void add_memberwise_equality_constraint(const ColumnReference& column, RLMObjectBase *obj);

    void add_link_constraint(NSPredicateOperatorType operatorType, const ColumnReference& column, RLMObjectBase *obj);
    void add_link_constraint(NSPredicateOperatorType operatorType, const ColumnReference& column, realm::null);
    void add_link_constraint(NSPredicateOperatorType, const ColumnReference&, const ColumnReference&);
    void add_within_constraint(const ColumnReference& column, id<RLMGeospatial_Private> geospatial);

    template <CollectionOperation::Type Operation, bool IsLinkCollection, bool IsDictionary, typename R>
    void add_collection_operation_constraint(NSPredicateOperatorType operatorType,
                                             const CollectionOperation& collectionOperation, R&& rhs,
                                             NSComparisonPredicateOptions comparisionOptions);
    template <CollectionOperation::Type Operation, typename R>
    void add_collection_operation_constraint(NSPredicateOperatorType operatorType,
                                             const CollectionOperation& collectionOperation, R&& rhs,
                                             NSComparisonPredicateOptions comparisionOptions);
    template <typename R>
    void add_collection_operation_constraint(NSPredicateOperatorType operatorType,
                                             const CollectionOperation& collectionOperation, R&& rhs,
                                             NSComparisonPredicateOptions comparisionOptions);

    CollectionOperation collection_operation_from_key_path(KeyPath&& kp);
    ColumnReference column_reference_from_key_path(KeyPath&& kp, bool isAggregate);
    NSString* get_path_elements(std::vector<PathElement> &paths, NSExpression *expression);

private:
    Query& m_query;
    Group& m_group;
    RLMSchema *m_schema;
};

#pragma mark Numeric Constraints

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
            unsupportedOperator(datatype, operatorType);
    }
}

template <typename A, typename B>
void QueryBuilder::add_bool_constraint(RLMPropertyType datatype,
                                       NSPredicateOperatorType operatorType,
                                       A&& lhs, B&& rhs) {
    switch (operatorType) {
        case NSEqualToPredicateOperatorType:
            m_query.and_query(lhs == rhs);
            break;
        case NSNotEqualToPredicateOperatorType:
            m_query.and_query(lhs != rhs);
            break;
        default:
            unsupportedOperator(datatype, operatorType);
    }
}

#pragma mark String Constraints

template<typename T>
void QueryBuilder::add_substring_constraint(const T& value, Query condition) {
    // Foundation always returns false for substring operations with a RHS of null or "".
    m_query.and_query(value.size()
                      ? std::move(condition)
                      : std::unique_ptr<Expression>(new FalseExpression));
}

template<>
void QueryBuilder::add_substring_constraint(const Mixed& value, Query condition) {
    // Foundation always returns false for substring operations with a RHS of null or "".
    m_query.and_query(value.get_string().size()
                      ? std::move(condition)
                      : std::unique_ptr<Expression>(new FalseExpression));
}


template<typename T>
void QueryBuilder::add_substring_constraint(const Columns<T>& value, Query condition) {
    // Foundation always returns false for substring operations with a RHS of null or "".
    // We don't need to concern ourselves with the possibility of value traversing a link list
    // and producing multiple values per row as such expressions will have been rejected.
    m_query.and_query(const_cast<Columns<T>&>(value).size() != 0 && std::move(condition));
}

template<typename Comparator>
Query make_diacritic_insensitive_constraint(bool caseSensitive, std::unique_ptr<Subexpr> left, std::unique_ptr<Subexpr> right) {
    using CompareCS = Compare<typename Comparator::CaseSensitive>;
    using CompareCI = Compare<typename Comparator::CaseInsensitive>;
    if (caseSensitive) {
        return make_expression<CompareCS>(std::move(left), std::move(right));
    }
    else {
        return make_expression<CompareCI>(std::move(left), std::move(right));
    }
};

Query make_diacritic_insensitive_constraint(NSPredicateOperatorType operatorType, bool caseSensitive,
                                            std::unique_ptr<Subexpr> left, std::unique_ptr<Subexpr> right) {
    switch (operatorType) {
        case NSBeginsWithPredicateOperatorType: {
            constexpr auto flags = kCFCompareDiacriticInsensitive | kCFCompareAnchored;
            return make_diacritic_insensitive_constraint<ContainsSubstring<flags>>(caseSensitive, std::move(left), std::move(right));
        }
        case NSEndsWithPredicateOperatorType: {
            constexpr auto flags = kCFCompareDiacriticInsensitive | kCFCompareAnchored | kCFCompareBackwards;
            return make_diacritic_insensitive_constraint<ContainsSubstring<flags>>(caseSensitive, std::move(left), std::move(right));
        }
        case NSContainsPredicateOperatorType: {
            constexpr auto flags = kCFCompareDiacriticInsensitive;
            return make_diacritic_insensitive_constraint<ContainsSubstring<flags>>(caseSensitive, std::move(left), std::move(right));
        }
        default:
            REALM_COMPILER_HINT_UNREACHABLE();
    }
}

// static_assert is always evaluated even if it's inside a if constexpr
// unless the value is derived from the template argument, in which case it's
// only evaluated if that branch is active
template <typename> struct AlwaysFalse : std::false_type {};

template <typename C, typename T>
Query make_lexicographical_constraint(NSPredicateOperatorType operatorType,
                                      bool caseSensitive,
                                      C& column, T const& value) {
    if (!caseSensitive) {
        throwException(@"Invalid predicate",
                       @"Lexicographical comparisons must be case-sensitive");
    }
    switch (operatorType) {
        case NSLessThanPredicateOperatorType:
            return column < value;
        case NSLessThanOrEqualToPredicateOperatorType:
            return column <= value;
        case NSGreaterThanPredicateOperatorType:
            return column > value;
        case NSGreaterThanOrEqualToPredicateOperatorType:
            return column >= value;
        default:
            REALM_COMPILER_HINT_UNREACHABLE();
    }
}

template <typename C, typename T>
Query make_diacritic_sensitive_constraint(NSPredicateOperatorType operatorType,
                                          bool caseSensitive, C& column, T const& value)
{
    switch (operatorType) {
        case NSBeginsWithPredicateOperatorType:
            return column.begins_with(value, caseSensitive);
        case NSEndsWithPredicateOperatorType:
            return column.ends_with(value, caseSensitive);
        case NSContainsPredicateOperatorType:
            return column.contains(value, caseSensitive);
        case NSEqualToPredicateOperatorType:
            return column.equal(value, caseSensitive);
        case NSNotEqualToPredicateOperatorType:
            return column.not_equal(value, caseSensitive);
        case NSLikePredicateOperatorType:
            return column.like(value, caseSensitive);
        case NSLessThanPredicateOperatorType:
        case NSLessThanOrEqualToPredicateOperatorType:
        case NSGreaterThanPredicateOperatorType:
        case NSGreaterThanOrEqualToPredicateOperatorType:
            return make_lexicographical_constraint(operatorType, caseSensitive, column, value);
        default: {
            if constexpr (is_any_v<C, Columns<String>, Columns<Lst<String>>, Columns<Set<String>>, ColumnDictionaryKeys>) {
                unsupportedOperator(RLMPropertyTypeString, operatorType);
            }
            else if constexpr (is_any_v<C, Columns<Binary>, Columns<Lst<Binary>>, Columns<Set<Binary>>>) {
                unsupportedOperator(RLMPropertyTypeData, operatorType);
            }
            else if constexpr (is_any_v<C, Columns<Mixed>, Columns<Lst<Mixed>>, Columns<Set<Mixed>>>) {
                unsupportedOperator(RLMPropertyTypeAny, operatorType);
            }
            else if constexpr (is_any_v<C, Columns<Dictionary>>) {
                // The underlying storage type Dictionary is always Mixed. This creates an issue
                // where we cannot be descriptive about the exception as we do not know
                // the actual value type.
                throwException(@"Invalid operand type",
                               @"Operator '%@' not supported for string queries on Dictionary.",
                               operatorName(operatorType));
            }
            else {
                static_assert(AlwaysFalse<C>::value, "unsupported column type");
            }
        }
    }
}

template <typename C, typename T>
void QueryBuilder::do_add_diacritic_sensitive_string_constraint(NSPredicateOperatorType operatorType,
                                                                NSComparisonPredicateOptions predicateOptions,
                                                                C&& column, T&& value) {
    bool caseSensitive = !(predicateOptions & NSCaseInsensitivePredicateOption);
    Query condition = make_diacritic_sensitive_constraint(operatorType, caseSensitive, column, value);

    // Queries on Mixed used to coerce Strings to Binary and vice-versa. Core
    // no longer does this, but we can maintain compatibility by doing the
    // coercion and checking both
    // NEXT-MAJOR: we should remove this and realign with core's behavior
    if constexpr (is_any_v<C, Columns<Mixed>, Columns<Lst<Mixed>>, Columns<Set<Mixed>>, Columns<Dictionary>>) {
        Mixed m = value;
        if (!m.is_null()) {
            if (m.get_type() == type_String) {
                m = m.export_to_type<BinaryData>();
            }
            else {
                m = m.export_to_type<StringData>();
            }

            // Equality and substring operations need (col == strValue OR col == binValue),
            // but not equals needs (col != strValue AND col != binValue)
            if (operatorType != NSNotEqualToPredicateOperatorType) {
                condition.Or();
            }

            condition.and_query(make_diacritic_sensitive_constraint(operatorType, caseSensitive, column, m));
        }
    }
    switch (operatorType) {
        case NSBeginsWithPredicateOperatorType:
        case NSEndsWithPredicateOperatorType:
        case NSContainsPredicateOperatorType:
            add_substring_constraint(value, std::move(condition));
            break;

        default:
            m_query.and_query(std::move(condition));
            break;
    }
}

template <typename C, typename T>
void QueryBuilder::add_diacritic_sensitive_string_constraint(NSPredicateOperatorType operatorType,
                                                             NSComparisonPredicateOptions predicateOptions,
                                                             C&& column, T&& value) {

    if constexpr (is_any_v<C, Columns<Dictionary>> && is_any_v<T, Columns<StringData>, Columns<BinaryData>>) {
        // Core only implements these for Columns<Mixed> due to Dictionary being Mixed internall
        throwException(@"Unsupported predicate",
                       @"String comparisons on a Dictionary and another property are only implemented for AnyRealmValue properties.");
    }
    else {
        do_add_diacritic_sensitive_string_constraint(operatorType, predicateOptions, std::forward<C>(column), std::forward<T>(value));
    }
}

template <typename C, typename T>
void QueryBuilder::add_string_constraint(NSPredicateOperatorType operatorType,
                                         NSComparisonPredicateOptions predicateOptions,
                                         C&& column, T&& value) {
    if (!(predicateOptions & NSDiacriticInsensitivePredicateOption)) {
        add_diacritic_sensitive_string_constraint(operatorType, predicateOptions, std::forward<C>(column), std::forward<T>(value));
        return;
    }

    auto as_subexpr = util::overload{
        [](StringData value) { return make_subexpr<ConstantStringValue>(value); },
        [](BinaryData value) { return make_subexpr<ConstantStringValue>(StringData(value.data(), value.size())); },
        [](Mixed value) {
            // When Mixed is null calling `get_type` will throw an exception.
            if (value.is_null())
                return make_subexpr<ConstantStringValue>(value.get_string());
            switch (value.get_type()) {
                case DataType::Type::String:
                    return make_subexpr<ConstantStringValue>(value.get_string());
                case DataType::Type::Binary:
                    return make_subexpr<ConstantStringValue>(StringData(value.get_binary().data(), value.get_binary().size()));
                default:
                    REALM_UNREACHABLE();
            }
        },
        [](auto& c) { return c.clone(); }
    };
    auto left = as_subexpr(column);
    auto right = as_subexpr(value);

    bool caseSensitive = !(predicateOptions & NSCaseInsensitivePredicateOption);
    constexpr auto flags = kCFCompareDiacriticInsensitive | kCFCompareAnchored;
    switch (operatorType) {
        case NSBeginsWithPredicateOperatorType:
        case NSEndsWithPredicateOperatorType:
        case NSContainsPredicateOperatorType:
            add_substring_constraint(value, make_diacritic_insensitive_constraint(operatorType, caseSensitive, std::move(left), std::move(right)));
            break;
        case NSNotEqualToPredicateOperatorType:
            m_query.and_query(make_diacritic_insensitive_constraint<NotEqual<flags>>(caseSensitive, std::move(left), std::move(right)));
            break;
        case NSEqualToPredicateOperatorType:
            m_query.and_query(make_diacritic_insensitive_constraint<Equal<flags>>(caseSensitive, std::move(left), std::move(right)));
            break;
        case NSLikePredicateOperatorType:
            throwException(@"Invalid operator type",
                           @"Operator 'LIKE' not supported with diacritic-insensitive modifier.");
        default:
            unsupportedOperator(RLMPropertyTypeString, operatorType);
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
    RLMPrecondition(isObjectValidForProperty(*from, prop) && isObjectValidForProperty(*to, prop),
                    @"Invalid value",
                    @"NSArray objects must be of type %@ for BETWEEN operations", RLMTypeToString(prop.type));
}

#pragma mark Between Constraint

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

    if (!propertyTypeIsNumeric(column.type())) {
        return unsupportedOperator(column.type(), NSBetweenPredicateOperatorType);
    }

    m_query.group();
    add_constraint(NSGreaterThanOrEqualToPredicateOperatorType, 0, column, from);
    add_constraint(NSLessThanOrEqualToPredicateOperatorType, 0, column, to);
    m_query.end_group();
}

#pragma mark Link Constraints

void QueryBuilder::add_memberwise_equality_constraint(const ColumnReference& column, RLMObjectBase *obj) {
    for (RLMProperty *property in obj->_objectSchema.properties) {
        // Both of these probably are implementable, but are significantly more complicated.
        RLMPrecondition(!property.collection, @"Invalid predicate",
                        @"Unsupported property '%@.%@' for memberwise equality query: equality on collections is not implemented.",
                        obj->_objectSchema.className, property.name);
        RLMPrecondition(!propertyTypeIsLink(property.type), @"Invalid predicate",
                        @"Unsupported property '%@.%@' for memberwise equality query: object links are not implemented.",
                        obj->_objectSchema.className, property.name);
        add_constraint(NSEqualToPredicateOperatorType, 0, column.append(property), RLMDynamicGet(obj, property));
    }
}

void QueryBuilder::add_link_constraint(NSPredicateOperatorType operatorType,
                                       const ColumnReference& column, RLMObjectBase *obj) {
    // If the value isn't actually a RLMObject then it's something which bridges
    // to RLMObject, i.e. a custom type mapping to an embedded object. For those
    // we want to perform memberwise equality rather than equality on the link itself.
    if (![obj isKindOfClass:[RLMObjectBase class]]) {
        obj = RLMBridgeSwiftValue(obj);
        REALM_ASSERT([obj isKindOfClass:[RLMObjectBase class]]);

        // Collections need to use subqueries, but unary links can just use a
        // group. Unary links could also use a subquery but that has worse performance.
        if (column.property().collection) {
            Query subquery = get_table(m_group, column.link_target_object_schema()).where();
            QueryBuilder(subquery, m_group, m_schema)
                .add_memberwise_equality_constraint(ColumnReference(subquery, m_group, m_schema), obj);
            if (operatorType == NSEqualToPredicateOperatorType) {
                m_query.and_query(column.resolve<Link>(std::move(subquery)).count() > 0);
            }
            else {
                // This strange condition is because "ANY list != x" isn't
                // "NONE list == x"; there must be an object in the list for
                // this to match
                m_query.and_query(column.resolve<Link>().count() > 0 &&
                                  column.resolve<Link>(std::move(subquery)).count() == 0);
            }
        }
        else {
            if (operatorType == NSNotEqualToPredicateOperatorType) {
                m_query.Not();
            }

            m_query.group();
            add_memberwise_equality_constraint(column, obj);
            m_query.end_group();
        }
        return;
    }

    if (!obj->_row.is_valid()) {
        // Unmanaged or deleted objects are not equal to any managed objects.
        // For arrays this effectively checks if there are any objects in the
        // array, while for links it's just always constant true or false
        // (for != and = respectively).
        if (column.has_any_to_many_links() || column.property().collection) {
            add_link_constraint(operatorType, column, null());
        }
        else if (operatorType == NSEqualToPredicateOperatorType) {
            m_query.and_query(std::unique_ptr<Expression>(new FalseExpression));
        }
        else {
            m_query.and_query(std::unique_ptr<Expression>(new TrueExpression));
        }
    }
    else {
        if (column.property().dictionary) {
            add_bool_constraint(RLMPropertyTypeObject, operatorType, column.resolve<Dictionary>(), obj->_row);
        }
        else {
            add_bool_constraint(RLMPropertyTypeObject, operatorType, column.resolve<Link>(), obj->_row);
        }
    }
}

void QueryBuilder::add_link_constraint(NSPredicateOperatorType operatorType,
                                       const ColumnReference& column, realm::null) {
    if (column.property().dictionary) {
        add_bool_constraint(RLMPropertyTypeObject, operatorType, column.resolve<Dictionary>(), null());
    }
    else {
        add_bool_constraint(RLMPropertyTypeObject, operatorType, column.resolve<Link>(), null());
    }
}

void QueryBuilder::add_link_constraint(NSPredicateOperatorType operatorType,
                                       const ColumnReference& a, const ColumnReference& b) {
    if (a.property().dictionary) {
        add_bool_constraint(RLMPropertyTypeObject, operatorType, a.resolve<Dictionary>(), b.resolve<Dictionary>());
    }
    else {
        add_bool_constraint(RLMPropertyTypeObject, operatorType, a.resolve<Link>(), b.resolve<Link>());
    }
}

#pragma mark Geospatial

void QueryBuilder::add_within_constraint(const ColumnReference& column, id<RLMGeospatial_Private> geospatial) {
    auto geoQuery = column.resolve<Link>().geo_within(geospatial.geoSpatial);
    m_query.and_query(std::move(geoQuery));
}

// iterate over an array of subpredicates, using @func to build a query from each
// one and ORing them together
template<typename Func>
void process_or_group(Query &query, id array, Func&& func) {
    array = RLMAsFastEnumeration(array);
    RLMPrecondition(array, @"Invalid value", @"IN clause requires an array of items");

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

#pragma mark Conversion Helpers

template <typename>
realm::null value_of_type(realm::null) {
    return realm::null();
}

template <typename RequestedType>
auto value_of_type(__unsafe_unretained const id value) {
    return RLMStatelessAccessorContext::unbox<RequestedType>(value);
}

template <>
auto value_of_type<Mixed>(id value) {
    return RLMObjcToMixed(value, nil, CreatePolicy::Skip);
}

template <typename RequestedType>
auto value_of_type(const ColumnReference& column) {
    return column.resolve<RequestedType>();
}

template <typename T, typename Fn>
void convert_null(T&& value, Fn&& fn) {
    if (isNSNull(value)) {
        fn(null());
    }
    else {
        fn(std::forward<T>(value));
    }
}

template <template<typename> typename W, typename T>
void QueryBuilder::do_add_constraint(RLMPropertyType type, NSPredicateOperatorType operatorType,
                                     NSComparisonPredicateOptions predicateOptions, ColumnReference const& column, T&& value)
{
    switch (type) {
        case RLMPropertyTypeBool:
            convert_null(value, [&](auto&& value) {
                add_bool_constraint(type, operatorType, column.resolve<W<bool>>(),
                                    value_of_type<bool>(value));
            });
            break;
        case RLMPropertyTypeObjectId:
            convert_null(value, [&](auto&& value) {
                add_bool_constraint(type, operatorType, column.resolve<W<ObjectId>>(),
                                    value_of_type<ObjectId>(value));
            });
            break;
        case RLMPropertyTypeDate:
            convert_null(value, [&](auto&& value) {
                add_numeric_constraint(type, operatorType, column.resolve<W<Timestamp>>(),
                                       value_of_type<Timestamp>(value));
            });
            break;
        case RLMPropertyTypeDouble:
            convert_null(value, [&](auto&& value) {
                add_numeric_constraint(type, operatorType, column.resolve<W<Double>>(),
                                       value_of_type<Double>(value));
            });
            break;
        case RLMPropertyTypeFloat:
            convert_null(value, [&](auto&& value) {
                add_numeric_constraint(type, operatorType, column.resolve<W<Float>>(),
                                       value_of_type<Float>(value));
            });
            break;
        case RLMPropertyTypeInt:
            convert_null(value, [&](auto&& value) {
                add_numeric_constraint(type, operatorType, column.resolve<W<Int>>(),
                                       value_of_type<Int>(value));
            });
            break;
        case RLMPropertyTypeDecimal128:
            convert_null(value, [&](auto&& value) {
                add_numeric_constraint(type, operatorType, column.resolve<W<Decimal128>>(),
                                       value_of_type<Decimal128>(value));
            });
            break;
        case RLMPropertyTypeString:
            add_string_constraint(operatorType, predicateOptions, column.resolve<W<String>>(),
                                  value_of_type<String>(value));
            break;
        case RLMPropertyTypeData:
            add_string_constraint(operatorType, predicateOptions,
                                  column.resolve<W<Binary>>(),
                                  value_of_type<Binary>(value));
            break;
        case RLMPropertyTypeObject:
        case RLMPropertyTypeLinkingObjects:
            convert_null(value, [&](auto&& value) {
                add_link_constraint(operatorType, column, value);
            });
            break;
        case RLMPropertyTypeUUID:
            convert_null(value, [&](auto&& value) {
                add_bool_constraint(type, operatorType, column.resolve<W<UUID>>(),
                                    value_of_type<UUID>(value));
            });
            break;
        case RLMPropertyTypeAny:
            convert_null(value, [&](auto&& value) {
                add_mixed_constraint(operatorType,
                                     predicateOptions,
                                     column.resolve<W<Mixed>>(),
                                     value);
            });
    }
}

#pragma mark Mixed Constraints

template<typename C, typename T>
void QueryBuilder::add_mixed_constraint(NSPredicateOperatorType operatorType,
                                        NSComparisonPredicateOptions predicateOptions,
                                        Columns<C>&& column,
                                        T value)
{
    // Handle cases where a string might be '1' or '0'. Without this the string
    // will be boxed as a bool and thus string query operations will crash in core.
    if constexpr(std::is_same_v<T, id>) {
        if (auto str = RLMDynamicCast<NSString>(value)) {
            add_string_constraint(operatorType, predicateOptions,
                                  std::move(column), realm::Mixed([str UTF8String]));
            return;
        }
    }
    do_add_mixed_constraint(operatorType, predicateOptions,
                            std::move(column), value_of_type<Mixed>(value));
}

template<typename C>
void QueryBuilder::do_add_mixed_constraint(NSPredicateOperatorType operatorType,
                                           NSComparisonPredicateOptions predicateOptions,
                                           Columns<C>&& column,
                                           Mixed&& value)
{
    switch (operatorType) {
        case NSLessThanPredicateOperatorType:
            m_query.and_query(column < value);
            break;
        case NSLessThanOrEqualToPredicateOperatorType:
            m_query.and_query(column <= value);
            break;
        case NSGreaterThanPredicateOperatorType:
            m_query.and_query(column > value);
            break;
        case NSGreaterThanOrEqualToPredicateOperatorType:
            m_query.and_query(column >= value);
            break;
        case NSEqualToPredicateOperatorType:
            m_query.and_query(column == value);
            break;
        case NSNotEqualToPredicateOperatorType:
            m_query.and_query(column != value);
            break;
        // String comparison operators: There isn't a way for a string value
        // to get down here, but a rhs of NULL can
        case NSLikePredicateOperatorType:
        case NSMatchesPredicateOperatorType:
        case NSBeginsWithPredicateOperatorType:
        case NSEndsWithPredicateOperatorType:
        case NSContainsPredicateOperatorType:
            add_string_constraint(operatorType, predicateOptions,
                                  std::move(column), value);
            break;
        default:
            break;
    }
}

template<typename C>
void QueryBuilder::add_mixed_constraint(NSPredicateOperatorType operatorType,
                                        NSComparisonPredicateOptions,
                                        Columns<C>&& column,
                                        const ColumnReference& value)
{
    add_bool_constraint(RLMPropertyTypeObject, operatorType, column, value.resolve<Mixed>());
}

template<typename T>
using Identity = T;
template<typename>
using AlwaysDictionary = Dictionary;

template <typename R>
void QueryBuilder::add_constraint(NSPredicateOperatorType operatorType,
                                  NSComparisonPredicateOptions predicateOptions, ColumnReference const& column, R const& rhs)
{
    auto type = column.type();
    if (column.property().array) {
        do_add_constraint<Lst>(type, operatorType, predicateOptions, column, rhs);
    }
    else if (column.property().set) {
        do_add_constraint<Set>(type, operatorType, predicateOptions, column, rhs);
    }
    else if (column.property().dictionary) {
        do_add_constraint<AlwaysDictionary>(type, operatorType, predicateOptions, column, rhs);
    }
    else {
        do_add_constraint<Identity>(type, operatorType, predicateOptions, column, rhs);
    }
}

struct KeyPath {
    std::vector<RLMProperty *> links;
    RLMProperty *property;
    CollectionOperation::Type collectionOperation;
    bool containsToManyRelationship;
};

KeyPath key_path_from_string(RLMSchema *schema, RLMObjectSchema *objectSchema, NSString *keyPath)
{
    RLMProperty *property;
    std::vector<RLMProperty *> links;

    CollectionOperation::Type collectionOperation = CollectionOperation::None;
    NSString *collectionOperationName;
    bool keyPathContainsToManyRelationship = false;

    NSUInteger start = 0, length = keyPath.length, end = length;
    for (; end != NSNotFound; start = end + 1) {
        end = [keyPath rangeOfString:@"." options:0 range:{start, length - start}].location;
        RLMPrecondition(end == NSNotFound || end + 1 < length, @"Invalid predicate",
                        @"Invalid keypath '%@': no key name after last '.'", keyPath);
        RLMPrecondition(end > start, @"Invalid predicate",
                        @"Invalid keypath '%@': no key name before '.'", keyPath);

        NSString *propertyName = [keyPath substringWithRange:{start, end == NSNotFound ? length - start : end - start}];

        if ([propertyName characterAtIndex:0] == '@') {
            if ([propertyName isEqualToString:@"@allValues"]) {
                RLMPrecondition(property.dictionary, @"Invalid predicate",
                                @"Invalid keypath '%@': @allValues must follow a dictionary property.", keyPath);
                continue;
            }
            RLMPrecondition(collectionOperation == CollectionOperation::None, @"Invalid predicate",
                            @"Invalid keypath '%@': at most one collection operation per keypath is supported.", keyPath);
            collectionOperation = CollectionOperation::type_for_name(propertyName);
            RLMPrecondition(collectionOperation != CollectionOperation::None, @"Invalid predicate",
                            @"Invalid keypath '%@': Unsupported collection operation '%@'", keyPath, propertyName);

            RLMPrecondition(property.collection, @"Invalid predicate",
                            @"Invalid keypath '%@': collection operation '%@' must be applied to a collection", keyPath, propertyName);
            switch (collectionOperation) {
                case CollectionOperation::None:
                    REALM_UNREACHABLE();
                case CollectionOperation::Count:
                    RLMPrecondition(end == NSNotFound, @"Invalid predicate",
                                    @"Invalid keypath '%@': @count must appear at the end of a keypath.", keyPath);
                    break;
                case CollectionOperation::AllKeys:
                    RLMPrecondition(end == NSNotFound, @"Invalid predicate",
                                    @"Invalid keypath '%@': @allKeys must appear at the end of a keypath.", keyPath);
                    RLMPrecondition(property.dictionary, @"Invalid predicate",
                                    @"Invalid keypath '%@': @allKeys must follow a dictionary property.", keyPath);
                    break;
                default:
                    if (propertyTypeIsLink(property.type)) {
                        RLMPrecondition(end != NSNotFound, @"Invalid predicate",
                                        @"Invalid keypath '%@': %@ on a collection of objects cannot appear at the end of a keypath.", keyPath, propertyName);
                    }
                    else {
                        RLMPrecondition(end == NSNotFound, @"Invalid predicate",
                                        @"Invalid keypath '%@': %@ on a collection of values must appear at the end of a keypath.", keyPath, propertyName);
                        RLMPrecondition(propertyTypeIsNumeric(property.type), @"Invalid predicate",
                                        @"Invalid keypath '%@': %@ can only be applied to a collection of numeric values.", keyPath, propertyName);
                    }
            }
            collectionOperationName = propertyName;
            continue;
        }

        RLMPrecondition(objectSchema, @"Invalid predicate",
                        @"Invalid keypath '%@': %@ property %@ can only be followed by a collection operation.",
                        keyPath, property.typeName, property.name);

        property = objectSchema[propertyName];
        RLMPrecondition(property, @"Invalid predicate",
                        @"Invalid keypath '%@': Property '%@' not found in object of type '%@'",
                        keyPath, propertyName, objectSchema.className);
        RLMPrecondition(collectionOperation == CollectionOperation::None || (propertyTypeIsNumeric(property.type) && !property.collection),
                        @"Invalid predicate",
                        @"Invalid keypath '%@': %@ must be followed by a numeric property.", keyPath, collectionOperationName);

        if (property.collection)
            keyPathContainsToManyRelationship = true;

        links.push_back(property);

        if (end != NSNotFound) {
            RLMPrecondition(property.type == RLMPropertyTypeObject || property.type == RLMPropertyTypeLinkingObjects || property.collection,
                            @"Invalid predicate", @"Invalid keypath '%@': Property '%@.%@' is not a link or collection and can only appear at the end of a keypath.",
                            keyPath, objectSchema.className, propertyName);
            objectSchema = property.objectClassName ? schema[property.objectClassName] : nil;
        }
    };

    links.pop_back();
    return {std::move(links), property, collectionOperation, keyPathContainsToManyRelationship};
}

ColumnReference QueryBuilder::column_reference_from_key_path(KeyPath&& kp, bool isAggregate)
{
    if (isAggregate && !kp.containsToManyRelationship && kp.property.type != RLMPropertyTypeAny) {
        throwException(@"Invalid predicate",
                       @"Aggregate operations can only be used on key paths that include an collection property");
    } else if (!isAggregate && kp.containsToManyRelationship) {
        throwException(@"Invalid predicate",
                       @"Key paths that include a collection property must use aggregate operations");
    }

    return ColumnReference(m_query, m_group, m_schema, kp.property, std::move(kp.links));
}

#pragma mark Collection Operations

template <CollectionOperation::Type OperationType, typename Column>
auto collection_operation_expr_2(Column&& column) {
    if constexpr (OperationType == CollectionOperation::Minimum) {
        return column.min();
    }
    else if constexpr (OperationType == CollectionOperation::Maximum) {
        return column.max();
    }
    else if constexpr (OperationType == CollectionOperation::Sum) {
        return column.sum();
    }
    else if constexpr (OperationType == CollectionOperation::Average) {
        return column.average();
    }
    else {
        static_assert(AlwaysFalse<std::integral_constant<CollectionOperation::Type, OperationType>>::value,
                      "invalid operation type");
    }
}

template <typename Requested, CollectionOperation::Type OperationType, bool IsLinkCollection, bool IsDictionary>
auto collection_operation_expr(CollectionOperation operation) {
    REALM_ASSERT(operation.type() == OperationType);

    if constexpr (IsLinkCollection) {
        auto&& resolved = operation.link_column().resolve<Link>();
        auto col = operation.column().column();
        return collection_operation_expr_2<OperationType>(resolved.template column<Requested>(col));
    }
    else if constexpr (IsDictionary) {
        return collection_operation_expr_2<OperationType>(operation.link_column().resolve<Dictionary>());
    }
    else {
        return collection_operation_expr_2<OperationType>(operation.link_column().resolve<Lst<Requested>>());
    }
}

template <CollectionOperation::Type Operation, bool IsLinkCollection, bool IsDictionary, typename R>
void QueryBuilder::add_collection_operation_constraint(NSPredicateOperatorType operatorType,
                                                       CollectionOperation const& collectionOperation, R&& rhs,
                                                       NSComparisonPredicateOptions)
{
    auto type = IsLinkCollection ? collectionOperation.column().type() : collectionOperation.link_column().type();

    switch (type) {
        case RLMPropertyTypeInt:
            add_numeric_constraint(type, operatorType,
                                   collection_operation_expr<Int, Operation, IsLinkCollection, IsDictionary>(collectionOperation),
                                   value_of_type<Int>(rhs));
            break;
        case RLMPropertyTypeFloat:
            add_numeric_constraint(type, operatorType,
                                   collection_operation_expr<Float, Operation, IsLinkCollection, IsDictionary>(collectionOperation),
                                   value_of_type<Float>(rhs));
            break;
        case RLMPropertyTypeDouble:
            add_numeric_constraint(type, operatorType,
                                   collection_operation_expr<Double, Operation, IsLinkCollection, IsDictionary>(collectionOperation),
                                   value_of_type<Double>(rhs));
            break;
        case RLMPropertyTypeDecimal128:
            add_numeric_constraint(type, operatorType,
                                   collection_operation_expr<Decimal128, Operation, IsLinkCollection, IsDictionary>(collectionOperation),
                                   value_of_type<Decimal128>(rhs));
            break;
        case RLMPropertyTypeDate:
            if constexpr (Operation == CollectionOperation::Sum || Operation == CollectionOperation::Average) {
                throwException(@"Unsupported predicate value type",
                               @"Cannot sum or average date properties");
            }
            else {
                add_numeric_constraint(type, operatorType,
                                       collection_operation_expr<Timestamp, Operation, IsLinkCollection, IsDictionary>(collectionOperation),
                                       value_of_type<Timestamp>(rhs));
            }
            break;
        case RLMPropertyTypeAny:
            add_numeric_constraint(type, operatorType,
                                   collection_operation_expr<Mixed, Operation, IsLinkCollection, IsDictionary>(collectionOperation),
                                   value_of_type<Mixed>(rhs));
            break;
        default:
            REALM_ASSERT(false && "Only numeric property types should hit this path.");
    }
}

template <CollectionOperation::Type Operation, typename R>
void QueryBuilder::add_collection_operation_constraint(NSPredicateOperatorType operatorType,
                                                       CollectionOperation const& collectionOperation, R&& rhs,
                                                       NSComparisonPredicateOptions options)
{
    convert_null(std::forward<R>(rhs), [&]<typename T>(T&& rhs) {
        if (collectionOperation.link_column().is_link()) {
            add_collection_operation_constraint<Operation, true, false>(operatorType, collectionOperation, std::forward<T>(rhs), options);
        }
        else if (collectionOperation.column().property().dictionary) {
            add_collection_operation_constraint<Operation, false, true>(operatorType, collectionOperation, std::forward<T>(rhs), options);
        }
        else {
            add_collection_operation_constraint<Operation, false, false>(operatorType, collectionOperation, std::forward<T>(rhs), options);
        }
    });
}

template <typename T, typename Fn>
void get_collection_type(__unsafe_unretained RLMProperty *prop, Fn&& fn) {
    if (prop.array) {
        fn((Lst<T>*)0);
    }
    else if (prop.set) {
        fn((Set<T>*)0);
    }
    else {
        fn((Dictionary*)0);
    }
}

template <typename R>
void QueryBuilder::add_collection_operation_constraint(NSPredicateOperatorType operatorType,
                                                       CollectionOperation const& collectionOperation, R&& rhs,
                                                       NSComparisonPredicateOptions comparisonOptions)
{
    switch (collectionOperation.type()) {
        case CollectionOperation::None:
            break;
        case CollectionOperation::Count: {
            auto& column = collectionOperation.link_column();
            RLMPropertyType type = column.type();
            auto rhsValue = value_of_type<Int>(rhs);
            auto continuation = [&]<typename T>(T *) {
                add_numeric_constraint(type, operatorType, column.resolve<T>().size(), rhsValue);
            };

            switch (type) {
                case RLMPropertyTypeBool:
                    return get_collection_type<Bool>(column.property(), std::move(continuation));
                case RLMPropertyTypeObjectId:
                    return get_collection_type<ObjectId>(column.property(), std::move(continuation));
                case RLMPropertyTypeDate:
                    return get_collection_type<Timestamp>(column.property(), std::move(continuation));
                case RLMPropertyTypeDouble:
                    return get_collection_type<Double>(column.property(), std::move(continuation));
                case RLMPropertyTypeFloat:
                    return get_collection_type<Float>(column.property(), std::move(continuation));
                case RLMPropertyTypeInt:
                    return get_collection_type<Int>(column.property(), std::move(continuation));
                case RLMPropertyTypeDecimal128:
                    return get_collection_type<Decimal128>(column.property(), std::move(continuation));
                case RLMPropertyTypeString:
                    return get_collection_type<String>(column.property(), std::move(continuation));
                case RLMPropertyTypeData:
                    return get_collection_type<Binary>(column.property(), std::move(continuation));
                case RLMPropertyTypeUUID:
                    return get_collection_type<UUID>(column.property(), std::move(continuation));
                case RLMPropertyTypeAny:
                    return get_collection_type<Mixed>(column.property(), std::move(continuation));
                case RLMPropertyTypeObject:
                case RLMPropertyTypeLinkingObjects:
                    return add_numeric_constraint(type, operatorType, column.resolve<Link>().count(), rhsValue);
            }
        }
        case CollectionOperation::Minimum:
            add_collection_operation_constraint<CollectionOperation::Minimum>(operatorType, collectionOperation, std::forward<R>(rhs), comparisonOptions);
            break;
        case CollectionOperation::Maximum:
            add_collection_operation_constraint<CollectionOperation::Maximum>(operatorType, collectionOperation, std::forward<R>(rhs), comparisonOptions);
            break;
        case CollectionOperation::Sum:
            add_collection_operation_constraint<CollectionOperation::Sum>(operatorType, collectionOperation, std::forward<R>(rhs), comparisonOptions);
            break;
        case CollectionOperation::Average:
            add_collection_operation_constraint<CollectionOperation::Average>(operatorType, collectionOperation, std::forward<R>(rhs), comparisonOptions);
            break;
        case CollectionOperation::AllKeys: {
            // BETWEEN and IN are not supported by @allKeys as the parsing for collection
            // operators happens before and disection of a rhs array of values.
            add_string_constraint(operatorType, comparisonOptions,
                                  Columns<Dictionary>(collectionOperation.link_column().column(), m_query.get_table()).keys(),
                                  value_of_type<StringData>(rhs));
            break;
        }
    }
}

bool key_path_contains_collection_operator(const KeyPath& kp) {
    return kp.collectionOperation != CollectionOperation::None;
}

CollectionOperation QueryBuilder::collection_operation_from_key_path(KeyPath&& kp) {
    // Collection operations can either come at the end, or immediately before
    // the last property. Count and AllKeys are always the end, while
    // min/max/sum/avg are at the end for collections of primitives and one
    // before the end for collections of objects (with the aggregate done on a
    // property of those objects). For one-before-the-end we need to construct
    // a KeyPath to both the final link and the final property.
    KeyPath linkPrefix = kp;
    if (kp.collectionOperation != CollectionOperation::Count && kp.collectionOperation != CollectionOperation::AllKeys && !kp.property.collection) {
        REALM_ASSERT(!kp.links.empty());
        linkPrefix.property = linkPrefix.links.back();
        linkPrefix.links.pop_back();
    }
    return CollectionOperation(kp.collectionOperation, column_reference_from_key_path(std::move(linkPrefix), true),
                               column_reference_from_key_path(std::move(kp), true));
}

NSPredicateOperatorType invert_comparison_operator(NSPredicateOperatorType type) {
    switch (type) {
        case NSLessThanPredicateOperatorType:
            return NSGreaterThanPredicateOperatorType;
        case NSLessThanOrEqualToPredicateOperatorType:
            return NSGreaterThanOrEqualToPredicateOperatorType;
        case NSGreaterThanPredicateOperatorType:
            return NSLessThanPredicateOperatorType;
        case NSGreaterThanOrEqualToPredicateOperatorType:
            return NSLessThanOrEqualToPredicateOperatorType;
        case NSBeginsWithPredicateOperatorType:
        case NSEndsWithPredicateOperatorType:
        case NSContainsPredicateOperatorType:
        case NSLikePredicateOperatorType:
            throwException(@"Unsupported predicate", @"Operator '%@' requires a keypath on the left side.", operatorName(type));
        default:
            return type;
    }
}

void QueryBuilder::apply_collection_operator_expression(KeyPath&& kp, id value,
                                                        NSComparisonPredicate *pred) {
    CollectionOperation operation = collection_operation_from_key_path(std::move(kp));
    operation.validate_comparison(value);

    auto type = pred.predicateOperatorType;
    if (pred.leftExpression.expressionType != NSKeyPathExpressionType) {
        // Turn "a > b" into "b < a" so that we can always put the column on the lhs
        type = invert_comparison_operator(type);
    }
    add_collection_operation_constraint(type, operation, value, pred.options);
}

void QueryBuilder::apply_value_expression(KeyPath&& kp, id value, NSComparisonPredicate *pred)
{
    if (key_path_contains_collection_operator(kp)) {
        apply_collection_operator_expression(std::move(kp), value, pred);
        return;
    }

    bool isAny = pred.comparisonPredicateModifier == NSAnyPredicateModifier;
    ColumnReference column = column_reference_from_key_path(std::move(kp), isAny);

    // check to see if this is a between query
    if (pred.predicateOperatorType == NSBetweenPredicateOperatorType) {
        add_between_constraint(std::move(column), value);
        return;
    }

    if (pred.predicateOperatorType == NSInPredicateOperatorType) {
        if ([value conformsToProtocol:@protocol(RLMGeospatial)]) {
            // In case of `IN` check if the value is a Geo-shape, create a `geoWithin` query
            add_within_constraint(std::move(column), value);
        } else {
            // turn "key.path IN collection" into ored together ==. "collection IN key.path" is handled elsewhere.
            process_or_group(m_query, value, [&](id item) {
                id normalized = value_from_constant_expression_or_value(item);
                column.validate_comparison(normalized);
                add_constraint(NSEqualToPredicateOperatorType, pred.options, column, normalized);
            });
        }
        return;
    }

    column.validate_comparison(value);
    if (pred.leftExpression.expressionType == NSKeyPathExpressionType) {
        add_constraint(pred.predicateOperatorType, pred.options, std::move(column), value);
    } else {
        add_constraint(invert_comparison_operator(pred.predicateOperatorType), pred.options, std::move(column), value);
    }
}

void QueryBuilder::apply_column_expression(KeyPath&& leftKeyPath, KeyPath&& rightKeyPath, NSComparisonPredicate *predicate)
{
    bool left_key_path_contains_collection_operator = key_path_contains_collection_operator(leftKeyPath);
    bool right_key_path_contains_collection_operator = key_path_contains_collection_operator(rightKeyPath);
    if (left_key_path_contains_collection_operator && right_key_path_contains_collection_operator) {
        throwException(@"Unsupported predicate", @"Key paths including aggregate operations cannot be compared with other aggregate operations.");
    }

    if (left_key_path_contains_collection_operator) {
        CollectionOperation left = collection_operation_from_key_path(std::move(leftKeyPath));
        ColumnReference right = column_reference_from_key_path(std::move(rightKeyPath), false);
        left.validate_comparison(right);
        add_collection_operation_constraint(predicate.predicateOperatorType, std::move(left), std::move(right), predicate.options);
        return;
    }
    if (right_key_path_contains_collection_operator) {
        ColumnReference left = column_reference_from_key_path(std::move(leftKeyPath), false);
        CollectionOperation right = collection_operation_from_key_path(std::move(rightKeyPath));
        right.validate_comparison(left);
        add_collection_operation_constraint(invert_comparison_operator(predicate.predicateOperatorType),
                                            std::move(right), std::move(left), predicate.options);
        return;
    }

    bool isAny = false;
    ColumnReference left = column_reference_from_key_path(std::move(leftKeyPath), isAny);
    ColumnReference right = column_reference_from_key_path(std::move(rightKeyPath), isAny);

    // NOTE: It's assumed that column type must match and no automatic type conversion is supported.
    RLMPrecondition(left.type() == right.type(),
                    RLMPropertiesComparisonTypeMismatchException,
                    RLMPropertiesComparisonTypeMismatchReason,
                    RLMTypeToString(left.type()),
                    RLMTypeToString(right.type()));

    // TODO: Should we handle special case where left row is the same as right row (tautology)
    add_constraint(predicate.predicateOperatorType, predicate.options,
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

void QueryBuilder::apply_map_expression(RLMObjectSchema *objectSchema, NSExpression *functionExpression,
                                        NSComparisonPredicateOptions options, NSPredicateOperatorType operatorType,
                                        NSExpression *right) {
    std::vector<PathElement> pathElements;
    NSString *keyPath = get_path_elements(pathElements, functionExpression);

    ColumnReference collectionColumn = column_reference_from_key_path(key_path_from_string(m_schema, objectSchema, keyPath), true);

    if (collectionColumn.property().type == RLMPropertyTypeAny && !collectionColumn.property().dictionary) {
        add_mixed_constraint(operatorType, options, std::move(collectionColumn.resolve<realm::Mixed>().path(pathElements)), right.constantValue);
    } else {
        RLMPrecondition(collectionColumn.property().dictionary, @"Invalid predicate",
                        @"Invalid keypath '%@': only dictionaries and realm `Any` support subscript predicates.", functionExpression);
        RLMPrecondition(pathElements.size() == 1, @"Invalid subscript size",
                        @"Invalid subscript size '%@': nested dictionaries queries are only allowed in mixed properties.", functionExpression);
        RLMPrecondition(pathElements[0].is_key(), @"Invalid subscript type",
                        @"Invalid subscript type '%@'; only string keys are allowed as subscripts in dictionary queries.", functionExpression);
        add_mixed_constraint(operatorType, options, std::move(collectionColumn.resolve<Dictionary>().key(pathElements[0].get_key())), right.constantValue);
    }
}

void QueryBuilder::apply_function_expression(RLMObjectSchema *objectSchema, NSExpression *functionExpression,
                                             NSPredicateOperatorType operatorType, NSExpression *right) {
    RLMPrecondition(functionExpression.operand.expressionType == NSSubqueryExpressionType,
                    @"Invalid predicate", @"The '%@' function is not supported.", functionExpression.function);
    RLMPrecondition([functionExpression.function isEqualToString:@"valueForKeyPath:"] && functionExpression.arguments.count == 1,
                    @"Invalid predicate", @"The '%@' function is not supported on the result of a SUBQUERY.", functionExpression.function);

    NSExpression *keyPathExpression = functionExpression.arguments.firstObject;
    RLMPrecondition([keyPathExpression.keyPath isEqualToString:@"@count"],
                    @"Invalid predicate", @"SUBQUERY is only supported when immediately followed by .@count that is compared with a constant number.");
    RLMPrecondition(right.expressionType == NSConstantValueExpressionType && [right.constantValue isKindOfClass:[NSNumber class]],
                    @"Invalid predicate expression", @"SUBQUERY(…).@count is only supported when compared with a constant number.");

    NSExpression *subqueryExpression = functionExpression.operand;
    int64_t value = [right.constantValue integerValue];

    ColumnReference collectionColumn = column_reference_from_key_path(key_path_from_string(m_schema, objectSchema, [subqueryExpression.collection keyPath]), true);
    RLMObjectSchema *collectionMemberObjectSchema = m_schema[collectionColumn.property().objectClassName];

    // Eliminate references to the iteration variable in the subquery.
    NSPredicate *subqueryPredicate = [subqueryExpression.predicate predicateWithSubstitutionVariables:@{subqueryExpression.variable: [NSExpression expressionForEvaluatedObject]}];
    subqueryPredicate = transformPredicate(subqueryPredicate, simplify_self_value_for_key_path_function_expression);

    Query subquery = RLMPredicateToQuery(subqueryPredicate, collectionMemberObjectSchema, m_schema, m_group);
    add_numeric_constraint(RLMPropertyTypeInt, operatorType,
                           collectionColumn.resolve<Link>(std::move(subquery)).count(), value);
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
                // Not actually possible short of users making their own weird
                // broken subclass of NSPredicate
                throwException(@"Invalid compound predicate type",
                               @"Only AND, OR, and NOT compound predicates are supported");
        }
    }
    else if ([predicate isMemberOfClass:[NSComparisonPredicate class]]) {
        NSComparisonPredicate *compp = (NSComparisonPredicate *)predicate;

        RLMPrecondition(compp.comparisonPredicateModifier != NSAllPredicateModifier,
                        @"Invalid predicate", @"ALL modifier not supported");

        NSExpressionType exp1Type = compp.leftExpression.expressionType;
        NSExpressionType exp2Type = compp.rightExpression.expressionType;

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
                    throwException(@"Invalid predicate",
                                   @"Predicate with BETWEEN operator must compare a KeyPath with an aggregate with two values");
                }
                else if (compp.predicateOperatorType == NSInPredicateOperatorType) {
                    throwException(@"Invalid predicate",
                                   @"Predicate with IN operator must compare a KeyPath with an aggregate");
                }
            }
        }

        if (exp1Type == NSKeyPathExpressionType && exp2Type == NSKeyPathExpressionType) {
            // both expression are KeyPaths
            apply_column_expression(key_path_from_string(m_schema, objectSchema, compp.leftExpression.keyPath),
                                    key_path_from_string(m_schema, objectSchema, compp.rightExpression.keyPath),
                                    compp);
        }
        else if (exp1Type == NSKeyPathExpressionType && exp2Type == NSConstantValueExpressionType) {
            // comparing keypath to value
            apply_value_expression(key_path_from_string(m_schema, objectSchema, compp.leftExpression.keyPath),
                                   compp.rightExpression.constantValue, compp);
        }
        else if (exp1Type == NSConstantValueExpressionType && exp2Type == NSKeyPathExpressionType) {
            // comparing value to keypath
            apply_value_expression(key_path_from_string(m_schema, objectSchema, compp.rightExpression.keyPath),
                                   compp.leftExpression.constantValue, compp);
        }
        else if (exp1Type == NSFunctionExpressionType) {
            if (compp.leftExpression.operand.expressionType == NSSubqueryExpressionType) {
                apply_function_expression(objectSchema, compp.leftExpression, compp.predicateOperatorType, compp.rightExpression);
            } else {
                apply_map_expression(objectSchema, compp.leftExpression, compp.options, compp.predicateOperatorType, compp.rightExpression);
            }
        }
        else if (exp1Type == NSSubqueryExpressionType) {
            // The subquery expressions that we support are handled by the NSFunctionExpressionType case above.
            throwException(@"Invalid predicate expression", @"SUBQUERY is only supported when immediately followed by .@count.");
        }
        else {
            throwException(@"Invalid predicate expressions",
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
        throwException(@"Invalid predicate",
                       @"Only support compound, comparison, and constant predicates");
    }
}

// This function returns the nested subscripts from a NSPredicate with the following format `anyCol[0]['key'][#any]`
// and its respective keypath (including any linked keypath)
// This will iterate each argument of the NSExpression and its nested NSExpressions, takes the constant subscript
// and creates a PathElement to be used in the query. If we use `#any` as a wildcard this will show in the parser 
// predicate as NSKeyPathExpressionType.
NSString* QueryBuilder::get_path_elements(std::vector<PathElement> &paths, NSExpression *expression) {
    NSString *keyPath = @"";
    for (NSUInteger i = 0; i < expression.arguments.count; i++) {
        NSString *nestedKeyPath = @"";
        if (expression.arguments[i].expressionType == NSFunctionExpressionType) {
            nestedKeyPath = get_path_elements(paths, expression.arguments[i]);
        } else if (expression.arguments[i].expressionType == NSConstantValueExpressionType) {
            id value = [expression.arguments[i] constantValue];
            if ([value isKindOfClass:[NSNumber class]]) {
                paths.push_back(PathElement{[(NSNumber *)value intValue]});
            } else if ([value isKindOfClass:[NSString class]]) {
                NSString *key = (NSString *)value;
                paths.push_back(PathElement{key.UTF8String});
            } else {
                throwException(@"Invalid subscript type",
                               @"Invalid subscript type '%@': Only `Strings` or index are allowed subscripts", expression);
            }
        } else if (expression.arguments[i].expressionType == NSKeyPathExpressionType) {
            auto keyPath = [(id)expression.arguments[i] predicateFormat];
            if ([keyPath isEqual:@"#any"]) {
                paths.emplace_back();
            } else {
                nestedKeyPath = keyPath;
            }
        } else {
            throwException(@"Invalid expression type",
                           @"Invalid expression type '%@': Subscripts queries don't allow any other expression types", expression);
        }
        if ([nestedKeyPath length] > 0) {
            keyPath = ([keyPath length] > 0) ? [NSString stringWithFormat:@"%@.%@", keyPath, nestedKeyPath] : nestedKeyPath;
        }
    }

    return keyPath;
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

    try {
        @autoreleasepool {
            QueryBuilder(query, group, schema).apply_predicate(predicate, objectSchema);
        }
    }
    catch (std::exception const& e) {
        @throw RLMException(e);
    }

    return query;
}

// return the property for a validated column name
RLMProperty *RLMValidatedProperty(RLMObjectSchema *desc, NSString *columnName) {
    RLMProperty *prop = desc[columnName];
    RLMPrecondition(prop, @"Invalid property name",
                    @"Property '%@' not found in object of type '%@'", columnName, desc.className);
    return prop;
}
