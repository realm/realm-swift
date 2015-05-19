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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SwatchColor : NSObject

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, strong, readonly) UIColor *color;

- (instancetype)initWithName:(NSString *)name color:(UIColor *)color;

+ (instancetype)swatchColorForName:(NSString *)name;

+ (NSArray *)allSwatchColors;
+ (instancetype)blackSwatchColor;
+ (instancetype)graySwatchColor;
+ (instancetype)redSwatchColor;
+ (instancetype)blueSwatchColor;
+ (instancetype)greenSwatchColor;
+ (instancetype)lightGreenSwatchColor;
+ (instancetype)lightBlueSwatchColor;
+ (instancetype)brownSwatchColor;
+ (instancetype)orangeSwatchColor;
+ (instancetype)yellowSwatchColor;
+ (instancetype)realmSwatchColor;

@end
