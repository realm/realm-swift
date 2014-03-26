/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2014] TightDB Inc
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of TightDB Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to TightDB Incorporated
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from TightDB Incorporated.
 *
 **************************************************************************/

#include <tightdb/group.hpp>
#include <tightdb/lang_bind_helper.hpp>

#import <tightdb/objc/TDBTransaction.h>
#import <tightdb/objc/TDBTransaction_noinst.h>
#import <tightdb/objc/TDBTable.h>
#import <tightdb/objc/TDBTable_noinst.h>
#import "PrivateTDB.h"

#include <tightdb/objc/util.hpp>

using namespace std;


@implementation TDBTransaction
{
    tightdb::Group* m_group;
    BOOL m_is_owned;
    BOOL m_read_only;
}


-(void)dealloc
{
#ifdef TIGHTDB_DEBUG
    NSLog(@"TightdbGroup dealloc");
#endif
    if (m_is_owned)
        delete m_group;
}


-(NSUInteger)tableCount // Overrides the property getter
{
    return m_group->size();
}

-(BOOL)hasTableWithName:(NSString*)name
{
    return m_group->has_table(ObjcStringAccessor(name));
}

-(TDBTable *)tableWithName:(NSString *)name
{
    if ([name length] == 0) {
        NSException *exception = [NSException exceptionWithName:@"tightdb:table_name_exception"
                                                         reason:@"Name must be a non-empty NSString"
                                                       userInfo:[NSMutableDictionary dictionary]];
        [exception raise];
    }
    
    // If table does not exist in context, return nil
    if (![self hasTableWithName:name]) {
        return nil;
    } else {
        // Otherwise
        TDBTable* table = [[TDBTable alloc] _initRaw];
        if (TIGHTDB_UNLIKELY(!table))
            return nil;
        TIGHTDB_EXCEPTION_HANDLER_CORE_EXCEPTION(
            tightdb::TableRef table_2 = m_group->get_table(ObjcStringAccessor(name));
            [table setNativeTable:table_2.get()];
        )
        [table setParent:self];
        [table setReadOnly:m_read_only];
        return table;
    }
}

-(id)tableWithName:(NSString *)name asTableClass:(__unsafe_unretained Class)class_obj
{
    if ([name length] == 0) {
        NSException *exception = [NSException exceptionWithName:@"tightdb:table_name_exception"
                                                         reason:@"Name must be a non-empty NSString"
                                                       userInfo:[NSMutableDictionary dictionary]];
        [exception raise];
    }
    
    // If table does not exist in context, return nil
    if (![self hasTableWithName:name]) {
        return nil;
    } else {
        TDBTable* table = [[class_obj alloc] _initRaw];
        if (TIGHTDB_UNLIKELY(!table))
            return nil;
        bool was_created;
        TIGHTDB_EXCEPTION_HANDLER_CORE_EXCEPTION(
            tightdb::TableRef table_2 = m_group->get_table(ObjcStringAccessor(name), was_created);
            [table setNativeTable:table_2.get()];
        )
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
}

// FIXME: Avoid creating a table instance. It should be enough to create an TightdbDescriptor and then check that.
// FIXME: Check that the specified class derives from Table.
// FIXME: Find a way to avoid having to transcode the table name twice
-(BOOL)hasTableWithName:(NSString *)name withTableClass:(__unsafe_unretained Class)class_obj
{
    if (!m_group->has_table(ObjcStringAccessor(name)))
        return NO;
    TDBTable* table = [self createTableWithName:name asTableClass:class_obj];
    return table != nil;
}

-(TDBTable *)createTableWithName:(NSString*)name
{
    if ([name length] == 0) {
        NSException *exception = [NSException exceptionWithName:@"tightdb:table_name_exception"
                                                         reason:@"Name must be a non-empty NSString"
                                                       userInfo:[NSMutableDictionary dictionary]];
        [exception raise];
    }
    
    if (m_read_only) {
        NSException *exception = [NSException exceptionWithName:@"tightdb:core_read_only_exception"
                                                         reason:@"Transaction is read-only."
                                                       userInfo:[NSMutableDictionary dictionary]];
        [exception raise];
    }
    
    if ([self hasTableWithName:name]) {
        NSException* exception = [NSException exceptionWithName:@"tightdb:table_with_name_already_exists"
                                                         reason:[NSString stringWithFormat:@"A table with the name '%@' already exists in the context.", name]
                                                       userInfo:[NSMutableDictionary dictionary]];
        [exception raise];
    }

    TDBTable* table = [[TDBTable alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table))
        return nil;
    TIGHTDB_EXCEPTION_HANDLER_CORE_EXCEPTION(
        tightdb::TableRef table_2 = m_group->get_table(ObjcStringAccessor(name));
        [table setNativeTable:table_2.get()];
    )
    [table setParent:self];
    [table setReadOnly:m_read_only];
    return table;
}

// FIXME: Check that the specified class derives from Table.
-(id)createTableWithName:(NSString*)name asTableClass:(__unsafe_unretained Class)class_obj
{
    if ([name length] == 0) {
        NSException *exception = [NSException exceptionWithName:@"tightdb:table_name_exception"
                                                         reason:@"Name must be a non-empty NSString"
                                                       userInfo:[NSMutableDictionary dictionary]];
        [exception raise];
    }
    
    if (m_read_only) {
        NSException *exception = [NSException exceptionWithName:@"tightdb:core_read_only_exception"
                                                         reason:@"Transaction is read-only."
                                                       userInfo:[NSMutableDictionary dictionary]];
        [exception raise];
    }
    
    if ([self hasTableWithName:name]) {
        NSException* exception = [NSException exceptionWithName:@"tightdb:table_with_name_already_exists"
                                                         reason:[NSString stringWithFormat:@"A table with the name '%@' already exists in the context.", name]
                                                       userInfo:[NSMutableDictionary dictionary]];
        [exception raise];
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

/* Moved to group_priv header for now */
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

/* Moved to group_priv header for now */
+(TDBTransaction *)groupWithFile:(NSString *)filename error:(NSError **)error
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
        if (error) // allow nil as the error argument
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

/* Moved to group_priv header for now */
+(TDBTransaction*)groupWithBuffer:(NSData*)buffer error:(NSError**)error
{
    TDBTransaction* group = [[TDBTransaction alloc] init];
    if (!group)
        return nil;
    try {
        const void *data = [(NSData *)buffer bytes];
        tightdb::BinaryData buffer_2(static_cast<const char *>(data), [(NSData *)buffer length]);
        bool take_ownership = false; // FIXME: should this be true?
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

-(NSString*)nameOfTableWithIndex:(NSUInteger)table_ndx
{
    return to_objc_string(m_group->get_table_name(table_ndx));
}

/* Moved to group_priv header for now */
-(BOOL)writeContextToFile:(NSString*)path error:(NSError* __autoreleasing*)error
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

/* Moved to group_priv header for now */
-(NSData*)writeContextToBuffer
{
    try {
        tightdb::BinaryData bd = m_group->write_to_mem();
        return [[NSData alloc] initWithBytes:static_cast<const void *>(bd.data()) length:bd.size()];
    }
    catch (std::exception& ex) {
        NSException *exception = [NSException exceptionWithName:@"tightdb:core_exception"
                                                         reason:[NSString stringWithUTF8String:ex.what()]
                                                       userInfo:[NSMutableDictionary dictionary]];  // IMPORTANT: cannot not be nil !!
        [exception raise];
    }
    return nil;
}

@end
