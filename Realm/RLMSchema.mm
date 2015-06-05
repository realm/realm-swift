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

#import "RLMSchema_Private.h"

#import "RLMAccessor.h"
#import "RLMObject_Private.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMSwiftSupport.h"
#import "RLMUtil.hpp"

#import <objc/runtime.h>
#import <realm/group.hpp>

NSString * const c_objectTableNamePrefix = @"class_";
const char * const c_metadataTableName = "metadata";
const char * const c_versionColumnName = "version";
const size_t c_versionColumnIndex = 0;

const char * const c_primaryKeyTableName = "pk";
const char * const c_primaryKeyObjectClassColumnName = "pk_table";
const size_t c_primaryKeyObjectClassColumnIndex =  0;
const char * const c_primaryKeyPropertyNameColumnName = "pk_property";
const size_t c_primaryKeyPropertyNameColumnIndex =  1;

const uint64_t RLMNotVersioned = std::numeric_limits<uint64_t>::max();

// RLMSchema private properties
@interface RLMSchema ()
@property (nonatomic, readwrite) NSMutableDictionary *objectSchemaByName;
@end

static RLMSchema *s_sharedSchema;
static NSMutableDictionary *s_localNameToClass;

@implementation RLMSchema

- (RLMObjectSchema *)schemaForClassName:(NSString *)className {
    return _objectSchemaByName[className];
}

- (RLMObjectSchema *)objectForKeyedSubscript:(__unsafe_unretained id<NSCopying> const)className {
    RLMObjectSchema *schema = _objectSchemaByName[className];
    if (!schema) {
        NSString *message = [NSString stringWithFormat:@"Object type '%@' not persisted in Realm", className];
        @throw RLMException(message);
    }
    return schema;
}

- (void)setObjectSchema:(NSArray *)objectSchema {
    _objectSchema = objectSchema;
    _objectSchemaByName = [NSMutableDictionary dictionaryWithCapacity:objectSchema.count];
    for (RLMObjectSchema *object in objectSchema) {
        [(NSMutableDictionary *)_objectSchemaByName setObject:object forKey:object.className];
    }
}

+ (void)initialize {
    static bool initialized;
    if (initialized) {
        return;
    }
    initialized = true;

    NSMutableArray *schemaArray = [NSMutableArray array];
    RLMSchema *schema = [[RLMSchema alloc] init];

    unsigned int numClasses;
    Class *classes = objc_copyClassList(&numClasses);

    // first create class to name mapping so we can do array validation
    // when creating object schema
    s_localNameToClass = [NSMutableDictionary dictionary];
    for (unsigned int i = 0; i < numClasses; i++) {
        Class cls = classes[i];
        static Class objectBaseClass = [RLMObjectBase class];
        if (!RLMIsKindOfClass(cls, objectBaseClass) || ![cls shouldPersistToRealm]) {
            continue;
        }

        NSString *className = NSStringFromClass(cls);
        if ([RLMSwiftSupport isSwiftClassName:className]) {
            className = [RLMSwiftSupport demangleClassName:className];
        }
        // NSStringFromClass demangles the names for top-level Swift classes
        // but not for nested classes. _T indicates it's a Swift symbol, t
        // indicates it's a type, and C indicates it's a class.
        else if ([className hasPrefix:@"_TtC"]) {
            NSString *message = [NSString stringWithFormat:@"RLMObject subclasses cannot be nested within other declarations. Please move %@ to global scope.", className];
            @throw RLMException(message);
        }

        if (s_localNameToClass[className]) {
            NSString *message = [NSString stringWithFormat:@"RLMObject subclasses with the same name cannot be included twice in the same target. Please make sure '%@' is only linked once to your current target.", className];
            @throw RLMException(message);
        }
        s_localNameToClass[className] = cls;

        // override classname for all valid classes
        RLMReplaceClassNameMethod(cls, className);
    }

    // process all RLMObject subclasses
    for (Class cls in s_localNameToClass.allValues) {
        RLMObjectSchema *schema = [RLMObjectSchema schemaForObjectClass:cls];
        [schemaArray addObject:schema];

        // override sharedSchema classs methods for performance
        RLMReplaceSharedSchemaMethod(cls, schema);

        // set standalone class on shared shema for standalone object creation
        schema.standaloneClass = RLMStandaloneAccessorClassForObjectClass(schema.objectClass, schema);
    }
    free(classes);

    // set class array
    schema.objectSchema = schemaArray;

    // set shared schema
    s_sharedSchema = schema;
}

// schema based on runtime objects
+ (instancetype)sharedSchema {
    return s_sharedSchema;
}

// schema based on tables in a realm
+ (instancetype)dynamicSchemaFromRealm:(RLMRealm *)realm {
    // generate object schema and class mapping for all tables in the realm
    unsigned long numTables = realm.group->size();
    NSMutableArray *schemaArray = [NSMutableArray arrayWithCapacity:numTables];
    
    // cache descriptors for all subclasses of RLMObject
    RLMSchema *schema = [[RLMSchema alloc] init];
    for (unsigned long i = 0; i < numTables; i++) {
        NSString *className = RLMClassForTableName(@(realm.group->get_table_name(i).data()));
        if (className) {
            RLMObjectSchema *object = [RLMObjectSchema schemaFromTableForClassName:className realm:realm];
            object.table = realm.group->get_table(i).get();
            [schemaArray addObject:object];
        }
    }
    
    // set class array and mapping
    schema.objectSchema = schemaArray;
    return schema;
}

uint64_t RLMRealmSchemaVersion(RLMRealm *realm) {
    realm::TableRef table = realm.group->get_table(c_metadataTableName);
    if (!table || table->get_column_count() == 0) {
        return RLMNotVersioned;
    }
    return table->get_int(c_versionColumnIndex, 0);
}

void RLMRealmSetSchemaVersion(RLMRealm *realm, uint64_t version) {
    realm::TableRef table = realm.group->get_or_add_table(c_metadataTableName);
    table->set_int(c_versionColumnIndex, 0, version);
}

NSString *RLMRealmPrimaryKeyForObjectClass(RLMRealm *realm, NSString *objectClass) {
    realm::TableRef table = realm.group->get_table(c_primaryKeyTableName);
    if (!table) {
        return nil;
    }
    size_t row = table->find_first_string(c_primaryKeyObjectClassColumnIndex, RLMStringDataWithNSString(objectClass));
    if (row == realm::not_found) {
        return nil;
    }
    return RLMStringDataToNSString(table->get_string(c_primaryKeyPropertyNameColumnIndex, row));
}

bool RLMRealmHasMetadataTables(RLMRealm *realm) {
    return realm.group->get_table(c_primaryKeyTableName) && realm.group->get_table(c_metadataTableName);
}

bool RLMRealmCreateMetadataTables(RLMRealm *realm) {
    bool changed = false;
    realm::TableRef table = realm.group->get_or_add_table(c_primaryKeyTableName);
    if (table->get_column_count() == 0) {
        table->add_column(realm::type_String, c_primaryKeyObjectClassColumnName);
        table->add_column(realm::type_String, c_primaryKeyPropertyNameColumnName);
        changed = true;
    }

    table = realm.group->get_or_add_table(c_metadataTableName);
    if (table->get_column_count() == 0) {
        table->add_column(realm::type_Int, c_versionColumnName);

        // set initial version
        table->add_empty_row();
        table->set_int(c_versionColumnIndex, 0, RLMNotVersioned);
        changed = true;
    }

    return changed;
}

void RLMRealmSetPrimaryKeyForObjectClass(RLMRealm *realm, NSString *objectClass, NSString *primaryKey) {
    realm::TableRef table = realm.group->get_table(c_primaryKeyTableName);

    // get row or create if new object and populate
    size_t row = table->find_first_string(c_primaryKeyObjectClassColumnIndex, RLMStringDataWithNSString(objectClass));
    if (row == realm::not_found && primaryKey != nil) {
        row = table->add_empty_row();
        table->set_string(c_primaryKeyObjectClassColumnIndex, row, RLMStringDataWithNSString(objectClass));
    }

    // set if changing, or remove if setting to nil
    if (primaryKey == nil && row != realm::not_found) {
        table->remove(row);
    }
    else {
        table->set_string(c_primaryKeyPropertyNameColumnIndex, row, RLMStringDataWithNSString(primaryKey));
    }
}


+ (Class)classForString:(NSString *)className {
    if (Class cls = s_localNameToClass[className]) {
        return cls;
    }
    return NSClassFromString(className);
}

- (id)copyWithZone:(NSZone *)zone {
    RLMSchema *schema = [[RLMSchema allocWithZone:zone] init];
    schema.objectSchema = [[NSArray allocWithZone:zone] initWithArray:self.objectSchema copyItems:YES];
    return schema;
}

- (instancetype)shallowCopy {
    RLMSchema *schema = [[RLMSchema alloc] init];
    NSMutableArray *objectSchema = [NSMutableArray arrayWithCapacity:_objectSchema.count];
    for (RLMObjectSchema *schema in _objectSchema) {
        [objectSchema addObject:[schema shallowCopy]];
    }
    schema.objectSchema = objectSchema;
    return schema;
}

- (BOOL)isEqualToSchema:(RLMSchema *)schema {
    if (_objectSchema.count != schema.objectSchema.count) {
        return NO;
    }
    for (RLMObjectSchema *objectSchema in schema.objectSchema) {
        if (![_objectSchemaByName[objectSchema.className] isEqualToObjectSchema:objectSchema]) {
            return NO;
        }
    }
    return YES;
}

- (NSString *)description {
    NSMutableString *objectSchemaString = [NSMutableString string];
    for (RLMObjectSchema *objectSchema in self.objectSchema) {
        [objectSchemaString appendFormat:@"\t%@\n", [objectSchema.description stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\t"]];
    }
    return [NSString stringWithFormat:@"Schema {\n%@}", objectSchemaString];
}

@end
