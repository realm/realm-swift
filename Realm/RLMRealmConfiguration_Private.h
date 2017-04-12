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

#import <Realm/RLMRealmConfiguration.h>
#if REALM_ENABLE_SYNC
#import <Realm/RLMSyncConfiguration.h>
#endif

@class RLMSchema, RLMSyncUser;

NS_ASSUME_NONNULL_BEGIN

// FIXME: This should really be in sync headers but
// that can't be added to the module map.
#if REALM_ENABLE_SYNC
typedef NS_ENUM(NSUInteger, RLMSyncStopPolicy) {
    RLMSyncStopPolicyImmediately,
    RLMSyncStopPolicyLiveIndefinitely,
    RLMSyncStopPolicyAfterChangesUploaded,
};

@interface RLMSyncConfiguration (Private)
/**
 Sync Stop Policy (Private).
 */
@property (nonatomic, readwrite) RLMSyncStopPolicy stopPolicy;
@end

@interface RLMRealmConfiguration (RealmSync)
+ (instancetype)managementConfigurationForUser:(RLMSyncUser *)user;
+ (instancetype)permissionConfigurationForUser:(RLMSyncUser *)user;
@end
#endif

@interface RLMRealmConfiguration ()

@property (nonatomic, readwrite) bool cache;
@property (nonatomic, readwrite) bool dynamic;
@property (nonatomic, readwrite) bool disableFormatUpgrade;
@property (nonatomic, copy, nullable) RLMSchema *customSchema;
@property (nonatomic, copy) NSString *pathOnDisk;

// Get the default confiugration without copying it
+ (RLMRealmConfiguration *)rawDefaultConfiguration;

+ (void)resetRealmConfigurationState;
@end

// Get a path in the platform-appropriate documents directory with the given filename
FOUNDATION_EXTERN NSString *RLMRealmPathForFile(NSString *fileName);
FOUNDATION_EXTERN NSString *RLMRealmPathForFileAndBundleIdentifier(NSString *fileName, NSString *mainBundleIdentifier);

NS_ASSUME_NONNULL_END
