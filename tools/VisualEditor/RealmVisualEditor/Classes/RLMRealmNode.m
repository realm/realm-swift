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

#import "SidebarTableCellView.h"
#import "NSColor+ByteSizeFactory.h"

@interface RLMRealm ()

// private constructor
+ (instancetype)realmWithPath:(NSString *)path
                     readOnly:(BOOL)readonly
                      dynamic:(BOOL)dynamic
                       schema:(RLMSchema *)customSchema
                        error:(NSError **)outError;

@end


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
                             dynamic:YES
                              schema:nil
                               error:error];
    
    if (*error != nil) {
        NSLog(@"Realm was opened with error: %@", *error);
    }
    else {
        _topLevelClazzes = [self constructTopLevelClazzes];    
    }
    
    return error != nil;
}


- (void)addTable:(RLMClazzNode *)table
{

}

#pragma mark - RLMRealmOutlineNode implementation

- (BOOL)isRootNode
{
    return YES;
}

- (BOOL)isExpandable
{
    return [self topLevelClazzes].count != 0;
}

- (NSUInteger)numberOfChildNodes
{
    return [self topLevelClazzes].count;
}

- (id<RLMRealmOutlineNode>)childNodeAtIndex:(NSUInteger)index
{
    return [self topLevelClazzes][index];
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
    SidebarTableCellView *result = [tableView makeViewWithIdentifier:@"HeaderLabel"
                                                      owner:self];
    
    result.textField.stringValue = @"classes".uppercaseString;
    result.textField.textColor = [NSColor colorWithByteRed:145
                                                     green:152
                                                      blue:153
                                                     alpha:255];
    
    [[result.button cell] setHighlightsBy:0];
    
    return result;

}

#pragma mark - Private methods

- (NSArray *)constructTopLevelClazzes
{
    RLMSchema *realmSchema = _realm.schema;
    NSArray *allObjectSchemas = realmSchema.objectSchema;
    
    NSUInteger clazzCount = allObjectSchemas.count;
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:clazzCount];
    
    for (NSUInteger index = 0; index < clazzCount; index++) {
        RLMObjectSchema *objectSchema = allObjectSchemas[index];        
        RLMClazzNode *tableNode = [[RLMClazzNode alloc] initWithSchema:objectSchema
                                                               inRealm:_realm];
        
        [result addObject:tableNode];
    }
    
    return result;
}

@end
