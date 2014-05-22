//
//  RLMTableNode.m
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 20/05/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMTableNode.h"

@implementation RLMTableNode {

    RLMTable *realmTable;
}

@synthesize tableName = _tableName;
@synthesize tableColumns = _tableColumns;

- (instancetype)initWithName:(NSString *)name realmTable:(RLMTable *)table
{
    if (self = [super init]) {
        realmTable = table;
        
        _tableName = [name copy];
        _tableColumns = [self constructColumnsObjectForTable:table];
    }
    return self;
}

- (BOOL)addRowWithValues:(NSArray *)values
{
    return NO;
}

- (NSUInteger)rowCount
{
    return realmTable.rowCount;
}

- (NSArray *)rowAtIndex:(NSUInteger)index
{
    return [realmTable rowAtIndex:index];
}

#pragma mark - RLMRealmOutlineNode implementation

- (BOOL)isRootNode
{
    return NO;
}

- (BOOL)isExpandable
{
    return NO;
}

- (NSUInteger)numberOfChildNodes
{
    return 0;
}

- (id<RLMRealmOutlineNode>)childNodeAtIndex:(NSUInteger)index
{
    return nil;
}

- (id)nodeElementForColumnWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
            return _tableName;
            
        default:
            return nil;
    }
}

#pragma mark - Public methods - Accessors

- (NSArray *)constructColumnsObjectForTable:(RLMTable *)table;
{
    RLMDescriptor *descriptor = [table descriptor];
    NSUInteger columnCount = descriptor.columnCount;
    
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:columnCount];
    for (NSUInteger index = 0; index < columnCount; index++) {
        NSString *columnName = [descriptor nameOfColumnWithIndex:index];
        RLMType columnType = [descriptor columnTypeOfColumnWithIndex:index];
        
        RLMTableColumn *tableColumn = [[RLMTableColumn alloc] initWithName:columnName
                                                                      type:columnType];
        [result addObject:tableColumn];
    }
    
    return result;
}

@end
