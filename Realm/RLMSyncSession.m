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

#import "RLMSyncSession_Private.h"
#import "RLMSyncNetworkClient.h"

@implementation RLMSyncSession

// MARK: Public API

- (void)refreshSession:(RLMSyncCompletionBlock)completionBlock {

    



    // TODO
    NSAssert(NO, @"Implement me!");
}

- (void)destroySession:(RLMSyncCompletionBlock)completionBlock {
    // TODO
    NSAssert(NO, @"Implement me!");
}

- (void)addLoginForProvider:(RLMSyncIdentityProvider)provider
                 credential:(RLMSyncCredential)credential
                   userInfo:(nullable NSDictionary *)userInfo
               onCompletion:(RLMSyncCompletionBlock)completionBlock {
    // TODO
    NSAssert(NO, @"Implement me!");
}

// MARK: Other

- (void)updateWithJSON:(NSDictionary *)json {
    // TODO
    
}

- (void)configureWithHost:(NSString *)host account:(RLMSyncAccountID)account {
    self.host = host;
    self.account = account;
}

- (instancetype)init {
    if (self = [super init]) {
        self.valid = NO;
        self.credentials = [NSMutableDictionary dictionary];
    }
    return self;
}

@end
