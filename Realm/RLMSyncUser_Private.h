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
#import <Realm/RLMSyncUser.h>

@class RLMSyncConfiguration, RLMRealmConfiguration;

typedef NS_ENUM(NSUInteger, RLMSyncSessionPurpose) {
    RLMSyncSessionPurposeOpenRealm,     // A synced Realm is opened normally.
    RLMSyncSessionPurposeFetchRealm,    // A synced Realm is opened through the `getRealmForURL:completion:` API.
    RLMSyncSessionPurposeStandalone,    // A standalone `RLMSyncSession` representing a remote Realm is opened.
};

typedef BOOL(^RLMSyncConfigCompletionBlock)(NSError * _Nullable, RLMRealmConfiguration * _Nullable, RLMSyncSession * _Nullable);

@interface RLMSyncUser ()

NS_ASSUME_NONNULL_BEGIN

@property (nullable, nonatomic) RLMServerToken refreshToken;

/**
 Register a Realm to a user.

 @param fileURL     The location of the file on disk where the local copy of the Realm will be saved.
 @param completion  An optional completion block.
 */
- (nullable RLMSyncSession *)_registerSessionForBindingWithFileURL:(NSURL *)fileURL
                                                        syncConfig:(RLMSyncConfiguration *)syncConfig
                                                           purpose:(RLMSyncSessionPurpose)purpose
                                                      onCompletion:(nullable RLMSyncSessionCompletionBlock)completion;

- (void)_deregisterSessionWithRealmURL:(NSURL *)realmURL;
- (void)setState:(RLMSyncUserState)state;

- (void)_getRealmAtURL:(NSURL *)realmURL onConfigCompletion:(RLMSyncConfigCompletionBlock)completion;

NS_ASSUME_NONNULL_END

@end
