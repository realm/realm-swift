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
#import "RLMSwiftSupport.h"

#import <objc/runtime.h>

@implementation RLMObject

@synthesize realm = _realm;
@synthesize RLMAccessor_writable = _RLMAccessor_writable;
@synthesize RLMAccessor_invalid = _RLMAccessor_invalid;
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
    RLMObjectSchema *desc = RLMSchema.sharedSchema[self.class.className];
    
    RLMPopulateObjectWithValues(desc, values, obj);
    
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
    
    RLMObjectSchema *desc = realm.schema[[self className]];
    
    RLMPopulateObjectWithValues(desc, values, obj);
    
    // insert populated object into store
    RLMAddObjectToRealm(obj, realm);

    return obj;
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

- (void)setRLMAccessor_writable:(BOOL)writable {
    if (!_realm) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Attempting to set writable on object not in a Realm" userInfo:nil];
    }
    
    // set accessor class based on write permission
    // FIXME - we are assuming this is always an accessor subclass
    if (writable) {
        object_setClass(self, RLMAccessorClassForObjectClass(self.superclass, _RLMObject_schema));
    }
    else {
        object_setClass(self, RLMReadOnlyAccessorClassForObjectClass(self.superclass, _RLMObject_schema));
    }
    _RLMAccessor_writable = writable;
}

- (void)setRLMAccessor_invalid:(BOOL)invalid {
    if (!_realm) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Attempting to set writable on object not in a Realm" userInfo:nil];
    }
    
    // set accessor class
    // FIXME - we are assuming this is always an accessor subclass
    if (invalid) {
        object_setClass(self, RLMInvalidAccessorClassForObjectClass(self.superclass, _RLMObject_schema));
    }
    else {
        object_setClass(self, RLMAccessorClassForObjectClass(self.superclass, _RLMObject_schema));
    }
    _RLMAccessor_invalid = invalid;
}

-(id)objectForKeyedSubscript:(NSString *)key {
    return [self valueForKey:key];
}

-(void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
    [self setValue:obj forKey:key];
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

+ (NSString *)className
{
    return RLMParsedClassFromClass(self).name;
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
