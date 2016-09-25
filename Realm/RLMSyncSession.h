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
    /// The sync session is valid, but has not yet been bound to the Realm Object Server.
    RLMSyncSessionStateUnbound,
    /// The sync session is bound to the Realm Object Server and communicating with it.
    RLMSyncSessionStateActive,
    /// The sync session is logged out, but could be rebound to the Realm Object Server.
    RLMSyncSessionStateLoggedOut,
    /// The sync session encountered an error and is invalid; it should be discarded.
    RLMSyncSessionStateInvalid
};

@class RLMSyncUser, RLMSyncConfiguration;

NS_ASSUME_NONNULL_BEGIN

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
@property (nonatomic, readonly) NSURL *realmURL;

/// A reference to the user object owning the Realm this session corresponds to. If the session object is invalid, this
/// property may automatically be set to `nil`.
@property (nonatomic, weak, nullable, readonly) RLMSyncUser *parentUser;

/// If the session is valid, return a sync configuration that can be used to open the Realm associated with this
/// session.
- (nullable RLMSyncConfiguration *)configuration;

NS_ASSUME_NONNULL_END

@end
