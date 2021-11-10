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

#import <Realm/RLMApp_Private.h>

#import <realm/object-store/sync/app.hpp>

#import <memory>

NS_ASSUME_NONNULL_BEGIN

@interface RLMAppConfiguration ()

- (realm::app::App::Config&)config;

- (void)setAppId:(NSString *)appId;

- (instancetype)initWithConfig:(const realm::app::App::Config&)config;

@end

@interface RLMApp ()

- (std::shared_ptr<realm::app::App>)_realmApp;

+ (instancetype)appWithId:(NSString *)appId
            configuration:(nullable RLMAppConfiguration *)configuration
            rootDirectory:(nullable NSURL *)rootDirectory;

- (instancetype)initWithApp:(std::shared_ptr<realm::app::App>)app;

@end

NSError * RLMAppErrorToNSError(realm::app::AppError const& appError);

NS_ASSUME_NONNULL_END
