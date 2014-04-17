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

#import "RLMConstants.h"
#import "RLMTable_noinst.h"
#import "RLMSmartContext_noinst.h"
#import "PrivateRLM.h"
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
- (instancetype)initWithTable:(RLMTable *)table indexInGroup:(size_t)index;
- (RLMTable *)table;
- (size_t)indexInGroup;
@end

@implementation TDBPrivateWeakTableReference
{
    __weak RLMTable *_table;
    size_t _indexInGroup;
}

- (instancetype)initWithTable:(RLMTable *)table indexInGroup:(size_t)index
{
    _table = table;
    _indexInGroup = index;
    return self;
}

- (RLMTable *)table
{
    return _table;
}

- (size_t)indexInGroup
{
    return _indexInGroup;
}

@end


@class RLMSmartContext;

@interface TDBPrivateWeakTimerTarget: NSObject
- (instancetype)initWithContext:(RLMSmartContext *)target;
- (void)timerDidFire:(NSTimer *)timer;
@end

@implementation TDBPrivateWeakTimerTarget
{
    __weak RLMSmartContext *_context;
}

- (instancetype)initWithContext:(RLMSmartContext *)context
{
    _context = context;
    return self;
}

- (void)timerDidFire:(NSTimer *)timer
{
    [_context checkForChange:timer];
}

@end


@implementation RLMSmartContext
{
    NSNotificationCenter *_notificationCenter;
    UniquePtr<SharedGroup> _sharedGroup;
    const Group *_group;
    NSTimer *_timer;
    NSMutableArray *_weakTableRefs; // Elements are instances of TDBPrivateWeakTableReference
    BOOL _tableRefsHaveDied;
}

+(RLMSmartContext *)contextWithPersistenceToFile:(NSString *)path
{
    NSRunLoop *runLoop = [NSRunLoop mainRunLoop];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    return [self contextWithPersistenceToFile:path
                                      runLoop:runLoop
                           notificationCenter:notificationCenter
                                        error:nil];
}

+(RLMSmartContext *)contextWithPersistenceToFile:(NSString *)path
                                         runLoop:(NSRunLoop *)runLoop
                              notificationCenter:(NSNotificationCenter *)notificationCenter
                                           error:(NSError **)error
{
    RLMSmartContext *context = [[RLMSmartContext alloc] init];
    if (!context)
        return nil;

    context->_notificationCenter = notificationCenter;

    TightdbErr errorCode = tdb_err_Ok;
    NSString *errorMessage;
    try {
        context->_sharedGroup.reset(new SharedGroup(StringData(ObjcStringAccessor(path))));
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
            *error = make_realm_error(errorCode, errorMessage);
        return nil;
    }

    // Register an interval timer on specified runLoop
    NSTimeInterval seconds = 0.1; // Ten times per second
    TDBPrivateWeakTimerTarget *weakTimerTarget =
        [[TDBPrivateWeakTimerTarget alloc] initWithContext:context];
    context->_timer = [NSTimer timerWithTimeInterval:seconds target:weakTimerTarget
                                            selector:@selector(timerDidFire:)
                                            userInfo:nil repeats:YES];
    [runLoop addTimer:context->_timer forMode:NSDefaultRunLoopMode];

    context->_weakTableRefs = [NSMutableArray array];

    try {
        context->_group = &context->_sharedGroup->begin_read();
    }
    catch (exception &ex) {
        throw_objc_exception(ex);
    }

    return context;
}

-(void)dealloc
{
    [_timer invalidate];
}

- (void)checkForChange:(NSTimer *)theTimer
{
    static_cast<void>(theTimer);

    // Remove dead table references from list
    if (_tableRefsHaveDied) {
        NSMutableArray *deadTableRefs = [NSMutableArray array];
        for (TDBPrivateWeakTableReference *weakTableRef in _weakTableRefs) {
            if (![weakTableRef table])
                [deadTableRefs addObject:weakTableRef];
        }
        [_weakTableRefs removeObjectsInArray:deadTableRefs];
        _tableRefsHaveDied = NO;
    }

    // Advance transaction if database has changed
    try {
        if (_sharedGroup->has_changed()) { // Throws
            _sharedGroup->end_read();
            _group = &_sharedGroup->begin_read(); // Throws

            // Revive all group level table accessors
            for (TDBPrivateWeakTableReference *weakTableRef in _weakTableRefs) {
                RLMTable *table = [weakTableRef table];
                size_t indexInGroup = [weakTableRef indexInGroup];
                ConstTableRef table_2 = _group->get_table(indexInGroup); // Throws
                // Note: Const spoofing is alright, because the
                // Objective-C table accessor is in 'read-only' mode.
                [table setNativeTable:const_cast<Table*>(table_2.get())];
            }

            [_notificationCenter postNotificationName:RLMContextDidChangeNotification object:self];
        }
    }
    catch (exception &ex) {
        throw_objc_exception(ex);
    }
}

-(RLMTable *)tableWithName:(NSString *)name
{
    ObjcStringAccessor name_2(name);
    if (!_group->has_table(name_2))
        return nil;
    RLMTable *table = [[RLMTable alloc] _initRaw];
    size_t indexInGroup;
    try {
        ConstTableRef table_2 = _group->get_table(name_2); // Throws
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
    TDBPrivateWeakTableReference *weakTableRef =
        [[TDBPrivateWeakTableReference alloc] initWithTable:table indexInGroup:indexInGroup];
    [_weakTableRefs addObject:weakTableRef];
    return table;
}

- (void)tableRefDidDie
{
    _tableRefsHaveDied = YES;
}

@end
