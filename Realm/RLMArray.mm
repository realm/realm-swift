////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMArray_Private.hpp"
#import "RLMObject.h"

@implementation RLMArray

@dynamic RLMAccessor_invalid;
@dynamic realm;
@dynamic RLMAccessor_writable;
@dynamic readOnly;

- (instancetype)initWithObjectClassName:(NSString *)objectClassName {
    self = [super init];
    if (self) {
        _objectClassName = objectClassName;
        _readOnly = NO;
    }
    return self;
}

- (RLMRealm *)realm {
    return _realm;
}

- (BOOL)RLMAccessor_writable {
    return _writable;
}

- (BOOL)RLMAccessor_invalid {
    return _invalid;
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
    [_backingArray insertObject:anObject atIndex:index];
}

- (void)removeObjectAtIndex:(NSUInteger)index {
    [_backingArray removeObjectAtIndex:index];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
    [_backingArray replaceObjectAtIndex:index withObject:anObject];
}

- (NSUInteger)indexOfObject:(RLMObject *)object {
    return [_backingArray indexOfObject:object];
}


//
// Methods unsupported on standalone RLMArray instances
//

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"
- (RLMArray *)objectsWhere:(id)predicate, ... {
    @throw [NSException exceptionWithName:@"RLMException"
                                   reason:@"This method can only be called in RLMArray instances retrieved from an RLMRealm" userInfo:nil];
}

- (RLMArray *)objectsOrderedBy:(id)order where:(id)predicate, ... {
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

- (NSUInteger)indexOfObjectWhere:(id)predicate, ... {
    @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                   reason:@"Method not implemented" userInfo:nil];
}
#pragma GCC diagnostic pop

- (NSString *)JSONString {
    @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                   reason:@"Method not implemented" userInfo:nil];
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
