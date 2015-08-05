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

#import <Foundation/Foundation.h>
#import <Realm/RLMRealm.h>

RLM_ASSUME_NONNULL_BEGIN

/**
 An `RLMConfiguration` is used to describe the different options used to
 create an `RLMRealm` instance.
 */
@interface RLMConfiguration : NSObject<NSCopying>

/**
 Returns the default configuration used to create realms.

 @return The default realm configuration.
 */
+ (instancetype)defaultConfiguration;

/**
 Sets the default configuration to the given `RLMConfiguration`.

 @param configuration The new default realm configuration.
 */
+ (void)setDefaultConfiguration:(nullable RLMConfiguration *)configuration;

/// The path to the realm file.
@property (nonatomic, copy, nullable) NSString *path;

/// A string used to identify a particular in-memory Realm.
@property (nonatomic, copy, nullable) NSString *inMemoryIdentifier;

/// 64-byte key to use to encrypt the data.
@property (nonatomic, copy, nullable) NSData *encryptionKey;

/// Whether the Realm is read-only (must be YES for read-only files).
@property (nonatomic) BOOL readOnly;

/// The current schema version.
@property (nonatomic) uint64_t schemaVersion;

/// The block which migrates the Realm to the current version.
@property (nonatomic, copy, nullable) RLMMigrationBlock migrationBlock;

@end

RLM_ASSUME_NONNULL_END
