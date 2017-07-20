////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
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

#import "RLMResults_Private.h"

#import "results.hpp"

NS_ASSUME_NONNULL_BEGIN

@interface RLMResults () {
@protected
    realm::Results _results;
}
- (instancetype)initWithResults:(realm::Results)results;
@end

NS_ASSUME_NONNULL_END

// Utility functions

[[gnu::noinline]]
[[noreturn]]
void RLMThrowResultsError(NSString * _Nullable aggregateMethod);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"
template<typename Function>
static auto translateErrors(Function&& f, NSString *aggregateMethod=nil) {
    try {
        return f();
    }
    catch (...) {
        RLMThrowResultsError(aggregateMethod);
    }
}
#pragma clang diagnostic pop
