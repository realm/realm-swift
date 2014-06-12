////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMRealm_Private.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMSchema_Private.h"
#import "RLMObject.h"
#import "RLMUtil.h"

#import <objc/runtime.h>

NSString *const c_objectTableNamePrefix = @"class_";
const char *c_metadataTableName = "metadata";
const char *c_versionColumnName = "version";
const size_t c_versionColumnIndex = 0;

// RLMSchema private properties
@interface RLMSchema ()
@property (nonatomic, readwrite) NSArray *objectSchema;
@property (nonatomic, readwrite) NSMutableDictionary *objectSchemaByName;
@property (nonatomic, readwrite) NSMutableDictionary *objectClassByName;
@end

static RLMSchema *s_sharedSchema;

@implementation RLMSchema

- (RLMObjectSchema *)schemaForObject:(NSString *)className {
    return _objectSchemaByName[className];
}

- (RLMProperty *)objectForKeyedSubscript:(id <NSCopying>)className {
    return _objectSchemaByName[className];
}

- (Class)objectClassForClassName:(NSString *)className {
    return _objectClassByName[className];
}

- (id)init {
    self = [super init];
    if (self) {
        // setup name mapping for object tables
        _tableNamesForClass = [NSMutableDictionary dictionary];
        _objectClassByName = [NSMutableDictionary dictionary];
        _objectSchemaByName = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // load object schemas for all RLMObject subclasses
        unsigned int numClasses;
        Class *classes = objc_copyClassList(&numClasses);
        NSMutableArray *schemaArray = [NSMutableArray array];
        
        // cache descriptors for all subclasses of RLMObject
        RLMSchema *schema = [[RLMSchema alloc] init];
        for (unsigned int i = 0; i < numClasses; i++) {
            // if direct subclass
            if (class_getSuperclass(classes[i]) == RLMObject.class) {
                // add to class list
                RLMObjectSchema *object = [RLMObjectSchema schemaForObjectClass:classes[i]];
                [schemaArray addObject:object];
                
                // set table name and mappings
                NSString *tableName = RLMTableNameForClassName(object.className);
                schema.tableNamesForClass[object.className] = tableName;
                schema.objectClassByName[object.className] = classes[i];
                [(NSMutableDictionary *)schema.objectSchemaByName setObject:object forKey:object.className];
            }
        }
        free(classes);
        
        // set class array
        schema.objectSchema = schemaArray;
        
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

            // add object and set mappings
            schema.tableNamesForClass[object.className] = tableName;
            [(NSMutableDictionary *)schema.objectSchemaByName setObject:object forKey:object.className];

            // generate dynamic class and set class mapping
            Class dynamicClass = RLMDynamicClassForSchema(object, realm.schemaVersion);
            schema.objectClassByName[object.className] = dynamicClass;
        }
    }
    
    // set class array and mapping
    schema.objectSchema = schemaArray;
    return schema;
}


inline tightdb::TableRef RLMVersionTable(RLMRealm *realm) {
    tightdb::TableRef table = realm.group->get_table(c_metadataTableName);
    if (table->is_empty()) {
        // create columns
        table->add_column(tightdb::type_Int, c_versionColumnName);
        
        // set initial version
        table->add_empty_row();
        (*table)[0].set_int(c_versionColumnIndex, 0);
    }
    return table;
}

NSUInteger RLMRealmSchemaVersion(RLMRealm *realm) {
    return (*RLMVersionTable(realm))[0].get_int(c_versionColumnIndex);

}

void RLMRealmSetSchemaVersion(RLMRealm *realm, NSUInteger version) {
    (*RLMVersionTable(realm))[0].set_int(c_versionColumnIndex, version);
}

@end
