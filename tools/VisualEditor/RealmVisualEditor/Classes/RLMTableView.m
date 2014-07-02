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

#import "RLMTableView.h"

@implementation RLMTableView {
	NSTrackingArea *trackingArea;
	BOOL mouseOverView;
	RLMTableLocation currentMouseLocation;
	RLMTableLocation previousMouseLocation;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    int opts = (NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingCursorUpdate);
    trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                options:opts
                                                  owner:self
                                               userInfo:nil];
    [self addTrackingArea:trackingArea];
    
	mouseOverView = NO;
    currentMouseLocation = RLMTableLocationUndefined;
    previousMouseLocation = RLMTableLocationUndefined;
}

- (void)cursorUpdate:(NSEvent *)event
{

}

- (void)dealloc
{
	[self removeTrackingArea:trackingArea];
}

- (void)mouseEntered:(NSEvent*)event
{
	mouseOverView = YES;
    
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(mouseDidEnterView:)]) {
        [(id<RLMTableViewDelegate>)self.delegate mouseDidEnterView:self];
    }
}

- (void)mouseMoved:(NSEvent*)event
{
	id myDelegate = [self delegate];
    
	if (!myDelegate) {
		return; // No delegate, no need to track the mouse.
    }

	if (mouseOverView) {

		currentMouseLocation = [self currentLocationAtPoint:[event locationInWindow]];
		
		if (RLMTableLocationEqual(previousMouseLocation, currentMouseLocation)) {
			return;
        }
		else {
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(mouseDidExitCellAtLocation:)]) {
                [(id<RLMTableViewDelegate>)self.delegate mouseDidExitCellAtLocation:previousMouseLocation];
            }
            
            CGRect cellRect = [self rectOfLocation:previousMouseLocation];
			[self setNeedsDisplayInRect:cellRect];
            
			previousMouseLocation = currentMouseLocation;

            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(mouseDidEnterCellAtLocation:)]) {
                [(id<RLMTableViewDelegate>)self.delegate mouseDidEnterCellAtLocation:currentMouseLocation];
            }

		}

        CGRect cellRect = [self rectOfLocation:currentMouseLocation];
        [self setNeedsDisplayInRect:cellRect];
	}
}

- (void)mouseExited:(NSEvent *)theEvent
{
	mouseOverView = NO;
    
    CGRect cellRect = [self rectOfLocation:currentMouseLocation];
    [self setNeedsDisplayInRect:cellRect];
    
    currentMouseLocation = RLMTableLocationUndefined;
    previousMouseLocation = RLMTableLocationUndefined;
    
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(mouseDidExitView:)]) {
        [(id<RLMTableViewDelegate>)self.delegate mouseDidExitView:self];
    }

}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    
    [self removeTrackingArea:trackingArea];
    int opts = (NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved);
    trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                options:opts
                                                  owner:self
                                               userInfo:nil];
    [self addTrackingArea:trackingArea];
}

- (RLMTableLocation)currentLocationAtPoint:(NSPoint)point
{
    NSPoint localPoint = [self convertPoint:point
                                   fromView:nil];
    
    NSInteger row = [self rowAtPoint:localPoint];
    NSInteger column = [self columnAtPoint:localPoint];
    
    return RLMTableLocationMake(row, column);
}

- (CGRect)rectOfLocation:(RLMTableLocation)location
{
    CGRect rowRect = [self rectOfRow:location.row];
    CGRect columnRect = [self rectOfColumn:location.column];
    
    return CGRectIntersection(rowRect, columnRect);
}

@end
