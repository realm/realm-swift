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
