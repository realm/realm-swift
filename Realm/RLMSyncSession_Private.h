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

@property (nonatomic) RLMSyncToken token;
@property (nonatomic) NSMutableDictionary<NSString *, RLMSyncCredential> *credentials;

/**
 Given a newly-created session object, configure all fields which are not expected to change between requests (except
 for `path`, which is configured by the sync manager when it retrieves the object from its dictionary. This method
 should only be called once.
 */
- (void)configureWithHost:(NSString *)host account:(RLMSyncAccountID)account;

/**
 Given a JSON response, update fields of the session object which aren't constant. 'Updating' might include updating the
 refresh token, the list of credentials, and any other fields that might change between requests.
 */
- (void)updateWithJSON:(NSDictionary *)json;

@end
