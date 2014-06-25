//
//  NSColor+ByteSizeFactory.h
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 25/06/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor (ByteSizeFactory)

+ (NSColor *)colorWithByteRed:(NSUInteger)red green:(NSUInteger)green blue:(NSUInteger)blue alpha:(NSUInteger)alpha;

+ (NSColor *)colorWithByteWhite:(NSUInteger)white alpha:(NSUInteger)alpha;

@end
