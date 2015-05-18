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

#import "RLMPuzzlePieceView.h"

@interface RLMPuzzlePieceView ()

@property (nonatomic, copy, readwrite) NSString *pieceName;

@end

@implementation RLMPuzzlePieceView

- (instancetype)initWithPieceName:(NSString *)pieceName
{
    if (pieceName.length == 0)
        return nil;
    
    if (self = [super initWithImage:[UIImage imageNamed:pieceName]]) {
        self.contentMode = UIViewContentModeScaleAspectFit;
        self.userInteractionEnabled = YES;
        _pieceName = pieceName;
    }
    
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    [self.superview bringSubviewToFront:self];
    [UIView animateWithDuration:0.25f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:0.5f options:0 animations:^{
        self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1f, 1.1f);
    } completion:nil];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [UIView animateWithDuration:0.25f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:0.5f options:0 animations:^{
        self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0f, 1.0f);
    } completion:nil];
}

@end
