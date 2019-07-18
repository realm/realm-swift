////////////////////////////////////////////////////////////////////////////
//
// Copyright 2018 Realm Inc.
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

#import <XCTest/XCTest.h>

#import "RLMSyncTestCase.h"

#import "RLMTestUtils.h"

#define APPLY_PERMISSION(ma_permission, ma_user) do { \
    XCTestExpectation *ex = [self expectationWithDescription:@"apply permission"]; \
    [ma_user applyPermission:ma_permission callback:^(NSError *err) {              \
        XCTAssertNil(err, @"Received an error when applying permission: %@", err); \
        [ex fulfill];                                                              \
    }];                                                                            \
    [self waitForExpectationsWithTimeout:10.0 handler:nil];                        \
} while (0)                                                                        \

@interface ObjectWithPermissions : RLMObject
@property (nonatomic) int value;
@property (nonatomic) RLMArray<RLMPermission *><RLMPermission> *permissions;
@end
@implementation ObjectWithPermissions
@end

@interface LinkToObjectWithPermissions : RLMObject
@property (nonatomic) int value;
@property (nonatomic) ObjectWithPermissions *link;
@property (nonatomic) RLMArray<RLMPermission *><RLMPermission> *permissions;
@end
@implementation LinkToObjectWithPermissions
@end

@interface RLMPermissionsTests : RLMSyncTestCase
@property (nonatomic, strong) RLMSyncUser *userA;
@property (nonatomic, strong) RLMSyncUser *userB;
@property (nonatomic, strong) RLMSyncUser *userC;

@property (nonatomic, strong) void (^errorBlock)(NSError *);
@end

@implementation RLMPermissionsTests

- (void)setUp {
    [super setUp];
    NSString *accountNameBase = [[NSUUID UUID] UUIDString];
    NSString *userNameA = [accountNameBase stringByAppendingString:@"a"];
    self.userA = [self logInUserForCredentials:[RLMSyncTestCase basicCredentialsWithName:userNameA register:YES]
                                        server:[RLMSyncTestCase authServerURL]];

    NSString *userNameB = [accountNameBase stringByAppendingString:@"b"];
    self.userB = [self logInUserForCredentials:[RLMSyncTestCase basicCredentialsWithName:userNameB register:YES]
                                        server:[RLMSyncTestCase authServerURL]];

    NSString *userNameC = [accountNameBase stringByAppendingString:@"c"];
    self.userC = [self logInUserForCredentials:[RLMSyncTestCase basicCredentialsWithName:userNameC register:YES]
                                        server:[RLMSyncTestCase authServerURL]];

    RLMSyncManager.sharedManager.errorHandler = ^(NSError *error, __unused RLMSyncSession *session) {
        if (self.errorBlock) {
            self.errorBlock(error);
            self.errorBlock = nil;
        } else {
            XCTFail(@"Error handler should not be called unless explicitly expected. Error: %@", error);
        }
    };
}

- (void)tearDown {
    [self.userA logOut];
    [self.userB logOut];
    [self.userC logOut];
    RLMSyncManager.sharedManager.errorHandler = nil;
    [super tearDown];
}

#pragma mark - Helper methods

- (BOOL)isPartial {
    return YES;
}

- (NSError *)subscribeToRealm:(RLMRealm *)realm type:(Class)cls where:(NSString *)pred {
    RLMSyncSubscription *sub = [[cls objectsInRealm:realm where:pred] subscribe];
    id ex = [[XCTKVOExpectation alloc] initWithKeyPath:@"state" object:sub expectedValue:@(RLMSyncSubscriptionStateComplete)];
    [self waitForExpectations:@[ex] timeout:20.0];
    return sub.error;
}

- (NSURL *)createRealmWithName:(SEL)sel permissions:(void (^)(RLMRealm *realm))block {
    // Create a new Realm with an admin user
    RLMSyncUser *admin = [self createAdminUserForURL:[RLMSyncTestCase authServerURL]
                                            username:[[NSUUID UUID] UUIDString]];

    auto url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"realm://127.0.0.1:9080/%@", NSStringFromSelector(sel)]];
    RLMRealm *adminRealm = [self openRealmForURL:url user:admin];
    [self addSyncObjectsToRealm:adminRealm descriptions:@[@"child-1", @"child-2", @"child-3"]];
    CHECK_COUNT(3, SyncObject, adminRealm);
    [self waitForUploadsForRealm:adminRealm error:nil];
    [self waitForDownloadsForRealm:adminRealm error:nil];

    // FIXME: we currently need to add a subscription to get the permissions types sent to us
    [adminRealm refresh];
    CHECK_COUNT(0, SyncObject, adminRealm);
    [self subscribeToRealm:adminRealm type:[SyncObject class] where:@"TRUEPREDICATE"];
    CHECK_COUNT(3, SyncObject, adminRealm);

    // Set up permissions on the Realm
    [adminRealm transactionWithBlock:^{ block(adminRealm); }];

    // FIXME: we currently need to also add the old realm-level permissions
    RLMSyncPermission *p = [[RLMSyncPermission alloc] initWithRealmPath:[url path]
                                                               identity:self.userA.identity
                                                            accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION(p, admin);
    p = [[RLMSyncPermission alloc] initWithRealmPath:[url path] identity:self.userB.identity
                                         accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION(p, admin);
    p = [[RLMSyncPermission alloc] initWithRealmPath:[url path] identity:self.userC.identity
                                         accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION(p, admin);
    [self waitForSync:adminRealm];

    return url;
}

- (void)waitForSync:(RLMRealm *)realm {
    [self waitForUploadsForRealm:realm error:nil];
    [self waitForDownloadsForRealm:realm error:nil];
    [realm refresh];
}

#pragma mark - Permissions

static RLMPermissionRole *getRole(RLMRealm *realm, NSString *roleName) {
    return [RLMPermissionRole createOrUpdateInRealm:realm withValue:@{@"name": roleName}];
}

static void addUserToRole(RLMRealm *realm, NSString *roleName, NSString *user) {
    [getRole(realm, roleName).users addObject:[RLMPermissionUser userInRealm:realm withIdentity:user]];
}

static void createPermissions(RLMArray<RLMPermission> *permissions) {
    auto permission = [RLMPermission permissionForRoleNamed:@"everyone" inArray:permissions];
    permission.canCreate = false;
    permission.canRead = false;
    permission.canQuery = false;
    permission.canDelete = false;
    permission.canUpdate = false;
    permission.canModifySchema = false;
    permission.canSetPermissions = false;

    permission = [RLMPermission permissionForRoleNamed:@"reader" inArray:permissions];
    permission.canRead = true;
    permission.canQuery = true;

    permission = [RLMPermission permissionForRoleNamed:@"writer" inArray:permissions];
    permission.canUpdate = true;
    permission.canCreate = true;
    permission.canDelete = true;

    permission = [RLMPermission permissionForRoleNamed:@"admin" inArray:permissions];
    permission.canSetPermissions = true;
}

#define CHECK_REALM_PRIVILEGE(realm, ...) do { \
    RLMRealmPrivileges expected{__VA_ARGS__}; \
    auto actual = [realm privilegesForRealm]; \
    XCTAssertEqual(expected.read, actual.read); \
    XCTAssertEqual(expected.update, actual.update); \
    XCTAssertEqual(expected.setPermissions, actual.setPermissions); \
    XCTAssertEqual(expected.modifySchema, actual.modifySchema); \
} while (0)

#define CHECK_CLASS_PRIVILEGE(realm, ...) do { \
    RLMClassPrivileges expected{__VA_ARGS__}; \
    auto actual = [realm privilegesForClass:SyncObject.class]; \
    XCTAssertEqual(expected.read, actual.read); \
    XCTAssertEqual(expected.create, actual.create); \
    XCTAssertEqual(expected.update, actual.update); \
    XCTAssertEqual(expected.subscribe, actual.subscribe); \
    XCTAssertEqual(expected.setPermissions, actual.setPermissions); \
} while (0)

#define CHECK_OBJECT_PRIVILEGE(realm, ...) do { \
    RLMObjectPrivileges expected{__VA_ARGS__}; \
    auto actual = [realm privilegesForObject:[SyncObject allObjectsInRealm:realm].firstObject]; \
    XCTAssertEqual(expected.read, actual.read); \
    XCTAssertEqual(expected.del, actual.del); \
    XCTAssertEqual(expected.update, actual.update); \
    XCTAssertEqual(expected.setPermissions, actual.setPermissions); \
} while (0)

- (void)testRealmReadAccess {
    NSURL *url = [self createRealmWithName:_cmd permissions:^(RLMRealm *realm) {
        createPermissions([RLMRealmPermission objectInRealm:realm].permissions);
        addUserToRole(realm, @"reader", self.userA.identity);
    }];

    // userA should now be able to open the Realm and see objects
    RLMRealm *userARealm = [self openRealmForURL:url user:self.userA];
    [self subscribeToRealm:userARealm type:[SyncObject class] where:@"TRUEPREDICATE"];
    CHECK_REALM_PRIVILEGE(userARealm, .read = true);
    CHECK_CLASS_PRIVILEGE(userARealm, .read = true, .subscribe = true);
    CHECK_OBJECT_PRIVILEGE(userARealm, .read = true);

    // userA should not be able to create new objects
    CHECK_COUNT(3, SyncObject, userARealm);
    [self addSyncObjectsToRealm:userARealm descriptions:@[@"child-4", @"child-5", @"child-6"]];
    CHECK_COUNT(6, SyncObject, userARealm);
    [self waitForSync:userARealm];
    CHECK_COUNT(3, SyncObject, userARealm);

    // userB should not be able to read any objects
    RLMRealm *userBRealm = [self openRealmForURL:url user:self.userB];
    [self subscribeToRealm:userBRealm type:[SyncObject class] where:@"TRUEPREDICATE"];
    CHECK_REALM_PRIVILEGE(userBRealm, .read = false);
    CHECK_CLASS_PRIVILEGE(userBRealm, .read = false);
    CHECK_COUNT(0, SyncObject, userBRealm);
}

- (void)testRealmWriteAccess {
    NSURL *url = [self createRealmWithName:_cmd permissions:^(RLMRealm *realm) {
        createPermissions([RLMRealmPermission objectInRealm:realm].permissions);

        addUserToRole(realm, @"reader", self.userA.identity);
        addUserToRole(realm, @"writer", self.userA.identity);

        addUserToRole(realm, @"reader", self.userB.identity);
    }];

    // userA should be able to add objects
    RLMRealm *userARealm = [self openRealmForURL:url user:self.userA];
    [self subscribeToRealm:userARealm type:[SyncObject class] where:@"TRUEPREDICATE"];
    CHECK_REALM_PRIVILEGE(userARealm, .read = true, .update = true);
    CHECK_CLASS_PRIVILEGE(userARealm, .read = true, .subscribe = true,
                          .update = true, .create = true, .setPermissions = true);
    CHECK_OBJECT_PRIVILEGE(userARealm, .read = true, .update = true, .del = true, .setPermissions = true);

    CHECK_COUNT(3, SyncObject, userARealm);
    [self addSyncObjectsToRealm:userARealm descriptions:@[@"child-4", @"child-5", @"child-6"]];
    CHECK_COUNT(6, SyncObject, userARealm);
    [self waitForSync:userARealm];
    CHECK_COUNT(6, SyncObject, userARealm);

    // userB's insertions should be reverted
    RLMRealm *userBRealm = [self openRealmForURL:url user:self.userB];
    [self subscribeToRealm:userBRealm type:[SyncObject class] where:@"TRUEPREDICATE"];
    CHECK_REALM_PRIVILEGE(userBRealm, .read = true);
    CHECK_CLASS_PRIVILEGE(userBRealm, .read = true, .subscribe = true);
    CHECK_OBJECT_PRIVILEGE(userBRealm, .read = true);

    CHECK_COUNT(6, SyncObject, userBRealm);
    [self addSyncObjectsToRealm:userBRealm descriptions:@[@"child-4", @"child-5", @"child-6"]];
    CHECK_COUNT(9, SyncObject, userBRealm);
    [self waitForSync:userBRealm];
    CHECK_COUNT(6, SyncObject, userBRealm);
}

- (void)testRealmManagePermissions {
    // FIXME: this test is wrong; setPermission doesn't govern adding users to roles
#if 0
    NSURL *url = [self createRealmWithName:_cmd permissions:^(RLMRealm *realm) {
        createPermissions([RLMRealmPermission objectInRealm:realm].permissions);

        addUserToRole(realm, @"reader", self.userA.identity);
        addUserToRole(realm, @"writer", self.userA.identity);
        addUserToRole(realm, @"admin", self.userA.identity);

        addUserToRole(realm, @"reader", self.userB.identity);
        addUserToRole(realm, @"writer", self.userB.identity);

        addUserToRole(realm, @"reader", self.userC.identity);
    }];

    RLMRealm *userARealm = [self openRealmForURL:url user:self.userA];
    RLMRealm *userBRealm = [self openRealmForURL:url user:self.userB];
    RLMRealm *userCRealm = [self openRealmForURL:url user:self.userC];

    // userC should initially not be able to write to the Realm
    [self subscribeToRealm:userCRealm type:[SyncObject class] where:@"TRUEPREDICATE"];
    CHECK_REALM_PRIVILEGE(userCRealm, .read = true);
    CHECK_CLASS_PRIVILEGE(userCRealm, .read = true, .subscribe = true);
    CHECK_OBJECT_PRIVILEGE(userCRealm, .read = true);

    [self addSyncObjectsToRealm:userCRealm descriptions:@[@"child-4", @"child-5", @"child-6"]];
    [self waitForSync:userCRealm];
    CHECK_COUNT(3, SyncObject, userCRealm);

    // userB should not be able to grant write permissions to userC
    [userBRealm transactionWithBlock:^{
        addUserToRole(userBRealm, @"writer", self.userC.identity);
    }];
    [self waitForSync:userBRealm];
    [self waitForSync:userCRealm];

    CHECK_REALM_PRIVILEGE(userCRealm, .read = true);
    CHECK_CLASS_PRIVILEGE(userCRealm, .read = true, .subscribe = true);
    CHECK_OBJECT_PRIVILEGE(userCRealm, .read = true);
    [self addSyncObjectsToRealm:userCRealm descriptions:@[@"child-4", @"child-5", @"child-6"]];
    [self waitForSync:userCRealm];
    CHECK_COUNT(3, SyncObject, userCRealm);

    // userA should be able to grant write permissions to userC
    [userARealm transactionWithBlock:^{
        addUserToRole(userARealm, @"writer", self.userC.identity);
    }];
    [self waitForSync:userARealm];
    [self waitForSync:userCRealm];

    CHECK_REALM_PRIVILEGE(userCRealm, .read = true, .update = true);
    CHECK_CLASS_PRIVILEGE(userCRealm, .read = true, .subscribe = true, .update = true, .create = true);
    CHECK_OBJECT_PRIVILEGE(userCRealm, .read = true, .update = true, .del = true);
    [self addSyncObjectsToRealm:userCRealm descriptions:@[@"child-4", @"child-5", @"child-6"]];
    [self waitForSync:userCRealm];
    CHECK_COUNT(6, SyncObject, userCRealm);
#endif
}

- (void)testRealmModifySchema {
    // awkward to test due to that reverts will normally crash
    // probably need to spawn a child process?
}

- (void)testClassRead {
    NSURL *url = [self createRealmWithName:_cmd permissions:^(RLMRealm *realm) {
        createPermissions([RLMClassPermission objectInRealm:realm forClass:SyncObject.class].permissions);
        addUserToRole(realm, @"reader", self.userA.identity);
    }];

    // userA should now be able to open the Realm and see objects
    RLMRealm *userARealm = [self openRealmForURL:url user:self.userA];
    [self subscribeToRealm:userARealm type:[SyncObject class] where:@"TRUEPREDICATE"];
    CHECK_REALM_PRIVILEGE(userARealm, .read = true, .update = true, .setPermissions = true, .modifySchema = true);
    CHECK_CLASS_PRIVILEGE(userARealm, .read = true, .subscribe = true);
    CHECK_OBJECT_PRIVILEGE(userARealm, .read = true);
    CHECK_COUNT(3, SyncObject, userARealm);

    // userA should not be able to create new objects
    [self addSyncObjectsToRealm:userARealm descriptions:@[@"child-4", @"child-5", @"child-6"]];
    CHECK_COUNT(6, SyncObject, userARealm);
    [self waitForSync:userARealm];
    CHECK_COUNT(3, SyncObject, userARealm);

    // userB should not be able to read any objects
    RLMRealm *userBRealm = [self openRealmForURL:url user:self.userB];
    [self subscribeToRealm:userBRealm type:[SyncObject class] where:@"TRUEPREDICATE"];
    CHECK_REALM_PRIVILEGE(userBRealm, .read = true, .update = true, .setPermissions = true, .modifySchema = true);
    CHECK_CLASS_PRIVILEGE(userBRealm, .read = false);
    CHECK_COUNT(0, SyncObject, userBRealm);
}

- (void)testClassUpdate {
    NSURL *url = [self createRealmWithName:_cmd permissions:^(RLMRealm *realm) {
        createPermissions([RLMClassPermission objectInRealm:realm forClass:SyncObject.class].permissions);

        addUserToRole(realm, @"reader", self.userA.identity);
        addUserToRole(realm, @"writer", self.userA.identity);

        addUserToRole(realm, @"reader", self.userB.identity);
    }];

    // userA should be able to mutate objects
    RLMRealm *userARealm = [self openRealmForURL:url user:self.userA];
    [self subscribeToRealm:userARealm type:[SyncObject class] where:@"TRUEPREDICATE"];
    CHECK_REALM_PRIVILEGE(userARealm, .read = true, .update = true, .setPermissions = true, .modifySchema = true);
    CHECK_CLASS_PRIVILEGE(userARealm, .read = true, .subscribe = true, .update = true, .create = true);
    CHECK_OBJECT_PRIVILEGE(userARealm, .read = true, .update = true, .del = true, .setPermissions = true);

    SyncObject *objA = [SyncObject allObjectsInRealm:userARealm].firstObject;
    [userARealm transactionWithBlock:^{
        objA.stringProp = @"new value";
    }];
    [self waitForSync:userARealm];
    XCTAssertEqualObjects(objA.stringProp, @"new value");

    // userB's mutations should be reverted
    RLMRealm *userBRealm = [self openRealmForURL:url user:self.userB];
    [self subscribeToRealm:userBRealm type:[SyncObject class] where:@"TRUEPREDICATE"];
    CHECK_REALM_PRIVILEGE(userBRealm, .read = true, .update = true, .setPermissions = true, .modifySchema = true);
    CHECK_CLASS_PRIVILEGE(userBRealm, .read = true, .subscribe = true);
    CHECK_OBJECT_PRIVILEGE(userBRealm, .read = true);

    SyncObject *objB = [SyncObject allObjectsInRealm:userBRealm].firstObject;
    [userBRealm transactionWithBlock:^{
        objB.stringProp = @"new value 2";
    }];
    XCTAssertEqualObjects(objB.stringProp, @"new value 2");
    [self waitForSync:userBRealm];
    XCTAssertEqualObjects(objB.stringProp, @"new value");
}

- (void)testClassCreate {
    NSURL *url = [self createRealmWithName:_cmd permissions:^(RLMRealm *realm) {
        createPermissions([RLMClassPermission objectInRealm:realm forClass:SyncObject.class].permissions);

        addUserToRole(realm, @"reader", self.userA.identity);
        addUserToRole(realm, @"writer", self.userA.identity);

        addUserToRole(realm, @"reader", self.userB.identity);
    }];

    // userA should be able to add objects
    RLMRealm *userARealm = [self openRealmForURL:url user:self.userA];
    [self subscribeToRealm:userARealm type:[SyncObject class] where:@"TRUEPREDICATE"];
    CHECK_REALM_PRIVILEGE(userARealm, .read = true, .update = true, .setPermissions = true, .modifySchema = true);
    CHECK_CLASS_PRIVILEGE(userARealm, .read = true, .subscribe = true, .update = true, .create = true);
    CHECK_OBJECT_PRIVILEGE(userARealm, .read = true, .update = true, .del = true, .setPermissions = true);

    CHECK_COUNT(3, SyncObject, userARealm);
    [self addSyncObjectsToRealm:userARealm descriptions:@[@"child-4", @"child-5", @"child-6"]];
    CHECK_COUNT(6, SyncObject, userARealm);
    [self waitForSync:userARealm];
    CHECK_COUNT(6, SyncObject, userARealm);

    // userB's insertions should be reverted
    RLMRealm *userBRealm = [self openRealmForURL:url user:self.userB];
    [self subscribeToRealm:userBRealm type:[SyncObject class] where:@"TRUEPREDICATE"];
    CHECK_REALM_PRIVILEGE(userBRealm, .read = true, .update = true, .setPermissions = true, .modifySchema = true);
    CHECK_CLASS_PRIVILEGE(userBRealm, .read = true, .subscribe = true);
    CHECK_OBJECT_PRIVILEGE(userBRealm, .read = true);

    CHECK_COUNT(6, SyncObject, userBRealm);
    [self addSyncObjectsToRealm:userBRealm descriptions:@[@"child-4", @"child-5", @"child-6"]];
    CHECK_COUNT(9, SyncObject, userBRealm);
    [self waitForSync:userBRealm];
    CHECK_COUNT(6, SyncObject, userBRealm);
}

- (void)testClassSetPermissions {
    NSURL *url = [self createRealmWithName:_cmd permissions:^(RLMRealm *realm) {
        createPermissions([RLMClassPermission objectInRealm:realm forClass:SyncObject.class].permissions);

        addUserToRole(realm, @"reader", self.userA.identity);
        addUserToRole(realm, @"writer", self.userA.identity);
        addUserToRole(realm, @"admin", self.userA.identity);

        addUserToRole(realm, @"reader", self.userB.identity);
        addUserToRole(realm, @"writer", self.userB.identity);

        addUserToRole(realm, @"reader", self.userC.identity);
    }];

    // Despite having write access userB should not be able to add "update" access to "reader"
    RLMRealm *userBRealm = [self openRealmForURL:url user:self.userB];
    [self subscribeToRealm:userBRealm type:[SyncObject class] where:@"TRUEPREDICATE"];
    [userBRealm transactionWithBlock:^{
        auto permission = [RLMPermission permissionForRoleNamed:@"reader" onClass:SyncObject.class realm:userBRealm];
        permission.canCreate = true;
        permission.canUpdate = true;

    }];
    [self waitForSync:userBRealm];

    // userC should be unable to create objects
    RLMRealm *userCRealm = [self openRealmForURL:url user:self.userC];
    [self subscribeToRealm:userCRealm type:[SyncObject class] where:@"TRUEPREDICATE"];
    CHECK_REALM_PRIVILEGE(userCRealm, .read = true, .update = true, .setPermissions = true, .modifySchema = true);
    CHECK_CLASS_PRIVILEGE(userCRealm, .read = true, .subscribe = true);
    CHECK_OBJECT_PRIVILEGE(userCRealm, .read = true);

    [self addSyncObjectsToRealm:userCRealm descriptions:@[@"child-4", @"child-5", @"child-6"]];
    CHECK_COUNT(6, SyncObject, userCRealm);
    [self waitForSync:userCRealm];
    CHECK_COUNT(3, SyncObject, userCRealm);

    // userA should able to add "update" access to "reader"
    RLMRealm *userARealm = [self openRealmForURL:url user:self.userA];
    [self subscribeToRealm:userARealm type:[SyncObject class] where:@"TRUEPREDICATE"];
    [userARealm transactionWithBlock:^{
        auto permission = [RLMPermission permissionForRoleNamed:@"reader" onClass:SyncObject.class realm:userARealm];
        permission.canCreate = true;
        permission.canUpdate = true;
    }];
    [self waitForSync:userARealm];

    // userC should now be able to create objects
    [self waitForSync:userCRealm];
    CHECK_CLASS_PRIVILEGE(userCRealm, .read = true, .subscribe = true, .update = true, .create = true);
    CHECK_OBJECT_PRIVILEGE(userCRealm, .read = true, .update = true, .del = true, .setPermissions = true);

    [self addSyncObjectsToRealm:userCRealm descriptions:@[@"child-4", @"child-5", @"child-6"]];
    CHECK_COUNT(6, SyncObject, userCRealm);
    [self waitForSync:userCRealm];
    CHECK_COUNT(6, SyncObject, userCRealm);
}

- (void)testObjectRead {
    NSURL *url = [self createRealmWithName:_cmd permissions:^(RLMRealm *realm) {
        addUserToRole(realm, @"reader", self.userA.identity);
        auto obj1 = [ObjectWithPermissions createInRealm:realm withValue:@[@1]];
        createPermissions(obj1.permissions);
        [ObjectWithPermissions createInRealm:realm withValue:@[@2]];
    }];

    // userA should be able to see both objects
    RLMRealm *userARealm = [self openRealmForURL:url user:self.userA];
    [self subscribeToRealm:userARealm type:[ObjectWithPermissions class] where:@"TRUEPREDICATE"];
    CHECK_COUNT(1, ObjectWithPermissions, userARealm);

    // userB should not be able to read any objects
    RLMRealm *userBRealm = [self openRealmForURL:url user:self.userB];
    [self subscribeToRealm:userBRealm type:[ObjectWithPermissions class] where:@"TRUEPREDICATE"];
    CHECK_COUNT(0, ObjectWithPermissions, userBRealm);
}

- (void)testObjectTransitiveRead {
}

- (void)testObjectUpdate {
    NSURL *url = [self createRealmWithName:_cmd permissions:^(RLMRealm *realm) {
        addUserToRole(realm, @"reader", self.userA.identity);
        addUserToRole(realm, @"reader", self.userB.identity);
        addUserToRole(realm, @"writer", self.userB.identity);
        auto obj1 = [ObjectWithPermissions createInRealm:realm withValue:@[@1]];
        createPermissions(obj1.permissions);
    }];

    RLMRealm *userARealm = [self openRealmForURL:url user:self.userA];
    [self subscribeToRealm:userARealm type:[ObjectWithPermissions class] where:@"TRUEPREDICATE"];
    ObjectWithPermissions *objA = [ObjectWithPermissions allObjectsInRealm:userARealm].firstObject;
    [userARealm transactionWithBlock:^{
        objA.value = 3;
    }];
    [self waitForSync:userARealm];
    XCTAssertEqual(objA.value, 1);

    RLMRealm *userBRealm = [self openRealmForURL:url user:self.userB];
    [self subscribeToRealm:userBRealm type:[ObjectWithPermissions class] where:@"TRUEPREDICATE"];
    ObjectWithPermissions *objB = [ObjectWithPermissions allObjectsInRealm:userBRealm].firstObject;
    [userBRealm transactionWithBlock:^{
        objB.value = 3;
    }];
    [self waitForSync:userBRealm];
    [self waitForSync:userARealm];

    XCTAssertEqual(objA.value, 3);
    XCTAssertEqual(objB.value, 3);
}

- (void)testObjectDelete {
    NSURL *url = [self createRealmWithName:_cmd permissions:^(RLMRealm *realm) {
        addUserToRole(realm, @"reader", self.userA.identity);
        addUserToRole(realm, @"reader", self.userB.identity);
        addUserToRole(realm, @"writer", self.userB.identity);
        auto obj1 = [ObjectWithPermissions createInRealm:realm withValue:@[@1]];
        createPermissions(obj1.permissions);
    }];

    RLMRealm *userARealm = [self openRealmForURL:url user:self.userA];
    [self subscribeToRealm:userARealm type:[ObjectWithPermissions class] where:@"TRUEPREDICATE"];
    ObjectWithPermissions *objA = [ObjectWithPermissions allObjectsInRealm:userARealm].firstObject;
    [userARealm transactionWithBlock:^{
        [userARealm deleteObject:objA];
    }];
    CHECK_COUNT(0, ObjectWithPermissions, userARealm);
    [self waitForSync:userARealm];
    CHECK_COUNT(1, ObjectWithPermissions, userARealm);
    objA = [ObjectWithPermissions allObjectsInRealm:userARealm].firstObject;

    RLMRealm *userBRealm = [self openRealmForURL:url user:self.userB];
    [self subscribeToRealm:userBRealm type:[ObjectWithPermissions class] where:@"TRUEPREDICATE"];
    ObjectWithPermissions *objB = [ObjectWithPermissions allObjectsInRealm:userBRealm].firstObject;
    [userBRealm transactionWithBlock:^{
        [userBRealm deleteObject:objB];
    }];
    [self waitForSync:userBRealm];
    [self waitForSync:userARealm];

    CHECK_COUNT(0, ObjectWithPermissions, userARealm);
    CHECK_COUNT(0, ObjectWithPermissions, userBRealm);
    XCTAssertTrue(objA.invalidated);
    XCTAssertTrue(objB.invalidated);
}

- (void)testObjectSetPermissions {
    NSURL *url = [self createRealmWithName:_cmd permissions:^(RLMRealm *) {}];

    RLMRealm *userARealm = [self openRealmForURL:url user:self.userA];
    [self subscribeToRealm:userARealm type:[ObjectWithPermissions class] where:@"TRUEPREDICATE"];
    [userARealm transactionWithBlock:^{
        auto obj = [ObjectWithPermissions createInRealm:userARealm withValue:@[@1]];
        auto permissions = [RLMPermission permissionForRoleNamed:@"foo" onObject:obj];
        permissions.canRead = true;
        addUserToRole(userARealm, @"foo", self.userB.identity);
    }];

    CHECK_COUNT(1, ObjectWithPermissions, userARealm);
    [self waitForSync:userARealm];
    CHECK_COUNT(0, ObjectWithPermissions, userARealm);

    RLMRealm *userBRealm = [self openRealmForURL:url user:self.userB];
    [self subscribeToRealm:userBRealm type:[ObjectWithPermissions class] where:@"TRUEPREDICATE"];
    CHECK_COUNT(1, ObjectWithPermissions, userBRealm);
}

- (void)testRetrieveClassPermissionsForRenamedClass {
    [self createRealmWithName:_cmd permissions:^(RLMRealm *realm) {
        XCTAssertNotNil([RLMClassPermission objectInRealm:realm forClass:RLMPermissionRole.class]);
    }];
}

@end
