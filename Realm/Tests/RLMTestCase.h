//
//  RLMTestCase.h
//  Realm
//
//  Created by JP Simard on 4/22/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Realm/Realm.h>

extern NSString *const RLMTestRealmPath;

@class RLMRealm;

@interface RLMTestCase : XCTestCase

- (RLMRealm *)realmWithTestPath;

@end
