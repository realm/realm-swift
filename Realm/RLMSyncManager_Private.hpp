////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#import <Realm/RLMSyncManager.h>

#import "RLMSyncUtil_Private.h"
#import "RLMNetworkTransport.h"
#import <memory>

namespace realm {
namespace app {
class App;
}
}

@class RLMAppConfiguration, RLMSyncUser, RLMSyncConfiguration;

// All private API methods are threadsafe and synchronized, unless denoted otherwise. Since they are expected to be
// called very infrequently, this should pose no issues.

NS_ASSUME_NONNULL_BEGIN

@interface RLMSyncManager ()

@property (nullable, nonatomic, copy) RLMSyncBasicErrorReportingBlock sessionCompletionNotifier;

- (std::shared_ptr<realm::app::App>)app;

- (instancetype)initWithAppConfiguration:(RLMAppConfiguration *)appConfiguration
                           rootDirectory:(NSURL *)rootDirectory;

- (void)configureWithRootDirectory:(nullable NSURL *)rootDirectory
                  appConfiguration:(nullable RLMAppConfiguration *)appConfiguration;

- (void)_fireError:(NSError *)error;

- (void)resetForTesting;

NS_ASSUME_NONNULL_END

@end
