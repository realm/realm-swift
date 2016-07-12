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

@class RLMSyncSession;

@interface RLMSyncManager ()

/**
 Given the path of a local Realm, retrieve (or create) a session object corresponding to that Realm. This object can be
 used to store session-specific data and perform certain operations only valid if logged in.
 */
- (RLMSyncSession *)syncSessionForRealm:(RLMSyncRealmPath)realmPath;

@property (nonatomic) NSMutableDictionary<RLMSyncRealmPath, RLMSyncSession *> *sessions;

@end
