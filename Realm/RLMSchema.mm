//
//  RLMSchema.m
//  Realm
//
//  Created by Ari Lazier on 5/16/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "RLMSchema.h"
#import "RLMObjectSchema.h"
#import "RLMUtil.h"
#import "RLMPrivate.hpp"

#import <objc/runtime.h>

// RLMObjectSchema private
@interface RLMObjectSchema ()
// returns a cached or new schema for a given object class
+(instancetype)schemaForObjectClass:(Class)objectClass;
// generate a schema from a table
+(instancetype)schemaForTable:(tightdb::Table *)table className:(NSString *)className;
@end


@interface RLMSchema ()
@property (nonatomic, readwrite) NSArray *objectSchema;
@property (nonatomic, readwrite) NSDictionary *objectSchemaByName;
@end

@implementation RLMSchema

- (void)setObjectSchema:(NSArray *)objectSchema {
    _objectSchema = [objectSchema copy];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:objectSchema.count];
    for (RLMObjectSchema *schema in objectSchema) {
        dict[schema.className] = schema;
    }
    _objectSchemaByName = [dict copy];
}

- (RLMObjectSchema *)schemaForObject:(NSString *)className {
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
    }
    return self;
}


// schema based on runime objects
+(instancetype)schemaForRuntimeObjects {
    // load object schemas for all RLMObject subclasses
    unsigned int numClasses;
    Class *classes = objc_copyClassList(&numClasses);
    NSMutableArray *schemaArray = [NSMutableArray array];
    
    // cache descriptors for all subclasses of RLMObject
    RLMSchema *schema = [[RLMSchema alloc] init];
    for (unsigned int i = 0; i < numClasses; i++) {
        if (RLMIsSubclass(classes[i], RLMObject.class)) {
            // add to class list
            RLMObjectSchema *object = [RLMObjectSchema schemaForObjectClass:classes[i]];
            [schemaArray addObject:object];
            
            // set table name
            NSString *tableName = [@"class_" stringByAppendingString:object.className];
            schema.tableNamesForClass[object.className] = tableName;
        }
    }
    free(classes);
    
    // set class array
    schema.objectSchema = schemaArray;
    return schema;
}

// schema based on tables in a realm
+(instancetype)schemaFromTablesInRealm:(RLMRealm *)realm {
    // generate object schema for all tables in the realm
    NSMutableArray *schemaArray = [NSMutableArray array];
    
    // cache descriptors for all subclasses of RLMObject
    RLMSchema *schema = [[RLMSchema alloc] init];
    unsigned long numTables = realm.group->size();
    for (unsigned long i = 0; i < numTables; i++) {
        NSString *tableName = [NSString stringWithUTF8String:realm.group->get_table_name(i).data()];
        if ([tableName hasPrefix:@"class_"]) {
            NSString *className = [tableName substringFromIndex:6];
            tightdb::TableRef table = realm.group->get_table(i);
            RLMObjectSchema *object = [RLMObjectSchema schemaForTable:table.get()
                                                            className:className];
            [schemaArray addObject:object];
            schema.tableNamesForClass[object.className] = tableName;
        }
    }
    
    // set class array
    schema.objectSchema = schemaArray;
    return schema;
}

@end
