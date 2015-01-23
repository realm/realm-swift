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

#import "RLMLinkTableCellView.h"
#import "NSColor+ByteSizeFactory.h"

@interface RLMLinkTableCellView ()

@property (nonatomic) NSAttributedString *attributedStringValue;

@end


@implementation RLMLinkTableCellView 

-(void)setDragType:(NSString *)dragType
{
    _dragType = dragType;
    [self unregisterDraggedTypes];
    
    if (dragType) {
        [self registerForDraggedTypes:@[dragType]];
    }
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
    [super setBackgroundStyle:backgroundStyle];
    self.textField.textColor = (backgroundStyle == NSBackgroundStyleLight ? [NSColor linkColor] : [NSColor whiteColor]);
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    NSLog(@"--entered");

    NSArray *supportedTypes = @[self.dragType];
    NSPasteboard *draggingPasteboard = [sender draggingPasteboard];
    NSString *availableType = [draggingPasteboard availableTypeFromArray:supportedTypes];

    if ([availableType compare:self.dragType] != NSOrderedSame) {
        NSLog(@"--WRONG TYPE");
        return NSDragOperationNone;
    }
    
    self.attributedStringValue = self.textField.attributedStringValue;
    self.textField.stringValue = @"Update link";
    
    return NSDragOperationAll;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
    NSLog(@"--exited");
    self.textField.attributedStringValue = self.attributedStringValue;
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender
{
    NSLog(@"--prepare");
    return YES;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    NSLog(@"--perform");
    self.textField.attributedStringValue = self.attributedStringValue;
    
    BOOL success = [self.delegate performDragOperationToCell:sender];
    
    NSLog(@"drag operation %@", success ? @"succeeded" : @"failed");
    
    return success;
}

@end
