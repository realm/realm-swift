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

@implementation SwatchColor

+ (NSDictionary *)sharedColors
{
    static NSDictionary<NSString *, UIColor*> *swatchColors;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swatchColors =
        @{
          @"Charcoal": [UIColor colorWithRed:28.0f/255.0f green:35.0f/255.0f blue:63.0f/255.0f alpha:1.0f],
          @"Elephant": [UIColor colorWithRed:154.0f/255.0f green:155.0f/255.0f blue:165.0f/255.0f alpha:1.0f],
          @"Dove": [UIColor colorWithRed:235.0f/255.0f green:235.0f/255.0f blue:242.0f/255.0f alpha:1.0f],
          @"Ultramarine": [UIColor colorWithRed:57.0f/255.0f green:71.0f/255.0f blue:127.0f/255.0f alpha:1.0f],
          @"Indigo": [UIColor colorWithRed:89.0f/255.0f green:86.0f/255.0f blue:158.0f/255.0f alpha:1.0f],
          @"GrapeJelly": [UIColor colorWithRed:154.0f/255.0f green:80.0f/255.0f blue:165.0f/255.0f alpha:1.0f],
          @"Mulberry": [UIColor colorWithRed:211.0f/255.0f green:76.0f/255.0f blue:163.0f/255.0f alpha:1.0f],
          @"Flamingo": [UIColor colorWithRed:242.0f/255.0f green:81.0f/255.0f blue:146.0f/255.0f alpha:1.0f],
          @"SexySalmon": [UIColor colorWithRed:247.0f/255.0f green:124.0f/255.0f blue:136.0f/255.0f alpha:1.0f],
          @"Peach": [UIColor colorWithRed:252.0f/255.0f green:159.0f/255.0f blue:149.0f/255.0f alpha:1.0f],
          @"Melon": [UIColor colorWithRed:252.0f/255.0f green:195.0f/255.0f blue:151.0f/255.0f alpha:1.0f]
        };
    });
    
    return swatchColors;
}

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
    SwatchColor *swatchColor = [SwatchColor sharedColors][name];
    if (swatchColor == nil) {
        return nil;
    }

    return [[SwatchColor alloc] initWithName:name color:swatchColor.color];
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
    return [SwatchColor swatchColorForName:@"Charcoal"];
}

+ (instancetype)graySwatchColor
{
    // Elephant
    return [SwatchColor swatchColorForName:@"Elephant"];
}

+ (instancetype)redSwatchColor
{
    // Dove
    return [SwatchColor swatchColorForName:@"Dove"];
}

+ (instancetype)blueSwatchColor
{
    // Ultramarine
    return [SwatchColor swatchColorForName:@"Ultramarine"];
}

+ (instancetype)greenSwatchColor
{
    // Indigo
    return [SwatchColor swatchColorForName:@"Indigo"];
}

+ (instancetype)lightGreenSwatchColor
{
    // Grape Jelly
    return [SwatchColor swatchColorForName:@"GrapeJelly"];
}

+ (instancetype)lightBlueSwatchColor
{
    // Mulberry
    return [SwatchColor swatchColorForName:@"Mulberry"];
}

+ (instancetype)brownSwatchColor
{
    // Flamingo
    return [SwatchColor swatchColorForName:@"Flamingo"];
}

+ (instancetype)orangeSwatchColor
{
    // Sexy Salmon
    return [SwatchColor swatchColorForName:@"SexySalmon"];
}

+ (instancetype)yellowSwatchColor
{
    // Peach
    return [SwatchColor swatchColorForName:@"Peach"];
}

+ (instancetype)realmSwatchColor
{
    // Melon
    return [SwatchColor swatchColorForName:@"Melon"];
}

@end
