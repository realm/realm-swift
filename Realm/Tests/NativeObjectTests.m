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

@interface NativeObjectTests : RLMTestCase
@end

@implementation NativeObjectTests

#pragma mark - Tests

- (void)testNativeInsert {
    
    RLMRealm *realm = self.realmWithTestPath;
    NSURL *url = [NSURL URLWithString:@"http://google.com"];
    NSURL *url2 = [NSURL URLWithString:@"http://apple.com"];
    [realm beginWriteTransaction];
    [NativeObject createInRealm:realm withObject:@[url, [NSData data]]];
    NativeObject *obj = [NativeObject createInRealm:realm withObject:@[url2, [NSData data]]];
    obj.nativeCol = nil;
    
    [realm commitWriteTransaction];
    
    RLMArray *objects = [NativeObject allObjectsInRealm:realm];
    XCTAssertEqual(objects.count, (NSUInteger)2, @"2 rows excepted");
    XCTAssertTrue([[objects objectAtIndex:0] isKindOfClass:[NativeObject class]], @"NativeObject expected");
    XCTAssertTrue([[objects objectAtIndex:0][@"nativeCol"] isKindOfClass:[NSURL class]], @"NSURL expected");
    XCTAssertTrue([[objects objectAtIndex:0][@"nativeCol"] isEqual:url], @"'%@' expected", url);
    XCTAssertTrue([[objects objectAtIndex:0][@"dataCol"] isEqual:[NSData data]], @"'%@' expected", [NSData data]);

    XCTAssertTrue([[objects objectAtIndex:1] isKindOfClass:[NativeObject class]], @"NativeObject expected");
    XCTAssertTrue([objects objectAtIndex:1][@"nativeCol"] == nil, @"nil expected");
    XCTAssertTrue([objects objectAtIndex:1][@"nativeCol"] == nil, @"nil expected");
    XCTAssertTrue([[objects objectAtIndex:1][@"dataCol"] isEqual:[NSData data]], @"[NSData data] expected");

}

- (void)testNativeValidate {
    RLMRealm *realm = [self realmWithTestPath];
    
    [realm beginWriteTransaction];
    XCTAssertThrows(([NativeObject createInRealm:realm withObject:@[@"Not a url", [NSData data]]]), @"Native not of the correct class");
    XCTAssertThrows(([NativeObject createInRealm:realm withObject:@[@11, [NSData data]]]), @"Native not of the correct class");
    
    XCTAssertEqual([NativeObject allObjects].count, (NSUInteger)0, @"0 rows expected");
    [realm commitWriteTransaction];
}



@end