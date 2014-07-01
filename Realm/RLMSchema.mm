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

#import "RLMRealm_Private.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMSchema_Private.h"
#import "RLMObject.h"
#import "RLMUtil.hpp"

#import <objc/runtime.h>

NSString *const c_objectTableNamePrefix = @"class_";
const char *c_metadataTableName = "metadata";
const char *c_versionColumnName = "version";
const size_t c_versionColumnIndex = 0;

// RLMSchema private properties
@interface RLMSchema ()
@property (nonatomic, readwrite) NSMutableDictionary *objectSchemaByName;
@end

static RLMSchema *s_sharedSchema;
static NSMutableDictionary *s_classNameToMangledName;


@implementation RLMSchema

- (RLMObjectSchema *)schemaForClassName:(NSString *)className {
    return _objectSchemaByName[className];
}

- (RLMProperty *)objectForKeyedSubscript:(id <NSCopying>)className {
    return _objectSchemaByName[className];
}

- (id)init {
    self = [super init];
    if (self) {
        // setup name mapping for object tables
        _tableNamesForClass = [NSMutableDictionary dictionary];
        _objectSchemaByName = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setObjectSchema:(NSArray *)objectSchema {
    _objectSchema = objectSchema;
    
    // update mappings
    for (RLMObjectSchema *object in objectSchema) {
        // set table name and mappings
        _tableNamesForClass[object.className] = RLMTableNameForClassName(object.className);
        [(NSMutableDictionary *)_objectSchemaByName setObject:object forKey:object.className];
    }
}

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // initialize mangled name mapping
        s_classNameToMangledName = [NSMutableDictionary dictionary];

        // load object schemas for all RLMObject subclasses
        unsigned int numClasses;
        Class *classes = objc_copyClassList(&numClasses);
        NSMutableArray *schemaArray = [NSMutableArray array];
        
        // cache descriptors for all subclasses of RLMObject
        RLMSchema *schema = [[RLMSchema alloc] init];
        for (unsigned int i = 0; i < numClasses; i++) {
            // if direct subclass
            if (class_getSuperclass(classes[i]) == RLMObject.class) {
                RLMObjectSchema *objectSchema = nil;
#ifdef REALM_SWIFT
                // if swift
                NSString *className = NSStringFromClass(classes[i]);
                if ([RLMSwiftSupport isSwiftClassName:className]) {
                    objectSchema = [RLMSwiftSupport schemaForObjectClass:classes[i]];
                    s_classNameToMangledName[objectSchema.className] = objectSchema.objectClass;
                }
                else {
                    objectSchema = [RLMObjectSchema schemaForObjectClass:classes[i]];
                }
#else
                objectSchema = [RLMObjectSchema schemaForObjectClass:classes[i]];
#endif
                // add to list
                [schemaArray addObject:objectSchema];

            }
        }
        free(classes);
        
        // set class array
        schema.objectSchema = schemaArray;
        
        // set shared schema
        s_sharedSchema = schema;
    });
}

// schema based on runtime objects
+(instancetype)sharedSchema {
    return s_sharedSchema;
}

// schema based on tables in a realm
+(instancetype)dynamicSchemaFromRealm:(RLMRealm *)realm {
    // generate object schema and class mapping for all tables in the realm
    unsigned long numTables = realm.group->size();
    NSMutableArray *schemaArray = [NSMutableArray arrayWithCapacity:numTables];
    
    // cache descriptors for all subclasses of RLMObject
    RLMSchema *schema = [[RLMSchema alloc] init];
    for (unsigned long i = 0; i < numTables; i++) {
        NSString *tableName = [NSString stringWithUTF8String:realm.group->get_table_name(i).data()];
        NSString *className = RLMClassForTableName(tableName);
        if (className) {
            tightdb::TableRef table = realm.group->get_table(i);
            RLMObjectSchema *object = [RLMObjectSchema schemaForTable:table.get() className:className];
            [schemaArray addObject:object];
        }
    }
    
    // set class array and mapping
    schema.objectSchema = schemaArray;
    return schema;
}


inline tightdb::TableRef RLMVersionTable(RLMRealm *realm) {
    tightdb::TableRef table = realm.group->get_table(c_metadataTableName);
    if (table->get_column_count() == 0) {
        // create columns
        table->add_column(tightdb::type_Int, c_versionColumnName);
        
        // set initial version
        table->add_empty_row();
        (*table)[0].set_int(c_versionColumnIndex, 0);
    }
    return table;
}

NSUInteger RLMRealmSchemaVersion(RLMRealm *realm) {
    return (NSUInteger)(*RLMVersionTable(realm))[0].get_int(c_versionColumnIndex);

}

void RLMRealmSetSchemaVersion(RLMRealm *realm, NSUInteger version) {
    (*RLMVersionTable(realm))[0].set_int(c_versionColumnIndex, version);
}

+ (Class)classForString:(NSString *)className {
#ifdef REALM_SWIFT
    if (s_classNameToMangledName[className]) {
        className = s_classNameToMangledName[className];
    }
#endif
    return NSClassFromString(className);
}

@end
