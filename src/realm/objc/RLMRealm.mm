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
#include <tightdb/group.hpp>
#include <tightdb/lang_bind_helper.hpp>

#import "RLMConstants.h"
#import "RLMTable_noinst.h"
#import "RLMRealm_noinst.h"
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


@interface RLMPrivateWeakTableReference: NSObject

- (instancetype)initWithTable:(RLMTable *)table indexInRealm:(size_t)index;
- (RLMTable *)table;
- (size_t)indexInRealm;

@end

@implementation RLMPrivateWeakTableReference
{
    __weak RLMTable *_table;
    size_t _indexInRealm;
}

- (instancetype)initWithTable:(RLMTable *)table indexInRealm:(size_t)index
{
    _table = table;
    _indexInRealm = index;
    return self;
}

- (RLMTable *)table
{
    return _table;
}

- (size_t)indexInRealm
{
    return _indexInRealm;
}

@end


@class RLMRealm;

@interface RLMPrivateWeakTimerTarget : NSObject

- (instancetype)initWithRealm:(RLMRealm *)realm;
- (void)timerDidFire:(NSTimer *)timer;

@end

@implementation RLMPrivateWeakTimerTarget
{
    __weak RLMRealm *_realm;
}

- (instancetype)initWithRealm:(RLMRealm *)realm
{
    self = [super init];
    if (self) {
        _realm = realm;
    }
    return self;
}

- (void)timerDidFire:(NSTimer *)timer
{
    [_realm checkForChange:timer];
}

@end

@implementation RLMRealm
{
    NSNotificationCenter *_notificationCenter;
    UniquePtr<SharedGroup> _sharedGroup;
    NSTimer *_timer;
    NSMutableArray *_weakTableRefs; // Elements are instances of RLMPrivateWeakTableReference
    BOOL _tableRefsHaveDied;
    BOOL _usesImplicitTransactions;
    
    tightdb::Group *_group;
    BOOL m_is_owned;
    BOOL m_read_only;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _usesImplicitTransactions = NO;
        m_read_only = NO;
    }
    return self;
}

- (instancetype)initForImplicitTransactions:(BOOL)usesImplicitTransactions
{
    self = [super init];
    if (self) {
        _usesImplicitTransactions = usesImplicitTransactions;
        m_read_only = YES;
    }
    return self;
}

+ (instancetype)realmWithDefaultPersistence
{
    return [RLMRealm realmWithPersistenceToFile:[RLMContext defaultPath]];
}

+ (instancetype)realmWithPersistenceToFile:(NSString *)path
{
    // This constructor can only be called from the main thread
    if (![NSThread isMainThread]) {
        @throw [NSException exceptionWithName:@"realm:runloop_exception"
                                       reason:[NSString stringWithFormat:@"%@ \
                                               can only be called from the main thread",
                                               NSStringFromSelector(_cmd)]
                                     userInfo:nil];
    }
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    return [self realmWithPersistenceToFile:path
                                    runLoop:[NSRunLoop mainRunLoop]
                         notificationCenter:notificationCenter
                                      error:nil];
}

+ (instancetype)realmWithPersistenceToFile:(NSString *)path
                                   runLoop:(NSRunLoop *)runLoop
                        notificationCenter:(NSNotificationCenter *)notificationCenter
                                     error:(NSError **)error
{
    RLMRealm *realm = [[RLMRealm alloc] initForImplicitTransactions:YES];
    if (!realm) {
        return nil;
    }

    realm->_notificationCenter = notificationCenter;

    RLMError errorCode = RLMErrorOk;
    NSString *errorMessage;
    try {
        realm->_sharedGroup.reset(new SharedGroup(StringData(ObjcStringAccessor(path))));
    }
    catch (File::PermissionDenied &ex) {
        errorCode    = RLMErrorFilePermissionDenied;
        errorMessage = [NSString stringWithUTF8String:ex.what()];
    }
    catch (File::Exists &ex) {
        errorCode    = RLMErrorFileExists;
        errorMessage = [NSString stringWithUTF8String:ex.what()];
    }
    catch (File::AccessError &ex) {
        errorCode    = RLMErrorFileAccessError;
        errorMessage = [NSString stringWithUTF8String:ex.what()];
    }
    catch (exception &ex) {
        errorCode    = RLMErrorFail;
        errorMessage = [NSString stringWithUTF8String:ex.what()];
    }
    if (errorCode != RLMErrorOk) {
        if (error) {
            *error = make_realm_error(errorCode, errorMessage);
        }
        return nil;
    }

    // Register an interval timer on specified runLoop
    NSTimeInterval seconds = 0.1; // Ten times per second
    RLMPrivateWeakTimerTarget *weakTimerTarget = [[RLMPrivateWeakTimerTarget alloc] initWithRealm:realm];
    realm->_timer = [NSTimer timerWithTimeInterval:seconds target:weakTimerTarget
                                          selector:@selector(timerDidFire:)
                                          userInfo:nil repeats:YES];
    [runLoop addTimer:realm->_timer forMode:NSDefaultRunLoopMode];

    realm->_weakTableRefs = [NSMutableArray array];

    try {
        realm->_group = (tightdb::Group *)&realm->_sharedGroup->begin_read();
    }
    catch (exception &ex) {
        throw_objc_exception(ex);
    }

    return realm;
}

- (void)dealloc
{
    [_timer invalidate];
    if (m_is_owned) {
        delete _group;
    }
}

- (void)checkForChange:(NSTimer *)theTimer
{
    static_cast<void>(theTimer);

    // Remove dead table references from list
    if (_tableRefsHaveDied) {
        NSMutableArray *deadTableRefs = [NSMutableArray array];
        for (RLMPrivateWeakTableReference *weakTableRef in _weakTableRefs) {
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
            _group = (tightdb::Group *)&_sharedGroup->begin_read(); // Throws

            // Revive all realm level table accessors
            for (RLMPrivateWeakTableReference *weakTableRef in _weakTableRefs) {
                RLMTable *table = [weakTableRef table];
                size_t indexInRealm = [weakTableRef indexInRealm];
                ConstTableRef tableRef = _group->get_table(indexInRealm); // Throws
                // Note: Const spoofing is alright, because the
                // Objective-C table accessor is in 'read-only' mode.
                [table setNativeTable:const_cast<Table*>(tableRef.get())];
            }

            [_notificationCenter postNotificationName:RLMContextDidChangeNotification object:self];
        }
    }
    catch (exception &ex) {
        throw_objc_exception(ex);
    }
}

- (RLMTable *)tableWithName:(NSString *)name
{
    if ([name length] == 0) {
        // FIXME: Exception name must be `TDBException` according to
        // the exception naming conventions of the official Cocoa
        // style guide. The same is true for most (if not all) of the
        // exceptions we throw.
        @throw [NSException exceptionWithName:@"realm:table_name_exception"
                                       reason:@"Name must be a non-empty NSString"
                                     userInfo:nil];
    }
    ObjcStringAccessor nameRef(name);
    if (!_group->has_table(nameRef)) {
        return nil;
    }
    RLMTable *table = [[RLMTable alloc] _initRaw];
    size_t indexInRealm;
    try {
        ConstTableRef tableRef = _group->get_table(nameRef); // Throws
        // Note: Const spoofing is alright, because the
        // Objective-C table accessor is in 'read-only' mode.
        [table setNativeTable:const_cast<Table*>(tableRef.get())];
        indexInRealm = tableRef->get_index_in_parent();
    }
    catch (exception &ex) {
        throw_objc_exception(ex);
    }
    [table setParent:self];
    [table setReadOnly:m_read_only];
    if (_usesImplicitTransactions) {
        [table setReadOnly:YES];
        RLMPrivateWeakTableReference *weakTableRef = [[RLMPrivateWeakTableReference alloc] initWithTable:table
                                                                                            indexInRealm:indexInRealm];
        [_weakTableRefs addObject:weakTableRef];
    }
    return table;
}

- (void)tableRefDidDie
{
    _tableRefsHaveDied = YES;
}


-(NSUInteger)tableCount // Overrides the property getter
{
    return _group->size();
}

-(BOOL)isEmpty // Overrides the property getter
{
    return self.tableCount == 0;
}

-(BOOL)hasTableWithName:(NSString*)name
{
    return _group->has_table(ObjcStringAccessor(name));
}

- (id)tableWithName:(NSString *)name asTableClass:(__unsafe_unretained Class)class_obj
{
    ObjcStringAccessor nameRef(name);
    if (!_group->has_table(nameRef)) {
        return nil;
    }
    RLMTable *table = [[class_obj alloc] _initRaw];
    size_t indexInRealm;
    try {
        ConstTableRef tableRef = _group->get_table(nameRef); // Throws
        // Note: Const spoofing is alright, because the
        // Objective-C table accessor is in 'read-only' mode.
        [table setNativeTable:const_cast<Table*>(tableRef.get())];
        indexInRealm = tableRef->get_index_in_parent();
    }
    catch (exception &ex) {
        throw_objc_exception(ex);
    }
    [table setParent:self];
    [table setReadOnly:m_read_only];
    if (_usesImplicitTransactions) {
        [table setReadOnly:YES];
        RLMPrivateWeakTableReference *weakTableRef = [[RLMPrivateWeakTableReference alloc] initWithTable:table
                                                                                            indexInRealm:indexInRealm];
        [_weakTableRefs addObject:weakTableRef];
    }
    return table;
}

-(BOOL)hasTableWithName:(NSString *)name withTableClass:(__unsafe_unretained Class)class_obj
{
    if (!_group->has_table(ObjcStringAccessor(name))) {
        return NO;
    }
    RLMTable *table = [self tableWithName:name asTableClass:class_obj];
    return table != nil;
}

-(RLMTable *)createTableWithName:(NSString*)name
{
    if ([name length] == 0) {
        @throw [NSException exceptionWithName:@"realm:table_name_exception"
                                       reason:@"Name must be a non-empty NSString"
                                     userInfo:nil];
    }
    
    if (m_read_only) {
        @throw [NSException exceptionWithName:@"realm:core_read_only_exception"
                                       reason:@"Realm is read-only."
                                     userInfo:nil];
    }
    
    if ([self hasTableWithName:name]) {
        @throw [NSException exceptionWithName:@"realm:table_with_name_already_exists"
                                       reason:[NSString stringWithFormat:@"A table with the name '%@' already exists in the context.", name]
                                     userInfo:nil];
    }
    
    RLMTable * table = [[RLMTable alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table))
        return nil;
    REALM_EXCEPTION_HANDLER_CORE_EXCEPTION(
                                           tightdb::TableRef tableRef = _group->get_table(ObjcStringAccessor(name));
                                           [table setNativeTable:tableRef.get()];
                                           )
    [table setParent:self];
    [table setReadOnly:m_read_only];
    return table;
}

-(RLMTable *)createTableWithName:(NSString*)name columns:(NSArray*)columns
{
    RLMTable * table = [self createTableWithName:name];
    
    //Set columns
    tightdb::TableRef nativeTable = [table getNativeTable].get_table_ref();
    if (!set_columns(nativeTable, columns)) {
        // Parsing the schema failed
        //TODO: More detailed error msg in exception
        @throw [NSException exceptionWithName:@"realm:invalid_columns"
                                       reason:@"The supplied list of columns was invalid"
                                     userInfo:nil];
    }
    
    return table;
}

// FIXME: Check that the specified class derives from Table.
-(id)createTableWithName:(NSString*)name asTableClass:(__unsafe_unretained Class)class_obj
{
    if ([name length] == 0) {
        @throw [NSException exceptionWithName:@"realm:table_name_exception"
                                       reason:@"Name must be a non-empty NSString"
                                     userInfo:nil];
    }
    
    if (m_read_only) {
        @throw [NSException exceptionWithName:@"realm:core_read_only_exception"
                                       reason:@"Realm is read-only."
                                     userInfo:nil];
    }
    
    if ([self hasTableWithName:name]) {
        @throw [NSException exceptionWithName:@"realm:table_with_name_already_exists"
                                       reason:[NSString stringWithFormat:@"A table with the name '%@' already exists in the context.", name]
                                     userInfo:nil];
    }
    
    RLMTable * table = [[class_obj alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table))
        return nil;
    bool was_created;
    REALM_EXCEPTION_HANDLER_CORE_EXCEPTION(
                                           tightdb::TableRef tableRef = _group->get_table(ObjcStringAccessor(name), was_created);
                                           [table setNativeTable:tableRef.get()];)
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

// Private.
// Careful with this one - Remember that group will be deleted on dealloc.
+(instancetype)realmWithNativeGroup:(tightdb::Group*)group isOwned:(BOOL)is_owned readOnly:(BOOL)read_only
{
    RLMRealm *realm = [[RLMRealm alloc] init];
    realm->_group = group;
    realm->m_is_owned  = is_owned;
    realm->m_read_only = read_only;
    return realm;
}

-(NSString*)nameOfTableWithIndex:(NSUInteger)table_ndx
{
    return to_objc_string(_group->get_table_name(table_ndx));
}

@end
