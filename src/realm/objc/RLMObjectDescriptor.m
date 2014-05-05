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

#import "RLMObjectDescriptor.h"
#import "RLMTable.h"
#import "RLMFast.h"
#import "RLMPrivate.h"

@interface RLMObjectDescriptor ()
@property (nonatomic, readwrite, copy) NSArray * properties;
@property (nonatomic, readwrite) NSDictionary * propertiesByName;

@end

// static caches for schema and proxy classes
static NSMutableDictionary * s_descriptorCache;

@implementation RLMObjectDescriptor

+ (void)initialize {
    if (self == [RLMObjectDescriptor class]) {
        s_descriptorCache = [NSMutableDictionary dictionary];
    }
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

+(instancetype)descriptorForObjectClass:(Class)objectClass {
    NSString * className = NSStringFromClass(objectClass);
    if (s_descriptorCache[className]) {
        return s_descriptorCache[className];
    }
    
    // check if proxy
    if ([className hasPrefix:@"RLMProxy_"]) {
        NSString * proxiedClassName = [className substringFromIndex:9];
        s_descriptorCache[className] = s_descriptorCache[proxiedClassName];
        return s_descriptorCache[className];
    }
    
    // get object properties
    unsigned int count;
    objc_property_t *props = class_copyPropertyList(objectClass, &count);
    
    // create array of RLMProperties
    NSMutableArray *propArray = [NSMutableArray arrayWithCapacity:count];
    for (unsigned int i = 0; i < count; i++) {
        RLMProperty *prop = [RLMProperty propertyForObjectProperty:props[i]];
        if (prop) {
            // if a table and we don't already know the object class figure out now
            if (prop.type == RLMTypeTable && !prop.subtableObjectClass) {
                prop.subtableObjectClass = [objectClass subtableObjectClassForProperty:prop.name];
            }
            [propArray addObject:prop];
        }
    }
    
    free(props);
    
    // create schema object and set properties
    RLMObjectDescriptor * descriptor = [RLMObjectDescriptor new];
    descriptor.properties = propArray;
    
    s_descriptorCache[className] = descriptor;
    return descriptor;
}

@end

