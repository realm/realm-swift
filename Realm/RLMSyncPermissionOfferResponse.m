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

#import "RLMSyncPermissionOfferResponse_Private.h"
#import "RLMSyncUtil_Private.h"

@implementation RLMSyncPermissionOfferResponse

+ (instancetype)permissionOfferResponseWithToken:(NSString *)token {
    RLMSyncPermissionOfferResponse *permissionOfferResponse = [RLMSyncPermissionOfferResponse new];
    permissionOfferResponse.token = token;
    return permissionOfferResponse;
}

+ (NSArray<NSString *> *)requiredProperties {
    return @[@"id", @"createdAt", @"updatedAt", @"token"];
}

+ (NSDictionary *)defaultPropertyValues {
    NSDate *now = [NSDate date];
    return @{
             @"id": [NSUUID UUID].UUIDString,
             @"createdAt": now,
             @"updatedAt": now,
             @"token": @"",
             };
}

+ (nullable NSString *)primaryKey {
    return @"id";
}

+ (BOOL)shouldIncludeInDefaultSchema {
    return NO;
}

- (RLMSyncManagementObjectStatus)status {
    return RLMMakeSyncManagementObjectStatus(self.statusCode);
}

+ (NSString *)_realmObjectName {
    return @"PermissionOfferResponse";
}

@end
