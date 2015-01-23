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

#import "RLMScrollView.h"
#import "RLMClipView.h"

@implementation RLMScrollView

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self == nil) return nil;
    
    [self swapClipView];
    
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    if (![self.contentView isKindOfClass:[RLMClipView class]]) {
        [self swapClipView];
    }
}

- (void)swapClipView
{
    self.wantsLayer = YES;
    id documentView = self.documentView;
    RLMClipView *clipView = [[RLMClipView alloc] initWithFrame:self.contentView.frame];
    self.contentView = clipView;
    self.documentView = documentView;
}

@end
