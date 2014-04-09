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

#include <exception>

#include <tightdb/util/unique_ptr.hpp>
#include <tightdb/group_shared.hpp>

#import "TDBConstants.h"
#import "TDBTable_noinst.h"
#import "TDBSmartContext_noinst.h"
#import "PrivateTDB.h"
#import "util_noinst.hpp"

using namespace std;
using namespace tightdb;
using namespace tightdb::util;


namespace {

void throw_objc_exception(exception &ex)
{
    NSString *errorMessage = [NSString stringWithUTF8String:ex.what()];
    @throw [NSException exceptionWithName:@"TDBException" reason:errorMessage userInfo:nil];
}

} // anonymous namespace


@interface TDBPrivateWeakTableReference: NSObject
- (instancetype)initWithTable:(TDBTable *)table indexInGroup:(size_t)index;
- (TDBTable *)table;
- (size_t)indexInGroup;
@end

@implementation TDBPrivateWeakTableReference
{
    __weak TDBTable *table;
    size_t indexInGroup;
}

- (instancetype)initWithTable:(TDBTable *)aTable indexInGroup:(size_t)anIndex
{
    table = aTable;
    indexInGroup = anIndex;
    return self;
}

- (TDBTable *)table
{
    return table;
}

- (size_t)indexInGroup
{
    return indexInGroup;
}

@end


@class TDBSmartContext;

@interface TDBPrivateWeakTimerTarget: NSObject
- (instancetype)initWithContext:(TDBSmartContext *)target;
- (void)timerDidFire:(NSTimer *)timer;
@end

@implementation TDBPrivateWeakTimerTarget
{
    __weak TDBSmartContext *context;
}

- (instancetype)initWithContext:(TDBSmartContext *)aContext
{
    context = aContext;
    return self;
}

- (void)timerDidFire:(NSTimer *)timer
{
    [context checkForChange:timer];
}

@end


@implementation TDBSmartContext
{
    NSNotificationCenter *notificationCenter;
    UniquePtr<SharedGroup> sharedGroup;
    const Group *group;
    NSTimer *timer;
    NSMutableArray *tables; // Elements are instances of TDBPrivateWeakTableReference
    BOOL tableRefsHaveDied;
}

+(TDBSmartContext *)contextWithPersistenceToFile:(NSString *)path
{
    NSRunLoop *runLoop = [NSRunLoop mainRunLoop];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    return [self contextWithPersistenceToFile:path
                                      runLoop:runLoop
                           notificationCenter:notificationCenter
                                        error:nil];
}

+(TDBSmartContext *)contextWithPersistenceToFile:(NSString *)path
                                         runLoop:(NSRunLoop *)runLoop
                              notificationCenter:(NSNotificationCenter *)notificationCenter
                                           error:(NSError **)error
{
    TDBSmartContext *context = [[TDBSmartContext alloc] init];
    if (!context)
        return nil;

    context->notificationCenter = notificationCenter;

    TightdbErr errorCode = tdb_err_Ok;
    NSString *errorMessage;
    try {
        context->sharedGroup.reset(new SharedGroup(StringData(ObjcStringAccessor(path))));
    }
    catch (File::PermissionDenied &ex) {
        errorCode    = tdb_err_File_PermissionDenied;
        errorMessage = [NSString stringWithUTF8String:ex.what()];
    }
    catch (File::Exists &ex) {
        errorCode    = tdb_err_File_Exists;
        errorMessage = [NSString stringWithUTF8String:ex.what()];
    }
    catch (File::AccessError &ex) {
        errorCode    = tdb_err_File_AccessError;
        errorMessage = [NSString stringWithUTF8String:ex.what()];
    }
    catch (exception &ex) {
        errorCode    = tdb_err_Fail;
        errorMessage = [NSString stringWithUTF8String:ex.what()];
    }
    if (errorCode != tdb_err_Ok) {
        if (error)
            *error = make_tightdb_error(errorCode, errorMessage);
        return nil;
    }

    // Register an interval timer on specified runLoop
    NSTimeInterval seconds = 0.1; // Ten times per second
    TDBPrivateWeakTimerTarget *weakTimerTarget =
        [[TDBPrivateWeakTimerTarget alloc] initWithContext:context];
    context->timer = [NSTimer timerWithTimeInterval:seconds target:weakTimerTarget
                                           selector:@selector(timerDidFire:)
                                           userInfo:nil repeats:YES];
    [runLoop addTimer:context->timer forMode:NSDefaultRunLoopMode];

    context->tables = [NSMutableArray array];

    try {
        context->group = &context->sharedGroup->begin_read();
    }
    catch (exception &ex) {
        throw_objc_exception(ex);
    }

    return context;
}

-(void)dealloc
{
    [timer invalidate];
}

- (void)checkForChange:(NSTimer *)theTimer
{
    static_cast<void>(theTimer);

    // Remove dead table references from list
    if (tableRefsHaveDied) {
        NSMutableArray *deadTables = [NSMutableArray array];
        for (TDBPrivateWeakTableReference *weakTableReference in tables) {
            if (![weakTableReference table])
                [deadTables addObject:weakTableReference];
        }
        [tables removeObjectsInArray:deadTables];
        tableRefsHaveDied = NO;
    }

    // Advance transaction if database has changed
    try {
        if (sharedGroup->has_changed()) { // Throws
            sharedGroup->end_read();
            group = &sharedGroup->begin_read(); // Throws

            // Revive all group level table accessors
            for (TDBPrivateWeakTableReference *weakTableReference in tables) {
                TDBTable *table = [weakTableReference table];
                size_t indexInGroup = [weakTableReference indexInGroup];
                ConstTableRef table_2 = group->get_table(indexInGroup); // Throws
                // Note: Const spoofing is alright, because the
                // Objective-C table accessor is in 'read-only' mode.
                [table setNativeTable:const_cast<Table*>(table_2.get())];
            }

            [notificationCenter postNotificationName:TDBContextDidChangeNotification object:self];
        }
    }
    catch (exception &ex) {
        throw_objc_exception(ex);
    }
}

-(TDBTable *)tableWithName:(NSString *)name
{
    ObjcStringAccessor name_2(name);
    if (!group->has_table(name_2))
        return nil;
    TDBTable *table = [[TDBTable alloc] _initRaw];
    size_t indexInGroup;
    try {
        ConstTableRef table_2 = group->get_table(name_2); // Throws
        // Note: Const spoofing is alright, because the
        // Objective-C table accessor is in 'read-only' mode.
        [table setNativeTable:const_cast<Table*>(table_2.get())];
        indexInGroup = table_2->get_index_in_parent();
    }
    catch (exception &ex) {
        throw_objc_exception(ex);
    }
    [table setParent:self];
    [table setReadOnly:YES];
    TDBPrivateWeakTableReference *weakTableReference =
        [[TDBPrivateWeakTableReference alloc] initWithTable:table indexInGroup:indexInGroup];
    [tables addObject:weakTableReference];
    return table;
}

- (void)tableRefDidDie
{
    tableRefsHaveDied = YES;
}

@end
