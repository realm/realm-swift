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

@class RLMApp, RLMUser;

/// A block type used to report an error
typedef void(^RLMOptionalErrorBlock)(NSError * _Nullable);

/// A client which can be used to register devices with the server to receive push notificatons
@interface RLMPushClient : NSObject

/// The push notification service name the device will be registered with on the server
@property (nonatomic, readonly, nonnull) NSString *serviceName;

/// Request to register device token to the server
- (void)registerDeviceWithToken:(NSString *)token
                           user:(RLMUser *)user
                     completion:(RLMOptionalErrorBlock)completion NS_SWIFT_NAME(registerDevice(token:user:completion:));

/// Request to deregister a device for a user
- (void)deregisterDeviceForUser:(RLMUser *)user
                     completion:(RLMOptionalErrorBlock)completion NS_SWIFT_NAME(deregisterDevice(user:completion:));

@end

NS_ASSUME_NONNULL_END
