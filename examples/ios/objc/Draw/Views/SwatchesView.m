////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#import "SwatchesView.h"

static CGFloat kSwatchButtonHeightPhone = 85.0f;
static CGFloat kSwatchButtonWidthPhone = 30.0f;

static CGFloat kSwatchButtonHeightPad= 166.0f;
static CGFloat kSwatchButtonWidthPad = 57.0f;

static CGFloat kSwatchPencilPadding = 1.0f;

@interface SwatchesView()

@property (nonatomic, strong) UIImageView *selectedIconView;
@property (nonatomic, strong) NSDictionary *colors;
@property (nonatomic, strong) NSArray *colorButtons;

@end

@implementation SwatchesView

- (instancetype)initWithFrame:(CGRect)frame
{
    frame.size.height = [SwatchesView sizeForDevice].height;
    if (self = [super initWithFrame:frame]) {
        [self setupButtons];
    }
    
    return self;
}

- (void)setupButtons
{
    self.colors = [UIColor realmColors];

    NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:self.colors.count];
    NSInteger tag = 0;
    for (NSString *color in self.colors.allKeys) {
        UIImage *pencilImage = [[UIImage imageNamed:color] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];

        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.tag = tag++;
        button.contentMode = UIViewContentModeScaleAspectFit;
        [button setImage:pencilImage forState:UIControlStateNormal];
        [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];

        [buttons addObject:button];
    }
    self.colorButtons = buttons;

    CGSize swatchSize = [SwatchesView sizeForDevice];
    CGFloat totalWidth = (self.colors.count * swatchSize.width) + ((self.colors.count-1) * kSwatchPencilPadding);
    CGFloat x = 0.0f;
    for (UIButton *button in self.colorButtons) {
        CGRect frame = button.frame;
        frame.origin.x = x;
        frame.size = swatchSize;
        button.frame = frame;

        x += swatchSize.width + kSwatchPencilPadding;
    }

    self.contentSize = (CGSize){totalWidth, swatchSize.height};
    [self updateContentInset];
    
    self.selectedIconView = [[UIImageView alloc] initWithImage:[[self class] circleIcon]];
    [self addSelectedIconToButton:self.colorButtons.firstObject];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self updateContentInset];
}

- (void)updateContentInset
{
    CGSize contentSize = self.contentSize;
    CGSize size = self.frame.size;
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;

    //Only do content insets if the scroll size is smaller than the window
    if (contentSize.width < size.width) {
        CGFloat inset = (size.width - contentSize.width) * 0.5f;
        contentInsets.left = inset;
        contentInsets.right = inset;
    }
    
    self.contentInset = contentInsets;
}

- (void)addSelectedIconToButton:(UIButton *)button
{
    [button addSubview:self.selectedIconView];
    CGRect frame = self.selectedIconView.frame;
    frame.origin.x = (button.frame.size.width - frame.size.width) * 0.5f;
    frame.origin.y = button.frame.size.height - 12.0f;
    self.selectedIconView.frame = frame;
}

- (void)buttonTapped:(id)sender
{
    UIButton *button = (UIButton *)sender;
    self.selectedColor = self.colors.allKeys[button.tag];
    [self addSelectedIconToButton:sender];
}

- (void)setSelectedColor:(NSString *)selectedColor
{
    if (selectedColor == _selectedColor) {
        return;
    }
    
    _selectedColor = selectedColor;
    
    if (self.swatchColorChangedHandler)
        self.swatchColorChangedHandler();
}

+ (CGSize)sizeForDevice
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return (CGSize){kSwatchButtonWidthPad, kSwatchButtonHeightPad};
    }
    
    return (CGSize){kSwatchButtonWidthPhone, kSwatchButtonHeightPhone};
}

+ (UIImage *)circleIcon
{
    CGRect rect = CGRectMake(0, 0, 6.0f, 6.0f);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0f);
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:rect];
    [[UIColor colorWithWhite:1.0f alpha:0.8f] set];
    [path fill];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
