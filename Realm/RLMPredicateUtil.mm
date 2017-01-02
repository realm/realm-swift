////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

#import "RLMPredicateUtil.hpp"

#include <realm/util/assert.hpp>

// NSConditionalExpressionType is new in OS X 10.11 and iOS 9.0
#if defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
#define CONDITIONAL_EXPRESSION_DECLARED (__MAC_OS_X_VERSION_MIN_REQUIRED >= 101100)
#elif defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
#define CONDITIONAL_EXPRESSION_DECLARED (__IPHONE_OS_VERSION_MIN_REQUIRED >= 90000)
#else
#define CONDITIONAL_EXPRESSION_DECLARED 0
#endif

#if !CONDITIONAL_EXPRESSION_DECLARED

#define NSConditionalExpressionType 20

@interface NSExpression (NewIn1011And90)
+ (NSExpression *)expressionForConditional:(NSPredicate *)predicate trueExpression:(NSExpression *)trueExpression falseExpression:(NSExpression *)falseExpression;
- (NSExpression *)trueExpression;
- (NSExpression *)falseExpression;
@end

#endif

namespace {

struct PredicateExpressionTransformer {
    PredicateExpressionTransformer(ExpressionVisitor visitor) : m_visitor(visitor) { }

    NSExpression *visit(NSExpression *expression) const;
    NSPredicate *visit(NSPredicate *predicate) const;

    ExpressionVisitor m_visitor;
};

NSExpression *PredicateExpressionTransformer::visit(NSExpression *expression) const {
    expression = m_visitor(expression);

    switch (expression.expressionType) {
        case NSFunctionExpressionType: {
            NSMutableArray *arguments = [NSMutableArray array];
            for (NSExpression *argument in expression.arguments) {
                [arguments addObject:visit(argument)];
            }
            if (expression.operand) {
                return [NSExpression expressionForFunction:visit(expression.operand) selectorName:expression.function arguments:arguments];
            } else {
                return [NSExpression expressionForFunction:expression.function arguments:arguments];
            }
        }

        case NSUnionSetExpressionType:
            return [NSExpression expressionForUnionSet:visit(expression.leftExpression) with:visit(expression.rightExpression)];
        case NSIntersectSetExpressionType:
            return [NSExpression expressionForIntersectSet:visit(expression.leftExpression) with:visit(expression.rightExpression)];
        case NSMinusSetExpressionType:
            return [NSExpression expressionForMinusSet:visit(expression.leftExpression) with:visit(expression.rightExpression)];

        case NSSubqueryExpressionType: {
            NSExpression *collection = expression.collection;
            // NSExpression.collection is declared as id, but appears to always hold an NSExpression for subqueries.
            REALM_ASSERT([collection isKindOfClass:[NSExpression class]]);
            return [NSExpression expressionForSubquery:visit(collection) usingIteratorVariable:expression.variable predicate:visit(expression.predicate)];
        }

        case NSAggregateExpressionType: {
            NSMutableArray *subexpressions = [NSMutableArray array];
            for (NSExpression *subexpression in expression.collection) {
                [subexpressions addObject:visit(subexpression)];
            }
            return [NSExpression expressionForAggregate:subexpressions];
        }

        case NSConditionalExpressionType:
            return [NSExpression expressionForConditional:visit(expression.predicate) trueExpression:visit(expression.trueExpression) falseExpression:visit(expression.falseExpression)];

        default:
            // The remaining expression types do not contain nested expressions or predicates.
            return expression;
    }
}

NSPredicate *PredicateExpressionTransformer::visit(NSPredicate *predicate) const {
    if ([predicate isKindOfClass:[NSCompoundPredicate class]]) {
        NSCompoundPredicate *compoundPredicate = (NSCompoundPredicate *)predicate;
        NSMutableArray *subpredicates = [NSMutableArray array];
        for (NSPredicate *subpredicate in compoundPredicate.subpredicates) {
            [subpredicates addObject:visit(subpredicate)];
        }
        return [[NSCompoundPredicate alloc] initWithType:compoundPredicate.compoundPredicateType subpredicates:subpredicates];
    }
    if ([predicate isKindOfClass:[NSComparisonPredicate class]]) {
        NSComparisonPredicate *comparisonPredicate = (NSComparisonPredicate *)predicate;
        NSExpression *leftExpression = visit(comparisonPredicate.leftExpression);
        NSExpression *rightExpression = visit(comparisonPredicate.rightExpression);
        return [NSComparisonPredicate predicateWithLeftExpression:leftExpression rightExpression:rightExpression modifier:comparisonPredicate.comparisonPredicateModifier type:comparisonPredicate.predicateOperatorType options:comparisonPredicate.options];
    }
    return predicate;
}

} // anonymous namespace

NSPredicate *transformPredicate(NSPredicate *predicate, ExpressionVisitor visitor) {
    PredicateExpressionTransformer transformer(visitor);
    return transformer.visit(predicate);
}
