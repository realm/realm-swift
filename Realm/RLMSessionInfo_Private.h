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

#import "RLMSessionInfo.h"

#import "RLMServerUtil_Private.h"

@class RLMUser;

@interface RLMSessionInfo ()

/// The path on disk where the Realm file backing this synced Realm is stored.
@property (nonatomic) NSURL *fileURL;

@property (nonatomic) RLMServerPath path;

- (instancetype)initWithFileURL:(NSURL *)fileURL path:(RLMServerPath)path;


#pragma mark - per-Realm access token API
// NOTE: much of this may disappear once we get a single access token for a user that works with multiple Realms

@property (nonatomic) RLMServerToken accessToken;
@property (nonatomic) NSTimeInterval accessTokenExpiry;

@property (nonatomic) NSTimer *refreshTimer;

@property (nonatomic, weak) RLMUser *parentUser;

- (void)configureWithAccessToken:(RLMServerToken)token expiry:(NSTimeInterval)expiry user:(RLMUser *)user;
- (void)refresh;

@end
