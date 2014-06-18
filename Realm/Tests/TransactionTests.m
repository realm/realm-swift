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
#import "RLMTestObjects.h"

@interface SimpleMisuseObject : RLMObject
@property (nonatomic, copy) NSString *stringCol;
@property (nonatomic, assign) NSInteger intCol;
@end

@implementation SimpleMisuseObject

+ (NSDictionary *)defaultPropertyValues
{
    return @{@"stringCol" : @""};
}

@end


@interface TransactionTests : RLMTestCase

@end

@implementation TransactionTests

- (void)testRealmModifyObjectsOutsideOfWriteTransaction {
    RLMRealm *realm = [self realmWithTestPath];
    [realm beginWriteTransaction];
    RLMTestObject *obj = [RLMTestObject createInRealm:realm withObject:@[@"a"]];
    [realm commitWriteTransaction];
    
    XCTAssertThrows([obj setColumn:@"throw"], @"Setter should throw when called outside of transaction.");
}

-(void)testTransactionMisuse {
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    // Insert an object
    [realm beginWriteTransaction];
    SimpleMisuseObject *obj = [SimpleMisuseObject createInRealm:realm withObject:nil];
    obj.stringCol = @"stringVal";
    obj.intCol = 10;
    [realm commitWriteTransaction];
    
    XCTAssertThrows([SimpleMisuseObject createInRealm:realm withObject:nil], @"Outside write transaction");
    XCTAssertThrows([realm commitWriteTransaction], @"No write transaction to close");
    
    [realm beginWriteTransaction];
    XCTAssertThrows([realm beginWriteTransaction], @"Write transaction already in place");
    [realm commitWriteTransaction];
    
    XCTAssertThrows([realm deleteObject:obj], @"Outside writetransaction");
}


@end
