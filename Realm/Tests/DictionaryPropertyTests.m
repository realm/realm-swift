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

@interface DictionaryPropertyTests : RLMTestCase
@end

@implementation DictionaryPropertyTests

-(void)testPopulateEmptyDictionary {
    RLMRealm *realm = [self realmWithTestPath];

    [realm beginWriteTransaction];
    DictionaryPropertyObject *dict = [DictionaryPropertyObject createInRealm:realm withValue:@[@{}, @{}]];
    XCTAssertNotNil(dict.stringDictionary, @"Should be able to get an empty dictionary");
    XCTAssertEqual(dict.stringDictionary.count, 0U, @"Should start with no dictionary elements");

    StringObject *obj = [[StringObject alloc] init];
    obj.stringCol = @"a";

    dict.stringDictionary[@"one"] = obj;
    dict.stringDictionary[@"two"] = [StringObject createInRealm:realm withValue:@[@"b"]];
    dict.stringDictionary[@"three"] = obj;

    [realm commitWriteTransaction];

    XCTAssertEqual(dict.stringDictionary.count, 3U, @"Should have three elements in the dictionary");
    XCTAssertEqualObjects([dict.stringDictionary[@"one"] stringCol], @"a", @"First element should have property value 'a'");
    XCTAssertEqualObjects([dict.stringDictionary[@"two"] stringCol], @"b", @"Second element should have property value 'b'");
    XCTAssertEqualObjects([dict.stringDictionary[@"three"] stringCol], @"a", @"Third element should have property value 'a'");

    RLMDictionary *dictionaryProp = dict.stringDictionary;
    RLMAssertThrowsWithReasonMatching([dictionaryProp setObject:obj forKey:@"four"], @"write transaction");

    // make sure we can fast enumerate
    // TODO: fast enumeration only works on primitives atm.
//    for (id obj in dictionaryProp) {
//        XCTAssertTrue(obj.description.length, @"Object should have description");
//    }
}

-(void)testModifyDetatchedDictionary {
    RLMRealm *realm = [self realmWithTestPath];

    [realm beginWriteTransaction];
    ArrayPropertyObject *arObj = [ArrayPropertyObject createInRealm:realm withValue:@[@"arrayObject", @[], @[]]];
    XCTAssertNotNil(arObj.array, @"Should be able to get an empty array");
    XCTAssertEqual(arObj.array.count, 0U, @"Should start with no array elements");

    StringObject *obj = [[StringObject alloc] init];
    obj.stringCol = @"a";
    RLMArray *array = arObj.array;
    [array addObject:obj];
    [array addObject:[StringObject createInRealm:realm withValue:@[@"b"]]];
    [realm commitWriteTransaction];

    XCTAssertEqual(array.count, 2U, @"Should have two elements in array");
    XCTAssertEqualObjects([array[0] stringCol], @"a", @"First element should have property value 'a'");
    XCTAssertEqualObjects([arObj.array[1] stringCol], @"b", @"Second element should have property value 'b'");

    RLMAssertThrowsWithReasonMatching([array addObject:obj], @"write transaction");
}

@end
