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

- (void)testBasicLink
{
    RLMRealm *realm = [self realmWithTestPath];
    
    OwnerObject *owner = [[OwnerObject alloc] init];
    owner.name = @"Tim";
    owner.dog = [[DogObject alloc] init];
    owner.dog.dogName = @"Harvie";
    
    [realm beginWriteTransaction];
    [realm addObject:owner];
    [realm commitWriteTransaction];
    
    RLMArray *owners = [realm objects:[OwnerObject className] withPredicate:nil];
    RLMArray *dogs = [realm objects:[DogObject className] withPredicate:nil];
    XCTAssertEqual(owners.count, (NSUInteger)1, @"Expecting 1 owner");
    XCTAssertEqual(dogs.count, (NSUInteger)1, @"Expecting 1 dog");
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

    RLMArray *owners = [realm objects:[OwnerObject className] withPredicate:nil];
    RLMArray *dogs = [realm objects:[DogObject className] withPredicate:nil];
    XCTAssertEqual(owners.count, (NSUInteger)1, @"Expecting 1 owner");
    XCTAssertEqual(dogs.count, (NSUInteger)0, @"Expecting 0 dogs");
    XCTAssertEqualObjects([owners[0] name], @"Tim", @"Tim is named Tim");

    OwnerObject *tim = owners[0];
    XCTAssertEqualObjects(tim.dog, nil, @"Tim does not have a dog");
}

- (void)testMultipleOwnerLink
{
    RLMRealm *realm = [self realmWithTestPath];
    
    OwnerObject *owner = [[OwnerObject alloc] init];
    owner.name = @"Tim";
    owner.dog = [[DogObject alloc] init];
    owner.dog.dogName = @"Harvie";
    
    [realm beginWriteTransaction];
    [realm addObject:owner];
    [realm commitWriteTransaction];
    
    XCTAssertEqual([realm objects:[OwnerObject className] withPredicate:nil].count, (NSUInteger)1, @"Expecting 1 owner");
    XCTAssertEqual([realm objects:[DogObject className] withPredicate:nil].count, (NSUInteger)1, @"Expecting 1 dog");
    
    [realm beginWriteTransaction];
    OwnerObject *fiel = [OwnerObject createInRealm:realm withObject:@[@"Fiel", [NSNull null]]];
    fiel.dog = owner.dog;
    [realm commitWriteTransaction];
    
    XCTAssertEqual([realm objects:[OwnerObject className] withPredicate:nil].count, (NSUInteger)2, @"Expecting 2 owners");
    XCTAssertEqual([realm objects:[DogObject className] withPredicate:nil].count, (NSUInteger)1, @"Expecting 1 dog");
}

- (void)testLinkRemoval
{
    RLMRealm *realm = [self realmWithTestPath];
    
    OwnerObject *owner = [[OwnerObject alloc] init];
    owner.name = @"Tim";
    owner.dog = [[DogObject alloc] init];
    owner.dog.dogName = @"Harvie";
    
    [realm beginWriteTransaction];
    [realm addObject:owner];
    [realm commitWriteTransaction];
    
    XCTAssertEqual([realm objects:[OwnerObject className] withPredicate:nil].count, (NSUInteger)1, @"Expecting 1 owner");
    XCTAssertEqual([realm objects:[DogObject className] withPredicate:nil].count, (NSUInteger)1, @"Expecting 1 dog");
    
    [realm beginWriteTransaction];
    DogObject *dog = owner.dog;
    [realm deleteObject:dog];
    [realm commitWriteTransaction];
    
    XCTAssertNil(owner.dog, @"Dog should be nullified when deleted");
    XCTAssertThrows(dog.dogName, @"Dog object should be invalid after being deleted from the realm");

    // refresh owner and check
    owner = [realm allObjects:[OwnerObject className]].firstObject;
    XCTAssertNotNil(owner, @"Should have 1 owner");
    XCTAssertNil(owner.dog, @"Dog should be nullified when deleted");
    XCTAssertEqual([realm objects:[DogObject className] withPredicate:nil].count, (NSUInteger)0, @"Expecting 0 dogs");
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

- (void)testLinkQueryString
{
    RLMRealm *realm = [self realmWithTestPath];

    OwnerObject *owner1 = [[OwnerObject alloc] init];
    owner1.name = @"Tim";
    owner1.dog = [[DogObject alloc] init];
    owner1.dog.dogName = @"Harvie";

    [realm beginWriteTransaction];
    [realm addObject:owner1];
    [realm commitWriteTransaction];

    NSPredicate *p1 = [NSPredicate predicateWithFormat:@"dog.dogName = 'Harvie'"];
    NSUInteger count1 = [[realm objects:@"OwnerObject" withPredicate:p1] count];
    XCTAssertEqual(count1, (NSUInteger)1, @"Expecting 1 dog");

    NSPredicate *p2 = [NSPredicate predicateWithFormat:@"dog.dogName = 'eivraH'"];
    NSUInteger count2 = [[realm objects:@"OwnerObject" withPredicate:p2] count];
    XCTAssertEqual(count2, (NSUInteger)0, @"Expecting 0 dogs");

    OwnerObject *owner2 = [[OwnerObject alloc] init];
    owner2.name = @"Joe";
    owner2.dog = [[DogObject alloc] init];
    owner2.dog.dogName = @"Harvie";

    [realm beginWriteTransaction];
    [realm addObject:owner2];
    [realm commitWriteTransaction];

    NSPredicate *p3 = [NSPredicate predicateWithFormat:@"dog.dogName = 'Harvie'"];
    NSUInteger count3 = [[realm objects:@"OwnerObject" withPredicate:p3] count];
    XCTAssertEqual(count3, (NSUInteger)2, @"Expecting 2 dogs");

    NSPredicate *p4 = [NSPredicate predicateWithFormat:@"dog.dogName = 'eivraH'"];
    NSUInteger count4 = [[realm objects:@"OwnerObject" withPredicate:p4] count];
    XCTAssertEqual(count4, (NSUInteger)0, @"Expecting 0 dogs");

    OwnerObject *owner3 = [[OwnerObject alloc] init];
    owner3.name = @"Jim";
    owner3.dog = [[DogObject alloc] init];
    owner3.dog.dogName = @"Fido";

    [realm beginWriteTransaction];
    [realm addObject:owner3];
    [realm commitWriteTransaction];

    NSPredicate *p5 = [NSPredicate predicateWithFormat:@"dog.dogName = 'Harvie'"];
    NSUInteger count5 = [[realm objects:@"OwnerObject" withPredicate:p5] count];
    XCTAssertEqual(count5, (NSUInteger)2, @"Expecting 2 dogs");

    NSPredicate *p6 = [NSPredicate predicateWithFormat:@"dog.dogName = 'eivraH'"];
    NSUInteger count6 = [[realm objects:@"OwnerObject" withPredicate:p6] count];
    XCTAssertEqual(count6, (NSUInteger)0, @"Expecting 0 dogs");

    NSPredicate *p7 = [NSPredicate predicateWithFormat:@"dog.dogName = 'Fido'"];
    NSUInteger count7 = [[realm objects:@"OwnerObject" withPredicate:p7] count];
    XCTAssertEqual(count7, (NSUInteger)1, @"Expecting 1 dogs");
}

- (void)testLinkQueryAllTypes
{
    RLMRealm *realm = [self realmWithTestPath];

    NSDate *now = [NSDate dateWithTimeIntervalSince1970:100000];

    LinkToAllTypesObject *linkToAllTypes = [[LinkToAllTypesObject alloc] init];
    linkToAllTypes.allTypesCol = [[AllTypesObject alloc] init];
    linkToAllTypes.allTypesCol.boolCol = YES;
    linkToAllTypes.allTypesCol.intCol = 1;
    linkToAllTypes.allTypesCol.floatCol = 1.1f;
    linkToAllTypes.allTypesCol.doubleCol = 1.11;
    linkToAllTypes.allTypesCol.stringCol = @"string";
    linkToAllTypes.allTypesCol.binaryCol = [NSData dataWithBytes:"a" length:1];
    linkToAllTypes.allTypesCol.dateCol = now;
    linkToAllTypes.allTypesCol.cBoolCol = YES;
    linkToAllTypes.allTypesCol.longCol = 11;
    linkToAllTypes.allTypesCol.mixedCol = @0;
    linkToAllTypes.allTypesCol.objectCol = [[StringObject alloc] init];
    linkToAllTypes.allTypesCol.objectCol.stringCol = @"string";

    [realm beginWriteTransaction];
    [realm addObject:linkToAllTypes];
    [realm commitWriteTransaction];

    XCTAssertEqual([[realm objects:@"LinkToAllTypesObject" where:@"allTypesCol.boolCol = YES"] count], (NSUInteger)1, @"1 expected");
    XCTAssertEqual([[realm objects:@"LinkToAllTypesObject" where:@"allTypesCol.boolCol = NO"] count], (NSUInteger)0, @"0 expected");

    XCTAssertEqual([[realm objects:@"LinkToAllTypesObject" where:@"allTypesCol.intCol = 1"] count], (NSUInteger)1, @"1 expected");
    XCTAssertEqual([[realm objects:@"LinkToAllTypesObject" where:@"allTypesCol.intCol != 1"] count], (NSUInteger)0, @"0 expected");

    XCTAssertEqual([[realm objects:@"LinkToAllTypesObject" where:@"allTypesCol.floatCol = 1.1"] count], (NSUInteger)1, @"1 expected");
    XCTAssertEqual([[realm objects:@"LinkToAllTypesObject" where:@"allTypesCol.floatCol < 1.1"] count], (NSUInteger)0, @"0 expected");

    XCTAssertEqual([[realm objects:@"LinkToAllTypesObject" where:@"allTypesCol.doubleCol = 1.11"] count], (NSUInteger)1, @"1 expected");
    XCTAssertEqual([[realm objects:@"LinkToAllTypesObject" where:@"allTypesCol.doubleCol > 1.11"] count], (NSUInteger)0, @"0 expected");

    XCTAssertEqual([[realm objects:@"LinkToAllTypesObject" where:@"allTypesCol.longCol = 11"] count], (NSUInteger)1, @"1 expected");
    XCTAssertEqual([[realm objects:@"LinkToAllTypesObject" where:@"allTypesCol.longCol != 11"] count], (NSUInteger)0, @"0 expected");

    NSPredicate *p1 = [NSPredicate predicateWithFormat:@"allTypesCol.dateCol = %@", now];
    XCTAssertEqual([[realm objects:@"LinkToAllTypesObject" withPredicate:p1] count], (NSUInteger)1, @"1 expected");
    NSPredicate *p2 = [NSPredicate predicateWithFormat:@"allTypesCol.dateCol != %@", now];
    XCTAssertEqual([[realm objects:@"LinkToAllTypesObject" withPredicate:p2] count], (NSUInteger)0, @"0 expected");

    XCTAssertThrows([realm objects:@"LinkToAllTypesObject" where:@"allTypesCol.binaryCol = 'a'"], @"Binary data not supported");
}

- (void)testLinkQueryMany
{
    RLMRealm *realm = [self realmWithTestPath];

    ArrayPropertyObject *arrPropObj1 = [[ArrayPropertyObject alloc] init];
    arrPropObj1.name = @"Test";
    for(NSUInteger i=0; i<10; i++) {
        StringObject *sobj = [[StringObject alloc] init];
        sobj.stringCol = [NSString stringWithFormat:@"%lu", i];
        [arrPropObj1.array addObject:sobj];
        IntObject *iobj = [[IntObject alloc] init];
        iobj.intCol = (int)i;
        [arrPropObj1.intArray addObject:iobj];
    }
    [realm beginWriteTransaction];
    [realm addObject:arrPropObj1];
    [realm commitWriteTransaction];

    XCTAssertEqual([[realm objects:[ArrayPropertyObject className] where:@"intArray.intCol > 10"] count], (NSUInteger)0, @"0 expected");
    XCTAssertEqual([[realm objects:[ArrayPropertyObject className] where:@"intArray.intCol > 5"] count], (NSUInteger)1, @"1 expected");
    XCTAssertEqual([[realm objects:[ArrayPropertyObject className] where:@"array.stringCol = '1'"] count], (NSUInteger)1, @"1 expected");

    ArrayPropertyObject *arrPropObj2 = [[ArrayPropertyObject alloc] init];
    arrPropObj2.name = @"Test";
    for(NSUInteger i=0; i<4; i++) {
        StringObject *sobj = [[StringObject alloc] init];
        sobj.stringCol = [NSString stringWithFormat:@"%lu", i];
        [arrPropObj2.array addObject:sobj];
        IntObject *iobj = [[IntObject alloc] init];
        iobj.intCol = (int)i;
        [arrPropObj2.intArray addObject:iobj];
    }
    [realm beginWriteTransaction];
    [realm addObject:arrPropObj2];
    [realm commitWriteTransaction];
    XCTAssertEqual([[realm objects:[ArrayPropertyObject className] where:@"intArray.intCol > 10"] count], (NSUInteger)0, @"0 expected");
    XCTAssertEqual([[realm objects:[ArrayPropertyObject className] where:@"intArray.intCol > 5"] count], (NSUInteger)1, @"1 expected");
    XCTAssertEqual([[realm objects:[ArrayPropertyObject className] where:@"intArray.intCol > 2"] count], (NSUInteger)2, @"2 expected");
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

