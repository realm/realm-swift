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
#import <objc/runtime.h>

NSString * const c_arrayInvalidMessage = @"RLMArray is no longer valid.";
NSString * const c_arrayReadOnlyMessage = @"Attempting to modify a read-only RLMArray.";

inline NSException *RLMException(NSString *message) {
    return [NSException exceptionWithName:@"RLMException" reason:message userInfo:nil];
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"

// NOTE: we only need to override core methods
@implementation RLMArrayLinkViewReadOnly
- (void)addObject:(RLMObject *)object {
    @throw RLMException(c_arrayReadOnlyMessage);
}
- (void)insertObject:(RLMObject *)anObject atIndex:(NSUInteger)index {
    @throw RLMException(c_arrayReadOnlyMessage);
}
- (void)removeObjectAtIndex:(NSUInteger)index {
    @throw RLMException(c_arrayReadOnlyMessage);
}
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
    @throw RLMException(c_arrayReadOnlyMessage);
}
- (void)removeLastObject {
    @throw RLMException(c_arrayReadOnlyMessage);
}
- (void)removeAllObjects {
    @throw RLMException(c_arrayReadOnlyMessage);
}
@end

@implementation RLMArrayTableViewReadOnly
- (void)addObject:(RLMObject *)object {
    @throw RLMException(c_arrayReadOnlyMessage);
}
- (void)insertObject:(RLMObject *)anObject atIndex:(NSUInteger)index {
    @throw RLMException(c_arrayReadOnlyMessage);
}
- (void)removeObjectAtIndex:(NSUInteger)index {
    @throw RLMException(c_arrayReadOnlyMessage);
}
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
    @throw RLMException(c_arrayReadOnlyMessage);
}
@end

@implementation RLMArrayLinkViewInvalid
- (IMP)methodForSelector:(SEL)aSelector {
    return imp_implementationWithBlock(^{ @throw RLMException(c_arrayInvalidMessage); });
}
@end

@implementation RLMArrayTableViewInvalid
- (IMP)methodForSelector:(SEL)aSelector {
    return imp_implementationWithBlock(^{ @throw RLMException(c_arrayInvalidMessage); });
}
@end
#pragma GCC diagnostic pop
