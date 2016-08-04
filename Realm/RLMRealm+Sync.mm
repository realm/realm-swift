////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

#import "RLMRealm+Sync.h"

#import "RLMRealm_Private.hpp"
#import "RLMRealmConfiguration.h"
#import "RLMSyncNetworkClient.h"
#import "RLMSyncPrivateUtil.h"
#import "RLMCredential.h"
#import "RLMUser.h"

@implementation RLMRealm (Sync)

+ (void)fetchRealmAtPath:(RLMSyncPath)realmSyncPath
                 forUser:(RLMUser *)user
                readOnly:(BOOL)isReadOnly
              completion:(RLMSyncFetchedRealmCompletionBlock)completion {
    NSAssert(NO, @"This method isn't implemented yet. Come back later!");
}

@end
