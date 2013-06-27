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
    TightdbGroup *group = [[TightdbGroup alloc] init];
    group.group = new tightdb::Group(); // FIXME: Both new-operator and Group constructor may throw at least std::bad_alloc.
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
    try {
        group = new tightdb::Group(tightdb::StringData(ObjcStringAccessor(filename)));
    }
    catch (std::exception &ex) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.group", tdb_err_Fail, [NSString stringWithUTF8String:ex.what()]);
        return nil;
    }
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

+(TightdbGroup *)groupWithBuffer:(const char *)data size:(size_t)size error:(NSError **)error
{
    tightdb::Group* group;
    try {
        group = new tightdb::Group(tightdb::BinaryData(data, size));
    }
    catch (std::exception &ex) {
        if (error)
            *error = make_tightdb_error(@"com.tightdb.group", tdb_err_Fail, [NSString stringWithUTF8String:ex.what()]);
        return nil;
    }
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

-(void)write:(NSString *)filePath
{
    _group->write(tightdb::StringData(ObjcStringAccessor(filePath))); // FIXME: May throw at least tightdb::File::AccessError (and various derivatives), tightdb::ResourceAllocError, and std::bad_alloc
}
-(const char*)writeToMem:(size_t*)size
{
    tightdb::BinaryData buffer = _group->write_to_mem(); // FIXME: May throw at least std::bad_alloc
    *size = buffer.size();
    return buffer.data();
}

-(BOOL)hasTable:(NSString *)name
{
    return _group->has_table(ObjcStringAccessor(name));
}

// FIXME: Avoid creating a table instance. It should be enough to create an TightdbSpec and then check that.
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
    TightdbTable *table = [[TightdbTable alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table)) return nil;
    [table setTable:_group->get_table(ObjcStringAccessor(name))];
    [table setParent:self];
    [table setReadOnly:_readOnly];
    return table;
}

// FIXME: Check that the specified class derives from Table.
-(id)getTable:(NSString *)name withClass:(__unsafe_unretained Class)classObj
{
    TightdbTable *table = [[classObj alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table)) return nil;
    bool was_created;
    tightdb::TableRef r = tightdb::LangBindHelper::get_table_ptr(_group, ObjcStringAccessor(name),
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
