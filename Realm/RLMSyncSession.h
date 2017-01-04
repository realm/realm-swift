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

/**
 The current state of a sync session object.
 */
typedef NS_ENUM(NSUInteger, RLMSyncSessionState) {
    /// The sync session is bound to the Realm Object Server and communicating with it.
    RLMSyncSessionStateActive,
    /// The sync session is not currently communicating with the Realm Object Server.
    RLMSyncSessionStateInactive,
    /// The sync session encountered an error and is invalid; it should be discarded.
    RLMSyncSessionStateInvalid
};

@class RLMSyncUser, RLMSyncConfiguration;

typedef void(^RLMProgressNotificationBlock)(NSUInteger downloaded_bytes,
                                            NSNumber * _Nullable downloadable_bytes,
                                            NSUInteger uploaded_bytes,
                                            NSNumber * _Nullable uploadable_bytes);

NS_ASSUME_NONNULL_BEGIN

/**
 A token object corresponding to a progress notifier block on a `RLMSyncSession`. To stop notifications manually,
 destroy the token or call `-stop` on it.
 */
@interface RLMProgressNotificationToken : NSObject

- (void)stop;

@end

/**
 An object encapsulating a Realm Object Server "session". Sessions represent the communication between the client (and a
 local Realm file on disk), and the server (and a remote Realm at a given URL stored on a Realm Object Server).
 
 Sessions are always created by the SDK and vended out through various APIs. The lifespans of sessions associated with
 Realms are managed automatically.
 */
@interface RLMSyncSession : NSObject

/// The session's current state.
@property (nonatomic, readonly) RLMSyncSessionState state;

/// The Realm Object Server URL of the remote Realm this session corresponds to.
@property (nullable, nonatomic, readonly) NSURL *realmURL;

/// The user that owns this session.
- (nullable RLMSyncUser *)parentUser;

/// If the session is valid, return a sync configuration that can be used to open the Realm associated with this
/// session.
- (nullable RLMSyncConfiguration *)configuration;

/**
 Register a progress notification block. Multiple blocks can be registered on the same session at once.

 If `streaming` is YES, the block will be called periodically with the current number of downloaded and uploaded bytes,
 relative to the most recent number of downloadable and uploadable bytes. It will not be automatically unregistered.

 If `streaming` is NO, the block will be called periodically with the current number of downloaded and uploaded bytes,
 relative to the number of downloadable and uploadable bytes at the time the block was registered. Once the number of
 downloaded and uploaded bytes both exceed their downloadable and uploadable counterparts, the block will be
 automatically unregistered and called no longer.

 The token returned by this method can be destroyed if notifications for a given block are no longer desired. If no
 token is returned, the session was not in a state where it could accept progress notifiers.
 */
- (nullable RLMProgressNotificationToken *)addProgressNotificationBlock:(RLMProgressNotificationBlock)block
                                                            isStreaming:(BOOL)streaming NS_REFINED_FOR_SWIFT;
@end

NS_ASSUME_NONNULL_END
