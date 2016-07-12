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

@interface RLMSyncSession ()

// TODO: store and manage the refresh token.
// TODO: runloop management - the session object should handle the timer for making the refresh call; the timer should
// be destroyed whenever the session becomes invalid.

@property (nonatomic, readwrite) RLMSyncAccountID account;
@property (nonatomic, readwrite) BOOL valid;
@property (nonatomic, readwrite) NSString *host;

@property (nonatomic, readwrite) RLMSyncRealmPath path;
@property (nonatomic, readwrite) NSString *remoteURL;
@property (nonatomic, readwrite) NSString *realmID;

@property (nonatomic) RLMSyncToken accessToken;

@property (nonatomic) RLMSyncToken refreshToken;

/**
 Given a newly-created session object, configure all fields which are not expected to change between requests (except
 for `path`, which is configured by the sync manager when it retrieves the object from its dictionary. Also sets the
 validity flag to YES.

 This method should only be called once.
 */
- (void)configureWithHost:(NSString *)host
                  account:(RLMSyncAccountID)account
                  realmID:(NSString *)realmID
                 realmURL:(NSString *)realmURL;

- (void)updateWithAccessToken:(RLMSyncToken)accessToken
                   expiration:(NSTimeInterval)expiration
                 refreshToken:(RLMSyncToken)refreshToken;

@end
