/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2014] TightDB Inc
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of TightDB Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to TightDB Incorporated
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from TightDB Incorporated.
 *
 **************************************************************************/

#import "RLMSchema.h"
#import "RLMTable.h"
#import "RLMFast.h"
#import "RLMPrivate.h"

@interface RLMSchema ()
@property (nonatomic, readwrite) NSArray * properties;
@property (nonatomic, readwrite) NSDictionary * propertiesByName;

@end

// static caches for schema and proxy classes
static NSMutableDictionary * s_schemaCache;

@implementation RLMSchema

+ (void)initialize {
    s_schemaCache = [NSMutableDictionary dictionary];
}

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

+(RLMSchema *)schemaForObjectClass:(Class)objectClass {
    NSString * className = NSStringFromClass(objectClass);
    if (s_schemaCache[className]) return s_schemaCache[className];
    
    // get object properties
    unsigned int count;
    objc_property_t * props = class_copyPropertyList(objectClass, &count);
    
    // create array of TDBProperties
    NSMutableArray * propArray = [NSMutableArray arrayWithCapacity:count];
    for (unsigned int i = 0; i < count; i++) {
        RLMProperty * prop = [RLMProperty propertyForObjectProperty:props[i]];
        if (prop) {
            // if a table and we don't already know the object class figure out now
            if (prop.type == RLMTypeTable && !prop.subtableObjectClass) {
                prop.subtableObjectClass = [objectClass subtableObjectClassForProperty:prop.name];
                // TODO - throw exception if no object class
            }
            [propArray addObject:prop];
        }
    }
    
    free(props);
    
    // create schema object and set properties
    RLMSchema * schema = [RLMSchema new];
    schema.properties = [propArray copy];
    
    s_schemaCache[className] = schema;
    return schema;
}

@end

