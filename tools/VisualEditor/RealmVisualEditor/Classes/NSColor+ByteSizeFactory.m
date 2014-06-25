//
//  NSColor+ByteSizeFactory.m
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 25/06/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "NSColor+ByteSizeFactory.h"

@implementation NSColor (ByteSizeFactory)

+ (NSColor *)colorWithByteRed:(NSUInteger)red green:(NSUInteger)green blue:(NSUInteger)blue alpha:(NSUInteger)alpha
{
    return [NSColor colorWithRed:(CGFloat)red/255.0f
                           green:(CGFloat)green/255.0f
                            blue:(CGFloat)blue/255.0f
                           alpha:(CGFloat)alpha/255.0f];
}

+ (NSColor *)colorWithByteWhite:(NSUInteger)white alpha:(NSUInteger)alpha
{
    return [NSColor colorWithWhite:(CGFloat)white/255.0f
                             alpha:(CGFloat)alpha/255.0f];
}

@end
