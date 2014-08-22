//
//  NSFont+Standard.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 22/08/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "NSFont+Standard.h"

@implementation NSFont (Standard)

+(NSFont *)textFont
{
    return [NSFont fontWithName:@"Helvetica" size:14.0];
}

+(NSFont *)linkFont
{
    return [NSFont fontWithName:@"Helvetica-Bold" size:14.0];
}

@end
