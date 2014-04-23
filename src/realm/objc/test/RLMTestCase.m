//
//  RLMTestCase.m
//  Realm
//
//  Created by JP Simard on 4/22/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "RLMTestCase.h"
#import <realm/objc/Realm.h>

NSString *const RLMTestRealmPath = @"test.realm";

@implementation RLMTestCase

- (void)setUp {
    // This method is run before every test method
    [super setUp];
    [[NSFileManager defaultManager] removeItemAtPath:RLMTestRealmPath error:nil];
}

- (RLMRealm *)realmPersistedAtTestPath {
    return [RLMRealm realmWithPersistenceToFile:RLMTestRealmPath];
}

- (RLMContext *)contextPersistedAtTestPath {
    return [RLMContext contextPersistedAtPath:RLMTestRealmPath error:nil];
}

@end
