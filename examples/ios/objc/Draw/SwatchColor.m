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

#import "SwatchColor.h"

@interface SwatchColor ()

@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) UIColor *color;

@end

@implementation SwatchColor

- (instancetype)initWithName:(NSString *)name color:(UIColor *)color
{
    if (self = [super init]) {
        _name = name;
        _color = color;
    }
    
    return self;
}

+ (instancetype)swatchColorForName:(NSString *)name
{
    if ([name isEqualToString:@"Charcoal"]) {
        return [SwatchColor blackSwatchColor];
    }
    else if ([name isEqualToString:@"Elephant"]) {
        return [SwatchColor graySwatchColor];
    }
    else if ([name isEqualToString:@"Dove"]) {
        return [SwatchColor redSwatchColor];
    }
    else if ([name isEqualToString:@"Ultramarine"]) {
        return [SwatchColor blueSwatchColor];
    }
    else if ([name isEqualToString:@"Indigo"]) {
        return [SwatchColor greenSwatchColor];
    }
    else if ([name isEqualToString:@"GrapeJelly"]) {
        return [SwatchColor lightGreenSwatchColor];
    }
    else if ([name isEqualToString:@"Mulberry"]) {
        return [SwatchColor lightBlueSwatchColor];
    }
    else if ([name isEqualToString:@"Flamingo"]) {
        return [SwatchColor brownSwatchColor];
    }
    else if ([name isEqualToString:@"SexySalmon"]) {
        return [SwatchColor orangeSwatchColor];
    }
    else if ([name isEqualToString:@"Peach"]) {
        return [SwatchColor yellowSwatchColor];
    }
    else if ([name isEqualToString:@"Melon"]) {
        return [SwatchColor realmSwatchColor];
    }
    
    return nil;
}

+ (NSArray *)allSwatchColors
{
    return @[[SwatchColor blackSwatchColor],
             [SwatchColor graySwatchColor],
             [SwatchColor redSwatchColor],
             [SwatchColor blueSwatchColor],
             [SwatchColor greenSwatchColor],
             [SwatchColor lightGreenSwatchColor],
             [SwatchColor lightBlueSwatchColor],
             [SwatchColor brownSwatchColor],
             [SwatchColor orangeSwatchColor],
             [SwatchColor yellowSwatchColor],
             [SwatchColor realmSwatchColor]];
}

+ (instancetype)blackSwatchColor
{
    // Charcoal
    return [[SwatchColor alloc] initWithName:@"Charcoal" color:[UIColor colorWithRed:28.0f/255.0f green:35.0f/255.0f blue:63.0f/255.0f alpha:1.0f]];
}

+ (instancetype)graySwatchColor
{
    // Elephant
    return [[SwatchColor alloc] initWithName:@"Elephant" color:[UIColor colorWithRed:154.0f/255.0f green:155.0f/255.0f blue:165.0f/255.0f alpha:1.0f]];
}

+ (instancetype)redSwatchColor
{
    // Dove
    return [[SwatchColor alloc] initWithName:@"Dove" color:[UIColor colorWithRed:235.0f/255.0f green:235.0f/255.0f blue:242.0f/255.0f alpha:1.0f]];
}

+ (instancetype)blueSwatchColor
{
    // Ultramarine
    return [[SwatchColor alloc] initWithName:@"Ultramarine" color:[UIColor colorWithRed:57.0f/255.0f green:71.0f/255.0f blue:127.0f/255.0f alpha:1.0f]];
}

+ (instancetype)greenSwatchColor
{
    // Indigo
    return [[SwatchColor alloc] initWithName:@"Indigo" color:[UIColor colorWithRed:89.0f/255.0f green:86.0f/255.0f blue:158.0f/255.0f alpha:1.0f]];
}

+ (instancetype)lightGreenSwatchColor
{
    // Grape Jelly
    return [[SwatchColor alloc] initWithName:@"GrapeJelly" color:[UIColor colorWithRed:154.0f/255.0f green:80.0f/255.0f blue:165.0f/255.0f alpha:1.0f]];
}

+ (instancetype)lightBlueSwatchColor
{
    // Mulberry
    return [[SwatchColor alloc] initWithName:@"Mulberry" color:[UIColor colorWithRed:211.0f/255.0f green:76.0f/255.0f blue:163.0f/255.0f alpha:1.0f]];
}

+ (instancetype)brownSwatchColor
{
    // Flamingo
    return [[SwatchColor alloc] initWithName:@"Flamingo" color:[UIColor colorWithRed:242.0f/255.0f green:81.0f/255.0f blue:146.0f/255.0f alpha:1.0f]];
}

+ (instancetype)orangeSwatchColor
{
    // Sexy Salmon
    return [[SwatchColor alloc] initWithName:@"SexySalmon" color:[UIColor colorWithRed:247.0f/255.0f green:124.0f/255.0f blue:136.0f/255.0f alpha:1.0f]];
}

+ (instancetype)yellowSwatchColor
{
    // Peach
    return [[SwatchColor alloc] initWithName:@"Peach" color:[UIColor colorWithRed:252.0f/255.0f green:159.0f/255.0f blue:149.0f/255.0f alpha:1.0f]];
}

+ (instancetype)realmSwatchColor
{
    // Melon
    return [[SwatchColor alloc] initWithName:@"Melon" color:[UIColor colorWithRed:252.0f/255.0f green:195.0f/255.0f blue:151.0f/255.0f alpha:1.0f]];
}

@end
