//
//  RLMRealmTable.m
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 20/05/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMRealmTable.h"

@implementation RLMRealmTable {
    
    NSMutableArray *tableRows;
}

@synthesize tableName = _tableName;
@synthesize tableColumns = _tableColumns;

- (instancetype)initWithName:(NSString *)name columns:(NSArray *)columns
{
    if (self = [super init]) {
        _tableName = [name copy];
        _tableColumns = [columns copy];
        tableRows = [[NSMutableArray alloc] initWithCapacity:50];
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name columnNames:(NSArray *)columnNames columnTypes:(NSArray *)columnTypes
{
    if (columnNames.count == columnTypes.count) {
        NSMutableArray *columns = [[NSMutableArray alloc] initWithCapacity:columnNames.count];
        
        for(NSUInteger index = 0; index < columnNames.count; index++) {
            NSNumber *type = columnTypes[index];
            RLMRealmColumn *column = [[RLMRealmColumn alloc] initWithName:columnNames[index]
                                                                     type:(RLMTableColumnType)type.integerValue];
            [columns addObject:column];
        }
        
        self = [self initWithName:name
                          columns:columns];
        return self;
    }
    return nil;
}

- (BOOL)addRowWithValues:(NSArray *)values
{
    if(values.count == _tableColumns.count) {
        for(NSUInteger index = 0; index < values.count; index++) {
            NSObject *value = values[index];
            RLMRealmColumn *column = _tableColumns[index];
            if(![value isKindOfClass:column.columnClass]) {
                return NO;
            }
        }
        
        [tableRows addObject:values];
        
        return YES;
    }
    
    return NO;
}

- (NSUInteger)rowCount
{
    return tableRows.count;
}

- (NSArray *)rowAtIndex:(NSUInteger)index
{
    return tableRows[index];
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
    return tableRows[index];
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

@end
