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

#import "RLMMultiProcessTestCase.h"

typedef void(^RLMSyncBasicErrorReportingBlock)(NSError * _Nullable);

NS_ASSUME_NONNULL_BEGIN

@interface RLMSyncManager ()
- (void)setSessionCompletionNotifier:(RLMSyncBasicErrorReportingBlock)sessionCompletionNotifier;
@end

@interface SyncObject : RLMObject
@property NSString *stringProp;
@end

@interface RLMSyncTestCase : RLMMultiProcessTestCase

+ (RLMSyncManager *)managerForCurrentTest;

+ (NSURL *)rootRealmCocoaURL;

+ (NSURL *)authServerURL;

+ (RLMSyncCredential *)basicCredential:(BOOL)createAccount;

/// Synchronously open a synced Realm and wait until the binding process has completed or failed.
- (RLMRealm *)openRealmForURL:(NSURL *)url user:(RLMSyncUser *)user error:(NSError **)error;

/// Immediately open a synced Realm.
- (RLMRealm *)immediatelyOpenRealmForURL:(NSURL *)url user:(RLMSyncUser *)user error:(NSError **)error;

/// Synchronously create, log in, and return a user.
- (RLMSyncUser *)logInUserForCredential:(RLMSyncCredential *)credential
                                 server:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END

#define CHECK_COUNT(d_count, macro_object_type, macro_realm) \
{ \
NSInteger c = [macro_object_type allObjectsInRealm:r].count; \
NSString *w = self.isParent ? @"parent" : @"child"; \
XCTAssert(d_count == c, @"Expected %@ items, but actually got %@ (%@)", @(d_count), @(c), w); \
}
