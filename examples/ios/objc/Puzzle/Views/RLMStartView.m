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

#import "RLMStartView.h"
#import "AYVibrantButton.h"

@interface RLMStartView ()

@property (nonatomic, strong) AYVibrantButton *startButton;
@property (nonatomic, strong) AYVibrantButton *joinButton;

- (void)buttonTapped:(id)sender;

@end

@implementation RLMStartView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]]) {
        self.frame = frame;
        _startButton = [[AYVibrantButton alloc] initWithFrame:(CGRect){0,0,200,50} style:AYVibrantButtonStyleInvert];
        _startButton.text = @"Start";
        _startButton.vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:(UIBlurEffect *)self.effect];
        _startButton.font = [UIFont systemFontOfSize:18.0];
        [_startButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_startButton];
        
        _joinButton = [[AYVibrantButton alloc] initWithFrame:(CGRect){0,0,200,50} style:AYVibrantButtonStyleInvert];
        _joinButton.text = @"Join";
        _joinButton.vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:(UIBlurEffect *)self.effect];
        _joinButton.font = [UIFont systemFontOfSize:18.0];
        [_joinButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_joinButton];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = self.startButton.frame;
    frame.origin.x = (CGRectGetWidth(self.frame) - CGRectGetWidth(frame)) * 0.5f;
    frame.origin.y = ((CGRectGetHeight(self.frame) - CGRectGetHeight(frame)) * 0.5f) - 50.0f;
    self.startButton.frame = frame;
    
    frame = self.joinButton.frame;
    frame.origin.x = (CGRectGetWidth(self.frame) - CGRectGetWidth(frame)) * 0.5f;
    frame.origin.y = ((CGRectGetHeight(self.frame) - CGRectGetHeight(frame)) * 0.5f) + 50.0f;
    self.joinButton.frame = frame;
}

- (void)buttonTapped:(id)sender
{
    if (sender == self.startButton && self.startButtonTapped) {
        self.startButtonTapped();
    }
    else if (sender == self.joinButton && self.joinButtonTapped) {
        self.joinButtonTapped();
    }
}

@end
