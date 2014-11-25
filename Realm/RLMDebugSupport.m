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
#import "RLMObjectSchema.h"

#import <objc/runtime.h>

@interface NSObject (RLMDebugSupport)
- (NSString *)debugSummary;
@end

uintptr_t RLMDebugSummary(__unsafe_unretained id obj) {
    // This is of course not remotely thread-safe, but the debug script isn't
    // (and can't be) multithreaded
    static char buffer[1024];
    @autoreleasepool {
        NSString *str = [obj debugSummary];
        if (!str) {
            return 0;
        }
        NSUInteger used = 0;
        [str getBytes:buffer
            maxLength:sizeof(buffer) - 1 usedLength:&used
             encoding:NSUTF8StringEncoding options:0
                range:NSMakeRange(0, str.length) remainingRange:0];
        buffer[used] = 0;
    }
    return (uintptr_t)buffer;
}

NSString *RLMDebugSummaryHelper(__unsafe_unretained id obj) {
    uintptr_t str = RLMDebugSummary(obj);
    return str ? [NSString stringWithUTF8String:(const char *)str] : nil;
}

NSUInteger RLMDebugArrayCount(__unsafe_unretained id obj) {
    return [obj count];
}

id RLMDebugArrayChildAtIndex(__unsafe_unretained id obj, NSUInteger index) {
    __autoreleasing RLMObject *o = obj[index];
    return o;
}

size_t RLMDebugGetIvarOffset(__unsafe_unretained id obj, const char *name) {
    Ivar ivar = class_getInstanceVariable([obj class], name);
    assert(ivar);
    return ivar_getOffset(ivar);
}

id RLMDebugAddrToObj(uintptr_t ptr) {
    return (__bridge id)(void *)ptr;
}

uintptr_t RLMDebugPropertyNames(__unsafe_unretained id obj) {
    return (uintptr_t)[[[[obj objectSchema] properties] valueForKey:@"name"] componentsJoinedByString:@" "].UTF8String;
}

uintptr_t RLMDebugGetSubclassList(void) {
    NSMutableString *names = [NSMutableString stringWithCapacity:1024];

    unsigned int numClasses;
    Class *classes = objc_copyClassList(&numClasses);

    for (unsigned int i = 0; i < numClasses; i++) {
        const char *name = class_getName(classes[i]);
        if (strncmp("RLMAccessor_v", name, sizeof("RLMAccessor_v") - 1) == 0 ||
            strncmp("RLMStandalone_", name, sizeof("RLMStandalone_") - 1) == 0) {
            continue;
        }
        for (Class cls = class_getSuperclass(classes[i]); cls; cls = class_getSuperclass(cls)) {
            if (cls == RLMObject.class) {
                [names appendFormat:@"%s ", name];
                break;
            }
        }
    }

    free(classes);
    return (uintptr_t)names.UTF8String;
}
