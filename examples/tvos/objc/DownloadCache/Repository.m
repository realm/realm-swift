//
//  Repository.m
//  RealmExamples
//
//  Created by Katsumi Kishikawa on 11/19/15.
//  Copyright © 2015 Realm. All rights reserved.
//

#import "Repository.h"

@implementation Repository

+ (NSString *)primaryKey {
    return @"identifier";
}

+ (NSArray<NSString *> *)requiredProperties {
    return @[@"identifier"];
}

@end
