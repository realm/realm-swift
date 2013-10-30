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
    
    try {
        group.group = new tightdb::Group();
    } catch (std::exception &ex) {
        NSException *exception = [NSException exceptionWithName:@"tightdb:core_exception"
                                                         reason:[NSString stringWithUTF8String:ex.what()]
                                                       userInfo:[NSMutableDictionary dictionary]];  // IMPORTANT: cannot not be nil !!
        [exception raise];
    }
    group.readOnly = NO;
    return group;
}

// Private.
// Careful with this one - Remember that group will be deleted on dealloc.
+(TightdbGroup *)groupTightdbGroup:(tightdb::Group *)tightdbGroup readOnly:(BOOL)readOnly
{
    TightdbGroup *group = [[TightdbGroup alloc] init];
    group.group = tightdbGroup;
    group.readOnly = readOnly;
    return group;
}


+(TightdbGroup *)groupWithFile:(NSString *)filename withError:(NSError **)error
{
    tightdb::Group* coreGroup;

    try {
        coreGroup = new tightdb::Group(tightdb::StringData(ObjcStringAccessor(filename)));
    }
    // TODO: capture this in a macro or function, shared group constructor uses the same pattern.
    catch (tightdb::File::PermissionDenied &ex) {
        if(error) // allow nil as the error argument
            *error = make_tightdb_error(@"com.tightdb.sharedgroup", tdb_err_File_PermissionDenied, [NSString stringWithUTF8String:ex.what()]);
        return nil;

    }
    catch (tightdb::File::Exists &ex) {
        if(error) // allow nil as the error argument
            *error = make_tightdb_error(@"com.tightdb.sharedgroup", tdb_err_File_Exists, [NSString stringWithUTF8String:ex.what()]);
        return nil;

    }
    catch (tightdb::File::AccessError &ex) {
        if(error) // allow nil as the error argument
            *error = make_tightdb_error(@"com.tightdb.sharedgroup", tdb_err_File_AccessError, [NSString stringWithUTF8String:ex.what()]);
        return nil;

    }
    catch (std::exception &ex) {
        if(error) // allow nil as the error argument
            *error = make_tightdb_error(@"com.tightdb.sharedgroup", tdb_err_Fail, [NSString stringWithUTF8String:ex.what()]);
        return nil;
    }
    TightdbGroup* group = [[TightdbGroup alloc] init];
    if (group) {  // we are not consistent regarding this additional check
      group.group = coreGroup;
      group.readOnly = NO;
    }
    return group;
}

+(TightdbGroup *)groupWithBuffer:(const char *)data ofSize:(size_t)size withError:(NSError **)error
{
    tightdb::Group* coreGroup;

    try {
        coreGroup = new tightdb::Group(tightdb::BinaryData(data, size));
    } 
    catch (tightdb::InvalidDatabase &ex) {
        if(error) // allow nil as the error argument
            *error = make_tightdb_error(@"com.tightdb.sharedgroup", tdb_err_InvalidDatabase, [NSString stringWithUTF8String:ex.what()]);
        return nil;
    } 
    catch (std::exception &ex) {
        NSException *exception = [NSException exceptionWithName:@"tightdb:core_exception"
                                                         reason:[NSString stringWithUTF8String:ex.what()]
                                                       userInfo:[NSMutableDictionary dictionary]];  // IMPORTANT: cannot not be nil !!
        [exception raise];
    }

    TightdbGroup* group = [[TightdbGroup alloc] init];
    if(group) {
        group.group = coreGroup;
        group.readOnly = NO;
    }
    return group;
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

-(BOOL)writeToFile:(NSString *)filePath withError:(NSError *__autoreleasing *)error
{
    try {
        _group->write(tightdb::StringData(ObjcStringAccessor(filePath)));
    }
        // TODO: capture this in a macro or function, shared group constructor uses the same pattern.
        // Except, here, we return no instead of nil.
    catch (tightdb::File::PermissionDenied &ex) {
        if(error) // allow nil as the error argument
            *error = make_tightdb_error(@"com.tightdb.sharedgroup", tdb_err_File_PermissionDenied, [NSString stringWithUTF8String:ex.what()]);
        return NO;

    }
    catch (tightdb::File::Exists &ex) {
        if(error) // allow nil as the error argument
            *error = make_tightdb_error(@"com.tightdb.sharedgroup", tdb_err_File_Exists, [NSString stringWithUTF8String:ex.what()]);
        return NO;

    }
    catch (tightdb::File::AccessError &ex) {
        if(error) // allow nil as the error argument
            *error = make_tightdb_error(@"com.tightdb.sharedgroup", tdb_err_File_AccessError, [NSString stringWithUTF8String:ex.what()]);
        return NO;

    }
    catch (std::exception &ex) {
        if(error) // allow nil as the error argument
            *error = make_tightdb_error(@"com.tightdb.sharedgroup", tdb_err_Fail, [NSString stringWithUTF8String:ex.what()]);
        return NO;
    }

    return YES;
}

-(const char*)writeToBufferOfSize:(size_t*)size // size is an output paramater
{
    const char* returnValue = nil;

    try {
        tightdb::BinaryData buffer = _group->write_to_mem();
        *size = buffer.size();
        returnValue = buffer.data();
    }
    catch (std::exception &ex) {
        NSException *exception = [NSException exceptionWithName:@"tightdb:core_exception"
                                                         reason:[NSString stringWithUTF8String:ex.what()]
                                                       userInfo:[NSMutableDictionary dictionary]];  // IMPORTANT: cannot not be nil !!
        [exception raise];
    }

    return returnValue;
}

/*-(const char*)writeToMem:(size_t*)size error:(NSError *__autoreleasing *)error
{
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 tightdb::BinaryData buffer = _group->write_to_mem();
                                 *size = buffer.size();
                                 return buffer.data();
                                 , @"com.tightdb.group", nil);
}*/

-(BOOL)hasTable:(NSString *)name
{
    BOOL returnValue = NO;
    
    TIGHTDB_EXCEPTION_HANDLER_CORE_EXCEPTION (
                                                returnValue = _group->has_table(ObjcStringAccessor(name));
                                             )

    return returnValue;
}

// FIXME: Avoid creating a table instance. It should be enough to create an TightdbSpec and then check that.
// FIXME: Check that the specified class derives from Table.
// FIXME: Find a way to avoid having to transcode the table name twice
-(BOOL)hasTable:(NSString *)name withClass:(__unsafe_unretained Class)classObj
{
    BOOL returnValue;

    TIGHTDB_EXCEPTION_HANDLER_CORE_EXCEPTION (
                                                if (!_group->has_table(ObjcStringAccessor(name))) return NO;
                                                TightdbTable* table = [self getTable:name withClass:classObj error:nil];
                                                returnValue = table != nil;
                                             )
    return returnValue;
}

-(id)getTable:(NSString *)name error:(NSError **)error
{
    if(_readOnly) {
        // A group is readonly when it has been extracted from a shared group in a read transaction.
        // In this case, getTable should return nil for non-existing tables.
        if (![self hasTable:name]) {
            if(error) // allow nil as the error argument
                *error = make_tightdb_error(@"com.tightdb.group", tdb_err_TableNotFound, @"The table was not found. Cannot create the table in read only mode.");
            return nil;
        }
            
    }

    // If the group is NOT read only, non-existing tables will be created. 
    TightdbTable *table = [[TightdbTable alloc] _initRaw];

    TIGHTDB_EXCEPTION_HANDLER_CORE_EXCEPTION (
                                                [table setTable:_group->get_table(ObjcStringAccessor(name))];
                                             )
    [table setParent:self];
    [table setReadOnly:_readOnly];
    
    return table;
}
/*
-(id)getTable:(NSString *)name error:(NSError *__autoreleasing *)error
{
    TightdbTable *table = [[TightdbTable alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table)) return nil;
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 [table setTable:_group->get_table(ObjcStringAccessor(name))];
                                 , @"com.tightdb.group", nil);
    [table setParent:self];
    [table setReadOnly:_readOnly];
    return table;
}*/

/*-(id)getTable:(NSString *)name withClass:(__unsafe_unretained Class)classObj
{
    return [self getTable:name withClass:classObj error:nil];
}*/
// FIXME: Check that the specified class derives from Table.
-(id)getTable:(NSString *)name withClass:(__unsafe_unretained Class)classObj error:(NSError *__autoreleasing *)error
{

    if(_readOnly) {
        // A group is readonly when it has been extracted from a shared group in a read transaction.
        // In this case, getTable should return nil for non-existing tables.
        if (![self hasTable:name]) {
            if(error) // allow nil as the error argument
                *error = make_tightdb_error(@"com.tightdb.group", tdb_err_TableNotFound, @"The table was not found. Cannot create the table in read only mode.");
            return nil;
        }
            
    }

    TightdbTable *table = [[classObj alloc] _initRaw];
    bool was_created;
    
    TIGHTDB_EXCEPTION_HANDLER_CORE_EXCEPTION (
                                                [table setTable:_group->get_table(ObjcStringAccessor(name), was_created)];
                                            )

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
