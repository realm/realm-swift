////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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

@interface RLMRealm ()
+ (instancetype)realmWithPath:(NSString *)path
                          key:(NSData *)key
                     readOnly:(BOOL)readonly
                     inMemory:(BOOL)inMemory
                      dynamic:(BOOL)dynamic
                       schema:(RLMSchema *)customSchema
                        error:(NSError **)outError;
+ (void)resetRealmState;
@end

// This ensures the shared schema is initialized outside of of a test case,
// so if an exception is thrown, it will kill the test process rather than
// allowing hundreds of test cases to fail in strange ways
__attribute((constructor))
static void initializeSharedSchema() {
    [RLMSchema class];
}

NSString *RLMRealmPathForFile(NSString *fileName) {
#if TARGET_OS_IPHONE
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
#else
    NSString *path = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0];
    path = [path stringByAppendingPathComponent:[[[NSBundle mainBundle] executablePath] lastPathComponent]];
#endif
    return [path stringByAppendingPathComponent:fileName];
}

NSString *RLMDefaultRealmPath() {
    return RLMRealmPathForFile(@"default.realm");
}

NSString *RLMTestRealmPath() {
    return RLMRealmPathForFile(@"test.realm");
}

static void deleteOrThrow(NSString *path) {
    NSError *error;
    if (![[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
        if (error.code != NSFileNoSuchFileError) {
            @throw [NSException exceptionWithName:@"RLMTestException"
                                           reason:[@"Unable to delete realm: " stringByAppendingString:error.description]
                                         userInfo:nil];
        }
    }
}

NSData *RLMGenerateKey() {
    uint8_t buffer[64];
    SecRandomCopyBytes(kSecRandomDefault, 64, buffer);
    return [[NSData alloc] initWithBytes:buffer length:sizeof(buffer)];
}

static BOOL encryptTests() {
    static BOOL encryptAll = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (getenv("REALM_ENCRYPT_ALL")) {
            encryptAll = YES;
        }
    });
    return encryptAll;
}

@implementation RLMTestCase

- (void)setUp {
    @autoreleasepool {
        [super setUp];
        [self deleteFiles];

        if (encryptTests()) {
            [RLMRealm setEncryptionKey:RLMGenerateKey() forRealmsAtPath:RLMDefaultRealmPath()];
            [RLMRealm setEncryptionKey:RLMGenerateKey() forRealmsAtPath:RLMTestRealmPath()];
        }
    }
}

- (void)tearDown {
    @autoreleasepool {
        [super tearDown];
        [self deleteFiles];
    }
}

- (void)deleteFiles {
    // Clear cache
    [RLMRealm resetRealmState];

    // Delete Realm files
    [self deleteRealmFileAtPath:RLMDefaultRealmPath()];
    [self deleteRealmFileAtPath:RLMTestRealmPath()];
}

- (void)deleteRealmFileAtPath:(NSString *)path
{
    deleteOrThrow(path);
    deleteOrThrow([path stringByAppendingString:@".lock"]);
    deleteOrThrow([path stringByAppendingString:@".note"]);
}

- (void)invokeTest {
    @autoreleasepool {
        [super invokeTest];
    }
}

- (RLMRealm *)realmWithTestPath
{
    return [RLMRealm realmWithPath:RLMTestRealmPath() readOnly:NO error:nil];
}

- (RLMRealm *)realmWithTestPathAndSchema:(RLMSchema *)schema {
    return [RLMRealm realmWithPath:RLMTestRealmPath() key:nil readOnly:NO inMemory:NO dynamic:YES schema:schema error:nil];
}

- (void)waitForNotification:(NSString *)expectedNote realm:(RLMRealm *)realm block:(dispatch_block_t)block {
    XCTestExpectation *notificationFired = [self expectationWithDescription:@"notification fired"];
    RLMNotificationToken *token = [realm addNotificationBlock:^(__unused NSString *note, RLMRealm *realm) {
        XCTAssertNotNil(realm, @"Realm should not be nil");
        if (note == expectedNote) {
            [notificationFired fulfill];
        }
    }];

    dispatch_queue_t queue = dispatch_queue_create("background", 0);
    dispatch_async(queue, block);

    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // wait for queue to finish
    dispatch_sync(queue, ^{});

    [realm removeNotification:token];
}

@end

