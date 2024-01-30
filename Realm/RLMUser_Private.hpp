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

#import "RLMUser_Private.h"

#import "RLMSyncConfiguration.h"

#import <realm/object-store/sync/sync_user.hpp>
#import <realm/sync/config.hpp>

@class RLMSyncConfiguration, RLMApp;

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

@interface RLMUser ()
- (instancetype)initWithUser:(std::shared_ptr<realm::SyncUser>)user app:(RLMApp *)app;
- (std::string)pathForPartitionValue:(std::string const&)partitionValue;
- (std::string)pathForFlexibleSync;
- (std::shared_ptr<realm::SyncUser>)_syncUser;
@property (weak, readonly) RLMApp *app;

@end

@interface RLMUserProfile ()
- (instancetype)initWithUserProfile:(realm::SyncUserProfile)userProfile;
@end

RLM_HEADER_AUDIT_END(nullability, sendability)
