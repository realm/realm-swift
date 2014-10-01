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

#import "RLMSidebarTableCellView.h"

@implementation RLMArrayNode {
    RLMProperty *referringProperty;
    RLMObject *referringObject;
    RLMArray *displayedArray;
    NSString *name;
}

#pragma mark - Public Methods

- (instancetype)initWithReferringProperty:(RLMProperty *)property onObject:(RLMObject *)object realm:(RLMRealm *)realm
{
    NSString *elementTypeName = property.objectClassName;
    RLMSchema *realmSchema = realm.schema;
    RLMObjectSchema *elementSchema = [realmSchema schemaForClassName:elementTypeName];
    
    if (self = [super initWithSchema:elementSchema
                             inRealm:realm]) {
        referringProperty = property;
        referringObject = object;
        displayedArray = object[property.name];
    }

    return self;
}

- (instancetype)initWithQuery:(NSString *)searchText result:(RLMArray *)result andParent:(RLMTypeNode *)classNode
{
    if (self = [super initWithSchema:classNode.schema inRealm:classNode.realm]) {
        displayedArray = result;
        name = searchText;
    }

    return self;
}

-(BOOL)insertInstance:(RLMObject *)object atIndex:(NSUInteger)index
{
    if (index >= [displayedArray count]) {
        return NO;
    }
    
    [displayedArray insertObject:object atIndex:index];
    return YES;
}

-(BOOL)removeInstanceAtIndex:(NSUInteger)index
{
    if (index >= [displayedArray count]) {
        return NO;
    }
    
    [displayedArray removeObjectAtIndex:index];
    return YES;
}

#pragma mark - RLMObjectNode Overrides

- (NSString *)name
{
    if (name) {
        return name;
    }
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

- (id)minimumOfPropertyNamed:(NSString *)propertyName
{
    return [displayedArray minOfProperty:propertyName];
}

- (NSNumber *)averageOfPropertyNamed:(NSString *)propertyName
{
    return [displayedArray averageOfProperty:propertyName];
}

- (id)maximumOfPropertyNamed:(NSString *)propertyName
{
    return [displayedArray maxOfProperty:propertyName];
}

- (NSNumber *)sumOfPropertyNamed:(NSString *)propertyName
{
    return [displayedArray sumOfProperty:propertyName];
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

- (NSView *)cellViewForTableView:(NSTableView *)tableView
{
    RLMSidebarTableCellView *cellView = [tableView makeViewWithIdentifier:@"MainCell" owner:self];
    if (name) {
        cellView.textField.stringValue = [NSString stringWithFormat:@"\"%@\"", name];
    }
    else {
        cellView.textField.stringValue = [NSString stringWithFormat:@"%@: <%@>",
                                          referringProperty.name, referringProperty.objectClassName];
    }

    cellView.button.title =[NSString stringWithFormat:@"%lu", [self instanceCount]];
    [[cellView.button cell] setHighlightsBy:0];
    cellView.button.hidden = NO;
    
    return cellView;
}

#pragma mark - RLMRealmOutlineNode Implementation

- (BOOL)hasToolTip
{
    return YES;
}

- (NSString *)toolTipString
{
    return referringObject.description;
}

@end
