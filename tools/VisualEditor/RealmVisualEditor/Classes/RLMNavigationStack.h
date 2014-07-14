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

#import <Foundation/Foundation.h>

#import "RLMNavigationState.h"
#import "RLMArrayNavigationState.h"
#import "RLMQueryNavigationState.h"

@interface RLMNavigationStack : NSObject

@property (nonatomic, readonly) RLMNavigationState *currentState;

- (RLMNavigationState *)pushStateWithTypeNode:(RLMTypeNode *)typeNode index:(NSInteger)selectionIndex;

- (RLMArrayNavigationState *)pushStateWithTypeNode:(RLMTypeNode *)typeNode index:(NSInteger)selectionIndex property:(RLMProperty *)property;

- (void)pushState:(RLMNavigationState *)state;

- (RLMNavigationState *)navigateBackward;

- (RLMNavigationState *)navigateForward;

- (BOOL)canNavigateBackward;

- (BOOL)canNavigateForward;

@end
