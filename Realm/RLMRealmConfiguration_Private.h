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

@class RLMSchema, RLMEventConfiguration;

RLM_HEADER_AUDIT_BEGIN(nullability)

@interface RLMRealmConfiguration ()

@property (nonatomic, readwrite) bool cache;
@property (nonatomic, readwrite) bool dynamic;
@property (nonatomic, readwrite) bool disableFormatUpgrade;
@property (nonatomic, copy, nullable) RLMSchema *customSchema;
@property (nonatomic, copy) NSString *pathOnDisk;
@property (nonatomic, retain, nullable) RLMEventConfiguration *eventConfiguration;
@property (nonatomic, nullable) Class migrationObjectClass;
@property (nonatomic) bool disableAutomaticChangeNotifications;

// Get the default configuration without copying it
+ (RLMRealmConfiguration *)rawDefaultConfiguration;

+ (void)resetRealmConfigurationState;

- (void)setCustomSchemaWithoutCopying:(nullable RLMSchema *)schema;
@end

// Get a path in the platform-appropriate documents directory with the given filename
FOUNDATION_EXTERN NSString *RLMRealmPathForFile(NSString *fileName);
FOUNDATION_EXTERN NSString *RLMRealmPathForFileAndBundleIdentifier(NSString *fileName, NSString *mainBundleIdentifier);

RLM_HEADER_AUDIT_END(nullability)
