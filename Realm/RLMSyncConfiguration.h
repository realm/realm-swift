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

@class RLMRealmConfiguration;
@class RLMUser;
@class RLMApp;
@protocol RLMBSON;

NS_ASSUME_NONNULL_BEGIN

/**
 A configuration object representing configuration state for a Realm which is intended to sync with a Realm Object
 Server.
 */
@interface RLMSyncConfiguration : NSObject

/// The user to which the remote Realm belongs.
@property (nonatomic, readonly) RLMUser *user;

/**
 The value this Realm is partitioned on. The partition key is a property defined in
 MongoDB Realm. All classes with a property with this value will be synchronized to the
 Realm.
 */
@property (nonatomic, readonly) id<RLMBSON> partitionValue;

/**
 Whether nonfatal connection errors should cancel async opens.
 
 By default, if a nonfatal connection error such as a connection timing out occurs, any currently pending asyncOpen operations will ignore the error and continue to retry until it succeeds. If this is set to true, the open will instead fail and report the error.
 
 FIXME: This should probably be true by default in the next major version.
 */
@property (nonatomic) bool cancelAsyncOpenOnNonFatalErrors;

/// :nodoc:
- (instancetype)initWithUser:(RLMUser *)user
              partitionValue:(nullable id<RLMBSON>)partitionValue __attribute__((unavailable("Use [RLMUser configurationWithPartitionValue:] instead")));

/// :nodoc:
+ (RLMRealmConfiguration *)automaticConfiguration __attribute__((unavailable("Use [RLMUser configuration] instead")));

/// :nodoc:
+ (RLMRealmConfiguration *)automaticConfigurationForUser:(RLMUser *)user __attribute__((unavailable("Use [RLMUser configuration] instead")));

/// :nodoc:
- (instancetype)init __attribute__((unavailable("This type cannot be created directly")));

/// :nodoc:
+ (instancetype)new __attribute__((unavailable("This type cannot be created directly")));

@end

NS_ASSUME_NONNULL_END
