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

#import <Realm/RLMSyncConfiguration.h>

#import <Realm/RLMConstants.h>

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

typedef RLM_CLOSED_ENUM(NSUInteger, RLMSyncStopPolicy) {
    RLMSyncStopPolicyImmediately,
    RLMSyncStopPolicyLiveIndefinitely,
    RLMSyncStopPolicyAfterChangesUploaded,
};


@class RLMSchema;

@interface RLMSyncConfiguration ()

// Flexible sync
- (instancetype)initWithUser:(RLMUser *)user;
// Partition-based sync
- (instancetype)initWithUser:(RLMUser *)user
              partitionValue:(nullable id<RLMBSON>)partitionValue;

// Internal-only APIs
@property (nonatomic, readwrite) RLMSyncStopPolicy stopPolicy;
@property (nonatomic, readonly) BOOL enableFlexibleSync;

@end

RLM_HEADER_AUDIT_END(nullability, sendability)
