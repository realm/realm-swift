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

@implementation RLMMigration {
    RLMSchema *_newSchema;
}

+ (instancetype)migrationAtPath:(NSString *)path error:(NSError **)error {
    RLMMigration *migration = [RLMMigration new];
    migration.realm = [RLMRealm realmWithPath:path readOnly:NO dynamic:YES error:error];
    migration->_newSchema = [RLMSchema sharedSchema];
    return migration;
}

- (RLMSchema *)oldSchema {
    return self.realm.schema;
}

- (RLMSchema *)newSchema {
    return _newSchema;
}

- (RLMArray *)allObjects:(NSString *)className {
    return [self.realm allObjects:className];
}

- (void)enumerateObjectsWithClass:(NSString *)className block:(RLMObjectMigrationBlock)block {
    // get all objects
    RLMArray *objects = [_realm allObjects:className];
    for (RLMObject *oldObj in objects) {
        // create copy using output schema
        RLMObject *newObj = [[RLMObject alloc] initWithRealm:_realm schema:[self newSchema][className] defaultValues:NO];
        newObj->_row = oldObj->_row;
        block(oldObj, newObj);
    }
}

- (void)migrateWithBlock:(RLMMigrationBlock)block {
    // start write transaction
    [_realm beginWriteTransaction];

    // add new tables
    bool changed = RLMCreateMissingTables(_realm, self.newSchema, NO);

    // add new columns before migration
    changed |= RLMAddNewColumnsToSchema(_realm, self.newSchema, NO);

    // apply block and set new schema version
    NSUInteger oldVersion = RLMRealmSchemaVersion(_realm);
    NSUInteger newVersion = block(self, oldVersion);
    RLMRealmSetSchemaVersion(_realm, newVersion);

    // remove old columns
    changed |= RLMRemoveOldColumnsFromSchema(_realm, self.newSchema);

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
