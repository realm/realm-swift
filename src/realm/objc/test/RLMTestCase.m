//
//  RLMTestCase.m
//  Realm
//
//  Created by JP Simard on 4/22/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "RLMTestCase.h"

NSString *const RLMTestRealmPath = @"test.realm";

@implementation RLMTestCase

- (void)setUp {
    // This method is run before every test method
    [super setUp];
    [[NSFileManager defaultManager] removeItemAtPath:RLMTestRealmPath error:nil];
}

+ (void)tearDown {
    // This method is run after all tests in a test method have run
    [[NSFileManager defaultManager] removeItemAtPath:RLMTestRealmPath error:nil];
    [super tearDown];
}

- (RLMRealm *)realmPersistedAtTestPath {
    return [RLMRealm realmWithPath:RLMTestRealmPath];
}

- (RLMRealm *)realmWithTestPath {
    return [RLMRealm realmWithPath:RLMTestRealmPath error:nil];
}

- (void)createTestTableWithWriteBlock:(void(^)(RLMTable *table))block {
    RLMRealm *realm = [RLMRealm realmWithPath:RLMTestRealmPath];
    [realm beginWriteTransaction];
    block([realm createTableWithName:@"table"]);
    [realm commitWriteTransaction];
}

@end
