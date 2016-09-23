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

@class RLMSyncUser;

@interface RLMSyncFileManager : NSObject

NS_ASSUME_NONNULL_BEGIN

+ (NSURL *)fileURLForRawRealmURL:(NSURL *)url user:(RLMSyncUser *)user;
+ (NSURL *)fileURLForMetadata;
+ (BOOL)removeFilesForUserIdentity:(NSString *)identity error:(NSError * _Nullable* _Nullable)error;

NS_ASSUME_NONNULL_END

@end
