//
//  RLMPredicateGen.m
//  Realm
//
//  Created by Oleksandr Shturmov on 22/06/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

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
