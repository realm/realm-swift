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

#import "RLMRealmConfiguration_Private.h"
#import "RLMTestObjects.h"
#import "RLMUtil.hpp"

@interface RealmConfigurationTests : RLMTestCase

@end

@implementation RealmConfigurationTests

- (void)testDefaultConfiguration {
    RLMRealmConfiguration *defaultConfiguration = [RLMRealmConfiguration defaultConfiguration];
    XCTAssertEqualObjects(defaultConfiguration.path, [RLMRealmConfiguration defaultRealmPath]);
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
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    configuration.path = @"path";
    [RLMRealmConfiguration setDefaultConfiguration:configuration];
    XCTAssertEqual(RLMRealmConfiguration.defaultConfiguration.path, @"path");
}

- (void)testSetDefaultConfigurationAfterRegistingPerPathThrows {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (!RLMIsDebuggerAttached()) {
        [RLMRealm setEncryptionKey:RLMGenerateKey() forRealmsAtPath:@"path"];
        RLMAssertThrowsWithReasonMatching([RLMRealmConfiguration setDefaultConfiguration:[RLMRealmConfiguration new]], @"per-path");
    }

    [RLMRealmConfiguration resetRealmConfigurationState];

    [RLMRealm setSchemaVersion:1 forRealmAtPath:@"path" withMigrationBlock:nil];
    RLMAssertThrowsWithReasonMatching([RLMRealmConfiguration setDefaultConfiguration:[RLMRealmConfiguration new]], @"per-path");
#pragma clang diagnostic pop
}

- (void)testSetPathAndInMemoryIdentifierAreMutuallyExclusive {
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];

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
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];

    if (!RLMIsDebuggerAttached()) {
        RLMAssertThrowsWithReasonMatching(configuration.encryptionKey = [NSData data], @"Encryption key must be exactly 64 bytes long");

        NSData *key = RLMGenerateKey();
        configuration.encryptionKey = key;
        XCTAssertEqual(configuration.encryptionKey, key);
    }

    XCTAssertNoThrow(configuration.encryptionKey = nil);
}

- (void)testSchemaVersionIsValidated {
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];

    RLMAssertThrowsWithReasonMatching(configuration.schemaVersion = RLMNotVersioned, @"schema version.*RLMNotVersioned");

    configuration.schemaVersion = 1;
    XCTAssertEqual(configuration.schemaVersion, 1U);
}

- (void)testClassSubsetsValidateLinks {
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];

    XCTAssertThrows(configuration.objectClasses = @[LinkStringObject.class]);
    XCTAssertNoThrow(configuration.objectClasses = (@[LinkStringObject.class, StringObject.class]));

    XCTAssertThrows(configuration.objectClasses = @[CompanyObject.class]);
    XCTAssertNoThrow(configuration.objectClasses = (@[CompanyObject.class, EmployeeObject.class]));
}

@end
