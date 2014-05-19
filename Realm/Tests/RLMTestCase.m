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

#import "RLMTestCase.h"


NSString *RLMRealmPathForFile(NSString *fileName) {
#if TARGET_OS_IPHONE
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:fileName];
#else
    return fileName;
#endif
}

NSString *RLMDefaultRealmPath() {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"default.realm"];
}

NSString *RLMTestRealmPath() {
    return RLMRealmPathForFile(@"test.realm");
}

NSString *RLMTestRealmPathLock() {
    return RLMRealmPathForFile(@"test.realm.lock");
}

@implementation RLMTestCase

- (void)setUp {
    // This method is run before every test method
    [super setUp];
    [[NSFileManager defaultManager] removeItemAtPath:RLMDefaultRealmPath() error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[RLMDefaultRealmPath() stringByAppendingString:@".lock"] error:nil];

    [[NSFileManager defaultManager] removeItemAtPath:RLMTestRealmPath() error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:RLMTestRealmPathLock() error:nil];
}

+ (void)tearDown {
    // This method is run after all tests in a test method have run
    [[NSFileManager defaultManager] removeItemAtPath:RLMTestRealmPath() error:nil];
    [super tearDown];
}

- (RLMRealm *)realmWithTestPath {
    return [RLMRealm realmWithPath:RLMTestRealmPath() readOnly:NO error:nil];
}

@end
