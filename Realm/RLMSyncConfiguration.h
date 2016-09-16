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

#import <Foundation/Foundation.h>

#import "RLMSyncUtil.h"

@class RLMSyncUser;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, RLMSyncStopPolicy) {
    RLMSyncStopPolicyImmediately,
    RLMSyncStopPolicyLiveIndefinitely,
    RLMSyncStopPolicyAfterChangesUploaded,
};

@interface RLMSyncConfiguration : NSObject RLM_SYNC_UNINITIALIZABLE

@property (nonatomic, readonly) RLMSyncUser *user;
@property (nonatomic, readonly) NSURL *realmURL;

/**
 Create a sync configuration instance.

 @param user    A `RLMSyncUser` that owns the Realm at the given URL.
 @param url     The full, unresolved URL to the Realm on the Realm Object Server. "Full" means that this URL is fully
                qualified; e.g. `realm://example.org/~/path/to/my.realm`. "Unresolved" means the path should contain the
                wildcard marker `~`.
 */
- (instancetype)initWithUser:(RLMSyncUser *)user realmURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
