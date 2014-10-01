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

#import "RLMObjectNode.h"
#import "RLMSidebarTableCellView.h"
#import "RLMArrayNode.h"
#import "RLMDescriptions.h"

@interface RLMObjectNode ()

@property (nonatomic) RLMObject *object;
@property (nonatomic) RLMDescriptions *realmDescriptions;

@end


@implementation RLMObjectNode {
    NSMutableArray *displayedArrays;
}

- (instancetype)initWithObject:(RLMObject *)object realm:(RLMRealm *)realm
{
    NSString *elementTypeName = object.className;
    RLMSchema *realmSchema = realm.schema;
    RLMObjectSchema *elementSchema = [realmSchema schemaForClassName:elementTypeName];
    
    if (self = [super initWithSchema:elementSchema inRealm:realm]) {
        displayedArrays = [[NSMutableArray alloc] initWithCapacity:10];
        self.realmDescriptions = [[RLMDescriptions alloc] init];
        
        self.object = object;
    }
    
    return self;
}

- (BOOL)isExpandable
{
    return YES;
}

- (NSUInteger)numberOfChildNodes
{
    return 1;
}

- (id<RLMRealmOutlineNode>)childNodeAtIndex:(NSUInteger)index
{
    return self.childNode;
}

- (RLMArrayNode *)displayChildArrayFromProperty:(RLMProperty *)property object:(RLMObject *)object
{
    RLMArrayNode *arrayNode = [[RLMArrayNode alloc] initWithReferringProperty:property
                                                                     onObject:object
                                                                        realm:self.realm];
    
    if (displayedArrays.count == 0) {
        [displayedArrays addObject:arrayNode];
    }
    else {
        [displayedArrays replaceObjectAtIndex:0
                                   withObject:arrayNode];
    }
    
    return arrayNode;
}

- (NSView *)cellViewForTableView:(NSTableView *)tableView
{
    RLMSidebarTableCellView *result = [tableView makeViewWithIdentifier:@"MainCell" owner:self];
    
    result.textField.stringValue = [self.realmDescriptions descriptionOfObject:self.object];
    result.button.hidden = YES;
    
    return result;
}

@end
