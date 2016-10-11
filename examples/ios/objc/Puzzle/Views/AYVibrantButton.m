//
//  AYVibrantButton.m
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

#import "AYVibrantButton.h"

#define kAYVibrantButtonDefaultAnimationDuration 0.15
#define kAYVibrantButtonDefaultAlpha 1.0
#define kAYVibrantButtonDefaultTranslucencyAlphaNormal 1.0
#define kAYVibrantButtonDefaultTranslucencyAlphaHighlighted 0.5
#define kAYVibrantButtonDefaultCornerRadius 4.0
#define kAYVibrantButtonDefaultRoundingCorners UIRectCornerAllCorners
#define kAYVibrantButtonDefaultBorderWidth 0.6
#define kAYVibrantButtonDefaultFontSize 14.0
#define kAYVibrantButtonDefaultBackgroundColor [UIColor whiteColor]

/** AYVibrantButton **/

@interface AYVibrantButton () {
	
	__strong UIColor *_backgroundColor;
}

@property (nonatomic, assign) AYVibrantButtonStyle style;

#ifdef __IPHONE_8_0
@property (nonatomic, strong) UIVisualEffectView *visualEffectView;
#endif

@property (nonatomic, strong) AYVibrantButtonOverlay *normalOverlay;
@property (nonatomic, strong) AYVibrantButtonOverlay *highlightedOverlay;

@property (nonatomic, assign) BOOL activeTouch;
@property (nonatomic, assign) BOOL hideRightBorder;

- (void)createOverlays;

@end

/** AYVibrantButtonOverlay **/

@interface AYVibrantButtonOverlay () {
	
	__strong UIFont *_font;
	__strong UIColor *_backgroundColor;
}

@property (nonatomic, assign) AYVibrantButtonOverlayStyle style;
@property (nonatomic, assign) CGFloat textHeight;
@property (nonatomic, assign) BOOL hideRightBorder;

- (void)_updateTextHeight;

@end

/** AYVibrantButtonGroup **/

@interface AYVibrantButtonGroup ()

@property (nonatomic, strong) NSArray *buttons;
@property (nonatomic, assign) NSUInteger buttonCount;

- (void)_initButtonGroupWithSelector:(SEL)selector andObjects:(NSArray *)objects style:(AYVibrantButtonStyle)style;

@end

/** AYVibrantButton **/

@implementation AYVibrantButton

- (instancetype)init {
	NSLog(@"AYVibrantButton must be initialized with initWithFrame:style:");
	return nil;
}

- (instancetype)initWithFrame:(CGRect)frame {
	NSLog(@"AYVibrantButton must be initialized with initWithFrame:style:");
	return nil;
}

- (instancetype)initWithFrame:(CGRect)frame style:(AYVibrantButtonStyle)style {
	if (self = [super initWithFrame:frame]) {
		
		self.style = style;
		self.opaque = NO;
		self.userInteractionEnabled = YES;
		
		// default values
		_animated = YES;
		_animationDuration = kAYVibrantButtonDefaultAnimationDuration;
		_cornerRadius = kAYVibrantButtonDefaultCornerRadius;
		_roundingCorners = kAYVibrantButtonDefaultRoundingCorners;
		_borderWidth = kAYVibrantButtonDefaultBorderWidth;
		_translucencyAlphaNormal = kAYVibrantButtonDefaultTranslucencyAlphaNormal;
		_translucencyAlphaHighlighted = kAYVibrantButtonDefaultTranslucencyAlphaHighlighted;
		_alpha = kAYVibrantButtonDefaultAlpha;
		_activeTouch = NO;
		
		// create overlay views
		[self createOverlays];
		
#ifdef __IPHONE_8_0
		// add the default vibrancy effect
		self.vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
#endif
		
		[self addTarget:self action:@selector(touchDown) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragInside];
		[self addTarget:self action:@selector(touchUp) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchDragOutside | UIControlEventTouchCancel];
	}
	return self;
}

- (void)layoutSubviews {
#ifdef __IPHONE_8_0
	self.visualEffectView.frame = self.bounds;
#endif
	self.normalOverlay.frame = self.bounds;
	self.highlightedOverlay.frame = self.bounds;
}

- (void)createOverlays {
	
	if (self.style == AYVibrantButtonStyleFill) {
		self.normalOverlay = [[AYVibrantButtonOverlay alloc] initWithStyle:AYVibrantButtonOverlayStyleInvert];
	} else {
		self.normalOverlay = [[AYVibrantButtonOverlay alloc] initWithStyle:AYVibrantButtonOverlayStyleNormal];
	}
	
	if (self.style == AYVibrantButtonStyleInvert) {
		self.highlightedOverlay = [[AYVibrantButtonOverlay alloc] initWithStyle:AYVibrantButtonOverlayStyleInvert];
		self.highlightedOverlay.alpha = 0.0;
	} else if (self.style == AYVibrantButtonStyleTranslucent || self.style == AYVibrantButtonStyleFill) {
		self.normalOverlay.alpha = self.translucencyAlphaNormal * self.alpha;
	}
	
#ifndef __IPHONE_8_0
	// for iOS 8, these two overlay views will be added as subviews in setVibrancyEffect:
	[self addSubview:self.normalOverlay];
	[self addSubview:self.highlightedOverlay];
#endif

}

#pragma mark - Control Event Handlers

- (void)touchDown {
	
	self.activeTouch = YES;

	void(^update)(void) = ^(void) {
		if (self.style == AYVibrantButtonStyleInvert) {
			self.normalOverlay.alpha = 0.0;
			self.highlightedOverlay.alpha = self.alpha;
		} else if (self.style == AYVibrantButtonStyleTranslucent || self.style == AYVibrantButtonStyleFill) {
			self.normalOverlay.alpha = self.translucencyAlphaHighlighted * self.alpha;
		}
	};
	
	if (self.animated) {
		[UIView animateWithDuration:self.animationDuration animations:update];
	} else {
		update();
	}
}

- (void)touchUp {
	
	self.activeTouch = NO;

	void(^update)(void) = ^(void) {
		if (self.style == AYVibrantButtonStyleInvert) {
			self.normalOverlay.alpha = self.alpha;
			self.highlightedOverlay.alpha = 0.0;
		} else if (self.style == AYVibrantButtonStyleTranslucent || self.style == AYVibrantButtonStyleFill) {
			self.normalOverlay.alpha = self.translucencyAlphaNormal * self.alpha;
		}
	};
	
	if (self.animated) {
		[UIView animateWithDuration:self.animationDuration animations:update];
	} else {
		update();
	}
}

#pragma mark - Override Getters

- (UIColor *)backgroundColor {
	return _backgroundColor == nil ? kAYVibrantButtonDefaultBackgroundColor : _backgroundColor;
}

#pragma mark - Override Setters

- (void)setAlpha:(CGFloat)alpha {
	
	_alpha = alpha;
	
	if (self.activeTouch) {
		if (self.style == AYVibrantButtonStyleInvert) {
			self.normalOverlay.alpha = 0.0;
			self.highlightedOverlay.alpha = self.alpha;
		} else if (self.style == AYVibrantButtonStyleTranslucent || self.style == AYVibrantButtonStyleFill) {
			self.normalOverlay.alpha = self.translucencyAlphaHighlighted * self.alpha;
		}
	} else {
		if (self.style == AYVibrantButtonStyleInvert) {
			self.normalOverlay.alpha = self.alpha;
			self.highlightedOverlay.alpha = 0.0;
		} else if (self.style == AYVibrantButtonStyleTranslucent || self.style == AYVibrantButtonStyleFill) {
			self.normalOverlay.alpha = self.translucencyAlphaNormal * self.alpha;
		}
	}
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
	_cornerRadius = cornerRadius;
	self.normalOverlay.cornerRadius = cornerRadius;
	self.highlightedOverlay.cornerRadius = cornerRadius;
}

- (void)setRoundingCorners:(UIRectCorner)roundingCorners {
	_roundingCorners = roundingCorners;
	self.normalOverlay.roundingCorners = roundingCorners;
	self.highlightedOverlay.roundingCorners = roundingCorners;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
	_borderWidth = borderWidth;
	self.normalOverlay.borderWidth = borderWidth;
	self.highlightedOverlay.borderWidth = borderWidth;
}

- (void)setIcon:(UIImage *)icon {
	_icon = icon;
	self.normalOverlay.icon = icon;
	self.highlightedOverlay.icon = icon;
}

- (void)setText:(NSString *)text {
	_text = [text copy];
	self.normalOverlay.text = text;
	self.highlightedOverlay.text = text;
}

- (void)setFont:(UIFont *)font {
	_font = font;
	self.normalOverlay.font = font;
	self.highlightedOverlay.font = font;
}

#ifdef __IPHONE_8_0
- (void)setVibrancyEffect:(UIVibrancyEffect *)vibrancyEffect {
	
	_vibrancyEffect = vibrancyEffect;
	
	[self.normalOverlay removeFromSuperview];
	[self.highlightedOverlay removeFromSuperview];
	[self.visualEffectView removeFromSuperview];
	
	if (vibrancyEffect != nil) {
		self.visualEffectView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
		self.visualEffectView.userInteractionEnabled = NO;
		[self.visualEffectView.contentView addSubview:self.normalOverlay];
		[self.visualEffectView.contentView addSubview:self.highlightedOverlay];
		[self addSubview:self.visualEffectView];
	} else {
		[self addSubview:self.normalOverlay];
		[self addSubview:self.highlightedOverlay];
	}
}
#endif

- (void)setBackgroundColor:(UIColor *)backgroundColor {
	self.normalOverlay.backgroundColor = backgroundColor;
	self.highlightedOverlay.backgroundColor = backgroundColor;
}

- (void)setHideRightBorder:(BOOL)hideRightBorder {
	_hideRightBorder = hideRightBorder;
	self.normalOverlay.hideRightBorder = hideRightBorder;
	self.highlightedOverlay.hideRightBorder = hideRightBorder;
}

@end

/** AYVibrantButtonOverlay **/

@implementation AYVibrantButtonOverlay

- (instancetype)initWithStyle:(AYVibrantButtonOverlayStyle)style {
	if (self = [self init]) {
		self.style = style;
	}
	return self;
}

- (instancetype)init {
	if (self = [super init]) {
		
		_cornerRadius = kAYVibrantButtonDefaultCornerRadius;
		_roundingCorners = kAYVibrantButtonDefaultRoundingCorners;
		_borderWidth = kAYVibrantButtonDefaultBorderWidth;
		
		self.opaque = NO;
		self.userInteractionEnabled = NO;
	}
	return self;
}

- (void)drawRect:(CGRect)rect {
	
	[super drawRect:rect];
	
	CGSize size = self.bounds.size;
	if (size.width == 0 || size.height == 0) return;
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextClearRect(context, self.bounds);
	
	[self.backgroundColor setStroke];
	[self.backgroundColor setFill];
	
	CGRect boxRect = CGRectInset(self.bounds, self.borderWidth / 2, self.borderWidth / 2);
	
	if (self.hideRightBorder) {
		boxRect.size.width += self.borderWidth * 2;
	}
	
	// draw background and border
	UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:boxRect byRoundingCorners:self.roundingCorners cornerRadii:CGSizeMake(self.cornerRadius, self.cornerRadius)];
	path.lineWidth = self.borderWidth;
	[path stroke];
	
	if (self.style == AYVibrantButtonOverlayStyleInvert) {
		// fill the rounded rectangle area
		[path fill];
	}
	
	CGContextClipToRect(context, boxRect);
	
	// draw icon
	if (self.icon != nil) {
		
		CGSize iconSize = self.icon.size;
		CGRect iconRect = CGRectMake((size.width - iconSize.width) / 2,
									 (size.height - iconSize.height) / 2,
									 iconSize.width,
									 iconSize.height);
		
		if (self.style == AYVibrantButtonOverlayStyleNormal) {
			// ref: http://blog.alanyip.me/tint-transparent-images-on-ios/
			CGContextSetBlendMode(context, kCGBlendModeNormal);
			CGContextFillRect(context, iconRect);
			CGContextSetBlendMode(context, kCGBlendModeDestinationIn);
		} else if (self.style == AYVibrantButtonOverlayStyleInvert) {
			// this will make the CGContextDrawImage below clear the image area
			CGContextSetBlendMode(context, kCGBlendModeDestinationOut);
		}
		
		CGContextTranslateCTM(context, 0, size.height);
		CGContextScaleCTM(context, 1.0, -1.0);
		
		// for some reason, drawInRect does not work here
		CGContextDrawImage(context, iconRect, self.icon.CGImage);
	}
	
	// draw text
	if (self.text != nil) {
		
		NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		style.lineBreakMode = NSLineBreakByTruncatingTail;
		style.alignment = NSTextAlignmentCenter;
		
		if (self.style == AYVibrantButtonOverlayStyleInvert) {
			// this will make the drawInRect below clear the text area
			CGContextSetBlendMode(context, kCGBlendModeClear);
		}
		
		[self.text drawInRect:CGRectMake(0.0, (size.height - self.textHeight) / 2, size.width, self.textHeight) withAttributes:@{ NSFontAttributeName:self.font, NSForegroundColorAttributeName:self.backgroundColor, NSParagraphStyleAttributeName:style }];
	}
}

#pragma mark - Override Getters

- (UIFont *)font {
	return _font == nil ? [UIFont systemFontOfSize:kAYVibrantButtonDefaultFontSize] : _font;
}

- (UIColor *)backgroundColor {
	return _backgroundColor == nil ? kAYVibrantButtonDefaultBackgroundColor : _backgroundColor;
}

#pragma mark - Override Setters

- (void)setCornerRadius:(CGFloat)cornerRadius {
	_cornerRadius = cornerRadius;
	[self setNeedsDisplay];
}

- (void)setRoundingCorners:(UIRectCorner)roundingCorners {
	_roundingCorners = roundingCorners;
	[self setNeedsDisplay];
}

- (void)setBorderWidth:(CGFloat)borderWidth {
	_borderWidth = borderWidth;
	[self setNeedsDisplay];
}

- (void)setIcon:(UIImage *)icon {
	_icon = icon;
	_text = nil;
	[self setNeedsDisplay];
}

- (void)setText:(NSString *)text {
	_icon = nil;
	_text = [text copy];
	[self _updateTextHeight];
	[self setNeedsDisplay];
}

- (void)setFont:(UIFont *)font {
	_font = font;
	[self _updateTextHeight];
	[self setNeedsDisplay];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
	_backgroundColor = backgroundColor;
	[self setNeedsDisplay];
}

- (void)setHideRightBorder:(BOOL)hideRightBorder {
	_hideRightBorder = hideRightBorder;
	[self setNeedsDisplay];
}

#pragma mark - Private Methods

- (void)_updateTextHeight {
	CGRect bounds = [self.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName:self.font } context:nil];
	self.textHeight = bounds.size.height;
}

@end

/** AYVibrantButtonGroup **/

@implementation AYVibrantButtonGroup

- (instancetype)init {
	NSLog(@"AYVibrantButtonGroup must be initialized with initWithFrame:buttonTitles:style: or initWithFrame:buttonIcons:style:");
	return nil;
}

- (instancetype)initWithFrame:(CGRect)frame {
	NSLog(@"AYVibrantButtonGroup must be initialized with initWithFrame:buttonTitles:style: or initWithFrame:buttonIcons:style:");
	return nil;
}

- (instancetype)initWithFrame:(CGRect)frame buttonTitles:(NSArray *)buttonTitles style:(AYVibrantButtonStyle)style {
	if (self = [super initWithFrame:frame]) {
		[self _initButtonGroupWithSelector:@selector(setText:) andObjects:buttonTitles style:style];
	}
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame buttonIcons:(NSArray *)buttonIcons style:(AYVibrantButtonStyle)style {
	if (self = [super initWithFrame:frame]) {
		[self _initButtonGroupWithSelector:@selector(setIcon:) andObjects:buttonIcons style:style];
	}
	return self;
}

- (void)layoutSubviews {
	
	if (self.buttonCount == 0) return;
	
	CGSize size = self.bounds.size;
	CGFloat buttonWidth = size.width / self.buttonCount;
	CGFloat buttonHeight = size.height;
	
	[self.buttons enumerateObjectsUsingBlock:^void(AYVibrantButton *button, NSUInteger idx, BOOL *stop) {
		button.frame = CGRectMake(buttonWidth * idx, 0.0, buttonWidth, buttonHeight);
	}];
}

- (AYVibrantButton *)buttonAtIndex:(NSUInteger)index {
	return self.buttons[index];
}

#pragma mark - Override Setters

- (void)setAnimated:(BOOL)animated {
	_animated = animated;
	for (AYVibrantButton *button in self.buttons) {
		button.animated = animated;
	}
}

- (void)setAnimationDuration:(CGFloat)animationDuration {
	_animationDuration = animationDuration;
	for (AYVibrantButton *button in self.buttons) {
		button.animationDuration = animationDuration;
	}
}

- (void)setTranslucencyAlphaNormal:(CGFloat)translucencyAlphaNormal {
	_translucencyAlphaNormal = translucencyAlphaNormal;
	for (AYVibrantButton *button in self.buttons) {
		button.translucencyAlphaNormal = translucencyAlphaNormal;
	}
}

- (void)setTranslucencyAlphaHighlighted:(CGFloat)translucencyAlphaHighlighted {
	_translucencyAlphaHighlighted = translucencyAlphaHighlighted;
	for (AYVibrantButton *button in self.buttons) {
		button.translucencyAlphaHighlighted = translucencyAlphaHighlighted;
	}
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
	_cornerRadius = cornerRadius;
	[self.buttons.firstObject setCornerRadius:cornerRadius];
	[self.buttons.lastObject setCornerRadius:cornerRadius];
}

- (void)setBorderWidth:(CGFloat)borderWidth {
	_borderWidth = borderWidth;
	for (AYVibrantButton *button in self.buttons) {
		button.borderWidth = borderWidth;
	}
}

- (void)setFont:(UIFont *)font {
	_font = font;
	[self.buttons makeObjectsPerformSelector:@selector(setFont:) withObject:font];
}

#ifdef __IPHONE_8_0
- (void)setVibrancyEffect:(UIVibrancyEffect *)vibrancyEffect {
	_vibrancyEffect = vibrancyEffect;
	[self.buttons makeObjectsPerformSelector:@selector(setVibrancyEffect:) withObject:vibrancyEffect];
}
#endif

- (void)setBackgroundColor:(UIColor *)backgroundColor {
	_backgroundColor = backgroundColor;
	[self.buttons makeObjectsPerformSelector:@selector(setBackgroundColor:) withObject:backgroundColor];
}

#pragma mark - Private Methods

- (void)_initButtonGroupWithSelector:(SEL)selector andObjects:(NSArray *)objects style:(AYVibrantButtonStyle)style {
	
	_cornerRadius = kAYVibrantButtonDefaultCornerRadius;
	_borderWidth = kAYVibrantButtonDefaultBorderWidth;
	
	self.opaque = NO;
	self.userInteractionEnabled = YES;
	
	NSMutableArray *buttons = [NSMutableArray array];
	NSUInteger count = objects.count;
	
	[objects enumerateObjectsUsingBlock:^void(id object, NSUInteger idx, BOOL *stop) {
		
		AYVibrantButton *button = [[AYVibrantButton alloc] initWithFrame:CGRectZero style:style];
		
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		[button performSelector:selector withObject:object];
#pragma clang diagnostic pop
		
		if (count == 1) {
			button.roundingCorners = UIRectCornerAllCorners;
		} else if (idx == 0) {
			button.roundingCorners = UIRectCornerTopLeft | UIRectCornerBottomLeft;
			button.hideRightBorder = YES;
		} else if (idx == count - 1) {
			button.roundingCorners = UIRectCornerTopRight | UIRectCornerBottomRight;
		} else {
			button.roundingCorners = (UIRectCorner)0;
			button.cornerRadius = 0;
			button.hideRightBorder = YES;
		}
		
		[self addSubview:button];
		[buttons addObject:button];
	}];
	
	self.buttons = buttons;
	self.buttonCount = count;
}

@end
