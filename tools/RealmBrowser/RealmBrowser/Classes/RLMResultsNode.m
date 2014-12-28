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

#import "RLMResultsNode.h"
#import "RLMSidebarTableCellView.h"

@implementation RLMResultsNode {
    RLMResults *displayedResults;
    NSString *name;
}

- (instancetype)initWithQuery:(NSString *)searchText result:(RLMResults *)result andParent:(RLMTypeNode *)classNode
{
    if (self = [super initWithSchema:classNode.schema inRealm:classNode.realm]) {
        displayedResults = result;
        name = searchText;
    }
    
    return self;
}

- (NSView *)cellViewForTableView:(NSTableView *)tableView
{
    RLMSidebarTableCellView *cellView = [tableView makeViewWithIdentifier:@"MainCell" owner:self];
    if (name) {
        cellView.textField.stringValue = [NSString stringWithFormat:@"\"%@\"", name];
    }
    
    cellView.button.title = [NSString stringWithFormat:@"%lu", [self instanceCount]];
    [[cellView.button cell] setHighlightsBy:0];
    cellView.button.hidden = NO;
    
    return cellView;
}

- (NSUInteger)instanceCount
{
    return displayedResults.count;
}

- (RLMObject *)instanceAtIndex:(NSUInteger)index
{
    return displayedResults[index];
}


@end
