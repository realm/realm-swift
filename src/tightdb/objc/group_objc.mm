//
//  group.m
//  TightDB
//

#import <tightdb/group.hpp>
#import <tightdb/lang_bind_helper.hpp>

#import <tightdb/objc/group.h>
#import <tightdb/objc/table.h>
#import <tightdb/objc/table_priv.h>


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
    tightdb::Group* group;
    try {
        group = new tightdb::Group([filename UTF8String]);
    }
    catch (...) {
        // FIXME: Diffrent exception types mean different things. More
        // details must be made available. We should proably have
        // special catches for at least these:
        // tightdb::File::OpenError (and various derivatives),
        // tightdb::ResourceAllocError, std::bad_alloc. In general,
        // any core library function or operator that is not declared
        // 'noexcept' must be considered as being able to throw
        // anything derived from std::exception.
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
    tightdb::Group* group;
    try {
        group = new tightdb::Group(tightdb::Group::BufferSpec(data, size));
    }
    catch (...) {
        // FIXME: Diffrent exception types mean different things. More
        // details must be made available. We should proably have
        // special catches for at least these:
        // tightdb::File::OpenError (and various derivatives),
        // tightdb::ResourceAllocError, std::bad_alloc. In general,
        // any core library function or operator that is not declared
        // 'noexcept' must be considered as being able to throw
        // anything derived from std::exception.
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
    return [NSString stringWithUTF8String:_group->get_table_name(table_ndx)];
}

-(void)write:(NSString *)filePath
{
    _group->write([filePath UTF8String]); // FIXME: May throw at least tightdb::File::OpenError (and various derivatives), tightdb::ResourceAllocError, and std::bad_alloc
}
-(const char*)writeToMem:(size_t*)size
{
    tightdb::Group::BufferSpec buffer = _group->write_to_mem(); // FIXME: May throw at least std::bad_alloc
    *size = buffer.m_size;
    return buffer.m_data;
}

-(BOOL)hasTable:(NSString *)name
{
    return _group->has_table([name UTF8String]);
}

// FIXME: Avoid creating a table instance. It should be enough to create an TightdbSpec and then check that.
// FIXME: Check that the specified class derives from Table.
-(BOOL)hasTable:(NSString *)name withClass:(__unsafe_unretained Class)classObj
{
    if (!_group->has_table([name UTF8String])) return NO;
    TightdbTable* table = [self getTable:name withClass:classObj];
    return table != nil;
}

-(id)getTable:(NSString *)name
{
    TightdbTable *table = [[TightdbTable alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table)) return nil;
    [table setTable:_group->get_table([name UTF8String])];
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
