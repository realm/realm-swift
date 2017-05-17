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
#import "RLMProperty_Private.hpp"
#import "RLMSchema.h"
#import "RLMUtil.hpp"

#import "object_store.hpp"
#import "results.hpp"

#include <realm/query_engine.hpp>
#include <realm/query_expression.hpp>
#include <realm/util/cf_ptr.hpp>
#include <realm/util/overload.hpp>

#include "eggs/variant.hpp"

#if 0
template <typename...> struct make_void { typedef void type; };
template <typename... Ts> using void_t = typename make_void<Ts...>::type;
#endif

struct nonesuch {
    nonesuch() = delete;
    ~nonesuch() = delete;
    nonesuch(nonesuch const&) = delete;
    void operator=(nonesuch const&) = delete;
};

namespace detail {

template <class Default, class AlwaysVoid,
template<class...> class Op, class... Args>
struct detector {
    using value_t = std::false_type;
    using type = Default;
};

template <class Default, template<class...> class Op, class... Args>
struct detector<Default, void_t<Op<Args...>>, Op, Args...> {
    // Note that std::void_t is a C++17 feature
    using value_t = std::true_type;
    using type = Op<Args...>;
};

} // namespace detail

template <template<class...> class Op, class... Args>
using is_detected = typename detail::detector<nonesuch, void, Op, Args...>::value_t;

template <template<class...> class Op, class... Args>
using detected_t = typename detail::detector<nonesuch, void, Op, Args...>::type;

template <class Default, template<class...> class Op, class... Args>
using detected_or = detail::detector<Default, void, Op, Args...>;





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
                        @"Property '%@' not found in object of type '%@'",
                        propertyName, objectSchema.className);

        if (property.array || property.type == RLMPropertyTypeLinkingObjects)
            keyPathContainsToManyRelationship = true;

        if (end != NSNotFound) {
            RLMPrecondition(property.type == RLMPropertyTypeObject || property.type == RLMPropertyTypeLinkingObjects,
                            @"Invalid value", @"Property '%@' is not a link in object of type '%@'",
                            propertyName, objectSchema.className);

            links.push_back(property);
            REALM_ASSERT(property.objectClassName);
            objectSchema = schema[property.objectClassName];
        }

        start = end + 1;
    } while (end != NSNotFound);

    return {std::move(links), property, keyPathContainsToManyRelationship};
}



struct Constant : eggs::variant<bool, int64_t, double, StringData, BinaryData, Timestamp, null>
{
    using Base = eggs::variant<bool, int64_t, double, StringData, BinaryData, Timestamp, null>;
    using Base::Base;

    explicit Constant(int64_t value) : Base(value) {}
};

struct ColumnPath {
    ColumnPath(std::vector<Property> path) : path(std::move(path))
    {
        REALM_ASSERT_DEBUG(!this->path.empty());
    }

    PropertyType type() const { return path.back().type; }

    std::vector<Property> path;
};

class AggregateOperation {
public:
    enum class Operator {
        Count,
        Sum,
        Min,
        Max,
        Average,
    };

    // FIXME: Aggregate operations can be performed on more than just columns (subqueries, for instance).
    // FIXME: Should this work with a generic Expression instead?
    AggregateOperation(ColumnPath path, Operator operator_, util::Optional<Property> property)
    : m_path(std::move(path))
    , m_operator(operator_)
    , m_property(std::move(property))
    {
        // FIXME: Property can be optional if the end of the key path is a primitive array?
        REALM_ASSERT_DEBUG(m_operator != Operator::Count ? bool(m_property) : !m_property);
    }

private:
    ColumnPath m_path;
    Operator m_operator;
    util::Optional<Property> m_property;
};

// FIXME: Subqueries?

struct Expression : eggs::variant<Constant, ColumnPath, AggregateOperation> {
    using Base = eggs::variant<Constant, ColumnPath, AggregateOperation>;
    using Base::Base;
};

struct Predicate;

class ComparisonPredicate {
public:
    enum class Operator {
        Equal,
        NotEqual,
        LessThan,
        LessThanOrEqual,
        GreaterThan,
        GreaterThanOrEqual,

        BeginsWith,
        Contains,
        EndsWith,
        Like,

        In,
        Between,
    };

    enum Options {
        None,
        CaseInsensitive,
        DiacriticInsensitive,
    };

    // FIXME: ANY vs ALL?

    Expression left;
    Expression right;
    Operator operator_;
    Options options;
};

class CompoundPredicate {
public:
    enum class Type {
        And,
        Or,
        Not,
    };

    CompoundPredicate(Type type, std::vector<std::unique_ptr<Predicate>> subpredicates)
    : subpredicates(std::move(subpredicates))
    , type(type)
    {
        REALM_ASSERT_DEBUG(this->type == Type::Not ? this->subpredicates.size() == 1 : true);
    }

    CompoundPredicate(const CompoundPredicate&);
    CompoundPredicate& operator=(const CompoundPredicate&);
    CompoundPredicate(CompoundPredicate&&) = default;
    CompoundPredicate& operator=(CompoundPredicate&&) = default;

    std::vector<std::unique_ptr<Predicate>> subpredicates;
    Type type;
};

struct ConstantPredicate {
    bool value;
};

struct Predicate : eggs::variant<ComparisonPredicate, CompoundPredicate, ConstantPredicate> {
    using Base = eggs::variant<ComparisonPredicate, CompoundPredicate, ConstantPredicate>;
    using Base::Base;
};

CompoundPredicate::CompoundPredicate(const CompoundPredicate& other)
: type(other.type)
{
    subpredicates.reserve(other.subpredicates.size());
    for (auto& predicate : other.subpredicates) {
        subpredicates.push_back(apply([](const auto& predicate){
            return std::make_unique<Predicate>(predicate);
        }, *predicate));
    }
}

CompoundPredicate& CompoundPredicate::operator=(const CompoundPredicate& other)
{
    CompoundPredicate copy(other);
    *this = std::move(copy);
    return *this;
}

ComparisonPredicate::Operator convert(NSPredicateOperatorType operatorType)
{
    using Operator = ComparisonPredicate::Operator;

    switch (operatorType) {
        case NSEqualToPredicateOperatorType:
            return Operator::Equal;
        case NSNotEqualToPredicateOperatorType:
            return Operator::NotEqual;
        case NSGreaterThanPredicateOperatorType:
            return Operator::GreaterThan;
        case NSGreaterThanOrEqualToPredicateOperatorType:
            return Operator::GreaterThanOrEqual;
        case NSLessThanPredicateOperatorType:
            return Operator::LessThan;
        case NSLessThanOrEqualToPredicateOperatorType:
            return Operator::LessThanOrEqual;

        case NSBeginsWithPredicateOperatorType:
            return Operator::BeginsWith;
        case NSContainsPredicateOperatorType:
            return Operator::Contains;
        case NSEndsWithPredicateOperatorType:
            return Operator::EndsWith;
        case NSLikePredicateOperatorType:
            return Operator::Like;

        case NSInPredicateOperatorType:
            return Operator::In;
        case NSBetweenPredicateOperatorType:
            return Operator::Between;

        case NSMatchesPredicateOperatorType:
        case NSCustomSelectorPredicateOperatorType:
            throw std::runtime_error("Unsupported operator type");
    }
}

ComparisonPredicate::Options convert(NSComparisonPredicateOptions options)
{
    using Options = ComparisonPredicate::Options;
    Options result = Options::None;

    if (options & NSCaseInsensitivePredicateOption)
        result = (Options)(result | Options::CaseInsensitive);
    if (options & NSDiacriticInsensitivePredicateOption)
        result = (Options)(result | Options::DiacriticInsensitive);

    if (options & (~NSCaseInsensitivePredicateOption & ~NSDiacriticInsensitivePredicateOption)) {
        NSLog(@"Unsupported predicate option: %zu", options);
        throw std::runtime_error("Unsupported predicate option");
    }

    return result;
}

CompoundPredicate::Type convert(NSCompoundPredicateType type)
{
    using Type = CompoundPredicate::Type;

    switch (type) {
        case NSNotPredicateType:
            return Type::Not;
        case NSAndPredicateType:
            return Type::And;
        case NSOrPredicateType:
            return Type::Or;
    }
}

template<typename F>
struct SubexpressionVisitor;

class QueryBuilder {
public:
    QueryBuilder(Query& query, RLMRealm *realm, RLMObjectSchema *objectSchema)
    : m_query(query), m_realm(realm), m_objectSchema(objectSchema) { }

    void apply_predicate(NSPredicate *predicate);

private:
    Expression convert(NSExpression *) const;
    Predicate convert(NSPredicate *) const;

    Query as_query(const Predicate&) const;
    Query as_query(const ComparisonPredicate&) const;
    Query as_query(const CompoundPredicate&) const;
    Query as_query(const ConstantPredicate&) const;

    Table& table() const
    {
        return *m_realm->_info[m_objectSchema.className].table();
    }

    template <typename F>
    auto subexpression_visitor(F&& function) const
    {
        return SubexpressionVisitor<F>{table(), std::forward<F>(function)};
    }

    Query& m_query;
    RLMRealm *m_realm;
    RLMObjectSchema *m_objectSchema;
};

Expression QueryBuilder::convert(NSExpression *expression) const
{
    switch (expression.expressionType) {
        case NSConstantValueExpressionType:
            if ([expression.constantValue isKindOfClass:[NSNumber class]]) {
                CFNumberRef number = (__bridge CFNumberRef)expression.constantValue;
                CFNumberType type = CFNumberGetType(number);
                if (type == kCFNumberFloat32Type || type == kCFNumberFloat64Type
                    || type == kCFNumberFloatType || type == kCFNumberCGFloatType) {
                    return Constant([expression.constantValue doubleValue]);
                }
                return Constant([expression.constantValue longLongValue]);
            }
            if ([expression.constantValue isKindOfClass:[NSString class]]) {
                return Constant(RLMStringDataWithNSString(expression.constantValue));
            }
            if ([expression.constantValue isKindOfClass:[NSDate class]]) {
                return Constant(RLMTimestampForNSDate(expression.constantValue));
            }
            throw std::runtime_error("Unsupported expression");

        case NSKeyPathExpressionType: {
            auto keyPath = key_path_from_string(m_realm.schema, m_objectSchema, expression.keyPath);
            std::vector<Property> path;
            path.reserve(keyPath.links.size() + 1);

            auto currentClassInfo = &m_realm->_info[m_objectSchema.className];
            for (RLMProperty *link : keyPath.links) {
                path.push_back(link.objectStoreCopy);
                if (link.type != RLMPropertyTypeLinkingObjects)
                    path.back().table_column = currentClassInfo->tableColumn(link);
                currentClassInfo = &currentClassInfo->linkTargetType(link.index);
            }

            path.push_back(keyPath.property.objectStoreCopy);
            path.back().table_column = currentClassInfo->tableColumn(keyPath.property);

            return ColumnPath(std::move(path));
        }
        default:
            NSLog(@"Unsupported expression: %@ (%zu)", expression, static_cast<size_t>(expression.expressionType));
            throw std::runtime_error("Unsupported expression");
    }
}

Predicate QueryBuilder::convert(NSPredicate *predicate) const
{
    if ([predicate isKindOfClass:[NSComparisonPredicate class]]) {
        NSComparisonPredicate *comparisonPredicate = (NSComparisonPredicate *)predicate;
        auto left = convert(comparisonPredicate.leftExpression);
        auto right = convert(comparisonPredicate.rightExpression);
        auto operator_ = ::convert(comparisonPredicate.predicateOperatorType);
        auto options = ::convert(comparisonPredicate.options);
        return ComparisonPredicate{left, right, operator_, options};
    }
    if ([predicate isKindOfClass:[NSCompoundPredicate class]]) {
        NSCompoundPredicate *compoundPredicate = (NSCompoundPredicate *)predicate;
        if (compoundPredicate.subpredicates.count == 0) {
            switch (compoundPredicate.compoundPredicateType) {
                case NSAndPredicateType:
                    // NSCompoundPredicate's documentation states that an AND predicate with no subpredicates evaluates to TRUE.
                    return ConstantPredicate{true};
                case NSOrPredicateType:
                    // NSCompoundPredicate's documentation states that an OR predicate with no subpredicates evaluates to FALSE.
                    return ConstantPredicate{false};
                case NSNotPredicateType:
                    throw std::runtime_error("FIXME: What should this do?");
            }
        }

        std::vector<std::unique_ptr<Predicate>> subpredicates;
        subpredicates.reserve(compoundPredicate.subpredicates.count);
        for (NSPredicate *subpredicate in compoundPredicate.subpredicates) {
            subpredicates.push_back(std::make_unique<Predicate>(convert(subpredicate)));
        }
        auto type = ::convert(compoundPredicate.compoundPredicateType);
        return CompoundPredicate(type, std::move(subpredicates));
    }
    if ([predicate isEqual:[NSPredicate predicateWithValue:YES]]) {
        return ConstantPredicate{true};
    }
    if ([predicate isEqual:[NSPredicate predicateWithValue:NO]]) {
        return ConstantPredicate{false};
    }
    NSLog(@"Unsupported predicate: %@", predicate);
    throw std::runtime_error("Unsupported predicate");
}

Query QueryBuilder::as_query(const Predicate& predicate) const
{
    return apply([&](auto&& predicate) {
        return as_query(predicate);
    }, predicate);
}

template <typename F>
auto visit_property_type(F&& function, PropertyType type)
{
    if (is_array(type)) {
        // FIXME: Arrrrrays.
        throw std::runtime_error("Unsupported property type");
        return Query();
    }

    switch (type) {
        case PropertyType::Int:
            return function(Int{});
        case PropertyType::Bool:
            return function(bool{});
        case PropertyType::String:
            return function(StringData{});
        case PropertyType::Data:
            return function(BinaryData{});
        case PropertyType::Date:
            return function(Timestamp{});
        case PropertyType::Float:
            return function(float{});
        case PropertyType::Double:
            return function(double{});
        case PropertyType::Object:
        case PropertyType::LinkingObjects:
            throw std::runtime_error("Unsupported property type");
            return Query();

        case PropertyType::Any:
        case PropertyType::Indexed:
        case PropertyType::Nullable:
        case PropertyType::Array:
        case PropertyType::Flags:
            throw std::runtime_error("Unsupported property type");
            return Query();
    }
}


template <typename F>
struct SubexpressionVisitor {
    auto operator()(const Constant& value) -> Query
    {
        return apply(function, value);
    }

    auto operator()(const ColumnPath& column) -> Query
    {
        return visit_property_type([&](auto type) {
            for (auto it = column.path.begin(); it != std::prev(column.path.end()); ++it) {
                auto& prop = *it;
                if (prop.type == PropertyType::LinkingObjects)
                    throw std::runtime_error("Unsupported column reference");
                table.link(prop.table_column);
            }

            return function(table.column<decltype(type)>(column.path.back().table_column));
        }, column.type());
    }

    auto operator()(const AggregateOperation&) -> Query
    {
        throw std::runtime_error("Unsupported subexpression type");
    }

    Table& table;
    F function;
};


template <typename Derived>
struct BaseVisitComparison {
    // FIXME: Add an overload for when both arguments are constants and map that to `TrueExpression` / `FalseExpression`?

    template <typename T, typename... Args>
    using result_of_call_member = decltype(T::call(std::declval<Args>()...));

    template <typename... Args>
    Query operator()(Args&&... args) const
    {
        using call_result_type = detected_t<result_of_call_member, Derived, Args...>;
        using is_query = std::integral_constant<bool, std::is_same<Query, call_result_type>::value>;
        return call(is_query(), std::forward<Args>(args)...);
    }

    template <typename... Args>
    auto call(std::true_type,  Args&&... args) const
    {
        return Derived::call(std::forward<Args>(args)...);
    }

    template <typename L, typename R, typename... Args>
    Query call(std::false_type, L&&, R&&, Args&&...) const
    {
        @throw RLMPredicateException(@"Unsupported comparison",
                                     @"Unsupported %s comparison between %s and %s", static_cast<const Derived&>(*this).name(),
                                     typeid(L).name(), typeid(R).name());
    }
};

struct DiacriticInsensitiveTag {};

template <typename Comparator, typename L, typename R>
auto diacritic_insensitive_comparison(L&& left, R&& right, bool case_sensitive)
    // FIXME: This decltype isn't accurate. It should really use an operation that matches Comparator.
    -> decltype(std::forward<L>(left).equal(std::forward<R>(right), case_sensitive))
{
    auto as_subexpr = overload([](StringData value) { return make_subexpr<ConstantStringValue>(value); },
                               [](const Columns<String>& c) { return c.clone(); });

    using CompareCS = Compare<typename Comparator::CaseSensitive, StringData>;
    using CompareCI = Compare<typename Comparator::CaseInsensitive, StringData>;
    if (case_sensitive)
        return make_expression<CompareCS>(as_subexpr(left), as_subexpr(right));
    else
        return make_expression<CompareCI>(as_subexpr(left), as_subexpr(right));
}

struct VisitEqual : BaseVisitComparison<VisitEqual> {
    template <typename L, typename R>
    static auto call(L&& left, R&& right) -> decltype(std::forward<L>(left) == std::forward<R>(right))
    {
        return std::forward<L>(left) == std::forward<R>(right);
    }

    template <typename L, typename R>
    static auto call(L&& left, R&& right, bool case_sensitive)
        -> decltype(std::forward<L>(left).equal(std::forward<R>(right), case_sensitive))
    {
        return std::forward<L>(left).equal(std::forward<R>(right), case_sensitive);
    }

    template <typename L, typename R>
    static auto call(L&& left, R&& right, DiacriticInsensitiveTag, bool case_sensitive)
        -> decltype(diacritic_insensitive_comparison<Equal<kCFCompareDiacriticInsensitive>>(std::forward<L>(left), std::forward<R>(right), case_sensitive))
    {
        return diacritic_insensitive_comparison<Equal<kCFCompareDiacriticInsensitive>>(std::forward<L>(left), std::forward<R>(right), case_sensitive);
    }

    const char* name() const { return "=="; }
};

static_assert(std::is_same<Query, detected_t<VisitEqual::result_of_call_member, VisitEqual, Columns<String>, String>>::value, "Can compare Columns<String> and String");

struct VisitNotEqual : BaseVisitComparison<VisitNotEqual> {
    template <typename L, typename R>
    static auto call(L&& left, R&& right) -> decltype(std::forward<L>(left) != std::forward<R>(right))
    {
        return std::forward<L>(left) != std::forward<R>(right);
    }

    template <typename L, typename R>
    static auto call(L&& left, R&& right, bool case_sensitive) -> decltype(std::forward<L>(left).not_equal(std::forward<R>(right), case_sensitive))
    {
        return std::forward<L>(left).not_equal(std::forward<R>(right), case_sensitive);
    }

    template <typename L, typename R>
    static auto call(L&& left, R&& right, DiacriticInsensitiveTag, bool case_sensitive)
        -> decltype(VisitEqual::call(std::forward<L>(left), std::forward<R>(right), DiacriticInsensitiveTag{}, case_sensitive))
    {
        return !VisitEqual::call(std::forward<L>(left), std::forward<R>(right), DiacriticInsensitiveTag{}, case_sensitive);
    }

    const char* name() const { return "!="; }
};

struct VisitLessThan : BaseVisitComparison<VisitLessThan> {
    template <typename L, typename R>
    static auto call(L&& left, R&& right) -> decltype(std::forward<L>(left) < std::forward<R>(right))
    {
        return std::forward<L>(left) < std::forward<R>(right);
    }

    const char* name() const { return "<"; }
};

struct VisitLessThanOrEqual : BaseVisitComparison<VisitLessThanOrEqual> {
    template <typename L, typename R>
    static auto call(L&& left, R&& right) -> decltype(std::forward<L>(left) <= std::forward<R>(right))
    {
        return std::forward<L>(left) <= std::forward<R>(right);
    }

    const char* name() const { return "<="; }
};

struct VisitGreaterThan : BaseVisitComparison<VisitGreaterThan> {
    template <typename L, typename R>
    static auto call(L&& left, R&& right) -> decltype(std::forward<L>(left) > std::forward<R>(right))
    {
        return std::forward<L>(left) > std::forward<R>(right);
    }

    const char* name() const { return ">"; }
};

struct VisitGreaterThanOrEqual : BaseVisitComparison<VisitGreaterThanOrEqual> {
    template <typename L, typename R>
    static auto call(L&& left, R&& right) -> decltype(std::forward<L>(left) >= std::forward<R>(right))
    {
        return std::forward<L>(left) >= std::forward<R>(right);
    }

    const char* name() const { return ">="; }
};

struct VisitBeginsWith : BaseVisitComparison<VisitBeginsWith> {
    template <typename L, typename R>
    static auto call(L&& left, R&& right, bool case_sensitive=true) -> decltype(std::forward<L>(left).begins_with(std::forward<R>(right), case_sensitive))
    {
        return std::forward<L>(left).begins_with(std::forward<R>(right), case_sensitive);
    }

    template <typename L, typename R>
    static auto call(L&& left, R&& right, DiacriticInsensitiveTag, bool case_sensitive)
        -> decltype(diacritic_insensitive_comparison<ContainsSubstring<kCFCompareDiacriticInsensitive | kCFCompareAnchored>>(std::forward<L>(left), std::forward<R>(right), case_sensitive))
    {
        return diacritic_insensitive_comparison<ContainsSubstring<kCFCompareDiacriticInsensitive | kCFCompareAnchored>>(std::forward<L>(left), std::forward<R>(right), case_sensitive);
    }

    const char* name() const { return "begins with"; }
};

struct VisitContains : BaseVisitComparison<VisitContains> {
    template <typename L, typename R>
    static auto call(L&& left, R&& right, bool case_sensitive=true) -> decltype(std::forward<L>(left).contains(std::forward<R>(right), case_sensitive))
    {
        return std::forward<L>(left).contains(std::forward<R>(right), case_sensitive);
    }

    template <typename L, typename R>
    static auto call(L&& left, R&& right, DiacriticInsensitiveTag, bool case_sensitive)
        -> decltype(diacritic_insensitive_comparison<ContainsSubstring<kCFCompareDiacriticInsensitive>>(std::forward<L>(left), std::forward<R>(right), case_sensitive))
    {
        return diacritic_insensitive_comparison<ContainsSubstring<kCFCompareDiacriticInsensitive>>(std::forward<L>(left), std::forward<R>(right), case_sensitive);
    }

    const char* name() const { return "contains"; }
};

struct VisitEndsWith : BaseVisitComparison<VisitEndsWith> {
    template <typename L, typename R>
    static auto call(L&& left, R&& right, bool case_sensitive=true) -> decltype(std::forward<L>(left).ends_with(std::forward<R>(right), case_sensitive))
    {
        return std::forward<L>(left).ends_with(std::forward<R>(right), case_sensitive);
    }

    template <typename L, typename R>
    static auto call(L&& left, R&& right, DiacriticInsensitiveTag, bool case_sensitive)
        -> decltype(diacritic_insensitive_comparison<ContainsSubstring<kCFCompareDiacriticInsensitive | kCFCompareAnchored | kCFCompareBackwards>>(std::forward<L>(left), std::forward<R>(right), case_sensitive))
    {
        return diacritic_insensitive_comparison<ContainsSubstring<kCFCompareDiacriticInsensitive | kCFCompareAnchored | kCFCompareBackwards>>(std::forward<L>(left), std::forward<R>(right), case_sensitive);
    }

    const char* name() const { return "ends with"; }
};

struct VisitLike : BaseVisitComparison<VisitLike> {
    template <typename L, typename R>
    static auto call(L&& left, R&& right, bool case_sensitive=true) -> decltype(std::forward<L>(left).like(std::forward<R>(right), case_sensitive))
    {
        return std::forward<L>(left).like(std::forward<R>(right), case_sensitive);
    }

    template <typename L, typename R>
    static auto call(L&& left, R&& right, DiacriticInsensitiveTag, bool case_sensitive) -> decltype(std::forward<L>(left).like(std::forward<R>(right), case_sensitive))
    {
        @throw RLMPredicateException(@"Invalid operator type",
                                     @"Operator 'LIKE' not supported with diacritic-insensitive modifier.");
    }

    const char* name() const { return "like"; }
};

struct VisitUnsupported {
    template <typename... Args>
    Query operator()(Args&&...) const
    {
        throw std::runtime_error("Unsupported operator type");
    }
};


template <typename F>
auto visit_comparison_operator(F&& function, ComparisonPredicate::Operator operator_)
{
    using Operator = ComparisonPredicate::Operator;
    switch (operator_) {
        case Operator::Equal:
            return function(VisitEqual());
        case Operator::NotEqual:
            return function(VisitNotEqual());
        case Operator::LessThan:
            return function(VisitLessThan());
        case Operator::LessThanOrEqual:
            return function(VisitLessThanOrEqual());
        case Operator::GreaterThan:
            return function(VisitGreaterThan());
        case Operator::GreaterThanOrEqual:
            return function(VisitGreaterThanOrEqual());

        case Operator::BeginsWith:
            return function(VisitBeginsWith());
        case Operator::Contains:
            return function(VisitContains());
        case Operator::EndsWith:
            return function(VisitEndsWith());
        case Operator::Like:
            return function(VisitLike());

        case Operator::In:
            return function(VisitUnsupported());
        case Operator::Between:
            return function(VisitUnsupported());
    }
}

template <typename T> T& unwrap_unique_ptr(std::unique_ptr<T>& pointer) { return *pointer; }
template <typename T> T& unwrap_unique_ptr(T& value) { return value; }

Query QueryBuilder::as_query(const ComparisonPredicate& comparison) const
{
    return apply(subexpression_visitor([&](auto&& left) {
        return apply(subexpression_visitor([&](auto&& right) {
            return visit_comparison_operator([&](auto op) {
                using Options = ComparisonPredicate::Options;

                if (comparison.options & Options::DiacriticInsensitive)
                    return op(left, right, DiacriticInsensitiveTag{}, !(comparison.options & Options::CaseInsensitive));

                if (comparison.options == ComparisonPredicate::Options::CaseInsensitive)
                    return op(left, right, false);

                return op(left, right);
            }, comparison.operator_);
        }), comparison.right);
    }), comparison.left);
}

Query QueryBuilder::as_query(const CompoundPredicate& predicate) const
{
    Query query = table().where();
    if (predicate.type == CompoundPredicate::Type::Not)
        query.Not();

    auto& subpredicates = predicate.subpredicates;
    for (auto it = subpredicates.begin(); it != subpredicates.end(); ++it) {
        if (predicate.type == CompoundPredicate::Type::Or && it != subpredicates.begin())
            query.Or();
        query.and_query(as_query(**it));
    }

    return query;
}

Query QueryBuilder::as_query(const ConstantPredicate& predicate) const
{
    if (predicate.value)
        return std::unique_ptr<realm::Expression>(new TrueExpression);
    else
        return std::unique_ptr<realm::Expression>(new FalseExpression);
}

void QueryBuilder::apply_predicate(NSPredicate *nspredicate)
{
    auto predicate = convert(nspredicate);
    m_query.and_query(as_query(predicate));
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
                                 RLMRealm *realm)
{
    auto query = get_table(realm.group, objectSchema).where();

    // passing a nil predicate is a no-op
    if (!predicate) {
        return query;
    }

    @autoreleasepool {
        QueryBuilder(query, realm, objectSchema).apply_predicate(predicate);
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
