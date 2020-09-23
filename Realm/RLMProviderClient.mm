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
- (instancetype)initWithApp:(RLMApp *)app {
    self = [super init];
    if (self) {
        _app = app;
    }
    return self;
}

- (void)handleResponse:(realm::util::Optional<realm::app::AppError>)error
            completion:(RLMProviderClientOptionalErrorBlock)completion {
    if (error && error->error_code) {
        return completion(RLMAppErrorToNSError(*error));
    }
    completion(nil);
}
@end
