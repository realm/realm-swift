////////////////////////////////////////////////////////////////////////////
//
// Copyright 2018 Realm Inc.
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

#import <Realm/RLMResults.h>

NS_ASSUME_NONNULL_BEGIN

// FIXME: Document this.
typedef NS_ENUM(NSInteger, RLMPartialSyncState) {
    RLMPartialSyncStateError = -1,
    RLMPartialSyncStateCreating = 2,
    RLMPartialSyncStatePending = 0,
    RLMPartialSyncStateComplete = 1,
};

@interface RLMSyncSubscription : NSObject
@property (nonatomic, readonly) NSString *name; // FIXME: Would "identifier" be better here?
@property (nonatomic, readonly) RLMPartialSyncState state;
@property (nonatomic, readonly, nullable) NSError *error;
@property (nonatomic, readonly) RLMResults *results;
@end

@interface RLMResults (PartialSync)
// FIXME: Document this.
- (RLMSyncSubscription *)subscribe;
- (RLMSyncSubscription *)subscribeWithName:(NSString *)subscriptionName;
@end

NS_ASSUME_NONNULL_END

