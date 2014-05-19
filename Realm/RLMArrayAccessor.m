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

#import "RLMArrayAccessor.h"

static NSException *s_arrayInvalidException;
static NSException *s_arrayReadOnlyException;

// NOTE: do not add any ivars or properties to these classes
//  we switch versions of RLMArray with this subclass dynamically
@implementation RLMArrayReadOnly

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_arrayInvalidException = [NSException exceptionWithName:@"RLMException"
                                                          reason:@"RLMArray is no longer valid."
                                                        userInfo:nil];
        s_arrayReadOnlyException = [NSException exceptionWithName:@"RLMException"
                                                           reason:@"Attempting to modify a read-only RLMArray."
                                                         userInfo:nil];
    });
}

- (void)addObject:(RLMObject *)object {
    @throw s_arrayReadOnlyException;
}
- (void)insertObject:(RLMObject *)anObject atIndex:(NSUInteger)index {
    @throw s_arrayReadOnlyException;
}
- (void)removeObjectAtIndex:(NSUInteger)index {
    @throw s_arrayReadOnlyException;
}
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
    @throw s_arrayReadOnlyException;
}

@end

@implementation RLMArrayInvalid
- (NSUInteger)count {
    @throw s_arrayInvalidException;
}
- (void)addObject:(RLMObject *)object {
    @throw s_arrayInvalidException;
}
- (void)insertObject:(RLMObject *)anObject atIndex:(NSUInteger)index {
    @throw s_arrayInvalidException;
}
- (void)removeObjectAtIndex:(NSUInteger)index {
    @throw s_arrayInvalidException;
}
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
    @throw s_arrayInvalidException;
}
- (NSUInteger)indexOfObject:(RLMObject *)object {
    @throw s_arrayInvalidException;
}
- (NSUInteger)indexOfObjectWhere:(id)predicate, ... {
    @throw s_arrayInvalidException;
}
- (RLMArray *)objectsWhere:(id)predicate, ... {
    @throw s_arrayInvalidException;
}
- (RLMArray *)objectsOrderedBy:(id)order where:(id)predicate, ... {
    @throw s_arrayInvalidException;
}
- (id)minOfProperty:(NSString *)property {
    @throw s_arrayInvalidException;
}
- (id)maxOfProperty:(NSString *)property {
    @throw s_arrayInvalidException;
}
- (NSNumber *)sumOfProperty:(NSString *)property {
    @throw s_arrayInvalidException;
}
- (NSNumber *)averageOfProperty:(NSString *)property {
    @throw s_arrayInvalidException;
}
- (NSString *)JSONString {
    @throw s_arrayInvalidException;
}
@end

