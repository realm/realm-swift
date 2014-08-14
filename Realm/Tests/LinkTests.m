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
#import "RLMRealm_Dynamic.h"

@interface LinkTests : RLMTestCase
@end

@implementation LinkTests

- (void)makeDogWithName:(NSString *)name owner:(NSString *)ownerName {
    RLMRealm *realm = [self realmWithTestPath];

    OwnerObject *owner = [[OwnerObject alloc] init];
    owner.name = ownerName;
    owner.dog = [[DogObject alloc] init];
    owner.dog.dogName = name;
    owner.dog.age = 0;

    [realm beginWriteTransaction];
    [realm addObject:owner];
    [realm commitWriteTransaction];
}

- (void)testBasicLink
{
    [self makeDogWithName:@"Harvie" owner:@"Tim"];

    RLMRealm *realm = [self realmWithTestPath];
    RLMArray *owners = [OwnerObject objectsInRealm:realm withPredicate:nil];
    RLMArray *dogs = [DogObject objectsInRealm:realm withPredicate:nil];
    XCTAssertEqual(owners.count, 1U);
    XCTAssertEqual(dogs.count, 1U);
    XCTAssertEqualObjects([owners[0] name], @"Tim", @"Tim is named Tim");
    XCTAssertEqualObjects([dogs[0] dogName], @"Harvie", @"Harvie is named Harvie");

    OwnerObject *tim = owners[0];
    XCTAssertEqualObjects(tim.dog.dogName, @"Harvie", @"Tim's dog should be Harvie");
}

-(void)testBasicLinkWithNil
{
    RLMRealm *realm = [self realmWithTestPath];

    OwnerObject *owner = [[OwnerObject alloc] init];
    owner.name = @"Tim";
    owner.dog = nil;

    [realm beginWriteTransaction];
    [realm addObject:owner];
    [realm commitWriteTransaction];

    RLMArray *owners = [OwnerObject objectsInRealm:realm withPredicate:nil];
    RLMArray *dogs = [DogObject objectsInRealm:realm withPredicate:nil];
    XCTAssertEqual(owners.count, 1U);
    XCTAssertEqual(dogs.count, 0U);
    XCTAssertEqualObjects([owners[0] name], @"Tim", @"Tim is named Tim");

    OwnerObject *tim = owners[0];
    XCTAssertEqualObjects(tim.dog, nil, @"Tim does not have a dog");
}

- (void)testMultipleOwnerLink
{
    [self makeDogWithName:@"Harvie" owner:@"Tim"];

    RLMRealm *realm = [self realmWithTestPath];

    XCTAssertEqual([OwnerObject allObjectsInRealm:realm].count, 1U);
    XCTAssertEqual([DogObject allObjectsInRealm:realm].count, 1U);

    [realm beginWriteTransaction];
    OwnerObject *fiel = [OwnerObject createInRealm:realm withObject:@[@"Fiel", [NSNull null]]];
    fiel.dog = [DogObject allObjectsInRealm:realm].firstObject;
    [realm commitWriteTransaction];

    XCTAssertEqual([OwnerObject objectsInRealm:realm withPredicate:nil].count, 2U);
    XCTAssertEqual([DogObject objectsInRealm:realm withPredicate:nil].count, 1U);
}

- (void)testLinkRemoval
{
    [self makeDogWithName:@"Harvie" owner:@"Tim"];

    RLMRealm *realm = [self realmWithTestPath];
    XCTAssertEqual([OwnerObject objectsInRealm:realm withPredicate:nil].count, 1U);
    XCTAssertEqual([DogObject objectsInRealm:realm withPredicate:nil].count, 1U);

    DogObject *dog = [DogObject allObjectsInRealm:realm].firstObject;
    OwnerObject *owner = [OwnerObject allObjectsInRealm:realm].firstObject;

    [realm beginWriteTransaction];
    [realm deleteObject:dog];
    [realm commitWriteTransaction];

    XCTAssertNil(owner.dog, @"Dog should be nullified when deleted");
    XCTAssertThrows(dog.dogName, @"Dog object should be invalid after being deleted from the realm");

    // refresh owner and check
    owner = [realm allObjects:[OwnerObject className]].firstObject;
    XCTAssertNotNil(owner, @"Should have 1 owner");
    XCTAssertNil(owner.dog, @"Dog should be nullified when deleted");
    XCTAssertEqual([DogObject objectsInRealm:realm withPredicate:nil].count, 0U);
}

- (void)testInvalidLinks
{
    RLMRealm *realm = [self realmWithTestPath];

    OwnerObject *owner = [[OwnerObject alloc] init];
    owner.name = @"Tim";
    owner.dog = [[DogObject alloc] init];

    [realm beginWriteTransaction];
    XCTAssertThrows([realm addObject:owner], @"dogName not set on linked object");

    StringObject *to = [StringObject createInRealm:realm withObject:@[@"testObject"]];
    NSArray *args = @[@"Tim", to];
    XCTAssertThrows([OwnerObject createInRealm:realm withObject:args], @"Inserting wrong object type should throw");
    [realm commitWriteTransaction];
}

- (void)testLinkTooManyRelationships
{
    RLMRealm *realm = [self realmWithTestPath];

    OwnerObject *owner = [[OwnerObject alloc] init];
    owner.name = @"Tim";
    owner.dog = [[DogObject alloc] init];
    owner.dog.dogName = @"Harvie";

    [realm beginWriteTransaction];
    [realm addObject:owner];
    [realm commitWriteTransaction];

    XCTAssertThrows([OwnerObject objectsInRealm:realm where:@"dog.dogName.first = 'Fifo'"], @"3 levels of relationship");

}

// FIXME - disabled until we fix commit log issue which break transacions when leaking realm objects
/*
- (void)testCircularLinks
 {
    RLMRealm *realm = [self realmWithTestPath];

    CircleObject *obj = [[CircleObject alloc] init];
    obj.data = @"a";
    obj.next = obj;

    [realm beginWriteTransaction];
    [realm addObject:obj];
    obj.next.data = @"b";
    [realm commitWriteTransaction];

    CircleObject *obj1 = [realm allObjects:CircleObject.className].firstObject;
    XCTAssertEqualObjects(obj1.data, @"b", @"data should be 'b'");
    XCTAssertEqualObjects(obj1.data, obj.next.data, @"objects should be equal");
}*/

@end

