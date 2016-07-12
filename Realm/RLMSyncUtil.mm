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

#import "RLMSyncUtil.h"

RLMSyncToken RLM_accessTokenForJSON(NSDictionary *json) {
    id token = json[@"token"];
    if (![token isKindOfClass:[NSString class]]) {
        return nil;
    }
    return token;
}

RLMSyncToken RLM_refreshTokenForJSON(NSDictionary *json) {
    id token = json[@"renew"][@"token"];
    if (![token isKindOfClass:[NSString class]]) {
        return nil;
    }
    return token;
}

RLMSyncAccountID RLM_accountForJSON(NSDictionary *json) {
    id accountID = json[@"account"];
    if (![accountID isKindOfClass:[NSString class]]) {
        return nil;
    }
    return accountID;
}

NSString *RLM_realmIDForJSON(NSDictionary *json) {
    id realmID = json[kRLMSyncRealmIDKey];
    if (![realmID isKindOfClass:[NSString class]]) {
        return nil;
    }
    return realmID;
}

NSString *RLM_realmURLForJSON(NSDictionary *json) {
    id realmURL = json[kRLMSyncRealmURLKey];
    if (![realmURL isKindOfClass:[NSString class]]) {
        return nil;
    }
    return realmURL;
}

NSTimeInterval RLM_accessExpirationForJSON(NSDictionary *json) {
    id expiry = json[@"expires"];
    if (![expiry isKindOfClass:[NSNumber class]]) {
        return 0;
    }
    return [expiry doubleValue];
}
