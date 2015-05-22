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

@interface TransactionTests : RLMTestCase
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

@end
