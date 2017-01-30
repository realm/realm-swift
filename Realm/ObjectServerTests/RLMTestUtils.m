////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#import <Foundation/Foundation.h>

#import "RLMTestUtils.h"

#import <objc/runtime.h>

static void RLMSwapOutMethod(Class class,
                             SEL original, Method originalMethod,
                             SEL swizzled, Method swizzledMethod) {
    if (class_addMethod(class,
                        original,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod))) {
        class_replaceMethod(class,
                            swizzled,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

void RLMSwapOutClassMethod(id classObject, SEL original, SEL swizzled) {
    Class class = object_getClass((id)classObject);
    RLMSwapOutMethod(class,
                     original, class_getClassMethod(class, original),
                     swizzled, class_getClassMethod(class, swizzled));
}

void RLMSwapOutInstanceMethod(id classObject, SEL original, SEL swizzled) {
    Class class = [classObject class];
    RLMSwapOutMethod(class,
                     original, class_getInstanceMethod(class, original),
                     swizzled, class_getInstanceMethod(class, swizzled));
}
