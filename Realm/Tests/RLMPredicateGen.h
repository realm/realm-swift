//
//  RLMPredicateGen.h
//  Realm
//
//  Created by Oleksandr Shturmov on 22/06/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RLMPredicateGen : NSObject

+ (NSPredicate *) comparisonWithKeyPath: (NSString *)keyPath
                             expression: (NSExpression *)expression
                                   type: (NSPredicateOperatorType) type;

+ (NSPredicate *) comparisonWithKeyPath: (NSString *)keyPath
                             expression: (NSExpression *)expression
                                   type: (NSPredicateOperatorType) type
                                options: (NSComparisonPredicateOptions) options;

+ (NSPredicate *) comparisonWithKeyPath: (NSString *)keyPath
                             expression: (NSExpression *)expression
                                   type: (NSPredicateOperatorType) type
                                options: (NSComparisonPredicateOptions) options
                               modifier: (NSComparisonPredicateModifier) modifier;

@end
