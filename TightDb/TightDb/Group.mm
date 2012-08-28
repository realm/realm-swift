//
//  Group.m
//  TightDB
//

#import <tightdb/group.hpp>
#import "Group.h"
#import "Table.h"
#import "TablePriv.h"


@interface Group()
@property(nonatomic) tightdb::Group *group;
@end
@implementation Group
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
#ifdef TIGHTDB_DEBUG
    NSLog(@"Group dealloc");
#endif
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
    __weak Group *weakSelf = self;
    __weak NSString *weakName = name;
    return [[obj alloc] initWithBlock:^(Table *table) {
        Group *strongSelf = weakSelf;
        NSString *strongName = weakName;
        if (strongSelf) {
            [table setTablePtr:nil];
            [table setTable:_group->get_table([strongName UTF8String])];
            [table setParent:strongSelf];
        }
    }];
}
@end
