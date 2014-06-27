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

#import "RLMMigration_Private.h"
#import "RLMRealm_Private.hpp"
#import "RLMSchema_Private.h"
#import "RLMObject_Private.h"
#import "RLMObjectStore.h"
#import "RLMArray.h"

@implementation RLMMigration

+ (instancetype)migrationAtPath:(NSString *)path error:(NSError **)error {
    RLMMigration *migration = [RLMMigration new];
    
    // create rw realm to migrate with current on disk table
    migration->_realm = [RLMRealm realmWithPath:path readOnly:NO dynamic:YES schema:nil error:error];
    if (error && *error) {
        return nil;
    }
    
    // create read only realm used during migration with current on disk schema
    migration->_oldRealm = [RLMRealm realmWithPath:path readOnly:YES dynamic:YES schema:nil error:error];
    if (error && *error) {
        return nil;
    }
    
    return migration;
}

- (RLMSchema *)oldSchema {
    return self.oldRealm.schema;
}

- (RLMSchema *)newSchema {
    return [RLMSchema sharedSchema];
}

- (void)enumerateObjects:(NSString *)className block:(RLMObjectMigrationBlock)block {
    // get all objects
    RLMArray *objects = [_realm allObjects:className], *oldObjects = [_oldRealm allObjects:className];
    for (NSUInteger o = 0; o < oldObjects.count; o++) {
        block(oldObjects[o], objects[o]);
    }
}

- (void)migrateWithBlock:(RLMMigrationBlock)block {
    // start write transaction
    [_realm beginWriteTransaction];

    // add new tables/columns for the current shared schema
    _realm.schema = [RLMSchema sharedSchema];
    bool changed = RLMUpdateTables(_realm, _realm.schema);

    // apply block and set new schema version
    NSUInteger oldVersion = RLMRealmSchemaVersion(_realm);
    NSUInteger newVersion = block(self, oldVersion);
    RLMRealmSetSchemaVersion(_realm, newVersion);

    // make sure a new version was provided if changes were made
    if (changed && oldVersion >= newVersion) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Migration block should return a higher version after a schema update"
                                     userInfo:nil];
    }

    // end transaction
    [_realm commitWriteTransaction];
}

@end
