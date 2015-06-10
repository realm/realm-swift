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

#import "RLMObject_Private.hpp"

#import "RLMAccessor.h"
#import "RLMObjectSchema_Private.hpp"
#import "RLMProperty_Private.h"
#import "RLMRealm_Private.hpp"
#import "RLMSchema_Private.h"
#import "RLMArray_Private.hpp"

#import "RLMObjectStore.h"
#import "RLMSwiftSupport.h"
#import "RLMUtil.hpp"

const NSUInteger RLMDescriptionMaxDepth = 5;

@implementation RLMObjectBase

// standalone init
- (instancetype)init {
    self = [super init];
    if (self && RLMSchema.sharedSchema) {
        _objectSchema = [self.class sharedSchema];

        // set default values
        if (!_objectSchema.isSwiftClass) {
            NSDictionary *dict = RLMDefaultValuesForObjectSchema(_objectSchema);
            for (NSString *key in dict) {
                [self setValue:dict[key] forKey:key];
            }
        }

        // set standalone accessor class
        object_setClass(self, _objectSchema.standaloneClass);
    }

    return self;
}

static id RLMValidatedObjectForProperty(id obj, RLMProperty *prop, RLMSchema *schema) {
    if (RLMIsObjectValidForProperty(obj, prop)) {
        return obj;
    }

    // check for object or array of properties
    if (prop.type == RLMPropertyTypeObject) {
        // for object create and try to initialize with obj
        RLMObjectSchema *objSchema = schema[prop.objectClassName];
        return [[objSchema.objectClass alloc] initWithValue:obj schema:schema];
    }
    else if (prop.type == RLMPropertyTypeArray && [obj conformsToProtocol:@protocol(NSFastEnumeration)]) {
        // for arrays, create objects for each element and return new array
        RLMObjectSchema *objSchema = schema[prop.objectClassName];
        RLMArray *objects = [[RLMArray alloc] initWithObjectClassName: objSchema.className standalone:YES];
        for (id el in obj) {
            [objects addObject:[[objSchema.objectClass alloc] initWithValue:el schema:schema]];
        }
        return objects;
    }

    // if not convertible to prop throw
    @throw RLMException([NSString stringWithFormat:@"Invalid value '%@' for property '%@'", obj, prop.name]);
}

- (instancetype)initWithValue:(id)value schema:(RLMSchema *)schema {
    self = [self init];
    NSArray *properties = _objectSchema.properties;
    if (NSArray *array = RLMDynamicCast<NSArray>(value)) {
        if (array.count != properties.count) {
            @throw RLMException(@"Invalid array input. Number of array elements does not match number of properties.");
        }
        for (NSUInteger i = 0; i < array.count; i++) {
            [self setValue:RLMValidatedObjectForProperty(array[i], properties[i], schema) forKeyPath:[properties[i] name]];
        }
    }
    else {
        // assume our object is an NSDictionary or an object with kvc properties
        NSDictionary *defaultValues = nil;
        for (RLMProperty *prop in properties) {
            id obj = [value valueForKey:prop.name];

            // get default for nil object
            if (!obj) {
                if (!defaultValues) {
                    defaultValues = RLMDefaultValuesForObjectSchema(_objectSchema);
                }
                obj = defaultValues[prop.name];
            }

            [self setValue:RLMValidatedObjectForProperty(obj, prop, schema) forKeyPath:prop.name];
        }
    }

    return self;
}

- (instancetype)initWithRealm:(__unsafe_unretained RLMRealm *const)realm
                       schema:(__unsafe_unretained RLMObjectSchema *const)schema {
    self = [super init];
    if (self) {
        _realm = realm;
        _objectSchema = schema;
    }
    return self;
}

// overridden at runtime per-class for performance
+ (NSString *)className {
    NSString *className = NSStringFromClass(self);
    if ([RLMSwiftSupport isSwiftClassName:className]) {
        className = [RLMSwiftSupport demangleClassName:className];
    }
    return className;
}

// overridden at runtime per-class for performance
+ (RLMObjectSchema *)sharedSchema {
    return RLMSchema.sharedSchema[self.className];
}

- (NSString *)description
{
    if (self.isInvalidated) {
        return @"[invalid object]";
    }

    return [self descriptionWithMaxDepth:RLMDescriptionMaxDepth];
}

- (NSString *)descriptionWithMaxDepth:(NSUInteger)depth {
    if (depth == 0) {
        return @"<Maximum depth exceeded>";
    }

    NSString *baseClassName = _objectSchema.className;
    NSMutableString *mString = [NSMutableString stringWithFormat:@"%@ {\n", baseClassName];

    for (RLMProperty *property in _objectSchema.properties) {
        id object = RLMObjectBaseObjectForKeyedSubscript(self, property.name);
        NSString *sub;
        if ([object respondsToSelector:@selector(descriptionWithMaxDepth:)]) {
            sub = [object descriptionWithMaxDepth:depth - 1];
        }
        else if (property.type == RLMPropertyTypeData) {
            static NSUInteger maxPrintedDataLength = 24;
            NSData *data = object;
            NSUInteger length = data.length;
            if (length > maxPrintedDataLength) {
                data = [NSData dataWithBytes:data.bytes length:maxPrintedDataLength];
            }
            NSString *dataDescription = [data description];
            sub = [NSString stringWithFormat:@"<%@ — %lu total bytes>", [dataDescription substringWithRange:NSMakeRange(1, dataDescription.length - 2)], (unsigned long)length];
        }
        else {
            sub = [object description];
        }
        [mString appendFormat:@"\t%@ = %@;\n", property.name, [sub stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\t"]];
    }
    [mString appendString:@"}"];

    return [NSString stringWithString:mString];
}

- (BOOL)isInvalidated {
    // if not standalone and our accessor has been detached, we have been deleted
    return self.class == _objectSchema.accessorClass && !_row.is_attached();
}

- (BOOL)isDeletedFromRealm {
    return self.isInvalidated;
}

- (BOOL)isEqual:(id)object {
    if (RLMObjectBase *other = RLMDynamicCast<RLMObjectBase>(object)) {
        if (_objectSchema.primaryKeyProperty) {
            return RLMObjectBaseAreEqual(self, other);
        }
    }
    return [super isEqual:object];
}

- (NSUInteger)hash {
    if (_objectSchema.primaryKeyProperty) {
        id primaryProperty = [self valueForKey:_objectSchema.primaryKeyProperty.name];

        // modify the hash of our primary key value to avoid potential (although unlikely) collisions
        return [primaryProperty hash] ^ 1;
    }
    else {
        return [super hash];
    }
}

+ (BOOL)shouldPersistToRealm {
    return RLMIsObjectSubclass(self);
}

@end



void RLMObjectBaseSetRealm(__unsafe_unretained RLMObjectBase *object, __unsafe_unretained RLMRealm *realm) {
    if (object) {
        object->_realm = realm;
    }
}

RLMRealm *RLMObjectBaseRealm(__unsafe_unretained RLMObjectBase *object) {
    return object ? object->_realm : nil;
}

void RLMObjectBaseSetObjectSchema(__unsafe_unretained RLMObjectBase *object, __unsafe_unretained RLMObjectSchema *objectSchema) {
    if (object) {
        object->_objectSchema = objectSchema;
    }
}

RLMObjectSchema *RLMObjectBaseObjectSchema(__unsafe_unretained RLMObjectBase *object) {
    return object ? object->_objectSchema : nil;
}

NSArray *RLMObjectBaseLinkingObjectsOfClass(RLMObjectBase *object, NSString *className, NSString *property) {
    if (!object) {
        return nil;
    }

    if (!object->_realm) {
        @throw RLMException(@"Linking object only available for objects in a Realm.");
    }
    RLMCheckThread(object->_realm);

    if (!object->_row.is_attached()) {
        @throw RLMException(@"Object has been deleted or invalidated and is no longer valid.");
    }

    RLMObjectSchema *schema = object->_realm.schema[className];
    RLMProperty *prop = schema[property];
    if (!prop) {
        @throw RLMException([NSString stringWithFormat:@"Invalid property '%@'", property]);
    }

    if (![prop.objectClassName isEqualToString:object->_objectSchema.className]) {
        @throw RLMException([NSString stringWithFormat:@"Property '%@' of '%@' expected to be an RLMObject or RLMArray property pointing to type '%@'", property, className, object->_objectSchema.className]);
    }

    Table *table = schema.table;
    if (!table) {
        return @[];
    }

    size_t col = prop.column;
    NSUInteger count = object->_row.get_backlink_count(*table, col);
    NSMutableArray *links = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger i = 0; i < count; i++) {
        [links addObject:RLMCreateObjectAccessor(object->_realm, schema, object->_row.get_backlink(*table, col, i))];
    }
    return [links copy];
}

id RLMObjectBaseObjectForKeyedSubscript(RLMObjectBase *object, NSString *key) {
    if (!object) {
        return nil;
    }

    if (object->_realm) {
        return RLMDynamicGet(object, key);
    }
    else {
        return [object valueForKey:key];
    }
}

void RLMObjectBaseSetObjectForKeyedSubscript(RLMObjectBase *object, NSString *key, id obj) {
    if (!object) {
        return;
    }

    if (object->_realm) {
        RLMDynamicValidatedSet(object, key, obj);
    }
    else {
        [object setValue:obj forKey:key];
    }
}


BOOL RLMObjectBaseAreEqual(RLMObjectBase *o1, RLMObjectBase *o2) {
    // if not the correct types throw
    if ((o1 && ![o1 isKindOfClass:RLMObjectBase.class]) || (o2 && ![o2 isKindOfClass:RLMObjectBase.class])) {
        @throw RLMException(@"Can only compare objects of class RLMObjectBase");
    }
    // if identical object (or both are nil)
    if (o1 == o2) {
        return YES;
    }
    // if one is nil
    if (o1 == nil || o2 == nil) {
        return NO;
    }
    // if not in realm or differing realms
    if (o1->_realm == nil || o1->_realm != o2->_realm) {
        return NO;
    }
    // if either are detached
    if (!o1->_row.is_attached() || !o2->_row.is_attached()) {
        return NO;
    }
    // if table and index are the same
    return o1->_row.get_table() == o2->_row.get_table() &&
    o1->_row.get_index() == o2->_row.get_index();
}


Class RLMObjectUtilClass(BOOL isSwift) {
    static Class objectUtilObjc = [RLMObjectUtil class];
    static Class objectUtilSwift = NSClassFromString(@"RealmSwift.ObjectUtil");
    return isSwift && objectUtilSwift ? objectUtilSwift : objectUtilObjc;
}

@implementation RLMObjectUtil

+ (NSArray *)ignoredPropertiesForClass:(Class)cls {
    return [cls ignoredProperties];
}

+ (NSArray *)indexedPropertiesForClass:(Class)cls {
    return [cls indexedProperties];
}

+ (NSArray *)getGenericListPropertyNames:(__unused id)obj {
    return nil;
}

+ (void)initializeListProperty:(__unused RLMObjectBase *)object property:(__unused RLMProperty *)property array:(__unused RLMArray *)array {
}

@end
