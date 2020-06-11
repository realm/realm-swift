////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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

NS_ASSUME_NONNULL_BEGIN

@class RLMApp, RLMSyncUser;

/// A block type used to report an error
typedef void(^RLMOptionalErrorBlock)(NSError * _Nullable);

/// A client for push notificaton services which can be used to register devices with the server
@interface RLMPushClient : NSObject

/// The service name the device will be registered with on the server
@property (nonatomic, readonly, nonnull) NSString *serviceName;

/// Request to registers token string with server
- (void)registerDeviceForToken:(NSString *)token
                       syncUser:(RLMSyncUser *)syncUser
                     completion:(RLMOptionalErrorBlock)completion;

/// Request to deregister token string with server
- (void)deregisterDeviceForToken:(NSString *)token
                         syncUser:(RLMSyncUser *)syncUser
                       completion:(RLMOptionalErrorBlock)completion;

@end

NS_ASSUME_NONNULL_END
