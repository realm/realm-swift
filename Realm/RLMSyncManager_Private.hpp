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

#import "RLMNetworkTransport.h"
#import <realm/object-store/sync/sync_manager.hpp>

namespace realm {
struct SyncConfig;
class SyncManager;
namespace app {
class App;
}
namespace util {
class Logger;
}
}

@class RLMAppConfiguration, RLMUser, RLMSyncConfiguration;

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

@interface RLMSyncManager ()
- (std::weak_ptr<realm::app::App>)app;
- (std::shared_ptr<realm::SyncManager>)syncManager;
- (instancetype)initWithSyncManager:(std::shared_ptr<realm::SyncManager>)syncManager;

- (void)resetForTesting;
- (void)waitForSessionTermination;
- (void)populateConfig:(realm::SyncConfig&)config;
@end

RLM_DIRECT_MEMBERS
@interface RLMSyncTimeoutOptions () {
    @public
    realm::SyncClientTimeouts _options;
}
- (instancetype)initWithOptions:(realm::SyncClientTimeouts)options;
@end

std::shared_ptr<realm::util::Logger> RLMWrapLogFunction(RLMSyncLogFunction);

RLM_HEADER_AUDIT_END(nullability, sendability)
