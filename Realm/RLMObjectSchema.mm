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

#import "RLMObjectSchema_Private.hpp"

#import "RLMArray.h"
#import "RLMListBase.h"
#import "RLMObject_Private.h"
#import "RLMProperty_Private.h"
#import "RLMRealm_Dynamic.h"
#import "RLMRealm_Private.hpp"
#import "RLMSchema_Private.h"
#import "RLMSwiftSupport.h"
#import "RLMUtil.hpp"

#import "object_store.hpp"

using namespace realm;

// private properties
@interface RLMObjectSchema ()
@property (nonatomic, readwrite) NSDictionary RLM_GENERIC(id, RLMProperty *) *propertiesByName;
@property (nonatomic, readwrite) NSString *className;
@end

@implementation RLMObjectSchema {
    // table accessor optimization
    realm::TableRef _table;
    NSArray *_propertiesInDeclaredOrder;
}

- (instancetype)initWithClassName:(NSString *)objectClassName objectClass:(Class)objectClass properties:(NSArray *)properties {
    self = [super init];
    self.className = objectClassName;
    self.properties = properties;
    self.objectClass = objectClass;
    self.accessorClass = objectClass;
    self.standaloneClass = objectClass;
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
    _propertiesInDeclaredOrder = nil;
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
    schema.accessorClass = RLMDynamicObject.class;
    schema.isSwiftClass = isSwift;

    // create array of RLMProperties, inserting properties of superclasses first
    Class cls = objectClass;
    Class superClass = class_getSuperclass(cls);
    NSArray *props = @[];
    while (superClass && superClass != RLMObjectBase.class) {
        props = [[RLMObjectSchema propertiesForClass:cls isSwift:isSwift] arrayByAddingObjectsFromArray:props];
        cls = superClass;
        superClass = class_getSuperclass(superClass);
    }
    NSUInteger index = 0;
    for (RLMProperty *prop in props) {
        prop.declarationIndex = index++;
    }
    schema.properties = props;

    // verify that we didn't add any properties twice due to inheritance
    if (props.count != [NSSet setWithArray:[props valueForKey:@"name"]].count) {
        NSCountedSet *countedPropertyNames = [NSCountedSet setWithArray:[props valueForKey:@"name"]];
        NSSet *duplicatePropertyNames = [countedPropertyNames filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *) {
            return [countedPropertyNames countForObject:object] > 1;
        }]];

        if (duplicatePropertyNames.count == 1) {
            @throw RLMException(@"Property '%@' is declared multiple times in the class hierarchy of '%@'", duplicatePropertyNames.allObjects.firstObject, className);
        } else {
            @throw RLMException(@"Object '%@' has properties that are declared multiple times in its class hierarchy: '%@'", className, [duplicatePropertyNames.allObjects componentsJoinedByString:@"', '"]);
        }
    }

    if (NSString *primaryKey = [objectClass primaryKey]) {
        for (RLMProperty *prop in schema.properties) {
            if ([primaryKey isEqualToString:prop.name]) {
                prop.indexed = YES;
                schema.primaryKeyProperty = prop;
                break;
            }
        }

        if (!schema.primaryKeyProperty) {
            @throw RLMException(@"Primary key property '%@' does not exist on object '%@'", primaryKey, className);
        }
        if (schema.primaryKeyProperty.type != RLMPropertyTypeInt && schema.primaryKeyProperty.type != RLMPropertyTypeString) {
            @throw RLMException(@"Only 'string' and 'int' properties can be designated the primary key");
        }
    }

    for (RLMProperty *prop in schema.properties) {
        RLMPropertyType type = prop.type;
        if (prop.optional && !RLMPropertyTypeIsNullable(type)) {
            NSString *error = [NSString stringWithFormat:@"Only 'string', 'binary', and 'object' properties can be made optional, and property '%@' is of type '%@'.", prop.name, RLMTypeToString(type)];
            if (prop.type == RLMPropertyTypeAny && isSwift) {
                error = [error stringByAppendingString:@"\nIf this is a 'String?' property, it must be declared as 'NSString?' instead."];
            }
            @throw RLMException(@"%@", error);
        }
    }

    return schema;
}

+ (NSArray *)propertiesForClass:(Class)objectClass isSwift:(bool)isSwiftClass {
    Class objectUtil = RLMObjectUtilClass(isSwiftClass);
    NSArray *ignoredProperties = [objectUtil ignoredPropertiesForClass:objectClass];

    // For Swift classes we need an instance of the object when parsing properties
    id swiftObjectInstance = isSwiftClass ? [[objectClass alloc] init] : nil;

    unsigned int count;
    objc_property_t *props = class_copyPropertyList(objectClass, &count);
    NSMutableArray *propArray = [NSMutableArray arrayWithCapacity:count];
    NSSet *indexed = [[NSSet alloc] initWithArray:[objectUtil indexedPropertiesForClass:objectClass]];
    for (unsigned int i = 0; i < count; i++) {
        NSString *propertyName = @(property_getName(props[i]));
        if ([ignoredProperties containsObject:propertyName]) {
            continue;
        }

        RLMProperty *prop = nil;
        if (isSwiftClass) {
            prop = [[RLMProperty alloc] initSwiftPropertyWithName:propertyName
                                                          indexed:[indexed containsObject:propertyName]
                                                         property:props[i]
                                                         instance:swiftObjectInstance];
        }
        else {
            prop = [[RLMProperty alloc] initWithName:propertyName indexed:[indexed containsObject:propertyName] property:props[i]];
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
        for (NSString *propName in [objectUtil getGenericListPropertyNames:swiftObjectInstance]) {
            Ivar ivar = class_getInstanceVariable(objectClass, propName.UTF8String);
            id value = object_getIvar(swiftObjectInstance, ivar);
            NSString *className = [value _rlmArray].objectClassName;
            NSUInteger existing = [propArray indexOfObjectPassingTest:^BOOL(RLMProperty *obj, __unused NSUInteger idx, __unused BOOL *stop) {
                return [obj.name isEqualToString:propName];
            }];
            if (existing != NSNotFound) {
                [propArray removeObjectAtIndex:existing];
            }
            [propArray addObject:[[RLMProperty alloc] initSwiftListPropertyWithName:propName
                                                                               ivar:ivar
                                                                    objectClassName:className]];
        }
    }

    if (auto optionalProperties = [objectUtil getOptionalProperties:swiftObjectInstance]) {
        for (RLMProperty *property in propArray) {
            property.optional = false;
        }
        [optionalProperties enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSNumber *propertyType, __unused BOOL *stop) {
            if ([ignoredProperties containsObject:propertyName]) {
                return;
            }
            NSUInteger existing = [propArray indexOfObjectPassingTest:^BOOL(RLMProperty *obj, __unused NSUInteger idx, __unused BOOL *stop) {
                return [obj.name isEqualToString:propertyName];
            }];
            RLMProperty *property;
            if (existing != NSNotFound) {
                property = propArray[existing];
                property.optional = true;
            }
            if (auto type = RLMCoerceToNil(propertyType)) {
                if (existing == NSNotFound) {
                    property = [[RLMProperty alloc] initSwiftOptionalPropertyWithName:propertyName
                                                                              indexed:[indexed containsObject:propertyName]
                                                                                 ivar:class_getInstanceVariable(objectClass, propertyName.UTF8String)
                                                                         propertyType:RLMPropertyType(type.intValue)];
                    [propArray addObject:property];
                }
                else {
                    property.type = RLMPropertyType(type.intValue);
                }
            }
        }];
    }
    if (auto requiredProperties = [objectUtil requiredPropertiesForClass:objectClass]) {
        for (RLMProperty *property in propArray) {
            bool required = [requiredProperties containsObject:property.name];
            if (required && property.type == RLMPropertyTypeObject) {
                @throw RLMException(@"Object properties cannot be made required, "
                                    "but '+[%@ requiredProperties]' included '%@'", objectClass, property.name);
            }
            property.optional &= !required;
        }
    }

    for (RLMProperty *property in propArray) {
        if (!property.optional && property.type == RLMPropertyTypeObject) { // remove if/when core supports required link columns
            @throw RLMException(@"The `%@.%@` property must be marked as being optional.", [objectClass className], property.name);
        }
    }

    return propArray;
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

    // _table not copied as it's realm::Group-specific
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

    // _table not copied as it's realm::Group-specific
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
            p1.optional != p2.optional ||
            ![p1.name isEqualToString:p2.name] ||
            !(p1.objectClassName == p2.objectClassName || [p1.objectClassName isEqualToString:p2.objectClassName])) {
            return NO;
        }
    }
    return YES;
}

- (NSString *)description {
    NSMutableString *propertiesString = [NSMutableString string];
    for (RLMProperty *property in self.properties) {
        [propertiesString appendFormat:@"\t%@\n", [property.description stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\t"]];
    }
    return [NSString stringWithFormat:@"%@ {\n%@}", self.className, propertiesString];
}

- (realm::Table *)table {
    if (!_table) {
        _table = ObjectStore::table_for_object_type(_realm.group, _className.UTF8String);
    }
    return _table.get();
}

- (void)setTable:(realm::Table *)table {
    _table.reset(table);
}

- (realm::ObjectSchema)objectStoreCopy {
    ObjectSchema objectSchema;
    objectSchema.name = _className.UTF8String;
    objectSchema.primary_key = _primaryKeyProperty ? _primaryKeyProperty.name.UTF8String : "";
    for (RLMProperty *prop in _properties) {
        Property p;
        p.name = prop.name.UTF8String;
        p.type = (PropertyType)prop.type;
        p.object_type = prop.objectClassName ? prop.objectClassName.UTF8String : "";
        p.is_indexed = prop.indexed;
        p.is_primary = (prop == _primaryKeyProperty);
        p.is_nullable = prop.optional;
        objectSchema.properties.push_back(std::move(p));
    }
    return objectSchema;
}

+ (instancetype)objectSchemaForObjectStoreSchema:(realm::ObjectSchema &)objectSchema {
    RLMObjectSchema *schema = [RLMObjectSchema new];
    schema.className = @(objectSchema.name.c_str());

    // create array of RLMProperties
    NSMutableArray *propArray = [NSMutableArray arrayWithCapacity:objectSchema.properties.size()];
    for (Property &prop : objectSchema.properties) {
        RLMProperty *property = [[RLMProperty alloc] initWithName:@(prop.name.c_str())
                                                             type:(RLMPropertyType)prop.type
                                                  objectClassName:prop.object_type.length() ? @(prop.object_type.c_str()) : nil
                                                          indexed:prop.is_indexed
                                                         optional:prop.is_nullable];
        property.isPrimary = (prop.name == objectSchema.primary_key);
        [propArray addObject:property];
    }
    schema.properties = propArray;
    
    // get primary key from realm metadata
    if (objectSchema.primary_key.length()) {
        NSString *primaryKeyString = [NSString stringWithUTF8String:objectSchema.primary_key.c_str()];
        schema.primaryKeyProperty = schema[primaryKeyString];
        if (!schema.primaryKeyProperty) {
            @throw RLMException(@"No property matching primary key '%@'", primaryKeyString);
        }
    }

    // for dynamic schema use vanilla RLMDynamicObject accessor classes
    schema.objectClass = RLMObject.class;
    schema.accessorClass = RLMDynamicObject.class;
    schema.standaloneClass = RLMObject.class;
    
    return schema;
}

- (void)sortPropertiesByColumn {
    _properties = [_properties sortedArrayUsingComparator:^NSComparisonResult(RLMProperty *p1, RLMProperty *p2) {
        if (p1.column < p2.column) return NSOrderedAscending;
        if (p1.column > p2.column) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    // No need to update the dictionary
}

- (NSArray *)propertiesInDeclaredOrder {
    if (!_propertiesInDeclaredOrder) {
        _propertiesInDeclaredOrder = [_properties sortedArrayUsingComparator:^NSComparisonResult(RLMProperty *p1, RLMProperty *p2) {
            if (p1.declarationIndex < p2.declarationIndex) return NSOrderedAscending;
            if (p1.declarationIndex > p2.declarationIndex) return NSOrderedDescending;
            return NSOrderedSame;
        }];
    }
    return _propertiesInDeclaredOrder;
}

@end
