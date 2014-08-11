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

#import "RLMTestObjects.h"
#import "RLMTestCase.h"
#import "RLMPredicateUtil.h"

@implementation RLMPredicateUtil

const NSUInteger DEFAULT_COMPARISON_PREDICATE_OPERATOR_TYPE = NSLessThanPredicateOperatorType;
const NSUInteger DEFAULT_COMPARISON_PREDICATE_OPTIONS = 0;
const NSUInteger DEFAULT_COMPARISON_PREDICATE_MODIFIER = NSDirectPredicateModifier;

+ (NSPredicate *(^)(NSExpression *, NSExpression *)) defaultPredicateGenerator
{
    return ^(NSExpression *leftExpression, NSExpression *rightExpression) {
        return [NSComparisonPredicate
                predicateWithLeftExpression: leftExpression
                rightExpression: rightExpression
                modifier: DEFAULT_COMPARISON_PREDICATE_MODIFIER
                type: DEFAULT_COMPARISON_PREDICATE_OPERATOR_TYPE
                options: DEFAULT_COMPARISON_PREDICATE_OPTIONS];
    };
}

+ (NSPredicate *) comparisonWithKeyPath: (NSString *)keyPath
                             expression: (NSExpression *)expression
                           operatorType: (NSPredicateOperatorType) type
{
    return [RLMPredicateUtil comparisonWithKeyPath: keyPath
                                        expression: expression
                                      operatorType: type
                                           options: DEFAULT_COMPARISON_PREDICATE_OPTIONS];
}

+ (NSPredicate *) comparisonWithKeyPath: (NSString *)keyPath
                             expression: (NSExpression *)expression
                           operatorType: (NSPredicateOperatorType) type
                                options: (NSComparisonPredicateOptions) options
{
    return [RLMPredicateUtil comparisonWithKeyPath: keyPath
                                        expression: expression
                                      operatorType: type
                                           options: options
                                          modifier: DEFAULT_COMPARISON_PREDICATE_MODIFIER];
}

+ (NSPredicate *) comparisonWithKeyPath: (NSString *)keyPath
                             expression: (NSExpression *)expression
                           operatorType: (NSPredicateOperatorType) type
                                options: (NSComparisonPredicateOptions) options
                               modifier: (NSComparisonPredicateModifier) modifier
{
    NSExpression *left = [NSExpression expressionForKeyPath:keyPath];
    NSExpression *right = expression;

    return [NSComparisonPredicate predicateWithLeftExpression: left
                                              rightExpression: right
                                                     modifier: modifier
                                                         type: type
                                                      options: options];
}

+ (NSPredicate *) comparisonWithKeyPath: (NSString *)keyPath
                             expression: (NSExpression *)expression
                               selector: (SEL)selector
{
    NSExpression *left = [NSExpression expressionForKeyPath:keyPath];
    NSExpression *right = expression;

    return [NSComparisonPredicate predicateWithLeftExpression: left
                                              rightExpression: right
                                               customSelector: selector];
}

+ (BOOL) isEmptyIntColWithPredicate:(NSPredicate *)predicate
{
    return [IntObject objectsWithPredicate:predicate].count == 0;
}

+ (BOOL) isEmptyFloatColWithPredicate:(NSPredicate *)predicate
{
    return [FloatObject objectsWithPredicate:predicate].count == 0;
}

+ (BOOL) isEmptyDoubleColWithPredicate:(NSPredicate *)predicate
{
    return [DoubleObject objectsWithPredicate:predicate].count == 0;
}

+ (BOOL) isEmptyDateColWithPredicate:(NSPredicate *)predicate
{
    return [DateObject objectsWithPredicate:predicate].count == 0;
}

+ (BOOL(^)(NSPredicateOperatorType)) isEmptyIntColPredicate
{
    NSExpression *expression = [NSExpression expressionForConstantValue: @0];

    return ^BOOL(NSPredicateOperatorType operatorType) {
        NSPredicate *predicate = [RLMPredicateUtil comparisonWithKeyPath: @"intCol"
                                                               expression: expression
                                                             operatorType: operatorType];
        return [RLMPredicateUtil isEmptyIntColWithPredicate:predicate];
    };
}

+ (BOOL(^)(NSPredicateOperatorType)) isEmptyFloatColPredicate
{
    NSExpression *expression = [NSExpression expressionForConstantValue: @0.0f];

    return ^BOOL(NSPredicateOperatorType operatorType) {
        NSPredicate *predicate = [RLMPredicateUtil comparisonWithKeyPath: @"floatCol"
                                                               expression: expression
                                                             operatorType: operatorType];
        return [RLMPredicateUtil isEmptyFloatColWithPredicate:predicate];
    };
}

+ (BOOL(^)(NSPredicateOperatorType)) isEmptyDoubleColPredicate
{
    NSExpression *expression = [NSExpression expressionForConstantValue: @0.0];

    return ^BOOL(NSPredicateOperatorType operatorType) {
        NSPredicate *predicate = [RLMPredicateUtil comparisonWithKeyPath: @"doubleCol"
                                                               expression: expression
                                                             operatorType: operatorType];
        return [RLMPredicateUtil isEmptyDoubleColWithPredicate:predicate];
    };
}

+ (BOOL(^)(NSPredicateOperatorType)) isEmptyDateColPredicate
{
    NSExpression *expression = [NSExpression expressionForConstantValue:
                                [NSDate dateWithTimeIntervalSinceNow:0]];

    return ^BOOL(NSPredicateOperatorType operatorType) {
        NSPredicate *predicate = [RLMPredicateUtil comparisonWithKeyPath: @"dateCol"
                                                               expression: expression
                                                             operatorType: operatorType];
        return [RLMPredicateUtil isEmptyDateColWithPredicate:predicate];
    };
}

+ (BOOL)alwaysFalse: (id) value
{
    return value == nil ? NO : NO;
};

+ (BOOL(^)()) alwaysEmptyIntColSelectorPredicate
{
    NSExpression *expression = [NSExpression expressionForConstantValue: @0];

    NSPredicate *predicate = [RLMPredicateUtil comparisonWithKeyPath: @"intCol"
                                                           expression: expression
                                                             selector: @selector(alwaysFalse:)];
    return ^BOOL() {
        return [RLMPredicateUtil isEmptyIntColWithPredicate:predicate];
    };
}

+ (BOOL(^)()) alwaysEmptyFloatColSelectorPredicate
{
    NSExpression *expression = [NSExpression expressionForConstantValue: @0.0f];

    NSPredicate *predicate = [RLMPredicateUtil comparisonWithKeyPath: @"floatCol"
                                                           expression: expression
                                                             selector: @selector(alwaysFalse:)];
    return ^BOOL() {
        return [RLMPredicateUtil isEmptyFloatColWithPredicate:predicate];
    };
}

+ (BOOL(^)()) alwaysEmptyDoubleColSelectorPredicate
{
    NSExpression *expression = [NSExpression expressionForConstantValue: @0.0];

    NSPredicate *predicate = [RLMPredicateUtil comparisonWithKeyPath: @"doubleCol"
                                                           expression: expression
                                                             selector: @selector(alwaysFalse:)];
    return ^BOOL() {
        return [RLMPredicateUtil isEmptyDoubleColWithPredicate:predicate];
    };
}

+ (BOOL(^)()) alwaysEmptyDateColSelectorPredicate
{
    NSExpression *expression = [NSExpression expressionForConstantValue:
                                [NSDate dateWithTimeIntervalSinceNow:0]];

    NSPredicate *predicate = [RLMPredicateUtil comparisonWithKeyPath: @"dateCol"
                                                           expression: expression
                                                             selector: @selector(alwaysFalse:)];
    return ^BOOL() {
        return [RLMPredicateUtil isEmptyDateColWithPredicate:predicate];
    };
}

+ (NSString *) predicateOperatorTypeString: (NSPredicateOperatorType) operatorType
{
    switch (operatorType) {
        case NSLessThanPredicateOperatorType:
            return @"<";
        case NSLessThanOrEqualToPredicateOperatorType:
            return @"<= or =<";
        case NSGreaterThanPredicateOperatorType:
            return @">";
        case NSGreaterThanOrEqualToPredicateOperatorType:
            return @">= or =>";
        case NSEqualToPredicateOperatorType:
            return @"= or ==";
        case NSNotEqualToPredicateOperatorType:
            return @"<> or !=";
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
        case NSCustomSelectorPredicateOperatorType:
            return @"@selector()";
        case NSContainsPredicateOperatorType:
            return @"CONTAINS";
        case NSBetweenPredicateOperatorType:
            return @"BETWEEN";
    }
}

@end
