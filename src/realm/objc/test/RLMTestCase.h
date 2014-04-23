//
//  RLMTestCase.h
//  RealmObjcDyn
//
//  Created by JP Simard on 4/22/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import <XCTest/XCTest.h>

extern NSString *const RLMTestRealmPath;

@class RLMRealm, RLMContext;

@interface RLMTestCase : XCTestCase

- (RLMRealm *)realmPersistedAtTestPath;
- (RLMContext *)contextPersistedAtTestPath;

@end
