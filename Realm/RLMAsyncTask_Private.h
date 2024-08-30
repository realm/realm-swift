////////////////////////////////////////////////////////////////////////////
//
// Copyright 2023 Realm Inc.
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

#import <Realm/RLMAsyncTask.h>

#import "RLMRealm_Private.h"

RLM_HEADER_AUDIT_BEGIN(nullability)

@interface RLMAsyncOpenTask ()
@property (nonatomic, nullable) RLMRealm *localRealm;

- (instancetype)initWithConfiguration:(RLMRealmConfiguration *)configuration
                           confinedTo:(RLMScheduler *)confinement
                           completion:(RLMAsyncOpenRealmCallback)completion
__attribute__((objc_direct));

- (instancetype)initWithConfiguration:(RLMRealmConfiguration *)configuration
                           confinedTo:(RLMScheduler *)confinement;

- (void)waitWithCompletion:(void (^)(NSError *_Nullable))completion;
- (void)waitForOpen:(RLMAsyncOpenRealmCallback)completion __attribute__((objc_direct));
@end

// A cancellable task for beginning an async write
NS_SWIFT_SENDABLE
@interface RLMAsyncWriteTask : NSObject
// Must only be called from within the Actor
- (instancetype)initWithRealm:(RLMRealm *)realm;
- (void)setTransactionId:(RLMAsyncTransactionId)transactionID;
- (void)complete:(bool)cancel;

// Can be called from any thread
- (void)wait:(void (^)(void))completion;
@end

typedef void (^RLMAsyncRefreshCompletion)(bool);
// A cancellable task for refreshing a Realm
NS_SWIFT_SENDABLE
@interface RLMAsyncRefreshTask : NSObject
- (void)complete:(bool)didRefresh;
- (void)wait:(RLMAsyncRefreshCompletion)completion;
+ (RLMAsyncRefreshTask *)completedRefresh;
@end

RLM_HEADER_AUDIT_END(nullability)
