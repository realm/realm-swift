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

#import "RLMNavigationState.h"

@implementation RLMNavigationState

- (instancetype)initWithSelectedType:(RLMTypeNode *)type index:(NSInteger)index
{
    if (self = [super init]) {
        _selectedType = type;
        _selectedInstanceIndex = index;
    }
    
    return self;
}

- (void)updateSelectionToIndex:(NSInteger)index
{
    _selectedInstanceIndex = index;
}

- (BOOL)isEqualTo:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        RLMNavigationState *comparedState = (RLMNavigationState *)object;
        BOOL result = self.selectedType == comparedState.selectedType &&
                      self.selectedInstanceIndex == comparedState.selectedInstanceIndex;
        
        return result;
    }
    
    return NO;
}

@end
