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

void throw_objc_exception(exception &ex) {
    NSString *errorMessage = [NSString stringWithUTF8String:ex.what()];
    @throw [NSException exceptionWithName:@"TDBException" reason:errorMessage userInfo:nil];
}

} // anonymous namespace


@interface TDBPrivateWeakTableReference: NSObject

- (instancetype)initWithTable:(RLMTable *)table indexInGroup:(size_t)index;
- (RLMTable *)table;
- (size_t)indexInGroup;

@end

@implementation TDBPrivateWeakTableReference {
    __weak RLMTable *_table;
    size_t _indexInGroup;
}

- (instancetype)initWithTable:(RLMTable *)table indexInGroup:(size_t)index {
    _table = table;
    _indexInGroup = index;
    return self;
}

- (RLMTable *)table {
    return _table;
}

- (size_t)indexInGroup {
    return _indexInGroup;
}

@end


@class RLMRealm;

@interface RLMPrivateWeakTimerTarget : NSObject

- (instancetype)initWithRealm:(RLMRealm *)realm;
- (void)timerDidFire:(NSTimer *)timer;

@end

@implementation RLMPrivateWeakTimerTarget {
    __weak RLMRealm *_realm;
}

- (instancetype)initWithRealm:(RLMRealm *)realm {
    self = [super init];
    if (self) {
        _realm = realm;
    }
    return self;
}

- (void)timerDidFire:(NSTimer *)timer {
    [_realm checkForChange:timer];
}

@end

@implementation RLMRealm {
    NSNotificationCenter *_notificationCenter;
    UniquePtr<SharedGroup> _sharedGroup;
    const Group *_group;
    NSTimer *_timer;
    NSMutableArray *_weakTableRefs; // Elements are instances of RLMPrivateWeakTableReference
    BOOL _tableRefsHaveDied;
    BOOL _hasParentContext;
    
    tightdb::Group* m_group;
    BOOL m_is_owned;
    BOOL m_read_only;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _hasParentContext = YES;
    }
    return self;
}

- (instancetype)initFromParentContext:(BOOL)hasParentContext {
    self = [super init];
    if (self) {
        _hasParentContext = hasParentContext;
    }
    return self;
}

+ (RLMRealm *)realmWithDefaultPersistence {
    return [RLMRealm realmWithPersistenceToFile:[RLMContext defaultPath]];
}

+ (RLMRealm *)realmWithPersistenceToFile:(NSString *)path {
    NSRunLoop *runLoop = [NSRunLoop mainRunLoop];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    return [self realmWithPersistenceToFile:path
                                    runLoop:runLoop
                         notificationCenter:notificationCenter
                                      error:nil];
}

+ (RLMRealm *)realmWithPersistenceToFile:(NSString *)path
                                         runLoop:(NSRunLoop *)runLoop
                              notificationCenter:(NSNotificationCenter *)notificationCenter
                                           error:(NSError **)error {
    RLMRealm *realm = [[RLMRealm alloc] initFromParentContext:NO];
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
        realm->_group = &realm->_sharedGroup->begin_read();
    }
    catch (exception &ex) {
        throw_objc_exception(ex);
    }

    return realm;
}

- (void)dealloc {
    if (_hasParentContext) {
        if (m_is_owned) {
            delete m_group;
        }
    } else {
        [_timer invalidate];
    }
}

- (void)checkForChange:(NSTimer *)theTimer {
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

- (RLMTable *)tableWithName:(NSString *)name {
    if (_hasParentContext) {
        // FIXME: Why impose this restriction? Isn't it kind of arbitrary?
        // The core library has no problems with an empty table name. What
        // if the database was created through a different language
        // binding without this restriction?
        if ([name length] == 0) {
            // FIXME: Exception name must be `TDBException` according to
            // the exception naming conventions of the official Cocoa
            // style guide. The same is true for most (if not all) of the
            // exceptions we throw.
            @throw [NSException exceptionWithName:@"realm:table_name_exception"
                                           reason:@"Name must be a non-empty NSString"
                                         userInfo:nil];
        }
        
        // If table does not exist in context, return nil
        if (![self hasTableWithName:name]) // FIXME: Do this using C++
            return nil;
        
        // Otherwise
        RLMTable * table = [[RLMTable alloc] _initRaw];
        if (TIGHTDB_UNLIKELY(!table))
            return nil;
        REALM_EXCEPTION_HANDLER_CORE_EXCEPTION(
                                               tightdb::TableRef table_2 = m_group->get_table(ObjcStringAccessor(name));
                                               [table setNativeTable:table_2.get()];
                                               )
        [table setParent:self];
        [table setReadOnly:m_read_only];
        return table;
    } else {
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
}

- (void)tableRefDidDie {
    _tableRefsHaveDied = YES;
}


-(NSUInteger)tableCount // Overrides the property getter
{
    return m_group->size();
}

-(BOOL)isEmpty // Overrides the property getter
{
    return self.tableCount == 0;
}

-(BOOL)hasTableWithName:(NSString*)name
{
    return m_group->has_table(ObjcStringAccessor(name));
}

-(id)tableWithName:(NSString *)name asTableClass:(__unsafe_unretained Class)class_obj
{
    // FIXME: Why impose this restriction? Isn't it kind of arbitrary?
    // The core library has no problems with an empty table name. What
    // if the database was created through a different language
    // binding without this restriction?
    if ([name length] == 0) {
        // FIXME: Exception name must be `TDBException` according to
        // the exception naming conventions of the official Cocoa
        // style guide. The same is true for most (if not all) of the
        // exceptions we throw.
        @throw [NSException exceptionWithName:@"realm:table_name_exception"
                                       reason:@"Name must be a non-empty NSString"
                                     userInfo:nil];
    }
    
    // If table does not exist in context, return nil
    if (![self hasTableWithName:name]) // FIXME: Do this using C++
        return nil;
    
    RLMTable * table = [[class_obj alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table))
        return nil;
    bool was_created;
    REALM_EXCEPTION_HANDLER_CORE_EXCEPTION(
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

// FIXME: Avoid creating a table instance. It should be enough to create an TightdbDescriptor and then check that.
// FIXME: Check that the specified class derives from Table.
// FIXME: Find a way to avoid having to transcode the table name twice
-(BOOL)hasTableWithName:(NSString *)name withTableClass:(__unsafe_unretained Class)class_obj
{
    if (!m_group->has_table(ObjcStringAccessor(name)))
        return NO;
    RLMTable * table = [self createTableWithName:name asTableClass:class_obj];
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
                                           tightdb::TableRef table_2 = m_group->get_table(ObjcStringAccessor(name));
                                           [table setNativeTable:table_2.get()];
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
+(RLMRealm *)group
{
    RLMRealm * group = [[RLMRealm alloc] init];
    try {
        group->m_group = new tightdb::Group;
    }
    catch (std::exception& ex) {
        @throw [NSException exceptionWithName:@"realm:core_exception"
                                       reason:[NSString stringWithUTF8String:ex.what()]
                                     userInfo:nil];
    }
    group->m_is_owned  = YES;
    group->m_read_only = NO;
    return group;
}


// Private.
// Careful with this one - Remember that group will be deleted on dealloc.
+(RLMRealm *)groupWithNativeGroup:(tightdb::Group*)group isOwned:(BOOL)is_owned readOnly:(BOOL)read_only
{
    RLMRealm * group_2 = [[RLMRealm alloc] init];
    group_2->m_group = group;
    group_2->m_is_owned  = is_owned;
    group_2->m_read_only = read_only;
    return group_2;
}

/* Moved to group_priv header for now */
+(RLMRealm *)groupWithFile:(NSString *)filename error:(NSError **)error
{
    RLMRealm * group = [[RLMRealm alloc] init];
    if (!group)
        return nil;
    try {
        group->m_group = new tightdb::Group(tightdb::StringData(ObjcStringAccessor(filename)));
    }
    // TODO: capture this in a macro or function, shared group constructor uses the same pattern.
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
    group->m_is_owned  = YES;
    group->m_read_only = NO;
    return group;
}

/* Moved to group_priv header for now */
+(RLMRealm *)groupWithBuffer:(NSData*)buffer error:(NSError**)error
{
    RLMRealm * group = [[RLMRealm alloc] init];
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
            *error = make_realm_error(RLMErrorInvalidDatabase, [NSString stringWithUTF8String:ex.what()]);
        return nil;
    }
    catch (std::exception& ex) {
        @throw [NSException exceptionWithName:@"realm:core_exception"
                                       reason:[NSString stringWithUTF8String:ex.what()]
                                     userInfo:nil];
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
            *error = make_realm_error(RLMErrorFilePermissionDenied, [NSString stringWithUTF8String:ex.what()]);
        return NO;
    }
    catch (tightdb::util::File::Exists& ex) {
        if (error) // allow nil as the error argument
            *error = make_realm_error(RLMErrorFileExists, [NSString stringWithUTF8String:ex.what()]);
        return NO;
    }
    catch (tightdb::util::File::AccessError& ex) {
        if (error) // allow nil as the error argument
            *error = make_realm_error(RLMErrorFileAccessError, [NSString stringWithUTF8String:ex.what()]);
        return NO;
    }
    catch (std::exception& ex) {
        if (error) // allow nil as the error argument
            *error = make_realm_error(RLMErrorFail, [NSString stringWithUTF8String:ex.what()]);
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
        @throw [NSException exceptionWithName:@"realm:core_exception"
                                       reason:[NSString stringWithUTF8String:ex.what()]
                                     userInfo:nil];
    }
    return nil;
}


@end
