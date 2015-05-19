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
#import "SwatchesView.h"

static CGFloat kSwatchButtonHeight = 110.0f;
static CGFloat kSwatchButtonWidth = 38.0f;

static CGFloat kSwatchPencilPadding = 1.0f;

@interface SwatchesView()

@property (nonatomic, strong) NSArray *colors;
@property (nonatomic, strong) NSArray *colorButtons;

- (void)setupButtons;
- (void)buttonTapped:(id)sender;

@end

@implementation SwatchesView

- (instancetype)initWithFrame:(CGRect)frame
{
    frame.size.height = kSwatchButtonHeight;
    if (self = [super initWithFrame:frame]) {
        [self setupButtons];
    }
    
    return self;
}

- (void)setupButtons
{
    self.colors = [SwatchColor allSwatchColors];
    
    NSMutableArray *buttons = [NSMutableArray array];
    
    NSInteger tag = 0;
    for (SwatchColor *color in [SwatchColor allSwatchColors]) {
        NSString *imageName = [NSString stringWithFormat:@"%@Pencil", color.name];
        NSImage *pencilImage = [NSImage imageNamed:imageName];
        
        NSButton *button = [[NSButton alloc] initWithFrame:CGRectZero];
        button.tag = tag++;
        button.bordered = NO;
        button.image = pencilImage;
        button.target = self;
        button.action = @selector(buttonTapped:);
        button.frame = (CGRect){CGPointZero, {kSwatchButtonWidth, kSwatchButtonHeight}};
        [self addSubview:button];
        
        [buttons addObject:button];
    }
    
    self.colorButtons = buttons;
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize
{
    CGFloat width = (self.colors.count * kSwatchButtonWidth) + ((self.colors.count-1) * kSwatchPencilPadding);
    CGFloat x = (CGRectGetWidth(self.frame) - width) * 0.5f;
    
    for (NSButton *button in self.colorButtons) {
        CGRect frame = button.frame;
        frame.origin.x = x;
        button.frame = frame;
        
        x += kSwatchButtonWidth + kSwatchPencilPadding;
    }
}

- (void)buttonTapped:(id)sender
{
    NSButton *button = (NSButton *)sender;
    if (button == nil) {
        return;
    }
    
    self.selectedColor = self.colors[button.tag];
}

- (void)setSelectedColor:(SwatchColor *)selectedColor
{
    if (selectedColor == _selectedColor) {
        return;
    }
    
    _selectedColor = selectedColor;
    
    if (self.swatchColorChangedHandler)
        self.swatchColorChangedHandler();
}

@end
