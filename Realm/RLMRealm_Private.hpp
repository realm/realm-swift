////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMRealm_Dynamic.h"
#import "RLMSchema_Private.h"
#import "RLMAccessor.h"

#import <tightdb/link_view.hpp>
#import <tightdb/group.hpp>

// RLMRealm private members
@interface RLMRealm () {
    @public
    // expose ivar to to avoid objc messages in accessors
    BOOL _inWriteTransaction;
    mach_port_t _threadID;
}
@property (nonatomic, readonly) BOOL inWriteTransaction;
@property (nonatomic, readonly) tightdb::Group *group;
@property (nonatomic, readwrite) RLMSchema *schema;

- (instancetype)initWithPath:(NSString *)path readOnly:(BOOL)readonly inMemory:(BOOL)inMemory error:(NSError **)error;
@end

// throw an exception if the realm is being used from the wrong thread
inline void RLMCheckThread(RLMRealm *realm) {
    if (realm->_threadID != pthread_mach_thread_np(pthread_self())) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Realm accessed from incorrect thread"
                                     userInfo:nil];
    }
}

// get the table used to store object of objectClass
static inline tightdb::TableRef RLMTableForObjectClass(RLMRealm *realm,
                                                       NSString *className,
                                                       bool &created) {
    NSString *tableName = RLMTableNameForClass(className);
    return realm.group->get_or_add_table(tableName.UTF8String, &created);
}
static inline tightdb::TableRef RLMTableForObjectClass(RLMRealm *realm,
                                                       NSString *className) {
    NSString *tableName = RLMTableNameForClass(className);
    return realm.group->get_table(tableName.UTF8String);
}

