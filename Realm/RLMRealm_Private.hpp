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

extern "C" {
#import "RLMRealm_Private.h"
#import "RLMSchema_Private.h"
#import "RLMAccessor.h"
}

#import <tightdb/link_view.hpp>
#import <tightdb/group.hpp>

@interface RLMRealm ()
@property (nonatomic, readonly, getter=getOrCreateGroup) tightdb::Group *group;
@end

// throw an exception if the realm is being used from the wrong thread
static inline void RLMCheckThread(__unsafe_unretained RLMRealm *realm) {
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

