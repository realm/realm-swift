//
//  RLMRealm.m
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 20/05/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMRealm.h"

@implementation RLMRealm {

    NSMutableArray *_topLevelTables;
}

@synthesize name = _name;
@synthesize url = _url;

@dynamic topLevelTables;

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
        _topLevelTables = [[NSMutableArray alloc] initWithCapacity:10];
    }
    return self;
}

- (void)addTable:(RLMRealmTable *)table
{
    [_topLevelTables addObject:table];
}

- (NSArray *)topLevelTables
{
    return _topLevelTables;
}

#pragma mark - RLMRealmOutlineNode implementation

- (BOOL)isRootNode
{
    return YES;
}

- (BOOL)isExpandable
{
    return _topLevelTables.count != 0;
}

- (NSUInteger)numberOfChildNodes
{
    return _topLevelTables.count;
}

- (id<RLMRealmOutlineNode>)childNodeAtIndex:(NSUInteger)index
{
    return _topLevelTables[index];
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

@end
