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

#import "RLMArray.h"
#import "RLMListBase.h"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObject_Private.h"
#import "RLMProperty_Private.h"
#import "RLMSchema_Private.h"
#import "RLMSwiftSupport.h"
#import "RLMUtil.hpp"

#import <tightdb/table.hpp>

@interface RLMObject (Swift)
+ (NSArray *)getGenericListPropertyNames:(id)obj;
@end

@implementation RLMObject (Swift)
// We need to implement this method in Swift, but we don't want the obj-c and
// Swift in the same target to avoid polluting the RealmSwift namespace with
// obj-c stuff. As such, this method is overridden in RealmSwift.Object to
// supply the real implementation at runtime without a compile-time dependency.
+ (NSArray *)getGenericListPropertyNames:(__unused id)obj {
    return nil;
}
@end

// private properties
@interface RLMObjectSchema ()
@property (nonatomic, readwrite) NSDictionary *propertiesByName;
@property (nonatomic, readwrite, assign) NSString *className;
@end

@implementation RLMObjectSchema {
    // table accessor optimization
    tightdb::TableRef _table;
}

- (instancetype)initWithClassName:(NSString *)objectClassName objectClass:(Class)objectClass properties:(NSArray *)properties {
    self = [super init];
    self.className = objectClassName;
    self.properties = properties;
    self.objectClass = objectClass;
    return self;
}

// return properties by name
-(RLMProperty *)objectForKeyedSubscript:(id <NSCopying>)key {
    return _propertiesByName[key];
}

// create property map when setting property array
-(void)setProperties:(NSArray *)properties {
    _properties = properties;
    NSMutableDictionary *map = [NSMutableDictionary dictionaryWithCapacity:_properties.count];
    for (RLMProperty *prop in _properties) {
        map[prop.name] = prop;
        if (prop.isPrimary) {
            self.primaryKeyProperty = prop;
        }
    }
    _propertiesByName = map;
}

- (void)setPrimaryKeyProperty:(RLMProperty *)primaryKeyProperty {
    _primaryKeyProperty.isPrimary = NO;
    primaryKeyProperty.isPrimary = YES;
    _primaryKeyProperty = primaryKeyProperty;
}

+ (instancetype)schemaForObjectClass:(Class)objectClass {
    RLMObjectSchema *schema = [RLMObjectSchema new];

    // determine classname from objectclass as className method has not yet been updated
    NSString *className = NSStringFromClass(objectClass);
    bool isSwift = [RLMSwiftSupport isSwiftClassName:className];
    if (isSwift) {
        className = [RLMSwiftSupport demangleClassName:className];
    }
    schema.className = className;
    schema.objectClass = objectClass;
    schema.accessorClass = RLMObject.class;
    schema.isSwiftClass = isSwift;
    
    // create array of RLMProperties, inserting properties of superclasses first
    Class cls = objectClass;
    Class superClass = class_getSuperclass(cls);
    NSArray *props = @[];
    while (superClass != RLMObjectBase.class) {
        props = [[RLMObjectSchema propertiesForClass:cls isSwift:isSwift] arrayByAddingObjectsFromArray:props];
        cls = superClass;
        superClass = class_getSuperclass(superClass);
    }
    schema.properties = props;

    // verify that we didn't add any properties twice due to inheritance
    assert(props.count == [NSSet setWithArray:[props valueForKey:@"name"]].count);

    if (NSString *primaryKey = [objectClass primaryKey]) {
        for (RLMProperty *prop in schema.properties) {
            if ([primaryKey isEqualToString:prop.name]) {
                 // FIXME - enable for ints when we have core suppport
                if (prop.type == RLMPropertyTypeString) {
                    prop.attributes |= RLMPropertyAttributeIndexed;
                }
                schema.primaryKeyProperty = prop;
                break;
            }
        }

        if (!schema.primaryKeyProperty) {
            NSString *message = [NSString stringWithFormat:@"Primary key property '%@' does not exist on object '%@'",
                                 primaryKey, className];
            @throw [NSException exceptionWithName:@"RLMException" reason:message userInfo:nil];
        }
        if (schema.primaryKeyProperty.type != RLMPropertyTypeInt && schema.primaryKeyProperty.type != RLMPropertyTypeString) {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"Only 'string' and 'int' properties can be designated the primary key"
                                         userInfo:nil];
        }
    }

    return schema;
}

+ (NSArray *)propertiesForClass:(Class)objectClass isSwift:(bool)isSwiftClass {
    NSArray *ignoredProperties = [objectClass ignoredProperties];

    // For Swift classes we need an instance of the object when parsing properties
    id swiftObjectInstance = isSwiftClass ? [[objectClass alloc] init] : nil;

    unsigned int count;
    objc_property_t *props = class_copyPropertyList(objectClass, &count);
    NSMutableArray *propArray = [NSMutableArray arrayWithCapacity:count];
    for (unsigned int i = 0; i < count; i++) {
        NSString *propertyName = @(property_getName(props[i]));
        if ([ignoredProperties containsObject:propertyName]) {
            continue;
        }

        RLMPropertyAttributes atts = [objectClass attributesForProperty:propertyName];
        RLMProperty *prop = nil;
        if (isSwiftClass) {
            prop = [[RLMProperty alloc] initSwiftPropertyWithName:propertyName
                                                       attributes:atts
                                                         property:props[i]
                                                         instance:swiftObjectInstance];
        }
        else {
            prop = [[RLMProperty alloc] initWithName:propertyName attributes:atts property:props[i]];
        }

        if (prop) {
            [propArray addObject:prop];
         }
    }
    free(props);

    if (isSwiftClass) {
        // List<> properties don't show up as objective-C properties due to
        // being generic, so use Swift reflection to get a list of them, and
        // then access their ivars directly
        for (NSString *propName in [objectClass getGenericListPropertyNames:swiftObjectInstance]) {
            Ivar ivar = class_getInstanceVariable(objectClass, propName.UTF8String);
            id value = object_getIvar(swiftObjectInstance, ivar);
            NSString *className = [value _rlmArray].objectClassName;
            [propArray addObject:[[RLMProperty alloc] initSwiftListPropertyWithName:propName
                                                                               ivar:ivar
                                                                    objectClassName:className]];
        }
    }

    return propArray;
}


// generate a schema from a table - specify the custom class name for the dynamic
// class and the name to be used in the schema - used for migrations and dynamic interface
+(instancetype)schemaFromTableForClassName:(NSString *)className realm:(RLMRealm *)realm {
    tightdb::TableRef table = RLMTableForObjectClass(realm, className);
    if (!table) {
        return nil;
    }
    
    // create array of RLMProperties
    size_t count = table->get_column_count();
    NSMutableArray *propArray = [NSMutableArray arrayWithCapacity:count];
    for (size_t col = 0; col < count; col++) {
        // create new property
        NSString *name = RLMStringDataToNSString(table->get_column_name(col).data());
        RLMProperty *prop = [[RLMProperty alloc] initWithName:name
                                                         type:RLMPropertyType(table->get_column_type(col))
                                              objectClassName:nil
                                                   attributes:(RLMPropertyAttributes)0];
        prop.column = col;
        if (prop.type == RLMPropertyTypeObject || prop.type == RLMPropertyTypeArray) {
            // set link type for objects and arrays
            tightdb::TableRef linkTable = table->get_link_target(col);
            prop.objectClassName = RLMClassForTableName(@(linkTable->get_name().data()));
        }

        [propArray addObject:prop];
    }

    // create schema object and set properties
    RLMObjectSchema *schema = [RLMObjectSchema new];
    schema.properties = propArray;
    schema.className = className;

    // get primary key from realm metadata
    NSString *primaryKey = RLMRealmPrimaryKeyForObjectClass(realm, className);
    if (primaryKey) {
        schema.primaryKeyProperty = schema[primaryKey];
        if (!schema.primaryKeyProperty) {
            NSString *reason = [NSString stringWithFormat:@"No property matching primary key '%@'", primaryKey];
            @throw [NSException exceptionWithName:@"RLMException" reason:reason userInfo:nil];
        }
    }

    // for dynamic schema use vanilla RLMObject accessor classes
    schema.objectClass = RLMObject.class;
    schema.accessorClass = RLMObject.class;
    schema.standaloneClass = RLMObject.class;

    return schema;
}

- (id)copyWithZone:(NSZone *)zone {
    RLMObjectSchema *schema = [[RLMObjectSchema allocWithZone:zone] init];
    schema->_objectClass = _objectClass;
    schema->_className = _className;
    schema->_objectClass = _objectClass;
    schema->_accessorClass = _accessorClass;
    schema->_standaloneClass = _standaloneClass;
    schema->_isSwiftClass = _isSwiftClass;

    // call property setter to reset map and primary key
    schema.properties = [[NSArray allocWithZone:zone] initWithArray:_properties copyItems:YES];
    // _table not copied as it's tightdb::Group-specific
    return schema;
}

- (instancetype)shallowCopy {
    RLMObjectSchema *schema = [[RLMObjectSchema alloc] init];
    schema->_objectClass = _objectClass;
    schema->_className = _className;
    schema->_objectClass = _objectClass;
    schema->_accessorClass = _accessorClass;
    schema->_standaloneClass = _standaloneClass;
    schema->_isSwiftClass = _isSwiftClass;

    // reuse propery array, map, and primary key instnaces
    schema->_properties = _properties;
    schema->_propertiesByName = _propertiesByName;
    schema->_primaryKeyProperty = _primaryKeyProperty;

    // _table not copied as it's tightdb::Group-specific
    return schema;
}

- (BOOL)isEqualToObjectSchema:(RLMObjectSchema *)objectSchema {
    if (objectSchema.properties.count != _properties.count) {
        return NO;
    }

    // compare ordered list of properties
    NSArray *otherProperties = objectSchema.properties;
    for (NSUInteger i = 0; i < _properties.count; i++) {
        RLMProperty *p1 = _properties[i], *p2 = otherProperties[i];
        if (p1.type != p2.type ||
            p1.column != p2.column ||
            p1.isPrimary != p2.isPrimary ||
            ![p1.name isEqualToString:p2.name] ||
            !(p1.objectClassName == p2.objectClassName || [p1.objectClassName isEqualToString:p2.objectClassName])) {
            return NO;
        }
    }
    return YES;
}

- (tightdb::Table *)table {
    if (!_table) {
        _table = RLMTableForObjectClass(_realm, _className);
    }
    return _table.get();
}

- (void)setTable:(tightdb::Table *)table {
    _table.reset(table);
}

@end
