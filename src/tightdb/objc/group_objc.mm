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


@interface TightdbGroup()
@property(nonatomic) tightdb::Group *group;
@property(nonatomic) BOOL readOnly;
@end

@implementation TightdbGroup
@synthesize group = _group;
@synthesize readOnly = _readOnly;

+(TightdbGroup *)group
{
    return [self groupWithError:nil];
}

+(TightdbGroup *)groupWithError:(NSError *__autoreleasing *)error
{
    TightdbGroup *group = [[TightdbGroup alloc] init];
    TIGHTDB_EXCEPTION_ERRHANDLER(group.group = new tightdb::Group();, nil);
    group.readOnly = NO;
    return group;
}

// Careful with this one - Remember that group will be deleted on dealloc.
+(TightdbGroup *)groupTightdbGroup:(tightdb::Group *)tightdbGroup readOnly:(BOOL)readOnly
{
    TightdbGroup *group = [[TightdbGroup alloc] init];
    group.group = tightdbGroup;
    group.readOnly = readOnly;
    return group;
}


+(TightdbGroup *)groupWithFilename:(NSString *)filename
{
    return [self groupWithFilename:filename error:nil];
}

+(TightdbGroup *)groupWithFilename:(NSString *)filename error:(NSError **)error
{
    tightdb::Group* group;
    TIGHTDB_EXCEPTION_ERRHANDLER(
        group = new tightdb::Group(tightdb::StringData(ObjcStringAccessor(filename)));,
        nil);
    TightdbGroup* group2 = [[TightdbGroup alloc] init];
    if (group2) {
      group2.group = group;
      group2.readOnly = NO;
    }
    return group2;
}

+(TightdbGroup *)groupWithBuffer:(const char *)data size:(size_t)size
{
    return [self groupWithBuffer:data size:size error:nil];
}

+(TightdbGroup *)groupWithBuffer:(const char *)data size:(size_t)size error:(NSError *__autoreleasing *)error
{
    tightdb::Group* group;
    TIGHTDB_EXCEPTION_ERRHANDLER(
        group = new tightdb::Group(tightdb::BinaryData(data, size));,
        nil);
    TightdbGroup* group2 = [[TightdbGroup alloc] init];
    group2.group = group;
    group2.readOnly = NO;
    return group2;
}

-(void)clearGroup
{
    _group = 0;
}

-(void)dealloc
{
#ifdef TIGHTDB_DEBUG
    NSLog(@"TightdbGroup dealloc");
#endif
    delete _group;
}


-(size_t)getTableCount
{
    return _group->size();
}
-(NSString *)getTableName:(size_t)table_ndx
{
    return to_objc_string(_group->get_table_name(table_ndx));
}

-(BOOL)write:(NSString *)filePath
{
    return [self write:filePath error:nil];
}

-(BOOL)write:(NSString *)filePath error:(NSError *__autoreleasing *)error
{
    TIGHTDB_EXCEPTION_ERRHANDLER(
        _group->write(tightdb::StringData(ObjcStringAccessor(filePath)));,
        NO);
    return YES;
}

-(const char*)writeToMem:(size_t*)size
{
    return [self writeToMem:size error:nil];
}

-(const char*)writeToMem:(size_t*)size error:(NSError *__autoreleasing *)error
{
    TIGHTDB_EXCEPTION_ERRHANDLER(
        tightdb::BinaryData buffer = _group->write_to_mem();
        *size = buffer.size();
        return buffer.data();,
        nil);
}

-(BOOL)hasTable:(NSString *)name
{
    return _group->has_table(ObjcStringAccessor(name));
}

// FIXME: Avoid creating a table instance. It should be enough to create an TightdbDescriptor and then check that.
// FIXME: Check that the specified class derives from Table.
// FIXME: Find a way to avoid having to transcode the table name twice
-(BOOL)hasTable:(NSString *)name withClass:(__unsafe_unretained Class)classObj
{
    if (!_group->has_table(ObjcStringAccessor(name))) return NO;
    TightdbTable* table = [self getTable:name withClass:classObj];
    return table != nil;
}

-(id)getTable:(NSString *)name
{
    return [self getTable:name error:nil];
}

-(id)getTable:(NSString *)name error:(NSError *__autoreleasing *)error
{
    TightdbTable *table = [[TightdbTable alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table)) return nil;
    TIGHTDB_EXCEPTION_ERRHANDLER(
        [table setTable:_group->get_table(ObjcStringAccessor(name))];,
        nil);
    [table setParent:self];
    [table setReadOnly:_readOnly];
    return table;
}

-(id)getTable:(NSString *)name withClass:(__unsafe_unretained Class)classObj
{
    return [self getTable:name withClass:classObj error:nil];
}
// FIXME: Check that the specified class derives from Table.
-(id)getTable:(NSString *)name withClass:(__unsafe_unretained Class)classObj error:(NSError *__autoreleasing *)error
{
    TightdbTable *table = [[classObj alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table)) return nil;
    bool was_created;
    TIGHTDB_EXCEPTION_ERRHANDLER(
        [table setTable:_group->get_table(ObjcStringAccessor(name), was_created)];,
        nil);
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
