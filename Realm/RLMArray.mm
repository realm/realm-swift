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

@implementation RLMArray

@dynamic writable;
@dynamic realm;

- (instancetype)initWithObjectClassName:(NSString *)objectClassName {
    self = [super init];
    if (self) {
        _objectClassName = objectClassName;
    }
    return self;
}

- (RLMRealm *)realm {
    return _realm;
}

- (BOOL)writable {
    return _writable;
}

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

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"
- (NSUInteger)count {
    @throw [NSException exceptionWithName:@"RLMAbstractBaseClassException"
                                   reason:@"Method not implemented in base class" userInfo:nil];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
    @throw [NSException exceptionWithName:@"RLMAbstractBaseClassException"
                                   reason:@"Method not implemented in base class" userInfo:nil];
}

- (id)objectAtIndex:(NSUInteger)index {
    @throw [NSException exceptionWithName:@"RLMAbstractBaseClassException"
                                   reason:@"Method not implemented in base class" userInfo:nil];
}

- (void)insertObject:(RLMObject *)anObject atIndex:(NSUInteger)index {
    @throw [NSException exceptionWithName:@"RLMAbstractBaseClassException"
                                   reason:@"Method not implemented in base class" userInfo:nil];
}

- (void)removeObjectAtIndex:(NSUInteger)index {
    @throw [NSException exceptionWithName:@"RLMAbstractBaseClassException"
                                   reason:@"Method not implemented in base class" userInfo:nil];
}


- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
    @throw [NSException exceptionWithName:@"RLMAbstractBaseClassException"
                                   reason:@"Method not implemented in base class" userInfo:nil];
}

- (RLMArray *)objectsWhere:(id)predicate, ... {
    @throw [NSException exceptionWithName:@"RLMAbstractBaseClassException"
                                   reason:@"Method not implemented in base class" userInfo:nil];
}

- (RLMArray *)objectsOrderedBy:(id)order where:(id)predicate, ... {
    @throw [NSException exceptionWithName:@"RLMAbstractBaseClassException"
                                   reason:@"Method not implemented in base class" userInfo:nil];
}

-(id)minOfProperty:(NSString *)property {
    @throw [NSException exceptionWithName:@"RLMAbstractBaseClassException"
                                   reason:@"Method not implemented in base class" userInfo:nil];
}

-(id)maxOfProperty:(NSString *)property {
    @throw [NSException exceptionWithName:@"RLMAbstractBaseClassException"
                                   reason:@"Method not implemented in base class" userInfo:nil];
}

-(NSNumber *)sumOfProperty:(NSString *)property {
    @throw [NSException exceptionWithName:@"RLMAbstractBaseClassException"
                                   reason:@"Method not implemented in base class" userInfo:nil];
}

-(NSNumber *)averageOfProperty:(NSString *)property {
    @throw [NSException exceptionWithName:@"RLMAbstractBaseClassException"
                                   reason:@"Method not implemented in base class" userInfo:nil];
}

- (NSUInteger)indexOfObject:(RLMObject *)object {
    @throw [NSException exceptionWithName:@"RLMAbstractBaseClassException"
                                   reason:@"Method not implemented in base class" userInfo:nil];
}

- (NSUInteger)indexOfObjectWhere:(id)predicate, ... {
    @throw [NSException exceptionWithName:@"RLMAbstractBaseClassException"
                                   reason:@"Method not implemented in base class" userInfo:nil];
}

- (NSString *)JSONString {
    @throw [NSException exceptionWithName:@"RLMAbstractBaseClassException"
                                   reason:@"Method not implemented in base class" userInfo:nil];
}

- (void)refreshAccessor {
    @throw [NSException exceptionWithName:@"RLMAbstractBaseClassException"
                                   reason:@"Method not implemented in base class" userInfo:nil];
}

#pragma GCC diagnostic pop




@end