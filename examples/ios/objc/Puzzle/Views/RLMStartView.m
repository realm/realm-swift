////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

#import "RLMStartView.h"
#import "AYVibrantButton.h"

@interface RLMStartView ()

@property (nonatomic, strong) AYVibrantButton *startButton;

- (void)buttonTapped;

@end

@implementation RLMStartView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]]) {
        self.frame = frame;
        _startButton = [[AYVibrantButton alloc] initWithFrame:(CGRect){0,0,200.0f,50} style:AYVibrantButtonStyleInvert];
        _startButton.text = @"Start";
        _startButton.vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:(UIBlurEffect *)self.effect];
        _startButton.font = [UIFont systemFontOfSize:18.0];
        [_startButton addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_startButton];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = self.startButton.frame;
    frame.origin.x = (CGRectGetWidth(self.frame) - CGRectGetWidth(frame)) * 0.5f;
    frame.origin.y = (CGRectGetHeight(self.frame) - CGRectGetHeight(frame)) * 0.5f;
    self.startButton.frame = frame;
}

- (void)buttonTapped
{
    if (self.startButtonTapped) {
        self.startButtonTapped();
    }
}

@end
