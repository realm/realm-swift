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

#import <Realm/RLMApp.h>
#import <memory>
#import "sync/app.hpp"

//namespace realm {
//namespace app {
//class App;
//struct AppError;
//}
//namespace util {
//template<typename T>
//class Optional;
//}
//}

@interface RLMAppConfiguration()

- (realm::app::App::Config)_config;

- (void)setAppId:(NSString *)appId;

@end

@interface RLMApp ()
- (std::shared_ptr<realm::app::App>)_realmApp;

- (void)handleResponse:(realm::util::Optional<realm::app::AppError>)error
            completion:(RLMOptionalErrorBlock)completion;

- (instancetype)initWithApp:(std::shared_ptr<realm::app::App>)app;

@end

NSError *RLMAppErrorToNSError(realm::app::AppError const& appError);
