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

#import "RLMSyncUser.h"

#import "RLMRealm+Sync.h"

@interface RLMSyncUser ()

@property (nonatomic, readwrite) RLMSyncCredential credential;
@property (nonatomic, readwrite) RLMSyncIdentityProvider provider;
@property (nonatomic, readwrite) NSDictionary *userInfo;

@end

@implementation RLMSyncUser

- (NSString *)description {
    return [NSString stringWithFormat:@"<RLMSyncUser: %p> credential: %@, provider: %@, userInfo: %@",
            self,
            self.credential,
            self.provider,
            self.userInfo];
}

- (instancetype)initWithCredential:(RLMSyncCredential)credential
                          provider:(RLMSyncIdentityProvider)provider
                          userInfo:(nullable NSDictionary *)userInfo {
    if (self = [super init]) {
        self.credential = credential;
        self.provider = provider;
        self.userInfo = userInfo;
    }
    return self;
}

@end
