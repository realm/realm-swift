//
//  ThreadSafeReferenceTests.m
//  Realm
//
//  Created by Realm on 9/9/16.
//  Copyright © 2016 Realm. All rights reserved.
//

#import "RLMTestCase.h"

#import "RLMRealmConfiguration_Private.h"
#import "RLMThreadSafeReference.h"

@interface ThreadSafeReferenceTests : RLMTestCase

@end

@implementation ThreadSafeReferenceTests

- (void)testInvalidThreadSafeReferenceConstruction {
    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.cache = false;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:nil];

    StringObject *stringObject = [[StringObject alloc] init];
    IntObject *intObject = [[IntObject alloc] init];

    RLMAssertThrowsWithReasonMatching([RLMThreadSafeReference referenceWithThreadConfined:stringObject],
                                      @"Cannot construct reference to unmanaged object");
    RLMAssertThrowsWithReasonMatching([RLMThreadSafeReference referenceWithThreadConfined:intObject],
                                      @"Cannot construct reference to unmanaged object");

    [realm transactionWithBlock:^{
        [realm addObject:stringObject];
        [realm addObject:intObject];
    }];
    [realm transactionWithBlock:^{
        [realm deleteAllObjects];
    }];

    RLMAssertThrowsWithReasonMatching([RLMThreadSafeReference referenceWithThreadConfined:stringObject],
                                      @"Cannot construct reference to invalidated object");
    RLMAssertThrowsWithReasonMatching([RLMThreadSafeReference referenceWithThreadConfined:intObject],
                                      @"Cannot construct reference to invalidated object");

}

- (void)testHandoverObjects {
    RLMRealm *realm = [RLMRealm defaultRealm];
    StringObject *stringObject = [[StringObject alloc] init];
    IntObject *intObject = [[IntObject alloc] init];
    [realm transactionWithBlock:^{
        [realm addObject:stringObject];
        [realm addObject:intObject];
    }];
    XCTAssertEqualObjects(nil, stringObject.stringCol);
    XCTAssertEqual(0, intObject.intCol);

    RLMThreadSafeReference *stringObjectRef = [RLMThreadSafeReference referenceWithThreadConfined:stringObject];
    RLMThreadSafeReference *intObjectRef = [RLMThreadSafeReference referenceWithThreadConfined:intObject];
    [self dispatchAsyncAndWait:^{
        RLMRealm *realm = [RLMRealm defaultRealm];
        StringObject *stringObject = [realm resolveThreadSafeReference:stringObjectRef];
        IntObject *intObject = [realm resolveThreadSafeReference:intObjectRef];

        [realm transactionWithBlock:^{
            stringObject.stringCol = @"the meaning of life";
            intObject.intCol = 42;
        }];
    }];
    XCTAssertEqualObjects(nil, stringObject.stringCol);
    XCTAssertEqual(0, intObject.intCol);
    [realm refresh];
    XCTAssertEqualObjects(@"the meaning of life", stringObject.stringCol);
    XCTAssertEqual(42, intObject.intCol);
}

- (void)testHandoverArray {
    RLMRealm *realm = [RLMRealm defaultRealm];
    DogArrayObject *object = [[DogArrayObject alloc] init];
    [realm transactionWithBlock:^{
        [realm addObject:object];
        DogObject *friday = [DogObject createInDefaultRealmWithValue:@{@"dogName": @"Friday", @"age": @15}];
        [object.dogs addObject:friday];
    }];
    XCTAssertEqual(1ul, object.dogs.count);
    XCTAssertEqualObjects(@"Friday", object.dogs[0].dogName);
    RLMThreadSafeReference *dogsArrayRef = [RLMThreadSafeReference referenceWithThreadConfined:object.dogs];
    [self dispatchAsyncAndWait:^{
        RLMRealm *realm = [RLMRealm defaultRealm];
        RLMArray<DogObject *> *dogs = [realm resolveThreadSafeReference:dogsArrayRef];
        XCTAssertEqual(1ul, dogs.count);
        XCTAssertEqualObjects(@"Friday", dogs[0].dogName);

        [realm transactionWithBlock:^{
            [dogs removeAllObjects];
            DogObject *cookie = [DogObject createInDefaultRealmWithValue:@{@"dogName": @"Cookie", @"age": @8}];
            DogObject *breezy = [DogObject createInDefaultRealmWithValue:@{@"dogName": @"Breezy", @"age": @6}];
            [dogs addObjects: @[cookie, breezy]];
        }];
        XCTAssertEqual(2ul, dogs.count);
        XCTAssertEqualObjects(@"Cookie", dogs[0].dogName);
        XCTAssertEqualObjects(@"Breezy", dogs[1].dogName);
    }];
    XCTAssertEqual(1ul, object.dogs.count);
    XCTAssertEqualObjects(@"Friday", object.dogs[0].dogName);
    [realm refresh];
    XCTAssertEqual(2ul, object.dogs.count);
    XCTAssertEqualObjects(@"Cookie", object.dogs[0].dogName);
    XCTAssertEqualObjects(@"Breezy", object.dogs[1].dogName);
}

- (void)testHandoverResults {
    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMResults<StringObject *> *results = [[StringObject objectsWhere:@"stringCol != 'C'"]
                                           sortedResultsUsingProperty:@"stringCol" ascending:NO];
    [realm transactionWithBlock:^{
        [StringObject createInDefaultRealmWithValue:@[@"A"]];
        [StringObject createInDefaultRealmWithValue:@[@"B"]];
        [StringObject createInDefaultRealmWithValue:@[@"C"]];
        [StringObject createInDefaultRealmWithValue:@[@"D"]];
    }];
    XCTAssertEqual(4ul, [StringObject allObjects].count);
    XCTAssertEqual(3ul, results.count);
    XCTAssertEqualObjects(@"D", results[0].stringCol);
    XCTAssertEqualObjects(@"B", results[1].stringCol);
    XCTAssertEqualObjects(@"A", results[2].stringCol);
    RLMThreadSafeReference *resultsRef = [RLMThreadSafeReference referenceWithThreadConfined:results];
    [self dispatchAsyncAndWait:^{
        RLMRealm *realm = [RLMRealm defaultRealm];
        RLMResults<StringObject *> *results = [realm resolveThreadSafeReference:resultsRef];
        XCTAssertEqual(4ul, [StringObject allObjects].count);
        XCTAssertEqual(3ul, results.count);
        XCTAssertEqualObjects(@"D", results[0].stringCol);
        XCTAssertEqualObjects(@"B", results[1].stringCol);
        XCTAssertEqualObjects(@"A", results[2].stringCol);
        [realm transactionWithBlock:^{
            [realm deleteObject:results[2]];
            [realm deleteObject:results[0]];
            [StringObject createInDefaultRealmWithValue:@[@"E"]];
        }];
        XCTAssertEqual(3ul, [StringObject allObjects].count);
        XCTAssertEqual(2ul, results.count);
        XCTAssertEqualObjects(@"E", results[0].stringCol);
        XCTAssertEqualObjects(@"B", results[1].stringCol);
    }];
    XCTAssertEqual(3ul, results.count);
    XCTAssertEqualObjects(@"D", results[0].stringCol);
    XCTAssertEqualObjects(@"B", results[1].stringCol);
    XCTAssertEqualObjects(@"A", results[2].stringCol);
    [realm refresh];
    XCTAssertEqual(3ul, [StringObject allObjects].count);
    XCTAssertEqual(2ul, results.count);
    XCTAssertEqualObjects(@"E", results[0].stringCol);
    XCTAssertEqualObjects(@"B", results[1].stringCol);
}

- (void)testHandoverLinkingObjects {
    RLMRealm *realm = [RLMRealm defaultRealm];
    DogObject *dog = [[DogObject alloc] initWithValue:@{@"dogName": @"Cookie", @"age": @10,}];
    [realm transactionWithBlock:^{
        [realm addObject:[[OwnerObject alloc] initWithValue:@{@"name": @"Jaden", @"dog": dog}]];
    }];
    XCTAssertEqual(1ul, dog.owners.count);
    XCTAssertEqualObjects(@"Jaden", ((OwnerObject *)dog.owners[0]).name);
    RLMThreadSafeReference *dogOwnersRef = [RLMThreadSafeReference referenceWithThreadConfined:dog.owners];
    [self dispatchAsyncAndWait:^{
        RLMRealm *realm = [RLMRealm defaultRealm];
        RLMLinkingObjects<OwnerObject *> *owners = [realm resolveThreadSafeReference:dogOwnersRef];
        XCTAssertEqual(1ul, owners.count);
        XCTAssertEqualObjects(@"Jaden", ((OwnerObject *)owners[0]).name);

        [realm transactionWithBlock:^{
            OwnerObject *oldOwner = (OwnerObject *)owners[0];
            [realm addObject: [[OwnerObject alloc] initWithValue:@{@"name": @"Andrea", @"dog": oldOwner.dog}]];
            [realm deleteObject:oldOwner];
        }];
        XCTAssertEqual(1ul, owners.count);
        XCTAssertEqualObjects(@"Andrea", ((OwnerObject *)owners[0]).name);
    }];
    XCTAssertEqual(1ul, dog.owners.count);
    XCTAssertEqualObjects(@"Jaden", ((OwnerObject *)dog.owners[0]).name);
    [realm refresh];
    XCTAssertEqual(1ul, dog.owners.count);
    XCTAssertEqualObjects(@"Andrea", ((OwnerObject *)dog.owners[0]).name);
}

@end
