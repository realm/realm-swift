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

#import "RLMProviderClient_Private.hpp"

#import "RLMApp_Private.hpp"

#import <realm/object-store/sync/app.hpp>
#import <realm/util/optional.hpp>

@implementation RLMProviderClient

- (instancetype)initWithApp:(std::shared_ptr<realm::app::App>)app {
    if (self = [super init]) {
        _app = std::move(app);
    }
    return self;
}

- (RLMApp *)app {
    return [RLMApp appWithId:@(_app->config().app_id.c_str())];
}

realm::util::UniqueFunction<void(std::optional<realm::app::AppError>)>
RLMWrapCompletion(RLMProviderClientOptionalErrorBlock completion) {
    return [completion](std::optional<realm::app::AppError> error) {
        if (error) {
            return completion(makeError(*error));
        }
        completion(nil);
    };
}
@end
