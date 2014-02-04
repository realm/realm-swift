//
//  group.m
//  TightDB
//

#include <tightdb/group.hpp>
#include <tightdb/lang_bind_helper.hpp>

#import <tightdb/objc/group.h>
#import <tightdb/objc/table.h>
#import <tightdb/objc/table_priv.h>

#include <tightdb/objc/util.hpp>

using namespace std;


@implementation TightdbGroup
{
    tightdb::Group* m_group;
    BOOL m_is_owned;
    BOOL m_read_only;
}

+(TightdbGroup*)group
{
    return [self groupWithError:nil];
}

+(TightdbGroup*)groupWithError:(NSError* __autoreleasing*)error
{
    TightdbGroup* group = [[TightdbGroup alloc] init];
    TIGHTDB_EXCEPTION_ERRHANDLER(group->m_group = new tightdb::Group;, nil);
    group->m_is_owned  = YES;
    group->m_read_only = NO;
    return group;
}

// Careful with this one - Remember that group will be deleted on dealloc.
+(TightdbGroup*)groupWithNativeGroup:(tightdb::Group*)group isOwned:(BOOL)is_owned readOnly:(BOOL)read_only
{
    TightdbGroup* group_2 = [[TightdbGroup alloc] init];
    group_2->m_group = group;
    group_2->m_is_owned  = is_owned;
    group_2->m_read_only = read_only;
    return group_2;
}


+(TightdbGroup*)groupWithFilename:(NSString*)filename
{
    return [self groupWithFilename:filename error:nil];
}

+(TightdbGroup*)groupWithFilename:(NSString*)filename error:(NSError**)error
{
    TightdbGroup* group = [[TightdbGroup alloc] init];
    if (!group)
        return nil;
    TIGHTDB_EXCEPTION_ERRHANDLER(
        group->m_group = new tightdb::Group(tightdb::StringData(ObjcStringAccessor(filename)));,
        nil);
    group->m_is_owned  = YES;
    group->m_read_only = NO;
    return group;
}

+(TightdbGroup*)groupWithBuffer:(const char*)data size:(size_t)size
{
    return [self groupWithBuffer:data size:size error:nil];
}

+(TightdbGroup*)groupWithBuffer:(const char*)data size:(size_t)size error:(NSError* __autoreleasing*)error
{
    TightdbGroup* group = [[TightdbGroup alloc] init];
    if (!group)
        return nil;
    TIGHTDB_EXCEPTION_ERRHANDLER(
        group->m_group = new tightdb::Group(tightdb::BinaryData(data, size));,
        nil);
    group->m_is_owned  = YES;
    group->m_read_only = NO;
    return group;
}

-(void)dealloc
{
#ifdef TIGHTDB_DEBUG
    NSLog(@"TightdbGroup dealloc");
#endif
    if (m_is_owned)
        delete m_group;
}


-(size_t)getTableCount
{
    return m_group->size();
}
-(NSString*)getTableName:(size_t)table_ndx
{
    return to_objc_string(m_group->get_table_name(table_ndx));
}

-(BOOL)write:(NSString*)file_path
{
    return [self write:file_path error:nil];
}

-(BOOL)write:(NSString*)file_path error:(NSError* __autoreleasing*)error
{
    TIGHTDB_EXCEPTION_ERRHANDLER(
        m_group->write(tightdb::StringData(ObjcStringAccessor(file_path)));,
        NO);
    return YES;
}

-(const char*)writeToMem:(size_t*)size
{
    return [self writeToMem:size error:nil];
}

-(const char*)writeToMem:(size_t*)size error:(NSError* __autoreleasing*)error
{
    TIGHTDB_EXCEPTION_ERRHANDLER(
        tightdb::BinaryData buffer = m_group->write_to_mem();
        *size = buffer.size();
        return buffer.data();,
        nil);
}

-(BOOL)hasTable:(NSString*)name
{
    return m_group->has_table(ObjcStringAccessor(name));
}

// FIXME: Avoid creating a table instance. It should be enough to create an TightdbDescriptor and then check that.
// FIXME: Check that the specified class derives from Table.
// FIXME: Find a way to avoid having to transcode the table name twice
-(BOOL)hasTable:(NSString*)name withClass:(__unsafe_unretained Class)class_obj
{
    if (!m_group->has_table(ObjcStringAccessor(name)))
        return NO;
    TightdbTable* table = [self getTable:name withClass:class_obj];
    return table != nil;
}

-(id)getTable:(NSString*)name
{
    return [self getTable:name error:nil];
}

-(id)getTable:(NSString*)name error:(NSError* __autoreleasing*)error
{
    TightdbTable* table = [[TightdbTable alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table))
        return nil;
    TIGHTDB_EXCEPTION_ERRHANDLER(
        tightdb::TableRef table_2 = m_group->get_table(ObjcStringAccessor(name));
        [table setNativeTable:table_2.get()];,
        nil);
    [table setParent:self];
    [table setReadOnly:m_read_only];
    return table;
}

-(id)getTable:(NSString*)name withClass:(__unsafe_unretained Class)class_obj
{
    return [self getTable:name withClass:class_obj error:nil];
}
// FIXME: Check that the specified class derives from Table.
-(id)getTable:(NSString*)name withClass:(__unsafe_unretained Class)class_obj error:(NSError* __autoreleasing*)error
{
    TightdbTable* table = [[class_obj alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table))
        return nil;
    bool was_created;
    TIGHTDB_EXCEPTION_ERRHANDLER(
        tightdb::TableRef table_2 = m_group->get_table(ObjcStringAccessor(name), was_created);
        [table setNativeTable:table_2.get()];,
        nil);
    [table setParent:self];
    [table setReadOnly:m_read_only];
    if (was_created) {
        if (![table _addColumns])
            return nil;
    }
    else {
        if (![table _checkType])
            return nil;
    }
    return table;
}
@end
