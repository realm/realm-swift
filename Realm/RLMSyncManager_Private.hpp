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

#import "RLMSyncManager.h"

#import "sync_config.hpp"

@class RLMUser;

// All private API methods are threadsafe and synchronized, unless denoted otherwise. Since they are expected to be
// called very infrequently, this should pose no issues.

@interface RLMSyncManager ()

NS_ASSUME_NONNULL_BEGIN

- (void)_handleErrorWithCode:(int)errorCode
                     message:(NSString *)message
                     session:(nullable RLMSyncSession *)session
                  errorClass:(realm::SyncSessionError)errorClass;

- (NSArray<RLMUser *> *)_allUsers;

- (void)_registerUser:(RLMUser *)user;

- (void)_deregisterUser:(RLMUser *)user;

- (nullable RLMUser *)_userForIdentity:(NSString *)identity;

NS_ASSUME_NONNULL_END

@end
