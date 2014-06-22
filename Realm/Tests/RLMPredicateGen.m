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

#import "RLMPredicateGen.h"

@implementation RLMPredicateGen

+ (NSPredicate *) comparisonWithKeyPath: (NSString *)keyPath
                             expression: (NSExpression *)expression
                                   type: (NSPredicateOperatorType) type
{
    return [RLMPredicateGen comparisonWithKeyPath: keyPath
                                       expression: expression
                                             type: type
                                          options: 0];
}

+ (NSPredicate *) comparisonWithKeyPath: (NSString *)keyPath
                             expression: (NSExpression *)expression
                                   type: (NSPredicateOperatorType) type
                                options: (NSComparisonPredicateOptions) options
{
    return [RLMPredicateGen comparisonWithKeyPath: keyPath
                                       expression: expression
                                             type: type
                                          options: options
                                         modifier: NSDirectPredicateModifier];
}

+ (NSPredicate *) comparisonWithKeyPath: (NSString *)keyPath
                             expression: (NSExpression *)expression
                                   type: (NSPredicateOperatorType) type
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

@end
