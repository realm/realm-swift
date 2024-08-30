////////////////////////////////////////////////////////////////////////////
//
// Copyright 2022 Realm Inc.
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

#import <Realm/RLMConstants.h>

@protocol RLMValue;

#pragma mark - Error Domains

/** Error code is a value from the RLMError enum. */
extern NSString *const RLMErrorDomain;

/** An error domain identifying non-specific system errors. */
extern NSString *const RLMUnknownSystemErrorDomain;

#pragma mark - RLMError

/// A user info key containing the name of the error code. This is for
/// debugging purposes only and should not be relied on.
extern NSString *const RLMErrorCodeNameKey;

/**
 `RLMError` is an enumeration representing all recoverable errors. It is
 associated with the Realm error domain specified in `RLMErrorDomain`.
 */
typedef RLM_ERROR_ENUM(NSInteger, RLMError, RLMErrorDomain) {
    /** Denotes a general error that occurred when trying to open a Realm. */
    RLMErrorFail                  = 1,

    /** Denotes a file I/O error that occurred when trying to open a Realm. */
    RLMErrorFileAccess            = 2,

    /**
     Denotes a file permission error that occurred when trying to open a Realm.

     This error can occur if the user does not have permission to open or create
     the specified file in the specified access mode when opening a Realm.
     */
    RLMErrorFilePermissionDenied  = 3,

    /**
     Denotes an error where a file was to be written to disk, but another
     file with the same name already exists.
     */
    RLMErrorFileExists            = 4,

    /**
     Denotes an error that occurs if a file could not be found.

     This error may occur if a Realm file could not be found on disk when
     trying to open a Realm as read-only, or if the directory part of the
     specified path was not found when trying to write a copy.
     */
    RLMErrorFileNotFound          = 5,

    /**
     Denotes an error that occurs if a file format upgrade is required to open
     the file, but upgrades were explicitly disabled or the file is being open
     in read-only mode.
     */
    RLMErrorFileFormatUpgradeRequired = 6,

    /**
     Denotes an error that occurs if the database file is currently open in
     another process which cannot share with the current process due to an
     architecture mismatch.

     This error may occur if trying to share a Realm file between an i386
     (32-bit) iOS Simulator and the Realm Studio application. In this case,
     please use the 64-bit version of the iOS Simulator.
     */
    RLMErrorIncompatibleLockFile  = 8,

    /**
     Denotes an error that occurs when there is insufficient available address
     space to mmap the Realm file.
     */
    RLMErrorAddressSpaceExhausted = 9,

    /**
    Denotes an error that occurs if there is a schema version mismatch and a
    migration is required.
    */
    RLMErrorSchemaMismatch = 10,

    /**
     Denotes an error where an operation was requested which cannot be
     performed on an open file.
     */
    RLMErrorAlreadyOpen = 12,

    /// Denotes an error where an input value was invalid.
    RLMErrorInvalidInput = 13,

    /// Denotes an error where a write failed due to insufficient disk space.
    RLMErrorOutOfDiskSpace = 14,

    /**
     Denotes an error where a Realm file could not be opened because another
     process has opened the same file in a way incompatible with inter-process
     sharing. For example, this can result from opening the backing file for an
     in-memory Realm in non-in-memory mode.
     */
    RLMErrorIncompatibleSession = 15,

    /**
     Denotes an error that occurs if the file is a valid Realm file, but has a
     file format version which is not supported by this version of Realm. This
     typically means that the file was written by a newer version of Realm, but
     may also mean that it is from a pre-1.0 version of Realm (or for
     synchronized files, pre-10.0).
     */
    RLMErrorUnsupportedFileFormatVersion = 16,

    /// A subscription was rejected by the server.
    RLMErrorSubscriptionFailed = 18,

    /// A file operation failed in a way which does not have a more specific error code.
    RLMErrorFileOperationFailed = 19,

    /**
     Denotes an error that occurs if the file being opened is not a valid Realm
     file. Some of the possible causes of this are:
     1. The file at the given URL simply isn't a Realm file at all.
     2. The wrong encryption key was given.
     3. The Realm file is encrypted and no encryption key was given.
     4. The Realm file isn't encrypted but an encryption key was given.
     5. The file on disk has become corrupted.
     */
    RLMErrorInvalidDatabase = 20,

    /**
     Denotes an error that occurs if a Realm is opened in the wrong history
     mode. Typically this means that either a local Realm is being opened as a
     synchronized Realm or vice versa.
     */
    RLMErrorIncompatibleHistories = 21,
};
