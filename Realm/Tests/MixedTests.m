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

@interface MixedTests : RLMTestCase
@end

@implementation MixedTests

#pragma mark - Tests

- (void)testMixedInsert {
    const char *data = "Hello World";
    
    RLMRealm *realm = self.realmWithTestPath;

    // FIXME: add object with subtable
    [realm beginWriteTransaction];
    [MixedObject createInRealm:realm withValue:@[@YES, @"Jens", @50]];
    [MixedObject createInRealm:realm withValue:@[@YES, @10, @52]];
    [MixedObject createInRealm:realm withValue:@[@YES, @3.1f, @53]];
    [MixedObject createInRealm:realm withValue:@[@YES, @3.1, @54]];
    [MixedObject createInRealm:realm withValue:@[@YES, [NSDate date], @55]];
    [MixedObject createInRealm:realm withValue:@[@YES, [NSData dataWithBytes:(void *)data length:strlen(data)], @56]];
    [realm commitWriteTransaction];

    RLMResults *objects = [MixedObject allObjectsInRealm:realm];
    XCTAssertEqual(objects.count, (NSUInteger)6, @"6 rows excepted");
    XCTAssertTrue([[objects objectAtIndex:0] isKindOfClass:[MixedObject class]], @"MixedObject expected");
    XCTAssertTrue([[objects objectAtIndex:0][@"other"] isKindOfClass:[NSString class]], @"NSString expected");
    XCTAssertTrue([[objects objectAtIndex:0][@"other"] isEqualToString:@"Jens"], @"'Jens' expected");

    XCTAssertTrue([[objects objectAtIndex:1][@"other"] isKindOfClass:[NSNumber class]], @"NSNumber expected");
    XCTAssertEqual([[objects objectAtIndex:1][@"other"] longLongValue], (long long)10, @"'10' expected");

    XCTAssertTrue([[objects objectAtIndex:2][@"other"] isKindOfClass:[NSNumber class]], @"NSNumber expected");
    XCTAssertEqual([[objects objectAtIndex:2][@"other"] floatValue], (float)3.1, @"'3.1' expected");

    XCTAssertTrue([[objects objectAtIndex:3][@"other"] isKindOfClass:[NSNumber class]], @"NSNumber expected");
    XCTAssertEqual([[objects objectAtIndex:3][@"other"] doubleValue], (double)3.1, @"'3.1' expected");

    XCTAssertTrue([[objects objectAtIndex:4][@"other"] isKindOfClass:[NSDate class]], @"NSDate expected");

    XCTAssertTrue([[objects objectAtIndex:5][@"other"] isKindOfClass:[NSData class]], @"NSData expected");
}

- (void)testMixedValidate {
    RLMRealm *realm = [self realmWithTestPath];

    [realm beginWriteTransaction];
    XCTAssertThrows(([MixedObject createInRealm:realm withValue:@[@YES, @[@1, @2], @7]]), @"Mixed cannot be an NSArray");
    XCTAssertThrows(([MixedObject createInRealm:realm withValue:@[@YES, @{@"key": @7}, @11]]), @"Mixed cannot be an NSDictionary");

    XCTAssertEqual([MixedObject allObjects].count, (NSUInteger)0, @"0 rows expected");
    [realm commitWriteTransaction];
}



@end
