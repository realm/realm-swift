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

#import "RLMNavigationStack.h"

@implementation RLMNavigationStack {

    NSMutableArray *stack;
    NSInteger index;
}

- (instancetype)init
{
    if (self = [super init]) {
        stack = [[NSMutableArray alloc] initWithCapacity:200];
        index = -1;
    }
    return  self;
}

- (RLMNavigationState *)currentState
{
    if (0 <= index && index < stack.count ) {
        return stack[index];
    }
    
    return nil;
}

- (RLMNavigationState *)pushStateWithTypeNode:(RLMTypeNode *)typeNode index:(NSInteger)selectionIndex
{
    RLMNavigationState *state = [[RLMNavigationState alloc] initWithSelectedType:typeNode
                                                                            index:selectionIndex];
    [self pushState:state];
    
    return state;
}

- (RLMArrayNavigationState *)pushStateWithTypeNode:(RLMTypeNode *)typeNode index:(NSInteger)selectionIndex property:(RLMProperty *)property
{
    RLMArrayNavigationState *state = [[RLMArrayNavigationState alloc] initWithSelectedType:typeNode
                                                                                 typeIndex:selectionIndex
                                                                                  property:property
                                                                                arrayIndex:0];
    [self pushState:state];
    
    return state;
}

- (void)pushState:(RLMNavigationState *)state
{
    NSInteger lastIndex = (NSInteger)stack.count - 1;
    if (index < lastIndex) {
        [stack removeObjectsInRange:NSMakeRange(index, stack.count - index - 1)];
    }
    
    [stack addObject:state];
    index++;
}

- (RLMNavigationState *)navigateBackward
{
    if (index > 0) {
        index--;
        return stack[index];
    }
    return nil;
}

- (RLMNavigationState *)navigateForward
{
    if (index < stack.count - 1) {
        index++;
        return stack[index];
    }
    return nil;
}

- (BOOL)canNavigateBackward
{
    return stack.count > 1 && index > 0;
}

- (BOOL)canNavigateForward
{
    return stack.count > 1 && index < stack.count - 1;
}

@end
