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

#import "RLMDebugSupport.h"

#import "RLMArray.h"

#import <objc/runtime.h>

@interface NSObject (RLMDebugSupport)
- (NSString *)debugSummary;
@end

uintptr_t RLMDebugSummary(uintptr_t obj) {
    // This is of course not remotely thread-safe, but the debug script isn't
    // (and can't be) multithreaded
    static char buffer[1024];
    @autoreleasepool {
        NSString *str = [(__bridge id)(void *)obj debugSummary];
        if (!str) {
            return 0;
        }
        strlcpy(buffer, str.UTF8String, sizeof(buffer));
    }
    return (uintptr_t)buffer;
}

NSString *RLMDebugSummaryHelper(__unsafe_unretained id obj) {
    // This is needlessly roundabout, but the point is to have the tests hit
    // the same function that the python script uses, and the python script
    // wants an API that's really awkward from obj-c and Swift
    uintptr_t str = RLMDebugSummary((uintptr_t)obj);
    return str ? [NSString stringWithUTF8String:(const char *)str] : nil;
}

NSUInteger RLMDebugArrayCount(uintptr_t obj) {
    return [(__bridge id)(void *)obj count];
}

id RLMDebugArrayChildAtIndex(uintptr_t obj, NSUInteger index) {
    RLMArray *array = (__bridge id)(void *)obj;
    __autoreleasing RLMObject *o = array[index];
    return o;
}

size_t RLMDebugGetIvarOffset(uintptr_t obj, const char *name) {
    Ivar ivar = class_getInstanceVariable([(__bridge id)(void *)obj class], name);
    assert(ivar);
    return ivar_getOffset(ivar);
}
