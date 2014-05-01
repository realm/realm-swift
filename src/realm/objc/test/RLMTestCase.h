//
//  RLMTestCase.h
//  Realm
//
//  Created by JP Simard on 4/22/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <realm/objc/Realm.h>

extern NSString *const RLMTestRealmPath;

@class RLMRealm, RLMTransactionManager;

@interface RLMTestCase : XCTestCase

- (RLMRealm *)realmPersistedAtTestPath;
- (RLMTransactionManager *)managerWithTestPath;
- (void)createTestTableWithWriteBlock:(RLMTableWriteBlock)block;

@end
