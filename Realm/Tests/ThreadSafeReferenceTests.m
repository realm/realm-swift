////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#import "RLMRealmConfiguration_Private.h"
#import "RLMThreadSafeReference.h"

@interface ThreadSafeReferenceTests : RLMTestCase

@end

@implementation ThreadSafeReferenceTests

/// Resolve a thread-safe reference confirming that you can't resolve it a second time.
- (id)assertResolve:(RLMRealm *)realm reference:(RLMThreadSafeReference *)reference {
    XCTAssertFalse(reference.isInvalidated);
    id object = [realm resolveThreadSafeReference:reference];
    XCTAssertTrue(reference.isInvalidated);
    RLMAssertThrowsWithReasonMatching([realm resolveThreadSafeReference:reference],
                                      @"Can only resolve a thread safe reference once");
    return object;
}

- (void)testInvalidThreadSafeReferenceConstruction {
    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.cache = false;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:nil];

    StringObject *stringObject = [[StringObject alloc] init];
    ArrayPropertyObject *arrayParent = [[ArrayPropertyObject alloc] initWithValue:@[@"arrayObject", @[@[@"a"]], @[]]];
    RLMArray *arrayObject = arrayParent.array;

    RLMAssertThrowsWithReasonMatching([RLMThreadSafeReference referenceWithThreadConfined:stringObject],
                                      @"Cannot construct reference to unmanaged object");
    RLMAssertThrowsWithReasonMatching([RLMThreadSafeReference referenceWithThreadConfined:arrayObject],
                                      @"Cannot construct reference to unmanaged object");

    [realm beginWriteTransaction];
    [realm addObject:stringObject];
    [realm addObject:arrayParent];
    arrayObject = arrayParent.array;
    [realm deleteAllObjects];
    [realm commitWriteTransaction];

    RLMAssertThrowsWithReasonMatching([RLMThreadSafeReference referenceWithThreadConfined:stringObject],
                                      @"Cannot construct reference to invalidated object");
    RLMAssertThrowsWithReasonMatching([RLMThreadSafeReference referenceWithThreadConfined:arrayObject],
                                      @"Cannot construct reference to invalidated object");
}

- (void)testInvalidThreadSafeReferenceUsage {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    StringObject *stringObject = [StringObject createInDefaultRealmWithValue:@{@"stringCol": @"hello"}];
    RLMThreadSafeReference *ref1 = [RLMThreadSafeReference referenceWithThreadConfined:stringObject];
    [realm commitWriteTransaction];

    RLMThreadSafeReference *ref2 = [RLMThreadSafeReference referenceWithThreadConfined:stringObject];
    RLMThreadSafeReference *ref3 = [RLMThreadSafeReference referenceWithThreadConfined:stringObject];
    [self dispatchAsyncAndWait:^{
        RLMRealm *realm = [RLMRealm defaultRealm];
        XCTAssertNil([[self realmWithTestPath] resolveThreadSafeReference:ref1]);
        XCTAssertNoThrow([realm resolveThreadSafeReference:ref2]);
        RLMAssertThrowsWithReasonMatching([realm resolveThreadSafeReference:ref2],
                                          @"Can only resolve a thread safe reference once");
        // Assert that we can resolve a different reference to the same object.
        XCTAssertEqualObjects([self assertResolve:realm reference:ref3][@"stringCol"], @"hello");
    }];
}

- (void)testPassThreadSafeReferenceToDeletedObject {
    RLMRealm *realm = [RLMRealm defaultRealm];
    IntObject *intObject = [[IntObject alloc] init];
    [realm transactionWithBlock:^{
        [realm addObject:intObject];
    }];

    RLMThreadSafeReference *ref1 = [RLMThreadSafeReference referenceWithThreadConfined:intObject];
    RLMThreadSafeReference *ref2 = [RLMThreadSafeReference referenceWithThreadConfined:intObject];
    XCTAssertEqual(0, intObject.intCol);
    [realm transactionWithBlock:^{
        [realm deleteObject:intObject];
    }];
    [self dispatchAsyncAndWait:^{
        RLMRealm *realm = [RLMRealm defaultRealm];
        XCTAssertEqualObjects([self assertResolve:realm reference:ref1][@"intCol"], @0);
        [realm refresh];
        XCTAssertNil([self assertResolve:realm reference:ref2]);
    }];
}

- (void)testPassThreadSafeReferencesToMultipleObjects {
    RLMRealm *realm = [RLMRealm defaultRealm];
    StringObject *stringObject = [[StringObject alloc] init];
    IntObject *intObject = [[IntObject alloc] init];
    [realm transactionWithBlock:^{
        [realm addObject:stringObject];
        [realm addObject:intObject];
    }];

    RLMThreadSafeReference *stringObjectRef = [RLMThreadSafeReference referenceWithThreadConfined:stringObject];
    RLMThreadSafeReference *intObjectRef = [RLMThreadSafeReference referenceWithThreadConfined:intObject];
    XCTAssertEqualObjects(nil, stringObject.stringCol);
    XCTAssertEqual(0, intObject.intCol);
    [self dispatchAsyncAndWait:^{
        RLMRealm *realm = [RLMRealm defaultRealm];
        StringObject *stringObject = [self assertResolve:realm reference:stringObjectRef];
        IntObject *intObject = [self assertResolve:realm reference:intObjectRef];

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

- (void)testPassThreadSafeReferenceToArray {
    RLMRealm *realm = [RLMRealm defaultRealm];
    DogArrayObject *object = [[DogArrayObject alloc] init];
    [realm transactionWithBlock:^{
        [realm addObject:object];
        DogObject *friday = [DogObject createInDefaultRealmWithValue:@{@"dogName": @"Friday", @"age": @15}];
        [object.dogs addObject:friday];
    }];
    RLMThreadSafeReference *dogsArrayRef = [RLMThreadSafeReference referenceWithThreadConfined:object.dogs];
    XCTAssertEqual(1ul, object.dogs.count);
    XCTAssertEqualObjects(@"Friday", object.dogs[0].dogName);
    [self dispatchAsyncAndWait:^{
        RLMRealm *realm = [RLMRealm defaultRealm];
        RLMArray<DogObject *> *dogs = [self assertResolve:realm reference:dogsArrayRef];
        XCTAssertEqual(1ul, dogs.count);
        XCTAssertEqualObjects(@"Friday", dogs[0].dogName);

        [realm transactionWithBlock:^{
            [dogs removeAllObjects];
            DogObject *cookie = [DogObject createInDefaultRealmWithValue:@{@"dogName": @"Cookie", @"age": @8}];
            DogObject *breezy = [DogObject createInDefaultRealmWithValue:@{@"dogName": @"Breezy", @"age": @6}];
            [dogs addObjects:@[cookie, breezy]];
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

- (void)testPassThreadSafeReferenceToResults {
    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMResults<StringObject *> *allObjects = [StringObject allObjects];
    RLMResults<StringObject *> *results = [[StringObject objectsWhere:@"stringCol != 'C'"]
                                           sortedResultsUsingKeyPath:@"stringCol" ascending:NO];
    RLMThreadSafeReference *resultsRef = [RLMThreadSafeReference referenceWithThreadConfined:results];
    [realm transactionWithBlock:^{
        [StringObject createInDefaultRealmWithValue:@[@"A"]];
        [StringObject createInDefaultRealmWithValue:@[@"B"]];
        [StringObject createInDefaultRealmWithValue:@[@"C"]];
        [StringObject createInDefaultRealmWithValue:@[@"D"]];
    }];
    XCTAssertEqual(4ul, allObjects.count);
    XCTAssertEqual(3ul, results.count);
    XCTAssertEqualObjects(@"D", results[0].stringCol);
    XCTAssertEqualObjects(@"B", results[1].stringCol);
    XCTAssertEqualObjects(@"A", results[2].stringCol);
    [self dispatchAsyncAndWait:^{
        RLMRealm *realm = [RLMRealm defaultRealm];
        RLMResults<StringObject *> *results = [self assertResolve:realm reference:resultsRef];
        RLMResults<StringObject *> *allObjects = [StringObject allObjects];
        XCTAssertEqual(0ul, [StringObject allObjects].count);
        XCTAssertEqual(0ul, results.count);
        [realm refresh];
        XCTAssertEqual(4ul, allObjects.count);
        XCTAssertEqual(3ul, results.count);
        XCTAssertEqualObjects(@"D", results[0].stringCol);
        XCTAssertEqualObjects(@"B", results[1].stringCol);
        XCTAssertEqualObjects(@"A", results[2].stringCol);
        [realm transactionWithBlock:^{
            [realm deleteObject:results[2]];
            [realm deleteObject:results[0]];
            [StringObject createInDefaultRealmWithValue:@[@"E"]];
        }];
        XCTAssertEqual(3ul, allObjects.count);
        XCTAssertEqual(2ul, results.count);
        XCTAssertEqualObjects(@"E", results[0].stringCol);
        XCTAssertEqualObjects(@"B", results[1].stringCol);
    }];
    XCTAssertEqual(4ul, allObjects.count);
    XCTAssertEqual(3ul, results.count);
    XCTAssertEqualObjects(@"D", results[0].stringCol);
    XCTAssertEqualObjects(@"B", results[1].stringCol);
    XCTAssertEqualObjects(@"A", results[2].stringCol);
    [realm refresh];
    XCTAssertEqual(3ul, allObjects.count);
    XCTAssertEqual(2ul, results.count);
    XCTAssertEqualObjects(@"E", results[0].stringCol);
    XCTAssertEqualObjects(@"B", results[1].stringCol);
}

- (void)testPassThreadSafeReferenceToLinkingObjects {
    RLMRealm *realm = [RLMRealm defaultRealm];
    DogObject *dogA = [[DogObject alloc] initWithValue:@{@"dogName": @"Cookie", @"age": @10}];
    DogObject *unaccessedDogB = [[DogObject alloc] initWithValue:@{@"dogName": @"Skipper", @"age": @7}];
    // Ensures that an `RLMLinkingObjects` without cached results can be handed over

    [realm transactionWithBlock:^{
        [realm addObject:[[OwnerObject alloc] initWithValue:@{@"name": @"Andrea", @"dog": dogA}]];
        [realm addObject:[[OwnerObject alloc] initWithValue:@{@"name": @"Mike", @"dog": unaccessedDogB}]];
    }];
    XCTAssertEqual(1ul, dogA.owners.count);
    XCTAssertEqualObjects(@"Andrea", ((OwnerObject *)dogA.owners[0]).name);
    RLMThreadSafeReference *ownersARef = [RLMThreadSafeReference referenceWithThreadConfined:dogA.owners];
    RLMThreadSafeReference *ownersBRef = [RLMThreadSafeReference referenceWithThreadConfined:unaccessedDogB.owners];
    [self dispatchAsyncAndWait:^{
        RLMRealm *realm = [RLMRealm defaultRealm];
        RLMLinkingObjects<OwnerObject *> *ownersA = [self assertResolve:realm reference:ownersARef];
        RLMLinkingObjects<OwnerObject *> *ownersB = [self assertResolve:realm reference:ownersBRef];

        XCTAssertEqual(1ul, ownersA.count);
        XCTAssertEqualObjects(@"Andrea", ((OwnerObject *)ownersA[0]).name);
        XCTAssertEqual(1ul, ownersB.count);
        XCTAssertEqualObjects(@"Mike", ((OwnerObject *)ownersB[0]).name);

        [realm transactionWithBlock:^{
            // Swap dogs
            OwnerObject *ownerA = ownersA[0];
            OwnerObject *ownerB = ownersB[0];
            DogObject *dogA = ownerA.dog;
            DogObject *dogB = ownerB.dog;
            ownerA.dog = dogB;
            ownerB.dog = dogA;
        }];
        XCTAssertEqual(1ul, ownersA.count);
        XCTAssertEqualObjects(@"Mike", ((OwnerObject *)ownersA[0]).name);
        XCTAssertEqual(1ul, ownersB.count);
        XCTAssertEqualObjects(@"Andrea", ((OwnerObject *)ownersB[0]).name);
    }];
    XCTAssertEqual(1ul, dogA.owners.count);
    XCTAssertEqualObjects(@"Andrea", ((OwnerObject *)dogA.owners[0]).name);
    XCTAssertEqual(1ul, unaccessedDogB.owners.count);
    XCTAssertEqualObjects(@"Mike", ((OwnerObject *)unaccessedDogB.owners[0]).name);
    [realm refresh];
    XCTAssertEqual(1ul, dogA.owners.count);
    XCTAssertEqualObjects(@"Mike", ((OwnerObject *)dogA.owners[0]).name);
    XCTAssertEqual(1ul, unaccessedDogB.owners.count);
    XCTAssertEqualObjects(@"Andrea", ((OwnerObject *)unaccessedDogB.owners[0]).name);
}

@end
