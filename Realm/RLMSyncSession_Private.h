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

#import "RLMSyncSession.h"

#import "RLMSyncConfiguration.h"
#import "RLMSyncUtil_Private.h"

@class RLMSyncUser, RLMSyncSessionHandle;

@interface RLMSessionBindingPackage : NSObject

NS_ASSUME_NONNULL_BEGIN

@property (nullable, nonatomic, copy) RLMSyncBasicErrorReportingBlock block;
@property (nonatomic) NSURL *fileURL;
@property (nonatomic) RLMSyncConfiguration *syncConfig;
@property (nonatomic) BOOL isStandalone;

- (instancetype)initWithFileURL:(NSURL *)fileURL
                     syncConfig:(RLMSyncConfiguration *)syncConfig
                     standalone:(BOOL)isStandalone
                          block:(nullable RLMSyncBasicErrorReportingBlock)block;

@end

@interface RLMSyncSession ()

- (void)_refresh;
- (void)_logOut;
- (void)_invalidate;

- (void)setState:(RLMSyncSessionState)state;

/// The path on disk where the Realm file backing this synced Realm is stored.
@property (nonatomic) NSURL *fileURL;

@property (nullable, nonatomic) RLMSessionBindingPackage *deferredBindingPackage;
@property (nullable, nonatomic) RLMServerPath resolvedPath;

- (instancetype)initWithFileURL:(NSURL *)fileURL realmURL:(NSURL *)realmURL NS_DESIGNATED_INITIALIZER;

#pragma mark - per-Realm access token API

@property (nullable, nonatomic) RLMServerToken accessToken;
@property (nonatomic) NSTimeInterval accessTokenExpiry;

@property (nonatomic) NSTimer *refreshTimer;

- (void)configureWithAccessToken:(RLMServerToken)token
                          expiry:(NSTimeInterval)expiry
                            user:(RLMSyncUser *)user
                          handle:(RLMSyncSessionHandle *)session;

- (void)refreshAccessToken:(NSString *)token serverURL:(nullable NSURL *)serverURL;

NS_ASSUME_NONNULL_END

@end
