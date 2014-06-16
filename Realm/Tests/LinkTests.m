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
#import "RLMTestObjects.h"
#import "XCTestCase+AsyncTesting.h"

@interface DogObject : RLMObject
@property NSString *dogName;
@end

@implementation DogObject
@end

@interface OwnerObject : RLMObject
@property NSString *name;
@property DogObject *dog;
@end

@implementation OwnerObject
@end

@interface CircleObject : RLMObject
@property NSString *data;
@property CircleObject *next;
@end

@implementation CircleObject
@end


@interface LinkTests : RLMTestCase
@end

@implementation LinkTests

- (void)testBasicLink {
    RLMRealm *realm = [self realmWithTestPath];
    
    OwnerObject *owner = [[OwnerObject alloc] init];
    owner.name = @"Tim";
    owner.dog = [[DogObject alloc] init];
    owner.dog.dogName = @"Harvie";
    
    [realm beginWriteTransaction];
    [realm addObject:owner];
    [realm commitWriteTransaction];
    
    RLMArray *owners = [realm objects:OwnerObject.className where:nil];
    RLMArray *dogs = [realm objects:DogObject.className where:nil];
    XCTAssertEqual(owners.count, (NSUInteger)1, @"Expecting 1 owner");
    XCTAssertEqual(dogs.count, (NSUInteger)1, @"Expecting 1 dog");
    XCTAssertEqualObjects([owners[0] name], @"Tim", @"Tim is named Tim");
    XCTAssertEqualObjects([dogs[0] dogName], @"Harvie", @"Harvie is named Harvie");
    
    OwnerObject *tim = owners[0];
    XCTAssertEqualObjects(tim.dog.dogName, @"Harvie", @"Tim's dog should be Harvie");
}

- (void)testMultipleOwnerLink {
    RLMRealm *realm = [self realmWithTestPath];
    
    OwnerObject *owner = [[OwnerObject alloc] init];
    owner.name = @"Tim";
    owner.dog = [[DogObject alloc] init];
    owner.dog.dogName = @"Harvie";
    
    [realm beginWriteTransaction];
    [realm addObject:owner];
    [realm commitWriteTransaction];
    
    XCTAssertEqual([realm objects:[OwnerObject className] where:nil].count, (NSUInteger)1, @"Expecting 1 owner");
    XCTAssertEqual([realm objects:[DogObject className] where:nil].count, (NSUInteger)1, @"Expecting 1 dog");
    
    [realm beginWriteTransaction];
    OwnerObject *fiel = [OwnerObject createInRealm:realm withObject:@[@"Fiel", [NSNull null]]];
    fiel.dog = owner.dog;
    [realm commitWriteTransaction];
    
    XCTAssertEqual([realm objects:[OwnerObject className] where:nil].count, (NSUInteger)2, @"Expecting 2 owners");
    XCTAssertEqual([realm objects:[DogObject className] where:nil].count, (NSUInteger)1, @"Expecting 1 dog");
}

- (void)testLinkRemoval {
    RLMRealm *realm = [self realmWithTestPath];
    
    OwnerObject *owner = [[OwnerObject alloc] init];
    owner.name = @"Tim";
    owner.dog = [[DogObject alloc] init];
    owner.dog.dogName = @"Harvie";
    
    [realm beginWriteTransaction];
    [realm addObject:owner];
    [realm commitWriteTransaction];
    
    XCTAssertEqual([realm objects:[OwnerObject className] where:nil].count, (NSUInteger)1, @"Expecting 1 owner");
    XCTAssertEqual([realm objects:[DogObject className] where:nil].count, (NSUInteger)1, @"Expecting 1 dog");
    
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
    XCTAssertEqual([realm objects:[DogObject className] where:nil].count, (NSUInteger)0, @"Expecting 0 dogs");
}

- (void)testInvalidLinks {
    RLMRealm *realm = [self realmWithTestPath];
    
    OwnerObject *owner = [[OwnerObject alloc] init];
    owner.name = @"Tim";
    owner.dog = [[DogObject alloc] init];
    
    [realm beginWriteTransaction];
    XCTAssertThrows([realm addObject:owner], @"dogName not set on linked object");
    
    RLMTestObject *to = [RLMTestObject createInRealm:realm withObject:@[@"testObject"]];
    NSArray *args = @[@"Tim", to];
    XCTAssertThrows([OwnerObject createInRealm:realm withObject:args], @"Inserting wrong object type should throw");
    [realm commitWriteTransaction];
}

- (void)testCircularLinks {
    RLMRealm *realm = [self realmWithTestPath];
    
    CircleObject *obj = [[CircleObject alloc] init];
    obj.data = @"a";
    obj.next = obj;
    
    [realm beginWriteTransaction];
    [realm addObject:obj];
    obj.next.data = @"b";
    [realm commitWriteTransaction];
    
    obj = [realm allObjects:CircleObject.className].firstObject;
    XCTAssertEqualObjects(obj.data, @"b", @"data should be 'b'");
    XCTAssertEqualObjects(obj.data, obj.next.data, @"objects should be equal");
}

@end

