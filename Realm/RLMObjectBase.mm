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
#import "RLMArray_Private.hpp"
#import "RLMListBase.h"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.h"
#import "RLMObservation.hpp"
#import "RLMOptionalBase.h"
#import "RLMProperty_Private.h"
#import "RLMRealm_Private.hpp"
#import "RLMSchema_Private.h"
#import "RLMSwiftSupport.h"
#import "RLMUtil.hpp"

using namespace realm;

const NSUInteger RLMDescriptionMaxDepth = 5;

static bool maybeInitObjectSchemaForUnmanaged(RLMObjectBase *obj) {
    obj->_objectSchema = [obj.class sharedSchema];
    if (!obj->_objectSchema) {
        return false;
    }

    // set default values
    if (!obj->_objectSchema.isSwiftClass) {
        NSDictionary *dict = RLMDefaultValuesForObjectSchema(obj->_objectSchema);
        for (NSString *key in dict) {
            [obj setValue:dict[key] forKey:key];
        }
    }

    // set unmanaged accessor class
    object_setClass(obj, obj->_objectSchema.unmanagedClass);
    return true;
}

@implementation RLMObjectBase
// unmanaged init
- (instancetype)init {
    if ((self = [super init])) {
        maybeInitObjectSchemaForUnmanaged(self);
    }
    return self;
}

- (void)dealloc {
    // This can't be a unique_ptr because associated objects are removed
    // *after* c++ members are destroyed and dealloc is called, and we need it
    // to be in a validish state when that happens
    delete _observationInfo;
    _observationInfo = nullptr;
}

static id validatedObjectForProperty(id obj, RLMProperty *prop, RLMSchema *schema) {
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
        RLMArray *objects = [[RLMArray alloc] initWithObjectClassName:objSchema.className];
        for (id el in obj) {
            [objects addObject:[[objSchema.objectClass alloc] initWithValue:el schema:schema]];
        }
        return objects;
    }

    // if not convertible to prop throw
    @throw RLMException(@"Invalid value '%@' for property '%@'", obj, prop.name);
}

- (instancetype)initWithValue:(id)value schema:(RLMSchema *)schema {
    if (!(self = [super init])) {
        return self;
    }

    if (!maybeInitObjectSchemaForUnmanaged(self)) {
        // Don't populate fields from the passed-in object if we're called
        // during schema init
        return self;
    }

    NSArray *properties = _objectSchema.properties;
    if (NSArray *array = RLMDynamicCast<NSArray>(value)) {
        if (array.count != properties.count) {
            @throw RLMException(@"Invalid array input. Number of array elements does not match number of properties.");
        }
        for (NSUInteger i = 0; i < array.count; i++) {
            id propertyValue = validatedObjectForProperty(array[i], properties[i], schema);
            [self setValue:RLMCoerceToNil(propertyValue) forKeyPath:[properties[i] name]];
        }
    }
    else if (value) {
        // assume our object is an NSDictionary or an object with kvc properties
        NSDictionary *defaultValues = nil;
        for (RLMProperty *prop in properties) {
            id obj = RLMValidatedValueForProperty(value, prop.name, _objectSchema.className);

            // get default for nil object
            if (!obj) {
                if (!defaultValues) {
                    defaultValues = RLMDefaultValuesForObjectSchema(_objectSchema);
                }
                obj = defaultValues[prop.name];
            }

            // don't set unspecified properties
            if (!obj) {
                continue;
            }

            obj = validatedObjectForProperty(obj, prop, schema);
            [self setValue:RLMCoerceToNil(obj) forKeyPath:prop.name];
        }
    } else {
        @throw RLMException(@"Must provide a non-nil value.");
    }

    return self;
}

id RLMCreateManagedAccessor(Class cls, __unsafe_unretained RLMRealm *realm, RLMClassInfo *info) {
    RLMObjectBase *obj = [[cls alloc] initWithRealm:realm schema:info->rlmObjectSchema];
    obj->_info = info;
    return obj;
}

- (instancetype)initWithRealm:(__unsafe_unretained RLMRealm *const)realm
                       schema:(RLMObjectSchema *)schema {
    self = [super init];
    if (self) {
        _realm = realm;
        _objectSchema = schema;
    }
    return self;
}

- (id)valueForKey:(NSString *)key {
    if (_observationInfo) {
        return _observationInfo->valueForKey(key);
    }
    return [super valueForKey:key];
}

// Generic Swift properties can't be dynamic, so KVO doesn't work for them by default
- (id)valueForUndefinedKey:(NSString *)key {
    if (Ivar ivar = _objectSchema[key].swiftIvar) {
        return RLMCoerceToNil(object_getIvar(self, ivar));
    }
    return [super valueForUndefinedKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    RLMProperty *property = _objectSchema[key];
    if (Ivar ivar = property.swiftIvar) {
        if (property.type == RLMPropertyTypeArray && [value conformsToProtocol:@protocol(NSFastEnumeration)]) {
            RLMArray *array = [object_getIvar(self, ivar) _rlmArray];
            [array removeAllObjects];
            [array addObjects:value];
        }
        else if (property.optional) {
            RLMOptionalBase *optional = object_getIvar(self, ivar);
            optional.underlyingValue = value;
        }
        return;
    }
    [super setValue:value forUndefinedKey:key];
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
    return [RLMSchema sharedSchemaForClass:self.class];
}

+ (Class)objectUtilClass:(BOOL)isSwift {
    return RLMObjectUtilClass(isSwift);
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

- (RLMRealm *)realm {
    return _realm;
}

- (RLMObjectSchema *)objectSchema {
    return _objectSchema;
}

- (BOOL)isInvalidated {
    // if not unmanaged and our accessor has been detached, we have been deleted
    return self.class == _objectSchema.accessorClass && !_row.is_attached();
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

+ (BOOL)shouldIncludeInDefaultSchema {
    return RLMIsObjectSubclass(self);
}

+ (NSString *)_realmObjectName {
    return nil;
}

- (id)mutableArrayValueForKey:(NSString *)key {
    id obj = [self valueForKey:key];
    if ([obj isKindOfClass:[RLMArray class]]) {
        return obj;
    }
    return [super mutableArrayValueForKey:key];
}

- (void)addObserver:(id)observer
         forKeyPath:(NSString *)keyPath
            options:(NSKeyValueObservingOptions)options
            context:(void *)context {
    if (!_observationInfo) {
        _observationInfo = new RLMObservationInfo(self);
    }
    _observationInfo->recordObserver(_row, _info, _objectSchema, keyPath);

    [super addObserver:observer forKeyPath:keyPath options:options context:context];
}

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    [super removeObserver:observer forKeyPath:keyPath];
    if (_observationInfo)
        _observationInfo->removeObserver();
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    const char *className = class_getName(self);
    const char accessorClassPrefix[] = "RLMAccessor_";
    if (!strncmp(className, accessorClassPrefix, sizeof(accessorClassPrefix) - 1)) {
        if (self.sharedSchema[key]) {
            return NO;
        }
    }

    return [super automaticallyNotifiesObserversForKey:key];
}

@end

RLMRealm *RLMObjectBaseRealm(__unsafe_unretained RLMObjectBase *object) {
    return object ? object->_realm : nil;
}

RLMObjectSchema *RLMObjectBaseObjectSchema(__unsafe_unretained RLMObjectBase *object) {
    return object ? object->_objectSchema : nil;
}

id RLMObjectBaseObjectForKeyedSubscript(RLMObjectBase *object, NSString *key) {
    if (!object) {
        return nil;
    }

    if (object->_realm) {
        return RLMDynamicGetByName(object, key, false);
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
    return o1->_row.get_table() == o2->_row.get_table()
        && o1->_row.get_index() == o2->_row.get_index();
}

id RLMValidatedValueForProperty(id object, NSString *key, NSString *className) {
    @try {
        return [object valueForKey:key];
    }
    @catch (NSException *e) {
        if ([e.name isEqualToString:NSUndefinedKeyException]) {
            @throw RLMException(@"Invalid value '%@' to initialize object of type '%@': missing key '%@'",
                                object, className, key);
        }
        @throw;
    }
}

Class RLMObjectUtilClass(BOOL isSwift) {
    static Class objectUtilObjc = [RLMObjectUtil class];
    static Class objectUtilSwift = NSClassFromString(@"RealmSwiftObjectUtil");
    return isSwift && objectUtilSwift ? objectUtilSwift : objectUtilObjc;
}

@implementation RLMObjectUtil

+ (NSArray *)ignoredPropertiesForClass:(Class)cls {
    return [cls ignoredProperties];
}

+ (NSArray *)indexedPropertiesForClass:(Class)cls {
    return [cls indexedProperties];
}

+ (NSDictionary *)linkingObjectsPropertiesForClass:(Class)cls {
    return [cls linkingObjectsProperties];
}

+ (NSDictionary *)linkingObjectProperties:(__unused id)object {
    return nil;
}

+ (NSArray *)getGenericListPropertyNames:(__unused id)obj {
    return nil;
}

+ (NSDictionary *)getLinkingObjectsProperties:(__unused id)obj {
    return nil;
}

+ (NSDictionary *)getOptionalProperties:(__unused id)obj {
    return nil;
}

+ (NSArray *)requiredPropertiesForClass:(Class)cls {
    return [cls requiredProperties];
}

@end
