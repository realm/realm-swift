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

#import <Realm/RLMRealm.h>

/**
 The current state of the session represented by a session object.
 */
typedef NS_ENUM(NSUInteger, RLMSyncSessionState) {
    /// The sync session is actively communicating or attempting to communicate
    /// with MongoDB Realm. A session is considered Active even if
    /// it is not currently connected. Check the connection state instead if you
    /// wish to know if the connection is currently online.
    RLMSyncSessionStateActive,
    /// The sync session is not attempting to communicate with MongoDB
    /// Realm due to the user logging out or synchronization being paused.
    RLMSyncSessionStateInactive,
    /// The sync session encountered a fatal error and is permanently invalid; it should be discarded.
    RLMSyncSessionStateInvalid
};

/**
 The current state of a sync session's connection. Sessions which are not in
 the Active state will always be Disconnected.
 */
typedef NS_ENUM(NSUInteger, RLMSyncConnectionState) {
    /// The sync session is not connected to the server, and is not attempting
    /// to connect, either because the session is inactive or because it is
    /// waiting to retry after a failed connection.
    RLMSyncConnectionStateDisconnected,
    /// The sync session is attempting to connect to MongoDB Realm.
    RLMSyncConnectionStateConnecting,
    /// The sync session is currently connected to MongoDB Realm.
    RLMSyncConnectionStateConnected,
};

/**
 The transfer direction (upload or download) tracked by a given progress notification block.

 Progress notification blocks can be registered on sessions if your app wishes to be informed
 how many bytes have been uploaded or downloaded, for example to show progress indicator UIs.
 */
typedef RLM_CLOSED_ENUM(NSUInteger, RLMSyncProgressDirection) {
    /// For monitoring upload progress.
    RLMSyncProgressDirectionUpload,
    /// For monitoring download progress.
    RLMSyncProgressDirectionDownload,
};

/**
 The desired behavior of a progress notification block.

 Progress notification blocks can be registered on sessions if your app wishes to be informed
 how many bytes have been uploaded or downloaded, for example to show progress indicator UIs.
 */
typedef NS_ENUM(NSUInteger, RLMSyncProgressMode) {
    /**
     The block will be called indefinitely, or until it is unregistered by calling
     `-[RLMProgressNotificationToken invalidate]`.

     Notifications will always report the latest number of transferred bytes, and the
     most up-to-date number of total transferrable bytes.
     */
    RLMSyncProgressModeReportIndefinitely,
    /**
     The block will, upon registration, store the total number of bytes
     to be transferred. When invoked, it will always report the most up-to-date number
     of transferrable bytes out of that original number of transferrable bytes.

     When the number of transferred bytes reaches or exceeds the
     number of transferrable bytes, the block will be unregistered.
     */
    RLMSyncProgressModeForCurrentlyOutstandingWork,
};

@class RLMUser, RLMSyncConfiguration, RLMSyncErrorActionToken, RLMSyncManager;

/**
 The type of a progress notification block intended for reporting a session's network
 activity to the user.

 `transferredBytes` refers to the number of bytes that have been uploaded or downloaded.
 `transferrableBytes` refers to the total number of bytes transferred, and pending transfer.
 */
typedef void(^RLMProgressNotificationBlock)(NSUInteger transferredBytes, NSUInteger transferrableBytes);

NS_ASSUME_NONNULL_BEGIN

/**
 A token object corresponding to a progress notification block on a session object.

 To stop notifications manually, call `-invalidate` on it. Notifications should be stopped before
 the token goes out of scope or is destroyed.
 */
@interface RLMProgressNotificationToken : RLMNotificationToken
@end

/**
 An object encapsulating a MongoDB Realm "session". Sessions represent the
 communication between the client (and a local Realm file on disk), and the server
 (and a remote Realm with a given partition value stored on MongoDB Realm).

 Sessions are always created by the SDK and vended out through various APIs. The
 lifespans of sessions associated with Realms are managed automatically. Session
 objects can be accessed from any thread.
 */
@interface RLMSyncSession : NSObject

/// The session's current state.
///
/// This property is not KVO-compliant.
@property (nonatomic, readonly) RLMSyncSessionState state;

/// The session's current connection state.
///
/// This property is KVO-compliant and can be observed to be notified of changes.
/// Be warned that KVO observers for this property may be called on a background
/// thread.
@property (atomic, readonly) RLMSyncConnectionState connectionState;

/// The user that owns this session.
- (nullable RLMUser *)parentUser;

/**
 If the session is valid, return a sync configuration that can be used to open the Realm
 associated with this session.
 */
- (nullable RLMSyncConfiguration *)configuration;

/**
 Temporarily suspend syncronization and disconnect from the server.

 The session will not attempt to connect to MongoDB Realm until `resume`
 is called or the Realm file is closed and re-opened.
 */
- (void)suspend;

/**
 Resume syncronization and reconnect to MongoDB Realm after suspending.

 This is a no-op if the session was already active or if the session is invalid.
 Newly created sessions begin in the Active state and do not need to be resumed.
 */
- (void)resume;

/**
 Register a progress notification block.

 Multiple blocks can be registered with the same session at once. Each block
 will be invoked on a side queue devoted to progress notifications.

 If the session has already received progress information from the
 synchronization subsystem, the block will be called immediately. Otherwise, it
 will be called as soon as progress information becomes available.

 The token returned by this method must be retained as long as progress
 notifications are desired, and the `-invalidate` method should be called on it
 when notifications are no longer needed and before the token is destroyed.

 If no token is returned, the notification block will never be called again.
 There are a number of reasons this might be true. If the session has previously
 experienced a fatal error it will not accept progress notification blocks. If
 the block was configured in the `RLMSyncProgressForCurrentlyOutstandingWork`
 mode but there is no additional progress to report (for example, the number
 of transferrable bytes and transferred bytes are equal), the block will not be
 called again.

 @param direction The transfer direction (upload or download) to track in this progress notification block.
 @param mode      The desired behavior of this progress notification block.
 @param block     The block to invoke when notifications are available.

 @return A token which must be held for as long as you want notifications to be delivered.

 @see `RLMSyncProgressDirection`, `RLMSyncProgress`, `RLMProgressNotificationBlock`, `RLMProgressNotificationToken`
 */
- (nullable RLMProgressNotificationToken *)addProgressNotificationForDirection:(RLMSyncProgressDirection)direction
                                                                          mode:(RLMSyncProgressMode)mode
                                                                         block:(RLMProgressNotificationBlock)block
NS_REFINED_FOR_SWIFT;

/**
 Given an error action token, immediately handle the corresponding action.
 
 @see `RLMSyncErrorClientResetError`, `RLMSyncErrorPermissionDeniedError`
 */
+ (void)immediatelyHandleError:(RLMSyncErrorActionToken *)token syncManager:(RLMSyncManager *)syncManager;

/**
 Get the sync session for the given Realm if it is a synchronized Realm, or `nil`
 if it is not.
 */
+ (nullable RLMSyncSession *)sessionForRealm:(RLMRealm *)realm;

@end

// MARK: - Error action token

#pragma mark - Error action token

/**
 An opaque token returned as part of certain errors. It can be
 passed into certain APIs to perform certain actions.

 @see `RLMSyncErrorClientResetError`, `RLMSyncErrorPermissionDeniedError`
 */
@interface RLMSyncErrorActionToken : NSObject

/// :nodoc:
- (instancetype)init __attribute__((unavailable("This type cannot be created directly")));

/// :nodoc:
+ (instancetype)new __attribute__((unavailable("This type cannot be created directly")));

@end

/**
 A task object which can be used to observe or cancel an async open.

 When a synchronized Realm is opened asynchronously, the latest state of the
 Realm is downloaded from the server before the completion callback is invoked.
 This task object can be used to observe the state of the download or to cancel
 it. This should be used instead of trying to observe the download via the sync
 session as the sync session itself is created asynchronously, and may not exist
 yet when -[RLMRealm asyncOpenWithConfiguration:completion:] returns.
 */
@interface RLMAsyncOpenTask : NSObject
/**
 Register a progress notification block.

 Each registered progress notification block is called whenever the sync
 subsystem has new progress data to report until the task is either cancelled
 or the completion callback is called. Progress notifications are delivered on
 the main queue.
 */
- (void)addProgressNotificationBlock:(RLMProgressNotificationBlock)block;

/**
 Register a progress notification block which is called on the given queue.

 Each registered progress notification block is called whenever the sync
 subsystem has new progress data to report until the task is either cancelled
 or the completion callback is called. Progress notifications are delivered on
 the supplied queue.
 */
- (void)addProgressNotificationOnQueue:(dispatch_queue_t)queue
                                 block:(RLMProgressNotificationBlock)block;

/**
 Cancel the asynchronous open.

 Any download in progress will be cancelled, and the completion block for this
 async open will never be called. If multiple async opens on the same Realm are
 happening concurrently, all other opens will fail with the error "operation cancelled".
 */
- (void)cancel;
@end

NS_ASSUME_NONNULL_END
