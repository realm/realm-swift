////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

#include <tightdb/util/unique_ptr.hpp>
#include <tightdb/group_shared.hpp>

#import "RLMContext.h"
#import "RLMRealm_noinst.h"
#import "util_noinst.hpp"

using namespace std;


@implementation RLMContext
{
    tightdb::util::UniquePtr<tightdb::SharedGroup> m_shared_group;
}

NSString *const defaultContextFileName = @"default.realm";

+(NSString *)defaultPath
{
    return [RLMContext writeablePathForFile:defaultContextFileName];
}


+(RLMContext *)contextWithDefaultPersistence
{
    NSString *path = [RLMContext writeablePathForFile:defaultContextFileName];
    return [self contextPersistedAtPath:path error:nil];
}

+ (NSString *)writeablePathForFile:(NSString*)fileName
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:fileName];
}



+(RLMContext *)contextPersistedAtPath:(NSString*)path error:(NSError**)error  // FIXME: Confirm __autoreleasing is not needed with ARC
{
    RLMContext * shared_group = [[RLMContext alloc] init];
    if (!shared_group)
        return nil;
    try {
        shared_group->m_shared_group.reset(new tightdb::SharedGroup(tightdb::StringData(ObjcStringAccessor(path))));
    }
    // TODO: capture this in a macro or function, group constructor uses the same pattern.
    catch (tightdb::util::File::PermissionDenied& ex) {
        if (error) // allow nil as the error argument
            *error = make_realm_error(RLMErrorFilePermissionDenied, [NSString stringWithUTF8String:ex.what()]);
        return nil;

    }
    catch (tightdb::util::File::Exists& ex) {
        if (error) // allow nil as the error argument
            *error = make_realm_error(RLMErrorFileExists, [NSString stringWithUTF8String:ex.what()]);
        return nil;

    }
    catch (tightdb::util::File::AccessError& ex) {
        if (error) // allow nil as the error argument
            *error = make_realm_error(RLMErrorFileAccessError, [NSString stringWithUTF8String:ex.what()]);
        return nil;

    }
    catch (std::exception& ex) {
        if (error) // allow nil as the error argument
            *error = make_realm_error(RLMErrorFail, [NSString stringWithUTF8String:ex.what()]);
        return nil;
    }
    return shared_group;
}

-(void)readUsingBlock:(RLMReadBlock)block
{
    const tightdb::Group* group;
    try {
        group = &m_shared_group->begin_read();
    }
    catch (std::exception& ex) {
        @throw [NSException exceptionWithName:@"realm:core_exception"
                                       reason:[NSString stringWithUTF8String:ex.what()]
                                     userInfo:nil];
    }

    @try {
        // No TightDB Obj-C methods used in the block
        // should throw anything but NSException or derivatives. Note: if the client calls other libraries
        // throwing other kinds of exceptions they will leak back to the client code, if he does not
        // catch them within the block.
        RLMRealm *realm = [RLMRealm realmWithNativeGroup:const_cast<tightdb::Group *>(group) isOwned:NO readOnly:YES];
        block(realm);

    }
    @finally {
        m_shared_group->end_read();
    }
}

-(void)readTable:(NSString*)tablename usingBlock:(RLMTableReadBlock)block
{
    [self readUsingBlock:^(RLMRealm *realm){
        RLMTable *table = [realm tableWithName:tablename];
        block(table);
    }];
}

-(void)writeUsingBlock:(RLMWriteBlock)block
{
    tightdb::Group* group;
    try {
        group = &m_shared_group->begin_write();
    }
    catch (std::exception& ex) {
        // File access errors are treated as exceptions here since they should not occur after the shared
        // group has already been successfully opened on the file and memory mapped. The shared group constructor handles
        // the excepted error related to file access.
        @throw [NSException exceptionWithName:@"realm:core_exception"
                                       reason:[NSString stringWithUTF8String:ex.what()]
                                     userInfo:nil];
    }

    @try {
        RLMRealm *realm = [RLMRealm realmWithNativeGroup:group isOwned:NO readOnly:NO];
        block(realm);
    }
    @catch (NSException* exception) {
        m_shared_group->rollback();
        @throw;
    }

    // Required to avoid leaking of core exceptions.
    try {
        m_shared_group->commit();
    }
    catch (std::exception& ex) {
        @throw [NSException exceptionWithName:@"realm:core_exception"
                                       reason:[NSString stringWithUTF8String:ex.what()]
                                     userInfo:nil];
    }
}


-(void)writeUsingBlockWithRollback:(RLMWriteBlockWithRollback)block
{
    tightdb::Group* group;
    try {
        group = &m_shared_group->begin_write();
    }
    catch (std::exception& ex) {
        // File access errors are treated as exceptions here since they should not occur after the shared
        // group has already been successfully opened on the file and memory mapped. The shared group constructor handles
        // the excepted error related to file access.
        @throw [NSException exceptionWithName:@"realm:core_exception"
                                       reason:[NSString stringWithUTF8String:ex.what()]
                                     userInfo:nil];
    }

    BOOL doRollback = NO;
    @try {
        RLMRealm *realm = [RLMRealm realmWithNativeGroup:group isOwned:NO readOnly:NO];
        block(realm, &doRollback);
    }
    @catch (NSException* exception) {
        m_shared_group->rollback();
        @throw;
    }

    if (!doRollback) {
        // Required to avoid leaking of core exceptions.
        try {
            m_shared_group->commit();
        }
        catch (std::exception& ex) {
            @throw [NSException exceptionWithName:@"realm:core_exception"
                                           reason:[NSString stringWithUTF8String:ex.what()]
                                         userInfo:nil];
        }
    }
    else {
        m_shared_group->rollback();
    }
}

-(void)writeTable:(NSString*)tablename usingBlock:(RLMTableWriteBlock)block
{
    [self writeUsingBlock:^(RLMRealm *realm){
        RLMTable *table = [realm tableWithName:tablename];
        block(table);
    }];
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
        @throw [NSException exceptionWithName:@"realm:core_exception"
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
        @throw [NSException exceptionWithName:@"realm:core_exception"
                                       reason:[NSString stringWithUTF8String:ex.what()]
                                     userInfo:nil];
    }
}

@end
