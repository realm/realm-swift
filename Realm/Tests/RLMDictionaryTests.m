////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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
#import <Realm/RLMDictionary.h>


@interface DictionaryObject : RLMObject
@property RLMDictionary<NSString *, PrimaryEmployeeObject *><PrimaryEmployeeObject> *employees;
//@property RLM_GENERIC_SET(PrimaryEmployeeObject) *employeeSet;
@end
//RLM_COLLECTION_TYPE(PrimaryEmployeeObject);

@implementation DictionaryObject
+ (NSArray *)requiredProperties {
    return @[@"employees"];
}
@end

@interface Test : RLMTestCase
@end

@implementation Test

- (void)testUnmanagedDictionary {
//    EmployeeObject *e1 = [PrimaryEmployeeObject createInRealm:realm withValue:@{@"name": @"A", @"age": @20, @"hired": @YES}];
    DictionaryObject *d = [[DictionaryObject alloc] initWithValue:@{@"employees": @{@"e": @{@"name": @"A", @"age": @20, @"hired": @YES}}}];
    
    XCTAssertEqual(d.description,
                   @"DictionaryObject {\n"
                   @"\temployees {\n"
                   @"\t\ttype = int;\n"
                   @"\t\tindexed = NO;\n"
                   @"\t\tisPrimary = NO;\n"
                   @"\t\tarray = NO;\n"
                   @"\t\tset = NO;\n"
                   @"\t\tdictionary = YES;\n"
                   @"\t\toptional = YES;\n"
                   @"\t}\n"
                   @"}");
    XCTAssertNotNil(d.employees);
}

@end
