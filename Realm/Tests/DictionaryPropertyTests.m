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
    DictionaryPropertyObject *dictObj = [DictionaryPropertyObject createInRealm:realm withValue:@[]];
    XCTAssertNotNil(dictObj.stringDictionary, @"Should be able to get an empty dictionary");
    XCTAssertEqual(dictObj.stringDictionary.count, 0U, @"Should start with no dictionary elements");

    StringObject *obj = [[StringObject alloc] init];
    obj.stringCol = @"a";
    RLMDictionary *dict = dictObj.stringDictionary;
    dict[@"one"] = obj;
    [dict setObject:[StringObject createInRealm:realm withValue:@[@"b"]] forKey:@"two"];
    [realm commitWriteTransaction];

    XCTAssertEqual(dictObj.stringDictionary.count, 2U, @"Should have two elements in dictionary");
    XCTAssertEqualObjects([dictObj.stringDictionary[@"one"] stringCol], @"a", @"First element should have property value 'a'");
    XCTAssertEqualObjects([dictObj.stringDictionary[@"two"] stringCol], @"b", @"Second element should have property value 'b'");

    RLMAssertThrowsWithReasonMatching([dictObj.stringDictionary setObject:obj forKey:@"one"], @"write transaction");
}

- (void)testDeleteUnmanagedObjectWithDictionaryProperty {
    DictionaryPropertyObject *dictObj = [[DictionaryPropertyObject alloc] initWithValue:@[]];
    RLMDictionary *stringDictionary = dictObj.stringDictionary;
    XCTAssertFalse(stringDictionary.isInvalidated, @"stringDictionary should be valid after creation.");
    dictObj = nil;
    XCTAssertFalse(stringDictionary.isInvalidated, @"stringDictionary should still be valid after parent deletion.");
}

- (void)testDeleteObjectWithDictionaryProperty {
    RLMRealm *realm = [self realmWithTestPath];

    [realm beginWriteTransaction];
    DictionaryPropertyObject *dictObj = [DictionaryPropertyObject createInRealm:realm withValue:@[]];
    RLMDictionary *dictArray = dictObj.stringDictionary;
    XCTAssertFalse(dictArray.isInvalidated, @"dictArray should be valid after creation.");
    [realm deleteObject:dictObj];
    XCTAssertTrue(dictArray.isInvalidated, @"dictArray should be invalid after parent deletion.");
    [realm commitWriteTransaction];
}

- (void)testDeleteObjectInDictionaryProperty {
    RLMRealm *realm = [self realmWithTestPath];
    StringObject *obj = [[StringObject alloc] init];
    [realm beginWriteTransaction];
    DictionaryPropertyObject *dictObj = [DictionaryPropertyObject createInRealm:realm withValue:@[@{@"one": obj}]];
    RLMDictionary *stringDictionary = dictObj.stringDictionary;
    StringObject *one = stringDictionary[@"one"];
    [realm deleteObjects:[StringObject allObjectsInRealm:realm]];
    XCTAssertFalse(stringDictionary.isInvalidated, @"stringDictionary should be valid after member object deletion.");
    XCTAssertTrue(one.isInvalidated, @"firstObject should be invalid after deletion.");
    XCTAssertEqual(stringDictionary.count, 1U, @"stringDictionary.count should be one as it holds onto the invalidated object.");
    [realm commitWriteTransaction];
}

-(void)testKeyedSubscript {
    RLMRealm *realm = [self realmWithTestPath];

    [realm beginWriteTransaction];
    DictionaryPropertyObject *obj = [DictionaryPropertyObject createInRealm:realm withValue:@[]];
    StringObject *child1 = [StringObject createInRealm:realm withValue:@[@"a"]];
    StringObject *child2 = [[StringObject alloc] init];
    StringObject *child3 = [StringObject createInRealm:realm withValue:@[@"c"]];

    obj.stringDictionary[@"one"] = child1;
    XCTAssertTrue([[obj.stringDictionary[@"one"] stringCol] isEqualToString:@"a"]);
    obj.stringDictionary[@"two"] = child2;
    XCTAssertNil([obj.stringDictionary[@"two"] stringCol]);
    // reassign
    obj.stringDictionary[@"two"] = child3;
    XCTAssertTrue([[obj.stringDictionary[@"two"] stringCol] isEqualToString:@"c"]);
    [realm commitWriteTransaction];
}

-(void)testRemoveObject {
    RLMRealm *realm = [self realmWithTestPath];

    [realm beginWriteTransaction];
    DictionaryPropertyObject *obj = [DictionaryPropertyObject createInRealm:realm withValue:@[]];
    StringObject *child1 = [StringObject createInRealm:realm withValue:@[@"a"]];
    StringObject *child2 = [[StringObject alloc] init];
    StringObject *child3 = [StringObject createInRealm:realm withValue:@[@"c"]];

    obj.stringDictionary[@"one"] = child1;
    XCTAssertTrue([[obj.stringDictionary[@"one"] stringCol] isEqualToString:@"a"]);
    obj.stringDictionary[@"two"] = child2;
    XCTAssertNil([obj.stringDictionary[@"two"] stringCol]);
    // reassign
    obj.stringDictionary[@"two"] = child3;
    XCTAssertTrue([[obj.stringDictionary[@"two"] stringCol] isEqualToString:@"c"]);



    [realm commitWriteTransaction];


    [realm beginWriteTransaction];

    NSLog(@"%@", obj.stringDictionary[@"one"]);
    [obj.stringDictionary removeObjectForKey:@"two"];
    XCTAssertNil(obj.stringDictionary[@"two"]);
    
    [realm commitWriteTransaction];

}

-(void)testAddInvalidated {
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    CompanyObject *company = [CompanyObject createInDefaultRealmWithValue:@[@"company", @[]]];

    EmployeeObject *person = [[EmployeeObject alloc] init];
    person.name = @"Mary";
    [realm addObject:person];
    [realm deleteObjects:[EmployeeObject allObjects]];

    RLMAssertThrowsWithReasonMatching([company.employeeDict setObject:person forKey:@"person1"], @"invalidated");

    [realm cancelWriteTransaction];
}

- (void)testAddNil {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    CompanyObject *company = [CompanyObject createInDefaultRealmWithValue:@[@"company", @[]]];

    RLMAssertThrowsWithReason([company.employeeDict setObject:self.nonLiteralNil forKey:@"blah"],
                              @"Invalid nil value for dictionary of 'EmployeeObject'.");
    [realm cancelWriteTransaction];
}

- (void)testUnmanaged {
    RLMRealm *realm = [self realmWithTestPath];

    DictionaryPropertyObject *dict = [[DictionaryPropertyObject alloc] init];
    XCTAssertNotNil(dict.stringDictionary, @"RLMDictionary property should get created on access");

    XCTAssertEqual(dict.stringDictionary.allValues.count, 0U, @"No objects added yet");
    XCTAssertEqual(dict.stringDictionary.allKeys.count, 0U, @"No objects added yet");

    StringObject *obj1 = [[StringObject alloc] init];
    obj1.stringCol = @"a";
    StringObject *obj2 = [[StringObject alloc] init];
    obj2.stringCol = @"b";
    StringObject *obj3 = [[StringObject alloc] init];
    obj3.stringCol = @"c";
    dict.stringDictionary[@"one"] = obj1;
    dict.stringDictionary[@"two"] = obj2;
    dict.stringDictionary[@"three"] = obj3;

    XCTAssertEqual(dict.stringDictionary.allValues.count, 3U);
    XCTAssertEqual(dict.stringDictionary.allKeys.count, 3U);

    XCTAssertEqualObjects(dict.stringDictionary[@"one"], obj1, @"Objects should be equal");
    XCTAssertEqualObjects(dict.stringDictionary[@"three"], obj3, @"Objects should be equal");
    XCTAssertEqualObjects(dict.stringDictionary.allValues[1], obj2, @"Objects should be equal");

    [realm beginWriteTransaction];
    [realm addObject:dict];
    [realm commitWriteTransaction];

    XCTAssertEqual(dict.stringDictionary.allValues.count, 3U);
    XCTAssertEqual(dict.stringDictionary.allKeys.count, 3U);

    XCTAssertEqual(dict.stringDictionary.count, 3U, @"Should have two elements in dictionary");
    XCTAssertEqualObjects([dict.stringDictionary[@"one"] stringCol], @"a", @"First element should have property value 'a'");
    XCTAssertEqualObjects([dict.stringDictionary[@"two"] stringCol], @"b", @"Second element should have property value 'b'");

    [realm beginWriteTransaction];
    dict.stringDictionary[@"one"] = obj3;
    XCTAssertTrue([dict.stringDictionary[@"one"] isEqualToObject:obj3], @"Objects should be replaced");
    dict.stringDictionary[@"one"] = obj1;
    XCTAssertTrue([obj1 isEqualToObject:dict.stringDictionary[@"one"]], @"Objects should be replaced");
    [dict.stringDictionary removeObjectForKey:@"one"];
    XCTAssertEqual(dict.stringDictionary.count, 2U, @"2 objects left");
    [dict.stringDictionary removeAllObjects];
    XCTAssertEqual(dict.stringDictionary.count, 0U, @"All objects removed");
    [realm commitWriteTransaction];

    DictionaryPropertyObject *intDictionary = [[DictionaryPropertyObject alloc] init];
    IntObject *intObj = [[IntObject alloc] init];
    intObj.intCol = 1;
    RLMAssertThrowsWithReasonMatching([intDictionary.intDictionary setObject:(id)intObj forKey:@"one"], @"IntObject.*StringObject");
    [intDictionary.intDictionary setObject:(id)intObj forKey:@"two"];

    XCTAssertThrows([intDictionary.intDictionary objectsWhere:@"intCol == 1"], @"Should throw on unmanaged RLMDictionary");
    XCTAssertThrows(([intDictionary.intDictionary objectsWithPredicate:[NSPredicate predicateWithFormat:@"intCol == %i", 1]]), @"Should throw on unmanaged RLMDictionary");
    XCTAssertThrows([intDictionary.intDictionary sortedResultsUsingKeyPath:@"intCol" ascending:YES], @"Should throw on unmanaged RLMDictionary");

    XCTAssertEqual(0U, [intDictionary.intDictionary indexOfObjectWhere:@"intCol == 1"]);
    XCTAssertEqual(0U, ([intDictionary.intDictionary indexOfObjectWithPredicate:[NSPredicate predicateWithFormat:@"intCol == %i", 1]]));

    XCTAssertEqual([intDictionary.intDictionary indexOfObject:intObj], 0U, @"Should be first element");
    XCTAssertEqual([intDictionary.intDictionary indexOfObject:intObj], 0U, @"Should be first element");

    // test unmanaged with literals
    __unused DictionaryPropertyObject *obj = [[DictionaryPropertyObject alloc] initWithValue:@[@{}, @{@"one": [[IntObject alloc] initWithValue:@[@1]]}]];
}

@end
