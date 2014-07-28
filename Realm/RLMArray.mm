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

#import "RLMArray_Private.hpp"
#import "RLMObject.h"
#import "RLMObjectSchema.h"
#import "RLMObjectStore.h"
#import "RLMQueryUtil.hpp"

@implementation RLMArray

@synthesize realm = _realm;
@synthesize objectClassName = _objectClassName;
@dynamic readOnly;

- (instancetype)initWithObjectClassName:(NSString *)objectClassName {
    self = [super init];
    if (self) {
        _objectClassName = objectClassName;
        _readOnly = NO;
    }
    return self;
}

- (BOOL)isReadOnly {
    return _readOnly;
}

//
// Generic implementations for all RLMArray variants
//

- (id)firstObject {
    if (self.count) {
        return [self objectAtIndex:0];
    }
    return nil;
}

- (id)lastObject {
    NSUInteger count = self.count;
    if (count) {
        return [self objectAtIndex:count-1];
    }
    return nil;
}

- (void)addObjectsFromArray:(id)objects {
    for (id obj in objects) {
        [self addObject:obj];
    }
}

- (void)addObject:(RLMObject *)object {
    [self insertObject:object atIndex:self.count];
}

- (void)removeLastObject {
    NSUInteger count = self.count;
    if (count) {
        [self removeObjectAtIndex:count-1];
    }
}

- (void)removeAllObjects {
    while (self.count) {
        [self removeLastObject];
    }
}

- (id)objectAtIndexedSubscript:(NSUInteger)index {
    return [self objectAtIndex:index];
}

- (void)setObject:(id)newValue atIndexedSubscript:(NSUInteger)index {
    [self replaceObjectAtIndex:index withObject:newValue];
}


//
// Stanalone RLMArray implementation
//

void RLMValidateMatchingObjectType(RLMArray *array, RLMObject *object) {
    if (![array->_objectClassName isEqualToString:object.objectSchema.className]) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Object type does not match RLMArray"
                                     userInfo:nil];
    }
}

+ (instancetype)standaloneArrayWithObjectClassName:(NSString *)objectClassName {
    RLMArray *ar = [[RLMArray alloc] initWithObjectClassName:objectClassName];
    ar->_backingArray = [NSMutableArray array];
    return ar;
}

- (id)objectAtIndex:(NSUInteger)index {
    return [_backingArray objectAtIndex:index];
}

- (NSUInteger)count {
    return _backingArray.count;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
    return [_backingArray countByEnumeratingWithState:state objects:buffer count:len];
}

- (void)insertObject:(RLMObject *)anObject atIndex:(NSUInteger)index {
    RLMValidateMatchingObjectType(self, anObject);
    [_backingArray insertObject:anObject atIndex:index];
}

- (void)removeObjectAtIndex:(NSUInteger)index {
    [_backingArray removeObjectAtIndex:index];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
    RLMValidateMatchingObjectType(self, anObject);
    [_backingArray replaceObjectAtIndex:index withObject:anObject];
}

- (NSUInteger)indexOfObject:(RLMObject *)object {
    RLMValidateMatchingObjectType(self, object);
    return [_backingArray indexOfObject:object];
}

- (void)deleteObjectsFromRealm {
    for (RLMObject *obj in _backingArray) {
        RLMDeleteObjectFromRealm(obj);
    }
}



//
// Methods unsupported on standalone RLMArray instances
//

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"
- (RLMArray *)objectsWhere:(NSString *)predicateFormat, ...
{
    va_list args;
    RLM_VARARG(predicateFormat, args);
    return [self objectsWhere:predicateFormat args:args];
}

- (RLMArray *)objectsWhere:(NSString *)predicateFormat args:(va_list)args
{
    @throw [NSException exceptionWithName:@"RLMException"
                                   reason:@"This method can only be called in RLMArray instances retrieved from an RLMRealm" userInfo:nil];
}

- (RLMArray *)objectsWithPredicate:(NSPredicate *)predicate
{
    @throw [NSException exceptionWithName:@"RLMException"
                                   reason:@"This method can only be called in RLMArray instances retrieved from an RLMRealm" userInfo:nil];
}

- (RLMArray *)arraySortedByProperty:(NSString *)property ascending:(BOOL)ascending
{
    @throw [NSException exceptionWithName:@"RLMException"
                                   reason:@"This method can only be called in RLMArray instances retrieved from an RLMRealm" userInfo:nil];
}

-(id)minOfProperty:(NSString *)property {
    @throw [NSException exceptionWithName:@"RLMException"
                                   reason:@"This method can only be called in RLMArray instances retrieved from an RLMRealm" userInfo:nil];
}

-(id)maxOfProperty:(NSString *)property {
    @throw [NSException exceptionWithName:@"RLMException"
                                   reason:@"This method can only be called in RLMArray instances retrieved from an RLMRealm" userInfo:nil];
}

-(NSNumber *)sumOfProperty:(NSString *)property {
    @throw [NSException exceptionWithName:@"RLMException"
                                   reason:@"This method can only be called in RLMArray instances retrieved from an RLMRealm" userInfo:nil];
}

-(NSNumber *)averageOfProperty:(NSString *)property {
    @throw [NSException exceptionWithName:@"RLMException"
                                   reason:@"This method can only be called in RLMArray instances retrieved from an RLMRealm" userInfo:nil];
}

- (NSUInteger)indexOfObjectWhere:(NSString *)predicateFormat, ...
{
    va_list args;
    RLM_VARARG(predicateFormat, args);
    return [self indexOfObjectWhere:predicateFormat args:args];
}

- (NSUInteger)indexOfObjectWhere:(NSString *)predicateFormat args:(va_list)args
{
    @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                   reason:@"Method not implemented" userInfo:nil];
}

- (NSUInteger)indexOfObjectWithPredicate:(NSPredicate *)predicate
{
    @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                   reason:@"Method not implemented" userInfo:nil];
}
#pragma GCC diagnostic pop

- (NSArray *)NSArray {
  NSMutableArray *array = [NSMutableArray array];
  for (RLMObject *object in self) {
    [array addObject:[object NSDictionary]];
  }
  return [NSArray arrayWithArray:array];
}

- (NSString *)JSONString {
  NSError *error = nil;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self NSArray]
                                                     options:NSJSONWritingPrettyPrinted
                                                       error:&error];

  if (error) {
    @throw [NSException exceptionWithName:@"RLMException" reason:@"Invalid RLMArray specified" userInfo:nil];
  } else {
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  }
}


#pragma mark - Superclass Overrides

- (NSString *)description
{
    const NSUInteger maxObjects = 100;
    NSMutableString *mString = [NSMutableString stringWithString:@"RLMArray (\n"];
    unsigned long index = 0, skipped = 0;
    for (NSObject *obj in self) {
        // Indent child objects
        NSString *objDescription = [obj.description stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\t"];
        [mString appendFormat:@"\t[%lu] %@,\n", index++, objDescription];
        if (index >= maxObjects) {
            skipped = self.count - maxObjects;
            break;
        }
    }
    
    // Remove last comma and newline characters
    [mString deleteCharactersInRange:NSMakeRange(mString.length-2, 2)];
    if (skipped) {
        [mString appendFormat:@"\n\t... %lu objects skipped.", skipped];
    }
    [mString appendFormat:@"\n)"];
    return [NSString stringWithString:mString];
}

@end
