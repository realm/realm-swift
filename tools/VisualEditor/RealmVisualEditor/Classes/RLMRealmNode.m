//
//  RLMRealmNode.m
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 20/05/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMRealmNode.h"

#import "Realm.h"

@implementation RLMRealmNode

@synthesize realm = _realm;
@synthesize name = _name;
@synthesize url = _url;
@synthesize topLevelTables = _topLevelTables;

- (instancetype)init
{
    return self = [self initWithName:@"Unknown name"
                                 url:@"Unknown location"];
}

- (instancetype)initWithName:(NSString *)name url:(NSString *)url
{
    if (self = [super init]) {
        _realm = [RLMRealm realmWithPath:url];
        
        _name = name;
        _url = url;        
        _topLevelTables = [self constructTopLevelTables];
    }
    return self;
}

- (void)addTable:(RLMTableNode *)table
{

}

#pragma mark - RLMRealmOutlineNode implementation

- (BOOL)isRootNode
{
    return YES;
}

- (BOOL)isExpandable
{
    return [self topLevelTables].count != 0;
}

- (NSUInteger)numberOfChildNodes
{
    return [self topLevelTables].count;
}

- (id<RLMRealmOutlineNode>)childNodeAtIndex:(NSUInteger)index
{
    return [self topLevelTables][index];
}

- (id)nodeElementForColumnWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
            return _name;

        case 1:
            return _url;
            
        default:
            return nil;
    }
}

#pragma mark - Private methods

- (NSArray *)constructTopLevelTables
{
    NSUInteger tableCount = [_realm tableCount];
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:tableCount];
    
    for(NSUInteger index = 0; index < tableCount; index++) {
        NSString *tableName = [_realm nameOfTableWithIndex:index];
        RLMTable *realmTable = [_realm tableWithName:tableName];
        
        RLMTableNode *tableNode = [[RLMTableNode alloc] initWithName:tableName
                                                          realmTable:realmTable];
        
        [result addObject:tableNode];
    }
    
    return result;
}

@end
