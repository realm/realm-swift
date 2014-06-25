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

#import "RLMObjectSchema.h"
#import "RLMUtil.hpp"
#import "RLMProperty_Private.h"
#import "RLMSchema_Private.h"
#import <tightdb/table.hpp>
#import "RLMObject_Private.h"

// private properties
@interface RLMObjectSchema ()
@property (nonatomic, readwrite, copy) NSArray * properties;
@property (nonatomic, readwrite) NSDictionary * propertiesByName;
@property (nonatomic, readwrite, assign) NSString *className;
@end


@implementation RLMObjectSchema

// return properties by name
-(RLMProperty *)objectForKeyedSubscript:(id <NSCopying>)key {
    return _propertiesByName[key];
}

// create property map when setting property array
-(void)setProperties:(NSArray *)properties {
    NSMutableDictionary * map = [NSMutableDictionary dictionaryWithCapacity:_properties.count];
    for (RLMProperty * prop in properties) {
        map[prop.name] = prop;
    }
    _propertiesByName = map;
    _properties = properties;
}

+(instancetype)schemaForObjectClass:(Class)objectClass {
    // get object properties
    unsigned int count;
    objc_property_t *props = class_copyPropertyList(objectClass, &count);

    NSArray *ignoredPropertiesForClass = [objectClass ignoredProperties];
    
    // create array of RLMProperties
    NSMutableArray *propArray = [NSMutableArray arrayWithCapacity:count];
    for (unsigned int i = 0; i < count; i++) {
        NSString *propertyName = [NSString stringWithUTF8String:property_getName(props[i])];
        BOOL ignored = [ignoredPropertiesForClass containsObject:propertyName];
        
        if (ignored) { // Don't process ignored properties
            continue;
        }
        
        RLMProperty *prop = [RLMProperty propertyForObjectProperty:props[i]
                                                        attributes:[objectClass attributesForProperty:propertyName]
                                                            column:propArray.count];
        
        if (prop) {
            [propArray addObject:prop];
        }
    }
    
    free(props);
    
    // create schema object and set properties
    RLMObjectSchema * schema = [RLMObjectSchema new];
    schema.properties = propArray;
#ifdef REALM_SWIFT
    schema.className = [RLMSwiftSupport parseClass:objectClass].name;
#else
    schema.className = NSStringFromClass(objectClass);
#endif
    return schema;
}


// generate a schema from a table - specify the custom class name for the dynamic
// class and the name to be used in the schema - used for migrations and dynamic interface
+(instancetype)schemaForTable:(tightdb::Table *)table className:(NSString *)className {
    // create array of RLMProperties
    size_t count = table->get_column_count();
    NSMutableArray *propArray = [NSMutableArray arrayWithCapacity:count];
    for (size_t col = 0; col < count; col++) {
        // create new property
        NSString *name = RLMStringDataToNSString(table->get_column_name(col).data());
        RLMProperty *prop = [[RLMProperty alloc] initWithName:name
                                                         type:RLMPropertyType(table->get_column_type(col))
                                                       column:col];
        if (prop.type == RLMPropertyTypeObject || prop.type == RLMPropertyTypeArray) {
            // set link type for objects and arrays
            tightdb::TableRef linkTable = table->get_link_target(col);
            prop.objectClassName = RLMClassForTableName(@(linkTable->get_name().data()));
        }

        [propArray addObject:prop];
    }
    
    // create schema object and set properties
    RLMObjectSchema * schema = [RLMObjectSchema new];
    schema.properties = propArray;
    schema.className = className;
    
    return schema;
}

@end

