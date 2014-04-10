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

#include <tightdb/util/unique_ptr.hpp>
#include <tightdb/group_shared.hpp>

#import "TDBContext.h"
#import "TDBTransaction_noinst.h"
#import "util_noinst.hpp"

using namespace std;


@implementation TDBContext
{
    tightdb::util::UniquePtr<tightdb::SharedGroup> m_shared_group;
}

NSString *const defaultContextFileName = @"default.tightdb";

+(NSString *)defaultPath
{
    return [TDBContext writeablePathForFile:defaultContextFileName];
}


+(TDBContext *)contextWithDefaultPersistence
{
    NSString *path = [TDBContext writeablePathForFile:defaultContextFileName];
    return [self contextPersistedAtPath:path error:nil];
}

+ (NSString *)writeablePathForFile:(NSString*)fileName
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:fileName];
}



+(TDBContext*)contextPersistedAtPath:(NSString*)path error:(NSError**)error  // FIXME: Confirm __autoreleasing is not needed with ARC
{
    TDBContext* shared_group = [[TDBContext alloc] init];
    if (!shared_group)
        return nil;
    try {
        shared_group->m_shared_group.reset(new tightdb::SharedGroup(tightdb::StringData(ObjcStringAccessor(path))));
    }
    // TODO: capture this in a macro or function, group constructor uses the same pattern.
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
    return shared_group;
}

-(void)dealloc
{
#ifdef TIGHTDB_DEBUG
    // NSLog(@"TDBSharedGroup dealloc");
#endif
}

-(void)readUsingBlock:(TDBReadBlock)block
{
    const tightdb::Group* group;
    try {
        group = &m_shared_group->begin_read();
    }
    catch (std::exception& ex) {
        @throw [NSException exceptionWithName:@"tightdb:core_exception"
                                       reason:[NSString stringWithUTF8String:ex.what()]
                                     userInfo:nil];
    }

    @try {
        // No TightDB Obj-C methods used in the block
        // should throw anything but NSException or derivatives. Note: if the client calls other libraries
        // throwing other kinds of exceptions they will leak back to the client code, if he does not
        // catch them within the block.
        TDBTransaction* group_2 = [TDBTransaction groupWithNativeGroup:const_cast<tightdb::Group*>(group) isOwned:NO readOnly:YES];
        block(group_2);

    }
    @finally {
        m_shared_group->end_read();
    }
}

-(void)readTable:(NSString*)tablename usingBlock:(TDBTableReadBlock)block
{
    [self readUsingBlock:^(TDBTransaction *trx){
        TDBTable *table = [trx tableWithName:tablename];
        block(table);
    }];
}


-(BOOL)writeUsingBlock:(TDBWriteBlock)block error:(NSError**)error
{
    tightdb::Group* group;
    try {
        group = &m_shared_group->begin_write();
    }
    catch (std::exception& ex) {
        // File access errors are treated as exceptions here since they should not occur after the shared
        // group has already beenn successfully opened on the file and memeory mapped. The shared group constructor handles
        // the excepted error related to file access.
        @throw [NSException exceptionWithName:@"tightdb:core_exception"
                                       reason:[NSString stringWithUTF8String:ex.what()]
                                     userInfo:nil];
    }

    BOOL confirmation = NO;
    @try {
        TDBTransaction* group_2 = [TDBTransaction groupWithNativeGroup:group isOwned:NO readOnly:NO];
        confirmation = block(group_2);
    }
    @catch (NSException* exception) {
        m_shared_group->rollback();
        @throw;
    }

    if (confirmation) {
        // Required to avoid leaking of core exceptions.
        try {
            m_shared_group->commit();
        }
        catch (std::exception& ex) {
            @throw [NSException exceptionWithName:@"tightdb:core_exception"
                                           reason:[NSString stringWithUTF8String:ex.what()]
                                         userInfo:nil];
        }
        return YES;
    }

    // As of now the only kind of error is when the block decides to rollback.
    // In the future, other kinds may be relevant (network error etc)..
    // It could be discussed if rollback is an error at all. But, if the method is
    // returning NO it makes sense the user can check the error an see that it
    // was caused by a decision of the block to roll back.

    if (error) // allow nil as the error argument
        *error = make_tightdb_error(tdb_err_Rollback, @"The block code requested a rollback");

    m_shared_group->rollback();
    return NO;
}

-(BOOL)writeTable:(NSString*)tablename usingBlock:(TDBTableWriteBlock)block error:(NSError **)error
{
    return [self writeUsingBlock:^(TDBTransaction *trx){
        TDBTable *table = [trx tableWithName:tablename];
        return block(table);
    } error: error];
}

-(BOOL) hasChangedSinceLastTransaction
{
    return m_shared_group->has_changed();
}


-(BOOL)pinReadTransactions
{
    try {
        return m_shared_group->pin_read_transactions();
    }
    catch(std::exception& ex) { 
        @throw [NSException exceptionWithName:@"tightdb:core_exception"
                                       reason:[NSString stringWithUTF8String:ex.what()]
                                     userInfo:nil];
    }
}

-(void)unpinReadTransactions
{
    try {
        m_shared_group->unpin_read_transactions();
    }
    catch(std::exception& ex) {
        @throw [NSException exceptionWithName:@"tightdb:core_exception"
                                       reason:[NSString stringWithUTF8String:ex.what()]
                                     userInfo:nil];
    }
}

@end
