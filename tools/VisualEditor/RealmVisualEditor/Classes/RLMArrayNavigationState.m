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

#import "RLMArrayNavigationState.h"

@implementation RLMArrayNavigationState

- (instancetype)initWithSelectedType:(RLMTypeNode *)type typeIndex:(NSInteger)typeIndex property:(RLMProperty *)property arrayIndex:(NSInteger)arrayIndex;
{
    if (self = [super initWithSelectedType:type
                                      index:typeIndex]) {
        _property = property;
        _arrayIndex = arrayIndex;
    }
    return self;
}

- (void)updateSelectionToIndex:(NSInteger)index
{
    _arrayIndex = index;
}

- (BOOL)isEqualTo:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        BOOL result = [super isEqualTo:object];
        
        RLMArrayNavigationState *comparedState = (RLMArrayNavigationState *)object;
        return result && self.property == comparedState.property;
    }
    
    return NO;
}


@end
