////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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

@implementation DogDictionaryObject
@end
    
@implementation DictionaryPropertyTests

- (void)testPopulateEmptyDictionary {
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

    for (NSString *key in dictionaryProp) {
        XCTAssertTrue(((RLMDictionary *)dictionaryProp[key]).description.length, @"Object should have description");
    }
}

- (void)testKeyType {
    DictionaryPropertyObject *unmanaged = [[DictionaryPropertyObject alloc] init];
    XCTAssertEqual(unmanaged.intDictionary.keyType, RLMPropertyTypeString);
    RLMRealm *realm = [self realmWithTestPath];

    [realm beginWriteTransaction];
    DictionaryPropertyObject *managed = [DictionaryPropertyObject createInRealm:realm withValue:@[]];
    [realm commitWriteTransaction];
    XCTAssertEqual(managed.intDictionary.keyType, RLMPropertyTypeString);
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
    RLMDictionary *dictionary = dictObj.stringDictionary;
    XCTAssertFalse(dictionary.isInvalidated, @"dictionary should be valid after creation.");
    [realm deleteObject:dictObj];
    XCTAssertTrue(dictionary.isInvalidated, @"dictionary should be invalid after parent deletion.");
    [realm commitWriteTransaction];
}

- (void)testDeleteObjectInDictionaryProperty {
    RLMRealm *realm = [self realmWithTestPath];
    StringObject *obj = [[StringObject alloc] init];
    [realm beginWriteTransaction];
    DictionaryPropertyObject *dictObj = [DictionaryPropertyObject createInRealm:realm withValue: @{@"stringDictionary": @{@"one": obj}}];
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
    [obj.stringDictionary removeObjectForKey:@"one"];
    XCTAssertNil(obj.stringDictionary[@"one"]);
    [obj.stringDictionary removeObjectForKey:@"two"];
    XCTAssertNil(obj.stringDictionary[@"two"]);
    obj.stringDictionary[@"three"] = child3;
    XCTAssertTrue([[obj.stringDictionary[@"three"] stringCol] isEqualToString:@"c"]);
    [obj.stringDictionary removeAllObjects];
    XCTAssertNil(obj.stringDictionary[@"three"]);

    obj.stringDictionary[@"one"] = child1;
    XCTAssertNotNil(obj.stringDictionary[@"one"]);
    obj.stringDictionary[@"two"] = child2;
    XCTAssertNotNil(obj.stringDictionary[@"two"]);
    [obj.stringDictionary removeObjectsForKeys:@[@"one", @"two"]];
    XCTAssertNil(obj.stringDictionary[@"one"]);
    XCTAssertNil(obj.stringDictionary[@"two"]);
    
    obj.stringDictionary[@"one"] = child1;
    XCTAssertNotNil(obj.stringDictionary[@"one"]);
    obj.stringDictionary[@"one"] = nil;
    XCTAssertNil(obj.stringDictionary[@"one"]);

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
                              @"Must provide a non-nil value.");
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
    [intDictionary.intObjDictionary setObject:intObj forKey:@"one"];
    [intDictionary.intObjDictionary setObject:intObj forKey:@"two"];

    XCTAssertThrows([intDictionary.intObjDictionary objectsWhere:@"intCol == 1"], @"Should throw on unmanaged RLMDictionary");
    XCTAssertThrows(([intDictionary.intObjDictionary objectsWithPredicate:[NSPredicate predicateWithFormat:@"intCol == %i", 1]]), @"Should throw on unmanaged RLMDictionary");
    XCTAssertThrows([intDictionary.intObjDictionary sortedResultsUsingKeyPath:@"intCol" ascending:YES], @"Should throw on unmanaged RLMDictionary");

    // test unmanaged with literals
    __unused DictionaryPropertyObject *obj = [[DictionaryPropertyObject alloc] initWithValue:@[@{}, @{}, @{}, @{@"one": [[IntObject alloc] initWithValue:@[@1]]}]];
}

- (void)testUnmanagedComparision {
    RLMRealm *realm = [self realmWithTestPath];

    DictionaryPropertyObject *dict = [[DictionaryPropertyObject alloc] init];
    DictionaryPropertyObject *dict2 = [[DictionaryPropertyObject alloc] init];

    XCTAssertNotNil(dict.stringDictionary, @"RLMDictionary property should get created on access");
    XCTAssertNotNil(dict2.stringDictionary, @"RLMDictionary property should get created on access");
    XCTAssertTrue([dict.stringDictionary isEqual:dict2.stringDictionary], @"Empty dictionaries should be equal");

    XCTAssertEqual(dict.stringDictionary.count, 0U);
    XCTAssertEqual(dict2.stringDictionary.count, 0U);

    StringObject *obj1 = [[StringObject alloc] init];
    obj1.stringCol = @"a";
    StringObject *obj2 = [[StringObject alloc] init];
    obj2.stringCol = @"b";
    StringObject *obj3 = [[StringObject alloc] init];
    obj3.stringCol = @"c";
    [dict.stringDictionary setObject:obj1 forKey:@"one"];
    dict.stringDictionary[@"two"] = obj2;
    [dict.stringDictionary setObject:obj3 forKey:@"three"];

    [dict2.stringDictionary setObject:obj1 forKey:@"one"];
    dict2.stringDictionary[@"two"] = obj2;
    [dict2.stringDictionary setObject:obj3 forKey:@"three"];

    XCTAssertTrue([dict.stringDictionary isEqual:dict2.stringDictionary], @"Dictionaries should be equal");
    [dict2.stringDictionary removeObjectForKey:@"three"];
    XCTAssertFalse([dict.stringDictionary isEqual:dict2.stringDictionary], @"Dictionaries should not be equal");
    dict2.stringDictionary[@"three"] = obj3;
    XCTAssertTrue([dict.stringDictionary isEqual:dict2.stringDictionary], @"Dictionaries should be equal");

    [realm beginWriteTransaction];
    [realm addObject:dict];
    [realm commitWriteTransaction];

    XCTAssertFalse([dict.stringDictionary isEqual:dict2.stringDictionary], @"Comparing a managed dictionary to an unmanaged one should fail");
    XCTAssertFalse([dict2.stringDictionary isEqual:dict.stringDictionary], @"Comparing a managed dictionary to an unmanaged one should fail");
}

- (void)testUnmanagedPrimitive {
    AllPrimitiveDictionaries *obj = [[AllPrimitiveDictionaries alloc] init];
    XCTAssertTrue([obj.intObj isKindOfClass:[RLMDictionary class]]);
    XCTAssertTrue([obj.floatObj isKindOfClass:[RLMDictionary class]]);
    XCTAssertTrue([obj.doubleObj isKindOfClass:[RLMDictionary class]]);
    XCTAssertTrue([obj.boolObj isKindOfClass:[RLMDictionary class]]);
    XCTAssertTrue([obj.stringObj isKindOfClass:[RLMDictionary class]]);
    XCTAssertTrue([obj.dataObj isKindOfClass:[RLMDictionary class]]);
    XCTAssertTrue([obj.dateObj isKindOfClass:[RLMDictionary class]]);
    XCTAssertTrue([obj.uuidObj isKindOfClass:[RLMDictionary class]]);

    [obj.intObj setObject:@1 forKey:@"one"];
    XCTAssertEqualObjects(obj.intObj[@"one"], @1);
    id nilValue;
    XCTAssertThrows([obj.intObj setObject:nilValue forKey:@"one"]);

    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    obj = [AllPrimitiveDictionaries createInRealm:realm withValue:@[]];

    XCTAssertTrue([obj.intObj isKindOfClass:[RLMDictionary class]]);
    XCTAssertTrue([obj.floatObj isKindOfClass:[RLMDictionary class]]);
    XCTAssertTrue([obj.doubleObj isKindOfClass:[RLMDictionary class]]);
    XCTAssertTrue([obj.boolObj isKindOfClass:[RLMDictionary class]]);
    XCTAssertTrue([obj.stringObj isKindOfClass:[RLMDictionary class]]);
    XCTAssertTrue([obj.dataObj isKindOfClass:[RLMDictionary class]]);
    XCTAssertTrue([obj.dateObj isKindOfClass:[RLMDictionary class]]);
    XCTAssertTrue([obj.uuidObj isKindOfClass:[RLMDictionary class]]);

    obj.intObj[@"two"] = @2;
    XCTAssertEqualObjects(obj.intObj[@"two"], @2);
    [realm cancelWriteTransaction];
}

- (void)testDeleteObjectInUnmanagedDictionary {
    DictionaryPropertyObject *dict = [[DictionaryPropertyObject alloc] init];

    StringObject *stringObj1 = [[StringObject alloc] init];
    stringObj1.stringCol = @"a";
    StringObject *stringObj2 = [[StringObject alloc] init];
    stringObj2.stringCol = @"b";
    StringObject *stringObj3 = [[StringObject alloc] init];
    stringObj3.stringCol = @"c";
    dict.stringDictionary[@"one"] = stringObj1;
    dict.stringDictionary[@"two"] = stringObj2;
    [dict.stringDictionary setObject:stringObj3 forKey:@"three"];

    IntObject *intObj1 = [[IntObject alloc] init];
    intObj1.intCol = 0;
    IntObject *intObj2 = [[IntObject alloc] init];
    intObj2.intCol = 1;
    IntObject *intObj3 = [[IntObject alloc] init];
    intObj3.intCol = 2;
    dict.intObjDictionary[@"one"] = intObj1;
    dict.intObjDictionary[@"two"] = intObj2;
    [dict.intObjDictionary setObject:intObj3 forKey:@"three"];

    XCTAssertEqualObjects(dict.stringDictionary[@"one"], stringObj1, @"Objects should be equal");
    XCTAssertEqualObjects([dict.stringDictionary objectForKey:@"two"], stringObj2, @"Objects should be equal");
    XCTAssertEqualObjects(dict.stringDictionary[@"three"], stringObj3, @"Objects should be equal");
    XCTAssertEqual(dict.stringDictionary.count, 3U, @"Should have 3 elements in string dictionary");

    XCTAssertEqualObjects(dict.intObjDictionary[@"one"], intObj1, @"Objects should be equal");
    XCTAssertEqualObjects([dict.intObjDictionary objectForKey:@"two"], intObj2, @"Objects should be equal");
    XCTAssertEqualObjects(dict.intObjDictionary[@"three"], intObj3, @"Objects should be equal");
    XCTAssertEqual(dict.intObjDictionary.count, 3U, @"Should have 3 elements in int dictionary");

    [dict.stringDictionary removeObjectForKey:@"three"];

    XCTAssertEqualObjects(dict.stringDictionary[@"one"], stringObj1, @"Objects should be equal");
    XCTAssertEqualObjects([dict.stringDictionary objectForKey:@"two"], stringObj2, @"Objects should be equal");
    XCTAssertEqual(dict.stringDictionary.count, 2U, @"Should have 2 elements in string dictionary");

    [dict.stringDictionary removeObjectForKey:@"three"]; // already deleted

    [dict.stringDictionary removeObjectForKey:@"two"];

    XCTAssertEqualObjects(dict.stringDictionary[@"one"], stringObj1, @"Objects should be equal");
    XCTAssertEqualObjects([dict.stringDictionary objectForKey:@"one"], stringObj1, @"Objects should be equal");
    XCTAssertEqual(dict.stringDictionary.count, 1U, @"Should have 1 elements in string dictionary");

    [dict.stringDictionary removeAllObjects];

    XCTAssertEqual(dict.stringDictionary.count, 0U, @"Should have 0 elements in string dictionary");

    [dict.intDictionary removeObjectsForKeys:@[@"one", @"two", @"three"]];
    XCTAssertEqual(dict.intDictionary.count, 0U, @"Should have 0 elements in int dictionary");
}

- (void)testFastEnumeration {
    RLMRealm *realm = self.realmWithTestPath;

    [realm beginWriteTransaction];
    CompanyObject *company = [[CompanyObject alloc] init];
    company.name = @"name";
    [realm addObject:company];
    [realm commitWriteTransaction];

    // enumerate empty dictionary
    for (__unused id obj in company.employeeDict) {
        XCTFail(@"Should be empty");
    }

    [company.employeeDict enumerateKeysAndObjectsUsingBlock:^(__unused id  _Nonnull key,
                                                              __unused id _Nonnull value,
                                                              __unused BOOL * _Nonnull stop) {
        XCTFail(@"Should be empty");
    }];

    [realm beginWriteTransaction];
    for (int i = 0; i < 30; ++i) {
        EmployeeObject *eo = [EmployeeObject createInRealm:realm withValue:@{@"name": @"Joe",  @"age": @40, @"hired": @YES}];
        NSString *key = [NSString stringWithFormat:@"item%d", i];
        company.employeeDict[key] = eo;
    }
    [realm commitWriteTransaction];

    XCTAssertEqual(company.employeeDict.count, 30U);

    NSInteger count = 0;
    for (id key in company.employeeDict) {
        XCTAssertNotNil(key, @"Object is not nil and accessible");
        count++;
    }

    XCTAssertEqual(count, 30, @"should have enumerated 30 objects");

    [company.employeeDict enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key,
                                                              EmployeeObject * _Nonnull obj,
                                                              __unused BOOL * _Nonnull stop) {
        XCTAssertEqualObjects([company.employeeDict[key] name], [obj name]);
        XCTAssertEqual(((EmployeeObject *)company.employeeDict[key]).age, [obj age]);
        XCTAssertEqual([company.employeeDict[key] hired], [obj hired]);
    }];
}

- (void)testDeleteDuringEnumeration {
    RLMRealm *realm = self.realmWithTestPath;

    [realm beginWriteTransaction];
    CompanyObject *company = [[CompanyObject alloc] init];
    company.name = @"name";
    [realm addObject:company];

    const size_t totalCount = 40;
    for (size_t i = 0; i < totalCount; ++i) {
        NSString *key = [NSString stringWithFormat:@"item%zu", i];
        company.employeeDict[key] = [EmployeeObject createInRealm:realm withValue:@[@"name", @(i), @NO]];
    }

    [realm commitWriteTransaction];

    [realm beginWriteTransaction];
    for (NSString *key in company.employeeDict) {
        [realm deleteObject:company.employeeDict[key]];
    }
    [realm commitWriteTransaction];

    [realm beginWriteTransaction];
    for (size_t i = 0; i < totalCount; ++i) {
        NSString *key = [NSString stringWithFormat:@"item%zu", i];
        company.employeeDict[key] = [EmployeeObject createInRealm:realm withValue:@[@"name", @(i), @NO]];
    }
    [realm commitWriteTransaction];

    [realm beginWriteTransaction];
    [company.employeeDict enumerateKeysAndObjectsUsingBlock:^(__unused id _Nonnull key,
                                                              __unused id _Nonnull obj,
                                                              __unused BOOL * _Nonnull stop) {
        [realm deleteObjects:company.employees];
    }];
    [realm commitWriteTransaction];
}

- (void)testValueForKey {
    // unmanaged
    DictionaryPropertyObject *unmanObj = [DictionaryPropertyObject new];
    StringObject *unmanChild1 = [[StringObject alloc] initWithValue:@[@"a"]];
    EmbeddedIntObject *unmanChild2 = [[EmbeddedIntObject alloc] initWithValue:@[@123]];

    [unmanObj.stringDictionary setValue:unmanChild1 forKey:@"one"];
    XCTAssertTrue([[unmanObj.stringDictionary valueForKey:@"one"][@"stringCol"] isEqualToString:unmanChild1.stringCol]);

    [unmanObj.embeddedDictionary setValue:unmanChild2 forKey:@"two"];
    XCTAssertEqual([[unmanObj.embeddedDictionary valueForKey:@"two"][@"intCol"] integerValue], unmanChild2.intCol);

    unmanObj.intDictionary[@"one"] = @1;
    XCTAssertEqualObjects([unmanObj.intDictionary valueForKey:@"invalidated"], @NO);

    // managed
    RLMRealm *realm = [self realmWithTestPath];
    [realm beginWriteTransaction];
    DictionaryPropertyObject *obj = [DictionaryPropertyObject createInRealm:realm withValue:@[]];
    StringObject *child1 = [StringObject createInRealm:realm withValue:@[@"a"]];
    EmbeddedIntObject *child2 = [[EmbeddedIntObject alloc] initWithValue:@[@123]];

    [obj.stringDictionary setValue:child1 forKey:@"one"];
    XCTAssertTrue([[obj.stringDictionary valueForKey:@"one"][@"stringCol"] isEqualToString:child1.stringCol]);

    [obj.embeddedDictionary setValue:child2 forKey:@"two"];
    XCTAssertEqual([[obj.embeddedDictionary valueForKey:@"two"][@"intCol"] integerValue], child2.intCol);

    [realm commitWriteTransaction];
    XCTAssertEqualObjects([obj.stringDictionary valueForKey:@"invalidated"], @NO);
}

- (void)testObjectAggregate {
    RLMRealm *realm = [RLMRealm defaultRealm];

    AggregateDictionaryObject *obj = [AggregateDictionaryObject new];
    XCTAssertEqual(0, [obj.dictionary sumOfProperty:@"intCol"].intValue);
    XCTAssertNil([obj.dictionary averageOfProperty:@"intCol"]);
    XCTAssertNil([obj.dictionary minOfProperty:@"intCol"]);
    XCTAssertNil([obj.dictionary maxOfProperty:@"intCol"]);

    NSDate *dateMinInput = [NSDate date];
    NSDate *dateMaxInput = [dateMinInput dateByAddingTimeInterval:1000];

    [realm transactionWithBlock:^{
        [AggregateObject createInRealm:realm withValue:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
        [AggregateObject createInRealm:realm withValue:@[@1, @0.0f, @2.5, @NO, dateMaxInput]];
        [AggregateObject createInRealm:realm withValue:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
        [AggregateObject createInRealm:realm withValue:@[@1, @0.0f, @2.5, @NO, dateMaxInput]];
        [AggregateObject createInRealm:realm withValue:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
        [AggregateObject createInRealm:realm withValue:@[@1, @0.0f, @2.5, @NO, dateMaxInput]];
        [AggregateObject createInRealm:realm withValue:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
        [AggregateObject createInRealm:realm withValue:@[@1, @0.0f, @2.5, @NO, dateMaxInput]];
        [AggregateObject createInRealm:realm withValue:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
        [AggregateObject createInRealm:realm withValue:@[@0, @1.2f, @0.0, @YES, dateMinInput]];

        RLMResults<AggregateObject *> *allObjects = [AggregateObject allObjectsInRealm:realm];
        for (NSUInteger i = 0; i < allObjects.count; i++) {
            NSString *key = [NSString stringWithFormat:@"item%lu", (unsigned long)i];
            obj.dictionary[key] = allObjects[i];
        }
    }];

    void (^test)(void) = ^{
        RLMDictionary *dictionary = obj.dictionary;

        // SUM
        XCTAssertEqual([dictionary sumOfProperty:@"intCol"].integerValue, 4);
        XCTAssertEqualWithAccuracy([dictionary sumOfProperty:@"floatCol"].floatValue, 7.2f, 0.1f);
        XCTAssertEqualWithAccuracy([dictionary sumOfProperty:@"doubleCol"].doubleValue, 10.0, 0.1f);
        RLMAssertThrowsWithReasonMatching([dictionary sumOfProperty:@"foo"], @"foo.*AggregateObject");
        RLMAssertThrowsWithReasonMatching([dictionary sumOfProperty:@"boolCol"], @"sum.*bool");
        RLMAssertThrowsWithReasonMatching([dictionary sumOfProperty:@"dateCol"], @"sum.*date");

        // Average
        XCTAssertEqualWithAccuracy([dictionary averageOfProperty:@"intCol"].doubleValue, 0.4, 0.1f);
        XCTAssertEqualWithAccuracy([dictionary averageOfProperty:@"floatCol"].doubleValue, 0.72, 0.1f);
        XCTAssertEqualWithAccuracy([dictionary averageOfProperty:@"doubleCol"].doubleValue, 1.0, 0.1f);
        RLMAssertThrowsWithReasonMatching([dictionary averageOfProperty:@"foo"], @"foo.*AggregateObject");
        RLMAssertThrowsWithReasonMatching([dictionary averageOfProperty:@"boolCol"], @"average.*bool");
        RLMAssertThrowsWithReasonMatching([dictionary averageOfProperty:@"dateCol"], @"average.*date");

        // MIN
        XCTAssertEqual(0, [[dictionary minOfProperty:@"intCol"] intValue]);
        XCTAssertEqual(0.0f, [[dictionary minOfProperty:@"floatCol"] floatValue]);
        XCTAssertEqual(0.0, [[dictionary minOfProperty:@"doubleCol"] doubleValue]);
        XCTAssertEqualObjects(dateMinInput, [dictionary minOfProperty:@"dateCol"]);
        RLMAssertThrowsWithReasonMatching([dictionary minOfProperty:@"foo"], @"foo.*AggregateObject");
        RLMAssertThrowsWithReasonMatching([dictionary minOfProperty:@"boolCol"], @"min.*bool");

        // MAX
        XCTAssertEqual(1, [[dictionary maxOfProperty:@"intCol"] intValue]);
        XCTAssertEqual(1.2f, [[dictionary maxOfProperty:@"floatCol"] floatValue]);
        XCTAssertEqual(2.5, [[dictionary maxOfProperty:@"doubleCol"] doubleValue]);
        XCTAssertEqualObjects(dateMaxInput, [dictionary maxOfProperty:@"dateCol"]);
        RLMAssertThrowsWithReasonMatching([dictionary maxOfProperty:@"foo"], @"foo.*AggregateObject");
        RLMAssertThrowsWithReasonMatching([dictionary maxOfProperty:@"boolCol"], @"max.*bool");
    };

    test();
    [realm transactionWithBlock:^{ [realm addObject:obj]; }];
    test();
}

- (void)testRenamedPropertyAggregate {
    RLMRealm *realm = [RLMRealm defaultRealm];

    LinkToRenamedProperties1 *obj = [LinkToRenamedProperties1 new];
    XCTAssertEqual(0, [obj.dictionary sumOfProperty:@"propA"].intValue);
    XCTAssertNil([obj.dictionary averageOfProperty:@"propA"]);
    XCTAssertNil([obj.dictionary minOfProperty:@"propA"]);
    XCTAssertNil([obj.dictionary maxOfProperty:@"propA"]);
    XCTAssertThrows([obj.dictionary sumOfProperty:@"prop 1"]);

    [realm transactionWithBlock:^{
        [RenamedProperties1 createInRealm:realm withValue:@[@1, @""]];
        [RenamedProperties1 createInRealm:realm withValue:@[@2, @""]];
        [RenamedProperties1 createInRealm:realm withValue:@[@3, @""]];

        RLMResults<RenamedProperties1 *> *allObjects = [RenamedProperties1 allObjectsInRealm:realm];
        for (NSUInteger i = 0; i < allObjects.count; i++) {
            NSString *key = [NSString stringWithFormat:@"item%lu", (unsigned long)i];
            obj.dictionary[key] = allObjects[i];
        }
    }];

    XCTAssertEqual(6, [obj.dictionary sumOfProperty:@"propA"].intValue);
    XCTAssertEqual(2.0, [obj.dictionary averageOfProperty:@"propA"].doubleValue);
    XCTAssertEqual(1, [[obj.dictionary minOfProperty:@"propA"] intValue]);
    XCTAssertEqual(3, [[obj.dictionary maxOfProperty:@"propA"] intValue]);

    [realm transactionWithBlock:^{ [realm addObject:obj]; }];

    XCTAssertEqual(6, [obj.dictionary sumOfProperty:@"propA"].intValue);
    XCTAssertEqual(2.0, [obj.dictionary averageOfProperty:@"propA"].doubleValue);
    XCTAssertEqual(1, [[obj.dictionary minOfProperty:@"propA"] intValue]);
    XCTAssertEqual(3, [[obj.dictionary maxOfProperty:@"propA"] intValue]);
}

-(void)testInsertMultiple {
    RLMRealm *realm = [self realmWithTestPath];
    
    [realm beginWriteTransaction];
    DictionaryPropertyObject *obj = [DictionaryPropertyObject createInRealm:realm withValue: @{@"stringDictionary": @{}}];

    StringObject *child1 = [StringObject createInRealm:realm withValue:@[@"a"]];
    StringObject *child2 = [[StringObject alloc] init];
    child2.stringCol = @"b";
    [obj.stringDictionary setValuesForKeysWithDictionary:@{@"a": child1, @"b": child2}];
    [realm commitWriteTransaction];
    
    RLMResults *children = [StringObject allObjectsInRealm:realm];
    XCTAssertEqualObjects([children[0] stringCol], @"a", @"First child should be 'a'");
    XCTAssertEqualObjects([children[1] stringCol], @"b", @"Second child should be 'b'");
}

- (void)testReplaceObjectInUnmanagedDictionary {
    DictionaryPropertyObject *dict = [[DictionaryPropertyObject alloc] init];
    
    StringObject *stringObj1 = [[StringObject alloc] initWithValue:@{@"stringCol": @"a"}];
    StringObject *stringObj2 = [[StringObject alloc] initWithValue:@{@"stringCol": @"b"}];
    StringObject *stringObj3 = [[StringObject alloc] initWithValue:@{@"stringCol": @"c"}];
    dict.stringDictionary[@"a"] = stringObj1;
    dict.stringDictionary[@"b"] = stringObj2;
    dict.stringDictionary[@"c"] = stringObj3;
    
    IntObject *intObj1 = [[IntObject alloc] initWithValue:@{@"intCol": @0}];
    IntObject *intObj2 = [[IntObject alloc] initWithValue:@{@"intCol": @1}];
    IntObject *intObj3 = [[IntObject alloc] initWithValue:@{@"intCol": @2}];
    dict.intObjDictionary[@"a"] = intObj1;
    dict.intObjDictionary[@"b"] = intObj2;
    dict.intObjDictionary[@"c"] = intObj3;

    XCTAssertEqualObjects(dict.stringDictionary[@"a"], stringObj1, @"Objects should be equal");
    XCTAssertEqualObjects(dict.stringDictionary[@"b"], stringObj2, @"Objects should be equal");
    XCTAssertEqualObjects(dict.stringDictionary[@"c"], stringObj3, @"Objects should be equal");
    XCTAssertEqual(dict.stringDictionary.count, 3U, @"Should have 3 elements in stringDictionary");
    
    XCTAssertEqualObjects(dict.intObjDictionary[@"a"], intObj1, @"Objects should be equal");
    XCTAssertEqualObjects(dict.intObjDictionary[@"b"], intObj2, @"Objects should be equal");
    XCTAssertEqualObjects(dict.intObjDictionary[@"c"], intObj3, @"Objects should be equal");
    XCTAssertEqual(dict.intObjDictionary.count, 3U, @"Should have 3 elements in intDictionary");
    
    StringObject *stringObj4 = [[StringObject alloc] initWithValue:@{@"stringCol": @"d"}];
    
    dict.stringDictionary[@"a"] = stringObj4;
    
    XCTAssertEqualObjects(dict.stringDictionary[@"a"], stringObj4, @"Objects should be replaced");
    XCTAssertEqual(dict.stringDictionary.count, 3U, @"Should have 3 elements in stringDictionary");

    IntObject *intObj4 = [[IntObject alloc] initWithValue:@{@"intCol": @3}];
    
    dict.intObjDictionary[@"a"] = intObj4;

    XCTAssertEqualObjects(dict.intObjDictionary[@"a"], intObj4, @"Objects should be replaced");
    XCTAssertEqual(dict.intObjDictionary.count, 3U, @"Should have 3 elements in intDictionary");
    
    RLMAssertThrowsWithReasonMatching([dict.stringDictionary setObject:(id)intObj4 forKey:@"a"],
                                      @"IntObject.*StringObject");
    RLMAssertThrowsWithReasonMatching([dict.intObjDictionary setObject:(id)stringObj4 forKey:@"a"],
                                      @"StringObject.*IntObject");
}

- (void)testExchangeObjectForKeyWithObjectForKey {
    
    void (^test)(RLMDictionary *) = ^(RLMDictionary *dict) {
        id obj = dict[@"a"];
        dict[@"a"] = dict[@"b"];
        dict[@"b"] = obj;
        XCTAssertEqual(2U, dict.count);
        XCTAssertEqualObjects(@"b", [dict[@"a"] stringCol]);
        XCTAssertEqualObjects(@"a", [dict[@"b"] stringCol]);
        
        obj = dict[@"a"];
        dict[@"a"] = dict[@"b"];
        dict[@"b"] = obj;
        XCTAssertEqual(2U, dict.count);
        XCTAssertEqualObjects(@"a", [dict[@"a"] stringCol]);
        XCTAssertEqualObjects(@"b", [dict[@"b"] stringCol]);
    };
    
    DictionaryPropertyObject *dict = [[DictionaryPropertyObject alloc] initWithValue:@{@"stringDictionary": @{@"a": [[StringObject alloc] initWithValue:@{@"stringCol": @"a"}], @"b": [[StringObject alloc] initWithValue:@{@"stringCol": @"b"}]}}];

    test(dict.stringDictionary);
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm addObject:dict];
    test(dict.stringDictionary);
    [realm commitWriteTransaction];
}

- (void)testObjectForKey {
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    EmployeeObject *po1 = [EmployeeObject createInRealm:realm withValue:@{@"name": @"Joe",  @"age": @40, @"hired": @YES}];
    EmployeeObject *po2 = [EmployeeObject createInRealm:realm withValue:@{@"name": @"John", @"age": @30, @"hired": @NO}];
    EmployeeObject *po3 = [EmployeeObject createInRealm:realm withValue:@{@"name": @"Jill", @"age": @25, @"hired": @YES}];
    EmployeeObject *deleted = [EmployeeObject createInRealm:realm withValue:@{@"name": @"Jill", @"age": @25, @"hired": @YES}];
    EmployeeObject *indirectlyDeleted = [EmployeeObject allObjectsInRealm:realm].lastObject;
    [realm deleteObject:deleted];
    
    // create company
    CompanyObject *company = [[CompanyObject alloc] init];
    company.name = @"name";
    [company.employeeDict setObject:po1 forKey:@"po1"];
    [company.employeeDict setObject:po2 forKey:@"po2"];
    [company.employeeDict setObject:po3 forKey:@"po3"];
    [company.employeeDict setObject:deleted forKey:@"deleted"];
    
    // test unmanaged
    XCTAssertNotNil(company.employeeDict[@"deleted"]);
    XCTAssertTrue(deleted.isInvalidated);
    [company.employeeDict removeObjectForKey:@"deleted"];
    
    // add to realm
    [realm addObject:company];
    [realm commitWriteTransaction];
    
    // test LinkView
    XCTAssertEqual(3U, company.employeeDict.count);
    XCTAssertEqualObjects(po2.name, [company.employeeDict[@"po2"] name]);
        
    // invalid object
    XCTAssertTrue(indirectlyDeleted.isInvalidated);
    
    RLMResults *employees = [company.employeeDict objectsWhere:@"age = %@", @40];
    XCTAssertEqual(0U, [employees indexOfObject:po1]);
    XCTAssertEqual((NSUInteger)NSNotFound, [employees indexOfObject:po3]);
}

- (void)testObjectWhere {
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    [EmployeeObject createInRealm:realm withValue:@{@"name": @"Joe",  @"age": @40, @"hired": @YES}];
    [EmployeeObject createInRealm:realm withValue:@{@"name": @"John", @"age": @30, @"hired": @NO}];
    [EmployeeObject createInRealm:realm withValue:@{@"name": @"Jill", @"age": @25, @"hired": @YES}];
    [EmployeeObject createInRealm:realm withValue:@{@"name": @"Bill", @"age": @55, @"hired": @YES}];
    
    // create company
    CompanyObject *company = [[CompanyObject alloc] init];
    company.name = @"name";
    for(EmployeeObject *eo in [EmployeeObject allObjectsInRealm:realm]) {
        company.employeeDict[eo.name] = eo;
    }
    
    // test unmanaged
    RLMAssertThrowsWithReasonMatching([company.employeeDict objectsWhere:@"name = 'Jill'"],
                                      @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");

    // add to realm
    [realm addObject:company];
    [realm commitWriteTransaction];
    
    // test LinkView RLMDictionary
    XCTAssertEqualObjects(@"Jill", [[company.employeeDict objectsWhere:@"name = 'Jill'"].firstObject name]);
    XCTAssertEqualObjects(@"Joe", [[company.employeeDict objectsWhere:@"name = 'Joe'"].firstObject name]);
    XCTAssertEqual([company.employeeDict objectsWhere:@"name = 'JoJo'"].count, 0U);
    
    RLMResults *results = [company.employeeDict objectsWhere:@"age > 30"];
    XCTAssertEqual(0U, [results indexOfObjectWhere:@"name = 'Joe'"]);
    XCTAssertEqual(1U, [results indexOfObjectWhere:@"name = 'Bill'"]);
    XCTAssertEqual((NSUInteger)NSNotFound, [results indexOfObjectWhere:@"name = 'John'"]);
    XCTAssertEqual((NSUInteger)NSNotFound, [results indexOfObjectWhere:@"name = 'Jill'"]);
}

- (void)testSetValueForKey {
    RLMRealm *realm = self.realmWithTestPath;
    
    [realm beginWriteTransaction];
    CompanyObject *company = [[CompanyObject alloc] init];
    company.name = @"name";

    RLMAssertThrowsWithReasonMatching([company.employeeDict setValue:@"name" forKey:@"name"], @"Value of type '__NSCFConstantString' does not match RLMDictionary value type 'EmployeeObject'.");

    EmployeeObject *e = [EmployeeObject createInRealm:realm withValue:@{@"name": @"Jane",  @"age": @(1), @"hired": @YES}];
    [company.employeeDict setValue:e forKey:@"e"];
    XCTAssertEqualObjects(((EmployeeObject *)[company.employeeDict valueForKey:@"e"]).name, @"Jane");

    [realm addObject:company];
    [realm commitWriteTransaction];
    
    XCTAssertThrows([company.employeeDict setValue:@{} forKey:@"e2"]);
    XCTAssertNil([company.employeeDict valueForKey:@"e2"]);
    
    // managed
    NSMutableArray *ages = [NSMutableArray array];
    [realm beginWriteTransaction];
    for (int i = 0; i < 30; ++i) {
        [ages addObject:@(20)];
        EmployeeObject *eo = [EmployeeObject createInRealm:realm withValue:@{@"name": @"Joe",  @"age": @(i), @"hired": @YES}];
        company.employeeDict[[NSString stringWithFormat:@"%d", i]] = eo;
    }
    
    [realm commitWriteTransaction];
    EmployeeObject *o = [[EmployeeObject objectsInRealm:realm where:@"name = 'Jane'"] firstObject];
    XCTAssertEqualObjects(((EmployeeObject *)[company.employeeDict valueForKey:@"e"]).name, o.name);
    
    // unmanaged object
    company = [[CompanyObject alloc] init];
    ages = [NSMutableArray array];
    for (int i = 0; i < 30; ++i) {
        [ages addObject:@(20)];
        EmployeeObject *eo = [[EmployeeObject alloc] initWithValue:@{@"name": @"Jamie",  @"age": @(i), @"hired": @YES}];
        company.employeeDict[[NSString stringWithFormat:@"%d", i]] = eo;
    }

    XCTAssertEqualObjects(((EmployeeObject *)[company.employeeDict valueForKey:@"0"]).name, @"Jamie");
}

- (void)testValueForCollectionOperationKeyPath {
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    EmployeeObject *e1 = [PrimaryEmployeeObject createInRealm:realm withValue:@{@"name": @"A", @"age": @20, @"hired": @YES}];
    EmployeeObject *e2 = [PrimaryEmployeeObject createInRealm:realm withValue:@{@"name": @"B", @"age": @30, @"hired": @NO}];
    EmployeeObject *e3 = [PrimaryEmployeeObject createInRealm:realm withValue:@{@"name": @"C", @"age": @40, @"hired": @YES}];
    EmployeeObject *e4 = [PrimaryEmployeeObject createInRealm:realm withValue:@{@"name": @"D", @"age": @50, @"hired": @YES}];
    PrimaryCompanyObject *c1 = [PrimaryCompanyObject createInRealm:realm withValue:@{@"name": @"ABC AG", @"employeeDict": @{@"e1": e1, @"e2": e2, @"e3": e3, @"e4": e2}, @"employee": @[], @"employeeSet": @[]}];
    PrimaryCompanyObject *c2 = [PrimaryCompanyObject createInRealm:realm withValue:@{@"name": @"ABC AG 2", @"employeeDict": @{@"e1": e1, @"e4": e4}, @"employee": @[], @"employeeSet": @[]}];
    
    ArrayOfPrimaryCompanies *companies = [ArrayOfPrimaryCompanies createInRealm:realm withValue:@[@[c1, c2]]];
    [realm commitWriteTransaction];
    
    // count operator
    XCTAssertEqual([[c1.employeeDict valueForKeyPath:@"@count"] integerValue], 4);
    
    // numeric operators
    XCTAssertEqual([[c1.employeeDict valueForKeyPath:@"@min.age"] intValue], 20);
    XCTAssertEqual([[c1.employeeDict valueForKeyPath:@"@max.age"] intValue], 40);
    XCTAssertEqual([[c1.employeeDict valueForKeyPath:@"@sum.age"] integerValue], 120);
    XCTAssertEqualWithAccuracy([[c1.employeeDict valueForKeyPath:@"@avg.age"] doubleValue], 30, 0.1f);
    
    // collection
    XCTAssertEqualObjects([[c1.employeeDict valueForKeyPath:@"@unionOfObjects.name"] sortedArrayUsingSelector:@selector(compare:)],
                          ([@[@"A", @"B", @"C", @"B"] sortedArrayUsingSelector:@selector(compare:)]));
    XCTAssertEqualObjects([[c1.employeeDict valueForKeyPath:@"@distinctUnionOfObjects.name"] sortedArrayUsingSelector:@selector(compare:)],
                          (@[@"A", @"B", @"C"]));
    NSComparator cmp = ^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare: obj2];
        
    };
    XCTAssertEqualObjects([[companies.companies valueForKeyPath:@"@unionOfArrays.employeeDict"] sortedArrayUsingComparator:cmp],
                          (@[@"e1", @"e1", @"e2", @"e3", @"e4", @"e4"]));
    XCTAssertEqualObjects([[companies.companies valueForKeyPath:@"@distinctUnionOfArrays.employeeDict"] sortedArrayUsingComparator:cmp],
                          (@[@"e1", @"e2", @"e3", @"e4"]));

    // invalid key paths
    RLMAssertThrowsWithReasonMatching([c1.employeeDict valueForKeyPath:@"@invalid.name"],
                                      @"Unsupported KVC collection operator found in key path '@invalid.name'");
    RLMAssertThrowsWithReasonMatching([c1.employeeDict valueForKeyPath:@"@sum"],
                                      @"Missing key path for KVC collection operator sum in key path '@sum'");
    RLMAssertThrowsWithReasonMatching([c1.employeeDict valueForKeyPath:@"@sum."],
                                      @"Missing key path for KVC collection operator sum in key path '@sum.'");
    RLMAssertThrowsWithReasonMatching([c1.employeeDict valueForKeyPath:@"@sum.employees.@sum.age"],
                                      @"Nested key paths.*not supported");
}

- (void)testCrossThreadAccess {
    CompanyObject *company = [[CompanyObject alloc] init];
    company.name = @"name";
    
    EmployeeObject *eo = [[EmployeeObject alloc] initWithValue:@{@"name": @"Joe",  @"age": @40, @"hired": @YES}];
    company.employeeDict[@"eo"] = eo;
    RLMDictionary *employees = company.employeeDict;
    
    // Unmanaged object can be accessed from other threads
    [self dispatchAsyncAndWait:^{
        XCTAssertNoThrow(company.employeeDict);
        XCTAssertNoThrow(employees[@"eo"]);
    }];
    
    [RLMRealm.defaultRealm beginWriteTransaction];
    [RLMRealm.defaultRealm addObject:company];
    [RLMRealm.defaultRealm commitWriteTransaction];
    
    employees = company.employeeDict;
    XCTAssertNoThrow(company.employeeDict);
    XCTAssertNoThrow(employees[@"eo"]);
    [self dispatchAsyncAndWait:^{
        XCTAssertThrows(company.employeeDict);
        XCTAssertThrows(employees.allValues);
        XCTAssertThrows(employees.allKeys);
        XCTAssertThrows(employees[@"eo"]);
    }];
}

- (void)testSortByNoColumns {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    DogObject *a2 = [DogObject createInDefaultRealmWithValue:@[@"a", @2]];
    DogObject *b1 = [DogObject createInDefaultRealmWithValue:@[@"b", @1]];
    DogObject *a1 = [DogObject createInDefaultRealmWithValue:@[@"a", @1]];
    DogObject *b2 = [DogObject createInDefaultRealmWithValue:@[@"b", @2]];
    
    RLMDictionary<NSString *, DogObject *><RLMString, DogObject> *dict
        = [DogDictionaryObject createInDefaultRealmWithValue:@[@{@"a1": a1, @"b1": b1, @"a2": a2, @"b2": b2}]].dogs;
    [realm commitWriteTransaction];
    
    RLMResults *notActuallySorted = [dict sortedResultsUsingDescriptors:@[]];
    XCTAssertEqual(notActuallySorted.count, dict.count);
    XCTAssertTrue([dict[@"a1"] isEqualToObject:notActuallySorted[0]]);
    XCTAssertTrue([dict[@"b2"] isEqualToObject:notActuallySorted[1]]);
    XCTAssertTrue([dict[@"b1"] isEqualToObject:notActuallySorted[2]]);
    XCTAssertTrue([dict[@"a2"] isEqualToObject:notActuallySorted[3]]);
}

- (void)testSortByMultipleColumns {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    DogObject *a1 = [DogObject createInDefaultRealmWithValue:@[@"a", @1]];
    DogObject *a2 = [DogObject createInDefaultRealmWithValue:@[@"a", @2]];
    DogObject *b1 = [DogObject createInDefaultRealmWithValue:@[@"b", @1]];
    DogObject *b2 = [DogObject createInDefaultRealmWithValue:@[@"b", @2]];
    
    DogDictionaryObject *ddo = [DogDictionaryObject createInDefaultRealmWithValue:@[@{@"a1": a1, @"b1": b1, @"a2": a2, @"b2": b2}]];
    [realm commitWriteTransaction];
    
    bool (^checkOrder)(NSArray *, NSArray *, NSArray *) = ^bool(NSArray *properties, NSArray *ascending, NSArray *dogs) {
        NSArray *sort = @[[RLMSortDescriptor sortDescriptorWithKeyPath:properties[0] ascending:[ascending[0] boolValue]],
                          [RLMSortDescriptor sortDescriptorWithKeyPath:properties[1] ascending:[ascending[1] boolValue]]];
        RLMResults *actual = [ddo.dogs sortedResultsUsingDescriptors:sort];
        
        return [actual[0] isEqualToObject:dogs[0]]
        && [actual[1] isEqualToObject:dogs[1]]
        && [actual[2] isEqualToObject:dogs[2]]
        && [actual[3] isEqualToObject:dogs[3]];
    };
    
    // Check each valid sort
    XCTAssertTrue(checkOrder(@[@"dogName", @"age"], @[@YES, @YES], @[a1, a2, b1, b2]));
    XCTAssertTrue(checkOrder(@[@"dogName", @"age"], @[@YES, @NO], @[a2, a1, b2, b1]));
    XCTAssertTrue(checkOrder(@[@"dogName", @"age"], @[@NO, @YES], @[b1, b2, a1, a2]));
    XCTAssertTrue(checkOrder(@[@"dogName", @"age"], @[@NO, @NO], @[b2, b1, a2, a1]));
    XCTAssertTrue(checkOrder(@[@"age", @"dogName"], @[@YES, @YES], @[a1, b1, a2, b2]));
    XCTAssertTrue(checkOrder(@[@"age", @"dogName"], @[@YES, @NO], @[b1, a1, b2, a2]));
    XCTAssertTrue(checkOrder(@[@"age", @"dogName"], @[@NO, @YES], @[a2, b2, a1, b1]));
    XCTAssertTrue(checkOrder(@[@"age", @"dogName"], @[@NO, @NO], @[b2, a2, b1, a1]));
}

- (void)testSortByRenamedColumns {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    id value = @{@"dictionary": @{@"0": @[@1, @"c"], @"1": @[@2, @"b"], @"2": @[@3, @"a"]}, @"set": @[]};
    LinkToRenamedProperties1 *obj = [LinkToRenamedProperties1 createInRealm:realm withValue:value];
    
    // FIXME: sorting has to use the column names because the parsing is done by
    // the object store. This is not ideal.
    XCTAssertEqualObjects([[obj.dictionary sortedResultsUsingKeyPath:@"prop 1" ascending:YES] valueForKeyPath:@"propA"],
                          (@[@1, @2, @3]));
    XCTAssertEqualObjects([[obj.dictionary sortedResultsUsingKeyPath:@"prop 2" ascending:YES] valueForKeyPath:@"propA"],
                          (@[@3, @2, @1]));
    
    LinkToRenamedProperties2 *obj2 = [LinkToRenamedProperties2 allObjectsInRealm:realm].firstObject;
    XCTAssertEqualObjects([[obj2.dictionary sortedResultsUsingKeyPath:@"prop 1" ascending:YES] valueForKeyPath:@"propC"],
                          (@[@1, @2, @3]));
    XCTAssertEqualObjects([[obj2.dictionary sortedResultsUsingKeyPath:@"prop 2" ascending:YES] valueForKeyPath:@"propC"],
                          (@[@3, @2, @1]));
    
    [realm cancelWriteTransaction];
}

- (void)testDeleteLinksAndObjectsInDictionary {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    EmployeeObject *po1 = [EmployeeObject createInRealm:realm withValue:@[@"Joe", @40, @YES]];
    EmployeeObject *po2 = [EmployeeObject createInRealm:realm withValue:@[@"John", @30, @NO]];
    EmployeeObject *po3 = [EmployeeObject createInRealm:realm withValue:@[@"Jill", @25, @YES]];
    
    CompanyObject *company = [[CompanyObject alloc] init];
    company.name = @"name";
    for (EmployeeObject *eo in [EmployeeObject allObjects]) {
        company.employeeDict[eo.name] = eo;
    }
    [realm addObject:company];
    [realm commitWriteTransaction];
    
    RLMDictionary *peopleInCompany = company.employeeDict;
    
    // Delete link to employee
    XCTAssertThrowsSpecificNamed([peopleInCompany removeObjectForKey:@"Joe"], NSException, @"RLMException", @"Not allowed in read transaction");
    XCTAssertEqual(peopleInCompany.count, 3U, @"No links should have been deleted");
    
    [realm beginWriteTransaction];
    XCTAssertNoThrow([peopleInCompany removeObjectForKey:@"John"], @"Should delete link to employee");
    [realm commitWriteTransaction];
    
    XCTAssertEqual(peopleInCompany.count, 2U, @"link deleted when accessing via links");
    EmployeeObject *test = peopleInCompany[@"Joe"];
    XCTAssertEqual(test.age, po1.age, @"Should be equal");
    XCTAssertEqualObjects(test.name, po1.name, @"Should be equal");
    XCTAssertEqual(test.hired, po1.hired, @"Should be equal");
    XCTAssertTrue([test isEqualToObject:po1], @"Should be equal");
    
    test = peopleInCompany[@"Jill"];
    XCTAssertEqual(test.age, po3.age, @"Should be equal");
    XCTAssertEqualObjects(test.name, po3.name, @"Should be equal");
    XCTAssertEqual(test.hired, po3.hired, @"Should be equal");
    XCTAssertTrue([test isEqualToObject:po3], @"Should be equal");
    
    XCTAssertThrowsSpecificNamed([peopleInCompany removeAllObjects], NSException, @"RLMException", @"Not allowed in read transaction");
    XCTAssertThrowsSpecificNamed(peopleInCompany[@"Joe"] = po2, NSException, @"RLMException", @"Replace not allowed in read transaction");
    XCTAssertThrowsSpecificNamed(peopleInCompany[@"John"] = po2, NSException, @"RLMException", @"Add not allowed in read transaction");
    
    [realm beginWriteTransaction];
    XCTAssertNoThrow(peopleInCompany[@"Jill"] = nil, @"Should delete value for key");
    XCTAssertEqual(peopleInCompany.count, 1U, @"1 remaining link");
    peopleInCompany[@"Joe"] = po2;
    XCTAssertEqual(peopleInCompany.count, 1U, @"1 link replaced");
    peopleInCompany[@"Jill"] = po3;
    XCTAssertEqual(peopleInCompany.count, 2U, @"2 links");
    XCTAssertNoThrow([peopleInCompany removeAllObjects], @"Should delete all links");
    XCTAssertEqual(peopleInCompany.count, 0U, @"0 remaining links");
    [realm commitWriteTransaction];
    
    RLMResults *allPeople = [EmployeeObject allObjects];
    XCTAssertEqual(allPeople.count, 3U, @"Only links should have been deleted, not the employees");
}

- (void)testDictionaryDescription {
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    RLMDictionary<NSString *, EmployeeObject *><RLMString, EmployeeObject> *employees = [CompanyObject createInDefaultRealmWithValue:@[@"company"]].employeeDict;
    RLMDictionary<NSString *, NSNumber *><RLMString, RLMInt> *ints = [AllPrimitiveDictionaries createInDefaultRealmWithValue:@[]].intObj;
    for (NSInteger i = 0; i < 1012; ++i) {
        EmployeeObject *person = [[EmployeeObject alloc] init];
        person.name = @"Mary";
        person.age = 24;
        person.hired = YES;
        NSString *key = [NSString stringWithFormat:@"%li", (long)i];
        employees[key] = person;
        ints[key] = @(i + 100);
    }
    [realm commitWriteTransaction];

    RLMAssertMatches(employees.description,
                     @"(?s)RLMDictionary\\<string, EmployeeObject\\> \\<0x[a-z0-9]+\\> \\(\n"
                     @"\\[[0-9]+\\]: EmployeeObject \\{\n"
                     @"\t\tname = Mary;\n"
                     @"\t\tage = 24;\n"
                     @"\t\thired = 1;\n"
                     @"\t\\},\n"
                     @".*\n"
                     @"\\)");

    RLMAssertMatches(ints.description,
                     @"(?s)RLMDictionary\\<string, int\\> \\<0x[a-z0-9]+\\> \\(\n"
                     @"\\[[0-9]+\\]: [0-9]+,\n"
                     @"\\[[0-9]+\\]: [0-9]+,\n"
                     @".*\n"
                     @"\\[[0-9]+\\]: [0-9]+\n"
                     @"\\)");
}

- (void)testUnmanagedAssignment {
    IntObject *io1 = [[IntObject alloc] init];
    IntObject *io2 = [[IntObject alloc] init];
    IntObject *io3 = [[IntObject alloc] init];
    
    DictionaryPropertyObject *dict1 = [[DictionaryPropertyObject alloc] init];
    DictionaryPropertyObject *dict2 = [[DictionaryPropertyObject alloc] init];
    
    // Assigning NSDictionary shallow copies
    dict1.intObjDictionary = (id)@{@"io1": io1, @"io2": io2};
    XCTAssertEqualObjects([dict1.intObjDictionary valueForKey:@"io1"], io1);
    
    [dict1 setValue:@{@"io1": io1, @"io3": io3} forKey:@"intObjDictionary"];
    XCTAssertEqualObjects([dict1.intObjDictionary valueForKey:@"io3"], io3);
    
    dict1[@"intObjDictionary"] = @{@"io2": io2, @"io3": io3};
    XCTAssertEqualObjects([dict1.intObjDictionary valueForKey:@"io3"], io3);

    // Assigning RLMDictionary shallow copies
    dict2.intObjDictionary = dict1.intObjDictionary;
    XCTAssertEqualObjects([dict2.intObjDictionary valueForKey:@"io3"], io3);

    [dict1.intObjDictionary removeAllObjects];
    XCTAssertEqualObjects([dict2.intObjDictionary valueForKey:@"io3"], io3);

    // Self-assignment is a no-op
    dict2.intObjDictionary = dict2.intObjDictionary;
    XCTAssertEqualObjects([dict2.intObjDictionary valueForKey:@"io3"], io3);
    dict2[@"intObjDictionary"] = dict2[@"intObjDictionary"];
    XCTAssertEqualObjects([dict2.intObjDictionary valueForKey:@"io3"], io3);
}

- (void)testManagedAssignment {
    RLMRealm *realm = self.realmWithTestPath;
    [realm beginWriteTransaction];
    
    IntObject *io1 = [IntObject createInRealm:realm withValue:@[@1]];
    IntObject *io2 = [IntObject createInRealm:realm withValue:@[@2]];
    IntObject *io3 = [IntObject createInRealm:realm withValue:@[@3]];
    
    DictionaryPropertyObject *dict1 = [[DictionaryPropertyObject alloc] init];
    DictionaryPropertyObject *dict2 = [[DictionaryPropertyObject alloc] init];

    // Assigning NSDictonary shallow copies
    dict1.intObjDictionary = (id)@{@"io1": io1, @"io2": io2};
    XCTAssertEqualObjects([dict1.intObjDictionary valueForKey:@"io1"], io1);
    
    [dict1 setValue:@{@"io1": io1, @"io3": io3} forKey:@"intObjDictionary"];
    XCTAssertEqualObjects([dict1.intObjDictionary valueForKey:@"io3"], io3);
    
    dict1[@"intObjDictionary"] = @{@"io2": io2, @"io3": io3};
    XCTAssertEqualObjects([dict1.intObjDictionary valueForKey:@"io2"], io2);
    
    // Assigning RLMDictionary shallow copies
    dict2.intObjDictionary = dict1.intObjDictionary;
    XCTAssertEqualObjects([dict2.intObjDictionary valueForKey:@"io2"], io2);
    
    [dict1.intObjDictionary removeAllObjects];
    XCTAssertEqualObjects([dict2.intObjDictionary valueForKey:@"io2"], io2);
    
    // Self-assignment is a no-op
    dict2.intObjDictionary = dict2.intObjDictionary;
    XCTAssertEqualObjects([dict2.intObjDictionary valueForKey:@"io2"], io2);
    dict2[@"intObjDictionary"] = dict2[@"intObjDictionary"];
    XCTAssertEqualObjects([dict2.intObjDictionary valueForKey:@"io2"], io2);

    [realm cancelWriteTransaction];
}

- (void)testAssignIncorrectType {
    RLMRealm *realm = self.realmWithTestPath;
    [realm beginWriteTransaction];
    DictionaryPropertyObject *dict = [DictionaryPropertyObject createInRealm:realm
                                                                   withValue:@{@"stringDictionary": @{@"a": [[StringObject alloc] initWithValue:@[@"a"]]}}];

    RLMAssertThrowsWithReason(dict.intObjDictionary = (id)dict.stringDictionary,
                              @"RLMDictionary<string, StringObject?> does not match expected type 'IntObject?' for property 'DictionaryPropertyObject.intObjDictionary'.");
    RLMAssertThrowsWithReason(dict[@"intObjDictionary"] = dict[@"stringDictionary"],
                              @"RLMDictionary<string, StringObject?> does not match expected type 'IntObject?' for property 'DictionaryPropertyObject.intObjDictionary'.");
    [realm cancelWriteTransaction];
}

- (void)testNotificationSentInitially {
    RLMRealm *realm = self.realmWithTestPath;
    [realm beginWriteTransaction];
    DictionaryPropertyObject *dict = [DictionaryPropertyObject createInRealm:realm
                                                                   withValue:@{@"stringDictionary": @{@"a": [[StringObject alloc] initWithValue:@[@"a"]]}}];
    [realm commitWriteTransaction];

    id expectation = [self expectationWithDescription:@""];
    id token = [dict.stringDictionary addNotificationBlock:^(RLMDictionary *dictionary, RLMDictionaryChange *change, NSError *error) {
        XCTAssertNotNil(dictionary);
        XCTAssertNil(change);
        XCTAssertNil(error);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [(RLMNotificationToken *)token invalidate];
}

- (void)testNotificationSentAfterCommit {
    RLMRealm *realm = self.realmWithTestPath;
    [realm beginWriteTransaction];
    DictionaryPropertyObject *dict = [DictionaryPropertyObject createInRealm:realm withValue:@{}];
    [realm commitWriteTransaction];

    __block bool first = true;
    __block id expectation = [self expectationWithDescription:@""];
    id token = [dict.stringDictionary addNotificationBlock:^(RLMDictionary *dictionary, RLMDictionaryChange *change, NSError *error) {
        XCTAssertNotNil(dictionary);
        XCTAssert(first ? !change : !!change);
        XCTAssertNil(error);
        first = false;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    [self dispatchAsyncAndWait:^{
        RLMRealm *realm = self.realmWithTestPath;
        [realm transactionWithBlock:^{
            RLMDictionary *dict = [(DictionaryPropertyObject *)[DictionaryPropertyObject allObjectsInRealm:realm].firstObject stringDictionary];
            dict[@"new"] = [[StringObject alloc] init];
        }];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [(RLMNotificationToken *)token invalidate];
}

- (void)testNotificationNotSentForUnrelatedChange {
    RLMRealm *realm = self.realmWithTestPath;
    [realm beginWriteTransaction];
    DictionaryPropertyObject *dict = [DictionaryPropertyObject createInRealm:realm withValue:@{}];
    [realm commitWriteTransaction];

    id expectation = [self expectationWithDescription:@""];
    id token = [dict.stringDictionary addNotificationBlock:^(__unused RLMDictionary *dictionary,
                                                             __unused RLMDictionaryChange *change,
                                                             __unused NSError *error) {
        // will throw if it's incorrectly called a second time due to the
        // unrelated write transaction
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // All notification blocks are called as part of a single runloop event, so
    // waiting for this one also waits for the above one to get a chance to run
    [self waitForNotification:RLMRealmDidChangeNotification realm:realm block:^{
        [self dispatchAsyncAndWait:^{
            RLMRealm *realm = self.realmWithTestPath;
            [realm transactionWithBlock:^{
                [DictionaryPropertyObject createInRealm:realm withValue:@{}];
            }];
        }];
    }];
    [(RLMNotificationToken *)token invalidate];
}

- (void)testNotificationSentOnlyForActualRefresh {
    RLMRealm *realm = self.realmWithTestPath;
    [realm beginWriteTransaction];
    DictionaryPropertyObject *dict = [DictionaryPropertyObject createInRealm:realm withValue:@{}];
    [realm commitWriteTransaction];

    __block id expectation = [self expectationWithDescription:@""];
    id token = [dict.stringDictionary addNotificationBlock:^(__unused RLMDictionary *dictionary,
                                                             __unused RLMDictionaryChange *change,
                                                             __unused NSError *error) {
        XCTAssertNotNil(dictionary);
        XCTAssertNil(error);
        // will throw if it's called a second time before we create the new
        // expectation object immediately before manually refreshing
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Turn off autorefresh, so the background commit should not result in a notification
    realm.autorefresh = NO;

    // All notification blocks are called as part of a single runloop event, so
    // waiting for this one also waits for the above one to get a chance to run
    [self waitForNotification:RLMRealmRefreshRequiredNotification realm:realm block:^{
        [self dispatchAsyncAndWait:^{
            RLMRealm *realm = self.realmWithTestPath;
            [realm transactionWithBlock:^{
                RLMDictionary *dict = [(DictionaryPropertyObject *)[DictionaryPropertyObject allObjectsInRealm:realm].firstObject stringDictionary];
                dict[@"new"] = [[StringObject alloc] init];
            }];
        }];
    }];

    expectation = [self expectationWithDescription:@""];
    [realm refresh];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [(RLMNotificationToken *)token invalidate];
}

- (void)testDeletingObjectWithNotificationsRegistered {
    RLMRealm *realm = self.realmWithTestPath;
    [realm beginWriteTransaction];
    DictionaryPropertyObject *dict = [DictionaryPropertyObject createInRealm:realm withValue:@{}];
    [realm commitWriteTransaction];
    
    __block id expectation = [self expectationWithDescription:@""];
    id token = [dict.stringDictionary addNotificationBlock:^(__unused RLMDictionary *dictionary,
                                                             __unused RLMDictionaryChange *change,
                                                             __unused NSError *error) {
        XCTAssertNotNil(dictionary);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    [realm beginWriteTransaction];
    [realm deleteObject:dict];
    [realm commitWriteTransaction];
    
    [(RLMNotificationToken *)token invalidate];
}

static RLMDictionary<NSString *, IntObject *><RLMString, IntObject> *managedTestDictionary() {
    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMDictionary<NSString *, IntObject *><RLMString, IntObject> *dict;
    [realm beginWriteTransaction];
    dict = [DictionaryPropertyObject createInDefaultRealmWithValue:
            @{@"intObjDictionary": @{@"0": @[@0], @"1": @[@1]}}].intObjDictionary;
    [realm commitWriteTransaction];
    return dict;
}

- (void)testAllMethodsCheckThread {
    RLMDictionary<NSString *, IntObject *><RLMString, IntObject> *dict = managedTestDictionary();
    IntObject *io = dict.allValues.firstObject;
    RLMRealm *realm = dict.realm;
    [realm beginWriteTransaction];
    
    [self dispatchAsyncAndWait:^{
        RLMAssertThrowsWithReasonMatching([dict count], @"thread");
        RLMAssertThrowsWithReasonMatching([dict objectForKey:@"thread"], @"thread");
        
        RLMAssertThrowsWithReasonMatching([dict setObject:io forKey:@"thread"], @"thread");
        RLMAssertThrowsWithReasonMatching([dict removeObjectForKey:@"thread"], @"thread");
        RLMAssertThrowsWithReasonMatching([dict setObject:nil forKey:@"thread"], @"thread");
        RLMAssertThrowsWithReasonMatching([dict removeAllObjects], @"thread");

        RLMAssertThrowsWithReasonMatching([dict objectsWhere:@"intCol = 0"], @"thread");
        RLMAssertThrowsWithReasonMatching([dict objectsWithPredicate:[NSPredicate predicateWithFormat:@"intCol = 0"]], @"thread");
        RLMAssertThrowsWithReasonMatching([dict sortedResultsUsingKeyPath:@"intCol" ascending:YES], @"thread");
        RLMAssertThrowsWithReasonMatching([dict sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"intCol" ascending:YES]]], @"thread");
        RLMAssertThrowsWithReasonMatching(dict[@"thread"], @"thread");
        RLMAssertThrowsWithReasonMatching(dict[@"thread"] = io, @"thread");
        RLMAssertThrowsWithReasonMatching([dict valueForKey:@"intCol"], @"thread");
        RLMAssertThrowsWithReasonMatching(({for (__unused id obj in dict);}), @"thread");
    }];
    [realm cancelWriteTransaction];
}

- (void)testAllMethodsCheckForInvalidation {
    RLMDictionary<NSString *, IntObject *><RLMString, IntObject> *dictionary = managedTestDictionary();
    IntObject *io = dictionary[@"0"];
    RLMRealm *realm = dictionary.realm;

    [realm beginWriteTransaction];

    XCTAssertNoThrow([dictionary objectClassName]);
    XCTAssertNoThrow([dictionary realm]);
    XCTAssertNoThrow([dictionary isInvalidated]);

    XCTAssertNoThrow([dictionary count]);
    XCTAssertNoThrow([dictionary allValues]);
    XCTAssertNoThrow([dictionary allKeys]);

    XCTAssertNoThrow(dictionary[@"new"] = io);
    XCTAssertNoThrow([dictionary setObject:io forKey:@"another"]);
    XCTAssertNoThrow(dictionary[@"new"] = nil);
    XCTAssertNoThrow([dictionary removeObjectForKey:@"another"]);

    XCTAssertNoThrow([dictionary objectsWhere:@"intCol = 0"]);
    XCTAssertNoThrow([dictionary objectsWithPredicate:[NSPredicate predicateWithFormat:@"intCol = 0"]]);
    XCTAssertNoThrow([dictionary sortedResultsUsingKeyPath:@"intCol" ascending:YES]);
    XCTAssertNoThrow([dictionary sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"intCol" ascending:YES]]]);
    XCTAssertNoThrow([dictionary valueForKey:@"0"]);
    XCTAssertNoThrow([dictionary setValue:io forKey:@"foo"]);
    XCTAssertNoThrow(({for (__unused id obj in dictionary);}));

    [realm cancelWriteTransaction];
    [realm invalidate];
    [realm beginWriteTransaction];
    io = [IntObject createInDefaultRealmWithValue:@[@0]];

    XCTAssertNoThrow([dictionary objectClassName]);
    XCTAssertNoThrow([dictionary realm]);
    XCTAssertNoThrow([dictionary isInvalidated]);

    RLMAssertThrowsWithReasonMatching([dictionary count], @"invalidated");
    RLMAssertThrowsWithReasonMatching([dictionary allValues], @"invalidated");
    XCTAssertNil(dictionary[@"new"]);

    RLMAssertThrowsWithReasonMatching(dictionary[@"new"] = io, @"invalidated");
    RLMAssertThrowsWithReasonMatching([dictionary setObject:io forKey:@"another"], @"invalidated");
    RLMAssertThrowsWithReasonMatching(dictionary[@"new"] = nil, @"invalidated");
    RLMAssertThrowsWithReasonMatching([dictionary removeObjectForKey:@"another"], @"invalidated");

    RLMAssertThrowsWithReasonMatching([dictionary objectsWhere:@"intCol = 0"], @"invalidated");
    RLMAssertThrowsWithReasonMatching([dictionary objectsWithPredicate:[NSPredicate predicateWithFormat:@"intCol = 0"]], @"invalidated");
    RLMAssertThrowsWithReasonMatching([dictionary sortedResultsUsingKeyPath:@"intCol" ascending:YES], @"invalidated");
    RLMAssertThrowsWithReasonMatching([dictionary sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"intCol" ascending:YES]]], @"invalidated");
    XCTAssertNil([dictionary valueForKey:@"new"]);
    RLMAssertThrowsWithReasonMatching([dictionary setValue:io forKey:@"foo"], @"invalidated");
    RLMAssertThrowsWithReasonMatching(({for (__unused id obj in dictionary);}), @"invalidated");

    [realm cancelWriteTransaction];
}

- (void)testMutatingMethodsCheckForWriteTransaction {
    RLMDictionary<NSString *, IntObject *><RLMString, IntObject> *dict = managedTestDictionary();
    IntObject *io = dict.allValues.firstObject;
    
    XCTAssertNoThrow([dict objectClassName]);
    XCTAssertNoThrow([dict realm]);
    XCTAssertNoThrow([dict isInvalidated]);
    
    XCTAssertNoThrow([dict count]);
    XCTAssertNoThrow([dict objectForKey:@"0"]);

    XCTAssertNoThrow([dict objectsWhere:@"intCol = 0"]);
    XCTAssertNoThrow([dict objectsWithPredicate:[NSPredicate predicateWithFormat:@"intCol = 0"]]);
    XCTAssertNoThrow([dict sortedResultsUsingKeyPath:@"intCol" ascending:YES]);
    XCTAssertNoThrow([dict sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"intCol" ascending:YES]]]);
    XCTAssertNoThrow(dict[@"0"]);
    XCTAssertNoThrow([dict valueForKey:@"intCol"]);
    XCTAssertNoThrow(({for (__unused id obj in dict);}));
    
    RLMAssertThrowsWithReasonMatching([dict setObject:io forKey:@"thread"], @"write transaction");
    RLMAssertThrowsWithReasonMatching([dict removeObjectForKey:@"thread"], @"write transaction");
    RLMAssertThrowsWithReasonMatching([dict setObject:nil forKey:@"thread"], @"write transaction");
    RLMAssertThrowsWithReasonMatching([dict removeAllObjects], @"write transaction");

    RLMAssertThrowsWithReasonMatching(dict[@"0"] = io, @"write transaction");
    RLMAssertThrowsWithReasonMatching([dict setValue:io forKey:@"intCol"], @"write transaction");
}

- (void)testDeleteObjectFromOutsideDictionary {
    RLMDictionary<NSString *, IntObject *><RLMString, IntObject> *dict = managedTestDictionary();
    RLMRealm *realm = dict.realm;
    [realm beginWriteTransaction];

    XCTAssertNotNil(dict[@"0"]);
    IntObject *o = dict.allValues[0];
    IntObject *o2 = dict.allValues[1];
    [realm deleteObject:o];
    [realm deleteObject:o2];
    XCTAssertEqualObjects(dict[@"0"], NSNull.null);
    XCTAssertEqualObjects(dict[@"1"], NSNull.null);

    [realm commitWriteTransaction];
}

- (void)testIsFrozen {
    RLMDictionary *unfrozen = managedTestDictionary();
    RLMDictionary *frozen = [unfrozen freeze];
    XCTAssertFalse(unfrozen.isFrozen);
    XCTAssertTrue(frozen.isFrozen);
}

- (void)testFreezingFrozenObjectReturnsSelf {
    RLMDictionary *dict = managedTestDictionary();
    RLMDictionary *frozen = [dict freeze];
    XCTAssertNotEqual(dict, frozen);
    XCTAssertNotEqual(dict.freeze, frozen);
    XCTAssertEqual(frozen, frozen.freeze);
}

- (void)testFreezeFromWrongThread {
    RLMDictionary *dict = managedTestDictionary();
    [self dispatchAsyncAndWait:^{
        RLMAssertThrowsWithReason([dict freeze],
                                  @"Realm accessed from incorrect thread");
    }];
}

- (void)testAccessFrozenFromDifferentThread {
    RLMDictionary *frozen = [managedTestDictionary() freeze];
    [self dispatchAsyncAndWait:^{
        XCTAssertEqualObjects(@([[frozen valueForKey:@"0"] intCol]), (@0));
    }];
}

- (void)testObserveFrozenDictionary {
    RLMDictionary *frozen = [managedTestDictionary() freeze];
    id block = ^(__unused BOOL deleted, __unused NSArray *changes, __unused NSError *error) {};
    RLMAssertThrowsWithReason([frozen addNotificationBlock:block],
                              @"Frozen Realms do not change and do not have change notifications.");
}

- (void)testQueryFrozenDictionary {
    RLMDictionary *frozen = [managedTestDictionary() freeze];
    XCTAssertEqualObjects([[frozen objectsWhere:@"intCol > 0"] valueForKey:@"intCol"], (@[@1]));
}

- (void)testFrozenDictionarysDoNotUpdate {
    RLMDictionary *dict = managedTestDictionary();
    RLMDictionary *frozen = [dict freeze];
    XCTAssertEqual(frozen.count, 2);
    [dict.realm transactionWithBlock:^{
        [dict removeObjectForKey:dict.allKeys.lastObject];
    }];
    XCTAssertEqual(frozen.count, 2);
}

- (void)testAddEntriesFromDictionaryUnmanaged {
    RLMDictionary<NSString *, StringObject *> *dict = [[DictionaryPropertyObject alloc] init].stringDictionary;
    RLMAssertThrowsWithReasonMatching([dict addEntriesFromDictionary:@[@"string"]],
                                      @"Cannot add entries from object of class '.*Array.*'");
    RLMAssertThrowsWithReason([dict addEntriesFromDictionary:@{@"": [[IntObject alloc] init]}],
                              @"Value of type 'IntObject' does not match RLMDictionary value type 'StringObject'.");
    RLMAssertThrowsWithReason([dict addEntriesFromDictionary:@{@1: [[StringObject alloc] init]}],
                              @"Invalid key '1' of type '" RLMConstantInt "' for expected type 'string'.");

    // Adding nil is a no-op
    XCTAssertNoThrow([dict addEntriesFromDictionary:self.nonLiteralNil]);
    XCTAssertEqual(dict.count, 0U);

    // Add into empty adds those entries
    [dict addEntriesFromDictionary:@{@"a": [[StringObject alloc] initWithValue:@[@"1"]],
                                     @"b": [[StringObject alloc] initWithValue:@[@"2"]]}];
    XCTAssertEqual(dict.count, 2U);
    XCTAssertEqualObjects(dict[@"a"].stringCol, @"1");
    XCTAssertEqualObjects(dict[@"b"].stringCol, @"2");

    // Duplicate keys overwrite the old values and leave any non-duplicates
    [dict addEntriesFromDictionary:@{@"a": [[StringObject alloc] initWithValue:@[@"3"]],
                                     @"c": [[StringObject alloc] initWithValue:@[@"4"]]}];
    XCTAssertEqual(dict.count, 3U);
    XCTAssertEqualObjects(dict[@"a"].stringCol, @"3");
    XCTAssertEqualObjects(dict[@"b"].stringCol, @"2");
    XCTAssertEqualObjects(dict[@"c"].stringCol, @"4");

    // Add from a RLMDictionary rather than a NSDictionary
    RLMDictionary<NSString *, StringObject *> *dict2 = [[DictionaryPropertyObject alloc] init].stringDictionary;
    dict2[@"d"] = [[StringObject alloc] initWithValue:@[@"5"]];
    [dict addEntriesFromDictionary:dict2];
    XCTAssertEqual(dict.count, 4U);
    XCTAssertEqualObjects(dict[@"a"].stringCol, @"3");
    XCTAssertEqualObjects(dict[@"b"].stringCol, @"2");
    XCTAssertEqualObjects(dict[@"c"].stringCol, @"4");
    XCTAssertEqualObjects(dict[@"d"].stringCol, @"5");
}

- (void)testAddEntriesFromDictionaryManaged {
    RLMDictionary<NSString *, IntObject *> *dict = managedTestDictionary();
    [dict.realm beginWriteTransaction];
    [dict removeAllObjects];

    RLMAssertThrowsWithReasonMatching([dict addEntriesFromDictionary:@[@"string"]],
                                      @"Cannot add entries from object of class '.*Array.*'");
    RLMAssertThrowsWithReason([dict addEntriesFromDictionary:@{@"": [[StringObject alloc] init]}],
                              @"Value of type 'StringObject' does not match RLMDictionary value type 'IntObject'.");
    RLMAssertThrowsWithReason([dict addEntriesFromDictionary:@{@1: [[IntObject alloc] init]}],
                              @"Invalid key '1' of type '" RLMConstantInt "' for expected type 'string'.");

    // Adding nil is a no-op
    XCTAssertNoThrow([dict addEntriesFromDictionary:self.nonLiteralNil]);
    XCTAssertEqual(dict.count, 0U);

    // Add into empty adds those entries
    [dict addEntriesFromDictionary:@{@"a": [[IntObject alloc] initWithValue:@[@1]],
                                     @"b": [[IntObject alloc] initWithValue:@[@2]]}];
    XCTAssertEqual(dict.count, 2U);
    XCTAssertEqual(dict[@"a"].intCol, 1);
    XCTAssertEqual(dict[@"b"].intCol, 2);

    // Duplicate keys overwrite the old values and leave any non-duplicates
    [dict addEntriesFromDictionary:@{@"a": [[IntObject alloc] initWithValue:@[@3]],
                                     @"c": [[IntObject alloc] initWithValue:@[@4]]}];
    XCTAssertEqual(dict.count, 3U);
    XCTAssertEqual(dict[@"a"].intCol, 3);
    XCTAssertEqual(dict[@"b"].intCol, 2);
    XCTAssertEqual(dict[@"c"].intCol, 4);

    // Add from a RLMDictionary rather than a NSDictionary
    RLMDictionary<NSString *, IntObject *> *dict2 = [[DictionaryPropertyObject alloc] init].intObjDictionary;
    dict2[@"d"] = [[IntObject alloc] initWithValue:@[@5]];
    [dict addEntriesFromDictionary:dict2];
    XCTAssertEqual(dict.count, 4U);
    XCTAssertEqual(dict[@"a"].intCol, 3);
    XCTAssertEqual(dict[@"b"].intCol, 2);
    XCTAssertEqual(dict[@"c"].intCol, 4);
    XCTAssertEqual(dict[@"d"].intCol, 5);

    [dict.realm cancelWriteTransaction];
}

- (void)testSetDictionaryUnmanaged {
    RLMDictionary<NSString *, StringObject *> *dict = [[DictionaryPropertyObject alloc] init].stringDictionary;
    RLMAssertThrowsWithReasonMatching([dict setDictionary:@[@"string"]],
                                      @"Cannot set dictionary to object of class '.*Array.*'");
    RLMAssertThrowsWithReason([dict setDictionary:@{@"": [[IntObject alloc] init]}],
                              @"Value of type 'IntObject' does not match RLMDictionary value type 'StringObject'.");
    RLMAssertThrowsWithReason([dict setDictionary:@{@1: [[StringObject alloc] init]}],
                              @"Invalid key '1' of type '" RLMConstantInt "' for expected type 'string'.");

    // Set into empty adds those entries
    [dict setDictionary:@{@"a": [[StringObject alloc] initWithValue:@[@"1"]],
                          @"b": [[StringObject alloc] initWithValue:@[@"2"]]}];
    XCTAssertEqual(dict.count, 2U);
    XCTAssertEqualObjects(dict[@"a"].stringCol, @"1");
    XCTAssertEqualObjects(dict[@"b"].stringCol, @"2");

    // New dictionary replaces the old one entirely
    [dict setDictionary:@{@"a": [[StringObject alloc] initWithValue:@[@"3"]],
                          @"c": [[StringObject alloc] initWithValue:@[@"4"]]}];
    XCTAssertEqual(dict.count, 2U);
    XCTAssertEqualObjects(dict[@"a"].stringCol, @"3");
    XCTAssertEqualObjects(dict[@"c"].stringCol, @"4");

    // Setting to nil clears
    XCTAssertNoThrow([dict setDictionary:self.nonLiteralNil]);
    XCTAssertEqual(dict.count, 0U);

    // Self-setting clears
    [dict setDictionary:@{@"a": [[StringObject alloc] initWithValue:@[@"3"]],
                          @"c": [[StringObject alloc] initWithValue:@[@"4"]]}];
    XCTAssertEqual(dict.count, 2U);
    [dict setDictionary:dict];
    XCTAssertEqual(dict.count, 0U);

    // Type error clears
    [dict setDictionary:@{@"a": [[StringObject alloc] initWithValue:@[@"3"]],
                          @"c": [[StringObject alloc] initWithValue:@[@"4"]]}];
    XCTAssertEqual(dict.count, 2U);
    RLMAssertThrowsWithReason([dict setDictionary:@{@"": [[IntObject alloc] init]}],
                              @"Value of type 'IntObject' does not match RLMDictionary value type 'StringObject'.");
    XCTAssertEqual(dict.count, 0U);
}

- (void)testSetDictionaryManaged {
    RLMDictionary<NSString *, IntObject *> *dict = managedTestDictionary();
    [dict.realm beginWriteTransaction];
    [dict removeAllObjects];

    RLMAssertThrowsWithReasonMatching([dict setDictionary:@[@"string"]],
                                      @"Cannot set dictionary to object of class '.*Array.*'");
    RLMAssertThrowsWithReason([dict setDictionary:@{@"": [[StringObject alloc] init]}],
                              @"Value of type 'StringObject' does not match RLMDictionary value type 'IntObject'.");
    RLMAssertThrowsWithReason([dict setDictionary:@{@1: [[IntObject alloc] init]}],
                              @"Invalid key '1' of type '" RLMConstantInt "' for expected type 'string'.");

    // Set into empty adds those entries
    [dict setDictionary:@{@"a": [[IntObject alloc] initWithValue:@[@1]],
                          @"b": [[IntObject alloc] initWithValue:@[@2]]}];
    XCTAssertEqual(dict.count, 2U);
    XCTAssertEqual(dict[@"a"].intCol, 1);
    XCTAssertEqual(dict[@"b"].intCol, 2);

    // New dictionary replaces the old one entirely
    [dict setDictionary:@{@"a": [[IntObject alloc] initWithValue:@[@3]],
                          @"c": [[IntObject alloc] initWithValue:@[@4]]}];
    XCTAssertEqual(dict.count, 2U);
    XCTAssertEqual(dict[@"a"].intCol, 3);
    XCTAssertEqual(dict[@"c"].intCol, 4);

    // Setting to nil clears
    XCTAssertNoThrow([dict setDictionary:self.nonLiteralNil]);
    XCTAssertEqual(dict.count, 0U);

    // Self-setting clears
    [dict setDictionary:@{@"a": [[IntObject alloc] initWithValue:@[@3]],
                          @"c": [[IntObject alloc] initWithValue:@[@4]]}];
    XCTAssertEqual(dict.count, 2U);
    [dict setDictionary:dict];
    XCTAssertEqual(dict.count, 0U);

    // Type error clears
    [dict setDictionary:@{@"a": [[IntObject alloc] initWithValue:@[@3]],
                          @"c": [[IntObject alloc] initWithValue:@[@4]]}];
    XCTAssertEqual(dict.count, 2U);
    RLMAssertThrowsWithReason([dict setDictionary:@{@"": [[StringObject alloc] init]}],
                              @"Value of type 'StringObject' does not match RLMDictionary value type 'IntObject'.");
    XCTAssertEqual(dict.count, 0U);

    [dict.realm cancelWriteTransaction];
}

- (void)testInitWithNullLink {
    id value = @{@"stringDictionary": @{@"1": NSNull.null},
                 @"intDictionary": @{@"2": NSNull.null},
                 @"primitiveStringDictionary": @{@"3": NSNull.null},
                 @"embeddedDictionary": @{@"4": NSNull.null},
                 @"intObjDictionary": @{@"5": NSNull.null}};

    DictionaryPropertyObject *obj = [[DictionaryPropertyObject alloc] initWithValue:value];
    XCTAssertEqual(obj.stringDictionary[@"1"], (id)NSNull.null);
    XCTAssertEqual(obj.intDictionary[@"2"], (id)NSNull.null);
    XCTAssertEqual(obj.primitiveStringDictionary[@"3"], (id)NSNull.null);
    XCTAssertEqual(obj.embeddedDictionary[@"4"], (id)NSNull.null);
    XCTAssertEqual(obj.intObjDictionary[@"5"], (id)NSNull.null);

    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    obj = [DictionaryPropertyObject createInRealm:realm withValue:value];
    XCTAssertEqual(obj.stringDictionary[@"1"], (id)NSNull.null);
    XCTAssertEqual(obj.intDictionary[@"2"], (id)NSNull.null);
    XCTAssertEqual(obj.primitiveStringDictionary[@"3"], (id)NSNull.null);
    XCTAssertEqual(obj.embeddedDictionary[@"4"], (id)NSNull.null);
    XCTAssertEqual(obj.intObjDictionary[@"5"], (id)NSNull.null);
    [realm cancelWriteTransaction];
}

@end
