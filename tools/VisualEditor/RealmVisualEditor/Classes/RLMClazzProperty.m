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

#import "RLMClazzProperty.h"

#import "RLMClazzNode.h"

@implementation RLMClazzProperty

- (instancetype)initWithProperty:(RLMProperty *)property;
{
    if (self = [super init]) {
        _property = property;
    }
    return self;
}

- (NSString *)name
{
    return _property.name;
}

- (RLMPropertyType)type
{
    return _property.type;
}

- (Class)clazz
{
    switch (self.type) {
        case RLMPropertyTypeBool:
        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
            return [NSNumber class];
        case RLMPropertyTypeString:
            return [NSString class];
        case RLMPropertyTypeDate:
            return [NSDate class];
        case RLMPropertyTypeData:
        case RLMPropertyTypeObject:
        case RLMPropertyTypeArray:
        case RLMPropertyTypeAny:
            return [RLMClazzNode class];
        default:
            return nil;
    }
}

@end
