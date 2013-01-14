//
//  group.m
//  TightDB
//

#import <tightdb/group.hpp>
#import <tightdb/lang_bind_helper.hpp>

#import <tightdb/objc/group.h>
#import <tightdb/objc/table.h>
#import <tightdb/objc/table_priv.h>


@interface Group()
@property(nonatomic) tightdb::Group *group;
@property(nonatomic) BOOL readOnly;
@end
@implementation Group
@synthesize group = _group;
@synthesize readOnly = _readOnly;

+(Group *)group
{
    Group *group = [[Group alloc] init];
    group.group = new tightdb::Group(); // FIXME: May throw
    group.readOnly = NO;
    return group;
}

// Careful with this one - Remember that group will be deleted on dealloc.
+(Group *)groupTightdbGroup:(tightdb::Group *)tightdbGroup readOnly:(BOOL)readOnly
{
    Group *group = [[Group alloc] init];
    group.group = tightdbGroup;
    group.readOnly = readOnly;
    return group;
}

+(Group *)groupWithFilename:(NSString *)filename
{
    Group *group = [[Group alloc] init];
    try {
        group.group = new tightdb::Group([filename UTF8String]);
    }
    catch (...) {
        // FIXME: Somehow reveal the reason for this failure to the user
        return nil;
    }
    group.readOnly = NO;
    return group;
}

+(Group *)groupWithBuffer:(char *)buffer len:(size_t)len
{
    Group *group = [[Group alloc] init];
    try {
        group.group = new tightdb::Group(tightdb::Group::BufferSpec(buffer, len));
    }
    catch (...) {
        // FIXME: Somehow reveal the reason for this failure to the user
        return nil;
    }
    group.readOnly = NO;
    return group;
}

-(void)clearGroup
{
    _group = 0;
}

-(void)dealloc
{
#ifdef TIGHTDB_DEBUG
    NSLog(@"Group dealloc");
#endif
    delete _group;
}


-(size_t)getTableCount
{
    return _group->get_table_count();
}
-(NSString *)getTableName:(size_t)table_ndx
{
    return [NSString stringWithUTF8String:_group->get_table_name(table_ndx)];
}

-(void)write:(NSString *)filePath
{
    _group->write([filePath UTF8String]); // FIXME: May throw
}
-(char*)writeToMem:(size_t*)len
{
    tightdb::Group::BufferSpec buffer = _group->write_to_mem(); // FIXME: May throw
    *len = buffer.m_size;
    return buffer.m_data;
}

-(BOOL)hasTable:(NSString *)name
{
    return _group->has_table([name UTF8String]);
}

// FIXME: Avoid creating a table instance. It should be enough to create an OCSpec and then check that.
// FIXME: Check that the specified class derives from Table.
-(BOOL)hasTable:(NSString *)name withClass:(__unsafe_unretained Class)classObj
{
    if (!_group->has_table([name UTF8String])) return NO;
    Table* table = [self getTable:name withClass:classObj];
    return table != nil;
}

-(id)getTable:(NSString *)name
{
    Table *table = [[Table alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table)) return nil;
    [table setTable:_group->get_table([name UTF8String])];
    [table setParent:self];
    [table setReadOnly:_readOnly];
    return table;
}

// FIXME: Check that the specified class derives from Table.
-(id)getTable:(NSString *)name withClass:(__unsafe_unretained Class)classObj
{
    Table *table = [[classObj alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table)) return nil;
    bool was_created;
    tightdb::TableRef r = tightdb::LangBindHelper::get_table_ptr(_group, [name UTF8String],
                                                                 was_created)->get_table_ref();
    [table setTable:move(r)];
    [table setParent:self];
    [table setReadOnly:_readOnly];
    if (was_created) {
        if (![table _addColumns]) return nil;
    }
    else {
        if (![table _checkType]) return nil;
    }
    return table;
}
@end
