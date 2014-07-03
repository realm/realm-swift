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
#import "RLMSchema_Private.h"
#import "RLMObjectStore.h"
#import "RLMQueryUtil.hpp"
#import "RLMUtil.hpp"

#import <objc/runtime.h>

@implementation RLMObject

@synthesize realm = _realm;
@synthesize RLMObject_schema = _RLMObject_schema;

// standalone init
-(instancetype)init {
    self = [self initWithRealm:nil schema:RLMSchema.sharedSchema[self.class.className] defaultValues:YES];

    // set standalone accessor class
    object_setClass(self, RLMStandaloneAccessorClassForObjectClass(self.class, self.RLMObject_schema));
    
    return self;
}


-(instancetype)initWithObject:(id)value {
    id obj = [self init];
    if ([value isKindOfClass:NSArray.class]) {
        RLMPopulateObjectWithArray(obj, value);
    }
    else if ([value isKindOfClass:NSDictionary.class]) {
        RLMPopulateObjectWithDictionary(obj, value);
    }
    else {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Values must be provided either as an array or dictionary"
                                     userInfo:nil];
    }

    return obj;
}

- (instancetype)initWithRealm:(RLMRealm *)realm
                       schema:(RLMObjectSchema *)schema
                defaultValues:(BOOL)useDefaults {
    self = [super init];
    
    if (self) {
        self.realm = realm;
        self.RLMObject_schema = schema;
        if (useDefaults) {
            // set default values
            // FIXME: Cache defaultPropertyValues in this instance
            NSDictionary *dict = [self.class defaultPropertyValues];
            for (NSString *key in dict) {
                [self setValue:dict[key] forKey:key];
            }
        }
    }
    return self;
}

+(instancetype)createInRealm:(RLMRealm *)realm {
    return RLMCreateObjectInRealm(realm, [self className]);;
}

+(instancetype)createInRealm:(RLMRealm *)realm withObject:(id)value {
    return RLMCreateObjectInRealmWithValue(realm, [self className], value);
}

void RLMPopulateObjectWithDictionary(RLMObject *obj, NSDictionary *values) {
    RLMObjectSchema *schema = obj.RLMObject_schema;
    for (NSString *name in values) {
        // Validate Value
        RLMProperty *prop = schema[name];
        if (prop) {
            id value = values[name];
            if (!RLMIsObjectValidForProperty(value, prop)) {
                @throw [NSException exceptionWithName:@"RLMException"
                                               reason:[NSString stringWithFormat:@"Invalid value type for %@", name]
                                             userInfo:nil];
            }
            [obj setValue:value forKeyPath:name];
        }
    }
}

void RLMPopulateObjectWithArray(RLMObject *obj, NSArray *array) {
    NSArray *properties = obj.RLMObject_schema.properties;

    if (array.count != properties.count) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Invalid array input. Number of array elements does not match number of properties." userInfo:nil];
    }
    
    for (NSUInteger i = 0; i < array.count; i++) {
        id value = array[i];
        RLMProperty *property = properties[i];
        
        // Validate Value
        if (!RLMIsObjectValidForProperty(value, property)) {
            @throw [NSException exceptionWithName:@"RLMException" reason:[NSString stringWithFormat:@"Invalid value type for %@", property.name] userInfo:nil];
        }
        [obj setValue:array[i] forKeyPath:property.name];

    }
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

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"
+(instancetype)createInRealm:(RLMRealm *)realm withJSONString:(NSString *)JSONString {
    // parse with NSJSONSerialization
    @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                   reason:@"Not yet implemented" userInfo:nil];
}
#pragma GCC diagnostic pop

-(id)objectForKeyedSubscript:(NSString *)key {
    return RLMDynamicGet(self, key);
}

-(void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
    RLMDynamicSet(self, key, obj);
}

+ (RLMArray *)allObjects {
    return RLMGetObjects(RLMRealm.defaultRealm, self.className, nil, nil);
}

+ (RLMArray *)objectsWithPredicateFormat:(NSString *)predicateFormat, ...
{
    NSPredicate *outPredicate = nil;
    RLM_PREDICATE(predicateFormat, outPredicate);
    return [self objectsWithPredicate:outPredicate];
}

+ (RLMArray *)objectsWithPredicate:(NSPredicate *)predicate
{
    return RLMGetObjects(RLMRealm.defaultRealm, self.className, predicate, nil);
}

- (NSString *)JSONString {
    @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                   reason:@"Not yet implemented" userInfo:nil];
}

+ (NSString *)className {
    const char *className = class_getName(self);
    return [[NSString alloc] initWithBytesNoCopy:(void *)className length:strlen(className) encoding:NSUTF8StringEncoding freeWhenDone:NO];
}

- (NSString *)description
{
    NSString *baseClassName = self.class.className;
    NSMutableString *mString = [NSMutableString stringWithFormat:@"%@ {\n", baseClassName];
    RLMObjectSchema *objectSchema = self.realm.schema[baseClassName];
    
    for (RLMProperty *property in objectSchema.properties) {
        [mString appendFormat:@"\t%@ = %@;\n", property.name, [self[property.name] description]];
    }
    [mString appendString:@"}"];
    
    return [NSString stringWithString:mString];
}

@end
