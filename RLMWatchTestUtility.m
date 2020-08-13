////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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

#import "RLMWatchTestUtility.h"
#import <Realm/RLMBSON.h>

@implementation RLMWatchTestUtility {
    NSUInteger _targetChangeEventCount;
    NSUInteger _currentChangeEventCount;
    __weak RLMWatchTestUtilityBlock _completion;
}

- (instancetype)initWithChangeEventCount:(NSUInteger)changeEventCount
                              completion:(RLMWatchTestUtilityBlock)completion {
    if (self = [super init]) {
        _completion = completion;
        _targetChangeEventCount = changeEventCount;
        return self;
    }

    return nil;
}

- (void)didClose {
}

- (void)didOpen {
}

- (void)didReceiveChangeEvent:(nonnull id<RLMBSON>)changeEvent {
    _currentChangeEventCount++;
    if (_currentChangeEventCount == _targetChangeEventCount) {
        _completion(nil);
    }
}

- (void)didReceiveError:(nonnull NSError *)error {
    _completion(error);
}

@end
