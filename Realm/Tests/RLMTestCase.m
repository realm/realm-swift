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

#import "RLMRealmConfiguration_Private.h"
#import <Realm/RLMRealm_Private.h>
#import <Realm/RLMSchema_Private.h>
#import <Realm/RLMProperty_Private.h>
#import <objc/runtime.h>
#import <stdalign.h>

static NSString *documentsDir() {
#if TARGET_OS_IPHONE
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
#else
    NSString *path = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0];
    return [path stringByAppendingPathComponent:[[[NSBundle mainBundle] executablePath] lastPathComponent]];
#endif
}

NSString *RLMRealmPathForFile(NSString *fileName) {
    return [documentsDir() stringByAppendingPathComponent:fileName];
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

@implementation RLMTestCase {
    dispatch_queue_t _bgQueue;
}

+ (void)setUp {
    [super setUp];
#if DEBUG || !TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    // Disable actually syncing anything to the disk to greatly speed up the
    // tests, but only when not running on device because it can't be
    // re-enabled and we need it enabled for performance tests
    RLMDisableSyncToDisk();
#endif
    [self preintializeSchema];

    // Ensure the documents directory exists as it sometimes doesn't after
    // resetting the simulator
    [NSFileManager.defaultManager createDirectoryAtPath:documentsDir() withIntermediateDirectories:YES attributes:nil error:nil];
}

- (void)setUp {
    @autoreleasepool {
        [super setUp];
        [self deleteFiles];

        if (encryptTests()) {
            RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
            configuration.encryptionKey = RLMGenerateKey();
        }
    }
}

- (void)tearDown {
    @autoreleasepool {
        [super tearDown];
        if (_bgQueue) {
            dispatch_sync(_bgQueue, ^{});
            _bgQueue = nil;
        }
        [self deleteFiles];
    }
}

// This ensures the shared schema is initialized outside of of a test case,
// so if an exception is thrown, it will kill the test process rather than
// allowing hundreds of test cases to fail in strange ways
// This is overridden by RLMMultiProcessTestCase to support testing the schema init
+ (void)preintializeSchema {
    [RLMSchema sharedSchema];
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
    return [RLMRealm realmWithPath:RLMTestRealmPath()];
}

- (RLMRealm *)realmWithTestPathAndSchema:(RLMSchema *)schema {
    return [RLMRealm realmWithPath:RLMTestRealmPath() key:nil readOnly:NO inMemory:NO dynamic:YES schema:schema error:nil];
}

- (RLMRealm *)inMemoryRealmWithIdentifier:(NSString *)identifier {
    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.inMemoryIdentifier = identifier;
    return [RLMRealm realmWithConfiguration:configuration error:nil];
}

- (RLMRealm *)readOnlyRealmWithPath:(NSString *)path error:(NSError **)error {
    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.path = path;
    configuration.readOnly = true;
    return [RLMRealm realmWithConfiguration:configuration error:error];
}

- (void)waitForNotification:(NSString *)expectedNote realm:(RLMRealm *)realm block:(dispatch_block_t)block {
    XCTestExpectation *notificationFired = [self expectationWithDescription:@"notification fired"];
    RLMNotificationToken *token = [realm addNotificationBlock:^(NSString *note, RLMRealm *realm) {
        XCTAssertNotNil(note, @"Note should not be nil");
        XCTAssertNotNil(realm, @"Realm should not be nil");
        if (note == expectedNote) { // Check pointer equality to ensure we're using the interned string constant
            [notificationFired fulfill];
        }
    }];

    dispatch_queue_t queue = dispatch_queue_create("background", 0);
    dispatch_async(queue, ^{
        @autoreleasepool {
            block();
        }
    });

    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // wait for queue to finish
    dispatch_sync(queue, ^{});

    [realm removeNotification:token];
}

- (void)dispatchAsync:(dispatch_block_t)block {
    if (!_bgQueue) {
        _bgQueue = dispatch_queue_create("test background queue", 0);
    }
    dispatch_async(_bgQueue, ^{
        @autoreleasepool {
            block();
        }
    });
}

- (void)dispatchAsyncAndWait:(dispatch_block_t)block {
    [self dispatchAsync:block];
    dispatch_sync(_bgQueue, ^{});
}

- (id)nonLiteralNil
{
    return nil;
}

// TODO: add support for indexedProperties, ignoredProperties, primaryKey
- (Class)runtimeClassWithName:(NSString *)className properties:(NSArray *)properties {
    Class objectClass = objc_allocateClassPair(RLMObject.class, className.UTF8String, 0);
    for (RLMProperty *property in properties) {
        char *type = nil;
        if (property.type == RLMPropertyTypeObject) {
            type = (char *)[[NSString stringWithFormat:@"@\"%@\"", property.objectClassName] UTF8String];
        } else if (property.type == RLMPropertyTypeArray) {
            type = (char *)[[NSString stringWithFormat:@"@\"RLMArray<%@>\"", property.objectClassName] UTF8String];
        } else {
            type = malloc(2*sizeof(char));
            type[0] = property.objcType;
            type[1] = '\0';
        }
        objc_property_attribute_t propertyAttributes[] = {
            { "T",  type },
        };
        size_t typeSize = 0;
        uint8_t typeAlignment = 0;
        switch (property.type) {
            case RLMPropertyTypeString:
            case RLMPropertyTypeData:
            case RLMPropertyTypeAny:
            case RLMPropertyTypeDate:
            case RLMPropertyTypeObject:
            case RLMPropertyTypeArray:
                typeSize = sizeof(id);
                typeAlignment = alignof(id);
                break;
            case RLMPropertyTypeInt:
                typeSize = sizeof(int);
                typeAlignment = alignof(int);
                break;
            case RLMPropertyTypeBool:
                typeSize = sizeof(char);
                typeAlignment = alignof(char);
                break;
            case RLMPropertyTypeFloat:
                typeSize = sizeof(float);
                typeAlignment = alignof(float);
                break;
            case RLMPropertyTypeDouble:
                typeSize = sizeof(double);
                typeAlignment = alignof(double);
                break;
        }
        class_addIvar(objectClass, property.name.UTF8String, typeSize, typeAlignment, type);
        class_addProperty(objectClass, property.name.UTF8String, propertyAttributes, sizeof(propertyAttributes) / sizeof(objc_property_attribute_t));
    }
    objc_registerClassPair(objectClass);
    return objectClass;
}

@end
