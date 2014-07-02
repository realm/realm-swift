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

+ (NSPredicate *) comparisonWithKeyPath: (NSString *)keyPath
                             expression: (NSExpression *)expression
                           operatorType: (NSPredicateOperatorType) type
{
    return [RLMPredicateUtil comparisonWithKeyPath: keyPath
                                        expression: expression
                                      operatorType: type
                                           options: 0];
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
                                          modifier: NSDirectPredicateModifier];
}

+ (NSPredicate *) comparisonWithKeyPath: (NSString *)keyPath
                             expression: (NSExpression *)expression
                           operatorType: (NSPredicateOperatorType) type
                                options: (NSComparisonPredicateOptions) options
                               modifier: (NSComparisonPredicateModifier) modifier
{
    return
    [NSComparisonPredicate predicateWithLeftExpression: [NSExpression expressionForKeyPath:keyPath]
                                       rightExpression: expression
                                              modifier: modifier
                                                  type: type
                                               options: options];
}

+ (NSPredicate *) comparisonWithKeyPath: (NSString *)keyPath
                             expression: (NSExpression *)expression
                               selector: (SEL)selector
{
    return
    [NSComparisonPredicate predicateWithLeftExpression: [NSExpression expressionForKeyPath: keyPath]
                                       rightExpression: expression
                                        customSelector: selector];
}

+ (BOOL(^)(NSPredicateOperatorType)) isEmptyIntColPredicate
{
    NSExpression *expression = [NSExpression expressionForConstantValue: @0];

    return ^BOOL(NSPredicateOperatorType operatorType) {
        NSPredicate * predicate = [RLMPredicateUtil comparisonWithKeyPath: @"intCol"
                                                               expression: expression
                                                             operatorType: operatorType];
        return [IntObject objectsWithPredicate:predicate].count == 0 ? YES : NO;
    };
}

+ (BOOL(^)(NSPredicateOperatorType)) isEmptyFloatColPredicate
{
    NSExpression *expression = [NSExpression expressionForConstantValue: @0.0f];

    return ^BOOL(NSPredicateOperatorType operatorType) {
        NSPredicate * predicate = [RLMPredicateUtil comparisonWithKeyPath: @"floatCol"
                                                               expression: expression
                                                             operatorType: operatorType];
        return [FloatObject objectsWithPredicate:predicate].count == 0 ? YES : NO;
    };
}

+ (BOOL(^)(NSPredicateOperatorType)) isEmptyDoubleColPredicate
{
    NSExpression *expression = [NSExpression expressionForConstantValue: @0.0];

    return ^BOOL(NSPredicateOperatorType operatorType) {
        NSPredicate * predicate = [RLMPredicateUtil comparisonWithKeyPath: @"doubleCol"
                                                               expression: expression
                                                             operatorType: operatorType];
        return [DoubleObject objectsWithPredicate:predicate].count == 0 ? YES : NO;
    };
}

+ (BOOL)alwaysFalse: (id) value
{
    return value == nil ? NO : NO;
};

+ (BOOL(^)()) alwaysEmptyIntColSelectorPredicate
{
    NSExpression *expression = [NSExpression expressionForConstantValue: @0];

    NSPredicate * predicate = [RLMPredicateUtil comparisonWithKeyPath: @"intCol"
                                                           expression: expression
                                                             selector: @selector(alwaysFalse:)];
    return ^BOOL() {
        return [IntObject objectsWithPredicate: predicate].count == 0 ? YES : NO;
    };
}

+ (BOOL(^)()) alwaysEmptyFloatColSelectorPredicate
{
    NSExpression *expression = [NSExpression expressionForConstantValue: @0.0f];

    NSPredicate * predicate = [RLMPredicateUtil comparisonWithKeyPath: @"floatCol"
                                                           expression: expression
                                                             selector: @selector(alwaysFalse:)];
    return ^BOOL() {
        return [FloatObject objectsWithPredicate: predicate].count == 0 ? YES : NO;
    };
}

+ (BOOL(^)()) alwaysEmptyDoubleColSelectorPredicate
{
    NSExpression *expression = [NSExpression expressionForConstantValue: @0.0];

    NSPredicate * predicate = [RLMPredicateUtil comparisonWithKeyPath: @"doubleCol"
                                                           expression: expression
                                                             selector: @selector(alwaysFalse:)];
    return ^BOOL() {
        return [DoubleObject objectsWithPredicate: predicate].count == 0 ? YES : NO;
    };
}

@end