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

#import "RLMSchema_Private.h"

#import "RLMAccessor.h"
#import "RLMObject_Private.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMProperty_Private.h"
#import "RLMRealm_Private.hpp"
#import "RLMSwiftSupport.h"
#import "RLMUtil.hpp"

#include <mutex>
#import "object_store.hpp"
#import <objc/runtime.h>
#import <realm/group.hpp>

using namespace realm;

const uint64_t RLMNotVersioned = realm::ObjectStore::NotVersioned;

// RLMSchema private properties
@interface RLMSchema ()
@property (nonatomic, readwrite) NSMutableDictionary *objectSchemaByName;
@end

static RLMSchema *s_sharedSchema;
static RLMSchema *s_partialSharedSchema = [[RLMSchema alloc] init];
static NSMutableDictionary *s_localNameToClass = [[NSMutableDictionary alloc] init];

@implementation RLMSchema

+ (instancetype)schemaWithObjectClasses:(NSArray *)classes {
    NSUInteger count = classes.count;
    auto classArray = std::make_unique<__unsafe_unretained Class[]>(count);
    [classes getObjects:classArray.get() range:NSMakeRange(0, count)];
    [self registerClasses:classArray.get() count:count];

    RLMSchema *schema = [[self alloc] init];
    NSMutableArray *schemas = [NSMutableArray arrayWithCapacity:count];
    for (Class cls in classes) {
        if (!RLMIsObjectSubclass(cls)) {
            @throw RLMException([NSString stringWithFormat:@"Can't add non-Object type '%@' to a schema.", cls]);
        }
        [schemas addObject:[cls sharedSchema]];
    }
    schema.objectSchema = schemas;

    NSMutableArray *errors = [NSMutableArray new];
    // Verify that all of the targets of links are included in the class list
    for (RLMObjectSchema *objectSchema in schema->_objectSchema) {
        for (RLMProperty *prop in objectSchema.properties) {
            if (prop.type != RLMPropertyTypeObject && prop.type != RLMPropertyTypeArray) {
                continue;
            }
            if (!schema->_objectSchemaByName[prop.objectClassName]) {
                [errors addObject:[NSString stringWithFormat:@"- '%@.%@' links to class '%@', which is missing from the list of classes to persist", objectSchema.className, prop.name, prop.objectClassName]];
            }
        }
    }
    if (errors.count) {
        @throw RLMException([@"Invalid class subset list:\n" stringByAppendingString:[errors componentsJoinedByString:@"\n"]]);
    }

    return schema;
}

- (RLMObjectSchema *)schemaForClassName:(NSString *)className {
    return _objectSchemaByName[className];
}

- (RLMObjectSchema *)objectForKeyedSubscript:(__unsafe_unretained id<NSCopying> const)className {
    RLMObjectSchema *schema = _objectSchemaByName[className];
    if (!schema) {
        NSString *message = [NSString stringWithFormat:@"Object type '%@' not persisted in Realm", className];
        @throw RLMException(message);
    }
    return schema;
}

- (void)setObjectSchema:(NSArray *)objectSchema {
    _objectSchema = objectSchema;
    _objectSchemaByName = [NSMutableDictionary dictionaryWithCapacity:objectSchema.count];
    for (RLMObjectSchema *object in objectSchema) {
        [(NSMutableDictionary *)_objectSchemaByName setObject:object forKey:object.className];
    }
}

+ (instancetype)partialSharedSchema {
    return s_partialSharedSchema;
}

+ (void)registerClasses:(Class *)classes count:(NSUInteger)count {
    auto newClasses = [NSMutableArray new];
    auto threadID = pthread_mach_thread_np(pthread_self());

    @synchronized(s_localNameToClass) {
        // first create class to name mapping so we can do array validation
        // when creating object schema
        for (NSUInteger i = 0; i < count; i++) {
            Class cls = classes[i];

            if (!RLMIsObjectSubclass(cls) || RLMIsGeneratedClass(cls)) {
                continue;
            }

            NSString *className = NSStringFromClass(cls);
            if ([RLMSwiftSupport isSwiftClassName:className]) {
                className = [RLMSwiftSupport demangleClassName:className];
            }
            // NSStringFromClass demangles the names for top-level Swift classes
            // but not for nested classes. _T indicates it's a Swift symbol, t
            // indicates it's a type, and C indicates it's a class.
            else if ([className hasPrefix:@"_TtC"]) {
                NSString *message = [NSString stringWithFormat:@"RLMObject subclasses cannot be nested within other declarations. Please move %@ to global scope.", className];
                @throw RLMException(message);
            }

            if (Class existingClass = s_localNameToClass[className]) {
                if (existingClass != cls) {
                    NSString *message = [NSString stringWithFormat:@"RLMObject subclasses with the same name cannot be included twice in the same target. Please make sure '%@' is only linked once to your current target.", className];
                    @throw RLMException(message);
                }
                continue;
            }

            s_localNameToClass[className] = cls;
            [newClasses addObject:cls];

            RLMReplaceClassNameMethod(cls, className);
            // override sharedSchema class method to return nil to avoid topo-sort issues when on this thread
            // (i.e. while during schema initialization), but wait on other threads until schema initialization is done,
            // then return the just-initialized schema
            RLMReplaceSharedSchemaMethodWithBlock(cls, ^RLMObjectSchema *(Class cls) {
                if (threadID == pthread_mach_thread_np(pthread_self())) {
                    return nil;
                }
                @synchronized(s_localNameToClass) {
                    return [cls sharedSchema];
                }
            });
        }

        NSMutableArray *schemas = [NSMutableArray arrayWithCapacity:newClasses.count];
        for (Class cls in newClasses) {
            RLMObjectSchema *schema = [RLMObjectSchema schemaForObjectClass:cls];

            // set standalone class on shared shema for standalone object creation
            schema.standaloneClass = RLMStandaloneAccessorClassForObjectClass(schema.objectClass, schema);

            // override sharedSchema classs methods for performance
            RLMReplaceSharedSchemaMethod(cls, schema);

            if ([cls shouldIncludeInDefaultSchema]) {
                [schemas addObject:schema];
            }
        }

        // protected by the @synchronized around s_localNameToClass
        s_partialSharedSchema.objectSchema = [[s_partialSharedSchema objectSchema] arrayByAddingObjectsFromArray:schemas] ?: schemas;
    }
}

// schema based on runtime objects
+ (instancetype)sharedSchema {
    static std::once_flag onceFlag;
    std::call_once(onceFlag, [&](){
        RLMSchema *schema = [[RLMSchema alloc] init];

        unsigned int numClasses;
        std::unique_ptr<__unsafe_unretained Class[], decltype(&free)> classes(objc_copyClassList(&numClasses), &free);
        [self registerClasses:classes.get() count:numClasses];

        // set class array
        schema.objectSchema = s_partialSharedSchema.objectSchema;

        // set shared schema
        s_sharedSchema = schema;
    });
    return s_sharedSchema;
}

// schema based on tables in a realm
+ (instancetype)dynamicSchemaFromRealm:(RLMRealm *)realm {
    // generate object schema and class mapping for all tables in the realm
    ObjectStore::Schema objectStoreSchema = ObjectStore::schema_from_group(realm.group);

    // cache descriptors for all subclasses of RLMObject
    NSMutableArray *schemaArray = [NSMutableArray arrayWithCapacity:objectStoreSchema.size()];
    for (unsigned long i = 0; i < objectStoreSchema.size(); i++) {
        [schemaArray addObject:[RLMObjectSchema objectSchemaForObjectStoreSchema:objectStoreSchema[i]]];
    }

    // set class array and mapping
    RLMSchema *schema = [RLMSchema new];
    schema.objectSchema = schemaArray;
    return schema;
}

+ (Class)classForString:(NSString *)className {
    if (Class cls = s_localNameToClass[className]) {
        return cls;
    }
    return NSClassFromString(className);
}

- (id)copyWithZone:(NSZone *)zone {
    RLMSchema *schema = [[RLMSchema allocWithZone:zone] init];
    schema.objectSchema = [[NSArray allocWithZone:zone] initWithArray:self.objectSchema copyItems:YES];
    return schema;
}

- (instancetype)shallowCopy {
    RLMSchema *schema = [[RLMSchema alloc] init];
    NSMutableArray *objectSchema = [NSMutableArray arrayWithCapacity:_objectSchema.count];
    for (RLMObjectSchema *schema in _objectSchema) {
        [objectSchema addObject:[schema shallowCopy]];
    }
    schema.objectSchema = objectSchema;
    return schema;
}

- (BOOL)isEqualToSchema:(RLMSchema *)schema {
    if (_objectSchema.count != schema.objectSchema.count) {
        return NO;
    }
    for (RLMObjectSchema *objectSchema in schema.objectSchema) {
        if (![_objectSchemaByName[objectSchema.className] isEqualToObjectSchema:objectSchema]) {
            return NO;
        }
    }
    return YES;
}

- (NSString *)description {
    NSMutableString *objectSchemaString = [NSMutableString string];
    for (RLMObjectSchema *objectSchema in self.objectSchema) {
        [objectSchemaString appendFormat:@"\t%@\n", [objectSchema.description stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\t"]];
    }
    return [NSString stringWithFormat:@"Schema {\n%@}", objectSchemaString];
}

@end
