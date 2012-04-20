//
//  OCGroup.m
//  TightDB
//

#import "OCGroup.h"
#import "Group.h"
#import "OCTable.h"
#import "OCTablePriv.h"


@interface OCGroup()
@property(nonatomic) Group *group;
@end
@implementation OCGroup
{
    NSMutableArray *_tables; // Temp solution to refrain from deleting group before tables.
}
@synthesize group = _group;

+(OCGroup *)group
{
    OCGroup *group = [[OCGroup alloc] init];
    group.group = new Group();
    return group;    
}

+(OCGroup *)groupWithFilename:(NSString *)filename
{
    OCGroup *group = [[OCGroup alloc] init];
    group.group = new Group([filename UTF8String]);
    return group;
}

+(OCGroup *)groupWithBuffer:(const char *)buffer len:(size_t)len
{
    OCGroup *group = [[OCGroup alloc] init];
    group.group = new Group(buffer,len);
    return group;
}

-(void)dealloc
{
#ifdef DEBUG
    NSLog(@"Group dealloc");
#endif
    // NOTE: Because of ARC we remove tableref from sub tables when this is deleted.
/*    for(OCTable *table in _tables) {
        NSLog(@"Delete...");
        table.table = TableRef();
    }
    _tables = nil;*/
    delete _group;
}


-(BOOL)isValid
{
    return _group->IsValid();
}
-(size_t)getTableCount
{
    return _group->GetTableCount();
}
-(NSString *)getTableName:(size_t)table_ndx
{
    return [NSString stringWithUTF8String:_group->GetTableName(table_ndx)];
}
-(BOOL)hasTable:(NSString *)name
{
    return _group->HasTable([name UTF8String]);
}
-(void)write:(NSString *)filePath
{
    _group->Write([filePath UTF8String]);
}
-(char*)writeToMem:(size_t*)len
{
    return _group->WriteToMem(*len);
}

-(id)getTable:(NSString *)name withClass:(__unsafe_unretained Class)obj
{
    return [[obj alloc] initWithBlock:^(OCTable *table) {
        [table setTablePtr:nil];
        [table setTable:_group->GetTable([name UTF8String]).GetTableRef()];
        [table setParent:self];
    }];
    return [_tables lastObject];
}
@end
