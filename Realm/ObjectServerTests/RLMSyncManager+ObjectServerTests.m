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

#import "RLMSyncManager_Private.h"
#import "RLMSyncManager+ObjectServerTests.h"
#import "RLMSyncTestCase.h"
#import "RLMTestUtils.h"

@interface RLMSyncManager ()
- (NSArray<RLMSyncUser *> *)_allUsers;
@end

@implementation RLMSyncManager (ObjectServerTests)

+ (void)load {
    RLMSwapOutClassMethod(self, @selector(sharedManager),  @selector(ost_sharedManager));
}

+ (instancetype)ost_sharedManager {
    return [RLMSyncTestCase managerForCurrentTest];
}

- (void)prepareForDestruction {
    // Log out all the logged-in users.
    [[self _allUsers] makeObjectsPerformSelector:@selector(logOut)];
    [RLMSyncManager resetForTesting];
}

@end
