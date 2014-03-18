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


@implementation TDBTransaction
{
    tightdb::Group* m_group;
    BOOL m_is_owned;
    BOOL m_read_only;
}


+(TDBTransaction*)group
{
    TDBTransaction* group = [[TDBTransaction alloc] init];
    try {
        group->m_group = new tightdb::Group;
    }
    catch (std::exception& ex) {
        NSException *exception = [NSException exceptionWithName:@"tightdb:core_exception"
                                                         reason:[NSString stringWithUTF8String:ex.what()]
                                                       userInfo:[NSMutableDictionary dictionary]];  // IMPORTANT: cannot not be nil !!
        [exception raise];
    }
    group->m_is_owned  = YES;
    group->m_read_only = NO;
    return group;
}


// Private.
// Careful with this one - Remember that group will be deleted on dealloc.
+(TDBTransaction*)groupWithNativeGroup:(tightdb::Group*)group isOwned:(BOOL)is_owned readOnly:(BOOL)read_only
{
    TDBTransaction* group_2 = [[TDBTransaction alloc] init];
    group_2->m_group = group;
    group_2->m_is_owned  = is_owned;
    group_2->m_read_only = read_only;
    return group_2;
}


+(TDBTransaction *)groupWithFile:(NSString *)filename withError:(NSError **)error
{
    TDBTransaction* group = [[TDBTransaction alloc] init];
    if (!group)
        return nil;
    try {
        group->m_group = new tightdb::Group(tightdb::StringData(ObjcStringAccessor(filename)));
    }
    // TODO: capture this in a macro or function, shared group constructor uses the same pattern.
    catch (tightdb::util::File::PermissionDenied& ex) {
        if (error) // allow nil as the error argument
            *error = make_tightdb_error(tdb_err_File_PermissionDenied, [NSString stringWithUTF8String:ex.what()]);
        return nil;

    }
    catch (tightdb::util::File::Exists& ex) {
        if(error) // allow nil as the error argument
            *error = make_tightdb_error(tdb_err_File_Exists, [NSString stringWithUTF8String:ex.what()]);
        return nil;

    }
    catch (tightdb::util::File::AccessError& ex) {
        if (error) // allow nil as the error argument
            *error = make_tightdb_error(tdb_err_File_AccessError, [NSString stringWithUTF8String:ex.what()]);
        return nil;

    }
    catch (std::exception& ex) {
        if (error) // allow nil as the error argument
            *error = make_tightdb_error(tdb_err_Fail, [NSString stringWithUTF8String:ex.what()]);
        return nil;
    }
    group->m_is_owned  = YES;
    group->m_read_only = NO;
    return group;
}


+(TDBTransaction*)groupWithBuffer:(TDBBinary*)buffer withError:(NSError**)error
{
    TDBTransaction* group = [[TDBTransaction alloc] init];
    if (!group)
        return nil;
    try {
        const tightdb::BinaryData& buffer_2 = [buffer getNativeBinary];
        bool take_ownership = true;
        group->m_group = new tightdb::Group(buffer_2, take_ownership);
    }
    catch (tightdb::InvalidDatabase& ex) {
        if (error) // allow nil as the error argument
            *error = make_tightdb_error(tdb_err_InvalidDatabase, [NSString stringWithUTF8String:ex.what()]);
        return nil;
    }
    catch (std::exception& ex) {
        NSException *exception = [NSException exceptionWithName:@"tightdb:core_exception"
                                                         reason:[NSString stringWithUTF8String:ex.what()]
                                                       userInfo:[NSMutableDictionary dictionary]];  // IMPORTANT: cannot not be nil !!
        [exception raise];
    }
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


-(NSUInteger)getTableCount
{
    return m_group->size();
}
-(NSString*)getTableName:(NSUInteger)table_ndx
{
    return to_objc_string(m_group->get_table_name(table_ndx));
}


-(BOOL)writeToFile:(NSString*)path withError:(NSError* __autoreleasing*)error
{
    try {
        m_group->write(tightdb::StringData(ObjcStringAccessor(path)));
    }
        // TODO: capture this in a macro or function, shared group constructor uses the same pattern.
        // Except, here, we return no instead of nil.
    catch (tightdb::util::File::PermissionDenied& ex) {
        if (error) // allow nil as the error argument
            *error = make_tightdb_error(tdb_err_File_PermissionDenied, [NSString stringWithUTF8String:ex.what()]);
        return NO;

    }
    catch (tightdb::util::File::Exists& ex) {
        if (error) // allow nil as the error argument
            *error = make_tightdb_error(tdb_err_File_Exists, [NSString stringWithUTF8String:ex.what()]);
        return NO;

    }
    catch (tightdb::util::File::AccessError& ex) {
        if (error) // allow nil as the error argument
            *error = make_tightdb_error(tdb_err_File_AccessError, [NSString stringWithUTF8String:ex.what()]);
        return NO;

    }
    catch (std::exception& ex) {
        if (error) // allow nil as the error argument
            *error = make_tightdb_error(tdb_err_Fail, [NSString stringWithUTF8String:ex.what()]);
        return NO;
    }
    return YES;
}


-(TDBBinary*)writeToBuffer
{
    TDBBinary* buffer = [[TDBBinary alloc] init];
    if (!buffer)
        return nil;
    try {
        [buffer getNativeBinary] = m_group->write_to_mem();
    }
    catch (std::exception& ex) {
        NSException *exception = [NSException exceptionWithName:@"tightdb:core_exception"
                                                         reason:[NSString stringWithUTF8String:ex.what()]
                                                       userInfo:[NSMutableDictionary dictionary]];  // IMPORTANT: cannot not be nil !!
        [exception raise];
    }
    return buffer;
}

-(TDBTable *)getTableWithName:(NSString *)name
{
    if ([self hasTableWithName:name]) {
        return [self getOrCreateTableWithName:name];
    }
    
    return nil;
}


-(BOOL)hasTableWithName:(NSString*)name
{
    return m_group->has_table(ObjcStringAccessor(name));
}

// FIXME: Avoid creating a table instance. It should be enough to create an TightdbDescriptor and then check that.
// FIXME: Check that the specified class derives from Table.
// FIXME: Find a way to avoid having to transcode the table name twice
-(BOOL)hasTableWithName:(NSString *)name withTableClass:(__unsafe_unretained Class)class_obj
{
    if (!m_group->has_table(ObjcStringAccessor(name)))
        return NO;
    TDBTable* table = [self getOrCreateTableWithName:name asTableClass:class_obj];
    return table != nil;
}

-(id)getOrCreateTableWithName:(NSString*)name
{
    // FIXME: Read-only errors should probably be handled by throwing
    // an exception. That is what is done in other places in this
    // binding, and it also seems like the right thing to do. This
    // method should also not take an error argument.
    if (m_read_only) {
        // A group is readonly when it has been extracted from a shared group in a read transaction.
        // In this case, getTable should return nil for non-existing tables.
        if (![self hasTableWithName:name]) {
            return nil;
        }
    }

    TDBTable* table = [[TDBTable alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table))
        return nil;
    TIGHTDB_EXCEPTION_HANDLER_CORE_EXCEPTION(
        tightdb::TableRef table_2 = m_group->get_table(ObjcStringAccessor(name));
        [table setNativeTable:table_2.get()];)
    [table setParent:self];
    [table setReadOnly:m_read_only];
    return table;
}

// FIXME: Check that the specified class derives from Table.
-(id)getOrCreateTableWithName:(NSString*)name asTableClass:(__unsafe_unretained Class)class_obj
{
    // FIXME: Read-only errors should probably be handled by throwing
    // an exception. That is what is done in other places in this
    // binding, and it also seems like the right thing to do. This
    // method should also not take an error argument.
    if (m_read_only) {
        // A group is readonly when it has been extracted from a shared group in a read transaction.
        // In this case, getTable should return nil for non-existing tables.
        if (![self hasTableWithName:name]) {
            return nil;
        }
    }

    TDBTable* table = [[class_obj alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table))
        return nil;
    bool was_created;
    TIGHTDB_EXCEPTION_HANDLER_CORE_EXCEPTION(
        tightdb::TableRef table_2 = m_group->get_table(ObjcStringAccessor(name), was_created);
        [table setNativeTable:table_2.get()];)
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
