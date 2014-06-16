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
#import "RLMQueryUtil.h"
#import "RLMUtil.h"

#import <objc/runtime.h>

@implementation RLMObject

@synthesize realm = _realm;
@synthesize writable = _writable;

// standalone init
-(instancetype)init {
    self = [self initWithRealm:nil schema:RLMSchema.sharedSchema[self.class.className] defaultValues:YES];
    
    // set standalone accessor class
    object_setClass(self, RLMStandaloneAccessorClassForObjectClass(self.class, self.schema));
    
    return self;
}

- (instancetype)initWithRealm:(RLMRealm *)realm
                       schema:(RLMObjectSchema *)schema
                defaultValues:(BOOL)useDefaults {
    self = [super init];
    
    if (self) {
        self.realm = realm;
        self.schema = schema;
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
    NSArray *properties = desc.properties;
    
    // FIXME - this can be optimized by inserting directly into the table
    //  after validation, rather than populating the object first
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
    }
    
    // insert populated object into store
    RLMAddObjectToRealm(obj, realm);

    return obj;
}

-(void)setBackingTable:(tightdb::TableRef)backingTable {
    _backingTable = backingTable;
    _backingTableIndex = backingTable->get_index_in_parent();
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

- (void)setWritable:(BOOL)writable {
    if (!_realm) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Attempting to set writable on object not in a Realm" userInfo:nil];
    }
    
    // set accessor class based on write permission
    // FIXME - we are assuming this is always an accessor subclass
    if (writable) {
        object_setClass(self, RLMAccessorClassForObjectClass(self.superclass, _schema));
    }
    else {
        object_setClass(self, RLMReadOnlyAccessorClassForObjectClass(self.superclass, _schema));
    }
    _writable = writable;
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

+ (RLMArray *)objectsWhere:(id)predicate, ... {
    NSPredicate *outPredicate = nil;
    if (predicate) {
        RLM_PREDICATE(predicate, outPredicate);
    }
    return RLMGetObjects(RLMRealm.defaultRealm, self.className, outPredicate, nil);
}

+ (RLMArray *)objectsOrderedBy:(id)order where:(id)predicate, ... {
    NSPredicate *outPredicate = nil;
    if (predicate) {
        RLM_PREDICATE(predicate, outPredicate);
    }
    return RLMGetObjects(RLMRealm.defaultRealm, self.className, outPredicate, order);
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
