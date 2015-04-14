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

NSString * const kUTF8TestString = @"值значен™👍☞⎠‱௹♣︎☐▼❒∑⨌⧭иеمرحبا";

@interface UnicodeTests : RLMTestCase
@end

@implementation UnicodeTests

- (void)testUTF8StringContents
{
    RLMRealm *realm = self.realmWithTestPath;

    [realm beginWriteTransaction];
    [StringObject createInRealm:realm withValue:@[kUTF8TestString]];
    [realm commitWriteTransaction];

    StringObject *obj1 = [[StringObject allObjectsInRealm:realm] firstObject];
    XCTAssertEqualObjects(obj1.stringCol, kUTF8TestString, @"Storing and retrieving a string with UTF8 content should work");

    StringObject *obj2 = [[StringObject objectsInRealm:realm where:@"stringCol == %@", kUTF8TestString] firstObject];
    XCTAssertTrue([obj1 isEqualToObject:obj2], @"Querying a realm searching for a string with UTF8 content should work");
}

- (void)testUTF8PropertyWithUTF8StringContents
{
    RLMRealm *realm = self.realmWithTestPath;

    [realm beginWriteTransaction];
    [UTF8Object createInRealm:realm withValue:@[kUTF8TestString]];
    [realm commitWriteTransaction];

    UTF8Object *obj1 = [[UTF8Object allObjectsInRealm:realm] firstObject];
    XCTAssertEqualObjects(obj1.柱колоéнǢкƱаم, kUTF8TestString, @"Storing and retrieving a string with UTF8 content should work");

    // Test fails because of rdar://17735684
    // NSPredicate does not support UTF8 keypaths
//    UTF8Object *obj2 = [[StringObject objectsInRealm:realm where:@"柱колоéнǢкƱаم == %@", kUTF8TestString] firstObject];
//    XCTAssertEqualObjects(obj1, obj2, @"Querying a realm searching for a string with UTF8 content should work");
}

@end
