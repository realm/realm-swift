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

#import "RLMSyncConfiguration_Private.h"

#import <functional>
#import <memory>
#import <string>

namespace realm {
class Realm;
class SyncSession;
struct SyncConfig;
struct SyncError;
using SyncSessionErrorHandler = void(std::shared_ptr<SyncSession>, SyncError);
class ThreadSafeReference;
}

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

namespace realm {

struct CallbackSchema {
    bool dynamic;
    std::string path;
    RLMSchema *customSchema;

    RLMSchema *getSchema(realm::Realm& realm);
};

struct BeforeClientResetWrapper : CallbackSchema {
    RLMClientResetBeforeBlock block;
    void operator()(std::shared_ptr<realm::Realm> local);
};
struct AfterClientResetWrapper : CallbackSchema {
    RLMClientResetAfterBlock block;
    void operator()(std::shared_ptr<realm::Realm> local, realm::ThreadSafeReference remote, bool);
};
}

@interface RLMSyncConfiguration ()

- (instancetype)initWithRawConfig:(realm::SyncConfig)config path:(std::string const&)path;
- (realm::SyncConfig&)rawConfiguration;

// Pass the RLMRealmConfiguration to it's sync configuration so client reset callbacks
// can access schema, dynamic, and path properties.
void RLMSetConfigInfoForClientResetCallbacks(realm::SyncConfig& syncConfig, RLMRealmConfiguration *config);

@property (nonatomic) std::string path;

@end

NSError *_Nullable RLMTranslateSyncError(realm::SyncError);

RLM_HEADER_AUDIT_END(nullability, sendability)
