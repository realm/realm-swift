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
struct SyncClientConfig;
class SyncManager;
namespace app {
class App;
}
namespace util {
class Logger;
}
}

@class RLMAppConfiguration, RLMUser, RLMSyncConfiguration;

// All private API methods are threadsafe and synchronized, unless denoted otherwise. Since they are expected to be
// called very infrequently, this should pose no issues.

NS_ASSUME_NONNULL_BEGIN

@interface RLMSyncManager ()

- (std::weak_ptr<realm::app::App>)app;
- (std::shared_ptr<realm::SyncManager>)syncManager;
- (instancetype)initWithSyncManager:(std::shared_ptr<realm::SyncManager>)syncManager;

+ (realm::SyncClientConfig)configurationWithRootDirectory:(nullable NSURL *)rootDirectory
                                                    appId:(nonnull NSString *)appId;

- (void)_fireError:(NSError *)error;

- (void)resetForTesting;
- (void)waitForSessionTermination;

@end

std::shared_ptr<realm::util::Logger> RLMWrapLogFunction(RLMSyncLogFunction);

NS_ASSUME_NONNULL_END
