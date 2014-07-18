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

@interface UtilTests : RLMTestCase
// Nothing new to add.
@end

@interface UTF8Object : RLMObject
@property NSString* 柱колонка;
@end

@implementation UTF8Object
// No implementation necessary.
@end

@implementation UtilTests

-(void) testRLMStringDataWithNSString
{
    [RLMRealm useInMemoryDefaultRealm];
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [UTF8Object createInRealm:realm withObject:@[@"值значение"]];
    [realm commitWriteTransaction];

    UTF8Object *obj = (UTF8Object*)[[UTF8Object allObjects] firstObject];
    XCTAssertEqualObjects(obj.柱колонка, @"值значение");
}

@end