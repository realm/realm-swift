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

#import <Foundation/Foundation.h>

#import "RLMSyncRenewalTokenModel.h"
#import "RLMSyncUtil.h"

@interface RLMSyncSessionDataModel : NSObject

@property (nonatomic, readonly) RLMSyncToken accessToken;
@property (nonatomic, readonly) NSTimeInterval accessTokenExpiry;
@property (nonatomic, readonly) RLMSyncAccountID accountID;

@property (nonatomic, readonly) NSString *realmID;
@property (nonatomic, readonly) NSString *realmURL;

@property (nonatomic, readonly) RLMSyncRenewalTokenModel *renewalTokenModel;

//@property (nonatomic, readonly) NSArray *access;

- (instancetype)initWithJSON:(NSDictionary *)json;

@end
