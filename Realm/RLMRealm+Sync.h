////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
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

#import "RLMRealm.h"

@class RLMResults, RLMSyncSession;

/**
 A callback used to vend the results of a partial sync fetch.
 */
typedef void(^RLMPartialSyncFetchCallback)(RLMResults * _Nullable results, NSError * _Nullable error);

NS_ASSUME_NONNULL_BEGIN

///
@interface RLMRealm (Sync)

/// :nodoc:
- (void)subscribeToObjects:(Class)type where:(NSString *)query callback:(RLMPartialSyncFetchCallback)callback
__attribute__((unavailable("Use -[RLMResults subscribe]")));

/**
 Get the RLMSyncSession used by this Realm. Will be nil if this is not a
 synchronized Realm.
*/
@property (nonatomic, nullable, readonly) RLMSyncSession *syncSession;

@end

NS_ASSUME_NONNULL_END
