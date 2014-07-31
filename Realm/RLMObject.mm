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
#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.h"
#import "RLMQueryUtil.hpp"
#import "RLMUtil.hpp"
#import "RLMArray.h"
#import "RLMAccessor.h"

#ifdef REALM_SWIFT
#import <Realm/Realm-Swift.h>
#endif

#import <objc/runtime.h>

// Private Category to perform "primitiveSelectors"
@interface NSObject (PrimitiveSelection)
- (void *)performPrimitiveSelector:(SEL)selector;
@end

@implementation NSObject (PrimitiveSelection)
- (void *)performPrimitiveSelector:(SEL)selector {
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
  [invocation setSelector:selector];
  [invocation setTarget:self];

  [invocation invoke];

  NSUInteger length = [[invocation methodSignature] methodReturnLength];

  // If method is non-void:
  if (length > 0) {
    void *buffer = (void *)malloc(length);
    [invocation getReturnValue:buffer];
    return buffer;
  }
  // If method is void:
  return NULL;
}
@end

@implementation RLMObject

@synthesize realm = _realm;
@synthesize objectSchema = _objectSchema;


// standalone init
- (instancetype)init
{
    if (RLMSchema.sharedSchema) {
        self = [self initWithRealm:nil schema:[self.class sharedSchema] defaultValues:YES];

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
    self = [self init];
    if ([value isKindOfClass:NSArray.class]) {
        // validate and populate
        NSArray *array = RLMValidatedArrayForObjectSchema(value, _objectSchema, RLMSchema.sharedSchema);
        NSArray *properties = _objectSchema.properties;
        for (NSUInteger i = 0; i < array.count; i++) {
            [self setValue:array[i] forKeyPath:[properties[i] name]];
        }
    }
    else if ([value isKindOfClass:NSDictionary.class]) {
        // validate and populate
        NSDictionary *dict = RLMValidatedDictionaryForObjectSchema(value, _objectSchema, RLMSchema.sharedSchema);
        for (NSString *name in dict) {
            [self setValue:dict[name] forKeyPath:name];
        }
    }
    else {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Values must be provided either as an array or dictionary"
                                     userInfo:nil];
    }

    return self;
}

- (instancetype)initWithRealm:(RLMRealm *)realm
                       schema:(RLMObjectSchema *)schema
                defaultValues:(BOOL)useDefaults {
    self = [super init];
    if (self) {
        _realm = realm;
        _objectSchema = schema;
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

+(instancetype)createInDefaultRealmWithObject:(id)object {
    return RLMCreateObjectInRealmWithValue([RLMRealm defaultRealm], [self className], object);
}

+(instancetype)createInRealm:(RLMRealm *)realm withObject:(id)value {
    return RLMCreateObjectInRealmWithValue(realm, [self className], value);
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
    if (_realm) {
        return RLMDynamicGet(self, key);
    }
    else {
        return [self valueForKey:key];
    }
}

-(void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
    if (_realm) {
        RLMDynamicValidatedSet(self, key, obj);
    }
    else {
        [self setValue:obj forKey:key];
    }
}

+ (RLMArray *)allObjects {
    return RLMGetObjects(RLMRealm.defaultRealm, self.className, nil, nil);
}

+ (RLMArray *)allObjectsInRealm:(RLMRealm *)realm {
    return RLMGetObjects(realm, self.className, nil, nil);
}

+ (RLMArray *)objectsWhere:(NSString *)predicateFormat, ... {
    va_list args;
    RLM_VARARG(predicateFormat, args);
    return [self objectsWhere:predicateFormat args:args];
}

+ (RLMArray *)objectsWhere:(NSString *)predicateFormat args:(va_list)args {
    return [self objectsWithPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
}

+(RLMArray *)objectsInRealm:(RLMRealm *)realm where:(NSString *)predicateFormat, ... {
    va_list args;
    RLM_VARARG(predicateFormat, args);
    return [self objectsInRealm:realm where:predicateFormat args:args];
}

+(RLMArray *)objectsInRealm:(RLMRealm *)realm where:(NSString *)predicateFormat args:(va_list)args {
    return [self objectsInRealm:realm withPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
}

+ (RLMArray *)objectsWithPredicate:(NSPredicate *)predicate {
    return RLMGetObjects(RLMRealm.defaultRealm, self.className, predicate, nil);
}

+(RLMArray *)objectsInRealm:(RLMRealm *)realm withPredicate:(NSPredicate *)predicate {
    return RLMGetObjects(realm, self.className, predicate, nil);
}

- (NSDictionary *)JSONDictionary {
  return [self JSONDictionaryWithRootClassname:self.objectSchema.className];
}

- (NSDictionary *)JSONDictionaryWithRootClassname:(NSString *)rootClassname {

  if (![self isKindOfClass:[RLMObject class]]) {
    @throw [NSException exceptionWithName:@"RLMException" reason:@"Invalid RLMPropertyType specified" userInfo:nil];
  }

  NSMutableDictionary *objDictionary = [NSMutableDictionary dictionary];
  NSArray *properties = self.objectSchema.properties;
  for (RLMProperty *property in properties) {
    NSString *propertyName = property.name;
    SEL propertySelector = NSSelectorFromString(propertyName);
    if ([self respondsToSelector:propertySelector]) {

      id propertyValue = RLMDynamicGet(self, propertyName);

      switch (property.type) {
        case RLMPropertyTypeArray:
        {
          [objDictionary setValue:[propertyValue JSONArray] forKey:propertyName];
          break;
        }
        case RLMPropertyTypeObject:
        {
          // ignore circular relationships
          NSString *currentClassname = self.objectSchema.className;
          if (![rootClassname isEqualToString:currentClassname]) {
            NSDictionary *dictionaryProperty = [(RLMObject *)propertyValue JSONDictionaryWithRootClassname:rootClassname];
            [objDictionary setValue:dictionaryProperty forKey:propertyName];
          }
          break;
        }
        case RLMPropertyTypeData:
        {
          NSString *dataString = [(NSData *)propertyValue base64EncodedStringWithOptions:0];
          [objDictionary setValue:dataString forKey:propertyName];
          break;
        }
        case RLMPropertyTypeDate:
        {
          //TODO: Let user override formatter
          NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
          formatter.dateStyle = NSDateFormatterFullStyle; // default formatter
          NSString *dateString = [formatter stringFromDate:(NSDate *)propertyValue];
          [objDictionary setValue:dateString forKey:propertyName];
          break;
        }
        case RLMPropertyTypeString:
        {
          [objDictionary setValue:propertyValue forKey:propertyName];
          break;
        }
        case RLMPropertyTypeAny:
        {
          //FIXME: Should id properties be ignored?
          break;
        }
        default:
          // for all primitive properties, RLMDynamicGet already returns a NSNumber wrapping the value
          [objDictionary setValue:propertyValue forKey:propertyName];
          break;
      }

    }
  }
  return [NSDictionary dictionaryWithDictionary:objDictionary];
}

- (NSString *)JSONString {
  NSError *error = nil;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self JSONDictionary]
                                                     options:NSJSONWritingPrettyPrinted
                                                       error:&error];

  if (error) {
    @throw [NSException exceptionWithName:@"RLMException" reason:@"Invalid RLMObject specified" userInfo:nil];
  } else {
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  }
}


// overridden at runtime per-class for performance
+ (NSString *)className {
    NSString *className = NSStringFromClass(self);
#ifdef REALM_SWIFT
    if ([RLMSwiftSupport isSwiftClassName:className]) {
        className = [RLMSwiftSupport demangleClassName:className];
    }
#endif
    return className;
}

// overriddent at runtime per-class for performance
+ (RLMObjectSchema *)sharedSchema {
    return RLMSchema.sharedSchema[self.className];
}

- (NSString *)description
{
    NSString *baseClassName = self.objectSchema.className;
    NSMutableString *mString = [NSMutableString stringWithFormat:@"%@ {\n", baseClassName];
    RLMObjectSchema *objectSchema = self.realm.schema[baseClassName];
    
    for (RLMProperty *property in objectSchema.properties) {
        [mString appendFormat:@"\t%@ = %@;\n", property.name, [self[property.name] description]];
    }
    [mString appendString:@"}"];
    
    return [NSString stringWithString:mString];
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
    return [self isEqualToObject:object];
}

@end
