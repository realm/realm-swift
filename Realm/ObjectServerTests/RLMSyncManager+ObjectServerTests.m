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

#import "RLMSyncManager+ObjectServerTests.h"
#import "RLMSyncTestCase.h"
#import "RLMSyncFileManager.h"

#import <objc/runtime.h>

@interface RLMSyncManager ()
- (NSMutableDictionary<NSString *, RLMSyncUser *> *)activeUsers;
- (RLMSyncFileManager *)fileManager;
@end

@implementation RLMSyncManager (ObjectServerTests)

+ (void)load {
    Class class = object_getClass((id)self);
    SEL originalSelector = @selector(sharedManager);
    SEL swizzledSelector = @selector(ost_sharedManager);
    Method originalMethod = class_getClassMethod(class, originalSelector);
    Method swizzledMethod = class_getClassMethod(class, swizzledSelector);

    if (class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod))) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

+ (instancetype)ost_sharedManager {
    return [RLMSyncTestCase managerForCurrentTest];
}

- (void)prepareForDestruction {
    // Log out all the logged-in users. This will immediately kill any open sessions.
    NSMutableArray<RLMSyncUser *> *buffer = [NSMutableArray array];
    for (id key in [self activeUsers]) {
        [buffer addObject:[self activeUsers][key]];
    }
    [self.activeUsers.allValues makeObjectsPerformSelector:@selector(logOut)];
    NSURL *metadataURL = [self.fileManager fileURLForMetadata];

    // Destroy the metadata Realm.
    [[[RLMTestCase alloc] init] deleteRealmFileAtURL:metadataURL];
}

@end
