////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
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

#import "RLMSyncPermissionResults_Private.hpp"

#import "collection_notifications.hpp"
#import "RLMCollection_Private.hpp"
#import "RLMSyncPermissions_Private.hpp"
#import "RLMSyncUser_Private.hpp"
#import "RLMUtil.hpp"

using namespace realm;

@interface RLMSyncPermissionResults () {
    std::unique_ptr<PermissionResults> _results;
}
@end

@implementation RLMSyncPermissionResults

- (NSInteger)count {
    REALM_ASSERT_DEBUG(_results);
    return _results->size();
}

- (RLMNotificationToken *)addNotificationBlock:(RLMPermissionStatusBlock)block {
    REALM_ASSERT_DEBUG(_results);
    auto token = _results->async(RLMWrapPermissionStatusCallback(block));
    return [[RLMCancellationToken alloc] initWithToken:std::move(token) realm:nil];
}

- (RLMSyncPermissionValue *)permissionAtIndex:(NSInteger)index {
    REALM_ASSERT_DEBUG(_results);
    try {
        return [[RLMSyncPermissionValue alloc] initWithPermission:_results->get(index)];
    } catch (std::exception const& ex) {
        @throw RLMException(ex);
    }
}

- (instancetype)initWithResults:(std::unique_ptr<PermissionResults>)results {
    if (self = [super init]) {
        REALM_ASSERT_DEBUG(results);
        _results = std::move(results);
    }
    return self;
}

- (NSString *)description {
    constexpr int NUMBER_OF_ITEMS = 4;
    NSMutableString *base = [NSMutableString stringWithFormat:@"<RLMSyncPermissionResults> (%@ items)", @(self.count)];
    // Stick the first few items in the description.
    for (NSInteger i=0; i<MIN(self.count, NUMBER_OF_ITEMS); i++) {
        [base appendFormat:@"\n    [%@]: %@", @(i), [self permissionAtIndex:i]];
    }
    if (self.count > NUMBER_OF_ITEMS) {
        [base appendFormat:@"\n    (%@ additional items...)", @(self.count - NUMBER_OF_ITEMS)];
    }
    return base;
}

@end
