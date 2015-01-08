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

#import "RLMObject_Private.h"

#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.hpp"
#import "RLMProperty_Private.h"
#import "RLMSwiftSupport.h"
#import "RLMUtil.hpp"

@implementation RLMObjectBase


// standalone init
- (instancetype)init {
    return [self initWithObjectSchema:[self.class sharedSchema]];
}

- (instancetype)initWithObjectSchema:(RLMObjectSchema *)schema {
    if (RLMSchema.sharedSchema) {
        self = [self initWithRealm:nil schema:schema defaultValues:YES];

        // set standalone accessor class
        object_setClass(self, self.objectSchema.standaloneClass);
    }
    else {
        // if schema not initialized
        // this is only used for introspection
        self = [super init];
    }

    return self;
}

- (instancetype)initWithObject:(id)value {
    return [self initWithObject:value schema:RLMSchema.sharedSchema];
}

- (instancetype)initWithObject:(id)value schema:(RLMSchema *)schema {
    self = [self init];
    if (NSArray *array = RLMDynamicCast<NSArray>(value)) {
        // validate and populate
        array = RLMValidatedArrayForObjectSchema(array, _objectSchema, schema);
        NSArray *properties = _objectSchema.properties;
        for (NSUInteger i = 0; i < array.count; i++) {
            [self setValue:array[i] forKeyPath:[properties[i] name]];
        }
    }
    else {
        // assume our object is an NSDictionary or a an object with kvc properties
        NSDictionary *dict = RLMValidatedDictionaryForObjectSchema(value, _objectSchema, schema);
        for (NSString *name in dict) {
            id val = dict[name];
            // strip out NSNull before passing values to standalone setters
            if (val == NSNull.null) {
                val = nil;
            }
            [self setValue:val forKeyPath:name];
        }
    }

    return self;
}

- (instancetype)initWithRealm:(__unsafe_unretained RLMRealm *)realm
                       schema:(__unsafe_unretained RLMObjectSchema *)schema
                defaultValues:(BOOL)useDefaults {
    self = [super init];
    if (self) {
        _realm = realm;
        _objectSchema = schema;
        if (useDefaults) {
            // set default values
            NSDictionary *dict = [self.class defaultPropertyValues];
            for (NSString *key in dict) {
                [self setValue:dict[key] forKey:key];
            }
        }
    }
    return self;
}

// default attributes for property implementation
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-parameter"
+ (RLMPropertyAttributes)attributesForProperty:(NSString *)propertyName {
    return (RLMPropertyAttributes)0;
    // FIXME: return RLMPropertyAttributeDeleteNever;
}
#pragma clang diagnostic pop

// default default values implementation
+ (NSDictionary *)defaultPropertyValues {
    return nil;
}

// default ignored properties implementation
+ (NSArray *)ignoredProperties {
    return nil;
}

// default primaryKey implementation
+ (NSString *)primaryKey {
    return nil;
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

- (NSArray *)linkingObjectsOfClass:(NSString *)className forProperty:(NSString *)property {
    if (!_realm) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Linking object only available for objects in a Realm."
                                     userInfo:nil];
    }
    RLMCheckThread(_realm);

    if (!_row.is_attached()) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Object has been deleted or invalidated and is no longer valid."
                                     userInfo:nil];
    }

    RLMObjectSchema *schema = _realm.schema[className];
    RLMProperty *prop = schema[property];
    if (!prop) {
        @throw [NSException exceptionWithName:@"RLMException" reason:[NSString stringWithFormat:@"Invalid property '%@'", property] userInfo:nil];
    }

    if (![prop.objectClassName isEqualToString:_objectSchema.className]) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:[NSString stringWithFormat:@"Property '%@' of '%@' expected to be an RLMObject or RLMArray property pointing to type '%@'", property, className, _objectSchema.className]
                                     userInfo:nil];
    }

    Table *table = schema.table;
    if (!table) {
        return @[];
    }
    
    size_t col = prop.column;
    NSUInteger count = _row.get_backlink_count(*table, col);
    NSMutableArray *links = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger i = 0; i < count; i++) {
        [links addObject:RLMCreateObjectAccessor(_realm, schema, _row.get_backlink(*table, col, i))];
    }
    return [links copy];
}

- (id)objectForKeyedSubscript:(NSString *)key {
    if (_realm) {
        return RLMDynamicGet(self, key);
    }
    else {
        return [self valueForKey:key];
    }
}

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
    if (_realm) {
        RLMDynamicValidatedSet(self, key, obj);
    }
    else {
        [self setValue:obj forKey:key];
    }
}

- (NSString *)description
{
    if (self.isInvalidated) {
        return @"[invalid object]";
    }

    return [self descriptionWithMaxDepth:5];
}

- (NSString *)descriptionWithMaxDepth:(NSUInteger)depth {
    if (depth == 0) {
        return @"<Maximum depth exceeded>";
    }

    RLMObjectSchema *objectSchema = self.objectSchema;
    NSString *baseClassName = objectSchema.className;
    NSMutableString *mString = [NSMutableString stringWithFormat:@"%@ {\n", baseClassName];

    for (RLMProperty *property in objectSchema.properties) {
        id object = self[property.name];
        NSString *sub;
        if ([object respondsToSelector:@selector(descriptionWithMaxDepth:)]) {
            sub = [object descriptionWithMaxDepth:depth - 1];
        }
        else {
            sub = [object description];
        }
        [mString appendFormat:@"\t%@ = %@;\n", property.name, sub];
    }
    [mString appendString:@"}"];

    return [NSString stringWithString:mString];
}

- (BOOL)isInvalidated {
    // if not standalone and our accessor has been detached, we have been deleted
    return self.class == self.objectSchema.accessorClass && !_row.is_attached();
}

- (BOOL)isDeletedFromRealm {
    return self.isInvalidated;
}

- (BOOL)isEqualToObject:(RLMObject *)object {
    // if identical object
    if (self == object) {
        return YES;
    }
    // if not in realm or differing realms
    if (_realm == nil || _realm != object.realm) {
        return NO;
    }
    // if either are detached
    if (!_row.is_attached() || !object->_row.is_attached()) {
        return NO;
    }
    // if table and index are the same
    return _row.get_table() == object->_row.get_table() && _row.get_index() == object->_row.get_index();
}

- (BOOL)isEqual:(id)object {
    if (_objectSchema.primaryKeyProperty) {
        return [self isEqualToObject:object];
    }
    else {
        return [super isEqual:object];
    }
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

@end