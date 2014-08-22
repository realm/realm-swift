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

#import "RLMTableCellView.h"

@implementation RLMTableCellView

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewWillDraw
{
    [super viewWillDraw];
    self.textField.frame = self.bounds;
}

- (NSSize)sizeThatFits
{
    [self.textField sizeToFit];
    
    return self.textField.bounds.size;
}

-(NSArray *)draggingImageComponents
{
    return @[];
}

- (NSUInteger)hitTestForEvent:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView
{
    return NSCellHitContentArea;
}


@end
