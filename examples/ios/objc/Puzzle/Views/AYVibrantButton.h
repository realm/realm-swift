//
//  AYVibrantButton.h
//  AYVibrantButton
//
//  http://github.com/a1anyip/AYVibrantButton
//
//  The MIT License (MIT)
//
//  Copyright (c) 2014 Alan Yip
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

@import UIKit;

/** AYVibrantButton **/

typedef enum {
	
	AYVibrantButtonStyleInvert,
	AYVibrantButtonStyleTranslucent,
	AYVibrantButtonStyleFill
	
} AYVibrantButtonStyle;

@interface AYVibrantButton : UIButton

@property (nonatomic, assign) BOOL animated;
@property (nonatomic, assign) CGFloat animationDuration;
@property (nonatomic, assign) CGFloat alpha;
@property (nonatomic, assign) CGFloat translucencyAlphaNormal;
@property (nonatomic, assign) CGFloat translucencyAlphaHighlighted;
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) UIRectCorner roundingCorners;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, strong) UIImage *icon;
@property (nonatomic, copy)   NSString *text;
@property (nonatomic, strong) UIFont *font;

#ifdef __IPHONE_8_0
// the vibrancy effect to be applied on the button
@property (nonatomic, strong) UIVibrancyEffect *vibrancyEffect;
#endif

// the background color when vibrancy effect is nil, or not supported.
@property (nonatomic, strong) UIColor *backgroundColor;

// this is the only method to initialize a vibrant button
- (instancetype)initWithFrame:(CGRect)frame style:(AYVibrantButtonStyle)style;

@end

/** AYVibrantButtonOverlay **/

typedef enum {
	
	AYVibrantButtonOverlayStyleNormal,
	AYVibrantButtonOverlayStyleInvert
	
} AYVibrantButtonOverlayStyle;

@interface AYVibrantButtonOverlay : UIView

// numeric configurations
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) UIRectCorner roundingCorners;
@property (nonatomic, assign) CGFloat borderWidth;

// icon image
@property (nonatomic, strong) UIImage *icon;

// display text
@property (nonatomic, copy)   NSString *text;
@property (nonatomic, strong) UIFont *font;

// background color
@property (nonatomic, strong) UIColor *backgroundColor;

- (instancetype)initWithStyle:(AYVibrantButtonOverlayStyle)style;

@end

/** AYVibrantButtonGroup **/

@interface AYVibrantButtonGroup : UIView

@property (nonatomic, assign) BOOL animated;
@property (nonatomic, assign) CGFloat animationDuration;
@property (nonatomic, assign) CGFloat translucencyAlphaNormal;
@property (nonatomic, assign) CGFloat translucencyAlphaHighlighted;
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, strong) UIFont *font;

#ifdef __IPHONE_8_0
// the vibrancy effect to be applied on the button
@property (nonatomic, strong) UIVibrancyEffect *vibrancyEffect;
#endif

// the background color when vibrancy effect is nil, or not supported.
@property (nonatomic, strong) UIColor *backgroundColor;

- (instancetype)initWithFrame:(CGRect)frame buttonTitles:(NSArray *)buttonTitles style:(AYVibrantButtonStyle)style;
- (instancetype)initWithFrame:(CGRect)frame buttonIcons:(NSArray *)buttonIcons style:(AYVibrantButtonStyle)style;

- (AYVibrantButton *)buttonAtIndex:(NSUInteger)index;

@end