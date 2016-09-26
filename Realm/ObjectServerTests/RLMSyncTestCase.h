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

#import "RLMSyncUser+ObjectServerTests.h"

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
- (RLMRealm *)openRealmForURL:(NSURL *)url user:(RLMSyncUser *)user;

/// Immediately open a synced Realm.
- (RLMRealm *)immediatelyOpenRealmForURL:(NSURL *)url user:(RLMSyncUser *)user;

/// Synchronously create, log in, and return a user.
- (RLMSyncUser *)logInUserForCredential:(RLMSyncCredential *)credential
                                 server:(NSURL *)url;

/// Add a number of objects to a Realm.
- (void)addSyncObjectsToRealm:(RLMRealm *)realm descriptions:(NSArray<NSString *> *)descriptions;

/// Synchronously wait for downloads to complete for any number of Realms, and then check their `SyncObject` counts.
- (void)waitForDownloadsForUser:(RLMSyncUser *)user
                         realms:(NSArray<RLMRealm *> *)realms
                      realmURLs:(NSArray<NSURL *> *)realmURLs
                 expectedCounts:(NSArray<NSNumber *> *)counts;

@end

NS_ASSUME_NONNULL_END

#define WAIT_FOR_UPLOAD(macro_user, macro_url) \
XCTAssertTrue([macro_user waitForUploadToFinish:macro_url], @"Upload timed out for URL: %@", macro_url);

#define WAIT_FOR_DOWNLOAD(macro_user, macro_url) \
XCTAssertTrue([macro_user waitForDownloadToFinish:macro_url], @"Download timed out for URL: %@", macro_url);

#define CHECK_COUNT(d_count, macro_object_type, macro_realm) \
{ \
NSInteger c = [macro_object_type allObjectsInRealm:macro_realm].count; \
NSString *w = self.isParent ? @"parent" : @"child"; \
XCTAssert(d_count == c, @"Expected %@ items, but actually got %@ (%@)", @(d_count), @(c), w); \
}
