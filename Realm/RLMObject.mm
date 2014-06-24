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


-(instancetype)initWithObject:(id)values {
    id obj = [self init];
    RLMObjectSchema *schema = RLMSchema.sharedSchema[self.class.className];
    
    RLMPopulateObjectWithValues(schema, values, obj);
    
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

+(instancetype)createInRealm:(RLMRealm *)realm withObject:(id)values {
    id obj = [[self alloc] init];
    
    RLMObjectSchema *schema = realm.schema[[self className]];
    
    RLMPopulateObjectWithValues(schema, values, obj);
    
    // insert populated object into store
    RLMAddObjectToRealm(obj, realm);

    return obj;
}

void RLMPopulateObjectWithValues(RLMObjectSchema *schema, id values, id obj) {
    NSArray *properties = schema.properties;
    
    if ([values isKindOfClass:NSDictionary.class]) {
        for (RLMProperty * property in properties) {
            id value = values[property.name];
            if (value) {
                // Validate Value
                if (RLMIsObjectValidForProperty(value, property)) {
                    [obj setValue:value forKeyPath:property.name];
                }
                else {
                    @throw [NSException exceptionWithName:@"RLMException" reason:[NSString stringWithFormat:@"Invalid value type for %@", property.name] userInfo:nil];
                }
            }
        }
    }
    else if ([values isKindOfClass:NSArray.class]) {
        // for arrays use property names as keys
        NSArray *array = values;
        
        if (array.count != properties.count) {
            @throw [NSException exceptionWithName:@"RLMException" reason:@"Invalid array input. Number of array elements does not match number of properties." userInfo:nil];
        }
        
        for (NSUInteger i = 0; i < array.count; i++) {
            id value = values[i];
            RLMProperty *property = properties[i];
            
            // Validate Value
            if (RLMIsObjectValidForProperty(value, property)) {
                [obj setValue:array[i] forKeyPath:property.name];
            }
            else {
                @throw [NSException exceptionWithName:@"RLMException" reason:[NSString stringWithFormat:@"Invalid value type for %@", property.name] userInfo:nil];
            }
        }
    } else {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Values must be provided either as an array or dictionary" userInfo:nil];
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
    return NSStringFromClass(self);
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
