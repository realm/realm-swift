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
/////////////////////////////////////////////////////////////////////////////

#import "NSColor+ByteSizeFactory.h"

@implementation NSColor (ByteSizeFactory)

+ (NSColor *)linkColor
{
    return [NSColor colorWithByteRed:52 green:94 blue:242 alpha:255];
}

+ (NSColor *)pinkColor
{
    return [NSColor colorWithByteRed:253 green:183 blue:186 alpha:255];
}

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
