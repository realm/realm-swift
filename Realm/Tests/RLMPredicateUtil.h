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

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

@interface RLMPredicateUtil : NSObject

+ (NSPredicate *(^)(NSExpression *, NSExpression *)) defaultPredicateGenerator;

+ (NSPredicate *) comparisonWithKeyPath: (NSString *)keyPath
                             expression: (NSExpression *)expression
                           operatorType: (NSPredicateOperatorType) type;

+ (NSPredicate *) comparisonWithKeyPath: (NSString *)keyPath
                             expression: (NSExpression *)expression
                           operatorType: (NSPredicateOperatorType) type
                                options: (NSComparisonPredicateOptions) options;

+ (NSPredicate *) comparisonWithKeyPath: (NSString *)keyPath
                             expression: (NSExpression *)expression
                           operatorType: (NSPredicateOperatorType) type
                                options: (NSComparisonPredicateOptions) options
                               modifier: (NSComparisonPredicateModifier) modifier;

+ (NSPredicate *) comparisonWithKeyPath: (NSString *)keyPath
                             expression: (NSExpression *)expression
                               selector: (SEL)selector;

+ (BOOL) isEmptyIntColWithPredicate:(NSPredicate *)predicate;
+ (BOOL) isEmptyFloatColWithPredicate:(NSPredicate *)predicate;
+ (BOOL) isEmptyDoubleColWithPredicate:(NSPredicate *)predicate;
+ (BOOL) isEmptyDateColWithPredicate:(NSPredicate *)predicate;

+ (BOOL(^)(NSPredicateOperatorType)) isEmptyIntColPredicate;

+ (BOOL(^)(NSPredicateOperatorType)) isEmptyFloatColPredicate;

+ (BOOL(^)(NSPredicateOperatorType)) isEmptyDoubleColPredicate;

+ (BOOL(^)(NSPredicateOperatorType)) isEmptyDateColPredicate;

+ (BOOL(^)()) alwaysEmptyIntColSelectorPredicate;

+ (BOOL(^)()) alwaysEmptyFloatColSelectorPredicate;

+ (BOOL(^)()) alwaysEmptyDoubleColSelectorPredicate;

+ (BOOL(^)()) alwaysEmptyDateColSelectorPredicate;

+ (NSString *) predicateOperatorTypeString: (NSPredicateOperatorType) operatorType;

@end
