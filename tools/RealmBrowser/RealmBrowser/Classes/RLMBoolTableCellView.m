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

#import "RLMBoolTableCellView.h"

@implementation RLMBoolTableCellView

- (void)viewWillDraw
{
    [super viewWillDraw];
    
    CGRect frame = self.checkBox.frame;
    CGRect bounds = self.bounds;
    
    frame.origin.x = (CGRectGetWidth(bounds) - CGRectGetWidth(frame))/2.0;
    frame.origin.y = (CGRectGetHeight(bounds) - CGRectGetHeight(frame))/2.0;
    
    self.checkBox.frame = frame;
}

-(NSSize)sizeThatFits
{
    return self.checkBox.bounds.size;
}

@end
