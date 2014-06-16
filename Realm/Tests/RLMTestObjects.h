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

#import <Foundation/Foundation.h>
#import "RLMObject.h"

@interface RLMTestObject : RLMObject
@property (nonatomic, copy) NSString *column;
@end

RLM_ARRAY_TYPE(RLMTestObject)

@interface AllTypesObject : RLMObject
@property BOOL           boolCol;
@property int            intCol;
@property float          floatCol;
@property double         doubleCol;
@property NSString      *stringCol;
@property NSData        *binaryCol;
@property NSDate        *dateCol;
@property bool           cBoolCol;
@property long           longCol;
@property id             mixedCol;
@property RLMTestObject *objectCol;
//@property AgeTable      *tableCol;
@end



