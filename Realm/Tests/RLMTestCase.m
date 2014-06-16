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
#import "XCTestCase+AsyncTesting.h"

@interface RLMRealm ()
+ (void)clearRealmCache;
@end

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

NSString *RLMLockPath(NSString *path) {
    return [path stringByAppendingString:@".lock"];
}

void RLMDeleteRealmFilesAtPath(NSString *path) {
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        @throw [NSException exceptionWithName:@"RLMTestException" reason:@"Unable to delete realm" userInfo:nil];
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:RLMLockPath(path) error:nil];
    if ([[NSFileManager defaultManager] fileExistsAtPath:RLMLockPath(path)]) {
        @throw [NSException exceptionWithName:@"RLMTestException" reason:@"Unable to delete realm" userInfo:nil];
    }
}


@implementation RLMTestCase

+ (void)setUp {
    [super setUp];
    
    // Delete Realm files
    RLMDeleteRealmFilesAtPath(RLMDefaultRealmPath());
    RLMDeleteRealmFilesAtPath(RLMTestRealmPath());
}

+ (void)tearDown {
    [super tearDown];
    
    // Reset realm cache
    [RLMRealm clearRealmCache];
    
    // Delete Realm files
    RLMDeleteRealmFilesAtPath(RLMDefaultRealmPath());
    RLMDeleteRealmFilesAtPath(RLMTestRealmPath());
}

- (void)invokeTest {
    [RLMTestCase setUp];
    @autoreleasepool {
        [super invokeTest];
    }
    [RLMTestCase tearDown];
}

- (RLMRealm *)realmWithTestPath {
    return [RLMRealm realmWithPath:RLMTestRealmPath() readOnly:NO error:nil];
}

- (void)testBefore:(void (^)(RLMRealm *realm))before
             async:(void (^)(RLMRealm *realm))async
        completion:(void (^)(RLMRealm *realm))completion {
    NSString *randomFileName = [NSString stringWithFormat:@"%d.realm", arc4random()];
    RLMRealm *realm = [RLMRealm realmWithPath:RLMRealmPathForFile(randomFileName) readOnly:NO error:nil];
    
    before(realm);
    
    dispatch_queue_t queue = dispatch_queue_create("background", 0);
    dispatch_async(queue, ^{
        async(realm);
    });
    
    [self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:2.0f];
    completion(realm);
    
    RLMDeleteRealmFilesAtPath(RLMRealmPathForFile(randomFileName));
}

@end
