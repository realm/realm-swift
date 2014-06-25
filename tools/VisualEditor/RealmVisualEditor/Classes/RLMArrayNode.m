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

#import "RLMArrayNode.h"

@implementation RLMArrayNode {

    RLMProperty *referringProperty;
    RLMObject *referringObject;
    RLMArray *displayedArray;
}

- (instancetype)initWithArray:(RLMArray *)array withReferringProperty:(RLMProperty *)property onObject:(RLMObject *)object realm:(RLMRealm *)realm
{
    NSString *elementTypeName = property.objectClassName;
    RLMSchema *realmSchema = realm.schema;
    RLMObjectSchema *elementSchema = [realmSchema schemaForObject:elementTypeName];
    
    if (self = [super initWithSchema:elementSchema
                             inRealm:realm]) {
        referringProperty = property;
        referringObject = object;
        displayedArray = array;
    }

    return self;
}

#pragma mark - RLMObjectNode overrides

- (NSString *)name
{
    return @"Array";
}

- (NSUInteger)instanceCount
{
    return displayedArray.count;
}

- (RLMObject *)instanceAtIndex:(NSUInteger)index
{
    return displayedArray[index];
}

- (id)nodeElementForColumnWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
            return [NSString stringWithFormat:@"%@<%@>", referringProperty.name, referringProperty.objectClassName];
            
        default:
            return nil;
    }
}

#pragma mark - RLMRealmOutlineNode implementation

- (BOOL)hasToolTip
{
    return YES;
}

- (NSString *)toolTipString
{
    return referringObject.description;
}

@end
