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

#import "RLMAccessor.h"
#import "RLMObject_Private.h"
#import "RLMObject_Private.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.h"
#import "RLMProperty_Private.h"
#import "RLMRealm_Dynamic.h"
#import "RLMRealm_Private.hpp"
#import "RLMResults_Private.hpp"
#import "RLMSchema_Private.hpp"
#import "RLMUtil.hpp"

#import "object_store.hpp"
#import "shared_realm.hpp"
#import "schema.hpp"

#import <realm/table.hpp>

using namespace realm;

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
    @throw RLMException(@"Cannot modify the source Realm in a migration");
}
@end

@implementation RLMMigration {
    realm::Schema *_schema;
}

- (instancetype)initWithRealm:(RLMRealm *)realm oldRealm:(RLMRealm *)oldRealm schema:(realm::Schema &)schema {
    self = [super init];
    if (self) {
        _realm = realm;
        _oldRealm = oldRealm;
        _schema = &schema;
        object_setClass(_oldRealm, RLMMigrationRealm.class);
    }
    return self;
}

- (RLMSchema *)oldSchema {
    return self.oldRealm.schema;
}

- (RLMSchema *)newSchema {
    return self.realm.schema;
}

- (void)enumerateObjects:(NSString *)className block:(__attribute__((noescape)) RLMObjectMigrationBlock)block {
    RLMResults *objects = [_realm.schema schemaForClassName:className] ? [_realm allObjects:className] : nil;
    RLMResults *oldObjects = [_oldRealm.schema schemaForClassName:className] ? [_oldRealm allObjects:className] : nil;

    // For whatever reason if this is a newly added table we enumerate the
    // objects in it, while in all other cases we enumerate only the existing
    // objects. It's unclear how this could be useful, but changing it would
    // also be a pointless breaking change and it's unlikely to be hurting anyone.
    if (objects && !oldObjects) {
        for (RLMObject *object in objects) {
            @autoreleasepool {
                block(nil, object);
            }
        }
        return;
    }

    if (oldObjects.count == 0 || objects.count == 0) {
        return;
    }

    auto& info = _realm->_info[className];
    for (RLMObject *oldObject in oldObjects) {
        @autoreleasepool {
            Obj newObj;
            try {
                newObj = info.table()->get_object(oldObject->_row.get_key());
            }
            catch (KeyNotFound const&) {
                continue;
            }
            block(oldObject, (id)RLMCreateObjectAccessor(info, std::move(newObj)));
        }
    }
}

- (void)execute:(RLMMigrationBlock)block {
    @autoreleasepool {
        // disable all primary keys for migration and use DynamicObject for all types
        for (RLMObjectSchema *objectSchema in _realm.schema.objectSchema) {
            objectSchema.accessorClass = RLMDynamicObject.class;
            objectSchema.primaryKeyProperty.isPrimary = NO;
        }
        for (RLMObjectSchema *objectSchema in _oldRealm.schema.objectSchema) {
            objectSchema.accessorClass = RLMDynamicObject.class;
        }

        block(self, _oldRealm->_realm->schema_version());

        _oldRealm = nil;
        _realm = nil;
    }
}

- (RLMObject *)createObject:(NSString *)className withValue:(id)value {
    return [_realm createObject:className withValue:value];
}

- (RLMObject *)createObject:(NSString *)className withObject:(id)object {
    return [self createObject:className withValue:object];
}

- (void)deleteObject:(RLMObject *)object {
    [_realm deleteObject:object];
}

- (BOOL)deleteDataForClassName:(NSString *)name {
    if (!name) {
        return false;
    }

    TableRef table = ObjectStore::table_for_object_type(_realm.group, name.UTF8String);
    if (!table) {
        return false;
    }
    if ([_realm.schema schemaForClassName:name]) {
        table->clear();
    }
    else {
        _realm.group.remove_table(table->get_key());
    }

    return true;
}

- (void)renamePropertyForClass:(NSString *)className oldName:(NSString *)oldName newName:(NSString *)newName {
    realm::ObjectStore::rename_property(_realm.group, *_schema, className.UTF8String,
                                        oldName.UTF8String, newName.UTF8String);
}

@end
