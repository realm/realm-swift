////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////


#import <XCTest/XCTest.h>
#import <Realm/Realm.h>

NSString *RLMTestRealmPath();
NSString *RLMDefaultRealmPath();
NSString *RLMRealmPathForFile();

@class RLMRealm;

@interface RLMTestCase : XCTestCase

- (RLMRealm *)realmWithTestPath;

- (void)testBefore:(void (^)(RLMRealm *realm))before
             async:(void (^)(RLMRealm *realm))async
        completion:(void (^)(RLMRealm *realm))completion;

@end
