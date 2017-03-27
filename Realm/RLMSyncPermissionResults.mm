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
#import "RLMSyncPermissions_Private.hpp"
#import "RLMSyncUser_Private.hpp"
#import "RLMUtil.hpp"

using namespace realm;

@interface RLMSyncPermissionResultsToken() {
    std::unique_ptr<NotificationToken> _token;
}
@end

@implementation RLMSyncPermissionResultsToken

- (void)suppressNextNotification {
    @throw RLMException(@"RLMPermissionResultsTokens cannot be passed to "
                        @"the commitWriteTransactionWithoutNotifying: method");
}

- (void)stop {
    _token = nil;
}

- (void)dealloc {
    if (_token) {
        NSLog(@"RLMPermissionResultsToken released without unregistering "
              @"a notification. You must hold on to the token and call "
              @"-[RLMPermissionResultsToken stop] when you no longer wish "
              @"to receive notifications.");
    }
}

- (instancetype)initWithToken:(NotificationToken)token {
    if (self = [super init]) {
        _token = std::make_unique<NotificationToken>(std::move(token));
        return self;
    }
    return nil;
}

@end

@interface RLMSyncPermissionResults () {
    std::unique_ptr<PermissionResults> _results;
}
@end

@implementation RLMSyncPermissionResults

- (NSInteger)count {
    REALM_ASSERT_DEBUG(_results);
    return _results->size();
}

- (RLMSyncPermissionResultsToken *)addNotificationBlock:(RLMPermissionStatusBlock)block {
    REALM_ASSERT_DEBUG(_results);
    auto token = _results->async(RLMWrapPermissionStatusCallback(block));
    return [[RLMSyncPermissionResultsToken alloc] initWithToken:std::move(token)];
}

- (RLMSyncPermissionValue *)permissionAtIndex:(NSInteger)index {
    REALM_ASSERT_DEBUG(_results);
    if (index < 0 || (size_t)index >= _results->size()) {
        @throw RLMException(@"Index out of bounds; index is %@ but the permission results contains %@ objects.",
                            @(index), @(_results->size()));
    }
    return [[RLMSyncPermissionValue alloc] initWithPermission:_results->get(index)];
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
