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
#import "RLMProperty_Private.h"
#import "RLMSchema_Private.h"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObject_Private.h"
#import "RLMObjectStore.hpp"
#import "RLMArray.h"

#import <tightdb/table_view.hpp>

// The source realm for a migration has to use a SharedGroup to be able to share
// the file with the destination realm, but we don't want to let the user call
// beginWriteTransaction on it as that would make no sense.
@interface RLMMigrationRealm : RLMRealm
@end

@implementation RLMMigrationRealm
- (BOOL)readonly {
    return YES;
}

- (void)beginWriteTransaction {
    @throw [NSException exceptionWithName:@"RLMException"
                                   reason:@"Cannot modify the source Realm in a migration"
                                 userInfo:nil];
}
@end

@implementation RLMMigration

+ (instancetype)migrationForRealm:(RLMRealm *)realm error:(NSError **)error {
    RLMMigration *migration = [RLMMigration new];
    
    // create rw realm to migrate with current on disk table
    migration->_realm = realm;
    
    // create read only realm used during migration with current on disk schema
    migration->_oldRealm = [[RLMMigrationRealm alloc] initWithPath:realm.path readOnly:NO inMemory:NO error:error];
    if (migration->_oldRealm) {
        RLMRealmSetSchema(migration->_oldRealm, [RLMSchema dynamicSchemaFromRealm:migration->_oldRealm]);
    }
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
    RLMResults *objects = [_realm.schema schemaForClassName:className] ? [_realm allObjects:className] : nil;
    RLMResults *oldObjects = [_oldRealm.schema schemaForClassName:className] ? [_oldRealm allObjects:className] : nil;
    if (objects && oldObjects) {
        for (long i = oldObjects.count - 1; i >= 0; i--) {
            block(oldObjects[i], objects[i]);
        }
    }
    else if (objects) {
        for (long i = objects.count - 1; i >= 0; i--) {
            block(nil, objects[i]);
        }
    }
    else if (oldObjects) {
        for (long i = oldObjects.count - 1; i >= 0; i--) {
            block(oldObjects[i], nil);
        }
    }
}

- (void)verifyPrimaryKeyUniqueness {
    for (RLMObjectSchema *objectSchema in _realm.schema.objectSchema) {
        // if we have a new primary key not equal to our old one, verify uniqueness
        RLMProperty *primaryProperty = objectSchema.primaryKeyProperty;
        RLMProperty *oldPrimaryProperty = [[_oldRealm.schema schemaForClassName:objectSchema.className] primaryKeyProperty];
        if (primaryProperty && primaryProperty != oldPrimaryProperty) {
            // FIXME: replace with count of distinct once we support indexing

            // FIXME: support other types
            tightdb::TableRef &table = objectSchema->_table;
            NSUInteger count = table->size();
            if (primaryProperty.type == RLMPropertyTypeString) {
                if (!table->has_search_index(primaryProperty.column)) {
                    table->add_search_index(primaryProperty.column);
                }
                if (table->get_distinct_view(primaryProperty.column).size() != count) {
                    NSString *reason = [NSString stringWithFormat:@"Primary key property '%@' has duplicate values after migration.", primaryProperty.name];
                    @throw [NSException exceptionWithName:@"RLMException" reason:reason userInfo:nil];
                }
            }
            else {
                for (NSUInteger i = 0; i < count; i++) {
                    if (table->count_int(primaryProperty.column, table->get_int(primaryProperty.column, i)) > 1) {
                        NSString *reason = [NSString stringWithFormat:@"Primary key property '%@' has duplicate values after migration.", primaryProperty.name];
                        @throw [NSException exceptionWithName:@"RLMException" reason:reason userInfo:nil];
                    }
                }
            }
        }
    }
}

- (void)migrateWithBlock:(RLMMigrationBlock)block version:(NSUInteger)newVersion {
    // start write transaction
    [_realm beginWriteTransaction];

    @try {
        // add new tables/columns for the current shared schema
        RLMRealmCreateTables(_realm, [RLMSchema sharedSchema], true);

        // disable all primary keys for migration
        for (RLMObjectSchema *objectSchema in _realm.schema.objectSchema) {
            objectSchema.primaryKeyProperty.isPrimary = NO;
        }

        // apply block and set new schema version
        NSUInteger oldVersion = RLMRealmSchemaVersion(_realm);
        block(self, oldVersion);

        // verify uniqueness for any new unique columns before committing
        [self verifyPrimaryKeyUniqueness];

        // update new version
        RLMRealmSetSchemaVersion(_realm, newVersion);
    }
    @finally {
        // end transaction
        [_realm commitWriteTransaction];
    }
}

-(RLMObject *)createObject:(NSString *)className withObject:(id)object {
    return [_realm createObject:className withObject:object];
}

- (void)deleteObject:(RLMObject *)object {
    [_realm deleteObject:object];
}

@end
