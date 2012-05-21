//
//  Group.m
//  TightDB
//

#import "group.hpp"
#import "Group.h"
#import "Table.h"
#import "TablePriv.h"


@interface Group()
@property(nonatomic) tightdb::Group *group;
@end
@implementation Group
{
    NSMutableArray *_tables; // Temp solution to refrain from deleting group before tables.
}
@synthesize group = _group;

+(Group *)group
{
    Group *group = [[Group alloc] init];
    group.group = new tightdb::Group();
    return group;    
}

+(Group *)groupWithFilename:(NSString *)filename
{
    Group *group = [[Group alloc] init];
    group.group = new tightdb::Group([filename UTF8String]);
    return group;
}

+(Group *)groupWithBuffer:(const char *)buffer len:(size_t)len
{
    Group *group = [[Group alloc] init];
    group.group = new tightdb::Group(buffer,len);
    return group;
}

-(void)dealloc
{
#ifdef DEBUG
    NSLog(@"Group dealloc");
#endif
    // NOTE: Because of ARC we remove tableref from sub tables when this is deleted.
/*    for(Table *table in _tables) {
        NSLog(@"Delete...");
        table.table = TableRef();
    }
    _tables = nil;*/
    delete _group;
}


-(BOOL)isValid
{
    return _group->is_valid();
}
-(size_t)getTableCount
{
    return _group->get_table_count();
}
-(NSString *)getTableName:(size_t)table_ndx
{
    return [NSString stringWithUTF8String:_group->get_table_name(table_ndx)];
}
-(BOOL)hasTable:(NSString *)name
{
    return _group->has_table([name UTF8String]);
}
-(void)write:(NSString *)filePath
{
    _group->write([filePath UTF8String]);
}
-(char*)writeToMem:(size_t*)len
{
    return _group->write_to_mem(*len);
}

-(id)getTable:(NSString *)name withClass:(__unsafe_unretained Class)obj
{
    return [[obj alloc] initWithBlock:^(Table *table) {
        [table setTablePtr:nil];
        [table setTable:_group->get_table([name UTF8String])];
        [table setParent:self];
    }];
    return [_tables lastObject];
}
@end
