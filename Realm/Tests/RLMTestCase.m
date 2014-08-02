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

@interface RLMRealm ()
+ (instancetype)realmWithPath:(NSString *)path
                     readOnly:(BOOL)readonly
                      dynamic:(BOOL)dynamic
                       schema:(RLMSchema *)customSchema
                        error:(NSError **)outError;
+ (void)clearRealmCache;
@end

#if !defined(SWIFT)
@implementation XCTestExpectation{
@public
    BOOL _fulfilled;
}

- (void)fulfill {
    _fulfilled = YES;
    CFRunLoopStop(CFRunLoopGetMain());
}
@end
#endif

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
#if TARGET_OS_IPHONE
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
#else
    NSString *path = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0];
    path = [path stringByAppendingPathComponent:[[[NSBundle mainBundle] executablePath] lastPathComponent]];
#endif
    return [path stringByAppendingPathComponent:@"default.realm"];
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
#if !defined(SWIFT)
{
    NSMutableArray *_expectations;
}
#endif

+ (void)setUp
{
    [super setUp];
    
    // Delete Realm files
    RLMDeleteRealmFilesAtPath(RLMDefaultRealmPath());
    RLMDeleteRealmFilesAtPath(RLMTestRealmPath());
}

+ (void)tearDown
{
    [super tearDown];

    // Clear cache
    [RLMRealm clearRealmCache];
    
    // Delete Realm files
    RLMDeleteRealmFilesAtPath(RLMDefaultRealmPath());
    RLMDeleteRealmFilesAtPath(RLMTestRealmPath());
}

- (void)invokeTest
{
    [RLMTestCase setUp];
    @autoreleasepool {
        [super invokeTest];
    }
    [RLMTestCase tearDown];
}

- (RLMRealm *)realmWithTestPath
{
    return [RLMRealm realmWithPath:RLMTestRealmPath() readOnly:NO error:nil];
}

- (RLMRealm *)realmWithTestPathAndSchema:(RLMSchema *)schema {
    return [RLMRealm realmWithPath:RLMTestRealmPath() readOnly:NO dynamic:NO schema:schema error:nil];
}

- (RLMRealm *)dynamicRealmWithTestPathAndSchema:(RLMSchema *)schema {
    return [RLMRealm realmWithPath:RLMTestRealmPath() readOnly:NO dynamic:YES schema:schema error:nil];
}

#if !defined(SWIFT)
- (void)waitForExpectationsWithTimeout:(NSTimeInterval)interval handler:(__unused id)noop {
    NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow:interval];
    NSLog(@"start");
    while (!_expectations.count && [endDate timeIntervalSinceNow] > 0) {
        for (NSInteger i = (NSInteger)_expectations.count-1; i > 0; i--) {
            if (((XCTestExpectation *)_expectations[i])->_fulfilled) {
                [_expectations removeObjectAtIndex:i];
            }
        }
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:endDate];
    }
    NSLog(@"end");

    if (_expectations.count) {
        XCTFail(@"Wait for expectation timed out after %f seconds", interval);
    }
}

- (XCTestExpectation *)expectationWithDescription:(__unused NSString *)desc {
    XCTestExpectation *exp = [[XCTestExpectation alloc] init];
    [_expectations addObject:exp];
    return exp;
}
#endif

@end

