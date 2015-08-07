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

#import "RLMTestCase.h"

#import "RLMConfiguration_Private.h"
#import "RLMUtil.hpp"

@interface ConfigurationTests : RLMTestCase

@end

@implementation ConfigurationTests

- (void)testDefaultConfiguration {
    RLMConfiguration *defaultConfiguration = [RLMConfiguration defaultConfiguration];
    XCTAssertEqualObjects(defaultConfiguration.path, [RLMConfiguration defaultRealmPath]);
    XCTAssertNil(defaultConfiguration.inMemoryIdentifier);
    XCTAssertNil(defaultConfiguration.encryptionKey);
    XCTAssertFalse(defaultConfiguration.readOnly);
    XCTAssertEqual(defaultConfiguration.schemaVersion, 0U);
    XCTAssertNil(defaultConfiguration.migrationBlock);

    // private properties
    XCTAssertFalse(defaultConfiguration.dynamic);
    XCTAssertNil(defaultConfiguration.customSchema);
}

- (void)testSetDefaultConfiguration {
    RLMConfiguration *configuration = [[RLMConfiguration alloc] init];
    configuration.path = @"path";
    [RLMConfiguration setDefaultConfiguration:configuration];
    XCTAssertEqual(RLMConfiguration.defaultConfiguration.path, @"path");
}

- (void)testSetDefaultConfigurationAfterRegistingPerPathThrows {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (!RLMIsDebuggerAttached()) {
        [RLMRealm setEncryptionKey:RLMGenerateKey() forRealmsAtPath:@"path"];
        RLMAssertThrowsWithReasonMatching([RLMConfiguration setDefaultConfiguration:nil], @"per-path");
    }

    [RLMConfiguration resetRealmConfigurationState];

    [RLMRealm setSchemaVersion:1 forRealmAtPath:@"path" withMigrationBlock:nil];
    RLMAssertThrowsWithReasonMatching([RLMConfiguration setDefaultConfiguration:nil], @"per-path");
#pragma clang diagnostic pop
}

- (void)testSetDefaultConfigurationtoNilResets {
    RLMConfiguration *configuration = [[RLMConfiguration alloc] init];
    configuration.path = @"path";
    [RLMConfiguration setDefaultConfiguration:configuration];
    [RLMConfiguration setDefaultConfiguration:nil];

    XCTAssertEqual(RLMConfiguration.defaultConfiguration.path, [RLMConfiguration defaultRealmPath]);
}

- (void)testSetPathAndInMemoryIdentifierAreMutuallyExclusive {
    RLMConfiguration *configuration = [[RLMConfiguration alloc] init];

    configuration.inMemoryIdentifier = @"identifier";
    XCTAssertNil(configuration.path);
    configuration.path = nil;
    XCTAssertEqual(configuration.inMemoryIdentifier, @"identifier");

    configuration.path = @"path";
    XCTAssertNil(configuration.inMemoryIdentifier);
    configuration.inMemoryIdentifier = nil;
    XCTAssertEqual(configuration.path, @"path");
}

- (void)testEncryptionKeyIsValidated {
    RLMConfiguration *configuration = [[RLMConfiguration alloc] init];

    if (!RLMIsDebuggerAttached()) {
        RLMAssertThrowsWithReasonMatching(configuration.encryptionKey = [NSData data], @"Encryption key must be exactly 64 bytes long");

        NSData *key = RLMGenerateKey();
        configuration.encryptionKey = key;
        XCTAssertEqual(configuration.encryptionKey, key);
    }

    XCTAssertNoThrow(configuration.encryptionKey = nil);
}

- (void)testSchemaVersionIsValidated {
    RLMConfiguration *configuration = [[RLMConfiguration alloc] init];

    RLMAssertThrowsWithReasonMatching(configuration.schemaVersion = RLMNotVersioned, @"schema version.*RLMNotVersioned");

    configuration.schemaVersion = 1;
    XCTAssertEqual(configuration.schemaVersion, 1U);
}

@end
