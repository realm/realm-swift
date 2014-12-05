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

#import "RLMRealmNode.h"

#import <Realm/Realm.h>

#import "RLMSidebarTableCellView.h"
#import "NSColor+ByteSizeFactory.h"
#import "Realm_Private.h"

@implementation RLMRealmNode

- (instancetype)init
{
    return self = [self initWithName:@"Unknown name"
                                 url:@"Unknown location"];
}

- (instancetype)initWithName:(NSString *)name url:(NSString *)url
{
    if (self = [super init]) {
        _name = name;
        _url = url;        
    }
    return self;
}

- (BOOL)connect:(NSError **)error
{
    _realm = [RLMRealm realmWithPath:_url
                            readOnly:NO
                            inMemory:NO
                             dynamic:YES
                              schema:nil
                               error:error];
    
    if (*error != nil) {
        NSLog(@"Realm was opened with error: %@", *error);
    }
    else {
        _topLevelClasses = [self constructTopLevelClasses];    
    }
    
    return error != nil;
}


- (void)addTable:(RLMClassNode *)table
{

}

#pragma mark - RLMRealmOutlineNode implementation

- (BOOL)isRootNode
{
    return YES;
}

- (BOOL)isExpandable
{
    return self.topLevelClasses.count != 0;
}

- (NSUInteger)numberOfChildNodes
{
    return self.topLevelClasses.count;
}

- (id<RLMRealmOutlineNode>)childNodeAtIndex:(NSUInteger)index
{
    return self.topLevelClasses[index];
}

- (BOOL)hasToolTip
{
    return YES;
}

- (NSString *)toolTipString
{
    return _url;
}

- (NSView *)cellViewForTableView:(NSTableView *)tableView
{
    NSTextField *result = [tableView makeViewWithIdentifier:@"HeaderLabel" owner:self];
    [result setStringValue:@"CLASSES"];
    
    return result;
}

#pragma mark - Private methods

- (NSArray *)constructTopLevelClasses
{
    RLMSchema *realmSchema = _realm.schema;
    NSArray *allObjectSchemas = realmSchema.objectSchema;
    
    NSUInteger classCount = allObjectSchemas.count;
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:classCount];
    
    for (NSUInteger index = 0; index < classCount; index++) {
        RLMObjectSchema *objectSchema = allObjectSchemas[index];        
        RLMClassNode *tableNode = [[RLMClassNode alloc] initWithSchema:objectSchema inRealm:_realm];
        
        [result addObject:tableNode];
    }
    
    return result;
}

@end
