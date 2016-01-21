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
#import <XCTest/XCTest.h>

@interface TransactionTests : RLMTestCase
@end



RLM_ARRAY_TYPE(Breeder)

@interface Breeder : RLMObject
@end

@implementation Breeder
@end

@interface Dog : RLMObject

@property RLMArray<Breeder> *breeders;

@end

@implementation Dog
@end

@interface Person : RLMObject

@property Dog *dog;

@end

@implementation Person
@end



@implementation TransactionTests

- (void)testRealmModifyObjectsOutsideOfWriteTransaction
{
    RLMRealm *realm = [self realmWithTestPath];
    [realm beginWriteTransaction];
    StringObject *obj = [StringObject createInRealm:realm withValue:@[@"a"]];
    [realm commitWriteTransaction];
    
    XCTAssertThrows([obj setStringCol:@"throw"], @"Setter should throw when called outside of transaction.");
}

- (void)testTransactionMisuse
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    // Insert an object
    [realm beginWriteTransaction];
    StringObject *obj = [StringObject createInRealm:realm withValue:@[@"a"]];
    [realm commitWriteTransaction];
    
    XCTAssertThrows([StringObject createInRealm:realm withValue:@[@"a"]], @"Outside write transaction");
    XCTAssertThrows([realm commitWriteTransaction], @"No write transaction to close");
    
    [realm beginWriteTransaction];
    XCTAssertThrows([realm beginWriteTransaction], @"Write transaction already in place");
    [realm commitWriteTransaction];
    
    XCTAssertThrows([realm deleteObject:obj], @"Outside writetransaction");
}

- (void)testDeleteBug
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm transactionWithBlock:^{
        [realm deleteAllObjects];
    }];
    
    Breeder *breeder = [[Breeder alloc] init];
    [realm transactionWithBlock:^{
        [realm addObject:breeder];
    }];
    
    RLMResults *results = [Dog objectsInRealm:realm where:@"ANY breeders = %@", breeder];
    
    [realm transactionWithBlock:^{
        Person *person = [[Person alloc] init];
        
        Dog *dog = [[Dog alloc] init];
        person.dog = dog;
        
        [realm addObject:person];
    }];
    
    [realm transactionWithBlock:^{
        Breeder *breeder = [Breeder allObjectsInRealm:realm].firstObject;
        if (breeder) {
            [realm deleteObject:breeder];
        }
    }];
    XCTAssertNoThrow(results.count, @"Delete test Failed.");
}

- (void)testMovedItems
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm transactionWithBlock:^{
        [realm deleteAllObjects];
    }];
    
    Breeder *breeder = [[Breeder alloc] init];
    [realm transactionWithBlock:^{
        [realm addObject:breeder];
    }];
    
    Breeder *second_breeder = [[Breeder alloc] init];
    [realm transactionWithBlock:^{
        [realm addObject:second_breeder];
    }];
    
    RLMResults *results = [Dog objectsInRealm:realm where:@"ANY breeders = %@", breeder];

    [realm transactionWithBlock:^{
        Dog *dog = [[Dog alloc] init];
        [dog.breeders addObject:breeder];
        [realm addObject:dog];
        
        Dog *second_dog = [[Dog alloc] init];
        [second_dog.breeders addObject:second_breeder];
        [realm addObject:second_dog];
        
        [realm deleteObject:breeder];
        
    }];
    
    XCTAssertNoThrow(results.count, @"Moved Items test Failed.");
    XCTAssertEqual(results.count,(unsigned long)0);
}

- (void)testLinkQueryWhenLinkIsDeleted
{
    RLMRealm *realm = [self realmWithTestPath];
    
    [realm beginWriteTransaction];
    AllTypesObject *linkedObject = [AllTypesObject createInRealm:realm withValue:@[@YES, @1, @1.0f, @1.0, @"d", [@"d" dataUsingEncoding:NSUTF8StringEncoding], NSDate.date, @YES, @((long)1), @1, @[@"a"]]];
    LinkToAllTypesObject *linkObject = [LinkToAllTypesObject createInRealm:realm withValue:@[linkedObject]];
    [LinkToAllTypesObject createInRealm:realm withValue:@[[AllTypesObject createInRealm:realm withValue:@[@YES, @1, @1.0f, @1.0, @"d", [@"d" dataUsingEncoding:NSUTF8StringEncoding], NSDate.date, @YES, @((long)1), @1, @[@"a"]]]]];
    [realm commitWriteTransaction];
    
    XCTAssertEqual(2U, [LinkToAllTypesObject allObjectsInRealm:realm].count);
    RLMResults *results = [LinkToAllTypesObject objectsInRealm:realm where:@"allTypesCol = %@", linkedObject];
    XCTAssertEqual(1U, results.count);
    XCTAssert([linkObject isEqualToObject:results.firstObject]);
    
    [realm beginWriteTransaction];
    [realm deleteObject:linkedObject];
    [realm commitWriteTransaction];
    
    XCTAssertEqual(0U, results.count);
    XCTAssertEqualObjects(nil, results.firstObject);
    
    [realm beginWriteTransaction];
    [realm deleteObjects:[LinkToAllTypesObject allObjectsInRealm:realm]];
    [realm commitWriteTransaction];
    
    XCTAssertEqual(0U, results.count);
    XCTAssertEqualObjects(nil, results.firstObject);
}

@end
