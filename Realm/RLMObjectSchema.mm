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

#import "RLMObjectSchema.h"
#import "RLMUtil.h"
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
    
    // create array of RLMProperties
    NSMutableArray *propArray = [NSMutableArray arrayWithCapacity:count];
    for (unsigned int i = 0; i < count; i++) {
        NSString *propertyName = [NSString stringWithUTF8String:property_getName(props[i])];
        BOOL ignored = [[objectClass ignoredProperties] containsObject:propertyName];
        
        if (!ignored) { // Don't process ignored properties
            RLMProperty *prop = [RLMProperty propertyForObjectProperty:props[i] column:propArray.count];
            if (prop) {
                [propArray addObject:prop];
            }
        }
    }
    
    free(props);
    
    // create schema object and set properties
    RLMObjectSchema * schema = [RLMObjectSchema new];
    schema.properties = propArray;
    schema.className = NSStringFromClass(objectClass);
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
        if (prop.type == RLMPropertyTypeObject) {
            // set link type for objects
            tightdb::TableRef linkTable = table->get_link_target(col);
            prop.objectClassName = RLMClassForTableName(@(linkTable->get_name().data()));
        }
        else if (prop.type == RLMPropertyTypeArray) {
            @throw [NSException exceptionWithName:@"RLMNotImplementedException" reason:@"Not implemented." userInfo:nil];
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

