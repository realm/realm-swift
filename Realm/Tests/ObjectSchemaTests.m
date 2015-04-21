////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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
#import "RLMObjectSchema_Private.h"

@interface ObjectSchemaTests : RLMTestCase

@end

@implementation ObjectSchemaTests

- (void)testDescription {
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:[PrimaryStringObject class]];
    XCTAssertEqualObjects(objectSchema.description, @"PrimaryStringObject {\n"
                                                    @"\tstringCol {\n"
                                                    @"\t\ttype = string;\n"
                                                    @"\t\tobjectClassName = (null);\n"
                                                    @"\t\tindexed = YES;\n"
                                                    @"\t\tisPrimary = YES;\n"
                                                    @"\t\toptional = YES;\n"
                                                    @"\t}\n"
                                                    @"\tintCol {\n"
                                                    @"\t\ttype = int;\n"
                                                    @"\t\tobjectClassName = (null);\n"
                                                    @"\t\tindexed = NO;\n"
                                                    @"\t\tisPrimary = NO;\n"
                                                    @"\t\toptional = NO;\n"
                                                    @"\t}\n"
                                                    @"}");
}

@end
