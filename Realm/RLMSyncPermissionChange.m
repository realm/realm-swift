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

#import "RLMSyncPermissionChange_Private.h"

#import "RLMRealm.h"
#import "RLMRealmConfiguration+Sync.h"
#import "RLMSyncConfiguration.h"
#import "RLMSyncUser.h"

@implementation RLMSyncPermissionChange

+ (instancetype)permissionChangeWithRealmURL:(NSString *)realmURL
                                      userID:(NSString *)userID
                                        read:(nullable NSNumber<RLMBool> *)mayRead
                                       write:(nullable NSNumber<RLMBool> *)mayWrite
                                      manage:(nullable NSNumber<RLMBool> *)mayManage {
    RLMSyncPermissionChange *permissionChange = [RLMSyncPermissionChange new];
    permissionChange.realmUrl = realmURL;
    permissionChange.userId = userID;
    permissionChange.mayRead = mayRead;
    permissionChange.mayWrite = mayWrite;
    permissionChange.mayManage = mayManage;
    return permissionChange;
}

+ (NSArray<NSString *> *)requiredProperties {
    return @[@"id", @"createdAt", @"updatedAt", @"realmUrl", @"userId"];
}

+ (NSDictionary *)defaultPropertyValues {
    NSDate *now = [NSDate date];
    return @{
        @"id": [NSUUID UUID].UUIDString,
        @"createdAt": now,
        @"updatedAt": now,
        @"realmUrl": @"*",
        @"userId": @"*"
    };
}

+ (BOOL)shouldIncludeInDefaultSchema {
    return NO;
}

- (RLMSyncManagementObjectStatus)status {
    if (!self.statusCode) {
        return RLMSyncManagementObjectStatusNotProcessed;
    }
    if (self.statusCode.integerValue == 0) {
        return RLMSyncManagementObjectStatusSuccess;
    }
    return RLMSyncManagementObjectStatusError;
}

+ (NSString *)_realmObjectName {
    return @"PermissionChange";
}

@end
